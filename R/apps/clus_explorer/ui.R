
ui <- dashboardPage(skin = "black",
  dashboardHeader(title = "CLUS: Explorer Tool"
                 ),
  dashboardSidebar(    
    sidebarMenu(
      menuItem("Settings", tabName = "settings", icon = icon("gears")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"),
        menuSubItem("Caribou", tabName = "caribou", icon = icon("paw")),
        menuSubItem("Climate", tabName = "climate", icon = icon("thermometer-half")),
        menuSubItem("Fire", tabName = "fire", icon = icon("fire")),
        menuSubItem("Forestry", tabName = "forestry", icon = icon("tree")),
        menuSubItem("Insects (planned)", tabName = "insects", icon = icon("bug")),
        menuSubItem("Mining (planned)", tabName = "mining", icon = icon("industry")),
        menuSubItem("Oil and Gas (planned)", tabName = "oilandgas", icon = icon("bolt")),
        menuSubItem("Recreation (planned)", tabName = "recreation", icon = icon("shoe-prints"))
        ), 
      menuItem("Query Builder", tabName = "querybuilder", icon = icon("search")),
      menuItem("Map Viewer", tabName = "mapviewer", icon = icon("layer-group"))
    )
  ),
  dashboardBody(
   #tags$style(type = "text/css", "a{color: #090909;}"),
    tabItems(
      tabItem(tabName = "settings",
          fluidRow(
            box(title = "Area of interest", background = "black", solidHeader = TRUE,
                "select an area of interest",
                selectInput(inputId = "schema", label = NULL, 
                            choices = availStudyAreas, selected = character(0)))
            ),
          fluidRow(
            box(title = "Scenarios", background = "black", solidHeader = TRUE,
                "select the scenarios you wish to compare",
                checkboxGroupInput(inputId ="scenario", label = NULL ),
                tableOutput("scenarioDescription")
            )
          )
      ),
      tabItem(tabName = "querybuilder",
        fluidRow( #Table query
          box(title = "Table Query", background = "black", solidHeader = TRUE,
                    #em("SELECT",style="color:#090909;font-size:80%")
              selectInput(inputId = "queryTable", label = "FROM TABLE:", choices = c("scenarios", "harvest", "rsf",  "growingstock", "survival" ), selected = character(0)),
              fluidRow(
                column(width = 6, textInput(inputId= "queryWHERE", label = "Where")),
                column(width = 6, selectInput(inputId= "queryColumns", label = "Columns", choices = NULL))
              ),
              fluidRow(
                column(width = 6, selectInput(inputId= "queryRows", label = "Rows", choices = NULL)),
                column(width = 6, selectInput(inputId= "queryValue", label = "Values", choices =c("SUM", "AVG", "COUNT"), selected = character(0)))
              )
            ),
            dataTableOutput("resultSetTable")
          )
      ),
      tabItem(tabName = "mapviewer",
        fluidRow(#Raster query
          box(title = "Map Query",  collapsible = T, background = "black", solidHeader = TRUE, width = 10,
            selectInput("maplayers", label = "Available Layers", multiple = TRUE, choices = NULL),
            actionButton("getMapLayersButton", "Load")
          )
      ),
        leafletOutput("resultSetRaster", height = 750, width = "83%")     
      ),
      tabItem(tabName = "caribou",
        fluidRow(
          valueBox("BAU", "Disturbance", icon = icon("paw"), color = "purple"),
          valueBox("BAU", "Survival", icon = icon("paw"), color = "purple"),
          valueBox("BAU", "RSF", icon = icon("paw"), color = "purple")
          ),
        fluidRow(
          box(title = "Proportion Disturbed", collapsible = TRUE, solidHeader = TRUE, background = "purple", width =12,
              plotlyOutput(outputId = "propAgePlot", height = "400px"))
        ),
        fluidRow(
          box(title = "Survival", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
            plotlyOutput(outputId = "survivalPlot", height = "400px"))
          ),
        fluidRow(
          box(title = "Resource Selection", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
              plotlyOutput(outputId = "rsfPlot", height = "400px"))
        )
      ),
      tabItem(tabName = "forestry",
        fluidRow(
          valueBox("BAU", "Acheiving AAC", icon = icon("tree"), color = "green"),
          valueBox("BAU", "Area Harvested", icon = icon("tree"), color = "green"),
          valueBox("BAU", "Volume Harvested", icon = icon("tree"), color = "green")
        ),
        fluidRow(
          box(title = "Harvest Flow", collapsible = TRUE, solidHeader = TRUE,background = "green", width =12,
            plotlyOutput(outputId = "harvestAreaPlot", height = "400px"),
            plotlyOutput(outputId = "harvestVolumePlot", height = "400px")
          )
        ),
        fluidRow(
          box(title = "Growingstock", collapsible = TRUE,  collapsed = TRUE, solidHeader = TRUE,background = "green", width =12,
            plotlyOutput(outputId = "growingStockPlot", height = "400px")
          )
        )
      ),
      tabItem(tabName = "fire",
        fluidRow(
            valueBox("0", "Fires", icon = icon("fire"), color = "red"),
            valueBox("0", "Area Burnt", icon = icon("fire"), color = "red"),
            valueBox("0", "Volume Burnt", icon = icon("fire"), color = "red")
          )
      ),
      tabItem(tabName = "insects",
        fluidRow(
            valueBox("0", "Outbreaks", icon = icon("bug"), color = "teal"),
            valueBox("0", "Area spread", icon = icon("bug"), color = "teal"),
            valueBox("0", "Volume Lost", icon = icon("bug"), color = "teal")
        )
      ),
      tabItem(tabName = "climate",
        box(title = "Conceptual Path Diagram", width=12, background = "yellow", solidHeader = TRUE, collapsible = TRUE,
        plotOutput(outputId = "climatemap", height = "800px")
        ),
        box(title = "Modelled Path Diagram", width=12, background = "yellow", solidHeader = TRUE, collapsible = TRUE, collapsed = TRUE
        )
      ),
      tabItem(tabName = "oilandgas",
        fluidRow(
            valueBox("BAU", "Footprint", icon = icon("bolt"), color = "navy"),
            valueBox("0", "Jobs", icon = icon("bolt"), color = "navy"),
            valueBox("0", "GDP", icon = icon("bolt"), color = "navy")
        )
      ),
      tabItem(tabName = "mining",
        fluidRow(
            valueBox("BAU", "Footprint", icon = icon("industry"), color = "navy"),
            valueBox("0", "Jobs", icon = icon("industry"), color = "navy"),
            valueBox("0", "GDP", icon = icon("industry"), color = "navy")
          )
      ),
      tabItem(tabName = "recreation",
        fluidRow(
            valueBox("BAU", "Footprint", icon = icon("shoe-prints"), color = "aqua"),
            valueBox("0", "Jobs", icon = icon("shoe-prints"), color = "aqua"),
            valueBox("0", "GDP", icon = icon("shoe-prints"), color = "aqua")
        )
      )
    )
  )
)