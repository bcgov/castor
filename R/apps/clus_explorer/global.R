library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyjs)
library(shinyBS)
library(shinyWidgets)
library(shinyFiles)
library(shinyauthr)
library(plotly)
library(RSQLite)
library(leaflet)
library(RPostgreSQL)
library(data.table)
library(bsplus)
library(dplyr)
library(glue)

user_base <- data.frame(
  user = c("user1", "user2"),
  password = c("pass1", "pass2"), 
  permissions = c("admin", "standard"),
  name = c("User One", "User Two"),
  stringsAsFactors = FALSE,
  row.names = NULL
)

getTableQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='', dbname = '', port='5432', user='', password='')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}


#map <- leaflet() %>% addTiles()
availStudyAreas <- unlist(getTableQuery("Select nspname from pg_catalog.pg_namespace WHERE nspname NOT IN ('pg_toast', 'pg_temp_1', 'pg_toast_temp_1', 'pg_catalog','information_schema', 'topology', 'public')"), use.names = FALSE)
