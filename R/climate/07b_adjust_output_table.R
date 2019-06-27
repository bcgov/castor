library(dplyr)

##Get a connection to the postgreSQL server (local instance)
conn<-RPostgreSQL::dbConnect(dbDriver(drv = RPostgreSQL::PostgreSQL(), 
                                      host = key_get('dbhost', keyring = 'postgreSQL'),
                                      user = key_get('dbuser', keyring = 'postgreSQL'),
                                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                                      password = key_get('dbpass', keyring = 'postgreSQL'),
                                      port = "5432"))
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
