#-------------------------------------------------------------------------------------------------
# Define UI
# UI is user interface; think of this as the code to create the app GUI
# some elements of the GUI, e.g., sliderInput, are inputs into the 'server' code


# some libraries you'll need
require (shinythemes)
require (leaflet)
require (leaflet.extras)

shinyUI(fluidPage(theme = shinytheme("lumen"),  
                titlePanel("GAR Order Assessment Tool"),
                sidebarLayout(
                  sidebarPanel(
                    radioButtons("queryType", label = h3("Query Options"),
                                 choices = list("WHA Boundary" = 1, 
                                                "Drawn/Edited Shapefile" = 2), 
                                 selected = 1)
                  ),
                  
                  # Output: Description, lineplot, and reference
                  mainPanel( # puts the map in the server panel
                    leafletOutput("map"),
                    downloadButton("downloadDrawnData", "Download Drawn/Edited Shapefile"),
                    helpText("Save drawn polygons"),
                    fileInput (inputId = "filemap", # upload shapefile GUI
                               width = "450px",
                               label = "Upload a Shapefile",
                               placeholder = "Must include: .shp, .dbf, .prj and .shx files",
                               buttonLabel = "Upload Shapefile",
                               multiple = TRUE,
                               accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj', 'xml')
                    ),
                    tabsetPanel( # creates a set of tabs under the map to put in plots, etc.
                      tabPanel("Disturbance", navlistPanel(
                        "Summary", 
                        
                        tabPanel("Road", tableOutput("rdTable"),
                                 sliderInput("sliderBuffer", label = h4("Buffer (m)"), min = 0, 
                                             max = 1000, value = 500, step = 20))
                     )))
                    )
                  )
                )
)

