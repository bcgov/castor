---TIPSY Development Curves
----------------------------

CREATE TABLE IF NOT EXISTS public.tipsy_prov_current_2020
(
    ycid integer,
	stand1 text,
	stand2 text,
    age integer,
    height double precision,
    vol_gross double precision,
    vol_conifer double precision,
    basalarea double precision,
    qmd double precision,
    sph double precision,
    vpt double precision,
    crownclosure double precision,
    vol_dec double precision,
    tvol double precision
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.tipsy_prov_current_2020
    OWNER to klochhea;
	
CREATE TABLE IF NOT EXISTS public.tipsy_prov_2020
(
    ycid integer,
	stand1 text,
	stand2 text,
    age integer,
    height double precision,
    vol_gross double precision,
    vol_conifer double precision,
    basalarea double precision,
    qmd double precision,
    sph double precision,
    vpt double precision,
    crownclosure double precision,
    vol_dec double precision,
    tvol double precision
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.tipsy_prov_2020
    OWNER to klochhea;	

--remove the output not needed
alter table tipsy_prov_2020 drop stand1;
alter table tipsy_prov_2020 drop stand2;
alter table tipsy_prov_current_2020 drop stand1;
alter table tipsy_prov_current_2020 drop stand2;
--add in eca, dec-pcnt
alter table tipsy_prov_2020 add column eca double precision;
alter table tipsy_prov_2020 add column dec_pcnt double precision;
alter table tipsy_prov_current_2020 add column eca double precision;
alter table tipsy_prov_current_2020 add column dec_pcnt double precision;
--- Deciduous percentage.*/
update tipsy_prov_2020 set dec_pcnt = vol_dec/tvol where tvol > 0 and dec_pcnt > 0;
update tipsy_prov_current_2020 set dec_pcnt = vol_dec/tvol where tvol > 0 and dec_pcnt > 0;

--- format percentages to two decimals;
update tipsy_prov_2020 set dec_pcnt = ROUND(CAST(dec_pcnt as numeric), 2);
update tipsy_prov_2020 set height = ROUND(CAST(height as numeric), 2);
update tipsy_prov_2020 set tvol = ROUND(CAST(tvol as numeric), 2);

update tipsy_prov_current_2020 set dec_pcnt = ROUND(CAST(dec_pcnt as numeric), 2);
update tipsy_prov_current_2020 set height = ROUND(CAST(height as numeric), 2);
update tipsy_prov_current_2020 set tvol = ROUND(CAST(tvol as numeric), 2);

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
update tipsy_prov_2020 set eca = 1 where height < 3;
update tipsy_prov_2020 set eca = 0.75 where height >= 3 and height < 5;
update tipsy_prov_2020 set eca = 0.5 where height >= 5 and height < 7;
update tipsy_prov_2020 set eca = 0.25 where height >= 7 and height < 9;
update tipsy_prov_2020 set eca = 0.1 where height >= 9;

update tipsy_prov_current_2020 set eca = 1 where height < 3;
update tipsy_prov_current_2020 set eca = 0.75 where height >= 3 and height < 5;
update tipsy_prov_current_2020 set eca = 0.5 where height >= 5 and height < 7;
update tipsy_prov_current_2020 set eca = 0.25 where height >= 7 and height < 9;
update tipsy_prov_current_2020 set eca = 0.1 where height >= 9;
--- Add in ycgrp********************************************

Update tipsy_prov_2020 set tvol = 0 where tvol is NULL;
Update tipsy_prov_current_2020 set tvol = 0 where tvol is NULL;


CREATE INDEX IF NOT EXISTS idx_tipsy_prov_2020_ycid
    ON public.tipsy_prov_2020 USING btree
    (ycid ASC NULLS LAST)
    TABLESPACE pg_default;

select min(ycid) from tipsy_prov_2020; ---1810868 is the max ycid
select count(*) from tipsy_prov_current_2020;

alter table tipsy_prov_current_2020 add column ycid2 integer;
update tipsy_prov_current_2020 c
 set ycid2 = c2.seqnum
   from (select ycid, row_number() over (ORDER BY ycid) as seqnum
          from tipsy_prov_current_2020 group by ycid order by seqnum
         ) c2
    where c2.ycid = c.ycid;
	
	
alter table tipsy_prov_current_2020 rename column ycid to feature_id;
alter table tipsy_prov_current_2020 rename column ycid2 to ycid;

update tipsy_prov_current_2020 set ycid = ycid*-1;
select * from tipsy_prov_current_2020 where feature_id = 17850206;
	
vacuum tipsy_prov_current_2020;
select * from veg_comp_lyr_r1_poly2021 where feature_id = 17850206;

create table tipsy_prov_current_2020_vat as (select distinct(ycid), feature_id from tipsy_prov_current_2020);

