#Access SQLite database:

library(RSQLite)

sqlite <- dbDriver("SQLite")

castordb <- dbConnect(sqlite,"C:/Work/caribou/castor/central_group_march2023_castordb.sqlite")
castordb <- dbConnect(sqlite,"C:/Work/caribou/castor/test_castordb.sqlite")

boundaryInfo <- list("public.tsa_aac_bounds","tsa_name",c("Dawson_Creek_TSA", "TFL48"),'wkb_geometry') # list of boundary parameters to set the extent of where the model will be run; these parameters are expected inputs in dataCastor
extent <- NA

ras<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                  srcRaster= "rast.tsa_aac_boundary", 
                                  clipper=boundaryInfo[[1]], 
                                  geom= boundaryInfo[[4]], 
                                  where_clause =  paste0 (boundaryInfo[[2]], " in (''", paste(boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                  conn=NULL))

#crs(ras)<-"epsg:4326"

ras2<-terra::project(ras, "EPSG:4326")



pts <- data.table(terra::xyFromCell(ras2,1:ncell(ras2))) #Seems to be faster than rasterTopoints
pts <- pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid

pixels <- data.table(V1 = as.integer(ras[]))
pixels[, pixelid := seq_len(.N)]

  compart_vat <- data.table(getTableQuery(glue::glue("SELECT * FROM  vat.tsa_aac_bounds_vat;")))
  pixels<- merge(pixels, compart_vat, by.x = "V1", by.y = "value", all.x = TRUE )
  pixels[, V1:= NULL]
  col_name<-data.table(colnames(compart_vat))[!V1 == "value"]
  setnames(pixels, col_name$V1 , "compartid")
  setorder(pixels, "pixelid")

ras[]<-pixels$pixelid



pixels<-dbGetQuery(castordb, "Select * from pixels limit 10")

dbGetQuery(castordb, "SELECT name FROM sqlite_master WHERE type='table';")

all.dist<-data.table(dbGetQuery(castordb, paste0("SELECT age, blockid, (case when ((roadtype != 0 OR roadtype IS NULL) OR roadtype = 0) then 1 else 0 end) as road_dist, pixelid FROM pixels WHERE perm_dist > 0 OR (blockid > 0 and age >= 0) OR (roadtype != 0 OR roadtype IS NULL) OR roadtype = 0;")))

ras.info<-dbGetQuery(castordb, "Select * from raster_info limit 1;")
spreadRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
spreadRas[]<-dbGetQuery(castordb, "Select treed from pixels order by pixelid;")$treed
plot(spreadRas)



disturbance <- pts

boundaryInfo <- list("tsa_aac_bounds","tsa_name","Lakes_TSA", "wkb_geometry")

message("...Get the critical habitat")


dbGetQuery(castordb, "Select * from pixels order by pixelid limit 5;")

if(!is.null(sim$boundaryInfo)){ # if you have boundary data...
  
  if(P(sim, "criticalHabRaster", "disturbanceCastor") == '99999'){
    disturbance[, attribute := 1]
  }else{
    bounds <- data.table (V1 = RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                            srcRaster = "rast.bc_crithab_and_herd", 
                                            clipper = boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                                            geom = boundaryInfo[[4]], 
                                            where_clause =  paste0 (boundaryInfo[[2]], " in (''", paste(boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                            conn = NULL)[])
    bounds [, pixelid := seq_len(.N)] # make a unique id to ensure it merges correctly

        crit_lu<-data.table(getTableQuery(paste0("SELECT cast(value as int) , attribute FROM ","vat.vat_bc_crithab_and_herd")))
        bounds<-merge (bounds, crit_lu, by.x = "V1", by.y = "value", all.x = TRUE)
      }else{
        stop(paste0("ERROR: need to supply a lookup table: ", P(sim, "criticalHabitatTable", "disturbanceCastor")))
      }
    }else{
      stop(paste0(P(sim, "criticalHabRaster", "disturbanceCastor"), "- does not overlap with aoi"))
    }
    setorder(bounds, pixelid) #sort the bounds
    sim$disturbance[, critical_hab:= bounds$attribute]
    sim$disturbance[, compartment:= dbGetQuery(castordb, "SELECT compartid FROM pixels order by pixelid")$compartid]
    sim$disturbance[, treed:= dbGetQuery(sim$castordb, "SELECT treed FROM pixels order by pixelid")$treed]
  }
  
  #get the permanent disturbance raster
  #check it a field already in sim$castordb?
  if(dbGetQuery (sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='perm_dist';")$exists_check == 0){
    # add in the column
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN perm_dist integer DEFAULT 0")
    # add in the raster
    if(P(sim, "permDisturbanceRaster", "disturbanceCastor") == '99999'){
      message("WARNING: No permanent disturbance raster specified ... defaulting to no permanent disturbances")
      dbExecute(sim$castordb, "Update pixels set perm_dist = 0;")
    }else{
      perm_dist <- data.table(perm_dist = RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                       srcRaster = P(sim, "permDisturbanceRaster", "disturbanceCastor"), 
                                                       clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                                                       geom = sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[])
      perm_dist[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly
      #add to the castordb
      dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, "Update pixels set perm_dist = :perm_dist where pixelid = :pixelid", perm_dist)
      dbClearResult(rs)
      dbCommit(sim$castordb)
      
      #clean up
      rm(perm_dist)
      gc()
    }
  }else{
    message("...using existing permanent disturbance raster")
  }
} 

return(invisible(sim))



# see line 132 of datacastor. This is what Im checking out

ras.info<-dbGetQuery(conn, "select * from raster_info where name = 'ras'")
ras<-terra::rast(terra::ext(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =1:ras.info$ncell)
terra::crs(ras)<-paste0("EPSG:", ras.info$crs) #set the raster projection

pts <- data.table(terra::xyFromCell(ras,1:length(ras[]))) # creates pts at centroids of raster boundary file; seems to be faster that rasterTopoints
pts <- pts[, pixelid:= seq_len(.N)] #add in the pixelid which streams data in according to the cell number = pixelid

#Get the available zones for other modules to query -- In forestryCastor the zones that are not part of the scenario get deleted.
zone.available<-data.table(dbGetQuery(conn, "SELECT * FROM zone;")) 


spreadRas[]<-dbGetQuery(conn, "Select * from pixels order by pixelid;")$treed



##########################
###
# from dataCastor.R L211


# creating pixel id table. But ask Kyle to show this to me again. 
coef_varying<-st_read("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\BC\\estimated_coefficients\\BC_ignit_escape_spread_varying_coefficient_2021.gpkg")

coef_lightning_const<-raster("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\BC\\estimated_coefficients\\Lightning_2021_constant_coefficients.tif")

pts <- data.table(terra::xyFromCell(coef_lightning_const,1:ncell(coef_lightning_const))) #Seems to be faster than rasterTopoints
pts <- pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid

pixels <- data.table(V1 = as.integer(sim$ras[]))
pixels[, pixelid := seq_len(.N)]

