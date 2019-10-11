server <- function(input, output, session) {


    ## >>> common part for all 3 tabs <<<====================

    ## set values based inits
    values <- reactiveValues(
        penning = inits$penning,
        penning0 = NULL,
        penning_compare = FALSE,
        predator = inits$predator,
        predator0 = NULL,
        predator_compare = FALSE,
        moose = inits$moose,
        moose0 = inits$moose0,
        moose_compare = TRUE)

    observeEvent(input$herd, {
        HERD <- input$herd
        if (HERD == "Default")
            HERD <- NULL

        values$penning <- c(
            fpen.prop = values$penning$fpen.prop,
            caribou_settings("mat.pen", HERD))
        if (values$penning_compare) {
            values$penning0 <- values$penning
        } else {
            values$penning0 <- NULL
        }

        values$predator <- c(
            fpen.prop = values$predator$fpen.prop,
            caribou_settings("mat.pen", HERD))
        if (values$predator_compare) {
            values$predator0 <- values$predator
        } else {
            values$predator0 <- NULL
        }

        values$moose <- c(
            fpen.prop = values$moose$fpen.prop,
            caribou_settings("moose.red", HERD))
        values$moose0 <- c(
            fpen.prop = values$moose0$fpen.prop,
            caribou_settings("mat.pen", HERD))
    })


    ## >>> penning tab <<<=====================================

    ## dynamically render sliders
    output$penning_demogr_sliders <- renderUI({
        if (input$herd != "Default")
            return(p("Demography settings not available for specific herds."))
        tagList(
            sliderInput("penning_DemCsw", "Calf survival, wild",
                min = 0, max = 1, value = inits$penning$c.surv.wild, step = 0.01),
            sliderInput("penning_DemCsc", "Calf survival, captive",
                min = 0, max = 1, value = inits$penning$c.surv.capt, step = 0.01),
            sliderInput("penning_DemFsw", "Adult female survival, wild",
                min = 0, max = 1, value = inits$penning$f.surv.wild, step = 0.01),
            sliderInput("penning_DemFsc", "Adult female survival, captive",
                min = 0, max = 1, value = inits$penning$f.surv.capt, step = 0.01),
            sliderInput("penning_DemFpw", "Pregnancy rate, wild",
                min = 0, max = 1, value = inits$penning$f.preg.wild, step = 0.01),
            sliderInput("penning_DemFpc", "Pregnancy rate, captive",
                min = 0, max = 1, value = inits$penning$f.preg.capt, step = 0.01)
        )
    })
    ## dynamically render button
    output$penning_button <- renderUI({
        tagList(
            actionButton("penning_button",
                if (values$penning_compare)
                    "Single scenario" else "Compare scenarios",
                icon = icon(if (values$penning_compare)
                    "stop-circle" else "arrows-alt-h"))
        )
    })
    ## observers
    observeEvent(input$penning_button, {
        values$penning_compare <- !values$penning_compare
        if (values$penning_compare) {
            values$penning0 <- values$penning
        } else {
            values$penning0 <- NULL
        }
    })
    observeEvent(input$penning_FpenPerc, {
        values$penning$fpen.prop <- input$penning_FpenPerc / 100
    })
    observeEvent(input$penning_DemCsw, {
        values$penning$c.surv.wild <- input$penning_DemCsw
    })
    observeEvent(input$penning_DemCsc, {
        values$penning$c.surv.capt <- input$penning_DemCsc
    })
    observeEvent(input$penning_DemFsw, {
        values$penning$f.surv.wild <- input$penning_DemFsw
    })
    observeEvent(input$penning_DemFsc, {
        values$penning$f.surv.capt <- input$penning_DemFsc
    })
    observeEvent(input$penning_DemFpw, {
        values$penning$f.preg.wild <- input$penning_DemFpw
    })
    observeEvent(input$penning_DemFpc, {
        values$penning$f.preg.capt <- input$penning_DemFpc
    })
    observeEvent(input$penning_CostPencap, {
        values$penning$pen.cap <- input$penning_CostPencap
    })
    observeEvent(input$penning_CostSetup, {
        values$penning$pen.cost.setup <- input$penning_CostSetup
    })
    observeEvent(input$penning_CostProj, {
        values$penning$pen.cost.proj <- input$penning_CostProj
    })
    observeEvent(input$penning_CostMaint, {
        values$penning$pen.cost.maint <- input$penning_CostMaint
    })
    observeEvent(input$penning_CostCapt, {
        values$penning$pen.cost.capt <- input$penning_CostCapt
    })
    #observeEvent(input$penning_CostPred, {
    #    values$penning$pen.cost.pred <- input$penning_CostPred
    #})
    ## apply settings and get forecast
    penning_getF <- reactive({
        caribou_forecast(values$penning,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = values$penning$fpen.prop)
    })
    ## try to find breakeven point
    penning_getB <- reactive({
        req(penning_getF())
        p <- suppressWarnings(caribou_breakeven(penning_getF()))
        if (is.na(p))
            return(NULL)
        caribou_forecast(penning_getF()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = p)
    })
    ## these are similar functions to the bechmark scenario
    penning_getF0 <- reactive({
        if (!values$penning_compare)
            return(NULL)
        caribou_forecast(values$penning0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = values$penning0$fpen.prop)
    })
    penning_getB0 <- reactive({
        req(penning_getF0())
        p <- suppressWarnings(caribou_breakeven(penning_getF0()))
        if (is.na(p))
            return(NULL)
        caribou_forecast(penning_getF0()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = p)
    })
    ## making nice table of the results
    penning_getT <- reactive({
        req(penning_getF())
        bev <- if (is.null(penning_getB()))
            NA else unlist(summary(penning_getB()))
        tab <- cbind(
            Results=unlist(summary(penning_getF())),
            Breakeven=bev)
        subs <- c("fpen.prop", "npens", "lam.pen", "lam.nopen",
            "Nend.pen", "Nend.nopen", "Nend.diff",
            "Cost.total", "Cost.percap")
        df <- tab[subs,,drop=FALSE]
        df[1L,] <- df[1L,]*100
        rownames(df) <- c("% penned",
            "# pens", "&lambda; (maternity pen)", "&lambda; (no maternity pen)",
            "N (end, maternity pen)", "N (end, no maternity pen)", "N (end, difference)",
            "Total cost (x $1000)", "Cost per capita (x $1000 / caribou)")
        if (values$penning_compare) {
            bev0 <- if (is.null(penning_getB0()))
                NA else unlist(summary(penning_getB0()))
            tab0 <- cbind(
                Results=unlist(summary(penning_getF0())),
                Breakeven=bev0)
            df0 <- tab0[subs,,drop=FALSE]
            df0[1L,] <- df0[1L,]*100
            rownames(df0) <- rownames(df)
            df <- cbind(df0, df)
            colnames(df) <- c("Results, reference", "Breakeven, reference",
                "Results", "Breakeven")
        }
        df
    })
    ## making nice table of the settings
    penning_getS <- reactive({
        req(penning_getF())
        bev <- if (is.null(penning_getB()))
            NA else get_settings(penning_getB())
        tab <- cbind(
            Results=get_settings(penning_getF()),
            Breakeven=bev)
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            "fpen.prop" = "% females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Pregnancy rate, wild",
            "f.preg.capt" = "Pregnancy rate, captive",
            "pen.cap" = "Max in a single pen",
            "pen.cost.setup" = "Initial set up (x $1000)",
            "pen.cost.proj" = "Project manager (x $1000)",
            "pen.cost.maint" = "Maintenance (x $1000)",
            "pen.cost.capt" = "Capture/monitor (x $1000)",
            "pen.cost.pred" = "Removing predators (x $1000)")
        df <- tab[names(SNAM),,drop=FALSE]
        df["fpen.prop",] <- df["fpen.prop",]*100
        rownames(df) <- SNAM
        if (values$penning_compare) {
            bev0 <- if (is.null(penning_getB0()))
                NA else get_settings(penning_getB0())
            tab0 <- cbind(
                Results=get_settings(penning_getF0()),
                Breakeven=bev0)
            df0 <- tab0[names(SNAM),,drop=FALSE]
            df0["fpen.prop",] <- df0["fpen.prop",]*100
            rownames(df0) <- SNAM
            df <- cbind(df0, df)
            colnames(df) <- c("Results, reference", "Breakeven, reference",
                "Results", "Breakeven")
        }
        df
    })
    ## plot
    output$penning_Plot <- renderPlotly({
        req(penning_getF())
        df <- plot(penning_getF(), plot=FALSE)
        colnames(df)[colnames(df) == "Npen"] <- "Individuals"
        p <- plot_ly(df, x = ~Years, y = ~Individuals,
            name = 'Maternity pen', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~Nnopen, name = 'No maternity pen',
                mode = 'lines', color=I('blue'))
        if (values$penning_compare) {
            df0 <- plot(penning_getF0(), plot=FALSE)
            p <- p %>% add_trace(y = ~Npen, name = 'Maternity pen, reference', data = df0,
                    line=list(dash = 'dash', color='red')) %>%
                add_trace(y = ~Nnopen, name = 'No maternity pen, reference', data = df0,
                    line=list(dash = 'dash', color='blue'))
        }
        p <- p %>% layout(legend = list(x = 100, y = 0))
        p
    })
    ## table
    output$penning_Table <- renderTable({
        req(penning_getT())
        penning_getT()
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)
    ## dowload
    penning_xlslist <- reactive({
        req(penning_getF())
        req(penning_getT())
        TS <- plot(penning_getF(), plot=FALSE)
        if (values$penning_compare) {
            TS <- cbind(plot(penning_getF0(), plot=FALSE), TS[,-1])
            colnames(TS) <- c("Years",
                "N no maternity pen, reference", "N maternity pen, reference",
                "N no maternity pen", "N maternity pen")
        }
        df <- penning_getT()
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- penning_getS()
        ver <- read.dcf(file=system.file("DESCRIPTION", package="CaribouBC"),
            fields="Version")
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$herd))),
            Settings=as.data.frame(ss),
            TimeSeries=as.data.frame(TS),
            Summary=as.data.frame(df))
        out$Settings$Parameters <- rownames(ss)
        out$Settings <- out$Settings[,c(ncol(ss)+1, 1:ncol(ss))]
        out$Summary$Variables <- rownames(df)
        out$Summary <- out$Summary[,c(ncol(df)+1, 1:ncol(df))]
        out
    })
    output$penning_download <- downloadHandler(
        filename = function() {
            paste0("CaribouBC_maternity_pen_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(penning_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> predator tab <<<=====================================

    ## dynamically render sliders
    output$predator_demogr_sliders <- renderUI({
        if (input$herd != "Default")
            return(p("Demography settings not available for specific herds."))
        tagList(
             sliderInput("predator_DemCsw", "Calf survival, wild",
                min = 0, max = 1, value = inits$predator$c.surv.wild, step = 0.01),
             sliderInput("predator_DemCsc", "Calf survival, captive",
                min = 0, max = 1, value = inits$predator$c.surv.capt, step = 0.01),
             sliderInput("predator_DemFsw", "Adult female survival, wild",
                min = 0, max = 1, value = inits$predator$f.surv.wild, step = 0.01),
             sliderInput("predator_DemFsc", "Adult female survival, captive",
                min = 0, max = 1, value = inits$predator$f.surv.capt, step = 0.01),
             sliderInput("predator_DemFpw", "Pregnancy rate, wild",
                min = 0, max = 1, value = inits$predator$f.preg.wild, step = 0.01),
             sliderInput("predator_DemFpc", "Pregnancy rate, captive",
                min = 0, max = 1, value = inits$predator$f.preg.capt, step = 0.01)
        )
    })
    ## dynamically render button
    output$predator_button <- renderUI({
        tagList(
            actionButton("predator_button",
                if (values$predator_compare)
                    "Single scenario" else "Compare scenarios",
                icon = icon(if (values$predator_compare)
                    "stop-circle" else "arrows-alt-h"))
        )
    })
    ## observers
    observeEvent(input$predator_button, {
        values$predator_compare <- !values$predator_compare
        if (values$predator_compare) {
            values$predator0 <- values$predator
        } else {
            values$predator0 <- NULL
        }
    })
    observeEvent(input$predator_FpenPerc, {
        values$predator$fpen.prop <- input$predator_FpenPerc / 100
    })
    observeEvent(input$predator_DemCsw, {
        values$predator$c.surv.wild <- input$predator_DemCsw
    })
    observeEvent(input$predator_DemCsc, {
        values$predator$c.surv.capt <- input$predator_DemCsc
    })
    observeEvent(input$predator_DemFsw, {
        values$predator$f.surv.wild <- input$predator_DemFsw
    })
    observeEvent(input$predator_DemFsc, {
        values$predator$f.surv.capt <- input$predator_DemFsc
    })
    observeEvent(input$predator_DemFpw, {
        values$predator$f.preg.wild <- input$predator_DemFpw
    })
    observeEvent(input$predator_DemFpc, {
        values$predator$f.preg.capt <- input$predator_DemFpc
    })
    observeEvent(input$predator_CostPencap, {
        values$predator$pen.cap <- input$predator_CostPencap
    })
    observeEvent(input$predator_CostSetup, {
        values$predator$pen.cost.setup <- input$predator_CostSetup
    })
    observeEvent(input$predator_CostProj, {
        values$predator$pen.cost.proj <- input$predator_CostProj
    })
    observeEvent(input$predator_CostMaint, {
        values$predator$pen.cost.maint <- input$predator_CostMaint
    })
    observeEvent(input$predator_CostCapt, {
        values$predator$pen.cost.capt <- input$predator_CostCapt
    })
    observeEvent(input$predator_CostPred, {
        values$predator$pen.cost.pred <- input$predator_CostPred
    })
    ## apply settings and get forecast
    predator_getF <- reactive({
        caribou_forecast(values$predator,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = values$predator$fpen.prop)
    })
    ## try to find breakeven point
    predator_getB <- reactive({
        req(predator_getF())
        p <- suppressWarnings(caribou_breakeven(predator_getF()))
        if (is.na(p))
            return(NULL)
        caribou_forecast(predator_getF()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = p)
    })
    ## these are similar functions to the bechmark scenario
    predator_getF0 <- reactive({
        if (!values$predator_compare)
            return(NULL)
        caribou_forecast(values$predator0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = values$predator0$fpen.prop)
    })
    predator_getB0 <- reactive({
        req(predator_getF0())
        p <- suppressWarnings(caribou_breakeven(predator_getF0()))
        if (is.na(p))
            return(NULL)
        caribou_forecast(predator_getF0()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = p)
    })
    ## making nice table of the results
    predator_getT <- reactive({
        req(predator_getF())
        bev <- if (is.null(predator_getB()))
            NA else unlist(summary(predator_getB()))
        tab <- cbind(
            Results=unlist(summary(predator_getF())),
            Breakeven=bev)
        subs <- c("fpen.prop", "npens", "lam.pen", "lam.nopen",
            "Nend.pen", "Nend.nopen", "Nend.diff",
            "Cost.total", "Cost.percap")
        df <- tab[subs,,drop=FALSE]
        df[1L,] <- df[1L,]*100
        rownames(df) <- c("% penned",
            "# pens", "&lambda; (predator exclosure)", "&lambda; (no predator exclosure)",
            "N (end, predator exclosure)", "N (end, no predator exclosure)", "N (end, difference)",
            "Total cost (x $1000)", "Cost per capita (x $1000 / caribou)")
        if (values$predator_compare) {
            bev0 <- if (is.null(predator_getB0()))
                NA else unlist(summary(predator_getB0()))
            tab0 <- cbind(
                Results=unlist(summary(predator_getF0())),
                Breakeven=bev0)
            df0 <- tab0[subs,,drop=FALSE]
            df0[1L,] <- df0[1L,]*100
            rownames(df0) <- rownames(df)
            df <- cbind(df0, df)
            colnames(df) <- c("Results, reference", "Breakeven, reference",
                "Results", "Breakeven")
        }
        df
    })
    ## making nice table of the settings
    predator_getS <- reactive({
        req(predator_getF())
        bev <- if (is.null(predator_getB()))
            NA else get_settings(predator_getB())
        tab <- cbind(
            Results=get_settings(predator_getF()),
            Breakeven=bev)
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            "fpen.prop" = "% females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Pregnancy rate, wild",
            "f.preg.capt" = "Pregnancy rate, captive",
            "pen.cap" = "Max in a single pen",
            "pen.cost.setup" = "Initial set up (x $1000)",
            "pen.cost.proj" = "Project manager (x $1000)",
            "pen.cost.maint" = "Maintenance (x $1000)",
            "pen.cost.capt" = "Capture/monitor (x $1000)",
            "pen.cost.pred" = "Removing predators (x $1000)")
        df <- tab[names(SNAM),,drop=FALSE]
        df["fpen.prop",] <- df["fpen.prop",]*100
        rownames(df) <- SNAM
        if (values$predator_compare) {
            bev0 <- if (is.null(predator_getB0()))
                NA else get_settings(predator_getB0())
            tab0 <- cbind(
                Results=get_settings(predator_getF0()),
                Breakeven=bev0)
            df0 <- tab0[names(SNAM),,drop=FALSE]
            df0["fpen.prop",] <- df0["fpen.prop",]*100
            rownames(df0) <- SNAM
            df <- cbind(df0, df)
            colnames(df) <- c("Results, reference", "Breakeven, reference",
                "Results", "Breakeven")
        }
        df
    })
    ## plot
    output$predator_Plot <- renderPlotly({
        req(predator_getF())
        df <- plot(predator_getF(), plot=FALSE)
        colnames(df)[colnames(df) == "Npen"] <- "Individuals"
        p <- plot_ly(df, x = ~Years, y = ~Individuals,
            name = 'Predator exclosure', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~Nnopen, name = 'No predator exclosure',
                mode = 'lines', color=I('blue'))
        if (values$predator_compare) {
            df0 <- plot(predator_getF0(), plot=FALSE)
            p <- p %>% add_trace(y = ~Npen, name = 'Predator exclosure, reference', data = df0,
                    line=list(dash = 'dash', color='red')) %>%
                add_trace(y = ~Nnopen, name = 'No predator exclosure, reference', data = df0,
                    line=list(dash = 'dash', color='blue'))
        }
        p <- p %>% layout(legend = list(x = 100, y = 0))
        p
    })
    ## table
    output$predator_Table <- renderTable({
        req(predator_getT())
        predator_getT()
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)
    ## dowload
    predator_xlslist <- reactive({
        req(predator_getF())
        req(predator_getT())
        TS <- plot(predator_getF(), plot=FALSE)
        if (values$predator_compare) {
            TS <- cbind(plot(predator_getF0(), plot=FALSE), TS[,-1])
            colnames(TS) <- c("Years",
                "N no predator exclosure, reference", "N predator exclosure, reference",
                "N no predator exclosure", "N predator exclosure")
        }
        df <- predator_getT()
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- predator_getS()
        ver <- read.dcf(file=system.file("DESCRIPTION", package="CaribouBC"),
            fields="Version")
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$herd))),
            Settings=as.data.frame(ss),
            TimeSeries=as.data.frame(TS),
            Summary=as.data.frame(df))
        out$Settings$Parameters <- rownames(ss)
        out$Settings <- out$Settings[,c(ncol(ss)+1, 1:ncol(ss))]
        out$Summary$Variables <- rownames(df)
        out$Summary <- out$Summary[,c(ncol(df)+1, 1:ncol(df))]
        out
    })
    output$predator_download <- downloadHandler(
        filename = function() {
            paste0("CaribouBC_predator_exclosure_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(predator_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> moose tab <<<=====================================

    ## observers
    observeEvent(input$moose_FpenPerc, {
        values$moose$fpen.prop <- input$moose_FpenPerc / 100
        values$moose0$fpen.prop <- input$moose_FpenPerc / 100
    })
    ## moose reduction with penning
    moose_getF <- reactive({
        caribou_forecast(values$moose,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = values$moose$fpen.prop)
    })
    ## no moose reduction with penning
    moose_getB <- reactive({
        caribou_forecast(values$moose0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = values$moose0$fpen.prop)
    })
    ## moose reduction without penning
    moose_getF0 <- reactive({
        caribou_forecast(values$moose,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## no moose reduction without penning
    moose_getB0 <- reactive({
        caribou_forecast(values$moose0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## making nice table of the results
    moose_getT <- reactive({
        req(moose_getF(),
            moose_getB(),
            moose_getF0(),
            moose_getB0())
        tab <- cbind(
            MooseNoPen=unlist(summary(moose_getF0())),
            MoosePen=unlist(summary(moose_getF())),
            NoMooseNoPen=unlist(summary(moose_getB0())),
            NoMoosePen=unlist(summary(moose_getB()))
        )
        subs <- c("lam.pen", "Nend.pen")
        df <- tab[subs,,drop=FALSE]
        rownames(df) <- c("&lambda;", "N (end)")
        colnames(df) <- c(
            "Moose reduction, no pen",
            "Moose reduction, penned",
            "No moose reduction, no pen",
            "No moose reduction, penned")
        df
    })
    ## making nice table of the settings
    moose_getS <- reactive({
        req(moose_getF(),
            moose_getB(),
            moose_getF0(),
            moose_getB0())
        tab <- cbind(
            MooseNoPen=get_settings(moose_getF0()),
            MoosePen=get_settings(moose_getF()),
            NoMooseNoPen=get_settings(moose_getB0()),
            NoMoosePen=get_settings(moose_getB())
        )
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            "fpen.prop" = "% females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Pregnancy rate, wild",
            "f.preg.capt" = "Pregnancy rate, captive",
            "pen.cap" = "Max in a single pen")
        df <- tab[names(SNAM),,drop=FALSE]
        df["fpen.prop",] <- df["fpen.prop",]*100
        rownames(df) <- SNAM
        colnames(df) <- c(
            "Moose reduction, no pen",
            "Moose reduction, penned",
            "No moose reduction, no pen",
            "No moose reduction, penned")
        df
    })
    ## plot
    output$moose_Plot <- renderPlotly({
        req(moose_getF())
        dF0 <- plot(moose_getF0(), plot=FALSE)
        dF <- plot(moose_getF(), plot=FALSE)
        dB0 <- plot(moose_getB0(), plot=FALSE)
        dB <- plot(moose_getB(), plot=FALSE)
        colnames(dF0)[colnames(dF0) == "Npen"] <- "Individuals"
        p <- plot_ly(dF0, x = ~Years, y = ~Individuals,
            name = 'Moose reduction, no pen', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~Npen, name = 'Moose reduction, penned', data = dF,
                mode = 'lines', color=I('blue')) %>%
            add_trace(y = ~Npen, name = 'No moose reduction, no pen', data = dB0,
                    line=list(dash = 'dash', color='red')) %>%
            add_trace(y = ~Npen, name = 'No moose reduction, penned', data = dB,
                line=list(dash = 'dash', color='blue')) %>%
            layout(legend = list(x = 100, y = 0))
        p
    })
    ## table
    output$moose_Table <- renderTable({
        req(moose_getT())
        moose_getT()
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)
    ## dowload
    moose_xlslist <- reactive({
        req(moose_getF(), moose_getF0(), moose_getB(), moose_getB0())
        req(moose_getT())
        TS <- cbind(
            plot(moose_getF0(), plot=FALSE)[,c("Years", "Npen")],
            plot(moose_getF(), plot=FALSE)[,"Npen"],
            plot(moose_getB0(), plot=FALSE)[,"Npen"],
            plot(moose_getB(), plot=FALSE)[,"Npen"])
        colnames(TS) <- c("Years",
            "N moose reduction, no pen",
            "N moose reduction, penned",
            "N no moose reduction, no pen",
            "N no moose reduction, penned")
        df <- moose_getT()
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- moose_getS()
        ver <- read.dcf(file=system.file("DESCRIPTION", package="CaribouBC"),
            fields="Version")
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$herd))),
            Settings=as.data.frame(ss),
            TimeSeries=as.data.frame(TS),
            Summary=as.data.frame(df))
        out$Settings$Parameters <- rownames(ss)
        out$Settings <- out$Settings[,c(ncol(ss)+1, 1:ncol(ss))]
        out$Summary$Variables <- rownames(df)
        out$Summary <- out$Summary[,c(ncol(df)+1, 1:ncol(df))]
        out
    })
    output$moose_download <- downloadHandler(
        filename = function() {
            paste0("CaribouBC_moose_reduction_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(moose_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


}
