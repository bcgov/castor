run_simulation <- function(
  scenario,
  ssh_keyfile_tbl,
  do_droplet_size,
  do_volumes,
  do_region,
  do_image
) {
  # browser()
  
  ssh_keyfile <- stringr::str_replace(ssh_keyfile_tbl$datapath, 'NULL/', '/')
  ssh_keyfile_name <- ssh_keyfile_tbl$name
  
  # scenario_tbl <- shinyFiles::parseFilePaths(volumes, scenario)
  # scenario <- scenario_tbl$name
  
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
    
    v <- analogsea::volume_create(
      snapshot_id = existing_snapshot$id, 
      name = volume_name,
      size = 10,
      region = do_region,
      filesystem_label = 'sqlitedb'
    )
  }
  
  volume_attach(volume = v, droplet = d, region = do_region)
  
  # incProgress(0.1, detail = "Uploading scenario parameters")
  
  d %>% droplet_ssh("echo Connecting...", keyfile = ssh_keyfile)
  
  # volume_attach(volume = v, droplet = d, region = region)
  d %>%
    droplet_ssh(
      glue::glue("screen -S {volume_name} \
mkdir -p /mnt/{volume_name}; \
mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name}; \
echo '/dev/disk/by-id/scsi-0DO_Volume_{volume_name} /mnt/{volume_name} ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab; \
git clone https://github.com/bcgov/clus; \
git checkout cloud_deploy; \
cd clus; \
ln -s /mnt/{volume_name}/Lakes_TSA_clusdb.sqlite ~/clus/R/scenarios/Lakes_TSA/Lakes_TSA_clusdb.sqlite"),
      keyfile = ssh_keyfile
    )
  
  # incProgress(0.1, detail = "Running the scenario")
  
  # Knit the scenario ----
  d %>%
    droplet_execute({
      knitr::knit(glue::glue('clus/R/scenarios/Lakes_TSA/forestryCLUS_lakestsa.Rmd'))
      # knitr::knit(glue::glue('knit.Rmd'))
      wd <- getwd()
      dc <- dir()
    })
  
  # incProgress(0.5, detail = "Cleaning up")
  
  # Cleanup ----
  v %>% volume_detach(droplet = d, region = do_region)
  Sys.sleep(10)
  v %>% volume_delete()
  
  # Download kintted md ----
  d %>% droplet_download(
    remote = '/root/forestryCLUS_lakestsa.md',
    local = './inst/app/md/',
    keyfile = ssh_keyfile
  )
  
  d %>% droplet_delete()
  NULL
}


