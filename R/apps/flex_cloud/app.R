#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(httr)
library(jsonlite)
library(dplyr)
library(magrittr)
library(dplyr)
library(analogsea)
library(DBI)
library(RPostgreSQL)
library(shinyFiles)
library(shinydashboard)
library(shinyjs)
library(future)
library(future.callr)
library(future.apply)
library(rlist)
library(fs)
library(stringr)
library(glue)
library(ssh)
library(ipc)
library(purrr)
library(filelock)
library(shinyjs)
library(glouton)
library(shinyWidgets)
library(raster)
library(ggplot2)
library(tictoc)

source('src/functions.R')

# options(shiny.error = browser)

# plan(sequential)
# plan(multicore)
plan(callr)
# plan(multisession)

# Available scneario Rmd files
available_scenarios <- list.files('scenarios/')

# Digital Ocean resources ----
api_base_url <- 'https://api.digitalocean.com/v2/'
region <- 'tor1'
uploader_image <- 'ubuntu-20-04-x64'
uploader_size = 's-1vcpu-1gb'

# FLEX droplet image
# snapshots <- analogsea::snapshots()
# image <- snapshots$`flex-cloud-image-20230224`$id

# SSH config
ssh_user <- "root"

# UI ----
ui <- shiny::tagList(

  shinyjs::useShinyjs(),
  glouton::use_glouton(),

  dashboardPage(
    skin = 'black', title = 'FLEX Cloud Deployment',
    header = dashboardHeader(
      title = 'FLEX Cloud Deployment',
      titleWidth = 400
    ),
    sidebar = dashboardSidebar(
      useShinyjs(),
      shiny::tags$head(
        shiny::tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
      ),
      shiny::tags$style(
        "@import url(https://use.fontawesome.com/releases/v5.15.3/css/all.css);"
      ),
      sidebarMenu(
        menuItem("Run Simulations", tabName = "run", icon = icon("play-circle")),
        menuItem("Cloud Servers", tabName = "resources", icon = icon("server")),
        menuItem("Billing", tabName = "billing", icon = icon("search-dollar")),
        menuItem("Settings", tabName = "settings", icon = icon("cog"))
      )
    ),
    body = dashboardBody(
      # shinyjs::useShinyjs(),
      tabItems(

        ## Run simulations ----
        tabItem(
          tabName = "run",
          h2('Run simulations'),
          p('Select the options and run the simulations.'),
          sidebarLayout(
            sidebarPanel(
              width = 4,
              div(
                class = "form-group",
                verbatimTextOutput("file_scenario_selected"),
                shinyFilesButton(
                  id = "file_scenario",
                  label = "Select scenario",
                  title = "Please select a file",
                  multiple = FALSE,
                  viewtype = "detail",
                  buttonType = 'info',
                  icon = icon('file-code'),
                  class = 'btn-flex-light'
                ),
              ),
              sliderInput('iterations', label = 'Number of iterations', value = 48, min = 4, max = 100, step = 4),
              selectizeInput(
                'droplet_size',
                label = "Cloud server config",
                choices = NULL,
                selected = '',
                multiple = FALSE
              ),
              div(
                class = "form-group",
                dropdownButton(
                  inputId = "settings_dropdown",
                  label = "Settings",
                  icon = icon("sliders"),
                  status = "btn-flex-light",
                  margin = '25px',
                  circle = FALSE,
                  textInput(
                    inputId = 'times',  label = "Times", value = 2
                  ),
                  numericInput(
                    inputId = 'female_max_age',  label = "Female max age",
                    min = 0, max = 15, value = 9
                  ),
                  numericInput(
                    inputId = 'den_target',  label = "Den target",
                    min = 0, max = 0.015, value = 0.003, step = 0.001
                  ),
                  numericInput(
                    inputId = 'rest_target',  label = "Rest target",
                    min = 0, max = 0.050, value = 0.028, step = 0.001
                  ),
                  numericInput(
                    inputId = 'move_target',  label = "Move target",
                    min = 0, max = 0.2, value = 0.091, step = 0.001
                  ),
                  numericInput(
                    inputId = 'reproductive_age',  label = "Reproductive age",
                    min = 0, max = 10, value = 2, step = 1
                  ),
                  numericInput(
                    inputId = 'sex_ratio',  label = "Sex ratio",
                    min = 0, max = 1, value = 0.5, step = 0.1
                  ),
                  textInput(
                    inputId = 'female_dispersal',  label = "Female dispersal", value = '785000'
                  ),
                  numericInput(
                    inputId = 'time_interval',  label = "Time interval",
                    min = 0, max = 50, value = 5, step = 5
                  )
                )
              ),
              hr(),
              div(
                class = "form-group",
                actionButton(
                  'run_scenario',
                  'Run scenario',
                  icon = icon('play-circle'),
                  class = 'btn-flex'
                )
              )
            ),
            mainPanel(
              width = 8,
              tabsetPanel(
                tabPanel(
                  "Simulation log",
                  fluidRow(
                    shiny::helpText("The log will appear in real time when you run the simulations based on selected options."),
                    dataTableOutput("simulation_log")
                  )
                ),
                tabPanel(
                  "Simulation output",
                  fluidRow(
                    shiny::helpText("Use controls below to view and manage the simulation output files."),
                    div(
                      class = 'form-group',
                      shiny::radioButtons(
                        inputId = 'report_currency', 
                        label = 'Select simulation',
                        choiceNames = c('Current', 'Previous'),
                        choiceValues = c('current', 'previous'),
                        selected = 'current', inline = TRUE
                      ),
                      shiny::selectizeInput(
                        inputId = 'report_simulation',
                        label = "Previous simulations",
                        choices = NULL,
                        selected = '',
                        multiple = FALSE
                      ),
                      actionButton(
                        'run_report',
                        'Generate simulation report',
                        icon = icon('file-alt'),
                        class = 'btn-flex-light'
                      )
                    ),
                    plotOutput('plot_csv'),
                    plotOutput('plot_tif', height = '600px')
                  ),
                  fluidRow(
                    h4("Parameters used in this simulation"),
                    tableOutput('params_used')
                  )
                )
              )
            )
          )
        ),

        ## Resources ----
        tabItem(
          tabName = "resources",
          h2('Manage Resources'),
          h3('Droplets'),
          tableOutput('droplets'),
          shiny::actionButton(
            inputId = 'refresh_droplets',
            label = 'Refresh',
            icon = icon('refresh')
          )
        ),

        ## Billing ----
        tabItem(
          tabName = "billing",
          h2('Billing'),
          h3('Droplets'),
          tableOutput('billing'),
          shiny::actionButton(
            inputId = 'refresh_billing',
            label = 'Refresh',
            icon = icon('refresh')
          ),
          shiny::textOutput('connection_status')
        ),

        ## Settings ----
        tabItem(
          tabName = "settings",
          h2('Settings'),
          hr(),
          h3('Authentication'),
          fluidRow(
            column(
              width = 5,
              shiny::helpText(
                'Select a private key to be used to be able to connect and manage
                Digital Ocean cloud resources.'
              ),
              div(
                class = "form-group",
                shinyFilesButton(
                  id = "key",
                  label = "Select private key",
                  title = "Please select a file",
                  multiple = FALSE,
                  viewtype = "detail",
                  buttonType = 'info',
                  icon = icon('key'),
                  class = 'btn-flex-light'
                )
              ),
              textInput('cores', "Local machine CPU cores"),
            ),
            column(
              width = 6, offset = 1,
              shiny::helpText(
                'Check which private key (if any) is currently set to be used
                to connect and manage Digital Ocean cloud resources.'
              ),
              div(
                class = "form-group",
                actionButton(
                  inputId = "get_settings",
                  label = "Current settings",
                  icon = icon('cog'),
                  class = 'btn-flex-light'
                )
              ),
              verbatimTextOutput("key_selected"),
            )
          ),
          hr(),
          fluidRow(
            column(
              width = 12,
              actionButton(
                'save_settings',
                'Save settings',
                icon = icon('cog'),
                class = 'btn-flex'
              )
            )
          )
        )
      )
    )
  ),
  shiny::tags$footer(
    class = 'footer',
    shiny::tags$div(
      class = 'container',
      shiny::tags$ul(
        shiny::tags$li(shiny::tags$a(href = '.', 'Home')),
        shiny::tags$li(
          shiny::tags$a(href = 'https://www2.gov.bc.ca/gov/content/home/disclaimer', 'Disclaimer')
        ),
        shiny::tags$li(
          shiny::tags$a(href = 'https://www2.gov.bc.ca/gov/content/home/privacy', 'Privacy')
        ),
        shiny::tags$li(
          shiny::tags$a(href = 'https://www2.gov.bc.ca/gov/content/home/accessibility', 'Accessibility')
        ),
        shiny::tags$li(
          shiny::tags$a(href = 'https://www2.gov.bc.ca/gov/content/home/copyright', 'Copyright')
        ),
        shiny::tags$li(
          shiny::tags$a(href = 'https://github.com/bcgov/devhub-app-web/issues', 'Contact Us')
        )
      )
    )
  )
)

# Server ----
server <- function(input, output, session) {
  validate(
    need(Sys.getenv("DO_TOKEN"), "Please set Digital Ocean API token in .Renviron file.")
  )

  rv <- reactiveValues(
    d_uploader = NULL,
    progress = NULL,
    sim_params = list()
  )
  
  shinyFileChoose(
    input, "file_scenario",
    roots = c('wd' = '.', 'scenarios' = paste0(getwd(), '/scenarios')),
    filetypes = c('tif'),
    defaultPath = '', defaultRoot = 'scenarios', session = session
  )
  shinyFileChoose(
    input, "key",
    roots = c('wd' = '.', 'root' = '/', 'home' = fs::path_home()),
    hidden = TRUE,
    defaultPath = '', defaultRoot = 'root', session = session
  )
  shinyFileChoose(
    input, "key_db",
    roots = c('wd' = '.', 'root' = '/', 'home' = fs::path_home()),
    hidden = TRUE,
    defaultPath = '', defaultRoot = 'root', session = session
  )

  volumes <- analogsea::volumes()
  getVolumeName <- function(volume) {
    volume$name
  }
  volume_names <- lapply(volumes, getVolumeName)

  volume_snapshots <- analogsea::snapshots(type = 'volume')
  getVolumeSnapshotName <- function(volume_snapshot) {
    volume_snapshot$name
  }
  volume_snapshot_names <- lapply(volume_snapshots, getVolumeSnapshotName)

  # Fetch available scenario Rmd files
  shiny::updateSelectizeInput(
    session = getDefaultReactiveDomain(),
    'scenario',
    choices = available_scenarios,
    selected = ''
  )

  # Droplet size
  # Available sizes
  # required_processes <- reactiveValue({
  #   input$iterations / 
  # })
  
  sizes <- analogsea::sizes(per_page = 200) %>%
    dplyr::filter(
      available == TRUE,
      grepl("tor1", region),
      !grepl("-amd", slug),
      !grepl("-intel", slug),
      memory > 16000,
      vcpus > 4,
      disk >= 320
    ) %>%
    mutate(
      processes_by_core = vcpus,
      processes_by_memory = memory / 1024 / 4,
      processes = pmin(processes_by_core, processes_by_memory),
      price_per_process = price_hourly / processes,
      label = paste0(
        processes, ' parallel processes, ',
        scales::dollar(price_per_process, prefix = '', suffix = '¢', accuracy = 0.01, scale = 100), ' per process per hour (',
        scales::dollar(price_hourly, prefix = '', suffix = '¢', accuracy = 0.01, scale = 100), ' hourly, ',
        memory / 1024, 'GB, ', 
        vcpus, ' vCPUs)'
      )
    ) %>%
    arrange(price_per_process) %>% 
    dplyr::select(slug, label, processes)
  
  size_choices <- setNames(
    as.character(sizes$slug),
    as.character(sizes$label)
  )
  
  shiny::updateSelectizeInput(
    session = getDefaultReactiveDomain(),
    'droplet_size',
    choices = size_choices,
    selected = ''
  )

  # Change of iterations
  observeEvent(
    input$iterations,
    ignoreInit = TRUE,
    {
      # browser()
      cookies <- glouton::fetch_cookies()
      cores <- as.numeric(cookies$cores)
      
      required_processes <- ceiling(input$iterations / cores)
      refined_sizes <- sizes %>% 
        filter(processes > required_processes)
      
      refined_size_choices <- setNames(
        as.character(refined_sizes$slug),
        as.character(refined_sizes$label)
      )
      
      shiny::updateSelectizeInput(
        session = getDefaultReactiveDomain(),
        'droplet_size',
        choices = refined_size_choices,
        selected = ''
      )
    }
  )

  # Previous simulations
  prev_simulations <- dir('inst/app/', no.. = TRUE, pattern = '^202')
  shiny::updateSelectizeInput(
    session = getDefaultReactiveDomain(),
    'report_simulation',
    choices = prev_simulations,
    selected = ''
  )

  output$file_scenario_selected <- renderPrint({
    if (is.integer(input$file_scenario)) {
      cat("Scenario has not been selected")
    } else {
      parseFilePaths(volumes, input$file_scenario)$name
    }
  })

  observeEvent(
    input$get_settings,
    {
      output$key_selected <- renderPrint({
        cookies <- glouton::fetch_cookies()
        
        ssh_keyfile <- cookies$key_path
        ssh_keyfile_name <- cookies$key_name
        
        cores <- cookies$cores
        
        print(paste("SSH key:", ssh_keyfile))
        print(paste("CPU cores:", cores))
      })
    }
  )

  logfile <- tempfile(tmpdir = tempdir(check = TRUE), pattern = 'simulation_')
  simulation_logfile <- paste0(logfile, '.csv')
  simulation_logfile_lock <- paste0(logfile, '.lock')

  ssh_keyfile <- ''
  ssh_keyfile_name <- ''

  # Run simulation ----
  observeEvent(
    input$run_scenario,
    ignoreInit = TRUE,
    {
      req(input$file_scenario)
      req(input$droplet_size)

      cookies <- glouton::fetch_cookies()
      ssh_keyfile <- cookies$key_path
      ssh_keyfile_name <- cookies$key_name
      cores <- cookies$cores

      if (length(ssh_keyfile) == 0 | length(ssh_keyfile_name) == 0) {
        shinyjs::alert('SSH key has not been set. Please go to Settings tab to configure it.')
      }
      req(length(ssh_keyfile) > 0 & length(ssh_keyfile_name) > 0)

      if (!file.exists(ssh_keyfile)) {
        shinyjs::alert('Configured SSH key does not exist. Please go to Settings tab to configure a new key.')
      }
      req(file.exists(ssh_keyfile))
      # stopifnot(input$droplet_size %in% sizes$slug)

      if (length(cores) == 0) {
        shinyjs::alert('Number of cores has not been set. Please go to Settings tab to configure it.')
      }
      req(length(cores) > 0)

      # Disable controls while the simulation is running ----
      disable('file_scenario')
      disable('droplet_size')
      disable('iterations')
      disable('times')
      disable('female_max_age')
      disable('den_target')
      disable('rest_target')
      disable('move_target')
      disable('reproductive_age')
      disable('sex_ratio')
      disable('female_dispersal')
      disable('time_interval')
      disable('run_scenario')

      progressOne <- Progress$new(session, min = 1, max = 10)
      on.exit(progressOne$close())
      progressOne$set(message = 'Creating droplet to host the scenario',
                   detail = 'This will take about a minute.')
      
      
      # SSH config
      ssh_user <- "root"

      # Scenario
      selected_scenario <- input$file_scenario
      scenario_tbl <- shinyFiles::parseFilePaths(volumes, selected_scenario)
      scenarios <- scenario_tbl$name

      # DO scenario uploader config
      region <- 'tor1'
      uploader_image <- 'ubuntu-20-04-x64'
      uploader_size = 's-1vcpu-2gb'

      progressOne$set(1, detail = 'Creating droplet')
      
      rv$d_uploader <- create_scenario_droplet(
        scenario = selected_scenario,
        ssh_keyfile = ssh_keyfile,
        ssh_keyfile_name = ssh_keyfile_name,
        ssh_user = ssh_user,
        progressOne = progressOne
      )
      # progressOne$close()

      if (is.null(rv$d_uploader)) {
        shinyjs::alert("Error has occrred, please refresh the page and try again.")
      }
      req(rv$d_uploader)

      scenario_droplet_ip <- get_private_ip(rv$d_uploader)

      rv$progress <- AsyncProgress$new(message="Overall job progress")
      
      print(paste("Simulation log file ", simulation_logfile))

      # FLEX droplet image ----
      snapshots <- snapshots_with_params(per_page = 200)
      snap_image <- snapshots$`flex-cloud-image-20230224`$id
      print(paste("Building from snapshot ID ", snap_image))
# browser()
      droplet_properties <- sizes %>% filter(slug == input$droplet_size)
      droplet_sequence <- droplet_properties %>% pull(processes)
      sim_sequence <- ceiling(input$iterations / droplet_sequence)
      total_steps <- sim_sequence * 13

      if (file.exists(simulation_logfile)) {
        file.remove(simulation_logfile)
        file.create(simulation_logfile)
      }

      write(
        paste0(
          "ID,Droplet,Progress,Description,Timestamp,Cost\n",
          "0,,,PROCESS STARTED,", as.character(Sys.time()), ","
        ),
        file = simulation_logfile,
        append = FALSE
      )

      rv$sim_params <- list(
        times = input$times,
        female_max_age = input$female_max_age,
        den_target = input$den_target,
        rest_target = input$rest_target,
        move_target = input$move_target,
        reproductive_age = input$reproductive_age,
        sex_ratio = input$sex_ratio,
        female_dispersal = input$female_dispersal,
        time_interval = input$time_interval
      )

      simulation_id <- stringr::str_replace_all(
        stringr::str_replace_all(
          paste(
            as.character(lubridate::now())#,
            # uuid::UUIDgenerate(use.time = TRUE)
          ),
          ':',
          ''
        ),
        ' ',
        '_'
      )
      
      download_path <- glue::glue('inst/app/{simulation_id}')
      fs::dir_create(download_path)
      
      # Save params
      sim_params_df <- as_tibble(rv$sim_params)
      saveRDS(object = sim_params_df, file = glue::glue("{download_path}/params.rds"))

      rv$sim_params$simulation_id <- simulation_id
      
      # parallel::mclapply(
      lapply(
        X = seq(1:sim_sequence),
        FUN = run_simulation,
        # mc.cores = parallel::detectCores(),
        scenario = selected_scenario,
        ssh_keyfile = ssh_keyfile,
        ssh_keyfile_name = ssh_keyfile_name,
        do_droplet_size = input$droplet_size,
        scenario_droplet_ip = scenario_droplet_ip,
        do_region = region,
        do_image = snap_image,
        simulation_logfile = simulation_logfile,
        simulation_logfile_lock = simulation_logfile_lock,
        progress = rv$progress,
        total_steps = total_steps,
        d_uploader = rv$d_uploader,
        sim_params = rv$sim_params,
        simulation_id = simulation_id,
        droplet_sequence = droplet_sequence
      )
    }
  )

  # Render report ----
  observeEvent(
    input$run_report,
    {
      cookies <- glouton::fetch_cookies()
      cores <- as.numeric(cookies$cores)
      
      # getwd()
      # setwd('R/apps/flex_cloud/')
      # rv <- list()
      # rv$sim_params$simulation_id <- '2023-03-12_143930'
      # cores <- 6

      if (input$report_currency == 'current') {
        dir <- paste0('inst/app/', rv$sim_params$simulation_id, '/downloads/')
      } else {
        dir <- paste0('inst/app/', input$report_simulation, '/downloads/')
      }
      
      params <- readRDS(file = glue::glue("{dir}../params.rds"))
      params <- params %>% 
        mutate(
          times = as.numeric(times),
          female_dispersal = as.numeric(female_dispersal)
        ) %>% 
        tidyr::pivot_longer(cols = colnames(params)) %>% 
        mutate(value = as.character(value))
      output$params_used <- renderTable(params)
      
      progressReport <- Progress$new(session, min = 1, max = 10)
      on.exit(progressReport$close())
      progressReport$set(
        message = 'Loading report data',
        detail = 'Fetching CSV files.'
      )
      
      csv_files <- list.files(path = dir, pattern = '^d[0-9]+i[0-9]+test_fisher_agents.csv$')
      
      data <- bind_rows(
        parallel::mclapply(
          csv_files, 
          mc.cores = cores,
          function(file, dir) {
            file <- paste0(dir, file)
            readr::read_csv(file)
          },
          dir
        )
      ) %>% 
        mutate(timeperiod = as.factor(timeperiod))
      
      progressReport$set(
        value = 2,
        detail = 'Processing CSV data.'
      )
      
      group_data <- data %>%
        group_by(timeperiod) %>%
        summarize(
          mean_val = mean(n_f_adult),
          lower_ci = mean_val - qt(0.975, n() - 1) * sd(n_f_adult) / sqrt(n()),
          upper_ci = mean_val + qt(0.975, n() - 1) * sd(n_f_adult) / sqrt(n())
        )

      progressReport$set(
        value = 3,
        detail = 'Plotting CSV data.'
      )
      
      output$plot_csv <- renderPlot(
        ggplot(
          data = data %>% mutate(timeperiod = as.factor(timeperiod)), 
          aes(
            x = timeperiod, y = n_f_adult
          )
        ) + 
          geom_point(size = 3, 
                     alpha = 0.2, 
                     colour = '#1A5A96') +
          stat_summary(
            fun.data = "mean_cl_normal",
            geom = "crossbar",
            colour = "#D8292F",
            linewidth = 0.75,
            width = 0.1,
            fatten = 2
          ) +
          geom_text(
            x = as.integer(group_data$timeperiod) + 0.1, 
            y = group_data$mean_val, 
            aes(
              label = paste0(
                "Upper CI: ", round(upper_ci, 2), "\n",
                "Mean: ", round(mean_val, 2), "\n",
                "Lower CI: ", round(lower_ci, 2)
              ),
              
            ),
            hjust = 0,
            data = group_data
          ) +
          ggtitle(
            paste0("Number of female adults per time period (", length(csv_files), " observations)")
          ) + 
          labs(
            x = "Time period", 
            y = "Number of female adults"
          ) + 
          theme_minimal()
      )
      
      ggsave(file=paste0(dir, "../n_f_adults.png"))

      progressReport$set(
        value = 4,
        detail = 'Fetching TIFF files.'
      )
      
      tif_files <- list.files(path = dir, pattern = '^d[0-9]+i[0-9]+test_final_fisher_territories.tif$')
      
      tic("Overall process")
      tic("Processing other tif files", quiet = TRUE)
      
      data_tif <- bind_rows(
        parallel::mclapply(
          tif_files, 
          mc.cores = cores,
          function(file, dir) {
            file <- paste0(dir, file)

            # Read raster file, cast to data frame and bind with all previous rasters
            as.data.frame(
              raster(file), xy = TRUE
            ) %>% 
              filter(layer > 0) %>%
              mutate(layer = 1)
          },
          dir
        )
      ) %>% 
        group_by(x, y) %>%
        summarize(layer = sum(layer))

      toc()

      tic("Visualizing tif files", quiet = TRUE)
      
      progressReport$set(
        value = 7,
        detail = 'Plotting TIFF files.'
      )
      
      g <- ggplot() +
        geom_raster(data = data_tif , aes(x = x, y = y, fill = layer)) +
        scale_fill_viridis_c(direction = -1) +
        coord_equal() +
        ggtitle(
          paste0("Composite raster file (", length(csv_files), " observations)")
        ) + 
        theme_minimal()
      
      toc() # Visualizing tif files
      toc() # Overall process
      
      output$plot_tif <- renderPlot(g)

      rm(data_tif)
      ggsave(file=paste0(dir, "../heatmap.png"))
      
      progressReport$set(
        value = 10,
        message = 'Done',
        detail = ''
      )
    }
  )

  # Simulation log ----
  simulation_log_data <- shiny::reactivePoll(
    1000, session,
    # This function returns the time that log_file was last modified
    checkFunc = function() {
      log_file = simulation_logfile
      if (file.exists(log_file))
        file.info(log_file)$mtime[1]
      else
        ""
    },
    # This function returns the content of log_file
    valueFunc = function() {
      log_file = simulation_logfile
      if (file.exists(log_file) & file.size(log_file) > 0) {
        read.csv(log_file)
      } else {
        data.frame(
          ID = c(),
          Scenario = c(),
          Progress = c(),
          Description = c(),
          Timestamp = c()
        )
      }
    }
  )

  output$simulation_log <- renderDataTable({
    data <- simulation_log_data()

    if (nrow(simulation_log_data()) > 0) {
      data <- data %>%
        group_by(Droplet) %>%
        top_n(1, ID) %>%
        ungroup() %>%
        arrange(Droplet) %>%
        select(-ID)
    }

    if (nrow(data) > 0) {
      if (nrow(data %>% filter(isTruthy(Droplet))) > 0) {
        non_finished <- data %>% 
          filter(
            Droplet != '',
            Description != 'PROCESS FINISHED'
          )
        
        print(non_finished)
        if (nrow(non_finished) == 0) {
          rv$progress$close()
          cost_uploader <- rv$d_uploader %>% droplets_cost()
          rv$d_uploader %>% droplet_delete()
          fs::file_delete('tmp/id_rsa.pub')

          enable('file_scenario')
          enable('droplet_size')
          enable('iterations')
          enable('times')
          enable('female_max_age')
          enable('den_target')
          enable('rest_target')
          enable('move_target')
          enable('reproductive_age')
          enable('sex_ratio')
          enable('female_dispersal')
          enable('time_interval')
          enable('run_scenario')
        }
      }
    }
    
    data
  })

  # Refresh droplets ----
  filter_by_tag <- function(x, tag) {
    tag %in% x
  }

  observeEvent(
    input$refresh_droplets,
    {
      droplets <- analogsea::droplets()
      droplets_df <- as.data.frame(do.call(rbind, droplets)) %>%
        select(id, name, memory, vcpus, disk, status, tags, created_at) %>%
        mutate(
          tags = map_lgl(
            tags,
            filter_by_tag,
            'flex_cloud'
          )
        ) %>%
        filter(tags == TRUE) %>%
        select(-tags)

      output$droplets <- renderTable(droplets_df)
    }
  )

  # Save settings ----
  observeEvent(
    input$save_settings,
    ignoreInit = TRUE,
    {
      req(input$key)

      # SSH config
      ssh_user <- "root"
      ssh_keyfile_tbl <- parseFilePaths(volumes, input$key)
      ssh_keyfile <- stringr::str_replace(ssh_keyfile_tbl$datapath, 'NULL/', '/')
      ssh_keyfile_name <- ssh_keyfile_tbl$name
      
      # Available CPU cores on local machine
      cores <- input$cores

      glouton::add_cookie('cores', cores, options = cookie_options(expires = 2026))
      glouton::add_cookie('key_path', ssh_keyfile, options = cookie_options(expires = 365))
      glouton::add_cookie('key_name', ssh_keyfile_name, options = cookie_options(expires = 365))
    }
  )

}

# Run the application
shinyApp(ui = ui, server = server)
