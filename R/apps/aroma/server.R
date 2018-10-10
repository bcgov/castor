server <- function(input, output) {
  
  output$map = renderLeaflet({ 
    leaflet( options = leafletOptions(doubleClickZoom= TRUE)) %>% 
      setView(-121.7476, 53.7267, 4) %>%
      addTiles() %>% 
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
      addProviderTiles("Esri.DeLorme", group ="DeLorme" ) 
     
  })
  output$serverConnect <- renderText(paste(getQuery("SELECT COUNT(*) FROM aroma.ab_gy_test;")))
  
  getQuery<-function(sql){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='206.167.181.178', dbname = 'aroma', port='5432', user='aroma', password='Fomsummer2014')
    on.exit(dbDisconnect(conn))
    DBI::dbGetQuery(conn, sql)
  }
}