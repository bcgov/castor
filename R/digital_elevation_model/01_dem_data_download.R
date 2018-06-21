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
#  Script Purpose: Download digital elevation model adn put into postgres.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 19 June 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================
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
list.dem.100s <- list ("104m", "104n", "104o","104p", "104i", "104j", "104k", "104g", "104h", "104a", "103p",
                       "103i")
list.dem.90s <- list ("94m", "94n", "94o", "94p", "94i", "94j", "94k", "94l", "94e", "94f", "94g", 
                       "94h", "94a", "94b", "94c", "94d", "93m", "93n", "93o", "93p", "93i", "93j", 
                       "93k", "93l", "103i", "93e", "93f", "93g", "93h", "83e", "83c", "83d", "93a", 
                       "93b", "93c", "93d", "92n", "92o", "92p", "82m", "82n", "82o", "82j", "82k",
                       "82l", "82e", "82f", "82g")
for (i in list.dem.100s) { # loop though list to grab data for each tile; there are 32 'sub-tiles' within ech
  try ({# some tiles dont; exist; this skips them
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


for (i in list.dem.90s) { # loop though list to grab data for each tile; there are 32 'sub-tiles' within ech
  try ({# some tiles don't exist; this skips them
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


# crashed at tile 82g for some reason; manually doing that tile
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g16_w.dem.zip"),
            dest = paste0 ("82g16_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g16_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g16_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g16_e.dem.zip"),
            dest = paste0 ("82g16_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g16_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g16_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g15_w.dem.zip"),
            dest = paste0 ("82g15_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g15_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g15_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g15_e.dem.zip"),
            dest = paste0 ("82g15_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g15_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g15_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g14_w.dem.zip"),
            dest = paste0 ("82g14_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g14_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g14_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g14_e.dem.zip"),
            dest = paste0 ("82g14_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g14_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g14_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g13_w.dem.zip"),
            dest = paste0 ("82g13_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g13_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g13_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g13_e.dem.zip"),
            dest = paste0 ("82g13_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g13_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g13_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g12_w.dem.zip"),
            dest = paste0 ("82g12_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g12_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g12_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g12_e.dem.zip"),
            dest = paste0 ("82g12_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g12_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g12_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g11_w.dem.zip"),
            dest = paste0 ("82g11_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g11_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g11_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g11_e.dem.zip"),
            dest = paste0 ("82g11_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g11_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g11_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g10_w.dem.zip"),
            dest = paste0 ("82g10_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g10_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g10_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g10_e.dem.zip"),
            dest = paste0 ("82g10_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g10_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g10_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g09_w.dem.zip"),
            dest = paste0 ("82g09_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g09_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g09_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g09_e.dem.zip"),
            dest = paste0 ("82g09_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g09_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g09_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g08_w.dem.zip"),
            dest = paste0 ("82g08_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g08_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g08_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g08_e.dem.zip"),
            dest = paste0 ("82g08_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g08_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g08_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g07_w.dem.zip"),
            dest = paste0 ("82g07_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g07_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g07_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g07_e.dem.zip"),
            dest = paste0 ("82g07_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g07_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g07_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g06_w.dem.zip"),
            dest = paste0 ("82g06_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g06_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g06_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g06_e.dem.zip"),
            dest = paste0 ("82g06_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g06_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g06_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g05_w.dem.zip"),
            dest = paste0 ("82g05_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g05_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g05_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g05_e.dem.zip"),
            dest = paste0 ("82g05_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g05_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g05_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g04_w.dem.zip"),
            dest = paste0 ("82g04_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g04_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g04_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g04_e.dem.zip"),
            dest = paste0 ("82g04_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g04_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g04_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g03_w.dem.zip"),
            dest = paste0 ("82g03_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g03_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g03_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g03_e.dem.zip"),
            dest = paste0 ("82g03_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g03_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g03_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g02_w.dem.zip"),
            dest = paste0 ("82g02_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g02_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g02_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g02_e.dem.zip"),
            dest = paste0 ("82g02_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g02_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g02_e.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g01_w.dem.zip"),
            dest = paste0 ("82g01_w.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g01_w.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g01_w.dem.zip"))
  download (paste0 ("https://pub.data.gov.bc.ca/datasets/175624/82g/082g01_e.dem.zip"),
            dest = paste0 ("82g01_e.dem.zip"),
            mode = "wb")
  unzip (paste0 ("82g01_e.dem.zip"), 
         exdir = outPath)
  file.remove (paste0 ("82g01_e.dem.zip"))

# Merge rasters together

# 82m
dem.082m01.e <- raster ("082m01_e.dem") # load the first two to create the merged raster
dem.082m01.w <- raster ("082m01_w.dem")
dem.final <- raster::merge (dem.082m01.e, dem.082m01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.82m <- list.files (pattern = "^.*082m.*.dem$", full.names = TRUE)
for (i in filenames.82m) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082m\\082m.tif", format = "GTiff")

# 82e
dem.082e01.e <- raster ("082e01_e.dem") # load the first two to create the merged raster
dem.082e01.w <- raster ("082e01_w.dem")
dem.final <- raster::merge (dem.082e01.e, dem.082e01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.82e <- list.files (pattern = "^.*082e.*.dem$", full.names = TRUE)
for (i in filenames.82e) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082e\\082e.tif", format = "GTiff")

# 82f
dem.082f01.e <- raster ("082f01_e.dem") # load the first two to create the merged raster
dem.082f01.w <- raster ("082f01_w.dem")
dem.final <- raster::merge (dem.082f01.e, dem.082f01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.82f <- list.files (pattern = "^.*082f.*.dem$", full.names = TRUE)
for (i in filenames.82f) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082f\\082f.tif", format = "GTiff")

# 82g
dem.082g01.e <- raster ("082g01_e.dem") # load the first two to create the merged raster
dem.082g01.w <- raster ("082g01_w.dem")
dem.final <- raster::merge (dem.082g01.e, dem.082g01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.82g <- list.files (pattern = "^.*082g.*.dem$", full.names = TRUE)
for (i in filenames.82g) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082g\\082g.tif", format = "GTiff")

# 82k
dem.082k01.e <- raster ("082k01_e.dem") # load the first two to create the merged raster
dem.082k01.w <- raster ("082k01_w.dem")
dem.final <- raster::merge (dem.082k01.e, dem.082k01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.82k <- list.files (pattern = "^.*082k.*.dem$", full.names = TRUE)
for (i in filenames.82k) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082k\\082k.tif", format = "GTiff")

# 82l
dem.082l01.e <- raster ("082l01_e.dem") # load the first two to create the merged raster
dem.082l01.w <- raster ("082l01_w.dem")
dem.final <- raster::merge (dem.082l01.e, dem.082l01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.82l <- list.files (pattern = "^.*082l.*.dem$", full.names = TRUE)
for (i in filenames.82l) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "082l\\082l.tif", format = "GTiff")

# 83d
dem.083d01.e <- raster ("083d01_e.dem") # load the first two to create the merged raster
dem.083d01.w <- raster ("083d01_w.dem")
dem.final <- raster::merge (dem.083d01.e, dem.083d01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.83d <- list.files (pattern = "^.*083d.*.dem$", full.names = TRUE)
for (i in filenames.83d) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
raster::writeRaster (dem.final, filename = "083d\\083d.tif", format = "GTiff")

# 92n
dem.092n01.e <- raster ("092n01_e.dem") # load the first two to create the merged raster
dem.092n01.w <- raster ("092n01_w.dem")
dem.final <- raster::merge (dem.092n01.e, dem.092n01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.92n <- list.files (pattern = "^.*092n.*.dem$", full.names = TRUE)
for (i in filenames.92n) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092n")
raster::writeRaster (dem.final, filename = "092n\\092n.tif", format = "GTiff")

# 92o
dem.092o01.e <- raster ("092o01_e.dem") # load the first two to create the merged raster
dem.092o01.w <- raster ("092o01_w.dem")
dem.final <- raster::merge (dem.092o01.e, dem.092o01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.92o <- list.files (pattern = "^.*092o.*.dem$", full.names = TRUE)
for (i in filenames.92o) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092o")
raster::writeRaster (dem.final, filename = "092o\\092o.tif", format = "GTiff")

# 92p
dem.092p01.e <- raster ("092p01_e.dem") # load the first two to create the merged raster
dem.092p01.w <- raster ("092p01_w.dem")
dem.final <- raster::merge (dem.092p01.e, dem.092p01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
filenames.92p <- list.files (pattern = "^.*092p.*.dem$", full.names = TRUE)
for (i in filenames.92p) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  
# project to WGS84
dem.final <- raster::projectRaster (from = dem.final, crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
dir.create ("092p")
raster::writeRaster (dem.final, filename = "092p\\092p.tif", format = "GTiff")

# 93a
dem.093a01.e <- raster ("093a01_e.dem") # load the first two to create the merged raster
dem.093a01.w <- raster ("093a01_w.dem")
dem.final <- raster::merge (dem.093a01.e, dem.093a01.w)
# tried looping trhough all data, but was filling up the temp folder and C: drive
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
dem.093b01.e <- raster ("093b01_e.dem") # load the first two to create the merged raster
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








tempdir ()


plot (dem.final)






  
                         
  