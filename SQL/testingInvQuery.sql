SELECT feature_id as fid, proj_age_1 as age, proj_height_1 as height , crown_closure as crownclosure FROM 
veg_comp_lyr_r1_poly_finalv3_deliveryv2
 WHERE feature_id IN ( 2244131, 2244131, 2244131, 2244131, 2244131, 2244131, 2244131 ,1975241 ,1975241,
  3114307, 3114307 ,3114307, 1956559 ,3322803 ,3322803);

SELECT feature_id as fid, proj_age_1 as age, proj_height_1 as height  from veg_comp_lyr_r1_poly_finalv3_deliveryv2 a, study_area_compart b
WHERE tsb_number IN ('08B') AND ST_Intersects(a.wkb_geometry, b.wkb_geometry)

SELECT st_valueCount(st_union(ST_Clip(foo.rast, 1, foo.wkb_geometry, true))) as pvc FROM 
(SELECT st_union(rast) as rast,wkb_geometry from rast.vri2002_id, study_area_compart
WHERE tsb_number IN ('08B') AND ST_Intersects(rast, wkb_geometry) group by wkb_geometry ) as foo
        