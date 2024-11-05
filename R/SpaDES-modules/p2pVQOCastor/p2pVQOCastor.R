# Copyright 2024 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

defineModule(sim, list(
  name = "p2pVQOCastor",
  description = "Adjusts visual quality objectives based on slope. Using plan to perspective ratios and visualy effective green-up heights adjust the permissable alteration by visual quality objective (VQO)",
  keywords = "Visual Quality",
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Rhian", "Davies", email = "rhian.davies@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(p2pVQOCastor = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("NEWS.md", "README.md", "p2pVQOCastor.Rmd"),
  reqdPkgs = list("SpaDES.core (>= 2.0.5)", "ggplot2"),
  parameters = bindrows(
    defineParameter("nameSlopeRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the slope percentage (%)"),
    defineParameter("nameVQORaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the polygon ids pertaining to VQOs"),
  ),
  inputObjects = bindrows(
    expectsInput(objectName ="castordb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates castor realted information", sourceURL = NA),
    expectsInput(objectName ="dbCreds", objectClass ="list", desc = 'Credentials used to connect to users postgresql database', sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="ras", objectClass ="SpatRaster", desc = NA, sourceURL = NA),
    expectsInput(objectName ="p2pRatioVegHt", objectClass = "data.table", desc = "A data.table object containing the plan to perspective ratios andvisually effective green up heights by slope class. See table 40 in https://www2.gov.bc.ca/assets/gov/farming-natural-resources-and-industry/forestry/stewardship/forest-analysis-inventory/tsr-annual-allowable-cut/13ts_dpkg_2020_november.pdf", sourceURL = NA)
    ),
  outputObjects = bindrows(
    createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

doEvent.p2pVQOCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      
      #Checks
      if(nrow(dbGetQuery(sim$castordb, glue::glue("Select * from zone where reference_zone ='", P(sim, "nameVQORaster","p2pVQOCastor"), "';"))) == 0){
        stop(paste0("ERROR: The raster:", P(sim, "nameVQORaster","p2pVQOCastor"), " is not listed in the zone table"))
      }
      
      sim <- Init(sim)
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  browser()
  if(!(P(sim, "nameSlopeRaster", "p2pVQOCastor") == '99999')){
    message(paste0('..getting slope for VQO adjustment: ',P(sim, "nameSlopeRaster", "p2pVQOCastor")))
    ras.slope <- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                       srcRaster= P(sim, "nameSlopeRaster", "p2pVQOCastor"), 
                                       clipper=sim$boundaryInfo[1] , 
                                       geom= sim$boundaryInfo[4] , 
                                       where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                       conn = sim$dbCreds))
  }else{
    stop("ERROR: Need to define a slope raster: nameSlopeRaster")
  }
  
  if(terra::ext(sim$ras) == terra::ext(ras.slope)){
    #get the slopes for each pixels
    slope_vqo<-data.table(slope = ras.slope[])
    names(slope_vqo) <- "slope" 
    slope_vqo[, pixelid := seq_len(.N)]
    
    
    nameVqoColumn<-dbGetQuery(sim$castordb, glue::glue("Select zone_column from zone where reference_zone = '", P(sim, "nameVQORaster","p2pVQOCastor"), "';"))
    vqo_pixels<-data.table(dbGetQuery(sim$castordb, glue::glue("select pixelid, ",nameVqoColumn$zone_column ," as zoneid, cflb from pixels where ", nameVqoColumn$zone_column," is not null and cflb > 0;")))
    
    #get the ids that distinguish VQO polygons
    slope_vqo<-merge(slope_vqo, vqo_pixels, by.x = "pixelid", by.y = "pixelid", all.y= TRUE)
    
    #assign slope class each pixel. Remove the last element of the slope_class vector for labeling
    slope_vqo[, slope_bin := cut(slope, sim$p2pRatios$slope_class, labels = head(sim$p2pRatios$slope_class,-1))]
    slope_vqo[, slope_class := as.numeric(as.character(slope_bin))][is.na(slope_class), slope_class :=0]
 
    #get the veg height and p2p ratio
    slope_vqo<-merge(slope_vqo, sim$p2pRatios, by.x = "slope_class", by.y = "slope_class", all.x= TRUE)
    
    #calculate the area weighted p2p and VEG height
    vqo_adj<-slope_vqo[, .(p2p = mean(p2pRatio), veg = mean(vegHeight)), by = zoneid ]
    
    #Update the zoneConstraint table in the database
    #browser()
    dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, glue::glue("UPDATE zoneConstraints set threshold = :veg, percentage = percentage*:p2p where reference_zone ='", P(sim, "nameVQORaster","p2pVQOCastor"),"' and zoneid =:zoneid;"),vqo_adj[,c("zoneid", "p2p", "veg")])
    dbClearResult(rs)
    dbCommit(sim$castordb)

    
  }else{
    stop(paste0("ERROR: extents are not the same check -", P(sim, "nameSlopeRaster", "p2pVQOCastor")))
  }

  return(invisible(sim))
}


.inputObjects <- function(sim) {
  if(!suppliedElsewhere("p2pRatioVegHt", sim)){
    sim$p2pRatios<-data.table(slope_class = c(0,5.1,10.1,15.1,20.1,25.1,30.1,35.1,40.1,45.1,50.1,55.1,60.1,65.1,70.1,100),
                              p2pRatio =c(4.68,4.23,3.77,3.41,3.04,2.75,2.45,2.22,1.98,1.79,1.6,1.45,1.29,1.17,1.04,1.04),
                              vegHeight =c(3,3.5,4,4.5,5,5.5,6,6.5,6.5,7,7.5,8,8.5,8.5,8.5,8.5))
  }
  return(invisible(sim))
}

