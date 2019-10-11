dashboardPage(
  dashboardHeader(title = "Caribou BC"),
  dashboardSidebar(
    tags$script(src = "tips.js"),
    selectInput("herd", "Herd", c("Default"="Default", Herds)),
    sliderInput("tmax", "Number of years to forecast",
      min = 1, max = 100, value = 20, step = 1
    ),
    sliderInput("popstart", "Initial population size",
      min = 1, max = 200, value = 100, step = 1
    ),
    bsTooltip("herd",
      "Select a herd for herd specific demography parameters.",
      placement="right"),
    bsTooltip("tmax",
      "Number of years in which the caribou population is forecasted. Default set, but the user can change the value by slider."),
    bsTooltip("popstart",
      "Number of caribou in the starting population. Default set, but the user can change the value by slider."),
    sidebarMenu(
      menuItem("Maternity pen", tabName = "penning"),
      menuItem("Predator exclosure", tabName = "predator"),
      menuItem("Moose reduction", tabName = "moose")
    )
  ),
  dashboardBody(
    tabItems(

      tabItem("penning",
        fluidRow(
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Maternity pen",
              plotlyOutput("penning_Plot", width = "100%", height = 400),
              bsTooltip("penning_Plot",
                "Change in the number of caribou over time. Hover over the plot to download, zoom and explore the results.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Maternity pen",
              tableOutput("penning_Table"),
              downloadButton("penning_download", "Download results as Excel file"),
              bsTooltip("penning_Table",
                "Table summarizing reports. Click below to download the full summary.",
                placement="right"),
              bsTooltip("penning_download",
                "Click here to download results.",
                placement="top")
            )
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Penning",
              sliderInput("penning_FpenPerc", "Percent of females penned",
                min = 0, max = 100, value = round(100*inits$penning$fpen.prop),
                step = 1),
              bsTooltip("penning_FpenPerc",
                "Change the percent of female population in maternity pens. Default set, but the user can toggle."),
              uiOutput("penning_button"),
              bsTooltip("penning_button",
                "Click here to create a reference scenario, and see how changing penning or demography parameters affect results.")
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Demography",
              uiOutput("penning_demogr_sliders")
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Cost (x $1000)",
              sliderInput("penning_CostPencap", "Max in a single pen",
                min = 1, max = 100, value = inits$penning$pen.cap, step = 1),
              sliderInput("penning_CostSetup", "Initial set up",
                min = 0, max = 2000, value = 100*round(inits$penning$pen.cost.setup/100),
                step = 100),
              sliderInput("penning_CostProj", "Project manager",
                min = 0, max = 500, value = inits$penning$pen.cost.proj, step = 10),
              sliderInput("penning_CostMaint", "Maintenance",
                min = 0, max = 1000, value = inits$penning$pen.cost.maint, step = 10),
              sliderInput("penning_CostCapt", "Capture/monitor",
                min = 0, max = 500, value = inits$penning$pen.cost.capt, step = 10)#,
            )
          )
        )
      ),

      tabItem("predator",
        fluidRow(
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Predator exclosure",
              plotlyOutput("predator_Plot", width = "100%", height = 400),
              bsTooltip("predator_Plot",
                "Change in the number of caribou over time. Hover over the plot to download, zoom and explore the results.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Predator exclosure",
              tableOutput("predator_Table"),
              downloadButton("predator_download", "Download results as Excel file"),
              bsTooltip("predator_Table",
                "Table summarizing reports. Click below to download the full summary.",
                placement="right"),
              bsTooltip("predator_download",
                "Click here to download results.",
                placement="top")
            )
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Penning",
              sliderInput("predator_FpenPerc", "Percent of females penned",
                min = 0, max = 100, value = round(100*inits$predator$fpen.prop),
                step = 1),
              bsTooltip("predator_FpenPerc",
                "Change the percent of female population in maternity pens. Default set, but the user can toggle."),
              uiOutput("predator_button"),
              bsTooltip("predator_button",
                "Click here to create a reference scenario, and see how changing penning or demography parameters affect results.")
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Demography",
              uiOutput("predator_demogr_sliders")
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Cost (x $1000)",
              sliderInput("predator_CostPencap", "Max in a single pen",
                min = 1, max = 100, value = inits$predator$pen.cap, step = 1),
              sliderInput("predator_CostSetup", "Initial set up",
                min = 0, max = 2000, value = 100*round(inits$predator$pen.cost.setup/100),
                step = 100),
              sliderInput("predator_CostProj", "Project manager",
                min = 0, max = 500, value = inits$predator$pen.cost.proj, step = 10),
              sliderInput("predator_CostMaint", "Maintenance",
                min = 0, max = 1000, value = inits$predator$pen.cost.maint, step = 10),
              sliderInput("predator_CostCapt", "Capture/monitor",
                min = 0, max = 500, value = inits$predator$pen.cost.capt, step = 10),
              sliderInput("predator_CostPred", "Removing predators",
                min = 0, max = 500, value = inits$predator$pen.cost.pred, step = 10)
            )
          )
        )
      ),

      tabItem("moose",
        fluidRow(
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Moose reduction",
              plotlyOutput("moose_Plot", width = "100%", height = 400),
              bsTooltip("moose_Plot",
                "Change in the number of caribou over time. Hover over the plot to download, zoom and explore the results.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Moose reduction",
              tableOutput("moose_Table"),
              downloadButton("moose_download", "Download results as Excel file"),
              bsTooltip("moose_Table",
                "Table summarizing reports. Click below to download the full summary.",
                placement="right"),
              bsTooltip("moose_download",
                "Click here to download results.",
                placement="top")
            )
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Penning",
              sliderInput("moose_FpenPerc", "Percent of females penned",
                min = 0, max = 100, value = round(100*inits$predator$fpen.prop),
                step = 1),
              bsTooltip("moose_FpenPerc",
                "Change the percent of female population in maternity pens. Default set, but the user can toggle."),
              uiOutput("moose_button"),
              bsTooltip("moose_button",
                "Click here to create a reference scenario, and see how changing penning or demography parameters affect results.")
            )
          )
        )
      )
    )
  )
)

