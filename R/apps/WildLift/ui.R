dashboardPage(
  dashboardHeader(title = paste("WildLift", ver[1])),
  dashboardSidebar(
    tags$script(src = "tips.js"),
    sidebarMenu(
      menuItem("Home", tabName = "home", icon=icon("home")),
      menuItem("Single lever", tabName = "single",
               startExpanded=FALSE, icon=icon("dice-one"),
        menuSubItem("Maternity penning", tabName = "penning"),
        menuSubItem("Predator exclosure", tabName = "predator"),
        menuSubItem("Moose reduction", tabName = "moose"),
        menuSubItem("Wolf reduction", tabName = "wolf"),
        menuSubItem("Linear feature", tabName = "seismic"),
        menuSubItem("Conservation breeding", tabName = "breeding")
      ),
      menuItem("Multiple levers", tabName = "multiple", icon=icon("dice-two"),
        menuSubItem("Demographic augmentation", tabName = "multi1"),
        menuSubItem("Conservation breeding", tabName = "breeding1")
      ),
      menuItem("Documentation", tabName = "docs", icon=icon("book"))
    ),
    hr(),
    sliderInput("tmax", "Number of years to forecast",
      min = 1, max = 50, value = 20, step = 1
    ),
    sliderInput("popstart", "Initial population size",
      min = 1, max = 1000, value = 100, step = 1
    ),
    bsTooltip("tmax",
      "Number of years in which the population is forecasted. Default set, but the user can change the value by slider."),
    bsTooltip("popstart",
      "Number of females (from all stage classes) in the starting population. Default set, but the user can change the value by slider."),
    radioButtons("use_perc", "How to provide females penned",
      list("Percent"="perc", "Number of individuals"="inds"))
  ),
  dashboardBody(
    tabItems(

      tabItem("home",
        fluidRow(
          column(width=12,
                 includeMarkdown("intro.md")
          ),
        )
      ),


      tabItem("docs",
        fluidRow(
          column(width=12,
                 includeMarkdown("docs.md")
          ),
        )
      ),


      tabItem("multi1",
        fluidRow(
          column(width=12,
            h2("Demographic Augmentation and Predator/Prey Management"),
            HTML("<br/><p><strong>Limitations</strong> &mdash; Results using multiple levers are extrapolated based on knowledge from locations where single levers were studied. Combinations of these levers do not have documented examples and need to be treated with caution. Parameters for non-captive individuals were derived from average subpopulation response to either WR or WR. Parameters for captive individuals under PE were derived from average responses to this action in isolation. Parameters for MP were adjusted based on assumed additive effects. Please see documentation for details.</p><p>MP = Maternity Penning; PE = Predator Exclosure; MR = Moose Reduction; WR = Wolf Reduction</p><p><strong>Note</strong> &mdash; To estimate cost of WR, please enter an appropriate number of wolves to be removed.</p><br/>"),
          ),
          column(width=6,
            uiOutput("multi1_perc_or_inds")
          ),
          column(width=6,
            radioButtons("multi1_plot_type", "Plot design",
                         choices=c("Single"="all",
                                   "By demographic augmentation"="dem",
                                   "By predator/prey management"="man",
                                   "Facets"="fac"))
          )
        ),
        fluidRow(
          column(width=12,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Multiple levers",
              plotlyOutput("multi1_Plot", width = "100%", height = 400),
              bsTooltip("multi1_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="bottom")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Multiple levers",
              #tableOutput("multi1_Table"),
              reactableOutput("multi1_Table"),
              downloadButton("multi1_download", "Download results as Excel file"),
              bsTooltip("multi1_Table",
                "Table summarizing reports, population numbers refert to females (i.e., all stage classes). Click on the headings to sort the table. Click below to download the full summary.",
                placement="top"),
              bsTooltip("multi1_download",
                "Click here to download results.",
                placement="top")
            ),
          )
        ),
        fluidRow(
          column(width=12,
            box(
              width = 3, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Demography status quo",
              uiOutput("multi1_demogr_wild")
            ),
            box(
              width = 3, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Demography captive",
              uiOutput("multi1_demogr_captive")
            ),
            box(
              width = 3, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Moose reduction",
              sliderInput("multi1_DemFsw_MR", "Adult female survival, MR",
                  min = 0, max = 1,
                  value = inits$multi1$f.surv.wild.mr, step = 0.001),
              hr(),
              HTML("<p><strong>Additive effect of MP over MR-only parameters</strong></p><p>Survival boost due to females spending some of their life outside of the pen</p>"),
              sliderInput("multi1_DemFsc_MPMRboost", "Additive effect of MP over MR-only adult female survival, captive",
                  min = 0, max = 1,
                  value = inits$multi1$f.surv.capt.mpmr.boost, step = 0.001)
            ),
            box(
              width = 3, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Wolf reduction",
              sliderInput("multi1_DemCsw_WR", "Calf survival, WR",
                  min = 0, max = 1,
                  value = inits$multi1$c.surv.wild.wr, step = 0.001),
              sliderInput("multi1_DemFsw_WR", "Adult female survival, WR",
                  min = 0, max = 1,
                  value = inits$multi1$f.surv.wild.wr, step = 0.001),
              hr(),
              HTML("<p><strong>Additive effect of MP over WR-only parameters</strong></p>"),
              sliderInput("multi1_DemCsc_MPWRboost", "Additive effect of MP over WR-only calf survival, captive",
                  min = 0, max = 1,
                  value = inits$multi1$c.surv.capt.mpwr.boost, step = 0.001),
              sliderInput("multi1_DemFsc_MPWRboost", "Additive effect of MP over WR-only adult female survival, captive",
                  min = 0, max = 1,
                  value = inits$multi1$f.surv.capt.mpwr.boost, step = 0.001)
            )
          )
        ),
        fluidRow(
          column(width=12,
            box(
              width = 4, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Cost: MP",
              p("All costs: x $1000"),
              sliderInput("multi1_CostPencap_MP", "Max adult females in a single pen",
                min = 1, max = 100, value = inits$penning$pen.cap, step = 1),
              sliderInput("multi1_CostSetup_MP", "Initial set up",
                min = 0, max = 2000, value = 100*round(inits$penning$pen.cost.setup/100),
                step = 100),
              sliderInput("multi1_CostProj_MP", "Project manager",
                min = 0, max = 500, value = inits$penning$pen.cost.proj, step = 10),
              sliderInput("multi1_CostMaint_MP", "Maintenance",
                min = 0, max = 1000, value = inits$penning$pen.cost.maint, step = 10),
              sliderInput("multi1_CostCapt_MP", "Capture/monitor",
                min = 0, max = 500, value = inits$penning$pen.cost.capt, step = 10)
            ),
            box(
              width = 4L, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Cost: PE",
              p("All costs: x $1000"),
              sliderInput("multi1_CostPencap_PE", "Max adult females in a single pen",
                min = 1, max = 100, value = inits$predator$pen.cap, step = 1),
              sliderInput("multi1_CostSetup_PE", "Initial set up",
                min = 0, max = 2000, value = 100*round(inits$predator$pen.cost.setup/100),
                step = 100),
              sliderInput("multi1_CostProj_PE", "Project manager",
                min = 0, max = 500, value = inits$predator$pen.cost.proj, step = 10),
              sliderInput("multi1_CostMaint_PE", "Maintenance",
                min = 0, max = 1000, value = inits$predator$pen.cost.maint, step = 10),
              sliderInput("multi1_CostCapt_PE", "Capture/monitor",
                min = 0, max = 500, value = inits$predator$pen.cost.capt, step = 10),
              sliderInput("multi1_CostPred_PE", "Predator removal",
                min = 0, max = 500, value = inits$predator$pen.cost.pred, step = 10)
            ),
            box(
              width = 4, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,
              title = "Cost: WR",
              p("All costs: x $1000"),
              sliderInput("multi1_cost1", "Cost per wolf to be removed",
                min = 0, max = 10, value = 5.1, step = 0.1),
              sliderInput("multi1_nremove", "Number of wolves to be removed per year",
                min = 0, max = 200, value = 105, step = 1),
              bsTooltip("multi1_nremove",
                "The number of wolves is used to calculate cost, but does not influence demographic response given the assumption that wolf reduction results in 2 wolves / 1000 km<sup>2</sup>. Please make sure to <bold>use the slider</bold> to reflect the annual number of wolves to be removed to achieve a maximum wolf density of 2 wolves / 1000 km<sup>2</sup> within the subpopulation range.",
                placement="left")
            )
          )
        )
      ),


      tabItem("penning",
        fluidRow(
          column(width=12, h2("Maternity Penning")),
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Maternity penning",
              plotlyOutput("penning_Plot", width = "100%", height = 400),
              bsTooltip("penning_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Maternity penning",
              tableOutput("penning_Table"),
              downloadButton("penning_download", "Download results as Excel file"),
              bsTooltip("penning_Table",
                "Table summarizing reports (NA for breakeven point indicates that a breakeven point cannot be found that satisfies tha lambda=1 criterion). Population numbers refert to females (i.e., all stage classes). Click below to download the full summary.",
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
                "Select a subpopulation for subpopulation specific demography parameters.",
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
              width = NULL, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Cost (x $1000)",
              sliderInput("penning_CostPencap", "Max adult females in a single pen",
                min = 1, max = 100, value = inits$penning$pen.cap, step = 1),
              sliderInput("penning_CostSetup", "Initial set up",
                min = 0, max = 2000, value = 100*round(inits$penning$pen.cost.setup/100),
                step = 100),
              sliderInput("penning_CostProj", "Project manager",
                min = 0, max = 500, value = inits$penning$pen.cost.proj, step = 10),
              sliderInput("penning_CostMaint", "Maintenance",
                min = 0, max = 1000, value = inits$penning$pen.cost.maint, step = 10),
              sliderInput("penning_CostCapt", "Capture/monitor",
                min = 0, max = 500, value = inits$penning$pen.cost.capt, step = 10)
            )
          )
        )
      ),

      tabItem("predator",
        fluidRow(
          column(width=12, h2("Predator Exclosure")),
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Predator exclosure",
              plotlyOutput("predator_Plot", width = "100%", height = 400),
              bsTooltip("predator_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Predator exclosure",
              tableOutput("predator_Table"),
              downloadButton("predator_download", "Download results as Excel file"),
              bsTooltip("predator_Table",
                "Table summarizing reports (NA for breakeven point indicates that a breakeven point cannot be found that satisfies tha lambda=1 criterion). Population numbers refert to females (i.e., all stage classes). Click below to download the full summary.",
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
                "Select a subpopulation for subpopulation specific demography parameters.",
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
              width = NULL, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Cost (x $1000)",
              sliderInput("predator_CostPencap", "Max adult females in a single pen",
                min = 1, max = 100, value = inits$predator$pen.cap, step = 1),
              sliderInput("predator_CostSetup", "Initial set up",
                min = 0, max = 2000, value = 10*round(inits$predator$pen.cost.setup/10),
                step = 10),
              sliderInput("predator_CostProj", "Project manager",
                min = 0, max = 500, value = inits$predator$pen.cost.proj, step = 10),
              sliderInput("predator_CostMaint", "Maintenance",
                min = 0, max = 1000, value = inits$predator$pen.cost.maint, step = 10),
              sliderInput("predator_CostCapt", "Capture/monitor",
                min = 0, max = 500, value = inits$predator$pen.cost.capt, step = 10),
              sliderInput("predator_CostPred", "Predator removal",
                min = 0, max = 500, value = inits$predator$pen.cost.pred, step = 10)
            )
          )
        )
      ),

      tabItem("moose",
        fluidRow(
          column(width=12, h2("Moose Reduction")),
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Moose reduction",
              plotlyOutput("moose_Plot", width = "100%", height = 400),
              bsTooltip("moose_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Moose reduction",
              tableOutput("moose_Table"),
              downloadButton("moose_download", "Download results as Excel file"),
              bsTooltip("moose_Table",
                "Table summarizing reports. Population numbers refert to females (i.e., all stage classes). Click below to download the full summary.",
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
                "Select a subpopulation for subpopulation specific demography parameters.",
                placement="top")
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
          column(width=12,
            h2("Wolf Reduction"),
            HTML("<br/><p><strong>Note</strong> &mdash; To estimate cost of WR, please enter an appropriate number of wolves to be removed.</p><br/>")
          ),
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: Wolf reduction",
              plotlyOutput("wolf_Plot", width = "100%", height = 400),
              bsTooltip("wolf_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: Wolf reduction",
              tableOutput("wolf_Table"),
              downloadButton("wolf_download", "Download results as Excel file"),
              bsTooltip("wolf_Table",
                "Table summarizing reports. Population numbers refert to females (i.e., all stage classes). Click below to download the full summary.",
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
                "Select a subpopulation for subpopulation specific demography parameters.",
                placement="top")
            ),
            box(
              width = NULL, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Demography",
              uiOutput("wolf_demogr_sliders")
            ),
            box(
              width = NULL, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Cost",
              sliderInput("wolf_cost1", "Cost per wolf to be removed (x $1000)",
                min = 0, max = 10, value = 5.1, step = 0.1),
              sliderInput("wolf_nremove", "Number of wolves to be removed per year",
                min = 0, max = 200, value = 105, step = 1),
              bsTooltip("wolf_nremove",
                "The number of wolves is used to calculate cost, but does not influence demographic response given the assumption that wolf reduction results in 2 wolves / 1000 km<sup>2</sup>. Please make sure to <bold>use the slider</bold> to reflect the annual number of wolves to be removed to achieve a maximum wolf density of 2 wolves / 1000 km<sup>2</sup> within the subpopulation range.",
                placement="bottom")
            )
          )
        )
      ),


      tabItem("seismic",
        fluidRow(
          column(width=12, h2("Linear Reature Deactivation and Restoration")),
          column(width=8,
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: linear feature",
              plotlyOutput("seismic_Plot", width = "100%", height = 400),
              bsTooltip("seismic_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="right")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: linear feature",
              tableOutput("seismic_Table"),
              downloadButton("seismic_download", "Download results as Excel file"),
              bsTooltip("seismic_Table",
                "Table summarizing reports. Population numbers refert to females (i.e., all stage classes). Click below to download the full summary.",
                placement="right"),
              bsTooltip("seismic_download",
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
              selectInput(
                "seismic_herd", "Subpopulation",
                c("East Side Athabasca"="esar",
                  "West Side Athabasca"="wsar", "Cold Lake"="coldlake")
              ),
              bsTooltip("seismic_herd",
                "Select a subpopulation for subpopulation range specific parameters.",
                placement="top"),
              uiOutput("seismic_sliders")
            ),
            box(
              width = NULL, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Cost",
              sliderInput("seismic_cost",
                "Cost per km (x $1000)",
                min = 0, max = 100, value = 12, step = 1),
            )
          )
        )
      ),


      tabItem("breeding",
        fluidRow(
          column(width=12,
            h2("Conservation Breeding"),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: conservation breeding",
              plotlyOutput("breeding_Plot", width = "100%", height = 400),
              bsTooltip("breeding_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="bottom")
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: conservation breeding",
              tableOutput("breeding_Table"),
              downloadButton("breeding_download", "Download results as Excel file"),
              bsTooltip("breeding_Table",
                "Table summarizing reports. &lambda; is defined based on the last 2 years in facility or as (N<sub>t</sub>/N<sub>0</sub>)<sup>1/t</sup> otherwise. Population numbers refert to females (i.e., all stage classes) unless noted otherwise. Click below to download the full summary.",
                placement="bottom"),
              bsTooltip("breeding_download",
                "Click here to download results.",
                placement="top")
            ),
            HTML(FooterText)
          )
        ),
        fluidRow(
            box(
              width = 4, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Settings",
              uiOutput("breeding_herd"),
              bsTooltip("breeding_herd",
                "Select a subpopulation for subpopulation specific demographic parameters.",
                placement="top"),
              sliderInput("breeding_outprop", "Proportion of juvenile females transferred",
                min = 0, max = 1, value = 0.5, step = 0.01),
              bsTooltip("breeding_outprop",
                "The proportion of juvenile females transferred from the facility to the recipient subpopulation."),
              sliderInput("breeding_ininds", "Number of females put into facility each year (max)",
                min = 0, max = 40, value = 10, step = 1),
              uiOutput("breeding_years"),
              sliderInput("breeding_ftrans", "Adult female survival during capture/transport to the facility",
                min = 0, max = 1, value = 1, step = 0.01),
              uiOutput("breeding_jyears"),
              sliderInput("breeding_jtrans", "Juvenile female survival during capture/transport from the facility to the recipient subpopulation",
                min = 0, max = 1, value = 1, step = 0.01),
              sliderInput("breeding_jsred", "Relative reduction in survival of juvenile females transported to recipient subpopulation for 1 year after transport",
                min = 0, max = 1, value = 1, step = 0.01),
              checkboxInput("breeding_breedearly", "Females inside the facility reproduce at 2 yrs age with fecundity rate 0.57",
                value = FALSE),

            ),
            box(
              width = 4, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Demography",
              uiOutput("breeding_demogr_sliders")
            ),
            box(
              width = 4, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Cost (x $1000)",
              sliderInput("breeding_CostSetup", "Initial set up",
                min = 0, max = 20000, value = 100*round(inits$breeding$pen.cost.setup/100),
                step = 1000),
              sliderInput("breeding_CostProj", "Project manager",
                min = 0, max = 500, value = inits$breeding$pen.cost.proj, step = 10),
              sliderInput("breeding_CostMaint", "Maintenance",
                min = 0, max = 1000, value = inits$breeding$pen.cost.maint, step = 10),
              sliderInput("breeding_CostCapt", "Capture/monitor",
                min = 0, max = 500, value = inits$breeding$pen.cost.capt, step = 10)
            )
        )
      ),


      tabItem("breeding1",
        fluidRow(
          column(width=12,
            h2("Conservation Breeding and Predator/Prey Management"),
            HTML("<br/><p><strong>Limitations</strong> &mdash; Results using multiple levers are extrapolated based on knowledge from locations where single levers were studied. Combinations of these levers do not have documented examples and need to be treated with caution. Parameters for non-captive individuals were derived from average subpopulation response to either WR or WR. Parameters for captive individuals under CB were derived from average responses to this action in isolation. Please see documentation for details.</p><p>CB = Conservation Breeding; MR = Moose Reduction; WR = Wolf Reduction</p><p><strong>Note</strong> &mdash; To estimate cost of WR, please enter an appropriate number of wolves to be removed.</p><br/>"),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Population forecast: conservation breeding",
              plotlyOutput("breeding1_Plot", width = "100%", height = 400),
              bsTooltip("breeding1_Plot",
                "Change in the number of females over time. Hover over the plot to download, zoom and explore the results. Click on the legend to hide a line, double click to show a single line.",
                placement="bottom"),
              checkboxGroupInput("breeding1_plot_show", NULL,
                  choices=list(
                    "CB + MR"="mr",
                    "CB + WR"="wr",
                    "Facility in/out"="fac"
                  ), selected=c("mr", "wr"), inline=TRUE)
            ),
            box(
              width = NULL, status = "success", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Summary: conservation breeding",
              tableOutput("breeding1_Table"),
              downloadButton("breeding1_download", "Download results as Excel file"),
              bsTooltip("breeding1_Table",
                "Table summarizing reports. &lambda; is defined based on the last 2 years in facility or as (N<sub>t</sub>/N<sub>0</sub>)<sup>1/t</sup> otherwise. Population numbers refert to females (i.e., all stage classes) unless noted otherwise. Click below to download the full summary.",
                placement="bottom"),
              bsTooltip("breeding1_download",
                "Click here to download results.",
                placement="top")
            ),
            HTML(FooterText)
          )
        ),
        fluidRow(
            box(
              width = 4, status = "info", solidHeader = TRUE,
              collapsible = FALSE, collapsed = FALSE,
              title = "Settings",
              uiOutput("breeding1_herd"),
              bsTooltip("breeding1_herd",
                "Select a subpopulation for subpopulation specific demographic parameters.",
                placement="top"),
              sliderInput("breeding1_outprop", "Proportion of juvenile females transferred",
                min = 0, max = 1, value = 0.5, step = 0.01),
              bsTooltip("breeding1_outprop",
                "The proportion of juvenile females transferred from the facility to the recipient subpopulation."),
              sliderInput("breeding1_ininds", "Number of females put into facility each year (max)",
                min = 0, max = 40, value = 10, step = 1),
              uiOutput("breeding1_years"),
              sliderInput("breeding1_ftrans", "Adult female survival during capture/transport to the facility",
                min = 0, max = 1, value = 1, step = 0.01),
              uiOutput("breeding1_jyears"),
              sliderInput("breeding1_jtrans", "Juvenile female survival during capture/transport from the facility to the recipient subpopulation",
                min = 0, max = 1, value = 1, step = 0.01),
              sliderInput("breeding1_jsred", "Relative reduction in survival of juvenile females transported to recipient subpopulation for 1 year after transport",
                min = 0, max = 1, value = 1, step = 0.01),
              checkboxInput("breeding1_breedearly", "Females inside the facility reproduce at 2 yrs age with fecundity rate 0.57",
                value = FALSE),

            ),
            box(
              width = 4, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Demography facility",
              uiOutput("breeding1_demogr_sliders_fac")
            ),
            box(
              width = 4, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Demography status quo & recipient CB only",
              uiOutput("breeding1_demogr_sliders_out")
            )
        ),
        fluidRow(
            box(
              width = 3, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Moose reduction",
              uiOutput("breeding1_demogr_sliders_mr")
            ),
            box(
              width = 3, status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Wolf reduction",
              uiOutput("breeding1_demogr_sliders_wr")
            ),
            box(
              width = 3, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Cost: CB",
              p("All costs: x $1000"),
              sliderInput("breeding1_CostSetup", "Initial set up",
                min = 0, max = 20000, value = 100*round(inits$breeding1$pen.cost.setup/100),
                step = 1000),
              sliderInput("breeding1_CostProj", "Project manager",
                min = 0, max = 500, value = inits$breeding1$pen.cost.proj, step = 10),
              sliderInput("breeding1_CostMaint", "Maintenance",
                min = 0, max = 1000, value = inits$breeding1$pen.cost.maint, step = 10),
              sliderInput("breeding1_CostCapt", "Capture/monitor",
                min = 0, max = 500, value = inits$breeding1$pen.cost.capt, step = 10)
            ),
            box(
              width = 3, status = "warning", solidHeader = TRUE,
              collapsible = TRUE, collapsed = FALSE,
              title = "Cost: WR",
              p("All costs: x $1000"),
              sliderInput("breeding1_costwolf", "Cost per wolf to be removed",
                min = 0, max = 10, value = 5.1, step = 0.1),
              sliderInput("breeding1_nremove", "Number of wolves to be removed per year",
                min = 0, max = 200, value = 105, step = 1),
              bsTooltip("breeding1_nremove",
                "The number of wolves is used to calculate cost, but does not influence demographic response given the assumption that wolf reduction results in 2 wolves / 1000 km<sup>2</sup>. Please make sure to add the annual number of wolves to be removed to achieve a maximum wolf density of 2 wolves / 1000 km<sup>2</sup> within the subpopulation range.",
                placement="bottom")
            )
        )
      )


    )
  )
)

