--Select the timber marks that have dstrb start dates between 2012 and 2016. 
----This could mean that some of the openings started in <2011 or >2017.
create table ftn_results_2012_16 as 
(select * from public.ftn_c_b_pl_polygon 
where timber_mrk IN 
(select distinct(timber_mrk) from 
public.ftn_c_b_pl_polygon where 
dstrbncstr BETWEEN '2012-01-01 00:00:00'::timestamp 
	AND '2016-12-31 00:00:00'::timestamp));
	
--Remove those timber makrs that have distrbance start dates > 2016 or < 2012	
DELETE FROM ftn_results_2012_16 where timber_mrk IN  (select distinct(timber_mrk) 
	from ftn_results_2012_16 where dstrbncstr > '2016-12-31 00:00:00'::timestamp 
						OR dstrbncstr < '2012-01-01 00:00:00'::timestamp);
--Now ftn_results_2012_16 contains timber marks that are comprised of opening ids 
--with start dates between 2012 and 2016.
--Join with the cns_cut_block_poly to get the opening ids with a timber mark
create table cnx_hbs as (
select * from (
(select * from cns_cut_bl_polygon) as b
left join (select opening_id, timber_mrk, dstrbncstr, dstrbncndd, pln_net_ar from ftn_results_2012_16) as a
on b.openingid = a.opening_id) as foo where timber_mrk IS NOT NULL);

--Confine the datasource to timber marks that contain only RESULTS
DELETE FROM cnx_hbs where timber_mrk IN (select distinct(timber_mrk) from cnx_hbs where datasource = 'VRI');

--Alter the end date
ALTER TABLE public.cnx_hbs ALTER COLUMN dstrbncndd TYPE timestamp
USING to_timestamp(dstrbncndd, 'YYYYMMDDHH24MISS');

--Save to csv to get HBS volumes
copy (SELECT distinct(timber_mrk) FROM cnx_hbs) to '/timber_mrks.csv' CSV HEADER;

select * from cnx_hbs where dstrbncndd > '2018-01-31 00:00:00'::timestamp;

select max(dstrbncndd) FROM cnx_hbs ;












