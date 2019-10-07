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


getTableQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='', dbname = '', port='5432', user='', password='')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='', dbname = '', port='5432', user='', password='')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}


getRasterQuery<-function(srcRaster){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='', dbname = '', port='5432', user='', password='')
  on.exit(dbDisconnect(conn))
  pgGetRast(conn, srcRaster)
}


availStudyAreas<-unlist(getTableQuery("Select nspname from pg_catalog.pg_namespace WHERE nspname NOT IN ('pg_toast', 'pg_temp_1', 'pg_toast_temp_1', 'pg_catalog','information_schema', 'topology', 'public')"), use.names = FALSE)
