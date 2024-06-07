library(data.table)
library(raster)
library(sf)
library(fasterize)
library(ggplot2)
source("C:/Users/klochhea/castor/R/functions/R_Postgres.R")
conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                     host=keyring::key_get('vmdbhost', keyring = 'postgreSQL'), 
                     dbname = keyring::key_get('vmdbname', keyring = 'postgreSQL'), port='5432' ,
                     user=keyring::key_get('vmdbuser', keyring = 'postgreSQL') ,
                     password= keyring::key_get('vmdbpass', keyring = 'postgreSQL'))
#data<-data.table(dbGetQuery(conn, "SELECT * from fisher_rcb.fisher where scenario = 'no_harvest';"))
data2<-data.table(dbGetQuery(conn, "SELECT * from fisher_rcb.fisher 
                               where d2 <=7 and scenario not in ('upload', 'bau', 'bau_adj', 'no_harvest', 'no_harvest_adj', 'esr_no_harvest', 'bau_pri_og_adj') and timeperiod in (0, 5,10,15)"))
#harv<-data.table(dbGetQuery(conn, "SELECT avg(volume), compartment, scenario from fisher_rcb.harvest where scenario not in ('upload', 'bau', 'bau_adj', 'no_harvest', 'no_harvest_adj', 'esr_no_harvest', 'bau_pri_og_adj') group by scenario, compartment;"))
dbDisconnect(conn)

fisher.poly.d2<-st_read("C:/Users/klochhea/fetaMapper/data-raw/habitat_categories/feta_historic_d2.shp")
fish.table.d2<-data.table(st_drop_geometry(fisher.poly.d2))
fisher.table.d2<-fish.table.d2[, suit2003 :=0][d2_2003 <=7, suit2003 :=1][, suit2010:=0][d2_2010 <=7, suit2010 :=1][, suit2015:=0][d2_2015 <=7, suit2015 :=1][, suit2021:=0][d2_2021 <=7, suit2021 :=1]
#Check the totals
fisher.table.d2[,.(suit_2003 = sum(suit2003), suit_2010 = sum(suit2010), suit_2015 = sum(suit2015), suit_2021 = sum(suit2021))]

fisher.poly.d2<-merge(fisher.poly.d2,fisher.table.d2[,c("fid", "suit2003", "suit2010", "suit2015", "suit2021")], by = "fid")

tsa<-getSpatialQuery("SELECT * from tsa where rtrmntdt is null and tsnmbrdscr in ('Quesnel_TSA', '100_Mile_House_TSA', 'Williams_Lake_TSA');")
fisher.tsa<-st_intersection(fisher.poly.d2, tsa)

fisher.tsa$area<-st_area(fisher.tsa)
out_tsa<-data.table(st_drop_geometry(fisher.tsa))
out_tsa<-units::drop_units(out_tsa)

out_tsa2<-out_tsa[d2_2003 <= 7, ]

final<-merge(out_tsa2[,c("fid", "d2_2003")], data2, by.x = "fid", by.y = "zone", all.y = T)
final<-final[!is.na(d2_2003), suit2003:=1]
out99<-final[, sum(suit2003, na.rm=T), by = c("scenario", "timeperiod")]
out991<-data2[zone %in% out_tsa$fid, .N, by = c("scenario", "timeperiod")]

latst<-merge(out99,out991, by=c("scenario", "timeperiod"))
write.csv(latst, "cclup_from2003_suit.csv")
