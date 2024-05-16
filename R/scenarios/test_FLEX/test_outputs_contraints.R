library(ggplot2)
library(data.table)
library(DBI)

conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                      host='165.227.35.74', 
                      dbname = 'clus', 
                      port='5432', 
                      user='klochhea',
                      password='XVneCw86' )

rs<-data.table(dbGetQuery(conn, "select count(*), timeperiod, scenario from rcb.fisher where d2 < 4 and mov > 25 group by timeperiod, scenario;"))
#rs<-rs[scenario == 'nuke_harvest', scenario:= '1.2x_bau_harvest']
#rs$scenario <- factor(rs$scenario, levels = c("no_harvest", "bau_harvest", "1.2x_bau_harvest"))
ggplot2::ggplot(data =rs[scenario == 'nh',], aes(x = timeperiod, y = count, color = scenario, group = scenario)) + geom_line()
ggplot2::ggplot(data =rs, aes(x = timeperiod, y = count, color = scenario, group = scenario)) + geom_line()

rs2<-data.table(dbGetQuery(conn, "select sum(volume) as vol, timeperiod, scenario from rcb.harvest where scenario = 'bau' group by timeperiod, scenario;"))
ggplot2::ggplot(data =rs2, aes(x = timeperiod, y = vol, color = scenario, group = scenario)) + geom_line()

dbDisconnect(conn)

###overlap
feta<-st_read("C:/Users/klochhea/fetaMapper/data-raw/feta_v1.shp")
userdb <- dbConnect(RSQLite::SQLite(), dbname =  "c:/users/klochhea/clus/R/scenarios/test_flex/rcb_clusdb.sqlite")
fetas_rcb<-dbGetQuery(userdb, "select distinct(fetaid) from fisherhabitat")
rcb<-feta[feta$fid %in% fetas_rcb$fetaid,]

const<-raster("C:/Users/klochhea/clus/R/scenarios/test_FLEX/bau_harvest_RCB_constraints.tif")
const[const[] > 0] <- 1
const[is.na(const[])]<-0

den_p<-raster("C:/Users/klochhea/fetaMapper/data-raw/denning_p.tif")
den<-raster("C:/Users/klochhea/fetaMapper/data-raw/denning.tif")

den[den[] > 0] <- 1
den[is.na(den[])]<-0

denc<-const+den
denc[denc[] == 1]<-0
denc[denc[] > 1]<-1

mov<-raster("C:/Users/klochhea/fetaMapper/data-raw/movement.tif")
mov[mov[] > 0] <- 1
mov[is.na(mov[])]<-0

movc<-const+mov
movc[movc[] == 1]<-0
movc[movc[] > 1]<-1

rcb$const<- exactextractr::exact_extract(const,rcb,c('sum'))
rcb$denc<- exactextractr::exact_extract(denc,rcb,c('sum'))
rcb$movc<- exactextractr::exact_extract(movc,rcb,c('sum'))

rcb.table<-st_drop_geometry(rcb)
rcb.table<-data.table(rcb.table)
rcb.table[, den_prop:=denc/hab_den]

hist(rcb.table$den_prop, main="Histogram of  FETA", xlab = "Proportion between 'protected denning habitat' and denning habitat")
abline(v = median(rcb.table$den_prop, na.rm = T),                     
       col = "red",
       lwd = 3)
text(x =  median(rcb.table$den_prop, na.rm = T) * 0.5,                 # Add text for median
     y =  median(rcb.table$den_prop, na.rm = T) * 495.7,
     paste("Median =",  round(median(rcb.table$den_prop, na.rm = T), 2)),
     col = "red",
     cex = 2)

hist(rcb.table[]$movc/rcb.table[]$hab_mov, main="Histogram of  FETA", xlab = "Proportion between 'protected movement habitat' and movement habitat")

st_write(rcb, 'rcb.shp')

### priority
rcb<-st_read("C:/Users/klochhea/fetaMapper/rcb.shp")
conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                     host='165.227.35.74', 
                     dbname = 'clus', 
                     port='5432', 
                     user='klochhea',
                     password='XVneCw86' )
dat<-data.table(dbGetQuery(conn, "select * from rcb.fisher where scenario = 'nh' and timeperiod < 105;"))
dbDisconnect(conn)

dat<-dat[timeperiod <= 10 & d2 < 4 & mov > 25, pri:=1]
dat<-dat[timeperiod > 10 & timeperiod <= 50 & d2 < 4 & mov > 25 & is.na(pri), pri2:=2]
test<-dat[, .(pri = min(pri, na.rm=T), pri2 = min(pri2, na.rm=T)), by = zone]
test[pri > 10, pri:= NA]
test[pri2 > 10, pri2:= NA]
test[pri == 1 & pri2 ==2, pri2:=NA]
test[pri==1, pri_c:="blue"]
test[pri2==2, pri_c2:="yellow"]
test$pri<-NULL
test$pri2<-NULL
rcb<-merge(rcb, test, by.x = 'fid', by.y = 'zone', all.x=T)

plot(rcb["pri_c"], main = "Essential and Retain", col=rcb$pri_c)
plot(rcb["pri_c2"], main = "Recruit", col=rcb$pri_c2)
