SELECT * FROM public.zone_uwr 
FULL OUTER JOIN
(SELECT (pvc).value as value, SUM((pvc).count) as count
 FROM (SELECT ST_ValueCount(rast,1) AS pvc
   FROM rast.zone_uwr) AS f
 GROUP BY value ORDER BY value) as h
 ON zoneid = value
 ORDER BY zoneid, value;


 SELECT * FROM public.zone_uwr WHERE label = 'u-3-003';