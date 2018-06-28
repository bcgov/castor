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
#  Script Name: 01_caribou_protected_areas_download
#  Script Version: 1.0
#  Script Purpose: Download data on provincial protected areas for caribou.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                  
#  Script Date: 19 June 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================

# packages
require (downloader)
require (rgdal) 
require (RPostgreSQL)
require (rpostgis)
# require (postGIStools)
require (lubridate)

# data directory
# setwd ('\\spatialfiles2.bcgov\\archive\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\')
setwd ('T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou_protected_areas\\') # directory through my drive path
       
# Manual download
# UWR :https://catalogue.data.gov.bc.ca/dataset/ungulate-winter-range-approved/resource/5822def0-e253-483f-989a-f1392f124ddc
# UWR proposed: https://catalogue.data.gov.bc.ca/dataset/ungulate-winter-range-proposed
# WHA: https://catalogue.data.gov.bc.ca/dataset/wildlife-habitat-areas-approved/resource/626b498d-b1e5-4a9b-90e8-b9208844f93a
# WHA proposed: https://catalogue.data.gov.bc.ca/dataset/wildlife-habitat-areas-proposed
# Parks: https://catalogue.data.gov.bc.ca/dataset/bc-parks-ecological-reserves-and-protected-areas/resource/2d022ea1-31f6-4749-bdf8-9d117ab4e847

# BCGW file names:
# WHA: WHSE_WILDLIFE_MANAGEMENT.WCP_WILDLIFE_HABITAT_AREA_POLY
# WHA proposed: WHSE_WILDLIFE_MANAGEMENT.WCP_WHA_PROPOSED_SP
# UWR: WHSE_WILDLIFE_MANAGEMENT.WCP_UNGULATE_WINTER_RANGE_SP
# Parks: WHSE_TANTALIS.TA_PARK_ECORES_PA_SVW

# Follwoign scripts for getting specific to caribou
# Load data
uwr <- readOGR (dsn = "caribou_protected_areas.gdb",
                layer = "uwr_20180619")
uwr.prop <- readOGR (dsn = "caribou_protected_areas.gdb",
                     layer = "uwr_proposed_20180619")
wha <- readOGR (dsn = "caribou_protected_areas.gdb",
                     layer = "wha_20180619")
wha.prop <- readOGR (dsn = "caribou_protected_areas.gdb",
                      layer = "wha_proposed_20180619")
parks <- readOGR (dsn = "caribou_protected_areas.gdb",
                  layer = "bc_parks_protected_areas_20180619")

#=======================================
# Define the date field and extract year
#=======================================
uwr@data$DATE_OF_NOTICE <- as.Date (uwr@data$DATE_OF_NOTICE)
uwr@data$APPROVAL_DATE <- as.Date (uwr@data$APPROVAL_DATE)
uwr@data$APPROVAL_YEAR <- year (uwr@data$APPROVAL_DATE)

wha@data$DATE_OF_NOTICE <- as.Date (wha@data$NOTICE_DATE)
wha@data$APPROVAL_DATE <- as.Date (wha@data$APPROVAL_DATE)
wha@data$APPROVAL_YEAR <- year (wha@data$APPROVAL_DATE)

#========================================
# Filter caribou-specific protected areas
#========
# UWRs
#========
uwr@data$SPECIES_2 <- as.character(uwr@data$SPECIES_2) # first need to replace NA values
uwr@data$SPECIES_2 [is.na (uwr@data$SPECIES_2)] <- "N/A"
uwr@data$SPECIES_2 <- as.factor(uwr@data$SPECIES_2)

uwr.prop@data$SPECIES_2 <- as.character(uwr.prop@data$SPECIES_2) # first need to replace NA values
uwr.prop@data$SPECIES_2 [is.na (uwr.prop@data$SPECIES_2)] <- "N/A"
uwr.prop@data$SPECIES_2 <- as.factor(uwr.prop@data$SPECIES_2)

uwr.caribou <- uwr [uwr$SPECIES_1 == "M-RATA-15" | 
                    uwr$SPECIES_1 == "M-RATA-01" |
                    uwr$SPECIES_1 == "M-RATA-14" |
                    uwr$SPECIES_1 == "M-RATA"  |
                    uwr$SPECIES_2 == "M-RATA-15" |
                    uwr$SPECIES_2 == "M-RATA-01" |
                    uwr$SPECIES_2 == "M-RATA-14" |
                    uwr$SPECIES_2 == "M-RATA" ,] 

uwr.prop.caribou <- uwr.prop [uwr.prop$SPECIES_1 == "M-RATA-15" | 
                              uwr.prop$SPECIES_1 == "M-RATA-01" |
                              uwr.prop$SPECIES_1 == "M-RATA-14" |
                              uwr.prop$SPECIES_1 == "M-RATA"  |
                              uwr.prop$SPECIES_2 == "M-RATA-15" |
                              uwr.prop$SPECIES_2 == "M-RATA-01" |
                              uwr.prop$SPECIES_2 == "M-RATA-14" |
                              uwr.prop$SPECIES_2 == "M-RATA" ,] 

# if you want no harvest vs. conditional harvest types
uwr.caribou.no.harvest <- uwr.caribou [uwr.caribou$TIMBER_HARVEST_CODE == "NO HARVEST ZONE", ] 
uwr.caribou.cond.harvest <- uwr.caribou [uwr.caribou$TIMBER_HARVEST_CODE == "CONDITIONAL HARVEST ZONE", ] 

uwr.prop.caribou.no.harvest <- uwr.prop.caribou [uwr.prop.caribou$TIMBER_HARVEST_CODE == "NO HARVEST ZONE", ] 
uwr.prop.caribou.no.constraint <- uwr.prop.caribou [uwr.prop.caribou$TIMBER_HARVEST_CODE == "NO HARVEST CONSTRAINTS", ] 

#========
# WHAs
#========
wha.prop@data$TIMBER_HARVEST_CODE <- as.character(wha.prop@data$TIMBER_HARVEST_CODE) # first need to replace NA values
wha.prop@data$TIMBER_HARVEST_CODE [is.na (wha.prop@data$TIMBER_HARVEST_CODE)] <- "N/A"
wha.prop@data$TIMBER_HARVEST_CODE <- as.factor(wha.prop@data$TIMBER_HARVEST_CODE)

wha.caribou <- wha [wha$COMMON_SPECIES_NAME == "Northern Caribou" | 
                    wha$COMMON_SPECIES_NAME ==  "Mountain Caribou" |
                    wha$COMMON_SPECIES_NAME ==  "Boreal Caribou" |
                    wha$COMMON_SPECIES_NAME ==  "Caribou" ,] 

wha.prop.caribou <- wha.prop [wha.prop$COMMON_SPECIES_NAME == "Northern Caribou" | 
                              wha.prop$COMMON_SPECIES_NAME ==  "Mountain Caribou" |
                              wha.prop$COMMON_SPECIES_NAME ==  "Boreal Caribou" |
                              wha.prop$COMMON_SPECIES_NAME ==  "Caribou" ,] 

# if you want no harvest vs. conditional harvest types
wha.caribou.no.harvest <- wha.caribou [wha.caribou$TIMBER_HARVEST_CODE == "NO HARVEST ZONE", ] 
wha.caribou.cond.harvest <- wha.caribou [wha.caribou$TIMBER_HARVEST_CODE == "CONDITIONAL HARVEST ZONE", ] 

wha.prop.caribou.no.harvest <- wha.prop.caribou [wha.prop.caribou$TIMBER_HARVEST_CODE == "NO HARVEST ZONE" |
                                                 wha.prop.caribou$TIMBER_HARVEST_CODE == "NO HARVEST", ] 
wha.prop.caribou.cond.harvest <- wha.prop.caribou [wha.prop.caribou$TIMBER_HARVEST_CODE == "CONDITIONAL HARVEST ZONE", ] # should be empty

#========
# Parks
#========
# Use 'as-is'; not clear to me at this point if these have more or less value for caribou
# could 'symbolize' by PROTECTED_LANDS_DESIGNATION: PROVINCIAL PARK, ECOLOGICAL RESERVE PROTECTED AREA, RECREATION AREA

#=================================
# Putting into Kyle's Postgres DB
#=================================
drv <- dbDriver ("PostgreSQL")
con <- dbConnect(drv, 
                 host = "DC052586", # Kyle's computer name
                 user = "Tyler",
                 dbname = "clus",
                 password = "tyler",
                 port = "5432")
rpostgis::pgInsert (conn = con,
                    name = "20180627_uwr_caribou_no_harvest",
                    data.obj = uwr.caribou.no.harvest,
                    new.id = "gid")
rpostgis::pgInsert (conn = con,
                    name = "20180627_uwr_caribou_conditional_harvest",
                    data.obj = uwr.caribou.cond.harvest,
                    new.id = "gid")
rpostgis::pgInsert (conn = con,
                    name = "20180627_uwr_proposed_caribou_no_harvest",
                    data.obj = uwr.prop.caribou.no.harvest,
                    new.id = "gid")
rpostgis::pgInsert (conn = con,
                    name = "20180627_uwr_proposed_caribou_no_constraints",
                    data.obj = uwr.prop.caribou.no.constraint,
                    new.id = "gid")
rpostgis::pgInsert (conn = con,
                    name = "20180627_wha_caribou_no_harvest",
                    data.obj = wha.caribou.no.harvest,
                    new.id = "gid")
rpostgis::pgInsert (conn = con,
                    name = "20180627_wha_caribou_conditional_harvest",
                    data.obj = wha.caribou.cond.harvest,
                    new.id = "gid")
rpostgis::pgInsert (conn = con,
                    name = "20180627_wha_proposed_caribou_no_harvest",
                    data.obj = wha.prop.caribou.no.harvest,
                    new.id = "gid")
# rpostgis::pgInsert (conn = con,
#                    name = "20180627_wha_proposed_caribou_conditional_harvest",
#                    data.obj = wha.prop.caribou.cond.harvest,
#                    new.id = "gid")
# dbListTables(con)


