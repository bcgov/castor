create table rast.mat2 as (select ST_MapAlgebra(rast,1,'32BF', '[rast]/10') as rast from rast.mat);
alter table rast.mat2  rename to mat ;