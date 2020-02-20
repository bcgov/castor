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
#  Script Name: 24_RSF_validation.R
#  Script Version: 1.0
#  Script Purpose: Script to validate RSF models with out of sample (i.e., new) location data.
#                  Here I adapt the Johnson et al. 2006 (https://www.jstor.org/stable/3803680?seq=1#page_scan_tab_contents)
#                   to validate RSF models using 'new' (out-of-sample) RSF data
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 16 August 2019
#  R Version: 
#  R Packages: 
#  Data: 
#=================================

#==========================================
options (scipen = 999)
require (raster)
require (sf)
require (dplyr)
require (adehabitatHR)
require (ggplot2)


# require (rgdal)

#====================================
# 1. LOAD THE RSF MAP(S) OF INTEREST
#====================================
# here I am testing the caribou RSF maps I developed for DU7
raster.rsf.caribou.du7.ew <- raster (x = "C:\\Work\\caribou\\clus_data\\rsf\\du7\\rsf_du7_ew.tif") 
raster.rsf.caribou.du7.lw <- raster (x = "C:\\Work\\caribou\\clus_data\\rsf\\du7\\rsf_du7_lw.tif") 
raster.rsf.caribou.du7.s <- raster (x = "C:\\Work\\caribou\\clus_data\\rsf\\du7\\rsf_du7_s.tif") 

#=====================================
# 2. LOAD THE NEW ANIMAL LOCATION DATA
#=====================================
# here I am loading caribou telemetry data from the Chilctoin region
data.locs.caribou <- sf::st_read (dsn = "C:\\Work\\caribou\\clus_data\\caribou\\Chilcotin_LPU_telemetry_1985to2019")

# I only want 'recent' data, form teh last year (Aug. 1 2018 to July 31, 2019),
# as data prior to that was used to build the RSF
data.locs.caribou.2019 <- dplyr::filter (data.locs.caribou,
                                         Date_Local > "2018-07-31")

#=========================================
# 3. DEFINE THE AREA AVAILABLE TO CARIBOU
#========================================
# here I estimate a study area using a minimum convex polygon (MCP); I use the mcp function 
# in the adehabitatHR package
# here you could use another approach to deifne available space to caribou, but the MCP approach 
# seems reasonable 

# sf object needs to be covnereted to a spatiapointsdataframe
data.locs.caribou.2019 <- as (data.locs.caribou.2019, 'Spatial')

# create the mcp
mcp.locs.caribou.2019 <- adehabitatHR::mcp (data.locs.caribou.2019,
                                            percent = 95)

plot (mcp.locs.caribou.2019) # quick plot to make sure it looks ok
plot (data.locs.caribou.2019, add = T) 

#=========================================
# 4. GET RSF SCORES IN THE AVAILABLE AREA
#========================================
available.rsf.du7.ew <- raster::extract (raster.rsf.caribou.du7.ew,
                                         mcp.locs.caribou.2019,
                                         method = "simple",
                                         df = T)

available.rsf.du7.lw <- raster::extract (raster.rsf.caribou.du7.lw,
                                         mcp.locs.caribou.2019,
                                         method = "simple",
                                         df = T)

available.rsf.du7.s <- raster::extract (raster.rsf.caribou.du7.s,
                                         mcp.locs.caribou.2019,
                                         method = "simple",
                                         df = T)

#============================================
# 5. GET RSF SCORES AT THE CARIBOU LOCATIONS
#===========================================
# first, clip the locations in the MCP
mcp.locs.caribou.2019 <- st_as_sf (mcp.locs.caribou.2019) # convert the sp objects to sf objects
data.locs.caribou.2019 <- st_as_sf (data.locs.caribou.2019)

data.locs.caribou.2019.clip <- sf::st_intersection (data.locs.caribou.2019, mcp.locs.caribou.2019)

plot (st_geometry (mcp.locs.caribou.2019)) # quick plot to make sure it looks ok
plot (st_geometry (data.locs.caribou.2019.clip), add = T)

# then get the RFS scores at the locations
data.locs.caribou.2019.rsf.du7.lw <- raster::extract (raster.rsf.caribou.du7.lw,
                                                      data.locs.caribou.2019,
                                                      method = "simple",
                                                      df = T)

data.locs.caribou.2019.rsf.du7.ew <- raster::extract (raster.rsf.caribou.du7.ew,
                                                      data.locs.caribou.2019,
                                                      method = "simple",
                                                      df = T)

data.locs.caribou.2019.rsf.du7.s <- raster::extract (raster.rsf.caribou.du7.s,
                                                      data.locs.caribou.2019,
                                                      method = "simple",
                                                      df = T)

#========================
# 6. BIN THE RSF SCORES
#=======================
# first, let's look at the distribution of the data

### for the early winter model...... ###
ggplot (data = available.rsf.du7.ew, aes (rsf_du7_ew)) +
  geom_histogram() # distribution of the available data
max (available.rsf.du7.ew$rsf_du7_ew)
min (available.rsf.du7.ew$rsf_du7_ew)

ggplot (data = data.locs.caribou.2019.rsf.du7.ew, aes (rsf_du7_ew)) +
  geom_histogram() # distribution of the available data
max (na.omit (data.locs.caribou.2019.rsf.du7.ew$rsf_du7_ew))
min (na.omit (data.locs.caribou.2019.rsf.du7.ew$rsf_du7_ew))

# here I define bins between 0 to 0.6 at 0.05 intervals and define which bin the location falls in 
available.rsf.du7.ew$rsf_bin <- cut (available.rsf.du7.ew$rsf_du7_ew, 
                                     breaks = c (-Inf, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 
                                                  0.35, 0.4, 0.45, 0.5, 0.55, Inf), 
                                     labels = c ("0.05", "0.10", "0.15", "0.20", "0.25", 
                                                 "0.30", "0.35", "0.40", "0.45", "0.50", 
                                                 "0.55", "0.60"))
data.locs.caribou.2019.rsf.du7.ew$rsf_bin <- cut (data.locs.caribou.2019.rsf.du7.ew$rsf_du7_ew, 
                                                  breaks = c (-Inf, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 
                                                               0.35, 0.4, 0.45, 0.5, 0.55, Inf), 
                                                  labels = c ("0.05", "0.10", "0.15", "0.20", "0.25", 
                                                               "0.30", "0.35", "0.40", "0.45", "0.50", 
                                                               "0.55", "0.60"))

### for the late winter model...... ###
ggplot (data = available.rsf.du7.lw, aes (rsf_du7_lw)) +
  geom_histogram() # distribution of the available data
max (available.rsf.du7.lw$rsf_du7_lw)
min (available.rsf.du7.lw$rsf_du7_lw)

ggplot (data = data.locs.caribou.2019.rsf.du7.lw, aes (rsf_du7_lw)) +
  geom_histogram() # distribution of the available data
max (na.omit (data.locs.caribou.2019.rsf.du7.lw$rsf_du7_lw))
min (na.omit (data.locs.caribou.2019.rsf.du7.lw$rsf_du7_lw))

# here I define bins between 0 to 0.55 at 0.05 intervals and define which bin the location falls in 
available.rsf.du7.lw$rsf_bin <- cut (available.rsf.du7.lw$rsf_du7_lw, 
                                     breaks = c (-Inf, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 
                                                 0.35, 0.4, 0.45, 0.5, Inf), 
                                     labels = c ("0.05", "0.10", "0.15", "0.20", "0.25", 
                                                 "0.30", "0.35", "0.40", "0.45", "0.50", 
                                                 "0.55"))
data.locs.caribou.2019.rsf.du7.lw$rsf_bin <- cut (data.locs.caribou.2019.rsf.du7.lw$rsf_du7_lw, 
                                                  breaks = c (-Inf, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 
                                                              0.35, 0.4, 0.45, 0.5, Inf), 
                                                  labels = c ("0.05", "0.10", "0.15", "0.20", "0.25", 
                                                              "0.30", "0.35", "0.40", "0.45", "0.50", 
                                                              "0.55"))

### for the summer model...... ###
ggplot (data = available.rsf.du7.s, aes (rsf_du7_s)) +
  geom_histogram() # distribution of the available data
max (available.rsf.du7.s$rsf_du7_s)
min (available.rsf.du7.s$rsf_du7_s)

ggplot (data = data.locs.caribou.2019.rsf.du7.s, aes (rsf_du7_s)) +
  geom_histogram() # distribution of the available data
max (na.omit (data.locs.caribou.2019.rsf.du7.s$rsf_du7_s))
min (na.omit (data.locs.caribou.2019.rsf.du7.s$rsf_du7_s))

# here I define bins between 0 to 0.58 at 0.05 intervals and define which bin the location falls in 
available.rsf.du7.s$rsf_bin <- cut (available.rsf.du7.s$rsf_du7_s, 
                                     breaks = c (-Inf, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 
                                                 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7,
                                                 0.75, Inf), 
                                     labels = c ("0.05", "0.10", "0.15", "0.20", "0.25", 
                                                 "0.30", "0.35", "0.40", "0.45", "0.50", 
                                                 "0.55", "0.60", "0.65", "0.70", "0.75", "0.80"))
data.locs.caribou.2019.rsf.du7.s$rsf_bin <- cut (data.locs.caribou.2019.rsf.du7.s$rsf_du7_s, 
                                                  breaks = c (-Inf, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 
                                                              0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65,
                                                              0.7, 0.75, Inf), 
                                                  labels = c ("0.05", "0.10", "0.15", "0.20", "0.25", 
                                                              "0.30", "0.35", "0.40", "0.45", "0.50", 
                                                              "0.55", "0.60", "0.65", "0.70", "0.75", 
                                                              "0.80"))

#=============================================================================================
# 7. CALCULATE FREQUENCY OF USED AND EXPECTED (AREA WEIGHTED AVAILABLE RSF SCORES) RSF SCORES
#============================================================================================

# create a table of the data used to validate the model
table.kfold <- data.frame (matrix (ncol = 12, nrow = 39))
colnames (table.kfold) <- c ("model", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")

# define the models and bin mid-points
table.kfold [c (1:12), 1] <- "Early Winter"
table.kfold [c (1:12), 2] <- c (0.025, 0.075, 0.125, 0.175, 0.225, 0.275, 0.325, 0.375, 0.425, 0.475,
                                0.525, 0.575)
table.kfold [c (13:23), 1] <- "Late Winter"
table.kfold [c (13:23), 2] <- c (0.025, 0.075, 0.125, 0.175, 0.225, 0.275, 0.325, 0.375, 0.425, 0.475,
                                 0.525)
table.kfold [c (24:39), 1] <- "Summer"
table.kfold [c (24:39), 2] <- c (0.025, 0.075, 0.125, 0.175, 0.225, 0.275, 0.325, 0.375, 0.425, 0.475,
                                 0.525, 0.575, 0.625, 0.675, 0.725, 0.775)

# calcualte the 'available' bin weight 
# by multiplying the bin mid-point value by the area of the bin
table.kfold [1, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.05")) * 0.025) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.10")) * 0.075)
table.kfold [3, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.15")) * 0.125)
table.kfold [4, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.20")) * 0.175)
table.kfold [5, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.25")) * 0.225)
table.kfold [6, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.30")) * 0.275)
table.kfold [7, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.35")) * 0.325)
table.kfold [8, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.40")) * 0.375)
table.kfold [9, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.45")) * 0.425)
table.kfold [10, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.50")) * 0.475)
table.kfold [11, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.55")) * 0.525)
table.kfold [12, 3] <- (nrow (dplyr::filter (available.rsf.du7.ew, rsf_bin == "0.60")) * 0.575)

table.kfold [13, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.05")) * 0.025) 
table.kfold [14, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.10")) * 0.075)
table.kfold [15, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.15")) * 0.125)
table.kfold [16, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.20")) * 0.175)
table.kfold [17, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.25")) * 0.225)
table.kfold [18, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.30")) * 0.275)
table.kfold [19, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.35")) * 0.325)
table.kfold [20, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.40")) * 0.375)
table.kfold [21, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.45")) * 0.425)
table.kfold [22, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.50")) * 0.475)
table.kfold [23, 3] <- (nrow (dplyr::filter (available.rsf.du7.lw, rsf_bin == "0.55")) * 0.525)

table.kfold [24, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.05")) * 0.025) 
table.kfold [25, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.10")) * 0.075)
table.kfold [26, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.15")) * 0.125)
table.kfold [27, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.20")) * 0.175)
table.kfold [28, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.25")) * 0.225)
table.kfold [29, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.30")) * 0.275)
table.kfold [30, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.35")) * 0.325)
table.kfold [31, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.40")) * 0.375)
table.kfold [32, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.45")) * 0.425)
table.kfold [33, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.50")) * 0.475)
table.kfold [34, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.55")) * 0.525)
table.kfold [35, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.60")) * 0.575)
table.kfold [36, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.65")) * 0.625)
table.kfold [37, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.70")) * 0.675)
table.kfold [38, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.75")) * 0.725)
table.kfold [39, 3] <- (nrow (dplyr::filter (available.rsf.du7.s, rsf_bin == "0.80")) * 0.775)

# calculate 'utilization'
table.kfold [1, 4] <- table.kfold [1, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [2, 4] <- table.kfold [2, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [3, 4] <- table.kfold [3, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [4, 4] <- table.kfold [4, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [5, 4] <- table.kfold [5, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [6, 4] <- table.kfold [6, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [7, 4] <- table.kfold [7, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [8, 4] <- table.kfold [8, 3] / sum  (table.kfold [c (1:12), 3])
table.kfold [9, 4] <- table.kfold [9, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [10, 4] <- table.kfold [10, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [11, 4] <- table.kfold [11, 3] / sum  (table.kfold [c (1:12), 3]) 
table.kfold [12, 4] <- table.kfold [12, 3] / sum  (table.kfold [c (1:12), 3]) 

table.kfold [13, 4] <- table.kfold [13, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [14, 4] <- table.kfold [14, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [15, 4] <- table.kfold [15, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [16, 4] <- table.kfold [16, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [17, 4] <- table.kfold [17, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [18, 4] <- table.kfold [18, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [19, 4] <- table.kfold [19, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [20, 4] <- table.kfold [20, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [21, 4] <- table.kfold [21, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [22, 4] <- table.kfold [22, 3] / sum  (table.kfold [c (13:23), 3]) 
table.kfold [23, 4] <- table.kfold [23, 3] / sum  (table.kfold [c (13:23), 3]) 

table.kfold [24, 4] <- table.kfold [24, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [25, 4] <- table.kfold [25, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [26, 4] <- table.kfold [26, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [27, 4] <- table.kfold [27, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [28, 4] <- table.kfold [28, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [29, 4] <- table.kfold [29, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [30, 4] <- table.kfold [30, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [31, 4] <- table.kfold [31, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [32, 4] <- table.kfold [32, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [33, 4] <- table.kfold [33, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [34, 4] <- table.kfold [34, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [35, 4] <- table.kfold [35, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [36, 4] <- table.kfold [36, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [37, 4] <- table.kfold [37, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [38, 4] <- table.kfold [38, 3] / sum  (table.kfold [c (24:39), 3]) 
table.kfold [39, 4] <- table.kfold [39, 3] / sum  (table.kfold [c (24:39), 3]) 

# count # of used locations in each bin
table.kfold [1, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.05"))
table.kfold [2, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.10"))
table.kfold [3, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.15"))
table.kfold [4, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.20"))
table.kfold [5, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.25"))
table.kfold [6, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.30"))
table.kfold [7, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.35"))
table.kfold [8, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.40"))
table.kfold [9, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.45"))
table.kfold [10, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.50"))
table.kfold [11, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.55"))
table.kfold [12, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.ew, rsf_bin == "0.60"))

table.kfold [13, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.05"))
table.kfold [14, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.10"))
table.kfold [15, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.15"))
table.kfold [16, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.20"))
table.kfold [17, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.25"))
table.kfold [18, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.30"))
table.kfold [19, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.35"))
table.kfold [20, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.40"))
table.kfold [21, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.45"))
table.kfold [22, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.50"))
table.kfold [23, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.lw, rsf_bin == "0.55"))

table.kfold [24, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.05"))
table.kfold [25, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.10"))
table.kfold [26, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.15"))
table.kfold [27, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.20"))
table.kfold [28, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.25"))
table.kfold [29, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.30"))
table.kfold [30, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.35"))
table.kfold [31, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.40"))
table.kfold [32, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.45"))
table.kfold [33, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.50"))
table.kfold [34, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.55"))
table.kfold [35, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.60"))
table.kfold [36, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.65"))
table.kfold [37, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.70"))
table.kfold [38, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.75"))
table.kfold [39, 5] <- nrow (dplyr::filter (data.locs.caribou.2019.rsf.du7.s, rsf_bin == "0.80"))

# Calculate the expected number of used in each bin (area-weighted)
table.kfold [1, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [1, 4], 0) # expected number of uses in each bin
table.kfold [2, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [2, 4], 0) 
table.kfold [3, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [3, 4], 0) 
table.kfold [4, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [4, 4], 0) 
table.kfold [5, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [5, 4], 0) 
table.kfold [6, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [6, 4], 0) 
table.kfold [7, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [7, 4], 0) 
table.kfold [8, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [8, 4], 0) 
table.kfold [9, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [9, 4], 0) 
table.kfold [10, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [10, 4], 0) 
table.kfold [11, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [11, 4], 0) 
table.kfold [12, 6] <- round (sum (table.kfold [c (1:12), 5]) * table.kfold [12, 4], 0) 

table.kfold [13, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [13, 4], 0)
table.kfold [14, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [14, 4], 0)
table.kfold [15, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [15, 4], 0)
table.kfold [16, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [16, 4], 0)
table.kfold [17, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [17, 4], 0)
table.kfold [18, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [18, 4], 0)
table.kfold [19, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [19, 4], 0)
table.kfold [20, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [20, 4], 0)
table.kfold [21, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [21, 4], 0)
table.kfold [22, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [22, 4], 0)
table.kfold [23, 6] <- round (sum (table.kfold [c (13:23), 5]) * table.kfold [23, 4], 0)

table.kfold [24, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [24, 4], 0)
table.kfold [25, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [25, 4], 0)
table.kfold [26, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [26, 4], 0)
table.kfold [27, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [27, 4], 0)
table.kfold [28, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [28, 4], 0)
table.kfold [29, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [29, 4], 0)
table.kfold [30, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [30, 4], 0)
table.kfold [31, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [31, 4], 0)
table.kfold [32, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [32, 4], 0)
table.kfold [33, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [33, 4], 0)
table.kfold [34, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [34, 4], 0)
table.kfold [35, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [35, 4], 0)
table.kfold [36, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [36, 4], 0)
table.kfold [37, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [37, 4], 0)
table.kfold [38, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [38, 4], 0)
table.kfold [39, 6] <- round (sum (table.kfold [c (24:39), 5]) * table.kfold [39, 4], 0)

#==================================================================
# 8. CALCULATE LINEAR REGRESSION BETWEEN USED AND EXPECTED COUNTS
#================================================================

# Early winter model 
glm.kfold.ew <- lm (used.count ~ expected.count, 
                    data = dplyr::filter(table.kfold, model == "Early Winter"))
summary (glm.kfold.ew)

# model fit stats
table.kfold [1, 7] <- 0.86607 # model slope coefficient; slope = 1 indicates use equivalent to available, and thus a valid model
table.kfold [1, 8] <- "<0.001" # model slope p-value; low p-value (e.g., <0.05) indicates expected count a good predictor of used, and thus a valid model 
table.kfold [1, 9] <- 132.08166 # model intercept; 0 indicates use equivalent to available, and thus a valid model
table.kfold [1, 10] <- 0.305 # model intercept p-value; high p-value (e.g., >0.05) indicates expected count a good predictor of used, and thus a valid model 
table.kfold [1, 11] <- 0.9359 # adjusted R-squared value; R-sq = 1 indicates use equivalent to available, and thus a valid model

chisq.test (dplyr::filter (table.kfold, model == "Early Winter")$used.count, 
            dplyr::filter (table.kfold, model == "Early Winter")$expected.count)
table.kfold [1, 12] <- 0.2329 # chi-squre test; high p-value (e.g., >0.05) indicates expected count distribtuion similar to used, and thus a valid model

ggplot (dplyr::filter(table.kfold, model == "Early Winter"), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Expected versus observed proportion of caribou locations in RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 5000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 5000, by = 250)) # should be a linear fit


# Late winter model 
glm.kfold.lw <- lm (used.count ~ expected.count, 
                    data = dplyr::filter(table.kfold, model == "Late Winter"))
summary (glm.kfold.lw)

# model fit stats
table.kfold [13, 7] <- 0.92990 # model slope coefficient; slope = 1 indicates use equivalent to available, and thus a valid model
table.kfold [13, 8] <- "<0.001" # model slope p-value; low p-value (e.g., <0.05) indicates expected count a good predictor of used, and thus a valid model 
table.kfold [13, 9] <- 75.28786 # model intercept; 0 indicates use equivalent to available, and thus a valid model
table.kfold [13, 10] <- 0.442 # model intercept p-value; high p-value (e.g., >0.05) indicates expected count a good predictor of used, and thus a valid model 
table.kfold [13, 11] <- 0.9627 # adjusted R-squared value; R-sq = 1 indicates use equivalent to available, and thus a valid model

chisq.test (dplyr::filter (table.kfold, model == "Late Winter")$used.count, 
            dplyr::filter (table.kfold, model == "Late Winter")$expected.count)
table.kfold [13, 12] <- 0.2423 # chi-squre test; high p-value (e.g., >0.05) indicates expected count distribtuion similar to used, and thus a valid model

ggplot (dplyr::filter(table.kfold, model == "Late Winter"), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Expected versus observed proportion of caribou locations in RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 5000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 5000, by = 250)) # should be a linear fit


# Summer model 
glm.kfold.s <- lm (used.count ~ expected.count, 
                    data = dplyr::filter(table.kfold, model == "Summer"))
summary (glm.kfold.s)

# model fit stats
table.kfold [24, 7] <- 0.80249 # model slope coefficient; slope = 1 indicates use equivalent to available, and thus a valid model
table.kfold [24, 8] <- "<0.001" # model slope p-value; low p-value (e.g., <0.05) indicates expected count a good predictor of used, and thus a valid model 
table.kfold [24, 9] <- 146.26852 # model intercept; 0 indicates use equivalent to available, and thus a valid model
table.kfold [24, 10] <- 0.0229 # model intercept p-value; high p-value (e.g., >0.05) indicates expected count a good predictor of used, and thus a valid model 
table.kfold [24, 11] <- 0.9591 # adjusted R-squared value; R-sq = 1 indicates use equivalent to available, and thus a valid model

chisq.test (dplyr::filter (table.kfold, model == "Summer")$used.count, 
            dplyr::filter (table.kfold, model == "Summer")$expected.count)
table.kfold [24, 12] <- 0.09055 # chi-squre test; high p-value (e.g., >0.05) indicates expected count distribtuion similar to used, and thus a valid model

ggplot (dplyr::filter(table.kfold, model == "Summer"), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Expected versus observed proportion of caribou locations in RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 5000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 5000, by = 250)) # should be a linear fit


#### Model fit stats generally look good here ####


