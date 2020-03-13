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
    progress$set(value = 0, message = 'Loading...')
 
    
  ## Load spatial data objects from postgres server
  #----------------
    
    # THIS IS AN EXAMPLE: NEED TO UPLOAD THE DATA YOU NEED (e.g., WHA, UWR boundaries) to a 
    # postgres server, or something similar; need to determine what data you want in there (species, year, id, etc.)
    
    uwr<<- getSpatialQuery("SELECT approval_year, geom FROM public.uwr_caribou_no_harvest_20180627 ")
    progress$set(value = 0.3, message = 'Loading...')
    wha<<- getSpatialQuery("SELECT common_species_name, approval_year, geom FROM public.wha_caribou_no_harvest_20180627 ")
    empt<<-st_sf(st_sfc(st_polygon(list(cbind(c(0,1,1,0,0),c(0,0,1,1,0)))),crs=3005))
    progress$set(value = 0.5, message = 'Loading...')
  #----------------
  # Load non-spatial data 
  #----------------
  #get cached cutblock summary
    progress$set(value = 0.8, message = 'Loading...')
    cb_sumALL<<-getTableQuery("SELECT * FROM public.cb_sum")
  #----------------
    #get cached thlb summary
    progress$set(value = 0.9, message = 'Loading...')
    gcbp_thlb<<-getTableQuery("SELECT herd_name, sum FROM public.gcbp_thlb_sum")
  #----------------
  #get cached fire summary
    #fire_sum<<-getTableQuery("SELECT * FROM public.fire_sum")
    progress$close()
  }
  
  if(is.null(test)){
    readData(session)
  }

  
  
  
  #----------------  
  # Reactive Values 
  valueModal<-reactiveValues(atTable=NULL)
  
  whaSelect<-reactive({ # this function lets you select the wha layer on the map, by species code (but can use whatever you want in data)
    req(input$map_shape_click$group) # input$map_shape_click is the key command to allow active selection of the feature on the map
    wha[wha$common_species_name == input$map_shape_click$group, ]}) # in this case, we're saying, make WHA selectable, by 'common_species_name' 
  
  drawnPolys <- reactive({ # this is the function that lets you draw on the map
    req(valueModal)
    if(!is.null(input$map_draw_all_features)){ # input$map_draw_all_features is the command for drawing features on a map
      f<-input$map_draw_all_features
      #get the lat long coordinates of the clicks
      coordz<-lapply(f$features, function(x){unlist(x$geometry$coordinates)})
      Longitudes<-lapply(coordz, function(coordz) {coordz[seq(1,length(coordz), 2)] })
      Latitudes<-lapply(coordz, function(coordz)  {coordz[seq(2,length(coordz), 2)] })
      
      polys<-list()
      for (i in 1:length(Longitudes)){polys[[i]]<- Polygons(
        list(Polygon(cbind(Longitudes[[i]], Latitudes[[i]]))), ID=f$features[[i]]$properties$`_leaflet_id`
      )}
      spPolys<-SpatialPolygons(polys) # create a spatial polygon of the list of coordinates
      proj4string(spPolys)<-"+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
      
      #Extract the ID's from spPolys
      pid <- sapply(slot(spPolys, "polygons"), function(x) slot(x, "ID")) 
      #create a data.frame
      p.df <- data.frame(ID=pid, row.names = pid) 
      #Get the list of labels and ID from the user
      df <- as.data.frame(valueModal$atTable) 
      colnames(df)<-c("ID", "Label")
      #merge to the original ID of the polygons
      p.df$label<- df$Label[match(p.df$ID, df$ID)]
      SPDF<-spTransform(SpatialPolygonsDataFrame(spPolys, data=p.df), CRS("+init=epsg:3005"))
    }else{
      SDPF<-NULL
    }
    SPDF
  }) 
  
  totalArea <- reactive({ # function to get the area value of the WHA common_species_name you clicked
    req(input$map_shape_click$group)
    sum(st_area(wha[wha$common_species_name == input$map_shape_click$group, ]))
    })
  
  whaName <- reactive({ # function to get the WHA common_species_name name
    req(input$map_shape_click$group)
    if(input$map_shape_click$group != "Wildlife Habitat Area"){
      as.character(input$map_shape_click$group)
    }
  })


  dist_data <- reactive({ # this function gets the area of cutblock by WHA common_species_name; requires 'caching' the sum of cutblock area by WHA common_species_name, i.e., cb_sumALL 
    req(whaName())
    req(cb_sumALL)
    req(input$sliderCutAge)
    cb_sum<-rbind(cb_sumALL[which(cb_sumALL$whaName == whaName()),],c(0,NA,1900),c(0,NA,2019)) #Add 50 years prior to the first cutblock date in cns_polys (~1950) and current date
    
    if(!is.null(cb_sum$harvestyr)){
      cb2<-tidyr::complete(cb_sum, harvestyr = full_seq(harvestyr,1), fill = list(sumarea = 0))
      cb2$Dist40<-zoo::rollapplyr(cb2$sumarea, input$sliderCutAge, FUN = sum, fill=0)
    }else{
      cb2 <- data.frame(harvestyr = 2000:2018, Dist40 = 0)
    }
    cb2 %>% filter(harvestyr>1960)
  })

  thlb_data<- reactive({ # this function gets the area of thlb by WHA common_species_name; requires 'caching' the sum of THLB area by WHA common_species_name, i.e., gcbp_thlb 
    req(whaName())
    req(gcbp_thlb)
    req(totalArea())
    out<-gcbp_thlb[which(gcbp_thlb$herd_name ==whaName()),]
    out$percentBoundary<-(out$sum/(totalArea()/10000))*100
    out$herd_name<-NULL
    out
  })
  
  #Spatial--

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
    leaflet(wha, options = leafletOptions(doubleClickZoom = TRUE)) %>% 
      setView(-121.7476, 53.7267, 4.3) %>% # sets the map view to the province
      addTiles() %>% # add some datasets
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>% # adds openstreet data
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>% # add ESRI imagery data
      addProviderTiles("Esri.DeLorme", group ="DeLorme" ) %>% # add ESRI delorme data
      addPolygons(data=wha, fillColor = "blue", # add the data 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~common_species_name,
                  group= ~common_species_name,
                  smoothFactor = 0.5,
                  label = ~common_species_name,
                  labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addScaleBar(position = "bottomright") %>%
      addControl(actionButton("reset","Refresh", icon =icon("refresh"), style="
                              background-position: -31px -2px;"),position="bottomleft") %>%
      addDrawToolbar( # adds the toolbar to draw polys
        editOptions = editToolbarOptions(),
        targetGroup='Drawn',
        circleOptions = FALSE,
        circleMarkerOptions = FALSE,
        rectangleOptions = FALSE,
        markerOptions = FALSE,
        singleFeature = F,
        polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,
                                                                          color = 'red',
                                                                          weight = 3, 
                                                                          clickable = TRUE))) %>%
      addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"), overlayGroups = c('Ungulate Winter Range','Wildlife Habitat Area', 'Drawn'), options = layersControlOptions(collapsed = TRUE)) %>%
      hideGroup(c('Drawn', 'Ungulate Winter Range','Wildlife Habitat Area')) 
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
  
 
  output$cutPlot <- renderPlotly({ # a function to plot the area of cutblocks in selected WHA
    withProgress(message = 'Running Cutblock Query', value = 0.1, {
      ta<-as.numeric(totalArea())
      incProgress(0.3)
      data<-dist_data()
      data$per_harvest<-(data$Dist40/ta)*100
      incProgress(0.6)
      
      p<- ggplot(data, aes(x =harvestyr, y=per_harvest) )+
        geom_line()+
        xlab ("Year") +
        ylab (paste0("% Boundary with Age < ", input$sliderCutAge)) + 
        scale_x_continuous(breaks = seq(1960, 2018, by = 10))+
        expand_limits(y=0) +
        #theme (axis.text = element_text (size = 12), axis.title =  element_text (size = 14, face = "bold"))
        theme_bw()
      
      incProgress(0.8)
      ggplotly(p)
    })
  })
  
  
  output$thlbTable<-renderTable({ # a function to plot the area of THLB in drawn area or selected WHA
    withProgress(message = 'Running THLB Query', value = 0, {
      if(input$queryType == 2){
        incProgress(0.5)
        #Convert the polygon object to sql polygon
        table<-getTableQuery(paste0("SELECT (ST_SummaryStatsAgg(x.intersectx,1,true)).sum 
          FROM
        (SELECT ST_Intersection(rast,1,ST_AsRaster(geom, rast),1) as intersectx
          FROM bc_thlb2018, (SELECT ST_GeomFromText('",sf::st_as_text(st_as_sfc(drawnPolys()), EWKT = FALSE),"', 3005) as geom ) as t 
          WHERE ST_Intersects(geom, rast)) as x
        WHERE x.intersectx IS NOT NULL;"))
        incProgress(0.95)
        ta<-as.numeric(sf::st_area(st_as_sfc(drawnPolys()))/10000)
        table$per_boundary<-(table$sum/ta)*100
        names(table)<-c("Sum THLB (ha)", "Percent of Drawn Area (%)")
        table
      }else{
        incProgress(0.5)
        table<-thlb_data()
        names(table)<-c("Sum THLB (ha)", "Percent of Boundary Area (%)")
        table
      }
    })
  })
  
  
  output$rdTable<-renderTable({ # a function to plot the area of buffered roads in drawn area or selected WHA
    withProgress(message = 'Running Roads Query...takes a while', value = 0, {
      req(input$sliderBuffer)
      req(totalArea())
      if(input$queryType == 2){
        incProgress(0.5)
        #Convert the polygon object to sql polygon
        table<-getTableQuery(paste0("SELECT r.road_surface,sum(ST_Length(r.wkb_geometry))/1000 as length_km, 
                            st_area(st_union(st_buffer(r.wkb_geometry, ", input$sliderBuffer,")))/10000 as area_ha_buffer 
                              FROM public.integrated_roads AS r,  
                             (SELECT ST_GeomFromText('",sf::st_as_text(st_as_sfc(drawnPolys()), EWKT = FALSE),"', 3005)) as m 
                             WHERE
                             ST_Contains(m.st_geomfromtext,r.wkb_geometry) 
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
                             (SELECT * FROM gcbp_carib_polygon WHERE herd_name = '",whaName(),"') AS m 
                             WHERE
                             ST_Contains(m.geom,r.wkb_geometry) 
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
  
  #-------
  # OBSERVE

  ## Zoom to WHA being cliked
  observe({
    if(is.null(input$map_shape_click))
      return()
     
    if(!is.null(uploadPolys())){ #  drawnPolys
      leafletProxy("map") %>%
        clearShapes() %>%
        clearControls() %>%
        setView(lng = input$map_shape_click$lng,lat = input$map_shape_click$lat, zoom = 7.4) %>%
        addPolygons(data=sf::as_Spatial(st_transform(whaHerdSelect(), 4326)), color = "blue", fillColor="darkgreen", group = "Wildlife Habitat Area",
                    options = pathOptions(clickable = FALSE)) %>%
        addPolygons (data = uploadPolys(), # drawnPolys
                     group = "Drawn", color = "yellow", fillColor = "yellow", fillOpacity = 0.1) %>%
        addScaleBar(position = "bottomright") %>%
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
        addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"),
                         overlayGroups = c('Ungulate Winter Range','Wildlife Habitat Area', 'Drawn'),
                         options = layersControlOptions(collapsed = TRUE)) %>%
        hideGroup(c('Ungulate Winter Range','Wildlife Habitat Area')) %>%
        addControl(actionButton("reset","Refresh", icon =icon("refresh"), style="
                              background-position: -31px -2px;"),position="bottomleft") 

      }else{
    
        leafletProxy("map") %>%
          clearShapes() %>%
          clearControls() %>%
          setView(lng = input$map_shape_click$lng,lat = input$map_shape_click$lat, zoom = 7.4) %>%
          addPolygons(data=sf::as_Spatial(st_transform(whaSelect(), 4326)), color = "blue"
                      , fillColor="darkgreen", group = "Wildlife Habitat Area",
                      options = pathOptions(clickable = FALSE)) %>%
          addControl(actionButton("reset","Refresh", icon =icon("refresh"), style="
                                  background-position: -31px -2px;"),position="bottomleft") %>%
          addScaleBar(position = "bottomright") %>%
          addDrawToolbar(
            editOptions = editToolbarOptions(),
            targetGroup='Drawn',
            circleOptions = FALSE,
            circleMarkerOptions = FALSE,
            rectangleOptions = FALSE,
            markerOptions = FALSE,
            singleFeature = F,
            polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,
                                                                              color = 'red',
                                                                              weight = 3, 
                                                                              clickable = TRUE))) %>%
          
          addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"), 
                           overlayGroups = c('Ungulate Winter Range','Wildlife Habitat Area', 'Drawn'), 
                           options = layersControlOptions(collapsed = TRUE)) %>%
          hideGroup(c('Drawn')) 
      }
  })
  
  ## reset map
  observeEvent(input$reset, { # reset the map after a zoom
    leafletProxy("map") %>%
      clearShapes() %>%
      clearControls() %>%
      setView(-121.7476, 53.7267, 4.3) %>%
      addControl(actionButton("reset","Refresh", icon =icon("refresh"), style="
                              background-position: -31px -2px;"),position="bottomleft") %>%
      addPolygons(data = wha,  fillColor = "blue", 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~common_species_name,
                  group= ~common_species_name,
                  smoothFactor = 0.5,
                  label = ~common_species_name,
                  labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addLegend("bottomright", pal = pal, values = unique(wha$timber_harvest_code), title = "Population Trend", opacity = 1) 
      
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