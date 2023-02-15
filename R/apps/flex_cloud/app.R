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
# image <- snapshots$`flex-cloud-image-20230210`$id

# SSH config
ssh_user <- "root"

# Available sizes
sizes <- analogsea::sizes(per_page = 200) %>%
  filter(
    available == TRUE,
    grepl("tor1", region),
    !grepl("-amd", slug),
    !grepl("-intel", slug),
    memory > 8000
  ) %>%
  mutate(
    label = paste0(
      memory / 1024,
      'GB (', disk, 'GB disk, ',
      vcpus, ' vCPUs, ',
      scales::dollar(price_hourly, prefix = '', suffix = '¢', accuracy = 0.01, scale = 100),
      ' hourly)'
    )
  ) %>%
  select(slug, label)

size_choices <- setNames(
  as.character(sizes$slug),
  as.character(sizes$label)
)

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
              hr(),
              selectizeInput(
                'droplet_size',
                label = "Cloud server config",
                choices = NULL,
                selected = '',
                multiple = FALSE
              ),
              # hr(),
              sliderInput('iterations', label = 'Number of iterations', value = 2, min = 1, max = 100, step = 1),
              hr(),
              # female_max_age
              # den_target
              # rest_target
              # move_target
              # reproductive_age
              # sex_ratio
              # female_dispersal
              # timeInterval
              # iterations
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
              ),
              textInput(
                inputId = 'sim_iterations',  label = "Iterations", value = 1
              ),
              hr(),
              actionButton(
                'run_scenario',
                'Run scenario',
                icon = icon('play-circle'),
                class = 'btn-flex'
              )
            ),
            mainPanel(
              width = 8,
              tabsetPanel(
                tabPanel(
                  "Simulation log",
                  p("The log will appear in real time when you run the simulations based on selected options."),
                  dataTableOutput("simulation_log")
                ),
                tabPanel(
                  "Simulation output",
                  p("Use controls below to view and manage the simulation output files."),
                  # selectizeInput(
                  #   inputId = 'rendered_mds',
                  #   label = 'Review scenario output',
                  #   choices = NULL,
                  #   selected = '',
                  #   multiple = FALSE
                  # ),
                  # shiny::actionButton(
                  #   inputId = 'refresh_mds',
                  #   label = 'Refresh md list',
                  #   icon = icon('refresh')
                  # ),
                  # actionButton(
                  #   'include_md',
                  #   'Preview selected md',
                  #   icon = icon('file-alt'),
                  #   class = 'btn-flex-light'
                  # ),
                  # actionButton(
                  #   'delete_mds',
                  #   'Delete md files',
                  #   icon = icon('trash-alt'),
                  #   class = 'btn-danger'
                  # ),
                  # uiOutput("preview_md")
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
              p(
                'Select a private key to be used to be able to connect and manage
                Digital Ocean cloud resources.'
              ),
              shinyFilesButton(
                id = "key",
                label = "Select private key",
                title = "Please select a file",
                multiple = FALSE,
                viewtype = "detail",
                buttonType = 'info',
                icon = icon('key'),
                class = 'btn-flex-light'
              ),
            ),
            column(
              width = 6, offset = 1,
              p(
                'Check which private key (if any) is currently set to be used
                to connect and manage Digital Ocean cloud resources.'
              ),
              actionButton(
                inputId = "check_key",
                label = "Check private key",
                icon = icon('user-shield'),
                class = 'btn-flex-light'
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

  # db_host <- Sys.getenv('DB_HOST')
  # db_port <- Sys.getenv('DB_PORT')
  # db_name <- Sys.getenv('DB_NAME')
  # db_user <- Sys.getenv('DB_USER')
  # db_pass <- Sys.getenv('DB_PASS')

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
  shiny::updateSelectizeInput(
    session = getDefaultReactiveDomain(),
    'droplet_size',
    choices = size_choices,
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
    input$check_key,
    {
      output$key_selected <- renderPrint({
        cookies <- glouton::fetch_cookies()
        ssh_keyfile <- cookies$key_path
        ssh_keyfile_name <- cookies$key_name
        print(ssh_keyfile)
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

      if (length(ssh_keyfile) == 0 | length(ssh_keyfile_name) == 0) {
        shinyjs::alert('SSH key has not been set. Please go to Settings tab to configure it.')
      }
      req(length(ssh_keyfile) > 0 & length(ssh_keyfile_name) > 0)

      if (!file.exists(ssh_keyfile)) {
        shinyjs::alert('Configured SSH key does not exist. Please go to Settings tab to configure a new key.')
      }
      req(file.exists(ssh_keyfile))
      # stopifnot(input$droplet_size %in% sizes$slug)

      progressOne <- Progress$new(session, min = 1, max = 10)
      on.exit(progressOne$close())
      progressOne$set(message = 'Creating droplet to host the scenario',
                   detail = 'This will take about a minute.')
      
      
      # SSH config
      ssh_user <- "root"

      # browser()
      # Scenario
      selected_scenario <- input$file_scenario
      scenario_tbl <- shinyFiles::parseFilePaths(volumes, selected_scenario)
      scenarios <- scenario_tbl$name

      # DO scenario uploader config
      region <- 'tor1'
      uploader_image <- 'ubuntu-20-04-x64'
      uploader_size = 's-1vcpu-2gb'

      progressOne$set(1, detail = 'Creating droplet')
      
      d_uploader <- create_scenario_droplet(
        scenario = selected_scenario,
        ssh_keyfile = ssh_keyfile,
        ssh_keyfile_name = ssh_keyfile_name,
        ssh_user = ssh_user,
        progressOne = progressOne
      )
      # progressOne$close()

      if (is.null(d_uploader)) {
        shinyjs::alert("Error has occrred, please refresh the page and try again.")
      }
      req(d_uploader)
      
      scenario_droplet_ip <- get_private_ip(d_uploader)
      # d_uploader <- 'abc'
      # scenario_droplet_ip <- '10.1.2.3'

      progress <- AsyncProgress$new(message="Overall job progress")
      
      print(paste("Simulation log file ", simulation_logfile))

      # FLEX droplet image ----
      snapshots <- snapshots_with_params(per_page = 200)
      snap_image <- snapshots$`flex-cloud-image-20230210`$id
      print(paste("Building from snapshot ID ", snap_image))

      sim_sequence <- input$iterations
      total_steps <- sim_sequence * 14

      if (file.exists(simulation_logfile)) {
        file.remove(simulation_logfile)
        file.create(simulation_logfile)
      }

      write(
        paste0(
          "ID,Scenario,Progress,Description,Timestamp\n",
          "0,,,PROCESS STARTED,", as.character(Sys.time())
        ),
        file = simulation_logfile,
        append = FALSE
      )

      sim_params <- list(
        female_max_age = input$female_max_age,
        den_target = input$den_target,
        rest_target = input$rest_target,
        move_target = input$move_target,
        reproductive_age = input$reproductive_age,
        sex_ratio = input$sex_ratio,
        female_dispersal = input$female_dispersal,
        time_interval = input$time_interval,
        iterations = input$sim_iterations
      )

      # tryCatch({
        lapply(
        # future_lapply(
          X = seq(1:sim_sequence),
          FUN = run_simulation,
          scenario = selected_scenario,
          ssh_keyfile = ssh_keyfile,
          ssh_keyfile_name = ssh_keyfile_name,
          do_droplet_size = input$droplet_size,
          scenario_droplet_ip = scenario_droplet_ip,
          do_region = region,
          do_image = snap_image,
          simulation_logfile = simulation_logfile,
          simulation_logfile_lock = simulation_logfile_lock,
          progress = progress,
          total_steps = total_steps,
          d_uploader = d_uploader,
          sim_params = sim_params
        )
        # run_simulation(
        #   scenario = selected_scenario,
        #   ssh_keyfile = ssh_keyfile,
        #   ssh_keyfile_name = ssh_keyfile_name,
        #   do_droplet_size = input$droplet_size,
        #   scenario_droplet_ip = scenario_droplet_ip,
        #   do_region = region,
        #   do_image = snap_image,
        #   simulation_logfile = simulation_logfile,
        #   simulation_logfile_lock = simulation_logfile_lock,
        #   progress = progress,
        #   total_steps = total_steps,
        #   d_uploader = d_uploader
        # )
      # }, error = function(e) {
      #   # shiny:::reactiveStop(conditionMessage(e))
      #   debug_msg(e$message)
      #   shinyjs::alert("There was an error running the simulation, cleaning up.")
      #   # errored <- TRUE
      # })

      # browser()
      # Delete the scenario droplet
      # d_uploader %>% droplet_delete()

      # Return something other than the future so we don't block the UI
      # return(NULL)
    }
  )

  # Render knited md ----
  # observeEvent(
  #   input$include_md,
  #   {
  #     req(input$rendered_mds)
  #
  #     isolate(input$rendered_mds)
  #
  #     file_stats <- file.info(input$rendered_mds, extra_cols = FALSE)
  #     file_stats <- data.frame(
  #       'Created' = c(file_stats$mtime),
  #       'Size' = c(file_stats$size)
  #     )
  #     file_stats$Created <- as.character(file_stats$Created)
  #     file_stats$Size <- as.character(as_fs_bytes(file_stats$Size))
  #
  #     output$preview_md <- renderUI({
  #       tagList(
  #         h2('File info'),
  #         hr(),
  #         renderTable(file_stats),
  #         h2('File content'),
  #         hr(),
  #         includeMarkdown(input$rendered_mds)
  #       )
  #     })
  #   }
  # )

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
        group_by(Scenario) %>%
        top_n(1, ID) %>%
        ungroup() %>%
        arrange(Scenario) %>%
        select(-ID)
    }

    data
  })

  # Load saved simulation outputs ----
  # fisherSimOut <- readRDS('R/apps/flex_cloud/inst/app/fisherSimOut.Rdata')
  # This is only one... find the way to load

  # Refresh md files ----
  # observeEvent(
  #   input$refresh_mds,
  #   {
  #     all_mds <-
  #         # dir_ls('R/apps/flex_cloud/inst/app/md/', type = 'file', glob = '*.md') %>%
  #       dir_ls('inst/app/md/', type = 'file', glob = '*.md') %>%
  #       purrr::map_chr(clean_md_path)
  #
  #     all_mds <- setNames(names(all_mds), all_mds)
  #
  #     shiny::updateSelectizeInput(
  #       session = getDefaultReactiveDomain(),
  #       'rendered_mds',
  #       choices = all_mds,
  #       selected = '',
  #       server = TRUE
  #     )
  #   }
  # )

  # Delete md files ----
  # observeEvent(
  #   input$delete_mds,
  #   {
  #     all_mds <-
  #         # dir_ls('R/apps/flex_cloud/inst/app/md/', type = 'file', glob = '*.md') %>%
  #       dir_ls('inst/app/md/', type = 'file', glob = '*.md') %>%
  #       purrr::map(file.remove)
  #
  #     shiny::updateSelectizeInput(
  #       session = getDefaultReactiveDomain(),
  #       'rendered_mds',
  #       choices = NULL,
  #       selected = '',
  #       server = TRUE
  #     )
  #   }
  # )

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

  # Refresh billing ----
  # observeEvent(
  #   input$refresh_billing,
  #   {
  #     tryCatch({
  #       drv <- dbDriver('PostgreSQL')
  #       conn <- dbConnect(
  #         drv,
  #         dbname = db_name,
  #         host = db_host,
  #         port = db_port,
  #         user = db_user,
  #         password = db_pass
  #       )
  #       costs <- dbGetQuery(conn, "SELECT * FROM billing")
  #       output$billing <- renderDataTable(costs)
  #     },
  #     error = function(cond) {
  #       output$connection_status <- shiny::renderText('Unable to connect to the database.')
  #       print('Unable to connect to the database.')
  #     })
  #
  #   }
  # )

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

      glouton::add_cookie('key_path', ssh_keyfile)
      glouton::add_cookie('key_name', ssh_keyfile_name)
    }
  )

}

# Run the application
shinyApp(ui = ui, server = server)
