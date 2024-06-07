beo.table<-readRDS("beo_table.rds")
beo.lut<-readRDS("beo_lut.rds")

# CCLUP
qu<-st_read("F:/Fisher/early_seral_rating/dqu.shp")
hm<-st_read("F:/Fisher/early_seral_rating/dmh.shp")
cc<-st_read("F:/Fisher/early_seral_rating/dcc.shp")

cclup.lut<-rbindlist(list(data.table(link_key = qu$link_key) , data.table(link_key = hm$link_key), data.table(link_key = cc$link_key)))
cclup.lut$cclup_id<-1:nrow(cclup.lut)
cclup.qu<-st_drop_geometry(merge(qu, cclup.lut, by.x = "link_key",by.y = "link_key", all.x =T))
cclup.hm<-st_drop_geometry(merge(hm, cclup.lut, by.x = "link_key",by.y = "link_key", all.x =T))
cclup.cc<-st_drop_geometry(merge(cc, cclup.lut, by.x = "link_key",by.y = "link_key", all.x =T))

cclup.table<-rbindlist(list(cclup.qu[,c("link_key", "analysis_g", "BGC_LABEL", "ZONE", "NATURAL_DI", "legal_earl", "legal_ea_1", "legal_ea_2", "legal_mato", "legal_ma_1", "legal_ma_2", "legal_old_", "legal_ol_1", "legal_ol_2")],cclup.cc[,c("link_key", "analysis_g", "BGC_LABEL","ZONE", "NATURAL_DI","legal_earl", "legal_ea_1", "legal_ea_2", "legal_mato", "legal_ma_1", "legal_ma_2", "legal_old_", "legal_ol_1", "legal_ol_2")],cclup.hm[,c("link_key", "analysis_g", "BGC_LABEL","ZONE","NATURAL_DI", "legal_earl", "legal_ea_1", "legal_ea_2", "legal_mato", "legal_ma_1", "legal_ma_2", "legal_old_", "legal_ol_1", "legal_ol_2")]))

cclup.table[,"lu":=substr(analysis_g, 5, nchar(analysis_g))]
cclup_beo<-read.csv("lu_beo_cclup.csv")
cclup.table<-merge(cclup.table, cclup_beo, by.x = "lu", by.y = "lu", all.x =T)

beo.lut.info<-merge(beo.lut, cclup.table, by.x = "key_beo", by.y = "link_key", all.y = TRUE)
beo.lut.info<-beo.lut.info[beo == 3 & !is.na(id_beo), ][, ndt:=as.integer(substr(NATURAL_DI,4,4))][, bec:=ZONE]
beo.lut.info[, c("lu_xxx", "bxxx", "nxxxx", "maxxxxabel", "species", "one", "two") := tstrsplit(key_beo, "_", fixed=TRUE)]
beo.lut.info[species %in% c('FirGroup', 'PineGroup'), group:=species]
beo.lut.info[one %in% c('FirGroup', 'PineGroup'), group:=one]
beo.lut.info[two %in% c('FirGroup', 'PineGroup'), group:=two]
beo.lut.info[!(bec == 'IDF'), group:=NA]

#threshold lut

mature<-beo.lut.info[!(legal_ma_1=='na'),c('id_beo', 'ndt', 'legal_ma_1')]
saveRDS(mature, paste0(here::here(), "/R/scenarios/fisher_cclup/lowToInt_Mature.rds"))
old<-beo.lut.info[!(legal_ol_1=='na'),c('id_beo', 'ndt', 'legal_ol_1')]
saveRDS(old, paste0(here::here(), "/R/scenarios/fisher_cclup/lowToInt_Old.rds"))

change_table<-data.table(ndt=c(1,	1,	1,	1,	2,	2,	2,	2,	2,	2,	3,	3,	3,	3,	3,	3,	4,	4,	4,	4,	4,	4,	5,	5),
                         bec=c('CWH',	'ICH',	'ESSF',	'MH',	'CWH',	'CDF',	'ICH',	'SBS',	'ESSF',	'SWB',	'BWBS',	'SBPS',	'SBS',	'MS',	'ESSF',	'ICH',	'ICH',	'IDF',	'IDF',	'IDF',	'PP',	'BG',	'ESSF',	'MH'),
                         target =c(30,	30,	22,	22,	36,	36,	36,	36,	36,	36,	54,	66,	54,	46,	46,	46,	30,	30,	22,	54,	30,	30,	22,	22),
                         group =c(NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	NA,	'FirGroup',	'PineGroup',	NA,	NA,	NA,	NA))
out<-merge(beo.lut.info, change_table, by.x = c("bec", "ndt", "group"), by.y = c("bec", "ndt", "group"), all.x=T)
out<-out[,c('id_beo', 'ndt', 'target')]
saveRDS(out, paste0(here::here(), "/R/scenarios/fisher_cclup/lowToInt.rds"))
