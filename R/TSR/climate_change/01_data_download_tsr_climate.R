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
#  Script Name: 01_download_data_tsr_climate.R
#  Script Version: 1.0
#  Script Purpose: Download data for timber supply area scale climate summaries.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 16 July 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================

#=================================
# data directory and packages
#=================================
setwd ('C:\\Work\\tsr_climate\\data\\') # where you are puttign the data
require (downloader)

#########################
# MANUAL DATA DOWNLOADS #
#########################
# BEC zone climate projections; 2020s, 2050s and 2080s; downloaded 7 July 2018
# <http://www.climatewna.com/ClimateBC_Map.aspx>
# At top of map 'Òverlays' select from 'Climate Maps': 'BEC zone - currently mapped', 
# 'BEC zone - climate_2020s',  'BEC zone - climate_2050s', and 'BEC zone - climate_2080s'.
# Click 'Download Overlay raster files" after each selection
# C:\Work\tsr_climate\data\bec\

# unzip the files
unzip ("bec\\BEC_zone.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone.zip")

unzip ("bec\\BEC_zone_2020s.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone_2020s.zip")

unzip ("bec\\BEC_zone_2050s.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone_2050s.zip")

unzip ("bec\\BEC_zone_2080s.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone_2080s.zip")

# TSA and TFL Boundary data
# Need to copied form BCGW



###################################
# Data downloadable from websites #
###################################
