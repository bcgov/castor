#
# This is the server logic of a Shiny web application. You can run the
#-----------------------
# Define server function
server <- function(input, output, session) {
    # 
    filemapBtn <- (actionButton("filemapBtn", "Upload Shapefile"))
    fb <- (actionButton("fb", "Filter"))
    filemap <- fileInput(placeholder = "shp,dbf,shx",width = 185 ,inputId = "filemap", label = "Upload Shapefile to Map", multiple = TRUE, accept = c("shp","dbf", "shx", "sbn", "sbx", "prj", "xml"))
    filemap <- absolutePanel(filemap, right = -166, top = -40, fixed = FALSE, width = -200 , height = "100%")
    
    #----------------  
    # Reactive Values 
    valueModal<-reactiveValues(atTable=NULL)
    
    #Filter based on drawn value
    sp_from_draw <- function(){
        if(!is.null(input$map_draw_all_features) & !is.null(drawnPolys()) & !is.null(fetaPoly_r()) ){
            points <- st_intersects(sf::st_make_valid(st_as_sf(drawnPolys())), fetaPoly_r())
            #points <- st_intersection(st_as_sf(drawnPolys()), sp_samplePoints_r())
         if(nrow(points) == 0){
           points <- NULL
          }
        }
        else { points <- NULL}
        points
    }
    #
    #Filter based on imported shape
    sp_from_imp <- function(){
        if(!is.null(impShp()) & !is.null(fetaPoly_r()) ) {
            points <- st_intersects(st_as_sf(impShp()), fetaPoly_r())
            if(nrow(points) == 0){
                points <- NULL}
        }
        else { points <- NULL}
        points
    }
    #
    sp_from_imp_and_draw <- function(){
        
        if(!is.null(sp_from_imp()) & !is.null(sp_from_draw()) & !is.null(fetaPoly_r())) {
            poly <- st_union(st_as_sf(drawnPolys()), st_as_sf(impShp()))
            points <- st_intersects(poly, fetaPoly_r())
            
            if(nrow(points) == 0){
                points <- NULL}
        }
        
        else if(is.null(impShp()) ){
            
            points <- sp_from_draw()}
        
        else if(is.null(drawnPolys())){
            points <- sp_from_imp()}
        
        else { points <- NULL}
        points
    }
    #
    #Filter based on map selection
    fetaPoly_r <-reactive({
        if(length(input$tsa) > 0 ){
            spatial<-fetaPoly[unique(fetaTSA[tsa %in% input$tsa,]$fid),]
            if(nrow(spatial) == 1){
                spatial <- NULL
            }
        }
        
        else {spatial <- NULL}
        
        spatial
    })
    #
    
    masterTable <- reactive({
        switch(input$shapeFilt,
            "Drawn Polygon" = {
                spatial <- fetaPoly_r()[unlist(sp_from_draw(), use.names = F),]
            },
            "Shapefile" = {
                spatial <- fetaPoly_r()[unlist(sp_from_imp(), use.names = F),]
            },
            "Both" = {
                spatial <- fetaPoly_r()[unlist(sp_from_imp_and_draw(), use.names = F),]
            },
            "None" = {
                spatial <- fetaPoly_r()
            }
        )
       return(spatial)
    })
    
    
    drawnPolys<-reactive({
        req(valueModal)
        if(!is.null(input$map_draw_all_features)){
            f<-input$map_draw_all_features
            if (length(f$features) > 0) {
                #get the lat long coordinates
                coordz<-lapply(f$features, function(x){unlist(x$geometry$coordinates)})
                Longitudes<-lapply(coordz, function(coordz) {coordz[seq(1,length(coordz), 2)] })
                Latitudes<-lapply(coordz, function(coordz)  {coordz[seq(2,length(coordz), 2)] })
                
                polys<-list()
                for (i in 1:length(Longitudes)){
                    polys[[i]]<- Polygons(list(Polygon(cbind(Longitudes[[i]], Latitudes[[i]]))), ID=f$features[[i]]$properties$`_leaflet_id` )}
                
                spPolys<-SpatialPolygons(polys)
                proj4string(spPolys)<-"+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
                
                #Extract the ID's from spPolys
                pid <- sapply(slot(spPolys, "polygons"), function(x) slot(x, "ID"))
                #create a data.frame
                p.df <- data.frame(ID=pid, row.names = pid)
                df <- as.data.frame(valueModal$atTable)
                p.df$ID = as.character(p.df$ID)
                df$V1 = as.character(df$V1)
                df$V2 = as.character(df$V2)
                colnames(df)<-c("ID", "Label")
                
                #merge to the original ID of the polygons
                p.df$label<- df$Label[match(p.df$ID, df$ID)]
                SPDF<-SpatialPolygonsDataFrame(spPolys, data=p.df)}
            
            else{
                SPDF<-NULL
            }
            
        }
        
        else{
            SPDF<-NULL
        }
        SPDF
    })
    # # 
    # # 
    #Data to be plotted on age/volume chart. Any record with age < 0 is removed
    noZerosPlotData <- reactive({
        if (!is.null(masterTable())){
            data <- subset(as.data.frame(masterTable()), p_occ > 0)}
        else {
            data <- NULL}
        data
    })
    #
    #Import Shapefile as df
    impShp <- reactive({
        shpValid <- FALSE
        outShp <- NULL
        # shpdf is a data.frame with the name, size, type and datapath of the uploaded files
        if (!is.null(input$filemap)){
            shpValid <- TRUE
            shpdf <- input$filemap
            tempdirname <- dirname(shpdf$datapath[1])
            fileList <- list()
            i <- 1
            for (file in shpdf$datapath) {
                fileExt <- strsplit(file, "\\.")
                fileExt <-fileExt[[1]][length(fileExt[[1]])]
                fileList[[i]] <- fileExt
                i <- i + 1
                if (fileExt %in% c("shp","dbf", "shx", "sbn", "sbx", "prj", "xml"))
                {print ("shp ext is good")}
                else{
                    shpValid <- FALSE
                    showModal(warningModal)}
            }
            
            if(!"shp" %in% fileList | !"shp" %in% fileList | !"dbf" %in% fileList | !"shx" %in% fileList )
            { shpValid <- FALSE
            showModal(warningModal)}
            # if("shp" %in% fileList)
            # { print ("yes")}
            
            
            
            if (shpValid){
                # Rename files
                for(i in 1:nrow(shpdf)){
                    file.rename(shpdf$datapath[i], paste0(tempdirname, "/", shpdf$name[i]))
                }
                tryCatch(
                    {outShp <-  spTransform(readOGR(paste(tempdirname, shpdf$name[grep(pattern = "*.shp$", shpdf$name)], sep = "/")), CRS("+init=epsg:4326"))},
                    error=function(cond) {
                        shpValid <- FALSE
                        showModal(warningModal)
                        outShp <- NULL
                        message("Here's the original error message:")
                        
                    },
                    finally ={print ("shape done")}
                )
            }
            
        }
        if (!shpValid) {
            outShp = NULL
            
        }
        else{outShp}
        outShp
    })
    
    getOnclickCoord <- reactive({
        d <- event_data("plotly_click")
        if (is.null(d)) NULL
        else d$key})
    
    
    pal <- reactive({
        colorNumeric(palette = "Blues", domain = )
    })
    
    
    #--------  
    # Outputs 
    ## Create scatterplot object the plotOutput function is expecting
    ## set the pallet for mapping
    #pal <- colorNumeric(palette = "Blues",  domain = fetaPoly$n_fish)
    
    ## render the leaflet map  
    output$map = renderLeaflet({ 
        req(input$colorFilt)
        data<-fetaPoly
        pal<-colorNumeric(palette = "Blues", domain = as.numeric(data[[paste0(input$colorFilt)]]) )
        leaflet(data, options = leafletOptions(doubleClickZoom= TRUE, minZoom = 5)) %>% 
            setView(-121.7476, 53.7267, 5) %>%
            setMaxBounds( lng1 = -142 
                          , lat1 = 46 
                          , lng2 = -112
                          , lat2 =  62 ) %>%
            addTiles() %>% 
            addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
            addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
            addWMSTiles(baseUrl = "https://openmaps.gov.bc.ca/geo/ows/",
                        layers = "pub:WHSE_ADMIN_BOUNDARIES.FADM_TSA",
                        options = WMSTileOptions(format = "image/png", transparent = TRUE, group = 'TSA Boundaries')
            )%>%
            addPolygons(data = data, stroke = TRUE, fillColor = pal(as.numeric(data[[paste0(input$colorFilt)]])), color = pal(as.numeric(data[[paste0(input$colorFilt)]])),weight = 2,
                    opacity = 0.9, fill = TRUE, fillOpacity = 0.2,  highlight = highlightOptions(
                        weight = 5,
                        color = "#666666",
                        fillOpacity = 0.7,
                        bringToFront = TRUE), group ="FETA",
                    layerId = data$fid,
                    popup = paste(sep = "<br/>",
                            paste(paste("<b>FID</b> : ", data$fid, "<br/>"),
                            paste("<b>Density</b> : ", round(data$n_fish,2), "<br/>"),
                            paste("<b>Rel. Prob. Occup</b> : ", round(data$p_occ,2), "<br/>"),
                            paste("<b>Movement</b> : ", round(data$hab_mov_x,0), "ha <br/>"),
                            paste("<b>Denning</b> : ", round(data$hab_den_y,0), "ha <br/>"),
                            paste("<b>Rest. Rust</b> : ", round(data$hab_rus_y, 0), "ha <br/>"),
                            paste("<b>Rest. CWD</b> : ", round(data$hab_cwd_y,0), "ha <br/>"),
                            paste("<b>Rest. Cavity</b> : ", round(data$hab_cav_y,0), "ha <br/>")))
                    )%>%
            addScaleBar(position = "bottomright") %>%
            addControl(filemap,position="bottomleft") %>%
            addLegend("bottomright", pal = pal, values = as.numeric(data[[paste0(input$colorFilt)]]),  title = paste0(input$colorFilt), opacity = 1) %>%
            addDrawToolbar(
                editOptions = editToolbarOptions(edit = TRUE, remove = TRUE, selectedPathOptions = NULL,
                                                 allowIntersection = FALSE),
                targetGroup='Drawn',
                polylineOptions = FALSE,
                circleOptions = FALSE,
                circleMarkerOptions = FALSE,
                rectangleOptions = FALSE,
                markerOptions = FALSE,
                singleFeature = FALSE,
                polygonOptions = myDrawPolygonOptions()) %>%
            
            
            addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "TSA Boundaries"), overlayGroups = "FETA", options = layersControlOptions(collapsed = FALSE)) %>%
            mapOptions(zoomToLimits = "always")  %>%
            addEasyButton(easyButton(
                icon = 'ion-arrow-shrink',
                title = 'Zoom to Features',
                onClick = JS("function(btn, map) { 
       var groupLayer = map.layerManager.getLayerGroup('FETA');
        map.fitBounds(groupLayer.getBounds());}")  
            ))
        
        
    })
    
    
    plotData <- function(data){
        output$fisherQuality <- renderPlotly({
            if (!is.null(data)){
                key <- data$fid
                
                p <- plot_ly(data,
                             x = data$p_occ,
                             hoverinfo = 'text',
                             text = data$fid,
                             key = ~key ,
                             type = "histogram")
                
                p %>%
                    layout(  autosize=TRUE, dragmode = 'lasso', xaxis = (list(autorange = TRUE, title = "Distribution of Rel. Prob. Occupancy", automargin = TRUE)),
                             legend = list(orientation = 'h',  y = 100), margin = list(r = 20, b = 50, t = 50, pad = 4),
                             yaxis = (list(title = "Rel. Prob Occupancy")))%>%
                    config(displayModeBar = F)}
            
            else{
                
                
                p <- plot_ly(x = runif(100,0,1),
                             type = "histogram") %>%
                    layout(  autosize=TRUE, dragmode = 'lasso', xaxis = (list(autorange = TRUE, title = "Distribution of Rel. Prob. Occupancy", automargin = TRUE)),
                             legend = list(orientation = 'h',  y = 100), margin = list(r = 20, b = 50, t = 50, pad = 4),
                             yaxis = (list(title = "Rel. Prob Occupancy")))%>%
                    config(displayModeBar = F)
                
            }
            p
        })
        
        output$fisherDensity <- renderPlotly({
            if (!is.null(data)){
                key <- data$fid
                
                p <- plot_ly(data,
                             x = data$n_fish,
                             hoverinfo = 'text',
                             text = data$fid,
                             key = ~key ,
                             type = "histogram")
                
                p %>%
                    layout(  autosize=TRUE, dragmode = 'lasso', xaxis = (list(autorange = TRUE, title = "Distribution of Fisher Density", automargin = TRUE)),
                             legend = list(orientation = 'h',  y = 100), margin = list(r = 20, b = 50, t = 50, pad = 4),
                             yaxis = (list(title = "Density")))%>%
                    config(displayModeBar = F)}
            
            else{
                
                
                p <- plot_ly(x = runif(100,0,1),
                             type = "histogram") %>%
                    layout(  autosize=TRUE, dragmode = 'lasso', xaxis = (list(autorange = TRUE, title = "Fake Distribution", automargin = TRUE)),
                             legend = list(orientation = 'h',  y = 100), margin = list(r = 20, b = 50, t = 50, pad = 4),
                             yaxis = (list(title = "Density")))%>%
                    config(displayModeBar = F)
                
            }
            p
        })
        }
    
    plotData(as.data.frame(noZerosPlotData()))
    
    #   #-------
    # #OBSERVE
    observe(
        {
            row <- fetaPoly[which(fetaPoly$fid %in% getOnclickCoord()[[1]]),]
            
            if (!is.null(getOnclickCoord())){
                pal<-colorNumeric(palette = "Blues", domain = as.numeric(row[[paste0(input$colorFilt)]]) )
                leafletProxy('map') %>%
                    removeShape(getOnclickCoord()[[1]] ) %>%
                    addPolygons(data = row,  fillColor = pal(as.numeric(row[[paste0(input$colorFilt)]])), color = "red", weight = 3,
                                opacity = 0.9, fill = TRUE, fillOpacity = 0.2,  highlight = highlightOptions(
                                    weight = 5,
                                    color = "#666666",
                                    fillOpacity = 0.7,
                                    bringToFront = TRUE), group ="FETA",
                                   popup = paste(sep = "<br/>",
                                              paste(paste("<b>FID</b> : ", row$fid, "<br/>"),
                                                    paste("<b>Density</b> : ", round(row$n_fish,2), "<br/>"),
                                                    paste("<b>Rel. Prob. Occup</b> : ", round(row$p_occ,2), "<br/>"),
                                                    paste("<b>Movement</b> : ", round(row$hab_mov_x,0), "ha <br/>"),
                                                    paste("<b>Denning</b> : ", round(row$hab_den_y,0), "ha <br/>"),
                                                    paste("<b>Rest. Rust</b> : ", round(row$hab_rus_y, 0), "ha <br/>"),
                                                    paste("<b>Rest. CWD</b> : ", round(row$hab_cwd_y,0), "ha <br/>"),
                                                    paste("<b>Rest. Cavity</b> : ", round(row$hab_cav_y,0), "ha <br/>")))
                    )
            }
        })
    #   
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
    
    # Modal for labeling the drawn polygons
    labelModal = modalDialog(
        title = "Enter polygon label",
        textInput(inputId = "myLabel", label = "Enter a label for the drawn polygon: "),
        footer = actionButton("ok_modal",label = "Ok"))
    
    # New Feature plus show modal
    observeEvent(input$map_draw_new_feature, {
        showModal(labelModal)
    })
    # 
    # Help for Plots
    spHelpModal = modalDialog(
        title = HTML("<h2><b>Sample Types</b></h2>"),
        easyClose = TRUE,
        fade = FALSE,
        HTML("")
    )
    
    # Terms and Cond
    termsAndCondsModal = modalDialog(
        title = HTML("<h2><b>Terms and Conditions</b></h2>"),
        easyClose = TRUE,
        fade = FALSE,
        HTML("<h4><b>Conditions for the Release of Fisher Equivalent Areas Data
B.C. Ministry of Forests, Lands and Natural Resource Operations
Forest Analysis and Inventory Branch
</b></h4>
          The release of Fisher Equivalent Areas Data requires that your agency agrees
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
    
    
    
    observeEvent(input$samplePlotsHelp, {
        showModal(spHelpModal)
    })
    
    # Modal for labeling the drawn polygons
    warningModal = modalDialog(
        title = "Important message",
        "Shapefile not valid")
    
    # Modal for labeling the drawn polygons
    termsWarn = modalDialog(
        title = "Important message",
        "Please agree to the Terms and Conditions")
    
    observeEvent(input$termsMod, {
        showModal(termsAndCondsModal)
    })
    
    
    #When shapefiles are upload
    observeEvent( impShp(), {
        if(!is.null(impShp())){
            proxy <- leafletProxy('map')
            proxy %>%
                clearGroup(group='Shapefile') %>%
                addPolygons( data=impShp(), group='Shapefile',stroke = TRUE, color = "#03F", weight = 5, opacity = 0.5) %>%
                addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery" ), overlayGroups = c('TSA Boundaries','Shapefile'), options = layersControlOptions(collapsed = FALSE))%>%
                showGroup(c('Shapefile'))
            if(length(input$map_draw_all_features$features) > 0){
                proxy %>%
                    addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery" ), overlayGroups = c('TSA Boundaries','Shapefile', 'Drawn'), options = layersControlOptions(collapsed = FALSE))
            }
        }
    })
    # 
    # 
    #Once ok in the modal is pressed by the user - store this into a matrix
    observeEvent(input$ok_modal, {
        req(input$map_draw_new_feature$properties$`_leaflet_id`)
        valueModal$atTable<-rbind(valueModal$atTable, c(input$map_draw_new_feature$properties$`_leaflet_id`, input$myLabel))
        removeModal()
        proxy <- leafletProxy('map')
        proxy %>%
            addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery" ), overlayGroups = c('TSA Boundaries','Drawn'), options = layersControlOptions(collapsed = FALSE))%>%
            showGroup(c('Drawn'))
        if(length(impShp()) > 0){
            proxy %>%
                addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery" ), overlayGroups = c('TSA Boundaries','Shapefile','Drawn'), options = layersControlOptions(collapsed = FALSE))
        }
    })
    # 
    observeEvent(input$db, {
        if (input$terms) {
            #Create a CSV to download
            output$downloadSHP<<- downloadHandler(
                filename = paste("feta_data-", Sys.Date(), ".zip", sep=""),
                content = function(fname) {
                    fs <- c("feta.shp", "feta.dbf", "feta.prj", "feta.shx")
                    st_write(masterTable(), "feta.shp", driver="ESRI Shapefile", delete_layer = TRUE)
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
    
    
    observeEvent(input$fb, {
        shinyjs::disable(input$fb)
        plotData(noZerosPlotData())
        proxy <- leafletProxy('map')
        proxy %>%
            clearShapes() %>%
            clearPopups()
        if (!is.null(masterTable())){
            data<-masterTable()
            pal<-colorNumeric(palette = "Blues", domain = as.numeric(data[[paste0(input$colorFilt)]]) )
            test<-as.vector(st_bbox(data))
            proxy %>%
                fitBounds(test[1], test[2], test[3], test[4]) %>%
                addPolygons(data = data, stroke = TRUE, fillColor = pal(as.numeric(data[[paste0(input$colorFilt)]])), color= pal(as.numeric(data[[paste0(input$colorFilt)]])), weight = 2,
                            opacity = 0.9, fill = TRUE, fillOpacity = 0.2,  highlight = highlightOptions(
                                weight = 5,
                                color = "#666666",
                                fillOpacity = 0.7,
                                bringToFront = TRUE), group ="FETA",
                            #label = fetaPoly$fid,
                            popup = paste(sep = "<br/>",
                                          paste(paste("<b>FID</b> : ", data$fid, "<br/>"),
                                                paste("<b>Density</b> : ", round(data$n_fish,2), "<br/>"),
                                                paste("<b>Rel. Prob. Occup</b> : ", round(data$p_occ,2), "<br/>"),
                                                paste("<b>Movement</b> : ", round(data$hab_mov_x,0), "ha <br/>"),
                                                paste("<b>Denning</b> : ", round(data$hab_den_y,0), "ha <br/>"),
                                                paste("<b>Rest. Rust</b> : ", round(data$hab_rus_y, 0), "ha <br/>"),
                                                paste("<b>Rest. CWD</b> : ", round(data$hab_cwd_y,0), "ha <br/>"),
                                                paste("<b>Rest. Cavity</b> : ", round(data$hab_cav_y,0), "ha <br/>")))
                )
            
        }
        shinyjs::enable(input$fb)
        
    })
    
    
}
