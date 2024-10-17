library (data.table)
library (terra)
source (paste0 (here::here(), "/R/functions/R_Postgres.R"))

brfn<-st_read("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/area_for_data/area_for_data.shp")

den<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/denning.tif")
mov<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/movement.tif")
opn<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/open.tif")
cwd<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/rest_cwd.tif")
rus<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/rest_rust.tif")
cav<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/rest_cavity.tif")

den1<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/denning.tif")
mov1<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/movement.tif")
opn1<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/open.tif")
cwd1<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/rest_cwd.tif")
rus1<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/rest_rust.tif")
cav1<-rast("C:/Users/klochhea/castor/R/scenarios/fisher_brfn/rest_cavity.tif")

denning<-c(den, den1)
names(denning)<- c("ras_fisher_denning_init","ras_fisher_denning_1")

movement<-c(mov, mov1)
names(movement)<- c("ras_fisher_movement_init","ras_fisher_movement_1")

open<-c(opn, opn1)
names(open)<- c("ras_fisher_open_init","ras_fisher_open_1")

rest_cwd<-c(cwd, cwd1)
names(rest_cwd)<- c("ras_fisher_cwd_init","ras_fisher_cwd_1")

rest_rust<-c(rus, rus1)
names(rest_rust)<- c("ras_fisher_rust_init","ras_fisher_rust_1")

rest_cavity<-c(cav,cav1)
names(rest_cavity)<- c("ras_fisher_cavity_init","ras_fisher_cavity_1")

fisher_pop<-rast("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/fisher_pop.tif")
names(fisher_pop)<-"ras_fisher_pop"

landscape<-c(denning, rest_cavity, movement, rest_rust, open, rest_cwd, fisher_pop)
x <- crop(landscape, ext(brfn) + .01)
y <- mask(x, brfn)

pixelid<- terra::subset (y, "ras_fisher_pop")
pixelid[]<-1:ncell(pixelid)
names(pixelid) <- "pixelid"

y<-c(y,pixelid)

terra::writeRaster (x = y, filename = "C:/Users/klochhea/castor/R/scenarios/fisher_brfn/static_habitat_brfn.tif", overwrite = TRUE)

