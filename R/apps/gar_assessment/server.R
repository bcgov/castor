#----------------
#-----------------------
test<-NULL

# Define server function
shinyServer(function(input, output, session) {
  #-------------------------------------------------------------------------------------------------
  #Functions for retrieving data from the postgres server (vector, raster and tables)
  #-------------------------------------------------------------------------------------------------
  readData<-function(session){
    progress<-Progress$new(session)
    progress$set(value = 0.2, message = 'Loading...')
 
  ## Load spatial data objects from postgres server
  #----------------
    
    # THIS IS AN EXAMPLE: USES THE WHA DATA, which we've put on our postgres server
    wha <<- sf::st_zm (getSpatialQuery("SELECT wha_tag, common_nam, wkb_geometry FROM public.wcp_whaply_polygon WHERE common_nam = 'Northern Caribou'")) # this query is a custom function, see script I sent you; change SELECT column (field) names if you want to select specific columns and change WHERE statement to get other species; foucs on Mtn Goadt here to save load time 
    sp_wha <<- sf::as_Spatial(st_transform(wha, 4326))

    progress$set(value = 0.5, message = 'Loading...')
    empt<<-st_sf(st_sfc(st_polygon(list(cbind(c(0,1,1,0,0),c(0,0,1,1,0)))),crs=3005))
    progress$set(value = 0.75, message = 'Loading...')
    
  #----------------
  # Load non-spatial data; query for accessing tables in db that are not spatial; not used here, but here as an example
  #----------------
  #get cached cutblock summary
    # progress$set(value = 0.8, message = 'Loading...')
    # cb_sumALL<<-getTableQuery("SELECT * FROM public.cb_sum")
  #----------------

    progress$close()
  }
  
  if(is.null(test)){
    readData(session)
  }

  
  #----------------  
  # Reactive Values 
  valueModal <- reactiveValues (atTable = NULL)
  
  whaSelect <- reactive({ # this function lets you select the wha layer on the map, by wha_tag
    req (input$map_shape_click$group) # input$map_shape_click is the key command to allow active selection of the feature on the map
    wha[wha$wha_tag == input$map_shape_click$group, ]}) # in this case, we're saying, make WHA selectable, by 'wha_tag' 
  
  drawnPolys <- reactive({ # this is the function that lets you draw on the map
    req(valueModal)
    if(!is.null(input$map_draw_all_features)){ # input$map_draw_all_features is the command for drawing features on a map
      f<-input$map_draw_all_features
      #get the lat long coordinates of the clicks
      coordz<-lapply(f$features, function(x){unlist(x$geometry$coordinates)})
      Longitudes<-lapply(coordz, function(coordz) {coordz[seq(1,length(coordz), 2)] })
      Latitudes<-lapply(coordz, function(coordz)  {coordz[seq(2,length(coordz), 2)] })
      
      polys<-list() # create a list of coords
      for (i in 1:length(Longitudes)){polys[[i]]<- Polygons(
        list(Polygon(cbind(Longitudes[[i]], Latitudes[[i]]))), ID=f$features[[i]]$properties$`_leaflet_id`
      )}
      spPolys<-SpatialPolygons(polys) # create a spatial polygon of the list of coordinates
      proj4string(spPolys)<-"+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
      
      # Extract the ID's from spPolys
      pid <- sapply(slot(spPolys, "polygons"), function(x) slot(x, "ID")) 
      # create a data.frame of teh ID's
      p.df <- data.frame(ID=pid, row.names = pid) 
      # Get the list of labels and ID from the user
      df <- as.data.frame (valueModal$atTable) 
      colnames(df) < -c("ID", "Label")
      # merge to the original ID of the polygons
      p.df$label<- df$Label[match(p.df$ID, df$ID)]
      SPDF <- spTransform(SpatialPolygonsDataFrame(spPolys, data=p.df), CRS("+init=epsg:3005"))
    }else{
      SDPF<-NULL
    }
    SPDF
  }) 
  
  totalArea <- reactive({ # function to get the area value of the WHA tag you clicked
    req(input$map_shape_click$group)
    sum(st_area(wha[wha$wha_tag == input$map_shape_click$group, ]))
    })
  
  whaName <- reactive({ # function to get the WHA tag name
    req(input$map_shape_click$group)
    as.character(input$map_shape_click$group)
  })


  # Spatial functions------

  # function to upload a shapefile... 
  uploadPolys <- reactive({ # drawnPolys
    shpValid <- FALSE
    outShp <- NULL
    if (!is.null(input$filemap)){
      shpValid <- TRUE
      shpdf <- input$filemap # shpdf is a data.frame with the name, size, type and datapath of the uploaded files
      tempdirname <- dirname(shpdf$datapath[1])
      fileList <- list()
      i <- 1
      for (file in shpdf$datapath) {
        fileExt <- strsplit(file, "\\.")
        fileExt <-fileExt[[1]][length(fileExt[[1]])]
        fileList[[i]] <- fileExt
        i <- i + 1
        if (fileExt %in% c("shp","dbf", "shx", "sbn", "sbx", "prj", "xml")){
          #print ("shp ext is good")
        }else{
          shpValid <- FALSE
          showModal(warningModal)}
      }

      if(!"shp" %in% fileList | !"dbf" %in% fileList | !"shx" %in% fileList ){
        shpValid <- FALSE
        showModal(warningModal)
      }

      if (shpValid){ # function to make sure the uploaded file is valid
        # Rename files
        for(i in 1:nrow(shpdf)){
          file.rename(shpdf$datapath[i], paste0(tempdirname, "/", shpdf$name[i]))
        }
        tryCatch({
          outShp <- st_transform(st_read(paste(tempdirname, shpdf$name[grep(pattern = "*.shp$", shpdf$name)], sep = "/")), CRS("+init=epsg:4326"))},
          error=function(cond) {
            shpValid <- FALSE
            showModal(warningModal)
            outShp <- NULL
            message(paste0("Here's the original error message:", cond))
          },
          finally ={
           # print ("shape done")
            }
        )
      }
    }
    if (!shpValid) {
      outShp = NULL

    } else {
      outShp 
    }
  })
  
  #--------  
  # Outputs 

   ## render the leaflet map; creates the map interface in the app  
  output$map = renderLeaflet({ 
    leaflet(sp_wha, options = leafletOptions(doubleClickZoom = TRUE)) %>% # zooms to the clicked WHA polygon
      setView(-121.7476, 53.7267, 4.3) %>% # sets the map view to the province
      addTiles() %>% # add some datasets
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>% # adds openstreet data
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>% # add ESRI imagery data
      addProviderTiles("Esri.DeLorme", group ="DeLorme" ) %>% # add ESRI delorme data
      addPolygons(data = sp_wha, fillColor = "red", # add the WHA data 
                  weight = 1, opacity = 1, color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~wha_tag,
                  group= ~wha_tag,
                  smoothFactor = 0.5,
                  label = ~wha_tag,
                  labelOptions = labelOptions (noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions (weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addScaleBar(position = "bottomright") %>%
      addControl(actionButton ("reset", "Refresh", icon = icon ("refresh"), 
                               style = "background-position: -31px -2px;"),
                               position = "bottomleft") %>% # Re-set button to re-set the map after zoom
      addDrawToolbar( # adds the toolbar to draw polys
        editOptions = editToolbarOptions(),
        targetGroup='Drawn',
        circleOptions = FALSE,
        circleMarkerOptions = FALSE,
        rectangleOptions = FALSE,
        markerOptions = FALSE,
        singleFeature = FALSE,
        polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,
                                                                          color = 'red',
                                                                          weight = 3, 
                                                                          clickable = TRUE))) %>%
      addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"), 
                       overlayGroups = c('Wildlife Habitat Area', 'Drawn'), 
                       options = layersControlOptions(collapsed = TRUE)) %>%
      hideGroup(c('Drawn')) 
  })
  
  # Create a shapefile to download
  output$downloadDrawnData <- downloadHandler( # this function lets you download a drawn poly as a shapefile
    filename = 'CLUSshpExport.zip',
    content = function(file) {
      if (length(Sys.glob("CLUSshpExport.*"))>0){
        file.remove(Sys.glob("CLUSshpExport.*"))
      }
      if(!is.null(input$map_draw_all_features)){
        rgdal::writeOGR(drawnPolys(), dsn="CLUSshpExport.shp", layer="CLUSshpExport", driver="ESRI Shapefile")
      }

      zip(zipfile='CLUSshpExport.zip', files=Sys.glob("CLUSshpExport.*"))
      file.copy("CLUSshpExport.zip", file)
    })
  
 
  output$rdTable<-renderTable({ # a function to create a table of the area of buffered roads in drawn area or selected WHA
    withProgress(message = 'Running Roads Query...takes a while', value = 0, {
      req(input$sliderBuffer)
      req(totalArea())
      if(input$queryType == 2){
        incProgress(0.5)
        # The following functions query the road data (FROM public.integrated_roads), and by road type
        # (road surface), calculate the length ST_Length (r.wkb_geometry), in km(/1000)
        # calculate the area of disturbance ( st_area ), based on the input buffer width (input$sliderBuffer)
        
        # The first query does ths within a drawn polygon, the second does it by selected WHA
        table<-getTableQuery(paste0("SELECT r.road_surface, sum (ST_Length (r.wkb_geometry))/1000 as length_km,
                              st_area (st_union (st_buffer (r.wkb_geometry, ", input$sliderBuffer,")))/10000 as area_ha_buffer 
                              FROM public.integrated_roads AS r,  
                              (SELECT ST_GeomFromText('",sf::st_as_text(st_as_sfc(drawnPolys()), EWKT = FALSE),"', 3005)) as m 
                              WHERE
                              ST_Contains (m.st_geomfromtext,r.wkb_geometry) 
                              GROUP BY  r.road_surface
                              ORDER BY  r.road_surface"))
        incProgress(0.95)
        ta<-as.numeric(sf::st_area(st_as_sfc(drawnPolys()))/10000)
        table$per_boundary<-(table$area_ha_buffer/ta)*100
        names(table)<-c("Road Surface", "Length (km)", paste0("Total Area (ha) with ",input$sliderBuffer ,"m Buffer"), "Percent of Drawn Area (%)")
        table
      }else{
        incProgress(0.5)
        table<-getTableQuery(paste0("SELECT 
                             r.road_surface, 
                             sum(ST_Length(r.wkb_geometry))/1000 as length_km,
                             st_area(st_union(st_buffer(r.wkb_geometry, ", input$sliderBuffer,")))/10000 as area_ha_buffer 
                              FROM 
                             public.integrated_roads AS r,  
                             (SELECT * FROM wcp_whaply_polygon WHERE wha_tag = '",whaName(),"') AS m 
                             WHERE
                             ST_Contains(m.wkb_geometry, r.wkb_geometry) 
                             GROUP BY  r.road_surface
                             ORDER BY  r.road_surface"))
        incProgress(0.95)
        ta<-as.numeric(totalArea()/10000)
        table$per_boundary<-(table$area_ha_buffer/ta)*100
        table$density <- table$length_km/(ta*0.01) # road density
        names(table)<-c("Road Surface", "Length (km)", paste0("Total Area (ha) with ",input$sliderBuffer ,"m Buffer"), "Percent of Boundary Area (%)", "Road Density (km/km2)")
        table
        
      }
    })
  })
  
  # If you want, try to replciate teh above for cutblocks 
  # cutlbocks data = public.cns_cut_bl_polygon
  
  #-------
  # OBSERVE

  ## This is a fucntion to zoom to the WHA being clicked on the leaflet map
  observe({
    if(is.null(input$map_shape_click))
      return()
     
    if(!is.null(uploadPolys())){ #  drawnPolys
      leafletProxy("map") %>%
        clearShapes() %>%
        clearControls() %>%
        setView(lng = input$map_shape_click$lng,lat = input$map_shape_click$lat, zoom = 10) %>% # set the view extent of the leaflet map to the clicked polygon
        addPolygons (data=sf::as_Spatial(st_transform(whaName(), 4326)), color = "red", fillColor="darkgreen", group = "Wildlife Habitat Area",
                     options = pathOptions(clickable = FALSE)) %>% # add the WHA data to the map
        addPolygons (data = uploadPolys(), # drawnPolys
                     group = "Drawn", color = "yellow", fillColor = "yellow", fillOpacity = 0.1) %>%
        addScaleBar (position = "bottomright") %>%
        addDrawToolbar(
          editOptions = editToolbarOptions(),
          targetGroup='Drawn',
          circleOptions = FALSE,
          circleMarkerOptions = FALSE,
          rectangleOptions = FALSE,
          markerOptions = FALSE,
          singleFeature = FALSE,
          polygonOptions = drawPolygonOptions (shapeOptions = drawShapeOptions (fillOpacity = 0,
                                                                                color = 'red',
                                                                                weight = 3,
                                                                                clickable = TRUE))) %>%
        addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"),
                         overlayGroups = c('Wildlife Habitat Area', 'Drawn'),
                         options = layersControlOptions(collapsed = TRUE)) %>%
        hideGroup(c('Drawn')) %>%
        addControl(actionButton("reset","Refresh", icon =icon("refresh"), style="
                                background-position: -31px -2px;"),position="bottomleft") 

      }else{
    
        leafletProxy("map") %>%
          clearShapes () %>%
          clearControls () %>%
          setView (lng = input$map_shape_click$lng,lat = input$map_shape_click$lat, zoom = 7.4) %>%
          addPolygons(data=sf::as_Spatial(st_transform(whaSelect(), 4326)), color = "red", 
                      fillColor="darkgreen", group = "Wildlife Habitat Area",
                      options = pathOptions(clickable = FALSE)) %>%
          addControl (actionButton("reset","Refresh", icon = icon("refresh"), style="
                                  background-position: -31px -2px;"),position="bottomleft") %>%
          addScaleBar (position = "bottomright") %>%
          addDrawToolbar(
            editOptions = editToolbarOptions(),
            targetGroup='Drawn',
            circleOptions = FALSE,
            circleMarkerOptions = FALSE,
            rectangleOptions = FALSE,
            markerOptions = FALSE,
            singleFeature = FALSE,
            polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,
                                                                              color = 'red',
                                                                              weight = 3, 
                                                                              clickable = TRUE))) %>%
          
          addLayersControl(baseGroups = c("OpenStreetMap", "WorldImagery", "DeLorme"), 
                           overlayGroups = c('Wildlife Habitat Area', 'Drawn'), 
                           options = layersControlOptions(collapsed = TRUE)) %>%
          hideGroup(c('Drawn')) 
      }
  })
  
  ## reset map
  observeEvent(input$reset, { # reset the map by clicking the button after a zoom
    leafletProxy("map") %>%
      clearShapes() %>%
      clearControls() %>%
      setView(-121.7476, 53.7267, 4.3) %>%
      addControl(actionButton("reset","Refresh", icon =icon("refresh"), 
                              style = "background-position: -31px -2px;"),position="bottomleft") %>%
      addPolygons(data = sp_wha,  fillColor = "red", 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~wha_tag,
                  group= ~wha_tag,
                  smoothFactor = 0.5,
                  label = ~wha_tag,
                  labelOptions = labelOptions (noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions (weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE))  
      
  })
  
  
  # Modal for labeling the drawn/edited polygons
  labelModal = modalDialog(
    title = "Enter polygon label",
    textInput(inputId = "myLabel", label = "Enter a label for the drawn polygon: "),
    footer = actionButton("ok_modal",label = "Ok"))
  
  #Model for warning shapefile upload
  warningModal = modalDialog(
    title = "Important message",
    "Shapefile not valid")
  
  # New Feature plus show modal
  observeEvent(input$map_draw_new_feature, {
    showModal(labelModal)
  })
  
  #Once ok in the modal is pressed by the user - store this into a matrix  
  observeEvent(input$ok_modal, {
    req(input$map_draw_new_feature$properties$`_leaflet_id`)
    valueModal$atTable<-rbind(valueModal$atTable, c(input$map_draw_new_feature$properties$`_leaflet_id`, input$myLabel))
    removeModal()
    
  })
  observe({
    print(input$map_draw_all_features)
  })

  # observe the uploaded shapefile on the map
  observe({
    if(!is.null(uploadPolys())){ # drawnPolys

     bb <- bbox (sf::as_Spatial (uploadPolys())) # drawnPolys

     leafletProxy("map") %>%
        addPolygons (data = uploadPolys(), # drawnPolys
                     group = "Drawn", color = "yellow", fillColor = "yellow", fillOpacity = 0.1) %>%
        showGroup(c('Drawn'))  %>%

        flyToBounds (lng1 = bb[1],lat1 = bb[2], lng2 = bb[3], lat2=bb[4]) # zoom to upload
    }
  })
  
  
  
  #--------------------------------
  ##Useful observeEvent for drawing  
  # Edited Features
  observeEvent(input$map_draw_edited_features, {
    #print("Edited Features")
    #print(input$map_draw_edited_features)
  })
  # Deleted features
  observeEvent(input$map_draw_deleted_features, {
    #print("Deleted Features")
    #print(input$map_draw_deleted_features)
  })
  # Start of Drawing
  observeEvent(input$map_draw_start, {
    #print("Start of drawing")
  })
  # Stop of Drawing
  observeEvent(input$map_draw_stop, {
    #prompt the used to label the polygon
    #print("Stop drawing")
  })
}
)