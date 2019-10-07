#shiny::runApp("inst/shiny/matpen")

## install/update CaribouBC package as needed
## need to install from github for rsconnect to work properly
#devtools::install_github("psolymos/CaribouBC")

library(shiny)
library(shinydashboard)
library(shinyBS)
library(plotly)
library(openxlsx)
library(CaribouBC)

## initialize sliders for the different pen types
inits <- list(
    penning = c(
        fpen.prop = 0.25,
        caribou_settings("mat.pen")),
    predator = c(
        fpen.prop = 0.25,
        caribou_settings("pred.excl")),
    moose = c(
        fpen.prop = 0.25,
        caribou_settings("moose.red")),
    moose0 = c(
        fpen.prop = 0.25,
        caribou_settings("mat.pen"))
)

get_settings <- function(x) {
    c(tmax = x$tmax,
        pop.start = x$pop.start,
        fpen.prop = x$fpen.prop,
        unlist(x$settings))
}

Herds <- c(
    "Columbia North" = "ColumbiaNorth",
    "Columbia South" = "ColumbiaSouth",
    "Frisby-Queest" = "FrisbyQueest",
    "Wells Grey South" = "WellsGreySouth",
    "Groundhog" = "Groundhog",
    "Parsnip" = "Parsnip")

## TODO:
## OK - add static settings sliders
## OK - implement plot
## OK - implement summary
## OK - add download options
## OK - remove pred cost slider where not relevant
## - need some kind of help page / info popups?
