#shiny::runApp("inst/shiny/matpen")

## install/update CaribouBC package as needed
## need to install from github for rsconnect to work properly
#remotes::install_github("psolymos/CaribouBC")

library(shiny)
library(shinydashboard)
library(shinyBS)
library(plotly)
library(openxlsx)
library(CaribouBC)

ver <- read.dcf(file=system.file("DESCRIPTION", package="CaribouBC"),
                fields="Version")

## initialize sliders for the different pen types
inits <- list(
    penning = c(
        fpen.prop = 0.25,
        fpen.inds = 10,
        caribou_settings("mat.pen")),
    predator = c(
        fpen.prop = 0.25,
        fpen.inds = 10,
        caribou_settings("pred.excl")),
    moose = c(
        fpen.prop = 0.25,
        fpen.inds = 10,
        caribou_settings("moose.red")),
    moose0 = c(
        fpen.prop = 0.25,
        fpen.inds = 10,
        caribou_settings("mat.pen")),
    wolf = caribou_settings("wolf.red"),
    ## set AFS=0.801 CS=0.295 under no wolf option
    wolf0 = caribou_settings("mat.pen",
        f.surv.capt=0.801,
        f.surv.wild=0.801,
        c.surv.capt=0.295,
        c.surv.wild=0.295),
    breeding = caribou_settings("mat.pen",
        c.surv.capt=0.7,
        c.surv.wild=0.25)
)

get_settings <- function(x, use_perc=TRUE) {
    out <- c(tmax = x$tmax,
        pop.start = x$pop.start,
        fpen=if (use_perc)
            paste0(100*x$fpen.prop, "%") else paste0(x$fpen.inds, collapse=", "),
        unlist(x$settings))
    attr(out, "fpen.prop") <- x$fpen.prop
    attr(out, "fpen.inds") <- x$fpen.inds
    out
}

#get_inds <- function(x) eval(parse(text=paste("c(", x, ")")))

get_summary <- function(x, use_perc=TRUE) {
    xx <- summary(x)
    xx$fpen <- if (use_perc)
        x$fpen.prop else x$fpen.inds
    xx$fpen.prop <- NULL
    xx$fpen.inds <- NULL
    unlist(xx)
}

Herds <- c(
    "Columbia North" = "ColumbiaNorth",
    "Columbia South" = "ColumbiaSouth",
    "Frisby-Queest" = "FrisbyQueest",
    "Wells Grey South" = "WellsGreySouth",
    "Groundhog" = "Groundhog",
    "Parsnip" = "Parsnip")
HerdsWolf <- c(
    "Kennedy Siding" = "KennedySiding",
    "Klinse-za (Moberly)" = "KlinsezaMoberly",
    "Quintette" = "Quintette")

FooterText <- "<p>Shiny app made by the <a href='https://github.com/bcgov/CaribouBC'>CaribouBC</a> R package.</p>"

hover <- function(x, d=1) {
    tot <- round(rowSums(x), d)
    x <- round(x, d)
    sapply(seq_along(tot), function(i) {
        paste0(
            tot[i], "=[",
            paste0(x[i,], collapse=","),
            "]"
        )
    })
}

stack_breeding <- function(x) {
    tt <- 0:x$tmax
    rr <- rownames(x$Nin)
    N <- rbind(
        data.frame(What="Nin", Year=tt, t(x$Nin)),
        data.frame(What="Nout", Year=tt, t(x$Nout)),
        data.frame(What="Ncapt", Year=tt, t(x$Ncapt)),
        data.frame(What="Nrecip", Year=tt, t(x$Nrecip)),
        data.frame(What="Nwild", Year=tt, t(x$Nwild)))
    colnames(N) <- c("Part", "Year", rr)
    N
}