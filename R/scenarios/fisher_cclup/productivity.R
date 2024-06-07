#userdb <- dbConnect(RSQLite::SQLite(), dbname = paste0(here::here(), "/R/scenarios/fisher_cclup/wlms_lk/williams_lake_castordb.sqlite"))
#userdb <- dbConnect(RSQLite::SQLite(), dbname = paste0(here::here(), "/R/scenarios/fisher_cclup/hundred_mile/hundred_mile_castordb.sqlite"))
userdb <- dbConnect(RSQLite::SQLite(), dbname = paste0(here::here(), "/R/scenarios/fisher_cclup/quesnel/quesnel_castordb.sqlite"))

ras.info<-dbGetQuery(userdb, "Select * from raster_info limit 1;")
ras<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =1:ras.info$ncell)
ras[]<-dbGetQuery(userdb, "select siteindex from pixels order by pixelid;")$siteindex
prod<-data.table(dbGetQuery(userdb, "select siteindex, pixelid from pixels order by pixelid;"))
dbDisconnect(userdb)


#writeRaster(ras, paste0(here::here(), "/R/scenarios/fisher_cclup/wlms_lk/siteindex.tif"))
#writeRaster(ras, paste0(here::here(), "/R/scenarios/fisher_cclup/hundred_mile/siteindex.tif"))
writeRaster(ras, paste0(here::here(), "/R/scenarios/fisher_cclup/quesnel/siteindex.tif"))

bau<-raster("C:/Users/klochhea/castor/R/scenarios/fisher_cclup/wlms_lk/bau_Williams_Lake_TSA_harvestBlocks.tif")
es<-raster("C:/Users/klochhea/castor/R/scenarios/fisher_cclup/wlms_lk/legal_early_seral_Williams_Lake_TSA_harvestBlocks.tif")
up<-raster("C:/Users/klochhea/castor/R/scenarios/fisher_cclup/wlms_lk/upgrade_low_beo_Williams_Lake_TSA_harvestBlocks.tif")


prod$bau<-bau[]
prod$es<-es[]
prod$up<-up[]

p_bau<-prod[bau>0,]
p_bau[,scen:='bau']
nrow(p_bau[siteindex >= 20,])
p_es<-prod[es>0,]
p_es[,scen:='es']
nrow(p_es[siteindex >= 20,])
p_up<-prod[up>0,]
p_up[,scen:='up']
nrow(p_up[siteindex >= 20,])

data<-rbindlist(list(p_bau,p_es,p_up))
ggplot(data=data, aes(x=siteindex, group = scen)) + geom_histogram() +facet_wrap(~scen, ncol=1)
