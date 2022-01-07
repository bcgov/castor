
alter table lakes_tsa.scenarios add column rank double precision default 0.0; UPDATE lakes_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from lakes_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from lakes_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where lakes_tsa.scenarios.scenario = subq.scenario;

alter table itcha_ilgachuz.scenarios add column rank double precision default 0.0; UPDATE itcha_ilgachuz.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from itcha_ilgachuz.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from itcha_ilgachuz.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where itcha_ilgachuz.scenarios.scenario = subq.scenario;

alter table kamloops_tsa.scenarios add column rank double precision default 0.0; UPDATE kamloops_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from kamloops_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from kamloops_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where kamloops_tsa.scenarios.scenario = subq.scenario;

alter table cascadia_kootenay_block.scenarios add column rank double precision default 0.0; UPDATE cascadia_kootenay_block.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from cascadia_kootenay_block.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from cascadia_kootenay_block.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where cascadia_kootenay_block.scenarios.scenario = subq.scenario;

alter table itcha_ilgachuz_plan.scenarios add column rank double precision default 0.0; UPDATE itcha_ilgachuz_plan.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from itcha_ilgachuz_plan.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from itcha_ilgachuz_plan.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where itcha_ilgachuz_plan.scenarios.scenario = subq.scenario;

alter table quesnel_tsa.scenarios add column rank double precision default 0.0; UPDATE quesnel_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from quesnel_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from quesnel_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where quesnel_tsa.scenarios.scenario = subq.scenario;

alter table golden_tsa.scenarios add column rank double precision default 0.0; UPDATE golden_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from golden_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from golden_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where golden_tsa.scenarios.scenario = subq.scenario;

alter table central_group.scenarios add column rank double precision default 0.0; UPDATE central_group.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from central_group.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from central_group.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where central_group.scenarios.scenario = subq.scenario;

alter table dawson_creek_tsa.scenarios add column rank double precision default 0.0; UPDATE dawson_creek_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from dawson_creek_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from dawson_creek_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where dawson_creek_tsa.scenarios.scenario = subq.scenario;

alter table morice_tsa.scenarios add column rank double precision default 0.0; UPDATE morice_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from morice_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from morice_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where morice_tsa.scenarios.scenario = subq.scenario;

alter table okanagan_tsa.scenarios add column rank double precision default 0.0; UPDATE okanagan_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from okanagan_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from okanagan_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where okanagan_tsa.scenarios.scenario = subq.scenario;

alter table prince_george_tsa.scenarios add column rank double precision default 0.0; UPDATE prince_george_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from prince_george_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from prince_george_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where prince_george_tsa.scenarios.scenario = subq.scenario;

alter table mackenzie_tsa.scenarios add column rank double precision default 0.0; UPDATE mackenzie_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from mackenzie_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from mackenzie_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where mackenzie_tsa.scenarios.scenario = subq.scenario;

alter table tfl14.scenarios add column rank double precision default 0.0; UPDATE tfl14.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl14.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl14.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl14.scenarios.scenario = subq.scenario;

alter table kootenaylake_tsa.scenarios add column rank double precision default 0.0; UPDATE kootenaylake_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from kootenaylake_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from kootenaylake_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where kootenaylake_tsa.scenarios.scenario = subq.scenario;

alter table williams_lake_tsa.scenarios add column rank double precision default 0.0; UPDATE williams_lake_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from williams_lake_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from williams_lake_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where williams_lake_tsa.scenarios.scenario = subq.scenario;

alter table revelstoke_tsa.scenarios add column rank double precision default 0.0; UPDATE revelstoke_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from revelstoke_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from revelstoke_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where revelstoke_tsa.scenarios.scenario = subq.scenario;

alter table tfl56.scenarios add column rank double precision default 0.0; UPDATE tfl56.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl56.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl56.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl56.scenarios.scenario = subq.scenario;

alter table robsonvalley_tsa.scenarios add column rank double precision default 0.0; UPDATE robsonvalley_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from robsonvalley_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from robsonvalley_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where robsonvalley_tsa.scenarios.scenario = subq.scenario;

alter table tfl18.scenarios add column rank double precision default 0.0; UPDATE tfl18.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl18.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl18.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl18.scenarios.scenario = subq.scenario;


alter table tfl23.scenarios add column rank double precision default 0.0; UPDATE tfl23.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl23.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl23.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl23.scenarios.scenario = subq.scenario;

alter table tfl55.scenarios add column rank double precision default 0.0; UPDATE tfl55.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl55.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl55.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl55.scenarios.scenario = subq.scenario;

alter table mackenzie_sw_tsa.scenarios add column rank double precision default 0.0; UPDATE mackenzie_sw_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from mackenzie_sw_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from mackenzie_sw_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where mackenzie_sw_tsa.scenarios.scenario = subq.scenario;

alter table tfl33.scenarios add column rank double precision default 0.0; UPDATE tfl33.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl33.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl33.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl33.scenarios.scenario = subq.scenario;

alter table tfl30.scenarios add column rank double precision default 0.0; UPDATE tfl30.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl30.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl30.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl30.scenarios.scenario = subq.scenario;

alter table tfl48.scenarios add column rank double precision default 0.0; UPDATE tfl48.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl48.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl48.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl48.scenarios.scenario = subq.scenario;

alter table tfl41.scenarios add column rank double precision default 0.0; UPDATE tfl41.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl41.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl41.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl41.scenarios.scenario = subq.scenario;

alter table tfl1.scenarios add column rank double precision default 0.0; UPDATE tfl1.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl1.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl1.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl1.scenarios.scenario = subq.scenario;

alter table pacific_tsa.scenarios add column rank double precision default 0.0; UPDATE pacific_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from pacific_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from pacific_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where pacific_tsa.scenarios.scenario = subq.scenario;

alter table tfl52.scenarios add column rank double precision default 0.0; UPDATE tfl52.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl52.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl52.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl52.scenarios.scenario = subq.scenario;

alter table invermere_tsa.scenarios add column rank double precision default 0.0; UPDATE invermere_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from invermere_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from invermere_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where invermere_tsa.scenarios.scenario = subq.scenario;

alter table cascadia_cariboo_chilcotin.scenarios add column rank double precision default 0.0; UPDATE cascadia_cariboo_chilcotin.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from cascadia_cariboo_chilcotin.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from cascadia_cariboo_chilcotin.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where cascadia_cariboo_chilcotin.scenarios.scenario = subq.scenario;

alter table cascadia_okanagan_columbia.scenarios add column rank double precision default 0.0; UPDATE cascadia_okanagan_columbia.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from cascadia_okanagan_columbia.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from cascadia_okanagan_columbia.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where cascadia_okanagan_columbia.scenarios.scenario = subq.scenario;

alter table cascadia_blk10_tsa.scenarios add column rank double precision default 0.0; UPDATE cascadia_blk10_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from cascadia_blk10_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from cascadia_blk10_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where cascadia_blk10_tsa.scenarios.scenario = subq.scenario;

alter table tfl53.scenarios add column rank double precision default 0.0; UPDATE tfl53.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from tfl53.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from tfl53.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where tfl53.scenarios.scenario = subq.scenario;

alter table cranbrook_tsa.scenarios add column rank double precision default 0.0; UPDATE cranbrook_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from cranbrook_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from cranbrook_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where cranbrook_tsa.scenarios.scenario = subq.scenario;

alter table onehundred_mile_tsa.scenarios add column rank double precision default 0.0; UPDATE onehundred_mile_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from onehundred_mile_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from onehundred_mile_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where onehundred_mile_tsa.scenarios.scenario = subq.scenario;

alter table fort_st_john_tsa.scenarios add column rank double precision default 0.0; UPDATE fort_st_john_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from fort_st_john_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from fort_st_john_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where fort_st_john_tsa.scenarios.scenario = subq.scenario;

alter table great_bear_rainforest_north_tsa.scenarios add column rank double precision default 0.0; UPDATE great_bear_rainforest_north_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from great_bear_rainforest_north_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from great_bear_rainforest_north_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where great_bear_rainforest_north_tsa.scenarios.scenario = subq.scenario;

alter table great_bear_rainforest_south_tsa.scenarios add column rank double precision default 0.0; UPDATE great_bear_rainforest_south_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from great_bear_rainforest_south_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from great_bear_rainforest_south_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where great_bear_rainforest_south_tsa.scenarios.scenario = subq.scenario;

alter table fisher_central_bc.scenarios add column rank double precision default 0.0; UPDATE fisher_central_bc.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from fisher_central_bc.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from fisher_central_bc.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where fisher_central_bc.scenarios.scenario = subq.scenario;

alter table kalum_tsa.scenarios add column rank double precision default 0.0; UPDATE kalum_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from kalum_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from kalum_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where kalum_tsa.scenarios.scenario = subq.scenario;

alter table test_quesnel_tsa.scenarios add column rank double precision default 0.0; UPDATE test_quesnel_tsa.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from test_quesnel_tsa.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from test_quesnel_tsa.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where test_quesnel_tsa.scenarios.scenario = subq.scenario;

alter table test_quesnel.scenarios add column rank double precision default 0.0; UPDATE test_quesnel.scenarios
SET rank = subq.rank
FROM (select d.scenario, vol/dist as rank from 
(select sum(volume) as vol, scenario from test_quesnel.harvest group by scenario) as h
LEFT JOIN (select sum(c80r50) as dist, scenario from test_quesnel.disturbance group by scenario) as d
on d.scenario = h.scenario  order by rank) as subq
where test_quesnel.scenarios.scenario = subq.scenario;






