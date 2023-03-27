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
    iteration,
    scenario,
    ssh_keyfile,
    ssh_keyfile_name,
    do_droplet_size,
    scenario_droplet_ip,
    do_region,
    do_image,
    queue,
    simulation_logfile,
    simulation_logfile_lock,
    progress,
    total_steps,
    d_uploader,
    sim_params,
    simulation_id,
    droplet_sequence
) {
  # browser()
  download_path <- glue::glue('inst/app/{simulation_id}/')
  fs::dir_create(download_path)
  
  # capture.output(unlist(sim_params), file = glue::glue("{download_path}params.txt"))
  
  sim_params$iteration <- iteration

  future({
    options(do.wait_time = 15)
    
    errored <- FALSE
    
    Sys.getenv("DO_PAT")
    
    # SSH config
    ssh_user <- "root"
    
    print(paste(as.character(Sys.time()), ",got key", ssh_keyfile_name))
    
    selected_scenario_tbl <- parseFilePaths(volumes, scenario)
    selected_scenario <- selected_scenario_tbl$name
    selected_scenario_path <- stringr::str_remove(selected_scenario_tbl$datapath, 'NULL/')
    
    status <- paste0(
      "1,", paste0("Iteration ", iteration), ",0%,START PROCESSING,", as.character(Sys.time()), ","
    )
    
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)
    
    status <- paste0(
      "2,", paste0("Iteration ", iteration), ",10%,Creating droplet,", as.character(Sys.time()), ","
    )
    
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)
    
    d_name <- do_namify(paste0(ids::adjective_animal(), iteration))

    tryCatch({
      d <- analogsea::droplet_create(
        name = d_name,
        size = do_droplet_size,
        region = do_region,
        image = do_image,
        ssh_keys = ssh_keyfile_name,
        tags = c('flex_cloud')
      ) %>%
        droplet_wait()
      print(paste("Droplet created, ID:", d$id))
    }, error = function(e) {
      status <- paste0(
        "3,", paste0("Iteration ", iteration), ",20%,ERROR:", glue::trim(e), ". Cleaning up.,", as.character(Sys.time()), ","
      )
      lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
      write(
        status,
        file = simulation_logfile,
        append = TRUE
      )
      filelock::unlock(lock)
      
      # debug_msg(e$message)
      # shinyjs::alert("There was an error connecting to the droplet, retrying.")
      errored <- TRUE
    })

    if (!errored) {
      status <- paste0(
        "3,", paste0("Iteration ", iteration), ",20%,Awaiting connectivity,", as.character(Sys.time()), ","
      )
      
      lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
      write(
        status,
        file = simulation_logfile,
        append = TRUE
      )
      filelock::unlock(lock)
      progress$inc(1 / total_steps)
      
      Sys.sleep(5)
      
      status <- paste0(
        "4,", paste0("Iteration ", iteration), ",30%,Connecting to droplet,", as.character(Sys.time()), ","
      )
      lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
      write(
        status,
        file = simulation_logfile,
        append = TRUE
      )
      filelock::unlock(lock)
      progress$inc(1 / total_steps)
      
      # d <- droplet(d$id)
      
      tryCatch({
        d %>% droplet_ssh("echo Connecting...", keyfile = ssh_keyfile)
      }, error = function(e) {
        status <- paste0(
          "5,", paste0("Iteration ", iteration), ",30%,Couldn't connect to droplet - retrying,", as.character(Sys.time()), ","
        )
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        
        # debug_msg(e$message)
        # shinyjs::alert("There was an error connecting to the droplet, retrying.")
        # errored <- TRUE
        Sys.sleep(30)
      })
      
      status <- paste0(
        "6,", paste0("Iteration ", iteration), ",40%,Cloning castor repo,", as.character(Sys.time()), ","
      )
      
      lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
      write(
        status,
        file = simulation_logfile,
        append = TRUE
      )
      filelock::unlock(lock)
      progress$inc(1 / total_steps)
      # browser()
  # git checkout flex_cloud; \
      tryCatch({
        d %>%
          droplet_ssh(
            glue::glue("curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash; \
  git clone https://github.com/bcgov/castor; \
  cd castor; \
  mkdir -p ~/castor/R/scenarios/fisher/inputs; \
  mkdir -p /tmp/fisher/;"),
  keyfile = ssh_keyfile
          )
      }, error = function(e) {
        status <- paste0(
          "7,", paste0("Iteration ", iteration), ",40%,ERROR cloning castor repo,", as.character(Sys.time()), ","
        )
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        # debug_msg(e$message)
        # shinyjs::alert("There was an error setting up the castor repo, cleaning up.")
        errored <- TRUE
      })
    }

    if (!errored) {
      tryCatch({
        # Download pubkey from droplet to tmp directory ----
        status <- paste0(
          "8,", paste0("Iteration ", iteration), ",50%,Getting scenario public key,", as.character(Sys.time()), ","
        )
        
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        progress$inc(1 / total_steps)
        
        droplet_download(
          d, 
          remote = '/root/.ssh/id_rsa.pub', 
          local = 'tmp/', 
          keyfile = ssh_keyfile
        )
        
        # Add pubkey to authorized_keys on scenario droplet ----
        status <- paste0(
          "9,", paste0("Iteration ", iteration), ",60%,Adding public key,", as.character(Sys.time()), ","
        )
        
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        progress$inc(1 / total_steps)
        
        droplet_upload(
          d_uploader, 
          local = 'tmp/id_rsa.pub', 
          remote = '/root/id_rsa.pub', 
          keyfile = ssh_keyfile
        )
        
        status <- paste0(
          "10,", paste0("Iteration ", iteration), ",65%,Adding key to authorized keys,", as.character(Sys.time()), ","
        )
        
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        progress$inc(1 / total_steps)
        
        d_uploader %>%
          droplet_ssh(
            glue::glue("cat /root/id_rsa.pub >> '/root/.ssh/authorized_keys'"),
            keyfile = ssh_keyfile
          )
        
      }, error = function(e) {
        status <- paste0(
          "10,", paste0("Iteration ", iteration), ",60%,ERROR adding key to authorized keys - cleaning up,", as.character(Sys.time()), ","
        )
        
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        errored <- TRUE
      })
    }
    
    # Add scenario droplet private IP address to known hosts on the droplet ----
    # Copy the scenario file from scenario droplet to droplet ----
    if (!errored) {
      tryCatch({
        status <- paste0(
          "11,", paste0("Iteration ", iteration), ",70%,Copying scenario to droplet,", as.character(Sys.time()), ","
        )
        
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        progress$inc(1 / total_steps)
        
        d %>%
          droplet_ssh(
            glue::glue("ssh-keyscan {scenario_droplet_ip} >> ~/.ssh/known_hosts; \
scp root@{scenario_droplet_ip}:/root/scenario.tif ~/castor/R/scenarios/fisher/inputs"),
            keyfile = ssh_keyfile
          )
      }, error = function(e) {
        status <- paste0(
          "11,", paste0("Iteration ", iteration), ",70%,ERROR copying scenario to droplet from", scenario_droplet_ip, ",", as.character(Sys.time()), ","
        )
        
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        errored <- TRUE
      })
    }
    
    if (!errored) {
      status <- paste0(
        "12,", paste0("Iteration ", iteration), ",80%,Running the simulation,", as.character(Sys.time()), ","
      )
      lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
      write(
        status,
        file = simulation_logfile,
        append = TRUE
      )
      filelock::unlock(lock)
      progress$inc(1 / total_steps)
      # browser()
      # Running the simulation ----
      tryCatch({
        run_iteration(
          droplet_sequence,
          d,
          sim_params,
          ssh_keyfile,
          simulation_id,
          iteration
        )
      }, error = function(e) {
        status <- paste0(
          "13,", paste0("Iteration ", iteration), ",80%,ERROR running the simulation,", as.character(Sys.time()), ","
        )
        lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
        write(
          status,
          file = simulation_logfile,
          append = TRUE
        )
        filelock::unlock(lock)
        # debug_msg(e$message)
        # shinyjs::alert("There was an error running the simulation, cleaning up.")
        errored <- TRUE
      })
    }

    # Download simulation output ----
    if (!errored) {
      status <- paste0(
        "14,", paste0("Iteration ", iteration), ",95%,Downloading simulation output,", as.character(Sys.time()), ","
      )
      lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
      write(
        status,
        file = simulation_logfile,
        append = TRUE
      )
      filelock::unlock(lock)
      progress$inc(1 / total_steps)
    }
    
    status <- paste0(
      "15,", paste0("Iteration ", iteration), ",100%,Deleting the droplet,", as.character(Sys.time()), ","
    )
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)
    
    cost <- d %>% droplets_cost()
    
    d %>% droplet_delete()
    
    status <- paste0(
      "16,", paste0("Iteration ", iteration), ",,PROCESS FINISHED,", as.character(Sys.time()), ",", cost$total
    )
    lock <- filelock::lock(path = simulation_logfile_lock, exclusive = TRUE)
    write(
      status,
      file = simulation_logfile,
      append = TRUE
    )
    filelock::unlock(lock)
    progress$inc(1 / total_steps)
    
    # Return something other than the future so we don't block the UI
    return(NULL)
  })
}

run_iteration <- function(d_iteration, d, sim_params, ssh_keyfile, simulation_id, iteration) {
  # browser()
  # Simulation parameters
  times <- sim_params$times
  female_max_age <- sim_params$female_max_age
  den_target <- sim_params$den_target
  rest_target <- sim_params$rest_target
  move_target <- sim_params$move_target
  reproductive_age <- sim_params$reproductive_age
  sex_ratio <- sim_params$sex_ratio
  female_dispersal <- sim_params$female_dispersal
  time_interval <- sim_params$time_interval
  # filename <- uuid::UUIDgenerate(use.time = TRUE)

  download_path <- glue::glue('inst/app/{simulation_id}/')
  # fs::dir_create(download_path)
  command_run <- glue::glue("cd castor/; Rscript R/SpaDES-modules/FLEX2/fisher.R {times} {female_max_age} {den_target} {rest_target} {move_target} {reproductive_age} {sex_ratio} {female_dispersal} {time_interval} {d_iteration}; ")

  output_dir <- '/root/castor/R/scenarios/fisher/outputs'
  downloads_dir <- '/root/castor/R/scenarios/fisher/downloads'
  command_move_files <- glue::glue("mkdir -p {downloads_dir}; i=1; for DIRNAME in {output_dir}/*/; do for FILENAME in $DIRNAME/*; do cp $FILENAME {downloads_dir}/d{iteration}i$i`basename $FILENAME`; done; i=$((i+1)); done")

  command <- paste(command_run, command_move_files)

  # Move files to a single directory
  d %>% droplet_ssh(
    command,
    keyfile = ssh_keyfile
  )
  
  # Download files
  d %>% droplet_download(
    remote = downloads_dir,
    local = download_path,
    keyfile = ssh_keyfile
  )
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

create_scenario_droplet <- function(
    scenario,
    ssh_keyfile,
    ssh_keyfile_name,
    ssh_user = 'root',
    progressOne
) {
  options(do.wait_time = 30)
  
  # DO scenario uploader config
  region <- 'tor1'
  uploader_image <- 'ubuntu-22-04-x64'
  # uploader_size = 's-1vcpu-1gb'
  uploader_size = 's-1vcpu-2gb'
  
  # Scenario
  selected_scenario_tbl <- parseFilePaths(volumes, scenario)
  selected_scenario <- selected_scenario_tbl$name
  selected_scenario_path <- stringr::str_replace(
    selected_scenario_tbl$datapath, 
    'NULL/',
    ifelse(
      stringr::str_to_lower(Sys.info()[1]) == 'windows',
      paste0(fs::path_(), '/'),
      ''
    )
  )
  
  if (!file.exists(selected_scenario_path)) {
    shinyjs::alert("Wrong path supplied for scenario file. Please refresh the page and try again.")
    return(NULL)
  }
  
  progressOne$set(value = 2)
  
  droplet_name <- ids::adjective_animal()
  
  ## Create scenario uploader droplet ----
  d_uploader <- analogsea::droplet_create(
    name = do_namify(ids::adjective_animal()),
    size = uploader_size,
    region = region,
    image = uploader_image,
    ssh_keys = ssh_keyfile_name,
    tags = c('flex_cloud')
  ) %>%
    droplet_wait()
  
  progressOne$set(value = 5, detail = 'Waiting for connectivity')
  
  Sys.sleep(5)
  
  progressOne$set(8, detail = 'Uplaoding scenario')
  
  # Upload scenario to the droplet ----
  
  tryCatch({  
    d_uploader <- droplet(d_uploader$id)
  }, error = function(e) {
    # debug_msg(e$message)
    # shinyjs::alert("There was an error running the simu1lation, cleaning up.")
    progressOne$set(9, detail = "Couldn't connect to droplet, retrying")
    
    Sys.sleep(30)
  })
  
  error <- FALSE
  tryCatch({  
    d_uploader %>%
      droplet_upload(
        user = ssh_user,
        keyfile = ssh_keyfile,
        local = selected_scenario_path,
        # remote = paste0('/mnt/scenario/', selected_scenario)
        remote = paste0('/root/scenario.tif')
      )
    d_uploader <- droplet(d_uploader$id)
  }, error = function(e) {
    # debug_msg(e$message)
    progressOne$set(9, detail = "Couldnt connect to droplet, cleaning up")
    d_uploader %>% droplet_delete()
    error <- FALSE
    
    shinyjs::alert("There was an error running the simulation. Please refresh the page and try again/")
  })
  
  if (error) {
    return(NULL)
  }
  
  progressOne$set(9, detail = 'Completing the upload')
  
  d_uploader
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

get_private_ip <- function(droplet) {
  v4 <- droplet$networks$v4
  if (length(v4) == 0) {
    stop("No network interface registered for this droplet\n  Try refreshing like: droplet(d$id)",
         call. = FALSE
    )
  }
  ips <- do.call("rbind", lapply(v4, as.data.frame))
  public_ip <- ips$type == "private"
  if (!any(public_ip)) {
    ip <- v4[[1]]$ip_address
  } else {
    ip <- ips$ip_address[public_ip][[1]]
  }
  ip
}

do_namify <- function(name) {
  stringr::str_remove_all(
    stringr::str_to_title(
      stringr::str_replace_all(name, '_', ' ')
    ),
    ' '
  )
}

# wait_for_connectivity <- function(droplet) {
#   analogsea:::droplet_ip_safe()
# }
