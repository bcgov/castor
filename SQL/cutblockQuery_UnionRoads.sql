
Create TAble cutseq as
  SELECT a.areaha, a.harvestyr, ST_X(a.point) as X ,ST_Y(a.point) as Y, point FROM (SELECT areaha, harvestyr, ST_PointN(ST_Exteriorring(wkb_geometry) , 1) as point
  FROM cns_cut_bl_polygon) a  


 SELECT a.areaha, a.harvestyr,  ST_X(a.point) as X ,ST_Y(a.point) as Y, point, herd_name FROM sample_caribou_bound, (SELECT areaha, harvestyr, ST_PointN(ST_Exteriorring(wkb_geometry) , 1) as point
  FROM cns_cut_bl_polygon
  WHERE harvestyr ='2000') a 
  Where ST_Within(point, sample_caribou_bound.geom);


SELECT clus_road_class, herd_name, wkb_geometry  FROM roads, sample_caribou_bound
  Where ST_Within(roads.wkb_geometry, sample_caribou_bound.geom);


  
SELECT Count(*) FROM
   roads ;
   
Create table roads as (
SELECT * FROM clus_introads_tsa01
UNION ALL
SELECT * FROM clus_introads_tsa02
UNION ALL
SELECT * FROM clus_introads_tsa03
UNION ALL
SELECT * FROM clus_introads_tsa04
UNION ALL
SELECT * FROM clus_introads_tsa05
UNION ALL
SELECT * FROM clus_introads_tsa07
UNION ALL
SELECT * FROM clus_introads_tsa08
UNION ALL
SELECT * FROM clus_introads_tsa09
UNION ALL
SELECT * FROM clus_introads_tsa10
UNION ALL
SELECT * FROM clus_introads_tsa11
UNION ALL
SELECT * FROM clus_introads_tsa12
UNION ALL
SELECT * FROM clus_introads_tsa13
UNION ALL
SELECT * FROM clus_introads_tsa14
UNION ALL
SELECT * FROM clus_introads_tsa15
UNION ALL
SELECT * FROM clus_introads_tsa16
UNION ALL
SELECT * FROM clus_introads_tsa17
UNION ALL
SELECT * FROM clus_introads_tsa19
UNION ALL
SELECT * FROM clus_introads_tsa20
UNION ALL
SELECT * FROM clus_introads_tsa22
UNION ALL
SELECT * FROM clus_introads_tsa23
UNION ALL
SELECT * FROM clus_introads_tsa24
UNION ALL
SELECT * FROM clus_introads_tsa25
UNION ALL
SELECT * FROM clus_introads_tsa26
UNION ALL
SELECT * FROM clus_introads_tsa27
UNION ALL
SELECT * FROM clus_introads_tsa29
UNION ALL
SELECT * FROM clus_introads_tsa33
UNION ALL
SELECT * FROM clus_introads_tsa39
UNION ALL
SELECT * FROM clus_introads_tsa40
UNION ALL
SELECT * FROM clus_introads_tsa41
UNION ALL
SELECT * FROM clus_introads_tsa43
UNION ALL
SELECT * FROM clus_introads_tsa44
UNION ALL
SELECT * FROM clus_introads_tsa45
UNION ALL
SELECT * FROM clus_introads_tsa46
UNION ALL
SELECT * FROM clus_introads_tsa47
)

SELECT r.road_surface, sum(ST_Length(r.wkb_geometry))/1000 as length_in_km FROM 
integrated_roads AS r, (SELECT * FROM gcbp_carib_polygon WHERE herd_name = '",caribouHerd(),"') AS m 
WHERE ST_Contains(m.geom,r.wkb_geometry) 
GROUP BY m.herd_name, r.road_surface
ORDER BY m.herd_name, r.road_surface

SELECT harvestyr, x, y from cutseq, (Select * FROM gcbp_carib_polygon WHERE herd_name = 'Muskwa') as h
WHERE h.geom && cutseq.point /* Uses GiST index with the polygon's bounding box */
AND ST_Contains(h.geom ,cutseq.point)
ORDER BY harvestyr; 

/*For the clusgetroads*/
SELECT clus_road_class, wkb_geometry FROM pre_roads, (SELECT geom FROM gcbp_carib_polygon WHERE herd_name = 'Muskwa') as h 
WHERE h.geom && pre_roads.wkb_geometry /* Uses GiST index with the polygon's bounding box */
AND ST_Contains(h.geom, pre_roads.wkb_geometry)
ORDER BY clus_road_class; 

SELECT road_class, wkb_geometry FROM integrated_roads, (SELECT geom FROM gcbp_carib_polygon WHERE herd_name = 'Hart Ranges') as h 
WHERE h.geom && integrated_roads.wkb_geometry /* Uses GiST index with the polygon's bounding box */
AND ST_Contains(h.geom, integrated_roads.wkb_geometry)
ORDER BY road_class; 

SELECT clus_road_class, st_length(wkb_geometry)/1000 as length_km, wkb_geometry FROM pre_roads,(SELECT geom FROM gcbp_carib_polygon 
                         WHERE herd_name = 'Chinchaga') as h 
                         WHERE h.geom  && pre_roads.wkb_geometry 
                         AND ST_Contains(h.geom, pre_roads.wkb_geometry);

SELECT harvestyr, x, y, point from cutseq, 
              (Select geom FROM gcbp_carib_polygon WHERE herd_name = 'Chinchaga') as h
              WHERE h.geom && cutseq.point 
              AND ST_Contains(h.geom ,cutseq.point)
              ORDER BY harvestyr
              
                        