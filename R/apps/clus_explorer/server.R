
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

scenariosList<-reactive({
    data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".scenarios")))
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
    leafletProxy("raster_map") %>% 
      clearImages() #%>% 
      #addTiles() %>%
      #addRasterImage(r_NDVI_temp(),  opacity = 0.5)# %>%
    #addLegend(pal = pal, values = values(r),
    #          title = "Surface temp")
  }) 
  
#---Outputs
  output$resultSetTable<-renderDataTable(
    data.table(getTableQuery(paste0("SELECT ", paste(input$queryColumn, sep="' '", collapse=", "), " FROM ", input$schema, ".", input$queryTable)))
    )

  output$resultSetRaster <- renderLeaflet({
    leaflet() %>%
    addTiles() #%>%
    #setView(lat = (bbox(rec)[[4]]+bbox(rec)[[2]])/2, lng = (bbox(rec)[[1]]+bbox(rec)[[3]])/2, zoom = 12)
  })
  
  output$climatemap <-renderPlot({
    plot.igraph(climateMap[[1]], layout=climateMap[[2]])
    legend('topleft', legend=c("Climate", "Anthropogenic", "Landscape Condition", "Predator-prey", "Energetics", "Health", "Population"),
           col =c("yellow", "orange", "purple", "lightblue", "pink", "red", "green"), pch =19, bty = 'n', cex = 1.7)
  })
  
}

