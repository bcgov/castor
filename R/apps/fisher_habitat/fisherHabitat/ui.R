#-------------------------------------------------------------------------------------------------
# Define UI
navbarPage("FETA", id ="nav",
           tabPanel("Interactive map",
                    div(class="outer",
                        tags$head(
                          # Include our custom CSS
                          #includeCSS("styles.css"),
                          #includeScript("gomap.js")
                        ),
                        
           leafletOutput("map", height = 800),
                              
           absolutePanel(id = "controls", class = "panel panel-default", draggable = T, top = 60, left = "auto", right = 20, bottom = "auto",
                         fixed = T, width = 330, height = "auto",
                                
                         h2("Controls"),
                         
                         fluidRow(
                           selectInput("colorFilt",
                                       "Select Attribute",
                                       choices = c("abund","n_fish","p_occ", "hab_den", "hab_mov", "hab_rus", "hab_cwd", "hab_cav")
                           ),
                           selectizeInput(
                             "tsa","Select by TSA",
                             choices = c("Clear All","Select All", tsaBnds),
                             selected = tsaBnds,
                             multiple = TRUE, 
                             options = list('plugins' = list('remove_button'), placeholder = 'Select a Timber Supply Area', 'persist' = F)
                            )
                         ),
                         conditionalPanel("input.colorFilt == 'hab_den'",
                                          # Only prompt for abundance
                                          sliderInput("threshold_hab_den", "Denning Habitat (ha)", 0,0.5, 0)
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
),

tabPanel("Data explorer",
    tags$footer(actionLink("contactUs", "Contact Us ", onclick = "window.open('https://www.bcfisherhabitat.ca/contact/')" ), 
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
)
