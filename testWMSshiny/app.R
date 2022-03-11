library(shiny)
library(leaflet)
library(tibble)
library(rgdal)
#fetas<<-st_read(paste0(here::here(),"/testWMSshiny/www/feta_v0.shp"))
#fetas.proj<-st_transform(fish.constraints.columbia, 4326)
#st_write(fetas.proj, "fetas.geojson")
#res <- readOGR(dsn = paste0(here::here(),"/fetas.geojson"), layer = "OGRGeoJSON")

ui <- fluidPage(
    titlePanel("Natural Disturbance Types of BC"),
        mainPanel(
            leafletOutput("map", height = 750, width = "100%")
        )
    
)
server <- function(input, output) {
    
    output$map <- renderLeaflet({
        #leaflet() %>% 
        #    setView(lng = -127.287638, lat = 53.7, zoom = 10) %>% 
         #   addWMSTiles(
         #       baseUrl = "https://openmaps.gov.bc.ca/geo/wms",
         #       layers = "pub:WHSE_FOREST_VEGETATION.BEC_NATURAL_DISTURBANCE_SV",
         #       options = WMSTileOptions(format = "image/png", transparent = TRUE)
          #  )%>%
            
         #   addGeoJSON(topoData)
            
        
        leaflet() %>%
            addTiles() %>%
            #setView(-77.0369, 38.9072, 11) %>%
            setView(-121.7476, 53.7267, 6) %>%
            addWMS(
                       baseUrl = "https://openmaps.gov.bc.ca/geo/wms",
                       layers = "pub:WHSE_FOREST_VEGETATION.BEC_NATURAL_DISTURBANCE_SV",
                       options = WMSTileOptions(format = "image/png", transparent = TRUE)
                  )%>%
                
            addBootstrapDependency() %>%
            enableMeasurePath() %>%
            addGeoJSONChoropleth(
                geoJson2,
                #valueProperty = "AREASQMI",
                valueProperty = "abund",
                scale = c("white", "red"),
                mode = "q",
                steps = 4,
                padding = c(0.2, 0),
                labelProperty = "NAME",
                popupProperty = propstoHTMLTable(
                    #props = c("NAME", "AREASQMI", "REP_NAME", "WEB_URL", "REP_PHONE", "REP_EMAIL", "REP_OFFICE"),
                    props = c("fid", "thlb", "hab_den"),
                    table.attrs = list(class = "table table-striped table-bordered"),
                    drop.na = TRUE
                ),
                color = "#ffffff", weight = 1, fillOpacity = 0.7,
                highlightOptions = highlightOptions(
                    weight = 2, color = "#000000",
                    fillOpacity = 1, opacity = 1,
                    bringToFront = TRUE, sendToBack = TRUE),
                pathOptions = pathOptions(
                    showMeasurements = TRUE,
                    measurementOptions = measurePathOptions(imperial = TRUE)))
    })
}
# Run the application 
shinyApp(ui = ui, server = server)
