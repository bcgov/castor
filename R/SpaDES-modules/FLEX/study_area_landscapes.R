library (data.table)
library (terra)
source (paste0 (here::here(), "/R/functions/R_Postgres.R"))

study.areas<-st_read("F:/Fisher/spatial/BC_fisher_study_areas.shp")
williston<-study.areas[study.areas$NOTE == 'Williston', ]
beaver.valley<-study.areas[study.areas$NOTE == 'Beaver Valley',]
chilcotin_west<-study.areas[study.areas$NOTE =='Chilcotin',]
chilcotin_east<-study.areas[study.areas$NOTE == 'Chiclotin',]

chilcotin_east<-st_buffer(chilcotin_east, 10000)

den2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2003.tif")
den2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2010.tif")
den2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2015.tif")
den2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2021.tif")

mov2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2003.tif")
mov2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2010.tif")
mov2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2015.tif")
mov2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2021.tif")

opn2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2003.tif")
opn2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2010.tif")
opn2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2015.tif")
opn2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2021.tif")

cwd2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2003.tif")
cwd2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2010.tif")
cwd2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2015.tif")
cwd2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2021.tif")

rus2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2003.tif")
rus2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2010.tif")
rus2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2015.tif")
rus2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2021.tif")

cav2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2003.tif")
cav2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2010.tif")
cav2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2015.tif")
cav2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2021.tif")

denning<-c(den2003, den2010, den2015, den2021)
names(denning)<- c("ras_fisher_denning_init","ras_fisher_denning_5","ras_fisher_denning_10","ras_fisher_denning_15" )
movement<-c(mov2003, mov2010, mov2015, mov2021)
names(movement)<- c("ras_fisher_movement_init","ras_fisher_movement_5","ras_fisher_movement_10","ras_fisher_movement_15" )
open<-c(opn2003, opn2010, opn2015, opn2021)
names(open)<- c("ras_fisher_open_init","ras_fisher_open_5","ras_fisher_open_10","ras_fisher_open_15" )
cwd<-c(cwd2003, cwd2010, cwd2015, cwd2021)
names(cwd)<- c("ras_fisher_cwd_init","ras_fisher_cwd_5","ras_fisher_cwd_10","ras_fisher_cwd_15" )
rust<-c(rus2003, rus2010, rus2015, rus2021)
names(rust)<- c("ras_fisher_rust_init","ras_fisher_rust_5","ras_fisher_rust_10","ras_fisher_rust_15" )

fisher_pop<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/fisher_pop.tif")

cavity<-c(cav2003, cav2010, cav2015, cav2021, fisher_pop)
names(cavity)<- c("ras_fisher_cavity_init","ras_fisher_cavity_5","ras_fisher_cavity_10","ras_fisher_cavity_15", "ras_fisher_pop")

landscape<-c(denning, cavity, movement, rust, open, cwd)
x <- crop(landscape, ext(chilcotin_east) + .01)
y <- mask(x, chilcotin_east)

pixelid<- terra::subset (y, "ras_fisher_pop")
pixelid[]<-1:ncell(pixelid)
names(pixelid) <- "pixelid"

y<-c(y,pixelid)

terra::writeRaster (x = y, filename = "C:/Users/klochhea/castor/R/SpaDES-modules/FLExplorer/chilcotin_east.tif", overwrite = TRUE)

