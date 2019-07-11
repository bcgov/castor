SELECT g.zoneid FROM (SELECT * FROM public.zone_uwr 
FULL OUTER JOIN
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1,true) AS pvc
   FROM rast.zone_cond_uwr) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value) as g WHERE g.value is NULL;

SELECT * FROM public.zone_uwr WHERE zoneid IN (SELECT g.zoneid FROM (SELECT * FROM public.zone_uwr 
FULL OUTER JOIN
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1,true) AS pvc
   FROM rast.zone_cond_uwr) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value) as g WHERE g.value is NULL);