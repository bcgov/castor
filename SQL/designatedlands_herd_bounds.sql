create table designated_herd_bounds2 as
	select foo.herd_name, desig, category, st_intersection(foo.geom, wkb_geometry) as geom FROM
	public.designatedlands, (select herd_name,  shape as geom 
							 from bc_caribou_herd_boundary_v20200507 where
						  herd_name <> 'NA') as foo
						  where st_intersects(foo.geom, wkb_geometry);
ALTER TABLE designated_herd_bounds2 ADD COLUMN id SERIAL PRIMARY KEY;

update designated_herd_bounds2 set geom = st_multi(st_collectionextract(st_makevalid(geom), 3));
ALTER TABLE designated_herd_bounds2 ALTER COLUMN geom 
    SET DATA TYPE geometry(MultiPolygon,3005) USING ST_Multi(geom);

select distinct(category) from designated_herd_bounds2 ;
	
create table designated_herd_bounds3 as select herd_name, desig, category, st_union(geom) as geom 
FROM designated_herd_bounds2 group by herd_name, desig, category;
ALTER TABLE designated_herd_bounds3 ALTER COLUMN geom 
    SET DATA TYPE geometry(MultiPolygon,3005) USING ST_Multi(geom);