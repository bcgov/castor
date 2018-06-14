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
#  Script Name: 05_range_climate_profiles.R
#  Script Version: 1.0
#  Script Purpose: Figures to illustrate current and future climate conditions i
#                  in caribou ranges.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 8 May 2018
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
require (dplyr)
require (ggplot2)
require (reshape2)

#============================================
# Load, clean and prep the data for plotting 
#===========================================
data <- read.table ("model\\model_data_20180502.csv", header = T, stringsAsFactors = T, sep = ",")
data.clean <- data [complete.cases (data), ]
data.clean <- data.clean %>% # see 03_regres.... for details on why these data removed
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

data.clean$bec.2050.simple <- as.character (data.clean$bec2050)
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "BG  xh 3" |
                            data.clean$bec.2050.simple == "BG  xw 2"] <- "BG"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "BAFAun" | 
                             data.clean$bec.2050.simple == "BAFAunp"] <- "BAFA"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "BWBSdk" | 
                              data.clean$bec.2050.simple == "BWBSmk" |
                              data.clean$bec.2050.simple == "BWBSmw" |
                              data.clean$bec.2050.simple == "BWBSwk 1" |  
                              data.clean$bec.2050.simple == "BWBSwk 2" |   
                              data.clean$bec.2050.simple == "BWBSwk 3" |   
                              data.clean$bec.2050.simple == "BWBSmw 1" |   
                              data.clean$bec.2050.simple == "BWBSmw 2" |   
                              data.clean$bec.2050.simple == "BWBSdk 2" |   
                              data.clean$bec.2050.simple == "BWBSdk 1" |   
                              data.clean$bec.2050.simple == "BWBSvk"] <- "BWBS"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "CMA un" |
                              data.clean$bec.2050.simple == "CMA unp"] <- "CMA"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "CWH ds 2" |
                              data.clean$bec.2050.simple == "CWH ms 2" |
                              data.clean$bec.2050.simple == "CWH vm 1" |
                              data.clean$bec.2050.simple == "CWH vm 2" |  
                              data.clean$bec.2050.simple == "CWH ws 1" | 
                              data.clean$bec.2050.simple == "CWH ws 2" | 
                              data.clean$bec.2050.simple == "CWH ms 1" | 
                              data.clean$bec.2050.simple == "CWH ds 1" | 
                              data.clean$bec.2050.simple == "CWH wm" | 
                              data.clean$bec.2050.simple == "CWH vm" ] <- "CWH"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "ESSFdc 1" |
                              data.clean$bec.2050.simple == "ESSFdc 3" |
                              data.clean$bec.2050.simple == "ESSFdk 1" |
                              data.clean$bec.2050.simple == "ESSFdk 2" |  
                              data.clean$bec.2050.simple == "ESSFdkp" | 
                              data.clean$bec.2050.simple == "ESSFdkw" | 
                              data.clean$bec.2050.simple == "ESSFmc"  |
                              data.clean$bec.2050.simple == "ESSFmcp"  |
                              data.clean$bec.2050.simple == "ESSFmh"  |
                              data.clean$bec.2050.simple == "ESSFmk"  |
                              data.clean$bec.2050.simple == "ESSFmkp"  |
                              data.clean$bec.2050.simple == "ESSFmm 1"  |
                              data.clean$bec.2050.simple == "ESSFmmp"  |
                              data.clean$bec.2050.simple == "ESSFmmw"  |
                              data.clean$bec.2050.simple == "ESSFmv 1"  |
                              data.clean$bec.2050.simple == "ESSFmv 2"  |
                              data.clean$bec.2050.simple == "ESSFmv 3"  |
                              data.clean$bec.2050.simple == "ESSFmv 4"  |
                              data.clean$bec.2050.simple == "ESSFmvp"  |
                              data.clean$bec.2050.simple == "ESSFmw"  |
                              data.clean$bec.2050.simple == "ESSFmwp"  |
                              data.clean$bec.2050.simple == "ESSFun"  |
                              data.clean$bec.2050.simple == "ESSFunp"  |
                              data.clean$bec.2050.simple == "ESSFvc"  |
                              data.clean$bec.2050.simple == "ESSFvcp"  |
                              data.clean$bec.2050.simple == "ESSFvcw"  |
                              data.clean$bec.2050.simple == "ESSFwc 2"  |
                              data.clean$bec.2050.simple == "ESSFwc 2w"  |
                              data.clean$bec.2050.simple == "ESSFwc 3"  |
                              data.clean$bec.2050.simple == "ESSFwc 4"  |
                              data.clean$bec.2050.simple == "ESSFwcp"  |
                              data.clean$bec.2050.simple == "ESSFwcw"  |
                              data.clean$bec.2050.simple == "ESSFwh 1"  |
                              data.clean$bec.2050.simple == "ESSFwh 2"  |
                              data.clean$bec.2050.simple == "ESSFwh 3"  |
                              data.clean$bec.2050.simple == "ESSFwk 1"  |
                              data.clean$bec.2050.simple == "ESSFwk 2"  |
                              data.clean$bec.2050.simple == "ESSFwm"  |
                              data.clean$bec.2050.simple == "ESSFwm 2"  |
                              data.clean$bec.2050.simple == "ESSFwm 3"  |
                              data.clean$bec.2050.simple == "ESSFwm 4"  |
                              data.clean$bec.2050.simple == "ESSFwmp"  |
                              data.clean$bec.2050.simple == "ESSFwmw"  |
                              data.clean$bec.2050.simple == "ESSFwv"  |
                              data.clean$bec.2050.simple == "ESSFwvp"  |
                              data.clean$bec.2050.simple == "ESSFxv 1"  |
                              data.clean$bec.2050.simple == "ESSFxvp" |
                              data.clean$bec.2050.simple == "ESSFdm" |
                              data.clean$bec.2050.simple == "ESSFwc 1" |
                              data.clean$bec.2050.simple == "ESSFmw 1" |
                              data.clean$bec.2050.simple == "ESSFdc 2"] <- "ESSF"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "ICH dk" |
                              data.clean$bec.2050.simple == "ICH dm" |
                              data.clean$bec.2050.simple == "ICH dw 1" |
                              data.clean$bec.2050.simple == "ICH dw 3" |  
                              data.clean$bec.2050.simple == "ICH dw 4" | 
                              data.clean$bec.2050.simple == "ICH mc 1" | 
                              data.clean$bec.2050.simple == "ICH mk 2"  |
                              data.clean$bec.2050.simple == "ICH mk 3"  |
                              data.clean$bec.2050.simple == "ICH mk 4"  |
                              data.clean$bec.2050.simple == "ICH mm"  |
                              data.clean$bec.2050.simple == "ICH mw 1"  |
                              data.clean$bec.2050.simple == "ICH mw 2"  |
                              data.clean$bec.2050.simple == "ICH mw 3"  |
                              data.clean$bec.2050.simple == "ICH mw 4"  |
                              data.clean$bec.2050.simple == "ICH mw 5"  |
                              data.clean$bec.2050.simple == "ICH vk 1"  |
                              data.clean$bec.2050.simple == "ICH vk 2"  |
                              data.clean$bec.2050.simple == "ICH wc"  |
                              data.clean$bec.2050.simple == "ICH wk 1"  |
                              data.clean$bec.2050.simple == "ICH wk 2"  |
                              data.clean$bec.2050.simple == "ICH wk 3"  |
                              data.clean$bec.2050.simple == "ICH wk 4"  |
                              data.clean$bec.2050.simple == "ICH xw"  |
                              data.clean$bec.2050.simple == "ICH xw  a" |
                              data.clean$bec.2050.simple == "ICH mc 2" |
                              data.clean$bec.2050.simple == "ICH mk 1" |
                              data.clean$bec.2050.simple == "ICH vc"] <- "ICH"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "IDF dk 4" |
                              data.clean$bec.2050.simple == "IDF dm 2" |
                              data.clean$bec.2050.simple == "IDF dw" |
                              data.clean$bec.2050.simple == "IDF mw 1" |  
                              data.clean$bec.2050.simple == "IDF mw 2" | 
                              data.clean$bec.2050.simple == "IDF ww" | 
                              data.clean$bec.2050.simple == "IDF xm" | 
                              data.clean$bec.2050.simple == "IDF xh 2" | 
                              data.clean$bec.2050.simple == "IDF ww 1" | 
                              data.clean$bec.2050.simple == "IDF xc" | 
                              data.clean$bec.2050.simple == "IDF dk 1" | 
                              data.clean$bec.2050.simple == "IDF dk 3" | 
                              data.clean$bec.2050.simple == "IDF dc" | 
                              data.clean$bec.2050.simple == "IDF dk 2"] <- "IDF"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "IMA un" |
                              data.clean$bec.2050.simple == "IMA unp" ] <- "IMA"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "MH  mm 1" |
                              data.clean$bec.2050.simple == "MH  mm 2" |
                              data.clean$bec.2050.simple == "MH  mmp" |
                              data.clean$bec.2050.simple == "MH  unp" |
                              data.clean$bec.2050.simple == "MH  un"] <- "MH"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "MS  dc 2" |
                              data.clean$bec.2050.simple == "MS  dk 1" |
                              data.clean$bec.2050.simple == "MS  dk 2" |
                              data.clean$bec.2050.simple == "MS  un" |
                              data.clean$bec.2050.simple == "MS  xv" |
                              data.clean$bec.2050.simple == "MS  dm 2"] <- "MS"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "PP  dh 2" ] <- "PP"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "SBPSdc" |
                              data.clean$bec.2050.simple == "SBPSmc" |
                              data.clean$bec.2050.simple == "SBPSmk" |
                              data.clean$bec.2050.simple == "SBPSxc" ] <- "SBPS"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "SBS dk" |
                              data.clean$bec.2050.simple == "SBS dh 1" |
                              data.clean$bec.2050.simple == "SBS dw 1" | 
                              data.clean$bec.2050.simple == "SBS dw 3"  |
                              data.clean$bec.2050.simple == "SBS mc 1"  |
                              data.clean$bec.2050.simple == "SBS mc 2"  |
                              data.clean$bec.2050.simple == "SBS mc 3"  |
                              data.clean$bec.2050.simple == "SBS mh"  |
                              data.clean$bec.2050.simple == "SBS mk 1"  |
                              data.clean$bec.2050.simple == "SBS mk 2"  |
                              data.clean$bec.2050.simple == "SBS mm"  |
                              data.clean$bec.2050.simple == "SBS mw"  |
                              data.clean$bec.2050.simple == "SBS un"  |
                              data.clean$bec.2050.simple == "SBS vk"  |
                              data.clean$bec.2050.simple == "SBS wk 1"  |
                              data.clean$bec.2050.simple == "SBS wk 2"  |
                              data.clean$bec.2050.simple == "SBS wk 3"  |
                              data.clean$bec.2050.simple == "SBS wk 3a" |
                              data.clean$bec.2050.simple == "SBS dw 2"] <- "SBS"
data.clean$bec.2050.simple [data.clean$bec.2050.simple == "SWB mk"  |
                              data.clean$bec.2050.simple == "SWB mks"  |
                              data.clean$bec.2050.simple == "SWB un" |
                              data.clean$bec.2050.simple == "SWB uns" |
                              data.clean$bec.2050.simple == "SWB vk" |
                              data.clean$bec.2050.simple == "SWB dk"] <- "SWB"
data.clean$bec.2050.simple <- as.factor (data.clean$bec.2050.simple)

data.clean$bec.2080.simple <- as.character (data.clean$bec2080)
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "BG  xh 3" |
                              data.clean$bec.2080.simple == "BG  xw 2"] <- "BG"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "BAFAun" | 
                              data.clean$bec.2080.simple == "BAFAunp"] <- "BAFA"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "BWBSdk" | 
                              data.clean$bec.2080.simple == "BWBSmk" |
                              data.clean$bec.2080.simple == "BWBSmw" |
                              data.clean$bec.2080.simple == "BWBSwk 1" |  
                              data.clean$bec.2080.simple == "BWBSwk 2" |   
                              data.clean$bec.2080.simple == "BWBSwk 3" |   
                              data.clean$bec.2080.simple == "BWBSmw 1" |   
                              data.clean$bec.2080.simple == "BWBSmw 2" |   
                              data.clean$bec.2080.simple == "BWBSdk 2" |   
                              data.clean$bec.2080.simple == "BWBSdk 1" |   
                              data.clean$bec.2080.simple == "BWBSvk"] <- "BWBS"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "CDF mm"] <- "CDF"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "CMA un" |
                              data.clean$bec.2080.simple == "CMA unp"] <- "CMA"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "CWH ds 2" |
                              data.clean$bec.2080.simple == "CWH ms 2" |
                              data.clean$bec.2080.simple == "CWH vm 1" |
                              data.clean$bec.2080.simple == "CWH vm 2" |  
                              data.clean$bec.2080.simple == "CWH ws 1" | 
                              data.clean$bec.2080.simple == "CWH ws 2" | 
                              data.clean$bec.2080.simple == "CWH ms 1" | 
                              data.clean$bec.2080.simple == "CWH ds 1" | 
                              data.clean$bec.2080.simple == "CWH wm" | 
                              data.clean$bec.2080.simple == "CWH vm" | 
                              data.clean$bec.2080.simple == "CWH dm"] <- "CWH"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "ESSFdc 1" |
                              data.clean$bec.2080.simple == "ESSFdc 3" |
                              data.clean$bec.2080.simple == "ESSFdk 1" |
                              data.clean$bec.2080.simple == "ESSFdk 2" |  
                              data.clean$bec.2080.simple == "ESSFdkp" | 
                              data.clean$bec.2080.simple == "ESSFdkw" | 
                              data.clean$bec.2080.simple == "ESSFmc"  |
                              data.clean$bec.2080.simple == "ESSFmcp"  |
                              data.clean$bec.2080.simple == "ESSFmh"  |
                              data.clean$bec.2080.simple == "ESSFmk"  |
                              data.clean$bec.2080.simple == "ESSFmkp"  |
                              data.clean$bec.2080.simple == "ESSFmm 1"  |
                              data.clean$bec.2080.simple == "ESSFmmp"  |
                              data.clean$bec.2080.simple == "ESSFmmw"  |
                              data.clean$bec.2080.simple == "ESSFmv 1"  |
                              data.clean$bec.2080.simple == "ESSFmv 2"  |
                              data.clean$bec.2080.simple == "ESSFmv 3"  |
                              data.clean$bec.2080.simple == "ESSFmv 4"  |
                              data.clean$bec.2080.simple == "ESSFmvp"  |
                              data.clean$bec.2080.simple == "ESSFmw"  |
                              data.clean$bec.2080.simple == "ESSFmwp"  |
                              data.clean$bec.2080.simple == "ESSFun"  |
                              data.clean$bec.2080.simple == "ESSFunp"  |
                              data.clean$bec.2080.simple == "ESSFvc"  |
                              data.clean$bec.2080.simple == "ESSFvcp"  |
                              data.clean$bec.2080.simple == "ESSFvcw"  |
                              data.clean$bec.2080.simple == "ESSFwc 2"  |
                              data.clean$bec.2080.simple == "ESSFwc 2w"  |
                              data.clean$bec.2080.simple == "ESSFwc 3"  |
                              data.clean$bec.2080.simple == "ESSFwc 4"  |
                              data.clean$bec.2080.simple == "ESSFwcp"  |
                              data.clean$bec.2080.simple == "ESSFwcw"  |
                              data.clean$bec.2080.simple == "ESSFwh 1"  |
                              data.clean$bec.2080.simple == "ESSFwh 2"  |
                              data.clean$bec.2080.simple == "ESSFwh 3"  |
                              data.clean$bec.2080.simple == "ESSFwk 1"  |
                              data.clean$bec.2080.simple == "ESSFwk 2"  |
                              data.clean$bec.2080.simple == "ESSFwm"  |
                              data.clean$bec.2080.simple == "ESSFwm 2"  |
                              data.clean$bec.2080.simple == "ESSFwm 3"  |
                              data.clean$bec.2080.simple == "ESSFwm 4"  |
                              data.clean$bec.2080.simple == "ESSFwmp"  |
                              data.clean$bec.2080.simple == "ESSFwmw"  |
                              data.clean$bec.2080.simple == "ESSFwv"  |
                              data.clean$bec.2080.simple == "ESSFwvp"  |
                              data.clean$bec.2080.simple == "ESSFxv 1"  |
                              data.clean$bec.2080.simple == "ESSFxvp" |
                              data.clean$bec.2080.simple == "ESSFdm" |
                              data.clean$bec.2080.simple == "ESSFwc 1" |
                              data.clean$bec.2080.simple == "ESSFmw 1" |
                              data.clean$bec.2080.simple == "ESSFdc 2"] <- "ESSF"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "ICH dk" |
                              data.clean$bec.2080.simple == "ICH dm" |
                              data.clean$bec.2080.simple == "ICH dw 1" |
                              data.clean$bec.2080.simple == "ICH dw 3" |  
                              data.clean$bec.2080.simple == "ICH dw 4" | 
                              data.clean$bec.2080.simple == "ICH mc 1" | 
                              data.clean$bec.2080.simple == "ICH mk 2"  |
                              data.clean$bec.2080.simple == "ICH mk 3"  |
                              data.clean$bec.2080.simple == "ICH mk 4"  |
                              data.clean$bec.2080.simple == "ICH mm"  |
                              data.clean$bec.2080.simple == "ICH mw 1"  |
                              data.clean$bec.2080.simple == "ICH mw 2"  |
                              data.clean$bec.2080.simple == "ICH mw 3"  |
                              data.clean$bec.2080.simple == "ICH mw 4"  |
                              data.clean$bec.2080.simple == "ICH mw 5"  |
                              data.clean$bec.2080.simple == "ICH vk 1"  |
                              data.clean$bec.2080.simple == "ICH vk 2"  |
                              data.clean$bec.2080.simple == "ICH wc"  |
                              data.clean$bec.2080.simple == "ICH wk 1"  |
                              data.clean$bec.2080.simple == "ICH wk 2"  |
                              data.clean$bec.2080.simple == "ICH wk 3"  |
                              data.clean$bec.2080.simple == "ICH wk 4"  |
                              data.clean$bec.2080.simple == "ICH xw"  |
                              data.clean$bec.2080.simple == "ICH xw  a" |
                              data.clean$bec.2080.simple == "ICH mc 2" |
                              data.clean$bec.2080.simple == "ICH mk 1" |
                              data.clean$bec.2080.simple == "ICH vc"] <- "ICH"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "IDF dk 4" |
                              data.clean$bec.2080.simple == "IDF dm 2" |
                              data.clean$bec.2080.simple == "IDF dw" |
                              data.clean$bec.2080.simple == "IDF mw 1" |  
                              data.clean$bec.2080.simple == "IDF mw 2" | 
                              data.clean$bec.2080.simple == "IDF ww" | 
                              data.clean$bec.2080.simple == "IDF xm" | 
                              data.clean$bec.2080.simple == "IDF xh 2" | 
                              data.clean$bec.2080.simple == "IDF ww 1" | 
                              data.clean$bec.2080.simple == "IDF xc" | 
                              data.clean$bec.2080.simple == "IDF dk 1" | 
                              data.clean$bec.2080.simple == "IDF dk 3" | 
                              data.clean$bec.2080.simple == "IDF dc" | 
                              data.clean$bec.2080.simple == "IDF dk 2" | 
                              data.clean$bec.2080.simple == "IDF xh 1"] <- "IDF"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "IMA un" |
                              data.clean$bec.2080.simple == "IMA unp" ] <- "IMA"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "MH  mm 1" |
                              data.clean$bec.2080.simple == "MH  mm 2" |
                              data.clean$bec.2080.simple == "MH  mmp" |
                              data.clean$bec.2080.simple == "MH  unp" |
                              data.clean$bec.2080.simple == "MH  un"] <- "MH"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "MS  dc 2" |
                              data.clean$bec.2080.simple == "MS  dk 1" |
                              data.clean$bec.2080.simple == "MS  dk 2" |
                              data.clean$bec.2080.simple == "MS  un" |
                              data.clean$bec.2080.simple == "MS  xv" |
                              data.clean$bec.2080.simple == "MS  dm 2" |
                              data.clean$bec.2080.simple == "MS  dm 1" |
                              data.clean$bec.2080.simple == "MS  xk 3"] <- "MS"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "PP  dh 2" |
                              data.clean$bec.2080.simple == "PP  xh 1" |
                              data.clean$bec.2080.simple == "PP  xh 2"] <- "PP"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "SBPSdc" |
                              data.clean$bec.2080.simple == "SBPSmc" |
                              data.clean$bec.2080.simple == "SBPSmk" |
                              data.clean$bec.2080.simple == "SBPSxc" ] <- "SBPS"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "SBS dk" |
                              data.clean$bec.2080.simple == "SBS dh 1" |
                              data.clean$bec.2080.simple == "SBS dw 1" | 
                              data.clean$bec.2080.simple == "SBS dw 3"  |
                              data.clean$bec.2080.simple == "SBS mc 1"  |
                              data.clean$bec.2080.simple == "SBS mc 2"  |
                              data.clean$bec.2080.simple == "SBS mc 3"  |
                              data.clean$bec.2080.simple == "SBS mh"  |
                              data.clean$bec.2080.simple == "SBS mk 1"  |
                              data.clean$bec.2080.simple == "SBS mk 2"  |
                              data.clean$bec.2080.simple == "SBS mm"  |
                              data.clean$bec.2080.simple == "SBS mw"  |
                              data.clean$bec.2080.simple == "SBS un"  |
                              data.clean$bec.2080.simple == "SBS vk"  |
                              data.clean$bec.2080.simple == "SBS wk 1"  |
                              data.clean$bec.2080.simple == "SBS wk 2"  |
                              data.clean$bec.2080.simple == "SBS wk 3"  |
                              data.clean$bec.2080.simple == "SBS wk 3a" |
                              data.clean$bec.2080.simple == "SBS dw 2"] <- "SBS"
data.clean$bec.2080.simple [data.clean$bec.2080.simple == "SWB mk"  |
                              data.clean$bec.2080.simple == "SWB mks"  |
                              data.clean$bec.2080.simple == "SWB un" |
                              data.clean$bec.2080.simple == "SWB uns" |
                              data.clean$bec.2080.simple == "SWB vk" |
                              data.clean$bec.2080.simple == "SWB dk"] <- "SWB"
data.clean$bec.2080.simple <- as.factor (data.clean$bec.2080.simple)
# select the used data only and the needed columns for each plot type
data.clean.used <- dplyr::filter (data.clean, pttype == 1)
data.temp <- dplyr::select (data.clean.used, herdname, tave.wt.1990, tave.wt.2010, tave.wt.2025, tave.wt.2055,
                            tave.wt.2085)
data.pas <- dplyr::select (data.clean.used, herdname, pas.wt.1990, pas.wt.2010, pas.wt.2025, pas.wt.2055,
                           pas.wt.2085)
data.nffd <- dplyr::select (data.clean.used, herdname, nffd.sp.1990, nffd.sp.2010, nffd.sp.2025, nffd.sp.2055, 
                            nffd.sp.2085)
data.bec <- dplyr::select (data.clean.used, herdname, bec.curr.simple, bec.2050.simple, bec.2080.simple)

# write.table (data.clean.used,
#              file = "C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\data_clean_used.csv",
#              sep = ",")
# need to put the data into long fromat for plotting
##############
# HERD LEVEL #
##############
data.plot.temp <- melt (data.temp, id.vars = "herdname")
names (data.plot.temp) [2] <- "year"
names (data.plot.temp) [3] <- "awt"
levels (data.plot.temp$year) <- sub ("tave.wt.1990", "1990", levels (data.plot.temp$year))
levels (data.plot.temp$year) <- sub ("tave.wt.2010", "2010", levels (data.plot.temp$year))
levels (data.plot.temp$year) <- sub ("tave.wt.2025", "2025", levels (data.plot.temp$year))
levels (data.plot.temp$year) <- sub ("tave.wt.2055", "2055", levels (data.plot.temp$year))
levels (data.plot.temp$year) <- sub ("tave.wt.2085", "2085", levels (data.plot.temp$year))

data.plot.pas <- melt (data.pas, id.vars = "herdname")
names (data.plot.pas) [2] <- "year"
names (data.plot.pas) [3] <- "pas"
levels (data.plot.pas$year) <- sub ("pas.wt.1990", "1990", levels (data.plot.pas$year))
levels (data.plot.pas$year) <- sub ("pas.wt.2010", "2010", levels (data.plot.pas$year))
levels (data.plot.pas$year) <- sub ("pas.wt.2025", "2025", levels (data.plot.pas$year))
levels (data.plot.pas$year) <- sub ("pas.wt.2055", "2055", levels (data.plot.pas$year))
levels (data.plot.pas$year) <- sub ("pas.wt.2085", "2085", levels (data.plot.pas$year))

data.plot.nffd <- melt (data.nffd, id.vars = "herdname")
names (data.plot.nffd) [2] <- "year"
names (data.plot.nffd) [3] <- "spffd"
levels (data.plot.nffd$year) <- sub ("nffd.sp.1990", "1990", levels (data.plot.nffd$year))
levels (data.plot.nffd$year) <- sub ("nffd.sp.2010", "2010", levels (data.plot.nffd$year))
levels (data.plot.nffd$year) <- sub ("nffd.sp.2025", "2025", levels (data.plot.nffd$year))
levels (data.plot.nffd$year) <- sub ("nffd.sp.2055", "2055", levels (data.plot.nffd$year))
levels (data.plot.nffd$year) <- sub ("nffd.sp.2085", "2085", levels (data.plot.nffd$year))

data.plot.bec <- melt (data.bec, id.vars = "herdname")
names (data.plot.bec) [2] <- "year"
names (data.plot.bec) [3] <- "bec"
levels (data.plot.bec$year) <- sub ("bec.curr.simple", "Current", levels (data.plot.bec$year))
levels (data.plot.bec$year) <- sub ("bec.2050.simple", "2050", levels (data.plot.bec$year))
levels (data.plot.bec$year) <- sub ("bec.2080.simple", "2080", levels (data.plot.bec$year))


##################
# ECOTYPE LEVEL #
################
data.temp.ecotype <- dplyr::select (data.clean.used, ecotype, tave.wt.1990, tave.wt.2010, tave.wt.2025, tave.wt.2055,
                            tave.wt.2085)
data.pas.ecotype <- dplyr::select (data.clean.used, ecotype, pas.wt.1990, pas.wt.2010, pas.wt.2025, pas.wt.2055,
                           pas.wt.2085)
data.nffd.ecotype <- dplyr::select (data.clean.used, ecotype, nffd.sp.1990, nffd.sp.2010, nffd.sp.2025, nffd.sp.2055, 
                            nffd.sp.2085)
data.bec.ecotype <- dplyr::select (data.clean.used, ecotype, bec.curr.simple, bec.2050.simple, bec.2080.simple)

data.plot.temp.ecotype <- melt (data.temp.ecotype, id.vars = "ecotype")
names (data.plot.temp.ecotype) [2] <- "year"
names (data.plot.temp.ecotype) [3] <- "awt"
levels (data.plot.temp.ecotype$year) <- sub ("tave.wt.1990", "1990", levels (data.plot.temp.ecotype$year))
levels (data.plot.temp.ecotype$year) <- sub ("tave.wt.2010", "2010", levels (data.plot.temp.ecotype$year))
levels (data.plot.temp.ecotype$year) <- sub ("tave.wt.2025", "2025", levels (data.plot.temp.ecotype$year))
levels (data.plot.temp.ecotype$year) <- sub ("tave.wt.2055", "2055", levels (data.plot.temp.ecotype$year))
levels (data.plot.temp.ecotype$year) <- sub ("tave.wt.2085", "2085", levels (data.plot.temp.ecotype$year))

data.plot.pas.ecotype <- melt (data.pas.ecotype, id.vars = "ecotype")
names (data.plot.pas.ecotype) [2] <- "year"
names (data.plot.pas.ecotype) [3] <- "pas"
levels (data.plot.pas.ecotype$year) <- sub ("pas.wt.1990", "1990", levels (data.plot.pas.ecotype$year))
levels (data.plot.pas.ecotype$year) <- sub ("pas.wt.2010", "2010", levels (data.plot.pas.ecotype$year))
levels (data.plot.pas.ecotype$year) <- sub ("pas.wt.2025", "2025", levels (data.plot.pas.ecotype$year))
levels (data.plot.pas.ecotype$year) <- sub ("pas.wt.2055", "2055", levels (data.plot.pas.ecotype$year))
levels (data.plot.pas.ecotype$year) <- sub ("pas.wt.2085", "2085", levels (data.plot.pas.ecotype$year))

data.plot.nffd.ecotype <- melt (data.nffd.ecotype, id.vars = "ecotype")
names (data.plot.nffd.ecotype) [2] <- "year"
names (data.plot.nffd.ecotype) [3] <- "spffd"
levels (data.plot.nffd.ecotype$year) <- sub ("nffd.sp.1990", "1990", levels (data.plot.nffd.ecotype$year))
levels (data.plot.nffd.ecotype$year) <- sub ("nffd.sp.2010", "2010", levels (data.plot.nffd.ecotype$year))
levels (data.plot.nffd.ecotype$year) <- sub ("nffd.sp.2025", "2025", levels (data.plot.nffd.ecotype$year))
levels (data.plot.nffd.ecotype$year) <- sub ("nffd.sp.2055", "2055", levels (data.plot.nffd.ecotype$year))
levels (data.plot.nffd.ecotype$year) <- sub ("nffd.sp.2085", "2085", levels (data.plot.nffd.ecotype$year))

data.plot.bec.ecotype <- melt (data.bec.ecotype, id.vars = "ecotype")
names (data.plot.bec.ecotype) [2] <- "year"
names (data.plot.bec.ecotype) [3] <- "bec"
levels (data.plot.bec.ecotype$year) <- sub ("bec.curr.simple", "Current", levels (data.plot.bec.ecotype$year))
levels (data.plot.bec.ecotype$year) <- sub ("bec.2050.simple", "2050", levels (data.plot.bec.ecotype$year))
levels (data.plot.bec.ecotype$year) <- sub ("bec.2080.simple", "2080", levels (data.plot.bec.ecotype$year))

#====================
# Data for BEC plots 
#===================
data.plot.bec.boreal <- dplyr::filter (data.plot.bec.ecotype, ecotype == "Boreal")
data.plot.bec.mount <- dplyr::filter (data.plot.bec.ecotype, ecotype == "Mountain")
data.plot.bec.north <- dplyr::filter (data.plot.bec.ecotype, ecotype == "Northern")

herd.list <- list (levels (data.clean$herdname))
data.plot.bec.atlin <- dplyr::filter (data.plot.bec, herdname == "Atlin")
data.plot.bec.barker <- dplyr::filter (data.plot.bec, herdname == "Barkerville")
data.plot.bec.burnt <- dplyr::filter (data.plot.bec, herdname == "Burnt Pine")
data.plot.bec.calendar <- dplyr::filter (data.plot.bec, herdname == "Calendar")
data.plot.bec.carcross <- dplyr::filter (data.plot.bec, herdname == "Carcross")
data.plot.bec.central.rock <- dplyr::filter (data.plot.bec, herdname == "Central Rockies")
data.plot.bec.charlotte <- dplyr::filter (data.plot.bec, herdname == "Charlotte Alplands")
data.plot.bec.chase <- dplyr::filter (data.plot.bec, herdname == "Chase")
data.plot.bec.chin <- dplyr::filter (data.plot.bec, herdname == "Chinchaga")
data.plot.bec.columbia <- dplyr::filter (data.plot.bec, herdname == "Columbia North")
data.plot.bec.columbia.s <- dplyr::filter (data.plot.bec, herdname == "Columbia South")
data.plot.bec.duncan <- dplyr::filter (data.plot.bec, herdname == "Duncan")
data.plot.bec.edziza <- dplyr::filter (data.plot.bec, herdname == "Edziza")
data.plot.bec.finlay <- dplyr::filter (data.plot.bec, herdname == "Finlay")
data.plot.bec.frisbey <- dplyr::filter (data.plot.bec, herdname == "Frisby-Boulder")
data.plot.bec.frog <- dplyr::filter (data.plot.bec, herdname == "Frog")
data.plot.bec.gataga <- dplyr::filter (data.plot.bec, herdname == "Gataga")
data.plot.bec.graham <- dplyr::filter (data.plot.bec, herdname == "Graham")
data.plot.bec.groundhog <- dplyr::filter (data.plot.bec, herdname == "Groundhog")
data.plot.bec.hart <- dplyr::filter (data.plot.bec, herdname == "Hart Ranges")
data.plot.bec.horse <- dplyr::filter (data.plot.bec, herdname == "Horseranch")
data.plot.bec.itcha <- dplyr::filter (data.plot.bec, herdname == "Itcha-Ilgachuz")
data.plot.bec.kennedy <- dplyr::filter (data.plot.bec, herdname == "Kennedy Siding")
data.plot.bec.level <- dplyr::filter (data.plot.bec, herdname == "Level Kawdy")
data.plot.bec.liard <- dplyr::filter (data.plot.bec, herdname == "Liard Plateau")
data.plot.bec.little <- dplyr::filter (data.plot.bec, herdname == "Little Rancheria")
data.plot.bec.maxhamish <- dplyr::filter (data.plot.bec, herdname == "Maxhamish")
data.plot.bec.moberly <- dplyr::filter (data.plot.bec, herdname == "Moberly")
data.plot.bec.monashee <- dplyr::filter (data.plot.bec, herdname == "Monashee")
data.plot.bec.muskwa <- dplyr::filter (data.plot.bec, herdname == "Muskwa")
data.plot.bec.nakusp <- dplyr::filter (data.plot.bec, herdname == "Nakusp")
data.plot.bec.narraway <- dplyr::filter (data.plot.bec, herdname == "Narraway")
data.plot.bec.narrow <- dplyr::filter (data.plot.bec, herdname == "Narrow Lake")
data.plot.bec.northcar <- dplyr::filter (data.plot.bec, herdname == "North Cariboo")
data.plot.bec.parker <- dplyr::filter (data.plot.bec, herdname == "Parker")
data.plot.bec.pink <- dplyr::filter (data.plot.bec, herdname == "Pink Mountain")
data.plot.bec.prophet <- dplyr::filter (data.plot.bec, herdname == "Prophet")
data.plot.bec.purcells <- dplyr::filter (data.plot.bec, herdname == "Purcells South")
data.plot.bec.quint <- dplyr::filter (data.plot.bec, herdname == "Quintette")
data.plot.bec.rabbit <- dplyr::filter (data.plot.bec, herdname == "Rabbit")
data.plot.bec.rainbows <- dplyr::filter (data.plot.bec, herdname == "Rainbows")
data.plot.bec.scott <- dplyr::filter (data.plot.bec, herdname == "Scott")
data.plot.bec.snake <- dplyr::filter (data.plot.bec, herdname == "Snake-Sahtaneh")
data.plot.bec.south.selk <- dplyr::filter (data.plot.bec, herdname == "South Selkirks")
data.plot.bec.spatsizi <- dplyr::filter (data.plot.bec, herdname == "Spatsizi")
data.plot.bec.swan <- dplyr::filter (data.plot.bec, herdname == "Swan Lake")
data.plot.bec.takla <- dplyr::filter (data.plot.bec, herdname == "Takla")
data.plot.bec.telkwa <- dplyr::filter (data.plot.bec, herdname == "Telkwa")
data.plot.bec.tsena <- dplyr::filter (data.plot.bec, herdname == "Tsenaglode")
data.plot.bec.tweeds <- dplyr::filter (data.plot.bec, herdname == "Tweedsmuir")
data.plot.bec.wells <- dplyr::filter (data.plot.bec, herdname == "Wells Gray")
data.plot.bec.wolverine <- dplyr::filter (data.plot.bec, herdname == "Wolverine")

#==================================
# BEC plots of current and future 
#==================================
###########
# ECOTYPE #         need to create a function and loop or lapply
###########
# Boreal
plot.bec.boreal <- ggplot (data.plot.bec.boreal, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Boreal Ecotype") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_boreal_20180509.tif", plot = plot.bec.boreal, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Mountain
plot.bec.mount <- ggplot (data.plot.bec.mount, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Mountain Ecotype") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_mountain_20180509.tif", plot = plot.bec.mount, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Northern
plot.bec.north <- ggplot (data.plot.bec.north, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Northern Ecotype") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_north_20180509.tif", plot = plot.bec.north, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

###############
# HERD LEVEL #         need to create a function and loop or lapply
#############
plot.bec.atlin <- ggplot (data.plot.bec.atlin, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Atlin") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_atlin_20180509.tif", plot = plot.bec.atlin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.barker <- ggplot (data.plot.bec.barker, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Barkerville") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_barker_20180509.tif", plot = plot.bec.barker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.burnt <- ggplot (data.plot.bec.burnt, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Burnt Pine") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_burnt_20180509.tif", plot = plot.bec.burnt, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.calendar <- ggplot (data.plot.bec.calendar, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Calendar") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_calendar_20180509.tif", plot = plot.bec.calendar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.carcross <- ggplot (data.plot.bec.carcross, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Carcross") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_carcross_20180509.tif", plot = plot.bec.carcross, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.central.rock <- ggplot (data.plot.bec.central.rock, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Central Rockies") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_central_rock_20180509.tif", plot = plot.bec.central.rock, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.charlotte <- ggplot (data.plot.bec.charlotte, aes (x = year)) +  
                                  geom_bar (aes (fill = bec), position = 'fill') +
                                  ggtitle ("Charlotte Alplands") +
                                  xlab ("Year") +
                                  ylab ("Proportion of range area") +
                                  scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_charlotte_20180509.tif", plot = plot.bec.charlotte, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.chase <- ggplot (data.plot.bec.chase, aes (x = year)) +  
                                geom_bar (aes (fill = bec), position = 'fill') +
                                ggtitle ("Chase") +
                                xlab ("Year") +
                                ylab ("Proportion of range area") +
                                scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_chase_20180509.tif", plot = plot.bec.chase, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.chin <- ggplot (data.plot.bec.chin, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Chinchaga") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_chin_20180509.tif", plot = plot.bec.chin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.columbia <- ggplot (data.plot.bec.columbia, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Columbia North") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_columbia_north_20180509.tif", plot = plot.bec.columbia, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.columbia.s <- ggplot (data.plot.bec.columbia.s, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Columbia South") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_columbia.s_south_20180509.tif", plot = plot.bec.columbia.s, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.duncan <- ggplot (data.plot.bec.duncan, aes (x = year)) +  
                                geom_bar (aes (fill = bec), position = 'fill') +
                                ggtitle ("Duncan") +
                                xlab ("Year") +
                                ylab ("Proportion of range area") +
                                scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_duncan_20180509.tif", plot = plot.bec.duncan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.edziza <- ggplot (data.plot.bec.edziza, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Edziza") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_edziza_20180509.tif", plot = plot.bec.edziza, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.finlay <- ggplot (data.plot.bec.finlay, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Finlay") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_finlay_20180509.tif", plot = plot.bec.finlay, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.frisbey <- ggplot (data.plot.bec.frisbey, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Frisby-Boulder") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_frisbey_20180509.tif", plot = plot.bec.frisbey, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.frog <- ggplot (data.plot.bec.frog, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Frog") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_frog_20180509.tif", plot = plot.bec.frog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.gataga <- ggplot (data.plot.bec.gataga, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Gataga") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_gataga_20180509.tif", plot = plot.bec.gataga, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.graham <- ggplot (data.plot.bec.graham, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Graham") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_graham_20180509.tif", plot = plot.bec.graham, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.groundhog <- ggplot (data.plot.bec.groundhog, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Groundhog") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_groundhog_20180509.tif", plot = plot.bec.groundhog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.hart <- ggplot (data.plot.bec.hart, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Hart Ranges") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_hart_20180509.tif", plot = plot.bec.hart, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.horse <- ggplot (data.plot.bec.horse, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Horseranch") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_horse_20180509.tif", plot = plot.bec.horse, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.itcha <- ggplot (data.plot.bec.itcha, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Itcha-Ilgachuz") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_itcha_20180509.tif", plot = plot.bec.itcha, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.kennedy <- ggplot (data.plot.bec.kennedy, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Kennedy Siding") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_kennedy_20180509.tif", plot = plot.bec.kennedy, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.level <- ggplot (data.plot.bec.level, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Level Kawdy") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_level_20180509.tif", plot = plot.bec.level, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.liard <- ggplot (data.plot.bec.liard, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Liard Plateau") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_liard_20180509.tif", plot = plot.bec.liard, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.little <- ggplot (data.plot.bec.little, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Little Rancheria") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_little_20180509.tif", plot = plot.bec.little, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.maxhamish <- ggplot (data.plot.bec.maxhamish, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Maxhamish") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_maxhamish_20180509.tif", plot = plot.bec.maxhamish, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.moberly <- ggplot (data.plot.bec.moberly, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Moberly") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_moberly_20180509.tif", plot = plot.bec.moberly, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.monashee <- ggplot (data.plot.bec.monashee, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Monashee") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_monashee_20180509.tif", plot = plot.bec.monashee, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.muskwa <- ggplot (data.plot.bec.muskwa, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Muskwa") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_muskwa_20180509.tif", plot = plot.bec.muskwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.nakusp <- ggplot (data.plot.bec.nakusp, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Nakusp") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_nakusp_20180509.tif", plot = plot.bec.nakusp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.narraway <- ggplot (data.plot.bec.narraway, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Narraway") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_narraway_20180509.tif", plot = plot.bec.narraway, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.narrow <- ggplot (data.plot.bec.narrow, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Narrow Lake") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_narrow_20180509.tif", plot = plot.bec.narrow, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.northcar <- ggplot (data.plot.bec.northcar, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("North Cariboo") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_northcar_20180509.tif", plot = plot.bec.northcar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.parker <- ggplot (data.plot.bec.parker, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Parker") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_parker_20180509.tif", plot = plot.bec.parker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.pink <- ggplot (data.plot.bec.pink, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Pink Mountain") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_pink_20180509.tif", plot = plot.bec.pink, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.prophet <- ggplot (data.plot.bec.prophet, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Prophet") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_prophet_20180509.tif", plot = plot.bec.prophet, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.purcells <- ggplot (data.plot.bec.purcells, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Purcells South") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_purcells_20180509.tif", plot = plot.bec.purcells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.quint <- ggplot (data.plot.bec.quint, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Quintette") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_quint_20180509.tif", plot = plot.bec.quint, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.rabbit <- ggplot (data.plot.bec.rabbit, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Rabbit") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_rabbit_20180509.tif", plot = plot.bec.rabbit, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.rainbows <- ggplot (data.plot.bec.rainbows, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Rainbows") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_rainbows_20180509.tif", plot = plot.bec.rainbows, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
lot.bec.scott <- ggplot (data.plot.bec.scott, aes (x = year)) +  
                                geom_bar (aes (fill = bec), position = 'fill') +
                                ggtitle ("Scott") +
                                xlab ("Year") +
                                ylab ("Proportion of range area") +
                                scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_scott_20180509.tif", plot = plot.bec.scott, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.snake <- ggplot (data.plot.bec.snake, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Snake-Sahtaneh") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_snake_20180509.tif", plot = plot.bec.snake, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.south.selk <- ggplot (data.plot.bec.south.selk, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("South Selkirks") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_south.selk_20180509.tif", plot = plot.bec.south.selk, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.spatsizi <- ggplot (data.plot.bec.spatsizi, aes (x = year)) +  
                                geom_bar (aes (fill = bec), position = 'fill') +
                                ggtitle ("Spatsizi") +
                                xlab ("Year") +
                                ylab ("Proportion of range area") +
                                scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_spatsizi_20180509.tif", plot = plot.bec.spatsizi, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.swan <- ggplot (data.plot.bec.swan, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Swan Lake") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_swan_20180509.tif", plot = plot.bec.swan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.takla <- ggplot (data.plot.bec.takla, aes (x = year)) +  
                              geom_bar (aes (fill = bec), position = 'fill') +
                              ggtitle ("Takla") +
                              xlab ("Year") +
                              ylab ("Proportion of range area") +
                              scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_takla_20180509.tif", plot = plot.bec.takla, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.telkwa <- ggplot (data.plot.bec.telkwa, aes (x = year)) +  
                          geom_bar (aes (fill = bec), position = 'fill') +
                          ggtitle ("Telkwa") +
                          xlab ("Year") +
                          ylab ("Proportion of range area") +
                          scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_telkwa_20180509.tif", plot = plot.bec.telkwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.tsena <- ggplot (data.plot.bec.tsena, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Tsenaglode") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_tsena_20180509.tif", plot = plot.bec.tsena, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.tweeds <- ggplot (data.plot.bec.tweeds, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Tweedsmuir") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_tweeds_20180509.tif", plot = plot.bec.tweeds, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.wells <- ggplot (data.plot.bec.wells, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Wells Gray") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_wells_20180509.tif", plot = plot.bec.wells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.bec.wolverine <- ggplot (data.plot.bec.wolverine, aes (x = year)) +  
                            geom_bar (aes (fill = bec), position = 'fill') +
                            ggtitle ("Wolverine") +
                            xlab ("Year") +
                            ylab ("Proportion of range area") +
                            scale_fill_discrete (name = "Bec Zone")
ggsave ("plot_bec_wolverine_20180509.tif", plot = plot.bec.wolverine, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

#===============================================
# Temperature plots of past, current and future 
#==============================================

#====================
# Data for Temp plots 
#===================
data.plot.temp.boreal <- dplyr::filter (data.plot.temp.ecotype, ecotype == "Boreal")
data.plot.temp.mount <- dplyr::filter (data.plot.temp.ecotype, ecotype == "Mountain")
data.plot.temp.north <- dplyr::filter (data.plot.temp.ecotype, ecotype == "Northern")
data.plot.temp.atlin <- dplyr::filter (data.plot.temp, herdname == "Atlin")
data.plot.temp.barker <- dplyr::filter (data.plot.temp, herdname == "Barkerville")
data.plot.temp.burnt <- dplyr::filter (data.plot.temp, herdname == "Burnt Pine")
data.plot.temp.calendar <- dplyr::filter (data.plot.temp, herdname == "Calendar")
data.plot.temp.carcross <- dplyr::filter (data.plot.temp, herdname == "Carcross")
data.plot.temp.central.rock <- dplyr::filter (data.plot.temp, herdname == "Central Rockies")
data.plot.temp.charlotte <- dplyr::filter (data.plot.temp, herdname == "Charlotte Alplands")
data.plot.temp.chase <- dplyr::filter (data.plot.temp, herdname == "Chase")
data.plot.temp.chin <- dplyr::filter (data.plot.temp, herdname == "Chinchaga")
data.plot.temp.columbia <- dplyr::filter (data.plot.temp, herdname == "Columbia North")
data.plot.temp.columbia.s <- dplyr::filter (data.plot.temp, herdname == "Columbia South")
data.plot.temp.duncan <- dplyr::filter (data.plot.temp, herdname == "Duncan")
data.plot.temp.edziza <- dplyr::filter (data.plot.temp, herdname == "Edziza")
data.plot.temp.finlay <- dplyr::filter (data.plot.temp, herdname == "Finlay")
data.plot.temp.frisbey <- dplyr::filter (data.plot.temp, herdname == "Frisby-Boulder")
data.plot.temp.frog <- dplyr::filter (data.plot.temp, herdname == "Frog")
data.plot.temp.gataga <- dplyr::filter (data.plot.temp, herdname == "Gataga")
data.plot.temp.graham <- dplyr::filter (data.plot.temp, herdname == "Graham")
data.plot.temp.groundhog <- dplyr::filter (data.plot.temp, herdname == "Groundhog")
data.plot.temp.hart <- dplyr::filter (data.plot.temp, herdname == "Hart Ranges")
data.plot.temp.horse <- dplyr::filter (data.plot.temp, herdname == "Horseranch")
data.plot.temp.itcha <- dplyr::filter (data.plot.temp, herdname == "Itcha-Ilgachuz")
data.plot.temp.kennedy <- dplyr::filter (data.plot.temp, herdname == "Kennedy Siding")
data.plot.temp.level <- dplyr::filter (data.plot.temp, herdname == "Level Kawdy")
data.plot.temp.liard <- dplyr::filter (data.plot.temp, herdname == "Liard Plateau")
data.plot.temp.little <- dplyr::filter (data.plot.temp, herdname == "Little Rancheria")
data.plot.temp.maxhamish <- dplyr::filter (data.plot.temp, herdname == "Maxhamish")
data.plot.temp.moberly <- dplyr::filter (data.plot.temp, herdname == "Moberly")
data.plot.temp.monashee <- dplyr::filter (data.plot.temp, herdname == "Monashee")
data.plot.temp.muskwa <- dplyr::filter (data.plot.temp, herdname == "Muskwa")
data.plot.temp.nakusp <- dplyr::filter (data.plot.temp, herdname == "Nakusp")
data.plot.temp.narraway <- dplyr::filter (data.plot.temp, herdname == "Narraway")
data.plot.temp.narrow <- dplyr::filter (data.plot.temp, herdname == "Narrow Lake")
data.plot.temp.northcar <- dplyr::filter (data.plot.temp, herdname == "North Cariboo")
data.plot.temp.parker <- dplyr::filter (data.plot.temp, herdname == "Parker")
data.plot.temp.pink <- dplyr::filter (data.plot.temp, herdname == "Pink Mountain")
data.plot.temp.prophet <- dplyr::filter (data.plot.temp, herdname == "Prophet")
data.plot.temp.purcells <- dplyr::filter (data.plot.temp, herdname == "Purcells South")
data.plot.temp.quint <- dplyr::filter (data.plot.temp, herdname == "Quintette")
data.plot.temp.rabbit <- dplyr::filter (data.plot.temp, herdname == "Rabbit")
data.plot.temp.rainbows <- dplyr::filter (data.plot.temp, herdname == "Rainbows")
data.plot.temp.scott <- dplyr::filter (data.plot.temp, herdname == "Scott")
data.plot.temp.snake <- dplyr::filter (data.plot.temp, herdname == "Snake-Sahtaneh")
data.plot.temp.south.selk <- dplyr::filter (data.plot.temp, herdname == "South Selkirks")
data.plot.temp.spatsizi <- dplyr::filter (data.plot.temp, herdname == "Spatsizi")
data.plot.temp.swan <- dplyr::filter (data.plot.temp, herdname == "Swan Lake")
data.plot.temp.takla <- dplyr::filter (data.plot.temp, herdname == "Takla")
data.plot.temp.telkwa <- dplyr::filter (data.plot.temp, herdname == "Telkwa")
data.plot.temp.tsena <- dplyr::filter (data.plot.temp, herdname == "Tsenaglode")
data.plot.temp.tweeds <- dplyr::filter (data.plot.temp, herdname == "Tweedsmuir")
data.plot.temp.wells <- dplyr::filter (data.plot.temp, herdname == "Wells Gray")
data.plot.temp.wolverine <- dplyr::filter (data.plot.temp, herdname == "Wolverine")

###########
# ECOTYPE # 
###########
# Boreal
plot.temp.boreal <- ggplot (data.plot.temp.boreal, aes (year,awt)) +  
                             geom_boxplot () +
                             ggtitle ("Boreal Ecotype") +
                             xlab ("Year") +
                             ylab ("Average Winter Temperature") + 
                             theme_bw ()
ggsave ("plot_temp_boreal_20180510.tif", plot = plot.temp.boreal, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Mountain
plot.temp.mount <- ggplot (data.plot.temp.mount, aes (year,awt)) +  
                            geom_boxplot () +
                            ggtitle ("Mountain Ecotype") +
                            xlab ("Year") +
                            ylab ("Average Winter Temperature") + 
                            theme_bw ()
ggsave ("plot_temp_mountain_20180510.tif", plot = plot.temp.mount, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Northern
plot.temp.north <- ggplot (data.plot.temp.north, aes (year,awt)) +  
                            geom_boxplot () +
                            ggtitle ("Northern Ecotype") +
                            xlab ("Year") +
                            ylab ("Average Winter Temperature") + 
                            theme_bw ()
ggsave ("plot_temp_northern_20180510.tif", plot = plot.temp.north, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

###############
# HERD LEVEL #         
#############
plot.temp.atlin <- ggplot (data.plot.temp.atlin, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Atlin") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_atlin_20180510.tif", plot = plot.temp.atlin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.barker <- ggplot (data.plot.temp.barker, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Barkerville") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_barker_20180510.tif", plot = plot.temp.barker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.burnt <- ggplot (data.plot.temp.burnt, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Burnt Pine") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_burnt_20180510.tif", plot = plot.temp.burnt, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.calendar <- ggplot (data.plot.temp.calendar, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Calendar") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_calendar_20180510.tif", plot = plot.temp.calendar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.carcross <- ggplot (data.plot.temp.carcross, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Carcross") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_carcross_20180510.tif", plot = plot.temp.carcross, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.central.rock <- ggplot (data.plot.temp.central.rock, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Central Rockies") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_central_rock_20180510.tif", plot = plot.temp.central.rock, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.charlotte <- ggplot (data.plot.temp.charlotte, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Charlotte Alplands") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_charlotte_20180510.tif", plot = plot.temp.charlotte, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.chase <- ggplot (data.plot.temp.chase, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Chase") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_chase_20180510.tif", plot = plot.temp.chase, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.chin <- ggplot (data.plot.temp.chin, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Chinchaga") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_chin_20180510.tif", plot = plot.temp.chin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.columbia <- ggplot (data.plot.temp.columbia, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Columbia North") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_columbia_north_20180510.tif", plot = plot.temp.columbia, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.columbia.s <- ggplot (data.plot.temp.columbia.s, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Columbia South") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_columbia.s_south_20180510.tif", plot = plot.temp.columbia.s, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.duncan <- ggplot (data.plot.temp.duncan, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Duncan") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_duncan_20180510.tif", plot = plot.temp.duncan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.edziza <- ggplot (data.plot.temp.edziza, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Edziza") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_edziza_20180510.tif", plot = plot.temp.edziza, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.finlay <- ggplot (data.plot.temp.finlay, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Finlay") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_finlay_20180510.tif", plot = plot.temp.finlay, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.frisbey <- ggplot (data.plot.temp.frisbey, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Frisby-Boulder") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_frisbey_20180510.tif", plot = plot.temp.frisbey, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.frog <- ggplot (data.plot.temp.frog, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Frog") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_frog_20180510.tif", plot = plot.temp.frog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.gataga <- ggplot (data.plot.temp.gataga, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Gataga") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_gataga_20180510.tif", plot = plot.temp.gataga, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.graham <- ggplot (data.plot.temp.graham, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Graham") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_graham_20180510.tif", plot = plot.temp.graham, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.groundhog <- ggplot (data.plot.temp.groundhog, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Groundhog") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_groundhog_20180510.tif", plot = plot.temp.groundhog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.hart <- ggplot (data.plot.temp.hart, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Hart Ranges") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_hart_20180510.tif", plot = plot.temp.hart, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.horse <- ggplot (data.plot.temp.horse, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Horseranch") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_horse_20180510.tif", plot = plot.temp.horse, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.itcha <- ggplot (data.plot.temp.itcha, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Itcha-Ilgachuz") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_itcha_20180510.tif", plot = plot.temp.itcha, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.kennedy <- ggplot (data.plot.temp.kennedy, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Kennedy Siding") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_kennedy_20180510.tif", plot = plot.temp.kennedy, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.level <- ggplot (data.plot.temp.level, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Level Kawdy") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_level_20180510.tif", plot = plot.temp.level, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.liard <- ggplot (data.plot.temp.liard, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Liard Plateau") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_liard_20180510.tif", plot = plot.temp.liard, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.little <- ggplot (data.plot.temp.little, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Little Rancheria") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_little_20180510.tif", plot = plot.temp.little, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.maxhamish <- ggplot (data.plot.temp.maxhamish, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Maxhamish") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_maxhamish_20180510.tif", plot = plot.temp.maxhamish, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.moberly <- ggplot (data.plot.temp.moberly, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Moberly") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_moberly_20180510.tif", plot = plot.temp.moberly, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.monashee <- ggplot (data.plot.temp.monashee, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Monashee") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_monashee_20180510.tif", plot = plot.temp.monashee, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.muskwa <- ggplot (data.plot.temp.muskwa, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Muskwa") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_muskwa_20180510.tif", plot = plot.temp.muskwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.nakusp <- ggplot (data.plot.temp.nakusp, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Nakusp") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_nakusp_20180510.tif", plot = plot.temp.nakusp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.narraway <- ggplot (data.plot.temp.narraway, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Narraway") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_narraway_20180510.tif", plot = plot.temp.narraway, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.narrow <- ggplot (data.plot.temp.narrow, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Narrow Lake") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_narrow_20180510.tif", plot = plot.temp.narrow, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.northcar <- ggplot (data.plot.temp.northcar, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("North Cariboo") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_northcar_20180510.tif", plot = plot.temp.northcar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.parker <- ggplot (data.plot.temp.parker, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Parker") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_parker_20180510.tif", plot = plot.temp.parker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.pink <- ggplot (data.plot.temp.pink, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Pink Mountain") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_pink_20180510.tif", plot = plot.temp.pink, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.prophet <- ggplot (data.plot.temp.prophet, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Prophet") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_prophet_20180510.tif", plot = plot.temp.prophet, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.purcells <- ggplot (data.plot.temp.purcells, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Purcells South") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_purcells_20180510.tif", plot = plot.temp.purcells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.quint <- ggplot (data.plot.temp.quint, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Quintette") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_quint_20180510.tif", plot = plot.temp.quint, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.rabbit <- ggplot (data.plot.temp.rabbit, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Rabbit") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_rabbit_20180510.tif", plot = plot.temp.rabbit, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.rainbows <- ggplot (data.plot.temp.rainbows, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Rainbows") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_rainbows_20180510.tif", plot = plot.temp.rainbows, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.scott <- ggplot (data.plot.temp.scott, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Scott") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_scott_20180510.tif", plot = plot.temp.scott, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.snake <- ggplot (data.plot.temp.snake, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Snake-Sahtaneh") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_snake_20180510.tif", plot = plot.temp.snake, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.south.selk <- ggplot (data.plot.temp.south.selk, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("South Selkirks") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_south.selk_20180510.tif", plot = plot.temp.south.selk, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.spatsizi <- ggplot (data.plot.temp.spatsizi, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Spatsizi") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_spatsizi_20180510.tif", plot = plot.temp.spatsizi, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.swan <- ggplot (data.plot.temp.swan, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Swan Lake") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_swan_20180510.tif", plot = plot.temp.swan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.takla <- ggplot (data.plot.temp.takla, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Takla") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_takla_20180510.tif", plot = plot.temp.takla, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.telkwa <- ggplot (data.plot.temp.telkwa, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Telkwa") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_telkwa_20180510.tif", plot = plot.temp.telkwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.tsena <- ggplot (data.plot.temp.tsena, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Tsenaglode") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_tsena_20180510.tif", plot = plot.temp.tsena, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.tweeds <- ggplot (data.plot.temp.tweeds, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Tweedsmuir") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_tweeds_20180510.tif", plot = plot.temp.tweeds, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.wells <- ggplot (data.plot.temp.wells, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Wells Gray") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_wells_20180510.tif", plot = plot.temp.wells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.temp.wolverine <- ggplot (data.plot.temp.wolverine, aes (year, awt)) +  
  geom_boxplot () +
  ggtitle ("Wolverine") +
  xlab ("Year") +
  ylab ("Average Winter Temperature") +
  theme_bw ()
ggsave ("plot_temp_wolverine_20180510.tif", plot = plot.temp.wolverine, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

#===============================================================
# Precipitation as snow (PAS) plots of past, current and future 
#==============================================================
data.plot.pas.boreal <- dplyr::filter (data.plot.pas.ecotype, ecotype == "Boreal")
data.plot.pas.mount <- dplyr::filter (data.plot.pas.ecotype, ecotype == "Mountain")
data.plot.pas.north <- dplyr::filter (data.plot.pas.ecotype, ecotype == "Northern")
data.plot.pas.atlin <- dplyr::filter (data.plot.pas, herdname == "Atlin")
data.plot.pas.barker <- dplyr::filter (data.plot.pas, herdname == "Barkerville")
data.plot.pas.burnt <- dplyr::filter (data.plot.pas, herdname == "Burnt Pine")
data.plot.pas.calendar <- dplyr::filter (data.plot.pas, herdname == "Calendar")
data.plot.pas.carcross <- dplyr::filter (data.plot.pas, herdname == "Carcross")
data.plot.pas.central.rock <- dplyr::filter (data.plot.pas, herdname == "Central Rockies")
data.plot.pas.charlotte <- dplyr::filter (data.plot.pas, herdname == "Charlotte Alplands")
data.plot.pas.chase <- dplyr::filter (data.plot.pas, herdname == "Chase")
data.plot.pas.chin <- dplyr::filter (data.plot.pas, herdname == "Chinchaga")
data.plot.pas.columbia <- dplyr::filter (data.plot.pas, herdname == "Columbia North")
data.plot.pas.columbia.s <- dplyr::filter (data.plot.pas, herdname == "Columbia South")
data.plot.pas.duncan <- dplyr::filter (data.plot.pas, herdname == "Duncan")
data.plot.pas.edziza <- dplyr::filter (data.plot.pas, herdname == "Edziza")
data.plot.pas.finlay <- dplyr::filter (data.plot.pas, herdname == "Finlay")
data.plot.pas.frisbey <- dplyr::filter (data.plot.pas, herdname == "Frisby-Boulder")
data.plot.pas.frog <- dplyr::filter (data.plot.pas, herdname == "Frog")
data.plot.pas.gataga <- dplyr::filter (data.plot.pas, herdname == "Gataga")
data.plot.pas.graham <- dplyr::filter (data.plot.pas, herdname == "Graham")
data.plot.pas.groundhog <- dplyr::filter (data.plot.pas, herdname == "Groundhog")
data.plot.pas.hart <- dplyr::filter (data.plot.pas, herdname == "Hart Ranges")
data.plot.pas.horse <- dplyr::filter (data.plot.pas, herdname == "Horseranch")
data.plot.pas.itcha <- dplyr::filter (data.plot.pas, herdname == "Itcha-Ilgachuz")
data.plot.pas.kennedy <- dplyr::filter (data.plot.pas, herdname == "Kennedy Siding")
data.plot.pas.level <- dplyr::filter (data.plot.pas, herdname == "Level Kawdy")
data.plot.pas.liard <- dplyr::filter (data.plot.pas, herdname == "Liard Plateau")
data.plot.pas.little <- dplyr::filter (data.plot.pas, herdname == "Little Rancheria")
data.plot.pas.maxhamish <- dplyr::filter (data.plot.pas, herdname == "Maxhamish")
data.plot.pas.moberly <- dplyr::filter (data.plot.pas, herdname == "Moberly")
data.plot.pas.monashee <- dplyr::filter (data.plot.pas, herdname == "Monashee")
data.plot.pas.muskwa <- dplyr::filter (data.plot.pas, herdname == "Muskwa")
data.plot.pas.nakusp <- dplyr::filter (data.plot.pas, herdname == "Nakusp")
data.plot.pas.narraway <- dplyr::filter (data.plot.pas, herdname == "Narraway")
data.plot.pas.narrow <- dplyr::filter (data.plot.pas, herdname == "Narrow Lake")
data.plot.pas.northcar <- dplyr::filter (data.plot.pas, herdname == "North Cariboo")
data.plot.pas.parker <- dplyr::filter (data.plot.pas, herdname == "Parker")
data.plot.pas.pink <- dplyr::filter (data.plot.pas, herdname == "Pink Mountain")
data.plot.pas.prophet <- dplyr::filter (data.plot.pas, herdname == "Prophet")
data.plot.pas.purcells <- dplyr::filter (data.plot.pas, herdname == "Purcells South")
data.plot.pas.quint <- dplyr::filter (data.plot.pas, herdname == "Quintette")
data.plot.pas.rabbit <- dplyr::filter (data.plot.pas, herdname == "Rabbit")
data.plot.pas.rainbows <- dplyr::filter (data.plot.pas, herdname == "Rainbows")
data.plot.pas.scott <- dplyr::filter (data.plot.pas, herdname == "Scott")
data.plot.pas.snake <- dplyr::filter (data.plot.pas, herdname == "Snake-Sahtaneh")
data.plot.pas.south.selk <- dplyr::filter (data.plot.pas, herdname == "South Selkirks")
data.plot.pas.spatsizi <- dplyr::filter (data.plot.pas, herdname == "Spatsizi")
data.plot.pas.swan <- dplyr::filter (data.plot.pas, herdname == "Swan Lake")
data.plot.pas.takla <- dplyr::filter (data.plot.pas, herdname == "Takla")
data.plot.pas.telkwa <- dplyr::filter (data.plot.pas, herdname == "Telkwa")
data.plot.pas.tsena <- dplyr::filter (data.plot.pas, herdname == "Tsenaglode")
data.plot.pas.tweeds <- dplyr::filter (data.plot.pas, herdname == "Tweedsmuir")
data.plot.pas.wells <- dplyr::filter (data.plot.pas, herdname == "Wells Gray")
data.plot.pas.wolverine <- dplyr::filter (data.plot.pas, herdname == "Wolverine")

###########
# ECOTYPE # 
###########
# Boreal
plot.pas.boreal <- ggplot (data.plot.pas.boreal, aes (year,pas)) +  
  geom_boxplot () +
  ggtitle ("Boreal Ecotype") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") + 
  theme_bw ()
ggsave ("plot_pas_boreal_20180510.tif", plot = plot.pas.boreal, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Mountain
plot.pas.mount <- ggplot (data.plot.pas.mount, aes (year,pas)) +  
  geom_boxplot () +
  ggtitle ("Mountain Ecotype") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") + 
  theme_bw ()
ggsave ("plot_pas_mountain_20180510.tif", plot = plot.pas.mount, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Northern
plot.pas.north <- ggplot (data.plot.pas.north, aes (year,pas)) +  
  geom_boxplot () +
  ggtitle ("Northern Ecotype") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") + 
  theme_bw ()
ggsave ("plot_pas_northern_20180510.tif", plot = plot.pas.north, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

###############
# HERD LEVEL #         
#############
plot.pas.atlin <- ggplot (data.plot.pas.atlin, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Atlin") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_atlin_20180510.tif", plot = plot.pas.atlin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.barker <- ggplot (data.plot.pas.barker, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Barkerville") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_barker_20180510.tif", plot = plot.pas.barker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.burnt <- ggplot (data.plot.pas.burnt, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Burnt Pine") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_burnt_20180510.tif", plot = plot.pas.burnt, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.calendar <- ggplot (data.plot.pas.calendar, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Calendar") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_calendar_20180510.tif", plot = plot.pas.calendar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.carcross <- ggplot (data.plot.pas.carcross, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Carcross") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_carcross_20180510.tif", plot = plot.pas.carcross, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.central.rock <- ggplot (data.plot.pas.central.rock, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Central Rockies") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_central_rock_20180510.tif", plot = plot.pas.central.rock, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.charlotte <- ggplot (data.plot.pas.charlotte, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Charlotte Alplands") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_charlotte_20180510.tif", plot = plot.pas.charlotte, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.chase <- ggplot (data.plot.pas.chase, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Chase") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_chase_20180510.tif", plot = plot.pas.chase, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.chin <- ggplot (data.plot.pas.chin, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Chinchaga") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_chin_20180510.tif", plot = plot.pas.chin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.columbia <- ggplot (data.plot.pas.columbia, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Columbia North") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_columbia_north_20180510.tif", plot = plot.pas.columbia, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.columbia.s <- ggplot (data.plot.pas.columbia.s, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Columbia South") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_columbia.s_south_20180510.tif", plot = plot.pas.columbia.s, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.duncan <- ggplot (data.plot.pas.duncan, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Duncan") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_duncan_20180510.tif", plot = plot.pas.duncan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.edziza <- ggplot (data.plot.pas.edziza, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Edziza") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_edziza_20180510.tif", plot = plot.pas.edziza, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.finlay <- ggplot (data.plot.pas.finlay, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Finlay") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_finlay_20180510.tif", plot = plot.pas.finlay, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.frisbey <- ggplot (data.plot.pas.frisbey, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Frisby-Boulder") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_frisbey_20180510.tif", plot = plot.pas.frisbey, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.frog <- ggplot (data.plot.pas.frog, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Frog") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_frog_20180510.tif", plot = plot.pas.frog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.gataga <- ggplot (data.plot.pas.gataga, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Gataga") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_gataga_20180510.tif", plot = plot.pas.gataga, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.graham <- ggplot (data.plot.pas.graham, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Graham") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_graham_20180510.tif", plot = plot.pas.graham, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.groundhog <- ggplot (data.plot.pas.groundhog, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Groundhog") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_groundhog_20180510.tif", plot = plot.pas.groundhog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.hart <- ggplot (data.plot.pas.hart, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Hart Ranges") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_hart_20180510.tif", plot = plot.pas.hart, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.horse <- ggplot (data.plot.pas.horse, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Horseranch") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_horse_20180510.tif", plot = plot.pas.horse, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.itcha <- ggplot (data.plot.pas.itcha, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Itcha-Ilgachuz") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_itcha_20180510.tif", plot = plot.pas.itcha, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.kennedy <- ggplot (data.plot.pas.kennedy, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Kennedy Siding") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_kennedy_20180510.tif", plot = plot.pas.kennedy, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.level <- ggplot (data.plot.pas.level, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Level Kawdy") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_level_20180510.tif", plot = plot.pas.level, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.liard <- ggplot (data.plot.pas.liard, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Liard Plateau") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_liard_20180510.tif", plot = plot.pas.liard, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.little <- ggplot (data.plot.pas.little, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Little Rancheria") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_little_20180510.tif", plot = plot.pas.little, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.maxhamish <- ggplot (data.plot.pas.maxhamish, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Maxhamish") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_maxhamish_20180510.tif", plot = plot.pas.maxhamish, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.moberly <- ggplot (data.plot.pas.moberly, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Moberly") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_moberly_20180510.tif", plot = plot.pas.moberly, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.monashee <- ggplot (data.plot.pas.monashee, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Monashee") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_monashee_20180510.tif", plot = plot.pas.monashee, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.muskwa <- ggplot (data.plot.pas.muskwa, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Muskwa") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_muskwa_20180510.tif", plot = plot.pas.muskwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.nakusp <- ggplot (data.plot.pas.nakusp, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Nakusp") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_nakusp_20180510.tif", plot = plot.pas.nakusp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.narraway <- ggplot (data.plot.pas.narraway, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Narraway") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_narraway_20180510.tif", plot = plot.pas.narraway, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.narrow <- ggplot (data.plot.pas.narrow, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Narrow Lake") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_narrow_20180510.tif", plot = plot.pas.narrow, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.northcar <- ggplot (data.plot.pas.northcar, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("North Cariboo") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_northcar_20180510.tif", plot = plot.pas.northcar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.parker <- ggplot (data.plot.pas.parker, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Parker") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_parker_20180510.tif", plot = plot.pas.parker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.pink <- ggplot (data.plot.pas.pink, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Pink Mountain") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_pink_20180510.tif", plot = plot.pas.pink, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.prophet <- ggplot (data.plot.pas.prophet, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Prophet") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_prophet_20180510.tif", plot = plot.pas.prophet, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.purcells <- ggplot (data.plot.pas.purcells, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Purcells South") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_purcells_20180510.tif", plot = plot.pas.purcells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.quint <- ggplot (data.plot.pas.quint, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Quintette") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_quint_20180510.tif", plot = plot.pas.quint, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.rabbit <- ggplot (data.plot.pas.rabbit, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Rabbit") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_rabbit_20180510.tif", plot = plot.pas.rabbit, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.rainbows <- ggplot (data.plot.pas.rainbows, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Rainbows") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_rainbows_20180510.tif", plot = plot.pas.rainbows, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.scott <- ggplot (data.plot.pas.scott, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Scott") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_scott_20180510.tif", plot = plot.pas.scott, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.snake <- ggplot (data.plot.pas.snake, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Snake-Sahtaneh") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_snake_20180510.tif", plot = plot.pas.snake, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.south.selk <- ggplot (data.plot.pas.south.selk, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("South Selkirks") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_south.selk_20180510.tif", plot = plot.pas.south.selk, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.spatsizi <- ggplot (data.plot.pas.spatsizi, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Spatsizi") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_spatsizi_20180510.tif", plot = plot.pas.spatsizi, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.swan <- ggplot (data.plot.pas.swan, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Swan Lake") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_swan_20180510.tif", plot = plot.pas.swan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.takla <- ggplot (data.plot.pas.takla, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Takla") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_takla_20180510.tif", plot = plot.pas.takla, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.telkwa <- ggplot (data.plot.pas.telkwa, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Telkwa") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_telkwa_20180510.tif", plot = plot.pas.telkwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.tsena <- ggplot (data.plot.pas.tsena, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Tsenaglode") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_tsena_20180510.tif", plot = plot.pas.tsena, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.tweeds <- ggplot (data.plot.pas.tweeds, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Tweedsmuir") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_tweeds_20180510.tif", plot = plot.pas.tweeds, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.wells <- ggplot (data.plot.pas.wells, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Wells Gray") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_wells_20180510.tif", plot = plot.pas.wells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.pas.wolverine <- ggplot (data.plot.pas.wolverine, aes (year, pas)) +  
  geom_boxplot () +
  ggtitle ("Wolverine") +
  xlab ("Year") +
  ylab ("Precipitation as Snow") +
  theme_bw ()
ggsave ("plot_pas_wolverine_20180510.tif", plot = plot.pas.wolverine, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

#===============================================================
# Number of Spring Frost Free Days (nffd) plots of past, current and future 
#==============================================================
data.plot.nffd.boreal <- dplyr::filter (data.plot.nffd.ecotype, ecotype == "Boreal")
data.plot.nffd.mount <- dplyr::filter (data.plot.nffd.ecotype, ecotype == "Mountain")
data.plot.nffd.north <- dplyr::filter (data.plot.nffd.ecotype, ecotype == "Northern")
data.plot.nffd.atlin <- dplyr::filter (data.plot.nffd, herdname == "Atlin")
data.plot.nffd.barker <- dplyr::filter (data.plot.nffd, herdname == "Barkerville")
data.plot.nffd.burnt <- dplyr::filter (data.plot.nffd, herdname == "Burnt Pine")
data.plot.nffd.calendar <- dplyr::filter (data.plot.nffd, herdname == "Calendar")
data.plot.nffd.carcross <- dplyr::filter (data.plot.nffd, herdname == "Carcross")
data.plot.nffd.central.rock <- dplyr::filter (data.plot.nffd, herdname == "Central Rockies")
data.plot.nffd.charlotte <- dplyr::filter (data.plot.nffd, herdname == "Charlotte Alplands")
data.plot.nffd.chase <- dplyr::filter (data.plot.nffd, herdname == "Chase")
data.plot.nffd.chin <- dplyr::filter (data.plot.nffd, herdname == "Chinchaga")
data.plot.nffd.columbia <- dplyr::filter (data.plot.nffd, herdname == "Columbia North")
data.plot.nffd.columbia.s <- dplyr::filter (data.plot.nffd, herdname == "Columbia South")
data.plot.nffd.duncan <- dplyr::filter (data.plot.nffd, herdname == "Duncan")
data.plot.nffd.edziza <- dplyr::filter (data.plot.nffd, herdname == "Edziza")
data.plot.nffd.finlay <- dplyr::filter (data.plot.nffd, herdname == "Finlay")
data.plot.nffd.frisbey <- dplyr::filter (data.plot.nffd, herdname == "Frisby-Boulder")
data.plot.nffd.frog <- dplyr::filter (data.plot.nffd, herdname == "Frog")
data.plot.nffd.gataga <- dplyr::filter (data.plot.nffd, herdname == "Gataga")
data.plot.nffd.graham <- dplyr::filter (data.plot.nffd, herdname == "Graham")
data.plot.nffd.groundhog <- dplyr::filter (data.plot.nffd, herdname == "Groundhog")
data.plot.nffd.hart <- dplyr::filter (data.plot.nffd, herdname == "Hart Ranges")
data.plot.nffd.horse <- dplyr::filter (data.plot.nffd, herdname == "Horseranch")
data.plot.nffd.itcha <- dplyr::filter (data.plot.nffd, herdname == "Itcha-Ilgachuz")
data.plot.nffd.kennedy <- dplyr::filter (data.plot.nffd, herdname == "Kennedy Siding")
data.plot.nffd.level <- dplyr::filter (data.plot.nffd, herdname == "Level Kawdy")
data.plot.nffd.liard <- dplyr::filter (data.plot.nffd, herdname == "Liard Plateau")
data.plot.nffd.little <- dplyr::filter (data.plot.nffd, herdname == "Little Rancheria")
data.plot.nffd.maxhamish <- dplyr::filter (data.plot.nffd, herdname == "Maxhamish")
data.plot.nffd.moberly <- dplyr::filter (data.plot.nffd, herdname == "Moberly")
data.plot.nffd.monashee <- dplyr::filter (data.plot.nffd, herdname == "Monashee")
data.plot.nffd.muskwa <- dplyr::filter (data.plot.nffd, herdname == "Muskwa")
data.plot.nffd.nakusp <- dplyr::filter (data.plot.nffd, herdname == "Nakusp")
data.plot.nffd.narraway <- dplyr::filter (data.plot.nffd, herdname == "Narraway")
data.plot.nffd.narrow <- dplyr::filter (data.plot.nffd, herdname == "Narrow Lake")
data.plot.nffd.northcar <- dplyr::filter (data.plot.nffd, herdname == "North Cariboo")
data.plot.nffd.parker <- dplyr::filter (data.plot.nffd, herdname == "Parker")
data.plot.nffd.pink <- dplyr::filter (data.plot.nffd, herdname == "Pink Mountain")
data.plot.nffd.prophet <- dplyr::filter (data.plot.nffd, herdname == "Prophet")
data.plot.nffd.purcells <- dplyr::filter (data.plot.nffd, herdname == "Purcells South")
data.plot.nffd.quint <- dplyr::filter (data.plot.nffd, herdname == "Quintette")
data.plot.nffd.rabbit <- dplyr::filter (data.plot.nffd, herdname == "Rabbit")
data.plot.nffd.rainbows <- dplyr::filter (data.plot.nffd, herdname == "Rainbows")
data.plot.nffd.scott <- dplyr::filter (data.plot.nffd, herdname == "Scott")
data.plot.nffd.snake <- dplyr::filter (data.plot.nffd, herdname == "Snake-Sahtaneh")
data.plot.nffd.south.selk <- dplyr::filter (data.plot.nffd, herdname == "South Selkirks")
data.plot.nffd.spatsizi <- dplyr::filter (data.plot.nffd, herdname == "Spatsizi")
data.plot.nffd.swan <- dplyr::filter (data.plot.nffd, herdname == "Swan Lake")
data.plot.nffd.takla <- dplyr::filter (data.plot.nffd, herdname == "Takla")
data.plot.nffd.telkwa <- dplyr::filter (data.plot.nffd, herdname == "Telkwa")
data.plot.nffd.tsena <- dplyr::filter (data.plot.nffd, herdname == "Tsenaglode")
data.plot.nffd.tweeds <- dplyr::filter (data.plot.nffd, herdname == "Tweedsmuir")
data.plot.nffd.wells <- dplyr::filter (data.plot.nffd, herdname == "Wells Gray")
data.plot.nffd.wolverine <- dplyr::filter (data.plot.nffd, herdname == "Wolverine")

###########
# ECOTYPE # 
###########
# Boreal
plot.nffd.boreal <- ggplot (data.plot.nffd.boreal, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Boreal Ecotype") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") + 
  theme_bw ()
ggsave ("plot_nffd_boreal_20180510.tif", plot = plot.nffd.boreal, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Mountain
plot.nffd.mount <- ggplot (data.plot.nffd.mount, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Mountain Ecotype") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") + 
  theme_bw ()
ggsave ("plot_nffd_mountain_20180510.tif", plot = plot.nffd.mount, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

# Northern
plot.nffd.north <- ggplot (data.plot.nffd.north, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Northern Ecotype") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") + 
  theme_bw ()
ggsave ("plot_nffd_northern_20180510.tif", plot = plot.nffd.north, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

###############
# HERD LEVEL #         
#############
plot.nffd.atlin <- ggplot (data.plot.nffd.atlin, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Atlin") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_atlin_20180510.tif", plot = plot.nffd.atlin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.barker <- ggplot (data.plot.nffd.barker, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Barkerville") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_barker_20180510.tif", plot = plot.nffd.barker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.burnt <- ggplot (data.plot.nffd.burnt, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Burnt Pine") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_burnt_20180510.tif", plot = plot.nffd.burnt, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.calendar <- ggplot (data.plot.nffd.calendar, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Calendar") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_calendar_20180510.tif", plot = plot.nffd.calendar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.carcross <- ggplot (data.plot.nffd.carcross, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Carcross") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_carcross_20180510.tif", plot = plot.nffd.carcross, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.central.rock <- ggplot (data.plot.nffd.central.rock, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Central Rockies") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_central_rock_20180510.tif", plot = plot.nffd.central.rock, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.charlotte <- ggplot (data.plot.nffd.charlotte, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Charlotte Alplands") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_charlotte_20180510.tif", plot = plot.nffd.charlotte, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.chase <- ggplot (data.plot.nffd.chase, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Chase") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_chase_20180510.tif", plot = plot.nffd.chase, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.chin <- ggplot (data.plot.nffd.chin, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Chinchaga") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_chin_20180510.tif", plot = plot.nffd.chin, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.columbia <- ggplot (data.plot.nffd.columbia, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Columbia North") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_columbia_north_20180510.tif", plot = plot.nffd.columbia, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.columbia.s <- ggplot (data.plot.nffd.columbia.s, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Columbia South") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_columbia.s_south_20180510.tif", plot = plot.nffd.columbia.s, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.duncan <- ggplot (data.plot.nffd.duncan, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Duncan") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_duncan_20180510.tif", plot = plot.nffd.duncan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.edziza <- ggplot (data.plot.nffd.edziza, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Edziza") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_edziza_20180510.tif", plot = plot.nffd.edziza, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.finlay <- ggplot (data.plot.nffd.finlay, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Finlay") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_finlay_20180510.tif", plot = plot.nffd.finlay, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.frisbey <- ggplot (data.plot.nffd.frisbey, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Frisby-Boulder") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_frisbey_20180510.tif", plot = plot.nffd.frisbey, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.frog <- ggplot (data.plot.nffd.frog, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Frog") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_frog_20180510.tif", plot = plot.nffd.frog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.gataga <- ggplot (data.plot.nffd.gataga, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Gataga") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_gataga_20180510.tif", plot = plot.nffd.gataga, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.graham <- ggplot (data.plot.nffd.graham, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Graham") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_graham_20180510.tif", plot = plot.nffd.graham, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.groundhog <- ggplot (data.plot.nffd.groundhog, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Groundhog") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_groundhog_20180510.tif", plot = plot.nffd.groundhog, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.hart <- ggplot (data.plot.nffd.hart, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Hart Ranges") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_hart_20180510.tif", plot = plot.nffd.hart, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.horse <- ggplot (data.plot.nffd.horse, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Horseranch") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_horse_20180510.tif", plot = plot.nffd.horse, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.itcha <- ggplot (data.plot.nffd.itcha, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Itcha-Ilgachuz") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_itcha_20180510.tif", plot = plot.nffd.itcha, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.kennedy <- ggplot (data.plot.nffd.kennedy, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Kennedy Siding") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_kennedy_20180510.tif", plot = plot.nffd.kennedy, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.level <- ggplot (data.plot.nffd.level, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Level Kawdy") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_level_20180510.tif", plot = plot.nffd.level, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.liard <- ggplot (data.plot.nffd.liard, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Liard Plateau") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_liard_20180510.tif", plot = plot.nffd.liard, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.little <- ggplot (data.plot.nffd.little, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Little Rancheria") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_little_20180510.tif", plot = plot.nffd.little, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.maxhamish <- ggplot (data.plot.nffd.maxhamish, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Maxhamish") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_maxhamish_20180510.tif", plot = plot.nffd.maxhamish, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.moberly <- ggplot (data.plot.nffd.moberly, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Moberly") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_moberly_20180510.tif", plot = plot.nffd.moberly, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.monashee <- ggplot (data.plot.nffd.monashee, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Monashee") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_monashee_20180510.tif", plot = plot.nffd.monashee, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.muskwa <- ggplot (data.plot.nffd.muskwa, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Muskwa") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_muskwa_20180510.tif", plot = plot.nffd.muskwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.nakusp <- ggplot (data.plot.nffd.nakusp, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Nakusp") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_nakusp_20180510.tif", plot = plot.nffd.nakusp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.narraway <- ggplot (data.plot.nffd.narraway, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Narraway") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_narraway_20180510.tif", plot = plot.nffd.narraway, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.narrow <- ggplot (data.plot.nffd.narrow, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Narrow Lake") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_narrow_20180510.tif", plot = plot.nffd.narrow, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.northcar <- ggplot (data.plot.nffd.northcar, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("North Cariboo") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_northcar_20180510.tif", plot = plot.nffd.northcar, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.parker <- ggplot (data.plot.nffd.parker, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Parker") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_parker_20180510.tif", plot = plot.nffd.parker, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.pink <- ggplot (data.plot.nffd.pink, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Pink Mountain") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_pink_20180510.tif", plot = plot.nffd.pink, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.prophet <- ggplot (data.plot.nffd.prophet, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Prophet") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_prophet_20180510.tif", plot = plot.nffd.prophet, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.purcells <- ggplot (data.plot.nffd.purcells, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Purcells South") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_purcells_20180510.tif", plot = plot.nffd.purcells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.quint <- ggplot (data.plot.nffd.quint, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Quintette") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_quint_20180510.tif", plot = plot.nffd.quint, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.rabbit <- ggplot (data.plot.nffd.rabbit, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Rabbit") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_rabbit_20180510.tif", plot = plot.nffd.rabbit, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.rainbows <- ggplot (data.plot.nffd.rainbows, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Rainbows") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_rainbows_20180510.tif", plot = plot.nffd.rainbows, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.scott <- ggplot (data.plot.nffd.scott, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Scott") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_scott_20180510.tif", plot = plot.nffd.scott, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.snake <- ggplot (data.plot.nffd.snake, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Snake-Sahtaneh") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_snake_20180510.tif", plot = plot.nffd.snake, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.south.selk <- ggplot (data.plot.nffd.south.selk, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("South Selkirks") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_south.selk_20180510.tif", plot = plot.nffd.south.selk, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.spatsizi <- ggplot (data.plot.nffd.spatsizi, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Spatsizi") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_spatsizi_20180510.tif", plot = plot.nffd.spatsizi, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.swan <- ggplot (data.plot.nffd.swan, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Swan Lake") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_swan_20180510.tif", plot = plot.nffd.swan, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.takla <- ggplot (data.plot.nffd.takla, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Takla") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_takla_20180510.tif", plot = plot.nffd.takla, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.telkwa <- ggplot (data.plot.nffd.telkwa, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Telkwa") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_telkwa_20180510.tif", plot = plot.nffd.telkwa, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.tsena <- ggplot (data.plot.nffd.tsena, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Tsenaglode") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_tsena_20180510.tif", plot = plot.nffd.tsena, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.tweeds <- ggplot (data.plot.nffd.tweeds, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Tweedsmuir") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_tweeds_20180510.tif", plot = plot.nffd.tweeds, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.wells <- ggplot (data.plot.nffd.wells, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Wells Gray") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_wells_20180510.tif", plot = plot.nffd.wells, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
plot.nffd.wolverine <- ggplot (data.plot.nffd.wolverine, aes (year, spffd)) +  
  geom_boxplot () +
  ggtitle ("Wolverine") +
  xlab ("Year") +
  ylab ("Number of Spring Frost Free Days") +
  theme_bw ()
ggsave ("plot_nffd_wolverine_20180510.tif", plot = plot.nffd.wolverine, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

#===============================================
# Statistical tests of past, current and future 
#==============================================
table.tukey <- data.frame (matrix (ncol = 7, nrow = 0))
names (table.tukey) [1:7] <- c ("Ecotype", "Variable", "Years", "Difference", "Lower CI", "Upper CI", "p-value")
table.tukey [1:30, 1] <-  "Boreal"
table.tukey [31:60, 1] <-  "Mountain"
table.tukey [61:90, 1] <-  "Northern"
table.tukey [c (1:10, 31:40, 61:70), 2] <-  "Average Winter Temperature"
table.tukey [c (11:20, 41:50, 71:80), 2] <-  "Precipitation as Snow"
table.tukey [c (21:30, 51:60, 81:90), 2] <-  "Number of Spring Frost Free Days"
table.tukey [c (1, 11, 21, 31, 41, 51, 61, 71, 81), 3] <-  "2010-1990"
table.tukey [c (2, 12, 22, 32, 42, 52, 62, 72, 82), 3] <-  "2025-1990"
table.tukey [c (3, 13, 23, 33, 43, 53, 63, 73, 83), 3] <-  "2055-1990"
table.tukey [c (4, 14, 24, 34, 44, 54, 64, 74, 84), 3] <-  "2085-1990"
table.tukey [c (5, 15, 25, 35, 45, 55, 65, 75, 85), 3] <-  "2025-2010"
table.tukey [c (6, 16, 26, 36, 46, 56, 66, 76, 86), 3] <-  "2055-2010"
table.tukey [c (7, 17, 27, 37, 47, 57, 67, 77, 87), 3] <-  "2085-2010"
table.tukey [c (8, 18, 28, 38, 48, 58, 68, 78, 88), 3] <-  "2055-2025"
table.tukey [c (9, 19, 29, 39, 49, 59, 69, 79, 89), 3] <-  "2085-2025"
table.tukey [c (10, 20, 30, 40, 50, 60, 70, 80, 90), 3] <-  "2085-2055"

# Temperature ANOVAs
aov.temp.boreal <- aov (awt ~ year, data = data.plot.temp.boreal)
plot (aov.temp.boreal)
summary (aov.temp.boreal) # display Type I ANOVA table
drop1 (aov.temp.boreal, ~., test = "F")
table.tukey [1:10, 4:7] <- round (TukeyHSD (aov.temp.boreal)$year, 3)

aov.temp.mount <- aov (awt ~ year, data = data.plot.temp.mount)
plot (aov.temp.mount)
summary (aov.temp.mount) # display Type I ANOVA table
drop1 (aov.temp.mount, ~., test = "F") # display Type III ANOVA table
table.tukey [31:40, 4:7] <- round (TukeyHSD (aov.temp.mount)$year, 3)

aov.temp.north <- aov (awt ~ year, data = data.plot.temp.north)
plot (aov.temp.north)
summary (aov.temp.north) # display Type I ANOVA table
drop1 (aov.temp.north, ~., test = "F") # display Type III ANOVA table
table.tukey [61:70, 4:7] <- round (TukeyHSD (aov.temp.north)$year, 3)

# PAS ANOVAs
aov.pas.boreal <- aov (pas ~ year, data = data.plot.pas.boreal)
plot (aov.pas.boreal)
summary (aov.pas.boreal) # display Type I ANOVA table
drop1 (aov.pas.boreal, ~., test = "F")
table.tukey [11:20, 4:7] <- round (TukeyHSD (aov.pas.boreal)$year, 3)

aov.pas.mount <- aov (pas ~ year, data = data.plot.pas.mount)
plot (aov.pas.mount)
summary (aov.pas.mount) # display Type I ANOVA table
drop1 (aov.pas.mount, ~., test = "F") # display Type III ANOVA table
table.tukey [41:50, 4:7] <- round (TukeyHSD (aov.pas.mount)$year, 3)

aov.pas.north <- aov (pas ~ year, data = data.plot.pas.north)
plot (aov.pas.north)
summary (aov.pas.north) # display Type I ANOVA table
drop1 (aov.pas.north, ~., test = "F") # display Type III ANOVA table
table.tukey [71:80, 4:7] <- round (TukeyHSD (aov.pas.north)$year, 3)

# NFFD ANOVAs
aov.nffd.boreal <- aov (spffd ~ year, data = data.plot.nffd.boreal)
plot (aov.nffd.boreal)
summary (aov.nffd.boreal) # display Type I ANOVA table
drop1 (aov.nffd.boreal, ~., test = "F")
table.tukey [21:30, 4:7] <- round (TukeyHSD (aov.nffd.boreal)$year, 3)

aov.nffd.mount <- aov (spffd ~ year, data = data.plot.nffd.mount)
plot (aov.nffd.mount)
summary (aov.nffd.mount) # display Type I ANOVA table
drop1 (aov.nffd.mount, ~., test = "F") # display Type III ANOVA table
table.tukey [51:60, 4:7] <- round (TukeyHSD (aov.nffd.mount)$year, 3)

aov.nffd.north <- aov (spffd ~ year, data = data.plot.nffd.north)
plot (aov.nffd.north)
summary (aov.nffd.north) # display Type I ANOVA table
drop1 (aov.nffd.north, ~., test = "F") # display Type III ANOVA table
table.tukey [81:90, 4:7] <- round (TukeyHSD (aov.nffd.north)$year, 3)

write.table (table.tukey, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_tukey_climate.csv",
             sep = ",")
