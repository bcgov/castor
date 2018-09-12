#----------------------------------------------------------------------------------------------------------------------------------------
#Functions
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

test<-function(start, end, stepper){
  for (i in seq(start, end, stepper)){
    print(i)
  }
}

GetPolygonText_Matrix<-function(coords){
  txtPoly = 'POLYGON(('
  for (row in 1:nrow(coords)){
    if (row == nrow(coords)){
      txtPoly = paste(txtPoly, coords[row, 1], coords[row, 2])
    } else {
      txtPoly = paste(txtPoly, coords[row, 1], coords[row,2])
      txtPoly = paste(txtPoly, ', ')
    }
  }  
  txtPoly = paste(txtPoly, '))') 
}

GetPostgresCon<-function(dbName, dbUser, dbPass, dbHost="localhost", dbPort=5432){
  pgConn = pgConn <- dbConnect(PostgreSQL(), dbname=dbName, user=dbUser, password=dbPass, host=dbHost, port=dbPort) 
  return(pgConn)  
}

CallPostgresRasterFunction <- function(conn, func, outRast, poly, src, qry, refRast=NULL, srcKey=NULL){
  #--Valid func values:
      #-RASTER
      #-VECTOR
      #-VECTORLINKRASTER
  #--Dependencies
  library(sqldf)
  library(RPostgreSQL)
  
  if (func=='RASTER'){
      print(outRast)
      print(poly)
      print(src)
      print(qry)
      print(refRast)
      print(srcKey)
      if (is.null(refRast)){
        #print('hi')
      qry = sprintf("select FAIB_GET_MASK_RASTER_FROM_RASTER('%s', '%s', '%s', '%s' );", outRast, poly, src, qry)    
      #qry = sprintf("select FAIB_GET_MASK_RASTER_FROM_RASTER('%s', '%s', '%s', '%s', '%s', '%s' );", outRast, poly, src, qry, refRast, srcKey)  
      }
      else{
        #print('how are you')
      qry = sprintf("select FAIB_GET_MASK_RASTER_FROM_RASTER('%s', '%s', '%s', '%s', '%s', '%s' );", outRast, poly, src, qry, refRast, srcKey)  
      #qry = sprintf("select FAIB_GET_MASK_RASTER_FROM_RASTER('%s', '%s', '%s', '%s' );", outRast, poly, src, qry)    
      }
  } else if (func=='VECTOR'){
    qry = sprintf("select FAIB_GET_MASK_RASTER_FROM_VECTOR('%s', '%s', '%s', '%s' );", outRast, poly, src, qry)  
  } else if (func=='VECTORLINKRASTER'){
    qry = sprintf("select FAIB_GET_MASK_RASTER_FROM_VECTORLINKRASTER('%s', '%s', '%s', '%s', '%s', '%s' );", outRast, poly, refRast, src, srcKey, qry)  
  }
  print(qry)
  dbGetQuery(conn, qry)
  #dbDisconnect(pgConn)
}

#----------------------------------------------------------------------------------------------------------------------------------------
#-Applying the Functions
#----------------------------------------------------------------------------------------------------------------------------------------
RunMaskTests<-function(){
library(sqldf)
library(RPostgreSQL)

#txtPoly = GetPolygonText(coordz[[1]])
#C Polygon  
txtPoly = "POLYGON(( -116.768005 51.138001 ,  -116.927311 51.234407 ,  -117.130563 51.289406 ,  -117.366775 51.289406 ,  -117.542561 51.251601 ,  -117.69088 51.124213 ,  -117.778773 50.979182 ,  -117.795253 50.847573 ,  -117.800746 50.715591 ,  -117.784267 50.586724 ,  -117.685387 50.509933 ,  -117.498615 50.450509 ,  -117.240429 50.408518 ,  -117.048164 50.405017 ,  -116.844911 50.433017 ,  -116.740539 50.548344 ,  -116.685606 50.698197 ,  -116.691099 50.788575 ,  -116.982244 50.785102 ,  -117.048164 50.677316 ,  -117.234936 50.666872 ,  -117.377762 50.75731 ,  -117.377762 50.882243 ,  -117.317336 51.006842 ,  -117.17451 51.069017 ,  -116.943791 51.006842 ,  -116.768005 51.138001 ))"  
#txtPoly = "POLYGON(( -118.503882 51.289406 ,  -116.98773 51.282535 ,  -116.976744 50.913424 ,  -118.575295 50.930738 ,  -118.503882 51.289406 ))"
#pgConn<-GetPostgresCon("postgres", "postgres", "postgres")
pgConn<-GetPostgresCon("clus", "postgres", "postgres", "DC052586")

#CallPostgresRasterFunction(pgConn, 'VECTOR', CLUS_RUNTIME_TESTFROMAPP', txtPoly, 'BEC_ZONE', "ZONE IN (''ESSF'')")
#--Calls to Local Instance - Mikes Computer Datasets
CallPostgresRasterFunction(pgConn, 'RASTER', 'CLUS_RUNTIME_TESTFROMAPP_RASTER', txtPoly, 'BEC_ZONE_CLIP_RASTER', "2,3,16,17,18,26,27,40,42,43,45,46,47,48")
CallPostgresRasterFunction(pgConn, 'RASTER', 'CLUS_RUNTIME_TESTFROMAPP_RASTER_VAT', txtPoly, 'BEC_ZONE_CLIP_RASTER', "ZONE IN (''ESSF'') AND UPPER(SUBZONE) IN (''WC'', ''WCW'', ''WMP'', ''WCP'') ", 'BEC_ZONE_VAT', 'BEC_KEY')
#CallPostgresRasterFunction(pgConn, 'VECTOR', 'CLUS_RUNTIME_TESTFROMAPP_VECTOR', txtPoly, 'BEC_ZONE', "ZONE IN (''ESSF'') ")
#CallPostgresRasterFunction(pgConn, 'VECTORLINKRASTER', 'CLUS_RUNTIME_TESTFROMAPP_VECTORLINK', txtPoly, 'BEC_ZONE_CLIP', "ZONE IN (''ESSF'')", 'BEC_ZONE_CLIP_RASTER', 'BEC_KEY')
#--Calls to CLUS Instance - Kyles Computer Datasets
CallPostgresRasterFunction(pgConn, 'RASTER', 'CLUS_RUNTIME_TESTFROMAPP_RASTER_SLOPE', txtPoly, 'BC_HA_SLOPE', "60")
#CallPostgresRasterFunction(pgConn, 'RASTER', 'CLUS_RUNTIME_TESTFROMAPP_RASTER_VAT', txtPoly, 'BEC_ZONE_CLIP_RASTER', "ZONE IN (''ESSF'') AND UPPER(SUBZONE) IN (''WC'', ''WCW'', ''WMP'', ''WCP'') ", 'BEC_ZONE_VAT', 'BEC_KEY')
CallPostgresRasterFunction(pgConn, 'VECTOR', 'CLUS_RUNTIME_TESTFROMAPP_VECTOR_BEC', txtPoly, 'BEC_ZONE', "ZONE IN (''ESSF'') ")
CallPostgresRasterFunction(pgConn, 'VECTOR', 'CLUS_RUNTIME_TESTFROMAPP_VECTOR_VRI', txtPoly, 'VEG_COMP_LYR_L1_POLY', "UPPER(SPECIES_CD_1) IN (''SX'') ")
#CallPostgresRasterFunction(pgConn, 'VECTORLINKRASTER', 'CLUS_RUNTIME_TESTFROMAPP_VECTORLINK', txtPoly, 'BEC_ZONE_CLIP', "ZONE IN (''ESSF'')", 'BEC_ZONE_CLIP_RASTER', 'BEC_KEY')

dbDisconnect(pgConn)
}

