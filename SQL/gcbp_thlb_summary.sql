 create table gcbp_thlb_sum as 
  SELECT x.herd_name, (ST_SummaryStatsAgg(x.intersectx,1,true)).* 
  FROM
       (SELECT herd_name, ST_Intersection(rast,1,ST_AsRaster(geom, rast),1) as intersectx
       FROM rast.bc_thlb2018, (select herd_name, st_union(wkb_geometry) as geom FROM bc_carib_poly_20090904 group by herd_name) as t
       WHERE ST_Intersects(geom, rast)) as x
  WHERE x.intersectx IS NOT NULL
  GROUP BY herd_name;