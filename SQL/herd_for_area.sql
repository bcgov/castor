create table caribou_sm_forest_area as (select a.herd_name, a.bc_habitat, sum(ST_Area(ST_Intersection(a.geom, b.geom)))
FROM (select herd_name, bc_habitat, wkb_geometry as geom from public.bc_caribou_linework_v20200507_shp_core_matrix 
where herd_name in ('Barkerville', 'Wells_Gray_South','Wells_Gray_North','Central_Selkirks',
					'Columbia_North','Columbia_South', 'Groundhog', 'Hart_Ranges', 'Narrow_Lake', 
					'North_Cariboo', 'Purcell_Central', 'Purcells_South', 'South_Selkirks')) as a, 
(select shape as geom from veg_comp_lyr_r1_poly2019 where bclcs_level_2 = 'T')
as b
WHERE ST_Intersects(a.geom, b.geom)
GROUP BY a.herd_name, a.bc_habitat);