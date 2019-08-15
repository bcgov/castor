ui <- dashboardPage(skin = "black",
  dashboardHeader(title = "CLUS: Explorer Tool"),
  dashboardSidebar(    
    sidebarMenu(
      menuItem("Settings", tabName = "settings", icon = icon("gears")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Query Builder", tabName = "querybuilder", icon = icon("search")),
      menuItem("Caribou", tabName = "caribou", icon = icon("paw")),
      menuItem("Forestry", tabName = "forestry", icon = icon("tree")),
      menuItem("Fire", tabName = "fire", icon = icon("fire")),
      menuItem("Insects (planned)", tabName = "insects", icon = icon("bug")),
      menuItem("climate", tabName = "climate", icon = icon("thermometer-half")),
      menuItem("Oil and Gas (planned)", tabName = "oilandgas", icon = icon("bolt")),
      menuItem("Mining (planned)", tabName = "mining", icon = icon("industry")),
      menuItem("Recreation (planned)", tabName = "recreation", icon = icon("shoe-prints"))
    )
  ),
  dashboardBody(
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
                "select the sceanrios you wish to compare",
                checkboxGroupInput(inputId ="scenario", label = NULL )
                
          )
      )
    ),
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBox(100, "Probability of Acheiving AAC", icon = icon("tree")),
                valueBox(100, "Total Area Harvested", icon = icon("tree")),
                valueBox(100, "Caribou Habitat", icon = icon("paw"))
              )
      ),
      tabItem(tabName = "querybuilder",
              fluidRow( #Table query
                box(title = "Table Query", background = "black", solidHeader = TRUE,
                  selectInput(inputId = "queryTable", label = "From table:", choices = c("scenarios", "pixels", "rsf", "blocks", "growingStockReport", "harvestingReport" ), selected = character(0)),
                  accordion(
                         accordionItem(id =1, title = "SELECT", color = "black", 
                                       selectInput(inputId = "queryColumn", label = "SELECT", choices = NULL, multiple = TRUE )),
                         accordionItem(id =2,title ="SUM", color = "black", selectInput(inputId = "queryColumn", label = "SELECT", choices = NULL, multiple = TRUE )),
                         accordionItem(id =3,title ="AVERAGE", color = "black", selectInput(inputId = "queryColumn", label = "SELECT", choices = NULL, multiple = TRUE )),
                         accordionItem(id =4,title ="COUNT", color = "black", selectInput(inputId = "queryColumn", label = "SELECT", choices = NULL, multiple = TRUE ))
                  )
                  )
              ),
              dataTableOutput("resultSetTable"),
              
              
              
              fluidRow(#Raster query
              box(title = "Map Query",  collapsible = T, background = "black", solidHeader = TRUE,
                  textInput("query_columns", label = "SELECT" )
              ),
              leafletOutput("resultSetRaster"))
      ),
      tabItem(tabName = "caribou",
              h2("caribou")
      ),
      tabItem(tabName = "forestry",
              h2("Forestry")
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