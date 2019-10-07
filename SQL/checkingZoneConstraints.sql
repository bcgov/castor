--UWR -- OK
SELECT * FROM public.zone_uwr WHERE zoneid IN (SELECT g.zoneid FROM (SELECT * FROM public.zone_uwr 
FULL OUTER JOIN
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1,true) AS pvc
   FROM rast.zone_cond_uwr) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value) as g WHERE g.value is NULL);
 
--Wha's-- OK
 SELECT * FROM public.zone_wha WHERE zoneid IN (SELECT g.zoneid FROM (SELECT * FROM public.zone_wha 
FULL OUTER JOIN
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1,true) AS pvc
   FROM rast.zone_cond_wha) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value) as g WHERE g.value is NULL);
 
 --Vqo's -- NEED TO CHECK 
 SELECT * FROM public.zone_vqo WHERE zoneid IN (SELECT g.zoneid FROM (SELECT * FROM public.zone_vqo
FULL OUTER JOIN
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1,true) AS pvc
   FROM rast.zone_cond_vqo) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value) as g WHERE g.value is NULL);
 
  --beo's -- OK
 SELECT * FROM public.zone_beo WHERE zoneid IN (SELECT g.zoneid FROM (SELECT * FROM public.zone_beo
FULL OUTER JOIN
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1,true) AS pvc
   FROM rast.zone_cond_beo) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value) as g WHERE g.value is NULL);
 
   --fsw's -- NEEd TO CHECK
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1,true) AS pvc
   FROM rast.zone_cond_fsw) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value) as g WHERE g.value is NULL);