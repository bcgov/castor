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
filenames <- list.files (pattern = "*.dem", full.names = TRUE)
dem.104m.e <- raster ("104m01_e.dem") # load the first two to create the merged raster
dem.104m.w <- raster ("104m01_w.dem")
dem.final <- raster::merge (dem.104m.e, dem.104m.w)

for (i in filenames) {
  dem <- raster (i)
  dem.final <- raster::merge (dem.final, dem)
}  

tempdir ()


plot (dem.final)






  
                         
  