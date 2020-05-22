
server <- function(input, output, session) {
#---Functions
# buildClimateMap<-function(x){
#   dag<-data.table(from = c('Temperature_changes',	'Temperature_changes',	'Temperature_changes',	'Precipitation_changes',	'Precipitation_changes',	'Precipitation_changes',	'Core_habitat',	'Core_habitat',	'Core_habitat',	'Core_habitat',	'Core_habitat',	'Matrix_habitat',	'Matrix_habitat',	'Over_winter_prey_survival',	'Health_risk',	'Health_risk',	'Plant_phenology',	'Accessible_lichen_forage',	'Growing_season_forage',	'Growing_season_forage',	'Early_seral_anthro',	'Current_practice_forestry',	'Land_conversion',	'Primary_prey_density',	'Primary_prey_density',	'Predator_density',	'Linear_feature_density',	'Energy_balance',	'Energy_balance',	'Predation_pressure',	'Predation_pressure',	'Juvenile_recruitment',	'Adult_female_survival', 'Winter_displacement'),
#                   to = c('Matrix_habitat',	'Over_winter_prey_survival',	'Core_habitat',	'Matrix_habitat',	'Over_winter_prey_survival',	'Core_habitat',	'Health_risk',	'Plant_phenology',	'Accessible_lichen_forage',	'Predation_pressure',	'Matrix_habitat',	'Over_winter_prey_survival',	'Growing_season_forage',	'Primary_prey_density',	'Juvenile_recruitment',	'Adult_female_survival',	'Energy_balance',	'Energy_balance',	'Energy_balance',	'Primary_prey_density',	'Growing_season_forage',	'Early_seral_anthro',	'Early_seral_anthro',	'Health_risk',	'Predator_density',	'Predation_pressure',	'Predation_pressure',	'Juvenile_recruitment',	'Adult_female_survival',	'Juvenile_recruitment',	'Adult_female_survival',	'Population_trend',	'Population_trend', 'Accessible_lichen_forage')
#   ) 
#   g<-graph_from_data_frame(dag, directed=TRUE)
#   
#   V(g)$color <- c("yellow", "yellow", "purple", "purple", "lightblue","red","purple","purple", "purple", "purple",
#                   "orange", "orange", "lightblue","lightblue", "orange","pink", "lightblue", "green", "green","orange", "green")
#   l <-layout_with_fr(g, niter =5, start.temp = 5.25)
#   rownames(l) <- V(g)$name
#   test<-data.frame(x=c(   3, 11, 2 , 10, 13, -1, 1, 2.5,  7,  13.5,  17, 17, 8.0, 11,  17, 4, 9, 4, 11, 7, 8),
#                    y=c(0.5, -1,4,  1.5,  5, 14,  11, 7.5,  6,   8.5,   9.5,  6.5, 9.5, 11, 14, 13,  13, 16, 16, 4, 19))
#   test<-as.matrix(test)
#   rownames(test) <- V(g)$name
#   return(list(g,test))
# }
# climateMap <- buildClimateMap()

  
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
  #print(getSpatialQuery(paste0("SELECT r_table_name FROM public.raster_columns WHERE r_table_schema = '", input$schema , "' ;")))
  getTableQuery(paste0("SELECT r_table_name FROM public.raster_columns WHERE r_table_schema = '", input$schema , "' ;"))$r_table_name
})

scenariosList<-reactive({
  req(input$schema)
  data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".scenarios")))
  })

statusData<-reactive({
  req(input$schema)
  data.table(getTableQuery(paste0(
    "select a.compartment, gs, (gs/thlb) as avg_m3_ha, aoi, total, thlb, early, mature, old, road, dist500, dist, tarea from (SELECT compartment, max(m_gs) as gs 
    FROM ",input$schema,".growingstock 
where timeperiod = 0 group by compartment) a
Left join (Select * from ",input$schema,".state ) b
ON b.compartment = a.compartment
left join (select sum(dist500) as dist500, sum(dist) as dist, sum(dist500/(dist500_per/100)) as tarea, compartment 
		   from ",input$schema,".disturbance where timeperiod = 0 and scenario = (select scenario from itcha_ilgachuz_plan.disturbance limit 1) group by compartment )c
ON c.compartment = a.compartment;")))
  
})

reportList<-reactive({
  req(input$schema)
  req(input$scenario)
  data.survival<-data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".survival where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') order by scenario, herd_bounds, timeperiod;")))
  data.survival<-data.survival[,lapply(.SD, weighted.mean, w =area), by =c("scenario",  "herd_bounds", "timeperiod"), .SDcols = c("prop_age", "prop_mature", "prop_old", "survival_rate")]
  
  data.disturbance<-data.table (getTableQuery(paste0("SELECT scenario,timeperiod,critical_hab,
    sum(dist500) as dist500, sum(dist) as dist, sum(dist/((dist_per+0.000001)/100)) as tarea FROM ", input$schema, ".disturbance where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') group by scenario, critical_hab, timeperiod order by scenario, critical_hab, timeperiod;")))
  
  data.disturbance<-data.disturbance[, dist_per:= dist/tarea][, dist500_per:= dist500/tarea]
  
  data.fire<- getTableQuery(paste0("SELECT * FROM fire where herd_bounds IN ('", paste(unique(data.survival$herd_bounds), sep =  "' '", collapse = "', '"), "');"))
  data.fire2<- getTableQuery(paste0("SELECT herd_name, habitat,  round(cast(mean_ha2 as numeric),1) as mean,  round(cast(mean_area_percent as numeric),1) as percent, 
 round(cast(max_ha2 as numeric),1) as max,  round(cast(min_ha2 as numeric),1) as min, round(cast(cummulative_area_ha2 as numeric),1) as cummulative, round(cast(cummulative_area_percent as numeric),1) as cummul_percent 
                                    FROM firesummary where herd_bounds IN ('", paste(unique(data.survival$herd_bounds), sep =  "' '", collapse = "', '"), "');"))
  
  

list(harvest = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".harvest where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "');"))),
       growingstock = data.table(getTableQuery(paste0("SELECT scenario, timeperiod, sum(m_gs) as growingstock FROM ", input$schema, ".growingstock where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') group by scenario, timeperiod;"))),
       rsf = data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".rsf where scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') order by scenario, rsf_model, timeperiod;"))),
       survival = data.survival,
       disturbance = data.disturbance,
       fire = data.fire,
       fire2=data.fire2)
})

radarList<-reactive({
  DT.h<- reportList()$harvest[, sum(volume)/sum(target), by = c("scenario", "timeperiod")][ V1 > 0.9, .N, by = c("scenario")][,N:=N/100]
  setnames(DT.h, "N", "Timber")
  DT.s <-dcast(reportList()$survival[survival_rate > 0.75 & timeperiod > 0, .N/100, by =c("scenario", "herd_bounds") ], scenario ~herd_bounds, value.var =  "V1")
  DT.all<-merge(DT.h, DT.s, by.x = "scenario", by.y = "scenario")
  DT.g<-data.table(getTableQuery(paste0("select foo1.scenario, gs_100/gs_0 as GrowingStock  from (
	(select sum(m_gs) as gs_0, scenario from ",input$schema, ".growingstock where timeperiod in (0)  and scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "')
group by scenario, timeperiod) foo1
JOIN (select sum(m_gs) as gs_100, scenario from ", input$schema, ".growingstock where timeperiod in (100) and scenario IN ('", paste(input$scenario, sep =  "' '", collapse = "', '"), "') 
group by scenario, timeperiod) foo2
ON (foo1.scenario = foo2.scenario) )")))
  merge(DT.all, DT.g, by.x = "scenario", by.y = "scenario")
})

observeEvent(input$getMapLayersButton, {
  withProgress(message = 'Loading layers', value = 0.1, {
    mapLayersStack <-getRasterQuery(c(input$schema, tolower(input$maplayers)))
    mapLayersStack[mapLayersStack[] == 0] <- NA
  })
  cb<-colorBin("Spectral", domain = 1:200,  na.color = "#00000000")
  leafletProxy("resultSetRaster", session) %>% 
    clearTiles() %>%
    clearImages() %>%
    clearControls()%>%
    addTiles() %>% 
    addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
    addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
    addProviderTiles("Esri.DeLorme", group ="DeLorme" ) %>%
    addRasterImage(mapLayersStack,  colors = cb, opacity = 0.8, project= TRUE, group="Selected") %>% 
    addLegend(pal = cb, values = 1:200) %>%
    addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"),overlayGroups ="Selected") %>%
    addScaleBar(position = "bottomleft") 
})

#---Observe
  observe({
    updateSelectInput(session, "tsa_selected",
                    choices = statusData()$compartment,
                    selected = statusData()$compartment)
  })

  observe({ #Scenarios based on the area of interest selected
    updateCheckboxGroupInput(session, "scenario",
                       #label = scenariosList()$description,
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

  
#---Outputs
  
 output$scenarioDescription<-renderTable({
   as.data.frame(scenariosList())
 })
 
 output$statusPlot<-renderPlotly({
   data<-statusData()[compartment %in% input$tsa_selected,]
   data<-data.table(reshape2::melt(data[,c("compartment", "early", "mature", "old")], id.vars = "compartment",
                                   measure.vars = c("early", "mature", "old")))
   data<-data[, sum(value), by = list(variable)]
   plot_ly(data=data, labels = ~variable, values = ~V1,
           marker = list(line = list(color = "black", width =1))) %>% add_pie(hole = 0.6)%>%
     layout(plot_bgcolor='#00000000',legend = list(orientation = 'v'),paper_bgcolor='#00000000',title = "Seral Stage", font = list(color = 'White'))
 })
 output$statusTHLB<-renderInfoBox({
    data<-statusData()[compartment %in% input$tsa_selected,]
    infoBox(title = NULL, subtitle = "THLB", 
            value = tags$p(paste0(round((sum(data$thlb)/sum(data$total))*100,0), '%'), style = "font-size: 160%;"),
      icon = icon("images"), color = "green"
   )
 })
 output$statusAvgVol<-renderInfoBox({
   data<-statusData()[compartment %in% input$tsa_selected,]
   infoBox(title = NULL,subtitle = "m3/ha", 
           value = tags$p(paste0(round((sum(data$gs)/sum(data$thlb)),0)), style = "font-size: 160%;"),
           icon = icon("seedling"), color = "green"
   )
 })
  output$statusRoad<-renderInfoBox({
    data<-statusData()[compartment %in% input$tsa_selected,]
    infoBox(title = NULL,subtitle = "Road", 
      value = tags$p(paste0(round((sum(data$road)/sum(data$total))*100,0), '%'),  style = "font-size: 160%;"),
      icon = icon("road"), color = "green"
    )
  })
  
  output$statusDist<-renderValueBox({
    data<-statusData()[compartment %in% input$tsa_selected,]
    valueBox(
      subtitle = "Disturbed",
      tags$p(paste0(round((sum(data$dist)/sum(data$tarea))*100, 0), '%'), style = "font-size: 110%;"),
      icon = icon("paw"), color = "purple"
    )
  })
  
  output$statusCritHab<-renderValueBox({
    data<-statusData()[compartment %in% input$tsa_selected,]
    valueBox(
      subtitle = "Critical habitat",
      tags$p(paste0(round((sum(data$tarea)/sum(data$total))*100, 0), '%'), style = "font-size: 110%;"),
      icon = icon("exclamation-triangle"), color = "purple"
    )
  })
  
  output$statusDist500<-renderValueBox({
    data<-statusData()[compartment %in% input$tsa_selected,]
    valueBox(
      subtitle = "Disturbed 500m",
      tags$p(paste0(round((sum(data$dist500)/sum(data$tarea))*100, 0), '%'), style = "font-size: 110%;"),
      icon = icon("paw"), color = "purple"
    )
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
        scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 10))+
        scale_alpha_discrete(range=c(0.4,0.8))+
        scale_fill_grey(start=0.8, end=0.2) +
        theme_bw()
      ggplotly(p)
    })
  }) 
  
  output$harvestAgePlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data<-reportList()$harvest
      data<-data[, lapply(.SD, FUN=weighted.mean, x=volume), by=c("timeperiod", "scenario"), .SDcols='age']
      print(data)
      #data$scenario <- reorder(data$scenario, data$V1, function(x) -max(x) )
      data[,timeperiod:= as.integer(timeperiod)]
      p<-ggplot (data, aes (x=timeperiod, y=age, fill = scenario)) +  
        geom_area(position = "identity", aes(alpha = scenario)) +
        xlab ("Future year") +
        ylab ("Average Harvest Age (yrs)") +
        scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 10))+
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
        scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 10))+
        scale_alpha_discrete(range=c(0.4,0.8))+
        scale_fill_grey(start=0.8, end=0.2) +
        theme_bw()
      ggplotly(p)
  })
  
  output$managedAreaPlot <- renderPlotly ({
    data<-reportList()$harvest[,sum(transition_area), by=c("scenario", "timeperiod")]
    data$scenario <- reorder(data$scenario, data$V1, function(x) -max(x) )
    data[,timeperiod:= as.integer(timeperiod)]
    p<-ggplot (data, aes (x=timeperiod, y=V1, fill = scenario)) +  
      geom_area(position = "identity", aes(alpha = scenario)) +
      xlab ("Future year") +
      ylab ("Managed Area Harvested (ha)") +
      scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 10))+
      scale_alpha_discrete(range=c(0.4,0.8))+
      scale_fill_grey(start=0.8, end=0.2) +
      theme_bw()
    ggplotly(p)
  }) 
  
  output$managedVolumePlot <- renderPlotly ({
    data<-reportList()$harvest[,sum(transition_volume), by=c("scenario", "timeperiod")]
    data$scenario <- reorder(data$scenario, data$V1, function(x) -max(x) )
    data[,timeperiod:= as.integer(timeperiod)]
    p<-ggplot (data, aes (x=timeperiod, y=V1, fill = scenario)) +  
      geom_area(position = "identity", aes(alpha = scenario)) +
      xlab ("Future year") +
      ylab ("Managed Volume Harvested (m3)") +
      scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 10))+
      scale_alpha_discrete(range=c(0.4,0.8))+
      scale_fill_grey(start=0.8, end=0.2) +
      theme_bw()
    ggplotly(p)
  }) 
  
  output$availableTHLBPlot <- renderPlotly ({
    data<-reportList()$harvest[,sum(avail_thlb), by=c("scenario", "timeperiod")]
    data$scenario <- reorder(data$scenario, data$V1, function(x) -max(x) )
    data[,timeperiod:= as.integer(timeperiod)]
    p<-ggplot (data, aes (x=timeperiod, y=V1, fill = scenario)) +  
      geom_area(position = "identity", aes(alpha = scenario)) +
      xlab ("Future year") +
      ylab ("Available THLB (ha)") +
      scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 10))+
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
      scale_x_continuous(breaks = seq(0, max(data$timeperiod), by = 10))+
      scale_alpha_discrete(range=c(0.4,0.8))+
      scale_fill_grey(start=0.8, end=0.2) +
      theme_bw()
    ggplotly(p)
  }) 
  
  output$survivalPlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data<-reportList()$survival
      data[, survival_rate_change := survival_rate - first(survival_rate), by = .(scenario, herd_bounds)]  # replace first() with shift() to get difference with previous year value instead of first year value
      
     p<-ggplot(data, aes (x=timeperiod, y=survival_rate_change, color = scenario)) +
        facet_wrap(.~herd_bounds, ncol = 4)+
        geom_line() +
        geom_hline(yintercept=0, linetype="dashed", color = "black")+
        xlab ("Future year") +
        ylab ("Change in Annual Adult Female Survival Rate)") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p, height = 900) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 50, t = 40, pad = 0))
    })
  }) 
  
  output$propDisturbPlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data1<-reportList()$disturbance
      p<-ggplot(data1, aes (x=timeperiod, y=dist_per, color = scenario, linetype = scenario)) +
        facet_wrap(.~critical_hab, ncol = 4)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Percent Disturbed") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p, height = 900) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 40, t = 40, pad = 0)
                #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
        )# change seasonal values
    })
  }) 
  
  output$propDisturbBuffPlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data1<-reportList()$disturbance
      p<-ggplot(data1, aes (x = timeperiod, y = dist500_per, color = scenario, linetype = scenario)) +
        facet_wrap(.~critical_hab, ncol = 4)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Percent Disturbed") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        # scale_alpha_discrete(range=c(0.4,0.8))+
        # scale_color_grey(start=0.8, end=0.2) +
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p, height = 900) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 40, t = 40, pad = 0)
                #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
        )# change seasonal values
    })
  }) 
  
  output$propEarlyPlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data1<-reportList()$survival
      p<-ggplot(data1, aes (x=timeperiod, y=prop_age, color = scenario, type = scenario)) +
        facet_wrap(.~herd_bounds, ncol = 4)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Proportion Age 0 to 40 years") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        # scale_alpha_discrete(range=c(0.4,0.8))+
        # scale_color_grey(start=0.8, end=0.2) +
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p, height = 900) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 40, t = 40, pad = 0)
                #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
        )# change seasonal values
    })
  }) 
  
  output$propMaturePlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data1<-reportList()$survival
      p<-ggplot(data1, aes (x=timeperiod, y=prop_mature, color = scenario, type = scenario)) +
        facet_wrap(.~herd_bounds, ncol = 4)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Proportion Age 80 to 120 years") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        # scale_alpha_discrete(range=c(0.4,0.8))+
        # scale_color_grey(start=0.8, end=0.2) +
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p, height = 900) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 40, t = 40, pad = 0)
                #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
        )# change seasonal values
    })
  }) 
  
  output$propOldPlot <- renderPlotly ({
    withProgress(message = 'Making Plots', value = 0.1, {
      data1<-reportList()$survival
       p<-ggplot(data1, aes (x=timeperiod, y=prop_old, color = scenario, type = scenario)) +
        facet_wrap(.~herd_bounds, ncol = 4)+
        geom_line() +
        xlab ("Future year") +
        ylab ("Proportion > 120 years") +
        scale_x_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 10))+
        # scale_alpha_discrete(range=c(0.4,0.8))+
        # scale_color_grey(start=0.8, end=0.2) +
        theme_bw()+
        theme (legend.title = element_blank())
      ggplotly(p, height = 900) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 40, t = 40, pad = 0)
                #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
        )# change seasonal values
    })
  }) 
  
  output$rsfPlot <- renderPlotly ({
    data<-reportList()$rsf
    # data$scenario <- reorder(data$scenario, data$sum_rsf_hat, function(x) -max(x) )
    data[ , rsf_perc_change := ((first(sum_rsf_hat) - sum_rsf_hat)/first(sum_rsf_hat) * 100), by = .(scenario, rsf_model)]  # replace first() with shift() to get difference with previous year value instead of first year value
    p<-ggplot(data, aes (x=timeperiod, y=rsf_perc_change, fill = scenario)) +
      facet_wrap(rsf_model~., ncol = 4)+
      geom_bar(stat="identity",position = "dodge") +
      geom_hline(yintercept=0, linetype="dashed", color = "black")+
      xlab ("Future year") +
      ylab ("RSF Value Percent Change") +
      scale_x_continuous(limits = c(0, 55), breaks = seq(0, 50, by = 10))+
      theme_bw()+
      theme (legend.title = element_blank())
    ggplotly(p, height = 900)  %>% 
      layout (legend = list (orientation = "h", y = -0.1),
              margin = list (l = 50, r = 40, b = 40, t = 10, pad = 0)
              #yaxis = list (title=paste0(c(rep("&nbsp;", 10),"RSF Value Percent Change", rep("&nbsp;", 200), rep("&nbsp;", 3))
              )# change seasonal values
  })
  
  output$fireByYearPlot <- renderPlotly ({
    withProgress(message = 'Making Plot', value = 0.1,{
    data<-reportList()$fire
    # data$scenario <- reorder(data$scenario, data$sum_rsf_hat, function(x) -max(x) )
    #print(data)
    
    p<-ggplot(data, aes (x=year, y=proportion.burn)) +
      facet_wrap(.~herd_bounds, ncol = 4)+
      geom_bar(stat="identity",width=1) +
      #geom_line(col="grey")+
      #geom_bar(stat="identity", width=0.7) +
      xlab ("Year") +
      ylab ("Proportion of area burned") +
      scale_x_continuous(limits = c(1925, 2025), breaks = seq(1925, 2025, by = 75))+
      scale_y_continuous(limits = c(0, 45), breaks = seq(0, 45, by = 20))+
      theme_bw()+
      theme (legend.title = element_blank())
    ggplotly(p, height = 900) %>% 
      layout (legend = list (orientation = "h", y = -0.1),
              margin = list (l = 50, r = 40, b = 50, t = 40, pad = 0))
    })
  })
  
  output$firecummulativePlot <- renderPlotly ({
    withProgress(message = 'Making Plot', value = 0.1,{
      data<-reportList()$fire
      
      
      ##Calculating cummulative area burned over a 40 year moving window for each herd across each habitat type 
      Years<-1919:2018
      window_size<-40
      
      Fire_cummulative <- data.frame (matrix (ncol = 3, nrow = 0))
      colnames (Fire_cummulative) <- c ("herd_bounds","cummulative.area.burned","year")
      
      for (i in 1:(length(Years)-window_size)) {
        fire.summary<-data %>% filter(year<=(Years[i]+window_size)) %>% 
          group_by (herd_bounds) %>% 
          summarize(cummulative.area.burned=sum(proportion.burn))
        fire.summary$year<-Years[i]+window_size
        
        Fire_cummulative<-rbind(Fire_cummulative,as.data.frame(fire.summary))
      }
      #print(Fire_cummulative)
      
      p<-ggplot(Fire_cummulative, aes (x=year, y=cummulative.area.burned)) +
        facet_wrap(.~herd_bounds, ncol = 4)+
        #geom_line (col="grey") +
        #geom_point()+
        geom_bar(stat="identity", width=1) +
        xlab ("Year") +
        ylab ("Cummulative proportion of area burned < 40 years") +
        scale_x_continuous(limits = c(1960, 2020), breaks = seq(1960, 2020, by = 30)) +
        scale_y_continuous(limits =c(0,70),breaks=seq(0,70, by=20)) +
        theme_bw()+
        theme (legend.title = element_blank())

      ggplotly(p, height = 900) %>% 
        layout (legend = list (orientation = "h", y = -0.1),
                margin = list (l = 50, r = 40, b = 50, t = 40, pad = 0))
    })
  })
 
  output$fireTable <-renderDataTable(
      reportList()$fire2, extensions = 'Buttons', 
      options = list(dom = 'Bfrtip',
                     buttons = c('copy', 'csv', 'excel', 'pdf', 'print'))
      )
      
  output$radar<- renderPlotly ({
    
  radarLength<<-1:nrow(radarList()) 
  radarNames<-paste(c(names(radarList())[2:length(radarList())],names(radarList())[2]), collapse= "', '")
  radarData<-radarList()[, data:=paste(.SD, collapse = ',')  , .SDcols =c( names(radarList())[2:length(radarList())],names(radarList())[2]), by = scenario]
  
  eval(parse(text=paste0("plot_ly(
  type = 'scatterpolar',
  mode = 'lines+markers',
  fill = 'toself'
  ) %>%",paste(sapply(radarLength, function(x){
      paste0("add_trace(
      r = c(",radarData$data[x[]], "),
      theta = c('", radarNames,"'),
      name = '",radarList()$scenario[x[]], "'
    ) %>%")
    }),collapse = ''),"
  layout(
    polar = list(
      radialaxis = list(
        visible = T,
        range = c(0,1.2)
      )
    )
  ) "  )))
    
  })
}



