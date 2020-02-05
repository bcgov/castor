
create table prov_yields_summary_tipsy as 
select sum(out1.tvol*(out1.polygon_area/out1.tarea)) as tvol, out1.bec_zone, out1.bec_subzone from
(
select feature_id, veg_comp_spatial.bec_zone, veg_comp_spatial.bec_subzone,polygon_area, yc.tvol, area.tarea from veg_comp_spatial
	JOIN (select tvol, ycid from yieldcurves where age = 80) as yc
	ON (yc.ycid = feature_id)
	JOIN (select bec_zone, bec_subzone, sum (polygon_area) as tarea 
		  from veg_comp_spatial group by bec_zone, bec_subzone) as area
	ON (area.bec_zone = veg_comp_spatial.bec_zone and area.bec_subzone= veg_comp_spatial.bec_subzone)
) as out1
group by out1.bec_zone, out1.bec_subzone;


create table prov_yields_summary_vdyp as 
select sum(out1.tvol*(out1.polygon_area/out1.tarea)) as tvol, out1.bec_zone, out1.bec_subzone from
(
select vdyp_vri2018.yc_grp, vdyp.tvol, vdyp_vri2018.feature_id, bec.bec_zone_code as bec_zone, 
bec.bec_subzone, bec.polygon_area, area.tarea
from vdyp_vri2018
JOIN (select feature_id, bec_zone_code, bec_subzone, polygon_area 
	  from veg_comp_lyr_r1_poly2018) as bec
on (bec.feature_id = vdyp_vri2018.feature_id)
JOIN (select tvol, yc_grp from yieldcurves where age = 80) as vdyp
on (vdyp.yc_grp = vdyp_vri2018.yc_grp)
JOIN (select bec_zone_code as bec_zone, bec_subzone, sum (polygon_area) as tarea 
		  from  veg_comp_lyr_r1_poly2018 group by bec_zone_code, bec_subzone) as area
ON (area.bec_zone = bec.bec_zone_code and area.bec_subzone= bec.bec_subzone)
)as out1
group by out1.bec_zone, out1.bec_subzone;

select * from prov_yields_summary_vdyp;


	
	