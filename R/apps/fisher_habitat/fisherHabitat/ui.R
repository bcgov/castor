#-------------------------------------------------------------------------------------------------
# Define UI
ui <- tagList(dashboardPage(
    dashboardHeader(
        title = "FETA Scenario"),
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
                              tabPanel("Fisher Habtiat Quality" , 
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
            boxPlus(width=NULL,
                    title = "Filter Data ",  
                    closable = FALSE, 
                    status = "primary", 
                    solidHeader = TRUE, 
                    collapsible = FALSE,
                    collapsed = FALSE,
                    actionButton("fb", "Filter", width = "100%"),
                    radioButtons("shapeFilt",
                                 "Select Shape Filter",
                                 choices = c("None","Drawn Polygon", "Shapefile", "Both"),
                                 selected = "None",
                                 inline = FALSE),
                    selectizeInput(
                        "tsa",
                        "Select TSA Filter",
                        choices = c("Clear All","Select All", tsaBnds),
                        selected = tsaBnds,
                        multiple = TRUE, 
                        options = list('plugins' = list('remove_button'), placeholder = 'Select a Timber Supply Area', 'persist' = TRUE))
                  
                   
            ),
            
            boxPlus( 
                title = "Export Data as a CSV ",  
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
))), downloadLink("downloadCSV",label="")
)
