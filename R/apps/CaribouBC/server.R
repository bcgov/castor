server <- function(input, output, session) {

    ## >>> common part for all 3 tabs <<<====================

    ## set values based inits
    values <- reactiveValues(
        use_perc = TRUE,
        penning = inits$penning,
        penning0 = NULL,
        penning_compare = FALSE,
        predator = inits$predator,
        predator0 = NULL,
        predator_compare = FALSE,
        moose = inits$moose,
        moose0 = inits$moose0,
        wolf = inits$wolf,
        wolf0 = inits$wolf0,
        breeding = inits$breeding)
    ## set perc/inds
    observeEvent(input$use_perc, {
        values$use_perc <- input$use_perc == "perc"
    })

    ## >>> penning tab <<<=====================================

    ## dynamically render sliders
    output$penning_demogr_sliders <- renderUI({
        if (input$penning_herd != "Default")
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
    ## dynamically render herd selector
    output$penning_herd <- renderUI({
        tagList(
            selectInput(
                "penning_herd", "Herd", c("Default"="Default", Herds, HerdsWolf)
            )
        )
    })
    ## dynamically render perc or inds slider
    output$penning_perc_or_inds <- renderUI({
        if (values$use_perc) {
            tagList(
                sliderInput("penning_Fpen", "Percent of females penned",
                    min = 0, max = 100, value = round(100*inits$penning$fpen.prop),
                    step = 1),
                bsTooltip("penning_Fpen",
                    "Change the percent of female population in maternity pens. Default set, but the user can toggle.")
            )
        } else {
            tagList(
                sliderInput("penning_Fpen", "Number of females penned",
                    min = 0, max = input$popstart, value = inits$penning$fpen.inds,
                    step = 1),
                bsTooltip("penning_Fpen",
                    "Change the number of females in maternity pens. Default set, but the user can toggle.")
            )
        }
    })
    ## observers
    observeEvent(input$penning_herd, {
        values$penning <- c(
            fpen.prop = values$penning$fpen.prop,
            fpen.inds = values$penning$fpen.inds,
            caribou_settings("mat.pen",
                herd = if (input$penning_herd == "Default")
                    NULL else input$penning_herd))
        if (values$penning_compare) {
            values$penning0 <- values$penning
        } else {
            values$penning0 <- NULL
        }
    })
    observeEvent(input$penning_button, {
        values$penning_compare <- !values$penning_compare
        if (values$penning_compare) {
            values$penning0 <- values$penning
        } else {
            values$penning0 <- NULL
        }
    })
    observeEvent(input$penning_Fpen, {
        if (values$use_perc) {
            values$penning$fpen.prop <- input$penning_Fpen / 100
        } else {
            values$penning$fpen.inds <- input$penning_Fpen
        }
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
            fpen.prop = if (values$use_perc) values$penning$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$penning$fpen.inds)
    })
    ## try to find breakeven point
    penning_getB <- reactive({
        req(penning_getF())
        p <- suppressWarnings(
            caribou_breakeven(penning_getF(),
                type = if (values$use_perc) "prop" else "inds")
        )
        if (is.na(p))
            return(NULL)
        caribou_forecast(penning_getF()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) p else NULL,
            fpen.inds = if (values$use_perc) NULL else p)
    })
    ## these are similar functions to the bechmark scenario
    penning_getF0 <- reactive({
        if (!values$penning_compare)
            return(NULL)
        caribou_forecast(values$penning0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$penning0$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$penning0$fpen.inds)
    })
    penning_getB0 <- reactive({
        req(penning_getF0())
        p <- suppressWarnings(
            caribou_breakeven(penning_getF0(),
                type = if (values$use_perc) "perc" else "inds")
        )
        if (is.na(p))
            return(NULL)
        caribou_forecast(penning_getF0()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) p else NULL,
            fpen.inds = if (values$use_perc) NULL else p)
    })
    ## making nice table of the results
    penning_getT <- reactive({
        req(penning_getF())
        bev <- if (is.null(penning_getB()))
            #NA else unlist(summary(penning_getB()))
            NA else get_summary(penning_getB(), values$use_perc)
        tab <- cbind(
            #Results=unlist(summary(penning_getF())),
            Results=get_summary(penning_getF(), values$use_perc),
            Breakeven=bev)
        subs <- c("fpen", "npens", "lam.pen", "lam.nopen",
            "Nend.pen", "Nend.nopen", "Nend.diff",
            "Cost.total", "Cost.percap")
        df <- tab[subs,,drop=FALSE]
        if (values$use_perc)
            df[1L,] <- df[1L,]*100
        rownames(df) <- c(if (values$use_perc) "% penned" else "# penned",
            "# pens", "&lambda; (maternity pen)", "&lambda; (no maternity pen)",
            "N (end, maternity pen)", "N (end, no maternity pen)", "N (end, difference)",
            "Total cost (x $1000)", "Cost per capita (x $1000 / caribou)")
        if (values$penning_compare) {
            bev0 <- if (is.null(penning_getB0()))
                #NA else unlist(summary(penning_getB0()))
                NA else get_summary(penning_getB0(), values$use_perc)
            tab0 <- cbind(
                #Results=unlist(summary(penning_getF0())),
                Results=get_summary(penning_getF0(), values$use_perc),
                Breakeven=bev0)
            df0 <- tab0[subs,,drop=FALSE]
            if (values$use_perc)
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
            NA else get_settings(penning_getB(), values$use_perc)
        tab <- cbind(
            Results=get_settings(penning_getF(), values$use_perc),
            Breakeven=bev)
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            #"fpen.prop" = "% females penned",
            "fpen" = if (values$use_perc)
                "% females penned" else "# females penned",
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
        rownames(df) <- SNAM
        if (values$penning_compare) {
            bev0 <- if (is.null(penning_getB0()))
                NA else get_settings(penning_getB0(), values$use_perc)
            tab0 <- cbind(
                Results=get_settings(penning_getF0(), values$use_perc),
                Breakeven=bev0)
            df0 <- tab0[names(SNAM),,drop=FALSE]
            if (values$use_perc)
                df0["fpen",] <- df0["fpen",]*100
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
                mode = 'lines', color=I('blue')) %>%
            config(displayModeBar = FALSE)
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
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$penning_herd))),
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
        if (input$predator_herd != "Default")
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
    ## dynamically render herd selector
    output$predator_herd <- renderUI({
        tagList(
            selectInput(
                "predator_herd", "Herd", c("Default"="Default", Herds)
            )
        )
    })
    ## dynamically render perc or inds slider
    output$predator_perc_or_inds <- renderUI({
        if (values$use_perc) {
            tagList(
                sliderInput("predator_Fpen", "Percent of females penned",
                    min = 0, max = 100, value = round(100*inits$predator$fpen.prop),
                    step = 1),
                bsTooltip("predator_Fpen",
                    "Change the percent of female population in maternity pens. Default set, but the user can toggle.")
            )
        } else {
            tagList(
                sliderInput("predator_Fpen", "Number of females penned",
                    min = 0, max = input$popstart, value = inits$predator$fpen.inds,
                    step = 1),
                bsTooltip("predator_Fpen",
                    "Change the number of females in maternity pens. Default set, but the user can toggle.")
            )
        }
    })
    ## observers
    observeEvent(input$predator_herd, {
        values$predator <- c(
            fpen.prop = values$predator$fpen.prop,
            fpen.inds = values$predator$fpen.inds,
            caribou_settings("mat.pen",
                herd = if (input$predator_herd == "Default") NULL else input$predator_herd))
        if (values$predator_compare) {
            values$predator0 <- values$predator
        } else {
            values$predator0 <- NULL
        }
    })
    observeEvent(input$predator_button, {
        values$predator_compare <- !values$predator_compare
        if (values$predator_compare) {
            values$predator0 <- values$predator
        } else {
            values$predator0 <- NULL
        }
    })
    observeEvent(input$predator_Fpen, {
        if (values$use_perc) {
            values$predator$fpen.prop <- input$predator_Fpen / 100
        } else {
            values$predator$fpen.inds <- input$predator_Fpen
        }
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
            fpen.prop = if (values$use_perc) values$predator$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$predator$fpen.inds)
    })
    ## try to find breakeven point
    predator_getB <- reactive({
        req(predator_getF())
        p <- suppressWarnings(
            caribou_breakeven(predator_getF(),
                type = if (values$use_perc) "prop" else "inds")
        )
        if (is.na(p))
            return(NULL)
        caribou_forecast(predator_getF()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) p else NULL,
            fpen.inds = if (values$use_perc) NULL else p)
    })
    ## these are similar functions to the bechmark scenario
    predator_getF0 <- reactive({
        if (!values$predator_compare)
            return(NULL)
        caribou_forecast(values$predator0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$predator0$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$predator0$fpen.inds)
    })
    predator_getB0 <- reactive({
        req(predator_getF0())
        p <- suppressWarnings(
            caribou_breakeven(predator_getF0(),
                type = if (values$use_perc) "perc" else "inds")
        )
        if (is.na(p))
            return(NULL)
        caribou_forecast(predator_getF0()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) p else NULL,
            fpen.inds = if (values$use_perc) NULL else p)
    })
    ## making nice table of the results
    predator_getT <- reactive({
        req(predator_getF())
        bev <- if (is.null(predator_getB()))
            #NA else unlist(summary(predator_getB()))
            NA else get_summary(predator_getB(), values$use_perc)
        tab <- cbind(
            #Results=unlist(summary(predator_getF())),
            Results=get_summary(predator_getF(), values$use_perc),
            Breakeven=bev)
        subs <- c("fpen", "npens", "lam.pen", "lam.nopen",
            "Nend.pen", "Nend.nopen", "Nend.diff",
            "Cost.total", "Cost.percap")
        df <- tab[subs,,drop=FALSE]
        if (values$use_perc)
            df[1L,] <- df[1L,]*100
        rownames(df) <- c(if (values$use_perc) "% penned" else "# penned",
            "# pens", "&lambda; (predator exclosure)", "&lambda; (no predator exclosure)",
            "N (end, predator exclosure)", "N (end, no predator exclosure)", "N (end, difference)",
            "Total cost (x $1000)", "Cost per capita (x $1000 / caribou)")
        if (values$predator_compare) {
            bev0 <- if (is.null(predator_getB0()))
                #NA else unlist(summary(predator_getB0()))
                NA else get_summary(predator_getB0(), values$use_perc)
            tab0 <- cbind(
                #Results=unlist(summary(predator_getF0())),
                Results=get_summary(predator_getF0(), values$use_perc),
                Breakeven=bev0)
            df0 <- tab0[subs,,drop=FALSE]
            if (values$use_perc)
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
            NA else get_settings(predator_getB(), values$use_perc)
        tab <- cbind(
            Results=get_settings(predator_getF(), values$use_perc),
            Breakeven=bev)
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            #"fpen.prop" = "% females penned",
            "fpen" = if (values$use_perc)
                "% females penned" else "# females penned",
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
        rownames(df) <- SNAM
        if (values$predator_compare) {
            bev0 <- if (is.null(predator_getB0()))
                NA else get_settings(predator_getB0(), values$use_perc)
            tab0 <- cbind(
                Results=get_settings(predator_getF0(), values$use_perc),
                Breakeven=bev0)
            df0 <- tab0[names(SNAM),,drop=FALSE]
            if (values$use_perc)
                df0["fpen",] <- df0["fpen",]*100
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
                mode = 'lines', color=I('blue')) %>%
            config(displayModeBar = FALSE)
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
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$predator_herd))),
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

    ## dynamically render sliders
    output$moose_demogr_sliders <- renderUI({
        if (input$moose_herd != "Default")
            return(p("Demography settings not available for specific herds."))
        tagList(
            sliderInput("moose_DemCsw", "Calf survival, moose reduction",
                min = 0, max = 1, value = inits$moose$c.surv.wild, step = 0.01),
            sliderInput("moose_DemCsc", "Calf survival, no moose reduction",
                min = 0, max = 1, value = inits$moose0$c.surv.wild, step = 0.01),
            sliderInput("moose_DemFsw", "Adult female survival, moose reduction",
                min = 0, max = 1, value = inits$moose$f.surv.wild, step = 0.01),
            sliderInput("moose_DemFsc", "Adult female survival, no moose reduction",
                min = 0, max = 1, value = inits$moose0$f.surv.wild, step = 0.01),
            sliderInput("moose_DemFpw", "Pregnancy rate, moose reduction",
                min = 0, max = 1, value = inits$moose$f.preg.wild, step = 0.01),
            sliderInput("moose_DemFpc", "Pregnancy rate, no moose reduction",
                min = 0, max = 1, value = inits$moose0$f.preg.wild, step = 0.01)
        )
    })    ## dynamically render herd selector
    output$moose_herd <- renderUI({
        tagList(
            selectInput(
                "moose_herd", "Herd", c("Default"="Default", Herds)
            )
        )
    })
    ## dynamically render perc or inds slider
    output$moose_perc_or_inds <- renderUI({
        if (values$use_perc) {
            tagList(
                sliderInput("moose_Fpen", "Percent of females penned",
                    min = 0, max = 100, value = round(100*inits$moose$fpen.prop),
                    step = 1),
                bsTooltip("moose_Fpen",
                    "Change the percent of female population in maternity pens. Default set, but the user can toggle.")
            )
        } else {
            tagList(
                sliderInput("moose_Fpen", "Number of females penned",
                    min = 0, max = input$popstart, value = inits$moose$fpen.inds,
                    step = 1),
                bsTooltip("moose_Fpen",
                    "Change the number of females in maternity pens. Default set, but the user can toggle.")
            )
        }
    })
    ## observers
    observeEvent(input$moose_herd, {
        values$moose <- c(
            fpen.prop = values$moose$fpen.prop,
            fpen.inds = values$moose$fpen.inds,
            caribou_settings("moose.red",
                herd = if (input$moose_herd == "Default")
                    NULL else input$moose_herd))
        values$moose0 <- c(
            fpen.prop = values$moose0$fpen.prop,
            fpen.inds = values$moose0$fpen.inds,
            caribou_settings("mat.pen",
                herd = if (input$moose_herd == "Default")
                    NULL else input$moose_herd))
    })
    observeEvent(input$moose_DemCsw, {
        values$moose$c.surv.wild <- input$moose_DemCsw
    })
    observeEvent(input$moose_DemCsc, {
        values$moose0$c.surv.wild <- input$moose_DemCsc
    })
    observeEvent(input$moose_DemFsw, {
        values$moose$f.surv.wild <- input$moose_DemFsw
    })
    observeEvent(input$moose_DemFsc, {
        values$moose0$f.surv.wild <- input$moose_DemFsc
    })
    observeEvent(input$moose_DemFpw, {
        values$moose$f.preg.wild <- input$moose_DemFpw
    })
    observeEvent(input$moose_DemFpc, {
        values$moose0$f.preg.wild <- input$moose_DemFpc
    })
    observeEvent(input$moose_Fpen, {
        if (values$use_perc) {
            values$moose$fpen.prop <- input$moose_Fpen / 100
            values$moose0$fpen.prop <- input$moose_Fpen / 100
        } else {
            values$moose$fpen.inds <- input$moose_Fpen
            values$moose0$fpen.inds <- input$moose_Fpen
        }
    })
    ## moose reduction with penning
    moose_getF <- reactive({
        caribou_forecast(values$moose,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$moose$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$moose$fpen.inds)
    })
    ## no moose reduction with penning
    moose_getB <- reactive({
        caribou_forecast(values$moose0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$moose0$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$moose0$fpen.inds)
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
        subs <- c("lam.pen", "Nend.pen")
        df <- cbind(
            MooseNoPen=get_summary(moose_getF0(), values$use_perc)[subs],
            MoosePen=get_summary(moose_getF(), values$use_perc)[subs],
            NoMooseNoPen=get_summary(moose_getB0(), values$use_perc)[subs],
            NoMoosePen=get_summary(moose_getB(), values$use_perc)[subs]
        )
        #print(str(df))
        #df <- tab[subs,,drop=FALSE]
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
            MooseNoPen=get_settings(moose_getF0(), values$use_perc),
            MoosePen=get_settings(moose_getF(), values$use_perc),
            NoMooseNoPen=get_settings(moose_getB0(), values$use_perc),
            NoMoosePen=get_settings(moose_getB(), values$use_perc)
        )
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            #"fpen.prop" = "% females penned",
            "fpen" = if (values$use_perc)
                "% females penned" else "# females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Pregnancy rate, wild",
            "f.preg.capt" = "Pregnancy rate, captive",
            "pen.cap" = "Max in a single pen")
        df <- tab[names(SNAM),,drop=FALSE]
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
            layout(legend = list(x = 100, y = 0)) %>%
            config(displayModeBar = FALSE)
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
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$moose_herd))),
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


    ## >>> wolf tab <<<=====================================

    ## dynamically render sliders
    output$wolf_demogr_sliders <- renderUI({
        if (input$wolf_herd != "Default")
            return(p("Demography settings not available for specific herds."))
        tagList(
            sliderInput("wolf_DemCsw", "Calf survival, wolf reduction",
                min = 0, max = 1, value = inits$wolf$c.surv.wild, step = 0.01),
            sliderInput("wolf_DemCsc", "Calf survival, no wolf reduction",
                min = 0, max = 1, value = inits$wolf0$c.surv.wild, step = 0.01),
            sliderInput("wolf_DemFsw", "Adult female survival, wolf reduction",
                min = 0, max = 1, value = inits$wolf$f.surv.wild, step = 0.01),
            sliderInput("wolf_DemFsc", "Adult female survival, no wolf reduction",
                min = 0, max = 1, value = inits$wolf0$f.surv.wild, step = 0.01),
            sliderInput("wolf_DemFpw", "Pregnancy rate, wolf reduction",
                min = 0, max = 1, value = inits$wolf$f.preg.wild, step = 0.01),
            sliderInput("wolf_DemFpc", "Pregnancy rate, no wolf reduction",
                min = 0, max = 1, value = inits$wolf0$f.preg.wild, step = 0.01)
        )
    })
    ## dynamically render herd selector
    output$wolf_herd <- renderUI({
        tagList(
            selectInput(
                "wolf_herd", "Herd", c("Default"="Default", HerdsWolf)
            )
        )
    })
    ## observers
    observeEvent(input$wolf_herd, {
        values$wolf <- caribou_settings("wolf.red",
                herd = if (input$wolf_herd == "Default")
                    NULL else input$wolf_herd)
        ## set AFS=0.801 CS=0.295 under no wolf option
        values$wolf0 <- caribou_settings("mat.pen",
                herd = if (input$wolf_herd == "Default")
                    NULL else input$wolf_herd,
                f.surv.capt=0.801,
                f.surv.wild=0.801,
                c.surv.capt=0.295,
                c.surv.wild=0.295)
    })
    observeEvent(input$wolf_DemCsw, {
        values$wolf$c.surv.wild <- input$wolf_DemCsw
    })
    observeEvent(input$wolf_DemCsc, {
        values$wolf0$c.surv.wild <- input$wolf_DemCsc
    })
    observeEvent(input$wolf_DemFsw, {
        values$wolf$f.surv.wild <- input$wolf_DemFsw
    })
    observeEvent(input$wolf_DemFsc, {
        values$wolf0$f.surv.wild <- input$wolf_DemFsc
    })
    observeEvent(input$wolf_DemFpw, {
        values$wolf$f.preg.wild <- input$wolf_DemFpw
    })
    observeEvent(input$wolf_DemFpc, {
        values$wolf0$f.preg.wild <- input$wolf_DemFpc
    })
    ## wolf reduction without penning
    wolf_getF0 <- reactive({
        caribou_forecast(values$wolf,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## no wolf reduction without penning
    wolf_getB0 <- reactive({
        caribou_forecast(values$wolf0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## making nice table of the results
    wolf_getT <- reactive({
        req(wolf_getF0(),
            wolf_getB0())
        subs <- c("lam.pen", "Nend.pen")
        df <- rbind(
            WolfNoPen=get_summary(wolf_getF0(), values$use_perc)[subs],
            NoWolfNoPen=get_summary(wolf_getB0(), values$use_perc)[subs])
        df <- rbind(df, c(NA, df[1, "Nend.pen"]-df[2, "Nend.pen"]))
        colnames(df) <- c("&lambda;", "N (end)")
        rownames(df) <- c(
            "Wolf reduction",
            "No wolf reduction",
            "Difference")
        df
    })
    ## making nice table of the settings
    wolf_getS <- reactive({
        req(wolf_getF0(),
            wolf_getB0())
        tab <- cbind(
            WolfNoPen=get_settings(wolf_getF0(), values$use_perc),
            NoWolfNoPen=get_settings(wolf_getB0(), values$use_perc))
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            #"fpen.prop" = "% females penned",
            "fpen" = if (values$use_perc)
                "% females penned" else "# females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Pregnancy rate, wild",
            "f.preg.capt" = "Pregnancy rate, captive",
            "pen.cap" = "Max in a single pen")
        print("wolf_getS 3")
        df <- tab[names(SNAM),,drop=FALSE]
        rownames(df) <- SNAM
        colnames(df) <- c(
            "Wolf reduction",
            "No wolf reduction")
        df
    })
    ## plot
    output$wolf_Plot <- renderPlotly({
        req(wolf_getF0(),
            wolf_getB0())
        dF0 <- plot(wolf_getF0(), plot=FALSE)
        dB0 <- plot(wolf_getB0(), plot=FALSE)
        colnames(dF0)[colnames(dF0) == "Npen"] <- "Individuals"
        p <- plot_ly(dF0, x = ~Years, y = ~Individuals,
            name = 'Wolf reduction', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~Npen, name = 'No wolf reduction', data = dB0,
                    mode = 'lines', color=I('blue')) %>%
            layout(legend = list(x = 100, y = 0)) %>%
            config(displayModeBar = FALSE)
        p
    })
    ## table
    output$wolf_Table <- renderTable({
        req(wolf_getT())
        wolf_getT()
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)
    ## dowload
    wolf_xlslist <- reactive({
        req(wolf_getF0(), wolf_getB0())
        print("req")
        req(wolf_getT())
        print("req getT")
        TS <- cbind(
            plot(wolf_getF0(), plot=FALSE)[,c("Years", "Npen")],
            plot(wolf_getB0(), plot=FALSE)[,"Npen"])
        print("TS")
        colnames(TS) <- c("Years",
            "N wolf reduction",
            "N no wolf reduction")
        df <- wolf_getT()
        print("getT")
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- wolf_getS()
        print("getS")
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$wolf_herd))),
            Settings=as.data.frame(ss),
            TimeSeries=as.data.frame(TS),
            Summary=as.data.frame(df))
        out$Settings$Parameters <- rownames(ss)
        out$Settings <- out$Settings[,c(ncol(ss)+1, 1:ncol(ss))]
        out$Summary$Variables <- rownames(df)
        out$Summary <- out$Summary[,c(ncol(df)+1, 1:ncol(df))]
        print("out")
        out
    })
    output$wolf_download <- downloadHandler(
        filename = function() {
            paste0("CaribouBC_wolf_reduction_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(wolf_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> breeding tab <<<=====================================

    ## dynamically render sliders
    output$breeding_years <- renderUI({
        tagList(
            sliderInput("breeding_yrs",
                "Number of years to put females in captivity",
                min = 0, max = input$tmax, value = 1, step = 1)
        )
    })
    output$breeding_jyears <- renderUI({
        tagList(
            sliderInput("breeding_jyrs",
                "Number of years to delay juvenile transfer",
                min = 0, max = input$tmax, value = 0, step = 1)
        )
    })
    output$breeding_demogr_sliders <- renderUI({
        if (input$breeding_herd != "Default")
            return(p("Demography settings not available for specific herds."))
        tagList(
            sliderInput("breeding_DemCsc", "Calf survival, penned",
                min = 0, max = 1, value = inits$breeding$c.surv.capt, step = 0.01),
            sliderInput("breeding_DemCsw", "Calf survival, recipient & status quo",
                min = 0, max = 1, value = inits$breeding$c.surv.wild, step = 0.01),
            sliderInput("breeding_DemFsc", "Adult female survival, penned",
                min = 0, max = 1, value = inits$breeding$f.surv.capt, step = 0.01),
            sliderInput("breeding_DemFsw", "Adult female survival, recipient & status quo",
                min = 0, max = 1, value = inits$breeding$f.surv.wild, step = 0.01),
            sliderInput("breeding_DemFpc", "Pregnancy rate, penned",
                min = 0, max = 1, value = inits$breeding$f.preg.capt, step = 0.01),
            sliderInput("breeding_DemFpw", "Pregnancy rate, recipient & status quo",
                min = 0, max = 1, value = inits$breeding$f.preg.wild, step = 0.01)
        )
    })
    ## dynamically render herd selector
    output$breeding_herd <- renderUI({
        tagList(
            selectInput(
                "breeding_herd", "Herd", c("Default"="Default", Herds)
            )
        )
    })
    ## observers
    observeEvent(input$breeding_herd, {
        values$breeding <- caribou_settings("mat.pen",
                herd = if (input$breeding_herd == "Default")
                    NULL else input$breeding_herd)
    })
    observeEvent(input$breeding_DemCsw, {
        values$breeding$c.surv.wild <- input$breeding_DemCsw
    })
    observeEvent(input$breeding_DemCsc, {
        values$breeding$c.surv.capt <- input$breeding_DemCsc
    })
    observeEvent(input$breeding_DemFsw, {
        values$breeding$f.surv.wild <- input$breeding_DemFsw
    })
    observeEvent(input$breeding_DemFsc, {
        values$breeding$f.surv.capt <- input$breeding_DemFsc
    })
    observeEvent(input$breeding_DemFpw, {
        values$breeding$f.preg.wild <- input$breeding_DemFpw
    })
    observeEvent(input$breeding_DemFpc, {
        values$breeding$f.preg.capt <- input$breeding_DemFpc
    })
    ## breeding reduction without penning
    breeding_getF <- reactive({
        req(input$breeding_yrs, input$breeding_ininds, input$breeding_jyrs)
        nn <- rep(input$breeding_ininds, input$breeding_yrs)
        op <- c(rep(0, input$breeding_jyrs), input$breeding_outprop)
        caribou_breeding(values$breeding,
            tmax = input$tmax,
            pop.start = input$popstart,
            f.surv.trans = input$breeding_ftrans,
            j.surv.trans = input$breeding_jtrans,
            j.surv.red = input$breeding_jsred,
            in.inds = nn,
            out.prop = op)
    })
    ## plot
    output$breeding_Plot <- renderPlotly({
        req(breeding_getF())
        bb <- breeding_getF()
        dF <- summary(bb)
        colnames(dF)[colnames(dF) == "Nrecip"] <- "Individuals"
        p <- plot_ly(dF, x = ~Years, y = ~Individuals,
            name = 'Recipient', type = 'scatter', mode = 'lines',
            text = hover(t(bb$Nrecip)),
            hoverinfo = 'text',
            color=I('red')) %>%
            add_trace(y = ~Nwild, name = 'Status quo', data = dF,
                    mode = 'lines', color=I('blue'),
                    text = hover(t(bb$Nwild))) %>%
            add_trace(y = ~Ncapt, name = 'Penned', data = dF,
                    mode = 'lines', color=I('black'),
                    text = hover(t(bb$Ncapt))) %>%
            add_trace(y = ~Nout, name = 'Juvenile females out', data = dF,
                    mode = 'lines', color=I('orange'),
                    text = hover(t(bb$Nout))) %>%
            add_trace(y = ~Nin, name = 'Adult females in', data = dF,
                line=list(color='grey'),
                text = hover(t(bb$Nin))) %>%
            layout(legend = list(x = 100, y = 0)) %>%
            config(displayModeBar = FALSE)
        p
    })
    ## making nice table of the settings
    breeding_getS <- reactive({
        req(breeding_getF())
        x <- breeding_getF()
        s <- x$settings
        s$call <- NULL
        tab <- cbind(c(tmax = x$tmax,
            pop.start = x$pop.start,
            out.prop=x$out.prop,
            f.surv.trans=x$f.surv.trans,
            j.surv.trans=x$j.surv.trans,
            j.surv.red=x$j.surv.red,
            unlist(s)))
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, penned",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, penned",
            "f.preg.wild" = "Pregnancy rate, wild",
            "f.preg.capt" = "Pregnancy rate, penned",
            #"out.prop"="Proportion of calves transferred",
            "f.surv.trans"="Adult female survival during capture/transport",
            "j.surv.trans"="Juvenile female survival during capture/transport",
            "j.surv.red"="Juvenile female survival reduction in year 1")
        df <- tab[names(SNAM),,drop=FALSE]
        rownames(df) <- SNAM
        colnames(df) <- "Breeding"
        df
    })
    ## table
    output$breeding_Table <- renderTable({
        req(breeding_getF())
        dF <- summary(breeding_getF())[,-(1:3)]
        colnames(dF) <- c("Penned", "Recipient", "Status quo")
        N0 <- dF[1,,drop=FALSE]
        Ntmax1 <- dF[nrow(dF)-1L,,drop=FALSE]
        Ntmax <- dF[nrow(dF),,drop=FALSE]
        df <- rbind(
            'N'=Ntmax,
            '&lambda;'=round(Ntmax/Ntmax1, 3))
        df[2,2] <- round((Ntmax/N0)^(1/nrow(dF)), 3)[2]
        df
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)

    ## dowload
    breeding_xlslist <- reactive({
        req(breeding_getF())
        bb <- breeding_getF()
        dF <- summary(bb)
        ss <- breeding_getS()
        out <- list(
            Info=data.frame(CaribouBC=paste0(
                c("R package version: ", "Date of analysis: ", "Caribou herd: "),
                c(ver, format(Sys.time(), "%Y-%m-%d"), input$breeding_herd))),
            Settings=as.data.frame(ss),
            TimeSeries=as.data.frame(dF),
            AgeClasses=stack_breeding(bb))
        out$Settings$Parameters <- rownames(ss)
        out$Settings <- out$Settings[,c(ncol(ss)+1, 1:ncol(ss))]
        out
    })
    output$breeding_download <- downloadHandler(
        filename = function() {
            paste0("CaribouBC_breeding_reduction_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(breeding_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


}
