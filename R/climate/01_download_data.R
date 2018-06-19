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
#  Script Name: 01_download_data.R
#  Script Version: 1.0
#  Script Purpose: Download data for provincial caribou climate analysis.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 19 March 2018 (checked 25 May 2018)
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================
require (downloader)

# data directory
setwd ('C:\\Work\\caribou\\climate_analysis\\data\\')

#########################
# MANUAL DATA DOWNLOADS #
#########################

# Current BEC zone map (Version 10, August 31, 2016); downloaded 19 March 2018
# <https://catalogue.data.gov.bc.ca/dataset/biogeoclimatic-ecosystem-classification-bec-map>
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\bec\BEC_current

# BEC zone climate projections; 2020s, 2050s and 2080s; downloaded 19 March 2018
# <http://www.climatewna.com/ClimateBC_Map.aspx>
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\bec\BEC_zone_2020s
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\bec\BEC_zone_2050s
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\bec\BEC_zone_2080s
  
# caribou range boudnaries; downloaded 19 March 2018
# <https://catalogue.data.gov.bc.ca/dataset/caribou-herd-locations-for-bc>
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\caribou\caribou_herd

# digital road atlas data; downloaded 29 March 2018
# <https://catalogue.data.gov.bc.ca/dataset/digital-road-atlas-dra-demographic-partially-attributed-roads>
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\roads\DRA_DGTL_ROAD_ATLAS_DPAR_SP

# Oil and gas well/facility data; downloaded 29 March 2018
# <https://catalogue.data.gov.bc.ca/dataset/oil-and-gas-commission-well-facility-area-permits>
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\wells\OG_WELL_FACILITY_PERMIT_SP

# Cutblock data; downloaded 29 March 2018
# <https://catalogue.data.gov.bc.ca/dataset/harvested-areas-of-bc-consolidated-cutblocks->
# G:\!Workgrp\Analysts\tmuhly\Caribou\climate_analysis\data\cutblocks

# Integrated roads data from cumulative effects; copied June 18, 2018
# \\spatialfiles.bcgov\\work\\srm\\bcce\\shared\\data_library\roads\2017\BC_CE_IntegratedRoads_2017_v1_20170214.gdb
# layer = "integrated_roads"


###################################
# Data downloadable from websites #
###################################
# bc boundary; downloaded 19 March 2018
# available from federal government via https://open.canada.ca/data/dataset/bab06e04-e6d0-41f1-a595-6cff4d71bedf
download ("http://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/files-fichiers/gpr_000b11a_e.zip", 
          dest = "province\\border.zip", 
          mode = "wb")
unzip ("province\\border.zip", 
       exdir = "C:\\Work\\caribou\\climate_analysis\\data\\province")
file.remove ("province\\border.zip")

# VRI
download ("https://pub.data.gov.bc.ca/datasets/2ebb35d8-c82f-4a17-9c96-612ac3532d55/VEG_COMP_LYR_R1_POLY.gdb.zip",
          dest = "vri\\vri.zip",
          mode = "wb")
unzip ("vri\\vri.zip",
        exdir = "C:\\Work\\caribou\\climate_analysis\\data\\vri")
file.remove ("vri\\vri.zip")

# DEM; https://www2.gov.bc.ca/assets/gov/data/geographic/topography/250kgrid.pdf
list.dem <- list ("104n", "104o","104p", "94m", "94n", "94o", "94p", "94i", "94j", "94k", "94l", "104i", "104j",
                  "104k", "104g", "104h", "94e", "94f", "94g", "94h", "94a", "94b", "94c", "94d", "104a", "103p",
                  "93m", "93n", "93o", "93p", "93i", "93j", "93k", "93l", "103i", "93e", "93f", "93g", "93h", "83e",
                  "83c", "83d", "93a", "93b", "93c", "93d", "92n", "92o", "92p", "82m", "82n", "82o", "82j", "82k",
                  "82l", "82e", "82f", "82g")
for (i in list.dem) {
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "16_w.dem.zip"),
            dest = paste0 ("dem\\", i, "m16_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m16_w.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m16_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "16_e.dem.zip"),
            dest = paste0 ("dem\\", i, "m16_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m16_e.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m16_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "15_w.dem.zip"),
            dest = paste0 ("dem\\", i, "m15_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m15_w.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m15_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "15_e.dem.zip"),
            dest = paste0 ("dem\\", i, "m15_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m15_e.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m15_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "14_w.dem.zip"),
            dest = paste0 ("dem\\", i, "m14_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m14_w.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m14_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "14_e.dem.zip"),
            dest = paste0 ("dem\\", i, "m14_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m14_e.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m14_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "13_w.dem.zip"),
            dest = paste0 ("dem\\", i, "m13_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m13_w.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m13_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "13_e.dem.zip"),
            dest = paste0 ("dem\\", i, "m13_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m13_e.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m13_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "12_w.dem.zip"),
            dest = paste0 ("dem\\", i, "m12_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m12_w.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m12_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "12_e.dem.zip"),
            dest = paste0 ("dem\\", i, "m12_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("dem\\", i, "m12_e.dem.zip"), 
         exdir = "C:\\Work\\caribou\\climate_analysis\\data\\dem")
  file.remove (paste0 ("dem\\", i, "m12_e.dem.zip"))
  
  
  
  
  
  
  
  
  }








summary (roads.ce)



# current, past and future climate measure projections; downloaded 28 March 2018
# Reference: <http://climatebcdata.climatewna.com/#3._reference> # Wang, T., Hamann, A., Spittlehouse, D.L., Murdock, T., 2012. ClimateWNA - High-Resolution Spatial Climate Data for Western North America. Journal of Applied Meteorology and Climatology, 51: 16-29.
  download ("http://climatebcdata.climatewna.com/download/Normal_1961_1990MSY/Normal_1961_1990_seasonal.zip", 
            dest = "climate\\Normal_1961_1990_seasonal.zip", 
            mode = "wb")
unzip ("climate\\Normal_1961_1990_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\Normal_1961_1990_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/Normal_1981_2010MSY/Normal_1981_2010_seasonal.zip", 
          dest = "climate\\Normal_1981_2010_seasonal.zip", 
          mode = "wb")
unzip ("climate\\Normal_1981_2010_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\Normal_1981_2010_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/HadGEM2-ES_RCP45_2085MSY/HadGEM2-ES_RCP45_2085_seasonal.zip", 
          dest = "climate\\HadGEM2-ES_RCP45_2085_seasonal.zip", 
          mode = "wb")
unzip ("climate\\HadGEM2-ES_RCP45_2085_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\HadGEM2-ES_RCP45_2085_seasonal.zip")  

download ("http://climatebcdata.climatewna.com/download/HadGEM2-ES_RCP45_2055MSY/HadGEM2-ES_RCP45_2055_seasonal.zip", 
          dest = "climate\\HadGEM2-ES_RCP45_2055_seasonal.zip", 
          mode = "wb")
unzip ("climate\\HadGEM2-ES_RCP45_2055_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\HadGEM2-ES_RCP45_2055_seasonal.zip") 

download ("http://climatebcdata.climatewna.com/download/HadGEM2-ES_RCP45_2025MSY/HadGEM2-ES_RCP45_2025_seasonal.zip", 
          dest = "climate\HadGEM2-ES_RCP45_2025_seasonal.zip", 
          mode = "wb")
unzip ("climate\\HadGEM2-ES_RCP45_2025_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\HadGEM2-ES_RCP45_2025_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/CCSM4_RCP45_2085MSY/CCSM4_RCP45_2085_seasonal.zip", 
          dest = "climate\CCSM4_RCP45_2085_seasonal.zip", 
          mode = "wb")
unzip ("climate\\CCSM4_RCP45_2085_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\CCSM4_RCP45_2085_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/CCSM4_RCP45_2055MSY/CCSM4_RCP45_2055_seasonal.zip", 
          dest = "climate\CCSM4_RCP45_2055_seasonal.zip", 
          mode = "wb")
unzip ("climate\\CCSM4_RCP45_2055_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\CCSM4_RCP45_2055_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/CCSM4_RCP45_2025MSY/CCSM4_RCP45_2025_seasonal.zip", 
          dest = "climate\CCSM4_RCP45_2025_seasonal.zip", 
          mode = "wb")
unzip ("climate\\CCSM4_RCP45_2025_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\\CCSM4_RCP45_2025_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/CanESM2_RCP45_2085MSY/CanESM2_RCP45_2085_seasonal.zip", 
          dest = "climate\CanESM2_RCP45_2085_seasonal.zip", 
          mode = "wb")
unzip ("climate\CanESM2_RCP45_2085_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\CanESM2_RCP45_2085_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/CanESM2_RCP45_2055MSY/CanESM2_RCP45_2055_seasonal.zip", 
          dest = "climate\CanESM2_RCP45_2055_seasonal.zip", 
          mode = "wb")
unzip ("climate\CanESM2_RCP45_2055_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\CanESM2_RCP45_2055_seasonal.zip")

download ("http://climatebcdata.climatewna.com/download/CanESM2_RCP45_2025MSY/CanESM2_RCP45_2025_seasonal.zip", 
          dest = "climate\CanESM2_RCP45_2025_seasonal.zip", 
          mode = "wb")
unzip ("climate\CanESM2_RCP45_2025_seasonal.zip", 
       exdir = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\climate")
file.remove ("climate\CanESM2_RCP45_2025_seasonal.zip")

###########################
# Caribou telemetry data #
#########################
# BC OGRIS; README: <http://www.bcogris.ca/sites/default/files/bc-ogrisremb-telemetry-data-read-me-first-ver-3-dec17.pdf>
download ("http://www.bcogris.ca/sites/default/files/webexportcaribou.xlsx", 
          dest = "caribou\\\boreal_caribou_telemetry_2013_2018.xlsx", 
          mode = "wb")

# BCGW sensitive telemetry data
WHSE_WILDLIFE_INVENTORY.SPI_TELEMETRY_OBS_ALL_SP
SCIENTIFIC_NAME = 'Rangifer tarandus'
# C:\Work\caribou\climate_analysis\data\caribou\caribou_telemetry.gdb


