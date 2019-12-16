library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(plotly)
library(leaflet)
library(DBI)
library(RPostgreSQL)
library(rpostgis)
library(data.table)
library(bsplus)
library(igraph)
library(sf)
library(flexdashboard)
library (shinythemes)
library (rgdal)
library (leaflet.extras)
library (tidyr)
library (dplyr)
#ignore

getTableQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='206.12.91.188', dbname = 'clus', port='5432', user='appuser', password='sHcL5w9RTn8ZN3kc')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='206.12.91.188', dbname = 'clus', port='5432', user='appuser', password='sHcL5w9RTn8ZN3kc')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}


getRasterQuery<-function(srcRaster){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='206.12.91.188', dbname = 'clus', port='5432', user='appuser', password='sHcL5w9RTn8ZN3kc')
  on.exit(dbDisconnect(conn))
  out<-pgGetRast(conn, srcRaster)
  out[is.na(out[])]<-99999
  st_transform(out, 4326)
}


availStudyAreas<-unlist(getTableQuery("Select nspname from pg_catalog.pg_namespace WHERE nspname NOT IN ('pg_toast', 'pg_temp_1', 'pg_toast_temp_1', 'pg_catalog','information_schema', 'topology', 'public')"), use.names = FALSE)
