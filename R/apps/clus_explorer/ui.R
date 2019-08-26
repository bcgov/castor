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
      menuItem("Query Builder", tabName = "querybuilder", icon = icon("search"))

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
                checkboxGroupInput(inputId ="scenario", label = NULL )
            )
          )
      ),
      tabItem(tabName = "caribou",
          fluidRow(
            valueBox(100, "Caribou Habitat", icon = icon("paw"))
          )
      ),
      tabItem(tabName = "querybuilder",
          fluidRow( #Table query
            box(title = "Table Query", background = "black", solidHeader = TRUE,
                    #em("SELECT",style="color:#090909;font-size:80%")
              selectInput(inputId = "queryTable", label = "FROM TABLE:", choices = c("scenarios", "pixels", "rsf", "blocks", "growingStockReport", "harvestingReport" ), selected = character(0)),
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
          ),
          
          fluidRow(#Raster query
            box(title = "Map Query",  collapsible = T, background = "black", solidHeader = TRUE,
              textInput("query_columns", label = "SELECT" )
            )),
          leafletOutput("resultSetRaster")
      ),
      tabItem(tabName = "forestry",
        valueBox(100, "Probability of Acheiving AAC", icon = icon("tree")),
        valueBox(100, "Total Area Harvested", icon = icon("tree"))
      ),
      tabItem(tabName = "fire",
        h2("Fire")
      ),
      tabItem(tabName = "insects",
        h2("Insects")
      ),
      tabItem(tabName = "climate",
        h2("Climate")
      ),
      tabItem(tabName = "oilandgas",
        h2("Oil and Gas")
      ),
      tabItem(tabName = "mining",
        h2("Mining")
      ),
      tabItem(tabName = "recreation",
        h2("Recreation")
      )
    )
  )
)