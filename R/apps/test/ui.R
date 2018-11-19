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
#-------------------------------------------------------------------------------------------------
# Define UI
shinyUI(fluidPage(theme = shinytheme("lumen"),  
                titlePanel("CLUS: Scenario Tool"),
                sidebarLayout(
                  sidebarPanel(
                    # add the caribou recovery logo
                    img(src = "clus-logo.png", height = 100, width = 100),
                    helpText("Click map to select a herd"),
                    #Ecotype name
                    h2(textOutput("clickEcoType")),
                    helpText("Ecotype"),
                    #Herd name
                    h2(textOutput("clickCaribou")),
                    helpText("Herd"),
                    radioButtons("queryType", label = h3("Query Options"),
                                 choices = list("Herd Boundary" = 1, "Drawn" = 2), 
                                 selected = 1)
                  ),
                  
                  # Output: Description, lineplot, and reference
                  mainPanel(
                    leafletOutput("map"),
                    downloadButton("downloadData.zip", "Save"),
                    helpText("Save drawn polygons"),
                    tabsetPanel(
                      tabPanel("Herd Plan", uiOutput("pdfview")),
                      tabPanel("Protected Area", navlistPanel(
                        "Protection",
                        tabPanel("Ungulate Winter Range", tableOutput("uwrTable")),
                        tabPanel("Wildlife Habitat Area", tableOutput("whaTable")))
                      ),
                      tabPanel("Disturbance", navlistPanel(
                        "Summary", 
                        tabPanel("Fire", plotOutput(outputId = "firePlot", height = "300px")),
                        tabPanel("Cutblock", plotOutput(outputId = "cutPlot", height = "300px")),
                        tabPanel("Road", tableOutput("rdTable")),
                        tabPanel("Other Linear"),
                        tabPanel("Total Early Seral")
                      )
                      ),
                      tabPanel("Climate Change", navlistPanel(
                        "BEC", 
                        tabPanel("Proportion", plotOutput(outputId = "becPlot", height = "300px")), 
                        "Variables", 
                        tabPanel("Frost Free Days", plotOutput(outputId = "ffdPlot", height = "300px")), 
                        tabPanel("Precipitation as Snow", plotOutput(outputId = "pasPlot", height = "300px")), 
                        tabPanel("Average Winter Temperature", plotOutput(outputId = "awtPlot", height = "300px")
                        )))
                    )
                  )
                )
)
)
