/*Herd specific*/
WITH dist as ( select (case when scenario = 'golden_central_rockies_ch_he0d_m15d' then 1 else 0 end) as baseline, split_part(critical_hab, ' ', 1) AS herd, sum(cut40) as cut40, sum(road50) as r50, scenario, compartment, timeperiod 
  from golden_tsa.disturbance where scenario in ('golden_columbia_north_nh', 'golden_central_rockies_ch_he0d_m15d', 'golden_all_nh') group by scenario, compartment, timeperiod, herd),
view2 as (select * from dist where baseline = 1),
view3 as (select view2.scenario as base_scen, view2.timeperiod as base_time, 
  
  view2.herd as base_herd,view2.cut40 as base_cut40, view2.r50 as base_r50, alt.* from  view2
  inner join (select * from dist where baseline = 0) as alt 
  on view2.compartment = alt.compartment and view2.timeperiod = alt.timeperiod and view2.herd = alt.herd)
select * from view3;

/*Non-herd specific*/
WITH view1 AS (select scenario, compartment, timeperiod, m_gs as variable, 'm_gs' as ind_name from golden_tsa.growingstock 
			where scenario in ('golden_columbia_north_nh', 'golden_central_rockies_ch_he0d_m15d', 'golden_all_nh')
			Union All
 SELECT scenario, compartment, timeperiod, volume as variable, 'vol_h' as ind_name
	FROM golden_tsa.harvest where scenario in ('golden_columbia_north_nh', 'golden_central_rockies_ch_he0d_m15d','golden_all_nh')
Union all
SELECT scenario, compartment, timeperiod, sum(cut80) as variable, split_part(critical_hab, ' ', 1) AS ind_name 
	FROM golden_tsa.disturbance where scenario in ('golden_columbia_north_nh', 'golden_central_rockies_ch_he0d_m15d','golden_all_nh')
		group by scenario, compartment, timeperiod, ind_name)
  
select scenario, compartment, timeperiod, COALESCE(variable, 0)as variable, ind_name from view1
where ind_name is not null;
  
  