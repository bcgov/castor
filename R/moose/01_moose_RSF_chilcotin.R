# Copyright 2019 Province of British Columbia
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
#  Script Name: 01_moose_RSF_chilcotin.R
#  Script Version: 1.0
#  Script Purpose: Script to test the application of Schneideman's (2018) RSF model for the Chilcotin area
#                    of BC (adjacent to Tweedsmuir/Itch herds)..
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 17 June 2019
#  R Version: 
#  R Packages: 
#  Data: 
#=================================

options (scipen = 999)
require (raster)
require (fasterize)

#############################################################################
### 1. Create Raster layers equivalent to Schneideman's model covariates ###
###########################################################################
elev <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du7\\du7_elev_resample.tif") # used du7 data here to simplify processing; data clipped in arcgis (raster processing -> clip) because faster
elev <- elev / 1000 # convert m to km
east <- raster ("C:\\Work\\caribou\\clus_data\\dem\\du7_eastness_all_bc_int_x1000.tif")
east <- east / 1000 # divide by 1000 becuase previously x1000 to make as integer
north <- raster ("C:\\Work\\caribou\\clus_data\\dem\\du7_northness_all_bc_int_x1000.tif")
north <- north / 1000 
urban <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_urban.tif") # non-vegetated, land, upland, explosed land, urban; bclcs_level_1 = 'N' AND bclcs_level_2 = 'L' AND bclcs_level_3 = 'U' AND bclcs_level_4 = 'EL' AND bclcs_level_5 = 'UR'
nonveg <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_nonveg_land_no_urban.tif") # all BCLCS non-vegetated land types EXCEPT urban
wet <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_nonveg_water.tif") # all BCLCS non-vegetated water
herb <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_herb.tif") # BCLCS classes: vegetated, non-treed, wetland, all herbaceous types OR vegetated, non-treed, upland, all herbaceous types OR vegetated, non-treed, alpine, all herbaceous types 
pine <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_pine.tif") # VRI primary species = PIN
conifer <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_conifer.tif") # VRI primary species = BAL (balsam) OR CED (cedar) OR 
                                                                                    # CYP (yellow cedar) OR FIR (fir) OR HEM (hemlock) OR 
                                                                                    # LAR (larch) OR SPR (spruce) OR SPB (black spruce)
decid <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_deciduous.tif") # VRI primary species = ALB (alder, birch) OR APC (aspen, poplar, cottonwood) OR OTH (other); most of 'other' are deciduous shrub types
fire.other <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\du7_raster_fire_not_pine_2003to2017.tif")
fire.pine <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\du7_raster_fire_pine_2003to2017.tif")
fire.old <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\du7_raster_fire_1978to2002_old.tif")
new.cut <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\du7_raster_cutblocks_2003_2017.tif")
old.cut <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\du7_raster_cutblocks_1978_2002.tif")
dist.road <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\du7_dist_crds_all_roads.tif")
dist.mature <- 0
escape <- 0
# dist.mature and escape: didn't include here because no definition of what 'mature' forest is in MSc; 
# could use 60 years as they provided in lit review; 
# will calculate models without these covariates as they seem to have a weak effect in the RSF anyway


# script to create 'urban' raster; query of 'urban' bclcs type done in arcgis
# ProvRast <- raster (nrows = 15744, ncols = 17216, 
#                     xmn = 159587.5, xmx = 1881187.5, 
#                     ymn = 173787.5, ymx = 1748187.5,                      
#                     crs = 3005, 
#                     resolution = c (100, 100), vals = 0) 
# vri.urban.shp <- sf::st_read (dsn = "C:\\Work\\caribou\\clus_data\\vegetation\\vri_urban.shp")
# urban <- fasterize (vri.urban.shp, ProvRast, 
#                     field = "bclcs_le_4", # raster cells that are urban get a value of 1
#                     background = 0) 
# writeRaster (urban, "C:\\Work\\caribou\\clus_data\\rsf\\moose\\vri_urban.tif", 
#              format = "GTiff", overwrite = T)


### Script to change resolution of some rasters ###
# east <- resample (east, elev, method = 'bilinear') 
# writeRaster (east, "C:\\Work\\caribou\\clus_data\\dem\\du7_eastness_all_bc_int_x1000.tif", 
#              format = "GTiff", overwrite = T)
# north <- resample (north, elev, method = 'bilinear') 
# writeRaster (north, "C:\\Work\\caribou\\clus_data\\dem\\du7_northness_all_bc_int_x1000.tif", 
#              format = "GTiff", overwrite = T)


### Script to change projection ###
# proj.crs <- proj4string (elev)
# 
# urban <- projectRaster (urban, crs = proj.crs, method = "ngb")
# writeRaster (urban, "C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_urban.tif",
#              format = "GTiff", overwrite = T)
# nonveg <- projectRaster (nonveg, crs = proj.crs, method = "ngb")
# writeRaster (nonveg, "C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_nonveg_land_no_urban.tif",
#              format = "GTiff", overwrite = T)
# herb <- projectRaster (herb, crs = proj.crs, method = "ngb")
# writeRaster (herb, "C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_herb.tif",
#              format = "GTiff", overwrite = T)
# pine <- projectRaster (pine, crs = proj.crs, method = "ngb")
# writeRaster (pine, "C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_pine.tif",
#              format = "GTiff", overwrite = T)
# conifer <- projectRaster (conifer, crs = proj.crs, method = "ngb")
# writeRaster (conifer, "C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_conifer.tif",
#              format = "GTiff", overwrite = T)
# decid <- projectRaster (decid, crs = proj.crs, method = "ngb")
# writeRaster (decid, "C:\\Work\\caribou\\clus_data\\vegetation\\du7_vri_deciduous.tif",
#              format = "GTiff", overwrite = T)
# fire.other <- projectRaster (fire.other, crs = proj.crs, method = "ngb")
# writeRaster (fire.other, "C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\du7_raster_fire_not_pine_2003to2017.tif",
#              format = "GTiff", overwrite = T)
# fire.pine <- projectRaster (fire.pine, crs = proj.crs, method = "ngb")
# writeRaster (fire.pine, "C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\du7_raster_fire_pine_2003to2017.tif",
#              format = "GTiff", overwrite = T)
# fire.old <- projectRaster (fire.old, crs = proj.crs, method = "ngb")
# writeRaster (fire.old, "C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\du7_raster_fire_1978to2002_old.tif",
#              format = "GTiff", overwrite = T)

### CALCULATE RSF RASTERS ###
rsf.moose.lw <- (exp (-4.51 + (elev * 5.47) + ((elev * elev) * -2.48) + 
                     (east * -0.03) + (north * -0.06) + 
                     (conifer * 0.11) + (decid * 0.32) + 
                     (urban * -1.95) + (pine * -0.22) + (herb * 0.63) + (nonveg * 0.47) +
                     (wet * 0.23) +
                     # (cover * 0.02) +
                     (fire.other * 0.26) + (fire.pine * -0.41) + (fire.old * 0.41) +
                     (new.cut * -0.06) + 
                     (old.cut * 0.01))) /
                (1 + exp (-4.51 + (elev * 5.47) + ((elev * elev) * -2.48) + 
                           (east * -0.03) + (north * -0.06) + 
                           (conifer * 0.11) + (decid * 0.32) + 
                           (urban * -1.95) + (pine * -0.22) + (herb * 0.63) + (nonveg * 0.47) +
                           (wet * 0.23) +
                           # (cover * 0.02) +
                           (fire.other * 0.26) + (fire.pine * -0.41) + (fire.old * 0.41) +
                           (new.cut * -0.06) + 
                           (old.cut * 0.01)))       
writeRaster (rsf.moose.lw, "C:\\Work\\caribou\\clus_data\\rsf\\moose\\rsf_moose_lw_chilcotin.tif", 
             format = "GTiff", overwrite = T)

rsf.moose.c <- (exp (-3.48 + (elev * 3.83) + ((elev * elev) * -1.77) + 
                      (east * 0.11) + (north * -0.11) +
                    (conifer * -0.07) + (decid * 0.59) + (urban * -0.55) + (pine * -0.16) + 
                    (herb * 0.97) + (wet * -0.03) +
                    # (dist.mature * -0.01) +
                    (fire.other * 0.23) + (fire.pine * -0.22) + 
                    (new.cut * -0.12) + (old.cut * -0.65))) /
                (1 + exp (-3.48 + (elev * 3.83) + ((elev * elev) * -1.77) + 
                           (east * 0.11) + (north * -0.11) +
                           (conifer * -0.07) + (decid * 0.59) + (urban * -0.55) + (pine * -0.16) + 
                           (herb * 0.97) + (wet * -0.03) +
                           # (dist.mature * -0.01) +
                           (fire.other * 0.23) + (fire.pine * -0.22) + 
                           (new.cut * -0.12) + (old.cut * -0.65)))       
writeRaster (rsf.moose.c, "C:\\Work\\caribou\\clus_data\\rsf\\moose\\rsf_moose_calving_chilcotin.tif", 
             format = "GTiff", overwrite = T)

rsf.moose.s <- (exp (-3.81 + (elev * 3.87) + ((elev * elev) * -1.75) +
                     (conifer * 0.29) + (decid * 0.20) + (herb * 0.14) +
                    (pine * 0.14) + (wet * -0.06) +  
                    # (alpine * -0.65) + (dist.mature * 0.004) + (escape * 0.004) +
                    (fire.other * 0.23) + (fire.pine * -0.05) + (fire.old * 0.17) +  
                    (new.cut * -0.30) + (old.cut * -0.10))) /
                (1 + exp (-3.81 + (elev * 3.87) + ((elev * elev) * -1.75) +
                            (conifer * 0.29) + (decid * 0.20) + (herb * 0.14) +
                           (pine * 0.14) + (wet * -0.06) +  
                           # (dist.mature * 0.004) + (escape * 0.004) + (alpine * -0.65) +
                           (fire.other * 0.23) + (fire.pine * -0.05) + (fire.old * 0.17) +  
                           (new.cut * -0.30) + (old.cut * -0.10)))       
writeRaster (rsf.moose.s, "C:\\Work\\caribou\\clus_data\\rsf\\moose\\rsf_moose_summer_chilcotin.tif", 
             format = "GTiff", overwrite = T)

rsf.moose.f <- (exp (-1.76 + (elev * 0.42) + ((elev * elev) * -0.26) + 
                    (east * 0.03) + (north * 0.04) +
                    # (alpine * -0.16) + 
                    (conifer * 0.18) + (decid * 0.28) + (herb * 0.39) + 
                    (pine * -0.04) + (wet * -0.06) +
                    (new.cut * 0.01) + (old.cut * -0.31) + 
                    (fire.other * 0.21) + (fire.pine * -0.10) + (fire.old * -0.39))) /
                (1 + exp (-1.76 + (elev * 0.42) + ((elev * elev) * -0.26) + 
                           (east * 0.03) + (north * 0.04) +
                           # (alpine * -0.16) + 
                           (conifer * 0.18) + (decid * 0.28) + (herb * 0.39) + 
                           (pine * -0.04) + (wet * -0.06) +
                           (new.cut * 0.01) + (old.cut * -0.31) + 
                           (fire.other * 0.21) + (fire.pine * -0.10) + (fire.old * -0.39)))       
writeRaster (rsf.moose.f, "C:\\Work\\caribou\\clus_data\\rsf\\moose\\rsf_moose_fall_chilcotin.tif", 
             format = "GTiff", overwrite = T)

rsf.moose.ew <- (exp (-3.97 + (elev * 4.30) + ((elev * elev) * -1.76) + 
                    (east * 0.01) + 
                    (conifer * -0.40) + (decid * 0.18) + (herb * 0.79) + (pine * -0.71) + (wet * 0.56) +
                    # (dist.mature * 0.04) +
                      (fire.other * 0.13) + (fire.pine * -0.76) + (fire.old * 0.33) +
                    (new.cut * 0.08) + (old.cut * -0.20) +  
                      (dist.road * (0.01/1000)))) /
                (1 + exp (-3.97 + (elev * 4.30) + ((elev * elev) * -1.76) + 
                           (east * 0.01) + 
                           (conifer * -0.40) + (decid * 0.18) + (herb * 0.79) + (pine * -0.71) + (wet * 0.56) +
                           # (dist.mature * 0.04) +
                           (fire.other * 0.13) + (fire.pine * -0.76) + (fire.old * 0.33) +
                           (new.cut * 0.08) + (old.cut * -0.20) +  
                           (dist.road * (0.01/1000))))      
writeRaster (rsf.moose.ew, "C:\\Work\\caribou\\clus_data\\rsf\\moose\\rsf_moose_early_winter_chilcotin.tif", 
             format = "GTiff", overwrite = T)