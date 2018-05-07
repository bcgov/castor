
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
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("dbName", "character", 'postgres', NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
    defineParameter("dbGeom", "character", 'geom', NA, NA, "The name of the postgres file geom column"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput("herds", "list", "list of herd boundaries to include in the analysis", sourceURL = NA),
    #expectsInput(objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

## event types
#   - type `init` is required for initialiazation

doEvent.cutblockSeqPrepCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      ### establish a connection?
      sim <- sim$cutblockSeqPrepCLUSdbConnect(sim)

      # do stuff for this event
      sim <- Init(sim)

      # schedule future event(s)
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "cutblockSeqPrepCLUS", "plot")
      sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "cutblockSeqPrepCLUS", "save")
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
  sim$conn <- tryCatch(
    {
      conn<-dbConnect("PostgreSQL",dbname=sim$dbname, host=sim$host ,port=sim$port ,user=sim$user ,password=sim$password)
    },
    error=function(cond) {
      message(paste("Connection to pgsql was not valid:", conn ))
      message(cond)
      out = FALSE
      return(NA)
    }
  )    
  return(conn)
}
.inputObjects <- function(sim) {
  # Any code written here will be run during the simInit for the purpose of creating
  # any objects required by this module and identified in the inputObjects element of defineModule.
  # This is useful if there is something required before simulation to produce the module
  # object dependencies, including such things as downloading default datasets, e.g.,
  # downloadData("LCC2005", modulePath(sim)).
  # Nothing should be created here that does not create an named object in inputObjects.
  # Any other initiation procedures should be put in "init" eventType of the doEvent function.
  # Note: the module developer can use 'sim$.userSuppliedObjNames' in their function below to
  # selectively skip unnecessary steps because the user has provided those inputObjects in the
  # simInit call. e.g.,
  # if (!('defaultColor' %in% sim$.userSuppliedObjNames)) {
  #  sim$defaultColor <- 'red'
  # }
  # ! ----- EDIT BELOW ----- ! #

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}
### add additional events as needed by copy/pasting from above
