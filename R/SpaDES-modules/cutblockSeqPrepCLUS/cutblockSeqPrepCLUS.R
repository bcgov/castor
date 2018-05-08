
defineModule(sim, list(
  name = "cutblockSeqPrepCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = person("First", "Last", email = "first.last@example.com", role = c("aut", "cre")),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", cutblockSeqPrepCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "cutblockSeqPrepCLUS.Rmd"),
  reqdPkgs = list("rpostgis", "sp"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("dbName", "character", "postgres", NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
    defineParameter("dbGeom", "character", 'geom', NA, NA, "The name of the postgres file geom column"),
    defineParameter("nameBoundary", "character", 'name', NA, NA, desc = "Name of the boundary file"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("endTime", "numeric", end(sim), NA, NA, desc = "Simulation time at which to end"),
    defineParameter("cutblockSeqInterval", "numeric", 1, NA, NA, desc = "This describes the interval for the sequencing or scheduling of the cutblocks"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput("herds", "list", "list of herd boundaries to include in the analysis", sourceURL = NA)
    #expectsInput(objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput("landings", "SpatialPoint", "This describes a series of point locations representing the cutblocks or their landings", ...)
    #createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

doEvent.cutblockSeqPrepCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      sim <- sim$cutblockSeqPrepCLUSdbConnect(sim)
      sim <- scheduleEvent(sim, P(sim)$endTime, "cutblockSeqPrepCLUS", "endConnect")
      sim <- sim$cutblockSeqPrepCLUSgetBoundaries(sim)
      sim <- scheduleEvent(sim, P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep")
      sim$landings<-c(1,2)
      # schedule future event(s)
      #sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "cutblockSeqPrepCLUS", "plot")
      #sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "cutblockSeqPrepCLUS", "save")
    },
    cutblockSeqPrep = {
      plot(sim$landings)
      #sim <- scheduleEvent(sim, P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep")
    },
    endConnect = {
      sim <- sim$cutblockSeqPrepCLUSdbDisconnect(sim)
    },    
    plot = {
    },
    save = {
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}
Init <- function(sim) {
  return(invisible(sim))
}

### template for save events
Save <- function(sim) {
  sim <- saveFiles(sim)
  return(invisible(sim))
}

Plot <- function(sim) {
  return(invisible(sim))
}

cutblockSeqPrepCLUSdbConnect <- function(sim) {
  sim$conn<-dbConnect("PostgreSQL",dbname= P(sim)$dbName, host=P(sim)$dbHost, port=P(sim)$dbPort ,user=P(sim)$dbUser, password=P(sim)$dbPassword)
  return(invisible(sim))
}

cutblockSeqPrepCLUSdbDisconnect <- function(sim) {
  dbDisconnect(sim$conn)
  return(invisible(sim))
}

cutblockSeqPrepCLUSgetBoundaries <- function(sim) {
  boundaries<-pgGetGeom(sim$conn, name=P(sim)$nameBoundary,  geom = P(sim)$dbGeom)
  sim$boundaries<-subset(boundaries , herd_name == P(sim)$herds[[1]] | herd_name == P(sim)$herds[[2]] |  herd_name == P(sim)$herds[[3]] )
  plot(sim$boundaries)
  return(invisible(sim))
}
.inputObjects <- function(sim) {

  # if (!('defaultColor' %in% sim$.userSuppliedObjNames)) {
  #  sim$defaultColor <- 'red'
  # }

  return(invisible(sim))
}
