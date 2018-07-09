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
#-------------------------------------------------------------------------------------------------
# Load packages
#-------------------------------------------------------------------------------------------------
library(shiny)
library(shinythemes)
library(shinyWidgets)
library(leaflet.extras)
library(dplyr)
library(readr)
library(ggplot2)
library(leaflet)
library(rpostgis)
library(sf)
library(sp)
library(rgdal)
library(zoo)
library(tidyr)
library(raster)
#-------------------------------------------------------------------------------------------------
#Functions for retrieving data from the postgres server (vector, raster and tables)
#-------------------------------------------------------------------------------------------------
getSpatialQuery<-function(sql){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}
getTableQuery<-function(sql){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}
##Data objects
#----------------
#Spatial---------
##Get a connection to the postgreSQL server (local instance)
#onn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
#Get cariobu herd boundaries
herd_bound <- st_zm(getSpatialQuery("SELECT * FROM gcbp_carib_polygon WHERE herd_name <> 'NA'"))
sp_herd_bound<-sf::as_Spatial(st_transform(herd_bound, 4326))
uwr<- getSpatialQuery("SELECT approval_year, geom FROM uwr_caribou_no_harvest_20180627")
wha<- getSpatialQuery("SELECT approval_year, geom FROM wha_caribou_no_harvest_20180627")
empt<-st_sf(st_sfc(st_polygon(list(cbind(c(0,1,1,0,0),c(0,0,1,1,0)))),crs=3005))
#Get climate rasters from TYLER's ANALYSIS --- not sure if it makes sense to query this based on herd boundary buffer of 25 km or render all of it?
#boreal <- raster::stack(pgGetRast(conn, "clim_pred_boreal_1990"),pgGetRast(conn, "clim_pred_boreal_2010"),pgGetRast(conn, "clim_pred_boreal_2025"), pgGetRast(conn, "clim_pred_boreal_2055"),pgGetRast(conn, "clim_pred_boreal_2085"))
#mountain <- raster::stack(pgGetRast(conn, "clim_pred_mountain_1990"),pgGetRast(conn, "clim_pred_mountain_2010"),pgGetRast(conn, "clim_pred_mountain_2025"), pgGetRast(conn, "clim_pred_mountain_2055"),pgGetRast(conn, "clim_pred_mountain_2085"))
#northern <- raster::stack(pgGetRast(conn, "clim_pred_northern_1990"),pgGetRast(conn, "clim_pred_northern_2010"),pgGetRast(conn, "clim_pred_northern_2025"), pgGetRast(conn, "clim_pred_northern_2055"),pgGetRast(conn, "clim_pred_northern_2085"))

#----------------
#Non-Spatial 
#Get climate data
bec<-getTableQuery("SELECT * FROM public.clime_bec")
bec$year <- relevel(as.factor(bec$year), "Current")
clime<-getTableQuery("SELECT * FROM public.clim_plot_data")
#----------------
#get cached cutblock summary
cb_sumALL<-getTableQuery("SELECT * FROM public.cb_sum")
#----------------
#get cached road summary
#----------------
#get cached fire summary
fire_sum<-getTableQuery("SELECT * FROM public.fire_sum")

#-------------------------------------------------------------------------------------------------
# Define UI
ui <- fluidPage(theme = shinytheme("lumen"),  
                titlePanel("CLUS: Scenario Tool"),
                sidebarLayout(
                    sidebarPanel(
                      # add the caribou recovery logo
                      img(src = "clus-logo.png", height = 100, width = 100),
                      helpText("Click map to select a herd"),
                      #Ecotype name
                      h2(textOutput("clickEcoType")),
                      helpText("Ecotype"),
                      #Herd name
                      h2(textOutput("clickCaribou")),
                      helpText("Herd"),
                      radioButtons("queryType", label = h3("Query Options"),
                                   choices = list("Herd Boundary" = 1, "Drawn" = 2), 
                                   selected = 1)
),

# Output: Description, lineplot, and reference
mainPanel(
      leafletOutput("map"),
      downloadButton("downloadData.zip", "Save"),
      helpText("Save drawn polygons"),
      tabsetPanel(
        tabPanel("Population", tableOutput(outputId = "populationTable")),
        tabPanel("Habitat", navlistPanel(
                    "Protection",
                        tabPanel("Ungulate Winter Range", tableOutput("uwrTable")),
                        tabPanel("Wildlife Habitat Area", tableOutput("whaTable")))
                 ),
                tabPanel("Disturbance", navlistPanel(
                    "Summary", 
                        tabPanel("Fire", plotOutput(outputId = "firePlot", height = "300px")),
                        tabPanel("Cutblock", plotOutput(outputId = "cutPlot", height = "300px")),
                        tabPanel("Road", tableOutput("rdTable")),
                        tabPanel("Other Linear"),
                        tabPanel("Total Early Seral")
                    )
                  ),
                tabPanel("Climate Change", navlistPanel(
                    "BEC", 
                        tabPanel("Proportion", plotOutput(outputId = "becPlot", height = "300px")), 
                    "Variables", 
                        tabPanel("Frost Free Days", plotOutput(outputId = "ffdPlot", height = "300px")), 
                        tabPanel("Precipitation as Snow", plotOutput(outputId = "pasPlot", height = "300px")), 
                        tabPanel("Average Winter Temperature", plotOutput(outputId = "awtPlot", height = "300px")
                  )))
        )
      )
  )
)

#-----------------------
# Define server function
server <- function(input, output) {
#----------------  
# Reactive Values 
  valueModal<-reactiveValues(atTable=NULL)
  herdSelect<-reactive({ herd_bound[herd_bound$herd_name == input$map_shape_click$group, ]})
  
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
      SPDF<-SpatialPolygonsDataFrame(spPolys, data=p.df)
    }else{
      SDPF<-NULL
    }
    SPDF
  }) 
  
  caribouHerd<-reactive({
    if(input$map_shape_click$group != "Wildlife Habitat Area"){
      as.character(input$map_shape_click$group)
    }
    })
  caribouEcoType<-reactive({ 
    if(input$map_shape_click$group != "Wildlife Habitat Area"){
      as.character(herdSelect()[[12]])
    }
    })
  
  becData<-reactive({dplyr::filter (bec, herdname == caribouHerd() | herdname == caribouEcoType()[1])})
  
  climateData<-reactive({
    if(!is.null(caribouEcoType()[1])){
      eco<-dplyr::filter (clime, ecotype == caribouEcoType()[1])
      eco$group<-caribouEcoType()[1]
      herd<-dplyr::filter (clime, herdname == caribouHerd())
      herd$group<-caribouHerd()
      data<-rbind(eco, herd)
      data
    } else {
      data<-data.frame(0,0,0,0)
      colnames(data)<-c("ecotype","herdname", "year","pct")
    }
  })
  
  dist_data <- reactive({
    cb_sum<-rbind(cb_sumALL[which(cb_sumALL$herd_name ==caribouHerd()),],c(0,NA,1910),c(0,NA,2019)) #Add 40 years prior to the first cutblock date in cns_polys (~1950) and current date
    if(!is.null(cb_sum$harvestyr)){
      cb2<-tidyr::complete(cb_sum, harvestyr = full_seq(harvestyr,1), fill = list(sumarea = 0))
      cb2$Dist40<-zoo::rollapplyr(cb2$sumarea, 40, FUN = sum, fill=0)
    }else{
      cb2 <- data.frame(harvestyr = 2000:2018, Dist40 = 0)
    }
    cb2 %>% filter(harvestyr>1960)
  })
  #this should be merged in dist_data?
  fire_data <- reactive({fire_sum[which(fire_sum$herd_name == caribouHerd() & fire_sum$fire_year > 1960 ),]})
  
  #Spatial--
   whaHerdSelect<-reactive({
     ws<-wha[st_buffer(herdSelect(), dist=25000),,op=st_intersects]
     if(length(ws$geom) > 0){
       ws
     }else{
       empt
     }
   })
   uwrHerdSelect<-reactive({
     uwr<-uwr[st_buffer(herdSelect(), dist=25000),,op=st_intersects]
     if(length(uwr$geom) > 0){
       uwr
     }else{
       empt
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
      setView(-121.7476, 53.7267, 4) %>%
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
            polygonOptions = drawPolygonOptions(showArea=TRUE, shapeOptions=drawShapeOptions(fillOpacity = 0
                                                                        ,color = 'red'
                                                                        ,weight = 3, clickable = TRUE))) %>%
    addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery", "DeLorme"), overlayGroups = c('Ungulate Winter Range','Wildlife Habitat Area', 'Drawn', 'Caribou Selection'), options = layersControlOptions(collapsed = TRUE)) %>%
    hideGroup(c('Drawn', 'Ungulate Winter Range','Wildlife Habitat Area', 'Caribou Selection')) 
  })
  
# Create a shapefile to download
  output$downloadData.zip <- downloadHandler(
    file = 'shpExport.',
    content = function(file) {
      if (length(Sys.glob("shpExport.*"))>0){
        file.remove(Sys.glob("shpExport.*"))
      }
    if(!is.null(input$map_draw_all_features)){
        rgdal::writeOGR(drawnPolys(), dsn="shpExport.shp", layer="shpExport", driver="ESRI Shapefile")
    }
    zip(zipfile='shpExport.zip', files=Sys.glob("shpExport.*"))
    file.copy("shpExport.zip", file)
  })
  
  output$becPlot <- renderPlot ({
      ggplot (becData(), aes (x = herdname, y=pct, fill = bec)) + 
        facet_wrap(~year)+
        geom_bar (stat = "identity", position = "fill") +
        xlab ("Boundary") +
        ylab ("Proportion of Boundary (%)") +
        scale_fill_discrete (name = "Bec Zone") +
        theme (axis.text = element_text (size = 12), legend.title = element_blank(),
               axis.title =  element_text (size = 14, face = "bold")) 
  })  

  output$ffdPlot <- renderPlot ({
    ggplot (climateData(), aes (year, sffd, fill = group)) +  
      geom_boxplot () +
      xlab ("Year") +
      ylab ("Spring Frost Free Days (#)") +
      theme (axis.text = element_text (size = 12), legend.title = element_blank(),
             axis.title =  element_text (size = 14, face = "bold")) 
  }) 
  
  output$pasPlot <- renderPlot ({
    ggplot (climateData(), aes (x=year, y=pas, fill = group)) +  
      geom_boxplot () +
      xlab ("Year") +
      ylab ("Precipitation as Snow (mm)") +
      theme (axis.text = element_text (size = 12), legend.title = element_blank(),
             axis.title =  element_text (size = 14, face = "bold")) 
  }) 
  
  output$awtPlot <- renderPlot ({
    ggplot (climateData(), 
            aes (x=year, y=awt, fill = group)) +  
      geom_boxplot () +
      xlab ("Year") +
      ylab ("Average Winter Temperature (°C)") +
      theme (axis.text = element_text (size = 12), legend.title = element_blank(),
             axis.title =  element_text (size = 14, face = "bold")) 
  }) 
  
  output$cutPlot <- renderPlot({
    ggplot(dist_data(), aes(x =harvestyr, y=Dist40/10000))+
      geom_line()+
      xlab ("Year") +
      ylab ("Cutblock Area < 40 years (ha)") + 
      scale_x_continuous(breaks = seq(1960, 2018, by = 10))+
      expand_limits(y=0) +
      theme (axis.text = element_text (size = 12), axis.title =  element_text (size = 14, face = "bold"))
  })
  
  output$firePlot <- renderPlot({
    ggplot(fire_data(), aes(x =fire_year, y=sumarea/10000))+
      geom_bar (stat = "identity") +
      xlab ("Year") +
      ylab ("Area burnt (ha)") + 
      scale_x_continuous(breaks = seq(1960, 2018, by = 10))+
      expand_limits(y=0) +
      theme (axis.text = element_text (size = 12), axis.title =  element_text (size = 14, face = "bold"))
  })
  
  output$uwrTable<-renderTable({
      uwrtab<-st_intersection(st_set_agr(herdSelect(), "constant"), st_set_agr(uwrHerdSelect(), "constant"))
      uwrtab$area_ha<-st_area(uwrtab)/10000
    if(length(uwrtab$geom)> 0){
      uwrtabo<-as.data.frame(st_set_geometry(uwrtab, NULL))[c("approval_year", "area_ha")]
      as.factor(uwrtabo$approval_year)
      uwrtabo %>%
        group_by(approval_year) %>%
        summarize(area_in_ha = sum(area_ha))
    }
  })
  
  output$whaTable<-renderTable({
      whatab<-st_intersection(st_set_agr(herdSelect(), "constant"), st_set_agr(whaHerdSelect(), "constant"))
      whatab$area_ha<-st_area(whatab)/10000
      if(length(whatab$geom)> 0){
        whatabo<-as.data.frame(st_set_geometry(whatab, NULL))[c("approval_year", "area_ha")]
        as.factor(whatabo$approval_year)
        whatabo %>%
          group_by(approval_year) %>%
          summarize(area_in_ha = sum(area_ha))
    }
  })
  
  output$rdTable<-renderTable({
    if(input$queryType == 2){
    getTableQuery(paste0("SELECT 
                        r.road_surface, 
                        sum(ST_Length(r.wkb_geometry))/1000 as length_in_km 
                        FROM 
                        integrated_roads AS r,  
                        (SELECT * FROM gcbp_carib_polygon WHERE herd_name = '",caribouHerd(),"') AS m 
                        WHERE
                        ST_Contains(m.geom,r.wkb_geometry) 
                        GROUP BY m.herd_name, r.road_surface
                        ORDER BY m.herd_name, r.road_surface"))
    }else{
      getTableQuery(paste0("SELECT 
                        r.road_surface, 
                        sum(ST_Length(r.wkb_geometry))/1000 as length_in_km 
                        FROM 
                        integrated_roads AS r,  
                        (SELECT * FROM gcbp_carib_polygon WHERE herd_name = '",caribouHerd(),"') AS m 
                        WHERE
                        ST_Contains(m.geom,r.wkb_geometry) 
                        GROUP BY m.herd_name, r.road_surface
                        ORDER BY m.herd_name, r.road_surface"))
      
    }
  })
#-------
# OBSERVE
# Observe the click on caribou herd  
## Update the herd and ecotype label
  observeEvent(input$map_shape_click, {
    output$clickCaribou <- renderText(caribouHerd())
    output$clickEcoType <- renderText(caribouEcoType()[1])
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
                      , fillColor="brown", group = "Wildlife Habitat Area",
                      options = pathOptions(clickable = FALSE))%>%
        addPolygons(data=sf::as_Spatial(st_transform(whaHerdSelect(), 4326)), color = "blue"
                      , fillColor="darkgreen", group = "Ungulate Winter Range",
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
            polygonOptions = drawPolygonOptions(showArea=TRUE, shapeOptions=drawShapeOptions(fillOpacity = 0
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
    setView(-121.7476, 53.7267, 4) %>%
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

# Create Shiny object
shinyApp(ui = ui, server = server)
