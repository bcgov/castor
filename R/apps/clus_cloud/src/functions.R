#' Run simulation
#'
#' @param scenario Simulation scenario
#' @param ssh_keyfile_tbl SSH key file
#' @param do_droplet_size Digital Ocean droplet size
#' @param do_volumes Digital Ocean existing volume snapshots holding the sqlite databases
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
  do_volumes,
  do_region,
  do_image,
  queue,
  simulation_logfile,
  simulation_logfile_lock
) {
  future({
    
    Sys.getenv("DO_PAT")
    db_host <- Sys.getenv('DB_HOST')
    db_port <- Sys.getenv('DB_PORT')
    db_name <- Sys.getenv('DB_NAME')
    db_user <- Sys.getenv('DB_USER')
    db_pass <- Sys.getenv('DB_PASS')
  
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
    
    # Create actual droplet that will do the knitting ----
    d <- analogsea::droplet_create(
      name = analogsea:::random_name(),
      size = do_droplet_size,
      region = do_region,
      image = do_image,
      ssh_keys = ssh_keyfile_name,
      tags = c('clus_cloud')
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
    
    Sys.sleep(10)
    
    # Create volume from snapshot ----
    existing_snapshots <- analogsea::snapshots(type = 'volume')
    existing_snapshots_names <- rlist::list.names(existing_snapshots)
    
    if (do_volumes %in% existing_snapshots_names) {
      existing_snapshot <- existing_snapshots[[grep(do_volumes, names(existing_snapshots))]]
      
      volume_name <- stringr::str_remove(
        stringr::str_remove_all(
          stringr::str_to_lower(
            paste0(do_volumes, scenario)
          ),
          '_'
        ),
        '.rmd'
      )
      
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
      v <- analogsea::volume_create(
        snapshot_id = existing_snapshot$id, 
        name = volume_name,
        size = 10,
        region = do_region,
        filesystem_label = 'sqlitedb'
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
    d %>% droplet_ssh("echo Connecting...", keyfile = ssh_keyfile)
    
    status <- paste0(
      "7,", scenario_name, ",60%,Cloning CLUS repo,", as.character(Sys.time())
    )
    
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status,
      file = simulation_logfile, 
      append = TRUE
    )
    filelock::unlock(lock)
    
    d %>%
      droplet_ssh(
        glue::glue("screen -S {volume_name} \
  mkdir -p /mnt/{volume_name}; \
  mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name}; \
  echo '/dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name} ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab; \
  git clone https://github.com/bcgov/clus; \
  cd clus; \
  git checkout cloud_deploy; \
  ln -s /mnt/{volume_name}/Lakes_TSA_clusdb.sqlite ~/clus/R/scenarios/Lakes_TSA/Lakes_TSA_clusdb.sqlite"),
        keyfile = ssh_keyfile
      )
    
    # Knit the scenario ----
    scenario_to_run <- glue::glue("knitr::knit('clus/R/scenarios/Lakes_TSA/{scenario_name}.Rmd')")

    tmp <- tempfile()
    writeLines(scenario_to_run, tmp)
    d %>% droplet_upload(tmp, "remote.R")
    
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
  
    d %>% droplet_ssh(
      glue::glue("export DB_HOST={db_host}; \
  export DB_PORT={db_port}; \
  export DB_NAME={db_name}; \
  export DB_USER={db_user}; \
  export DB_PASS={db_pass}; \
  Rscript remote.R"
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
    
    v %>% volume_detach(droplet = d, region = do_region)
    Sys.sleep(10)
    v %>% volume_delete()
    
    # Download kintted md ----
    status <- paste0(
      "10,", scenario_name, ",90%,Downloading knitted md file,", as.character(Sys.time())
    )
    
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE, timeout = 1000)
    write(
      status, 
      file = simulation_logfile, 
      append = TRUE
    )
    filelock::unlock(lock)
    
    d %>% droplet_download(
      remote = glue::glue('/root/{scenario_name}.md'),
      local = './inst/app/md/',
      keyfile = ssh_keyfile
    )
    
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
    
    # Return something other than the future so we don't block the UI
    return(NULL)
  })
}

#' Remove the full path for knitted scenario md files
#'
#' @param md_path Knitted md file full path relative to the CLUS repo
#'
#' @return
#' @export
#'
#' @examples
clean_md_path <- function(md_path) {
  md_path_parts <- stringr::str_split(md_path, '/', simplify = FALSE)
  md_path_parts[[1]][length(md_path_parts[[1]])]
}
