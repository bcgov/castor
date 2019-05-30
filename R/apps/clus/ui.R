ui <- dashboardPage(
  dashboardHeader(title = "CLUS: Explorer Tool"),
  dashboardSidebar(    
    sidebarMenu(
      menuItem("Upload clusdb", tabName = "upload", icon = icon("cloud-upload-alt")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Compare Scenarios", tabName = "comparescenario", icon = icon("chart-bar")),
      menuItem("Query Builder", tabName = "querybuilder", icon = icon("search")),
      menuItem("Oil and Gas", tabName = "oilandgas", icon = icon("bolt")),
      menuItem("Mining", tabName = "oilandgas", icon = icon("industry")),
      menuItem("Forestry", tabName = "forestry", icon = icon("tree")),
      menuItem("Recreation", tabName = "recreation", icon = icon("shoe-prints")),
      menuItem("Caribou", tabName = "caribou", icon = icon("paw")),
      menuItem("Fire", tabName = "fire", icon = icon("fire")),
      menuItem("Insects", tabName = "insects", icon = icon("bug")),
      menuItem("climate", tabName = "climate", icon = icon("thermometer-half"))
    )
  ),
  dashboardBody(
    tabItems(
      #First upload tab
      tabItem(tabName = "upload",
              h2("upload tab content")
      ),
      tabItem(tabName = "dashboard",
              fluidRow(
                box(plotOutput("plot1", height = 250)),
                box(
                  title = "Controls",
                  sliderInput("slider", "Number of observations:", 1, 100, 50)
                )
              )
      ),
      # compare scenarios
      tabItem(tabName = "comparescenario",
              h2("scenario tab content")
      ),
      # query builder
      tabItem(tabName = "querybuilder",
              h2("query tab content")
      )
    )
  )
)