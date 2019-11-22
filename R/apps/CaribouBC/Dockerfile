FROM rocker/shiny:3.5.1


RUN apt-get update && apt-get install libssl-dev libcurl4-openssl-dev libv8-3.14-dev -y &&\
 mkdir -p /var/lib/shiny-server/bookmarks/shiny

RUN apt-get clean

# Download and install library
RUN R -e "install.packages(c('shiny','shinydashboard', 'shinyBS', 'plotly', 'openxlsx','devtools'))"

#Install from github
RUN R -e "devtools::install_github('psolymos/CaribouBC')"

# copy the app to the image 
COPY global.R /srv/shiny-server/
COPY server.R /srv/shiny-server/
COPY ui.R /srv/shiny-server/
COPY www /srv/shiny-server/www

# make all app files readable (solves issue when dev in Windows, but building in Ubuntu)
RUN sudo chown -R shiny:shiny /srv/shiny-server/

EXPOSE 3838

CMD ["/usr/bin/shiny-server.sh"]