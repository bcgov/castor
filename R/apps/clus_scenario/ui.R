#-------------------------------------------------------------------------------------------------
# Define UI
shinyUI(fluidPage(theme = shinytheme("lumen"),  
                titlePanel("CLUS: Scenario Tool"),
                sidebarLayout(
                  sidebarPanel(
                    # add the caribou recovery logo
                    img(src = "clus-logo.png", height = 100, width = 100),
                    helpText("Click map to select a herd"),
                    #Ecotype name
                    h2(textOutput("clickEcoType")),
                    helpText("Ecotype"),
                    #Herd name
                    h2(textOutput("clickCaribou")),
                    helpText("Herd"),
                    radioButtons("queryType", label = h3("Query Options"),
                                 choices = list("Herd Boundary" = 1, "Drawn" = 2), 
                                 selected = 1),
                    sliderInput("sliderBuffer", label = h4("Buffer (m)"), min = 0, 
                                max = 1000, value = 500, step = 20),
                    sliderInput("sliderCutAge", label = h4("Age (year)"), min = 20, 
                                max = 50, value = 40, step = 1)
                  ),
                  
                  # Output: Description, lineplot, and reference
                  mainPanel(
                    leafletOutput("map"),
                    downloadLink("downloadDrawnData", "Download"),
                    helpText("Save drawn polygons"),
                    tabsetPanel(
                      tabPanel("Herd Plan", uiOutput("pdfview")),
                      tabPanel("Population", plotlyOutput(outputId = "carbPopPlot", height = "400px")),
                      tabPanel("Protected Area", navlistPanel(
                          tabPanel("Ungulate Winter Range", tableOutput("uwrTable")),
                          tabPanel("Wildlife Habitat Area", tableOutput("whaTable"))
                          )
                      ),
                      tabPanel("Disturbance", navlistPanel(
                        "Summary", 
                        tabPanel("Fire", plotlyOutput(outputId = "firePlot", height = "400px")),
                        tabPanel("THLB", tableOutput(outputId = "thlbTable")),
                        tabPanel("Cutblock", plotlyOutput(outputId = "cutPlot", height = "400px")),
                        tabPanel("Road", tableOutput("rdTable"))
                      )
                      ),
                      tabPanel("Climate Change", navlistPanel(
                        "BEC", 
                        tabPanel("Proportion", plotlyOutput(outputId = "becPlot", height = "400px")), 
                        "Variables", 
                        tabPanel("Frost Free Days", plotlyOutput(outputId = "ffdPlot", height = "400px")), 
                        tabPanel("Precipitation as Snow", plotlyOutput(outputId = "pasPlot", height = "400px")), 
                        tabPanel("Average Winter Temperature", plotlyOutput(outputId = "awtPlot", height = "400px")
                        )))
                    )
                  )
                )
)
)
