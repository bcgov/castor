### additional functions
library(rpostgis)
library(sf)
library(raster)
library(RPostgreSQL)
library(rgdal)
library(sqldf)
library(DBI)
library(sp)

#Uses keyring to set the credentials

#Simple database connectivity functions
getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                       host=keyring::key_get('dbhost', keyring = 'postgreSQL'), 
                       dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,
                       user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,
                       password= keyring::key_get('dbpass', keyring = 'postgreSQL')
                       )
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

getTableQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

getRasterQuery<-function(srcRaster, bb){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  on.exit(dbDisconnect(conn))
  pgGetRast(conn, unlist(strsplit(srcRaster, "[.]")), boundary = c(bb[4],bb[2],bb[3],bb[1]))
}

setCSVPostgresTable<-function(name, table){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  on.exit(dbDisconnect(conn))
  dbWriteTable(conn, name, table)
}

#----------------------------------------------------------------------------------------------------------------------------------------
##R functions for Accessing PostGIS FAIB Raster functions
##This assumes the functions are loaded in db.
## See https://github.com/bcgov/clus/blob/master/SQL/Raster/Documentation/FAIB_PostGIS_Raster_Function_Documentation.md

#Mike Fowler
#Spatial Data Analyst
#October 25, 2018
#----------------------------------------------------------------------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------------------------------------------------------------------
GetPostgresConn<-function(dbName="clus", dbUser="postgres", dbPass="postgres", dbHost="localhost", dbPort=5432){
  pgConn <- DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  return(pgConn)  
}
#-----------------------------------------------------------------------------------------------------------------------------------------
GetRasterLayer_RPOSTGIS<-function(conn, target_rast, rastCol="rast"){
  rout <- pgGetRast(conn, target_rast, rastCol, 1) 
  return(rout)
}
#-----------------------------------------------------------------------------------------------------------------------------------------
GetRasterLayer_FAIB<-function(conn, target_rast){
  
  qry = paste0("SELECT unnest(FAIB_R_RASTERINFO('", target_rast, "'))::double precision")
  vals = dbGetQuery(conn, qry)
  xmx = vals[[1]][1]
  xmn = vals[[1]][2]
  ymx = vals[[1]][3]
  ymn = vals[[1]][4]
  ncols = vals[[1]][5]
  nrows = vals[[1]][6]
  rasvals <- vals[[1]][7:nrow(vals)]
  
  rout <- raster::raster(nrows = nrows, ncols = ncols, xmn = xmn, xmx = xmx, ymn = ymn, ymx = ymx, crs = 3005, val = rasvals)
  return(rout)
}
#-----------------------------------------------------------------------------------------------------------------------------------------
RASTER_FROM_VECTOR <- function(drawPoly, srcVect, whereClause="*", vatFld=NULL, vat=NULL, mask=FALSE, conn=NULL){

  tmpRast = 'FAIB_RFV_TEMPRAST'
  #--Get a Connection to the Database if one not supplied
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }
  #--Build the query string to execute the function to generate temporary Raster
  if ((is.null(vat))&(is.null(vatFld))){
    qry = sprintf("select FAIB_RASTER_FROM_VECTOR('%s', '%s', '%s', '%s', vatFld:=NULL, vat:=NULL, mask:=%s);", tmpRast, drawPoly, srcVect, whereClause, mask)            
  } else if (is.null(vatFld)){
    qry = sprintf("select FAIB_RASTER_FROM_VECTOR('%s', '%s', '%s', '%s', vatFld:=NULL, vat:='%s', mask:=%s);", tmpRast, drawPoly, srcVect, whereClause, vat, mask)    
  } else if (is.null(vat)){
    qry = sprintf("select FAIB_RASTER_FROM_VECTOR('%s', '%s', '%s', '%s', vatFld:='%s', mask:=%s);", tmpRast, drawPoly, srcVect, whereClause, vatFld, mask)        
  } else {
    qry = sprintf("select FAIB_RASTER_FROM_VECTOR('%s', '%s', '%s', '%s', vatFld:='%s', vat:='%s', mask:=%s);", tmpRast, drawPoly, srcVect, whereClause, vatFld, vat, mask)        
  }
  #print(qry)
  #--Execute the query
  dbGetQuery(conn, qry)
  #--Get Raster Layer object of Raster result
  rout <- pgGetRast(conn, tolower(tmpRast), 'rast', 1)
  #--Drop the temporary Raster from the DB
  qry = paste('DROP TABLE IF EXISTS', tmpRast)
  dbGetQuery(conn, qry)
  #--Disconnect the DB
  on.exit(dbDisconnect(conn))
  #--Return the Raster Layer
  return(rout)           
}
#-----------------------------------------------------------------------------------------------------------------------------------------
RASTER_FROM_RASTER <- function(drawPoly, srcRast, rastVal="*", rastVAT=NULL, mask=FALSE, conn=NULL){

  tmpRast = 'FAIB_RFR_TEMPRAST'
  #--Get a Connection to the Database if one not supplied
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }
  #--Build the query string to execute the function to generate temporary Raster
  if (is.null(rastVAT)){
    qry = sprintf("select FAIB_RASTER_FROM_RASTER('%s', '%s', '%s', '%s', rastVAT:=NULL, mask:=%s);", tmpRast, drawPoly, srcRast, rastVal, mask)            
  } else{
    qry = sprintf("select FAIB_RASTER_FROM_RASTER('%s', '%s', '%s', '%s', '%s', mask:=%s);", tmpRast, drawPoly, srcRast, rastVal, rastVAT, mask)        
  }
  #print(qry)
  #--Execute the query
  dbGetQuery(conn, qry)
  #--Get Raster Layer object of Raster result
  rout <- pgGetRast(conn, tolower(tmpRast), 'rast', 1)
  #--Drop the temporary Raster from the DB
  qry = paste('DROP TABLE IF EXISTS', tmpRast)
  dbGetQuery(conn, qry)
  #--Disconnect the DB
  on.exit(dbDisconnect(conn))
  
  #--Return the Raster Layer
  return(rout)           
}
#-----------------------------------------------------------------------------------------------------------------------------------------
FC_TO_RASTER <- function(fc, valFld, vat=NULL, conn=NULL){

  tmpRast = 'FAIB_FTR_TEMPRAST'
  #--Get a Connection to the Database if one not supplied
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }
  #--Build the query string to execute the function to generate temporary Raster
  if (is.null(vat)){
    qry = sprintf("select FAIB_FC_TO_RASTER('%s', '%s', '%s');", fc, valFld, tmpRast)            
  } else {
    qry = sprintf("select FAIB_FC_TO_RASTER('%s', '%s', '%s', '%s');", fc, valFld, tmpRast, vat)        
  }
  #print(qry)
  #--Execute the query
  dbGetQuery(conn, qry)
  #--Get Raster Layer object of Raster result
  rout <- pgGetRast(conn, tolower(tmpRast), 'rast', 1)
  #--Drop the temporary Raster from the DB
  qry = paste('DROP TABLE IF EXISTS', tmpRast)
  dbGetQuery(conn, qry)
  #--Disconnect the DB
  on.exit(dbDisconnect(conn))

  #--Return the Raster Layer
  return(rout)           
}
#-----------------------------------------------------------------------------------------------------------------------------------------
RASTER_CLIP <- function(srcRaster, clipper, conn=NULL){

  tmpRast = 'FAIB_RCL_TEMPRAST'
  #--Get a Connection to the Database if one not supplied
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }
  #--Build the query string to execute the function to generate temporary Raster
  qry = sprintf("select FAIB_RASTER_CLIP('%s', '%s', '%s');", tmpRast, srcRaster, clipper)
  #--Execute the query
  r<-dbGetQuery(conn, qry)
  #--Get Raster Layer object of Raster result
  rout <- pgGetRast(conn, tolower(tmpRast), 'rast', 1)
  #--Drop the temporary Raster from the DB
  qry = paste('DROP TABLE IF EXISTS', tmpRast)
  dbGetQuery(conn, qry)
  #--Disconnect the DB
  on.exit(dbDisconnect(conn))

  #--Return the Raster Layer
  return(rout)           
}
RASTER_CLIP2 <- function(tmpRast, srcRaster, clipper, geom, where_clause, conn=NULL){
  
  #tmpRast = 'FAIB_RCL_TEMPRAST_'
  #--Get a Connection to the Database if one not supplied
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }
  #--Build the query string to execute the function to generate temporary Raster
  qry = sprintf("select public.faib_raster_clip2('%s', '%s', '%s', '%s', '%s');", tmpRast, srcRaster, clipper, geom, where_clause)
  #--Execute the query
  r<-dbGetQuery(conn, qry)
  #--Get Raster Layer object of Raster result
  rout <- pgGetRast(conn, tolower(tmpRast), 'rast', 1)
  #--Drop the temporary Raster from the DB
  qry = paste('DROP TABLE IF EXISTS', tmpRast)
  dbGetQuery(conn, qry)
  #--Disconnect the DB
  on.exit(dbDisconnect(conn))
  
  #--Return the Raster Layer
  return(rout)           
}

RASTER_CLIP_CAT <- function(srcRaster, clipper, geom, where_clause, out_reclass, conn=NULL){
  
  tmpRast = 'FAIB_RCL_TEMPRAST'
  #--Get a Connection to the Database if one not supplied
  if (is.null(conn)){
    conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  }
  #--Build the query string to execute the function to generate temporary Raster
  qry = sprintf("select public.faib_raster_clip_cat('%s', '%s', '%s', '%s', '%s', '%s');", tmpRast, srcRaster, clipper, geom, where_clause, out_reclass)
  #--Execute the query
  r<-dbGetQuery(conn, qry)
  #--Get Raster Layer object of Raster result
  rout <- pgGetRast(conn, tolower(tmpRast), 'rast', 1)
  #--Drop the temporary Raster from the DB
  qry = paste('DROP TABLE IF EXISTS', tmpRast)
  dbGetQuery(conn, qry)
  #--Disconnect the DB
  on.exit(dbDisconnect(conn))
  #--Return the Raster Layer
  return(rout)           
}

#----------------------------------------------------------------------------------------------------------------------------------------
#-Applying the Functions
#----------------------------------------------------------------------------------------------------------------------------------------
RunRasterTests<-function(){
  #--Local Connection
  #conn<-GetPostgresConn("postgres", "postgres", "postgres", "localhost")
  #--CLUS Connection
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host=keyring::key_get('dbhost', keyring = 'postgreSQL'), dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,password= keyring::key_get('dbpass', keyring = 'postgreSQL'))
  
  txtPoly = GetPolygonText(coordz[[1]])
  #C Polygon  
  txtPoly = "POLYGON(( -116.768005 51.138001 ,  -116.927311 51.234407 ,  -117.130563 51.289406 ,  -117.366775 51.289406 ,  -117.542561 51.251601 ,  -117.69088 51.124213 ,  -117.778773 50.979182 ,  -117.795253 50.847573 ,  -117.800746 50.715591 ,  -117.784267 50.586724 ,  -117.685387 50.509933 ,  -117.498615 50.450509 ,  -117.240429 50.408518 ,  -117.048164 50.405017 ,  -116.844911 50.433017 ,  -116.740539 50.548344 ,  -116.685606 50.698197 ,  -116.691099 50.788575 ,  -116.982244 50.785102 ,  -117.048164 50.677316 ,  -117.234936 50.666872 ,  -117.377762 50.75731 ,  -117.377762 50.882243 ,  -117.317336 51.006842 ,  -117.17451 51.069017 ,  -116.943791 51.006842 ,  -116.768005 51.138001 ))"  
  #--Diamond Polygon
  txtPoly = 'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))'
  #--Examples of how to get a queried geometry into text to use with the functions
  geom <- dbGetQuery(conn, 'SELECT ST_ASTEXT(ST_TRANSFORM(WKB_GEOMETRY, 4326)) FROM TSA_CLIP WHERE TSA_NUMBER_INT = 27')  #--Single Poly
  geom <- dbGetQuery(conn, 'SELECT ST_ASTEXT(ST_TRANSFORM(WKB_GEOMETRY, 4326)) FROM TSA_CLIP WHERE TSA_NUMBER_INT = 9')   #--Single Poly
  geom <- dbGetQuery(conn, 'SELECT ST_ASTEXT(ST_UNION(ST_TRANSFORM(WKB_GEOMETRY, 4326))) FROM TSA_CLIP WHERE TSA_NUMBER_INT = 45')  #--Multiple Polygons
  
  

  #--Examples RASTER_FROM_VECTOR
  ras <- RASTER_FROM_VECTOR(txtPoly,  "TSA_CLIP", whereClause="*", conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "TSA_CLIP", whereClause="*", mask=TRUE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "BEC_ZONE_CLIP", whereClause="ZONE IN (''ESSF'') ", vatFld='ZONE', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "BEC_ZONE_CLIP", whereClause="ZONE IN (''ESSF'') ", vatFld='ZONE_ALL', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "BEC_ZONE_CLIP", whereClause="ZONE IN (''ESSF'', ''ICH'') ", vatFld='ZONE_ALL', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "TSA_CLIP", whereClause="*", vatFld='TSA_NAME', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "TSA_CLIP", whereClause="UPPER(TSA_NAME) LIKE ''REV%'' ", vatFld='TSA_NAME', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "TSA_CLIP", whereClause="UPPER(TSA_NAME) LIKE ''REV%'' ", vatFld='TSA_NAME', mask=TRUE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "BEC_ZONE_CLIP", whereClause="ZONE IN (''ESSF'') ", vatFld='BEC_KEY', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "BEC_ZONE_CLIP", whereClause="*", vatFld='BEC_KEY', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_VECTOR(txtPoly,  "BEC_TSA_EXTENT", whereClause="ZONE IN (''ICH'') ", vat='BEC_TSA_EXTENT_RASTER_VAT', vatFld='ZONE', mask=FALSE, conn=conn)
  
  #--Examples RASTER_FROM_RASTER
  ras <- RASTER_FROM_RASTER(txtPoly,  "TSA_CLIP_RASTER", rastVal="*", mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER(txtPoly,  "TSA_CLIP_RASTER", rastVal="*", mask=FALSE)
  ras <- RASTER_FROM_RASTER(txtPoly,  "BEC_TSA_EXTENT_RASTER", rastVal="*", mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER(txtPoly,  "BEC_TSA_EXTENT_RASTER", rastVal="6", mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER(txtPoly,  "BEC_TSA_EXTENT_RASTER", rastVal="6", mask=TRUE, conn=conn)
  ras <- RASTER_FROM_RASTER(txtPoly,  "BEC_TSA_EXTENT_RASTER", rastVal="4-8", mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER(txtPoly,  "BEC_TSA_EXTENT_RASTER", rastVal="ZONE IN (''ESSF'') ", rastVAT='BEC_TSA_EXTENT_RASTER_ZONE_VAT', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER(txtPoly,  "BEC_TSA_EXTENT_RASTER", rastVal="ZONE IN (''ESSF'', ''ICH'') ", rastVAT='BEC_TSA_EXTENT_RASTER_ZONE_VAT', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER(txtPoly,  "TSA_CLIP_RASTER", rastVal="UPPER(TSA_NAME) LIKE ''REV%'' ", rastVAT='TSA_CLIP_NAME_VAT', mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER("POLYGON((-119.403933423982 52.0420609230173,-119.613043827749 50.6463977535579,-116.003004175667 50.4018989930582,-115.721616634563 51.7861947596595,-119.403933423982 52.0420609230173))",  "TSA_CLIP_RASTER", rastVal="UPPER(TSA_NAME) LIKE ''%OO%'' ", rastVAT='TSA_CLIP_NAME_VAT', mask=FALSE)
  
  #--Use the functions with a geometry returned from a query to a feature class table
  #--The WKT Polygon must be in 4326 (WGS 84) - just transform it on the way out
  ras <- RASTER_FROM_RASTER(geom, "TSA_CLIP_RASTER", rastVal="*", mask=FALSE, conn=conn)
  ras <- RASTER_FROM_RASTER(geom,  "BEC_TSA_EXTENT_RASTER", rastVal="*", mask=FALSE, conn=conn)
  
  #--Examples FC_TO_RASTER
  ras <- FC_TO_RASTER('TSA_CLIP', 'TSA_NAME', conn=conn)
  ras <- FC_TO_RASTER('TSA_CLIP', 'TSA_NUMBER_INT', conn=conn)
  ras <- FC_TO_RASTER('BEC_ZONE_CLIP', 'ZONE_ALL', conn=conn)
  ras <- FC_TO_RASTER('BEC_ZONE_CLIP', 'BEC_KEY', conn=conn)
  
  #--Examples RASTER_CLIP
  ras <- RASTER_CLIP('BEC_TSA_EXTENT_RASTER', geom, conn=conn)
  ras <- RASTER_CLIP('BEC_TSA_EXTENT_RASTER', txtPoly, conn=conn)
  
  plot(ras)
  
  on.exit(dbDisconnect(conn))
}