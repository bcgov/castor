server <- function(input, output, session) {

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
  
}

