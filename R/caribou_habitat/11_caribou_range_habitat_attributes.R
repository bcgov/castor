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
#  Script Name: 05_caribou_habitat_model_RSF_data_prep.R
#  Script Version: 1.0
#  Script Purpose: Combine telemtery and habitat data for RSF analysis, includign creation of'available'
#                   sample points. 
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 31 August 2018
#  R Version: 3.5.1
#  R Package Versions: 
#  Data: 
#=================================



bec2020.rst <- raster ("bec\\BEC_zone_2020s\\BEC_zone_2020s.tif")
bec2050.rst <- raster ("bec\\BEC_zone_2050s\\BEC_zone_2050s.tif")
bec2080.rst <- raster ("bec\\BEC_zone_2080s\\BEC_zone_2080s.tif")
clim.1961.1990.tavewt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\tave_wt") # Tmax, Tmin, Tave were multiplied by 10; need to be divided by ten
clim.1961.1990.tmaxwt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\tmax_wt")
clim.1961.1990.tminwt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\tmin_wt")
clim.1961.1990.tavesm.rst <- raster ("climate\\Normal_1961_1990_seasonal\\tave_sm")
clim.1961.1990.tmaxsm.rst <- raster ("climate\\Normal_1961_1990_seasonal\\tmax_sm")
clim.1961.1990.pptwt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\ppt_wt") # winter precipitation
clim.1961.1990.paswt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\pas_wt") # winter precipitation as snow
clim.1961.1990.ddat.rst <- raster ("climate\\Normal_1961_1990_seasonal\\dd_0_at") # days below 0 degrees autumn
clim.1961.1990.ddwt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\dd_0_wt") # days below 0 degrees winter
clim.1961.1990.ddsp.rst <- raster ("climate\\Normal_1961_1990_seasonal\\dd_0_sp") # days below 0 degrees spring
clim.1961.1990.nffdsp.rst <- raster ("climate\\Normal_1961_1990_seasonal\\nffd_sp") # number of frost free days spring
clim.1961.1990.nffdat.rst <- raster ("climate\\Normal_1961_1990_seasonal\\nffd_at") # number of frost free days autumn

clim.1981.2010.tavewt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\tave_wt") # Tmax, Tmin, Tave were multiplied by 10; need to be divided by ten
clim.1981.2010.tmaxwt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\tmax_wt")
clim.1981.2010.tminwt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\tmin_wt")
clim.1981.2010.tavesm.rst <- raster ("climate\\Normal_1981_2010_seasonal\\tave_sm")
clim.1981.2010.tmaxsm.rst <- raster ("climate\\Normal_1981_2010_seasonal\\tmax_sm")
clim.1981.2010.pptwt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\ppt_wt")
clim.1981.2010.paswt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\pas_wt")
clim.1981.2010.ddat.rst <- raster ("climate\\Normal_1981_2010_seasonal\\dd_0_at") 
clim.1981.2010.ddwt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\dd_0_wt") 
clim.1981.2010.ddsp.rst <- raster ("climate\\Normal_1981_2010_seasonal\\dd_0_sp") 
clim.1981.2010.nffdsp.rst <- raster ("climate\\Normal_1981_2010_seasonal\\nffd_sp") 
clim.1981.2010.nffdat.rst <- raster ("climate\\Normal_1981_2010_seasonal\\nffd_at") 

canesm2.2025.tavewt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\tave_wt") # average winter temp
canesm2.2025.tmaxwt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\tmax_wt") # max winter temp
canesm2.2025.tminwt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\tmin_wt") # min winter temp
canesm2.2025.tavesm.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\tave_sm") # average summer temp
canesm2.2025.tmaxsm.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\tmax_sm") # max summer temp
canesm2.2025.pptwt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\ppt_wt") # winter precipitation
canesm2.2025.paswt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\pas_wt") # winter precipitation as snow
canesm2.2025.ddat.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\dd_0_at") 
canesm2.2025.ddwt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\dd_0_wt") 
canesm2.2025.ddsp.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\dd_0_sp") 
canesm2.2025.nffdsp.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\nffd_sp") 
canesm2.2025.nffdat.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\nffd_at") 

canesm2.2055.tavewt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\tave_wt") # average winter temp
canesm2.2055.tmaxwt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\tmax_wt") # max winter temp
canesm2.2055.tminwt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\tmin_wt") # min winter temp
canesm2.2055.tavesm.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\tave_sm") # average summer temp
canesm2.2055.tmaxsm.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\tmax_sm") # max summer temp
canesm2.2055.pptwt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\ppt_wt") # winter precipitation
canesm2.2055.paswt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\pas_wt") # winter precipitation as snow
canesm2.2055.ddat.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\dd_0_at") 
canesm2.2055.ddwt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\dd_0_wt") 
canesm2.2055.ddsp.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\dd_0_sp") 
canesm2.2055.nffdsp.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\nffd_sp") 
canesm2.2055.nffdat.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\nffd_at") 

canesm2.2085.tavewt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\tave_wt") # average winter temp
canesm2.2085.tmaxwt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\tmax_wt") # max winter temp
canesm2.2085.tminwt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\tmin_wt") # min winter temp
canesm2.2085.tavesm.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\tave_sm") # average summer temp
canesm2.2085.tmaxsm.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\tmax_sm") # max summer temp
canesm2.2085.pptwt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\ppt_wt") # winter precipitation
canesm2.2085.paswt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\pas_wt") # winter precipitation as snow
canesm2.2085.ddat.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\dd_0_at") 
canesm2.2085.ddwt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\dd_0_wt") 
canesm2.2085.ddsp.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\dd_0_sp") 
canesm2.2085.nffdsp.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\nffd_sp") 
canesm2.2085.nffdat.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\nffd_at") 

ccsm4.2025.tavewt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\tave_wt") # average winter temp
ccsm4.2025.tmaxwt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\tmax_wt") # max winter temp
ccsm4.2025.tminwt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\tmin_wt") # min winter temp
ccsm4.2025.tavesm.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\tave_sm") # average summer temp
ccsm4.2025.tmaxsm.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\tmax_sm") # max summer temp
ccsm4.2025.pptwt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\ppt_wt") # winter precipitation
ccsm4.2025.paswt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\pas_wt") # winter precipitation as snow
ccsm4.2025.ddat.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\dd_0_at") 
ccsm4.2025.ddwt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\dd_0_wt") 
ccsm4.2025.ddsp.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\dd_0_sp") 
ccsm4.2025.nffdsp.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\nffd_sp") 
ccsm4.2025.nffdat.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\nffd_at") 

ccsm4.2055.tavewt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\tave_wt") # average winter temp
ccsm4.2055.tmaxwt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\tmax_wt") # max winter temp
ccsm4.2055.tminwt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\tmin_wt") # min winter temp
ccsm4.2055.tavesm.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\tave_sm") # average summer temp
ccsm4.2055.tmaxsm.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\tmax_sm") # max summer temp
ccsm4.2055.pptwt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\ppt_wt") # winter precipitation
ccsm4.2055.paswt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\pas_wt") # winter precipitation as snow
ccsm4.2055.ddat.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\dd_0_at") 
ccsm4.2055.ddwt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\dd_0_wt") 
ccsm4.2055.ddsp.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\dd_0_sp") 
ccsm4.2055.nffdsp.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\nffd_sp") 
ccsm4.2055.nffdat.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\nffd_at") 

ccsm4.2085.tavewt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\tave_wt") # average winter temp
ccsm4.2085.tmaxwt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\tmax_wt") # max winter temp
ccsm4.2085.tminwt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\tmin_wt") # min winter temp
ccsm4.2085.tavesm.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\tave_sm") # average summer temp
ccsm4.2085.tmaxsm.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\tmax_sm") # max summer temp
ccsm4.2085.pptwt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\ppt_wt") # winter precipitation
ccsm4.2085.paswt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\pas_wt") # winter precipitation as snow
ccsm4.2085.ddat.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\dd_0_at") 
ccsm4.2085.ddwt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\dd_0_wt") 
ccsm4.2085.ddsp.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\dd_0_sp") 
ccsm4.2085.nffdsp.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\nffd_sp") 
ccsm4.2085.nffdat.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\nffd_at") 

hadgem.2025.tavewt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\tave_wt") # average winter temp
hadgem.2025.tmaxwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\tmax_wt") # max winter temp
hadgem.2025.tminwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\tmin_wt") # min winter temp
hadgem.2025.tavesm.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\tave_sm") # average summer temp
hadgem.2025.tmaxsm.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\tmax_sm") # max summer temp
hadgem.2025.pptwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\ppt_wt") # winter precipitation
hadgem.2025.paswt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\pas_wt") # winter precipitation as snow
hadgem.2025.ddat.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\dd_0_at") 
hadgem.2025.ddwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\dd_0_wt") 
hadgem.2025.ddsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\dd_0_sp") 
hadgem.2025.nffdsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\nffd_sp") 
hadgem.2025.nffdat.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\nffd_at") 

hadgem.2055.tavewt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\tave_wt") # average winter temp
hadgem.2055.tmaxwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\tmax_wt") # max winter temp
hadgem.2055.tminwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\tmin_wt") # min winter temp
hadgem.2055.tavesm.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\tave_sm") # average summer temp
hadgem.2055.tmaxsm.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\tmax_sm") # max summer temp
hadgem.2055.pptwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\ppt_wt") # winter precipitation
hadgem.2055.paswt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\pas_wt") # winter precipitation as snow
hadgem.2055.ddat.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\dd_0_at") 
hadgem.2055.ddwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\dd_0_wt") 
hadgem.2055.ddsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\dd_0_sp") 
hadgem.2055.nffdsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\nffd_sp") 
hadgem.2055.nffdat.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\nffd_at") 

hadgem.2085.tavewt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\tave_wt") # average winter temp
hadgem.2085.tmaxwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\tmax_wt") # max winter temp
hadgem.2085.tminwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\tmin_wt") # min winter temp
hadgem.2085.tavesm.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\tave_sm") # average summer temp
hadgem.2085.tmaxsm.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\tmax_sm") # max summer temp
hadgem.2085.pptwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\ppt_wt") # winter precipitation
hadgem.2085.paswt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\pas_wt") # winter precipitation as snow
hadgem.2085.ddat.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\dd_0_at") 
hadgem.2085.ddwt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\dd_0_wt") 
hadgem.2085.ddsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\dd_0_sp") 
hadgem.2085.nffdsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\nffd_sp") 
hadgem.2085.nffdat.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\nffd_at") 

#==============================================
# Project the provincial boundary
#==============================================
proj.crs <- proj4string (caribou.range)
prov.bnd.prj <- spTransform (prov.bnd, CRS = proj.crs) 
prov.bnd.prj <- prov.bnd.prj [prov.bnd.prj@data$PRENAME == "British Columbia", ] # subset BC only
# bec2020.rst.prj <- projectRaster (bec2020.rst, crs = proj.crs, method = "ngb", res = 500)
# 500 m resolution
# bec2050.rst.prj <- projectRaster (bec2050.rst, crs = proj.crs, method = "ngb", res = 500)
# bec2080.rst.prj <- projectRaster (bec2080.rst, crs = proj.crs, method = "ngb", res = 500)
# proj4string (prov.bnd.prj)

#================================================
# Create raster bricks of climate data
#===============================================
bec.future.stack <- stack (bec2020.rst, bec2050.rst, bec2080.rst) # stack the future bec data together
names (bec.future.stack) <- c ("bec2020", "bec2050", "bec2080") # rename the bands
bec.future.brick <- brick (bec.future.stack) # brick the stack as a single layer

clim.1981.2010.tavewt.rst <- clim.1981.2010.tavewt.rst / 10 # Tmax, Tmin, Tave were multiplied by 10 @ source; need to be divided by ten
clim.1981.2010.tmaxwt.rst <- clim.1981.2010.tmaxwt.rst / 10
clim.1981.2010.tminwt.rst <- clim.1981.2010.tminwt.rst / 10
clim.1981.2010.tavesm.rst <- clim.1981.2010.tavesm.rst / 10
clim.1981.2010.tmaxsm.rst <- clim.1981.2010.tmaxsm.rst / 10
clim.current.stack <- stack (clim.1981.2010.tavewt.rst, clim.1981.2010.tmaxwt.rst, 
                             clim.1981.2010.tminwt.rst, clim.1981.2010.tavesm.rst, 
                             clim.1981.2010.tmaxsm.rst, clim.1981.2010.pptwt.rst,
                             clim.1981.2010.paswt.rst, clim.1981.2010.ddwt.rst, 
                             clim.1981.2010.ddsp.rst, clim.1981.2010.ddat.rst,
                             clim.1981.2010.nffdsp.rst, clim.1981.2010.nffdat.rst) 
names (clim.current.stack) <- c ("tavewt", "tmaxwt", "tminwt", "tavesm", "tmaxsm", "pptwt", "paswt",
                                 "ddwt", "ddsp", "ddat", "nffdsp", "nffdat") 
clim.current.brick <- brick (clim.current.stack)

clim.1961.1990.tavewt.rst <- clim.1961.1990.tavewt.rst / 10 # Tmax, Tmin, Tave were multiplied by 10 @ source; need to be divided by ten
clim.1961.1990.tmaxwt.rst <- clim.1961.1990.tmaxwt.rst / 10
clim.1961.1990.tminwt.rst <- clim.1961.1990.tminwt.rst / 10
clim.1961.1990.tavesm.rst <- clim.1961.1990.tavesm.rst / 10
clim.1961.1990.tmaxsm.rst <- clim.1961.1990.tmaxsm.rst / 10
clim.historic.stack <- stack (clim.1961.1990.tavewt.rst, clim.1961.1990.tmaxwt.rst, 
                              clim.1961.1990.tminwt.rst, clim.1961.1990.tavesm.rst, 
                              clim.1961.1990.tmaxsm.rst, clim.1961.1990.pptwt.rst,
                              clim.1961.1990.paswt.rst, clim.1961.1990.ddwt.rst, 
                              clim.1961.1990.ddsp.rst, clim.1961.1990.ddat.rst,
                              clim.1961.1990.nffdsp.rst, clim.1961.1990.nffdat.rst) 
names (clim.historic.stack) <- c ("tavewt", "tmaxwt", "tminwt", "tavesm", "tmaxsm", "pptwt", "paswt",
                                  "ddwt", "ddsp", "ddat", "nffdsp", "nffdat") 
clim.historic.brick <- brick (clim.historic.stack)

tavewt.2025 <- mean (canesm2.2025.tavewt.rst, ccsm4.2025.tavewt.rst, hadgem.2025.tavewt.rst) # take average of three climate models
tavewt.2025 <- tavewt.2025 / 10 # divide by ten for temp covariates
tmaxwt.2025 <- mean (canesm2.2025.tmaxwt.rst, ccsm4.2025.tmaxwt.rst, hadgem.2025.tmaxwt.rst) 
tmaxwt.2025 <- tmaxwt.2025 / 10 
tminwt.2025 <- mean (canesm2.2025.tminwt.rst, ccsm4.2025.tminwt.rst, hadgem.2025.tminwt.rst) 
tminwt.2025 <- tminwt.2025 / 10 
tavesm.2025 <- mean (canesm2.2025.tavesm.rst, ccsm4.2025.tavesm.rst, hadgem.2025.tavesm.rst) 
tavesm.2025 <- tavesm.2025 / 10 
tmaxsm.2025 <- mean (canesm2.2025.tmaxsm.rst, ccsm4.2025.tmaxsm.rst, hadgem.2025.tmaxsm.rst) 
tmaxsm.2025 <- tmaxsm.2025 / 10 
pptwt.2025 <- mean (canesm2.2025.pptwt.rst, ccsm4.2025.pptwt.rst, hadgem.2025.pptwt.rst) 
paswt.2025 <- mean (canesm2.2025.paswt.rst, ccsm4.2025.paswt.rst, hadgem.2025.paswt.rst) 
ddwt.2025 <- mean (canesm2.2025.ddwt.rst, ccsm4.2025.ddwt.rst, hadgem.2025.ddwt.rst) 
ddsp.2025 <- mean (canesm2.2025.ddsp.rst, ccsm4.2025.ddsp.rst, hadgem.2025.ddsp.rst) 
ddat.2025 <- mean (canesm2.2025.ddat.rst, ccsm4.2025.ddat.rst, hadgem.2025.ddat.rst) 
nffdsp.2025 <- mean (canesm2.2025.nffdsp.rst, ccsm4.2025.nffdsp.rst, hadgem.2025.nffdsp.rst) 
nffdat.2025 <- mean (canesm2.2025.nffdat.rst, ccsm4.2025.nffdat.rst, hadgem.2025.nffdat.rst) 
clim.2025.stack <- stack (tavewt.2025, tmaxwt.2025, tminwt.2025, tavesm.2025, tmaxsm.2025, 
                          pptwt.2025, paswt.2025, ddwt.2025, ddsp.2025, ddat.2025, nffdsp.2025, nffdat.2025) 
names (clim.2025.stack) <- c ("tavewt.2025", "tmaxwt.2025", "tminwt.2025", "tavesm.2025", 
                              "tmaxsm.2025", "pptwt.2025", "paswt.2025", "ddwt.2025", "ddsp.2025", 
                              "ddat.2025", "nffdsp.2025", "nffdat.2025") 
clim.2025.brick <- brick (clim.2025.stack)

tavewt.2055 <- mean (canesm2.2055.tavewt.rst, ccsm4.2055.tavewt.rst, hadgem.2055.tavewt.rst) # take average of three climate models
tavewt.2055 <- tavewt.2055 / 10 # divide by ten for temp covariates
tmaxwt.2055 <- mean (canesm2.2055.tmaxwt.rst, ccsm4.2055.tmaxwt.rst, hadgem.2055.tmaxwt.rst) 
tmaxwt.2055 <- tmaxwt.2055 / 10 
tminwt.2055 <- mean (canesm2.2055.tminwt.rst, ccsm4.2055.tminwt.rst, hadgem.2055.tminwt.rst) 
tminwt.2055 <- tminwt.2055 / 10 
tavesm.2055 <- mean (canesm2.2055.tavesm.rst, ccsm4.2055.tavesm.rst, hadgem.2055.tavesm.rst) 
tavesm.2055 <- tavesm.2055 / 10 
tmaxsm.2055 <- mean (canesm2.2055.tmaxsm.rst, ccsm4.2055.tmaxsm.rst, hadgem.2055.tmaxsm.rst) 
tmaxsm.2055 <- tmaxsm.2055 / 10 
pptwt.2055 <- mean (canesm2.2055.pptwt.rst, ccsm4.2055.pptwt.rst, hadgem.2055.pptwt.rst) 
paswt.2055 <- mean (canesm2.2055.paswt.rst, ccsm4.2055.paswt.rst, hadgem.2055.paswt.rst) 
ddwt.2055 <- mean (canesm2.2055.ddwt.rst, ccsm4.2055.ddwt.rst, hadgem.2055.ddwt.rst) 
ddsp.2055 <- mean (canesm2.2055.ddsp.rst, ccsm4.2055.ddsp.rst, hadgem.2055.ddsp.rst) 
ddat.2055 <- mean (canesm2.2055.ddat.rst, ccsm4.2055.ddat.rst, hadgem.2055.ddat.rst) 
nffdsp.2055 <- mean (canesm2.2055.nffdsp.rst, ccsm4.2055.nffdsp.rst, hadgem.2055.nffdsp.rst) 
nffdat.2055 <- mean (canesm2.2055.nffdat.rst, ccsm4.2055.nffdat.rst, hadgem.2055.nffdat.rst) 
clim.2055.stack <- stack (tavewt.2055, tmaxwt.2055, tminwt.2055, tavesm.2055, tmaxsm.2055, 
                          pptwt.2055, paswt.2055, ddwt.2055, ddsp.2055, ddat.2055, nffdsp.2055, nffdat.2055) 
names (clim.2055.stack) <- c ("tavewt.2055", "tmaxwt.2055", "tminwt.2055", "tavesm.2055", 
                              "tmaxsm.2055", "pptwt.2055", "paswt.2055", "ddwt.2055", "ddsp.2055", 
                              "ddat.2055", "nffdsp.2055", "nffdat.2055") 
clim.2055.brick <- brick (clim.2055.stack)

tavewt.2085 <- mean (canesm2.2085.tavewt.rst, ccsm4.2085.tavewt.rst, hadgem.2085.tavewt.rst) # take average of three climate models
tavewt.2085 <- tavewt.2085 / 10 # divide by ten for temp covariates
tmaxwt.2085 <- mean (canesm2.2085.tmaxwt.rst, ccsm4.2085.tmaxwt.rst, hadgem.2085.tmaxwt.rst) 
tmaxwt.2085 <- tmaxwt.2085 / 10 
tminwt.2085 <- mean (canesm2.2085.tminwt.rst, ccsm4.2085.tminwt.rst, hadgem.2085.tminwt.rst) 
tminwt.2085 <- tminwt.2085 / 10 
tavesm.2085 <- mean (canesm2.2085.tavesm.rst, ccsm4.2085.tavesm.rst, hadgem.2085.tavesm.rst) 
tavesm.2085 <- tavesm.2085 / 10 
tmaxsm.2085 <- mean (canesm2.2085.tmaxsm.rst, ccsm4.2085.tmaxsm.rst, hadgem.2085.tmaxsm.rst) 
tmaxsm.2085 <- tmaxsm.2085 / 10 
pptwt.2085 <- mean (canesm2.2085.pptwt.rst, ccsm4.2085.pptwt.rst, hadgem.2085.pptwt.rst) 
paswt.2085 <- mean (canesm2.2085.paswt.rst, ccsm4.2085.paswt.rst, hadgem.2085.paswt.rst) 
ddwt.2085 <- mean (canesm2.2085.ddwt.rst, ccsm4.2085.ddwt.rst, hadgem.2085.ddwt.rst) 
ddsp.2085 <- mean (canesm2.2085.ddsp.rst, ccsm4.2085.ddsp.rst, hadgem.2085.ddsp.rst) 
ddat.2085 <- mean (canesm2.2085.ddat.rst, ccsm4.2085.ddat.rst, hadgem.2085.ddat.rst) 
nffdsp.2085 <- mean (canesm2.2085.nffdsp.rst, ccsm4.2085.nffdsp.rst, hadgem.2085.nffdsp.rst) 
nffdat.2085 <- mean (canesm2.2085.nffdat.rst, ccsm4.2085.nffdat.rst, hadgem.2085.nffdat.rst) 
clim.2085.stack <- stack (tavewt.2085, tmaxwt.2085, tminwt.2085, tavesm.2085, tmaxsm.2085, 
                          pptwt.2085, paswt.2085, ddwt.2085, ddsp.2085, ddat.2085, nffdsp.2085, nffdat.2085) 
names (clim.2085.stack) <- c ("tavewt.2085", "tmaxwt.2085", "tminwt.2085", "tavesm.2085", 
                              "tmaxsm.2085", "pptwt.2085", "paswt.2085", "ddwt.2085", "ddsp.2085", 
                              "ddat.2085", "nffdsp.2085", "nffdat.2085") 
clim.2085.brick <- brick (clim.2085.stack)

rm (bec2020.rst, bec2050.rst, bec2080.rst, bec.future.stack) # dump some data
rm (clim.1981.2010.tavewt.rst, clim.1981.2010.tmaxwt.rst, clim.1981.2010.tminwt.rst,
    clim.1981.2010.tavesm.rst, clim.1981.2010.tmaxsm.rst, clim.1981.2010.pptwt.rst,
    clim.1981.2010.paswt.rst, clim.1981.2010.ddat.rst, clim.1981.2010.ddsp.rst,
    clim.1981.2010.ddwt.rst, clim.1981.2010.nffdat.rst, clim.1981.2010.nffdsp.rst, clim.current.stack) 
rm (clim.1961.1990.tavewt.rst, clim.1961.1990.tmaxwt.rst, clim.1961.1990.tminwt.rst,
    clim.1961.1990.tavesm.rst, clim.1961.1990.tmaxsm.rst, clim.1961.1990.pptwt.rst,
    clim.1961.1990.paswt.rst, clim.1961.1990.ddat.rst, clim.1961.1990.ddsp.rst,
    clim.1961.1990.ddwt.rst, clim.1961.1990.nffdat.rst, clim.1961.1990.nffdsp.rst, clim.historic.stack) 
rm (canesm2.2025.tavewt.rst, ccsm4.2025.tavewt.rst, hadgem.2025.tavewt.rst, tavewt.2025)
rm (canesm2.2025.tmaxwt.rst, ccsm4.2025.tmaxwt.rst, hadgem.2025.tmaxwt.rst, tmaxwt.2025)
rm (canesm2.2025.tminwt.rst, ccsm4.2025.tminwt.rst, hadgem.2025.tminwt.rst, tminwt.2025)
rm (canesm2.2025.tavesm.rst, ccsm4.2025.tavesm.rst, hadgem.2025.tavesm.rst, tavesm.2025)
rm (canesm2.2025.tmaxsm.rst, ccsm4.2025.tmaxsm.rst, hadgem.2025.tmaxsm.rst, tmaxsm.2025)
rm (canesm2.2025.pptwt.rst, ccsm4.2025.pptwt.rst, hadgem.2025.pptwt.rst, pptwt.2025)
rm (canesm2.2025.paswt.rst, ccsm4.2025.paswt.rst, hadgem.2025.paswt.rst, paswt.2025, clim.2025.stack)
rm (canesm2.2025.ddwt.rst, ccsm4.2025.ddwt.rst, hadgem.2025.ddwt.rst, ddwt.2025)
rm (canesm2.2025.ddsp.rst, ccsm4.2025.ddsp.rst, hadgem.2025.ddsp.rst, ddsp.2025)
rm (canesm2.2025.ddat.rst, ccsm4.2025.ddat.rst, hadgem.2025.ddat.rst, ddat.2025)
rm (canesm2.2025.nffdsp.rst, ccsm4.2025.nffdsp.rst, hadgem.2025.nffdsp.rst, nffdsp.2025)
rm (canesm2.2025.nffdat.rst, ccsm4.2025.nffdat.rst, hadgem.2025.nffdat.rst, nffdat.2025)
rm (canesm2.2055.tavewt.rst, ccsm4.2055.tavewt.rst, hadgem.2055.tavewt.rst, tavewt.2055)
rm (canesm2.2055.tmaxwt.rst, ccsm4.2055.tmaxwt.rst, hadgem.2055.tmaxwt.rst, tmaxwt.2055)
rm (canesm2.2055.tminwt.rst, ccsm4.2055.tminwt.rst, hadgem.2055.tminwt.rst, tminwt.2055)
rm (canesm2.2055.tavesm.rst, ccsm4.2055.tavesm.rst, hadgem.2055.tavesm.rst, tavesm.2055)
rm (canesm2.2055.pptwt.rst, ccsm4.2055.pptwt.rst, hadgem.2055.pptwt.rst, pptwt.2055)
rm (canesm2.2055.paswt.rst, ccsm4.2055.paswt.rst, hadgem.2055.paswt.rst, paswt.2055, clim.2055.stack)
rm (canesm2.2055.tmaxsm.rst, ccsm4.2055.tmaxsm.rst, hadgem.2055.tmaxsm.rst, tmaxsm.2055)
rm (canesm2.2055.ddwt.rst, ccsm4.2055.ddwt.rst, hadgem.2055.ddwt.rst, ddwt.2055)
rm (canesm2.2055.ddsp.rst, ccsm4.2055.ddsp.rst, hadgem.2055.ddsp.rst, ddsp.2055)
rm (canesm2.2055.ddat.rst, ccsm4.2055.ddat.rst, hadgem.2055.ddat.rst, ddat.2055)
rm (canesm2.2055.nffdsp.rst, ccsm4.2055.nffdsp.rst, hadgem.2055.nffdsp.rst, nffdsp.2055)
rm (canesm2.2055.nffdat.rst, ccsm4.2055.nffdat.rst, hadgem.2055.nffdat.rst, nffdat.2055)
rm (canesm2.2085.tavewt.rst, ccsm4.2085.tavewt.rst, hadgem.2085.tavewt.rst, tavewt.2085)
rm (canesm2.2085.tmaxwt.rst, ccsm4.2085.tmaxwt.rst, hadgem.2085.tmaxwt.rst, tmaxwt.2085)
rm (canesm2.2085.tminwt.rst, ccsm4.2085.tminwt.rst, hadgem.2085.tminwt.rst, tminwt.2085)
rm (canesm2.2085.tavesm.rst, ccsm4.2085.tavesm.rst, hadgem.2085.tavesm.rst, tavesm.2085)
rm (canesm2.2085.pptwt.rst, ccsm4.2085.pptwt.rst, hadgem.2085.pptwt.rst, pptwt.2085)
rm (canesm2.2085.paswt.rst, ccsm4.2085.paswt.rst, hadgem.2085.paswt.rst, paswt.2085, clim.2085.stack)
rm (canesm2.2085.tmaxsm.rst, ccsm4.2085.tmaxsm.rst, hadgem.2085.tmaxsm.rst, tmaxsm.2085)
rm (canesm2.2085.ddwt.rst, ccsm4.2085.ddwt.rst, hadgem.2085.ddwt.rst, ddwt.2085)
rm (canesm2.2085.ddsp.rst, ccsm4.2085.ddsp.rst, hadgem.2085.ddsp.rst, ddsp.2085)
rm (canesm2.2085.ddat.rst, ccsm4.2085.ddat.rst, hadgem.2085.ddat.rst, ddat.2085)
rm (canesm2.2085.nffdsp.rst, ccsm4.2085.nffdsp.rst, hadgem.2085.nffdsp.rst, nffdsp.2085)
rm (canesm2.2085.nffdat.rst, ccsm4.2085.nffdat.rst, hadgem.2085.nffdat.rst, nffdat.2085)

#=======================================================================
# Define 'study area' boundaries, by Ecotype 
#=======================================================================
# remove Haida Gwaii
caribou.range <- caribou.range [caribou.range@data$OBJECTID != 138, ] # NOTE: the polygon ID was obtained using ArcGIS; not sure how to get that using R 
caribou.range@data[["diss"]] <- 1  # add field in data frame for 'dissolving' data
caribou.range.boreal <- subset (caribou.range, caribou.range@data$ECOTYPE == "Boreal")
caribou.range.mtn <- subset (caribou.range, caribou.range@data$ECOTYPE == "Mountain")
caribou.range.north <- subset (caribou.range, caribou.range@data$ECOTYPE == "Northern")
caribou.range.boreal.diss <- aggregate (caribou.range.boreal, by = 'diss') 
caribou.range.mtn.diss <- aggregate (caribou.range.mtn, by = 'diss') 
caribou.range.north.diss <- aggregate (caribou.range.north, by = 'diss') 
caribou.range.boreal.buff.25km <- gBuffer (caribou.range.boreal.diss, width = 25000) # buffer ecotype ranges by 25km, a reasonable distance based on wolf territory size (Mech et al. 2003, pg 174) 
caribou.range.mtn.buff.25km <- gBuffer (caribou.range.mtn.diss, width = 25000) 
caribou.range.north.buff.25km <- gBuffer (caribou.range.north.diss, width = 25000) 
caribou.boreal.sa <- gIntersection (caribou.range.boreal.buff.25km, prov.bnd.prj) # clip by province
caribou.mtn.sa <- gIntersection (caribou.range.mtn.buff.25km, prov.bnd.prj) 
caribou.north.sa <- gIntersection (caribou.range.north.buff.25km, prov.bnd.prj) 
caribou.boreal.sa.data <- data.frame (matrix (ncol = 1, nrow = 1)) # add 'data' to each area
caribou.mtn.sa.data <- data.frame (matrix (ncol = 1, nrow = 1))
caribou.north.sa.data <- data.frame (matrix (ncol = 1, nrow = 1))
x <- "avail.ecotype"
colnames (caribou.boreal.sa.data) <- x
colnames (caribou.mtn.sa.data) <- x
colnames (caribou.north.sa.data) <- x
caribou.boreal.sa.data$avail.ecotype <- "Boreal"
caribou.mtn.sa.data$avail.ecotype <- "Mountain"
caribou.north.sa.data$avail.ecotype <- "Northern"
caribou.boreal.sa <- SpatialPolygonsDataFrame (caribou.boreal.sa, data = caribou.boreal.sa.data)
caribou.mtn.sa <- SpatialPolygonsDataFrame (caribou.mtn.sa, data = caribou.mtn.sa.data)
caribou.north.sa <- SpatialPolygonsDataFrame (caribou.north.sa, data = caribou.north.sa.data)
writeOGR (caribou.boreal.sa, dsn = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\studyarea\\caribou_boreal_study_area.shp", 
          layer = "caribou_boreal_study_area", driver = "ESRI Shapefile")
writeOGR (caribou.mtn.sa, dsn = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\studyarea\\caribou_mtn_study_area.shp", 
          layer = "caribou_mtn_study_area", driver = "ESRI Shapefile")
writeOGR (caribou.north.sa, dsn = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\climate_analysis\\data\\studyarea\\caribou_north_study_area.shp", 
          layer = "caribou_north_study_area", driver = "ESRI Shapefile")
# caribou.boreal.sa <- readOGR ("studyarea\\caribou_boreal_study_area.shp", stringsAsFactors = T)
# caribou.mtn.sa <- readOGR ("studyarea\\caribou_mtn_study_area.shp", stringsAsFactors = T)
# caribou.north.sa <- readOGR ("studyarea\\caribou_north_study_area.shp", stringsAsFactors = T)

#=================================================================================================================
# Generate points in study areas (only produce the points once for consistency; just load data below from now on)
#=================================================================================================================
sample.pts.boreal <- spsample (caribou.boreal.sa, cellsize = c (2000, 2000), type = "regular")
sample.pts.mtn <- spsample (caribou.mtn.sa, cellsize = c (2000, 2000), type = "regular")
sample.pts.north <- spsample (caribou.north.sa, cellsize = c (2000, 2000), type = "regular")
sample.pts.boreal.data <- data.frame (matrix (ncol = 3, nrow = nrow (sample.pts.boreal@coords))) # add 'data' to the points
colnames (sample.pts.boreal.data) <- c ("sample.point", "ptID", "avail.ecotype")
sample.pts.boreal.data$sample.point <- 1
sample.pts.boreal.data$ptID <- 1:16296
sample.pts.boreal.data$avail.ecotype <- "Boreal"
sample.pts.boreal <- SpatialPointsDataFrame (sample.pts.boreal, data = sample.pts.boreal.data)
sample.pts.mtn.data <- data.frame (matrix (ncol = 3, nrow = 26998)) # add 'data' to the points
colnames (sample.pts.mtn.data) <- c ("sample.point", "ptID", "avail.ecotype")
sample.pts.mtn.data$sample.point <- 1
sample.pts.mtn.data$ptID <- 16297:43294
sample.pts.mtn.data$avail.ecotype <- "Mountain"
sample.pts.mtn <- SpatialPointsDataFrame (sample.pts.mtn, data = sample.pts.mtn.data)
sample.pts.north.data <- data.frame (matrix (ncol = 3, nrow = 87760)) # add 'data' to the points
colnames (sample.pts.north.data) <- c ("sample.point", "ptID", "avail.ecotype")
sample.pts.north.data$sample.point <- 1
sample.pts.north.data$ptID <- 43295:131054
sample.pts.north.data$avail.ecotype <- "Northern"
sample.pts.north <- SpatialPointsDataFrame (sample.pts.north, data = sample.pts.north.data)
sample.pts <- maptools::spRbind (spRbind (sample.pts.boreal, sample.pts.mtn), sample.pts.north)
sample.pts@data$avail.ecotype <- as.factor (sample.pts@data$avail.ecotype)
writeOGR (sample.pts, 
          dsn = "C:\\Work\\caribou\\climate_analysis\\data\\samplepoints\\sample_points_raw_20180502.shp", 
          layer = "sample_points", driver = "ESRI Shapefile")
# sample.pts <- readOGR ("samplepoints\\sample_points_raw_20180502.shp", stringsAsFactors = T)

#======================================================================
# Identify points that overlap with caribou ranges
#======================================================================
sample.pts.prj <- spTransform (sample.pts, CRS = proj.crs) 
sample.pts.bou.rg <- sp::over (sample.pts.prj, caribou.range)
sample.pts.bou.rg$ptID <- 1:131054 # create a ptID to join data on; I did some visual inspection in GIS to see where points fell relative to caribou range and confirmed that the point order is equivalent to ID
sample.pts.prj@data <- dplyr::full_join (sample.pts.prj@data, sample.pts.bou.rg, 
                                         by = c ("ptID" = "ptID")) 

#===================================================
# Sample current BEC at locations
#===================================================
sample.pts.bec <- sp::over (sample.pts.prj, bec.current [15]) # column 15 is the BEC name
sample.pts.bec$ptID <- 1:131054 # create a ptID to join data on
sample.pts.prj@data <- dplyr::full_join (sample.pts.prj@data, sample.pts.bec, 
                                         by = c ("ptID" = "ptID")) 
# I did some visual inspection in GIS to see where points fell relative to caribou range and 
# confirmed that the point order is equivalent to ID. 

#=================================
# Sample future BEC at locations
#=================================
# Transforming the raster projection 'lost' the @data@attributes$dataframe classes for BEC zone
# So, I transformed the points to raster porjection here before extracting data.
# The implication of using the 'native' raster projection is that it is in decimal degrees and thus 
# the resolution (0.0083333) changes with latitude. When measured in metric distance (m) the cell 
# height was pretty concistent acorss the province (~925m) but the width was ~450m in the north and 
# ~600 m in the south. This isn't a huge difference but may need some consideration, or at least 
# clarification in interpretation of the model results. 
ras.crs <- proj4string (bec.future.brick)
sample.pts.ras.prj <- spTransform (sample.pts.prj, CRS = ras.crs)
sample.pts.future.bec <- raster::extract (bec.future.brick, sample.pts.ras.prj, method = 'simple',
                                          factors = T, df = T) 
sample.pts.future.bec$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, sample.pts.future.bec, 
                                             by = c ("ptID" = "ptID")) 
# sample.pts <- readOGR ("samplepoints\\sample_points_final_20180330.shp", 
#                        stringsAsFactors = T)

#==================================================
# Sample historic and current climate at locations
#=================================================
sample.pts.clim.curr <- raster::extract (clim.current.brick, sample.pts.ras.prj, 
                                         method = 'simple',
                                         factors = F, df = T) 
sample.pts.clim.curr$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, 
                                             sample.pts.clim.curr, 
                                             by = c ("ptID" = "ptID"))

sample.pts.clim.hist <- raster::extract (clim.historic.brick, sample.pts.ras.prj, 
                                         method = 'simple',
                                         factors = F, df = T) 
sample.pts.clim.hist$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, 
                                             sample.pts.clim.hist, 
                                             by = c ("ptID" = "ptID"))

#===============================================================================
# Sample future climate at locations; mean value of the three climate models
#==============================================================================
sample.pts.clim.2025 <- raster::extract (clim.2025.brick, sample.pts.ras.prj, 
                                         method = 'simple',
                                         factors = F, df = T) 
sample.pts.clim.2025$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, 
                                             sample.pts.clim.2025, 
                                             by = c ("ptID" = "ptID"))
sample.pts.clim.2055 <- raster::extract (clim.2055.brick, sample.pts.ras.prj, 
                                         method = 'simple',
                                         factors = F, df = T) 
sample.pts.clim.2055$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, 
                                             sample.pts.clim.2055, 
                                             by = c ("ptID" = "ptID"))
sample.pts.clim.2085 <- raster::extract (clim.2085.brick, sample.pts.ras.prj, 
                                         method = 'simple',
                                         factors = F, df = T) 
sample.pts.clim.2085$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, 
                                             sample.pts.clim.2085, 
                                             by = c ("ptID" = "ptID"))

#===============================================================================
# Disturbance data
#==============================================================================
# Roads
# I calculated road density in ArcGIS using the Line Density Spatial Analsysis tool
# I used the digital road atlas (DRA) data and clipped the DRA data to 
# the larger caribou study area (i.e., extant range buffered by 100km).
# I calculated line density at a 1km resolution (pixel) in a 1km and 27.185km
# area around each pixel. The 27km area is the circular radius of the median 
# caribou range size in B.C. (i.e., median caribou range size = 2321.73224071500
# where radius of median range size  = sq.rt. (2321.7/pi))
# I explored ways to calculate line density in R. There were solutions (see:
# https://gis.stackexchange.com/questions/119993/convert-line-shapefile-to-raster-value-total-length-of-lines-within-cell
# however, they took a very long time to process (days in some cases) and thus 
# I was unable to find a tenable solution for the size of the datasets. 
# Will explore later if there is time.
# roads <- spTransform (roads, CRS = ras.crs)
empty.raster <- raster (nrows = 1404, ncols = 3001, xmn = -139.0632,  
                        xmx = -114.055, ymn = 48.30073, ymx = 60.00068, 
                        res = 0.0083333, crs = ras.crs)
# roads@data$raster <- 1
# raster.roads <- raster::rasterize (roads, empty.raster, field = roads@data$raster, update = T)
# raster.roads.poly <- rasterToPolygons (raster.roads)
# roads.isect <- gIntersection (roads, raster.roads.poly, byid = TRUE)
roads.stack <- stack (roads.1k.rst, roads.27k.rst) # stack the future bec data together
names (roads.stack) <- c ("road.dns.1k", "road.dns.27k") # rename the bands
roads.brick <- brick (roads.stack) # brick the stack as a single layer
rm (roads.stack)
sample.pts.roads <- raster::extract (roads.brick, sample.pts.ras.prj, 
                                     method = 'bilinear',
                                     factors = F, df = T) 
sample.pts.roads$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, 
                                             sample.pts.roads, 
                                             by = c ("ptID" = "ptID")) 

# Wells
wells <- spTransform (wells, CRS = ras.crs)
wells <- wells [wells@data$CONST_CODE == "CONS", ] # subset constructed wells only
ras.wells <- rasterize (wells, empty.raster, getCover = T) # calculates (approx) percentage of raster cell covered by the well polygons
# writeRaster (ras.wells, "wells\\raster\\well_rast.tif", format = "GTiff", 
#              prj = T)
# ras.wells <- raster ("wells\\raster\\well_rast.tif")
sample.pts.wells <- raster::extract (ras.wells, sample.pts.ras.prj, 
                                     method = 'bilinear',
                                     factors = F, df = T) 
sample.pts.wells$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, 
                                             sample.pts.wells, 
                                             by = c ("ptID" = "ptID")) 
names (sample.pts.ras.prj@data) [101] <- "well.prop" 

# Cutblocks 
cutblocks40 <- cutblocks [cutblocks@data$HARVESTYR > 1977, ]  
# subset last 40 years
cutblocks40 <- spTransform (cutblocks40, CRS = ras.crs)
ras.cutblocks <- rasterize (cutblocks40, empty.raster, getCover = T)
sample.pts.cut <- raster::extract (ras.cutblocks, sample.pts.ras.prj, 
                                   method = 'bilinear',
                                   factors = F, df = T) 
sample.pts.cut$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, sample.pts.cut, 
                                             by = c ("ptID" = "ptID")) 
names (sample.pts.ras.prj@data) [104] <- "cut.prop" 
# writeRaster (ras.cutblocks, "cutblocks\\raster\\cut_rast.tif", format = "GTiff", prj = T)
# ras.cutblocks <- raster ("cutblocks\\raster\\cut_rast.tif")
# test1 <- sample.pts.ras.prj@data [sample.pts.ras.prj@data$ptID == 200000, ]

#=================================
# Export/Save the data
#=================================
names (sample.pts.ras.prj@data) [15] <- "bec.current"
sample.pts.ras.prj@data$pttype <- ifelse (sample.pts.ras.prj@data$HERD_NAME == "NA", "0", "1") 
sample.pts.ras.prj@data$pttype [is.na (sample.pts.ras.prj@data$pttype)] <- 0
sample.pts.ras.prj@data$HERD_STAT <- as.character (sample.pts.ras.prj@data$HERD_STAT)
sample.pts.ras.prj@data$HERD_STAT [is.na (sample.pts.ras.prj@data$HERD_STAT )] <- "Outside"
sample.pts.ras.prj@data$HERD_STAT  <- as.factor (sample.pts.ras.prj@data$HERD_STAT)
sample.pts.ras.prj@data$HERD_NAME <- as.character (sample.pts.ras.prj@data$HERD_NAME)
sample.pts.ras.prj@data$HERD_NAME [is.na (sample.pts.ras.prj@data$HERD_NAME)] <- "Outside"
sample.pts.ras.prj@data$HERD_NAME <- as.factor (sample.pts.ras.prj@data$HERD_NAME)
# NOTE: NAMES MAY NEED TO BE REORDERED
names (sample.pts.ras.prj@data) [3] <- "ecotype"
names (sample.pts.ras.prj@data) [4] <- "in_herd"
names (sample.pts.ras.prj@data) [6] <- "herdname"
names (sample.pts.ras.prj@data) [15] <- "bec_cur"
names (sample.pts.ras.prj@data) [21] <- "bec2020"
names (sample.pts.ras.prj@data) [26] <- "bec2050"
names (sample.pts.ras.prj@data) [31] <- "bec2080"
names (sample.pts.ras.prj@data) [33] <- "taw2010"
names (sample.pts.ras.prj@data) [34] <- "txw2010"
names (sample.pts.ras.prj@data) [35] <- "tiw2010"
names (sample.pts.ras.prj@data) [36] <- "tas2010"
names (sample.pts.ras.prj@data) [37] <- "txs2010"
names (sample.pts.ras.prj@data) [38] <- "ptw2010"
names (sample.pts.ras.prj@data) [39] <- "psw2010"
names (sample.pts.ras.prj@data) [40] <- "dwt2010"
names (sample.pts.ras.prj@data) [41] <- "dsp2010"
names (sample.pts.ras.prj@data) [42] <- "dat2010"
names (sample.pts.ras.prj@data) [42] <- "dat2010"
names (sample.pts.ras.prj@data) [43] <- "fsp2010"
names (sample.pts.ras.prj@data) [44] <- "fat2010"
names (sample.pts.ras.prj@data) [46] <- "taw1990"
names (sample.pts.ras.prj@data) [47] <- "txw1990"
names (sample.pts.ras.prj@data) [48] <- "tiw1990"
names (sample.pts.ras.prj@data) [49] <- "tas1990"
names (sample.pts.ras.prj@data) [50] <- "txs1990"
names (sample.pts.ras.prj@data) [51] <- "ptw1990"
names (sample.pts.ras.prj@data) [52] <- "psw1990"
names (sample.pts.ras.prj@data) [53] <- "dwt1990"
names (sample.pts.ras.prj@data) [54] <- "dsp1990"
names (sample.pts.ras.prj@data) [55] <- "dat1990"
names (sample.pts.ras.prj@data) [56] <- "fsp1990"
names (sample.pts.ras.prj@data) [57] <- "fat1990"
names (sample.pts.ras.prj@data) [59] <- "taw2025"
names (sample.pts.ras.prj@data) [60] <- "txw2025"
names (sample.pts.ras.prj@data) [61] <- "tiw2025"
names (sample.pts.ras.prj@data) [62] <- "tas2025"
names (sample.pts.ras.prj@data) [63] <- "txs2025"
names (sample.pts.ras.prj@data) [64] <- "ptw2025"
names (sample.pts.ras.prj@data) [65] <- "psw2025"
names (sample.pts.ras.prj@data) [66] <- "dwt2025"
names (sample.pts.ras.prj@data) [67] <- "dsp2025"
names (sample.pts.ras.prj@data) [68] <- "dat2025"
names (sample.pts.ras.prj@data) [69] <- "fsp2025"
names (sample.pts.ras.prj@data) [70] <- "fat2025"
names (sample.pts.ras.prj@data) [72] <- "taw2055"
names (sample.pts.ras.prj@data) [73] <- "txw2055"
names (sample.pts.ras.prj@data) [74] <- "tiw2055"
names (sample.pts.ras.prj@data) [75] <- "tas2055"
names (sample.pts.ras.prj@data) [76] <- "txs2055"
names (sample.pts.ras.prj@data) [77] <- "ptw2055"
names (sample.pts.ras.prj@data) [78] <- "psw2055"
names (sample.pts.ras.prj@data) [79] <- "dwt2055"
names (sample.pts.ras.prj@data) [80] <- "dsp2055"
names (sample.pts.ras.prj@data) [81] <- "dat2055"
names (sample.pts.ras.prj@data) [82] <- "fsp2055"
names (sample.pts.ras.prj@data) [83] <- "fat2055"
names (sample.pts.ras.prj@data) [85] <- "taw2085"
names (sample.pts.ras.prj@data) [86] <- "txw2085"
names (sample.pts.ras.prj@data) [87] <- "tiw2085"
names (sample.pts.ras.prj@data) [88] <- "tas2085"
names (sample.pts.ras.prj@data) [89] <- "txs2085"
names (sample.pts.ras.prj@data) [90] <- "ptw2085"
names (sample.pts.ras.prj@data) [91] <- "psw2085"
names (sample.pts.ras.prj@data) [92] <- "dwt2085"
names (sample.pts.ras.prj@data) [93] <- "dsp2085"
names (sample.pts.ras.prj@data) [94] <- "dat2085"
names (sample.pts.ras.prj@data) [95] <- "fsp2085"
names (sample.pts.ras.prj@data) [96] <- "fat2085"
names (sample.pts.ras.prj@data) [98] <- "rd_dn1k"
names (sample.pts.ras.prj@data) [99] <- "rddn27k"
names (sample.pts.ras.prj@data) [101] <- "wellper"
names (sample.pts.ras.prj@data) [102] <- "pttype"
names (sample.pts.ras.prj@data) [104] <- "cutper"
writeOGR (sample.pts.ras.prj, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\samplepoints\\sample_points_final_20180502.shp", layer = "sample_points", driver = "ESRI Shapefile")
data <- data.frame (subset (sample.pts.ras.prj@data, 
                            select = c (ptID, pttype, in_herd, ecotype, herdname, bec_cur, bec2020,
                                        bec2050, bec2080, taw1990, txw1990, tiw1990, tas1990, txs1990,
                                        ptw1990, psw1990, dwt1990, dsp1990, dat1990, fsp1990, fat1990,
                                        taw2010, txw2010, tiw2010, tas2010, txs2010, ptw2010, psw2010,
                                        dwt2010, dsp2010, dat2010, fsp2010, fat2010, taw2025, txw2025,
                                        tiw2025, tas2025, txs2025, ptw2025, psw2025, dwt2025, dsp2025,
                                        dat2025, fsp2025, fat2025, taw2055, txw2055, tiw2055, tas2055,
                                        txs2055, ptw2055, psw2055, dwt2055, dsp2055, dat2055, fsp2055,
                                        fat2055, taw2085, txw2085, tiw2085, tas2085, txs2085,
                                        ptw2085, psw2085, dwt2085, dsp2085, dat2085, fsp2085, fat2085,
                                        rd_dn1k, rddn27k, wellper, cutper)))
names (data) [3] <- "in.out.herd"
names (data) [6] <- "bec.current"
names (data) [10] <- "tave.wt.1990"
names (data) [11] <- "tmax.wt.1990"
names (data) [12] <- "tmin.wt.1990"
names (data) [13] <- "tave.su.1990"
names (data) [14] <- "tmax.su.1990"
names (data) [15] <- "ppt.wt.1990"
names (data) [16] <- "pas.wt.1990"
names (data) [17] <- "dd.wt.1990"
names (data) [18] <- "dd.sp.1990"
names (data) [19] <- "dd.at.1990"
names (data) [20] <- "nffd.sp.1990"
names (data) [21] <- "nffd.at.1990"
names (data) [22] <- "tave.wt.2010"
names (data) [23] <- "tmax.wt.2010"
names (data) [24] <- "tmin.wt.2010"
names (data) [25] <- "tave.su.2010"
names (data) [26] <- "tmax.su.2010"
names (data) [27] <- "ppt.wt.2010"
names (data) [28] <- "pas.wt.2010"
names (data) [29] <- "dd.wt.2010"
names (data) [30] <- "dd.sp.2010"
names (data) [31] <- "dd.at.2010"
names (data) [32] <- "nffd.sp.2010"
names (data) [33] <- "nffd.at.2010"
names (data) [34] <- "tave.wt.2025"
names (data) [35] <- "tmax.wt.2025"
names (data) [36] <- "tmin.wt.2025"
names (data) [37] <- "tave.su.2025"
names (data) [38] <- "tmax.su.2025"
names (data) [39] <- "ppt.wt.2025"
names (data) [40] <- "pas.wt.2025"
names (data) [41] <- "dd.wt.2025"
names (data) [42] <- "dd.sp.2025"
names (data) [43] <- "dd.at.2025"
names (data) [44] <- "nffd.sp.2025"
names (data) [45] <- "nffd.at.2025"
names (data) [46] <- "tave.wt.2055"
names (data) [47] <- "tmax.wt.2055"
names (data) [48] <- "tmin.wt.2055"
names (data) [49] <- "tave.su.2055"
names (data) [50] <- "tmax.su.2055"
names (data) [51] <- "ppt.wt.2055"
names (data) [52] <- "pas.wt.2055"
names (data) [53] <- "dd.wt.2055"
names (data) [54] <- "dd.sp.2055"
names (data) [55] <- "dd.at.2055"
names (data) [56] <- "nffd.sp.2055"
names (data) [57] <- "nffd.at.2055"
names (data) [58] <- "tave.wt.2085"
names (data) [59] <- "tmax.wt.2085"
names (data) [60] <- "tmin.wt.2085"
names (data) [61] <- "tave.su.2085"
names (data) [62] <- "tmax.su.2085"
names (data) [63] <- "ppt.wt.2085"
names (data) [64] <- "pas.wt.2085"
names (data) [65] <- "dd.wt.2085"
names (data) [66] <- "dd.sp.2085"
names (data) [67] <- "dd.at.2085"
names (data) [68] <- "nffd.sp.2085"
names (data) [69] <- "nffd.at.2085"
names (data) [70] <- "road.dns.1k"
names (data) [71] <- "road.dns.27k"
names (data) [72] <- "well.perc"
names (data) [73] <- "cut.perc"
data$pttype <- as.integer (data$pttype)
write.table (data, "C:\\Work\\caribou\\climate_analysis\\data\\model\\model_data_20180502.csv", 
             sep = ",")


