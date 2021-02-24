library(leaflet)
library(shiny)
ui <- fluidPage(
  titlePanel("Hello Shiny!"),
  sidebarLayout(
    sidebarPanel(),
    mainPanel(
      leafletOutput("map", height = 750, width = "83%")
    )
  )
)
server <- function(input, output) {
  
  output$resultSetRaster <- renderLeaflet({
    leaflet() %>% 
      setView(lng = -127.287638, lat = 53.7, zoom = 8) %>% 
      addWMSTiles(
        baseUrl = "https://openmaps.gov.bc.ca/geo/wms",
        layers = "pub:WHSE_FOREST_VEGETATION.BEC_NATURAL_DISTURBANCE_SV",
        options = WMSTileOptions(format = "image/png", transparent = TRUE)
      )
  })
    
  }