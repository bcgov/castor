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
#  Script Name: 02_wolf_fxn_response_model
#  Script Version: 1.0
#  Script Purpose: Script to model wolf predation rate on cariobu as a Type II fucntional response . 
#                  Initial versions were exploratory analyses to identify appropriate 
#                  equations, later versions will be built to run dynamically and integrate with 
#                  landscape models.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 
#  Script Date: 5 January 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: dplyr 0.7.4, ggplot2
#=================================

#=================================
# Load the packages
#=================================
library (dplyr)
library (ggplot2)
options (scipen = 999)

#=================================
# Load/Create the data
#=================================
fxn.data.one <- data.frame ("total.time.days" = 365, # 'simulated' dataset to test some equations
                            "linear.travel.km" = 100, "detect.dist.km" = 1, "prob.capt" = 0.3,
                            "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                            "handle.time.days" = 1, "scenario" = "100-30-1", stringsAsFactors = FALSE)

fxn.data.two <- data.frame ("total.time.days" = 365, 
                            "linear.travel.km" = 100, "detect.dist.km" = 1, "prob.capt" = 0.5,
                            "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                            "handle.time.days" = 1, "scenario" = "100-50-1", stringsAsFactors = FALSE)

fxn.data.three <- data.frame ("total.time.days" = 365, 
                              "linear.travel.km" = 50, "detect.dist.km" = 1, "prob.capt" = 0.3,
                              "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                              "handle.time.days" = 1, "scenario" = "50-30-1", stringsAsFactors = FALSE)

fxn.data.four <- data.frame ("total.time.days" = 365, 
                             "linear.travel.km" = 100, "detect.dist.km" = 1, "prob.capt" = 0.3,
                             "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                             "handle.time.days" = 2, "scenario" = "100-30-2", stringsAsFactors = FALSE)

fxn.data.five <- data.frame ("total.time.days" = 365, 
                             "linear.travel.km" = 50, "detect.dist.km" = 1, "prob.capt" = 0.5,
                             "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                             "handle.time.days" = 1, "scenario" = "50-50-1", stringsAsFactors = FALSE)

fxn.data.six <- data.frame ("total.time.days" = 365, 
                             "linear.travel.km" = 50, "detect.dist.km" = 1, "prob.capt" = 0.5,
                             "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                             "handle.time.days" = 2, "scenario" = "50-50-2", stringsAsFactors = FALSE)

fxn.data.seven <- data.frame ("total.time.days" = 365, 
                            "linear.travel.km" = 100, "detect.dist.km" = 1, "prob.capt" = 0.5,
                            "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                            "handle.time.days" = 2, "scenario" = "100-50-2", stringsAsFactors = FALSE)

fxn.data.eight <- data.frame ("total.time.days" = 365, 
                              "linear.travel.km" = 50, "detect.dist.km" = 1, "prob.capt" = 0.3,
                              "caribou.dens.km2" = seq (from = 0, to = 1, by = 0.05), 
                              "handle.time.days" = 2, "scenario" = "50-30-2", stringsAsFactors = FALSE)

fxn.data <- dplyr::bind_rows (fxn.data.one, fxn.data.two)
fxn.data <- dplyr::bind_rows (fxn.data, fxn.data.three)
fxn.data <- dplyr::bind_rows (fxn.data, fxn.data.four)
fxn.data <- dplyr::bind_rows (fxn.data, fxn.data.five)
fxn.data <- dplyr::bind_rows (fxn.data, fxn.data.six)
fxn.data <- dplyr::bind_rows (fxn.data, fxn.data.seven)
fxn.data <- dplyr::bind_rows (fxn.data, fxn.data.eight)

#=================================
# Holling Type II functional response equation
#=================================
holling.fxn.resp <- function (data, total.time, linear.travel, detect.dist, prob.capt, caribou.dens, 
                              handle.time) {
  data$h.caribou.killed <- (total.time * (((detect.dist * linear.travel)/365) * prob.capt) * caribou.dens) / 
                            (1 + (handle.time * (((detect.dist * linear.travel)/365) * prob.capt) * 
                                     caribou.dens))
  return (data)
}

#=================================
# Vucetich functional response equation
#=================================
vucetich.fxn.resp <- function (data, linear.travel, detect.dist, prob.capt, caribou.dens, wolf.dens,
                              handle.time) {
  data$v.caribou.killed <- ((((detect.dist * linear.travel)/365) * prob.capt) * caribou.dens * wolf.dens) / 
                          (wolf.dens + (handle.time * (((detect.dist * linear.travel)/365) * prob.capt) * 
                                  caribou.dens))
  return (data)
}

#=================================
# Calculate number of caribou killed
#=================================
fxn.data <- holling.fxn.resp (fxn.data, fxn.data$total.time.days, fxn.data$linear.travel.km, 
                               fxn.data$detect.dist.km, fxn.data$prob.capt, fxn.data$caribou.dens.km2,
                               fxn.data$handle.time.days)

fxn.data <- vucetich.fxn.resp (fxn.data, fxn.data$total.time.days, fxn.data$linear.travel.km, 
                               fxn.data$detect.dist.km, fxn.data$prob.capt, fxn.data$caribou.dens.km2,
                               fxn.data$handle.time.days)
fxn.data <- fxn.data %>%
              mutate (mean.caribou.killed = ((v.caribou.killed + h.caribou.killed)/2))

#=================================
# Plot sensitivity of number of caribou killed
#=================================
ggplot (fxn.data, aes (caribou.dens.km2, h.caribou.killed, 
                       group = scenario,
                       color = scenario)) +
        geom_line (aes (linetype = scenario)) +
        theme_classic () + 
        scale_x_continuous (name = expression ("Caribou Density"~km^2), limits = c (0, 1),
                            breaks = c (0.2, 0.4, 0.6, 0.8, 1.0)) +
        scale_y_continuous (name = "Caribou killed - Holling Function", limits = c (0, 50),
                             breaks = c (5, 10, 15, 20, 25, 30, 35, 40, 45, 50)) + 
        labs (title = "Functional Response Scenarios (travel distance-capture probability-handling time)")

ggplot (fxn.data, aes (caribou.dens.km2, v.caribou.killed, 
                       group = scenario,
                       color = scenario)) +
        geom_line (aes (linetype = scenario)) +
        theme_classic () + 
        scale_x_continuous (name = expression ("Caribou Density"~km^2), limits = c (0, 1),
                            breaks = c (0.2, 0.4, 0.6, 0.8, 1.0)) +
        scale_y_continuous (name = "Caribou killed - Vucetich Function", limits = c (0, 50),
                            breaks = c (5, 10, 15, 20, 25, 30, 35, 40, 45, 50)) + 
        labs (title = "Functional Response Scenarios (travel distance-capture probability-handling time)")






