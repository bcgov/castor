library(dplyr)

##Get a connection to the postgreSQL server (local instance)
conn<-RPostgreSQL::dbConnect(dbDriver("PostgreSQL"), host='DC052586', dbname = 'clus', port='5432', user = 'postgres', password ='postgres')
bec<-dbGetQuery(conn,"SELECT * FROM public.clim_plot_data_bec")

ecoproportion <- bec %>%
  group_by(ecotype, year, bec) %>%
  tally() %>%
  group_by(ecotype,year) %>%
  mutate(pct = n / sum(n))
ecoproportion$herdname <- ecoproportion$ecotype

herdproportion <- bec %>%
  group_by(ecotype,year, herdname,bec) %>%
  tally() %>%
  group_by(ecotype,year, herdname) %>%
  mutate(pct = n / sum(n))

combinedData <- rbind (herdproportion , ecoproportion )

#write table to local instance
RPostgreSQL::dbWriteTable(conn, "clime_bec", combinedData, append=TRUE, row.names = FALSE)
dbDisconnect(conn)
