#
# This is the server logic of a Shiny web application. You can run the
#-----------------------
# Define server function
server <- function(input, output, session) {
    #----------------  
    # Reactive Values 
    valueModal<-reactiveValues(atTable=NULL)
    # create a reactive value that will store the click position
    data_of_click <- reactiveValues(clickedShape=list())
    
    #
    #Filter based on map selection
    fetaPolyRender <-reactive({
      print(input$tsa)
        if(length(input$tsa) > 0 ){
           geojsonsf::sf_geojson(fetaPolySf[fetaTSA[fetaTSA$tsa %in% input$tsa,]$fid,])
        }
    })
    
    #--------  
    # Outputs 
    output$numberFisher<-renderValueBox({
        
        if(!is.null(input$tsa)){
          data<-geojsonsf::geojson_sf(fetaPolyRender())
          numDenning<-nrow(data[data$hab_den > 232, ])
          numMovement<-nrow(data[data$hab_mov > 1634, ])
          numRust<-nrow(data[data$hab_rus > 420, ])
          numCWD<-nrow(data[data$hab_cwd > 450, ])
          numCavity<-nrow(data[data$hab_cav > 10, ])
          valueBox(
              tags$p("Status", style = "font-size: 50%;"),
              fluidRow(
                  column(HTML(paste0("Abundance:&nbsp ", paste0(round(sum(data$abund),0))," <br> Max Abundance (n_fish):&nbsp ",paste0(round(sum(data$n_fish),0))," <br> Denning:&nbsp ",paste0(numDenning)," <br> Movement:&nbsp ",paste0(numMovement)," <br> Rust:&nbsp ",paste0(numRust)," <br> CWD:&nbsp ",paste0(numCWD)," <br> Cavity:&nbsp ",paste0(numCavity))), status = "primary", 
                         title = "O",  width = 12 , 
                         height = 120)
                  ), color = 'blue'
          )
        }else{
          valueBox(
            tags$p("Status", style = "font-size: 50%;"),
            fluidRow(
              column(HTML("Abundance:&nbsp 0 <br> Max Abundance (n_fish):&nbsp 0 <br> Denning:&nbsp 0 <br> Movement:&nbsp 0 <br> Rust:&nbsp 0 <br> CWD:&nbsp 0 <br> Cavity:&nbsp 0"), status = "primary", 
                     title = "O",  width = 12 , 
                     height = 120)
              )
            )
              
        }
    })
 
    ## render the base leaflet map  
    output$map = renderLeaflet({ 
        leaflet(options = leafletOptions(doubleClickZoom= TRUE, minZoom = 5)) %>% 
            setView(-121.7476, 53.7267, 6) %>%
            addTiles() %>% 
            addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>% 
        
            addWMSTiles(baseUrl = "https://openmaps.gov.bc.ca/geo/ows/",
               layers = c("pub:WHSE_ADMIN_BOUNDARIES.FADM_TSA"),
               group = c('TSA'),
               options = leaflet::WMSTileOptions(
                 transparent = TRUE,
                 format = "image/png",
                 info_format = "text/html",
                 tiled = FALSE
               ))%>%
            addWMSTiles(baseUrl = "https://openmaps.gov.bc.ca/geo/ows/",
               layers = c("pub:WHSE_TANTALIS.TA_PARK_ECORES_PA_SVW"),
               group = 'Parks',
               options = leaflet::WMSTileOptions(
                 transparent = T,
                 format = "image/png",
                 info_format = "text/html",
                 tiled = FALSE
               ))%>%
            addWMSTiles(baseUrl = "https://openmaps.gov.bc.ca/geo/ows/",
               layers = c("pub:WHSE_ADMIN_BOUNDARIES.FADM_DESIGNATED_AREAS"),
               group = 'FADM',
               options = leaflet::WMSTileOptions(
                 transparent = TRUE,
                 format = "image/png",
                 info_format = "text/html",
                 tiled = FALSE
               ))%>%
            addWMSTiles(baseUrl = "https://openmaps.gov.bc.ca/geo/ows/",
               layers = c("pub:WHSE_WILDLIFE_MANAGEMENT.WCP_WILDLIFE_HABITAT_AREA_POLY"),
               group = "WHA",
               options = leaflet::WMSTileOptions(
                 transparent = TRUE,
                 format = "image/png",
                 info_format = "text/html",
                 tiled = FALSE
               ))%>%
            addWMSTiles(baseUrl = "https://openmaps.gov.bc.ca/geo/ows/",
               layers = c("pub:WHSE_WILDLIFE_MANAGEMENT.WCP_UNGULATE_WINTER_RANGE_SP"),
               group = "UWR",
               options = leaflet::WMSTileOptions(
                 transparent = TRUE,
                 format = "image/png",
                 info_format = "text/html",
                 tiled = T
               ))%>%
            addLayersControl(
              baseGroups = "WorldImagery",
              overlayGroups = c("FETA","TSA","Parks","FADM", "WHA", "UWR" ),
              options = layersControlOptions(collapsed = TRUE)) %>%
            hideGroup("TSA") 
    })
    
  
    # ... OBSERVE EVENTS ----
    # store the click
    
    observeEvent(input$map_geojson_click, {
      print(input$map_geojson_click)
    })
    
    # Change the choropleth
    observe( { 
      req(input$colorFilt)

      leafletProxy('map')  %>% 
        clearGroup('FETA') %>%
        addGeoJSONChoropleth(
          fetaPolyRender(), group = 'FETA', layerId = "fid",
          valueProperty = input$colorFilt,
          scale = c("white", "blue"),
          color = "#ffffff", weight = 1, fillOpacity = 0.7,
          highlightOptions = highlightOptions(
            weight = 2, color = "#000000",
            fillOpacity = 0.1, opacity = 1,
            bringToFront = T, sendToBack = T)
        ) 
    })
 
    
    #Agree to the terms and conditions
    observeEvent(input$termsMod, {
      showModal(termsAndCondsModal)
    })
    
    #Download the FETAs into a shapefile
    observeEvent(input$db, {
      if (input$terms) {
        #Create a CSV to download
        output$downloadSHP<<- downloadHandler(
          filename = paste("feta_data-", Sys.Date(), ".zip", sep=""),
          content = function(fname) {
            fs <- c("feta.shp", "feta.dbf", "feta.prj", "feta.shx")
            st_write(geojsonsf::geojson_sf(fetaPolyRender()), "feta.shp", driver="ESRI Shapefile", delete_layer = TRUE)
            zip(zipfile="feta.zip", files=Sys.glob("feta.*"))
            file.copy("feta.zip", fname)
          },
          contentType = "application/zip")
        jsinject <- "setTimeout(function(){window.open($('#downloadSHP').attr('href'))}, 100);"
        session$sendCustomMessage(type = 'jsCode', list(value = jsinject))
      }
      else{
        showModal(termsWarn)
        print ("Please agree to the Terms and Conditions")
      }
    })
    
    # ... OBSERVE ---- 
    observe({
        if ("Select All" %in% input$tsa) {
            # choose all the choices _except_ "Select All"
            selected_choices <- setdiff(tsaBnds, "Select All")
            updateSelectInput(session, "tsa", selected = selected_choices)
        }
        if ("Clear All" %in% input$tsa) {
            # choose all the choices _except_ "Select All"
            selected_choices <- ""
            updateSelectInput(session, "tsa", selected = selected_choices)
        }
    })
    
    # ... MODALS ----
    # Terms and Cond
    termsAndCondsModal = modalDialog(
        title = HTML("<h2><b>Terms and Conditions</b></h2>"),
        easyClose = TRUE,
        fade = FALSE,
        HTML("<h4><b>Conditions for the Release of Fisher Equivalent Territory Areas Data
B.C. Ministry of Forests, Lands and Natural Resource Operations
Forest Analysis and Inventory Branch
</b></h4>
          The release of Fisher Equivalent Territory Areas Data requires that your agency agrees
          to the following terms and conditions prior to completing this transaction.
          <ol>
          <li>  The data cannot be used for purposes other than those negotiated between the Forest Analysis and Inventory Branch (Branch) and the agency.</li>
          <li>  The data cannot be distributed or sold to a third party or retained by the agency as a proprietary asset.</li>
          <li>  Any models/analyses developed from the use of the data may be requested for review by the Branch and may be put into the public domain.</li>
          <li>  The data will be returned to the Branch at the completion of the project, if requested.</li>
          <li>  Although these data have been carefully validated, some data quality/completion issues may still exist. The Branch cannot be held liable for the state of the data.</li>
          <li>  The Branch is not obliged to act on, or make a standard, the results from the agency's use/interpretation of the data.</li>
          <li>  The Branch is not held liable from the agency's use/interpretation of the data.</li>
          <li>  The agency is responsible for these terms and conditions for all its staff, associates and sub-contractors.</li>
          </ol>")
    )
    
    
    # Modal for labeling the drawn polygons
    warningModal = modalDialog(
        title = "Important message",
        "Shapefile not valid")
    
    # Modal for labeling the drawn polygons
    termsWarn = modalDialog(
        title = "Important message",
        "Please agree to the Terms and Conditions")
    
}
