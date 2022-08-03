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
library(analogsea)
library(DBI)
library(RSQLite)
library(shinyFiles)
library(shinydashboard)
library(shinyjs)
library(future)
library(future.apply)
library(future.callr)

source('src/functions.R')

# plan(callr)
plan(sequential)

# Available scneario Rmd files
available_scenarios <- list.files('scenarios/')

available_sqlite <- list.files('sqlite/')

# Digital Ocean resources ----
api_base_url <- 'https://api.digitalocean.com/v2/'
endpoint_snapshots <- 'snapshots'
endpoint_droplets <- 'droplets'

region <- 'tor1'
uploader_image <- 'ubuntu-20-04-x64'
uploader_size = 's-1vcpu-1gb'

# CLUS droplet image
snapshots <- analogsea::snapshots()
image <- snapshots$`clus-cloud-image-202205042050`$id

# Available sizes
sizes <- analogsea::sizes() %>%
  filter(
    available == TRUE,
    grepl("tor1", region),
    !grepl("-amd", slug),
    !grepl("-intel", slug),
    memory > 16000
  ) %>%
  mutate(
    label = paste0(memory / 1024, 'GB (', disk, 'GB disk, $', price_monthly, ' monthly)')
  ) %>%
  select(slug, label)

size_choices <- setNames(
  as.character(sizes$slug),
  as.character(sizes$label)
)

# SSH config
ssh_user <- "root"
# ssh_keyfile <- "keys/ssh_keyfile_name"

# UI ----
ui <- shiny::tagList(
  dashboardPage(
    skin = 'black', title = 'CLUS Clound Deployment',
    header = dashboardHeader(
      title = 'CLUS Cloud Deployment',
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
        menuItem("Databases", tabName = "databases", icon = icon("database")),
        menuItem("Resources", tabName = "resources", icon = icon("server")),
        menuItem("Billing", tabName = "billing", icon = icon("search-dollar"))
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
                multiple = TRUE,
                viewtype = "detail",
                buttonType = 'info',
                icon = icon('file-code'),
                class = 'btn-clus-light'
              ),
              hr(),
              # verbatimTextOutput("file_sqlitedb_selected"),
              # shinyFilesButton(
              #   id = "file_sqlitedb",
              #   label = "Select SQLite db",
              #   title = "Please select a file",
              #   multiple = TRUE,
              #   viewtype = "detail",
              #   buttonType = 'info',
              #   icon = icon('database'),
              #   class = 'btn-clus-light'
              # ),
              hr(),
              selectizeInput(
                'droplet_size',
                label = "Select droplet size",
                choices = NULL,
                selected = '',
                multiple = FALSE
              ),
              hr(),
              # radioButtons(
              #   'volume_options',
              #   label = 'Volume options',
              #   choices = list(
              #     'Create new' = 'new',
              #     'Use existing' = 'existing'
              #   ),
              #   inline = FALSE
              # ),
              selectizeInput('volumes', label = 'Select a database', choices = NULL, selected = '', multiple = FALSE),
              # checkboxInput('preserve_volume', label = "Preserve sqlite DB volume", value = TRUE),
              hr(),
              verbatimTextOutput("key_selected"),
              shinyFilesButton(
                id = "key",
                label = "Select private key",
                title = "Please select a file",
                multiple = FALSE,
                viewtype = "detail",
                buttonType = 'info',
                icon = icon('key'),
                class = 'btn-clus-light'
              ),
              hr(),
              actionButton(
                'run_scenario',
                'Run scenario',
                icon = icon('play-circle'),
                class = 'btn-clus'
              ),
              actionButton(
                'include_md',
                'Preview md',
                icon = icon('file-alt'),
                class = 'btn-clus'
              )
            ),
            mainPanel(
              width = 8,
              uiOutput("preview_md")
            )
          )
        ),
        
        ## Databases ----
        tabItem(
          tabName = "databases",
          tabsetPanel(
            type = 'tabs',
            id = 'databases-tabset-panel',
            tabPanel(
              title = 'Database Snapshots',
              value = 'databases_snapshots',
              tagList(
                h3('Database Snapshots'),
                # tableOutput('database_snapshots'),
                dataTableOutput('database_snapshots'),
                shiny::actionButton(
                  inputId = 'refresh_database_snapshots',
                  label = 'Refresh',
                  icon = icon('refresh')
                )
              )
            ),
            tabPanel(
              title = 'New Database',
              value = 'new_database',
              tagList(
                h3('New Database'),
                sidebarLayout(
                  sidebarPanel(
                    width = 4,
                    tagList(
                      p('Select sqlite database to upload. The application will:'),
                      shiny::tags$ol(
                        shiny::tags$li('Create a volume'),
                        shiny::tags$li('Upload the database to it'),
                        shiny::tags$li('Create a volume snapshot'),
                        shiny::tags$li('Delete the volume'),
                      ),
                      p(
                        'The volume snapshot can be used to create
                        any number of volumes from it, to be used for running the 
                        different simulations using the same sqlite database.'
                      ),
                      verbatimTextOutput("file_sqlitedb_selected"),
                      shinyFilesButton(
                        id = "file_sqlitedb",
                        label = "Select SQLite db",
                        title = "Please select a file",
                        multiple = FALSE,
                        viewtype = "detail",
                        buttonType = 'info',
                        icon = icon('database'),
                        class = 'btn-clus-light'
                      ),
                      hr(),
                      verbatimTextOutput("key_selected_db"),
                      shinyFilesButton(
                        id = "key_db",
                        label = "Select private key",
                        title = "Please select a file",
                        multiple = FALSE,
                        viewtype = "detail",
                        buttonType = 'info',
                        icon = icon('key'),
                        class = 'btn-clus-light'
                      ),
                      hr(),
                      actionButton(
                        'new_database_create',
                        'Create database',
                        icon = icon('plus-circle'),
                        class = 'btn-clus'
                      )
                    )
                  ),
                  mainPanel(
                    width = 8,
                    tagList(
                      uiOutput("preview_new_database")
                    )
                  )
                )
              )
            ),
            tabPanel(
              title = 'Databases',
              value = 'databases',
              tagList(
                h3('Databases'),
                dataTableOutput('databases'),
                # tableOutput('databases'),
                shiny::actionButton(
                  inputId = 'refresh_databases',
                  label = 'Refresh',
                  icon = icon('refresh')
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
          h2('Billing')
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

  shinyFileChoose(
    input, "file_scenario", 
    roots = c('wd' = '.', 'scenarios' = paste0(getwd(), '/../../scenarios')), 
    filetypes = c('Rmd'),
    defaultPath = '', defaultRoot = 'scenarios', session = session
  )
  shinyFileChoose(
    input, "file_sqlitedb", 
    roots = c('wd' = '.', 'clus_repo' = paste0(getwd(), '/../../..'), 'root' = '/'), 
    filetypes = c('', 'sqlite'),
    defaultPath = '', defaultRoot = 'clus_repo', session = session
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

  shiny::updateSelectizeInput(
    session = getDefaultReactiveDomain(),
    'sqlite',
    choices = available_sqlite,
    selected = ''
  )

  shiny::updateSelectizeInput(
    session = getDefaultReactiveDomain(),
    'volumes',
    choices = volume_snapshot_names,
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

  output$file_sqlitedb_selected <- renderPrint({
    if (is.integer(input$file_sqlitedb)) {
      cat("SQLite database has not been selected")
    } else {
      parseFilePaths(volumes, input$file_sqlitedb)$name
    }
  })

  output$key_selected <- renderPrint({
    if (is.integer(input$key)) {
      cat("SSH key has not been selected")
    } else {
      parseFilePaths(volumes, input$key)$name
    }
  })

  output$key_selected_db <- renderPrint({
    if (is.integer(input$key_db)) {
      cat("SSH key has not been selected")
    } else {
      parseFilePaths(volumes, input$key_db)$name
    }
  })

  # Run simulation ----
  observeEvent(
    input$run_scenario,
    ignoreInit = TRUE,
    {
      browser()
      # req(input$scenario)
      # req(input$sqlite)
      req(input$file_scenario)
      req(input$volumes)
      req(input$droplet_size)
      # req(input$volume_options)

      stopifnot(input$droplet_size %in% sizes$slug)

      ssh_keyfile_tbl <- parseFilePaths(volumes, input$key)
      ssh_keyfile <- stringr::str_replace(ssh_keyfile_tbl$datapath, 'NULL/', '/')
      ssh_keyfile_name <- ssh_keyfile_tbl$name

      selected_scenarios <- input$file_scenario
      
      future.apply::future_lapply(
        selected_scenarios,
        run_simulation,
        # scenario = scenario,
        ssh_keyfile = ssh_keyfile_tbl,
        do_droplet_size = input$droplet_size,
        do_volumes = input$volumes,
        do_region = region,
        do_image = image,
        future.seed = TRUE
      )
      
      # run_simulation(
      #   scenario = selected_scenarios,
      #   ssh_keyfile_tbl = ssh_keyfile_tbl,
      #   do_droplet_size = input$droplet_size,
      #   do_volumes = input$volumes,
      #   do_region = region,
      #   do_image = image
      # )
      
      # scenario <- input$scenario
      # scenario_tbl <- parseFilePaths(volumes, input$file_scenario)
      # scenario <- scenario_tbl$name
      # scenario_path <- stringr::str_remove(scenario_tbl$datapath, 'NULL/')

      # withProgress(
      #   message = "Running scenario",
      #   value = 0,
      #   {
      #     incProgress(0.1, detail = "Creating droplet")


#           # Create actual droplet that will do the knitting ----
#           d <- analogsea::droplet_create(
#             name = analogsea:::random_name(),
#             size = input$droplet_size,
#             region = region,
#             image = image,
#             ssh_keys = ssh_keyfile_name,
#             tags = c('clus_cloud')
#           ) %>%
#             droplet_wait()
# 
#           Sys.sleep(15)
# 
#           incProgress(0.1, detail = "Creating volume and uploading sqlite database")
# 
#           # Create volume from snapshot ----
#           existing_snapshots <- analogsea::snapshots(type = 'volume')
#           existing_snapshots_names <- rlist::list.names(existing_snapshots)
#           
#           if (input$volumes %in% existing_snapshots_names) {
#             existing_snapshot <- existing_snapshots[[grep(input$volumes, names(existing_snapshots))]]
#             
#             volume_name <- stringr::str_remove(
#               stringr::str_remove(
#                 stringr::str_to_lower(
#                   paste0(input$volumes, scenario)
#                 ),
#                 '_'
#               ),
#               '.rmd'
#             )
# 
#             v <- analogsea::volume_create(
#               snapshot_id = existing_snapshot$id, 
#               name = volume_name,
#               size = 10,
#               region = region,
#               filesystem_label = 'sqlitedb'
#             )
#           }
#           
#           volume_attach(volume = v, droplet = d, region = region)
# 
#           incProgress(0.1, detail = "Uploading scenario parameters")
# 
#           d %>% droplet_ssh("echo Connecting...",
#             keyfile = ssh_keyfile
#           )
# 
#           # volume_attach(volume = v, droplet = d, region = region)
#           d %>%
#             droplet_ssh(
#               glue::glue("screen -S {volume_name} \
# mkdir -p /mnt/{volume_name}; \
# mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name}; \
# echo '/dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name} ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab; \
# git clone https://github.com/bcgov/clus; \
# cd clus; \
# ln -s /mnt/{volume_name}/Lakes_TSA_clusdb.sqlite ~/clus/R/scenarios/Lakes_TSA/Lakes_TSA_clusdb.sqlite"),
#               keyfile = ssh_keyfile
#             )
# 
#           incProgress(0.1, detail = "Running the scenario")
# 
#           # Knit the scenario ----
#           results <- d %>%
#             droplet_execute({
#               knitr::knit(glue::glue('clus/R/scenarios/Lakes_TSA/forestryCLUS_lakestsa.Rmd'))
#               # knitr::knit(glue::glue('knit.Rmd'))
#               wd <- getwd()
#               dc <- dir()
#             })
# 
#           incProgress(0.5, detail = "Cleaning up")
# 
#           # Cleanup ----
#           v %>% volume_detach(droplet = d, region = region)
#           Sys.sleep(10)
#           v %>% volume_delete()
# 
#           # Download kintted md ----
#           d %>% droplet_download(
#             remote = '/root/forestryCLUS_lakestsa.md',
#             # remote = '/root/knit.md',
#             local = './inst/app/md/',
#             keyfile = ssh_keyfile
#           )
# 
#           d %>% droplet_delete()
          
      #   }
      # )
    }
  )

  # Render knited md ----
  observeEvent(
    input$include_md,
    {
      output$preview_md <- renderUI({
        includeMarkdown('inst/app/md/forestryCLUS_lakestsa.md')
      })
    }
  )

  # Upload new database ----
  observeEvent(
    input$new_database_create,
    {
      browser()
      sqlitedb_tbl <- parseFilePaths(volumes, input$file_sqlitedb)
      sqlitedb <- sqlitedb_tbl$name
      sqlitedb_path <- stringr::str_remove(sqlitedb_tbl$datapath, 'NULL/')
      
      volume_snapshot_name <- stringr::str_to_lower(
        stringr::str_remove(
          stringr::str_remove_all(sqlitedb, '_'),
          '.sqlite'
        )
      )
      
      ssh_keyfile_db_tbl <- parseFilePaths(volumes, input$key_db)
      ssh_keyfile_db <- stringr::str_replace(ssh_keyfile_db_tbl$datapath, 'NULL/', '/')
      ssh_keyfile_db_name <- ssh_keyfile_db_tbl$name
      
      existing_snapshots <- analogsea::snapshots(type = 'volume')
      existing_snapshots_names <- rlist::list.names(existing_snapshots)

      if (volume_snapshot_name %in% existing_snapshots_names) {
        existing_snapshot <- existing_snapshots[[grep(volume_snapshot_name, names(existing_snapshots))]]
        analogsea::snapshot_delete(existing_snapshot)
      }
      
      ## Create sqlite DB uploader droplet ----
      d_uploader <- analogsea::droplet_create(
        name = analogsea:::random_name(),
        size = uploader_size,
        region = region,
        image = uploader_image,
        ssh_keys = ssh_keyfile_db_name,
        tags = c('clus_cloud')
      ) %>%
        droplet_wait()

      Sys.sleep(15)
      
      # Create volume to upload DB to ----
      volume_name <- stringr::str_to_lower(analogsea:::random_name())
      v <- volume_create(
        volume_name,
        size = 10,
        region = region,
        # snapshot_id = NULL,
        filesystem_label = 'sqlitedb'#,
        # tags = c('CLUS_cloud')
      )
      volume_attach(volume = v, droplet = d_uploader, region = region)
      # volume_attach(volume = v, droplet = d, region = region)
      
      # Format and mount the volume ----
      # d %>%
      d_uploader %>%
        droplet_ssh(
          glue::glue("sudo mkfs.ext4 /dev/disk/by-id/scsi-0DO_Volume_{volume_name}; \
                           mkdir -p /mnt/{volume_name}; \
                           mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name}; \
                           echo '/dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name} ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab"),
          keyfile = ssh_keyfile_db #
        )
      
      # Upload sqlite DB to the volume ----
      # d %>%
      d_uploader %>%
        droplet_upload(
          user = ssh_user,
          keyfile = ssh_keyfile_db,
          local = paste0('../../../', sqlitedb_path),
          remote = paste0("/mnt/", sqlitedb, '/', sqlitedb)
        )
      
      # Detach volume from the uploader droplet and delete the droplet ----
      v %>% volume_detach(droplet = d_uploader, region = region)
      d_uploader %>% droplet_delete()
      
      # Create volume snapshot 
      analogsea::volume_snapshot_create(v, volume_snapshot_name)
      
      # Delete volume
      analogsea::volume_delete(v)
      
      shinyjs::alert("Done.")
    }
  )

  # Refresh droplets ----
  observeEvent(
    input$refresh_droplets,
    {
      droplets <- analogsea::droplets()
      droplets_df <- as.data.frame(do.call(rbind, droplets)) %>% 
        select(id, name, memory, vcpus, disk, status, created_at)
      
      output$droplets <- renderTable(droplets_df)
    }
  )

  # Refresh volume snapshots ----
  observeEvent(
    input$refresh_database_snapshots,
    {
      db_snapshots <- rlist::list.stack(
        analogsea::snapshots(type = 'volume')
      )
      db_snapshots <- as.data.frame(db_snapshots) %>% 
        select(id, name, created_at, min_disk_size, size_gigabytes)
      
      # output$database_snapshots <- renderTable(db_snapshots)
      output$database_snapshots <- renderDataTable(db_snapshots)
    }
  )

  # Refresh volumes ----
  observeEvent(
    input$refresh_databases,
    {
      dbs <- analogsea::volumes()
      dbs_df <- as.data.frame(do.call(rbind, dbs)) 
      if (nrow(dbs_df) > 0) {
        dbs_df <- dbs_df %>% 
          select(id, name, created_at, size_gigabytes)
      }
      
      # output$databases <- renderTable(dbs_df)
      output$databases <- renderDataTable(dbs_df)
    }
  )

}

# Run the application
shinyApp(ui = ui, server = server)
