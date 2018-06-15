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

# Load data
#trend_data <- read_csv("data/trend_data.csv")
date<-format(seq(as.Date("01/01/2007", "%m/%d/%Y"), as.Date("01/30/2007", "%m/%d/%Y"), by = "1 day"))

trend_data <- data.frame(rbind(cbind(as.numeric(rnorm(30,0,1)), date , "test"),cbind(as.numeric(rnorm(30,0,1)), date , "test1")))
names(trend_data)<-c("close","date", "type")
trend_data$close<-as.numeric(trend_data$close)
trend_data$date<-as.Date(trend_data$date)
#check the data frame
#str(trend_data)
trend_description <- "This is a test"
#-------------------------------------------------------------------------------------------------


# Define UI
ui <- fluidPage(theme = shinytheme("lumen"),
                titlePanel("Historical human disturbance in caribou herds"),
                sidebarLayout(
                    sidebarPanel(
                      # add the caribou recovery logo
                      img(src = "clus-logo.png", height = 100, width = 100),
                      verbatimTextOutput("clickInfo"),
                      # Select type of trend to plot
                      selectInput(inputId = "type", label = strong("Select data"),
                                choices = unique(trend_data$type),
                                selected = "test"),
                      # Select date range to be plotted
                      dateRangeInput("date", strong("Date range"), start = "2007-01-01", end = "2007-01-05",
                                                                    min = "2007-01-01", max = "2007-01-30"),

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
    req(input$date)
    validate(need(!is.na(input$date[1]) & !is.na(input$date[2]), "Error: Please provide both a start and an end date."))
    validate(need(input$date[1] < input$date[2], "Error: Start date should be earlier than end date."))
    trend_data %>%
      filter(
        type == input$type,
        date > input$date[1] & date < input$date[2]
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
    plot(x = selected_trends()$date, y = selected_trends()$close, type = "l",
         xlab = "Date", ylab = "Y~N(0,1)", col = color, fg = color, col.lab = color, col.axis = color)
    # Display only if smoother is checked
    if(input$smoother){
      smooth_curve <- lowess(x = as.numeric(selected_trends()$date), y = selected_trends()$close, f = input$f)
      lines(smooth_curve, col = "#E6553A", lwd = 3)
    }
  })
  
  #Create the map object
  ###get data from postgres parameters
  dbname = 'ima'
  host='localhost'
  port='5432'
  user='postgres'
  password='postgres'
  #C("schema", "tbl_name")
  name=c("gisdata","gcbp_carib_polygon")
  geom = "geom"

  #-------------------------------------------------------------------------------------------------
  ##Get a connection to the postgreSQL server
  conn<-dbConnect("PostgreSQL",dbname=dbname, host=host ,port=port ,user=user ,password=password)
  ##Import a shapefile from the postgres server 
  #my_spdf<-pgGetGeom(conn, name=name,  geom = geom)
  my_spdf.2 <- spTransform(pgGetGeom(conn, name=name,  geom = geom), CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
  my_spdf.2  <- my_spdf.2[which(my_spdf.2@data$herd_name != "NA"), ]
  #close connection
  dbDisconnect(conn)
 
  #set the pallet
  pal <- colorFactor(palette = c("lightblue", "darkblue", "red"),  my_spdf.2$risk_stat)
  
  output$map = renderLeaflet({ 
      leaflet(my_spdf.2) %>% 
      setView(-121.7476, 53.7267, 4) %>%
      addTiles() %>% 
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
      addPolygons(data=my_spdf.2,  fillColor = ~pal(risk_stat), 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~gid,
                  group= ~herd_name,
                  smoothFactor = 0.5,
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addLayersControl(baseGroups = c("WorldImagery","OpenStreetMap"), options = layersControlOptions(collapsed = FALSE)) %>%
      addMeasure(position = "topleft") %>%
      addScaleBar(position = "bottomright") %>%
      addEasyButton(easyButton(icon="fa-globe", title="Zoom to Level 1", onClick=JS("function(btn, map){ map.setZoom(4); }"))) %>%
      addLegend("bottomright", pal = pal, values = c("Red/Threatened","Blue/Special","Blue/Threatened"), title = "Risk Status", opacity = 1)
  })
  
  observe({
    click <- input$map_shape_click
    if(is.null(click))
      return()
    mapInd2 <- my_spdf.2[which(my_spdf.2@data$herd_name == my_spdf.2[which(my_spdf.2@data$gid == click$id), ]$herd_name), ]
    leafletProxy("map") %>%
      clearShapes() %>%
      addPolygons(data=my_spdf.2,  fillColor = ~pal(risk_stat), 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~gid,
                  group= ~herd_name,
                  smoothFactor = 0.5,
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addPolygons(data = mapInd2,
                  fillColor = "grey", layerId = ~gid, group= ~herd_name,
                  weight = 4,opacity = 0.7, color = "yellow", dashArray = "1", fillOpacity = 0.2,
                  smoothFactor = 0.9) %>%
      setView(lng = click$lng,lat = click$lat, zoom = 7.4)
    
   
  })
  
  observeEvent(input$map_shape_click, {
    
    click<-input$map_shape_click
    output$clickInfo <- renderPrint(my_spdf.2[which(my_spdf.2@data$gid == click$id), ]$herd_name)
  }) 
  
}

# Create Shiny object
shinyApp(ui = ui, server = server)
