create table caribou_sm_forest_area as (
	
	select a.herd_name, a.bc_habitat, sum(ST_Area(ST_Intersection(a.geom, b.geom)))
FROM (select herd_name, bc_habitat, wkb_geometry as geom from public.bc_caribou_linework_v20200507_shp_core_matrix 
where herd_name in ('Barkerville', 'Wells_Gray_South','Wells_Gray_North','Central_Selkirks',
					'Columbia_North','Columbia_South', 'Groundhog', 'Hart_Ranges', 'Narrow_Lake', 
					'North_Cariboo', 'Purcell_Central', 'Purcells_South', 'South_Selkirks')) as a, 
(select shape as geom from veg_comp_lyr_r1_poly2019 where bclcs_level_2 = 'T')
as b
WHERE ST_Intersects(a.geom, b.geom)
GROUP BY a.herd_name, a.bc_habitat);



with hr as (SELECT wkb_geometry, bc_habitat, herd_name 
							from hart_ranges_south_bnds),
	forest as (SELECT shape
FROM veg_comp_lyr_r1_poly2019 
WHERE bclcs_level_2 = 'T' and 
ST_Intersects(shape, 'SRID=3005;POLYGON((1237665.5001 943506.823450048,1237665.5001 1073059.65781366,1399606.37521117 1073059.65781366,1399606.37521117 943506.823450048,1237665.5001 943506.823450048))'::geometry))
select sum(st_area(st_intersection(hr.wkb_geometry, forest.shape))/10000) as area, hr.bc_habitat, hr.herd_name 
from hr, forest where st_intersects (hr.wkb_geometry, forest.shape) group by hr.bc_habitat, hr.herd_name 

select st_astext(st_envelope(st_union(wkb_geometry))) from hart_ranges_south_bnds;

with core as (SELECT herd_name, wkb_geometry from hart_ranges_south_bnds 
			  where bc_habitat = 'Core'), 
	nohab as (SELECT shape from veg_comp_lyr_r1_poly2019 WHERE bclcs_level_5 in ('GL', 'TA') or 
			  non_productive_descriptor_cd in ('ICE', 'L', 'RIV'))  
select sum(st_area(st_intersection(core.wkb_geometry, nohab.shape))/10000) as area, 
core.herd_name from core, nohab where st_intersects(core.wkb_geometry, nohab.shape) group by core.herd_name ;

