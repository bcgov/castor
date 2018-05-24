# Load packages
library(shiny)
library(shinythemes)
library(dplyr)
library(readr)
library(ggplot2)
# Load data
#trend_data <- read_csv("data/trend_data.csv")
date<-format(seq(as.Date("01/01/2007", "%m/%d/%Y"), as.Date("01/30/2007", "%m/%d/%Y"), by = "1 day"))

trend_data <- data.frame(rbind(cbind(as.numeric(rnorm(30,0,1)), date , "test"),cbind(as.numeric(rnorm(30,0,1)), date , "test1")))
names(trend_data)<-c("close","date", "type")
trend_data$close<-as.numeric(trend_data$close)
trend_data$date<-as.Date(trend_data$date)
str(trend_data)


trend_description <- "This is a test"

# Define UI
ui <- fluidPage(theme = shinytheme("lumen"),
                titlePanel("Sample Shiny App"),
                sidebarLayout(
                  sidebarPanel(
                    
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
  plotOutput(outputId = "lineplot", height = "300px"),
  textOutput(outputId = "desc"),
  tags$a(href = "https://www2.gov.bc.ca/", "Source: Gov BC", target = "_blank")
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
  
  # Pull in description of trend
  output$desc <- renderText({
    trend_text <- filter(trend_description, type == input$type) %>% pull(text)
    paste(trend_text, "The index is set to 1.0 on January 1, 2004 and is calculated only for US search traffic.")
  })
}

# Create Shiny object
shinyApp(ui = ui, server = server)
