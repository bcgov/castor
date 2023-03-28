#Access SQLite database:

library(RSQLite)

setwd("/Path/To/Database/Folder")
sqlite <- dbDriver("SQLite")
conn <- dbConnect(sqlite,"C:/Work/caribou/castor/test_castordb.sqlite")

dbGetQuery(conn, "Select * from pixels limit 1")


##########################
###
# from dataCastor.R L211
# Here Im trying to create a raster with the pixel id's and them im trying to join these pixel id numbers back to my spatial file and then im trying to create a raster by streaming in my coefficients back into the raster in order of the pixel id's.
# Basically Im trying to find another work around to create rasters rather than doing it manually in Qgis. Also, it will be useful for the simulations.


# But its not working!


# creating pixel id table. But ask Kyle to show this to me again. 

coef_varying<-st_read("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\BC\\estimated_coefficients\\BC_ignit_escape_spread_varying_coefficient_2021.gpkg")

coef_lightning_const<-raster("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\BC\\estimated_coefficients\\Lightning_2021_constant_coefficients.tif")

pts <- data.table(terra::xyFromCell(coef_lightning_const,1:ncell(coef_lightning_const))) #Seems to be faster than rasterTopoints
pts <- pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels <- data.table(V1 = as.integer(sim$ras[]))
    pixels[, pixelid := seq_len(.N)]
    
     sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels <- data.table(V1 = as.integer(sim$ras[]))
    pixels[, pixelid := seq_len(.N)]
    
    
#[2023-03-20, 12:41:23 PM] Lochhead, Kyle FOR:EX: 
ras.info<-dbGetQuery(userdb, "Select * from raster_info limit 1;")

ras1<-extent(coef_lightning_const)

# Im creating a new empty raster with the same extent as my raster with the data. I should make the vals=0 but I  made it the pixelid no's because I wanted to see how it looked. Im not 100% sure its correct. 

ras<-raster(extent(ras1[1], ras1[2], ras1[3], ras1[4]), nrow = dim(coef_lightning_const)[1], ncol = dim(coef_lightning_const)[2], vals = 1:length(pts$pixelid), crs = 3005)

# I tried cropping the raster because my coefficients table only has values in places where there is land. But my raster covers the ocean too i.e. many places where the coefficients will be zero or at least the probability of ignition/escape/spread will be zero. So I was trying to crop the raster, maybe masking it is the correct way though.
ras_crop<-mask(ras, coef_varying)
plot(ras_crop)


#extract raster pixel id number from raster and join to my coefficients table

test<-cbind(coef_varying, st_coordinates(coef_varying))
head(test)

pointCoordinates<-data.frame(test$X, test$Y)
head(pointCoordinates)
#crs(pointCoordinates) #No CRS when a dataframe

##Extract DEM values from stacked layer
rasValue2=raster::extract(ras, pointCoordinates)
head(rasValue2)
str(rasValue2) #200298 values
str(coef_varying)#200298 values

#Append new information
coef_varying_pixelid<-cbind(coef_varying, rasValue2)
head(coef_varying_pixelid)
min(coef_varying_pixelid$rasValue2)
crs(coef_varying_pixelid)

ras[]<-coef_varying_pixelid$varying_coef_lightning[order(coef_varying_pixelid$rasValue2)]



ras.fisher.pop <- fasterize::fasterize(sf= fisher.pop, raster = aggregate(sim$ras, fact =55) , field = "pop")
[2023-03-20, 12:57:36 PM] Lochhead, Kyle FOR:EX: oneha_ras<-ras

oneha_ras[] <- 1:lengthRas

 

fourHundred_ras<-RASTER_CLIP2(tmpRast = 'temp1', srcRaster ='rast.fireParams' , clipper = 'tsa_aac_bounds' , 

                             geom = 'wkb_geometry', where_clause = paste0("tsa_name", " in (''", "Fort_St_John_Core_TSA" ,"'')"), conn=NULL)

dbExecute(sim$clusdb, paste0("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('fireras',", fireExtent[1], ", ",fireExtent[2], ", ",

                             fireExtent[3], ", ", fireExtent[4], ",", ncell(fourHundred_ra) , ", ", nrow(fourHundred_ra),", '3005')"))

 

fire_table<-data.table(fire_param= fourHundred_ras[])[, fireId:=seq_len(.N)]

 

pixels<-pixels[, fireID := extract(oneha_ras)]
    
    
    
    
```

## R Markdown

This is an R Markdown document. Markdown is a simple formatting syntax for authoring HTML, PDF, and MS Word documents. For more details on using R Markdown see <http://rmarkdown.rstudio.com>.

When you click the **Knit** button a document will be generated that includes both content as well as the output of any embedded R code chunks within the document. You can embed an R code chunk like this:

```{r cars}
summary(cars)
```

## Including Plots

You can also embed plots, for example:

```{r pressure, echo=FALSE}
plot(pressure)
```

Note that the `echo = FALSE` parameter was added to the code chunk to prevent printing of the R code that generated the plot.
