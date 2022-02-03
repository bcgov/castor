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
WITH gs AS (select scenario, compartment, timeperiod, m_gs, (case when scenario = 'golden_central_rockies_ch_he0d_m15d' then 1 else 0 end) as baseline from golden_tsa.growingstock 
			where scenario in ('golden_columbia_north_nh', 'golden_central_rockies_ch_he0d_m15d', 'golden_all_nh')), 
h as (SELECT scenario, compartment, timeperiod, volume
	FROM golden_tsa.harvest where scenario in ('golden_columbia_north_nh', 'golden_central_rockies_ch_he0d_m15d','golden_all_nh')),
view1 as( SELECT gs.scenario, gs.compartment, gs.timeperiod, gs.baseline, m_gs, volume
  FROM gs 
  left JOIN h 
		 ON gs.scenario = h.scenario and gs.compartment = h.compartment and gs.timeperiod = h.timeperiod),
view2 as (select * from view1 where baseline = 1),
view3 as (select view2.scenario as base_scen, view2.timeperiod as base_time, view2.m_gs as base_m_gs, 
  view2.volume as base_volume,  alt.* from  view2
  inner join (select * from view1 where baseline = 0) as alt 
  on view2.compartment = alt.compartment and view2.timeperiod = alt.timeperiod)
select * from view3;
  
  
  