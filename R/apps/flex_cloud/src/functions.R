#' Run simulation
#'
#' @param scenario Simulation scenario
#' @param ssh_keyfile_tbl SSH key file
#' @param do_droplet_size Digital Ocean droplet size
#' @param do_volume Digital Ocean existing volume snapshots holding the scenarios
#' @param do_region Digital Ocean region
#' @param do_image Digital Ocean image with preinstalled packages to run the simulation
#' @param queue ipc queue
#'
#' @return
#' @export
#'
#' @examples
run_simulation <- function(
  scenario,
  ssh_keyfile_tbl,
  do_droplet_size,
  do_volume,
  do_region,
  do_image,
  queue,
  simulation_logfile,
  simulation_logfile_lock,
  progress,
  total_steps
) {
  # future({

    Sys.getenv("DO_PAT")

    ssh_keyfile <- stringr::str_replace(ssh_keyfile_tbl$datapath, 'NULL/', '/')
    ssh_keyfile_name <- ssh_keyfile_tbl$name
    print(paste(as.character(Sys.time()), ",got key", ssh_keyfile_name))

    scenario_name <- stringr::str_split(
      string = scenario,
      pattern = '\\.',
      n = 2,
      simplify = TRUE
    )[1,1]

    status <- paste0(
      "1,", scenario_name, ",0%,START PROCESSING,", as.character(Sys.time())
    )

    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    status <- paste0(
      "2,", scenario_name, ",10%,Creating droplet,", as.character(Sys.time())
    )

    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    d_name <- analogsea:::random_name()

    # Create actual droplet that will do the knitting ----
    d <- analogsea::droplet_create(
      name = d_name,
      size = do_droplet_size,
      region = do_region,
      image = do_image,
      ssh_keys = ssh_keyfile_name,
      tags = c('flex_cloud')
    ) %>%
      droplet_wait()

    status <- paste0(
      "3,", scenario_name, ",20%,Droplet created,", as.character(Sys.time())
    )

    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    Sys.sleep(10)

    # Create volume from snapshot ----
    existing_snapshots <- analogsea::snapshots(type = 'volume')
    existing_snapshots_names <- rlist::list.names(existing_snapshots)

    if (do_volume %in% existing_snapshots_names) {
      existing_snapshot <- existing_snapshots[[grep(do_volume, names(existing_snapshots))]]

      # volume_name <- stringr::str_remove(
      #   stringr::str_remove_all(
      #     stringr::str_to_lower(
      #       paste0(do_volume)
      #     ),
      #     '_'
      #   ),
      #   '.tif'
      # )
#       volume_name <- stringr::str_to_lower(analogsea:::random_name())
# print(volume_name)
      # Check if volume with the same name already exists
      # v <- analogsea::volume(volume_name)
      # if (length(v) > 0) {
      #   print(paste(as.character(Sys.time()), ",found following volume", v$id, "exists with volume_name", volume_name))
      #   print(paste(as.character(Sys.time()), ",trying to detach and delete volume", v$id))
      #   if (v %>% analogsea::as.volume())
      #   v %>%
      #     volume_detach(droplet = d, region = do_region) %>%
      #     volume_delete()
      # }

      status <- paste0(
        "4,", scenario_name, ",30%,Creating database volume,", as.character(Sys.time())
      )
      lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
      write(
        status,
        file = simulation_logfile,
        append = TRUE
      )
      filelock::unlock(lock)
      progress$inc(1 / total_steps)
# browser()
      v <- analogsea::volume_create(
        snapshot_id = existing_snapshot$id,
        name = do_volume,
        size = 10,
        region = do_region,
        filesystem_label = 'scenario'
      )
    }

    status <- paste0(
      "5,", scenario_name, ",40%,Attaching volume to droplet,", as.character(Sys.time())
    )

    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    volume_attach(volume = v, droplet = d, region = do_region)

    status <- paste0(
      "6,", scenario_name, ",50%,Connecting to droplet,", as.character(Sys.time())
    )
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    d %>% droplet_ssh("echo Connecting...", keyfile = ssh_keyfile)

    status <- paste0(
      "7,", scenario_name, ",60%,Cloning castor repo,", as.character(Sys.time())
    )

    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)
browser()
    tryCatch({
      d %>%
        droplet_ssh(
          glue::glue("screen -S scenario; \
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash; \
mkdir -p /mnt/scenario; \
mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_{do_volume} /mnt/scenario; \
echo '/dev/disk/by-id/scsi-0DO_Volume_{do_volume} /mnt/scenario ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab; \
git clone https://github.com/sasha-ruby/castor; \
cd castor; \
git checkout flex_cloud; \
mkdir -p ~/castor/R/scenarios/fisher/inputs; \
ln -s /mnt/scenario/scenario.tif ~/castor/R/scenarios/fisher/inputs/scenario.tif;"),
          keyfile = ssh_keyfile
        )
    }, error = function(e) {
      # shiny:::reactiveStop(conditionMessage(e))
      debug_msg(e$message)
    })

    # Knit the scenario ----
    # scenario_to_run <- glue::glue("knitr::knit('castor/R/SpaDES-modules/FLEX2/fisher.R')")

    # tmp <- tempfile()
    # writeLines(scenario_to_run, tmp)
    # d %>% droplet_upload(tmp, "remote.R")

    status <- paste0(
      "8,", scenario_name, ",70%,Running the simulation,", as.character(Sys.time())
    )
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    d %>% droplet_ssh(
      glue::glue("cd castor/; Rscript R/SpaDES-modules/FLEX2/fisher.R"
      ),
      keyfile = ssh_keyfile
    )

    # Cleanup ----
    status <- paste0(
      "9,", scenario_name, ",80%,Detaching and deleting the volume,", as.character(Sys.time())
    )
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    cost <- d %>% droplets_cost()

#     create_table_query <- "CREATE TABLE IF NOT EXISTS billing (id SERIAL PRIMARY KEY, scenario_name varchar(255), droplet_name varchar(255), droplet_size varchar(40), volume_name varchar(255), cost varchar(40), _updated_at TIMESTAMP without time zone NULL DEFAULT clock_timestamp())"
#     insert_query <- glue::glue("INSERT INTO billing (scenario_name, droplet_name, droplet_size, volume_name, cost) VALUES ('{scenario_name}', '{d_name}', '{do_droplet_size}', '{do_volume}', '{cost}')")
#     billing_sql <- paste0("library(DBI)
# library(RPostgreSQL)
# tryCatch({drv <- dbDriver('PostgreSQL')
# conn <- dbConnect(drv, dbname = \"", db_name, "\", host = \"", db_host, "\", port = \"", db_port, "\", user = \"", db_user, "\", password = \"", db_pass, "\")
# dbSendQuery(conn, '", create_table_query, "')
# dbSendQuery(conn, \"", insert_query, "\")
# },
# error = function(cond) {
# print('Unable to connect to Database.')
# })"
#     )
# 
#     tmp <- tempfile()
#     writeLines(billing_sql, tmp)
#     d %>% droplet_upload(tmp, "record_cost.R")
# 
#     d %>% droplet_ssh(
#       glue::glue("Rscript record_cost.R"),
#       keyfile = ssh_keyfile
#     )


    v %>% volume_detach(droplet = d, region = do_region)
    Sys.sleep(10)
    v %>% volume_delete()

    # Download kintted md ----
    # status <- paste0(
    #   "10,", scenario_name, ",90%,Downloading knitted md file,", as.character(Sys.time())
    # )
    # lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    # write(
    #   status,
    #   file = simulation_logfile,
    #   append = TRUE
    # )
    # filelock::unlock(lock)
    # progress$inc(1 / total_steps)
    # 
    # d %>% droplet_download(
    #   remote = glue::glue('/root/{scenario_name}.md'),
    #   local = './inst/app/md/',
    #   keyfile = ssh_keyfile
    # )
    # 
    status <- paste0(
      "11,", scenario_name, ",100%,Deleting the droplet,", as.character(Sys.time())
    )
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    d %>% droplet_delete()

    status <- paste0(
      "12,", scenario_name, ",,PROCESS FINISHED,", as.character(Sys.time())
    )
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)

    # Return something other than the future so we don't block the UI
    return(NULL)
  # })
}

#' Remove the full path for knitted scenario md files
#'
#' @param md_path Knitted md file full path relative to the FLEX repo
#'
#' @return
#' @export
#'
#' @examples
clean_md_path <- function(md_path) {
  md_path_parts <- stringr::str_split(md_path, '/', simplify = FALSE)
  md_path_parts[[1]][length(md_path_parts[[1]])]
}

create_scenario_volume <- function(
    scenario,
    ssh_keyfile_tbl
) {
  # browser()
  # DO scenario uploader config
  region <- 'tor1'
  uploader_image <- 'ubuntu-22-04-x64'
  # uploader_size = 's-1vcpu-1gb'
  uploader_size = 's-1vcpu-2gb'
  
  # Scenario
  selected_scenario_tbl <- parseFilePaths(volumes, scenario)
  selected_scenario <- selected_scenario_tbl$name
  selected_scenario_path <- stringr::str_remove(selected_scenario_tbl$datapath, 'NULL/')
  
  volume_snapshot_name <- stringr::str_to_lower(
    stringr::str_remove(
      stringr::str_remove_all(selected_scenario, '_'),
      '.tif'
    )
  )
  
  # SSH config
  ssh_user <- "root"
  ssh_keyfile <- stringr::str_replace(ssh_keyfile_tbl$datapath, 'NULL/', '/')
  ssh_keyfile_name <- ssh_keyfile_tbl$name
  
  existing_snapshots <- snapshots_with_params(type = 'volume', per_page = 200)
  existing_snapshots_names <- rlist::list.names(existing_snapshots)
  
  if (volume_snapshot_name %in% existing_snapshots_names) {
    existing_snapshot <- existing_snapshots[[grep(volume_snapshot_name, names(existing_snapshots))]]
    analogsea::snapshot_delete(existing_snapshot)
  }
  
  ## Create scenario uploader droplet ----
  d_uploader <- analogsea::droplet_create(
    name = analogsea:::random_name(),
    size = uploader_size,
    region = region,
    image = uploader_image,
    ssh_keys = ssh_keyfile_name,
    tags = c('flex_cloud')
  ) %>%
    droplet_wait()
  
  Sys.sleep(60)
  
  # Create volume to upload the scenario file to it ----
  volume_name <- stringr::str_to_lower(analogsea:::random_name())
  # volume_name <- stringr::str_remove(
  #   stringr::str_remove_all(
  #     stringr::str_to_lower(
  #       paste0(do_volume, scenario)
  #     ),
  #     '_'
  #   ),
  #   '.rmd'
  # )
  v <- volume_create(
    volume_name,
    size = 10,
    region = region,
    # snapshot_id = NULL,
    filesystem_label = 'scenario'#,
    # tags = c('flex_cloud')
  )
  
  volume_attach(volume = v, droplet = d_uploader, region = region)
  # volume_attach(volume = v, droplet = d, region = region)
  
  # Format and mount the volume ----
  # browser()
  d_uploader %>%
    droplet_ssh(
      glue::glue("sudo mkfs.ext4 /dev/disk/by-id/scsi-0DO_Volume_{volume_name}; \
                       mkdir -p /mnt/scenario; \
                       mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/scenario; \
                       echo '/dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/scenario ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab"),
      keyfile = ssh_keyfile #
    )
  
  # Upload scenario to the volume ----
  # browser()
  d_uploader %>%
    droplet_upload(
      user = ssh_user,
      keyfile = ssh_keyfile,
      local = paste0('scenarios/', selected_scenario_path),
      # remote = paste0('/mnt/scenario/', selected_scenario)
      remote = paste0('/mnt/scenario/scenario.tif')
    )
  
  # browser()
  
  # Detach volume from the uploader droplet and delete the droplet ----
  v %>% volume_detach(droplet = d_uploader, region = region)
  d_uploader %>% droplet_delete()
  
  # Create volume snapshot ----
  analogsea::volume_snapshot_create(v, volume_snapshot_name)
  
  # Delete volume ---- 
  analogsea::volume_delete(v)
  
  volume_snapshot_name
}

# @TODO: This function is needed only until analogsea PR 
# https://github.com/pachadotdev/analogsea/pull/218
# is merged and package updated
snapshots_with_params <- function(type = NULL, page = 1, per_page = 20, ...) {
  per_page = min(per_page, 200)
  analogsea:::as.snapshot(
    analogsea:::do_GET(
      analogsea:::snapshot_url(), 
      query = analogsea:::ascompact(
        list(
          resource_type = type,
          page = page, 
          per_page = per_page
        )
      ), 
      ...
    )
  )
}

#' Print error message when caught
#'
#' @param ... Error message
#'
#' @return
#' @export
debug_msg <- function(...) {
  # is_local <- Sys.getenv('SHINY_PORT') == ""
  # in_shiny <- !is.null(shiny::getDefaultReactiveDomain())
  txt <- toString(list(...))
  # if (is_local) {
  #   message(txt)
  # }
  # if (in_shiny) {
    # shinyjs::runjs(sprintf("console.debug(\"%s\")", txt))
    showNotification(paste('The error occorred:', txt), '', type = "error")
  # }
}



