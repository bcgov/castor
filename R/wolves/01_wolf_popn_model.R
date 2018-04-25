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
#  Script Name: 01_wolf_popn_model
#  Script Version: 1.0
#  Script Purpose: Script to model wolf population abundance as a function of ungulate abundance in 
#                  caribou herd range. Initial versions were exploratory analyses to identify appropriate 
#                  equations> later versions will be built to run dynamically and integrate with landscape 
#                  models.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 
#  Script Date: 21 December 2017
#  R Version: 3.4.3
#  R Package Versions: dplyr 0.7.4
#  Data: 
#=================================

#=================================
# Load the packages
#=================================
library (dplyr)
options (scipen = 999)

#=================================
# Load/Create the data
#=================================
wolf.data <- data.frame ("caribou.herd" = "Ritchie", # 'simulated' dataset to test some equations
                        "area.km2.caribou.herd" = 1000, "wolves.1000.km2" = c (0:20), 
                        "moose.km2" = 0.1, "elk.km2" = 0.1, "white.tailed.deer.km2" = 0.1,
                        "mule.deer.km2" = 0.1,
                        stringsAsFactors = FALSE)

# wolf density data
# Source: Serrouya, http://www.bcogris.ca/sites/default/files/bcip-2015-08-final-report-serrouya-abmi_0.pdf
Calendar herd <- 32/range size
Parker herd <- 6/range size
Chinchaga herd Resource Reivew Area <- 52/range size

# Source: Serrouya 2015, http://www.bcogris.ca/sites/default/files/bcip-2016-12-final-report-abmi-serrouya.pdf
Calendar herd <- 7/1000km2
Chinchaga herd <- 15.6/1000km2

# Moose density data
# soruce: Thiessen, C. 2010. Horn River Basin moose inventory, January/February 2010. M
# Ministry of Environment,Ft. St. John, BC. ; McNay, S., D. Webster, and G. Sutherland. 
# Aerial moose survey in NE BC, 2013.Submitted to: Research and Effictiveness Monitoring Board
Calendar herd <- 0.018 moose/km2
Parker herd <-  0.25 moose/km2 
Chinchaga herd Resource Reivew Area <- 0.15 moose/km2


#=================================
# Fuller et al. 2003 ungulate biomass equation; function to calculate ungulate biomass from density
#=================================
fuller.biomass <- function (data, moose.dens, elk.dens, wtdeer.dens, mule.deer.dens) {
  data$ungulate.biomass <- ((moose.dens * 6) + (elk.dens * 3) + # density input is animals/km2
                            (wtdeer.dens * 1) + (mule.deer.dens * 1))
  return (data)
  print ("Output is biomass index per km2; make sure the input data are in animals/km2.")
}

#=================================
# Fuller et al. 2003 wolf density equation; function to calculate wolf density from ungulate biomass index
#=================================
fuller.wolf.dens <- function (data, ungulate.biomass) {
  data$wolf.dens.fuller <- 3.5 + (ungulate.biomass * 3.3)
  return(data)
}

#=================================
# Kuzyk and Hatter 2014 wolf density equation; function to calculate wolf density from ungulate biomass index
#=================================
kuzyk.wolf.dens <- function (data, ungulate.biomass) {
  data$wolf.dens.kuzyk <- (ungulate.biomass * 5.4) - (ungulate.biomass^2 * 0.166)
  return(data)
}

#=================================
# Messier 1994 wolf density equation; function to calculate wolf density from moose density
#=================================
messier.wolf.dens <- function (data, moose.dens) {
  data$wolf.dens.messier <- (58.7 * (moose.dens - 0.03))/(0.76 + moose.dens)
  return(data)
}

#=================================
# Messier 1994 wolf density equation with conversion of ungulates density to moose density
#=================================
messier.wolf.dens.ung <- function (data, moose.dens, elk.dens, wtdeer.dens, mule.deer.dens) {
  data$wolf.dens.messier.ung <- (58.7 * (((moose.dens) + (elk.dens * 0.5) + (wtdeer.dens * 0.1666667) + 
                                            (mule.deer.dens * 0.1666667)) - 0.03))/(0.76 + 
                                            ((moose.dens) + (elk.dens * 0.5) + 
                                            (wtdeer.dens * 0.1666667) + (mule.deer.dens * 0.1666667)))
  return(data)
}

#=================================
# Calculate wolf density from ungulate density
#=================================
wolf.data <- fuller.biomass (wolf.data, wolf.data$moose.km2, wolf.data$elk.km2,
                             wolf.data$white.tailed.deer.km2, wolf.data$mule.deer.km2)
wolf.data <- fuller.wolf.dens (wolf.data, wolf.data$ungulate.biomass)
wolf.data <- kuzyk.wolf.dens (wolf.data, wolf.data$ungulate.biomass)
wolf.data <- messier.wolf.dens (wolf.data, wolf.data$moose.km2)
wolf.data <- messier.wolf.dens.ung (wolf.data, wolf.data$moose.km2, wolf.data$elk.km2,
                                    wolf.data$white.tailed.deer.km2, wolf.data$mule.deer.km2)

#=================================
# Average wolf density from ungulate models (not moose)
#=================================
wolf.data <- wolf.data %>%
              mutate (mean.wolf.dens = (wolf.dens.fuller + wolf.dens.kuzyk + wolf.dens.messier.ung) / 3)
