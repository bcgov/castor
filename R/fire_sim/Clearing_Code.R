library(gdata)

keep(dat_lightning, dat_lightning_, dat_person, dat_person_, Escape_data_lightning_t, 
     Escape_data_lightning_nt, Escape_data_person_nt, Escape_data_person_t, Escape_data_lightning, Escape_data_person,
     big.mod, huckle_data_logged2c, huckle_data_logged, cutblock_plots, cutblock_plots_logged,
     berry_data, berry_data_logged, huckle_data, sample_locations_distances, sure = TRUE) # setting sure to TRUE removes variables not in the list

keep(spread_150_1ha, spread_500_1ha, sure = TRUE) # setting sure to TRUE removes variables not in the list

ls()
gc(TRUE)

Escape_data_lightning<-rbind(Escape_data_lightning_t, Escape_data_lightning_nt)

Escape_data_person<-rbind(Escape_data_person_t, Escape_data_person_nt)
