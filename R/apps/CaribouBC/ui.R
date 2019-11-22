dashboardPage(
  dashboardHeader(title = paste("Caribou BC", ver[1])),
  dashboardSidebar(
    tags$script(src = "tips.js"),
    sliderInput("tmax", "Number of years to forecast",
      min = 1, max = 50, value = 20, step = 1
    ),
    sliderInput("popstart", "Initial population size",
      min = 1, max = 200, value = 100, step = 1
    ),
    bsTooltip("tmax",
      "Number of years in which the caribou population is forecasted. Default set, but the user can change the value by slider."),
    bsTooltip("popstart",
      "Number of caribou in the starting population. Default set, but the user can change the value by slider."),
    radioButtons("use_perc", "How to provide females penned",
      list("Percent"="perc", "Number of individuals"="inds")),
    sidebarMenu(
      menuItem("Maternity pen", tabName = "penning"),
      menuItem("Predator exclosure", tabName = "predator"),
      menuItem("Moose reduction", tabName = "moose"),
      menuItem("Wolf reduction", tabName = "wolf"),
      menuItem("Conservation breeding", tabName = "breeding")
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
            ),
            HTML(FooterText)
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Settings",
              uiOutput("penning_herd"),
              bsTooltip("penning_herd",
                "Select a herd for herd specific demography parameters.",
                placement="top"),
              uiOutput("penning_perc_or_inds"),
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
            ),
            HTML(FooterText)
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Settings",
              uiOutput("predator_herd"),
              bsTooltip("predator_herd",
                "Select a herd for herd specific demography parameters.",
                placement="top"),
              uiOutput("predator_perc_or_inds"),
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
            ),
            HTML(FooterText)
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Settings",
              uiOutput("moose_herd"),
              bsTooltip("moose_herd",
                "Select a herd for herd specific demography parameters.",
                placement="top"),
              uiOutput("moose_perc_or_inds"),
              uiOutput("moose_button"),
              bsTooltip("moose_button",
                "Click here to create a reference scenario, and see how changing penning or demography parameters affect results.")
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Demography",
              uiOutput("moose_demogr_sliders")
            )
          )
        )
      ),

      tabItem("wolf",
        fluidRow(
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Wolf reduction",
              plotlyOutput("wolf_Plot", width = "100%", height = 400),
              bsTooltip("wolf_Plot",
                "Change in the number of caribou over time. Hover over the plot to download, zoom and explore the results.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Wolf reduction",
              tableOutput("wolf_Table"),
              downloadButton("wolf_download", "Download results as Excel file"),
              bsTooltip("wolf_Table",
                "Table summarizing reports. Click below to download the full summary.",
                placement="right"),
              bsTooltip("wolf_download",
                "Click here to download results.",
                placement="top")
            ),
            HTML(FooterText)
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Settings",
              uiOutput("wolf_herd"),
              bsTooltip("wolf_herd",
                "Select a herd for herd specific demography parameters.",
                placement="top")
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Demography",
              uiOutput("wolf_demogr_sliders")
            )
          )
        )
      ),

      tabItem("breeding",
        fluidRow(
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: captive breeding",
              plotlyOutput("breeding_Plot", width = "100%", height = 400),
              bsTooltip("breeding_Plot",
                "Change in the number of caribou over time. Hover over the plot to download, zoom and explore the results.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: conservation breeding",
              tableOutput("breeding_Table"),
              downloadButton("breeding_download", "Download results as Excel file"),
              bsTooltip("breeding_Table",
                "Table summarizing reports. &lambda; is defined based on the last 2 years for penned and as (N<sub>t</sub>/N<sub>0</sub>)<sup>1/t</sup> otherwise. Click below to download the full summary.",
                placement="right"),
              bsTooltip("breeding_download",
                "Click here to download results.",
                placement="top")
            ),
            HTML(FooterText)
          ),
          column(width=4,
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Settings",
              uiOutput("breeding_herd"),
              bsTooltip("breeding_herd",
                "Select a herd for herd specific demography parameters.",
                placement="top"),
              sliderInput("breeding_outprop", "Proportion of juvenile females captured/transferred",
                min = 0, max = 1, value = 0.5, step = 0.01),
              bsTooltip("breeding_outprop",
                "The proportion of juvenile females captured/transferred from the captive to the recipient herd."),
              sliderInput("breeding_ininds", "Number of females put into pen each year (max)",
                min = 0, max = 20, value = 10, step = 1),
              uiOutput("breeding_years"),
              sliderInput("breeding_ftrans", "Adult female survival during capture/transport",
                min = 0, max = 1, value = 1, step = 0.01),
              uiOutput("breeding_jyears"),
              sliderInput("breeding_jtrans", "Juvenile female survival during capture/transport",
                min = 0, max = 1, value = 1, step = 0.01),
              sliderInput("breeding_jsred", "Transported juvenile female survival reduction for 1 year after transport",
                min = 0, max = 1, value = 1, step = 0.01)
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Demography",
              uiOutput("breeding_demogr_sliders")
            )
          )
        )
      )

    )
  )
)