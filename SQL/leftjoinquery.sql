SELECT t.blockid, t.area, (2018 - harvestyr) as age, openingid, (1) as state, (20-(2018 - harvestyr)) as regendelay FROM 
(SELECT (col1).value::int as blockid, (col1).count::int as area  FROM (
SELECT ST_ValueCount(st_union(ST_Clip(rast, 1, foo.geom, -9999, true)),1,true)  as col1 FROM 
(SELECT st_union(rast) as rast, geom FROM rast.cns_cut_bl, public.gcbp_carib_polygon
		WHERE herd_name in ('Graham','Muskwa') AND ST_Intersects(rast, geom) group by geom ) as foo) as k) as t
INNER JOIN public.cns_cut_bl_polygon
ON t.blockid = public.cns_cut_bl_polygon.cutblockid;


SELECT t.feature_id, bclcs_level_1 FROM 
(SELECT (col1).value::int as feature_id FROM (
SELECT ST_ValueCount(st_union(ST_Clip(rast, 1, foo.geom, -9999, true)),1,true)  as col1 FROM 
(SELECT st_union(rast) as rast, geom FROM rast.veg_comp2003_id, public.gcbp_carib_polygon
		WHERE herd_name in ('Graham','Muskwa') AND ST_Intersects(rast, geom) group by geom ) as foo) as k) as t
INNER JOIN public.veg_comp_lyr_r1_poly_final_spatialv2_2003
ON t.feature_id = public.veg_comp_lyr_r1_poly_final_spatialv2_2003.feature_id;
