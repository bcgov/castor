library(ggplot2)
library(data.table)
source(here::here("R/functions/R_Postgres.R"))
conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                     host=keyring::key_get('vmdbhost', keyring = 'postgreSQL'), 
                     dbname = keyring::key_get('vmdbname', keyring = 'postgreSQL'), port='5432' ,
                     user=keyring::key_get('vmdbuser', keyring = 'postgreSQL') ,
                     password= keyring::key_get('vmdbpass', keyring = 'postgreSQL'))
data<-data.table(dbGetQuery(conn, "SELECT * from fisher_rcb.fisher where scenario = 'no_harvest';"))
data2<-data.table(dbGetQuery(conn, "SELECT * from fisher_rcb.fisher 
                               where d2 <=7 and scenario not in ('upload', 'bau', 'bau_adj', 'no_harvest', 'no_harvest_adj', 'esr_no_harvest', 'bau_pri_og_adj')"))
harv<-data.table(dbGetQuery(conn, "SELECT avg(volume), compartment, scenario from fisher_rcb.harvest where scenario not in ('upload', 'bau', 'bau_adj', 'no_harvest', 'no_harvest_adj', 'esr_no_harvest', 'bau_pri_og_adj') group by scenario, compartment;"))
dbDisconnect(conn)

fire_adj<-readRDS(paste0(here::here(), "/feta_fire_adj.rds"))
data3<-merge(data2, fire_adj, by.x = "zone", by.y = "feta")
data3<-data3[, nonadj:=1]
data4<-data3[, .(bu=as.integer(sum((3000-(bu*1))/3000)), bl=as.integer(sum((3000-(bl*1))/3000)), nonfireadj = sum(nonadj)), by = c("scenario", "timeperiod")]

data4<-data4[scenario == 'esr_bau_adj', scenarios:= '1-CUR'][scenario == 'esr_bau_pri_og_adj', scenarios:= '2-CUR+OG'][scenario == 'esr_bau_pri_og_caribou_adj', scenarios:= '3-CUR+OG+Caribou'][scenario == 'esr_bau_adj_og_caribou_legal_es', scenarios:= '4a-Legalize Early Seral in H and I']
data4<-data4[scenario == 'esr_bau_adj_og_caribou_add_es_low', scenarios:= '4b-Legalize Early Seral in L'][scenario == 'esr_no_harvest_adj', scenarios:= '5-No Disturbance'][scenario == 'esr_bau_adj_og_caribou_upgrade_low', scenarios:='4c-Upgrade L to I']
data4$scenarios <- factor(data4$scenarios, levels=c('1-CUR', '2-CUR+OG', '3-CUR+OG+Caribou', '4a-Legalize Early Seral in H and I', '4b-Legalize Early Seral in L','4c-Upgrade L to I', '5-No Disturbance'))


tsa_fire_adj<-readRDS(paste0(here::here(), "/tsa_fire_adj.rds"))
tsa_fire_adj<-tsa_fire_adj[compart == 1, compartment := 'Quesnel_TSA'][compart == 2, compartment := 'Williams_Lake_TSA'][compart == 3, compartment := 'Onehundred_Mile_House_TSA']
data5<-merge(harv, tsa_fire_adj, by.x = "compartment", by.y = "compartment")
data5<-data5[,aac_upper:=(thlb - (bu*10))*(avg/thlb)][,aac_lower:=(thlb - (bl*10))*(avg/thlb)]

data6<-data5[, .(aacUp = sum(aac_upper), aacLow = sum(aac_lower)), by = scenario]

#ggplot(data= data4, aes(x = timeperiod, y = bu, color = scenario )) + geom_line()
ggplot(data= data4, aes(x = timeperiod, y = bu, color = scenarios )) + 
  geom_ribbon(aes(ymin=bu,ymax=bl, fill = scenarios)) +
  ylab("Count of FETA") +
  xlab("Future Time (years)")+
  theme(legend.position="bottom") 
  
ggplot(data= data4[timeperiod <= 50,], aes(x = timeperiod, y = bu, color = scenarios )) + 
  geom_ribbon(aes(ymin=bu,ymax=bl, fill = scenarios)) +
  ylab("Count of FETA") +
  xlab("Future Time (years)")+
  theme(legend.position="bottom") 
  #annotate('text', x = c(60,57,57,57,57,57,57,57), y = c(850, 869,792, 805, 820, 776, 760, 835), label =  c("", "-100%", "-23.4%","-27.8%", "-32.2%", "-13.6%","5.11 to 5.68M m3 yr-1", "-34%"), size = unit(3, "pt"),alpha =0.5)

early<-data[d2<=7 & denning > 0, min(timeperiod), by = c("zone","compartment") ]
early2<-merge(early, data[,c("zone", "compartment", "timeperiod", "denning", "mov", "rust", "cwd")], by.x = c("zone", "compartment", "V1"), by.y = c("zone", "compartment", "timeperiod"), all.x =T)

current<- data[timeperiod ==0,c("zone", "compartment", "timeperiod", "denning", "mov", "rust", "cwd")]
setnames(current, c("zone", "compartment","timeperiod", "denning", "mov", "rust", "cwd"), c("zone", "compartment","timeperiod", "c_denning", "c_mov", "c_rust", "c_cwd"))

test<-merge(early2, current,  by.x = c("zone", "compartment"), by.y = c("zone", "compartment"), all.x =T)
test<-test[V1>0,]
bp <-barplot(hist(test$V1, breaks = 20)$counts/nrow(test)~hist(test$V1, breaks = 20)$mids, ylab = "Proportion", xlab = "Years to Suitable")
abline(v=4.3, col = "red")
box()

den_t<-merge(early2, data[,c("zone", "compartment", "timeperiod", "denning")], by.x = c("zone", "compartment", "denning"), by.y = c("zone", "compartment", "denning"), all.y =T)
den_early<-den_t[ !is.na(V1), min(timeperiod), by = c("zone", "compartment") ]
setnames(den_early, "V1", "y2den")
test<-merge(test, den_early,  by.x = c("zone", "compartment"), by.y = c("zone", "compartment"), all.x =T)

mov_t<-merge(early2, data[,c("zone", "compartment", "timeperiod", "mov")], by.x = c("zone", "compartment", "mov"), by.y = c("zone", "compartment", "mov"), all.y =T)
mov_early<-mov_t[ !is.na(V1), min(timeperiod), by =  c("zone", "compartment") ]
setnames(mov_early, "V1", "y2mov")
test<-merge(test, mov_early,  by.x = c("zone", "compartment"), by.y = c("zone", "compartment"), all.x =T)

cwd_t<-merge(early2, data[,c("zone", "compartment", "timeperiod", "cwd")], by.x = c("zone", "compartment", "cwd"), by.y = c("zone", "compartment", "cwd"), all.y =T)
cwd_early<-cwd_t[ !is.na(V1), min(timeperiod), by =  c("zone", "compartment") ]
setnames(cwd_early, "V1", "y2cwd")
test<-merge(test, cwd_early,  by.x = c("zone", "compartment"), by.y = c("zone", "compartment"), all.x =T)

rust_t<-merge(early2, data[,c("zone", "compartment", "timeperiod", "rust")], by.x = c("zone", "compartment", "rust"), by.y = c("zone", "compartment", "rust"), all.y =T)
rust_early<-rust_t[ !is.na(V1), min(timeperiod), by =  c("zone", "compartment") ]
setnames(rust_early, "V1", "y2rust")
test<-merge(test, rust_early,  by.x = c("zone", "compartment"), by.y = c("zone", "compartment"), all.x =T)

test[, limit:="3 or more"]
test[y2den>y2mov & y2den>y2rust & y2den>y2cwd, limit:="denning"]
test[y2mov>y2den & y2mov>y2rust & y2mov>y2cwd, limit:="movement"]
test[y2rust>y2den & y2mov<y2rust & y2rust>y2cwd, limit:="rust"]
test[y2cwd>y2den & y2mov<y2cwd & y2rust<y2cwd, limit:="cwd"]
test[y2cwd==y2den & y2mov==y2cwd & y2rust==y2cwd & y2den==y2mov & y2den==y2rust, limit:="all"]

test[y2den == y2mov & y2den>y2cwd & y2den>y2rust, limit:="Both-den-mov"]
test[y2den == y2rust & y2den>y2cwd & y2den>y2mov, limit:="Both-den-rust"]
test[y2den == y2cwd & y2den>y2rust & y2den>y2mov, limit:="Both-den-cwd"]
test[y2rust == y2mov & y2rust>y2cwd & y2den<y2rust, limit:="Both-mov-rust"]
test[y2cwd == y2mov & y2rust<y2cwd & y2den<y2cwd, limit:="Both-mov-cwd"]
test[y2cwd == y2rust & y2mov<y2cwd & y2den<y2cwd, limit:="Both-rust-cwd"]

plyr::count(test[compartment == '100_Mile_House_TSA',], 'limit')
plyr::count(test[V1 <= 30 & V1 > 0 & compartment == '100_Mile_House_TSA',], 'limit')
plyr::count(test[V1 > 30 & compartment == '100_Mile_House_TSA',], 'limit')

plot(hbk.x[,1:2])
points(1.55,1.8, col = 'red')
