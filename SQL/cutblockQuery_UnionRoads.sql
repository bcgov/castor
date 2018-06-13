

  SELECT a.areaha, a.harvestyr, ST_X(a.point) as X ,ST_Y(a.point) as Y, point FROM (SELECT areaha, harvestyr, ST_PointN(ST_Exteriorring(wkb_geometry) , 1) as point
  FROM cns_cut_bl_polygon
  WHERE harvestyr ='2000') a  


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