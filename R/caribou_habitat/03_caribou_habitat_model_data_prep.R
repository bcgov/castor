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
#  R Version: 3.4.3
#  R Packages: sp, raster, rgeos, dplyr, rgdal, maptools, spatstat
#  Data: 
#=================================

#=================================
# data directory
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

# require (sp) # spatial package; particulary useful for working with vector data
# require (raster) # for working with and processing raster data; 
# require (rgeos) # geoprocessing functions
# require (dplyr)
# require (rgdal) # for loading and writing spatial data
# require (maptools)
# require (spatstat)
# require (adehabitatHR)

#===================================================
# Load data, rasterize to 1ha and put into postgres
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

# ha BC standard raster
ProvRast <- raster (nrows = 15744, ncols = 17216, 
                    xmn = 159587.5, xmx = 1881187.5, 
                    ymn = 173787.5, ymx = 1748187.5,                      
                    crs = 3005, 
                    resolution = c (100, 100), vals = 0) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R
# writeRasterQuery (c ("admin_boundaries", "raster_ha_bc"), ProvRast)
# ProvRast <- pgGetRast (conn, c ("admin_boundaries", "raster_ha_bc"))

# bec as polygon and rasterized to ha bc
bec <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                    layer = "bec_poly_20180725")

writeTableQuery (bec, c ("vegetation", "bec_poly_20180725"))

ras.bec.zone <- fasterize (bec, ProvRast, field = "ZONE" , 
                           fun = "last") # takes the 'last' polygon value for the raster; ideally would use the most common, but couldn't find a function for that
writeRasterQuery (c ("vegetation", "raster_bec_zone_current"), ras.bec.zone)
lut_bec_zone_current <- data.frame (levels (bec$ZONE))
lut_bec_zone_current$raster_integer <- c (1:16)
writeTableQuery (lut_bec_zone_current, "lut_bec_current")









# 'new' vri landscalsses for raster






dem.ha.bc <- raster::resample (dem.all, ProvRast, method = "ngb") # nearest neighbour resampling
raster::writeRaster (dem.ha.bc, filename = "all_bc\\dem_ha_bc.tif", format = "GTiff", overwrite = T)




caribou.range <- readOGR ("caribou\\caribou_herd\\GCPB_CARIBOU_POPULATION_SP\\GCBP_CARIB_polygon.shp", 
                          stringsAsFactors = T)
prov.bnd <- readOGR ("province\\gpr_000b11a_e.shp", stringsAsFactors = T)
bec.current <- readOGR ("bec\\BEC_current\\BEC_BIOGEOCLIMATIC_POLY\\BEC_POLY_polygon.shp", 
                          stringsAsFactors = T)
roads.ce <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\roads\\BC_CE_IntegratedRoads_2017_v1_20170214.gdb",
                     layer = "integrated_roads") 
vri <- readOGR (dsn = "C:\Work\caribou\climate_analysis\data\vri\vri\VEG_COMP_LYR_R1_POLY.gdb",
                layer = "")


# roads <- readOGR ("roads\\DRA_DGTL_ROAD_ATLAS_DPAR_SP\\RA_DPAR_line.shp")
# https://github.com/bcgov/bc-raster-roads
roads.1k.rst <- raster ("roads\\dra_dens_1k_tif\\dra_dns_1km.tif")
roads.27k.rst <- raster ("roads\\dra_dens_27km_tif\\dra_dns_27k.tif")
cutblocks <- readOGR ("cutblocks\\VEG_CONSOLIDATED_CUT_BLOCKS_SP\\CNS_CUT_BL_polygon.shp")
wells <- readOGR ("wells\\OG_WELL_FACILITY_PERMIT_SP\\OG_WEL_F_P_polygon.shp")

dem <- raster ("C:\\Work\\caribou\\climate_analysis\\data\\dem\\104m16_w.dem")





drv <- dbDriver ("PostgreSQL")
conn <- dbConnect (drv, # connection to the postgres db where you want to store the data
                   host = "",
                   user = "postgres",
                   dbname = "caribou_habitat",
                   password = "postgres",
                   port = "5432")
pgWriteRast (conn, "dem_all_bc", dem.all, overwrite = TRUE, bit.depth = "16BUI", 
             blocks = c (1000, 1000)) # http://postgis.net/docs/RT_ST_BandPixelType.html
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

#===================================
# Caribou Home Range Scale Analysis
#==================================

#=================================
# Load the Telemetry Data
#=================================
# needed to convert from multipoitn to pint geomtery in arcgis 
prov.locs <- sf::st_read (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\caribou_telemetry.gdb",
                          layer = "spi_telemetry_obs_all_caribou_20180502") # errors reading with OGR for soem reason; used SF to read 
prov.locs.single <- st_cast (prov.locs, "POINT") # function in SF to switch form multipoint to Point feature; was having difficulties working with multipoint data 
prov.locs.single <- as (prov.locs.single, "Spatial") # and then coerce to to SpatialPoints here; https://cran.r-project.org/web/packages/sf/vignettes/sf2.html

boreal.locs <- readOGR ("C:\\Work\\caribou\\climate_analysis\\data\\caribou\\caribou_telemetry_shape\\boreal_caribou_telemetry_2013_2018.shp")
telem.crs <- proj4string (caribou.range.boreal)
boreal.locs.prj <- spTransform (boreal.locs, CRS = telem.crs) 

writeOGR (obj = prov.locs.single, 
          dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\caribou_telemetry_shape_raw", 
          layer = "spi_telemetry_point_raw", driver = "ESRI Shapefile")

#=================================
#  Prepare the Telemetry Data
#=================================
# freq.year <- table (prov.locs.single@data$OBSERVATION_YEAR) # frequency of locations by year
# divided data by season
# identified based on lit. review; a decent amount of variability there, but settled on:
# calving/summer/fall	(summer) = 15-May to 31-Oct 
# early winter =	01-Nov	to 15-Jan
# late winter	= 16-Jan to 14-May
# note that I tried a seperate calving season, but estimating calving season home ranges was 
# difficult in the boreal because of apparent variability in calving dates and associated movements
# resulting in highly variable home range sizes depending if and when the animal moved to calve
# also, on further reflection I don't know if an animal was male or female, and habitat use
# of each is obviously different, so I went with a more broader seasonal definition  
prov.locs.summer <- subset (prov.locs.single, 
                             prov.locs.single$OBSERVATION_MONTH == 5 & 
                             prov.locs.single$OBSERVATION_DAY >= 15 |
                             prov.locs.single$OBSERVATION_MONTH >= 6 &
                             prov.locs.single$OBSERVATION_MONTH < 11)

prov.locs.early.winter <- subset (prov.locs.single, 
                                  prov.locs.single$OBSERVATION_MONTH > 10 |
                                  prov.locs.single$OBSERVATION_MONTH == 1 &
                                  prov.locs.single$OBSERVATION_DAY < 16)

prov.locs.late.winter <- subset (prov.locs.single, 
                                 prov.locs.single$OBSERVATION_MONTH == 1 & 
                                 prov.locs.single$OBSERVATION_DAY > 15 |
                                 prov.locs.single$OBSERVATION_MONTH == 5 &
                                 prov.locs.single$OBSERVATION_DAY < 15 |
                                 prov.locs.single$OBSERVATION_MONTH > 1 &
                                 prov.locs.single$OBSERVATION_MONTH < 5)

# boreal locations
# NEED TO WORK ON THESE; IDEA IS TO USE JULIAN DAY
# https://landweb.modaps.eosdis.nasa.gov/browse/calendar.html
boreal.locs.prj@data$yr.julian <- c ("as.character(boreal.locs.prj@data$Yr)",
                                     "as.character(boreal.locs.prj@data$Julian)") 

boreal.locs.prj@data <- mutate (boreal.locs.prj@data, yr.julian = paste(boreal.locs.prj@data$Yr, 
                                                                        boreal.locs.prj@data$Julian,
                                                                        sep = "")) 
boreal.locs.prj@data$yr.julian <- as.numeric (boreal.locs.prj@data$yr.julian)  




# boreal locations
# NEED TO WORK HERE
boreal.locs.calving <- boreal.locs.calving [boreal.locs.calving$Collar %in% 
                                            names (table (boreal.locs.calving$Collar)) [table (boreal.locs.calving$Collar) >= 50] , ]

plot (boreal.locs)



# Provincial Data
# clip data by study areas/ecotypes
# BOREAL
prov.locs.summer.boreal <- prov.locs.summer [caribou.range.boreal.diss, ] # clip locations to boreal
prov.locs.summer.boreal@data$pttype <- 1
prov.locs.summer.boreal@data$ptID <- 1:38121
prov.locs.summer.boreal@data$ecotype <- "Boreal"
prov.locs.summer.boreal@data$season <- "Summer"

prov.locs.early.winter.boreal <- prov.locs.early.winter [caribou.range.boreal.diss, ] 
prov.locs.early.winter.boreal@data$pttype <- 1
prov.locs.early.winter.boreal@data$ptID <- 38122:53318
prov.locs.early.winter.boreal@data$ecotype <- "Boreal"
prov.locs.early.winter.boreal@data$season <- "Early Winter"

prov.locs.late.winter.boreal <- prov.locs.late.winter [caribou.range.boreal.diss, ] 
prov.locs.late.winter.boreal@data$pttype <- 1
prov.locs.late.winter.boreal@data$ptID <- 53319:82233
prov.locs.late.winter.boreal@data$ecotype <- "Boreal"
prov.locs.late.winter.boreal@data$season <- "Late Winter"

# MOUNTAIN
prov.locs.summer.mount <- prov.locs.summer [caribou.range.mtn.diss, ] # clip locations to mountain
prov.locs.summer.mount@data$pttype <- 1
prov.locs.summer.mount@data$ptID <- 82234:135309
prov.locs.summer.mount@data$ecotype <- "Mountain"
prov.locs.summer.mount@data$season <- "Summer"

prov.locs.early.winter.mount <- prov.locs.early.winter [caribou.range.mtn.diss, ] # clip locations to mountain
prov.locs.early.winter.mount@data$pttype <- 1
prov.locs.early.winter.mount@data$ptID <- 135310:156912
prov.locs.early.winter.mount@data$ecotype <- "Mountain"
prov.locs.early.winter.mount@data$season <- "Early Winter"

prov.locs.late.winter.mount <- prov.locs.late.winter [caribou.range.mtn.diss, ] # clip locations to mountain
prov.locs.late.winter.mount@data$pttype <- 1
prov.locs.late.winter.mount@data$ptID <- 156913:199393
prov.locs.late.winter.mount@data$ecotype <- "Mountain"
prov.locs.late.winter.mount@data$season <- "Late Winter"

# NORTHERN
prov.locs.summer.north <- prov.locs.summer [caribou.range.north.diss, ] # clip locations to northern
prov.locs.summer.north@data$pttype <- 1
prov.locs.summer.north@data$ptID <- 199394:321122
prov.locs.summer.north@data$ecotype <- "Northern"
prov.locs.summer.north@data$season <- "Summer"

prov.locs.early.winter.north <- prov.locs.early.winter [caribou.range.north.diss, ] 
prov.locs.early.winter.north@data$pttype <- 1
prov.locs.early.winter.north@data$ptID <- 321123:380720
prov.locs.early.winter.north@data$ecotype <- "Northern"
prov.locs.early.winter.north@data$season <- "Early Winter"

prov.locs.late.winter.north <- prov.locs.late.winter [caribou.range.north.diss, ] 
prov.locs.late.winter.north@data$pttype <- 1
prov.locs.late.winter.north@data$ptID <- 380721:497401
prov.locs.late.winter.north@data$ecotype <- "Northern"
prov.locs.late.winter.north@data$season <- "Late Winter"

# remove animals with <50 locations  
# Seaman, D. E., Millspaugh, J. J., Kernohan, B. J., Brundige, G. C., Raedeke, K. J., & Gitzen, R. A. (1999). Effects of sample size on kernel home range estimates. The journal of wildlife management, 739-747.
# Kernohan, B. J., R. A. Gitzen, and J. J. Millspaugh. 2001. Analysis of animal space use and movements. Pages 125–166 in J. J. Millspaugh and J. M. Marzluff, editors. Radio tracking and animal populations. Academic Press, San Diego, CA, USA
prov.locs.summer.boreal <- prov.locs.summer.boreal [prov.locs.summer.boreal$ANIMAL_ID %in% 
                                                     names (table (prov.locs.summer.boreal$ANIMAL_ID)) [table (prov.locs.summer.boreal$ANIMAL_ID) >= 50] , ]
prov.locs.summer.mount <- prov.locs.summer.mount [prov.locs.summer.mount$ANIMAL_ID %in% 
                                                      names (table (prov.locs.summer.mount$ANIMAL_ID)) [table (prov.locs.summer.mount$ANIMAL_ID) >= 50] , ]
prov.locs.summer.north <- prov.locs.summer.north [prov.locs.summer.north$ANIMAL_ID %in% 
                                                    names (table (prov.locs.summer.north$ANIMAL_ID)) [table (prov.locs.summer.north$ANIMAL_ID) >= 50] , ]
prov.locs.early.winter.boreal <- prov.locs.early.winter.boreal [prov.locs.early.winter.boreal$ANIMAL_ID %in% 
                                                    names (table (prov.locs.early.winter.boreal$ANIMAL_ID)) [table (prov.locs.early.winter.boreal$ANIMAL_ID) >= 50] , ]
prov.locs.early.winter.mount <- prov.locs.early.winter.mount [prov.locs.early.winter.mount$ANIMAL_ID %in% 
                                                           names (table (prov.locs.early.winter.mount$ANIMAL_ID)) [table (prov.locs.early.winter.mount$ANIMAL_ID) >= 50] , ]
prov.locs.early.winter.north <- prov.locs.early.winter.north [prov.locs.early.winter.north$ANIMAL_ID %in% 
                                                          names (table (prov.locs.early.winter.north$ANIMAL_ID)) [table (prov.locs.early.winter.north$ANIMAL_ID) >= 50] , ]
prov.locs.late.winter.boreal <- prov.locs.late.winter.boreal [prov.locs.late.winter.boreal$ANIMAL_ID %in% 
                                                  names (table (prov.locs.late.winter.boreal$ANIMAL_ID)) [table (prov.locs.late.winter.boreal$ANIMAL_ID) >= 50] , ]
prov.locs.late.winter.mount <- prov.locs.late.winter.mount [prov.locs.late.winter.mount$ANIMAL_ID %in% 
                                                                names (table (prov.locs.late.winter.mount$ANIMAL_ID)) [table (prov.locs.late.winter.mount$ANIMAL_ID) >= 50] , ]
prov.locs.late.winter.north <- prov.locs.late.winter.north [prov.locs.late.winter.north$ANIMAL_ID %in% 
                                                                names (table (prov.locs.late.winter.north$ANIMAL_ID)) [table (prov.locs.late.winter.north$ANIMAL_ID) >= 50] , ]
# bind the points together
prov.locs.all.used <- rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (prov.locs.summer.boreal, 
                      prov.locs.early.winter.boreal), prov.locs.late.winter.boreal), prov.locs.summer.mount),
                      prov.locs.early.winter.mount), prov.locs.late.winter.mount),
                      prov.locs.summer.north), prov.locs.early.winter.north),
                      prov.locs.late.winter.north) # also, see: sf::st_union?
prov.locs.all.used@data$ecotype <- as.factor (prov.locs.all.used@data$ecotype)
prov.locs.all.used@data$season <- as.factor (prov.locs.all.used@data$season)

# Assign new indivudal ID's based on ANIMAL_ID and range
# looking at HR's in QGIS, clearly there are duplicate animals; 
# need to re-assign identifiers based on ranges, year and season
# prov.locs.all.used.herd <- sf::st_join (prov.locs.all.used, # alternative option using sf?
#                                         caribou.range, 
#                                         join = st_intersects)
prov.locs.all.used.herd <- sp::over (prov.locs.all.used, caribou.range[3]) # column 3 is herd name
prov.locs.all.used.herd$joinID <- 1:469998 # create a joinID to join data on; I did some visual inspection in GIS to see where points fell relative to caribou range and confirmed that the point order is equivalent to ID
prov.locs.all.used@data$joinID <- 1:469998 
prov.locs.all.used@data <- dplyr::full_join (prov.locs.all.used@data, prov.locs.all.used.herd, 
                                         by = c ("joinID" = "joinID")) 
prov.locs.all.used@data <- mutate (prov.locs.all.used@data, 
                                   uniqueID = paste (prov.locs.all.used@data$ANIMAL_ID,
                                                     prov.locs.all.used@data$HERD_NAME,
                                                     prov.locs.all.used@data$ecotype,
                                                     prov.locs.all.used@data$season,
                                                     prov.locs.all.used@data$OBSERVATION_YEAR,
                                                     sep = "_")) 
prov.locs.all.used <- prov.locs.all.used [prov.locs.all.used$uniqueID %in% 
                                            names (table (prov.locs.all.used$uniqueID)) [table (prov.locs.all.used$uniqueID) >= 50] , ]
writeOGR (prov.locs.all.used, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\caribou_telemetry_final\\locs_all_used.shp", 
          layer = "locs_all_used", driver = "ESRI Shapefile")
# remove animals with <50 locations again 

# rm (prov.locs.calving.boreal, prov.locs.summ.fall.boreal, prov.locs.early.winter.boreal,
#    prov.locs.late.winter.boreal, prov.locs.calving.mount, prov.locs.summ.fall.mount,
#    prov.locs.early.winter.mount, prov.locs.late.winter.mount, prov.locs.calving.north,
#    prov.locs.summ.fall.north, prov.locs.late.winter.north)

#===============================================================
# "Kernel home range Utiliation Distribution Using adehabitatHR
#==============================================================
# https://cran.r-project.org/web/packages/adehabitatHR/vignettes/adehabitatHR.pdf
#  bivariate normal kernel
# variable h size and interpret visually
# a subjective visual choice for the smoothing parameter, based on successive trials (Calenge et al. 2011)
# Hemson, G., Johnson, P., South, A., Kenward, R., Ripley, R., & MACDONALD, D. (2005). Are kernels the mustard? Data from global positioning system (GPS) collars suggests problems for kernel home‐range analyses with least‐squares cross‐validation. Journal of Animal Ecology, 74(3), 455-463.
# too big to procees all data together, so break into smaller chunks again 
prov.locs.summer.boreal <- subset (prov.locs.all.used, 
                                   prov.locs.all.used@data$ecotype == "Boreal" & 
                                   prov.locs.all.used@data$season == "Summer")
prov.locs.summer.mount <- subset (prov.locs.all.used, 
                                  prov.locs.all.used@data$ecotype == "Mountain" & 
                                  prov.locs.all.used@data$season == "Summer")
prov.locs.summer.north <- subset (prov.locs.all.used, 
                                  prov.locs.all.used@data$ecotype == "Northern" & 
                                  prov.locs.all.used@data$season == "Summer")
prov.locs.early.winter.boreal <- subset (prov.locs.all.used, 
                                  prov.locs.all.used@data$ecotype == "Boreal" & 
                                  prov.locs.all.used@data$season == "Early Winter")
prov.locs.early.winter.mount <- subset (prov.locs.all.used, 
                                        prov.locs.all.used@data$ecotype == "Mountain" & 
                                        prov.locs.all.used@data$season == "Early Winter")
prov.locs.early.winter.north <- subset (prov.locs.all.used, 
                                        prov.locs.all.used@data$ecotype == "Northern" & 
                                        prov.locs.all.used@data$season == "Early Winter")
prov.locs.late.winter.boreal <- subset (prov.locs.all.used, 
                                        prov.locs.all.used@data$ecotype == "Boreal" & 
                                        prov.locs.all.used@data$season == "Late Winter")
prov.locs.late.winter.mount <- subset (prov.locs.all.used, 
                                       prov.locs.all.used@data$ecotype == "Mountain" & 
                                       prov.locs.all.used@data$season == "Late Winter")
prov.locs.late.winter.north <- subset (prov.locs.all.used, 
                                       prov.locs.all.used@data$ecotype == "Northern" & 
                                       prov.locs.all.used@data$season == "Late Winter")

# create factors without 0 records
prov.locs.summer.boreal@data$uniqueID <- factor (prov.locs.summer.boreal@data$uniqueID) # drop animals with no locations
prov.locs.summer.mount@data$uniqueID <- factor (prov.locs.summer.mount@data$uniqueID) # drop animals with no locations
prov.locs.summer.north@data$uniqueID <- factor (prov.locs.summer.north@data$uniqueID) # drop animals with no locations
prov.locs.early.winter.boreal@data$uniqueID <- factor (prov.locs.early.winter.boreal@data$uniqueID) # drop animals with no locations
prov.locs.early.winter.mount@data$uniqueID <- factor (prov.locs.early.winter.mount@data$uniqueID) # drop animals with no locations
prov.locs.early.winter.north@data$uniqueID <- factor (prov.locs.early.winter.north@data$uniqueID) # drop animals with no locations
prov.locs.late.winter.boreal@data$uniqueID <- factor (prov.locs.late.winter.boreal@data$uniqueID) # drop animals with no locations
prov.locs.late.winter.mount@data$uniqueID <- factor (prov.locs.late.winter.mount@data$uniqueID) # drop animals with no locations
prov.locs.late.winter.north@data$uniqueID <- factor (prov.locs.late.winter.north@data$uniqueID) # drop animals with no locations
# freq.animals.test <- data.frame(table (prov.locs.summer.boreal@data$uniqueID))

# ======================================
# Calculate UDs by season and ecotype
#======================================
###########
# BOREAL #
#########
# SUMMER
khr.summer.boreal.h1000 <- kernelUD (prov.locs.summer.boreal [, 45], # new unique animal ID
                                     h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
                                     grid = 1000, # grid 1km x 1km
                                     extent = 2)  # extent is 2x the 'normal' size
homerange.summer.boreal.h1000 <- getverticeshr (khr.summer.boreal.h1000, percent = 95)
writeOGR (homerange.summer.boreal.h1000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_summer_h1000.shp", 
          layer = "hr_boreal_summer_h1000", driver = "ESRI Shapefile")
khr.summer.boreal.h5000 <- kernelUD (prov.locs.summer.boreal [, 45], # new unique animal ID
                                     h = 5000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 5000, 50000)
                                     grid = 1000, # grid 1km x 1km
                                     extent = 10)  
homerange.summer.boreal.h5000 <- getverticeshr (khr.summer.boreal.h5000, percent = 95)
writeOGR (homerange.summer.boreal.h5000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_summer_h5000.shp", 
          layer = "hr_boreal_summer_h5000", driver = "ESRI Shapefile")
khr.summer.boreal.h500 <- kernelUD (prov.locs.summer.boreal [, 45], # new unique animal ID
                                     h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                     grid = 1000, # grid 1km x 1km
                                     extent = 2)  
homerange.summer.boreal.h500 <- getverticeshr (khr.summer.boreal.h500, percent = 95)
writeOGR (homerange.summer.boreal.h500, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_summer_h500.shp", 
          layer = "hr_boreal_summer_h500", driver = "ESRI Shapefile")
khr.summer.boreal.h750 <- kernelUD (prov.locs.summer.boreal [, 45], # new unique animal ID
                                    h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                    grid = 1000, # grid 1km x 1km
                                    extent = 2)  
homerange.summer.boreal.h750 <- getverticeshr (khr.summer.boreal.h750, percent = 95)
writeOGR (homerange.summer.boreal.h750, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_summer_h750.shp", 
          layer = "hr_boreal_summer_h750", driver = "ESRI Shapefile")

rm (khr.summer.boreal.h1000, khr.summer.boreal.h5000, khr.summer.boreal.h500, khr.summer.boreal.h750)

# EARLY WINTER
khr.early.winter.boreal.h1000 <- kernelUD (prov.locs.early.winter.boreal [, 45], # new unique animal ID
                                            h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
                                            grid = 1000, # grid 1km x 1km
                                            extent = 2)  # extent is 2x the 'normal' size
homerange.early.winter.boreal.h1000 <- getverticeshr (khr.early.winter.boreal.h1000, percent = 95)
writeOGR (homerange.early.winter.boreal.h1000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_early.winter_h1000.shp", 
          layer = "hr_boreal_early.winter_h1000", driver = "ESRI Shapefile")
khr.early.winter.boreal.h500 <- kernelUD (prov.locs.early.winter.boreal [, 45], # new unique animal ID
                                    h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                    grid = 1000, # grid 1km x 1km
                                    extent = 2)  
homerange.early.winter.boreal.h500 <- getverticeshr (khr.early.winter.boreal.h500, percent = 95)
writeOGR (homerange.early.winter.boreal.h500, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_early.winter_h500.shp", 
          layer = "hr_boreal_early.winter_h500", driver = "ESRI Shapefile")
khr.early.winter.boreal.h750 <- kernelUD (prov.locs.early.winter.boreal [, 45], # new unique animal ID
                                    h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                    grid = 1000, # grid 1km x 1km
                                    extent = 2)  
homerange.early.winter.boreal.h750 <- getverticeshr (khr.early.winter.boreal.h750, percent = 95)
writeOGR (homerange.early.winter.boreal.h750, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_early.winter_h750.shp", 
          layer = "hr_boreal_early.winter_h750", driver = "ESRI Shapefile")

rm (khr.early.winter.boreal.h1000, khr.early.winter.boreal.h500, khr.early.winter.boreal.h750)

# LATE WINTER
khr.late.winter.boreal.h1000 <- kernelUD (prov.locs.late.winter.boreal [, 45], # new unique animal ID
                                           h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
                                           grid = 1000, # grid 1km x 1km
                                           extent = 2)  # extent is 2x the 'normal' size
homerange.late.winter.boreal.h1000 <- getverticeshr (khr.late.winter.boreal.h1000, percent = 95)
writeOGR (homerange.late.winter.boreal.h1000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_late.winter_h1000.shp", 
          layer = "hr_boreal_late.winter_h1000", driver = "ESRI Shapefile")
khr.late.winter.boreal.h500 <- kernelUD (prov.locs.late.winter.boreal [, 45], # new unique animal ID
                                          h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                          grid = 1000, # grid 1km x 1km
                                          extent = 2)  
homerange.late.winter.boreal.h500 <- getverticeshr (khr.late.winter.boreal.h500, percent = 95)
writeOGR (homerange.late.winter.boreal.h500, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_late.winter_h500.shp", 
          layer = "hr_boreal_late.winter_h500", driver = "ESRI Shapefile")
khr.late.winter.boreal.h750 <- kernelUD (prov.locs.late.winter.boreal [, 45], # new unique animal ID
                                          h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                          grid = 1000, # grid 1km x 1km
                                          extent = 2)  
homerange.late.winter.boreal.h750 <- getverticeshr (khr.late.winter.boreal.h750, percent = 95)
writeOGR (homerange.late.winter.boreal.h750, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_late.winter_h750.shp", 
          layer = "hr_boreal_late.winter_h750", driver = "ESRI Shapefile")

rm (khr.late.winter.boreal.h1000, khr.late.winter.boreal.h500, khr.late.winter.boreal.h750)
# 5000 very large areas; boundaries extend ~10km beyond points; too big
# 1000 reasonable, but on the larger side
# 750 also slightly large
# 500 had more islands and holes in data, but 'tighter' to points 
# went with h = 500 as 'best' representation

#############
# MOUNTAIN #
###########
# SUMMER
khr.summer.mount.h1000 <- kernelUD (prov.locs.summer.mount [, 45], # new unique animal ID
                                     h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
                                     grid = 1000, # grid 1km x 1km
                                     extent = 5)  # extent is 2x the 'normal' size
homerange.summer.mount.h1000 <- getverticeshr (khr.summer.mount.h1000, percent = 95)
writeOGR (homerange.summer.mount.h1000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_summer_h1000.shp", 
          layer = "hr_mount_summer_h1000", driver = "ESRI Shapefile")
khr.summer.mount.h500 <- kernelUD (prov.locs.summer.mount [, 45], # new unique animal ID
                                    h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                    grid = 1000, # grid 1km x 1km
                                    extent = 5)  
homerange.summer.mount.h500 <- getverticeshr (khr.summer.mount.h500, percent = 95)
writeOGR (homerange.summer.mount.h500, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_summer_h500.shp", 
          layer = "hr_mount_summer_h500", driver = "ESRI Shapefile")
khr.summer.mount.h750 <- kernelUD (prov.locs.summer.mount [, 45], # new unique animal ID
                                    h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                    grid = 1000, # grid 1km x 1km
                                    extent = 5)  
homerange.summer.mount.h750 <- getverticeshr (khr.summer.mount.h750, percent = 95)
writeOGR (homerange.summer.mount.h750, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_summer_h750.shp", 
          layer = "hr_mount_summer_h750", driver = "ESRI Shapefile")

rm (khr.summer.mount.h1000, khr.summer.mount.h500, khr.summer.mount.h750)

# EARLY WINTER
khr.early.winter.mount.h1000 <- kernelUD (prov.locs.early.winter.mount [, 45], # new unique animal ID
                                    h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
                                    grid = 1000, # grid 1km x 1km
                                    extent = 5)  # extent is 2x the 'normal' size
homerange.early.winter.mount.h1000 <- getverticeshr (khr.early.winter.mount.h1000, percent = 95)
writeOGR (homerange.early.winter.mount.h1000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_early.winter_h1000.shp", 
          layer = "hr_mount_early.winter_h1000", driver = "ESRI Shapefile")
khr.early.winter.mount.h500 <- kernelUD (prov.locs.early.winter.mount [, 45], # new unique animal ID
                                   h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                   grid = 1000, # grid 1km x 1km
                                   extent = 5)  
homerange.early.winter.mount.h500 <- getverticeshr (khr.early.winter.mount.h500, percent = 95)
writeOGR (homerange.early.winter.mount.h500, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_early.winter_h500.shp", 
          layer = "hr_mount_early.winter_h500", driver = "ESRI Shapefile")
khr.early.winter.mount.h750 <- kernelUD (prov.locs.early.winter.mount [, 45], # new unique animal ID
                                   h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                   grid = 1000, # grid 1km x 1km
                                   extent = 5)  
homerange.early.winter.mount.h750 <- getverticeshr (khr.early.winter.mount.h750, percent = 95)
writeOGR (homerange.early.winter.mount.h750, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_early.winter_h750.shp", 
          layer = "hr_mount_early.winter_h750", driver = "ESRI Shapefile")

rm (khr.early.winter.mount.h1000, khr.early.winter.mount.h500, khr.early.winter.mount.h750)

# LATE WINTER
khr.late.winter.mount.h1000 <- kernelUD (prov.locs.late.winter.mount [, 45], # new unique animal ID
                                          h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
                                          grid = 1000, # grid 1km x 1km
                                          extent = 5)  # extent is 2x the 'normal' size
homerange.late.winter.mount.h1000 <- getverticeshr (khr.late.winter.mount.h1000, percent = 95)
writeOGR (homerange.late.winter.mount.h1000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_late.winter_h1000.shp", 
          layer = "hr_mount_late.winter_h1000", driver = "ESRI Shapefile")
khr.late.winter.mount.h500 <- kernelUD (prov.locs.late.winter.mount [, 45], # new unique animal ID
                                         h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                         grid = 1000, # grid 1km x 1km
                                         extent = 5)  
homerange.late.winter.mount.h500 <- getverticeshr (khr.late.winter.mount.h500, percent = 95)
writeOGR (homerange.late.winter.mount.h500, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_late.winter_h500.shp", 
          layer = "hr_mount_late.winter_h500", driver = "ESRI Shapefile")
khr.late.winter.mount.h750 <- kernelUD (prov.locs.late.winter.mount [, 45], # new unique animal ID
                                         h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                         grid = 1000, # grid 1km x 1km
                                         extent = 5)  
homerange.late.winter.mount.h750 <- getverticeshr (khr.late.winter.mount.h750, percent = 95)
writeOGR (homerange.late.winter.mount.h750, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_late.winter_h750.shp", 
          layer = "hr_mount_late.winter_h750", driver = "ESRI Shapefile")

rm (khr.late.winter.mount.h1000, khr.late.winter.mount.h500, khr.late.winter.mount.h750)

# 1000 reasonable, but on the larger side
# 750 also slightly large
# 500 had more islands and holes in data, but 'tighter' to points 
# went with h = 500 as 'best' representation

#############
# NORTHERN #
###########
# SUMMER
# split the data to make it easier to handle
# summer.north.ids <- list (unique (prov.locs.summer.north@data$uniqueID))
prov.locs.summer.north.top <-  prov.locs.summer.north [prov.locs.summer.north@data$uniqueID == "C02a_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C03_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C04a_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C05a_Graham_Northern_Summer_2001" |  
                                                         prov.locs.summer.north@data$uniqueID == "C07_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C09a_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C10a_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C01a_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C06a_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C11_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C12a_Graham_Northern_Summer_2001" |
                                                         prov.locs.summer.north@data$uniqueID == "C04b_Graham_Northern_Summer_2002" |             
                                                         prov.locs.summer.north@data$uniqueID == "C06b_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C10b_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C02b_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C09b_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C05b_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C12b_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C01b_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C14_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C15_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C16_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C17_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C13_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C18_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C20_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C22_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "C21_Graham_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "148.559_Telkwa_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "148.559_Telkwa_Northern_Summer_2003" |
                                                         prov.locs.summer.north@data$uniqueID == "148.669_Telkwa_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "148.669_Telkwa_Northern_Summer_2003" |
                                                         prov.locs.summer.north@data$uniqueID == "148.59_Telkwa_Northern_Summer_2002" |
                                                         prov.locs.summer.north@data$uniqueID == "148.59_Telkwa_Northern_Summer_2003" |
                                                         prov.locs.summer.north@data$uniqueID == "C1_Atlin_Northern_Summer_2000" |
                                                         prov.locs.summer.north@data$uniqueID == "C2_Atlin_Northern_Summer_2000" |
                                                         prov.locs.summer.north@data$uniqueID == "C3_Atlin_Northern_Summer_2000" |
                                                         prov.locs.summer.north@data$uniqueID == "C4_Atlin_Northern_Summer_2000" |
                                                         prov.locs.summer.north@data$uniqueID == "SL06_Swan Lake_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "SL02_Swan Lake_Northern_Summer_2005" |
                                                         prov.locs.summer.north@data$uniqueID == "SL06_Swan Lake_Northern_Summer_2005" |
                                                         prov.locs.summer.north@data$uniqueID == "SL06_Swan Lake_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "SL28_Swan Lake_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "SL15_Swan Lake_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "SL15_Swan Lake_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car055_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car056_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car056_Narraway_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car077_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car056_Narraway_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID ==  "car077_Quintette_Northern_Summer_2009" |
                                                         prov.locs.summer.north@data$uniqueID == "car032_Kennedy Siding_Northern_Summer_2004" |
                                                         prov.locs.summer.north@data$uniqueID == "car078_Narraway_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car043_Kennedy Siding_Northern_Summer_2005" |
                                                         prov.locs.summer.north@data$uniqueID == "car044_Kennedy Siding_Northern_Summer_2005" |
                                                         prov.locs.summer.north@data$uniqueID == "car025_Kennedy Siding_Northern_Summer_2004" |
                                                         prov.locs.summer.north@data$uniqueID == "car044_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car047_Kennedy Siding_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car047_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car048_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car049_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car048_Kennedy Siding_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car050_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car049_Kennedy Siding_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car050_Kennedy Siding_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car051_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car053_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car051_Kennedy Siding_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car053_Kennedy Siding_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car010_Moberly_Northern_Summer_2004" |
                                                         prov.locs.summer.north@data$uniqueID == "car061_Kennedy Siding_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car020_Moberly_Northern_Summer_2004" |
                                                         prov.locs.summer.north@data$uniqueID == "car052_Moberly_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car052_Moberly_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car052_Kennedy Siding_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car066_Moberly_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car067_Moberly_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car067_Moberly_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car066_Moberly_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car079_Moberly_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car079_Scott_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car102_Moberly_Northern_Summer_2009" |
                                                         prov.locs.summer.north@data$uniqueID == "car080_Moberly_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car012_Quintette_Northern_Summer_2004" |
                                                         prov.locs.summer.north@data$uniqueID == "car014_Quintette_Northern_Summer_2003" |
                                                         prov.locs.summer.north@data$uniqueID == "car040_Quintette_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car040_Quintette_Northern_Summer_2005" |
                                                         prov.locs.summer.north@data$uniqueID == "car042_Quintette_Northern_Summer_2005" |
                                                         prov.locs.summer.north@data$uniqueID == "car042_Quintette_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car045_Quintette_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car057_Narraway_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car057_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car046_Quintette_Northern_Summer_2006" |
                                                         prov.locs.summer.north@data$uniqueID == "car057_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car057_Narraway_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car058_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car059_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car058_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car059_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car068_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car069_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car068_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car069_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car070_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car070_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car071_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car071_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car074_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car074_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car075_Quintette_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "car075_Quintette_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "car109_Quintette_Northern_Summer_2009" |
                                                         prov.locs.summer.north@data$uniqueID == "car112_Quintette_Northern_Summer_2009" |
                                                         prov.locs.summer.north@data$uniqueID == "car105_Quintette_Northern_Summer_2009" |
                                                         prov.locs.summer.north@data$uniqueID == "C069W_Wolverine_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C029W_Wolverine_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C041W_Wolverine_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C043W_Wolverine_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C042W_Wolverine_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C059C_Chase_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C060C_Chase_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C058C_Chase_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C067C_Chase_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C056C_Chase_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C047A_Chase_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C066C_Chase_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C093A_Finlay_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C094A_Finlay_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "C094A_Pink Mountain_Northern_Summer_1999" |
                                                         prov.locs.summer.north@data$uniqueID == "148.990b_Tweedsmuir_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "148.960b_Tweedsmuir_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "148.890_Tweedsmuir_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "148.870_Tweedsmuir_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "148.870_Tweedsmuir_Northern_Summer_2008" |
                                                         prov.locs.summer.north@data$uniqueID == "149.581b_Tweedsmuir_Northern_Summer_2007"| 
                                                         prov.locs.summer.north@data$uniqueID == "149.551b_Tweedsmuir_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "148.840b_Tweedsmuir_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "149.530_Tweedsmuir_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "148.850_Tweedsmuir_Northern_Summer_2007" |
                                                         prov.locs.summer.north@data$uniqueID == "148.850_Tweedsmuir_Northern_Summer_2008", ]

prov.locs.summer.north.bottom <-  prov.locs.summer.north [prov.locs.summer.north@data$uniqueID == "149.431b_Tweedsmuir_Northern_Summer_2006" |
                                                            prov.locs.summer.north@data$uniqueID == "148.830b_Tweedsmuir_Northern_Summer_2007" |
                                                            prov.locs.summer.north@data$uniqueID == "149.450b_Tweedsmuir_Northern_Summer_2006" |
                                                            prov.locs.summer.north@data$uniqueID == "149.581a_Tweedsmuir_Northern_Summer_2002" | # was having trouble fitting the kernel HR with these animals; I think becuase covered a very large area, so removed from analysis
                                                            prov.locs.summer.north@data$uniqueID == "149.490a_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.450a_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.531_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.110b_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.190b_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.120b_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.090b_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.098_Tweedsmuir_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "149.200a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "149.160a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "149.190a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "149.110a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "149.150a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "149.120a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "149.090a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "149.080a_Tweedsmuir_Northern_Summer_2000" |
                                                            prov.locs.summer.north@data$uniqueID == "C307T_Finlay_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "C307T_Finlay_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "C306T_Frog_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "C306T_Frog_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "C303T_Spatsizi_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "C303T_Spatsizi_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "C303T_Spatsizi_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "C296T_Chase_Northern_Summer_2012" |
                                                            # prov.locs.summer.north@data$uniqueID == "C297T_Spatsizi_Northern_Summer_2013" | # locations all within 50m of each other; so, removed from analysis
                                                            prov.locs.summer.north@data$uniqueID == "C294T_Frog_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "C293T_Frog_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "C293T_Frog_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "149.421_Level Kawdy_Northern_Summer_2003" |
                                                            prov.locs.summer.north@data$uniqueID == "149.421_Little Rancheria_Northern_Summer_2003" |
                                                            prov.locs.summer.north@data$uniqueID == "149.498_Edziza_Northern_Summer_2003" |
                                                            prov.locs.summer.north@data$uniqueID == "149.441_Edziza_Northern_Summer_2003" |
                                                            prov.locs.summer.north@data$uniqueID == "car132_Narraway_Northern_Summer_2010" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1002_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1002_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1003_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1003_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1004_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1006_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1007_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1001_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1001_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1005_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1005_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1008_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1012_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1012_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1009_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1009_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1017_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1017_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1014_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1014_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1011_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1016_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1016_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1015_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1015_Tweedsmuir_Northern_Summer_2015" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1028_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1027_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1029_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "TWC1030_Tweedsmuir_Northern_Summer_2016" |
                                                            prov.locs.summer.north@data$uniqueID == "42_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "3_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "4_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "56_Itcha-Ilgachuz_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "56_Rainbows_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "54_Itcha-Ilgachuz_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "54_Rainbows_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "53_Itcha-Ilgachuz_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "52_Itcha-Ilgachuz_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "52_Rainbows_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "51_Itcha-Ilgachuz_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "40_Itcha-Ilgachuz_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "40_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "39_Itcha-Ilgachuz_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "39_Rainbows_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "39_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "39_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "38_Itcha-Ilgachuz_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "38_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "38_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "37_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "36_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "35_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "34_Itcha-Ilgachuz_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "34_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "33_Charlotte Alplands_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "33_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "49_Itcha-Ilgachuz_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "49_Itcha-Ilgachuz_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "49_Rainbows_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "49_Rainbows_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "49_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "48_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "49_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "48_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "46_Rainbows_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "46_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "46_Itcha-Ilgachuz_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "44_Itcha-Ilgachuz_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "46_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "44_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "43_Rainbows_Northern_Summer_2012" |
                                                            prov.locs.summer.north@data$uniqueID == "42_Itcha-Ilgachuz_Northern_Summer_2014" |
                                                            prov.locs.summer.north@data$uniqueID == "42_Itcha-Ilgachuz_Northern_Summer_2013" |
                                                            prov.locs.summer.north@data$uniqueID == "GC23_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC16_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC21_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC08_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC16_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC08_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC07_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC07_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC04_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC06_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC04_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC09_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC10_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC09_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC14_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC12_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC12_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC11_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC13_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC11_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC20_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC20_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC19_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC19_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC03_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "GC03_Graham_Northern_Summer_2009" |
                                                            prov.locs.summer.north@data$uniqueID == "GC02_Graham_Northern_Summer_2008" |
                                                            prov.locs.summer.north@data$uniqueID == "C025A_Pink Mountain_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "C017A_Pink Mountain_Northern_Summer_2002" |
                                                            prov.locs.summer.north@data$uniqueID == "C012A_Pink Mountain_Northern_Summer_2002", ]     

# create factors without 0 records
prov.locs.summer.north.top@data$uniqueID <- factor (prov.locs.summer.north.top@data$uniqueID) # drop animals with no locations
prov.locs.summer.north.bottom@data$uniqueID <- factor (prov.locs.summer.north.bottom@data$uniqueID) # drop animals with no locations

# khr.summer.north.h1000.top <- kernelUD (prov.locs.summer.north.top [, 45], # new unique animal ID
#                                        h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
#                                        grid = 1000, # grid 1km x 1km
#                                        extent = 5)  # extent is 2x the 'normal' size
#homerange.summer.north.h1000.top <- getverticeshr (khr.summer.north.h1000.top, percent = 95)
#writeOGR (homerange.summer.north.h1000.top, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h1000_top.shp", 
#          layer = "hr_north_summer_h1000_top", driver = "ESRI Shapefile")
#rm (khr.summer.north.h1000.top)
khr.summer.north.h500.top <- kernelUD (prov.locs.summer.north.top [, 45], # new unique animal ID
                                       h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                       grid = 1000, # grid 1km x 1km
                                       extent = 5)  
homerange.summer.north.h500.top <- getverticeshr (khr.summer.north.h500.top, percent = 95)
writeOGR (homerange.summer.north.h500.top, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h500_top.shp", 
          layer = "hr_north_summer_h500_top", driver = "ESRI Shapefile")
rm (khr.summer.north.h500.top)
#khr.summer.north.h750.top <- kernelUD (prov.locs.summer.north.top [, 45], # new unique animal ID
#                                   h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
#                                   grid = 1000, # grid 1km x 1km
#                                   extent = 5)  
#homerange.summer.north.h750.top <- getverticeshr (khr.summer.north.h750.top, percent = 95)
#writeOGR (homerange.summer.north.h750.top, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h750_top.shp", 
#          layer = "hr_north_summer_h750_top", driver = "ESRI Shapefile")
#rm (khr.summer.north.h750.top)

#khr.summer.north.h1000.bottom <- kernelUD (prov.locs.summer.north.bottom [, 45], # new unique animal ID
#                                           h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
#                                           grid = 1000, # grid 1km x 1km
#                                           extent = 5)  # extent is 2x the 'normal' size
#homerange.summer.north.h1000.bottom <- getverticeshr (khr.summer.north.h1000.bottom, percent = 95)
#writeOGR (homerange.summer.north.h1000.bottom, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h1000_top.shp", 
#          layer = "hr_north_summer_h1000_top", driver = "ESRI Shapefile")
#rm (khr.summer.north.h1000.bottom)
khr.summer.north.h500.bottom <- kernelUD (prov.locs.summer.north.bottom [, 45], # new unique animal ID
                                          h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                          grid = 1000, # grid 1km x 1km
                                          extent = 5)  
homerange.summer.north.h500.bottom <- getverticeshr (khr.summer.north.h500.bottom, percent = 95)
writeOGR (homerange.summer.north.h500.bottom, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h500_bottom.shp", 
          layer = "hr_north_summer_h500_bottom", driver = "ESRI Shapefile")
rm (khr.summer.north.h500.bottom)
#khr.summer.north.h750 <- kernelUD (prov.locs.summer.north.bottom [, 45], # new unique animal ID
#                                   h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
#                                   grid = 1000, # grid 1km x 1km
#                                   extent = 5)  
#homerange.summer.north.h750.bottom <- getverticeshr (khr.summer.north.h750.bottom, percent = 95)
#writeOGR (homerange.summer.north.h750.bottom, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h750_top.shp", 
#          layer = "hr_north_summer_h750_top", driver = "ESRI Shapefile")
#rm (khr.summer.north.h750.bottom)

# EARLY WINTER
khr.early.winter.north.h1000 <- kernelUD (prov.locs.early.winter.north [, 45], # new unique animal ID
                                          h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
                                          grid = 1000, # grid 1km x 1km
                                          extent = 5)  # extent is 2x the 'normal' size
homerange.early.winter.north.h1000 <- getverticeshr (khr.early.winter.north.h1000, percent = 95)
writeOGR (homerange.early.winter.north.h1000, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_early.winter_h1000.shp", 
          layer = "hr_north_early.winter_h1000", driver = "ESRI Shapefile")
rm (khr.early.winter.north.h1000)
khr.early.winter.north.h500 <- kernelUD (prov.locs.early.winter.north [, 45], # new unique animal ID
                                         h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                         grid = 1000, # grid 1km x 1km
                                         extent = 5)  
homerange.early.winter.north.h500 <- getverticeshr (khr.early.winter.north.h500, percent = 95)
writeOGR (homerange.early.winter.north.h500, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_early.winter_h500.shp", 
          layer = "hr_north_early.winter_h500", driver = "ESRI Shapefile")
rm (khr.early.winter.north.h500)
khr.early.winter.north.h750 <- kernelUD (prov.locs.early.winter.north [, 45], # new unique animal ID
                                         h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                         grid = 1000, # grid 1km x 1km
                                         extent = 5)  
homerange.early.winter.north.h750 <- getverticeshr (khr.early.winter.north.h750, percent = 95)
writeOGR (homerange.early.winter.north.h750, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_early.winter_h750.shp", 
          layer = "hr_north_early.winter_h750", driver = "ESRI Shapefile")
rm (khr.early.winter.north.h750)

# LATE WINTER
# split the data to make it easier to handle
late.winter.north.ids <- list (unique (prov.locs.late.winter.north@data$uniqueID))
prov.locs.late.winter.north.top <-  prov.locs.late.winter.north [prov.locs.late.winter.north@data$uniqueID == "C02a_Graham_Northern_Late Winter_2001" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C03_Graham_Northern_Late Winter_2001" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C03_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C05a_Graham_Northern_Late Winter_2001" |  
                                                         prov.locs.late.winter.north@data$uniqueID == "C04a_Graham_Northern_Late Winter_2001" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C07_Graham_Northern_Late Winter_2001" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C05a_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C09a_Graham_Northern_Late Winter_2001" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C07_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C01a_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C01a_Graham_Northern_Late Winter_2001" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C11_Graham_Northern_Late Winter_2001" |             
                                                         prov.locs.late.winter.north@data$uniqueID == "C12a_Graham_Northern_Late Winter_2001" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C11_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C12a_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C04b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C06b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C10b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C06b_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C08b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C02b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C09b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C02b_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C12b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C09b_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C05b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C12b_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C01b_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C01b_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C14_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C14_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C15_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C15_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C16_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C16_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C17_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C18_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C13_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C17_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C18_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C20_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C20_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C19_Graham_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C22_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C21_Graham_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "148.559_Telkwa_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "148.559_Telkwa_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "148.669_Telkwa_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "148.669_Telkwa_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "148.59_Telkwa_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "148.59_Telkwa_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C1_Atlin_Northern_Late Winter_2000" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C2_Atlin_Northern_Late Winter_2000" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C3_Atlin_Northern_Late Winter_2000" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C4_Atlin_Northern_Late Winter_2000" |
                                                         prov.locs.late.winter.north@data$uniqueID == "C5_Atlin_Northern_Late Winter_2000" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL06_Swan Lake_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL06_Swan Lake_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL06_Swan Lake_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL28_Swan Lake_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL15_Swan Lake_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL28_Swan Lake_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL15_Little Rancheria_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "SL15_Swan Lake_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car055_Quintette_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car054_Narraway_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car056_Narraway_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car056_Quintette_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car056_Narraway_Northern_Late Winter_2009" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car077_Quintette_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car078_Narraway_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car077_Quintette_Northern_Late Winter_2009" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car078_Quintette_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car077_Narraway_Northern_Late Winter_2009" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car032_Burnt Pine_Northern_Late Winter_2004" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car032_Burnt Pine_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car025_Kennedy Siding_Northern_Late Winter_2004" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car024_Kennedy Siding_Northern_Late Winter_2004" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car011_Kennedy Siding_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car024_Kennedy Siding_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car043_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car025_Kennedy Siding_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car044_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car047_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car044_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car047_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car048_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car048_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car048_Kennedy Siding_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car049_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car049_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car050_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car050_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car050_Kennedy Siding_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car051_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car051_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car053_Kennedy Siding_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car053_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car053_Kennedy Siding_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car010_Moberly_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car061_Kennedy Siding_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car061_Kennedy Siding_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car010_Moberly_Northern_Late Winter_2004" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car020_Moberly_Northern_Late Winter_2004" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car009_Moberly_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car020_Moberly_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car010_Moberly_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car052_Moberly_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car052_Moberly_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car066_Moberly_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car066_Moberly_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car067_Moberly_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car067_Moberly_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car080_Moberly_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car079_Moberly_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car079_Scott_Northern_Late Winter_2009" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car080_Moberly_Northern_Late Winter_2009" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car102_Moberly_Northern_Late Winter_2009" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car015_Quintette_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car012_Quintette_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car012_Quintette_Northern_Late Winter_2004" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car031_Quintette_Northern_Late Winter_2004" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car014_Quintette_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car012_Quintette_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car013_Quintette_Northern_Late Winter_2003" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car040_Quintette_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car040_Quintette_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car045_Quintette_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car042_Quintette_Northern_Late Winter_2005" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car042_Quintette_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car046_Quintette_Northern_Late Winter_2006" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car045_Quintette_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car057_Quintette_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car057_Quintette_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car058_Quintette_Northern_Late Winter_2007" | 
                                                         prov.locs.late.winter.north@data$uniqueID == "car058_Quintette_Northern_Late Winter_2008" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car059_Quintette_Northern_Late Winter_2007" |
                                                         prov.locs.late.winter.north@data$uniqueID == "car059_Quintette_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car068_Quintette_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car068_Quintette_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car068_Quintette_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car069_Quintette_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car069_Quintette_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car070_Quintette_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car070_Quintette_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car070_Quintette_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car071_Quintette_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car071_Quintette_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car072_Quintette_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car074_Quintette_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car074_Quintette_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car074_Quintette_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car075_Quintette_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car075_Quintette_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car105_Quintette_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car075_Quintette_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car109_Quintette_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "car112_Quintette_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C043W_Wolverine_Northern_Late Winter_2000" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C042W_Wolverine_Northern_Late Winter_2000" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C068W_Wolverine_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C069W_Wolverine_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C056C_Chase_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C059C_Chase_Northern_Late Winter_2000" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C059C_Chase_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C060C_Chase_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C057A_Finlay_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C067C_Chase_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C112A_Finlay_Northern_Late Winter_2000" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C093A_Finlay_Northern_Late Winter_2000" |
                                                           prov.locs.late.winter.north@data$uniqueID == "C066C_Chase_Northern_Late Winter_1999" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.990b_Tweedsmuir_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.990b_Tweedsmuir_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.960b_Tweedsmuir_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.960b_Tweedsmuir_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.940b_Tweedsmuir_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.890_Tweedsmuir_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.890_Tweedsmuir_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.870_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.870_Tweedsmuir_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.581b_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.840b_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.490b_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.551b_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.850_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.530_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.810b_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.850_Tweedsmuir_Northern_Late Winter_2008" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.850_Tweedsmuir_Northern_Late Winter_2009" |
                                                           prov.locs.late.winter.north@data$uniqueID == "148.830b_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.450b_Tweedsmuir_Northern_Late Winter_2006" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.551a_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.450b_Tweedsmuir_Northern_Late Winter_2007" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.581a_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.450a_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.531_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.110b_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.190b_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.120b_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.190b_Tweedsmuir_Northern_Late Winter_2003" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.090b_Tweedsmuir_Northern_Late Winter_2002" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.090b_Tweedsmuir_Northern_Late Winter_2003" |
                                                           prov.locs.late.winter.north@data$uniqueID == "149.080b_Tweedsmuir_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "149.098_Tweedsmuir_Northern_Late Winter_2002" |
                                                         prov.locs.late.winter.north@data$uniqueID == "149.098_Tweedsmuir_Northern_Late Winter_2003", ]

prov.locs.late.winter.north.bottom <-  prov.locs.late.winter.north [prov.locs.late.winter.north@data$uniqueID == "149.200a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.190a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.160a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.110a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.120a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.150a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.080a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.090a_Tweedsmuir_Northern_Late Winter_2000" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C305T_Frog_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C303T_Spatsizi_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C303T_Spatsizi_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C296T_Chase_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C298T_Spatsizi_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C297T_Spatsizi_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C294T_Frog_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C293T_Frog_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.421_Level Kawdy_Northern_Late Winter_2003" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.411_Level Kawdy_Northern_Late Winter_2003" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.498_Edziza_Northern_Late Winter_2003" |
                                                            prov.locs.late.winter.north@data$uniqueID == "149.441_Edziza_Northern_Late Winter_2003" |
                                                            prov.locs.late.winter.north@data$uniqueID == "car133_Narraway_Northern_Late Winter_2011" |
                                                            prov.locs.late.winter.north@data$uniqueID == "car135_Narraway_Northern_Late Winter_2011" |
                                                            prov.locs.late.winter.north@data$uniqueID == "car134_Narraway_Northern_Late Winter_2011" |
                                                            prov.locs.late.winter.north@data$uniqueID == "car133_Narraway_Northern_Late Winter_2010" |
                                                            prov.locs.late.winter.north@data$uniqueID == "car132_Narraway_Northern_Late Winter_2011" |
                                                            prov.locs.late.winter.north@data$uniqueID == "car132_Narraway_Northern_Late Winter_2010" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1002_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1002_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1003_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1002_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1003_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1003_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1004_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1006_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1007_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1006_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1007_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1001_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1001_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1001_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1005_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1005_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1005_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1008_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1008_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1012_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1012_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1012_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1009_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1009_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1009_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1017_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1017_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1017_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1011_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1014_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1014_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1014_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1016_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1016_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1016_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1024_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1015_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1015_Tweedsmuir_Northern_Late Winter_2015" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1015_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1026_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1027_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1027_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1028_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1029_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1028_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1029_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1033_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1035_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1030_Tweedsmuir_Northern_Late Winter_2016" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1030_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1036_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1034_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1032_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1037_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "TWC1038_Tweedsmuir_Northern_Late Winter_2017" |
                                                            prov.locs.late.winter.north@data$uniqueID == "42_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "42_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "4_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "3_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "4_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "56_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "55_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "54_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "53_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "52_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "52_Charlotte Alplands_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "51_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "41_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "40_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "40_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "39_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "38_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "39_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "38_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "37_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "36_Charlotte Alplands_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "35_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "36_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "34_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "33_Charlotte Alplands_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "34_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "33_Charlotte Alplands_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "49_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "49_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "33_Rainbows_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "49_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "48_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "48_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "46_Itcha-Ilgachuz_Northern_Late Winter_2013" |
                                                            prov.locs.late.winter.north@data$uniqueID == "46_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "45_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "44_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "43_Charlotte Alplands_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "42_Itcha-Ilgachuz_Northern_Late Winter_2014" |
                                                            prov.locs.late.winter.north@data$uniqueID == "44_Itcha-Ilgachuz_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "43_Rainbows_Northern_Late Winter_2012" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC23_Graham_Northern_Late Winter_2010" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC23_Graham_Northern_Late Winter_2009" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC21_Graham_Northern_Late Winter_2009" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC16_Graham_Northern_Late Winter_2009" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC16_Graham_Northern_Late Winter_2010" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC16_Graham_Northern_Late Winter_2008" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC08_Graham_Northern_Late Winter_2010" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC08_Graham_Northern_Late Winter_2008" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC07_Graham_Northern_Late Winter_2010" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC08_Graham_Northern_Late Winter_2009" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC07_Graham_Northern_Late Winter_2009" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC07_Graham_Northern_Late Winter_2008" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC04_Graham_Northern_Late Winter_2009" |
                                                            prov.locs.late.winter.north@data$uniqueID == "GC06_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC04_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC10_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC09_Graham_Northern_Late Winter_2009" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC09_Graham_Northern_Late Winter_2010" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC09_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC14_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC12_Graham_Northern_Late Winter_2009" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC12_Graham_Northern_Late Winter_2010" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC11_Graham_Northern_Late Winter_2009" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC11_Graham_Northern_Late Winter_2010" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC12_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC13_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC11_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC20_Graham_Northern_Late Winter_2009" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC20_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC19_Graham_Northern_Late Winter_2009" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC19_Graham_Northern_Late Winter_2010" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC03_Graham_Northern_Late Winter_2009" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC03_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC19_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC02_Graham_Northern_Late Winter_2008" |
                                                              prov.locs.late.winter.north@data$uniqueID == "GC02_Graham_Northern_Late Winter_2009" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C043A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C037A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C036A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C042A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C021B_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C018B_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C035A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C033A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C029A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C028A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C031A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C012B_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C025A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C023A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C008B_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C020A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C022A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C017A_Pink Mountain_Northern_Late Winter_2003" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C017A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C015A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C016A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C012A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C011A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C014A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C006A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C010A_Pink Mountain_Northern_Late Winter_2002" |
                                                              prov.locs.late.winter.north@data$uniqueID == "C003A_Pink Mountain_Northern_Late Winter_2002" |
                                                            prov.locs.late.winter.north@data$uniqueID == "C002A_Pink Mountain_Northern_Late Winter_2002", ]     


# create factors without 0 records
prov.locs.late.winter.north.top@data$uniqueID <- factor (prov.locs.late.winter.north.top@data$uniqueID) # drop animals with no locations
prov.locs.late.winter.north.bottom@data$uniqueID <- factor (prov.locs.late.winter.north.bottom@data$uniqueID) # drop animals with no locations

# khr.late.winter.north.h1000.top <- kernelUD (prov.locs.late.winter.north.top [, 45], # new unique animal ID
#                                        h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
#                                        grid = 1000, # grid 1km x 1km
#                                        extent = 5)  # extent is 2x the 'normal' size
#homerange.late.winter.north.h1000.top <- getverticeshr (khr.late.winter.north.h1000.top, percent = 95)
#writeOGR (homerange.late.winter.north.h1000.top, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h1000_top.shp", 
#          layer = "hr_north_late.winter_h1000_top", driver = "ESRI Shapefile")
#rm (khr.late.winter.north.h1000.top)
khr.late.winter.north.h500.top <- kernelUD (prov.locs.late.winter.north.top [, 45], # new unique animal ID
                                       h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                       grid = 1000, # grid 1km x 1km
                                       extent = 5)  
homerange.late.winter.north.h500.top <- getverticeshr (khr.late.winter.north.h500.top, percent = 95)
writeOGR (homerange.late.winter.north.h500.top, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h500_top.shp", 
          layer = "hr_north_late.winter_h500_top", driver = "ESRI Shapefile")
rm (khr.late.winter.north.h500.top)
#khr.late.winter.north.h750.top <- kernelUD (prov.locs.late.winter.north.top [, 45], # new unique animal ID
#                                   h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
#                                   grid = 1000, # grid 1km x 1km
#                                   extent = 5)  
#homerange.late.winter.north.h750.top <- getverticeshr (khr.late.winter.north.h750.top, percent = 95)
#writeOGR (homerange.late.winter.north.h750.top, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h750_top.shp", 
#          layer = "hr_north_late.winter_h750_top", driver = "ESRI Shapefile")
#rm (khr.late.winter.north.h750.top)

#khr.late.winter.north.h1000.bottom <- kernelUD (prov.locs.late.winter.north.bottom [, 45], # new unique animal ID
#                                           h = 1000, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 1000, 10000)
#                                           grid = 1000, # grid 1km x 1km
#                                           extent = 5)  # extent is 2x the 'normal' size
#homerange.late.winter.north.h1000.bottom <- getverticeshr (khr.late.winter.north.h1000.bottom, percent = 95)
#writeOGR (homerange.late.winter.north.h1000.bottom, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h1000_top.shp", 
#          layer = "hr_north_late.winter_h1000_top", driver = "ESRI Shapefile")
#rm (khr.late.winter.north.h1000.bottom)
khr.late.winter.north.h500.bottom <- kernelUD (prov.locs.late.winter.north.bottom [, 45], # new unique animal ID
                                          h = 500, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
                                          grid = 1000, # grid 1km x 1km
                                          extent = 5)  
homerange.late.winter.north.h500.bottom <- getverticeshr (khr.late.winter.north.h500.bottom, percent = 95)
writeOGR (homerange.late.winter.north.h500.bottom, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h500_bottom.shp", 
          layer = "hr_north_late.winter_h500_bottom", driver = "ESRI Shapefile")
rm (khr.late.winter.north.h500.bottom)
#khr.late.winter.north.h750 <- kernelUD (prov.locs.late.winter.north.bottom [, 45], # new unique animal ID
#                                   h = 750, # smoothing parameter (h) computed by Least Square Cross Validation did not converge, so tried different h values (100, 10000, 100000)
#                                   grid = 1000, # grid 1km x 1km
#                                   extent = 5)  
#homerange.late.winter.north.h750.bottom <- getverticeshr (khr.late.winter.north.h750.bottom, percent = 95)
#writeOGR (homerange.late.winter.north.h750.bottom, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h750_top.shp", 
#          layer = "hr_north_late.winter_h750_top", driver = "ESRI Shapefile")
#rm (khr.late.winter.north.h750.bottom)

#===============================================================
# Random sample of 'available' points in home ranges
#==============================================================
# https://gis.stackexchange.com/questions/108046/how-to-create-randomly-points-within-polygons-for-each-row-of-a-dataframe-matchi
homerange.summer.boreal.h500 <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_summer_h500.shp",
                                         layer = "hr_boreal_summer_h500")
homerange.early.winter.boreal.h500 <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_early.winter_h500.shp",
                                                layer = "hr_boreal_early.winter_h500")
homerange.late.winter.boreal.h500 <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_boreal_late.winter_h500.shp",
                                              layer = "hr_boreal_late.winter_h500")
homerange.summer.mount.h500 <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_summer_h500.shp",
                                        layer = "hr_mount_summer_h500")
homerange.early.winter.mount.h500 <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_early.winter_h500.shp",
                                              layer = "hr_mount_early.winter_h500")
homerange.late.winter.mount.h500 <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_mount_late.winter_h500.shp",
                                            layer = "hr_mount_late.winter_h500")
homerange.summer.north.h500.top <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h500_top.shp",
                                            layer = "hr_north_summer_h500_top")
homerange.summer.north.h500.bottom <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_summer_h500_bottom.shp",
                                               layer = "hr_north_summer_h500_bottom")
homerange.early.winter.north.h500 <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_early.winter_h500.shp",
                                              layer = "hr_north_early.winter_h500")
homerange.late.winter.north.h500.top <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h500_top.shp",
                                                 layer = "hr_north_late.winter_h500_top")
homerange.late.winter.north.h500.bottom <- readOGR (dsn = "C:\\Work\\caribou\\climate_analysis\\data\\caribou\\homeranges\\hr_north_late.winter_h500_bottom.shp",
                                                    layer = "hr_north_late.winter_h500_bottom")
homerange.all <- rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (homerange.summer.boreal.h500, homerange.early.winter.boreal.h500),
                        homerange.late.winter.boreal.h500), homerange.summer.mount.h500), 
                        homerange.early.winter.mount.h500), homerange.late.winter.mount.h500), 
                        homerange.summer.north.h500.top), homerange.summer.north.h500.bottom), 
                        homerange.early.winter.north.h500), homerange.late.winter.north.h500.top),
                        homerange.late.winter.north.h500.bottom)

# create spatialpointsdataframe to bind to in loop
sample.pts.boreal.C1_Maxhamish_Boreal_Summer_2006 <- spsample (homerange.summer.boreal.h500 [homerange.summer.boreal.h500@data$id == "C1_Maxhamish_Boreal_Summer_2006",], 
                                                               n = 1000, type = "random")
sample.pts.boreal.data.C1_Maxhamish_Boreal_Summer_2006 <- data.frame (matrix (ncol = 2, nrow = nrow (sample.pts.boreal.C1_Maxhamish_Boreal_Summer_2006@coords)))
colnames (sample.pts.boreal.data.C1_Maxhamish_Boreal_Summer_2006) <- c ("pttype", "uniqueID")
sample.pts.boreal.data.C1_Maxhamish_Boreal_Summer_2006$pttype <- 0
sample.pts.boreal.data.C1_Maxhamish_Boreal_Summer_2006$uniqueID <- paste (i)
id.points.out.all <- SpatialPointsDataFrame (sample.pts.boreal.C1_Maxhamish_Boreal_Summer_2006, data = sample.pts.boreal.data.C1_Maxhamish_Boreal_Summer_2006)

for (i in levels (homerange.all@data$id)) { # loop to sample 1000 random points for each polygon
  id.poly <- homerange.all [homerange.all@data$id == i,]
  id.points <- spsample (id.poly, 
                         n = 1000, type = "random", iter = 50)
  data.pts <- data.frame (matrix (ncol = 2, nrow = nrow (id.points@coords)))
  colnames (data.pts) <- c ("pttype", "uniqueID")
  data.pts$pttype <- 0
  data.pts$uniqueID <- i
  id.points.out <- SpatialPointsDataFrame (id.points, data = data.pts)
  id.points.out.all <- rbind (id.points.out.all, id.points.out)
}

id.points.out.all@data$ecotype <- gsub (".*(Northern|Mountain|Boreal).*$", # define ecotype, season, etc. 
                                        "\\1", 
                                        id.points.out.all@data$uniqueID, ignore.case = F)
id.points.out.all@data$season <- gsub (".*(Early Winter|Late Winter|Summer).*$", # define ecotype, season, etc. 
                                        "\\1", 
                                        id.points.out.all@data$uniqueID, ignore.case = F)
id.points.out.all@data$ANIMAL_ID <- sub ('_.*$', '', id.points.out.all@data$uniqueID)
id.points.out.all@data$OBSERVATION_YEAR <-  sub ('^.*_', '', id.points.out.all@data$uniqueID)
id.points.out.all@data$HERD_NAME <- gsub (".*(Snake-Sahtaneh|Maxhamish|Chinchaga|Hart Ranges|Wells Gray|Frisby-Boulder|Columbia North|Groundhog|Monashee|Purcells South|Graham|Telkwa|Atlin|Swan Lake|Quintette|Narraway|Kennedy Siding|Moberly|Scott|Wolverine|Chase|Finlay|Pink Mountain|Tweedsmuir|Frog|Spatsizi|Level Kawdy|Little Rancheria|Edziza|Itcha-Ilgachuz|Rainbows|Charlotte Alplands|Burnt Pine  
).*$", # define ecotype, season, etc. 
                                          "\\1", 
                                          id.points.out.all@data$uniqueID, ignore.case = F)
writeOGR (id.points.out.all, dsn = "C:\\Work\\caribou\\climate_analysis\\data\\samplepoints\\homerange_scale\\homerange_avail_points.shp", 
          layer = "homerange_avail_points", driver = "ESRI Shapefile")

#===============================
# Sample habitat at locations
#===============================

id.points.out.all
prov.locs.all.used

























#================================================
# Bind the available and used locations together
#===============================================
prov.locs.all.used@data$ecotype <- as.character (prov.locs.all.used@data$ecotype)
prov.locs.all.used@data$OBSERVATION_YEAR <- as.character (prov.locs.all.used@data$OBSERVATION_YEAR)
prov.locs.all.used@data$uniqueID <- as.character (prov.locs.all.used@data$uniqueID)
prov.locs.all.used@data$season <- as.character (prov.locs.all.used@data$season)
prov.locs.all.used@data$HERD_NAME <- as.character (prov.locs.all.used@data$HERD_NAME)
prov.locs.all.used@data$ANIMAL_ID <- as.character (prov.locs.all.used@data$ANIMAL_ID)

id.points.out.all <- spTransform (id.points.out.all, CRS = proj4string (prov.locs.all.used)) # reproject
id.points.out.all@data [setdiff (names (prov.locs.all.used@data), names(id.points.out.all@data))] <- NA # create the same column names
prov.locs.all.used@data [setdiff (names (id.points.out.all@data), names(prov.locs.all.used@data))] <- NA # create the same column names
id.points.out.all@data$ptID <- c (453377:1978377)
all.locations <- rbind (prov.locs.all.used, id.points.out.all)


select ()





all.locations@data$ecotype 
all.locations@data$season 
all.locations@data$season 
all.locations@data$year 


as.factor

