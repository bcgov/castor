#-------------------------------------------------------------------------------------------------
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
#-------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------
# Load packages
#-------------------------------------------------------------------------------------------------
library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinydashboardPlus)
library(leaflet.extras)
library(leaflet)
library(rpostgis)
library(sf)
library(rgdal)
library(ggplot2)
library(plotly)
library(lwgeom)

#-------------------------------------------------------------------------------------------------
#Functions for retrieving data from the postgres server (vector, raster and tables)
#-------------------------------------------------------------------------------------------------


myDrawPolygonOptions <- function(allowIntersection = FALSE,
                                 guidelineDistance = 20,
                                 drawError = list(color = "#b00b00", timeout = 2500),
                                 shapeOptions = list(stroke = TRUE, color = '#003366', weight = 3,
                                                     fill = TRUE, fillColor = '#003366', fillOpacity = 0.1,
                                                     clickable = TRUE), metric = TRUE, zIndexOffset = 2000, repeatMode = FALSE, showArea = TRUE)
{
  if (isTRUE(showArea) && isTRUE(allowIntersection)) {
    warning("showArea = TRUE will be ignored because allowIntersection is TRUE")
  }
  
  list(
    allowIntersection = allowIntersection,
    drawError = drawError,
    guidelineDistance = guidelineDistance,
    shapeOptions = shapeOptions,
    metric = metric,
    zIndexOffset = zIndexOffset,
    repeatMode = repeatMode,
    showArea = showArea
  )
}

##Data objects
#----------------
#Spatial---------
##Get a connection to the postgreSQL server (local instance)
#sp_samplePoints <- getSpatialQueryIaian("SELECTobjectid,samp_id,sampletype,species_class,bgc_zone,tsa_desc,species_class, beclabel,project_design,meas_dt,no_meas,spc_label_live,stemsha_liv,baha_liv,wsvha_liv,tot_stand_age,geom, samp_sts from sample_plots_unique_final where geom is not null")
#tsa_sp <- st_transform(getSpatialQueryIaian("SELECT * from tsa_boundaries where shape is not null"), 4326)
fetaPoly<-st_transform(st_read("www/feta_v0.shp"), 4326)
fetaTSA<-readRDS("www/tsa_fids.rds")
#----------------
#Non-Spatial 
#sampleTypes <-  as.list(unique(sp_samplePoints$sampletype) )
#tsaBnds <- as.list(unique(sp_samplePoints$tsa_desc ))
#speciesLst <- as.list(unique(sp_samplePoints$species_class ))
#becLst <- as.list(unique(sp_samplePoints$bgc_zone ))
#prjdes <- as.list(unique(sp_samplePoints$project_design ))

#dummyData <- head(subset(as.data.frame(sp_samplePoints), select = c(tot_stand_age, wsvha_liv)),1)
#dummyData[,c("tot_stand_age", "wsvha_liv" )] <- 0
