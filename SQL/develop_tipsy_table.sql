
--Use tipsy_curves.rmd to create tipsy_prov and gy_species tables
--Step1. Change the format
--Step2. Add the remining piece of information- eca, con, etc.

Create Table tipsy_vri2018 as 
	select vols.feature_id, vols.age, vol, ht, s.src, bec_zone, lead_species, 
	site_index, m_type from (
SELECT feature_id, vol10 as vol, 10 as age from tipsy_prov UNION
SELECT feature_id, vol20 as vol, 20 as age from tipsy_prov UNION
SELECT feature_id, vol30 as vol, 30 as age from tipsy_prov UNION
SELECT feature_id, vol40 as vol, 40 as age from tipsy_prov UNION
SELECT feature_id, vol50 as vol, 50 as age from tipsy_prov UNION
SELECT feature_id, vol60 as vol, 60 as age from tipsy_prov UNION
SELECT feature_id, vol70 as vol, 70 as age from tipsy_prov UNION
SELECT feature_id, vol80 as vol, 80 as age from tipsy_prov UNION
SELECT feature_id, vol90 as vol, 90 as age from tipsy_prov UNION
SELECT feature_id, vol100 as vol, 100 as age from tipsy_prov UNION
SELECT feature_id, vol110 as vol, 110 as age from tipsy_prov UNION
SELECT feature_id, vol120 as vol, 120 as age from tipsy_prov UNION
SELECT feature_id, vol130 as vol, 130 as age from tipsy_prov UNION
SELECT feature_id, vol140 as vol, 140 as age from tipsy_prov UNION
SELECT feature_id, vol150 as vol, 150 as age from tipsy_prov UNION
SELECT feature_id, vol160 as vol, 160 as age from tipsy_prov UNION
SELECT feature_id, vol170 as vol, 170 as age from tipsy_prov UNION
SELECT feature_id, vol180 as vol, 180 as age from tipsy_prov UNION
SELECT feature_id, vol190 as vol, 190 as age from tipsy_prov UNION
SELECT feature_id, vol200 as vol, 200 as age from tipsy_prov UNION
SELECT feature_id, vol210 as vol, 210 as age from tipsy_prov UNION
SELECT feature_id, vol220 as vol, 220 as age from tipsy_prov UNION
SELECT feature_id, vol230 as vol, 230 as age from tipsy_prov UNION
SELECT feature_id, vol240 as vol, 240 as age from tipsy_prov UNION
SELECT feature_id, vol250 as vol, 250 as age from tipsy_prov ) vols
LEFT JOIN 
(SELECT feature_id, src, ht010 as ht, 10 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht020 as ht, 20 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht030 as ht, 30 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht040 as ht, 40 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht050 as ht, 50 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht060 as ht, 60 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht070 as ht, 70 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht080 as ht, 80 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht090 as ht, 90 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht100 as ht, 100 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht110 as ht, 110 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht120 as ht, 120 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht130 as ht, 130 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht140 as ht, 140 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht150 as ht, 150 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht160 as ht, 160 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht170 as ht, 170 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht180 as ht, 180 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht190 as ht, 190 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht200 as ht, 200 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht210 as ht, 210 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht220 as ht, 220 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht230 as ht, 230 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht240 as ht, 240 as age from tipsy_ht_prov UNION
SELECT feature_id, src, ht250 as ht, 250 as age from tipsy_ht_prov) ht
ON (vols.feature_id = ht.feature_id and vols.age = ht.age)
LEFT JOIN gy_species_comp s
ON (vols.feature_id = s.feature_id);
	
CREATE INDEX tipsy_vri2018_feature_id_idx
    ON public.tipsy_vri2018 USING btree
    (feature_id)
    TABLESPACE pg_default;
	
alter table tipsy_vri2018 rename column feature_id to ycid; 
alter table tipsy_vri2018 rename column vol to tvol;
alter table tipsy_vri2018 rename column ht to height;
Update tipsy_vri2018 set tvol = 0 where tvol is NULL;

--add in ycgrp
alter table tipsy_vri2018 add column yc_grp text;
Update tipsy_vri2018 set yc_grp = concat(bec_zone, '_', lead_species, '_',site_index, '_',m_type);
alter table tipsy_vri2018 drop bec_zone;
alter table tipsy_vri2018 drop src;
alter table tipsy_vri2018 drop lead_species;
alter table tipsy_vri2018 drop site_index;
alter table tipsy_vri2018 drop m_type;

--add in eca, dec-pcnt
alter table tipsy_vri2018 add column eca double precision;
alter table tipsy_vri2018 add column dec_pcnt double precision;

--add the lower limit of the yield curve
insert into tipsy_vri2018 (ycid, yc_grp, age, tvol, height, dec_pcnt, eca)
select distinct(ycid),  yc_grp, (0) as age, (0.0) as tvol, (0.0) as height, (0.0) as dec_pcnt, (0) as eca
from tipsy_vri2018;

/*STEP 7. Conifer percentage. From yield curves.*/
update tipsy_vri2018 set dec_pcnt = 1 where ycid in 
(select feature_id from gy_species_comp where lead_species in ('At', 'Dr'));

--select * from yc_vdyp order by yc_grp, age limit 1000;
update tipsy_vri2018 set dec_pcnt = ROUND(CAST(dec_pcnt as numeric), 2);
update tipsy_vri2018 set height = ROUND(CAST(height as numeric), 2);
update tipsy_vri2018 set tvol = ROUND(CAST(tvol as numeric), 2);

/*STEP 8. Assign ECA. See https://www.for.gov.bc.ca/tasb/legsregs/fpc/FPCGUIDE/wap/WAPGdbk-Web.pdf*/
---Table A2.2 Hydrological recovery for fully stocked stands that reach a maximum crown closure of 50%–70%.
/*Average height of the main canopy (m) % Recovery
0 – <3 0
3 – <5 25
5 – <7 50
7 – <9 75
9 + 90
*/
--ECA = A*(1-R). All VDYP curves are on 0 eca. TIPSY Curves will get this designation.
update tipsy_vri2018 set eca = 1 where height < 3;
update tipsy_vri2018 set eca = 0.75 where height >= 3 and height < 5;
update tipsy_vri2018 set eca = 0.5 where height >= 5 and height < 7;
update tipsy_vri2018 set eca = 0.25 where height >= 7 and height < 9;
update tipsy_vri2018 set eca = 0.1 where height >= 9;

--create inheritable table set
create table yc_tipsy as select * from tipsy_vri2018;