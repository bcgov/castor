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



# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library (shiny)
library (shinyWidgets)
library (shinythemes)
library (ggplot2)
library (dplyr)
# library (jpeg)
# library (leaflet)
# library (rgdal)
# library (raster)
# library (rgeos)


#----------------
# Load the Data
#----------------
# will this work remotely?
# host and grab the data from github? hosted on Shiny IO?


# https://www.datascience.com/blog/beginners-guide-to-shiny-and-leaflet-for-interactive-mapping


# caribou.range <- readOGR ("C:\\Work\\caribou\\climate_analysis\\\shiny_app\data\\GCPB_CARIBOU_POPULATION_SP\\GCBP_CARIB_polygon.shp", 
#                          stringsAsFactors = T)
# prov.bnd <- readOGR ("C:\\Work\\caribou\\climate_analysis\\\shiny_app\data\\gpr_000b11a_e.shp", stringsAsFactors = T)
# proj.crs <- proj4string (caribou.range)
# prov.bnd.prj <- spTransform (prov.bnd, CRS = proj.crs) 
# prov.bnd.prj <- prov.bnd.prj [prov.bnd.prj@data$PRENAME == "British Columbia", ] # subset BC only
# caribou.range <- caribou.range [caribou.range@data$OBJECTID != 138, ] # NOTE: the polygon ID was obtained using ArcGIS; not sure how to get that using R 
# caribou.range@data[["diss"]] <- 1  # add field in data frame for 'dissolving' data
# caribou.range.boreal <- subset (caribou.range, caribou.range@data$ECOTYPE == "Boreal")
# caribou.range.mtn <- subset (caribou.range, caribou.range@data$ECOTYPE == "Mountain")
# caribou.range.north <- subset (caribou.range, caribou.range@data$ECOTYPE == "Northern")
# caribou.range.boreal.diss <- aggregate (caribou.range.boreal, by = 'diss') 
# caribou.range.mtn.diss <- aggregate (caribou.range.mtn, by = 'diss') 
# caribou.range.north.diss <- aggregate (caribou.range.north, by = 'diss') 




data.plot.herd.bec <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\clim_plot_data_bec.csv", 
                                    header = T, stringsAsFactors = T, sep = ",")
data.plot.herd.temp <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\clim_plot_data_winter_temp.csv", 
                                     header = T, stringsAsFactors = T, sep = ",")
data.plot.herd.nffd <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\clim_plot_data_spring_frost_free_days.csv", 
                                   header = T, stringsAsFactors = T, sep = ",") 
data.plot.herd.pas <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\clim_plot_data_winter_precip_as_snow.csv", 
                                   header = T, stringsAsFactors = T, sep = ",") 
data.plot.herd.bec$year <- relevel (data.plot.herd.bec$year, "Current")

# User Interface 
ui <- fluidPage (

  # Application title
  tags$img (src = "program_img.png", 
            height = 200, width = 250),
  titlePanel ("Caribou and Climate Change in British Columbia"),
   tags$p ("This application allows you to explore how some climate variables are predicted to change in caribou ranges in British Columbia. The 'Climate Variable Plots' tab allows you to explore current, historic and predicted future climate conditions by cariobu ecotype and herd range. The 'Habitat Predciton Map' tabs allows you to explore model future climate conidtiosn may influence cariobu ranges."),
   tags$p (HTML (paste0 ("All climate data was downloaded from the climate BC website ", a (href = 'http://climatebcdata.climatewna.com/#3._reference', 'Wang et al. 2012'),". Details on predictive habitait maps are described in detail in Muhly (In prep)."))),
   # Sidebar Layout style
   sidebarLayout (
     sidebarPanel ( # this stuff goes in the sidebar panel
       helpText ("Select the ecotype, herd and climate variable you are interested in."
       ),
       selectInput (inputId = "ecotype",
                    label = "Choose an ecotype:",
                    choices = c ("Boreal", "Mountain", "Northern"),
                    selected = "Northern"
       ),
       # user input of herd; dynamic response to ecotype
       uiOutput ("ui"
       )
       
    ), # closes the sidebar panel
      # Reactive Outputs to put into Main Panel
      mainPanel (# this stuff goes in the main panel
        tabsetPanel ( # this stuff goes into the first Tab of the Main Panel
          tabPanel ("Climate Variable Plots",
            # User input of selected climate variable 
            selectInput (inputId = "climateVar",
                                 label = "Select the climate variable on interest:",
                                 choices = c ("BEC Zone", "Spring Frost Free Days", 
                                              "Winter Precipitation as Snow", "Average Winter Temperature")
            ),
            plotOutput ("ecotypeclimPlot"
            ),
            plotOutput ("herdclimPlot"
            )
          ), #closes this tab panel
          tabPanel ("How is Climate Influencing Caribou?",
            tags$p ("Climate is influecing cariobu...model...")
          ), #closes this tab panel
          tabPanel ("Habitat Prediction Maps", 
            sliderTextInput (inputId = "climyear",
                             label = "Select year of interest using the slider.",
                             choices = c (1990, 2010, 2025, 2055, 2085),
                             selected = 2010,
                             grid = TRUE
            ),
            imageOutput ("herdpredImage"
            )
          ), # closes this tab panel
          tabPanel ("Download Habitat Prediction Map Data",
            tags$p ("Download tiff files...."),
            downloadLink ("predboreal1990tif", "Boreal Caribou 1990 TIFF Download"),
            downloadLink ("predboreal2010tif", "Boreal Caribou 2010 TIFF Download"),
            downloadLink ("predboreal2025tif", "Boreal Caribou 2025 TIFF Download"),
            downloadLink ("predboreal2055tif", "Boreal Caribou 2055 TIFF Download"),
            downloadLink ("predboreal2085tif", "Boreal Caribou 2085 TIFF Download")
            
            # need to add other ecotypes here
            
          ) #closes this tab panel
        ) # closes the tabset
      ) # closes the main panel
   ) # closes the sidebar layout
) # closes the UI

# Define server logic required to draw plots
server <- function (input, output) {
  
  output$ui <- renderUI ({
    switch (input$ecotype,
            "Boreal" = selectInput (inputId = "herdname",
                                    label = "Choose a herd:",
                                    choices = c ("Maxhamish", "Chinchaga", "Snake-Sahtaneh", 
                                                 "Calendar", "Parker", "Prophet")),
            "Mountain" = selectInput (inputId = "herdname",
                                      label = "Choose a herd:",
                                      choices = c ("Frisby-Boulder", "Columbia North", 
                                                   "Wells Gray", "Monashee", "Groundhog",         
                                                   "South Selkirks", "Nakusp", "Purcells South",     
                                                   "North Cariboo", "Narrow Lake", "Duncan", 
                                                   "Columbia South", "Central Rockies", "Barkerville", 
                                                   "Hart Ranges")),
            "Northern" = selectInput (inputId = "herdname",
                                      label = "Choose a herd:",
                                      choices = c ("Muskwa", "Rabbit", "Gataga", "Frog", 
                                                   "Pink Mountain", "Graham", "Horseranch", 
                                                   "Chase", "Finlay", "Liard Plateau",
                                                   "Itcha-Ilgachuz", "Rainbows", 
                                                   "Charlotte Alplands", "Burnt Pine", 
                                                   "Kennedy Siding", "Moberly", "Quintette", 
                                                   "Scott", "Takla", "Wolverine", "Atlin", 
                                                   "Carcross", "Edziza","Level Kawdy", 
                                                   "Little Rancheria", "Spatsizi", "Swan Lake", 
                                                   "Telkwa", "Tsenaglode", "Tweedsmuir", 
                                                   "Narraway", "Atlin"),
                                      selected = "Itcha-Ilgachuz"))
  })
  
  output$ecotypeclimPlot <- renderPlot ({
    if (input$climateVar == "BEC Zone") {
      ggplot (dplyr::filter (data.plot.herd.bec, ecotype == input$ecotype), 
              aes (x = year)) +  
        geom_bar (aes (fill = bec), position = 'fill') +
        ggtitle (paste (input$ecotype)) +
        xlab ("Year") +
        ylab ("Proportion of range area") +
        scale_fill_discrete (name = "Bec Zone") +
        theme (axis.text = element_text (size = 12),
                axis.title =  element_text (size = 14, face = "bold")) 
    } else if (input$climateVar == "Spring Frost Free Days") {
      ggplot (dplyr::filter (data.plot.herd.nffd, ecotype == input$ecotype), 
              aes (year, spffd)) +  
        geom_boxplot () +
        ggtitle (paste (input$ecotype)) +
        xlab ("Year") +
        ylab ("Number of Spring Frost Free Days") + 
        theme_bw () +
        theme (axis.text = element_text (size = 12),
               axis.title =  element_text (size = 14, face = "bold"))
    } else if (input$climateVar == "Winter Precipitation as Snow") {
      ggplot (dplyr::filter (data.plot.herd.pas, ecotype == input$ecotype), 
              aes (year, pas)) +  
        geom_boxplot () +
        ggtitle (paste (input$ecotype)) +
        xlab ("Year") +
        ylab ("Precipitation as Snow") +
        theme_bw () +
        theme (axis.text = element_text (size = 12),
               axis.title =  element_text (size = 14, face = "bold"))
    } else if (input$climateVar == "Average Winter Temperature") {
      ggplot (dplyr::filter (data.plot.herd.temp, ecotype == input$ecotype),
              aes (x = year, y = awt)) +  
        geom_boxplot () +
        ggtitle (paste (input$ecotype)) +
        xlab ("Year") +
        ylab ("Average Winter Temperature") + 
        theme_bw () +
        theme (axis.text = element_text (size = 12),
               axis.title =  element_text (size = 14, face = "bold"))
    }
  })  
  
  output$herdclimPlot <- renderPlot ({
    if (input$climateVar == "BEC Zone") {
      ggplot (dplyr::filter (data.plot.herd.bec, herdname == input$herdname), 
              aes (x = year)) +  
        geom_bar (aes (fill = bec), position = 'fill') +
        ggtitle (paste (input$herdname)) +
        xlab ("Year") +
        ylab ("Proportion of range area") +
        scale_fill_discrete (name = "Bec Zone") +
        theme (axis.text = element_text (size = 12),
               axis.title =  element_text (size = 14, face = "bold")) 
    } else if (input$climateVar == "Spring Frost Free Days") {
      ggplot (dplyr::filter (data.plot.herd.nffd, herdname == input$herdname), 
              aes (year, spffd)) +  
        geom_boxplot () +
        ggtitle (paste (input$herdname)) +
        xlab ("Year") +
        ylab ("Number of Spring Frost Free Days") + 
        theme_bw () +
        theme (axis.text = element_text (size = 12),
               axis.title =  element_text (size = 14, face = "bold"))
    } else if (input$climateVar == "Winter Precipitation as Snow") {
      ggplot (dplyr::filter (data.plot.herd.pas, herdname == input$herdname), 
              aes (year, pas)) +  
        geom_boxplot () +
        ggtitle (paste (input$herdname)) +
        xlab ("Year") +
        ylab ("Precipitation as Snow") +
        theme_bw () +
        theme (axis.text = element_text (size = 12),
               axis.title =  element_text (size = 14, face = "bold"))
    } else if (input$climateVar == "Average Winter Temperature") {
      ggplot (dplyr::filter (data.plot.herd.temp, herdname == input$herdname),
              aes (x = year, y = awt)) +  
        geom_boxplot () +
        ggtitle (paste (input$herdname)) +
        xlab ("Year") +
        ylab ("Average Winter Temperature") + 
        theme_bw () +
        theme (axis.text = element_text (size = 12),
               axis.title =  element_text (size = 14, face = "bold"))
    }
  })  
  
  output$herdpredImage <- renderImage ({
   
    filename <- normalizePath (file.path ('C:/Work/caribou/climate_analysis/shiny_app/www',
                               paste (input$ecotype, 
                                             input$herdname,
                                             input$climyear, 
                                             ".jpg",
                                             sep = ""
                                      )
                                )
                )
    
    list (src = filename,
          height = 700, 
          width = 550
    )
    
  
  }, deleteFile = F)
  
  output$predboreal1990tif <- downloadHandler (
    filename = function () {
      paste ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\rasters\\boreal\\",
             input$predboreal1990tif,
             ".tiff"
      )
    },
    content <- function (file) {
      file.copy (filename, file)
    }
  )
  
  output$predboreal2010tif <- downloadHandler (
    filename = function () {
      paste ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\rasters\\boreal\\",
             input$predboreal2010tif,
             ".tiff"
      )
    },
    content <- function (file) {
      file.copy (filename, file)
    }
  )
  
  output$predboreal2025tif <- downloadHandler (
    filename = function () {
      paste ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\rasters\\boreal\\",
             input$predboreal2025tif,
             ".tiff"
      )
    },
    content <- function (file) {
      file.copy (filename, file)
    }
  )               

  output$predboreal2055tif <- downloadHandler (
    filename = function () {
      paste ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\rasters\\boreal\\",
             input$predboreal2055tif,
             ".tiff"
      )
    },
    content <- function (file) {
      file.copy (filename, file)
    }
  )               
 
  output$predboreal2085tif <- downloadHandler (
    filename = function () {
      paste ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\rasters\\boreal\\",
             input$predboreal2085tif,
             ".tiff"
      )
    },
    content <- function (file) {
      file.copy (filename, file)
    }
  )  
}

# Run the application 
shinyApp (ui = ui, server = server)
