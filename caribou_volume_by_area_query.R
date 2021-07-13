

require (keyring)
require (DBI)
require (RPostgreSQL)
require (data.table)
require (dplyr)
require (stringr)

con2 <- DBI::dbConnect(dbDriver("PostgreSQL"), 
                      host = key_get("vmdbhost", keyring="postgreSQL"), 
                      dbname = key_get("vmdbname", keyring="postgreSQL"), 
                      port ='5432', 
                      user = key_get("vmdbuser", keyring="postgreSQL"), 
                      password = key_get("vmdbpass", keyring="postgreSQL"))

# query <- dbGetQuery (conn,
#                      "SELECT scenario, area_name, timeperiod, SUM(volume_harvest) FROM quesnel_tsa.volumebyarea GROUP BY scenario, area_name, timeperiod;")

query <- dbGetQuery (con2,
                     "SELECT * FROM tfl56.volumebyarea WHERE scenario = 'tfl56_columbia_north_nh';") 
                      # quesnel_tsa.volumebyarea williams_lake_tsa.volumebyarea  
                      # prince_george_tsa.volumebyarea  cascadia_cariboo_chilcotin.volumebyarea
                      # tfl52.volumebyarea  robsonvalley_tsa.volumebyarea  tfl30.volumebyarea
                      # cascadia_cariboo_chilcotin.volumebyarea  tfl53.volumebyarea  onehundred_mile_tsa.volumebyarea
                      # kamloops_tsa.volumebyarea  golden_tsa.volumebyarea  revelstoke_tsa.volumebyarea
                      # tfl56.volumebyarea
                      
                      #  scenario = quesnel_bau  quesnel_chil_nh  williams_lake_bau williams_lake_chil_nh
                      # pg_south_bau  pg_chil_nh_notweeds quesnel_barkerville_he0d_m12d 
                      # quesnel_barkerville_nh  quesnel_barkerville_high_med_low_priority
                      # quesnel_barkerville_high_med_priority  quesnel_barkerville_high_priority

                      # cascadia_cariboo_chilcotin_bau  cascadia_cc_barkerville_nh  cascadia_cc_barkerville_he0d_m12d
                      # cascadia_cc_barkerville_hi_m_lo_priority  cascadia_cc_barkerville_high_priority

                      # cascadia_cariboo_chilcotin_bau cascadia_cc_narrow_lk_he0d_m12d

                      # pg_south_bau   golden_bau  revelstoke_bau

                      # quesnel_bau  quesnel_narrow_lake_nh  tfl56_bau

                      # robson_bau  robson_hart_he0d_m12d  robson_hart_he0d_m12d  
                      # robson_hart_hi_med_lo_priority  robson_hart_hi_med_priority
                      # robson_north_cariboo_nh  robson_north_cariboo_hi_med_lo  robson_columbia_north_nh

                      # tfl30_bau  tfl30_hart_nh tfl30_hart_he0d_m12d  tfl30_hart_hi_med_lo_priority  tfl30_hart_hi_med_priority

                      # tfl52_bau  tfl52_barkerville_nh  tfl52_barkerville_he0d_m12d  tfl52_barkerville_hi_med_lo_priority
                      # tfl52_barkerville_high_med_priority  tfl52_barkerville_high_priority
                      #  tfl52_north_cariboo_nh  tfl52_north_cariboo_he0d_m12d
                      # tfl52_north_cariboo_hi_med_lo_priority  tfl52_north_cariboo_hi_med_priority
                      #  tfl52_narrow_lake_nh

                      # tfl53_bau

                      # williams_lake_bau  williams_lake_barkerville_nh 
                      # 





query.mean <- query %>%
                group_by (scenario, area_name) %>%
                  summarise(mean_scen_area = mean(volume_harvest))



matrix.harvest <- query.mean %>% 
                    filter(str_detect(area_name, "Columbia_North Matrix")) %>%
                      summarise (sum (mean_scen_area ))
matrix.harvest <- matrix.harvest [,2] / 5 
matrix.harvest
# Barkerville Matrix | Itcha_Ilgachuz Matrix | Rainbows Matrix | Charlotte_Alplands Matrix | 
# Itcha_Ilgachuz Matrix|Rainbows Matrix|Charlotte_Alplands Matrix
# Hart_Ranges Matrix| North_Cariboo Matrix | Narrow_Lake Matrix | Wells_Gray_North Matrix
# Wells_Gray_South Matrix | Barkerville Matrix | Columbia_North | Central_Rockies | Columbia_South | Central_Selkirks
# Frisby_Boulder  Monashee


core.harvest <- query.mean %>% 
                  filter(str_detect(area_name, "Columbia_North HEWSR")) %>%
                    summarise (sum (mean_scen_area ))
core.harvest <- core.harvest [,2] / 5
core.harvest
# Itcha_Ilgachuz HEWSR|Itcha_Ilgachuz LESR|Itcha_Ilgachuz LEWR|Rainbows HEWSR|Rainbows LESR|Rainbows LEWR
 # Charlotte_Alplands HEWSR | Charlotte_Alplands LEWR | Itcha_Ilgachuz HEWSR|Itcha_Ilgachuz LESR|
# Itcha_Ilgachuz LEWR|Rainbows HEWSR|Rainbows LESR|Rainbows LEWR|Charlotte_Alplands HEWSR|
# Charlotte_Alplands LEWR
# Hart_Ranges HEWSR | North_Cariboo HEWSR | Narrow_Lake HEWSR | Wells_Gray_North HEWSR
# Wells_Gray_South HEWSR | Barkerville HEWSR | Columbia_North | Central_Rockies | Columbia_South | Frisby_Boulder
# Monashee

query2 <- dbGetQuery (con2,
                     "SELECT * FROM tfl56.harvest WHERE scenario = 'tfl56_columbia_north_nh';") 

query2.mean <- query2 %>%
                group_by (scenario) %>%
                    summarise(mean_volume = mean(volume))
query2.mean



other.habitat <- query.mean %>% 
                  filter(!str_detect(area_name, "Itcha_Ilgachuz Matrix|Itcha_Ilgachuz HEWSR|Itcha_Ilgachuz LESR|Itcha_Ilgachuz LEWR")) %>%
                      summarise (sum (mean_scen_area )) # filter crit = combo of the two above
other.habitat <- other.habitat [,2] / 5
# Itcha_Ilgachuz Matrix|Rainbows Matrix|Charlotte_Alplands Matrix|Itcha_Ilgachuz HEWSR|Itcha_Ilgachuz LESR|Itcha_Ilgachuz LEWR|Rainbows HEWSR|Rainbows LESR|Rainbows LEWR|Charlotte_Alplands HEWSR|Charlotte_Alplands LEWR

outside.habitat <- query.mean %>% 
                    filter(is.na(area_name)) %>%
                      summarise (sum (mean_scen_area ))
outside.habitat <- outside.habitat [,2] / 5


# total.harvest <- matrix.harvest + core.harvest + other.harvest + outside.habitat

dbDisconnect(conn)

