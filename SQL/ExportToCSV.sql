/*-----------------------------------------------------------------------------------------------------------------------------------------------
SQL Script For Postgres for exporting to CSV File

Mike Fowler
GIS Analyst
July 2018

--Unable to write to Network Drives - must be a configuration option of the DB Server.  Writing to local, then copying as required. 
-----------------------------------------------------------------------------------------------------------------------------------------------*/
/*-------------Copy the V_CLUS_HERD_BY_TSA to CSV File------------------------------------------------------------------------------------------*/
--COPY (SELECT * FROM V_CLUS_HERD_BY_TSA) TO  '//SPATIALFILES2.BCGOV/WORK/FOR/VIC/HTS/ANA/Workarea/mwfowler/CLUS/Data/V_CLUS_HERD_BY_TSA.CSV' WITH DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM V_CLUS_HERD_BY_TSA) TO  'C:/Data/V_CLUS_HERD_BY_TSA.CSV' WITH DELIMITER ',' CSV HEADER;
/*-------------Copy the V_CLUS_TSA_BY_HERD to CSV File------------------------------------------------------------------------------------------*/
--COPY (SELECT * FROM V_CLUS_TSA_BY_HERD) TO  '//SPATIALFILES2.BCGOV/WORK/FOR/VIC/HTS/ANA/Workarea/mwfowler/CLUS/Data/V_CLUS_TSA_BY_HERD.CSV' WITH DELIMITER ',' CSV HEADER;
COPY (SELECT * FROM V_CLUS_TSA_BY_HERD) TO  'C:/Data/V_CLUS_TSA_BY_HERD.CSV' WITH DELIMITER ',' CSV HEADER;