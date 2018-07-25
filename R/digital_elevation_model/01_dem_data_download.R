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
#  Script Name: 01_dem_data_download.R
#  Script Version: 1.0
#  Script Purpose: Download digital elevation model and put into postgres. 
#                   WARNING, the code is incomplete.  Use it to facilitate downloading and 
#                   creating a provincial DEM, but realize it's not clean.    
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 19 June 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================

#  WARNING, the code is incomplete.  Use it to facilitate downloading and 
#  creating a provincial DEM, but realize it's not clean.    

# packages
require (downloader)
require (rgdal)
require (raster)

# data directory
setwd ('C:\\Work\\caribou\\clus_data\\dem\\')
outPath <- "C:\\Work\\caribou\\clus_data\\dem"

# DEM 
# source for digital elevation data; using the GeoBC data: 
# https://catalogue.data.gov.bc.ca/dataset/digital-elevation-model-for-british-columbia-cded-1-250-000

# create a list of the map tiles you want data for
# can use this website to identify map tiles: https://www2.gov.bc.ca/assets/gov/data/geographic/topography/250kgrid.pdf
# these lists are in caribou range
list.dem.100s <- list ("104m", "104n", "104o","104p", "104i", "104j", "104k", "104g", "104h", "104a", "103p",
                       "103i", "104f")
list.dem.90s <- list ("94m", "94n", "94o", "94p", "94i", "94j", "94k", "94l", "94e", "94f", "94g", 
                       "94h", "94a", "94b", "94c", "94d", "93m", "93n", "93o", "93p", "93i", "93j", 
                       "93k", "93l", "103i", "93e", "93f", "93g", "93h", "83e", "83c", "83d", "93a", 
                       "93b", "93c", "93d", "92n", "92o", "92p", "82m", "82n", "82o", "82j", "82k",
                       "82l", "82e", "82f", "82g")
# these lists cover the rest of BC
list.dem.90s.2 <- list ("95d", "95c", "95b", "95a", "92m", "92l", "92k", "92j",
                        "92i", "92h", "92g", "92f", "92e", "92c", "92b", "92a",
                        "85d", "84m", "84l", "84e", "84d", "83m", "83l", "83e",
                        "83d", "83c", "82h", "82d", "82c", "82b", "82a")

list.dem.100s.2 <- list ("115b", "115a", "114p", "114o", "114i", "105d", "105c",
                         "105b", "105a", "104l", "104f", "104b", "104a", "103o",
                         "103k", "103j", "103h", "103g", "103f", "103c", "103b",
                         "103a", "102p", "102o", "102i")

for (i in list.dem.100s) { # loop though list to grab data for each tile; 
                           # there are maximum 32 'sub-tiles' within each
  try ({# some tiles don't exist; the 'try' command skips them in some cases,
        # but I noticed in other cases it fails, so be aware
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "16_w.dem.zip"),
            dest = paste0 (i, "16_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "16_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "16_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "16_e.dem.zip"),
            dest = paste0 (i, "16_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "16_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "16_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "15_w.dem.zip"),
            dest = paste0 (i, "15_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "15_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "15_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "15_e.dem.zip"),
            dest = paste0 (i, "15_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "15_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "15_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "14_w.dem.zip"),
            dest = paste0 (i, "14_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "14_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "14_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "14_e.dem.zip"),
            dest = paste0 (i, "14_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "14_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "14_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "13_w.dem.zip"),
            dest = paste0 (i, "13_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "13_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "13_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "13_e.dem.zip"),
            dest = paste0 (i, "13_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "13_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "13_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "12_w.dem.zip"),
            dest = paste0 (i, "12_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "12_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "12_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "12_e.dem.zip"),
            dest = paste0 (i, "12_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "12_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "12_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "11_w.dem.zip"),
            dest = paste0 (i, "11_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "11_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "11_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "11_e.dem.zip"),
            dest = paste0 (i, "11_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "11_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "11_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "10_w.dem.zip"),
            dest = paste0 (i, "10_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "10_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "10_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "10_e.dem.zip"),
            dest = paste0 (i, "10_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "10_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "10_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "09_w.dem.zip"),
            dest = paste0 (i, "09_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "09_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "09_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "09_e.dem.zip"),
            dest = paste0 (i, "09_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "09_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "09_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "08_w.dem.zip"),
            dest = paste0 (i, "08_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "08_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "08_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "08_e.dem.zip"),
            dest = paste0 (i, "08_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "08_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "08_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "07_w.dem.zip"),
            dest = paste0 (i, "07_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "07_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "07_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "07_e.dem.zip"),
            dest = paste0 (i, "07_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "07_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "07_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "06_w.dem.zip"),
            dest = paste0 (i, "06_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "06_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "06_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "06_e.dem.zip"),
            dest = paste0 (i, "06_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "06_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "06_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "05_w.dem.zip"),
            dest = paste0 (i, "05_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "05_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "05_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "05_e.dem.zip"),
            dest = paste0 (i, "05_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "05_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "05_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "04_w.dem.zip"),
            dest = paste0 (i, "04_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "04_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "04_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "04_e.dem.zip"),
            dest = paste0 (i, "04_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "04_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "04_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "03_w.dem.zip"),
            dest = paste0 (i, "03_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "03_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "03_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "03_e.dem.zip"),
            dest = paste0 (i, "03_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "03_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "03_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "02_w.dem.zip"),
            dest = paste0 (i, "02_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "02_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "02_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "02_e.dem.zip"),
            dest = paste0 (i, "02_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "02_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "02_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "01_w.dem.zip"),
            dest = paste0 (i, "01_w.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "01_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "01_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "01_e.dem.zip"),
            dest = paste0 (i, "01_e.dem.zip"),
            mode = "wb")
  unzip (paste0 (i, "01_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 (i, "01_e.dem.zip"))
  })
}

for (i in list.dem.90s) { 
  try ({
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "16_w.dem.zip"),
              dest = paste0 (i, "16_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "16_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "16_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "16_e.dem.zip"),
              dest = paste0 (i, "16_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "16_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "16_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "15_w.dem.zip"),
              dest = paste0 (i, "15_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "15_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "15_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "15_e.dem.zip"),
              dest = paste0 (i, "15_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "15_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "15_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "14_w.dem.zip"),
              dest = paste0 (i, "14_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "14_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "14_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "14_e.dem.zip"),
              dest = paste0 (i, "14_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "14_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "14_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "13_w.dem.zip"),
              dest = paste0 (i, "13_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "13_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "13_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "13_e.dem.zip"),
              dest = paste0 (i, "13_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "13_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "13_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "12_w.dem.zip"),
              dest = paste0 (i, "12_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "12_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "12_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "12_e.dem.zip"),
              dest = paste0 (i, "12_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "12_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "12_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "11_w.dem.zip"),
              dest = paste0 (i, "11_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "11_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "11_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "11_e.dem.zip"),
              dest = paste0 (i, "11_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "11_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "11_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "10_w.dem.zip"),
              dest = paste0 (i, "10_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "10_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "10_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "10_e.dem.zip"),
              dest = paste0 (i, "10_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "10_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "10_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "09_w.dem.zip"),
              dest = paste0 (i, "09_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "09_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "09_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "09_e.dem.zip"),
              dest = paste0 (i, "09_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "09_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "09_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "08_w.dem.zip"),
              dest = paste0 (i, "08_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "08_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "08_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "08_e.dem.zip"),
              dest = paste0 (i, "08_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "08_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "08_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "07_w.dem.zip"),
              dest = paste0 (i, "07_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "07_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "07_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "07_e.dem.zip"),
              dest = paste0 (i, "07_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "07_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "07_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "06_w.dem.zip"),
              dest = paste0 (i, "06_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "06_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "06_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "06_e.dem.zip"),
              dest = paste0 (i, "06_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "06_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "06_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "05_w.dem.zip"),
              dest = paste0 (i, "05_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "05_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "05_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "05_e.dem.zip"),
              dest = paste0 (i, "05_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "05_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "05_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "04_w.dem.zip"),
              dest = paste0 (i, "04_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "04_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "04_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "04_e.dem.zip"),
              dest = paste0 (i, "04_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "04_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "04_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "03_w.dem.zip"),
              dest = paste0 (i, "03_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "03_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "03_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "03_e.dem.zip"),
              dest = paste0 (i, "03_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "03_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "03_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "02_w.dem.zip"),
              dest = paste0 (i, "02_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "02_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "02_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "02_e.dem.zip"),
              dest = paste0 (i, "02_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "02_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "02_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "01_w.dem.zip"),
              dest = paste0 (i, "01_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "01_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "01_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "01_e.dem.zip"),
              dest = paste0 (i, "01_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "01_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "01_e.dem.zip"))
  })
}

for (i in list.dem.100s.2) { 
  try ({
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "16_w.dem.zip"),
              dest = paste0 (i, "16_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "16_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "16_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "16_e.dem.zip"),
              dest = paste0 (i, "16_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "16_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "16_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "15_w.dem.zip"),
              dest = paste0 (i, "15_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "15_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "15_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "15_e.dem.zip"),
              dest = paste0 (i, "15_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "15_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "15_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "14_w.dem.zip"),
              dest = paste0 (i, "14_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "14_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "14_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "14_e.dem.zip"),
              dest = paste0 (i, "14_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "14_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "14_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "13_w.dem.zip"),
              dest = paste0 (i, "13_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "13_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "13_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "13_e.dem.zip"),
              dest = paste0 (i, "13_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "13_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "13_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "12_w.dem.zip"),
              dest = paste0 (i, "12_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "12_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "12_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "12_e.dem.zip"),
              dest = paste0 (i, "12_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "12_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "12_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "11_w.dem.zip"),
              dest = paste0 (i, "11_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "11_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "11_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "11_e.dem.zip"),
              dest = paste0 (i, "11_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "11_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "11_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "10_w.dem.zip"),
              dest = paste0 (i, "10_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "10_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "10_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "10_e.dem.zip"),
              dest = paste0 (i, "10_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "10_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "10_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "09_w.dem.zip"),
              dest = paste0 (i, "09_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "09_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "09_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "09_e.dem.zip"),
              dest = paste0 (i, "09_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "09_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "09_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "08_w.dem.zip"),
              dest = paste0 (i, "08_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "08_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "08_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "08_e.dem.zip"),
              dest = paste0 (i, "08_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "08_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "08_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "07_w.dem.zip"),
              dest = paste0 (i, "07_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "07_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "07_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "07_e.dem.zip"),
              dest = paste0 (i, "07_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "07_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "07_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "06_w.dem.zip"),
              dest = paste0 (i, "06_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "06_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "06_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "06_e.dem.zip"),
              dest = paste0 (i, "06_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "06_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "06_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "05_w.dem.zip"),
              dest = paste0 (i, "05_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "05_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "05_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "05_e.dem.zip"),
              dest = paste0 (i, "05_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "05_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "05_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "04_w.dem.zip"),
              dest = paste0 (i, "04_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "04_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "04_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "04_e.dem.zip"),
              dest = paste0 (i, "04_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "04_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "04_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "03_w.dem.zip"),
              dest = paste0 (i, "03_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "03_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "03_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "03_e.dem.zip"),
              dest = paste0 (i, "03_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "03_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "03_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "02_w.dem.zip"),
              dest = paste0 (i, "02_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "02_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "02_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "02_e.dem.zip"),
              dest = paste0 (i, "02_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "02_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "02_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "01_w.dem.zip"),
              dest = paste0 (i, "01_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "01_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "01_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/", i, "01_e.dem.zip"),
              dest = paste0 (i, "01_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "01_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "01_e.dem.zip"))
  })
}

for (i in list.dem.90s.2) { 
  try ({
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "16_w.dem.zip"),
              dest = paste0 (i, "16_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "16_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "16_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "16_e.dem.zip"),
              dest = paste0 (i, "16_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "16_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "16_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "15_w.dem.zip"),
              dest = paste0 (i, "15_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "15_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "15_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "15_e.dem.zip"),
              dest = paste0 (i, "15_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "15_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "15_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "14_w.dem.zip"),
              dest = paste0 (i, "14_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "14_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "14_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "14_e.dem.zip"),
              dest = paste0 (i, "14_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "14_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "14_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "13_w.dem.zip"),
              dest = paste0 (i, "13_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "13_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "13_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "13_e.dem.zip"),
              dest = paste0 (i, "13_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "13_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "13_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "12_w.dem.zip"),
              dest = paste0 (i, "12_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "12_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "12_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "12_e.dem.zip"),
              dest = paste0 (i, "12_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "12_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "12_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "11_w.dem.zip"),
              dest = paste0 (i, "11_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "11_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "11_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "11_e.dem.zip"),
              dest = paste0 (i, "11_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "11_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "11_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "10_w.dem.zip"),
              dest = paste0 (i, "10_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "10_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "10_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "10_e.dem.zip"),
              dest = paste0 (i, "10_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "10_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "10_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "09_w.dem.zip"),
              dest = paste0 (i, "09_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "09_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "09_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "09_e.dem.zip"),
              dest = paste0 (i, "09_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "09_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "09_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "08_w.dem.zip"),
              dest = paste0 (i, "08_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "08_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "08_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "08_e.dem.zip"),
              dest = paste0 (i, "08_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "08_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "08_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "07_w.dem.zip"),
              dest = paste0 (i, "07_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "07_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "07_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "07_e.dem.zip"),
              dest = paste0 (i, "07_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "07_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "07_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "06_w.dem.zip"),
              dest = paste0 (i, "06_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "06_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "06_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "06_e.dem.zip"),
              dest = paste0 (i, "06_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "06_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "06_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "05_w.dem.zip"),
              dest = paste0 (i, "05_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "05_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "05_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "05_e.dem.zip"),
              dest = paste0 (i, "05_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "05_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "05_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "04_w.dem.zip"),
              dest = paste0 (i, "04_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "04_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "04_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "04_e.dem.zip"),
              dest = paste0 (i, "04_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "04_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "04_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "03_w.dem.zip"),
              dest = paste0 (i, "03_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "03_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "03_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "03_e.dem.zip"),
              dest = paste0 (i, "03_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "03_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "03_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "02_w.dem.zip"),
              dest = paste0 (i, "02_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "02_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "02_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "02_e.dem.zip"),
              dest = paste0 (i, "02_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "02_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "02_e.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "01_w.dem.zip"),
              dest = paste0 (i, "01_w.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "01_w.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "01_w.dem.zip"))
    download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/", i, "/0", i, "01_e.dem.zip"),
              dest = paste0 (i, "01_e.dem.zip"),
              mode = "wb")
    unzip (paste0 (i, "01_e.dem.zip"), 
           exdir = outPath)
    file.remove (paste0 (i, "01_e.dem.zip"))
  })
}

# Merge rasters together
# tried looping trhough all data, but was filling up the temp folder and C: drive, so doing it here tile by tile
# 82m
dem.082m01.e <- raster ("082m01_e.dem") 
dem.082m01.w <- raster ("082m01_w.dem")
dem.final <- raster::merge (dem.082m01.e, dem.082m01.w)

filenames.82m <- list.files (pattern = "^.*082m.*.dem$", full.names = TRUE)
for (i in filenames.82m) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082m\\082m.tif", format = "GTiff")

# 82e
dem.082e01.e <- raster ("082e01_e.dem") 
dem.082e01.w <- raster ("082e01_w.dem")
dem.final <- raster::merge (dem.082e01.e, dem.082e01.w)
filenames.82e <- list.files (pattern = "^.*082e.*.dem$", full.names = TRUE)
for (i in filenames.82e) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082e\\082e.tif", format = "GTiff")

# 82f
dem.082f01.e <- raster ("082f01_e.dem") 
dem.082f01.w <- raster ("082f01_w.dem")
dem.final <- raster::merge (dem.082f01.e, dem.082f01.w)
filenames.82f <- list.files (pattern = "^.*082f.*.dem$", full.names = TRUE)
for (i in filenames.82f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082f\\082f.tif", format = "GTiff")

# 82g
dem.082g01.e <- raster ("082g01_e.dem") 
dem.082g01.w <- raster ("082g01_w.dem")
dem.final <- raster::merge (dem.082g01.e, dem.082g01.w)
filenames.82g <- list.files (pattern = "^.*082g.*.dem$", full.names = TRUE)
for (i in filenames.82g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082g\\082g.tif", format = "GTiff")

# 82j
dem.082j02.e <- raster ("082j02_e.dem") 
dem.082j02.w <- raster ("082j02_w.dem")
dem.final <- raster::merge (dem.082j02.e, dem.082j02.w)
filenames.82j <- list.files (pattern = "^.*082j.*.dem$", full.names = TRUE)
for (i in filenames.82j) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("082j")
raster::writeRaster (dem.final, filename = "082j\\082j.tif", format = "GTiff")

# 82k
dem.082k01.e <- raster ("082k01_e.dem") 
dem.082k01.w <- raster ("082k01_w.dem")
dem.final <- raster::merge (dem.082k01.e, dem.082k01.w)
filenames.82k <- list.files (pattern = "^.*082k.*.dem$", full.names = TRUE)
for (i in filenames.82k) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082k\\082k.tif", format = "GTiff")

# 82l
dem.082l01.e <- raster ("082l01_e.dem") 
dem.082l01.w <- raster ("082l01_w.dem")
dem.final <- raster::merge (dem.082l01.e, dem.082l01.w)
filenames.82l <- list.files (pattern = "^.*082l.*.dem$", full.names = TRUE)
for (i in filenames.82l) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082l\\082l.tif", format = "GTiff")

# 82n
dem.082n01.e <- raster ("082n01_e.dem") 
dem.082n01.w <- raster ("082n01_w.dem")
dem.final <- raster::merge (dem.082n01.e, dem.082n01.w)
filenames.82n <- list.files (pattern = "^.*082n.*.dem$", full.names = TRUE)
for (i in filenames.82n) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("082n")
raster::writeRaster (dem.final, filename = "082n\\082n.tif", format = "GTiff")

# 83c
dem.083c02.e <- raster ("083c02_e.dem") 
dem.083c02.w <- raster ("083c02_w.dem")
dem.final <- raster::merge (dem.083c02.e, dem.083c02.w)
filenames.83c <- list.files (pattern = "^.*083c.*.dem$", full.names = TRUE)
for (i in filenames.83c) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("083c")
raster::writeRaster (dem.final, filename = "083c\\083c.tif", format = "GTiff")

# 83d
dem.083d01.e <- raster ("083d01_e.dem") 
dem.083d01.w <- raster ("083d01_w.dem")
dem.final <- raster::merge (dem.083d01.e, dem.083d01.w)
filenames.83d <- list.files (pattern = "^.*083d.*.dem$", full.names = TRUE)
for (i in filenames.83d) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("083d")
raster::writeRaster (dem.final, filename = "083d\\083d.tif", format = "GTiff")

# 83e
dem.083e02.e <- raster ("083e02_e.dem") 
dem.083e02.w <- raster ("083e02_w.dem")
dem.final <- raster::merge (dem.083e02.e, dem.083e02.w)
filenames.83e <- list.files (pattern = "^.*083e.*.dem$", full.names = TRUE)
for (i in filenames.83e) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("083e")
raster::writeRaster (dem.final, filename = "083e\\083e.tif", format = "GTiff")

# 92n
dem.092n01.e <- raster ("092n01_e.dem") 
dem.092n01.w <- raster ("092n01_w.dem")
dem.final <- raster::merge (dem.092n01.e, dem.092n01.w)
filenames.92n <- list.files (pattern = "^.*092n.*.dem$", full.names = TRUE)
for (i in filenames.92n) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092n")
raster::writeRaster (dem.final, filename = "092n\\092n.tif", format = "GTiff", overwrite = T)

# 92o
dem.092o01.e <- raster ("092o01_e.dem") 
dem.092o01.w <- raster ("092o01_w.dem")
dem.final <- raster::merge (dem.092o01.e, dem.092o01.w)
filenames.92o <- list.files (pattern = "^.*092o.*.dem$", full.names = TRUE)
for (i in filenames.92o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092o")
raster::writeRaster (dem.final, filename = "092o\\092o.tif", format = "GTiff",
                     overwrite = T)

# 92p
dem.092p01.e <- raster ("092p01_e.dem") 
dem.092p01.w <- raster ("092p01_w.dem")
dem.final <- raster::merge (dem.092p01.e, dem.092p01.w)
filenames.92p <- list.files (pattern = "^.*092p.*.dem$", full.names = TRUE)
for (i in filenames.92p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092p")
raster::writeRaster (dem.final, filename = "092p\\092p.tif", format = "GTiff",
                     overwrite = T)

# 93a
dem.093a01.e <- raster ("093a01_e.dem") 
dem.093a01.w <- raster ("093a01_w.dem")
dem.final <- raster::merge (dem.093a01.e, dem.093a01.w)
filenames.93a <- list.files (pattern = "^.*093a.*.dem$", full.names = TRUE)
for (i in filenames.93a) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093a")
raster::writeRaster (dem.final, filename = "093a\\093a.tif", format = "GTiff")

# 93b
dem.093b01.e <- raster ("093b01_e.dem") 
dem.093b01.w <- raster ("093b01_w.dem")
dem.final <- raster::merge (dem.093b01.e, dem.093b01.w)
filenames.93b <- list.files (pattern = "^.*093b.*.dem$", full.names = TRUE)
for (i in filenames.93b) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093b")
raster::writeRaster (dem.final, filename = "093b\\093b.tif", format = "GTiff")

# 93c
dem.093c01.e <- raster ("093c01_e.dem") 
dem.093c01.w <- raster ("093c01_w.dem")
dem.final <- raster::merge (dem.093c01.e, dem.093c01.w)
filenames.93c <- list.files (pattern = "^.*093c.*.dem$", full.names = TRUE)
for (i in filenames.93c) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093c")
raster::writeRaster (dem.final, filename = "093c\\093c.tif", format = "GTiff")

# 93d
dem.093d01.e <- raster ("093d01_e.dem")
dem.093d01.w <- raster ("093d01_w.dem")
dem.final <- raster::merge (dem.093d01.e, dem.093d01.w)
filenames.93d <- list.files (pattern = "^.*093d.*.dem$", full.names = TRUE)
for (i in filenames.93d) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093d")
raster::writeRaster (dem.final, filename = "093d\\093d.tif", format = "GTiff")

# 93e
dem.093e01.e <- raster ("093e01_e.dem") 
dem.093e01.w <- raster ("093e01_w.dem")
dem.final <- raster::merge (dem.093e01.e, dem.093e01.w)
filenames.93e <- list.files (pattern = "^.*093e.*.dem$", full.names = TRUE)
for (i in filenames.93e) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093e")
raster::writeRaster (dem.final, filename = "093e\\093e.tif", format = "GTiff")

# 93f
dem.093f01.e <- raster ("093f01_e.dem")
dem.093f01.w <- raster ("093f01_w.dem")
dem.final <- raster::merge (dem.093f01.e, dem.093f01.w)
filenames.93f <- list.files (pattern = "^.*093f.*.dem$", full.names = TRUE)
for (i in filenames.93f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093f")
raster::writeRaster (dem.final, filename = "093f\\093f.tif", format = "GTiff")

# 93g
dem.093g01.e <- raster ("093g01_e.dem")
dem.093g01.w <- raster ("093g01_w.dem")
dem.final <- raster::merge (dem.093g01.e, dem.093g01.w)
filenames.93g <- list.files (pattern = "^.*093g.*.dem$", full.names = TRUE)
for (i in filenames.93g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093g")
raster::writeRaster (dem.final, filename = "093g\\093g.tif", format = "GTiff")

# 93h
dem.093h01.e <- raster ("093h01_e.dem")
dem.093h01.w <- raster ("093h01_w.dem")
dem.final <- raster::merge (dem.093h01.e, dem.093h01.w)
filenames.93h <- list.files (pattern = "^.*093h.*.dem$", full.names = TRUE)
for (i in filenames.93h) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093h")
raster::writeRaster (dem.final, filename = "093h\\093h.tif", format = "GTiff")

# 93i
dem.093i01.e <- raster ("093i01_e.dem")
dem.093i01.w <- raster ("093i01_w.dem")
dem.final <- raster::merge (dem.093i01.e, dem.093i01.w)
filenames.93i <- list.files (pattern = "^.*093i.*.dem$", full.names = TRUE)
for (i in filenames.93i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093i")
raster::writeRaster (dem.final, filename = "093i\\093i.tif", format = "GTiff")

# 93j
dem.093j01.e <- raster ("093j01_e.dem")
dem.093j01.w <- raster ("093j01_w.dem")
dem.final <- raster::merge (dem.093j01.e, dem.093j01.w)
filenames.93j <- list.files (pattern = "^.*093j.*.dem$", full.names = TRUE)
for (i in filenames.93j) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093j")
raster::writeRaster (dem.final, filename = "093j\\093j.tif", format = "GTiff")

# 93k
dem.093k01.e <- raster ("093k01_e.dem")
dem.093k01.w <- raster ("093k01_w.dem")
dem.final <- raster::merge (dem.093k01.e, dem.093k01.w)
filenames.93k <- list.files (pattern = "^.*093k.*.dem$", full.names = TRUE)
for (i in filenames.93k) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093k")
raster::writeRaster (dem.final, filename = "093k\\093k.tif", format = "GTiff")

# 93l
dem.093l01.e <- raster ("093l01_e.dem")
dem.093l01.w <- raster ("093l01_w.dem")
dem.final <- raster::merge (dem.093l01.e, dem.093l01.w)
filenames.93l <- list.files (pattern = "^.*093l.*.dem$", full.names = TRUE)
for (i in filenames.93l) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093l")
raster::writeRaster (dem.final, filename = "093l\\093l.tif", format = "GTiff")

# 93m
dem.093m01.e <- raster ("093m01_e.dem") 
dem.093m01.w <- raster ("093m01_w.dem")
dem.final <- raster::merge (dem.093m01.e, dem.093m01.w)
filenames.93m <- list.files (pattern = "^.*093m.*.dem$", full.names = TRUE)
for (i in filenames.93m) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093m")
raster::writeRaster (dem.final, filename = "093m\\093m.tif", format = "GTiff")
                         
# 93n
dem.093n01.e <- raster ("093n01_e.dem") 
dem.093n01.w <- raster ("093n01_w.dem")
dem.final <- raster::merge (dem.093n01.e, dem.093n01.w)
filenames.93n <- list.files (pattern = "^.*093n.*.dem$", full.names = TRUE)
for (i in filenames.93n) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093n")
raster::writeRaster (dem.final, filename = "093n\\093n.tif", format = "GTiff")  

# 93o
dem.093o01.e <- raster ("093o01_e.dem")
dem.093o01.w <- raster ("093o01_w.dem")
dem.final <- raster::merge (dem.093o01.e, dem.093o01.w)
filenames.93o <- list.files (pattern = "^.*093o.*.dem$", full.names = TRUE)
for (i in filenames.93o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093o")
raster::writeRaster (dem.final, filename = "093o\\093o.tif", format = "GTiff")

# 93p
dem.093p01.e <- raster ("093p01_e.dem")
dem.093p01.w <- raster ("093p01_w.dem")
dem.final <- raster::merge (dem.093p01.e, dem.093p01.w)
filenames.93p <- list.files (pattern = "^.*093p.*.dem$", full.names = TRUE)
for (i in filenames.93p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("093p")
raster::writeRaster (dem.final, filename = "093p\\093p.tif", format = "GTiff")


# 94a
dem.094a01.e <- raster ("094a01_e.dem") 
dem.094a01.w <- raster ("094a01_w.dem")
dem.final <- raster::merge (dem.094a01.e, dem.094a01.w)
filenames.94a <- list.files (pattern = "^.*094a.*.dem$", full.names = TRUE)
for (i in filenames.94a) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094a")
raster::writeRaster (dem.final, filename = "094a\\094a.tif", format = "GTiff")

# 94b
dem.094b01.e <- raster ("094b01_e.dem") 
dem.094b01.w <- raster ("094b01_w.dem")
dem.final <- raster::merge (dem.094b01.e, dem.094b01.w)
filenames.94b <- list.files (pattern = "^.*094b.*.dem$", full.names = TRUE)
for (i in filenames.94b) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094b")
raster::writeRaster (dem.final, filename = "094b\\094b.tif", format = "GTiff")

# 94c
dem.094c01.e <- raster ("094c01_e.dem") 
dem.094c01.w <- raster ("094c01_w.dem")
dem.final <- raster::merge (dem.094c01.e, dem.094c01.w)
filenames.94c <- list.files (pattern = "^.*094c.*.dem$", full.names = TRUE)
for (i in filenames.94c) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094c")
raster::writeRaster (dem.final, filename = "094c\\094c.tif", format = "GTiff")

# 94d
dem.094d01.e <- raster ("094d01_e.dem") 
dem.094d01.w <- raster ("094d01_w.dem")
dem.final <- raster::merge (dem.094d01.e, dem.094d01.w)
filenames.94d <- list.files (pattern = "^.*094d.*.dem$", full.names = TRUE)
for (i in filenames.94d) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094d")
raster::writeRaster (dem.final, filename = "094d\\094d.tif", format = "GTiff")

# 94e
dem.094e01.e <- raster ("094e01_e.dem") 
dem.094e01.w <- raster ("094e01_w.dem")
dem.final <- raster::merge (dem.094e01.e, dem.094e01.w)
filenames.94e <- list.files (pattern = "^.*094e.*.dem$", full.names = TRUE)
for (i in filenames.94e) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094e")
raster::writeRaster (dem.final, filename = "094e\\094e.tif", format = "GTiff")

# 94f
dem.094f01.e <- raster ("094f01_e.dem") 
dem.094f01.w <- raster ("094f01_w.dem")
dem.final <- raster::merge (dem.094f01.e, dem.094f01.w)
filenames.94f <- list.files (pattern = "^.*094f.*.dem$", full.names = TRUE)
for (i in filenames.94f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094f")
raster::writeRaster (dem.final, filename = "094f\\094f.tif", format = "GTiff")

# 94g
dem.094g01.e <- raster ("094g01_e.dem") 
dem.094g01.w <- raster ("094g01_w.dem")
dem.final <- raster::merge (dem.094g01.e, dem.094g01.w)
filenames.94g <- list.files (pattern = "^.*094g.*.dem$", full.names = TRUE)
for (i in filenames.94g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094g")
raster::writeRaster (dem.final, filename = "094g\\094g.tif", format = "GTiff")

# 94h
dem.094h01.e <- raster ("094h01_e.dem")
dem.094h01.w <- raster ("094h01_w.dem")
dem.final <- raster::merge (dem.094h01.e, dem.094h01.w)
filenames.94h <- list.files (pattern = "^.*094h.*.dem$", full.names = TRUE)
for (i in filenames.94h) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094h")
raster::writeRaster (dem.final, filename = "094h\\094h.tif", format = "GTiff")

# 94i
dem.094i01.e <- raster ("094i01_e.dem") 
dem.094i01.w <- raster ("094i01_w.dem")
dem.final <- raster::merge (dem.094i01.e, dem.094i01.w)
filenames.94i <- list.files (pattern = "^.*094i.*.dem$", full.names = TRUE)
for (i in filenames.94i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094i")
raster::writeRaster (dem.final, filename = "094i\\094i.tif", format = "GTiff")

# 94j
dem.094j01.e <- raster ("094j01_e.dem")
dem.094j01.w <- raster ("094j01_w.dem")
dem.final <- raster::merge (dem.094j01.e, dem.094j01.w)
filenames.94j <- list.files (pattern = "^.*094j.*.dem$", full.names = TRUE)
for (i in filenames.94j) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094j")
raster::writeRaster (dem.final, filename = "094j\\094j.tif", format = "GTiff")

# 94k
dem.094k01.e <- raster ("094k01_e.dem") 
dem.094k01.w <- raster ("094k01_w.dem")
dem.final <- raster::merge (dem.094k01.e, dem.094k01.w)
filenames.94k <- list.files (pattern = "^.*094k.*.dem$", full.names = TRUE)
for (i in filenames.94k) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094k")
raster::writeRaster (dem.final, filename = "094k\\094k.tif", format = "GTiff")

# 94l
dem.094l01.e <- raster ("094l01_e.dem") 
dem.094l01.w <- raster ("094l01_w.dem")
dem.final <- raster::merge (dem.094l01.e, dem.094l01.w)
filenames.94l <- list.files (pattern = "^.*094l.*.dem$", full.names = TRUE)
for (i in filenames.94l) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094l")
raster::writeRaster (dem.final, filename = "094l\\094l.tif", format = "GTiff")

# 94m
dem.094m01.e <- raster ("094m01_e.dem") 
dem.094m01.w <- raster ("094m01_w.dem")
dem.final <- raster::merge (dem.094m01.e, dem.094m01.w)
filenames.94m <- list.files (pattern = "^.*094m.*.dem$", full.names = TRUE)
for (i in filenames.94m) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094m")
raster::writeRaster (dem.final, filename = "094m\\094m.tif", format = "GTiff")

# 94n
dem.094n01.e <- raster ("094n01_e.dem") 
dem.094n01.w <- raster ("094n01_w.dem")
dem.final <- raster::merge (dem.094n01.e, dem.094n01.w)
filenames.94n <- list.files (pattern = "^.*094n.*.dem$", full.names = TRUE)
for (i in filenames.94n) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094n")
raster::writeRaster (dem.final, filename = "094n\\094n.tif", format = "GTiff")  

# 94o
dem.094o01.e <- raster ("094o01_e.dem") 
dem.094o01.w <- raster ("094o01_w.dem")
dem.final <- raster::merge (dem.094o01.e, dem.094o01.w)
filenames.94o <- list.files (pattern = "^.*094o.*.dem$", full.names = TRUE)
for (i in filenames.94o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094o")
raster::writeRaster (dem.final, filename = "094o\\094o.tif", format = "GTiff")

# 94p
dem.094p01.e <- raster ("094p01_e.dem") 
dem.094p01.w <- raster ("094p01_w.dem")
dem.final <- raster::merge (dem.094p01.e, dem.094p01.w)
filenames.94p <- list.files (pattern = "^.*094p.*.dem$", full.names = TRUE)
for (i in filenames.94p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("094p")
raster::writeRaster (dem.final, filename = "094p\\094p.tif", format = "GTiff")

# 103i
dem.103i01.e <- raster ("103i01_e.dem") 
dem.103i01.w <- raster ("103i01_w.dem")
dem.final <- raster::merge (dem.103i01.e, dem.103i01.w)
filenames.103i <- list.files (pattern = "^.*103i.*.dem$", full.names = TRUE)
for (i in filenames.103i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103i")
raster::writeRaster (dem.final, filename = "103i\\103i.tif", format = "GTiff")

# 103j
dem.103j01.e <- raster ("103j01_e.dem") 
dem.103j01.w <- raster ("103j01_w.dem")
dem.final <- raster::merge (dem.103j01.e, dem.103j01.w)
filenames.103j <- list.files (pattern = "^.*103j.*.dem$", full.names = TRUE)
for (i in filenames.103j) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
dir.create ("103j")
raster::writeRaster (dem.final, filename = "103j\\103j.tif", format = "GTiff")

# 103o
dem.103o01.e <- raster ("103o01_e.dem") 
dem.103o01.w <- raster ("103o01_w.dem")
dem.final <- raster::merge (dem.103o01.e, dem.103o01.w)
filenames.103o <- list.files (pattern = "^.*103o.*.dem$", full.names = TRUE)
for (i in filenames.103o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
dir.create ("103o")
raster::writeRaster (dem.final, filename = "103o\\103o.tif", format = "GTiff")

# 103p
dem.103p01.e <- raster ("103p01_e.dem") 
dem.103p01.w <- raster ("103p01_w.dem")
dem.final <- raster::merge (dem.103p01.e, dem.103p01.w)
filenames.103p <- list.files (pattern = "^.*103p.*.dem$", full.names = TRUE)
for (i in filenames.103p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103p")
raster::writeRaster (dem.final, filename = "103p\\103p.tif", format = "GTiff")

# 104a
dem.104a01.e <- raster ("104a01_e.dem") 
dem.104a01.w <- raster ("104a01_w.dem")
dem.final <- raster::merge (dem.104a01.e, dem.104a01.w)
filenames.104a <- list.files (pattern = "^.*104a.*.dem$", full.names = TRUE)
for (i in filenames.104a) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104a")
raster::writeRaster (dem.final, filename = "104a\\104a.tif", format = "GTiff")

# 104b
dem.104b01.e <- raster ("104b01_e.dem") 
dem.104b01.w <- raster ("104b01_w.dem")
dem.final <- raster::merge (dem.104b01.e, dem.104b01.w)
filenames.104b <- list.files (pattern = "^.*104b.*.dem$", full.names = TRUE)
for (i in filenames.104b) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
dir.create ("104b")
raster::writeRaster (dem.final, filename = "104b\\104b.tif", format = "GTiff")

# 104f
dem.104f01.e <- raster ("104f01_e.dem") 
dem.104f01.w <- raster ("104f01_w.dem")
dem.final <- raster::merge (dem.104f01.e, dem.104f01.w)
filenames.104f <- list.files (pattern = "^.*104f.*.dem$", full.names = TRUE)
for (i in filenames.104f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
dir.create ("104f")
raster::writeRaster (dem.final, filename = "104f\\104f.tif", format = "GTiff")

# 104g
dem.104g01.e <- raster ("104g01_e.dem") 
dem.104g01.w <- raster ("104g01_w.dem")
dem.final <- raster::merge (dem.104g01.e, dem.104g01.w)
filenames.104g <- list.files (pattern = "^.*104g.*.dem$", full.names = TRUE)
for (i in filenames.104g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104g")
raster::writeRaster (dem.final, filename = "104g\\104g.tif", format = "GTiff")

# 104h
dem.104h01.e <- raster ("104h01_e.dem") 
dem.104h01.w <- raster ("104h01_w.dem")
dem.final <- raster::merge (dem.104h01.e, dem.104h01.w)
filenames.104h <- list.files (pattern = "^.*104h.*.dem$", full.names = TRUE)
for (i in filenames.104h) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104h")
raster::writeRaster (dem.final, filename = "104h\\104h.tif", format = "GTiff")

# 104i
dem.104i01.e <- raster ("104i01_e.dem")
dem.104i01.w <- raster ("104i01_w.dem")
dem.final <- raster::merge (dem.104i01.e, dem.104i01.w)
filenames.104i <- list.files (pattern = "^.*104i.*.dem$", full.names = TRUE)
for (i in filenames.104i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104i")
raster::writeRaster (dem.final, filename = "104i\\104i.tif", format = "GTiff")

# 104j
dem.104j01.e <- raster ("104j01_e.dem") 
dem.104j01.w <- raster ("104j01_w.dem")
dem.final <- raster::merge (dem.104j01.e, dem.104j01.w)
filenames.104j <- list.files (pattern = "^.*104j.*.dem$", full.names = TRUE)
for (i in filenames.104j) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104j")
raster::writeRaster (dem.final, filename = "104j\\104j.tif", format = "GTiff")

# 104k
dem.104k05.e <- raster ("104k05_e.dem")
dem.104k05.w <- raster ("104k05_w.dem")
dem.final <- raster::merge (dem.104k05.e, dem.104k05.w)
filenames.104k <- list.files (pattern = "^.*104k.*.dem$", full.names = TRUE)
for (i in filenames.104k) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104k")
raster::writeRaster (dem.final, filename = "104k\\104k.tif", format = "GTiff")

# 104m
dem.104m01.e <- raster ("104m01_e.dem") 
dem.104m01.w <- raster ("104m01_w.dem")
dem.final <- raster::merge (dem.104m01.e, dem.104m01.w)
filenames.104m <- list.files (pattern = "^.*104m.*.dem$", full.names = TRUE)
for (i in filenames.104m) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104m")
raster::writeRaster (dem.final, filename = "104m\\104m.tif", format = "GTiff")

# 104n
dem.104n01.e <- raster ("104n01_e.dem") 
dem.104n01.w <- raster ("104n01_w.dem")
dem.final <- raster::merge (dem.104n01.e, dem.104n01.w)
filenames.104n <- list.files (pattern = "^.*104n.*.dem$", full.names = TRUE)
for (i in filenames.104n) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104n")
raster::writeRaster (dem.final, filename = "104n\\104n.tif", format = "GTiff")  

# 104o
dem.104o01.e <- raster ("104o01_e.dem") 
dem.104o01.w <- raster ("104o01_w.dem")
dem.final <- raster::merge (dem.104o01.e, dem.104o01.w)
filenames.104o <- list.files (pattern = "^.*104o.*.dem$", full.names = TRUE)
for (i in filenames.104o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104o")
raster::writeRaster (dem.final, filename = "104o\\104o.tif", format = "GTiff")

# 104p
dem.104p01.e <- raster ("104p01_e.dem") 
dem.104p01.w <- raster ("104p01_w.dem")
dem.final <- raster::merge (dem.104p01.e, dem.104p01.w)
filenames.104p <- list.files (pattern = "^.*104p.*.dem$", full.names = TRUE)
for (i in filenames.104p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104p")
raster::writeRaster (dem.final, filename = "104p\\104p.tif", format = "GTiff")

# 102i
dem.102i01.e <- raster ("102i14_e.dem") 
dem.102i01.w <- raster ("102i14_w.dem")
dem.final <- raster::merge (dem.102i01.e, dem.102i01.w)
filenames.102i <- list.files (pattern = "^.*102i.*.dem$", full.names = TRUE)
for (i in filenames.102i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("102i")
raster::writeRaster (dem.final, filename = "102i\\102i.tif", format = "GTiff")

# 102p
dem.102p01.e <- raster ("102p15_e.dem") 
dem.102p01.w <- raster ("102p15_w.dem")
dem.final <- raster::merge (dem.102p01.e, dem.102p01.w)
filenames.102p <- list.files (pattern = "^.*102p.*.dem$", full.names = TRUE)
for (i in filenames.102p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("102p")
raster::writeRaster (dem.final, filename = "102p\\102p.tif", format = "GTiff")

# 103a
dem.103a01.e <- raster ("103a14_e.dem") 
dem.103a01.w <- raster ("103a14_w.dem")
dem.final <- raster::merge (dem.103a01.e, dem.103a01.w)
filenames.103a <- list.files (pattern = "^.*103a.*.dem$", full.names = TRUE)
for (i in filenames.103a) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103a")
raster::writeRaster (dem.final, filename = "103a\\103a.tif", format = "GTiff")

# 103c
dem.103c01.e <- raster ("103c15_e.dem") 
dem.103c01.w <- raster ("103c15_w.dem")
dem.final <- raster::merge (dem.103c01.e, dem.103c01.w)
filenames.103c <- list.files (pattern = "^.*103c.*.dem$", full.names = TRUE)
for (i in filenames.103c) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103c")
raster::writeRaster (dem.final, filename = "103c\\103c.tif", format = "GTiff")

# 103f
dem.103f01.e <- raster ("103f15_e.dem") 
dem.103f01.w <- raster ("103f15_w.dem")
dem.final <- raster::merge (dem.103f01.e, dem.103f01.w)
filenames.103f <- list.files (pattern = "^.*103f.*.dem$", full.names = TRUE)
for (i in filenames.103f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103f")
raster::writeRaster (dem.final, filename = "103f\\103f.tif", format = "GTiff")

# 103g
dem.103g01.e <- raster ("103g15_e.dem") 
dem.103g01.w <- raster ("103g15_w.dem")
dem.final <- raster::merge (dem.103g01.e, dem.103g01.w)
filenames.103g <- list.files (pattern = "^.*103g.*.dem$", full.names = TRUE)
for (i in filenames.103g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103g")
raster::writeRaster (dem.final, filename = "103g\\103g.tif", format = "GTiff")

# 103h
dem.103h01.e <- raster ("103h15_e.dem") 
dem.103h01.w <- raster ("103h15_w.dem")
dem.final <- raster::merge (dem.103h01.e, dem.103h01.w)
filenames.103h <- list.files (pattern = "^.*103h.*.dem$", full.names = TRUE)
for (i in filenames.103h) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103h")
raster::writeRaster (dem.final, filename = "103h\\103h.tif", format = "GTiff")

# 103i
dem.103i01.e <- raster ("103i15_e.dem") 
dem.103i01.w <- raster ("103i15_w.dem")
dem.final <- raster::merge (dem.103i01.e, dem.103i01.w)
filenames.103i <- list.files (pattern = "^.*103i.*.dem$", full.names = TRUE)
for (i in filenames.103i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103i")
raster::writeRaster (dem.final, filename = "103i\\103i.tif", format = "GTiff")

# 103p
dem.103p01.e <- raster ("103p15_e.dem") 
dem.103p01.w <- raster ("103p15_w.dem")
dem.final <- raster::merge (dem.103p01.e, dem.103p01.w)
filenames.103p <- list.files (pattern = "^.*103p.*.dem$", full.names = TRUE)
for (i in filenames.103p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("103p")
raster::writeRaster (dem.final, filename = "103p\\103p.tif", format = "GTiff")

# 104a
dem.104a01.e <- raster ("104a15_e.dem") 
dem.104a01.w <- raster ("104a15_w.dem")
dem.final <- raster::merge (dem.104a01.e, dem.104a01.w)
filenames.104a <- list.files (pattern = "^.*104a.*.dem$", full.names = TRUE)
for (i in filenames.104a) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104a")
raster::writeRaster (dem.final, filename = "104a\\104a.tif", format = "GTiff")

# 104b
dem.104b01.e <- raster ("104b15_e.dem") 
dem.104b01.w <- raster ("104b15_w.dem")
dem.final <- raster::merge (dem.104b01.e, dem.104b01.w)
filenames.104b <- list.files (pattern = "^.*104b.*.dem$", full.names = TRUE)
for (i in filenames.104b) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104b")
raster::writeRaster (dem.final, filename = "104b\\104b.tif", format = "GTiff")

# 104f
dem.104f01.e <- raster ("104f15_e.dem") 
dem.104f01.w <- raster ("104f15_w.dem")
dem.final <- raster::merge (dem.104f01.e, dem.104f01.w)
filenames.104f <- list.files (pattern = "^.*104f.*.dem$", full.names = TRUE)
for (i in filenames.104f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104f")
raster::writeRaster (dem.final, filename = "104f\\104f.tif", format = "GTiff")

# 104g
dem.104g01.e <- raster ("104g15_e.dem") 
dem.104g01.w <- raster ("104g15_w.dem")
dem.final <- raster::merge (dem.104g01.e, dem.104g01.w)
filenames.104g <- list.files (pattern = "^.*104g.*.dem$", full.names = TRUE)
for (i in filenames.104g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104g")
raster::writeRaster (dem.final, filename = "104g\\104g.tif", format = "GTiff")

# 104h
dem.104h01.e <- raster ("104h15_e.dem") 
dem.104h01.w <- raster ("104h15_w.dem")
dem.final <- raster::merge (dem.104h01.e, dem.104h01.w)
filenames.104h <- list.files (pattern = "^.*104h.*.dem$", full.names = TRUE)
for (i in filenames.104h) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104h")
raster::writeRaster (dem.final, filename = "104h\\104h.tif", format = "GTiff")

# 104i
dem.104i01.e <- raster ("104i15_e.dem") 
dem.104i01.w <- raster ("104i15_w.dem")
dem.final <- raster::merge (dem.104i01.e, dem.104i01.w)
filenames.104i <- list.files (pattern = "^.*104i.*.dem$", full.names = TRUE)
for (i in filenames.104i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104i")
raster::writeRaster (dem.final, filename = "104i\\104i.tif", format = "GTiff")

## 104j
dem.104j01.e <- raster ("104j15_e.dem") 
dem.104j01.w <- raster ("104j15_w.dem")
dem.final <- raster::merge (dem.104j01.e, dem.104j01.w)
filenames.104j <- list.files (pattern = "^.*104j.*.dem$", full.names = TRUE)
for (i in filenames.104j) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104j")
raster::writeRaster (dem.final, filename = "104j\\104j.tif", format = "GTiff")

# 104k
dem.104k05.e <- raster ("104k05_e.dem") 
dem.104k05.w <- raster ("104k05_w.dem")
dem.final <- raster::merge (dem.104k01.e, dem.104k01.w)
filenames.104k <- list.files (pattern = "^.*104k.*.dem$", full.names = TRUE)
for (i in filenames.104k) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
# dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104k")
raster::writeRaster (dem.final, filename = "104k\\104k.tif", format = "GTiff")

# 104l
dem.104l01.e <- raster ("104l16_e.dem") 
dem.104l01.w <- raster ("104l16_w.dem")
dem.final <- raster::merge (dem.104l01.e, dem.104l01.w)
filenames.104l <- list.files (pattern = "^.*104l.*.dem$", full.names = TRUE)
for (i in filenames.104l) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104l")
raster::writeRaster (dem.final, filename = "104l\\104l.tif", format = "GTiff")

# 104m
dem.104m01.e <- raster ("104m16_e.dem") 
dem.104m01.w <- raster ("104m16_w.dem")
dem.final <- raster::merge (dem.104m01.e, dem.104m01.w)
filenames.104m <- list.files (pattern = "^.*104m.*.dem$", full.names = TRUE)
for (i in filenames.104m) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104m")
raster::writeRaster (dem.final, filename = "104m\\104m.tif", format = "GTiff")

# 104n
dem.104n01.e <- raster ("104n16_e.dem") 
dem.104n01.w <- raster ("104n16_w.dem")
dem.final <- raster::merge (dem.104n01.e, dem.104n01.w)
filenames.104n <- list.files (pattern = "^.*104n.*.dem$", full.names = TRUE)
for (i in filenames.104n) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104n")
raster::writeRaster (dem.final, filename = "104n\\104n.tif", format = "GTiff")

# 104o
dem.104o01.e <- raster ("104o16_e.dem") 
dem.104o01.w <- raster ("104o16_w.dem")
dem.final <- raster::merge (dem.104o01.e, dem.104o01.w)
filenames.104o <- list.files (pattern = "^.*104o.*.dem$", full.names = TRUE)
for (i in filenames.104o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("104o")
raster::writeRaster (dem.final, filename = "104o\\104o.tif", format = "GTiff")

# 114p
dem.114p01.e <- raster ("114p16_e.dem") 
dem.114p01.w <- raster ("114p16_w.dem")
dem.final <- raster::merge (dem.114p01.e, dem.114p01.w)
filenames.114p <- list.files (pattern = "^.*114p.*.dem$", full.names = TRUE)
for (i in filenames.114p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("114p")
raster::writeRaster (dem.final, filename = "114p\\114p.tif", format = "GTiff", overwrite = T)

# 114p
dem.114p01.e <- raster ("114p16_e.dem") 
dem.114p01.w <- raster ("114p16_w.dem")
dem.final <- raster::merge (dem.114p01.e, dem.114p01.w)
filenames.114p <- list.files (pattern = "^.*114p.*.dem$", full.names = TRUE)
for (i in filenames.114p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("114p")
raster::writeRaster (dem.final, filename = "114p\\114p.tif", format = "GTiff", overwrite = T)

# 114o
dem.114o01.e <- raster ("114o16_e.dem") 
dem.114o01.w <- raster ("114o16_w.dem")
dem.final <- raster::merge (dem.114o01.e, dem.114o01.w)
filenames.114o <- list.files (pattern = "^.*114o.*.dem$", full.names = TRUE)
for (i in filenames.114o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("114o")
raster::writeRaster (dem.final, filename = "114o\\114o.tif", format = "GTiff", overwrite = T)

# 082b
dem.082b01.e <- raster ("082b16_e.dem") 
dem.082b01.w <- raster ("082b16_w.dem")
dem.final <- raster::merge (dem.082b01.e, dem.082b01.w)
filenames.082b <- list.files (pattern = "^.*082b.*.dem$", full.names = TRUE)
for (i in filenames.082b) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("082b")
raster::writeRaster (dem.final, filename = "082b\\082b.tif", format = "GTiff", overwrite = T)

# 082b
dem.082b01.e <- raster ("082b16_e.dem") 
dem.082b01.w <- raster ("082b16_w.dem")
dem.final <- raster::merge (dem.082b01.e, dem.082b01.w)
filenames.082b <- list.files (pattern = "^.*082b.*.dem$", full.names = TRUE)
for (i in filenames.082b) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("082b")
raster::writeRaster (dem.final, filename = "082b\\082b.tif", format = "GTiff", overwrite = T)

# 082c
dem.082c01.e <- raster ("082c16_e.dem") 
dem.082c01.w <- raster ("082c16_w.dem")
dem.final <- raster::merge (dem.082c01.e, dem.082c01.w)
filenames.082c <- list.files (pattern = "^.*082c.*.dem$", full.names = TRUE)
for (i in filenames.082c) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("082c")
raster::writeRaster (dem.final, filename = "082c\\082c.tif", format = "GTiff", overwrite = T)

# 082d
dem.082d01.e <- raster ("082d16_e.dem") 
dem.082d01.w <- raster ("082d16_w.dem")
dem.final <- raster::merge (dem.082d01.e, dem.082d01.w)
filenames.082d <- list.files (pattern = "^.*082d.*.dem$", full.names = TRUE)
for (i in filenames.082d) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("082d")
raster::writeRaster (dem.final, filename = "082d\\082d.tif", format = "GTiff", overwrite = T)

# 083d
dem.083d01.e <- raster ("083d16_e.dem") 
dem.083d01.w <- raster ("083d16_w.dem")
dem.final <- raster::merge (dem.083d01.e, dem.083d01.w)
filenames.083d <- list.files (pattern = "^.*083d.*.dem$", full.names = TRUE)
for (i in filenames.083d) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("083d")
raster::writeRaster (dem.final, filename = "083d\\083d.tif", format = "GTiff", overwrite = T)

# 092a
dem.092a01.e <- raster ("092a16_e.dem") 
dem.092a01.w <- raster ("092a16_w.dem")
dem.final <- raster::merge (dem.092a01.e, dem.092a01.w)
filenames.092a <- list.files (pattern = "^.*092a.*.dem$", full.names = TRUE)
for (i in filenames.092a) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092a")
raster::writeRaster (dem.final, filename = "092a\\092a.tif", format = "GTiff", overwrite = T)

# 092b
dem.092b01.e <- raster ("092b16_e.dem") 
dem.092b01.w <- raster ("092b16_w.dem")
dem.final <- raster::merge (dem.092b01.e, dem.092b01.w)
filenames.092b <- list.files (pattern = "^.*092b.*.dem$", full.names = TRUE)
for (i in filenames.092b) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092b")
raster::writeRaster (dem.final, filename = "092b\\092b.tif", format = "GTiff", overwrite = T)

# 092c
dem.092c01.e <- raster ("092c16_e.dem") 
dem.092c01.w <- raster ("092c16_w.dem")
dem.final <- raster::merge (dem.092c01.e, dem.092c01.w)
filenames.092c <- list.files (pattern = "^.*092c.*.dem$", full.names = TRUE)
for (i in filenames.092c) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092c")
raster::writeRaster (dem.final, filename = "092c\\092c.tif", format = "GTiff", overwrite = T)

# 092e
dem.092e01.e <- raster ("092e16_e.dem") 
dem.092e01.w <- raster ("092e16_w.dem")
dem.final <- raster::merge (dem.092e01.e, dem.092e01.w)
filenames.092e <- list.files (pattern = "^.*092e.*.dem$", full.names = TRUE)
for (i in filenames.092e) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092e")
raster::writeRaster (dem.final, filename = "092e\\092e.tif", format = "GTiff", overwrite = T)

# 092f
dem.092f01.e <- raster ("092f16_e.dem") 
dem.092f01.w <- raster ("092f16_w.dem")
dem.final <- raster::merge (dem.092f01.e, dem.092f01.w)
filenames.092f <- list.files (pattern = "^.*092f.*.dem$", full.names = TRUE)
for (i in filenames.092f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092f")
raster::writeRaster (dem.final, filename = "092f\\092f.tif", format = "GTiff", overwrite = T)

# 092g
dem.092g01.e <- raster ("092g16_e.dem") 
dem.092g01.w <- raster ("092g16_w.dem")
dem.final <- raster::merge (dem.092g01.e, dem.092g01.w)
filenames.092g <- list.files (pattern = "^.*092g.*.dem$", full.names = TRUE)
for (i in filenames.092g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092g")
raster::writeRaster (dem.final, filename = "092g\\092g.tif", format = "GTiff", overwrite = T)

# 092h
dem.092h01.e <- raster ("092h16_e.dem") 
dem.092h01.w <- raster ("092h16_w.dem")
dem.final <- raster::merge (dem.092h01.e, dem.092h01.w)
filenames.092h <- list.files (pattern = "^.*092h.*.dem$", full.names = TRUE)
for (i in filenames.092h) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092h")
raster::writeRaster (dem.final, filename = "092h\\092h.tif", format = "GTiff", overwrite = T)

# 092i
dem.092i01.e <- raster ("092i16_e.dem") 
dem.092i01.w <- raster ("092i16_w.dem")
dem.final <- raster::merge (dem.092i01.e, dem.092i01.w)
filenames.092i <- list.files (pattern = "^.*092i.*.dem$", full.names = TRUE)
for (i in filenames.092i) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092i")
raster::writeRaster (dem.final, filename = "092i\\092i.tif", format = "GTiff", overwrite = T)

# 092j
dem.092j01.e <- raster ("092j16_e.dem") 
dem.092j01.w <- raster ("092j16_w.dem")
dem.final <- raster::merge (dem.092j01.e, dem.092j01.w)
filenames.092j <- list.files (pattern = "^.*092j.*.dem$", full.names = TRUE)
for (i in filenames.092j) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092j")
raster::writeRaster (dem.final, filename = "092j\\092j.tif", format = "GTiff", overwrite = T)

# 092k
dem.092k01.e <- raster ("092k16_e.dem") 
dem.092k01.w <- raster ("092k16_w.dem")
dem.final <- raster::merge (dem.092k01.e, dem.092k01.w)
filenames.092k <- list.files (pattern = "^.*092k.*.dem$", full.names = TRUE)
for (i in filenames.092k) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092k")
raster::writeRaster (dem.final, filename = "092k\\092k.tif", format = "GTiff", overwrite = T)

# 092l
dem.092l01.e <- raster ("092l16_e.dem") 
dem.092l01.w <- raster ("092l16_w.dem")
dem.final <- raster::merge (dem.092l01.e, dem.092l01.w)
filenames.092l <- list.files (pattern = "^.*092l.*.dem$", full.names = TRUE)
for (i in filenames.092l) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092l")
raster::writeRaster (dem.final, filename = "092l\\092l.tif", format = "GTiff", overwrite = T)

# 092m
dem.092m01.e <- raster ("092m16_e.dem") 
dem.092m01.w <- raster ("092m16_w.dem")
dem.final <- raster::merge (dem.092m01.e, dem.092m01.w)
filenames.092m <- list.files (pattern = "^.*092m.*.dem$", full.names = TRUE)
for (i in filenames.092m) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092m")
raster::writeRaster (dem.final, filename = "092m\\092m.tif", format = "GTiff", overwrite = T)

# 114o
dem.114o01.e <- raster ("114o16_e.dem") 
dem.114o01.w <- raster ("114o16_w.dem")
dem.final <- raster::merge (dem.114o01.e, dem.114o01.w)
filenames.114o <- list.files (pattern = "^.*114o.*.dem$", full.names = TRUE)
for (i in filenames.114o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("114o")
raster::writeRaster (dem.final, filename = "114o\\114o.tif", format = "GTiff", overwrite = T)

# 114p
dem.114p01.e <- raster ("114p16_e.dem") 
dem.114p01.w <- raster ("114p16_w.dem")
dem.final <- raster::merge (dem.114p01.e, dem.114p01.w)
filenames.114p <- list.files (pattern = "^.*114p.*.dem$", full.names = TRUE)
for (i in filenames.114p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("114p")
raster::writeRaster (dem.final, filename = "114p\\114p.tif", format = "GTiff", overwrite = T)


#=======================================
# merging letter tiles into number tiles
#======================================
# 082
list.082 <- list ("082b", "082c", "082d", "082e", "082f", "082g", "082j", "082k", "082l", "082m", "082n")
dem.082b <- raster ("082b\\082b.tif") 
dem.082c <- raster ("082c\\082c.tif")
dem.final <- raster::merge (dem.082b, dem.082c)
for (i in list.082) {
  dem <- raster (paste0 (i, "\\", i, ".tif"))
  dem.final <- raster::merge (dem.final, dem, tolerance = 1) # tolerance for raster with different origins
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("082")
raster::writeRaster (dem.final, filename = "082\\082.tif", format = "GTiff", overwrite = T)

# 083
dem.083m <- raster ("083m\\083m.tif") 
dem.083d <- raster ("083d\\083d.tif")
dem.final <- raster::merge (dem.083m, dem.083d, tolerance = 1)
dir.create ("083")
raster::writeRaster (dem.final, filename = "083\\083.tif", format = "GTiff", overwrite = T)

# 092
list.092 <- list ("092b", "092c", "092a", "092e", "092f", "092g", "092h", "092i", 
                  "092j", "092k", "092l", "092m", "092n", "092o", "092p")
dem.092b <- raster ("092b\\092b.tif") 
dem.092c <- raster ("092c\\092c.tif")
dem.final <- raster::merge (dem.092b, dem.092c, tolerance = 1)
for (i in list.092) {
  dem <- raster (paste0 (i, "\\", i, ".tif"))
  dem.final <- raster::merge (dem.final, dem, tolerance = 1) # tolerance for raster with different origins
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092")
raster::writeRaster (dem.final, filename = "092\\092.tif", format = "GTiff", overwrite = T)

# 093
list.093 <- list ("093a", "093b", "093c", "093d", "093e", "093f", "093g", "093h", "093i", 
                  "093j", "093k", "093l", "093m", "093n", "093o", "093p")
dem.093b <- raster ("093b\\093b.tif") 
dem.093c <- raster ("093c\\093c.tif")
dem.final <- raster::merge (dem.093b, dem.093c, tolerance = 1)
for (i in list.093) {
  dem <- raster (paste0 (i, "\\", i, ".tif"))
  dem.final <- raster::merge (dem.final, dem, tolerance = 1) # tolerance for raster with different origins
}  
dir.create ("093")
raster::writeRaster (dem.final, filename = "093\\093.tif", format = "GTiff", overwrite = T)

# 094
list.094 <- list ("094a", "094b", "094c", "094d", "094e", "094f", "094g", "094h", "094i", 
                  "094j", "094k", "094l", "094m", "094n", "094o", "094p")
dem.094b <- raster ("094b\\094b.tif") 
dem.094c <- raster ("094c\\094c.tif")
dem.final <- raster::merge (dem.094b, dem.094c, tolerance = 1)
for (i in list.094) {
  dem <- raster (paste0 (i, "\\", i, ".tif"))
  dem.final <- raster::merge (dem.final, dem, tolerance = 1) # tolerance for raster with different origins
}  
dir.create ("094")
raster::writeRaster (dem.final, filename = "094\\094.tif", format = "GTiff", overwrite = T)

# 102
dem.102i <- raster ("102i\\102i.tif") 
dem.102p <- raster ("102p\\102p.tif")
dem.final <- raster::merge (dem.102i, dem.102p, tolerance = 1)
dir.create ("102")
raster::writeRaster (dem.final, filename = "102\\102.tif", format = "GTiff", overwrite = T)

# 103
list.103 <- list ("103a", "103c", "103f", "103g", "103h", "103i", 
                   "103p")
dem.103a <- raster ("103a\\103a.tif") 
dem.103c <- raster ("103c\\103c.tif")
dem.final <- raster::merge (dem.103a, dem.103c, tolerance = 1)
for (i in list.103) {
  dem <- raster (paste0 (i, "\\", i, ".tif"))
  dem.final <- raster::merge (dem.final, dem, tolerance = 1) # tolerance for raster with different origins
}  
dir.create ("103")
raster::writeRaster (dem.final, filename = "103\\103.tif", format = "GTiff", overwrite = T)

# 104
dem.104 <- raster ("104\\104.tif")
dem.104 <- raster::projectRaster (from = dem.104, 
                                    crs = "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
dem.final <- raster::merge (dem.104, dem.final, tolerance = 1)
raster::writeRaster (dem.final, filename = "104\\104.tif", format = "GTiff", overwrite = T)


list.104 <- list ("104a", "104b", "104f", "104g", "104h", "104i", 
                  "104j", "104k", "104l", "104m", "104n", "104o", "104p")
dem.104b <- raster ("104b\\104b.tif") 
dem.104a <- raster ("104a\\104a.tif")
dem.final <- raster::merge (dem.104b, dem.104a, tolerance = 1)
for (i in list.104) {
  dem <- raster (paste0 (i, "\\", i, ".tif"))
  dem.final <- raster::merge (dem.final, dem, tolerance = 1) # tolerance for raster with different origins
}  
dir.create ("104")
raster::writeRaster (dem.final, filename = "104\\104.tif", format = "GTiff", overwrite = T)

# 114
dem.114o <- raster ("114o\\114o.tif") 
dem.114p <- raster ("114p\\114p.tif")
dem.final <- raster::merge (dem.114o, dem.114p, tolerance = 1)
dir.create ("114")
raster::writeRaster (dem.final, filename = "114\\114.tif", format = "GTiff", overwrite = T)

#=================================
# merging all tiles together
#=================================
# ALL BC
dem.082 <- raster ("082\\082.tif")
dem.083 <- raster ("083\\083.tif")
dem.092 <- raster ("092\\092.tif")
dem.093 <- raster ("093\\093.tif")
dem.094 <- raster ("094\\094.tif")
dem.final <- raster::merge (dem.082, dem.083, tolerance = 1)
dem.final <- raster::merge (dem.final, dem.092, tolerance = 1)
dem.final <- raster::merge (dem.final, dem.093, tolerance = 1)
dem.final <- raster::merge (dem.final, dem.094, tolerance = 1)
raster::writeRaster (dem.final, filename = "all_bc\\dem_082_094_bc.tif", format = "GTiff", overwrite = T)

dem.102 <- raster ("102\\102.tif")
dem.103 <- raster ("103\\103.tif")
dem.104 <- raster ("104\\104.tif")
dem.114 <- raster ("114\\114.tif")
dem.final <- raster::merge (dem.102, dem.103, tolerance = 1)
dem.final <- raster::merge (dem.final, dem.104, tolerance = 1)
dem.final <- raster::merge (dem.final, dem.114, tolerance = 1)
dir.create ("all_bc")
raster::writeRaster (dem.final, filename = "all_bc\\dem_102_114_bc.tif", format = "GTiff", overwrite = T)

dem.102.114 <- raster ("all_bc\\dem_102_114_bc.tif")
dem.82.94 <- raster ("all_bc\\dem_082_094_bc.tif")
dem.final <- raster::merge (dem.82.94, dem.102.114, tolerance = 1)
dem.final <- raster::projectRaster (from = dem.all, 
                                    crs = "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
raster::writeRaster (dem.final, filename = "all_bc\\dem_all_bc.tif", format = "GTiff", overwrite = T,
                     dataType = "INT2U")

#=================================
# Calculate aspect and slope
#=================================
dem.all <- raster ("all_bc\\dem_all_bc_clip.tif") 
slope <- raster::terrain (dem.all, opt = 'slope', unit = "degrees", 
                          neighbors = 8) # neighbors = 8 uses 'Horn algorithm', which is best for rough surfaces (https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/terrain); most caribou live in 'rougher' terrain (mountains)
system.time ({
  raster::writeRaster (slope, filename = "all_bc\\slope_all_bc.tif", format = "GTiff", 
                     overwrite = T, dataType = "INT1U")
})

aspect.degrees <- raster::terrain (dem.all, opt = 'aspect', unit = "degrees", 
                                   neighbors = 8) # neighbors = 8 uses 'Horn algorithm', which is best for rough surfaces (https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/terrain); most caribou live in 'rougher' terrain (mountains)
raster::writeRaster (aspect.degrees, filename = "all_bc\\aspect_deg_all_bc.tif", format = "GTiff", overwrite = T)
aspect.radians <- raster::terrain (dem.all, opt = 'aspect', unit = "radians", 
                                   neighbors = 8)
raster::writeRaster (aspect.radians, filename = "all_bc\\aspect_rad_all_bc.tif", format = "GTiff", overwrite = T)
aspect.northing <- cos (aspect.radians)
raster::writeRaster (aspect.northing, filename = "all_bc\\aspect_northing_all_bc.tif", format = "GTiff", overwrite = T)
aspect.easting <- sin (aspect.radians)
raster::writeRaster (aspect.easting, filename = "all_bc\\aspect_easting_all_bc.tif", format = "GTiff", overwrite = T)
aspect.radians <- raster ("all_bc\\aspect_rad_all_bc.tif") # load the projected version

# is aspect = 0 flat or north?
# aspect.degrees <- raster ("all_bc\\aspect_deg_all_bc.tif") 
aspect.north <- reclassify (aspect.degrees, c (315,360,1,  0,45,1,  46,314,0), 
                            include.lowest = T, right = NA)
raster::writeRaster (aspect.north, filename = "all_bc\\aspect_north_all_bc.tif", format = "GTiff", overwrite = T)
aspect.east <- reclassify (aspect.degrees, c (146,360,0,  0,45,0,  46,145,1), 
                            include.lowest = T, right = NA)
raster::writeRaster (aspect.east, filename = "all_bc\\aspect_east_all_bc.tif", format = "GTiff", overwrite = T)
aspect.south <- reclassify (aspect.degrees, c (226,360,0,  0,135,0,  136,225,1), 
                           include.lowest = T, right = NA)
raster::writeRaster (aspect.south, filename = "all_bc\\aspect_south_all_bc.tif", format = "GTiff", overwrite = T)
aspect.west <- reclassify (aspect.degrees, c (316,360,0,  0,225,0,  226,315,1), 
                            include.lowest = T, right = NA)
raster::writeRaster (aspect.west, filename = "all_bc\\aspect_west_all_bc.tif", format = "GTiff", overwrite = T)

#=================================
# Conform rasters to hectares BC
#=================================
setwd ('//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/dem/all_bc')
dem.all<- raster ("dem_all_bc_proj3.tif")
plot(dem.all)
ProvRast <- raster (nrows = 15744, ncols = 17216, 
                    xmn = 159587.5, xmx = 1881187.5, 
                    ymn = 173787.5, ymx = 1748187.5, 
                    crs = proj4string (dem.all), 
                    resolution = c(100, 100), vals = 0) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R
dem.ha.bc <- raster::resample (dem.all, ProvRast, method = "ngb") # nearest neighbour resampling
raster::writeRaster (dem.ha.bc, filename = "all_bc\\dem_ha_bc.tif", format = "GTiff", overwrite = T)
## this takes way to long - use gdalwarp
#=================================
# Putting into Postgres DB
#=================================
require (RPostgreSQL)
require (rpostgis)
drv <- dbDriver ("PostgreSQL")
conn <- dbConnect (drv, # connection to the postgres db where you want to store the data
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
pgWriteRast (conn, "dem_all_bc", dem.all, overwrite = TRUE)
pgWriteRast (conn, "slope_all_bc", slope, overwrite = TRUE)





drv <- dbDriver ("PostgreSQL")
conn <- dbConnect(drv, 
                 host = "DC052586", # Kyle's computer name
                 user = "Tyler",
                 dbname = "postgres",
                 password = "tyler",
                 port = "5432")
dbListTables (conn)

rpostgispgWriteRast (conn = con, 
             name = "dem_all_bc",
             raster = dem.all)



library(sf)
library(RPostgreSQL)

#Create a DB connection
conn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')



#Use sf to write the sf object into the clus postgres database and name it herdtest - if it exists, overwrite
system.time({try(st_write(herd, conn, "herdtest", layer_options = "OVERWRITE=true"))})
#0.45s

#disconnect from the DB
dbDisconnect(conn)

#optionally convert the sf object to a SpatialPolygonsDataFrame
spdf<-as_Spatial(herd)



# http://rpubs.com/dgolicher/6373



