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
  ##Data objects
  #----------------
    herd_bound <<- sf::st_zm(getSpatialQuery("SELECT gid, herd_name, ecotype, risk_stat, geom FROM public.gcbp_carib_polygon WHERE herd_name <> 'NA'"))
    sp_herd_bound<<-sf::as_Spatial(st_transform(herd_bound, 4326))
    progress$set(value = 0.3, message = 'Loading...')
    uwr<<- getSpatialQuery("SELECT approval_year, geom FROM public.uwr_caribou_no_harvest_20180627 ")
    progress$set(value = 0.5, message = 'Loading...')
    wha<<- getSpatialQuery("SELECT approval_year, geom FROM public.wha_caribou_no_harvest_20180627 ")
    empt<<-st_sf(st_sfc(st_polygon(list(cbind(c(0,1,1,0,0),c(0,0,1,1,0)))),crs=3005))
    progress$set(value = 0.6, message = 'Loading...')
  #----------------
  #Non-Spatial 
  #Get climate data
    #bec<<-getTableQuery("SELECT * FROM public.clime_bec")
    #bec$year <<- relevel(as.factor(bec$year), "Current")
    #progress$set(value = 0.7, message = 'Loading...')
    #clime<<-getTableQuery("SELECT * FROM public.clim_plot_data")
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
  
  herdSelect<-reactive({ 
    req(input$map_shape_click$group)
    herd_bound[herd_bound$herd_name == input$map_shape_click$group, ]})
  
  drawnPolys<-reactive({
    req(valueModal)
    if(!is.null(input$map_draw_all_features)){
      f<-input$map_draw_all_features
      #get the lat long coordinates
      coordz<-lapply(f$features, function(x){unlist(x$geometry$coordinates)})
      Longitudes<-lapply(coordz, function(coordz) {coordz[seq(1,length(coordz), 2)] })
      Latitudes<-lapply(coordz, function(coordz)  {coordz[seq(2,length(coordz), 2)] })
      
      polys<-list()
      for (i in 1:length(Longitudes)){polys[[i]]<- Polygons(
        list(Polygon(cbind(Longitudes[[i]], Latitudes[[i]]))), ID=f$features[[i]]$properties$`_leaflet_id`
      )}
      spPolys<-SpatialPolygons(polys)
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
  
  totalArea<- reactive({
    req(input$map_shape_click$group)
    sum(st_area(herd_bound[herd_bound$herd_name == input$map_shape_click$group, ]))
    })
  
  caribouHerd<-reactive({
    req(input$map_shape_click$group)
    if(input$map_shape_click$group != "Wildlife Habitat Area"){
      as.character(input$map_shape_click$group)
    }
  })
  caribouEcoType<-reactive({ 
    req(input$map_shape_click$group)
    if(input$map_shape_click$group != "Wildlife Habitat Area"){
      as.character(herdSelect()[[3]])
    }
  })
  
  #becData<-reactive({
  #  req(caribouHerd())
  #  req(caribouEcoType())
   # dplyr::filter (bec, herdname == caribouHerd() | herdname == caribouEcoType()[1])})
  
  climateData<-reactive({
    req(caribouHerd())
    req(caribouEcoType())
    
    if(!is.null(caribouEcoType()[1])){
      clime<-getTableQuery(paste0("SELECT * FROM public.clim_plot_data WHERE herdname IN (
                                     '", caribouHerd() ,"');"))
      eco<-dplyr::filter (clime, ecotype == caribouEcoType()[1])
      eco$group<-caribouEcoType()[1]
      herd<-dplyr::filter (clime, herdname == caribouHerd())
      herd$group<-caribouHerd()
      rbind(eco, herd)
    } else {
      data<-data.frame(0,0,0,0)
      colnames(data)<-c("ecotype","herdname", "year","pct")
    }
  })
  
  dist_data <- reactive({
    req(caribouHerd())
    req(cb_sumALL)
    req(input$sliderCutAge)
    cb_sum<-rbind(cb_sumALL[which(cb_sumALL$herd_name ==caribouHerd()),],c(0,NA,1900),c(0,NA,2019)) #Add 50 years prior to the first cutblock date in cns_polys (~1950) and current date
    
    if(!is.null(cb_sum$harvestyr)){
      cb2<-tidyr::complete(cb_sum, harvestyr = full_seq(harvestyr,1), fill = list(sumarea = 0))
      cb2$Dist40<-zoo::rollapplyr(cb2$sumarea, input$sliderCutAge, FUN = sum, fill=0)
    }else{
      cb2 <- data.frame(harvestyr = 2000:2018, Dist40 = 0)
    }
    cb2 %>% filter(harvestyr>1960)
  })
  #this should be merged in dist_data?
  #fire_data <- reactive({
   # fire_sum[which(fire_sum$herd_name == caribouHerd() & fire_sum$fire_year > 1960 ),]
   # })
  
  thlb_data<- reactive({
    req(caribouHerd())
    req(gcbp_thlb)
    req(totalArea())
    out<-gcbp_thlb[which(gcbp_thlb$herd_name ==caribouHerd()),]
    out$percentBoundary<-(out$sum/(totalArea()/10000))*100
    out$herd_name<-NULL
    out
  })
  
  #Spatial--
  whaHerdSelect<-reactive({
    req(herdSelect())
    ws<-wha[st_buffer(herdSelect(), dist=20000),,op=st_intersects]
    if(length(ws$geom) > 0){
      ws
    }else{
      empt
    }
    
  })
  uwrHerdSelect<-reactive({
    req(herdSelect())
    #print(paste0("SELECT uwr_caribou_no_harvest_20180627.approval_year, uwr_caribou_no_harvest_20180627.geom 
     #FROM public.uwr_caribou_no_harvest_20180627 WHERE
     #                 ST_DWithin(uwr_caribou_no_harvest_20180627.geom, (SELECT geom FROM gcbp_carib_polygon WHERE 
     #                 gcbp_carib_polygon.herd_name = '",caribouHerd(),"'), 25000)"))
    #uw<-getSpatialQuery(paste0("SELECT uwr_caribou_no_harvest_20180627.approval_year, uwr_caribou_no_harvest_20180627.geom 
    # FROM public.uwr_caribou_no_harvest_20180627 WHERE
    #                  ST_DWithin(uwr_caribou_no_harvest_20180627.geom, (SELECT geom FROM gcbp_carib_polygon WHERE 
    #                  gcbp_carib_polygon.herd_name = '",caribouHerd(),"'), 25000)"))
    
    uw<-uwr[st_buffer(herdSelect(), dist=20000),,op=st_intersects]
    if(length(uw$geom) > 0){
      uw
    }else{
      empt
    }
  })
  
  # to upload shapefile... 
  uploadShp <- reactive({
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
      
      if (shpValid){
        # Rename files
        for(i in 1:nrow(shpdf)){
          file.rename(shpdf$datapath[i], paste0(tempdirname, "/", shpdf$name[i]))
        }
        tryCatch({
          outShp <-  st_transform(st_read(paste(tempdirname, shpdf$name[grep(pattern = "*.shp$", shpdf$name)], sep = "/")), CRS("+init=epsg:4326"))},
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
  ## Create scatterplot object the plotOutput function is expecting
  ## set the pallet for mapping
  pal <- colorFactor(palette = c("lightblue", "darkblue", "red"),  sp_herd_bound$risk_stat)
  ## render the leaflet map  
  output$map = renderLeaflet({ 
    leaflet(sp_herd_bound, options = leafletOptions(doubleClickZoom= TRUE)) %>% 
      setView(-121.7476, 53.7267, 4.3) %>%
      addTiles() %>% 
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
      addProviderTiles("Esri.DeLorme", group ="DeLorme" ) %>%
      addPolygons(data=sp_herd_bound, fillColor = ~pal(risk_stat), 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~gid,
                  group= ~herd_name,
                  smoothFactor = 0.5,
                  label = ~herd_name,
                  labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addScaleBar(position = "bottomright") %>%
      addControl(actionButton("reset","Refresh", icon =icon("refresh"), style="
                              background-position: -31px -2px;"),position="bottomleft") %>%
      addLegend("bottomright", pal = pal, values = c("Red/Threatened","Blue/Special","Blue/Threatened"), title = "Risk Status", opacity = 1) %>%
      addDrawToolbar(
        editOptions = editToolbarOptions(),
        targetGroup='Drawn',
        circleOptions = FALSE,
        circleMarkerOptions = FALSE,
        rectangleOptions = FALSE,
        markerOptions = FALSE,
        singleFeature = F,
        polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0
                                                                                         ,color = 'red'
                                                                                         ,weight = 3, clickable = TRUE))) %>%
      addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"), overlayGroups = c('Ungulate Winter Range','Wildlife Habitat Area', 'Drawn', 'Caribou Selection'), options = layersControlOptions(collapsed = TRUE)) %>%
      hideGroup(c('Drawn', 'Ungulate Winter Range','Wildlife Habitat Area', 'Caribou Selection')) 
  })
  
  # Create a shapefile to download
  output$downloadDrawnData <- downloadHandler(
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
  
  output$becPlot <- renderPlotly ({
    withProgress(message = 'Making BEC Plot', value = 0.1, {
      incProgress(0.2)
      bec_data<-getTableQuery(paste0("SELECT year, bec, pct, herdname FROM public.clime_bec WHERE herdname IN (
                                     '", caribouHerd() ,"', '", caribouEcoType()[1],"');"))
      bec_data$year<- relevel(as.factor(bec_data$year), "Current")
      dplyr::filter (bec_data, herdname == caribouHerd() | herdname == caribouEcoType()[1])
      incProgress(0.5)
      p<-ggplot(bec_data, aes (x = herdname, y=pct, fill = bec))+  
          facet_wrap(~year) +
          geom_bar (stat = "identity", position = "fill") +
          xlab ("Boundary") +
          ylab ("Proportion of Boundary (%)") +
          scale_fill_discrete (name = "Bec Zone") +
          theme_bw()
      rm(bec_data)
      gc()
      ggplotly(p)
    })
  })  
  
  output$ffdPlot <- renderPlotly ({
    withProgress(message = 'Making Climate Plot', value = 0.1, {
      p<-ggplot (climateData(), aes (year, sffd, fill = group)) +  
        geom_boxplot () +
        xlab ("Year") +
        ylab ("Spring Frost Free Days (#)") +
        #theme (axis.text = element_text (size = 12), legend.title = element_blank(),
        #       axis.title =  element_text (size = 14, face = "bold")) 
        theme_bw()
      ggplotly(p)%>%layout(boxmode = "group")
    })
  }) 
  
  output$pasPlot <- renderPlotly ({
    withProgress(message = 'Making Climate Plot', value = 0.1, {
      p<-ggplot (climateData(), aes (x=year, y=pas, fill = group)) +  
        geom_boxplot () +
        xlab ("Year") +
        ylab ("Precipitation as Snow (mm)") +
        #theme (axis.text = element_text (size = 12), legend.title = element_blank(),
        #       axis.title =  element_text (size = 14, face = "bold"))
        theme_bw()

      ggplotly(p)%>%layout(boxmode = "group")
    })
  }) 
  
  output$awtPlot <- renderPlotly ({
    withProgress(message = 'Making Climate Plot', value = 0.1, {
     p<-ggplot (climateData(), 
              aes (x=year, y=awt, fill = group)) +  
        geom_boxplot () +
        xlab ("Year") +
        ylab ("Average Winter Temperature (°C)") +
        #theme (axis.text = element_text (size = 12), legend.title = element_blank(),
        #       axis.title =  element_text (size = 14, face = "bold"))
        theme_bw()
     ggplotly(p)%>%layout(boxmode = "group")
    })
  }) 
  
  output$cutPlot <- renderPlotly({
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
  
  output$firePlot <- renderPlotly({
    withProgress(message = 'Running Fire Query', value = 0, {
      incProgress(0.2)
      fire_data<-getTableQuery(paste0("SELECT fire_year, (sumarea/10000) AS area FROM public.fire_sum WHERE herd_name = '", caribouHerd() ,"' AND fire_year > 1960
                                      GROUP BY sumarea, herd_name, fire_year ORDER BY fire_year "))
      #print(paste0("SELECT fire_year, (sumarea/10000) AS area FROM public.fire_sum WHERE herd_name = '", caribouHerd() ,"' AND fire_year > 1960;"))
      incProgress(0.5)
      p1<-ggplot(fire_data, aes(x =fire_year, y=area))+
        geom_bar (stat = "identity") +
        xlab ("Year") +
        ylab ("Area burnt (ha)") + 
        scale_x_continuous(breaks = seq(1960, 2018, by = 10))+
        scale_y_continuous(limits=c(0,max(fire_data$area)))+ 
        #theme (xis.text = element_text (size = 12), axis.title =  element_text (size = 14, face = "bold"))
        theme_bw()
      incProgress(0.8)
      ggplotly(p1)
    })
  })
  
  output$carbPopPlot <- renderPlotly({
    withProgress(message = 'Running Population Query', value = 0, {
      incProgress(0.2)
      carbPop_data<-getTableQuery(paste0("SELECT year, size FROM public.caribou_pop WHERE herd = '", caribouHerd() ,"';"))
      incProgress(0.5)
      if(length(carbPop_data) > 0){
      p<-ggplot(carbPop_data, aes(x =year, y=size))+
        geom_point (stat = "identity") +
        geom_smooth(method = 'lm', formula = y~x) +
        xlab ("Year") +
        ylab ("Estimated Population Size") + 
        #scale_x_continuous(breaks = seq(1960, 2018, by = 2))+
        expand_limits(y=0) +
        #theme (axis.text = element_text (size = 12), axis.title =  element_text (size = 14, face = "bold"))
        theme_bw()
      incProgress(0.8)
      rm(carbPop_data)
      gc()
      ggplotly(p)
      }
    })
  })
  
  output$uwrTable<-renderTable({
    withProgress(message = 'Running UWR Query', value = 0, {
      uwrtab<-st_intersection(st_set_agr(herdSelect(), "constant"), st_set_agr(uwrHerdSelect(), "constant"))
      uwrtab$area_ha<-st_area(uwrtab)/10000
      incProgress(0.2)
      if(length(uwrtab$geom)> 0){
        uwrtabo<-as.data.frame(st_set_geometry(uwrtab, NULL))[c("approval_year", "area_ha")]
        as.factor(uwrtabo$approval_year)
        uwrtabo %>%
          group_by(approval_year) %>%
          summarize(area_in_ha = sum(area_ha))
      }
    })
  })
  
  output$thlbTable<-renderTable({
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
  
  
  output$whaTable<-renderTable({
    withProgress(message = 'Running WHA Query', value = 0, {
      whatab<-st_intersection(st_set_agr(herdSelect(), "constant"), st_set_agr(whaHerdSelect(), "constant"))
      whatab$area_ha<-st_area(whatab)/10000
      incProgress(0.2)
      if(length(whatab$geom)> 0){
        whatabo<-as.data.frame(st_set_geometry(whatab, NULL))[c("approval_year", "area_ha")]
        as.factor(whatabo$approval_year)
        whatabo %>%
          group_by(approval_year) %>%
          summarize(area_in_ha = sum(area_ha))
      }
    })
  })
  
  output$rdTable<-renderTable({
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
                             (SELECT * FROM gcbp_carib_polygon WHERE herd_name = '",caribouHerd(),"') AS m 
                             WHERE
                             ST_Contains(m.geom,r.wkb_geometry) 
                             GROUP BY  r.road_surface
                             ORDER BY  r.road_surface"))
        incProgress(0.95)
        ta<-as.numeric(totalArea()/10000)
        table$per_boundary<-(table$area_ha_buffer/ta)*100
        names(table)<-c("Road Surface", "Length (km)", paste0("Total Area (ha) with ",input$sliderBuffer ,"m Buffer"), "Percent of Boundary Area (%)")
        table
        
      }
    })
  })
  #-------
  # OBSERVE
  # Observe the click on caribou herd  
  ## Update the herd and ecotype label
  observeEvent(input$map_shape_click, {
    output$clickCaribou <- renderText(caribouHerd())
    output$clickEcoType <- renderText(caribouEcoType()[1])
    
    output$pdfview <- renderUI({
        tags$iframe(style= "height:600px; width:100%; scrolling = yes", src = paste0(caribouHerd(),".pdf"))
    })
    
  })
  
  ## Zoom to caribou herd being cliked
  observe({
    if(is.null(input$map_shape_click))
      return()
    
    leafletProxy("map") %>%
      clearShapes() %>%
      clearControls() %>%
      setView(lng = input$map_shape_click$lng,lat = input$map_shape_click$lat, zoom = 7.4) %>%
      addPolygons(data=as_Spatial(st_transform(herdSelect(), 4326)) , fillOpacity = 0.1, color = "red", weight =4,labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , textsize='13px'),
                  options = pathOptions(clickable = FALSE)) %>%
      addPolygons(data=sf::as_Spatial(st_transform(uwrHerdSelect(), 4326)), color = "blue" 
                  , fillColor="brown", group = "Ungulate Winter Range",
                  options = pathOptions(clickable = FALSE))%>%
      addPolygons(data=sf::as_Spatial(st_transform(whaHerdSelect(), 4326)), color = "blue"
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
        polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0
                                                                                         ,color = 'red'
                                                                                         ,weight = 3, clickable = TRUE))) %>%
      
      addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"), 
                       overlayGroups = c('Ungulate Winter Range','Wildlife Habitat Area', 'Drawn', 'Caribou Selection'), 
                       options = layersControlOptions(collapsed = TRUE)) %>%
      hideGroup(c('Drawn', 'Caribou Selection')) 
  })
  
  
  ## rest map
  observeEvent(input$reset, {
    leafletProxy("map") %>%
      clearShapes() %>%
      clearControls() %>%
      setView(-121.7476, 53.7267, 4.3) %>%
      addControl(actionButton("reset","Refresh", icon =icon("refresh"), style="
                              background-position: -31px -2px;"),position="bottomleft") %>%
      addPolygons(data=sp_herd_bound,  fillColor = ~pal(risk_stat), 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~gid,
                  group= ~herd_name,
                  smoothFactor = 0.5,
                  label = ~herd_name,
                  labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addLegend("bottomright", pal = pal, values = c("Red/Threatened","Blue/Special","Blue/Threatened"), title = "Risk Status", opacity = 1) 
  })
  
  # Modal for labeling the drawn polygons
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
    if(!is.null(uploadShp())){
      leafletProxy("map") %>%
        addPolygons (data = uploadShp(), group = "Drawn") 
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