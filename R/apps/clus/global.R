library(shiny)
library(shinydashboard)
library(shinyBS)
library(shinyFiles)
library(plotly)
library(openxlsx)
library(CaribouBC)
library(RSQLite)


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
