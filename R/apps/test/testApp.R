#-------------------------------------------------------------------------------------------------
# Copyright 2018 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#-------------------------------------------------------------------------------------------------

# Load packages
library(shiny)
library(shinythemes)
library(dplyr)
library(readr)
library(ggplot2)
library(leaflet)
library(rpostgis)
library(sf)
library(sp)
library(leaflet.extras)
library(rgdal)
library(zoo)
library(tidyr)

# Load data
#str(trend_data)
trend_description <- "This is a test"

#-------------------------------------------------------------------------------------------------
#Dataabse prep
#-------------------------------------------------------------------------------------------------
dbname = 'postgres'
host='DC052586'
port='5432'
user='postgres'
password='postgres'
name=c("public","cns_cut_bl_polygon")
##Get a connection to the postgreSQL server (local instance)
conn<-dbConnect(dbDriver("PostgreSQL"), host=host, dbname = dbname, port=port ,user=user ,password=password)

##Data objects
###Get disturbance summary
###Get shapefile
name=c("public","gcbp_carib_polygon")
geom = "geom"
herd_bound <- spTransform(pgGetGeom(conn, name=name,  geom = geom), CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
####Remove NA's
herd_bound <- herd_bound[which(herd_bound@data$herd_name != "NA"), ]
#Get climate rasters
boreal <- raster::stack(pgGetRast(conn, "clim_pred_boreal_1990"),pgGetRast(conn, "clim_pred_boreal_2010"),pgGetRast(conn, "clim_pred_boreal_2025"), pgGetRast(conn, "clim_pred_boreal_2055"),pgGetRast(conn, "clim_pred_boreal_2085"))
mountain <- raster::stack(pgGetRast(conn, "clim_pred_boreal_1990"),pgGetRast(conn, "clim_pred_boreal_2010"),pgGetRast(conn, "clim_pred_boreal_2025"), pgGetRast(conn, "clim_pred_boreal_2055"),pgGetRast(conn, "clim_pred_boreal_2085"))
northern <- raster::stack(pgGetRast(conn, "clim_pred_boreal_1990"),pgGetRast(conn, "clim_pred_boreal_2010"),pgGetRast(conn, "clim_pred_boreal_2025"), pgGetRast(conn, "clim_pred_boreal_2055"),pgGetRast(conn, "clim_pred_boreal_2085"))
###close connection
dbDisconnect(conn)
#-------------------------------------------------------------------------------------------------

# Define UI
ui <- fluidPage(theme = shinytheme("lumen"),
                titlePanel("Caribou and Land Use Simulator: scenario builder"),
                sidebarLayout(
                    sidebarPanel(
                      # add the caribou recovery logo
                      img(src = "clus-logo.png", height = 100, width = 100),
                      helpText("Click map to select a herd"),
                      h3(textOutput("clickCaribou")),
                      
                      # Select year range to be used
                      sliderInput("sliderDate", label = strong("Year"), min = 2000, 
                                  max = 2085, value = 2010, step = 1, animate = animationOptions(interval = 1)
                                  ),
                      downloadButton("downloadData", "Save"),
                      helpText("Save the drawn caribou zone")

),

# Output: Description, lineplot, and reference
mainPanel(
      leafletOutput("map"),
      textOutput(outputId = "desc"),
      tags$a(href = "https://github.com/bcgov/clus", "Source: clus repo", target = "_blank"),
      tabsetPanel(
        tabPanel("Population"),
        tabPanel("Habitat"),
        tabPanel("Climate", plotOutput(outputId = "climateHabitat", height = "300px")),
        tabPanel("Disturbance", plotOutput(outputId = "distplot", height = "300px"))
        
        )
      )
  )
)

# Define server function
server <- function(input, output) {
  
  caribouHerd<-reactive(as.character(input$map_shape_click$group))
  output$climateHabitat<-renderPlot({
    spplot(raster(boreal,1))
  })
  
  # Subset data
  dist_data <- reactive({
    req(input$map_shape_click)
    conn<-dbConnect(dbDriver("PostgreSQL"),dbname=dbname, host=host ,port=port ,user=user ,password=password)
    sql.str = paste0(
      "SELECT SUM(t.areaha) AS sumarea, t.herd_name ,t.harvestyr
    FROM (
      SELECT b.areaha, b.harvestyr, y.herd_name
      FROM public.cns_cut_bl_polygon b, (SELECT * FROM public.gcbp_carib_polygon WHERE herd_name = '",caribouHerd(), "') y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom))t 
      GROUP BY harvestyr, herd_name
      ORDER BY  herd_name, harvestyr")
    cb_sum<-dbGetQuery(conn, sql.str)
    dbDisconnect(conn)
    cb_sum<-rbind(cb_sum,c(0,NA,1910)) #Add 40 years prior to the first cutblock date in cns_polys (~1950)
    if(!is.null(cb_sum$harvestyr)){
      cb2<-tidyr::complete(cb_sum, harvestyr = full_seq(harvestyr,1), fill = list(sumarea = 0))
      cb2$Dist40<-zoo::rollapplyr(cb2$sumarea, 40, FUN = sum, fill=0)
    }else{
      cb2 <- data.frame(harvestyr = 2000:2018, Dist40 = 0)
    }
    cb2 %>% filter(harvestyr>1960)
  })
  

  # Create scatterplot object the plotOutput function is expecting
  output$distplot <- renderPlot({
    ggplot(dist_data(), aes(x =harvestyr, y=Dist40))+
      geom_line()+
      xlab ("Year") +
      ylab ("Cutblock Area < 40 years (ha)") + 
      scale_x_continuous(breaks = seq(1960, 2018, by = 5))+
      expand_limits(y=0) +
      theme_bw () +
      theme (axis.text = element_text (size = 12),
             axis.title =  element_text (size = 14, face = "bold"))

  })
  
 
  
  #set the pallet
  pal <- colorFactor(palette = c("lightblue", "darkblue", "red"),  herd_bound$risk_stat)
  
  output$map = renderLeaflet({ 
      leaflet(herd_bound, options = leafletOptions(doubleClickZoom= TRUE)) %>% 
      setView(-121.7476, 53.7267, 4) %>%
      addTiles() %>% 
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
      addProviderTiles("Esri.WorldImagery", group ="WorldImagery" ) %>%
      addPolygons(data=herd_bound,  fillColor = ~pal(risk_stat), 
                  weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                  layerId = ~gid,
                  group= ~herd_name,
                  smoothFactor = 0.5,
                   label = ~herd_name,
                   labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , color= "black", textsize='13px'),
                  highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.3, bringToFront = TRUE)) %>%
      addScaleBar(position = "bottomright") %>%
      addResetMapButton() %>%
      addLegend("bottomright", pal = pal, values = c("Red/Threatened","Blue/Special","Blue/Threatened"), title = "Risk Status", opacity = 1) %>%
      addDrawToolbar(
            editOptions = editToolbarOptions(),
            targetGroup='Caribou Zone',
            circleOptions = FALSE,
            circleMarkerOptions = FALSE,
            rectangleOptions = FALSE,
            markerOptions = FALSE,
            polygonOptions = drawPolygonOptions(showArea=TRUE, shapeOptions=drawShapeOptions(fillOpacity = 0
                                                                        ,color = 'red'
                                                                       ,weight = 3, clickable = TRUE)))%>%
    addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery"), overlayGroups = c('UWR','WHA', 'Caribou Zone', 'Caribou Selection'), options = layersControlOptions(collapsed = TRUE)) 
  })
  

  observe({
    click <- input$map_shape_click
    if(is.null(click))
      return()
    mapSelect <- herd_bound[which(herd_bound@data$herd_name == click$group), ] 
    
    leafletProxy("map") %>%
      clearShapes() %>%
      addPolygons(data=herd_bound,  fillColor = ~pal(risk_stat), 
                    weight = 1,opacity = 1,color = "white", dashArray = "1", fillOpacity = 0.7,
                   layerId = ~gid,
                   group= ~herd_name,
                   label = ~herd_name,
                   labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , textsize='13px'),
                  smoothFactor = 0.5,
                   highlight = highlightOptions(weight = 4, color = "white", dashArray = "", fillOpacity = 0.1, bringToFront = TRUE)) %>%
      clearGroup(group = input$map_shape_click$group) %>%
      setView(lng = click$lng,lat = click$lat, zoom = 7.4) %>%
      addPolygons(data=mapSelect , fillOpacity = 0.1, color = "red", weight =4,labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , textsize='13px'))
    })
  
  observeEvent(input$map_shape_click, {
    output$clickCaribou <- renderText(caribouHerd())
  }) 
  

# observeEvent(input$map_draw_stop, {
#     req(input$map_draw_stop)
#     print(input$map_draw_new_feature)
#     feature_type <- input$map_draw_new_feature$properties$feature_type
#     #get the coordinates of the polygon
#     polygon_coordinates <- input$map_draw_new_feature$geometry$coordinates[[1]]
#     #transform them to an sp Polygon
#     drawn_polygon <- Polygon(do.call(rbind,lapply(polygon_coordinates,function(x){c(x[[1]][1],x[[2]][1])})))
#     sp <- SpatialPolygons(list(Polygons(list(drawn_polygon),"drawn_polygon")))
#     plot (sp)
#   })
  latlongs<-reactiveValues()   #temporary to hold coords
  latlongs$df2 <- data.frame(Longitude = numeric(0), Latitude = numeric(0))
  
  value<-reactiveValues()
  value$drawnPoly<-SpatialPolygonsDataFrame(SpatialPolygons(list()), data=data.frame (notes=character(0), stringsAsFactors = F))
  
  observeEvent(input$map_draw_new_feature, {
    
    #get the lat long coordinates
    coor<-unlist(input$map_draw_new_feature$geometry$coordinates)
    Longitude<-coor[seq(1,length(coor), 2)] 
    Latitude<-coor[seq(2,length(coor), 2)]
    isolate(latlongs$df2<-rbind(latlongs$df2, cbind(Longitude, Latitude)))
    
    #create a polygon based on the lat, long
    poly<-Polygon(cbind(latlongs$df2$Longitude, latlongs$df2$Latitude))
    
    # polys<-Polygons(list(poly), ID=input$map_draw_new_feature$properties$`_leaflet_id`)
    # spPolys<-SpatialPolygons(list(polys))
    # print(input$map_draw_new_feature$properties$`_leaflet_id`)
    # #plot(spPolys)
    # value$drawnPoly<-rbind(value$drawnPoly,SpatialPolygonsDataFrame(spPolys, data=data.frame(notes=NA, row.names=row.names(spPolys))))
    # print(value$drawnPoly)
    # #plot(value$drawnPoly)
  })
  
  # observeEvent(input$map_draw_edited_features, {
  #   f <- input$map_draw_edited_features
  #   coordy<-lapply(f$features, function(x){unlist(x$geometry$coordinates)})
  #   Longitudes<-lapply(coordy, function(coor) {coor[seq(1,length(coor), 2)] })
  #   Latitudes<-lapply(coordy, function(coor) { coor[seq(2,length(coor), 2)] })
  #   
  #   polys<-list()
  #   for (i in 1:length(Longitudes)){polys[[i]]<- Polygons(
  #     list(Polygon(cbind(Longitudes[[i]], Latitudes[[i]]))), ID=f$features[[i]]$properties$layerId
  #   )}
  #   spPolys<-SpatialPolygons(polys)
  #   SPDF<-SpatialPolygonsDataFrame(spPolys, 
  #                                  data=data.frame(notes=value$drawnPoly$notes[row.names(value$drawnPoly) %in% row.names(spPolys)], row.names=row.names(spPolys)))
  #   value$drawnPoly<-value$drawnPoly[!row.names(value$drawnPoly) %in% row.names(SPDF),]
  #   value$drawnPoly<-rbind(value$drawnPoly, SPDF)
  #   
  # })
  # 
  # observeEvent(input$map_draw_deleted_features, { 
  #   f <- input$map_draw_deleted_features
  #   ids<-lapply(f$features, function(x){unlist(x$properties$layerId)})
  #   value$drawnPoly<-value$drawnPoly[!row.names(value$drawnPoly) %in% ids ,]
  # })  
  
  output$downloadData <- downloadHandler(
    filename = 'shpExport.',
    content = function(file) {
      if (length(Sys.glob("shpExport.*"))>0){
        file.remove(Sys.glob("shpExport.*"))
      }
      
      proj4string(value$drawnPoly)<-"+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
      rgdal::writeOGR(value$drawnPoly, dsn="shpExport.shp", layer="shpExport", driver="ESRI Shapefile")
      zip(zipfile='shpExport.zip', files=Sys.glob("shpExport.*"))
      file.copy("shpExport.zip", file)
      if (length(Sys.glob("shpExport.*"))>0){
        file.remove(Sys.glob("shpExport.*"))
      }
    }
  
    )

}

# Create Shiny object
shinyApp(ui = ui, server = server)
