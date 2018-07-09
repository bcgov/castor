/*Example create summary tables for intersection herd boundary with cutblocks or fire*/
Create TAble cb_sum As
SELECT SUM(ST_Area(ST_Intersection(y.geom, b.wkb_geometry ))) AS sumarea, herd_name ,harvestyr
      FROM public.cns_cut_bl_polygon b, public.gcbp_carib_polygon y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom) 
      GROUP BY harvestyr, herd_name
      ORDER BY  herd_name, harvestyr;
Create TAble fire_sum As
SELECT SUM(ST_Area(ST_Intersection(y.geom, b.wkb_geometry ))) AS sumarea, herd_name ,fire_year
      FROM public.h_fire_ply_polygon b, public.gcbp_carib_polygon y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom) 
      GROUP BY fire_year, herd_name
      ORDER BY  herd_name, fire_year;
      
Create TAble rd_sum As
SELECT SUM(ST_Length(ST_Intersection(y.geom, b.wkb_geometry ))) AS sumlength, herd_name , road_surface
      FROM public.integrated_roads b, public.gcbp_carib_polygon y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom) 
      GROUP BY herd_name , road_surface
      ORDER BY  herd_name , road_surface;

/*Example Transform the geometery*/
ALTER TABLE public.uwr_caribou_no_harvest_20180627 
 ALTER COLUMN geom TYPE geometry(MultiPolygon,3005) 
  USING ST_Transform(geom,3005);
  
/*Example to Select within a distance of a polygon*/
SELECT wha_caribou_no_harvest_20180627.approval_year, wha_caribou_no_harvest_20180627.geom 
   FROM public.wha_caribou_no_harvest_20180627 INNER JOIN public.gcbp_carib_polygon
      ON ST_DWithin(wha_caribou_no_harvest_20180627.geom, gcbp_carib_polygon.geom, 20000)
WHERE gcbp_carib_polygon.herd_name = 'Chinchaga';

SELECT uwr_caribou_no_harvest_20180627.approval_year, uwr_caribou_no_harvest_20180627.geom 
     FROM public.uwr_caribou_no_harvest_20180627 INNER JOIN public.gcbp_carib_polygon
     ON ST_DWithin(uwr_caribou_no_harvest_20180627.geom, gcbp_carib_polygon.geom, 20000)
     WHERE gcbp_carib_polygon.herd_name = 'Rabbit'

 SELECT uwr_caribou_no_harvest_20180627.approval_year
                                    FROM public.uwr_caribou_no_harvest_20180627 INNER JOIN public.gcbp_carib_polygon
                                    ON ST_DWithin(uwr_caribou_no_harvest_20180627.geom, gcbp_carib_polygon.geom, 20000)
                                    WHERE gcbp_carib_polygon.herd_name = 'Rabbit'
                                    

SELECT SUM(shape_length) as sum_leng, bcgw_source, road_class,road_surface,petrlm_access_road_type, proponent FROM public.integrated_roads 
Group by bcgw_source, road_class,road_surface,petrlm_access_road_type, proponent
ORDER BY bcgw_source, road_class,road_surface,petrlm_access_road_type, proponent;

SELECT * FROM wha_caribou_no_harvest_20180627 WHERE geom &&  'BOX3D(501425.3  482726.5 , 1726725.4 1698464.0 )'::box3d 

SELECT 
  m.herd_name, r.road_surface, 
  sum(ST_Length(r.wkb_geometry))/1000 as roads_km 
FROM 
  integrated_roads AS r,  
  (SELECT * FROM gcbp_carib_polygon WHERE herd_name = 'Snake-Sahtaneh') AS m 
WHERE
  ST_Contains(m.geom,r.wkb_geometry) 
GROUP BY m.herd_name, r.road_surface
ORDER BY m.herd_name, r.road_surface; 












*