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
library(raster)
library(shiny)
library(shinythemes)
library(shinyWidgets)

#-------------------------------------------------------------------------------------------------
#Dataabse prep
#-------------------------------------------------------------------------------------------------
dbname = 'clus'
host='DC052586'
port='5432'
user='app_user'
password='clus'
##Get a connection to the postgreSQL server (local instance)
conn<-dbConnect(dbDriver("PostgreSQL"), host=host, dbname = dbname, port=port ,user=user ,password=password)
##Data objects
#----------------
#Get cariobu herd boundaries
name=c("public","gcbp_carib_polygon")
geom = "geom"
herd_bound <- spTransform(pgGetGeom(conn, name=name,  geom = geom), CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
####Remove NA's
herd_bound <- herd_bound[which(herd_bound@data$herd_name != "NA"), ]
#name=c("public","20180627_uwr_caribou_no_harvest")
#uwrNH <- spTransform(pgGetGeom(conn, name=name,  geom = geom), CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
#----------------
#Get climate data
bec<-dbGetQuery(conn,"SELECT * FROM public.clime_bec")
bec$year <- relevel(as.factor(bec$year), "Current")
clime<-dbGetQuery(conn,"SELECT * FROM public.clim_plot_data")
#Get climate rasters from TYLER's ANALYSIS
boreal <- raster::stack(pgGetRast(conn, "clim_pred_boreal_1990"),pgGetRast(conn, "clim_pred_boreal_2010"),pgGetRast(conn, "clim_pred_boreal_2025"), pgGetRast(conn, "clim_pred_boreal_2055"),pgGetRast(conn, "clim_pred_boreal_2085"))
#mountain <- raster::stack(pgGetRast(conn, "clim_pred_mountain_1990"),pgGetRast(conn, "clim_pred_mountain_2010"),pgGetRast(conn, "clim_pred_mountain_2025"), pgGetRast(conn, "clim_pred_mountain_2055"),pgGetRast(conn, "clim_pred_mountain_2085"))
#northern <- raster::stack(pgGetRast(conn, "clim_pred_northern_1990"),pgGetRast(conn, "clim_pred_northern_2010"),pgGetRast(conn, "clim_pred_northern_2025"), pgGetRast(conn, "clim_pred_northern_2055"),pgGetRast(conn, "clim_pred_northern_2085"))
#----------------
#get cached cutblock summary
cb_sumALL<-dbGetQuery(conn,"SELECT * FROM public.cb_sum")
#----------------
#get cached road summary
#----------------
#get cached fire summary
dbDisconnect(conn)

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
                      
                      # Select year range to be used
                      sliderTextInput (inputId = "sliderDate",
                                       label = "",
                                       choices = c ("current", 2025, 2055, 2085),
                                       selected = "current",
                                       grid = TRUE
                      ),
                      helpText("Select year of interest using the slider"),
                      downloadButton("downloadData.zip", "Save"),
                      helpText("Save drawn polygons")
),

# Output: Description, lineplot, and reference
mainPanel(
      leafletOutput("map"),
      textOutput(outputId = "desc"),
      tags$a(href = "https://github.com/bcgov/clus", "Source: clus repo", target = "_blank"),
      tabsetPanel(
        tabPanel("Population", tableOutput(outputId = "populationTable")),
        tabPanel("Habitat", navlistPanel(
                    "Protection",
                        tabPanel("Ungulate Winter Range"),
                        tabPanel("Wildlife Habitat Area"))
                 ),
                tabPanel("Disturbance", navlistPanel(
                    "Herd Boundary", 
                        tabPanel("Fire"),
                        tabPanel("Cutblock", plotOutput(outputId = "distPlot", height = "300px")),
                        tabPanel("Road"),
                        tabPanel("Other Linear"),
                        tabPanel("Total"),
                    "Drawn",
                        tabPanel("Total")
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
  caribouHerd<-reactive({as.character(input$map_shape_click$group)})
  caribouEcoType<-reactive({ herd_bound@data[which(herd_bound@data$herd_name == input$map_shape_click$group), ][[12]]})
  
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
  
  becData<-reactive({
    data<-dplyr::filter (bec, herdname == caribouHerd() | herdname == caribouEcoType()[1])
    data
  })
  
  herdSelect<-reactive({
    herd_bound[which(herd_bound@data$herd_name == input$map_shape_click$group), ]
  }) 

  dist_data <- reactive({
    req(input$map_shape_click)
    cb_sum<-rbind(cb_sumALL[which(cb_sumALL$herd_name ==caribouHerd()),],c(0,NA,1910)) #Add 40 years prior to the first cutblock date in cns_polys (~1950)
    if(!is.null(cb_sum$harvestyr)){
      cb2<-tidyr::complete(cb_sum, harvestyr = full_seq(harvestyr,1), fill = list(sumarea = 0))
      cb2$Dist40<-zoo::rollapplyr(cb2$sumarea, 40, FUN = sum, fill=0)
    }else{
      cb2 <- data.frame(harvestyr = 2000:2018, Dist40 = 0)
    }
    cb2 %>% filter(harvestyr>1960)
  })
#--------  
# Outputs 
## Create scatterplot object the plotOutput function is expecting
  output$distPlot <- renderPlot({
    ggplot(dist_data(), aes(x =harvestyr, y=Dist40))+
      geom_line()+
      xlab ("Year") +
      ylab ("Cutblock Area < 40 years (ha)") + 
      scale_x_continuous(breaks = seq(1960, 2018, by = 10))+
      expand_limits(y=0) +
      theme (axis.text = element_text (size = 12), axis.title =  element_text (size = 14, face = "bold"))
  })
  
## set the pallet
  pal <- colorFactor(palette = c("lightblue", "darkblue", "red"),  herd_bound$risk_stat)
## render the leaflet map  
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
      #addRasterImage(raster(mountain,cs_date()), project =TRUE, group = 'Caribou Selection') %>%
      #addRasterImage(raster(boreal,cs_date()), project =TRUE, opacity = 0.7,  group = 'Caribou Selection') %>%
      #addRasterImage(raster(northern,cs_date()), project =TRUE, group = 'Caribou Selection') %>%
      addResetMapButton() %>%
      addLegend("bottomright", pal = pal, values = c("Red/Threatened","Blue/Special","Blue/Threatened"), title = "Risk Status", opacity = 1) %>%
      addDrawToolbar(
            editOptions = editToolbarOptions(),
            targetGroup='Drawn Zone',
            circleOptions = FALSE,
            circleMarkerOptions = FALSE,
            rectangleOptions = FALSE,
            markerOptions = FALSE,
            singleFeature = F,
            polygonOptions = drawPolygonOptions(showArea=TRUE, shapeOptions=drawShapeOptions(fillOpacity = 0
                                                                        ,color = 'red'
                                                                       ,weight = 3, clickable = TRUE))) %>%
    addLayersControl(baseGroups = c("OpenStreetMap","WorldImagery"), overlayGroups = c('UWR','WHA', 'Drawn Zone', 'Caribou Selection'), options = layersControlOptions(collapsed = TRUE)) %>%
    hideGroup(c('UWR','WHA', 'Caribou Selection')) 

  })
 
# Create a shapefile to download
  output$downloadData.zip <- downloadHandler(
    file = 'shpExport.',
    content = function(file) {
      if (length(Sys.glob("shpExport.*"))>0){
        file.remove(Sys.glob("shpExport.*"))
      }
      #get the lat long coordinates
    req(valueModal)
    if(!is.null(input$map_draw_all_features)){
        f<-input$map_draw_all_features
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
        plot(SPDF)
        rgdal::writeOGR(SPDF, dsn="shpExport.shp", layer="shpExport", driver="ESRI Shapefile")
    }
    zip(zipfile='shpExport.zip', files=Sys.glob("shpExport.*"))
    file.copy("shpExport.zip", file)
  })
  
  output$becPlot <- renderPlot ({
      ggplot (becData(), aes (x = herdname, y=pct, fill = bec)) + 
        facet_wrap(~year)+
        geom_bar (stat = "identity", position = "fill") +
        xlab ("Boundary") +
        ylab ("Proportion of Area (%)") +
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
  
  
#-------
# observe  
## Zoom to caribou herd being cliked
  observe({
    if(is.null(input$map_shape_click))
      return()
    leafletProxy("map") %>%
      clearGroup(group = input$map_shape_click$group) %>%
      setView(lng = input$map_shape_click$lng,lat = input$map_shape_click$lat, zoom = 7.4) %>%
      addPolygons(data=herdSelect() , fillOpacity = 0.1, color = "red", weight =4,labelOptions = labelOptions(noHide = FALSE, textOnly = TRUE, opacity = 0.5 , textsize='13px')) %>%
      addRasterImage(raster(boreal,1), project =TRUE, opacity = 0.7,  group = 'Caribou Selection')
    })
  
# Observe the click on caribou herd  
  observeEvent(input$map_shape_click, {
    output$clickCaribou <- renderText(caribouHerd())
    output$clickEcoType <- renderText(caribouEcoType()[1])
  })
 
# Modal for labeling the drawn polygons
  labelModal = modalDialog(
    title = "Enter polygon label",
    textInput(inputId = "myLabel", label = "Enter a string: "),
    footer = actionButton("ok_modal",label = "Ok"))
# New Feature plus show modal
  observeEvent(input$map_draw_new_feature, {
    #print("New Feature")
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
