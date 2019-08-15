# Install R version 3.5
FROM r-base:3.5.1

# Install Ubuntu packages
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev/unstable \
    libxt-dev \
    libssl-dev \
    libgeos-dev \
    libudunits2-dev \
    libgdal-dev \
    libpq-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
    liblwgeom-dev \
    libprotobuf-dev \
    libfftw3-dev 

# PROJ:
ENV PROJ_VERSION=5.0.0
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN wget http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz \
  && tar zxf proj-*tar.gz \
  && cd proj-${PROJ_VERSION} \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && ldconfig \
  && rm -rf proj*

# install proj-datumgrid:
RUN cd /usr/local/share/proj \
  && wget http://download.osgeo.org/proj/proj-datumgrid-1.8.zip \
  && unzip -o proj-datumgrid*zip \
  && rm proj-datumgrid*zip

#Dowload and Install GDal
ENV GDAL_VERSION=2.4.0
ENV GDAL_VERSION_NAME=2.4.0
COPY --from=rocker/gdal /gdal-${GDAL_VERSION} /gdal-${GDAL_VERSION}
RUN cd gdal-${GDAL_VERSION} \
  && make install \
  && cd .. \
  && ldconfig \
  && rm -rf gdal*


# GEOS:
#ENV GEOS_VERSION 3.6.2
ENV GEOS_VERSION 3.7.2
#
RUN wget http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 \
  && bzip2 -d geos-*bz2 \
  && tar xf geos*tar \
  && cd geos* \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && ldconfig


# Download and install ShinyServer (latest version)
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

# Install R packages that are required
# TODO: add further package if you need!
RUN R -e "install.packages(c('shiny', 'shinythemes', 'shinyWidgets','leaflet', 'leaflet.extras', 'dplyr', 'ggplot2', 'RPostgreSQL', 'sf', 'zoo','tidyr','plotly','raster','lobstr'), repos='http://cran.rstudio.com/')"

# Copy configuration files into the Docker image
#COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf
COPY www /srv/shiny-server/
COPY server.R /srv/shiny-server/
COPY ui.R /srv/shiny-server/

RUN chown shiny:shiny /var/lib/shiny-server

# Make the ShinyApp available at port 8787
EXPOSE 8787

# Copy further configuration files into the Docker image
# COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]