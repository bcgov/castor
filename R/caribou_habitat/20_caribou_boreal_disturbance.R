#=================================
#  Script Name: 11_caribou_boreal_disturbance
#  Script Version: 1.0
#  Script Purpose: Calculate caribou habitat 'disturbance' by watershed 
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations
#  Script Date: 10 April 2018
#  R Version: 3.4.3
#  R Package Versions: dplyr
#  Data: 
#=================================

#====================================================
# Load packages and Data; Build dataset for Analysis
#===================================================
library (dplyr)
options (scipen = 999)
setwd ("G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\boreal_disturbance\\data\\")
# Watershed areas
# needed to remove ' from text fields in csv data to load
fwa <- read.table ("fwa_tsa_isect_bou_area_caribou_area.csv", header = T, sep = ",") 
fwa <- fwa %>%
     select (WATERSHED_FEATURE_ID, TSA_NUMBER_DESCRIPTION, HERD_NAME, area_km2_tsa_bou)
names (fwa) [1] <- "watershed"
names (fwa) [2] <- "tsa"
names (fwa) [3] <- "herd"
names (fwa) [4] <- "fwa.area.km2"

# Initial disturbance data
disturb.fwa <- read.table ("disturb_fwa_tsa_caribou_isect.csv", header = T, sep = ",")
disturb.fwa <- disturb.fwa %>%
     select (WATERSHED_FEATURE_ID, TSA_NUMBER_DESCRIPTION, HERD_NAME, area_disturb_km2)
names (disturb.fwa) [1] <- "watershed"
names (disturb.fwa) [2] <- "tsa"
names (disturb.fwa) [3] <- "herd"
names (disturb.fwa) [4] <- "area.disturb.km2"

# Intital road length
roads.fwa <- read.table ("roads_fwa_tsa_caribou_isect.csv", header = T, sep = ",") 
# needed to remove ' from csv data to load first time
roads.fwa <- roads.fwa %>%
     select (WATERSHED_FEATURE_ID, TSA_NUMBER_DESCRIPTION, HERD_NAME, road_lgth_km)
names (roads.fwa) [1] <- "watershed"
names (roads.fwa) [2] <- "tsa"
names (roads.fwa) [3] <- "herd"
names (roads.fwa) [4] <- "init.roads.km"
roads.fwa <- data.frame (roads.fwa %>% # road length by watershed, TSA and herd  
                              group_by (watershed, tsa, herd) %>%
                              summarise (init.roads.km = sum (init.roads.km, na.rm = T)))

# Historic cutblocks
hist.cut.fwa <- read.table ("cutblocks_fwa_tsa_caribou_isect.csv", header = T, sep = ",") 
# needed to remove ' from csv data to load first time
hist.cut.fwa <- hist.cut.fwa %>%
     select (WATERSHED_FEATURE_ID, TSA_NUMBER_DESCRIPTION, HERD_NAME, HARVEST_YEAR, area_cut_km2)
names (hist.cut.fwa) [1] <- "watershed"
names (hist.cut.fwa) [2] <- "tsa"
names (hist.cut.fwa) [3] <- "herd"
names (hist.cut.fwa) [4] <- "harvest.year"
names (hist.cut.fwa) [5] <- "cut.area.km2"
hist.cut.fwa <- data.frame (hist.cut.fwa %>% # historic cut by watershed, TSA, herd and year
                                 group_by (watershed, tsa, herd, harvest.year) %>%
                                 summarise (cut.area.km2 = sum (cut.area.km2, na.rm = T)))

# Future new cut to predict roads
future.cut.roads.fwa <- read.table ("future_cut_for_roads_by_fwa.csv", header = T, sep = ",") # new cut by FWA for estimating future roads
future.cut.roads.fwa <- future.cut.roads.fwa %>%
     select (WATERSHED_, TSA_NUMBER, inital_her, year_log, area_km2_f)
names (future.cut.roads.fwa) [1] <- "watershed"
names (future.cut.roads.fwa) [2] <- "tsa"
names (future.cut.roads.fwa) [3] <- "herd"
names (future.cut.roads.fwa) [4] <- "harvest.year"
names (future.cut.roads.fwa) [5] <- "new.area.cut.km2"
future.cut.roads.fwa <- data.frame (future.cut.roads.fwa %>% # future roads (cut) by watershed, TSA, herd and year
                                         group_by (watershed, tsa, herd, harvest.year) %>%
                                         summarise (new.area.cut.km2 = sum (new.area.cut.km2, na.rm = T)))

# Future new cut ALL
future.cut.all.fwa <- read.table ("future_cut_all_by_fwa.csv", header = T, sep = ",") # all new cut by FWA
future.cut.all.fwa <- future.cut.all.fwa %>%
     select (WATERSHED_, TSA_NUMBER, inital_her, year_log, area_km2_f)
names (future.cut.all.fwa) [1] <- "watershed"
names (future.cut.all.fwa) [2] <- "tsa"
names (future.cut.all.fwa) [3] <- "herd"
names (future.cut.all.fwa) [4] <- "harvest.year"
names (future.cut.all.fwa) [5] <- "new.area.cut.km2"
future.cut.all.fwa <- data.frame (future.cut.all.fwa %>% # future roads (cut) by watershed, TSA, herd and year
                                         group_by (watershed, tsa, herd, harvest.year) %>%
                                         summarise (new.area.cut.km2 = sum (new.area.cut.km2, na.rm = T)))

# Put together the dataset
fwa.init.disturb <- full_join (fwa, disturb.fwa, by = c ("watershed", "tsa", "herd"))
fwa.init.disturb <- full_join (fwa.init.disturb, roads.fwa, by = c ("watershed", "tsa", "herd"))
fwa.init.disturb [is.na (fwa.init.disturb)] <- 0

# Calculate initial disturbance and road densities
fwa.init.disturb$disturb.dens.2017 <- fwa.init.disturb$area.disturb.km2 / fwa.init.disturb$fwa.area.km2 # disturbance density (km2/km2)
fwa.init.disturb$road.dens.2017 <- fwa.init.disturb$init.roads.km / fwa.init.disturb$fwa.area.km2 # road density (km/km2)

# Calculate historic cut, by year and add to dataset
fxn.hist.cut <- function (year) {
     data.frame (hist.cut.fwa %>%
                      filter (harvest.year == year) %>%
                      select (watershed, tsa, herd, cut.area.km2))
}

historic.cut.1976 <- fxn.hist.cut (1976)
historic.cut.1977 <- fxn.hist.cut (1977)
historic.cut.1978 <- fxn.hist.cut (1978)
historic.cut.1979 <- fxn.hist.cut (1979)
historic.cut.1980 <- fxn.hist.cut (1980)
historic.cut.1981 <- fxn.hist.cut (1981)
historic.cut.1982 <- fxn.hist.cut (1982)
historic.cut.1983 <- fxn.hist.cut (1983)
historic.cut.1984 <- fxn.hist.cut (1984)
historic.cut.1985 <- fxn.hist.cut (1985)
historic.cut.1986 <- fxn.hist.cut (1986)
historic.cut.1987 <- fxn.hist.cut (1987)
historic.cut.1988 <- fxn.hist.cut (1988)
historic.cut.1989 <- fxn.hist.cut (1989)
historic.cut.1990 <- fxn.hist.cut (1990)
historic.cut.1991 <- fxn.hist.cut (1991)
historic.cut.1992 <- fxn.hist.cut (1992)
historic.cut.1993 <- fxn.hist.cut (1993)
historic.cut.1994 <- fxn.hist.cut (1994)
historic.cut.1995 <- fxn.hist.cut (1995)
historic.cut.1996 <- fxn.hist.cut (1996)
historic.cut.1997 <- fxn.hist.cut (1997)
historic.cut.1998 <- fxn.hist.cut (1998)
historic.cut.1999 <- fxn.hist.cut (1999)
historic.cut.2000 <- fxn.hist.cut (2000)
historic.cut.2001 <- fxn.hist.cut (2001)
historic.cut.2002 <- fxn.hist.cut (2002)
historic.cut.2003 <- fxn.hist.cut (2003)
historic.cut.2004 <- fxn.hist.cut (2004)
historic.cut.2005 <- fxn.hist.cut (2005)
historic.cut.2006 <- fxn.hist.cut (2006)
historic.cut.2007 <- fxn.hist.cut (2007)
historic.cut.2008 <- fxn.hist.cut (2008)
historic.cut.2009 <- fxn.hist.cut (2009)
historic.cut.2010 <- fxn.hist.cut (2010)
historic.cut.2011 <- fxn.hist.cut (2011)
historic.cut.2012 <- fxn.hist.cut (2012)
historic.cut.2013 <- fxn.hist.cut (2013)
historic.cut.2014 <- fxn.hist.cut (2014)
historic.cut.2015 <- fxn.hist.cut (2015)
historic.cut.2016 <- fxn.hist.cut (2016)
names (historic.cut.1976) [4] <- "cut.area.km2.1976"
names (historic.cut.1977) [4] <- "cut.area.km2.1977"
names (historic.cut.1978) [4] <- "cut.area.km2.1978"
names (historic.cut.1979) [4] <- "cut.area.km2.1979"
names (historic.cut.1980) [4] <- "cut.area.km2.1980"
names (historic.cut.1981) [4] <- "cut.area.km2.1981"
names (historic.cut.1982) [4] <- "cut.area.km2.1982"
names (historic.cut.1983) [4] <- "cut.area.km2.1983"
names (historic.cut.1984) [4] <- "cut.area.km2.1984"
names (historic.cut.1985) [4] <- "cut.area.km2.1985"
names (historic.cut.1986) [4] <- "cut.area.km2.1986"
names (historic.cut.1987) [4] <- "cut.area.km2.1987"
names (historic.cut.1988) [4] <- "cut.area.km2.1988"
names (historic.cut.1989) [4] <- "cut.area.km2.1989"
names (historic.cut.1990) [4] <- "cut.area.km2.1990"
names (historic.cut.1991) [4] <- "cut.area.km2.1991"
names (historic.cut.1992) [4] <- "cut.area.km2.1992"
names (historic.cut.1993) [4] <- "cut.area.km2.1993"
names (historic.cut.1994) [4] <- "cut.area.km2.1994"
names (historic.cut.1995) [4] <- "cut.area.km2.1995"
names (historic.cut.1996) [4] <- "cut.area.km2.1996"
names (historic.cut.1997) [4] <- "cut.area.km2.1997"
names (historic.cut.1998) [4] <- "cut.area.km2.1998"
names (historic.cut.1999) [4] <- "cut.area.km2.1999"
names (historic.cut.2000) [4] <- "cut.area.km2.2000"
names (historic.cut.2001) [4] <- "cut.area.km2.2001"
names (historic.cut.2002) [4] <- "cut.area.km2.2002"
names (historic.cut.2003) [4] <- "cut.area.km2.2003"
names (historic.cut.2004) [4] <- "cut.area.km2.2004"
names (historic.cut.2005) [4] <- "cut.area.km2.2005"
names (historic.cut.2006) [4] <- "cut.area.km2.2006"
names (historic.cut.2007) [4] <- "cut.area.km2.2007"
names (historic.cut.2008) [4] <- "cut.area.km2.2008"
names (historic.cut.2009) [4] <- "cut.area.km2.2009"
names (historic.cut.2010) [4] <- "cut.area.km2.2010"
names (historic.cut.2011) [4] <- "cut.area.km2.2011"
names (historic.cut.2012) [4] <- "cut.area.km2.2012"
names (historic.cut.2013) [4] <- "cut.area.km2.2013"
names (historic.cut.2014) [4] <- "cut.area.km2.2014"
names (historic.cut.2015) [4] <- "cut.area.km2.2015"
names (historic.cut.2016) [4] <- "cut.area.km2.2016"
historic.data.list <- list (historic.cut.1976, historic.cut.1977, historic.cut.1978,
                            historic.cut.1979, historic.cut.1980, historic.cut.1981,
                            historic.cut.1982, historic.cut.1983, historic.cut.1984,
                            historic.cut.1985, historic.cut.1986, historic.cut.1987,
                            historic.cut.1988, historic.cut.1989, historic.cut.1990,
                            historic.cut.1991, historic.cut.1992, historic.cut.1993,
                            historic.cut.1994, historic.cut.1995, historic.cut.1996,
                            historic.cut.1997, historic.cut.1998, historic.cut.1999,
                            historic.cut.2000, historic.cut.2001, historic.cut.2002,
                            historic.cut.2003, historic.cut.2004, historic.cut.2005,
                            historic.cut.2006, historic.cut.2007, historic.cut.2008,
                            historic.cut.2009, historic.cut.2010, historic.cut.2011,
                            historic.cut.2012, historic.cut.2013, historic.cut.2014,
                            historic.cut.2015, historic.cut.2016)
historic.cut <- data.frame (Reduce (full_join, historic.data.list))
historic.cut [is.na (historic.cut)] <- 0
data <- dplyr::full_join (fwa.init.disturb, historic.cut, by = c ("watershed", "tsa", "herd"))
data [is.na (data)] <- 0
data [9:49] <- data [9:49] / data$fwa.area.km2 # this converts area to density
names (data) [9] <- "cut.dens.1976"
names (data) [10] <- "cut.dens.1977"
names (data) [11] <- "cut.dens.1978"
names (data) [12] <- "cut.dens.1979"
names (data) [13] <- "cut.dens.1980"
names (data) [14] <- "cut.dens.1981"
names (data) [15] <- "cut.dens.1982"
names (data) [16] <- "cut.dens.1983"
names (data) [17] <- "cut.dens.1984"
names (data) [18] <- "cut.dens.1985"
names (data) [19] <- "cut.dens.1986"
names (data) [20] <- "cut.dens.1987"
names (data) [21] <- "cut.dens.1988"
names (data) [22] <- "cut.dens.1989"
names (data) [23] <- "cut.dens.1990"
names (data) [24] <- "cut.dens.1991"
names (data) [25] <- "cut.dens.1992"
names (data) [26] <- "cut.dens.1993"
names (data) [27] <- "cut.dens.1994"
names (data) [28] <- "cut.dens.1995"
names (data) [29] <- "cut.dens.1996"
names (data) [30] <- "cut.dens.1997"
names (data) [31] <- "cut.dens.1998"
names (data) [32] <- "cut.dens.1999"
names (data) [33] <- "cut.dens.2000"
names (data) [34] <- "cut.dens.2001"
names (data) [35] <- "cut.dens.2002"
names (data) [36] <- "cut.dens.2003"
names (data) [37] <- "cut.dens.2004"
names (data) [38] <- "cut.dens.2005"
names (data) [39] <- "cut.dens.2006"
names (data) [40] <- "cut.dens.2007"
names (data) [41] <- "cut.dens.2008"
names (data) [42] <- "cut.dens.2009"
names (data) [43] <- "cut.dens.2010"
names (data) [44] <- "cut.dens.2011"
names (data) [45] <- "cut.dens.2012"
names (data) [46] <- "cut.dens.2013"
names (data) [47] <- "cut.dens.2014"
names (data) [48] <- "cut.dens.2015"
names (data) [49] <- "cut.dens.2016"
data [is.na (data)] <- 0
data$all.cut.2017 <- data [, 9] + data [, 10] + data [, 11] + data [, 12] + data [, 13] + data [, 14] + data [,15] + data [,16] + data [,17] + data [,18] + data [,19] + data [,20] + data [,21] + data [,22] + data [,23] + data [,24] + data [,25] + data [,26] + data [,27] + data [,28] + data [,29] + data [,30] + data [,31] + data [,32] + data [,33] + data [,34] + data [,35] + data [,36] + data [,37] + data [,38] + data [,39] + data [,40] + data [,41] + data [,42] + data [,43] + data [,44] + data [,45] + data [,46] + data [,47] + data [,48] + data [,49]  

rm ( list = c ('historic.cut.1976', 'historic.cut.1977', 'historic.cut.1978', 'historic.cut.1979', 'historic.cut.1980', 'historic.cut.1981', 'historic.cut.1982', 'historic.cut.1983', 'historic.cut.1984', 'historic.cut.1985', 'historic.cut.1986', 'historic.cut.1987', 'historic.cut.1988', 'historic.cut.1989', 'historic.cut.1990', 'historic.cut.1991', 'historic.cut.1992', 'historic.cut.1993', 'historic.cut.1994', 'historic.cut.1995', 'historic.cut.1996', 'historic.cut.1997', 'historic.cut.1998', 'historic.cut.1999', 'historic.cut.2000', 'historic.cut.2001', 'historic.cut.2002', 'historic.cut.2003', 'historic.cut.2004', 'historic.cut.2005', 'historic.cut.2006', 'historic.cut.2007', 'historic.cut.2008', 'historic.cut.2009', 'historic.cut.2010', 'historic.cut.2011', 'historic.cut.2012', 'historic.cut.2013', 'historic.cut.2014', 'historic.cut.2015', 'historic.cut.2016'))
rm (historic.data.list)

# Calculate new cut (from TSR models), by year and add to dataset
# Fort Nelson data is summarized by decade; need to do the same for FSJ data
fn.data <- future.cut.all.fwa %>%
     filter (tsa == "Fort Nelson TSA")
fsj.data <- future.cut.all.fwa %>%
     filter (tsa == "Fort St. John TSA")
fsj.data$harvest.year [fsj.data$harvest.year == 2017] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2018] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2019] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2020] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2021] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2022] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2023] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2024] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2025] <- 2026
fsj.data$harvest.year [fsj.data$harvest.year == 2027] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2028] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2029] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2030] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2031] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2032] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2033] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2034] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2035] <- 2036
fsj.data$harvest.year [fsj.data$harvest.year == 2037] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2038] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2039] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2040] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2041] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2042] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2043] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2044] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2045] <- 2046
fsj.data$harvest.year [fsj.data$harvest.year == 2047] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2048] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2049] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2050] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2051] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2052] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2053] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2054] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2055] <- 2056
fsj.data$harvest.year [fsj.data$harvest.year == 2057] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2058] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2059] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2060] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2061] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2062] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2063] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2064] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2065] <- 2066
fsj.data$harvest.year [fsj.data$harvest.year == 2067] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2068] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2069] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2070] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2071] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2072] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2073] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2074] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2075] <- 2076
fsj.data$harvest.year [fsj.data$harvest.year == 2077] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2078] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2079] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2080] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2081] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2082] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2083] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2084] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2085] <- 2086
fsj.data$harvest.year [fsj.data$harvest.year == 2087] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2088] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2089] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2090] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2091] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2092] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2093] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2094] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2095] <- 2096
fsj.data$harvest.year [fsj.data$harvest.year == 2097] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2098] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2099] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2100] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2101] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2102] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2103] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2104] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2105] <- 2106
fsj.data$harvest.year [fsj.data$harvest.year == 2107] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2108] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2109] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2110] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2111] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2112] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2113] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2114] <- 2116
fsj.data$harvest.year [fsj.data$harvest.year == 2115] <- 2116
future.cut.all.fwa <- dplyr::union (fsj.data, fn.data)
names (future.cut.all.fwa) [4] <- "harvest.decade"

fxn.new.cut <- function (decade) {
     data.frame (future.cut.all.fwa %>%
                      filter (harvest.decade == decade) %>%
                      select (watershed, tsa, herd, new.area.cut.km2) %>%
                      group_by (watershed, tsa, herd) %>%
                      summarise (new.area.cut.km2 = sum (new.area.cut.km2, na.rm = T)))
}

new.cut.2026 <- fxn.new.cut (2026)
new.cut.2036 <- fxn.new.cut (2036)
new.cut.2046 <- fxn.new.cut (2046)
new.cut.2056 <- fxn.new.cut (2056)
new.cut.2066 <- fxn.new.cut (2066)
new.cut.2076 <- fxn.new.cut (2076)
new.cut.2086 <- fxn.new.cut (2086)
new.cut.2096 <- fxn.new.cut (2096)
new.cut.2106 <- fxn.new.cut (2106)
new.cut.2116 <- fxn.new.cut (2116)
names (new.cut.2026) [4] <- "cut.area.km2.2026"
names (new.cut.2036) [4] <- "cut.area.km2.2036"
names (new.cut.2046) [4] <- "cut.area.km2.2046"
names (new.cut.2056) [4] <- "cut.area.km2.2056"
names (new.cut.2066) [4] <- "cut.area.km2.2066"
names (new.cut.2076) [4] <- "cut.area.km2.2076"
names (new.cut.2086) [4] <- "cut.area.km2.2086"
names (new.cut.2096) [4] <- "cut.area.km2.2096"
names (new.cut.2106) [4] <- "cut.area.km2.2106"
names (new.cut.2116) [4] <- "cut.area.km2.2116"
new.cut.data.list <- list (new.cut.2026, new.cut.2036, new.cut.2046, new.cut.2056, new.cut.2066, new.cut.2076, new.cut.2086, new.cut.2096, new.cut.2106, new.cut.2116)
new.cut.data <- data.frame (Reduce (full_join, new.cut.data.list))
new.cut.data [is.na (new.cut.data)] <- 0
rm ( list = c ('fsj.data', 'fn.data', 'new.cut.data.list', 'new.cut.2026', 'new.cut.2036', 'new.cut.2046', 'new.cut.2056', 'new.cut.2066', 'new.cut.2076', 'new.cut.2086', 'new.cut.2096', 'new.cut.2106', 'new.cut.2116'))
data <- dplyr::full_join (data, new.cut.data, by = c ("watershed", "tsa", "herd"))
data [is.na (data)] <- 0
data [51:60] <- data [51:60] / data$fwa.area.km2 # this converts area to density
data <- data[ -c (1092, 1094), ]
names (data) [51] <- "cut.dens.2026"
names (data) [52] <- "cut.dens.2036"
names (data) [53] <- "cut.dens.2046"
names (data) [54] <- "cut.dens.2056"
names (data) [55] <- "cut.dens.2066"
names (data) [56] <- "cut.dens.2076"
names (data) [57] <- "cut.dens.2086"
names (data) [58] <- "cut.dens.2096"
names (data) [59] <- "cut.dens.2106"
names (data) [60] <- "cut.dens.2116"

# Calculate historical cut density by decade
data$all.cut.1977to1986 <- data$cut.dens.1977 + data$cut.dens.1978 + data$cut.dens.1979 + 
     data$cut.dens.1980 + data$cut.dens.1981 + data$cut.dens.1982 +
     data$cut.dens.1983 + data$cut.dens.1984 + data$cut.dens.1985 +
     data$cut.dens.1986
data$all.cut.1987to1996 <- data$cut.dens.1987 + data$cut.dens.1988 + data$cut.dens.1989 + 
     data$cut.dens.1990 + data$cut.dens.1991 + data$cut.dens.1992 +
     data$cut.dens.1993 + data$cut.dens.1994 + data$cut.dens.1995 +
     data$cut.dens.1996
data$all.cut.1997to2006 <- data$cut.dens.1997 + data$cut.dens.1998 + data$cut.dens.1999 + 
     data$cut.dens.2000 + data$cut.dens.2001 + data$cut.dens.2002 +
     data$cut.dens.2003 + data$cut.dens.2004 + data$cut.dens.2005 +
     data$cut.dens.2006
data$all.cut.2007to2016 <- data$cut.dens.2007 + data$cut.dens.2008 + data$cut.dens.2009 + 
     data$cut.dens.2010 + data$cut.dens.2011 + data$cut.dens.2012 +
     data$cut.dens.2013 + data$cut.dens.2014 + data$cut.dens.2015 +
     data$cut.dens.2016

# Calculate decadal only NEW cut density to use to calculate new ROADS density for each watershed
# Calculate new cut, by year and add to dataset
fxn.road.cut <- function (year) {
     data.frame (future.cut.roads.fwa %>%
                      filter (harvest.year == year) %>%
                      select (watershed, tsa, herd, new.area.cut.km2))
}

road.cut.2026 <- fxn.road.cut (2026)
road.cut.2036 <- fxn.road.cut (2036)
road.cut.2046 <- fxn.road.cut (2046)
road.cut.2056 <- fxn.road.cut (2056)
road.cut.2066 <- fxn.road.cut (2066)
road.cut.2076 <- fxn.road.cut (2076)
road.cut.2086 <- fxn.road.cut (2086)
road.cut.2096 <- fxn.road.cut (2096)
road.cut.2106 <- fxn.road.cut (2106)
road.cut.2116 <- fxn.road.cut (2116)
names (road.cut.2026) [4] <- "road.cut.area.km2.2026"
names (road.cut.2036) [4] <- "road.cut.area.km2.2036"
names (road.cut.2046) [4] <- "road.cut.area.km2.2046"
names (road.cut.2056) [4] <- "road.cut.area.km2.2056"
names (road.cut.2066) [4] <- "road.cut.area.km2.2066"
names (road.cut.2076) [4] <- "road.cut.area.km2.2076"
names (road.cut.2086) [4] <- "road.cut.area.km2.2086"
names (road.cut.2096) [4] <- "road.cut.area.km2.2096"
names (road.cut.2106) [4] <- "road.cut.area.km2.2106"
names (road.cut.2116) [4] <- "road.cut.area.km2.2116"
road.cut.data.list <- list (road.cut.2026, road.cut.2036, road.cut.2046, road.cut.2056, road.cut.2066, road.cut.2076, road.cut.2086, road.cut.2096, road.cut.2106, road.cut.2116)
road.cut.data <- data.frame (Reduce (full_join, road.cut.data.list))
road.cut.data [is.na (road.cut.data)] <- 0
rm ( list = c ('road.cut.data.list', 'road.cut.2026', 'road.cut.2036', 'road.cut.2046', 'road.cut.2056', 'road.cut.2066', 'road.cut.2076', 'road.cut.2086', 'road.cut.2096', 'road.cut.2106', 'road.cut.2116'))
data <- dplyr::full_join (data, road.cut.data, by = c ("watershed", "tsa", "herd"))
data [is.na (data)] <- 0
data [65:74] <- data [65:74] / data$fwa.area.km2 # this converts area to density
names (data) [65] <- "road.cut.dens.2026"
names (data) [66] <- "road.cut.dens.2036"
names (data) [67] <- "road.cut.dens.2046"
names (data) [68] <- "road.cut.dens.2056"
names (data) [69] <- "road.cut.dens.2066"
names (data) [70] <- "road.cut.dens.2076"
names (data) [71] <- "road.cut.dens.2086"
names (data) [72] <- "road.cut.dens.2096"
names (data) [73] <- "road.cut.dens.2106"
names (data) [74] <- "road.cut.dens.2116"

# Calculate decadal road densities using equation from Muhly 2016
# subset data by TSA to apply equation by TSA
fn.data <- data %>%
     filter (tsa == "Fort Nelson TSA")
fsj.data <- data %>%
     filter (tsa == "Fort St. John TSA")

# FSJ
# dropped the intercept from the equation so not to double count roads
fsj.data$road.dens.2026 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2026)
fsj.data$road.dens.2036 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2036)
fsj.data$road.dens.2046 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2046)
fsj.data$road.dens.2056 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2056)
fsj.data$road.dens.2066 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2066)
fsj.data$road.dens.2076 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2076)
fsj.data$road.dens.2086 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2086)
fsj.data$road.dens.2096 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2096)
fsj.data$road.dens.2106 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2106)
fsj.data$road.dens.2116 <- ((1.16 - 0.36) * fsj.data$road.cut.dens.2116)

# FN
fn.data$road.dens.2026 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2026)
fn.data$road.dens.2036 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2036)
fn.data$road.dens.2046 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2046)
fn.data$road.dens.2056 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2056)
fn.data$road.dens.2066 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2066)
fn.data$road.dens.2076 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2076)
fn.data$road.dens.2086 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2086)
fn.data$road.dens.2096 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2096)
fn.data$road.dens.2106 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2106)
fn.data$road.dens.2116 <- ((1.16 - 0.487) * fn.data$road.cut.dens.2116)

# Calculate decadal disturbance densities using equation from Muhly 2016
# FSJ
# dropped the intercept from the equation and used previous decade as 'intercept' (start point)
fsj.data$disturb.dens.2026 <- fsj.data$disturb.dens.2017 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2026 - fsj.data$all.cut.1977to1986)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2026)
fsj.data$disturb.dens.2036 <- fsj.data$disturb.dens.2026 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2036 - fsj.data$all.cut.1987to1996)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2036)
fsj.data$disturb.dens.2046 <- fsj.data$disturb.dens.2036 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2046 - fsj.data$all.cut.1997to2006)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2046)
fsj.data$disturb.dens.2056 <- fsj.data$disturb.dens.2046 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2056 - fsj.data$all.cut.2007to2016)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2056)
fsj.data$disturb.dens.2066 <- fsj.data$disturb.dens.2056 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2066 - fsj.data$cut.dens.2026)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2066)
fsj.data$disturb.dens.2076 <- fsj.data$disturb.dens.2066 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2076 - fsj.data$cut.dens.2036)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2076)
fsj.data$disturb.dens.2086 <- fsj.data$disturb.dens.2076 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2086 - fsj.data$cut.dens.2046)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2086)
fsj.data$disturb.dens.2096 <- fsj.data$disturb.dens.2086 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2096 - fsj.data$cut.dens.2056)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2096)
fsj.data$disturb.dens.2106 <- fsj.data$disturb.dens.2096 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2106 - fsj.data$cut.dens.2066)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2106)
fsj.data$disturb.dens.2116 <- fsj.data$disturb.dens.2106 + 
     ((1.25 + 0.306) * 
           (fsj.data$cut.dens.2116 - fsj.data$cut.dens.2076)) +
     ((0.43 + 0.209) * fsj.data$road.dens.2116)
fsj.data$disturb.dens.2026 [fsj.data$disturb.dens.2026 < 0] <- 0 # some very small negative values (decimal dust) replaced with 0
fsj.data$disturb.dens.2026 [fsj.data$disturb.dens.2026 > 1] <- 1 # disturbance needs to be capped at 1
fsj.data$disturb.dens.2036 [fsj.data$disturb.dens.2036 < 0] <- 0
fsj.data$disturb.dens.2036 [fsj.data$disturb.dens.2036 > 1] <- 1
fsj.data$disturb.dens.2046 [fsj.data$disturb.dens.2046 < 0] <- 0
fsj.data$disturb.dens.2046 [fsj.data$disturb.dens.2046 > 1] <- 1
fsj.data$disturb.dens.2056 [fsj.data$disturb.dens.2056 < 0] <- 0
fsj.data$disturb.dens.2056 [fsj.data$disturb.dens.2056 > 1] <- 1
fsj.data$disturb.dens.2066 [fsj.data$disturb.dens.2066 < 0] <- 0
fsj.data$disturb.dens.2066 [fsj.data$disturb.dens.2066 > 1] <- 1
fsj.data$disturb.dens.2076 [fsj.data$disturb.dens.2076 < 0] <- 0
fsj.data$disturb.dens.2076 [fsj.data$disturb.dens.2076 > 1] <- 1
fsj.data$disturb.dens.2086 [fsj.data$disturb.dens.2086 < 0] <- 0
fsj.data$disturb.dens.2086 [fsj.data$disturb.dens.2086 > 1] <- 1
fsj.data$disturb.dens.2096 [fsj.data$disturb.dens.2096 < 0] <- 0
fsj.data$disturb.dens.2096 [fsj.data$disturb.dens.2096 > 1] <- 1
fsj.data$disturb.dens.2106 [fsj.data$disturb.dens.2106 < 0] <- 0
fsj.data$disturb.dens.2106 [fsj.data$disturb.dens.2106 > 1] <- 1
fsj.data$disturb.dens.2116 [fsj.data$disturb.dens.2116 < 0] <- 0
fsj.data$disturb.dens.2116 [fsj.data$disturb.dens.2116 > 1] <- 1

# Fort Nelson
fn.data$disturb.dens.2026 <- fn.data$disturb.dens.2017 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2026 - fn.data$all.cut.1977to1986)) +
     ((0.43 + 0.178) * fn.data$road.dens.2026)
fn.data$disturb.dens.2036 <- fn.data$disturb.dens.2026 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2036 - fn.data$all.cut.1987to1996)) +
     ((0.43 + 0.178) * fn.data$road.dens.2036)
fn.data$disturb.dens.2046 <- fn.data$disturb.dens.2036 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2046 - fn.data$all.cut.1997to2006)) +
     ((0.43 + 0.178) * fn.data$road.dens.2046)
fn.data$disturb.dens.2056 <- fn.data$disturb.dens.2046 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2056 - fn.data$all.cut.2007to2016)) +
     ((0.43 + 0.178) * fn.data$road.dens.2056)
fn.data$disturb.dens.2066 <- fn.data$disturb.dens.2056 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2066 - fn.data$cut.dens.2026)) +
     ((0.43 + 0.178) * fn.data$road.dens.2066)
fn.data$disturb.dens.2076 <- fn.data$disturb.dens.2066 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2076 - fn.data$cut.dens.2036)) +
     ((0.43 + 0.178) * fn.data$road.dens.2076)
fn.data$disturb.dens.2086 <- fn.data$disturb.dens.2076 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2086 - fn.data$cut.dens.2046)) +
     ((0.43 + 0.178) * fn.data$road.dens.2086)
fn.data$disturb.dens.2096 <- fn.data$disturb.dens.2086 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2096 - fn.data$cut.dens.2056)) +
     ((0.43 + 0.178) * fn.data$road.dens.2096)
fn.data$disturb.dens.2106 <- fn.data$disturb.dens.2096 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2106 - fn.data$cut.dens.2066)) +
     ((0.43 + 0.178) * fn.data$road.dens.2106)
fn.data$disturb.dens.2116 <- fn.data$disturb.dens.2106 + 
     ((1.25 + 0.909) * 
           (fn.data$cut.dens.2116 - fn.data$cut.dens.2076)) +
     ((0.43 + 0.178) * fn.data$road.dens.2116)
fn.data$disturb.dens.2026 [fn.data$disturb.dens.2026 < 0] <- 0 
fn.data$disturb.dens.2026 [fn.data$disturb.dens.2026 > 1] <- 1
fn.data$disturb.dens.2036 [fn.data$disturb.dens.2036 < 0] <- 0
fn.data$disturb.dens.2036 [fn.data$disturb.dens.2036 > 1] <- 1
fn.data$disturb.dens.2046 [fn.data$disturb.dens.2046 < 0] <- 0
fn.data$disturb.dens.2046 [fn.data$disturb.dens.2046 > 1] <- 1
fn.data$disturb.dens.2056 [fn.data$disturb.dens.2056 < 0] <- 0
fn.data$disturb.dens.2056 [fn.data$disturb.dens.2056 > 1] <- 1
fn.data$disturb.dens.2066 [fn.data$disturb.dens.2066 < 0] <- 0
fn.data$disturb.dens.2066 [fn.data$disturb.dens.2066 > 1] <- 1
fn.data$disturb.dens.2076 [fn.data$disturb.dens.2076 < 0] <- 0
fn.data$disturb.dens.2076 [fn.data$disturb.dens.2076 > 1] <- 1
fn.data$disturb.dens.2086 [fn.data$disturb.dens.2086 < 0] <- 0
fn.data$disturb.dens.2086 [fn.data$disturb.dens.2086 > 1] <- 1
fn.data$disturb.dens.2096 [fn.data$disturb.dens.2096 < 0] <- 0
fn.data$disturb.dens.2096 [fn.data$disturb.dens.2096 > 1] <- 1
fn.data$disturb.dens.2106 [fn.data$disturb.dens.2106 < 0] <- 0
fn.data$disturb.dens.2106 [fn.data$disturb.dens.2106 > 1] <- 1
fn.data$disturb.dens.2116 [fn.data$disturb.dens.2116 < 0] <- 0
fn.data$disturb.dens.2116 [fn.data$disturb.dens.2116 > 1] <- 1

# Rejoin the datasets
data <- dplyr::union (fsj.data, fn.data)

# Calculate disturbance by herd
# Total herd area
herd.data <- data %>%
     group_by (herd) %>%
     summarise (herd.area.km2 = sum (fwa.area.km2, na.rm = T))
data <- full_join (data, herd.data, by =  "herd")
data$fwa.prop.herd <- data$fwa.area.km2 / data$herd.area.km2
data$prop.herd.disturb.2017 <- data$disturb.dens.2017 * data$fwa.prop.herd
data$prop.herd.disturb.2026 <- data$disturb.dens.2026 * data$fwa.prop.herd
data$prop.herd.disturb.2036 <- data$disturb.dens.2036 * data$fwa.prop.herd
data$prop.herd.disturb.2046 <- data$disturb.dens.2046 * data$fwa.prop.herd
data$prop.herd.disturb.2056 <- data$disturb.dens.2056 * data$fwa.prop.herd
data$prop.herd.disturb.2066 <- data$disturb.dens.2066 * data$fwa.prop.herd
data$prop.herd.disturb.2076 <- data$disturb.dens.2076 * data$fwa.prop.herd
data$prop.herd.disturb.2086 <- data$disturb.dens.2086 * data$fwa.prop.herd
data$prop.herd.disturb.2096 <- data$disturb.dens.2096 * data$fwa.prop.herd
data$prop.herd.disturb.2106 <- data$disturb.dens.2106 * data$fwa.prop.herd
data$prop.herd.disturb.2116 <- data$disturb.dens.2116 * data$fwa.prop.herd

# Export the data
write.table (data, 
             file = "G:\\!Workgrp\\Analysts\\tmuhly\\Caribou\\boreal_disturbance\\output\\disturb_predict.csv", 
             sep = ",")
# these data were exported and added to arcgis to create maps and to the markdown for the report
# change '.' in field names to '_'; change to number format 
