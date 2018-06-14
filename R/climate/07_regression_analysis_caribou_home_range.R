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
#  Script Name: 06_regression_analysis_caribou_home_range.R
#  Script Version: 1.0
#  Script Purpose: Caribou home range scale climate analysis.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 8 June 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================

#=================================
# data directory
#=================================
setwd ('C:\\Work\\caribou\\climate_analysis\\data\\')
options (scipen = 999)

#=================================
# Load packages
#=================================
require (dplyr)
require (ggplot2)
require (ggcorrplot)
require (car)
require (MASS)
require (ROCR)
require (lme4)
require (mcgv)
require (rpart)
require (nloptr)
require (arm)
require (sjPlot)
require (sjmisc)
require (lattice)

