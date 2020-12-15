select foo.herd_name, foo.bc_habitat, min(cutseq.harvestyr) from 
(select herd_name, bc_habitat, wkb_geometry from bc_caribou_linework_v20200507_shp_core_matrix
where herd_name in('Barkerville', 'Central_Selkirks','Columbia_North',
				   'Columbia_South', 'Groundhog', 'Narrow_Lake', 'North_Cariboo', 
				   'Purcells_South', 'South_Selkirks', 
				   'Wells_Gray_South','Wells_Gray_North','Hart_Ranges')) as foo,
				   cutseq where st_contains(wkb_geometry, point ) group by herd_name, bc_habitat;
				   
select foo.herd_name, foo.bc_habitat, min(cutseq.harvestyr) from 
(select herd_name, bc_habitat, wkb_geometry from bc_caribou_linework_v20200507_shp_core_matrix
where herd_name in('Barkerville', 'Central_Selkirks','Columbia_North',
				   'Columbia_South', 'Groundhog', 'Narrow_Lake', 'North_Cariboo', 
				   'Purcells_South', 'South_Selkirks', 
				   'Wells_Gray_South','Wells_Gray_North','Hart_Ranges')) as foo,
				   cutseq where st_contains(wkb_geometry, point ) group by herd_name, bc_habitat;
				   
		   
				  			   