library(shiny)
library(shinythemes)
library(shinyWidgets)
library(leaflet.extras)
library(dplyr)
library(readr)
library(ggplot2)
library(leaflet)
library(rpostgis)
library(sf)
library(sp)
library(rgdal)
library(zoo)
library(tidyr)
library(raster)
getQuery<-function(sql){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='206.167.181.178', dbname = 'aroma', port='5432' ,user='aroma' ,password='Fomsummer2014')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

ui <- fluidPage(theme = shinytheme("lumen"),  
                titlePanel("CLUS: Scenario Tool"),
              sidebarLayout(
                  sidebarPanel(
                    h2(textOutput("serverConnect"))
                ),
                mainPanel(
                  leafletOutput("map"))
                  )
)

                  