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
        breeding = inits$breeding,
        breeding1 = inits$breeding1,
        multi1 = inits$multi1)
    ## set perc/inds
    observeEvent(input$use_perc, {
        values$use_perc <- input$use_perc == "perc"
    })

    ## >>> multi1 tab <<<=====================================

    ## dynamically render sliders
    output$multi1_demogr_wild <- renderUI({
        #req(input$multi1_herd)
        tagList(
            sliderInput("multi1_DemCsw", "Calf survival, wild",
                min = 0, max = 1, value = values$multi1$c.surv.wild, step = 0.001),
            sliderInput("multi1_DemFsw", "Adult female survival, wild",
                min = 0, max = 1, value = values$multi1$f.surv.wild, step = 0.001),
            sliderInput("multi1_DemFpw", "Fecundity, wild",
                min = 0, max = 1, value = values$multi1$f.preg.wild, step = 0.001)
        )
    })
    output$multi1_demogr_captive <- renderUI({
        #req(input$multi1_herd)
        tagList(
            sliderInput("multi1_DemCsc", "Calf survival, MP",
                min = 0, max = 1, value = values$multi1$c.surv.capt, step = 0.001),
            sliderInput("multi1_DemFsc", "Adult female survival, MP",
                min = 0, max = 1, value = values$multi1$f.surv.capt, step = 0.001),
            sliderInput("multi1_DemFpc", "Fecundity, MP",
                min = 0, max = 1, value = values$multi1$f.preg.capt, step = 0.001),
            hr(),
            sliderInput("multi1_DemCsc_PE", "Calf survival, PE",
                min = 0, max = 1, value = values$multi1$c.surv.capt.pe,
                step = 0.001),
            sliderInput("multi1_DemFsc_PE", "Adult female survival, PE",
                min = 0, max = 1, value = values$multi1$f.surv.capt.pe,
                step = 0.001),
            sliderInput("multi1_DemFpc_PE", "Fecundity, PE",
                min = 0, max = 1, value = values$multi1$f.preg.capt.pe,
                step = 0.001)
        )
    })
    ## dynamically render perc or inds slider
    output$multi1_perc_or_inds <- renderUI({
        if (values$use_perc) {
            tagList(
                sliderInput("multi1_Fpen", "Percent of adult females penned",
                    min = 0, max = 100, value = round(100*inits$multi1$fpen.prop),
                    step = 1),
                bsTooltip("multi1_Fpen",
                    "Change the percent of adult female population in maternity penning. Default set, but the user can toggle.")
            )
        } else {
            tagList(
                sliderInput("multi1_Fpen", "Number of adult females penned",
                    min = 0, max = input$popstart, value = inits$multi1$fpen.inds,
                    step = 1),
                bsTooltip("multi1_Fpen",
                    "Change the number of adult females in maternity penning. Default set, but the user can toggle.")
            )
        }
    })
    observeEvent(input$multi1_Fpen, {
        if (values$use_perc) {
            values$multi1$fpen.prop <- input$multi1_Fpen / 100
        } else {
            values$multi1$fpen.inds <- input$multi1_Fpen
        }
    })
    ## multi1 extras
    observeEvent(input$multi1_DemFsw_MR, {
        values$multi1$f.surv.wild.mr <- input$multi1_DemFsw_MR
    })
    observeEvent(input$multi1_DemCsw_WR, {
        values$multi1$c.surv.wild.wr <- input$multi1_DemCsw_WR
    })
    observeEvent(input$multi1_DemFsw_WR, {
        values$multi1$f.surv.wild.wr <- input$multi1_DemFsw_WR
    })
    observeEvent(input$multi1_DemCsc_MPWRboost, {
        values$multi1$c.surv.capt.mpwrboost <- input$multi1_DemCsc_MPWRboost
    })
    observeEvent(input$multi1_DemFsc_MPWRboost, {
        values$multi1$f.surv.capt.mpwrboost <- input$multi1_DemFsc_MPWRboost
    })
    observeEvent(input$multi1_DemFsc_MPMRboost, {
        values$multi1$f.surv.capt.mpmrboost <- input$multi1_DemFsc_MPMRboost
    })
    observeEvent(input$multi1_DemCsc_PE, {
        values$multi1$c.surv.capt.pe <- input$multi1_DemCsc_PE
    })
    observeEvent(input$multi1_DemFsc_PE, {
        values$multi1$f.surv.capt.pe <- input$multi1_DemFsc_PE
    })
    observeEvent(input$multi1_DemFpc_PE, {
        values$multi1$f.preg.capt.pe <- input$multi1_DemFpc_PE
    })
    ## plain
    observeEvent(input$multi1_DemCsw, {
        values$multi1$c.surv.wild <- input$multi1_DemCsw
    })
    observeEvent(input$multi1_DemCsc, {
        values$multi1$c.surv.capt <- input$multi1_DemCsc
    })
    observeEvent(input$multi1_DemFsw, {
        values$multi1$f.surv.wild <- input$multi1_DemFsw
    })
    observeEvent(input$multi1_DemFsc, {
        values$multi1$f.surv.capt <- input$multi1_DemFsc
    })
    observeEvent(input$multi1_DemFpw, {
        values$multi1$f.preg.wild <- input$multi1_DemFpw
    })
    observeEvent(input$multi1_DemFpc, {
        values$multi1$f.preg.capt <- input$multi1_DemFpc
    })
    ## MP costs
    observeEvent(input$multi1_CostPencap_MP, {
        values$multi1$pen.cap <- input$multi1_CostPencap_MP
    })
    observeEvent(input$multi1_CostSetup_MP, {
        values$multi1$pen.cost.setup <- input$multi1_CostSetup_MP
    })
    observeEvent(input$multi1_CostProj_MP, {
        values$multi1$pen.cost.proj <- input$multi1_CostProj_MP
    })
    observeEvent(input$multi1_CostMaint_MP, {
        values$multi1$pen.cost.maint <- input$multi1_CostMaint_MP
    })
    observeEvent(input$multi1_CostCapt_MP, {
        values$multi1$pen.cost.capt <- input$multi1_CostCapt_MP
    })
    ## PE costs
    observeEvent(input$multi1_CostPencap_PE, {
        values$multi1$pen.cap.pe <- input$multi1_CostPencap_PE
    })
    observeEvent(input$multi1_CostSetup_PE, {
        values$multi1$pen.cost.setup.pe <- input$multi1_CostSetup_PE
    })
    observeEvent(input$multi1_CostProj_PE, {
        values$multi1$pen.cost.proj.pe <- input$multi1_CostProj_PE
    })
    observeEvent(input$multi1_CostMaint_PE, {
        values$multi1$pen.cost.maint.pe <- input$multi1_CostMaint_PE
    })
    observeEvent(input$multi1_CostCapt_PE, {
        values$multi1$pen.cost.capt.pe <- input$multi1_CostCapt_PE
    })
    observeEvent(input$multi1_CostPred_PE, {
        values$multi1$pen.cost.capt.pe <- input$multi1_CostPred_PE
    })

    ## get multi1 settings
    multi1_settings <- reactive({
        req(input$multi1_DemCsw, input$multi1_DemCsc, input$multi1_DemFsw_MR,
            input$multi1_CostProj_MP, input$multi1_CostProj_PE, input$multi1_Fpen)
        #HERD <- NULL
        HERD <- "AverageSubpop"
        Settings <- list(
            mp    = wildlift_settings("mat.pen", herd=HERD,
                c.surv.wild = input$multi1_DemCsw,
                c.surv.capt = input$multi1_DemCsc,
                f.surv.wild = input$multi1_DemFsw,
                f.surv.capt = input$multi1_DemFsc,
                f.preg.wild = input$multi1_DemFpw,
                f.preg.capt = input$multi1_DemFpc,
                pen.cap = input$multi1_CostPencap_MP,
                pen.cost.setup = input$multi1_CostSetup_MP,
                pen.cost.proj = input$multi1_CostProj_MP,
                pen.cost.maint = input$multi1_CostMaint_MP,
                pen.cost.capt = input$multi1_CostCapt_MP,
                pen.cost.pred = 0
            ),
            ## this boost for captive comes from females spending some of their life
            ## outside of the pen, thus receiving the boost
            ## boost is on top of the normal surv rate (MP+MR only)
            mp_mr = wildlift_settings("mat.pen", herd=HERD,
                c.surv.wild = input$multi1_DemCsw,
                c.surv.capt = input$multi1_DemCsc,
                f.surv.wild = input$multi1_DemFsw_MR,
                f.surv.capt = input$multi1_DemFsc + input$multi1_DemFsc_MPMRboost,
                f.preg.wild = input$multi1_DemFpw,
                f.preg.capt = input$multi1_DemFpc,
                pen.cap = input$multi1_CostPencap_MP,
                pen.cost.setup = input$multi1_CostSetup_MP,
                pen.cost.proj = input$multi1_CostProj_MP,
                pen.cost.maint = input$multi1_CostMaint_MP,
                pen.cost.capt = input$multi1_CostCapt_MP,
                pen.cost.pred = 0
            ),
            ## this boost for captive comes from females spending some of their life
            ## outside of the pen, thus receiving the boost
            ## boost is on top of the normal surv rate (MP+WR only)
            mp_wr = wildlift_settings("mat.pen", herd=HERD,
                c.surv.wild = input$multi1_DemCsw_WR,
                c.surv.capt = input$multi1_DemCsc + input$multi1_DemCsc_MPWRboost,
                f.surv.wild = input$multi1_DemFsw_WR,
                f.surv.capt = input$multi1_DemFsc + input$multi1_DemFsc_MPWRboost,
                f.preg.wild = input$multi1_DemFpw,
                f.preg.capt = input$multi1_DemFpc,
                pen.cap = input$multi1_CostPencap_MP,
                pen.cost.setup = input$multi1_CostSetup_MP,
                pen.cost.proj = input$multi1_CostProj_MP,
                pen.cost.maint = input$multi1_CostMaint_MP,
                pen.cost.capt = input$multi1_CostCapt_MP,
                pen.cost.pred = 0
            ),
            pe    = wildlift_settings("pred.excl", herd=HERD,
                c.surv.wild = input$multi1_DemCsw,
                c.surv.capt = input$multi1_DemCsc_PE,
                f.surv.wild = input$multi1_DemFsw,
                f.surv.capt = input$multi1_DemFsc_PE,
                f.preg.wild = input$multi1_DemFpw,
                f.preg.capt = input$multi1_DemFpc_PE,
                pen.cap = input$multi1_CostPencap_PE,
                pen.cost.setup = input$multi1_CostSetup_PE,
                pen.cost.proj = input$multi1_CostProj_PE,
                pen.cost.maint = input$multi1_CostMaint_PE,
                pen.cost.capt = input$multi1_CostCapt_PE,
                pen.cost.pred = input$multi1_CostPred_PE
            ),
            pe_mr = wildlift_settings("pred.excl", herd=HERD,
                c.surv.wild = input$multi1_DemCsw,
                c.surv.capt = input$multi1_DemCsc_PE,
                f.surv.wild = input$multi1_DemFsw_MR,
                f.surv.capt = input$multi1_DemFsc_PE,
                f.preg.wild = input$multi1_DemFpw,
                f.preg.capt = input$multi1_DemFpc_PE,
                pen.cap = input$multi1_CostPencap_PE,
                pen.cost.setup = input$multi1_CostSetup_PE,
                pen.cost.proj = input$multi1_CostProj_PE,
                pen.cost.maint = input$multi1_CostMaint_PE,
                pen.cost.capt = input$multi1_CostCapt_PE,
                pen.cost.pred = input$multi1_CostPred_PE
            ),
            pe_wr = wildlift_settings("pred.excl", herd=HERD,
                c.surv.wild = input$multi1_DemCsw_WR,
                c.surv.capt = input$multi1_DemCsc_PE,
                f.surv.wild = input$multi1_DemFsw_WR,
                f.surv.capt = input$multi1_DemFsc_PE,
                f.preg.wild = input$multi1_DemFpw,
                f.preg.capt = input$multi1_DemFpc_PE,
                pen.cap = input$multi1_CostPencap_PE,
                pen.cost.setup = input$multi1_CostSetup_PE,
                pen.cost.proj = input$multi1_CostProj_PE,
                pen.cost.maint = input$multi1_CostMaint_PE,
                pen.cost.capt = input$multi1_CostCapt_PE,
                pen.cost.pred = input$multi1_CostPred_PE
            )
        )
        Settings
    })
    ## Use inputs and get summary & traces
    multi1_getF <- reactive({
        req(multi1_settings())
        ML <- wildlift_multilever(multi1_settings(),
            TMAX = input$tmax,
            POP_START = input$popstart,
            VAL = if (values$use_perc)
                values$multi1$fpen.prop else values$multi1$fpen.inds,
            USE_PROP = values$use_perc)

        Cwolf <- input$multi1_nremove * input$tmax * input$multi1_cost1 / 1000
        sw <- ML$summary$Manage == "WR"
        ML$summary[sw, "Cend"] <- ML$summary[sw, "Cend"] + Cwolf
        ML$summary[sw, "Cnew"] <- ML$summary[sw, "Cend"] / ML$summary[sw, "Nnew"]
        ML$summary$Cend[is.na(ML$summary$Cend)] <- 0
        ML
    })

    ## plot
    output$multi1_Plot <- renderPlotly({
        req(multi1_getF())
        print("multi1 render")
        p <- plot_multilever(multi1_getF(), input$multi1_plot_type)
        config(ggplotly(p), displaylogo = FALSE)
    })
    ## table
    output$multi1_Table <- renderReactable({
        req(multi1_getF())
        TB <- multi1_getF()$summary
        #print(TB)
        TB$Demogr <- NULL
        TB$Manage <- NULL
        colnames(TB) <- c("lambda", "N (end)", "N (new)",
                          "Total cost (x $million)",
                          "Cost per new female (x $million)")
        reactable(round(TB, 3),
            highlight = TRUE,
            fullWidth = FALSE)
    })
    ## dowload
    multi1_xlslist <- reactive({
        req(multi1_getF())
        ML <- multi1_getF()
        Settings <- multi1_settings()
        ss <- do.call(rbind, lapply(seq_along(Settings), function(i) {
            z <- Settings[[i]]
            z$call <- NULL
            data.frame(Combination=names(Settings)[i],
                       Parameter=names(z),
                       Value=unlist(z))
        }))
        rownames(ss) <- NULL
        TS <- do.call(rbind, lapply(seq_along(ML$traces), function(i) {
            data.frame(Combination=names(ML$traces)[i], ML$traces[[i]])
        }))
        rownames(TS) <- NULL

        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Multi lever",
                  format(Sys.time(), "%Y-%m-%d"), "AverageSubpop"))),
            Settings=ss,
            TimeSeries=TS,
            Summary=ML$summary)
        out
    })
    output$multi1_download <- downloadHandler(
        filename = function() {
            paste0("WildLift_multilever_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(multi1_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )

    ## >>> penning tab <<<=====================================

    ## dynamically render sliders
    output$penning_demogr_sliders <- renderUI({
        if (input$penning_herd != "EastSideAthabasca")
            return(p("Demography settings not available for specific subpopulations."))
        tagList(
            sliderInput("penning_DemCsw", "Calf survival, wild",
                min = 0, max = 1, value = inits$penning$c.surv.wild, step = 0.001),
            sliderInput("penning_DemCsc", "Calf survival, captive",
                min = 0, max = 1, value = inits$penning$c.surv.capt, step = 0.001),
            sliderInput("penning_DemFsw", "Adult female survival, wild",
                min = 0, max = 1, value = inits$penning$f.surv.wild, step = 0.001),
            sliderInput("penning_DemFsc", "Adult female survival, captive",
                min = 0, max = 1, value = inits$penning$f.surv.capt, step = 0.001),
            sliderInput("penning_DemFpw", "Fecundity, wild",
                min = 0, max = 1, value = inits$penning$f.preg.wild, step = 0.001),
            sliderInput("penning_DemFpc", "Fecundity, captive",
                min = 0, max = 1, value = inits$penning$f.preg.capt, step = 0.001)
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
    ## dynamically render subpopulation selector
    output$penning_herd <- renderUI({
        tagList(
            selectInput(
                "penning_herd", "Subpopulation",
                c("Default (East Side Athabasca)"="EastSideAthabasca",
                  "Average subpopulation"="AverageSubpop",
                  Herds[-1], HerdsWolf)
            )
        )
    })
    ## dynamically render perc or inds slider
    output$penning_perc_or_inds <- renderUI({
        if (values$use_perc) {
            tagList(
                sliderInput("penning_Fpen", "Percent of adult females penned",
                    min = 0, max = 100, value = round(100*inits$penning$fpen.prop),
                    step = 1),
                bsTooltip("penning_Fpen",
                    "Change the percent of adult female population in maternity penning. Default set, but the user can toggle.")
            )
        } else {
            tagList(
                sliderInput("penning_Fpen", "Number of adult females penned",
                    min = 0, max = input$popstart, value = inits$penning$fpen.inds,
                    step = 1),
                bsTooltip("penning_Fpen",
                    "Change the number of adult females in maternity penning. Default set, but the user can toggle.")
            )
        }
    })
    ## observers
    observeEvent(input$penning_herd, {
        values$penning <- c(
            fpen.prop = values$penning$fpen.prop,
            fpen.inds = values$penning$fpen.inds,
            wildlift_settings("mat.pen",
                herd = if (input$penning_herd == "EastSideAthabasca")
                    NULL else input$penning_herd,
            pen.cap = input$penning_CostPencap,
            pen.cost.setup = input$penning_CostSetup,
            pen.cost.proj = input$penning_CostProj,
            pen.cost.maint = input$penning_CostMaint,
            pen.cost.capt = input$penning_CostCapt,
            pen.cost.pred = 0))
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
    ## apply settings and get forecast
    penning_getF <- reactive({
        wildlift_forecast(values$penning,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$penning$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$penning$fpen.inds)
    })
    ## try to find breakeven point
    penning_getB <- reactive({
        req(penning_getF())
        p <- suppressWarnings(
            wildlift_breakeven(penning_getF(),
                type = if (values$use_perc) "prop" else "inds")
        )
        if (is.na(p))
            return(NULL)
        wildlift_forecast(penning_getF()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) p else NULL,
            fpen.inds = if (values$use_perc) NULL else p)
    })
    ## these are similar functions to the bechmark scenario
    penning_getF0 <- reactive({
        if (!values$penning_compare)
            return(NULL)
        wildlift_forecast(values$penning0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$penning0$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$penning0$fpen.inds)
    })
    penning_getB0 <- reactive({
        req(penning_getF0())
        p <- suppressWarnings(
            wildlift_breakeven(penning_getF0(),
                type = if (values$use_perc) "prop" else "inds")
        )
        if (is.na(p))
            return(NULL)
        wildlift_forecast(penning_getF0()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) p else NULL,
            fpen.inds = if (values$use_perc) NULL else p)
    })
    ## making nice table of the results
    penning_getT <- reactive({
        req(penning_getF())
        bev <- if (is.null(penning_getB()))
            NA else get_summary(penning_getB(), values$use_perc)
        tab <- cbind(
            Results=get_summary(penning_getF(), values$use_perc),
            Breakeven=bev)
        subs <- c("fpen", "npens", "lam.pen", "lam.nopen",
            "Nend.pen", "Nend.nopen", "Nend.diff",
            "Cost.total", "Cost.percap")
        df <- tab[subs,,drop=FALSE]
        if (values$use_perc)
            df[1L,] <- df[1L,]*100
        rownames(df) <- c(if (values$use_perc) "% penned" else "# penned",
            "# pens", "&lambda; (maternity penning)", "&lambda; (status quo)",
            "N (end, maternity penning)", "N (end, status quo)", "N (new)",
            "Total cost (x $million)", "Cost per new female (x $million)")
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
                "% adult females penned" else "# adult females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Fecundity, wild",
            "f.preg.capt" = "Fecundity, captive",
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

        cat("Max # adult in pen:",
            round(max(penning_getF()$Npop$tot.adult.in.pen), 1), "\n")
        print(predator_getF()$Npop[,c("N.pen","N.nopen","pens.needed","tot.adult.in.pen")])

        df <- plot(penning_getF(), plot=FALSE)
        colnames(df)[colnames(df) == "Npen"] <- "Individuals"
        p <- plot_ly(df, x = ~Years, y = ~Individuals,
            name = 'Maternity penning', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~Nnopen, name = 'Status quo',
                mode = 'lines', color=I('black')) %>%
            config(displayModeBar = 'hover', displaylogo = FALSE)
        if (values$penning_compare) {
            df0 <- plot(penning_getF0(), plot=FALSE)
            p <- p %>% add_trace(y = ~Npen, name = 'Maternity penning, reference', data = df0,
                    line=list(dash = 'dash', color='red')) %>%
                add_trace(y = ~Nnopen, name = 'Status quo, reference', data = df0,
                    line=list(dash = 'dash', color='black'))
        }
        p <- p %>% layout(legend = list(x = 100, y = 0),
                          yaxis=list(title="Number of females"))
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
                "N status quo, reference", "N maternity penning, reference",
                "N status quo", "N maternity penning")
        }
        df <- penning_getT()
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- penning_getS()
        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Maternal penning",
                  format(Sys.time(), "%Y-%m-%d"), input$penning_herd))),
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
            paste0("WildLift_maternity_pen_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(penning_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> predator tab <<<=====================================

    ## dynamically render sliders
    output$predator_demogr_sliders <- renderUI({
        if (input$predator_herd != "EastSideAthabasca")
            return(p("Demography settings not available for specific subpopulations."))
        tagList(
             sliderInput("predator_DemCsw", "Calf survival, wild",
                min = 0, max = 1, value = inits$predator$c.surv.wild, step = 0.001),
             sliderInput("predator_DemCsc", "Calf survival, captive",
                min = 0, max = 1, value = inits$predator$c.surv.capt, step = 0.001),
             sliderInput("predator_DemFsw", "Adult female survival, wild",
                min = 0, max = 1, value = inits$predator$f.surv.wild, step = 0.001),
             sliderInput("predator_DemFsc", "Adult female survival, captive",
                min = 0, max = 1, value = inits$predator$f.surv.capt, step = 0.001),
             sliderInput("predator_DemFpw", "Fecundity, wild",
                min = 0, max = 1, value = inits$predator$f.preg.wild, step = 0.001),
             sliderInput("predator_DemFpc", "Fecundity, captive",
                min = 0, max = 1, value = inits$predator$f.preg.capt, step = 0.001)
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
    ## dynamically render subpopulation selector
    output$predator_herd <- renderUI({
        tagList(
            selectInput(
                "predator_herd", "Subpopulation",
                c("Default (East Side Athabasca)"="EastSideAthabasca",
                  "Average subpopulation"="AverageSubpop",
                  Herds[-1])
            )
        )
    })
    ## dynamically render perc or inds slider
    output$predator_perc_or_inds <- renderUI({
        if (values$use_perc) {
            tagList(
                sliderInput("predator_Fpen", "Percent of adult females penned",
                    min = 0, max = 100, value = round(100*inits$predator$fpen.prop),
                    step = 1),
                bsTooltip("predator_Fpen",
                    "Change the percent of adult female population in maternity penning. Default set, but the user can toggle.")
            )
        } else {
            tagList(
                sliderInput("predator_Fpen", "Number of adult females penned",
                    min = 0, max = input$popstart, value = inits$predator$fpen.inds,
                    step = 1),
                bsTooltip("predator_Fpen",
                    "Change the number of adult females in maternity penning. Default set, but the user can toggle.")
            )
        }
    })
    ## observers
    observeEvent(input$predator_herd, {
        values$predator <- c(
            fpen.prop = values$predator$fpen.prop,
            fpen.inds = values$predator$fpen.inds,
            wildlift_settings("pred.excl",
                herd = if (input$predator_herd == "EastSideAthabasca")
                    NULL else input$predator_herd,
            pen.cap = input$predator_CostPencap,
            pen.cost.setup = input$predator_CostSetup,
            pen.cost.proj = input$predator_CostProj,
            pen.cost.maint = input$predator_CostMaint,
            pen.cost.capt = input$predator_CostCapt,
            pen.cost.pred = input$predator_CostPred))
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
        wildlift_forecast(values$predator,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$predator$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$predator$fpen.inds)
    })
    ## try to find breakeven point
    predator_getB <- reactive({
        req(predator_getF())
        p <- suppressWarnings(
            wildlift_breakeven(predator_getF(),
                type = if (values$use_perc) "prop" else "inds")
        )
        if (is.na(p))
            return(NULL)
        wildlift_forecast(predator_getF()$settings,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) p else NULL,
            fpen.inds = if (values$use_perc) NULL else p)
    })
    ## these are similar functions to the bechmark scenario
    predator_getF0 <- reactive({
        if (!values$predator_compare)
            return(NULL)
        wildlift_forecast(values$predator0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = if (values$use_perc) values$predator0$fpen.prop else NULL,
            fpen.inds = if (values$use_perc) NULL else values$predator0$fpen.inds)
    })
    predator_getB0 <- reactive({
        req(predator_getF0())
        p <- suppressWarnings(
            wildlift_breakeven(predator_getF0(),
                type = if (values$use_perc) "prop" else "inds")
        )
        if (is.na(p))
            return(NULL)
        wildlift_forecast(predator_getF0()$settings,
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
            "# pens", "&lambda; (predator exclosure)", "&lambda; (status quo)",
            "N (end, predator exclosure)", "N (end, status quo)", "N (new)",
            "Total cost (x $million)", "Cost per new female (x $million)")
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
                "% adult females penned" else "# adult females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Fecundity, wild",
            "f.preg.capt" = "Fecundity, captive",
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

        cat("Max # adult in pen:",
            round(max(penning_getF()$Npop$tot.adult.in.pen), 1), "\n")
        print(predator_getF()$Npop[,c("N.pen","N.nopen","pens.needed","tot.adult.in.pen")])

        df <- plot(predator_getF(), plot=FALSE)
        colnames(df)[colnames(df) == "Npen"] <- "Individuals"
        p <- plot_ly(df, x = ~Years, y = ~Individuals,
            name = 'Predator exclosure', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~Nnopen, name = 'Status quo',
                mode = 'lines', color=I('black')) %>%
            config(displayModeBar = 'hover', displaylogo = FALSE)
        if (values$predator_compare) {
            df0 <- plot(predator_getF0(), plot=FALSE)
            p <- p %>% add_trace(y = ~Npen, name = 'Predator exclosure, reference', data = df0,
                    line=list(dash = 'dash', color='red')) %>%
                add_trace(y = ~Nnopen, name = 'Status quo, reference', data = df0,
                    line=list(dash = 'dash', color='black'))
        }
        p <- p %>% layout(legend = list(x = 100, y = 0),
                          yaxis=list(title="Number of females"))
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
                "N status quo, reference", "N predator exclosure, reference",
                "N status quo", "N predator exclosure")
        }
        df <- predator_getT()
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- predator_getS()
        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Predator exclosure",
                  format(Sys.time(), "%Y-%m-%d"), input$predator_herd))),
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
            paste0("WildLift_predator_exclosure_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(predator_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> moose tab <<<=====================================

    ## dynamically render sliders
    output$moose_demogr_sliders <- renderUI({
        if (input$moose_herd != "EastSideAthabasca")
            return(p("Demography settings not available for specific subpopulations."
                     ))
        tagList(
            sliderInput("moose_DemCsw", "Calf survival, moose reduction",
                min = 0, max = 1, value = inits$moose$c.surv.wild, step = 0.001),
            sliderInput("moose_DemCsc", "Calf survival, status quo",
                min = 0, max = 1, value = inits$moose0$c.surv.wild, step = 0.001),
            sliderInput("moose_DemFsw", "Adult female survival, moose reduction",
                min = 0, max = 1, value = inits$moose$f.surv.wild, step = 0.001),
            sliderInput("moose_DemFsc", "Adult female survival, status quo",
                min = 0, max = 1, value = inits$moose0$f.surv.wild, step = 0.001),
            sliderInput("moose_DemFpw", "Fecundity, moose reduction",
                min = 0, max = 1, value = inits$moose$f.preg.wild, step = 0.001),
            sliderInput("moose_DemFpc", "Fecundity, status quo",
                min = 0, max = 1, value = inits$moose0$f.preg.wild, step = 0.001)
        )
    })    ## dynamically render subpopulation selector
    output$moose_herd <- renderUI({
        tagList(
            selectInput(
                "moose_herd", "Subpopulation",
                c("Default (East Side Athabasca)"="EastSideAthabasca",
                  "Average subpopulation"="AverageSubpop",
                  Herds[-1])
            )
        )
    })
    ## observers
    observeEvent(input$moose_herd, {
        values$moose <- c(
            fpen.prop = 0.35,
            fpen.inds = 10,
            wildlift_settings("moose.red",
                herd = if (input$moose_herd == "EastSideAthabasca")
                    NULL else input$moose_herd))
        values$moose0 <- c(
            fpen.prop = 0.35,
            fpen.inds = 10,
            wildlift_settings("mat.pen",
                herd = if (input$moose_herd == "EastSideAthabasca")
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
    ## moose reduction without penning
    moose_getF0 <- reactive({
        wildlift_forecast(values$moose,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## no moose reduction without penning
    moose_getB0 <- reactive({
        wildlift_forecast(values$moose0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## making nice table of the results
    moose_getT <- reactive({
        req(moose_getF0(), moose_getB0())
        subs <- c("lam.pen", "Nend.pen")
        df <- cbind(
            NoMooseNoPen=get_summary(moose_getB0(), values$use_perc)[subs],
            MooseNoPen=get_summary(moose_getF0(), values$use_perc)[subs]
        )
        Nnew <- pmax(0, df[2,]-df[2,1])
        df <- rbind(df,
            Nnew=Nnew,
            Cost=c(NA, NA),
            CostPerNew=c(NA, NA))
        rownames(df) <- c("&lambda;", "N (end)", "N (new)",
                          "Total cost (x $million)",
                          "Cost per new female (x $million)")
        colnames(df) <- c(
            "Status quo",
            "Moose reduction")
        df
    })

    ## making nice table of the settings
    moose_getS <- reactive({
        req(moose_getF0(), moose_getB0())
        tab <- cbind(
            MooseNoPen=get_settings(moose_getF0(), values$use_perc),
            NoMooseNoPen=get_settings(moose_getB0(), values$use_perc)
        )
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            "c.surv.wild" = "Calf survival, wild",
            "f.surv.wild" = "Adult female survival, wild",
            "f.preg.wild" = "Fecundity, wild")
        df <- tab[names(SNAM),,drop=FALSE]
        rownames(df) <- SNAM
        colnames(df) <- c(
            "Moose reduction",
            "Status quo")
        df
    })
    ## plot
    output$moose_Plot <- renderPlotly({
        req(moose_getF0(), moose_getB0())
        dF0 <- plot(moose_getF0(), plot=FALSE)
        dB0 <- plot(moose_getB0(), plot=FALSE)
        colnames(dF0)[colnames(dF0) == "Npen"] <- "Individuals"
        p <- plot_ly(dF0, x = ~Years, y = ~Individuals,
            name = 'Moose reduction', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~Npen, name = 'Status quo', data = dB0,
                    line=list(color='black')) %>%
            layout(legend = list(x = 100, y = 0),
                   yaxis=list(title="Number of females")) %>%
            config(displayModeBar = 'hover', displaylogo = FALSE)
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
        req(moose_getF0(), moose_getB0())
        req(moose_getT())
        TS <- cbind(
            plot(moose_getF0(), plot=FALSE)[,c("Years", "Npen")],
            plot(moose_getB0(), plot=FALSE)[,"Npen"])
        colnames(TS) <- c("Years",
            "N moose reduction",
            "N status quo")
        df <- moose_getT()
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- moose_getS()
        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Moose reduction",
                  format(Sys.time(), "%Y-%m-%d"), input$moose_herd))),
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
            paste0("WildLift_moose_reduction_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(moose_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> wolf tab <<<=====================================

    ## dynamically render sliders
    output$wolf_demogr_sliders <- renderUI({
        req(input$wolf_herd)
        if (input$wolf_herd != "AverageSubpop")
            return(p("Demography settings not available for specific subpopulations."))
        tagList(
            sliderInput("wolf_DemCsw", "Calf survival, wolf reduction",
                min = 0, max = 1, value = inits$wolf$c.surv.wild, step = 0.001),
            sliderInput("wolf_DemCsc", "Calf survival, status quo",
                min = 0, max = 1, value = inits$wolf0$c.surv.wild, step = 0.001),
            sliderInput("wolf_DemFsw", "Adult female survival, wolf reduction",
                min = 0, max = 1, value = inits$wolf$f.surv.wild, step = 0.001),
            sliderInput("wolf_DemFsc", "Adult female survival, status quo",
                min = 0, max = 1, value = inits$wolf0$f.surv.wild, step = 0.001),
            sliderInput("wolf_DemFpw", "Fecundity, wolf reduction",
                min = 0, max = 1, value = inits$wolf$f.preg.wild, step = 0.001),
            sliderInput("wolf_DemFpc", "Fecundity, status quo",
                min = 0, max = 1, value = inits$wolf0$f.preg.wild, step = 0.001)
        )
    })
    ## dynamically render subpopulation selector
    output$wolf_herd <- renderUI({
        tagList(
            selectInput(
                "wolf_herd", "Subpopulation",
                c("Average subpopulation"="AverageSubpop",
                  HerdsWolf)
            )
        )
    })
    ## observers
    observeEvent(input$wolf_herd, {
        values$wolf <- wildlift_settings("wolf.red",
                herd = input$wolf_herd)
        ## set AFS=0.801 CS=0.295 under no wolf option
        values$wolf0 <- wildlift_settings("mat.pen",
                herd = input$wolf_herd,
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
        req(input$wolf_DemCsw)
        wildlift_forecast(values$wolf,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## no wolf reduction (status quo) without penning
    wolf_getB0 <- reactive({
        req(input$wolf_DemCsw)
        wildlift_forecast(values$wolf0,
            tmax = input$tmax,
            pop.start = input$popstart,
            fpen.prop = 0)
    })
    ## making nice table of the results
    wolf_getT <- reactive({
        req(wolf_getF0(),
            wolf_getB0())
        subs <- c("lam.pen", "Nend.pen")
        Cost <- input$wolf_nremove * input$tmax * input$wolf_cost1 / 1000
        df <- cbind(
            WolfNoPen=get_summary(wolf_getF0(), values$use_perc)[subs],
            NoWolfNoPen=get_summary(wolf_getB0(), values$use_perc)[subs])
        Nnew <- max(0, df[2,1] - df[2,2])
        CostPerNew <- if (Nnew <= 0) NA else Cost/Nnew
        df <- rbind(df,
            Nnew=c(Nnew,NA),
            Cost=c(Cost, NA),
            CostPerNew=c(CostPerNew, NA))
        rownames(df) <- c("&lambda;", "N (end)", "N (new)",
                          "Total cost (x $million)",
                          "Cost per new female (x $million)")
        colnames(df) <- c(
            "Wolf reduction",
            "Status quo")
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
                "% adult females penned" else "# adult females penned",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival, captive",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival, captive",
            "f.preg.wild" = "Fecundity, wild",
            "f.preg.capt" = "Fecundity, captive",
            "pen.cap" = "Max in a single pen")
        print("wolf_getS 3")
        df <- tab[names(SNAM),,drop=FALSE]
        rownames(df) <- SNAM
        colnames(df) <- c(
            "Wolf reduction",
            "Status quo")
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
            add_trace(y = ~Npen, name = 'Status quo', data = dB0,
                    mode = 'lines', color=I('black')) %>%
            layout(legend = list(x = 100, y = 0),
                yaxis=list(title="Number of females")) %>%
            config(displayModeBar = 'hover', displaylogo = FALSE)
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
            "N status quo")
        df <- wolf_getT()
        print("getT")
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        ss <- wolf_getS()
        print("getS")
        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Wolf reduction",
                  format(Sys.time(), "%Y-%m-%d"), input$wolf_herd))),
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
            paste0("WildLift_wolf_reduction_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(wolf_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> linear features <<<=====================================

    output$seismic_sliders <- renderUI({
        area <- switch(input$seismic_herd,
            "coldlake"=6726,
            "esar"=13119,
            "wsar"=15707)
        linkm <- switch(input$seismic_herd,
            "coldlake"=11432,
            "esar"=26154,
            "wsar"=26620)
        lin2d <- switch(input$seismic_herd,
            "coldlake"=8012,
            "esar"=21235,
            "wsar"=21941)
        yng <- switch(input$seismic_herd,
            "coldlake"=13.85,
            "esar"=25.70,
            "wsar"=6.88)
        tagList(
            sliderInput("seismic_area",
                "Range area (sq km)",
                min = 0, max = 20000, value = area, step = 1),
            sliderInput("seismic_linkm",
                "Linear feature length (km)",
                min = 0, max = 40000, value = linkm, step = 1),
            sliderInput("seismic_lin2d",
                "Conventional seismic length (km)",
                min = 0, max = 40000, value = lin2d, step = 1),
            sliderInput("seismic_young",
                "Percent young forest (<30 yrs; %)",
                min = 0, max = 100, value = round(yng, 1), step = 0.11),
#            sliderInput("seismic_cost",
#                "Cost per km (x $1000)",
#                min = 0, max = 100, value = 12, step = 1),
            sliderInput("seismic_deact",
                "Years for 100% deactivation",
                min = 0, max = 50, value = 5, step = 1),
            sliderInput("seismic_restor",
                "Years for 100% restoration",
                min = 0, max = 50, value = 15, step = 1)
        )
    })
    seismic_all <- reactive({
        req(input$seismic_area,
            input$seismic_linkm,
            input$seismic_lin2d,
            input$seismic_young)
        if (input$seismic_linkm < input$seismic_lin2d) {
            showNotification("Conventional seismic cannot be more than total linear",
                             type="error")
            return(NULL)
        }
        wildlift_linear(
            tmax=input$tmax,
            pop.start=input$popstart,
            area=input$seismic_area,
            lin=input$seismic_linkm,
            seism=input$seismic_lin2d,
            young=input$seismic_young,
            cost=input$seismic_cost,
            yr_deact=input$seismic_deact,
            yr_restor=input$seismic_restor)
    })

    ## plot
    output$seismic_Plot <- renderPlotly({
        req(seismic_all())
        sm <- seismic_all()
        #print(sm)
        dF <- data.frame(sm$pop)
        colnames(dF)[1:2] <- c("Years", "Individuals")
        p <- plot_ly(dF, x = ~Years, y = ~Individuals,
            name = 'No linear features', type = 'scatter', mode = 'lines',
            color=I('red')) %>%
            add_trace(y = ~N1, name = 'Status quo', data = dF,
                    mode = 'lines', color=I('black')) %>%
            add_trace(y = ~Ndeact, name = 'Deactivation', data = dF,
                    mode = 'lines', color=I('blue')) %>%
            add_trace(y = ~Nrestor, name = 'Restoration', data = dF,
                    mode = 'lines', color=I('orange')) %>%
            layout(legend = list(x = 100, y = 0),
                   yaxis=list(title="Number of females")) %>%
            config(displayModeBar = 'hover', displaylogo = FALSE)
        p
    })
    ## table
    seismic_getT <- reactive({
        req(seismic_all())
        sm <- seismic_all()
        dF <- data.frame(sm$pop)
        colnames(dF) <- c("Years", "No linear features", "Status quo",
            "Deactivation", "Restoration",
            "Linear density, deactivation", "Linear density, restoration",
            "Percent young forest")
        df <- dF[nrow(dF),2:5]
        rownames(df) <- "N (end)"
        cost <- c(NA, NA, sm$costdeact, sm$costrestor)
        Nnew <- c(NA, NA, pmax(0, dF[nrow(dF),4:5]-dF[nrow(dF),3]))
        df <- rbind(
            "&lambda;"=dF[nrow(dF),2:5]/dF[nrow(dF)-1,2:5],
            df,
            "N (new)"=Nnew,
            "Total cost (x $million)"=cost,
            "Cost per new female (x $million)"=c(ifelse(Nnew>0,cost/Nnew, NA), NA, NA))
        df
    })
    output$seismic_Table <- renderTable({
        req(seismic_getT())
        seismic_getT()
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)

    ## dowload
    seismic_xlslist <- reactive({
        req(seismic_all(), seismic_getT())
        sm <- seismic_all()
        dF <- data.frame(sm$pop)[,1:8]
        colnames(dF) <- c("Years", "No linear features", "Status quo",
                          "Deactivation", "Restoration",
        "Linear density, deactivation", "Linear density, restoration",
        "Percent young forest")
        df <- seismic_getT()
        print("getT")
        rownames(df) <- gsub("&lambda;", "lambda", rownames(df))
        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Linear feature deactivation/restoration",
                  format(Sys.time(), "%Y-%m-%d")))),
            TimeSeries=as.data.frame(dF),
            Summary=as.data.frame(df))
        out$Summary$Variables <- rownames(df)
        out$Summary <- out$Summary[,c(ncol(df)+1, 1:ncol(df))]
        out
    })
    output$seismic_download <- downloadHandler(
        filename = function() {
            paste0("WildLift_linear_features_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(seismic_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> breeding tab / single lever <<<=====================================

    ## dynamically render sliders
    output$breeding_years <- renderUI({
        tagList(
            sliderInput("breeding_yrs",
                "Number of years that adult females are added to the facility",
                min = 0, max = input$tmax, value = 0, step = 1) #value = 1
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
        req(input$breeding_herd)
        if (input$breeding_herd != "EastSideAthabasca")
            return(p("Demography settings not available for specific subpopulations."))
        tagList(
            sliderInput("breeding_DemCsc", "Calf survival in facility",
                min = 0, max = 1,
                value = inits$breeding$c.surv.capt, step = 0.001),
            sliderInput("breeding_DemCsw", "Calf survival, recipient & status quo",
                min = 0, max = 1,
                value = inits$breeding$c.surv.wild, step = 0.001),
            sliderInput("breeding_DemFsc", "Adult female survival in facility",
                min = 0, max = 1,
                value = inits$breeding$f.surv.capt, step = 0.001),
            sliderInput("breeding_DemFsw",
                        "Adult female survival, recipient & status quo",
                min = 0, max = 1,
                value = inits$breeding$f.surv.wild, step = 0.001),
            sliderInput("breeding_DemFpc", "Fecundity in facility",
                min = 0, max = 1,
                value = inits$breeding$f.preg.capt, step = 0.001),
            sliderInput("breeding_DemFpw", "Fecundity, recipient & status quo",
                min = 0, max = 1,
                value = inits$breeding$f.preg.wild, step = 0.001)
        )
    })
    ## dynamically render subpopulation selector
    output$breeding_herd <- renderUI({
        tagList(
            selectInput(
                "breeding_herd", "Subpopulation",
                c("Default (East Side Athabasca)"="EastSideAthabasca",
                  "Average subpopulation"="AverageSubpop",
                  Herds[-1])
            )
        )
    })
    ## observers
    observeEvent(input$breeding_herd, {
        values$breeding <- wildlift_settings("cons.breed",
            herd = if (input$breeding_herd == "EastSideAthabasca")
                NULL else input$breeding_herd,
            pen.cap = input$breeding_CostPencap,
            pen.cost.setup = input$breeding_CostSetup,
            pen.cost.proj = input$breeding_CostProj,
            pen.cost.maint = input$breeding_CostMaint,
            pen.cost.capt = input$breeding_CostCapt,
            pen.cost.pred = 0)
    })
    ## plain
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
    observeEvent(input$breeding_CostSetup, {
        values$breeding$pen.cost.setup <- input$breeding_CostSetup
    })
    observeEvent(input$breeding_CostProj, {
        values$breeding$pen.cost.proj <- input$breeding_CostProj
    })
    observeEvent(input$breeding_CostMaint, {
        values$breeding$pen.cost.maint <- input$breeding_CostMaint
    })
    observeEvent(input$breeding_CostCapt, {
        values$breeding$pen.cost.capt <- input$breeding_CostCapt
    })
    ## breeding reduction without penning
    breeding_getF <- reactive({
        req(input$breeding_herd)
        if (is.null(input$breeding_breedearly))
            return(NULL)
        req(input$breeding_yrs, input$breeding_ininds,
            input$breeding_jyrs)
        nn <- rep(input$breeding_ininds, input$breeding_yrs)
        op <- c(rep(0, input$breeding_jyrs), input$breeding_outprop)
        wildlift_breeding(values$breeding,
            tmax = input$tmax,
            pop.start = input$popstart,
            f.surv.trans = input$breeding_ftrans,
            j.surv.trans = input$breeding_jtrans,
            j.surv.red = input$breeding_jsred,
            in.inds = nn,
            out.prop = op,
            breed.early = input$breeding_breedearly)
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
                    mode = 'lines', color=I('black'),
                    text = hover(t(bb$Nwild))) %>%
            add_trace(y = ~Ncapt, name = 'Inside facility', data = dF,
                    mode = 'lines', color=I('purple'),
                    text = hover(t(bb$Ncapt))) %>%
            add_trace(y = ~Nout, name = 'Juvenile females out', data = dF,
                    mode = 'lines', color=I('orange'),
                    text = hover(t(bb$Nout))) %>%
            add_trace(y = ~Nin, name = 'Adult females in', data = dF,
                    line=list(color='green'),
                    text = hover(t(bb$Nin))) %>%
            layout(legend = list(x = 100, y = 0),
                   yaxis=list(title="Number of females")) %>%
            config(displayModeBar = 'hover', displaylogo = FALSE)
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
            f.surv.wild.mr=x$mr$f.surv.wild,
            f.surv.wild.wr=x$wr$f.surv.wild,
            c.surv.wild.wr=x$wr$c.surv.wild,
            unlist(s)))
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.capt" = "Calf survival in facility",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.capt" = "Adult female survival in facility",
            "f.preg.wild" = "Fecundity, wild",
            "f.preg.capt" = "Fecundity in facility",
            #"out.prop"="Proportion of calves transferred",
            "pen.cost.setup" = "Initial set up (x $1000)",
            "pen.cost.proj" = "Project manager (x $1000)",
            "pen.cost.maint" = "Maintenance (x $1000)",
            "pen.cost.capt" = "Capture/monitor (x $1000)",
            "pen.cost.pred" = "Removing predators (x $1000)",
            "f.surv.trans"="Adult female survival during capture/transport to facility",
            "j.surv.trans"="Juvenile female survival during capture/transport from facility to recipient subpopulation",
            "j.surv.red"="Relative reduction in survival of juvenile females transported to recipient subpopulation for 1 year after transport")
        df <- tab[names(SNAM),,drop=FALSE]
        rownames(df) <- SNAM
        colnames(df) <- "Breeding"
        #print(df)
        df
    })

    ## table
    output$breeding_Table <- renderTable({
        req(breeding_getF())
        zz <- breeding_getF()
        #zz <- revrt(zz)
        #str(zz$settings)

        ## one time cost
        cost1 <- zz$settings$pen.cost.setup
        ## yearly costs
        cost2 <- zz$settings$pen.cost.proj +
            zz$settings$pen.cost.maint +
            zz$settings$pen.cost.capt +
            zz$settings$pen.cost.pred
        cost <- (cost1 + zz$tmax * cost2) / 1000
        #print(c(c1=cost1/1000, c2=cost2/1000, c3=cost))

        Pick <- c(Ncapt="In facility", Nrecip="Recipient", Nwild="Status quo")
        dF <- summary(zz)[,names(Pick)]
        colnames(dF) <- Pick
        N0 <- dF[1,,drop=FALSE]
        Ntmax1 <- dF[nrow(dF)-1L,,drop=FALSE]
        Ntmax <- dF[nrow(dF),,drop=FALSE]
        Nnew <- Ntmax[1,"Recipient"] - Ntmax[1,"Status quo"]
        df <- rbind(
            '&lambda;'=round(Ntmax/Ntmax1, 3),
            'N (end)'=Ntmax,
            'N (new)'=c(NA, max(0,Nnew),NA),
            "Total cost (x $million)"=c(NA, cost, NA),
            "Cost per new female (x $million)"=c(NA,
                ifelse(Nnew>0,cost/Nnew, NA), NA))
        df
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)

    ## dowload
    breeding_xlslist <- reactive({
        req(breeding_getF())
        bb <- breeding_getF()
        #bb <- revrt(bb)
        dF <- summary(bb)
        ss <- breeding_getS()
        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Conservation breeding",
                  format(Sys.time(), "%Y-%m-%d"), input$breeding_herd))),
            Settings=as.data.frame(ss),
            TimeSeries=as.data.frame(dF),
            AgeClasses=stack_breeding(bb))
        out$Settings$Parameters <- rownames(ss)
        out$Settings <- out$Settings[,c(ncol(ss)+1, 1:ncol(ss))]
        out
    })
    output$breeding_download <- downloadHandler(
        filename = function() {
            paste0("WildLift_conservation_breeding_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(breeding_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


    ## >>> breeding1 tab / multi lever <<<=====================================

    ## dynamically render sliders
    output$breeding1_years <- renderUI({
        tagList(
            sliderInput("breeding1_yrs",
                "Number of years that adult females are added to the facility",
                min = 0, max = input$tmax, value = 0, step = 1) #value = 1
        )
    })
    output$breeding1_jyears <- renderUI({
        tagList(
            sliderInput("breeding1_jyrs",
                "Number of years to delay juvenile transfer",
                min = 0, max = input$tmax, value = 0, step = 1)
        )
    })

    output$breeding1_demogr_sliders_fac <- renderUI({
        tagList(
            sliderInput("breeding1_DemCsc", "Calf survival in facility",
                min = 0, max = 1,
                value = inits$breeding1$c.surv.capt, step = 0.001),
            sliderInput("breeding1_DemFsc", "Adult female survival in facility",
                min = 0, max = 1,
                value = inits$breeding1$f.surv.capt, step = 0.001),
            sliderInput("breeding1_DemFpc", "Fecundity in facility",
                min = 0, max = 1,
                value = inits$breeding1$f.preg.capt, step = 0.001)
        )
    })
    output$breeding1_demogr_sliders_out <- renderUI({
        tagList(
            sliderInput("breeding1_DemCsw", "Calf survival, recipient & status quo",
                min = 0, max = 1,
                value = inits$breeding1$c.surv.wild, step = 0.001),
            sliderInput("breeding1_DemFsw",
                        "Adult female survival, recipient & status quo",
                min = 0, max = 1,
                value = inits$breeding1$f.surv.wild, step = 0.001),
            sliderInput("breeding1_DemFpw", "Fecundity, recipient & status quo",
                min = 0, max = 1,
                value = inits$breeding1$f.preg.wild, step = 0.001)
        )
    })
    output$breeding1_demogr_sliders_mr <- renderUI({
        tagList(
            sliderInput("breeding1_DemFsw_MR",
                        "Adult female survival, recipient",
                  min = 0, max = 1,
                  value = inits$breeding1$f.surv.wild.mr, step = 0.001)
        )
    })
    output$breeding1_demogr_sliders_wr <- renderUI({
        tagList(
            sliderInput("breeding1_DemCsw_WR",
                        "Calf survival, recipient",
                  min = 0, max = 1,
                  value = inits$breeding1$c.surv.wild.wr, step = 0.001),
            sliderInput("breeding1_DemFsw_WR",
                        "Adult female survival, recipient",
                  min = 0, max = 1,
                  value = inits$breeding1$f.surv.wild.wr, step = 0.001)
        )
    })

    ## plain
    observeEvent(input$breeding1_DemCsw, {
        values$breeding1$c.surv.wild <- input$breeding1_DemCsw
    })
    observeEvent(input$breeding1_DemCsc, {
        values$breeding1$c.surv.capt <- input$breeding1_DemCsc
    })
    observeEvent(input$breeding1_DemFsw, {
        values$breeding1$f.surv.wild <- input$breeding1_DemFsw
    })
    observeEvent(input$breeding1_DemFsc, {
        values$breeding1$f.surv.capt <- input$breeding1_DemFsc
    })
    observeEvent(input$breeding1_DemFpw, {
        values$breeding1$f.preg.wild <- input$breeding1_DemFpw
    })
    observeEvent(input$breeding1_DemFpc, {
        values$breeding1$f.preg.capt <- input$breeding1_DemFpc
    })
    observeEvent(input$breeding1_CostSetup, {
        values$breeding1$pen.cost.setup <- input$breeding1_CostSetup
    })
    observeEvent(input$breeding1_CostProj, {
        values$breeding1$pen.cost.proj <- input$breeding1_CostProj
    })
    observeEvent(input$breeding1_CostMaint, {
        values$breeding1$pen.cost.maint <- input$breeding1_CostMaint
    })
    observeEvent(input$breeding1_CostCapt, {
        values$breeding1$pen.cost.capt <- input$breeding1_CostCapt
    })
    ## multi extras
    observeEvent(input$breeding1_DemFsw_MR, {
        values$breeding1$f.surv.wild.mr <- input$breeding1_DemFsw_MR
    })
    observeEvent(input$breeding1_DemCsw_WR, {
        values$breeding1$c.surv.wild.wr <- input$breeding1_DemCsw_WR
    })
    observeEvent(input$breeding1_DemFsw_WR, {
        values$breeding1$f.surv.wild.wr <- input$breeding1_DemFsw_WR
    })
    ## breeding reduction without penning
    breeding1_getF <- reactive({
        req(input$breeding1_DemFsw_MR)
        if (is.null(input$breeding1_breedearly))
            return(NULL)
        req(input$breeding1_yrs, input$breeding1_ininds,
            input$breeding1_jyrs)
        nn <- rep(input$breeding1_ininds, input$breeding1_yrs)
        op <- c(rep(0, input$breeding1_jyrs), input$breeding1_outprop)
        out <- wildlift_breeding(values$breeding1,
            tmax = input$tmax,
            pop.start = input$popstart,
            f.surv.trans = input$breeding1_ftrans,
            j.surv.trans = input$breeding1_jtrans,
            j.surv.red = input$breeding1_jsred,
            in.inds = nn,
            out.prop = op,
            breed.early = input$breeding1_breedearly)
        ## edit out$population: add MR
        s_mr <- out$settings
        s_mr$f.surv.wild <- input$breeding1_DemFsw_MR
        out_mr <- wildlift_breeding(s_mr,
            tmax = input$tmax,
            pop.start = input$popstart,
            f.surv.trans = input$breeding1_ftrans,
            j.surv.trans = input$breeding1_jtrans,
            j.surv.red = input$breeding1_jsred,
            in.inds = nn,
            out.prop = op,
            breed.early = input$breeding1_breedearly)
        out$population$Nwild_MR <- out_mr$population$Nwild
        out$population$Nrecip_MR <- out_mr$population$Nrecip
        out$mr <- list(
            cost_extra = 0,
            settings=s_mr,
            output=out_mr)
        ## edit out$population: add WR
        s_wr <- out$settings
        s_wr$c.surv.wild <- input$breeding1_DemCsw_WR
        s_wr$f.surv.wild <- input$breeding1_DemFsw_WR
        out_wr <- wildlift_breeding(s_wr,
            tmax = input$tmax,
            pop.start = input$popstart,
            f.surv.trans = input$breeding1_ftrans,
            j.surv.trans = input$breeding1_jtrans,
            j.surv.red = input$breeding1_jsred,
            in.inds = nn,
            out.prop = op,
            breed.early = input$breeding1_breedearly)
        out$population$Nwild_WR <- out_wr$population$Nwild
        out$population$Nrecip_WR <- out_wr$population$Nrecip
        out$wr <- list(
            cost_extra = input$breeding1_nremove * input$tmax *
                input$breeding1_costwolf / 1000,
            settings=s_wr,
            output=out_wr)

        out
    })
    ## plot
    output$breeding1_Plot <- renderPlotly({
        req(breeding1_getF())
        bb <- breeding1_getF()
        dF <- summary(bb)
        colnames(dF)[colnames(dF) == "Nrecip"] <- "Individuals"
        p <- plot_ly(dF, x = ~Years, y = ~Individuals,
            name = 'Recipient CB', type = 'scatter', mode = 'lines',
            text = hover(t(bb$Nrecip)),
            hoverinfo = 'text',
            color=I('red')) %>%
            add_trace(y = ~Nwild, name = 'Status quo', data = dF,
                    mode = 'lines', color=I('black'),
                    text = hover(t(bb$Nwild))) %>%
            layout(legend = list(x = 100, y = 0),
                   yaxis=list(title="Number of females")) %>%
            config(displayModeBar = 'hover', displaylogo = FALSE)
        if ("fac" %in% input$breeding1_plot_show)
            p <- p %>% add_trace(y = ~Ncapt, name = 'Inside facility', data = dF,
                    mode = 'lines', color=I('purple'),
                    text = hover(t(bb$Ncapt))) %>%
                add_trace(y = ~Nout, name = 'Juvenile females out', data = dF,
                    mode = 'lines', color=I('orange'),
                    text = hover(t(bb$Nout))) %>%
                add_trace(y = ~Nin, name = 'Adult females in', data = dF,
                    line=list(color='green'),
                    text = hover(t(bb$Nin)))
        if ("mr" %in% input$breeding1_plot_show)
            p <- p %>% add_trace(y = ~Nrecip_MR,
                    name = 'CB + MR', data = dF,
                    mode = 'lines', type='scatter',
                    text = hover(t(bb$mr$output$Nrecip)),
                    hoverinfo = 'text',
                    color=I('red'), line=list(dash='dash')) %>%
                add_trace(y = ~Nwild_MR, name = 'MR', data = dF,
                    mode = 'lines', type='scatter',
                    text = hover(t(bb$mr$output$Nwild)),
                    hoverinfo = 'text',
                    color=I('blue'), line=list(dash='dash'))
        if ("wr" %in% input$breeding1_plot_show)
            p <- p %>% add_trace(y = ~Nrecip_WR, name = 'CB + WR', data = dF,
                    mode = 'lines', type='scatter',
                    text = hover(t(bb$wr$output$Nrecip)),
                    hoverinfo = 'text',
                    color=I('red'), line=list(dash='dot')) %>%
                add_trace(y = ~Nwild_WR, name = 'WR', data = dF,
                    mode = 'lines', type='scatter',
                    text = hover(t(bb$wr$output$Nwild)),
                    hoverinfo = 'text',
                    color=I('blue'), line=list(dash='dot'))

        p
    })
    ## making nice table of the settings
    breeding1_getS <- reactive({
        req(breeding1_getF())
        x <- breeding1_getF()
        s <- x$settings
        s$call <- NULL
        tab <- cbind(c(tmax = x$tmax,
            pop.start = x$pop.start,
            out.prop=x$out.prop,
            f.surv.trans=x$f.surv.trans,
            j.surv.trans=x$j.surv.trans,
            j.surv.red=x$j.surv.red,
            f.surv.wild.mr=x$mr$f.surv.wild,
            f.surv.wild.wr=x$wr$f.surv.wild,
            c.surv.wild.wr=x$wr$c.surv.wild,
            unlist(s)))
        SNAM <- c(
            "tmax" = "T max",
            "pop.start" = "N start",
            "c.surv.wild" = "Calf survival, wild",
            "c.surv.wild.wr" = "Calf survival, wild with wolf reduction",
            "c.surv.capt" = "Calf survival in facility",
            "f.surv.wild" = "Adult female survival, wild",
            "f.surv.wild.wr" = "Adult female survival, wild with wolf reduction",
            "f.surv.wild.mr" = "Adult female survival, wild with moose reduction",
            "f.surv.capt" = "Adult female survival in facility",
            "f.preg.wild" = "Fecundity, wild",
            "f.preg.capt" = "Fecundity in facility",
            #"out.prop"="Proportion of calves transferred",
            "pen.cost.setup" = "Initial set up (x $1000)",
            "pen.cost.proj" = "Project manager (x $1000)",
            "pen.cost.maint" = "Maintenance (x $1000)",
            "pen.cost.capt" = "Capture/monitor (x $1000)",
            "pen.cost.pred" = "Removing predators (x $1000)",
            "f.surv.trans"="Adult female survival during capture/transport to facility",
            "j.surv.trans"="Juvenile female survival during capture/transport from facility to recipient subpopulation",
            "j.surv.red"="Relative reduction in survival of juvenile females transported to recipient subpopulation for 1 year after transport")
        df <- tab[names(SNAM),,drop=FALSE]
        rownames(df) <- SNAM
        colnames(df) <- "Breeding"
        #print(df)
        df
    })

    ## table
    output$breeding1_Table <- renderTable({
        req(breeding1_getF())
        zz <- breeding1_getF()
        #zz <- revrt(zz)

        ## one time cost
        cost1 <- zz$settings$pen.cost.setup
        ## yearly costs
        cost2 <- zz$settings$pen.cost.proj +
            zz$settings$pen.cost.maint +
            zz$settings$pen.cost.capt +
            zz$settings$pen.cost.pred
        cost <- (cost1 + zz$tmax * cost2) / 1000
        costCBWR <- cost + zz$wr$cost_extra
        costWR <- zz$wr$cost_extra
        #print(c(cost1/1000, cost2/1000, cost))

        Pick <- c(Ncapt="In facility", Nrecip="Recipient CB", Nwild="Status quo",
                  Nrecip_MR="CB + MR",
                  Nwild_MR="MR",
                  Nrecip_WR="CB + WR",
                  Nwild_WR="WR")
        dF <- summary(zz)[,names(Pick)]
        colnames(dF) <- Pick
        N0 <- dF[1,,drop=FALSE]
        Ntmax1 <- dF[nrow(dF)-1L,,drop=FALSE]
        Ntmax <- dF[nrow(dF),,drop=FALSE]
        Nnew <- Ntmax[1,"Recipient CB"] - Ntmax[1,"Status quo"]
        NnewCBMR <- Ntmax[1,"CB + MR"] - Ntmax[1,"Status quo"]
        NnewMR <- Ntmax[1,"MR"] - Ntmax[1,"Status quo"]
        NnewCBWR <- Ntmax[1,"CB + WR"] - Ntmax[1,"Status quo"]
        NnewWR <- Ntmax[1,"WR"] - Ntmax[1,"Status quo"]
        df <- rbind(
            '&lambda;'=round(Ntmax/Ntmax1, 3),
            'N (end)'=Ntmax,
            'N (new)'=c(NA, max(0,Nnew),NA,
                max(0,NnewCBMR), max(0,NnewMR),
                max(0,NnewCBWR), max(0,NnewWR)),
            "Total cost (x $million)"=c(NA, cost, NA,
                cost, 0,
                costCBWR, costWR),
            "Cost per new female (x $million)"=c(NA,
                ifelse(Nnew>0,cost/Nnew, 0), NA,
                ifelse(NnewCBMR>0,cost/NnewCBMR, 0),
                0,
                ifelse(NnewCBWR>0,costCBWR/NnewCBWR, 0),
                ifelse(NnewWR>0,costWR/NnewWR, 0)))
        if (!("mr" %in% input$breeding1_plot_show))
            df <- df[,!(colnames(df) %in% c("CB + MR", "MR"))]
        if (!("wr" %in% input$breeding1_plot_show))
            df <- df[,!(colnames(df) %in% c("CB + WR", "WR"))]
        print(df)
        df
    }, rownames=TRUE, colnames=TRUE,
    striped=TRUE, bordered=TRUE, na="n/a",
    sanitize.text.function = function(x) x)

    ## dowload
    breeding1_xlslist <- reactive({
        req(breeding1_getF())
        bb <- breeding1_getF()
        #bb <- revrt(bb)
        dF <- summary(bb)
        ss <- breeding1_getS()
        out <- list(
            Info=data.frame(WildLift=paste0(
                c("R package version: ", "Tab: ",
                  "Date of analysis: ", "Subpopulation: "),
                c(ver, "Conservation breeding, multiple levers",
                  format(Sys.time(), "%Y-%m-%d"), "AverageSubpop"))),
            Settings=as.data.frame(ss),
            TimeSeries=as.data.frame(dF),
            AgeClasses=stack_breeding(bb),
            AgeClasses_MR=stack_breeding(bb$mr$output),
            AgeClasses_WR=stack_breeding(bb$wr$output))
        out$Settings$Parameters <- rownames(ss)
        out$Settings <- out$Settings[,c(ncol(ss)+1, 1:ncol(ss))]
        out
    })
    output$breeding1_download <- downloadHandler(
        filename = function() {
            paste0("WildLift_conservation_multi_", format(Sys.time(), "%Y-%m-%d"), ".xlsx")
        },
        content = function(file) {
            write.xlsx(breeding1_xlslist(), file=file, overwrite=TRUE)
        },
        contentType="application/octet-stream"
    )


}

