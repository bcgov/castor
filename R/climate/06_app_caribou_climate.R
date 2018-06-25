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




data.plot.herd.bec <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\data_plot_herd_bec.csv", 
                                    header = T, stringsAsFactors = T, sep = ",")
data.plot.herd.temp <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\data_plot_herd_temp.csv", 
                                     header = T, stringsAsFactors = T, sep = ",")
data.plot.herd.nffd <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\data_plot_herd_nffd.csv", 
                                   header = T, stringsAsFactors = T, sep = ",") 
data.plot.herd.pas <- read.table ("C:\\Work\\caribou\\climate_analysis\\shiny_app\\data\\data_plot_herd_pas.csv", 
                                   header = T, stringsAsFactors = T, sep = ",") 

data.plot.herd.bec$ecotype <- as.character (data.plot.herd.bec$herdname)
data.plot.herd.temp$ecotype <- as.character (data.plot.herd.temp$herdname)
data.plot.herd.nffd$ecotype <- as.character (data.plot.herd.nffd$herdname)
data.plot.herd.pas$ecotype <- as.character (data.plot.herd.pas$herdname)

data.plot.herd.bec$ecotype [data.plot.herd.bec$ecotype == "Chinchaga" | 
                            data.plot.herd.bec$ecotype == 'Prophet' | 
                            data.plot.herd.bec$ecotype == 'Snake-Sahtaneh' |
                            data.plot.herd.bec$ecotype == 'Parker' |
                            data.plot.herd.bec$ecotype == 'Maxhamish' |
                            data.plot.herd.bec$ecotype ==  'Calendar'] <- "Boreal"
data.plot.herd.bec$ecotype [data.plot.herd.bec$ecotype == "South Selkirks" | 
                              data.plot.herd.bec$ecotype == 'Purcells South' | 
                              data.plot.herd.bec$ecotype == 'Nakusp' |
                              data.plot.herd.bec$ecotype == 'Monashee' |
                              data.plot.herd.bec$ecotype == 'Duncan' |
                              data.plot.herd.bec$ecotype == 'Frisby-Boulder' |
                              data.plot.herd.bec$ecotype == "Columbia South" |
                              data.plot.herd.bec$ecotype == 'Columbia North' |
                              data.plot.herd.bec$ecotype == 'Groundhog' | 
                              data.plot.herd.bec$ecotype == 'Central Rockies'|
                              data.plot.herd.bec$ecotype == 'Wells Gray' |
                              data.plot.herd.bec$ecotype == 'Barkerville' |
                              data.plot.herd.bec$ecotype == 'North Cariboo' |
                              data.plot.herd.bec$ecotype == 'Narrow Lake' |
                              data.plot.herd.bec$ecotype == 'Hart Ranges'] <- "Mountain"
data.plot.herd.bec$ecotype [data.plot.herd.bec$ecotype == "Charlotte Alplands" | 
                              data.plot.herd.bec$ecotype == 'Itcha-Ilgachuz' | 
                              data.plot.herd.bec$ecotype == 'Rainbows' |
                              data.plot.herd.bec$ecotype == 'Tweedsmuir' |
                              data.plot.herd.bec$ecotype == 'Hart Ranges' |
                              data.plot.herd.bec$ecotype == 'Narraway' |
                              data.plot.herd.bec$ecotype == "Telkwa" |
                              data.plot.herd.bec$ecotype == 'Quintette' |
                              data.plot.herd.bec$ecotype == 'Takla' | 
                              data.plot.herd.bec$ecotype == 'Kennedy Siding'|
                              data.plot.herd.bec$ecotype == 'Scott' |
                              data.plot.herd.bec$ecotype == 'Wolverine' |
                              data.plot.herd.bec$ecotype == 'Narraway' |
                              data.plot.herd.bec$ecotype == 'Quintette' |
                              data.plot.herd.bec$ecotype == 'Kennedy Siding'|
                              data.plot.herd.bec$ecotype == 'Burnt Pine' |
                              data.plot.herd.bec$ecotype == 'Moberly' |
                              data.plot.herd.bec$ecotype == 'Chase' |
                              data.plot.herd.bec$ecotype == 'Graham' |
                              data.plot.herd.bec$ecotype == 'Finlay' |
                              data.plot.herd.bec$ecotype == 'Spatsizi' |
                              data.plot.herd.bec$ecotype == 'Pink Mountain' |
                              data.plot.herd.bec$ecotype == 'Edziza' |
                              data.plot.herd.bec$ecotype == 'Frog' |
                              data.plot.herd.bec$ecotype == 'Gataga' |
                              data.plot.herd.bec$ecotype == 'Muskwa' |
                              data.plot.herd.bec$ecotype == 'Tsenaglode'|
                              data.plot.herd.bec$ecotype == 'Rabbit' |
                              data.plot.herd.bec$ecotype == 'Prophet' |
                              data.plot.herd.bec$ecotype == 'Level Kawdy' |
                              data.plot.herd.bec$ecotype == 'Horseranch' |
                              data.plot.herd.bec$ecotype == 'Atlin' |
                              data.plot.herd.bec$ecotype == 'Little Rancheria' |
                              data.plot.herd.bec$ecotype == 'Swan Lake' |
                              data.plot.herd.bec$ecotype == 'Liard Plateau'|
                              data.plot.herd.bec$ecotype == 'Carcross'] <- "Northern"
data.plot.herd.bec$ecotype <- as.factor (data.plot.herd.bec$ecotype)

data.plot.herd.temp$ecotype [data.plot.herd.temp$ecotype == "Chinchaga" | 
                              data.plot.herd.temp$ecotype == 'Prophet' | 
                              data.plot.herd.temp$ecotype == 'Snake-Sahtaneh' |
                              data.plot.herd.temp$ecotype == 'Parker' |
                              data.plot.herd.temp$ecotype == 'Maxhamish' |
                              data.plot.herd.temp$ecotype ==  'Calendar'] <- "Boreal"
data.plot.herd.temp$ecotype [data.plot.herd.temp$ecotype == "South Selkirks" | 
                              data.plot.herd.temp$ecotype == 'Purcells South' | 
                              data.plot.herd.temp$ecotype == 'Nakusp' |
                              data.plot.herd.temp$ecotype == 'Monashee' |
                              data.plot.herd.temp$ecotype == 'Duncan' |
                              data.plot.herd.temp$ecotype == 'Frisby-Boulder' |
                              data.plot.herd.temp$ecotype == "Columbia South" |
                              data.plot.herd.temp$ecotype == 'Columbia North' |
                              data.plot.herd.temp$ecotype == 'Groundhog' | 
                              data.plot.herd.temp$ecotype == 'Central Rockies'|
                              data.plot.herd.temp$ecotype == 'Wells Gray' |
                              data.plot.herd.temp$ecotype == 'Barkerville' |
                              data.plot.herd.temp$ecotype == 'North Cariboo' |
                              data.plot.herd.temp$ecotype == 'Narrow Lake' |
                              data.plot.herd.temp$ecotype == 'Hart Ranges'] <- "Mountain"
data.plot.herd.temp$ecotype [data.plot.herd.temp$ecotype == "Charlotte Alplands" | 
                              data.plot.herd.temp$ecotype == 'Itcha-Ilgachuz' | 
                              data.plot.herd.temp$ecotype == 'Rainbows' |
                              data.plot.herd.temp$ecotype == 'Tweedsmuir' |
                              data.plot.herd.temp$ecotype == 'Hart Ranges' |
                              data.plot.herd.temp$ecotype == 'Narraway' |
                              data.plot.herd.temp$ecotype == "Telkwa" |
                              data.plot.herd.temp$ecotype == 'Quintette' |
                              data.plot.herd.temp$ecotype == 'Takla' | 
                              data.plot.herd.temp$ecotype == 'Kennedy Siding'|
                              data.plot.herd.temp$ecotype == 'Scott' |
                              data.plot.herd.temp$ecotype == 'Wolverine' |
                              data.plot.herd.temp$ecotype == 'Narraway' |
                              data.plot.herd.temp$ecotype == 'Quintette' |
                              data.plot.herd.temp$ecotype == 'Kennedy Siding'|
                              data.plot.herd.temp$ecotype == 'Burnt Pine' |
                              data.plot.herd.temp$ecotype == 'Moberly' |
                              data.plot.herd.temp$ecotype == 'Chase' |
                              data.plot.herd.temp$ecotype == 'Graham' |
                              data.plot.herd.temp$ecotype == 'Finlay' |
                              data.plot.herd.temp$ecotype == 'Spatsizi' |
                              data.plot.herd.temp$ecotype == 'Pink Mountain' |
                              data.plot.herd.temp$ecotype == 'Edziza' |
                              data.plot.herd.temp$ecotype == 'Frog' |
                              data.plot.herd.temp$ecotype == 'Gataga' |
                              data.plot.herd.temp$ecotype == 'Muskwa' |
                              data.plot.herd.temp$ecotype == 'Tsenaglode'|
                              data.plot.herd.temp$ecotype == 'Rabbit' |
                              data.plot.herd.temp$ecotype == 'Prophet' |
                              data.plot.herd.temp$ecotype == 'Level Kawdy' |
                              data.plot.herd.temp$ecotype == 'Horseranch' |
                              data.plot.herd.temp$ecotype == 'Atlin' |
                              data.plot.herd.temp$ecotype == 'Little Rancheria' |
                              data.plot.herd.temp$ecotype == 'Swan Lake' |
                              data.plot.herd.temp$ecotype == 'Liard Plateau'|
                              data.plot.herd.temp$ecotype == 'Carcross'] <- "Northern"
data.plot.herd.temp$ecotype <- as.factor (data.plot.herd.temp$ecotype)

data.plot.herd.nffd$ecotype [data.plot.herd.nffd$ecotype == "Chinchaga" | 
                               data.plot.herd.nffd$ecotype == 'Prophet' | 
                               data.plot.herd.nffd$ecotype == 'Snake-Sahtaneh' |
                               data.plot.herd.nffd$ecotype == 'Parker' |
                               data.plot.herd.nffd$ecotype == 'Maxhamish' |
                               data.plot.herd.nffd$ecotype ==  'Calendar'] <- "Boreal"
data.plot.herd.nffd$ecotype [data.plot.herd.nffd$ecotype == "South Selkirks" | 
                               data.plot.herd.nffd$ecotype == 'Purcells South' | 
                               data.plot.herd.nffd$ecotype == 'Nakusp' |
                               data.plot.herd.nffd$ecotype == 'Monashee' |
                               data.plot.herd.nffd$ecotype == 'Duncan' |
                               data.plot.herd.nffd$ecotype == 'Frisby-Boulder' |
                               data.plot.herd.nffd$ecotype == "Columbia South" |
                               data.plot.herd.nffd$ecotype == 'Columbia North' |
                               data.plot.herd.nffd$ecotype == 'Groundhog' | 
                               data.plot.herd.nffd$ecotype == 'Central Rockies'|
                               data.plot.herd.nffd$ecotype == 'Wells Gray' |
                               data.plot.herd.nffd$ecotype == 'Barkerville' |
                               data.plot.herd.nffd$ecotype == 'North Cariboo' |
                               data.plot.herd.nffd$ecotype == 'Narrow Lake' |
                               data.plot.herd.nffd$ecotype == 'Hart Ranges'] <- "Mountain"
data.plot.herd.nffd$ecotype [data.plot.herd.nffd$ecotype == "Charlotte Alplands" | 
                               data.plot.herd.nffd$ecotype == 'Itcha-Ilgachuz' | 
                               data.plot.herd.nffd$ecotype == 'Rainbows' |
                               data.plot.herd.nffd$ecotype == 'Tweedsmuir' |
                               data.plot.herd.nffd$ecotype == 'Hart Ranges' |
                               data.plot.herd.nffd$ecotype == 'Narraway' |
                               data.plot.herd.nffd$ecotype == "Telkwa" |
                               data.plot.herd.nffd$ecotype == 'Quintette' |
                               data.plot.herd.nffd$ecotype == 'Takla' | 
                               data.plot.herd.nffd$ecotype == 'Kennedy Siding'|
                               data.plot.herd.nffd$ecotype == 'Scott' |
                               data.plot.herd.nffd$ecotype == 'Wolverine' |
                               data.plot.herd.nffd$ecotype == 'Narraway' |
                               data.plot.herd.nffd$ecotype == 'Quintette' |
                               data.plot.herd.nffd$ecotype == 'Kennedy Siding'|
                               data.plot.herd.nffd$ecotype == 'Burnt Pine' |
                               data.plot.herd.nffd$ecotype == 'Moberly' |
                               data.plot.herd.nffd$ecotype == 'Chase' |
                               data.plot.herd.nffd$ecotype == 'Graham' |
                               data.plot.herd.nffd$ecotype == 'Finlay' |
                               data.plot.herd.nffd$ecotype == 'Spatsizi' |
                               data.plot.herd.nffd$ecotype == 'Pink Mountain' |
                               data.plot.herd.nffd$ecotype == 'Edziza' |
                               data.plot.herd.nffd$ecotype == 'Frog' |
                               data.plot.herd.nffd$ecotype == 'Gataga' |
                               data.plot.herd.nffd$ecotype == 'Muskwa' |
                               data.plot.herd.nffd$ecotype == 'Tsenaglode'|
                               data.plot.herd.nffd$ecotype == 'Rabbit' |
                               data.plot.herd.nffd$ecotype == 'Prophet' |
                               data.plot.herd.nffd$ecotype == 'Level Kawdy' |
                               data.plot.herd.nffd$ecotype == 'Horseranch' |
                               data.plot.herd.nffd$ecotype == 'Atlin' |
                               data.plot.herd.nffd$ecotype == 'Little Rancheria' |
                               data.plot.herd.nffd$ecotype == 'Swan Lake' |
                               data.plot.herd.nffd$ecotype == 'Liard Plateau'|
                               data.plot.herd.nffd$ecotype == 'Carcross'] <- "Northern"
data.plot.herd.nffd$ecotype <- as.factor (data.plot.herd.nffd$ecotype)

data.plot.herd.pas$ecotype [data.plot.herd.pas$ecotype == "Chinchaga" | 
                               data.plot.herd.pas$ecotype == 'Prophet' | 
                               data.plot.herd.pas$ecotype == 'Snake-Sahtaneh' |
                               data.plot.herd.pas$ecotype == 'Parker' |
                               data.plot.herd.pas$ecotype == 'Maxhamish' |
                               data.plot.herd.pas$ecotype ==  'Calendar'] <- "Boreal"
data.plot.herd.pas$ecotype [data.plot.herd.pas$ecotype == "South Selkirks" | 
                               data.plot.herd.pas$ecotype == 'Purcells South' | 
                               data.plot.herd.pas$ecotype == 'Nakusp' |
                               data.plot.herd.pas$ecotype == 'Monashee' |
                               data.plot.herd.pas$ecotype == 'Duncan' |
                               data.plot.herd.pas$ecotype == 'Frisby-Boulder' |
                               data.plot.herd.pas$ecotype == "Columbia South" |
                               data.plot.herd.pas$ecotype == 'Columbia North' |
                               data.plot.herd.pas$ecotype == 'Groundhog' | 
                               data.plot.herd.pas$ecotype == 'Central Rockies'|
                               data.plot.herd.pas$ecotype == 'Wells Gray' |
                               data.plot.herd.pas$ecotype == 'Barkerville' |
                               data.plot.herd.pas$ecotype == 'North Cariboo' |
                               data.plot.herd.pas$ecotype == 'Narrow Lake' |
                               data.plot.herd.pas$ecotype == 'Hart Ranges'] <- "Mountain"
data.plot.herd.pas$ecotype [data.plot.herd.pas$ecotype == "Charlotte Alplands" | 
                               data.plot.herd.pas$ecotype == 'Itcha-Ilgachuz' | 
                               data.plot.herd.pas$ecotype == 'Rainbows' |
                               data.plot.herd.pas$ecotype == 'Tweedsmuir' |
                               data.plot.herd.pas$ecotype == 'Hart Ranges' |
                               data.plot.herd.pas$ecotype == 'Narraway' |
                               data.plot.herd.pas$ecotype == "Telkwa" |
                               data.plot.herd.pas$ecotype == 'Quintette' |
                               data.plot.herd.pas$ecotype == 'Takla' | 
                               data.plot.herd.pas$ecotype == 'Kennedy Siding'|
                               data.plot.herd.pas$ecotype == 'Scott' |
                               data.plot.herd.pas$ecotype == 'Wolverine' |
                               data.plot.herd.pas$ecotype == 'Narraway' |
                               data.plot.herd.pas$ecotype == 'Quintette' |
                               data.plot.herd.pas$ecotype == 'Kennedy Siding'|
                               data.plot.herd.pas$ecotype == 'Burnt Pine' |
                               data.plot.herd.pas$ecotype == 'Moberly' |
                               data.plot.herd.pas$ecotype == 'Chase' |
                               data.plot.herd.pas$ecotype == 'Graham' |
                               data.plot.herd.pas$ecotype == 'Finlay' |
                               data.plot.herd.pas$ecotype == 'Spatsizi' |
                               data.plot.herd.pas$ecotype == 'Pink Mountain' |
                               data.plot.herd.pas$ecotype == 'Edziza' |
                               data.plot.herd.pas$ecotype == 'Frog' |
                               data.plot.herd.pas$ecotype == 'Gataga' |
                               data.plot.herd.pas$ecotype == 'Muskwa' |
                               data.plot.herd.pas$ecotype == 'Tsenaglode'|
                               data.plot.herd.pas$ecotype == 'Rabbit' |
                               data.plot.herd.pas$ecotype == 'Prophet' |
                               data.plot.herd.pas$ecotype == 'Level Kawdy' |
                               data.plot.herd.pas$ecotype == 'Horseranch' |
                               data.plot.herd.pas$ecotype == 'Atlin' |
                               data.plot.herd.pas$ecotype == 'Little Rancheria' |
                               data.plot.herd.pas$ecotype == 'Swan Lake' |
                               data.plot.herd.pas$ecotype == 'Liard Plateau'|
                               data.plot.herd.pas$ecotype == 'Carcross'] <- "Northern"
data.plot.herd.pas$ecotype <- as.factor (data.plot.herd.pas$ecotype)

data.plot.herd.bec$year <- as.factor (data.plot.herd.bec$year)
data.plot.herd.temp$year <- as.factor (data.plot.herd.temp$year)
data.plot.herd.nffd$year <- as.factor (data.plot.herd.nffd$year)
data.plot.herd.pas$year <- as.factor (data.plot.herd.pas$year)

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
