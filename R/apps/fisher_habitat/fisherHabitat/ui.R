#-------------------------------------------------------------------------------------------------
# Define UI
ui <- tagList(dashboardPage(
    dashboardHeader(
        title = "FETA Mapper"),
    #sidebar content
    dashboardSidebar(disable = TRUE 
    ),
    
    #body content
    dashboardBody(
        tags$head(tags$style(HTML('
      .content-wrapper  {
                              font-weight: normal;
                              font-size: 14px;
                              }'))),
        
        fluidRow(  tags$head(
            tags$style(HTML('#Help{color:black}'))
        ),
        column(width = 9, box(width=NULL,
                              leafletOutput("map", height = 670)),
                              boxPlus(height = 390, width=NULL,
                              tabBox(width = NULL, id = "tabset1", height = "0",
                              tabPanel("Fisher Density" , 
                                       plotlyOutput('fisherDensity', height = "300px")
                              ),
                              tabPanel("Rel. Prob. Occupancy" , 
                                       plotlyOutput('fisherQuality', height = "300px")
                              )
               ))
        ),
        
        column(
            tags$head(tags$style(HTML("#tsa ~ .selectize-control 
                                          .selectize-input {
                                         max-height: 90px;
                                         overflow-y: auto;}
                                         .selectize-dropdown-content {
                                          max-height: 90px;
                                          overflow-y: auto;}
                                         "))),
            width = 3,height = 400,
            
            boxPlus( 
              title = "Change Colour",  
              closable = FALSE, 
              status = "primary", 
              solidHeader = TRUE, 
              collapsible = FALSE,
              collapsed = FALSE,
              width = NULL,
              radioButtons("colorFilt",
                           "Select Attribute",
                           choices = c("n_fish","p_occ", "hab_den_x", "hab_mov_y", "hab_rus_y", "hab_cwd_y", "hab_cav_y"),
                           selected = "n_fish",
                           inline = FALSE)
            ),
            boxPlus(width=NULL,
                    title = "Filter Data ",  
                    closable = FALSE, 
                    status = "primary", 
                    solidHeader = TRUE, 
                    collapsible = FALSE,
                    collapsed = FALSE,
                    selectizeInput(
                      "tsa",
                      "Select by TSA",
                      choices = c("Clear All","Select All", tsaBnds),
                      selected = tsaBnds,
                      multiple = TRUE, 
                      options = list('plugins' = list('remove_button'), placeholder = 'Select a Timber Supply Area', 'persist' = TRUE)),
                    radioButtons(
                      "shapeFilt",
                      "Select by Shape",
                      choices = c("None","Drawn Polygon", "Shapefile", "Both"),
                      selected = "None",
                      inline = FALSE),
                    actionButton("fb", "Filter", width = "100%")
            ),
          
            boxPlus( 
                title = "Export Data",  
                closable = FALSE, 
                status = "primary", 
                solidHeader = TRUE, 
                collapsible = FALSE,
                collapsed = FALSE,
                width = NULL,
                checkboxInput("terms",
                              label = actionLink("termsMod","I Agree to Terms and Conditions")),
                actionButton("db", "Export", width="100%")
            )
            
        )
        )
    )
),  
tags$footer(actionLink("contactUs", "Contact Us ", onclick = "window.open('https://www2.gov.bc.ca/gov/content/industry/forestry/managing-our-forest-resources/forest-inventory/ground-sample-inventories')" ), 
            align = "center",
            style = "
                bottom:0;
                width:100%;
                height:40px;   /* Height of the footer */
                color: white;
                padding:10px;
                background-color: #367fa9;
                z-index: 2000;
                font-family:sans-serif;"),
tags$footer(
    tags$style(HTML('#contactUs{color:white}'))
),
tags$head(tags$script(HTML('
                           Shiny.addCustomMessageHandler("jsCode",
                           function(message) {
                           eval(message.value);
                           });'
))), downloadLink("downloadSHP",label="")
)
