#FROM SSC install the following

#install Oracle 11g from SSC (https://selfservecentre.gov.bc.ca/?)
#install OracleConnections FLNR from SSC

SET ENV # (https://www.google.ca/search?q=set+environment+windows&oq=set+environment+windows&aqs=chrome..69i57j0l5.3583j0j4&sourceid=chrome&ie=UTF-8)
set OCI_LIB64=C:\ORACLE\ORAHOME_11g\bin
New = OCI_LIB64
Variable Value = C:\ORACLE\ORAHOME_11g\bin
#set OCI_INC=C:\ORACLE\ORAHOME_11g\oci\include  doesn't seem to be requried


#From: http://www.oracle.com/technetwork/database/database-technologies/r/roracle/downloads/index.html
#copy ROracle_1.2-1.zip

#(or copy from G:\!Project\U3\Win7Apps\Oracle)

#Copy this to C:/data/temp_install
# From this folder, copy oci_dlls to C:\Oracle\ORAHOME_11g\bin AND to where you ROracle package was installed

#In an R session:
setwd ('C:/Data/temp_install')
install.packages('ROracle_1.2-1.zip', repos=NULL)

require (rgdal)
require (ROracle)
drv <- dbDriver("Oracle")
connect.string <-"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP) (HOST=BCGW.BCGOV)(PORT=1521)) (CONNECT_DATA=(SERVICE_NAME=IDWPROD1.BCGOV)))"

con <- dbConnect(drv, username = "...", password = "...", dbname = connect.string)
t <- dbGetQuery (con, "select count(*)  from whse_forest_vegetation.veg_comp_lyr_r1_poly")
t

dbDisconnect(con)



get instant client from :
http://www.oracle.com/technetwork/topics/winx64soft-089540.html
get the 64 bit version

need to set: ENV OCI_LIB64 to point to the ocit.dll

try C:\Oracle\orahome_11g\bin




Used LDAP adapter to resolve the alias
(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP) (HOST=BCGW.BCGOV)(PORT=1521)) (CONNECT_DATA=(SERVICE_NAME=IDWPROD1.BCGOV)))
OK (10 msec)