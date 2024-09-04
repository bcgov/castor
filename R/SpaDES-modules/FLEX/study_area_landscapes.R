library (data.table)
library (terra)
source (paste0 (here::here(), "/R/functions/R_Postgres.R"))

#study.areas<-st_read("F:/Fisher/spatial/BC_fisher_study_areas.shp")
#williston<-study.areas[study.areas$NOTE == 'Williston', ]
#beaver.valley<-study.areas[study.areas$NOTE == 'Beaver Valley',]
#chilcotin_west<-study.areas[study.areas$NOTE =='Chilcotin',]
#chilcotin_east<-study.areas[study.areas$NOTE == 'Chiclotin',]
#one_hundy_mile<-getSpatialQuery("select * from tsa where tsnmbrdscr = '100_Mile_House_TSA' ")
#quesnel<-getSpatialQuery("select * from tsa where tsnmbrdscr = 'Quesnel_TSA' ")

#chilcotin_east<-st_buffer(chilcotin_east, 10000)
#one_hundy_mile<-st_buffer(one_hundy_mile, 1000)
#quesnel<-st_buffer(quesnel, 1000)
#lakes<-st_read("C:/Users/klochhea/castor/R/SpaDES-modules/FLEX/Lakes/Lakes_PlanningBoundary_210310.shp")
columbia<-st_read("C:/Users/klochhea/castor/R/SpaDES-modules/FLEX/Columbia_Habitat_Rasters/Columbian_area.shp")

den2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2003.tif")
den2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2010.tif")
den2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2015.tif")
den2018<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2018.tif")
den2019<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2019.tif")
den2020<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2020.tif")
den2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2021.tif")
den2022<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/denning2022.tif")

mov2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2003.tif")
mov2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2010.tif")
mov2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2015.tif")
mov2018<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2018.tif")
mov2019<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2019.tif")
mov2020<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2020.tif")
mov2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2021.tif")
mov2022<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/movement2022.tif")

opn2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2003.tif")
opn2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2010.tif")
opn2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2015.tif")
opn2018<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2018.tif")
opn2019<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2019.tif")
opn2020<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2020.tif")
opn2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2021.tif")
opn2022<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/open2022.tif")

cwd2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2003.tif")
cwd2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2010.tif")
cwd2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2015.tif")
cwd2018<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2018.tif")
cwd2019<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2019.tif")
cwd2020<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2020.tif")
cwd2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2021.tif")
cwd2022<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cwd2022.tif")

rus2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2003.tif")
rus2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2010.tif")
rus2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2015.tif")
rus2018<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2018.tif")
rus2019<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2019.tif")
rus2020<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2020.tif")
rus2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2021.tif")
rus2022<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_rust2022.tif")

cav2003<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2003.tif")
cav2010<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2010.tif")
cav2015<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2015.tif")
cav2018<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2018.tif")
cav2019<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2019.tif")
cav2020<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2020.tif")
cav2021<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2021.tif")
cav2022<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/rest_cavity2022.tif")

denning<-c(den2018, den2019, den2020, den2021, den2022)
names(denning)<- c("ras_fisher_denning_init","ras_fisher_denning_1","ras_fisher_denning_2","ras_fisher_denning_3" ,"ras_fisher_denning_4")
movement<-c(mov2018, mov2019, mov2020, mov2021, mov2022)
names(movement)<- c("ras_fisher_movement_init","ras_fisher_movement_1","ras_fisher_movement_2","ras_fisher_movement_3","ras_fisher_movement_4" )
open<-c(opn2018, opn2019, opn2020, opn2021, opn2022)
names(open)<- c("ras_fisher_open_init","ras_fisher_open_1","ras_fisher_open_2","ras_fisher_open_3","ras_fisher_open_4" )
cwd<-c(cwd2018, cwd2019, cwd2020, cwd2021, cwd2022)
names(cwd)<- c("ras_fisher_cwd_init","ras_fisher_cwd_1","ras_fisher_cwd_2","ras_fisher_cwd_3","ras_fisher_cwd_4" )
rust<-c(rus2018, rus2019, rus2020, rus2021, rus2022)
names(rust)<- c("ras_fisher_rust_init","ras_fisher_rust_1","ras_fisher_rust_2","ras_fisher_rust_3","ras_fisher_rust_4" )

fisher_pop<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/fisher_pop.tif")

cavity<-c(cav2018, cav2019, cav2020, cav2021, cav2022, fisher_pop)
names(cavity)<- c("ras_fisher_cavity_init","ras_fisher_cavity_1","ras_fisher_cavity_2","ras_fisher_cavity_3","ras_fisher_cavity_4", "ras_fisher_pop")

landscape<-c(denning, cavity, movement, rust, open, cwd)
x <- crop(landscape, ext(columbia) + .01)
y <- mask(x, columbia)

pixelid<- terra::subset (y, "ras_fisher_pop")
pixelid[]<-1:ncell(pixelid)
names(pixelid) <- "pixelid"

y<-c(y,pixelid)

terra::writeRaster (x = y, filename = "C:/Users/klochhea/castor/R/SpaDES-modules/FLEX/Columbia_Habitat_Rasters/columbia_fisher_habitat_2018_2022.tif", overwrite = TRUE)

