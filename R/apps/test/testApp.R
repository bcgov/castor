# Load packages
library(shiny)
library(shinythemes)
library(dplyr)
library(readr)
library(ggplot2)
#install.packages('bcmaps.rdata', repos='https://bcgov.github.io/drat/')
library(bcmaps)
library(leaflet)

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


# Define UI
ui <- fluidPage(theme = shinytheme("lumen"),
                titlePanel("Historical human disturbance and caribou"),
                sidebarLayout(
                    sidebarPanel(
                      # add the caribou recovery logo
                      img(src = "clus-logo.png", height = 100, width = 150),
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
      leafletOutput("mymap"),
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
        as.Date(date) > as.POSIXct(input$date[1]) & as.Date(date) < as.POSIXct(input$date[2])
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
  
  output$mymap <- renderLeaflet({
    m <- leaflet() %>%
      addTiles() %>%
      setView(lng=-127.6476, lat=53.7267 , zoom=5) #%>%
      #addRasterImage(raster(), colors = pal, opacity = 0.8) %>%
      #addLegend(pal = pal, values = values(r),
       #         title = "Surface temp")
    m
  })
  
}

# Create Shiny object
shinyApp(ui = ui, server = server)
