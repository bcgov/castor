
server <- function(input, output, session) {
#---Functions
buildClimateMap<-function(x){
  dag<-data.table(from = c('Temperature_changes',	'Temperature_changes',	'Temperature_changes',	'Precipitation_changes',	'Precipitation_changes',	'Precipitation_changes',	'Core_habitat',	'Core_habitat',	'Core_habitat',	'Core_habitat',	'Core_habitat',	'Matrix_habitat',	'Matrix_habitat',	'Over_winter_prey_survival',	'Health_risk',	'Health_risk',	'Plant_phenology',	'Accessible_lichen_forage',	'Growing_season_forage',	'Growing_season_forage',	'Early_seral_anthro',	'Current_practice_forestry',	'Land_conversion',	'Primary_prey_density',	'Primary_prey_density',	'Predator_density',	'Linear_feature_density',	'Energy_balance',	'Energy_balance',	'Predation_pressure',	'Predation_pressure',	'Juvenile_recruitment',	'Adult_female_survival', 'Winter_displacement'),
                  to = c('Matrix_habitat',	'Over_winter_prey_survival',	'Core_habitat',	'Matrix_habitat',	'Over_winter_prey_survival',	'Core_habitat',	'Health_risk',	'Plant_phenology',	'Accessible_lichen_forage',	'Predation_pressure',	'Matrix_habitat',	'Over_winter_prey_survival',	'Growing_season_forage',	'Primary_prey_density',	'Juvenile_recruitment',	'Adult_female_survival',	'Energy_balance',	'Energy_balance',	'Energy_balance',	'Primary_prey_density',	'Growing_season_forage',	'Early_seral_anthro',	'Early_seral_anthro',	'Health_risk',	'Predator_density',	'Predation_pressure',	'Predation_pressure',	'Juvenile_recruitment',	'Adult_female_survival',	'Juvenile_recruitment',	'Adult_female_survival',	'Population_trend',	'Population_trend', 'Accessible_lichen_forage')
  ) 
  g<-graph_from_data_frame(dag, directed=TRUE)
  
  V(g)$color <- c("yellow", "yellow", "purple", "purple", "lightblue","red","purple","purple", "purple", "purple",
                  "orange", "orange", "lightblue","lightblue", "orange","pink", "lightblue", "green", "green","orange", "green")
  l <-layout_with_fr(g, niter =5, start.temp = 5.25)
  rownames(l) <- V(g)$name
  test<-data.frame(x=c(   3, 11, 2 , 10, 13, -1, 1, 2.5,  7,  13.5,  17, 17, 8.0, 11,  17, 4, 9, 4, 11, 7, 8),
                   y=c(0.5, -1,4,  1.5,  5, 14,  11, 7.5,  6,   8.5,   9.5,  6.5, 9.5, 11, 14, 13,  13, 16, 16, 4, 19))
  test<-as.matrix(test)
  rownames(test) <- V(g)$name
  return(list(g,test))
}
climateMap <- buildClimateMap()

#---Reactive 
queryColumnNames <- reactive({
    data.table(getTableQuery(paste0("SELECT column_name FROM information_schema.columns
          WHERE table_schema = '", input$schema , "' ", "
          AND table_name   = '",input$queryTable,"'")))
  })

availableMapLayers <- reactive({
  req(input$schema)
  req(input$scenario)
  #print(paste0("SELECT r_table_name FROM public.raster_columns WHERE r_table_schema = '", input$schema , "' ;"))
  #getSpatialQuery(paste0("SELECT r_table_name FROM public.raster_columns WHERE r_table_schema = '", input$schema , "' ;"))
  list_layers<-list()
  i<-1
  k<-1
  while(i < 2*length(input$scenario)){
    list_layers[[i]]<-paste0(input$scenario[[k]], "_quesnel_tsa_roads")
    i<-i+1
    list_layers[[i]]<-paste0(input$scenario[[k]], "_quesnel_tsa_cutblocks")
    i<-i+1
    list_layers[[i]]<-paste0(input$scenario[[k]], "_quesnel_tsa_constraint")
    k<- k +1
    i<-i+1
  }
  list_layers
})

scenariosList<-reactive({
  req(input$schema)
  data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".scenarios")))
})

reportList<-reactive({
  req(input$schema)
  req(input$scenario)
  list(harvest = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".harvest where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "');"))),
       growingstock = data.table(getTableQuery(paste0("SELECT scenario, timeperiod, sum(gs) as growingstock FROM ", input$schema, ".growingstock where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') group by scenario, timeperiod;"))),
       rsf = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".rsf where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') order by scenario, rsf_model, timeperiod;"))),
       survival = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".survival where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') order by scenario, herd_bounds, timeperiod;")))
    )
})

observeEvent(input$getMapLayersButton, {
  withProgress(message = 'Loading layers', value = 0.1, {
    mapLayersStack <-getRasterQuery(c(input$schema, tolower(input$maplayers)))
  })

  #colores <- c('red', 'green', 'blue', 'chocolate', 'deeppink', 'grey')
  #at <- seq(0, 20, 1)
  #cb <- colorBin(palette = colores, bins = at, domain = at)
  cb<-colorNumeric("Spectral", domain = 0:100, na.color = "#00000000")
  
  leafletProxy("resultSetRaster") %>% 
    clearImages() %>% 
    clearTiles() %>%
    addTiles()  %>%
    addRasterImage(mapLayersStack,  colors = , opacity = 0.8, project= TRUE) %>% 
    addLegend(pal = cb, values = 0:100)
})

#---Observe
  observe({ #Scenarios based on the area of interest selected
    updateCheckboxGroupInput(session, "scenario",
                       label = scenariosList()$description,
                       choices = scenariosList()$scenario,
                       selected = character(0)
    )
  })
  
  observe({
    updateSelectInput(session, "queryColumns",
                             choices = queryColumnNames()$column_name,
                             selected = character(0))
    updateSelectInput(session, "queryRows",
                      choices = queryColumnNames()$column_name,
                      selected = character(0))
  })
  
  observe({
    #print(availableMapLayers())
    updateSelectInput(session, "maplayers",
                      choices = availableMapLayers(),
                      selected = character(0))
  })

  observe({ 
    leafletProxy("resultSetRaster") %>% 
      clearImages() %>% 
      addTiles()
  }) 
  
#---Outputs
 output$scenarioDescription<-renderTable({
   req(input$scenario)
   as.data.frame(scenariosList())
 })
  
  output$resultSetTable<-renderDataTable({
    #print(paste0("SELECT ", paste(c(input$queryRows,input$queryColumns), sep="' '", collapse=", "), " FROM ", input$schema, ".", input$queryTable, " WHERE scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') GROUP BY ", input$queryColumns))
    data.table(getTableQuery(paste0("SELECT scenario, ", paste(c(paste0(input$queryValue, "(", input$queryRows, ")"),input$queryColumns), sep="' '", collapse=", "), " FROM ", 
                                    input$schema, ".", input$queryTable, " WHERE scenario IN ('",
                                    paste(input$scenario, sep =  "' '", collapse = "', '"), "') GROUP BY scenario, ", input$queryColumns, " ORDER BY ", input$queryColumns)))
  })
  output$resultSetRaster <- renderLeaflet({
    leaflet(options = leafletOptions(doubleClickZoom= TRUE))%>%
      setView(-124.87, 54.29, zoom = 5) %>%
      addTiles() %>% 
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
      addProviderTiles("Esri.DeLorme", group ="DeLorme" ) %>%
      addScaleBar(position = "bottomright") %>%
      addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"))

  })
  
  output$climatemap <-renderPlot({
    plot.igraph(climateMap[[1]], layout=climateMap[[2]])
    legend('topleft', legend=c("Climate", "Anthropogenic", "Landscape Condition", "Predator-prey", "Energetics", "Health", "Population"),
           col =c("yellow", "orange", "purple", "lightblue", "pink", "red", "green"), pch =19, bty = 'n', cex = 1.7)
  })
  
  output$harvestAreaPlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data<-reportList()$harvest[,sum(area), by=c("scenario", "timeperiod")]
      data$scenario <- reorder(data$scenario, data$V1, function(x) -max(x) )
      data[,timeperiod:= as.integer(timeperiod)]
      p<-ggplot (data, aes (x=timeperiod, y=V1, fill = scenario)) +  
        geom_area(position = "identity", aes(alpha = scenario)) +
        xlab ("Future year") +
        ylab ("Area Harvested (ha)") +
        scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 2))+
        scale_alpha_discrete(range=c(0.4,0.8))+
        scale_fill_grey(start=0.8, end=0.2) +
        theme_bw()
      ggplotly(p)
    })
  }) 
  
  output$harvestVolumePlot <- renderPlotly ({
      data<-reportList()$harvest[,sum(volume), by=c("scenario", "timeperiod")]
      data$scenario <- reorder(data$scenario, data$V1, function(x) -max(x) )
      data[,timeperiod:= as.integer(timeperiod)]
      p<-ggplot (data, aes (x=timeperiod, y=V1, fill = scenario)) +  
        geom_area(position = "identity", aes(alpha = scenario)) +
        xlab ("Future year") +
        ylab ("Volume Harvested (m3)") +
        scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 2))+
        scale_alpha_discrete(range=c(0.4,0.8))+
        scale_fill_grey(start=0.8, end=0.2) +
        theme_bw()
      ggplotly(p)
  })
  
  output$growingStockPlot <- renderPlotly ({
    data<-reportList()$growingstock
    data$scenario <- reorder(data$scenario, data$growingstock, function(x) -max(x) )
    p<-ggplot(data, aes (x=timeperiod, y=growingstock, fill = scenario)) +  
      geom_area(position = "identity", aes(alpha = scenario)) +
      xlab ("Future year") +
      ylab ("Growing Stock (m3)") +
      scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 2))+
      scale_alpha_discrete(range=c(0.4,0.8))+
      scale_fill_grey(start=0.8, end=0.2) +
      theme_bw()
    ggplotly(p)
  }) 
  
  output$survivalPlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data<-reportList()$survival
      # data [order(data$scenario,  data$herd_bounds, data$timeperiod)]
      # data.year0 <- data[data$timeperiod == 0, c ("scenario", "herd_bounds", "survival_rate")]
      # setnames(data.year0, old = "survival_rate", new = "survival_rate_0")
      # data <- merge (data, data.year0, by = c("scenario", "herd_bounds"))
      data[, survival_rate_change := survival_rate - first(survival_rate), by = .(scenario, herd_bounds)]  # replace first() with shift() to get difference with previous year value instead of first year value
      data [scenario %in% c ('bau', 'basu'), scenario := 'Business as Usual']
      data [scenario %in% c ('UpprBound_ditchlines'), scenario := 'Canada Recovery Plan (Upper Ditch Line)']
      data [scenario %in% c ('proposed_uwr'), scenario := 'Tyler Scenario']
      #data$scenario <- reorder(data$scenario, data$survival_rate, function(x) -max(x) )
      p<-ggplot(data, aes (x=timeperiod, y=survival_rate_change, color = scenario)) +
        facet_grid(.~herd_bounds)+
        geom_line() +
        geom_hline(yintercept=0, linetype="dashed", color = "black")+
        xlab ("Future year") +
        ylab ("Change in Annual Adult Female Survival Rate)") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        #scale_alpha(range=c(0.4,0.8))+
        #scale_color_grey(start=0.8, end=0.2) +
        # scale_color_manual (name = "Scenario", #not working... tryign to get the legend names subsituted...
        #                     labels = "Canada (Upper Ditchline)")+ # "Business as Usual (Lower Ditchline)", "Tyler"
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 50, t = 40, pad = 0)
                #yaxis = list (title=paste0(c(rep("&nbsp;", 50),"RSF Value Percent Change", rep("&nbsp;", 2000), rep("\n&nbsp;", 13))
                )# change seasonal values
    })
  }) 
  
  output$propAgePlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data1<-reportList()$survival
      # data1$scenario <- reorder(data1$scenario, data1$prop_age, function(x) -min(x))
      data1 [scenario %in% c ('bau', 'basu'), scenario := 'Business as Usual']
      data1 [scenario %in% c ('UpprBound_ditchlines'), scenario := 'Canada Recovery Plan (Upper Ditch Line)']
      data1 [scenario %in% c ('proposed_uwr'), scenario := 'Tyler Scenario']
      p<-ggplot(data1, aes (x=timeperiod, y=prop_age, color = scenario, type = scenario)) +
        facet_grid(.~herd_bounds)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Proportion Age < 40 years") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        # scale_alpha_discrete(range=c(0.4,0.8))+
        # scale_color_grey(start=0.8, end=0.2) +
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 40, t = 40, pad = 0)
                #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
                )# change seasonal values
    })
  }) 
  
  output$rsfPlot <- renderPlotly ({
    data<-reportList()$rsf
    # data$scenario <- reorder(data$scenario, data$sum_rsf_hat, function(x) -max(x) )
    data [scenario %in% c ('bau', 'basu'), scenario := 'Business as Usual']
    data [scenario %in% c ('UpprBound_ditchlines'), scenario := 'Canada Recovery Plan (Upper Ditch Line)']
    data [scenario %in% c ('proposed_uwr'), scenario := 'Tyler Scenario']
    data [rsf_model %in% c ('caribou_DU7_EW'), rsf_model := 'Early Winter (DU7)']
    data [rsf_model %in% c ('caribou_DU7_LW'), rsf_model := 'Late Winter (DU7)']
    data [rsf_model %in% c ('caribou_DU7_S'), rsf_model := 'Summer (DU7)']
    # data [order(data$scenario, data$rsf_model, data$timeperiod)]
    # data.year0 <- data[data$timeperiod == 0, c ("scenario", "sum_rsf_hat")]
    # setnames(data.year0, old = "sum_rsf_hat", new = "sum_rsf_hate_0")
    # data <- merge (data, data.year0, by = "scenario")
    data[ , rsf_perc_change := ((first(sum_rsf_hat) - sum_rsf_hat)/first(sum_rsf_hat) * 100), by = .(scenario, rsf_model)]  # replace first() with shift() to get difference with previous year value instead of first year value
    p<-ggplot(data, aes (x=timeperiod, y=rsf_perc_change, fill = scenario)) +
      facet_grid(rsf_model~.)+
      geom_bar(stat="identity",position = "dodge") +
      geom_hline(yintercept=0, linetype="dashed", color = "black")+
      xlab ("Future year") +
      ylab ("RSF Value Percent Change") +
      scale_x_continuous(limits = c(0, 55), breaks = seq(0, 50, by = 10))+
      # scale_alpha_discrete(range=c(0.4,0.8))+
      # scale_fill_grey(start=0.8, end=0.2)+
      theme_bw()+
      theme (legend.title = element_blank())
    ggplotly(p)  %>% 
      layout (legend = list (orientation = "h", y = -0.1),
              margin = list (l = 50, r = 40, b = 40, t = 10, pad = 0)
              #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
              )# change seasonal values
  })  
}

