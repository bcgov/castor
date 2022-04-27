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
library(leaflet.extras2)
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
#fetaPoly<-st_transform(st_read("www/feta_v1.shp"), 4326)
#fetaPoly<-readLines("www/test.geojson") %>% paste(collapse = "\n")
fetaPolyGeoJson<-readr::read_file("www/feta_v2.geojson")
fetaPolySf<-geojsonsf::geojson_sf(fetaPolyGeoJson)
fetaTSA<-readRDS("www/tsa_fids_v2.rds")
#----------------
#Non-Spatial 
tsaBnds <- as.list(unique(fetaTSA$tsa))


