#-------------------------------------------------------------------------------------------------
# Define UI
shinyUI(fluidPage(theme = shinytheme("lumen"),  
                titlePanel("GAR Order Assessment Tool"),
                sidebarLayout(
                  sidebarPanel(
                    # delete if don't want ot put anythign inot a sidebar panel
                  ),
                  
                  # Output: Description, lineplot, and reference
                  mainPanel( # puts the map in the server panel
                    leafletOutput("map"),
                    downloadButton("downloadDrawnData", "Download Drawn/Edited Shapefile"),
                    helpText("Save drawn polygons"),
                    fileInput (inputId = "filemap", # upload shapefile GUI
                               width = "450px",
                               label = "Upload a Shapefile",
                               placeholder = "Please include at a minimum: .shp, .dbf, and .shx files",
                               buttonLabel = "Upload Shapefile",
                               multiple = TRUE,
                               accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj', 'xml')
                    ),
                    tabsetPanel( # creates a set of tabs under the map to put in plots, etc.
                      tabPanel("Disturbance", navlistPanel(
                        "Summary", 
                        tabPanel("THLB", tableOutput(outputId = "thlbTable")),
                        tabPanel("Cutblock", plotlyOutput(outputId = "cutPlot", height = "400px"),
                                 sliderInput("sliderCutAge", label = h4("Age (year)"), min = 20, 
                                             max = 50, value = 40, step = 1)),
                        tabPanel("Road", tableOutput("rdTable"),
                                 sliderInput("sliderBuffer", label = h4("Buffer (m)"), min = 0, 
                                             max = 1000, value = 500, step = 20))
                     )))
                    )
                  )
                )
)

