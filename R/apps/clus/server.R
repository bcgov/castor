server <- function(input, output, session) {
#---Reactive  
#---Observe
  observe({ #Scenarios based on the area of interest selected
    x <- data.table(getTableQuery(paste0("SELECT * FROM ", input$schema, ".scenarios")))
    updateCheckboxGroupInput(session, "scenario",
                       label = x$description,
                       choices = x$scenario,
                       selected = character(0)
    )
  })
  
  observe({
    x <- data.table(getTableQuery(paste0("SELECT column_name FROM information_schema.columns
  WHERE table_schema = '", input$schema , "' ", "
  AND table_name   = '",input$queryTable,"'")))
    updateSelectInput(session, "queryColumn",
                             choices = x$column_name,
                             selected = character(0)
    )
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

