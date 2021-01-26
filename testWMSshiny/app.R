library(shiny)
library(leaflet)

ui <- fluidPage(
    titlePanel("Natural Disturbance Types of BC"),
        mainPanel(
            leafletOutput("map", height = 750, width = "83%")
        )
    
)
server <- function(input, output) {
    
    output$map <- renderLeaflet({
        leaflet() %>% 
            setView(lng = -127.287638, lat = 53.7, zoom = 10) %>% 
            addWMSTiles(
                baseUrl = "https://openmaps.gov.bc.ca/geo/wms",
                layers = "pub:WHSE_FOREST_VEGETATION.BEC_NATURAL_DISTURBANCE_SV",
                options = WMSTileOptions(format = "image/png", transparent = TRUE)
            )
    })
}
# Run the application 
shinyApp(ui = ui, server = server)
