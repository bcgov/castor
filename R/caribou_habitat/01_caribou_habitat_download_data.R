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
#  Script Purpose: Download data for provincial caribou habitat model analysis.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 25 July 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================
require (downloader)

# data directory
setwd ('C:\\Work\\caribou\\clus_data\\caribou_habitat_model')

#########################
# MANUAL DATA DOWNLOADS #
#########################
# copied from BCGW into geodatabase; for uploading to postgres

# caribou range boundaries; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/caribou-herd-locations-for-bc>
# Name in GDB: boundary_caribou_pop_20180725

# BEC Map; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/biogeoclimatic-ecosystem-classification-bec-map>
# Name in GDB: bec_poly_20180725

# Cutblock data; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/harvested-areas-of-bc-consolidated-cutblocks->
# Name in GDB: cutblocks_20180725

# VRI Public; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/vri-forest-vegetation-composite-polygons-and-rank-1-layer>
# Name in GDB: vir_public_20180725

# VRI Internal; downloaded 25 July 2018
# NOTE: the internal data provides access to VRI in TFLs, which is NOT available in the public version 
# <\\spatialfiles2.bcgov\work\FOR\VIC\HTS\DAM\WorkArea\Mcdougall\Projects\2018\PROJECTION_2018\Data\INTERNAL_VEG_COMP\INTERNAL_VEGCOMP
# Name in GDB: vri_internal_20180725

# Fire; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/fire-perimeters-historical>
# Name in GDB: fire_historic_20180725

# Oil and gas well/facility; downloaded 25 July 2018
# After 2016: <https://catalogue.data.gov.bc.ca/dataset/oil-and-gas-commission-facility-location-permits>
# Name in GDB: oil_gas_facility_post2016_20180725
# Before 2016: <https://catalogue.data.gov.bc.ca/dataset/oil-and-gas-commission-pre-2016-facility-locations>
# Name in GDB: oil_gas_facility_pre2016_20180725
# Historic <https://catalogue.data.gov.bc.ca/dataset/trim-cultural-points>
# Name in GDB: trim_points_20180815
# Well surface holes:  <https://catalogue.data.gov.bc.ca/dataset/well-surface-hole-status>
# Name in GDB: well_surface_hole_20180815

# Trasnmission Lines; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/bc-transmission-lines>
# Name in GDB: transmission_line_20180725

# Railways; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/railway-track-line>
# Name in GDB: railway_20180725

# Major Projects, for wind and mines; downloaded 25 July 2018
# <https://catalogue.data.gov.bc.ca/dataset/natural-resource-sector-major-projects-points>
# Name in GDB: major_projects_20180725

# Integrated roads data from cumulative effects; copied June 18, 2018
# \\spatialfiles.bcgov\\work\\srm\\bcce\\shared\\data_library\roads\2017\BC_CE_IntegratedRoads_2017_v1_20170214.gdb
# Get RASTER from Kyle

# Ski Resorts
# https://catalogue.data.gov.bc.ca/dataset/ski-resorts
# Name in GDB: ski_resorts_20180813

# Mines from MEMPR
# http://www.empr.gov.bc.ca/Mining/Geoscience/MapPlace/metadata/Pages/minf_metadata.aspx
# Name in GDB: minfile_20180813
# http://www.empr.gov.bc.ca/Mining/Geoscience/MINFILE/ProductsDownloads/MINFILEDocumentation/CodingManual/Pages/default.aspx

# Pipelines; downloaded 25 July 2018
# After 2006: <https://catalogue.data.gov.bc.ca/dataset/oil-and-gas-commission-pipeline-right-of-way-permits>
# Name in GDB: pipeline_post2006_20180725
# After 2016: <https://catalogue.data.gov.bc.ca/dataset/oil-and-gas-commission-pipeline-segment-permits>
# Name in GDB: pipeline_post2016_20180725
# https://catalogue.data.gov.bc.ca/dataset/tantalis-crown-tenures
# Name in GDB: tantalis_crown_tenures_20180814
# https://catalogue.data.gov.bc.ca/dataset/tantalis-surveyed-parcels
# Name in GDB: tantalis_surveyed_row_20180814
# https://catalogue.data.gov.bc.ca/dataset/trim-cultural-lines
# Name in GDB: trim_lines_20180814

# Powerplants/Clean Energy
# https://open.canada.ca/data/en/dataset/490db619-ab58-4a2a-a245-2376ce1840de
# Name in GDB:
# https://open.canada.ca/data/en/dataset/40fbe40c-01cd-49d3-8add-0d20ed64c90d
# Name in GDB:

############################
# Cumulative Effects Data #
##########################
# \\transverse\work\srm\bcce\shared\data_library\development\Consolidated_Development\2015\
# data not maintained or updated (or particularly well documented)
# produced in 2015
# some spot-checking suggests it is fairly accurate

# Mines
# Name in GDB: ce_mine_2015_20180814

# Seismic data
# NE_Seismic and Remainder_Seismic merged together
# Name in GDB: seismic_ce_2015

###################################
# Data downloadable from websites #
###################################
# bc boundary; downloaded 25 July 2018
# available from federal government via https://open.canada.ca/data/dataset/bab06e04-e6d0-41f1-a595-6cff4d71bedf
download ("http://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/files-fichiers/gpr_000b11a_e.zip", 
          dest = "province\\border.zip", 
          mode = "wb")
unzip ("province\\border.zip", 
       exdir = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\province")
file.remove ("province\\border.zip")

# current climate measures; downloaded 25 July 2018
# Reference: <http://climatebcdata.climatewna.com/#3._reference> # Wang, T., Hamann, A., Spittlehouse, D.L., Murdock, T., 2012. ClimateWNA - High-Resolution Spatial Climate Data for Western North America. Journal of Applied Meteorology and Climatology, 51: 16-29.
download ("http://climatebcdata.climatewna.com/download/Normal_1981_2010MSY/Normal_1981_2010_seasonal.zip", 
          dest = "climate\\Normal_1981_2010_seasonal.zip", 
          mode = "wb")
unzip ("climate\\Normal_1981_2010_seasonal.zip", 
       exdir = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\climate")
file.remove ("climate\\Normal_1981_2010_seasonal.zip")

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

# Additional data provided by Nicola Dodd
# \\spatialfiles.bcgov\work\env\esd\eis\wld\caribou\nldodd_work\caribou\telem_data\BCtelem_draft
# SMC_NoCentral_BConly_2002_18_July12_2018
# SMC_CentralGroup_BConly_Telemetry_July12_2018
# wcari_gps_Dec2011_Jan2015_master_BCEnvAlbers


