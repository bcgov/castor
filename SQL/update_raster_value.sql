create table rast.tave_sm2 as (select ST_MapAlgebra(rast,1,'32BF', '[rast]/10') as rast from rast.tave_sm);
alter table rast.tave_sm2  rename to tave_sm ;