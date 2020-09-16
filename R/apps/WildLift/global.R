#shiny::runApp("inst/shiny/WildLift")

## install/update WildLift package as needed
## need to install from github for rsconnect to work properly
#remotes::install_github("ABbiodiversity/WildLift")

library(shiny)
library(shinydashboard)
library(shinyBS)
library(plotly)
library(openxlsx)
library(WildLift)
library(knitr)
library(ggplot2)
library(reactable)

ver <- read.dcf(file=system.file("DESCRIPTION", package="WildLift"),
                fields="Version")

## initialize sliders for the different pen types
S_PE <- wildlift_settings("pred.excl", "AverageSubpop") # for multi1
inits <- list(
    penning = c(
        fpen.prop = 0.35,
        fpen.inds = 10,
        wildlift_settings("mat.pen")),
    predator = c(
        fpen.prop = 0.35,
        fpen.inds = 10,
        wildlift_settings("pred.excl")),
    moose = c(
        fpen.prop = 0.35,
        fpen.inds = 10,
        wildlift_settings("moose.red")),
    moose0 = c(
        fpen.prop = 0.35,
        fpen.inds = 10,
        wildlift_settings("mat.pen")),
    wolf = wildlift_settings("wolf.red"),
    ## set AFS=0.801 CS=0.295 under no wolf option
    wolf0 = wildlift_settings("mat.pen",
        f.surv.capt=0.801,
        f.surv.wild=0.801,
        c.surv.capt=0.295,
        c.surv.wild=0.295),
    breeding = wildlift_settings("cons.breed", pen.cap=40),
    ## multi-lever
    breeding1 = c(
        f.surv.wild.mr = 0.879,
        c.surv.wild.wr = 0.513,
        f.surv.wild.wr = 0.912,
        wildlift_settings("cons.breed", "AverageSubpop", pen.cap=40)),
    multi1 = c(
        fpen.prop = 0.35,
        fpen.inds = 10,
        f.surv.wild.mr = 0.879,
        c.surv.wild.wr = 0.513,
        f.surv.wild.wr = 0.912,
        ## this boost for captive comes from females spending some of their life
        ## outside of the pen, thus receiving the boost
        ## boost is on top of the normal surv rate (MP+WR only)
        c.surv.capt.mpwr.boost = 0.17,
        f.surv.capt.mpwr.boost = 0.026,
        f.surv.capt.mpmr.boost = 0.026,
        c.surv.capt.pe = S_PE$c.surv.capt,
        f.surv.capt.pe = S_PE$f.surv.capt,
        f.preg.capt.pe = S_PE$f.preg.capt,
        pen.cost.setup.pe = S_PE$pen.cost.setup,
        pen.cost.proj.pe = S_PE$pen.cost.proj,
        pen.cost.maint.pe = S_PE$pen.cost.maint,
        pen.cost.capt.pe = S_PE$pen.cost.capt,
        pen.cost.pred.pe = S_PE$pen.cost.pred,
        wildlift_settings("mat.pen"))
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
    "East Side Athabasca" = "EastSideAthabasca",
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

#FooterText <- "<p>Shiny app made by the <a href='https://github.com/bcgov/CaribouBC'>CaribouBC</a> R package.</p>"
FooterText <- ""

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

wildlift_multilever <- function(Settings,
TMAX, POP_START, VAL, USE_PROP) {

    Forecast <- lapply(Settings, function(s) {
        wildlift_forecast(s,
            tmax = TMAX,
            pop.start = POP_START,
            fpen.prop = if (USE_PROP) VAL else NULL,
            fpen.inds = if (USE_PROP) NULL else VAL)
    })

    Summary <- sapply(Forecast, get_summary, USE_PROP)
    Traces <- lapply(Forecast, plot, plot=FALSE)

    NAM <- list(
        c("Status quo", "MatPen", "PredExcl"),
        c("Status quo", "MooseRed", "WolfRed"),
        c("lam", "Nend", "CostEnd", "Nnew", "CostNew"))
    OUT <- array(0, sapply(NAM, length), NAM)

    OUT["Status quo", "Status quo", c("lam", "Nend")] <-
        Summary[c("lam.nopen", "Nend.nopen"), "mp"]
    OUT["MatPen", "Status quo", c("lam", "Nend", "CostEnd")] <-
        Summary[c("lam.pen", "Nend.pen", "Cost.total"), "mp"]
    OUT["PredExcl", "Status quo", c("lam", "Nend", "CostEnd")] <-
        Summary[c("lam.pen", "Nend.pen", "Cost.total"), "pe"]

    ## no extra cost
    OUT["Status quo", "MooseRed", c("lam", "Nend")] <-
        Summary[c("lam.nopen", "Nend.nopen"), "mp_mr"]
    OUT["MatPen", "MooseRed", c("lam", "Nend", "CostEnd")] <-
        Summary[c("lam.pen", "Nend.pen", "Cost.total"), "mp_mr"]
    OUT["PredExcl", "MooseRed", c("lam", "Nend", "CostEnd")] <-
        Summary[c("lam.pen", "Nend.pen", "Cost.total"), "pe_mr"]

    ## add extra cost
    # Cost <- input$wolf_nremove * input$tmax * input$wolf_cost1 / 1000
    OUT["Status quo", "WolfRed", c("lam", "Nend")] <-
        Summary[c("lam.nopen", "Nend.nopen"), "mp_wr"]
    OUT["MatPen", "WolfRed", c("lam", "Nend", "CostEnd")] <-
        Summary[c("lam.pen", "Nend.pen", "Cost.total"), "mp_wr"]
    OUT["PredExcl", "WolfRed", c("lam", "Nend", "CostEnd")] <-
        Summary[c("lam.pen", "Nend.pen", "Cost.total"), "pe_wr"]

    OUT[,,"Nnew"] <- pmax(0, OUT[,,"Nend"] - OUT["Status quo", "Status quo", "Nend"])
    OUT[,,"CostNew"] <- OUT[,,"CostEnd"] / OUT[,,"Nnew"]
    OUT[,,"CostNew"][is.na(OUT[,,"CostNew"])] <- 0

    TB <- data.frame(
        Demogr = factor(rep(c("Status quo", "MP", "PE"), 3), c("Status quo", "MP", "PE")),
        Manage = factor(rep(c("Status quo", "MR", "WR"), each=3), c("Status quo", "MR", "WR")))
    TB$lambda <- as.numeric(OUT[,,"lam"])
    TB$Nend <- as.numeric(OUT[,,"Nend"])
    TB$Nnew <- as.numeric(OUT[,,"Nnew"])
    TB$Cend <- as.numeric(OUT[,,"CostEnd"])
    TB$Cnew <- as.numeric(OUT[,,"CostNew"])
    TB$Demogr <- as.character(TB$Demogr)
    TB$Manage <- as.character(TB$Manage)
    rownames(TB) <- paste0(
        ifelse(TB$Demogr == "Status quo", "", TB$Demogr),
        ifelse(TB$Demogr != "Status quo" & TB$Manage != "Status quo", "+", ""),
        ifelse(TB$Manage == "Status quo", "", TB$Manage))
    rownames(TB)[1] <- "Status quo"

    list(summary=TB, traces=Traces)
}

COLOR <- c(
    '#a6cee3', # light blue
    '#1f78b4', # blue
    '#b2df8a', # light green
    '#33a02c', # green
    '#fb9a99', # pink
    '#e31a1c', # red
    '#fdbf6f', # light orange
    '#ff7f00', # orange
    '#cab2d6', # light purple
    '#6a3d9a') # purple

TCOL <- c("#000000", COLOR[c(1,2,9,10,5,6,7,8)])
names(TCOL) <- c("Status quo",
    "MP", "PE",
    "MR",  "WR",
    "MP + MR", "MP + WR",
    "PE + MR", "PE + WR")

plot_multilever <- function(ML, type=c("all", "dem", "man", "fac")) {

    type <- match.arg(type)
    Traces <- ML$traces
    TMAX <- nrow(ML$traces[[1]])-1L
    POP_START <- ML$traces[[1]][1,2]

    PL <- rbind(
        data.frame(Demogr="Status quo", Manage="Status quo", Years=0:TMAX,
            N=Traces$mp$Nnopen, stringsAsFactors = FALSE),
        data.frame(Demogr="MP", Manage="Status quo", Years=0:TMAX,
            N=Traces$mp$Npen, stringsAsFactors = FALSE),
        data.frame(Demogr="PE", Manage="Status quo", Years=0:TMAX,
            N=Traces$pe$Npen, stringsAsFactors = FALSE),
        data.frame(Demogr="Status quo", Manage="MR", Years=0:TMAX,
            N=Traces$mp_mr$Nnopen, stringsAsFactors = FALSE),
        PL_MP_MR <- data.frame(Demogr="MP", Manage="MR", Years=0:TMAX,
            N=Traces$mp_mr$Npen, stringsAsFactors = FALSE),
        PL_PE_MR <- data.frame(Demogr="PE", Manage="MR", Years=0:TMAX,
            N=Traces$pe_mr$Npen, stringsAsFactors = FALSE),
        PL_SQ_WR <- data.frame(Demogr="Status quo", Manage="WR", Years=0:TMAX,
            N=Traces$mp_wr$Nnopen, stringsAsFactors = FALSE),
        data.frame(Demogr="MP", Manage="WR", Years=0:TMAX,
            N=Traces$mp_wr$Npen, stringsAsFactors = FALSE),
        data.frame(Demogr="PE", Manage="WR", Years=0:TMAX,
            N=Traces$pe_wr$Npen, stringsAsFactors = FALSE))

    PL$N <- floor(PL$N)
    PL$Two <- paste0(PL$Demogr, "+", PL$Manage)
    PL$Manage <- factor(PL$Manage, c("Status quo", "MR", "WR"))
    PL$Demogr <- factor(PL$Demogr, c("Status quo", "MP", "PE"))
    PL$Comb <- paste0(as.character(PL$Demogr), " + ", as.character(PL$Manage))
    PL$Comb[PL$Comb == "Status quo + Status quo"] <- "Status quo"
    PL$Comb[PL$Comb == "MP + Status quo"] <- "MP"
    PL$Comb[PL$Comb == "PE + Status quo"] <- "PE"
    PL$Comb[PL$Comb == "Status quo + MR"] <- "MR"
    PL$Comb[PL$Comb == "Status quo + WR"] <- "WR"
    PL$Col <- as.character(PL$Demogr)
    PL$Col[PL$Manage=="Status quo" & PL$Demogr=="Status quo"] <- "Baseline"
    PL$Col <- factor(PL$Col, c("Baseline", "Status quo", "MP", "PE"))

    PL$Comb <- factor(PL$Comb, c(
        "Status quo",
        "MP", "PE", "MR",  "WR",
        "MP + MR", "MP + WR",
        "PE + MR", "PE + WR"))
    PL$lty <- as.integer(PL$Manage)

    p <- ggplot(PL, aes(x=Years, y=N)) +
        geom_line(aes(color=Comb)) +
        theme_minimal() +
        geom_hline(yintercept=POP_START, col="grey") +
        theme(legend.title = element_blank()) +
        ylab("Individuals") +
        scale_color_manual(values=TCOL)

    if (type == "fac")
        p <- p + facet_grid(rows=vars(Demogr), cols=vars(Manage))
    if (type == "man")
        p <- p + facet_grid(cols=vars(Manage))
    if (type == "dem")
        p <- p + facet_grid(cols=vars(Demogr))

    p
}

