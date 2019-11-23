
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
    list_layers[[i]]<-paste0(input$scenario[[k]], "_roads")
    i<-i+1
    list_layers[[i]]<-paste0(input$scenario[[k]], "_cutblocks")
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
       growingstock = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".growingstock where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "');"))),
       rsf = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".rsf where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "');"))),
       survival = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".survival where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "');")))
    )
})

observeEvent(input$getMapLayersButton, {
  print(length(input$maplayers))
  
  withProgress(message = 'Loading layers', value = 0.1, {
    mapLayersStack <-getRasterQuery(c("chilcotin", tolower(input$maplayers)))
  })

  colores <- c('red', 'green', 'blue', 'chocolate', 'deeppink', 'grey')
  at <- seq(0, 20, 1)
  cb <- colorBin(palette = colores, bins = at, domain = at)
  
  leafletProxy("resultSetRaster") %>% 
    clearImages() %>% 
    clearTiles() %>%
    addTiles()  %>%
    addRasterImage(mapLayersStack,  colors = cb, opacity = 0.8) %>% 
    addLegend(pal = cb, values = at)
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
      data[ , survival_rate_change := survival_rate - first(survival_rate), by = .(scenario, herd_bounds)]  # replace first() with shift() to get difference with previous year value instead of first year value
      #data$scenario <- reorder(data$scenario, data$survival_rate, function(x) -max(x) )
      p<-ggplot(data, aes (x=timeperiod, y=survival_rate_change, color = scenario)) +
        facet_grid(.~herd_bounds)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Change in Annual Adult Female Survival Rate)") +
        scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 2))+
        #scale_alpha(range=c(0.4,0.8))+
        #scale_color_grey(start=0.8, end=0.2) +
        # scale_color_manual (name = "Scenario", #not working... tryign to get the legend names subsituted...
        #                     labels = "Canada (Upper Ditchline)")+ # "Business as Usual (Lower Ditchline)", "Tyler"
        theme_bw()
      ggplotly(p)
    })
  }) 
  
  output$propAgePlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data1<-reportList()$survival
      #data1$scenario <- reorder(data1$scenario, data1$prop_age, function(x) -min(x) )
      p<-ggplot(data1, aes (x=timeperiod, y=prop_age, color = scenario, type = scenario)) +
        facet_grid(.~herd_bounds)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Proportion Age < 40 years") +
        scale_x_continuous(breaks = seq(0, max(data1$timeperiod), by = 2))+
        scale_alpha_discrete(range=c(0.4,0.8))+
        scale_color_grey(start=0.8, end=0.2) +
        theme_bw()
      ggplotly(p)
    })
  }) 
  
  output$rsfPlot <- renderPlotly ({
    data<-reportList()$rsf
    data$scenario <- reorder(data$scenario, data$sum_rsf_hat, function(x) -max(x) )
    data[ , rsf_perc_change := ((sum_rsf_hat - first(sum_rsf_hat))/sum_rsf_hat * 100), by = .(scenario, rsf_model)]  # replace first() with shift() to get difference with previous year value instead of first year value
    p<-ggplot(data, aes (x=as.factor(timeperiod), y=rsf_perc_change, fill = scenario)) +
      facet_grid(rsf_model~.)+
      geom_bar(stat="identity",position = "dodge") +
      xlab ("Future year") +
      ylab ("RSF Value Percent Change") +
      #scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 2))+
      scale_alpha_discrete(range=c(0.4,0.8))+
      scale_fill_grey(start=0.8, end=0.2) +
      theme_bw()
    ggplotly(p) # change seasonal values
  })  
}

