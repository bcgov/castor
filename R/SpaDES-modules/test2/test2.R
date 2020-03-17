defineModule(sim, list(
  name = "test2",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", test2 = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "test2.Rmd"),
  reqdPkgs = list("RSQLite", "velox"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("save_db", "logical", FALSE, NA, NA, desc = "Save the db to a file?")
     ),
  inputObjects = bind_rows(
    ),
  outputObjects = bind_rows(
    createsOutput("db", objectClass ="SQLiteConnection", desc = "A rsqlite database"),
    createsOutput("rasVelo", objectClass ="velox", desc = "Velox Raster Layer")
    )
))

doEvent.test2 = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = { 
      sim$db<-dbConnect(RSQLite::SQLite(), ":memory:")
      sim <-setTables(sim)
      sim <- scheduleEvent(sim, eventTime = end(sim),  "test2", "removeDb", eventPriority=99)
    },
    removeDb={
      sim<- disconnectDb(sim)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

disconnectDb<- function(sim) {
  if(P(sim)$save_db){
    message('Saving clusdb')
    con<-dbConnect(RSQLite::SQLite(), "db.sqlite") #create SQLite file
    RSQLite::sqliteCopyDatabase(sim$db, con) #copy the database
    dbDisconnect(sim$db)
    dbDisconnect(con)
  }else{
    dbDisconnect(sim$db)
  }
  
  return(invisible(sim))
}


setTables <- function(sim) {
  message('...setting data tables')
  sim$rasVelo <-velox::velox(raster(extent(0,10,0,10), vals = runif(100, 0,1)))
  return(invisible(sim))
}


.inputObjects <- function(sim) {
  return(invisible(sim))
}


