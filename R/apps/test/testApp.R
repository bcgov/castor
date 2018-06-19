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

# Load packages
library(shiny)
library(shinythemes)
library(dplyr)
library(readr)
library(ggplot2)
#install.packages('bcmaps.rdata', repos='https://bcgov.github.io/drat/')
library(bcmaps)
library(leaflet)
library(rpostgis)
library(sf)
library(sp)
library(leaflet.extras)
# Load data
#trend_data <- read_csv("data/trend_data.csv")
date<-format(seq(as.Date("01/01/2007", "%m/%d/%Y"), as.Date("01/30/2007", "%m/%d/%Y"), by = "1 day"))

trend_data <- data.frame(rbind(cbind(as.numeric(rnorm(30,0,1)), date , "cutblock"),cbind(as.numeric(rnorm(30,0,1)), date , "road")))
names(trend_data)<-c("close","date", "type")
trend_data$close<-as.numeric(trend_data$close)
trend_data$date<-as.Date(trend_data$date)
#check the data frame
#str(trend_data)
trend_description <- "This is a test"

#-------------------------------------------------------------------------------------------------
#Dataabse prep
#-------------------------------------------------------------------------------------------------
dbname = 'postgres'
host="DC052586"
port='5432'
user='postgres'
password='postgres'
name=c("public","cns_cut_bl_polygon")
##Get a connection to the postgreSQL server (local instance)
conn<-dbConnect(dbDriver("PostgreSQL"), host=host, dbname = dbname, port=port ,user=user ,password=password)

##Data objects
###Get disturbance summary
###Get shapefile
name=c("public","gcbp_carib_polygon")
geom = "geom"
my_spdf.2 <- spTransform(pgGetGeom(conn, name=name,  geom = geom), CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
####Remove NA's
my_spdf.2  <- my_spdf.2[which(my_spdf.2@data$herd_name != "NA"), ]
###close connection
dbDisconnect(conn)

#Resulting objects: 
#my_spdf.2 (a shapfile of herd locations) 
#-------------------------------------------------------------------------------------------------

# Define UI
ui <- fluidPage(theme = shinytheme("lumen"),
                titlePanel("Caribou and Land Use Simulator: historical anthropogenic disturbance"),
                sidebarLayout(
                    sidebarPanel(
                      # add the caribou recovery logo
                      img(src = "clus-logo.png", height = 100, width = 100),
                      helpText("Click map to select a herd"),
                      verbatimTextOutput("clickInfo"),
                      # Select type of trend to plot
                      selectInput(inputId = "type", label = strong("Select disturbance"),
                                choices = c("cutblock", "road", "all"),
                                selected = "cutblock"),
                      
                      # Select year range to be used
                      sliderInput("sliderDate", label = strong("Disturbance year"), min = 1950, 
                                  max = 2018, value = c(1950,2018)),

                      # Select whether to overlay smooth trend line
                      checkboxInput(inputId = "smoother", label = strong("Overlay smooth trend line"), value = FALSE),

                      # Display only if the smoother is checked
                      conditionalPanel(condition = "input.smoother == true",
                            sliderInput(inputId = "f", label = "Smoother span:",
                                 min = 0.01, max = 1, value = 0.67, step = 0.01,
                                    animate = animationOptions(interval = 100)),
                              HTML("Higher values give more smoothness.")
                                       )
),

# Output: Description, lineplot, and reference
mainPanel(
      leafletOutput("map"),
      plotOutput(outputId = "lineplot", height = "300px"),
      textOutput(outputId = "desc"),
      tags$a(href = "https://github.com/bcgov/clus", "Source: clus repo", target = "_blank")
        )
        )
)

# Define server function
server <- function(input, output) {
  
  # Subset data
  selected_trends <- reactive({
    req(input$sliderDate)
    req(input$map_shape_click)
    conn<-dbConnect(dbDriver("PostgreSQL"),dbname=dbname, host=host ,port=port ,user=user ,password=password)
    sql.str = paste0(
      "SELECT SUM(t.areaha) AS SumArea, t.herd_name ,t.harvestyr
    FROM (
      SELECT b.areaha, b.harvestyr, y.herd_name
      FROM public.cns_cut_bl_polygon b, (SELECT * FROM public.gcbp_carib_polygon WHERE herd_name = '",as.character(input$map_shape_click$group), "') y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom))t
      GROUP BY harvestyr, herd_name
      ORDER BY  herd_name, harvestyr")
    cb_sum<-dbGetQuery(conn, sql.str)
    dbDisconnect(conn)
      cb_sum %>%
      filter(
        harvestyr >= input$sliderDate[1] & harvestyr < input$sliderDate[2]
        )
  })
  
  datasetInput <- reactive({
    switch(input$type,
           "test1" = test1,
           "test" = test)
  }) 
  
  # Create scatterplot object the plotOutput function is expecting
  output$lineplot <- renderPlot({
    color = "#434343"
    par(mar = c(4, 4, 1, 1))
    plot(x = selected_trends()$harvestyr, y = selected_trends()$sumarea, type = "l",
         xlab = "Harvest Year", ylab = "Cutblock Area (ha)", col = color, fg = color, col.lab = color, col.axis = color)
    # Display only if smoother is checked
    if(input$smoother){
      smooth_curve <- lowess(x = as.numeric(selected_trends()$harvestyr), y = selected_trends()$sumarea, f = input$f)
      lines(smooth_curve, col = "#E6553A", lwd = 3)
    }
  })
  
  
  #set the pallet
  pal <- colorFactor(palette = c("lightblue", "darkblue", "red"),  my_spdf.2$risk_stat)
  
  output$map = renderLeaflet({ 
      leaflet(my_spdf.2,options = leafletOptions(doubleClickZoom= TRUE)) %>% 
      setView(-121.7476, 53.7267, 4) %>%
      addTiles() %>% 
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
      addPolygons(data=my_spdf.2,  fillColor = ~pal(risk_stat), 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~gid,
                  group= ~herd_name,
                  smoothFactor = 0.5,
                   label = ~herd_name,
                   labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery"), options = layersControlOptions(collapsed = FALSE)) %>%
      addScaleBar(position = "bottomright") %>%
      addResetMapButton() %>%
      addLegend("bottomright", pal = pal, values = c("Red/Threatened","Blue/Special","Blue/Threatened"), title = "Risk Status", opacity = 1) %>%
      addDrawToolbar(
            targetGroup='Selected',
            circleOptions = F,
            rectangleOptions = F,
            polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0
                                                                        ,color = 'white'
                                                                        ,weight = 3))) %>%
      addControl(html = actionButton("addSpatialFile", "", icon = icon("plus")), position = "topleft")
  })
  
  observe({
    click <- input$map_shape_click
    if(is.null(click))
      return()
    print(click$group)
    mapSelect <-  my_spdf.2[which(my_spdf.2@data$herd_name == click$group), ] 
    
    leafletProxy("map") %>%
      clearShapes() %>%
      addPolygons(data=my_spdf.2,  fillColor = ~pal(risk_stat), 
                    weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                   layerId = ~gid,
                   group= ~herd_name,
                   label = ~herd_name,
                   labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , textsize='13px'),
                  smoothFactor = 0.5,
                   highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.1, bringToFront = TRUE)) %>%
      clearGroup(group = input$map_shape_click$group) %>%
      setView(lng = click$lng,lat = click$lat, zoom = 7.4) %>%
      addPolygons(data=mapSelect , fillOpacity = 0.1, color = "red", weight =4,labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , textsize='13px'))
    })
  
  observeEvent(input$map_shape_click, {
    click<-input$map_shape_click
    output$clickInfo <- renderText(click$group)
  }) 
  
  observeEvent(input$addSpatialFile, {
    output$container <- renderUI({
      renderText("test")
    })
    
    })
  
  
  
}

# Create Shiny object
shinyApp(ui = ui, server = server)
