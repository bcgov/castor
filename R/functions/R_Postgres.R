### additional functions
library(sf)
library (terra)
library(raster)
library(RPostgreSQL)
library(sqldf)
library(DBI)
library(sp)
library(rpostgis)

#Uses keyring to set the credentials

#Simple database connectivity functions
getSpatialQuery<-function(sql, conn = NULL){
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }else{
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=conn["host"], dbname = conn["dbname"], port=conn["port"] ,user=conn["user"],password= conn["pass"])
  }
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

getTableQuery<-function(sql, conn = NULL){
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }else{
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=conn["host"], dbname = conn["dbname"], port=conn["port"] ,user=conn["user"],password= conn["pass"])
  }
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

#R functions for Accessing PostGIS FAIB Raster functions
#This assumes the functions are loaded in db.
# See https://github.com/bcgov/clus/blob/master/SQL/Raster/Documentation/FAIB_PostGIS_Raster_Function_Documentation.md
#Mike Fowler
#Spatial Data Analyst
#October 25, 2018

#--Assumes that coords is a single poly, represented as matrix (num) with coord values see Line 152ish
GetPolygonText<-function(coords){
  txtPoly = 'POLYGON(('
  for (row in seq(1, length(coords), 2)){
    if (row == length(coords) - 1){
      txtPoly = paste(txtPoly, coords[row], coords[row+1])
    } else {
      txtPoly = paste(txtPoly, coords[row], coords[row+1])
      txtPoly = paste(txtPoly, ', ')
    }
  }  
  txtPoly = paste(txtPoly, '))') 
}


RASTER_CLIP2 <- function(tmpRast, srcRaster, clipper, geom, where_clause, conn = NULL){
  #tmpRast = 'FAIB_RCL_TEMPRAST_'
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }else{
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=conn["host"], dbname = conn["dbname"], port=conn["port"] ,user=conn["user"],password= conn["pass"])
  }
      #--Build the query string to execute the function to generate temporary Raster
    qry = sprintf("select public.faib_raster_clip2('%s', '%s', '%s', '%s', '%s');", tmpRast, srcRaster, clipper, geom, where_clause)
    #--Execute the query
    r<-dbGetQuery(conn, qry)

  
  #--Get Raster Layer object of Raster result
  rout <- suppressMessages(pgGetRast2(conn, tolower(tmpRast), 'rast', 1, returnclass = "raster"))
  #--Drop the temporary Raster from the DB
  qry = paste('DROP TABLE IF EXISTS', tmpRast, ' CASCADE;')
  dbGetQuery(conn, qry)
  #--Disconnect the DB
  on.exit(dbDisconnect(conn))
  
  #--Return the Raster Layer
  return(rout)           
}


dbTableNameFix <- function(conn=NULL, t.nm, as.identifier = TRUE) {
  ## case of no schema provided
  if (length(t.nm) == 1 && !is.null(conn) && !inherits(conn, what = "AnsiConnection")) {
    schemalist<-dbGetQuery(conn,"select nspname as s from pg_catalog.pg_namespace;")$s
    user<-dbGetQuery(conn,"SELECT current_user as user;")$user
    schema<-dbGetQuery(conn,"SHOW search_path;")$search_path
    schema<-gsub(" ","",unlist(strsplit(schema,",",fixed=TRUE)),fixed=TRUE)
    # use user schema if available
    if ("\"$user\"" == schema[1] && user %in% schemalist) {
      sch<-user
    } else {
      sch<-schema[!schema=="\"$user\""][1]
    }
    t.nm <- c(sch, t.nm)
  }
  if (length(t.nm) > 2)
  {
    stop("Invalid PostgreSQL table/view name. Must be provided as one ('table') or two-length c('schema','table') character vector.")
  }
  if (is.null(conn)) {conn<-DBI::ANSI()}
  if (!as.identifier) {return(t.nm)} else {
    t.nm<-DBI::dbQuoteIdentifier(conn, t.nm)
    return(t.nm)
  }
}

## dbVersion

##' Returns major.minor version of PostgreSQL (for version checking)
##'
##' @param conn A PostgreSQL connection
##' @return numeric vector of length 3 of major,minor,bug version.
##' @keywords internal

dbVersion<- function (conn) {
  pv<-dbGetQuery(conn,"SHOW server_version;")$server_version
  nv<-unlist(strsplit(pv,".",fixed=TRUE))
  return(as.numeric(nv))
}


## dbBuildTableQuery
##' Builds CREATE TABLE query for a data frame object.
##'
##' @param conn A PostgreSQL connection
##' @param name Table name string, length 1-2.
##' @param obj A data frame object.
##' @param field.types optional named list of the types for each field in \code{obj}
##' @param row.names logical, should row.name of \code{obj} be exported as a row_names field? Default is FALSE
##'
##' @note Adapted from RPostgreSQL::postgresqlBuildTableDefinition
##' @keywords internal

dbBuildTableQuery <- function (conn = NULL, name, obj, field.types = NULL, row.names = FALSE) {
  if (is.null(conn)) {
    conn <- DBI::ANSI()
    nameque <- dbQuoteIdentifier(conn,name)
  } else {
    nameque<-paste(dbTableNameFix(conn, name),collapse = ".")
  }
  
  if (!is.data.frame(obj))
    obj <- as.data.frame(obj)
  if (!is.null(row.names) && row.names) {
    obj <- cbind(row.names(obj), obj)
    names(obj)[1] <- "row_names"
  }
  if (is.null(field.types)) {
    field.types <- sapply(obj, dbDataType, dbObj = conn)
  }
  i <- match("row_names", names(field.types), nomatch = 0)
  if (i > 0)
    field.types[i] <- dbDataType(conn, row.names(obj))
  flds <- paste(dbQuoteIdentifier(conn ,names(field.types)), field.types)
  
  paste("CREATE TABLE ", nameque , "\n(", paste(flds,
                                                collapse = ",\n\t"), "\n);")
}

## dbExistsTable
##' Check if a PostgreSQL table/view exists
##'
##' @param conn A PostgreSQL connection
##' @param name Table/view name string, length 1-2.
##'
##' @keywords internal

dbExistsTable <- function (conn, name, table.only = FALSE) {
  if (!table.only) to<-NULL else to<-" AND table_type = 'BASE TABLE'"
  full.name<-dbTableNameFix(conn,name, as.identifier = FALSE)
  chk<-dbGetQuery(conn, paste0("SELECT 1 FROM information_schema.tables
               WHERE table_schema = ",dbQuoteString(conn,full.name[1]),
                               " AND table_name = ",dbQuoteString(conn,full.name[2]),to,";"))[1,1]
  if (length(chk) == 1 && is.na(chk)) chk <- NULL
  if (is.null(chk)) {
    exists.t <- FALSE
    # check version (matviews >= 9.3)
    ver<-dbVersion(conn)
    if (!table.only & !(ver[1] < 9 | (ver[1] == 9 && ver[2] < 3))) {
      # matview case - not in information_schema
      chk2<-dbGetQuery(conn, paste0("SELECT oid::regclass::text, relname
                FROM pg_class
                WHERE relkind = 'm'
                AND relname = ",dbQuoteString(conn,full.name[2]),";"))
      if (length(names(chk2)) > 0) {
        sch<-gsub(paste0(".",chk2[1,2]),"",chk2[,1])
        if (full.name[1] %in% sch) exists.t<-TRUE else exists.t<-FALSE
      } else {
        exists.t<-FALSE
      }
    }
  } else {
    exists.t<-TRUE
  }
  return(exists.t)
}


## dbConnCheck
##' Check if a supported PostgreSQL connection
##'
##' @param conn A PostgreSQL connection
##'
##' @keywords internal

dbConnCheck <- function(conn) {
  if (inherits(conn, c("PostgreSQLConnection")) | inherits(conn, "PqConnection")) {
    return(TRUE)
  } else {
    return(stop("'conn' must be connection object: <PostgreSQLConnection> from `RPostgreSQL`, or <PqConnection> from `RPostgres`"))
  }
}

## dbGetDefs
##' Get definitions for data frame mode reading
##'
##' @param conn A PostgreSQL connection
##' @param name Table/view name string, length 1-2.
##'
##' @keywords internal

dbGetDefs <- function(conn, name) {
  name <- dbTableNameFix(conn, name, as.identifier = FALSE)
  if (dbExistsTable(conn, c(name[1], ".R_df_defs"), table.only = TRUE)) {
    sql_query <- paste0("SELECT unnest(df_def[1:1]) as nms,
                              unnest(df_def[2:2]) as defs,
                              unnest(df_def[3:3]) as atts
                              FROM ",
                        dbQuoteIdentifier(conn, name[1]), ".\".R_df_defs\" WHERE table_nm = ",
                        dbQuoteString(conn, name[2]), ";")
    defs <- dbGetQuery(conn, sql_query)
    return(defs)
  } else {
    return(data.frame())
  }
}


## pg* non-exported functions

## pgCheckGeom
##' Check if geometry or geography column exists in a table,
##' and return the column name for use in a query.
##'
##' @param conn A PostgreSQL connection
##' @param namechar A table name formatted for use in a query
##' @param geom a geometry or geography column name
##'
##' @keywords internal

pgCheckGeom <- function(conn, name, geom) {
  
  namechar <- dbQuoteString(conn,
                            paste(dbTableNameFix(conn,name, as.identifier = FALSE), collapse = "."))
  ## Check table exists geom
  tmp.query <- paste0("SELECT f_geometry_column AS geo FROM geometry_columns\nWHERE
        (f_table_schema||'.'||f_table_name) = ",
                      namechar, ";")
  tab.list <- dbGetQuery(conn, tmp.query)$geo
  ## Check table exists geog
  tmp.query <- paste0("SELECT f_geography_column AS geo FROM geography_columns\nWHERE
        (f_table_schema||'.'||f_table_name) = ",
                      namechar, ";")
  tab.list.geog <- dbGetQuery(conn, tmp.query)$geo
  tab.list <- c(tab.list, tab.list.geog)
  
  if (is.null(tab.list)) {
    stop(paste0("Table/view ", namechar, " is not listed in geometry_columns or geography_columns."))
  } else if (!geom %in% tab.list) {
    stop(paste0("Table/view ", namechar, " geometry/geography column not found. Available columns: ",
                paste(tab.list, collapse = ", ")))
  }
  ## prepare geom column
  if (geom %in% tab.list.geog) {
    # geog version
    geomque <- paste0(DBI::dbQuoteIdentifier(conn, geom),"::GEOMETRY")
  } else {
    geomque <- DBI::dbQuoteIdentifier(conn, geom)
  }
  return(geomque)
}

## pgGetSRID
##' Get SRID(s) from a geometry/geography column in a full table
##'
##' @param conn A PostgreSQL connection
##' @param name A schema/table name
##' @param geom a geometry or geography column name
##'
##' @keywords internal


pgGetSRID <- function(conn, name, geom) {
  
  ## Check and prepare the schema.name
  nameque <- paste(dbTableNameFix(conn,name), collapse = ".")
  ## prepare geom column
  geomque <- pgCheckGeom(conn, name, geom)
  
  ## Retrieve the SRID
  tmp.query <- paste0("SELECT DISTINCT a.s as st_srid FROM
                        (SELECT ST_SRID(", geomque, ") as s FROM ",
                      nameque, " WHERE ", geomque, " IS NOT NULL) a;")
  srid <- dbGetQuery(conn, tmp.query)
  
  return(srid$st_srid)
}

## bs
##' Return indexes for an exact number of blocks for a raster
##'
##' @param r a raster
##' @param blocks Number of desired blocks (columns, rows)
##'
##' @importFrom raster nrow ncol
##' @keywords internal

bs <- function(r, blocks) {
  blocks <- as.integer(blocks)
  if (any(is.na(blocks)) || length(blocks) > 2) stop("blocks must be a 1- or 2-length integer vector.")
  if (any(blocks == 0)) stop("Invalid number of blocks (0).")
  if (length(blocks) == 1) blocks <- c(blocks, blocks)
  r <- r[[1]]
  
  cr <- list()
  tr <- list()
  
  # cr
  b <- blocks[1]
  n.r <- raster::ncol(r)
  if (b == 1) {
    cr$row <- 1
    cr$nrows <- n.r
    cr$n <- 1
  } else {
    if (b >= n.r) b <- n.r
    if (n.r%%b == 0) {
      by <- n.r/b
      cr$row <- seq(1, to = n.r, by = by)
      cr$nrows <- rep(by, b)
      cr$n <- length(cr$row)
    } else {
      by <- floor(n.r/b)
      cr$row <- c(1,seq(1+by+(n.r%%b), to = n.r, by = by))
      cr$nrows <- c(cr$row[2:length(cr$row)], n.r+1) - cr$row
      cr$n <- length(cr$row)
    }
  }
  
  # tr
  b <- blocks[2]
  n.r <- raster::nrow(r)
  if (b == 1) {
    tr$row <- 1
    tr$nrows <- n.r
    tr$n <- 1
  } else {
    if (b >= n.r) b <- n.r
    if (n.r%%b == 0) {
      by <- n.r/b
      tr$row <- seq(1, to = n.r, by = by)
      tr$nrows <- rep(by, b)
      tr$n <- length(tr$row)
    } else {
      by <- floor(n.r/b)
      tr$row <- c(1,seq(1+by+(n.r%%b), to = n.r, by = by))
      tr$nrows <- c(tr$row[2:length(tr$row)], n.r+1) - tr$row
      tr$n <- length(tr$row)
    }
  }
  return(list(cr = cr, tr = tr))
}


pgGetRast2 <- function(conn, name, rast = "rast", bands = 1,
                      boundary = NULL, clauses = NULL, 
                      returnclass = "terra", progress = TRUE) {
  
  ## Message
  message("Since version 1.5 this function outputs SpatRaster objects by default. Use returnclass = 'raster' to return raster objects.")
  
  ## Check connection and PostGIS extension
  dbConnCheck(conn)
  if (!suppressMessages(pgPostGIS(conn))) {
    stop("PostGIS is not enabled on this database.")
  }
  
  ## Check and prepare the schema.name
  name1    <- dbTableNameFix(conn, name)
  nameque  <- paste(name1, collapse = ".")
  namechar <- gsub("'", "''", paste(gsub('^"|"$', '', name1), collapse = "."))
  
  ## Raster query name
  rastque <- dbQuoteIdentifier(conn, rast)
  
  ## Fix user clauses
  clauses2 <- sub("^where", "AND", clauses, ignore.case = TRUE)
  
  ## Check table exists and return error if it does not exist
  tmp.query <- paste0("SELECT r_raster_column AS geo FROM raster_columns\n  WHERE (r_table_schema||'.'||r_table_name) = '",
                      namechar, "';")
  tab.list  <- dbGetQuery(conn, tmp.query)$geo
  if (is.null(tab.list)) {
    stop(paste0("Table '", namechar, "' is not listed in raster_columns."))
  } else if (!rast %in% tab.list) {
    stop(paste0("Table '", namechar, "' raster column '", rast,
                "' not found. Available raster columns: ", paste(tab.list,
                                                                 collapse = ", ")))
  }
  
  ## Check bands
  tmp.query <- paste0("SELECT st_numbands(", rastque, ") FROM ", nameque, " WHERE ", rastque, " IS NOT NULL LIMIT 1;")
  
  nbs <- 1:dbGetQuery(conn, tmp.query)[1,1]
  if (isTRUE(bands)) {
    bands <- nbs
  } else if (!all(bands %in% nbs)) {
    stop(paste0("Selected band(s) do not exist in PostGIS raster: choose band numbers between ", min(nbs), " and ", max(nbs), "."))
  }
  
  ## Retrieve the SRID
  tmp.query <- paste0("SELECT DISTINCT(ST_SRID(", rastque, ")) FROM ", nameque, " WHERE ", rastque, " IS NOT NULL;")
  
  srid      <- dbGetQuery(conn, tmp.query)
  ## Check if the SRID is unique, otherwise throw an error
  if (nrow(srid) > 1) {
    stop("Multiple SRIDs in the raster")
  } else if (nrow(srid) < 1) {
    stop("Database table is empty.")
  }
  ## Retrieve the proj4string
  p4s <- NA
  # tmp.query <- paste0("SELECT proj4text AS p4s FROM spatial_ref_sys WHERE srid = ",
  #                     srid$st_srid, ";")
  #tmp.query.sr <- paste0("SELECT r_proj4 AS p4s FROM ", nameque, ";")
  #try(db.proj4 <- dbGetQuery(conn, tmp.query.sr)$p4s, silent = TRUE)
  
  # if db.proj4 doesnt exist (error because raster was not loaded using rpostgis)
  if (!exists("db.proj4")) {
    tmp.query.sr <- paste0("SELECT proj4text AS p4s FROM spatial_ref_sys WHERE srid = ",
                           srid$st_srid, ";")
    db.proj4 <- dbGetQuery(conn, tmp.query.sr)$p4s
  }
  if (!is.null(db.proj4)) {
    try(p4s <- terra::crs(db.proj4[1]), silent = TRUE)
  }
  if (is.na(p4s)) {
    warning("Table SRID not found. Projection will be undefined (NA)")
  }
  
  ## Check alignment of raster
  tmp.query <- paste0("SELECT ST_SameAlignment(", rastque, ") FROM ", nameque, ";")
  # needs postgis version 2.1+, so just try
  al <- FALSE
  try(al <- dbGetQuery(conn, tmp.query)[1,1])
  if (!al) {
    # get alignment from upper left pixel of all raster tiles
    tmp.query <-  paste0("SELECT min(ST_UpperLeftX(", rastque, ")) ux, max(ST_UpperLeftY(", rastque, ")) uy FROM ", nameque, ";")
    
    aligner <- dbGetQuery(conn, tmp.query)
    aq <- c("ST_SnapToGrid(", paste0(aligner[1,1],","), paste0(aligner[1,2],"),"))
  } else {
    aq <- NULL
  }
  
  ## Get band function
  get_band <- function(band) {
    
    ## Get raster information (bbox, rows, cols)
    info <- dbGetQuery(conn, paste0("select 
            st_xmax(st_envelope(rast)) as xmax,
            st_xmin(st_envelope(rast)) as xmin,
            st_ymax(st_envelope(rast)) as ymax,
            st_ymin(st_envelope(rast)) as ymin,
            st_width(rast) as cols,
            st_height(rast) as rows
            from
            (select st_union(",aq[1],rastque,",",aq[2],aq[3],band,") rast from ",nameque," ", clauses,") as a;"))
    ## Retrieve values of the cells
    vals <- dbGetQuery(conn, paste0("select
          unnest(st_dumpvalues(rast, 1)) as vals 
          from
          (select st_union(",aq[1],rastque,",",aq[2],aq[3],band,") rast from ",nameque," ", clauses,") as a;"))$vals
    
    rout <- terra::rast(nrows = info$rows, ncols = info$cols, xmin = info$xmin, 
                        xmax = info$xmax, ymin = info$ymin, ymax = info$ymax,
                        crs = p4s, vals = vals)
    
    return(rout)
    
  }
  
  ## Get band with boundary function
  get_band_boundary <- function(band) {
    
    ## Get info
    info <- dbGetQuery(conn, paste0("select 
            st_xmax(st_envelope(rast)) as xmx,
            st_xmin(st_envelope(rast)) as xmn,
            st_ymax(st_envelope(rast)) as ymx,
            st_ymin(st_envelope(rast)) as ymn,
            st_width(rast) as cols,
            st_height(rast) as rows
            from
            (select st_union(",aq[1],rastque,",",aq[2],aq[3],band,") rast from ",nameque, "\n
            WHERE ST_Intersects(",
                                    rastque, ",ST_SetSRID(ST_GeomFromText('POLYGON((", boundary[4],
                                    " ", boundary[1], ",", boundary[4], " ", boundary[2],
                                    ",\n  ", boundary[3], " ", boundary[2], ",", boundary[3],
                                    " ", boundary[1], ",", boundary[4], " ", boundary[1],
                                    "))'),", srid, "))", clauses2,") as a;"))
    if (is.na(info$cols) & is.na(info$rows)) {
      stop("No data found within geographic subset defined by 'boundary'.")
    }
    
    vals <- dbGetQuery(conn,paste0("select
          unnest(st_dumpvalues(rast, 1)) as vals 
          from
          (select st_union(",aq[1],rastque,",",aq[2],aq[3],band,") rast from ",nameque, "\n
            WHERE ST_Intersects(",
                                   rastque, ",ST_SetSRID(ST_GeomFromText('POLYGON((", boundary[4],
                                   " ", boundary[1], ",", boundary[4], " ", boundary[2],
                                   ",\n  ", boundary[3], " ", boundary[2], ",", boundary[3],
                                   " ", boundary[1], ",", boundary[4], " ", boundary[1],
                                   "))'),", srid, "))", clauses2,") as a;"))$vals  
    
    rout <- terra::rast(nrows = info$rows, ncols = info$cols, 
                        xmin = info$xmn, xmax = info$xmx, ymin = info$ymn, ymax = info$ymx,
                        crs = p4s, vals = vals)
    
    return(rout)
  }
  
  ## Get raster
  if (is.null(boundary)) {
    ## Get bands
    if (progress) {
      rout <- purrr::map(bands, get_band, .progress = "Reading bands")
    } else {
      rout <- purrr::map(bands, get_band)
    }
    
    rb   <- terra::rast(rout)
    
    ## Else: when boundary is provided
  } else {
    
    ## Bbox of terra and sf objects
    if (inherits(boundary, "sf")) {
      boundary <- sf::st_bbox(boundary)
      boundary <- c(boundary[4], boundary[2], boundary[3], boundary[1])
    } else if (inherits(boundary, "SpatVector")) {
      boundary <- c(terra::ext(boundary)[4], terra::ext(boundary)[3],
                    terra::ext(boundary)[2], terra::ext(boundary)[1])
    }
    
    ## Extent to clip the Rast
    extclip <- terra::ext(boundary[4], boundary[3], boundary[2], boundary[1])
    
    ## Get bands
    rout <- purrr::map(bands, get_band_boundary, .progress = "Reading bands")
    rb   <- terra::rast(rout)
  }
  
  ## Set layer names
  if ("band_names" %in% dbTableInfo(conn,name)$column_name) {
    try({
      ct <- 1
      for (b in bands) {
        lnm <- dbGetQuery(conn, paste0("SELECT DISTINCT band_names[",b,
                                       "][1] as nm FROM ",nameque," ", clauses,";"))
        names(rb)[ct] <- lnm$nm
        ct <- ct + 1
      }
    })
  }
  
  # precise cropping
  if (!is.null(boundary)) {
    rb_final <- terra::crop(rb, extclip)
  } else {
    rb_final <- rb
  }
  
  # Output terra or raster
  if (returnclass == "terra") {
    return(rb_final)
  } else if (returnclass == "raster") {
    if (terra::nlyr(rb_final) == 1) {
      return(raster::raster(rb_final))
    } else {
      return(raster::stack(rb_final))
    }
  } else {
    stop("returnclass must be one of 'terra' or 'raster'")
  }
  
  
  
}