
ui <- dashboardPage(skin = "black",
  dashboardHeader(title = "CLUS: Explorer Tool"),
  dashboardSidebar( 
    #shinyjs::useShinyjs(),
    sidebarMenu(
      menuItem("Settings", tabName = "settings", icon = icon("gears")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"),
        menuSubItem("Summary", tabName = "summary", icon = icon("balance-scale")),
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
          sidebarLayout(
            sidebarPanel( width = 6,
              fluidRow(
                column(width =12,
                  box(title = "Area of interest", width = 12, background = "black", solidHeader = TRUE,
  
                    selectInput(inputId = "schema", label = NULL,
                            selected = "" ,
                            choices = c("",availStudyAreas), selectize=FALSE
                    ),
                    bsTooltip("schema", "Select an area of interest",
                            "right", options = list(container = "body")
                    )
                  )
                )
              ),
              fluidRow(
                column(width =12,
                  box(title = "Scenarios", width = 12, background = "black", solidHeader = TRUE,
                    checkboxGroupInput(inputId ="scenario", label = NULL, selected = NULL, choiceNames = NULL ),
                    bsTooltip("scenario", "Select the scenarios you wish to compare. See Dashboard for indicators.",
                            "right", options = list(container = "body"))
                  #tableOutput("scenarioDescription")
                  )
                 # checkboxGroupTooltip(id = "scenario", placement = "right", trigger = "hover"),
                )
              )
            )
            ,
            mainPanel( width = 6,
              conditionalPanel(condition = "!input.schema == ''",
                box(title = "Current State", width = 12, background = "black", solidHeader = FALSE,
                  fluidRow(
                    valueBoxOutput("statusGS"),
                    valueBoxOutput("statusTHLB"),
                    valueBoxOutput("statusRoad"),
                    
                    valueBoxOutput("statusCritHab"),
                    valueBoxOutput("statusDist"),
                    valueBoxOutput("statusDist500"),
                    bsTooltip("statusGS", "Total merchtanable growingstock (m3)",
                              "top", options = list(container = "body")),
                    bsTooltip("statusTHLB", "Percentage of timber harvesting landbase",
                              "top", options = list(container = "body")),
                    bsTooltip("statusRoad", "Percentage of 100 m of a road",
                              "top", options = list(container = "body")),
                    bsTooltip("statusCritHab", "Percentage of critical caribou habitat",
                              "top", options = list(container = "body")),
                    bsTooltip("statusDist", "Percentage of caribou habitat disturbed",
                              "top", options = list(container = "body")),
                    bsTooltip("statusDist500", "Percentage of caribou habitat disturbed with 500 m buffer",
                              "top", options = list(container = "body"))
                  ),
                  fluidRow(
                    plotlyOutput(outputId = "statusPlot", height = "200px"),
                    bsTooltip("statusPlot", "Proportion of seral as early (<40 yrs), mature (60 - 120 yrs) and old (> 120 yrs).",
                              "top", options = list(container = "body"))
                  ),
                  fluidRow(
                    column(12,
                      selectInput("tsa_selected", choices = NULL, label = 'TSA:', width = '100%',
                                multiple = T),
                      bsTooltip("tsa_selected", "Select timber supply area(s).",
                              "bottom", options = list(container = "body"))
                    )
                  )
                )
              )
            )
          )
      ),
      tabItem(tabName = "querybuilder",
        fluidRow( #Table query
          box(title = "Table Query", background = "black", solidHeader = TRUE,
                    #em("SELECT",style="color:#090909;font-size:80%")
              selectInput(inputId = "queryTable", label = "FROM TABLE:", choices = c("scenarios", "harvest", "rsf",  "growingstock", "survival" , "yielduncertainty"), selected = character(0)),
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
            selectInput("maplayers", label = "Available Layers", multiple = FALSE, choices = NULL),
            actionButton("getMapLayersButton", "Load")
          )
      ),
        leafletOutput("resultSetRaster", height = 750, width = "83%")     
      ),
      tabItem(tabName = "summary",
        fluidRow(#Raster query
          plotlyOutput(outputId = "radar", height = "400px")
        )    
      ),
      tabItem(tabName = "caribou",
        fluidRow(
                box(title = "Proportion Disturbed", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
                    plotlyOutput(outputId = "propDisturbPlot", height = "900px"))
        ),
        fluidRow(
          box(title = "Proportion Disturbed with 500m Buffer", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
              plotlyOutput(outputId = "propDisturbBuffPlot", height = "900px"))
        ),
        fluidRow(
          box(title = "Proportion Early", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
              plotlyOutput(outputId = "propEarlyPlot", height = "900px"))
        ),
        fluidRow(
          box(title = "Proportion Mature", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
              plotlyOutput(outputId = "propMaturePlot", height = "900px"))
        ),
        fluidRow(
          box(title = "Proportion Old", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
              plotlyOutput(outputId = "propOldPlot", height = "900px"))
        ),
        fluidRow(
          box(title = "Survival", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
            plotlyOutput(outputId = "survivalPlot", height = "900px"))
          ),
        fluidRow(
          box(title = "Resource Selection", collapsible = TRUE, collapsed = TRUE, solidHeader = TRUE, background = "purple", width =12,
              plotlyOutput(outputId = "rsfPlot", height = "900px"))
        )
      ),
      tabItem(tabName = "forestry",
        fluidRow(
          box(title = "Harvest Flow", collapsible = TRUE,  collapsed = TRUE, solidHeader = TRUE,background = "green", width =12,
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