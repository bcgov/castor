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
  queue
) {
  # browser()
  Sys.getenv("DO_PAT")
  db_host <- Sys.getenv('DB_HOST')
  db_port <- Sys.getenv('DB_PORT')
  db_name <- Sys.getenv('DB_NAME')
  db_user <- Sys.getenv('DB_USER')
  db_pass <- Sys.getenv('DB_PASS')

  simulation_log <- 'inst/app/log/simulation_log.csv'
  # write(paste(as.character(Sys.time()), ",building from", do_image), file = simulation_log, append = TRUE)
  
  ssh_keyfile <- stringr::str_replace(ssh_keyfile_tbl$datapath, 'NULL/', '/')
  ssh_keyfile_name <- ssh_keyfile_tbl$name
  print(paste(as.character(Sys.time()), ",got key", ssh_keyfile_name))
  
  scenario_name <- stringr::str_split(
    string = scenario, 
    pattern = '\\.', 
    n = 2, 
    simplify = TRUE
  )[1,1]
  
  
  print(paste(as.character(Sys.time()), ",working on", scenario_name))
  queue$producer$fireNotify(paste(as.character(Sys.time()), ",working on", scenario_name))
  
  print(paste(as.character(Sys.time()), ",creating droplet: size", do_droplet_size, "region", do_region, "image", do_image))
  queue$producer$fireNotify(paste(as.character(Sys.time()), ",creating droplet: size", do_droplet_size, "region", do_region, "image", do_image))
  write(
    paste(as.character(Sys.time()), ",creating droplet: size", do_droplet_size, "region", do_region, "image", do_image), 
    file = simulation_log, 
    append = TRUE
  )
  
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
  
  print(paste(as.character(Sys.time()), ",created droplet: ID", d$id))
  queue$producer$fireNotify(paste(as.character(Sys.time()), ",created droplet: ID", d$id))
  write(paste(as.character(Sys.time()), ",created droplet: ID", d$id), 
    file = simulation_log, 
    append = TRUE
  )
  
  Sys.sleep(10)
  
  # incProgress(0.1, detail = "Creating volume and uploading sqlite database")
  
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
    
    print(paste(as.character(Sys.time()), ",about to create volume", volume_name))
    queue$producer$fireNotify(paste(as.character(Sys.time()), ",about to create volume", volume_name))
    write(paste(as.character(Sys.time()), ",about to create volume", volume_name), 
      file = simulation_log, 
      append = TRUE
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
      
    print(paste(as.character(Sys.time()), ",creating volume", volume_name, "from snapshot ID", existing_snapshot$id, "in the region", do_region))
    queue$producer$fireNotify(paste(as.character(Sys.time()), ",creating volume", volume_name, "from snapshot ID", existing_snapshot$id, "in the region", do_region))
    write(paste(as.character(Sys.time()), ",creating volume", volume_name, "from snapshot ID", existing_snapshot$id, "in the region", do_region), 
      file = simulation_log, 
      append = TRUE
    )
    v <- analogsea::volume_create(
      snapshot_id = existing_snapshot$id, 
      name = volume_name,
      size = 10,
      region = do_region,
      filesystem_label = 'sqlitedb'
    )
  }
  
  print(paste(as.character(Sys.time()), ",attaching volume ID", v$id, "to droplet ID", d$id))
  queue$producer$fireNotify(paste(as.character(Sys.time()), ",attaching volume ID", v$id, "to droplet ID", d$id))
  write(paste(as.character(Sys.time()), ",attaching volume ID", v$id, "to droplet ID", d$id), 
    file = simulation_log, 
    append = TRUE
  )
  volume_attach(volume = v, droplet = d, region = do_region)
  
  # incProgress(0.1, detail = "Uploading scenario parameters")
  
  print(paste(as.character(Sys.time()), ",connecting to droplet ID", d$id))
  queue$producer$fireNotify(paste(as.character(Sys.time()), ",connecting to droplet ID", d$id))
  write(paste(as.character(Sys.time()), ",connecting to droplet ID", d$id), 
    file = simulation_log, 
    append = TRUE
  )
  d %>% droplet_ssh("echo Connecting...", keyfile = ssh_keyfile)
  
  # volume_attach(volume = v, droplet = d, region = region)
  print(paste(as.character(Sys.time()), ",cloning CLUS repo to droplet ID", d$id))
  queue$producer$fireNotify(paste(as.character(Sys.time()), ",cloning CLUS repo to droplet ID", d$id))
  write(paste(as.character(Sys.time()), ",cloning CLUS repo to droplet ID", d$id), 
    file = simulation_log, 
    append = TRUE
  )
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
  
  # incProgress(0.1, detail = "Running the scenario")

  # Knit the scenario ----
  scenario_to_run <- glue::glue("rmarkdown::render('clus/R/scenarios/Lakes_TSA/{scenario_name}.Rmd', params = list(db_host = '{db_host}', db_port = '{db_port}', db_name = '{db_name}', db_user = '{db_user}', db_pass = '{db_pass}'))")
  # d %>%
  #   droplet_execute(eval(scenario_to_run))
                    
  tmp <- tempfile()
  writeLines(scenario_to_run, tmp)
  d %>% droplet_upload(tmp, "remote.R")
  
  print(paste(as.character(Sys.time()), ",knitting the scenario in droplet ID", d$id))
  queue$producer$fireNotify(paste(as.character(Sys.time()), ",knitting the scenario in droplet ID", d$id))
  write(paste(as.character(Sys.time()), ",knitting the scenario in droplet ID", d$id), 
    file = simulation_log, 
    append = TRUE
  )
  Sys.sleep(5)
  
  d %>% droplet_ssh("Rscript remote.R")
  
  # tmp <- tempdir()
  # d %>% droplet_download(".RData", tmp)
  # 
  # e <- new.env(parent = emptyenv())
  # load(file.path(tmp, ".RData"), envir = e)
  # 
  # as.list(e)
  
  # incProgress(0.5, detail = "Cleaning up")
  
  # Cleanup ----
  write(paste(as.character(Sys.time()), ",detaching and deleting volume ID", v$id), 
    file = simulation_log, 
    append = TRUE
  )
  v %>% volume_detach(droplet = d, region = do_region)
  Sys.sleep(10)
  v %>% volume_delete()
  
  # Download kintted md ----
  write(paste(as.character(Sys.time()), ",downloading knitted md file from droplet ID", d$id), 
    file = simulation_log, 
    append = TRUE
  )
  d %>% droplet_download(
    remote = glue::glue('/root/{scenario_name}.md'),
    local = './inst/app/md/',
    keyfile = ssh_keyfile
  )
  
  write(paste(as.character(Sys.time()), ",deleting droplet ID", d$id), 
    file = simulation_log, 
    append = TRUE
  )
  d %>% droplet_delete()
  
  write(paste(as.character(Sys.time()), ",FINISHED PROCESSING SCENARIO", scenario_name), 
    file = simulation_log, 
    append = TRUE
  )
  NULL
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
