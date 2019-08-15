FROM rocker/shiny:3.5.1

RUN apt-get update && apt-get install libgdal-dev libpq-dev libudunits2-dev libproj-dev libssl-dev libcurl4-openssl-dev libv8-3.14-dev -y &&\
  mkdir -p /var/lib/shiny-server/bookmarks/shiny

# Download and install library
RUN R -e "install.packages(c('shiny','shinydashboard', 'shinyjs', 'V8', 'shinythemes', 
'shinyWidgets','leaflet', 'leaflet.extras', 'dplyr', 'ggplot2', 'RPostgreSQL', 'sf', 'zoo','tidyr','plotly','raster','lobstr'))"

# copy the app to the image 
COPY server.R /srv/shiny-server/
COPY ui.R /srv/shiny-server/
COPY www /srv/shiny-server/www

# make all app files readable (solves issue when dev in Windows, but building in Ubuntu)
RUN sudo chown -R shiny:shiny /srv/shiny-server/

EXPOSE 8787

CMD ["/usr/bin/shiny-server.sh"]