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
#  Script Name: 02_data_prep.R
#  Script Version: 1.0
#  Script Purpose: Prepare data for provincial caribou habitat model analysis.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 25 July 2018
#  R Version: 3.5.1
#  R Packages: sf, RPostgreSQL, rpostgis, fasterize, raster, dplyr
#  Data: 
#=================================

#=================================
# Set data directory
#=================================
setwd ('C:\\Work\\caribou\\clus_data\\')
options (scipen = 999)

#=================================
# Load packages
#=================================
require (sf)
require (RPostgreSQL)
require (rpostgis)
require (fasterize)
require (raster)
require (dplyr)

# require (sp) # spatial package; particulary useful for working with vector data
# require (raster) # for working with and processing raster data; 
# require (rgeos) # geoprocessing functions
# require (rgdal) # for loading and writing spatial data
# require (maptools)
# require (spatstat)
# require (adehabitatHR)

#===================================================
# Create functions and empty ha BC raster
#==================================================
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")

writeRasterQuery <- function (schemaraster, rasterR) {
  conn <- dbConnect (dbDriver ("PostgreSQL"), 
                     host = "",
                     user = "postgres",
                     dbname = "postgres",
                     password = "postgres",
                     port = "5432")
  on.exit (dbDisconnect (conn))
  pgWriteRast (conn, schemaraster, rasterR, overwrite = TRUE)
}


writeTableQuery <- function (dataR, tablename){
  conn <- dbConnect (dbDriver("PostgreSQL"), 
                     host = "",
                     user = "postgres",
                     dbname = "postgres",
                     password = "postgres",
                     port = "5432")
  on.exit (dbDisconnect (conn))
  st_write (obj = dataR, dsn = conn, layer = tablename)
}

writeCutblockRaster <- function (harvest.year) {
  writeRaster (
    fasterize (
      dplyr::filter (
        cutblocks, 
        HARVEST_YEAR == harvest.year
      ), 
      ProvRast,  
      field = NULL, 
      background = 0
    ),
    filename = paste0 ("cutblocks\\cutblock_tiffs\\raster_cutblocks_", harvest.year, ".tiff"),
    format = "GTiff", 
    datatype = 'INT1U'
  )
}

writeFireRaster <- function (fire.year) {
  writeRaster (
    fasterize (
      dplyr::filter (
        fire, 
        FIRE_YEAR == fire.year
      ), 
      ProvRast,  
      field = NULL, 
      background = 0
    ),
    filename = paste0 ("fire\\fire_tiffs\\raster_fire_", fire.year, ".tiff"),
    format = "GTiff", 
    datatype = 'INT1U'
  )
}

# writeCutblockRaster <- function (harvest.year) {
#  conn <- dbConnect (dbDriver ("PostgreSQL"), 
#                     host = "",
#                     user = "postgres",
#                     dbname = "postgres",
#                     password = "postgres",
#                     port = "5432")
#  on.exit (dbDisconnect (conn))
#  pgWriteRast (conn, c ("human", paste0 ("raster_cutblocks_", harvest.year)), fasterize (
#    dplyr::filter (cutblocks, HARVEST_YEAR == harvest.year), 
#    ProvRast,  
#    field = NULL, 
#    background = 0), overwrite = TRUE)
#}

# ha BC standard raster
ProvRast <- raster (nrows = 15744, ncols = 17216, 
                    xmn = 159587.5, xmx = 1881187.5, 
                    ymn = 173787.5, ymx = 1748187.5,                      
                    crs = 3005, 
                    resolution = c (100, 100), vals = 0) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R
# writeRasterQuery (c ("admin_boundaries", "raster_ha_bc"), ProvRast)
# ProvRast <- pgGetRast (conn, c ("admin_boundaries", "raster_ha_bc"))

#===================================================
# BEC data
#==================================================
# bec as polygon and rasterized to ha bc
bec <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                    layer = "bec_poly_20180725")
writeTableQuery (bec, c ("vegetation", "bec_poly_20180725"))
ras.bec.zone <- fasterize (bec, ProvRast, field = "ZONE" , 
                           fun = "last") # takes the 'last' polygon value for the raster; ideally would use the most common, but couldn't find a function for that
writeRasterQuery (c ("vegetation", "raster_bec_zone_current"), ras.bec.zone)
lut_bec_zone_current <- data.frame (levels (bec$ZONE))
lut_bec_zone_current$raster_integer <- c (1:16)
dbWriteTable (conn, c ("vegetation", "lut_bec_current"), lut_bec_zone_current)

#===================================================
# Cutblocks
#==================================================
# idea here is to create rasters of cutblocks by year (similar to what STSM models output), 
# then explicitly test for effects of age on caribou selection using regression models
cutblocks <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                          layer = "cutblocks_20180725") 
writeTableQuery (cutblocks, c ("human", "cutblocks_20180725"))

cut.years <- sort (unique (cutblocks$HARVEST_YEAR)) # identify the cutblock years
cut.years.for.raster <- cut.years[50:107]

# need to filter data by year because unable to run functions (see below) on full dataset
cutblocks.2017 <- dplyr::filter (cutblocks, HARVEST_YEAR == 2017)
ras.cutblocks.2017 <- fasterize (cutblocks.2017, ProvRast, 
                                 field = NULL,# raster cells that were cut get in 2017 get a value of 1
                                 background = 0) # unharvested raster cells get value = 0 
raster::writeRaster (ras.cutblocks.2017, 
                     filename = "cutblocks\\cutblock_tiffs\\raster_cutblocks_2017.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U')
# there appears to be memory issues with saivng to postgres, so saving as TIFFs for now
# writeRasterQuery (c ("human", "raster_cutblocks_2017"), ras.cutblocks.2017) 
rm (cutblocks.2017, ras.cutblocks.2017)
gc () # free up some RAM
# 2017 done as test, the rest done with the writeCutblockRaster function 
writeCutblockRaster (2016) # testing fucntion
gc ()
system.time (writeCutblockRaster (2015))
gc ()

for (i in cut.years.for.raster) { # run through list for 1957 to 2014
writeCutblockRaster (i)
gc ()
}

cutblocks.pre.1957 <- dplyr::filter (cutblocks, HARVEST_YEAR < 1957) # do one for all pre 1957 cutblocks
ras.cutblocks.pre.1957 <- fasterize (cutblocks.pre.1957, ProvRast, 
                                      field = NULL,# raster cells that were cut get in 2017 get a value of 1
                                      background = 0) # unharvested raster cells get value = 0 
raster::writeRaster (ras.cutblocks.pre.1957, 
                     filename = "cutblocks\\cutblock_tiffs\\raster_cutblocks_pre1957.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U')

# calculate last year the raster was cut
# ras.cutblocks <- fasterize (cutblocks, ProvRast, field = "HARVEST_YEAR" , 
#                            fun = "last",
#                            background = 0) # unharvested rasters get value = 0 

#===================================================
# Fire
#==================================================
fire <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                    layer = "fire_historic_20180725")
writeTableQuery (fire, c ("disturbance", "fire_historic_20180725"))
fire.years <- sort (unique (fire$FIRE_YEAR)) # identify the fire years
fire.years.for.raster <- fire.years [41:101]

for (i in fire.years.for.raster) { # run through list for 1957 to 2017
  writeFireRaster (i)
  gc ()
}

fire.pre.1957 <- dplyr::filter (fire, FIRE_YEAR < 1957) # do one for all pre 1957 cutblocks
ras.fire.pre.1957 <- fasterize (fire.pre.1957, ProvRast, 
                                     field = NULL,# raster cells that were cut get in 2017 get a value of 1
                                     background = 0) # unharvested raster cells get value = 0 
raster::writeRaster (ras.fire.pre.1957, 
                     filename = "fire\\fire_tiffs\\raster_cutblocks_pre1957.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U')
gc ()

#===================================================
# Mines
#==================================================
# Use CE data
mine <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                     layer = "ce_mine_2015_20180814")
writeTableQuery (mine, c ("human", "mines_ce_2015"))
# raster of mines
ras.mine <- fasterize (mine, ProvRast, 
                       field = NULL,# raster cells that are mines get a value of 1
                       background = 0) 
raster::writeRaster (ras.mine, 
                     filename = "mine\\raster_mines_ce_2015.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U')
writeRasterQuery (c ("human", "raster_mines_ce_2015"), ras.mine)
# raster of distance to mines
# make values NA where mine polygon intesects raster
ras.mine.na <- raster::mask (ras.mine, mine)
# calculate distance to mine
# NOTE: the task below was done uisng QGIS as my computer maxed-out on RAM when trying to run this function in R
ras.mine.dist <- raster::distance (ras.mine.na, format = "GTiff", dataType = "INT4U")
writeRasterQuery (c ("human", "raster_dist_to_mines_ce_2015"), ras.mine.dist)


#===================================================
# Pipeline
#==================================================
# Built this following the CE protocol
# Completed the following analysis using ArcGIS

# Data sources
# 1. WHSE_TANTALIS.TA_CROWN_TENURES_SVW
#     Selection Criteria:
#     TENURE_PURPOSE = 'UTILITY' AND TENURE_SUBPURPOSE = 'GAS AND OIL PIPELINE' AND 
#     TENURE_TYPE <> 'RESERVE/NOTATION'
#     Name in GDB: tantalis_crown_tenures_pipelines_20180814
#     manually deleted PRGT and CGL

# 2. WHSE_TANTALIS.TA_SURVEYED_ROW_PARCELS_SVW
#     Selection Criteria:
#     FEATURE_CODE = 'FA91300120' OR FEATURE_CODE = 'FA91400120'
#     Name in GDB: tantalis_surveyed_row_pipelines_20180814

# 3. WHSE_BASEMAPPING.TRIM_CULTURAL_LINES 
#     Selection Criteria:
#     FCODE = 'EA21400000' (i.e. pipeline)
#     Name in GDB: trim_lines_pieplines_20180814

# 4. pipeline_post2006_20180725
#     Deleted PRGT adn CGL (not built yet)
#     PROPONENT = 'Coastal GasLink Pipeline Ltd.' OR PROPONENT = 'Prince Rupert Gas Transmission Ltd.'

# 5. pipeline_post2016_20180725
#     Deleted PRGT adn CGL (not built yet)
#     PROPONENT = 'Coastal GasLink Pipeline Ltd.' OR PROPONENT = 'Prince Rupert Gas Transmission Ltd.'

# ArcGIS steps:
# buffered 'tantalis_crown_tenures_pipelines_20180814' 30m each side (following CE protocol to remove overlaps <30m away)
# erase 'tantalis_surveyed_row_pipelines_20180814' within 30m buffered 'tantalis_crown_tenures_pipelines_20180814' = tantalis_surveyed_row_pipelines_erased30m_20180814
# merged 'tantalis_surveyed_row_pipelines_erased30m_20180814' and 'tantalis_crown_tenures_pipelines_20180814' = tantalis_all_pipelines_20180815
# buffered 'tantalis_all_pipelines_20180815' 30m each side = tantalis_all_pipelines_buff30m_20180815
# erase 'pipeline_post2006_20180725' within 30m buffered 'tantalis_all_pipelines_buff30m_20180815' = pipeline_post2006_erase_20180815
# merged 'tantalis_all_pipelines_20180815' and 'pipeline_post2006_erase_20180815' = all_pipelines_2006_20180815
# buffered pipeline_post2016_20180725' by 15m each side to polygonize line data = pipeline_post2016_buff15m_20180815
# buffered 'trim_lines_pieplines_20180814' by 15m each side to polygonize line data = trim_lines_pipelines_buff15m_20180814
# buffered 'all_pipelines_2006_20180815' 30m each side = all_pipelines_2006_buff30m_20180815
# erase 'trim_lines_pipelines_buff15m_20180814' within 30m buffered 'all_pipelines_2006_buff30m_20180815' = trim_lines_pipelines_buff15m_erase_20180815
# merged 'all_pipelines_2006_20180815' and 'trim_lines_pipelines_buff15m_erase_20180815' = pipelines_all_v2_20180815
# buffered 'pipelines_all_v2_20180815' 30m each side = pipelines_all_v2_buff30m_20180815
# erase 'pipeline_post2016_buff15m_20180815' within 30m buffered 'pipelines_all_v2_buff30m_20180815' = pipeline_post2016_buff15m_erase_20180815
# merged 'pipeline_post2016_buff15m_erase_20180815' and 'pipeline_post2016_buff15m_20180815' = pipelines_final_20180815
# buffered by 50m for rasterziation; unbuffered resulted in some raster cells getting a 0 value for pipeline = pipelines_all_final_buff50m_20180815
pipeline <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                     layer = "pipelines_all_final_buff50m_20180815")
pipeline <- sf::st_cast (pipeline, to = "MULTIPOLYGON") # this converts from "MULTISURFACE"
writeTableQuery (pipeline, c ("human", "pipelines_20180815"))
# raster of pipelines
ras.pipeline <- fasterize (pipeline, ProvRast, 
                            field = NULL,# raster cells that are pipelines get a value of 1
                            background = 0) 
raster::writeRaster (ras.pipeline, 
                     filename = "pipelines\\raster_pipelines_20180815.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_pipelines_20180815"), ras.pipeline)
# raster of distance to pipelines
# make values NA where pipeline polygon intesects raster
ras.pipline.na <- raster::mask (ras.pipeline, pipeline)
# calculate distance to pipelines
# NOTE: the task below was done uisng QGIS Raster>Analysis>Proximity(raster Distance) tool, as my computer maxed-out on RAM when trying to run this function in R
ras.pipeline.dist <- raster::distance (ras.pipline.na, format = "GTiff", dataType = "INT4U")
writeRasterQuery (c ("human", "raster_dist_to_pipeline"), ras.pipeline.dist)

#===================================================
# Wells and facilities
#==================================================

# Built this following the CE protocol
# Completed the following analysis using ArcGIS

# Buffered 'oil_gas_facility_pre2016_20180725' by 30m = 'oil_gas_facility_pre2016_buff30m_20180725'
# Erased 'oil_gas_facility_post2016_20180725' within oil_gas_facility_pre2016_buff30m_20180725 = oil_gas_facility_post2016_erase_20180725
# Merged oil_gas_facility_pre2016_20180725 and oil_gas_facility_post2016_erase_20180725 = oil_gas_facility_all_20180725
# Buffered 'oil_gas_facility_all_20180725' by 30m = 'oil_gas_facility_all_buff30m_20180816'
# Erased 'well_surface_hole_20180815' within 'oil_gas_facility_all_buff30m_20180816' = well_surface_hole_erase_20180815
# Merged oil_gas_facility_all_20180725 with well_surface_hole_erase_20180815 = oil_gas_facility_wells_all_20180816
# Buffered oil_gas_facility_wells_all_20180816 by 30m = oil_gas_facility_wells_all_buff30m_20180816
# Erased trim_points_wells_20180815 within oil_gas_facility_wells_all_buff30m_20180816 = trim_points_wells_erase_20180815
# converted oil_gas_facility_wells_all_point_20180816 from MULTIPOINT to POINT = oil_gas_facility_wells_all_point_20180816
# Merged oil_gas_facility_wells_all_20180816 and trim_points_wells_erase_20180815 = oil_gas_facility_wells_final_20180816
# Buffered by 50m to re-create well pad = oil_gas_facility_wells_final_poly_20180816
# Buffered by 100m for rasterization = oil_gas_facility_wells_final_buff100m_20180816

wells <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                         layer = "oil_gas_facility_wells_final_poly_20180816")
wells <- sf::st_cast (wells, to = "MULTIPOLYGON")
writeTableQuery (wells, c ("human", "oil_gas_facility_wells_20180815"))
# raster of pipelines
wells <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                      layer = "oil_gas_facility_wells_final_buff100m_20180816")
gc ()
wells <- sf::st_cast (wells, to = "MULTIPOLYGON")
ras.wells <- fasterize (wells, ProvRast, 
                        field = NULL,# raster cells that are wells get a value of 1
                        background = 0) 
raster::writeRaster (ras.wells, 
                     filename = "wells\\raster_wells_facilities_20180815.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_wells_facilities_20180815"), ras.wells)
# raster of distance to wells
# make values NA where well polygon intesects raster
ras.wells.na <- raster::mask (ras.wells, wells)
# calculate distance to mine
# NOTE: the task below was done uisng QGIS as my computer maxed-out on RAM when trying to run this function in R
ras.wells.dist <- raster::distance (ras.wells.na, format = "GTiff", dataType = "INT4U")
writeRasterQuery (c ("human", "raster_dist_to_pipeline"), ras.wells.dist)

#===================================================
# Seismic lines
#==================================================
# used the CE data, NE_Seismic and Remainder_Seismic merged together
seismic <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                      layer = "seismic_ce_2015")
seismic <- sf::st_cast (seismic, to = "MULTIPOLYGON")
writeTableQuery (seismic, c ("human", "seismic_ce_2015"))
seismic.buff100 <- sf::st_buffer (seismic, dist = 100)
ras.seismic <- fasterize (seismic.buff100, ProvRast, 
                        field = NULL,# raster cells that are wells get a value of 1
                        background = 0) 
raster::writeRaster (ras.seismic, 
                     filename = "seismic\\raster_seismic_20180816.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_seismic_20180816"), ras.seismic)
# didn't do a raster of distance to seismic because of high desity of seismic lines at a 1ha resolution

#===================================================
# Ski Resorts
#==================================================
ski <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "ski_resorts_20180813")
writeTableQuery (ski, c ("human", "ski_resorts_20180813"))
ski.buff100 <- sf::st_buffer (ski, dist = 100)
ras.ski <- fasterize (ski.buff100, ProvRast, 
                          field = NULL,# raster cells that are wells get a value of 1
                          background = 0) 
raster::writeRaster (ras.ski, 
                     filename = "ski\\raster_ski_resorts_20180816.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_ski_resorts_20180816"), ras.ski)

#===================================================
# Wind power
#==================================================
power.100 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                          layer = "powerplant_100mw_20180816")
power.1 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                          layer = "power_renewable_1mw_20180816")

# select by country and province and wind type
power.100.wind <- dplyr::filter (power.100, Country == "Canada")
power.100.wind <- dplyr::filter (power.100.wind, StateProv == "British Columbia")
power.100.wind <- dplyr::filter (power.100.wind, PrimSource == "Wind")

power.1.wind <- dplyr::filter (power.1, Country == "Canada")
power.1.wind <- dplyr::filter (power.1.wind, StateProv == "British Columbia")
power.1.wind <- dplyr::filter (power.1.wind, PrimSource == "Wind")

power.wind <- rbind (power.100.wind, power.1.wind) # merge the SF Objects into 1
power.wind <- st_transform (power.wind, 3005) # project to BC Albers

writeTableQuery (power.wind, c ("human", "wind_power_20180817"))
power.wind.buff100 <- sf::st_buffer (power.wind, dist = 100)
ras.wind <- fasterize (power.wind.buff100, ProvRast, 
                       field = NULL,# raster cells that are wells get a value of 1
                       background = 0) 
raster::writeRaster (ras.wind, 
                     filename = "wind\\raster_wind_power_20180816.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_wind_power_20180816"), ras.wind)

#===================================================
# Transmission Lines
#==================================================
trans.line <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                          layer = "transmission_line_20180725")
writeTableQuery (trans.line, c ("human", "transmission_line_20180817"))
trans.line.buff100 <- sf::st_buffer (trans.line, dist = 100)
ras.trans.line <- fasterize (trans.line.buff100, ProvRast, 
                              field = NULL,# raster cells that are wells get a value of 1
                              background = 0) 
raster::writeRaster (ras.trans.line, 
                     filename = "transmission_line\\raster_transmission_line_20180816.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_transmission_line_20180816"), ras.trans.line)

#===================================================
# Railway
#==================================================
rail <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                           layer = "railway_20180725")
writeTableQuery (rail, c ("human", "railway_20180817"))
rail.buff100 <- sf::st_buffer (rail, dist = 100)
ras.rail <- fasterize (rail.buff100, ProvRast, 
                       field = NULL,# raster cells that are wells get a value of 1
                       background = 0) 
raster::writeRaster (ras.rail, 
                     filename = "railway\\raster_railway_20180816.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_railway_20180816"), ras.rail)

#===================================================
# Watercourses
#==================================================
water <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                     layer = "watercourses_20180817")
writeTableQuery (water, c ("water", "watercourses_20180817"))
ras.water <- fasterize (water, ProvRast, 
                        field = NULL,# raster cells that are wells get a value of 1
                        background = 0) 
raster::writeRaster (ras.water, 
                     filename = "water\\raster_watercourses_20180816.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("water", "raster_watercourses_20180816"), ras.water)

#===================================================
# Lakes
#==================================================
lakes <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                      layer = "lakes_20180817")
writeTableQuery (lakes, c ("water", "lakes_20180817"))
ras.lakes <- fasterize (lakes, ProvRast, 
                        field = NULL,# raster cells that are wells get a value of 1
                        background = 0) 
raster::writeRaster (ras.lakes, 
                     filename = "water\\raster_lakes_20180816.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("water", "raster_lakes_20180816"), ras.lakes)

#===================================================
# Agriculture
#==================================================
agriculture <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                      layer = "agriculture_ce_2015")
writeTableQuery (agriculture, c ("human", "agriculture_ce_2015"))
ras.agriculture <- fasterize (agriculture, ProvRast, 
                        field = NULL,# raster cells that are wells get a value of 1
                        background = 0) 
raster::writeRaster (ras.agriculture, 
                     filename = "agriculture\\raster_agriculture_ce_2015.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("human", "raster_agriculture_ce_2015"), ras.agriculture)


#===================================================
# Beetle damage
#==================================================
# focussed on four major bark beetles that cause damage:
# Mountain pine beetle (IBM), spruce beetle (IBS), dougals-fir beetle (IBD ) and western balsam bark beetle (IBB)
# https://www2.gov.bc.ca/gov/content/industry/forestry/managing-our-forest-resources/forest-health/forest-pests/bark-beetles
# Also Babita Bains, pers. comm. suggested bark beetles are most signfciant issue; 
# also, only really feasible to measure mortality severity form aerial

#########
# 2017 #
#######
fh.2017 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2017")
writeTableQuery (fh.2017, c ("vegetation", "forest_health_2017"))
bark.beetles.2017 <- dplyr::filter (fh.2017, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                             FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                             FHF == "IBW")
bark.beetles.vs.2017 <- dplyr::filter (bark.beetles.2017, SEVERITY == "V")
ras.bark.beetles.vs.2017 <- fasterize (bark.beetles.vs.2017, ProvRast, 
                                    field = NULL,# raster cells that are wells get a value of 1
                                    background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2017, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2017.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2017"), ras.bark.beetles.vs.2017)

bark.beetles.s.2017 <- dplyr::filter (bark.beetles.2017, SEVERITY == "S")
ras.bark.beetles.s.2017 <- fasterize (bark.beetles.s.2017, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.s.2017, 
                     filename = "forest_health\\raster_bark_beetle_severe_2017.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2017"), ras.bark.beetles.s.2017)

bark.beetles.m.2017 <- dplyr::filter (bark.beetles.2017, SEVERITY == "M")
ras.bark.beetles.m.2017 <- fasterize (bark.beetles.m.2017, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2017, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2017.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2017"), ras.bark.beetles.m.2017)
rm (fh.2017, bark.beetles.2017, bark.beetles.s.2017, bark.beetles.vs.2017, bark.beetles.m.2017,
    ras.bark.beetles.m.2017, ras.bark.beetles.s.2017, ras.bark.beetles.vs.2017)
gc ()

#########
# 2016 #
#######
fh.2016 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2016")
writeTableQuery (fh.2016, c ("vegetation", "forest_health_2016"))
bark.beetles.2016 <- dplyr::filter (fh.2016, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2016 <- dplyr::filter (bark.beetles.2016, SEVERITY == "V")
ras.bark.beetles.vs.2016 <- fasterize (bark.beetles.vs.2016, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2016, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2016.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2016"), ras.bark.beetles.vs.2016)

bark.beetles.s.2016 <- dplyr::filter (bark.beetles.2016, SEVERITY == "S")
ras.bark.beetles.s.2016 <- fasterize (bark.beetles.s.2016, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2016, 
                     filename = "forest_health\\raster_bark_beetle_severe_2016.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2016"), ras.bark.beetles.s.2016)

bark.beetles.m.2016 <- dplyr::filter (bark.beetles.2016, SEVERITY == "M")
ras.bark.beetles.m.2016 <- fasterize (bark.beetles.m.2016, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2016, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2016.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2016"), ras.bark.beetles.m.2016)
rm (fh.2016, bark.beetles.2016, bark.beetles.s.2016, bark.beetles.vs.2016, bark.beetles.m.2016,
    ras.bark.beetles.m.2016, ras.bark.beetles.s.2016, ras.bark.beetles.vs.2016)
gc ()

#########
# 2015 #
#######
fh.2015 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2015")
writeTableQuery (fh.2015, c ("vegetation", "forest_health_2015"))
bark.beetles.2015 <- dplyr::filter (fh.2015, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2015 <- dplyr::filter (bark.beetles.2015, SEVERITY == "V")
ras.bark.beetles.vs.2015 <- fasterize (bark.beetles.vs.2015, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2015, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2015.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2015"), ras.bark.beetles.vs.2015)

bark.beetles.s.2015 <- dplyr::filter (bark.beetles.2015, SEVERITY == "S")
ras.bark.beetles.s.2015 <- fasterize (bark.beetles.s.2015, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2015, 
                     filename = "forest_health\\raster_bark_beetle_severe_2015.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2015"), ras.bark.beetles.s.2015)

bark.beetles.m.2015 <- dplyr::filter (bark.beetles.2015, SEVERITY == "M")
ras.bark.beetles.m.2015 <- fasterize (bark.beetles.m.2015, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2015, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2015.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2015"), ras.bark.beetles.m.2015)
rm (fh.2015, bark.beetles.2015, bark.beetles.s.2015, bark.beetles.vs.2015, bark.beetles.m.2015,
    ras.bark.beetles.m.2015, ras.bark.beetles.s.2015, ras.bark.beetles.vs.2015)
gc ()

#########
# 2014 #
#######
fh.2014 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2014")
writeTableQuery (fh.2014, c ("vegetation", "forest_health_2014"))
bark.beetles.2014 <- dplyr::filter (fh.2014, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2014 <- dplyr::filter (bark.beetles.2014, SEVERITY == "V")
ras.bark.beetles.vs.2014 <- fasterize (bark.beetles.vs.2014, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2014, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2014.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2014"), ras.bark.beetles.vs.2014)

bark.beetles.s.2014 <- dplyr::filter (bark.beetles.2014, SEVERITY == "S")
ras.bark.beetles.s.2014 <- fasterize (bark.beetles.s.2014, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2014, 
                     filename = "forest_health\\raster_bark_beetle_severe_2014.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2014"), ras.bark.beetles.s.2014)

bark.beetles.m.2014 <- dplyr::filter (bark.beetles.2014, SEVERITY == "M")
ras.bark.beetles.m.2014 <- fasterize (bark.beetles.m.2014, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2014, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2014.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2014"), ras.bark.beetles.m.2014)
rm (fh.2014, bark.beetles.2014, bark.beetles.s.2014, bark.beetles.vs.2014, bark.beetles.m.2014,
    ras.bark.beetles.m.2014, ras.bark.beetles.s.2014, ras.bark.beetles.vs.2014)
gc ()

#########
# 2013 #
#######
fh.2013 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2013")
writeTableQuery (fh.2013, c ("vegetation", "forest_health_2013"))
bark.beetles.2013 <- dplyr::filter (fh.2013, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2013 <- dplyr::filter (bark.beetles.2013, SEVERITY == "V")
ras.bark.beetles.vs.2013 <- fasterize (bark.beetles.vs.2013, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2013, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2013.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2013"), ras.bark.beetles.vs.2013)

bark.beetles.s.2013 <- dplyr::filter (bark.beetles.2013, SEVERITY == "S")
ras.bark.beetles.s.2013 <- fasterize (bark.beetles.s.2013, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2013, 
                     filename = "forest_health\\raster_bark_beetle_severe_2013.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2013"), ras.bark.beetles.s.2013)

bark.beetles.m.2013 <- dplyr::filter (bark.beetles.2013, SEVERITY == "M")
ras.bark.beetles.m.2013 <- fasterize (bark.beetles.m.2013, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2013, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2013.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2013"), ras.bark.beetles.m.2013)
rm (fh.2013, bark.beetles.2013, bark.beetles.s.2013, bark.beetles.vs.2013, bark.beetles.m.2013,
    ras.bark.beetles.m.2013, ras.bark.beetles.s.2013, ras.bark.beetles.vs.2013)
gc ()

#########
# 2012 #
#######
fh.2012 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2012")
writeTableQuery (fh.2012, c ("vegetation", "forest_health_2012"))
bark.beetles.2012 <- dplyr::filter (fh.2012, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2012 <- dplyr::filter (bark.beetles.2012, SEVERITY == "V")
ras.bark.beetles.vs.2012 <- fasterize (bark.beetles.vs.2012, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2012, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2012.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2012"), ras.bark.beetles.vs.2012)

bark.beetles.s.2012 <- dplyr::filter (bark.beetles.2012, SEVERITY == "S")
ras.bark.beetles.s.2012 <- fasterize (bark.beetles.s.2012, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2012, 
                     filename = "forest_health\\raster_bark_beetle_severe_2012.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2012"), ras.bark.beetles.s.2012)

bark.beetles.m.2012 <- dplyr::filter (bark.beetles.2012, SEVERITY == "M")
ras.bark.beetles.m.2012 <- fasterize (bark.beetles.m.2012, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2012, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2012.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2012"), ras.bark.beetles.m.2012)
rm (fh.2012, bark.beetles.2012, bark.beetles.s.2012, bark.beetles.vs.2012, bark.beetles.m.2012,
    ras.bark.beetles.m.2012, ras.bark.beetles.s.2012, ras.bark.beetles.vs.2012)
gc ()

#########
# 2011 #
#######
fh.2011 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2011")
writeTableQuery (fh.2011, c ("vegetation", "forest_health_2011"))
bark.beetles.2011 <- dplyr::filter (fh.2011, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2011 <- dplyr::filter (bark.beetles.2011, SEVERITY == "V")
ras.bark.beetles.vs.2011 <- fasterize (bark.beetles.vs.2011, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2011, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2011.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2011"), ras.bark.beetles.vs.2011)

bark.beetles.s.2011 <- dplyr::filter (bark.beetles.2011, SEVERITY == "S")
ras.bark.beetles.s.2011 <- fasterize (bark.beetles.s.2011, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2011, 
                     filename = "forest_health\\raster_bark_beetle_severe_2011.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2011"), ras.bark.beetles.s.2011)

bark.beetles.m.2011 <- dplyr::filter (bark.beetles.2011, SEVERITY == "M")
ras.bark.beetles.m.2011 <- fasterize (bark.beetles.m.2011, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2011, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2011.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2011"), ras.bark.beetles.m.2011)
rm (fh.2011, bark.beetles.2011, bark.beetles.s.2011, bark.beetles.vs.2011, bark.beetles.m.2011,
    ras.bark.beetles.m.2011, ras.bark.beetles.s.2011, ras.bark.beetles.vs.2011)
gc ()

#########
# 2010 #
#######
fh.2010 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2010")
writeTableQuery (fh.2010, c ("vegetation", "forest_health_2010"))
bark.beetles.2010 <- dplyr::filter (fh.2010, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2010 <- dplyr::filter (bark.beetles.2010, SEVERITY == "V")
ras.bark.beetles.vs.2010 <- fasterize (bark.beetles.vs.2010, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2010, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2010.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2010"), ras.bark.beetles.vs.2010)

bark.beetles.s.2010 <- dplyr::filter (bark.beetles.2010, SEVERITY == "S")
ras.bark.beetles.s.2010 <- fasterize (bark.beetles.s.2010, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2010, 
                     filename = "forest_health\\raster_bark_beetle_severe_2010.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2010"), ras.bark.beetles.s.2010)

bark.beetles.m.2010 <- dplyr::filter (bark.beetles.2010, SEVERITY == "M")
ras.bark.beetles.m.2010 <- fasterize (bark.beetles.m.2010, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2010, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2010.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2010"), ras.bark.beetles.m.2010)
rm (fh.2010, bark.beetles.2010, bark.beetles.s.2010, bark.beetles.vs.2010, bark.beetles.m.2010,
    ras.bark.beetles.m.2010, ras.bark.beetles.s.2010, ras.bark.beetles.vs.2010)
gc ()

#########
# 2009 #
#######
fh.2009 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2009")
writeTableQuery (fh.2009, c ("vegetation", "forest_health_2009"))
bark.beetles.2009 <- dplyr::filter (fh.2009, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2009 <- dplyr::filter (bark.beetles.2009, SEVERITY == "V")
ras.bark.beetles.vs.2009 <- fasterize (bark.beetles.vs.2009, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2009, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2009.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2009"), ras.bark.beetles.vs.2009)

bark.beetles.s.2009 <- dplyr::filter (bark.beetles.2009, SEVERITY == "S")
ras.bark.beetles.s.2009 <- fasterize (bark.beetles.s.2009, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2009, 
                     filename = "forest_health\\raster_bark_beetle_severe_2009.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2009"), ras.bark.beetles.s.2009)

bark.beetles.m.2009 <- dplyr::filter (bark.beetles.2009, SEVERITY == "M")
ras.bark.beetles.m.2009 <- fasterize (bark.beetles.m.2009, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2009, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2009.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2009"), ras.bark.beetles.m.2009)
rm (fh.2009, bark.beetles.2009, bark.beetles.s.2009, bark.beetles.vs.2009, bark.beetles.m.2009,
    ras.bark.beetles.m.2009, ras.bark.beetles.s.2009, ras.bark.beetles.vs.2009)
gc ()

#########
# 2008 #
#######
fh.2008 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2008")
writeTableQuery (fh.2008, c ("vegetation", "forest_health_2008"))
bark.beetles.2008 <- dplyr::filter (fh.2008, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2008 <- dplyr::filter (bark.beetles.2008, SEVERITY == "V")
ras.bark.beetles.vs.2008 <- fasterize (bark.beetles.vs.2008, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2008, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2008.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2008"), ras.bark.beetles.vs.2008)

bark.beetles.s.2008 <- dplyr::filter (bark.beetles.2008, SEVERITY == "S")
ras.bark.beetles.s.2008 <- fasterize (bark.beetles.s.2008, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2008, 
                     filename = "forest_health\\raster_bark_beetle_severe_2008.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2008"), ras.bark.beetles.s.2008)

bark.beetles.m.2008 <- dplyr::filter (bark.beetles.2008, SEVERITY == "M")
ras.bark.beetles.m.2008 <- fasterize (bark.beetles.m.2008, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2008, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2008.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2008"), ras.bark.beetles.m.2008)
rm (fh.2008, bark.beetles.2008, bark.beetles.s.2008, bark.beetles.vs.2008, bark.beetles.m.2008,
    ras.bark.beetles.m.2008, ras.bark.beetles.s.2008, ras.bark.beetles.vs.2008)
gc ()

x <- st_read (conn, table = "vegetation.raster_bark_beetle_moderate_2008",
                 geom = "rast")
#########
# 2007 #
#######
fh.2007 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2007")
writeTableQuery (fh.2007, c ("vegetation", "forest_health_2007"))
bark.beetles.2007 <- dplyr::filter (fh.2007, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2007 <- dplyr::filter (bark.beetles.2007, SEVERITY == "V")
ras.bark.beetles.vs.2007 <- fasterize (bark.beetles.vs.2007, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2007, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2007.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2007"), ras.bark.beetles.vs.2007)

bark.beetles.s.2007 <- dplyr::filter (bark.beetles.2007, SEVERITY == "S")
ras.bark.beetles.s.2007 <- fasterize (bark.beetles.s.2007, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2007, 
                     filename = "forest_health\\raster_bark_beetle_severe_2007.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2007"), ras.bark.beetles.s.2007)

bark.beetles.m.2007 <- dplyr::filter (bark.beetles.2007, SEVERITY == "M")
ras.bark.beetles.m.2007 <- fasterize (bark.beetles.m.2007, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2007, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2007.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2007"), ras.bark.beetles.m.2007)
rm (fh.2007, bark.beetles.2007, bark.beetles.s.2007, bark.beetles.vs.2007, bark.beetles.m.2007,
    ras.bark.beetles.m.2007, ras.bark.beetles.s.2007, ras.bark.beetles.vs.2007)
gc ()

#########
# 2006 #
#######
fh.2006 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2006")
writeTableQuery (fh.2006, c ("vegetation", "forest_health_2006"))
bark.beetles.2006 <- dplyr::filter (fh.2006, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2006 <- dplyr::filter (bark.beetles.2006, SEVERITY == "V")
ras.bark.beetles.vs.2006 <- fasterize (bark.beetles.vs.2006, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2006, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2006.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2006"), ras.bark.beetles.vs.2006)

bark.beetles.s.2006 <- dplyr::filter (bark.beetles.2006, SEVERITY == "S")
ras.bark.beetles.s.2006 <- fasterize (bark.beetles.s.2006, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2006, 
                     filename = "forest_health\\raster_bark_beetle_severe_2006.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2006"), ras.bark.beetles.s.2006)

bark.beetles.m.2006 <- dplyr::filter (bark.beetles.2006, SEVERITY == "M")
ras.bark.beetles.m.2006 <- fasterize (bark.beetles.m.2006, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2006, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2006.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2006"), ras.bark.beetles.m.2006)
rm (fh.2006, bark.beetles.2006, bark.beetles.s.2006, bark.beetles.vs.2006, bark.beetles.m.2006,
    ras.bark.beetles.m.2006, ras.bark.beetles.s.2006, ras.bark.beetles.vs.2006)
gc ()

#########
# 2005 #
#######
fh.2005 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2005")
writeTableQuery (fh.2005, c ("vegetation", "forest_health_2005"))
bark.beetles.2005 <- dplyr::filter (fh.2005, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2005 <- dplyr::filter (bark.beetles.2005, SEVERITY == "V")
ras.bark.beetles.vs.2005 <- fasterize (bark.beetles.vs.2005, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2005, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2005.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2005"), ras.bark.beetles.vs.2005)

bark.beetles.s.2005 <- dplyr::filter (bark.beetles.2005, SEVERITY == "S")
ras.bark.beetles.s.2005 <- fasterize (bark.beetles.s.2005, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2005, 
                     filename = "forest_health\\raster_bark_beetle_severe_2005.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2005"), ras.bark.beetles.s.2005)

bark.beetles.m.2005 <- dplyr::filter (bark.beetles.2005, SEVERITY == "M")
ras.bark.beetles.m.2005 <- fasterize (bark.beetles.m.2005, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2005, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2005.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2005"), ras.bark.beetles.m.2005)
rm (fh.2005, bark.beetles.2005, bark.beetles.s.2005, bark.beetles.vs.2005, bark.beetles.m.2005,
    ras.bark.beetles.m.2005, ras.bark.beetles.s.2005, ras.bark.beetles.vs.2005)
gc ()

#########
# 2004 #
#######
fh.2004 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2004")
writeTableQuery (fh.2004, c ("vegetation", "forest_health_2004"))
bark.beetles.2004 <- dplyr::filter (fh.2004, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2004 <- dplyr::filter (bark.beetles.2004, SEVERITY == "V")
ras.bark.beetles.vs.2004 <- fasterize (bark.beetles.vs.2004, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2004, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2004.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2004"), ras.bark.beetles.vs.2004)

bark.beetles.s.2004 <- dplyr::filter (bark.beetles.2004, SEVERITY == "S")
ras.bark.beetles.s.2004 <- fasterize (bark.beetles.s.2004, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2004, 
                     filename = "forest_health\\raster_bark_beetle_severe_2004.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2004"), ras.bark.beetles.s.2004)

bark.beetles.m.2004 <- dplyr::filter (bark.beetles.2004, SEVERITY == "M")
ras.bark.beetles.m.2004 <- fasterize (bark.beetles.m.2004, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2004, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2004.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2004"), ras.bark.beetles.m.2004)
rm (fh.2004, bark.beetles.2004, bark.beetles.s.2004, bark.beetles.vs.2004, bark.beetles.m.2004,
    ras.bark.beetles.m.2004, ras.bark.beetles.s.2004, ras.bark.beetles.vs.2004)
gc ()

#########
# 2003 #
#######
fh.2003 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2003")
writeTableQuery (fh.2003, c ("vegetation", "forest_health_2003"))
bark.beetles.2003 <- dplyr::filter (fh.2003, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2003 <- dplyr::filter (bark.beetles.2003, SEVERITY == "V")
ras.bark.beetles.vs.2003 <- fasterize (bark.beetles.vs.2003, ProvRast, 
                                       field = NULL,# raster cells that are wells get a value of 1
                                       background = 0) 
raster::writeRaster (ras.bark.beetles.vs.2003, 
                     filename = "forest_health\\raster_bark_beetle_very_severe_2003.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2003"), ras.bark.beetles.vs.2003)

bark.beetles.s.2003 <- dplyr::filter (bark.beetles.2003, SEVERITY == "S")
ras.bark.beetles.s.2003 <- fasterize (bark.beetles.s.2003, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2003, 
                     filename = "forest_health\\raster_bark_beetle_severe_2003.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2003"), ras.bark.beetles.s.2003)

bark.beetles.m.2003 <- dplyr::filter (bark.beetles.2003, SEVERITY == "M")
ras.bark.beetles.m.2003 <- fasterize (bark.beetles.m.2003, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2003, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2003.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2003"), ras.bark.beetles.m.2003)
rm (fh.2003, bark.beetles.2003, bark.beetles.s.2003, bark.beetles.vs.2003, bark.beetles.m.2003,
    ras.bark.beetles.m.2003, ras.bark.beetles.s.2003, ras.bark.beetles.vs.2003)
gc ()

#########
# 2002 #
#######
fh.2002 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2002")
fh.2002 <- sf::st_cast (fh.2002, to = "MULTIPOLYGON")
writeTableQuery (fh.2002, c ("vegetation", "forest_health_2002"))
bark.beetles.2002 <- dplyr::filter (fh.2002, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2002 <- dplyr::filter (bark.beetles.2002, SEVERITY == "V")
# NO VS POLYS IN 2002
# ras.bark.beetles.vs.2002 <- fasterize (bark.beetles.vs.2002, ProvRast, 
#                                       field = NULL,# raster cells that are wells get a value of 1
#                                       background = 0) 
#raster::writeRaster (ras.bark.beetles.vs.2002, 
#                     filename = "forest_health\\raster_bark_beetle_very_severe_2002.tiff", 
#                     format = "GTiff", 
#                     datatype = 'INT1U',
#                     overwrite = T)
# writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2002"), ras.bark.beetles.vs.2002)

bark.beetles.s.2002 <- dplyr::filter (bark.beetles.2002, SEVERITY == "S")
ras.bark.beetles.s.2002 <- fasterize (bark.beetles.s.2002, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2002, 
                     filename = "forest_health\\raster_bark_beetle_severe_2002.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2002"), ras.bark.beetles.s.2002)

bark.beetles.m.2002 <- dplyr::filter (bark.beetles.2002, SEVERITY == "M")
ras.bark.beetles.m.2002 <- fasterize (bark.beetles.m.2002, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2002, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2002.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2002"), ras.bark.beetles.m.2002)
rm (fh.2002, bark.beetles.2002, bark.beetles.s.2002, bark.beetles.vs.2002, bark.beetles.m.2002,
    ras.bark.beetles.m.2002, ras.bark.beetles.s.2002, ras.bark.beetles.vs.2002)
gc ()

#########
# 2001 #
#######
fh.2001 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2001")
writeTableQuery (fh.2001, c ("vegetation", "forest_health_2001"))
bark.beetles.2001 <- dplyr::filter (fh.2001, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
# NO VS POLYS IN 2001
bark.beetles.vs.2001 <- dplyr::filter (bark.beetles.2001, SEVERITY == "V") 
# ras.bark.beetles.vs.2001 <- fasterize (bark.beetles.vs.2001, ProvRast, 
#                                       field = NULL,# raster cells that are wells get a value of 1
#                                      background = 0) 
# raster::writeRaster (ras.bark.beetles.vs.2001, 
#                     filename = "forest_health\\raster_bark_beetle_very_severe_2001.tiff", 
#                     format = "GTiff", 
#                     datatype = 'INT1U',
#                     overwrite = T)
# writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2001"), ras.bark.beetles.vs.2001)

bark.beetles.s.2001 <- dplyr::filter (bark.beetles.2001, SEVERITY == "S")
ras.bark.beetles.s.2001 <- fasterize (bark.beetles.s.2001, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2001, 
                     filename = "forest_health\\raster_bark_beetle_severe_2001.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2001"), ras.bark.beetles.s.2001)

bark.beetles.m.2001 <- dplyr::filter (bark.beetles.2001, SEVERITY == "M")
ras.bark.beetles.m.2001 <- fasterize (bark.beetles.m.2001, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2001, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2001.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2001"), ras.bark.beetles.m.2001)
rm (fh.2001, bark.beetles.2001, bark.beetles.s.2001, bark.beetles.vs.2001, bark.beetles.m.2001,
    ras.bark.beetles.m.2001, ras.bark.beetles.s.2001, ras.bark.beetles.vs.2001)
gc ()

#########
# 2000 #
#######
fh.2000 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_2000")
writeTableQuery (fh.2000, c ("vegetation", "forest_health_2000"))
bark.beetles.2000 <- dplyr::filter (fh.2000, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.2000 <- dplyr::filter (bark.beetles.2000, SEVERITY == "V")
# NO VS POLYS IN 2000
# ras.bark.beetles.vs.2000 <- fasterize (bark.beetles.vs.2000, ProvRast, 
#                                       field = NULL,# raster cells that are wells get a value of 1
#                                       background = 0) 
# raster::writeRaster (ras.bark.beetles.vs.2000, 
#                     filename = "forest_health\\raster_bark_beetle_very_severe_2000.tiff", 
#                     format = "GTiff", 
#                     datatype = 'INT1U',
#                     overwrite = T)
# writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_2000"), ras.bark.beetles.vs.2000)

bark.beetles.s.2000 <- dplyr::filter (bark.beetles.2000, SEVERITY == "S")
ras.bark.beetles.s.2000 <- fasterize (bark.beetles.s.2000, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.2000, 
                     filename = "forest_health\\raster_bark_beetle_severe_2000.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_2000"), ras.bark.beetles.s.2000)

bark.beetles.m.2000 <- dplyr::filter (bark.beetles.2000, SEVERITY == "M")
ras.bark.beetles.m.2000 <- fasterize (bark.beetles.m.2000, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.2000, 
                     filename = "forest_health\\raster_bark_beetle_moderate_2000.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_2000"), ras.bark.beetles.m.2000)
rm (fh.2000, bark.beetles.2000, bark.beetles.s.2000, bark.beetles.vs.2000, bark.beetles.m.2000,
    ras.bark.beetles.m.2000, ras.bark.beetles.s.2000, ras.bark.beetles.vs.2000)
gc ()

#########
# 1999 #
#######
fh.1999 <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                        layer = "mpb_1999")
writeTableQuery (fh.1999, c ("vegetation", "forest_health_1999"))
bark.beetles.1999 <- dplyr::filter (fh.1999, FHF == "IB" | FHF == "IBB" | FHF == "IBD" |
                                      FHF == "IBM" | FHF == "IBS" | FHF == "IBI" |
                                      FHF == "IBW")
bark.beetles.vs.1999 <- dplyr::filter (bark.beetles.1999, SEVERITY == "V")
# NO VS POLYS IN 1999
# ras.bark.beetles.vs.1999 <- fasterize (bark.beetles.vs.1999, ProvRast, 
#                                       field = NULL,# raster cells that are wells get a value of 1
#                                      background = 0) 
# raster::writeRaster (ras.bark.beetles.vs.1999, 
#                     filename = "forest_health\\raster_bark_beetle_very_severe_1999.tiff", 
#                     format = "GTiff", 
#                     datatype = 'INT1U',
#                     overwrite = T)
# writeRasterQuery (c ("vegetation", "raster_bark_beetle_very_severe_1999"), ras.bark.beetles.vs.1999)

bark.beetles.s.1999 <- dplyr::filter (bark.beetles.1999, SEVERITY == "S")
ras.bark.beetles.s.1999 <- fasterize (bark.beetles.s.1999, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.s.1999, 
                     filename = "forest_health\\raster_bark_beetle_severe_1999.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_severe_1999"), ras.bark.beetles.s.1999)

bark.beetles.m.1999 <- dplyr::filter (bark.beetles.1999, SEVERITY == "M")
ras.bark.beetles.m.1999 <- fasterize (bark.beetles.m.1999, ProvRast, 
                                      field = NULL,# raster cells that are wells get a value of 1
                                      background = 0) 
raster::writeRaster (ras.bark.beetles.m.1999, 
                     filename = "forest_health\\raster_bark_beetle_moderate_1999.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U',
                     overwrite = T)
writeRasterQuery (c ("vegetation", "raster_bark_beetle_moderate_1999"), ras.bark.beetles.m.1999)
rm (fh.1999, bark.beetles.1999, bark.beetles.s.1999, bark.beetles.vs.1999, bark.beetles.m.1999,
    ras.bark.beetles.m.1999, ras.bark.beetles.s.1999, ras.bark.beetles.vs.1999)
gc ()


#===========================================================
# VRI 
#==========================================================







#===================================================
# Put 'distance to rasters' in postgres
#==================================================
mine <- raster ("mine\\raster_distance_to_mines_ce_2015_bcalbers.tif")
writeRasterQuery (c ("human", "raster_distance_to_mines_ce_2015_bcalbers"), mine)
rm (mine)
gc ()

pipeline <- raster ("pipelines\\raster_distance_to_pipelines_bcalbers_20180815.tif")
writeRasterQuery (c ("human", "raster_distance_to_pipelines_bcalbers_20180815"), pipeline)
rm (pipeline)
gc ()

rail <- raster ("railway\\raster_dist_to_railway_bcalbers_20180820.tif")
writeRasterQuery (c ("human", "raster_dist_to_railway_bcalbers_20180820"), rail)
rm (rail)
gc ()

ski <- raster ("ski\\raster_dist_to_ski_resorts_bcalbers_20180816.tif")
writeRasterQuery (c ("human", "raster_dist_to_ski_resorts_bcalbers_20180816"), ski)
rm (ski)
gc ()

powerline <- raster ("transmission_line\\raster_dist_to_transmission_line_bcalbers_20180816.tif")
writeRasterQuery (c ("human", "raster_dist_to_transmission_line_bcalbers_20180816"), powerline)
rm (powerline)
gc ()

water <- raster ("water\\raster_dist_to_watercourses_bcalbers_20180820.tif")
writeRasterQuery (c ("water", "raster_dist_to_watercourses_bcalbers_20180820"), water)
rm (water)
gc ()

wells <- raster ("wells\\raster_distance _to_wells_facilities_bcalbers_20180815.tif")
writeRasterQuery (c ("human", "raster_distance_to_wells_facilities_bcalbers_20180815"), wells)
rm (wells)
gc ()

wind <- raster ("wind\\raster_distance_to_wind_power_bcalbers_20180816.tif")
writeRasterQuery (c ("human", "raster_distance_to_wind_power_bcalbers_20180816"), wind)
rm (wind)
gc ()

lake <- raster ("water\\raster_dist_to_watercourses_bcalbers_20180820.tif")
writeRasterQuery (c ("water", "raster_dist_to_watercourses_bcalbers_20180820"), lake)
rm (lake)
gc ()

ras.agriculture <- raster ("agriculture\\agriculture_ce_2015.tif")
writeRasterQuery (c ("human", "raster_dist_to_agriculture_bcalbers_ce_2015"), ras.agriculture)
rm (ras.agriculture)
gc ()
