-------------------------------------------------------------------------------
--Steps needed to connect the Harvest Billing System to VRI growth projections
--By: Kyle Lochhead
--Date: 2019-10-11
--INPUTS:ftn_c_b_pl_polygon, cns_cut_bl_polygon
-------------------------------------------------------------------------------
--STEP 1. Get the geometries of select (2012+) timber marks using ftn_c_b_pl_polygon
----Select the timber marks that have dstrb start dates between 2012 and 2016. 
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
(select harvestyr, openingid, ogc_fid, areaha, datasource, cutblockid, dstrbstdt, 
 wkb_geometry , st_area(wkb_geometry)/10000 as cns_area 
 from cns_cut_bl_polygon) as b
left join 
	(select opening_id, timber_mrk, dstrbncstr, dstrbncndd
	 from ftn_results_2012_16 ) as a
on b.openingid = a.opening_id
left join
	(select timber_mrk as id, sum(pln_net_ar) as pln_net_ar from ftn_results_2012_16 group by timber_mrk) as c
on a.timber_mrk = c.id) 	
	 as foo where timber_mrk IS NOT NULL) ;

--Confine the datasource to timber marks that contain only RESULTS
DELETE FROM cnx_hbs where timber_mrk IN 
(select distinct(timber_mrk) from cnx_hbs2 where datasource = 'VRI');

--Alter the end date
ALTER TABLE public.cnx_hbs ALTER COLUMN dstrbncndd TYPE timestamp
USING to_timestamp(dstrbncndd, 'YYYYMMDDHH24MISS');

DELETE FROM cnx_hbs where timber_mrk 
IN (select distinct(timber_mrk) FROM cnx_hbs2 where pln_net_ar <= 0);

--Remove those timber marks that do not match in area
DELETE FROM cnx_hbs where timber_mrk IN ( 	
select distinct(timber_mrk) FROM (
	SELECT timber_mrk, sum(cns_area/pln_net_ar) as per_area
	FROM cnx_hbs group by timber_mrk 
     ) as foo
where 1.2 < per_area OR per_area < 0.8);


--DELETE BY5H37 -- missing a portion --but this portion is within +- 20%
DELETE FROM cnx_hbs where timber_mrk = 'BY5H37';

--Save to csv to get HBS volumes
copy (SELECT distinct(timber_mrk) FROM cnx_hbs) to '/timber_mrks.csv' CSV HEADER;
--Checks:
--select * from cnx_hbs where dstrbncndd > '2018-01-31 00:00:00'::timestamp;
--select max(dstrbncndd) FROM cnx_hbs ;

-------------------------------------------------------------------------------
--STEP 2. Get HBS volumes
--***SEND '/timber_mrks.csv' TO HBS
--Iaian can query this under his oracle account....?
--Provided by Steve Davis - Revenue Forecasting, Reporting & Planning Timber Pricing Branch, Ministry of Forests, Lands and Natural Resource Operations 
---Phone: (778) 974- 2459  FAX:  (250)  387 - 5670 
---E-mail: Stephen.davis@gov.bc.ca

--Currently this is saved in: ~\clus\VDYP\8026 Scale - Select Marks
--Upload into postgres
CREATE TABLE public.hbs_select_tmbr_mrk
(
    scale_year integer,
    scale_quarter integer,
    scale_month integer,
    land_type text COLLATE pg_catalog."default",
    coast_interior text COLLATE pg_catalog."default",
    region text COLLATE pg_catalog."default",
    district text COLLATE pg_catalog."default",
    licence text COLLATE pg_catalog."default",
    timber_mark text COLLATE pg_catalog."default",
    cutting_permit_id text COLLATE pg_catalog."default",
    mark_status text COLLATE pg_catalog."default",
    mark_issue_date text COLLATE pg_catalog."default",
    mark_expiry_extend_date text COLLATE pg_catalog."default",
    file_type_code text COLLATE pg_catalog."default",
    file_type text COLLATE pg_catalog."default",
    mu_type text COLLATE pg_catalog."default",
    mu_id integer,
    mu_group text COLLATE pg_catalog."default",
    tfl_tsa_no integer,
    tfl_tsa_name text COLLATE pg_catalog."default",
    cb_ind text COLLATE pg_catalog."default",
    bcts text COLLATE pg_catalog."default",
    scale_site text COLLATE pg_catalog."default",
    site_district text COLLATE pg_catalog."default",
    site_name text COLLATE pg_catalog."default",
    product_group text COLLATE pg_catalog."default",
    species_type text COLLATE pg_catalog."default",
    species_code text COLLATE pg_catalog."default",
    species text COLLATE pg_catalog."default",
    grade_group text COLLATE pg_catalog."default",
    grade_code text COLLATE pg_catalog."default",
    grade text COLLATE pg_catalog."default",
    waste_ind text COLLATE pg_catalog."default",
    waste_type text COLLATE pg_catalog."default",
    reject_ind text COLLATE pg_catalog."default",
    volume_m3 double precision,
    value_dollar double precision
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.hbs_select_tmbr_mrk
    OWNER to clus_project;

copy hbs_select_tmbr_mrk from '/hbs_data.csv' CSV HEADER;

--select count(*) from hbs_select_tmbr_mrk;
-------------------------------------------------------------------------------
--STEP 3. RUN get VRI 2011 feature_ids that intersect with hbs polygons 
create table hbs_vri_feature_ids as
select distinct(feature_id) from  whse_forest_vegetation_2011_veg_comp_poly, cnx_hbs where
st_intersects(whse_forest_vegetation_2011_veg_comp_poly.shape, wkb_geometry);
--check
--select * from whse_forest_vegetation_2011_veg_comp_layer where feature_id = 6614619;


-------------------------------------------------------------------------------
--STEP 4.Create a simpflified VEG_COMP table with the necessay information need 
---- to connect with the yc_grp in the meta-model

CREATE TABLE yt_vri2011 AS 
SELECT l.feature_id, p.shape,
basal_area, crown_closure, crown_closure_class_cd, proj_age_1, proj_age_class_cd_1, proj_height_1, proj_height_class_cd_1, 
site_index, line_3_tree_species, species_cd_1, species_pct_1, species_cd_2, species_pct_2, species_cd_3,
species_pct_3, species_cd_4,species_pct_4 , for_cover_rank_cd, bec_zone_code,
(live_stand_volume_125/(dead_stand_volume_125 + live_stand_volume_125)) as pcnt_dead
FROM public.whse_forest_vegetation_2011_veg_comp_layer as l
Left JOIN (select  feature_id,shape, line_3_tree_species, polygon_area, bclcs_level_3, bclcs_level_2, reference_year, bec_zone_code from public.whse_forest_vegetation_2011_veg_comp_poly) as p 
ON
 l.feature_id = p.feature_id
 WHERE species_pct_1 > 0  AND for_cover_rank_cd = '1' and l.feature_id IN (
select feature_id from hbs_vri_feature_ids);
-------------------------------------------------------------------------------
--STEP 5. Build the yc_grp or the key needed to connect with
delete from yt_vri2011 where UPPER(species_cd_1) IN ('G','GP','GR','J','JD','JH','JR','K','KC','OA','OB','OC','OD','OE','OF','OG','OH','OI','Q','QE','QG','QW','R','RA','T','TW','U','UA','UP',
'V','VB','VP','VS','VV','VW','W','WA','WB','WD','WP','WS','WT','X','XC','XH','YP','Z','ZC','ZH'); /*non commercial species*/ 

CREATE INDEX yt_vri2011_feature_id_idx /*Create an index which will be used to link with the vdyp output*/
  ON public.yt_vri2011
  USING btree
  (feature_id);

----Create an aggregated species call similar to line_3_tree_species in the VEG_COMP --i.e., A list of major species (minor species), ordered by percentage. 
----The species symbols are F (Douglas fir), C (western red cedar), H (hemlock), B (balsam), S (spruce), Sb (black spruce), Yc (yellow cedar), P (pine), L (larch), 
----Ac (Populus), D (red alder), Mb (broadleaf maple), E (birch), O (non-commercial). 
----see https://www2.gov.bc.ca/assets/gov/farming-natural-resources-and-industry/forestry/stewardship/forest-analysis-inventory/data-management/standards/vegcomp_poly_rank1_data_dictionary_draft40.pdf*/ 
/*We keep these codes and add in further decription as per VDYP species codes. Thus, Hw is western hemock versus mountain hemlock.*/

Update yt_vri2011 set species_cd_1 =
CASE 
WHEN UPPER(species_cd_1) IN ('D','DG','DM','DR') THEN 'Dr' /*Red alder*/
WHEN UPPER(species_cd_1) IN ('E','EB','EE','ES','EW','EX','EXP','EXW') THEN 'E' /*Birch*/
WHEN UPPER(species_cd_1) IN ('EA') THEN 'Ea' /*Alaskan Birch*/
WHEN UPPER(species_cd_1) IN ('EP') THEN 'Ep' /*Common paper Birch*/
WHEN UPPER(species_cd_1) IN ('A','AC','ACB','ACT','AD','AX') THEN 'Ac' /*Poplar*/
WHEN UPPER(species_cd_1) IN ('AT') THEN 'At' /*aspen*/
WHEN UPPER(species_cd_1) IN ('B','BB','BC','BM','BP') THEN 'B' /*True Fir*/
WHEN UPPER(species_cd_1) IN ('BL') THEN 'Bl' /*Apline fir*/
WHEN UPPER(species_cd_1) IN ('BG') THEN 'Bg' /*grand fir*/
WHEN UPPER(species_cd_1) IN ('BA') THEN 'Ba' /*amabillis fir*/
WHEN UPPER(species_cd_1) IN ('C','CW') THEN 'Cw' /*Western Red Cedar*/
WHEN UPPER(species_cd_1) IN ('Y','YC') THEN 'Yc' /*Yellow Cedar*/
WHEN UPPER(species_cd_1) IN ('F','FD','FDC','FDI') THEN 'Fd' /*Douglas Fir*/
WHEN UPPER(species_cd_1) IN ('H','HX','HXM') THEN 'H' /*Hemlock*/
WHEN UPPER(species_cd_1) IN ('HM') THEN 'Hm' /*Mountain hemlock*/
WHEN UPPER(species_cd_1) IN ('HW') THEN 'Hw' /*western hemlock*/
WHEN UPPER(species_cd_1) IN ('L','LD','LS','LW') THEN 'L' /*larch*/
WHEN UPPER(species_cd_1) IN ('LW') THEN 'Lw' /*western larch*/
WHEN UPPER(species_cd_1) IN ('LA') THEN 'La' /*alpine larch*/
WHEN UPPER(species_cd_1) IN ('LT') THEN 'Lt' /*tamarack*/
WHEN UPPER(species_cd_1) IN ('M','MB','ME','MN','MR','MS','MV') THEN 'Mb' /*big leaf maple*/
WHEN UPPER(species_cd_1) IN ('P','PM','PR','PS','PX') THEN 'P'
WHEN UPPER(species_cd_1) IN ('PL','PLC','PLI') THEN 'Pl' /*Lodgepole pine*/
WHEN UPPER(species_cd_1) IN ('PY') THEN 'Py' /*yellow (ponderosa) pine*/
WHEN UPPER(species_cd_1) IN ('PW') THEN 'Pw' /*westrern white pine*/
WHEN UPPER(species_cd_1) IN ('PJ','PXJ') THEN 'Pj' /*jack pine*/
WHEN UPPER(species_cd_1) IN ('PF') THEN 'Pf' /*limber pine*/
WHEN UPPER(species_cd_1) IN ('PA') THEN 'Pa' /*whitebark pine*/
WHEN UPPER(species_cd_1) IN ('SB') THEN 'Sb' /*black spruce*/
WHEN UPPER(species_cd_1) IN ('SS') THEN 'Ss' /*sitka spruce*/
WHEN UPPER(species_cd_1) IN ('SE','SXE') THEN 'Se' /*engelmann spruce*/
WHEN UPPER(species_cd_1) IN ('SW','SXW') THEN 'Sw' /*white spruce*/
WHEN UPPER(species_cd_1) IN ('S','SA','SN','SX','SXB','SXL','SXS','SXX') THEN 'S' /*generic spruce?*/
ELSE species_cd_1
END  ;

Update yt_vri2011 set species_cd_2 =
CASE 
WHEN UPPER(species_cd_2) IN ('D','DG','DM','DR') THEN 'Dr' /*Red alder*/
WHEN UPPER(species_cd_2) IN ('E','EB','EE','ES','EW','EX','EXP','EXW') THEN 'E' /*Birch*/
WHEN UPPER(species_cd_2) IN ('EA') THEN 'Ea' /*Alaskan Birch*/
WHEN UPPER(species_cd_2) IN ('EP') THEN 'Ep' /*Common paper Birch*/
WHEN UPPER(species_cd_2) IN ('A','AC','ACB','ACT','AD','AX') THEN 'Ac' /*Poplar*/
WHEN UPPER(species_cd_2) IN ('AT') THEN 'At' /*aspen*/
WHEN UPPER(species_cd_2) IN ('B','BB','BC','BM','BP') THEN 'B' /*True Fir*/
WHEN UPPER(species_cd_2) IN ('BL') THEN 'Bl' /*Apline fir*/
WHEN UPPER(species_cd_2) IN ('BG') THEN 'Bg' /*grand fir*/
WHEN UPPER(species_cd_2) IN ('BA') THEN 'Ba' /*amabillis fir*/
WHEN UPPER(species_cd_2) IN ('C','CW') THEN 'Cw' /*Western Red Cedar*/
WHEN UPPER(species_cd_2) IN ('Y','YC') THEN 'Yc' /*Yellow Cedar*/
WHEN UPPER(species_cd_2) IN ('F','FD','FDC','FDI') THEN 'Fd' /*Douglas Fir*/
WHEN UPPER(species_cd_2) IN ('H','HX','HXM') THEN 'H' /*Hemlock*/
WHEN UPPER(species_cd_2) IN ('HM') THEN 'Hm' /*Mountain hemlock*/
WHEN UPPER(species_cd_2) IN ('HW') THEN 'Hw' /*western hemlock*/
WHEN UPPER(species_cd_2) IN ('L','LD','LS','LW') THEN 'L' /*larch*/
WHEN UPPER(species_cd_2) IN ('LW') THEN 'Lw' /*western larch*/
WHEN UPPER(species_cd_2) IN ('LA') THEN 'La' /*alpine larch*/
WHEN UPPER(species_cd_2) IN ('LT') THEN 'Lt' /*tamarack*/
WHEN UPPER(species_cd_2) IN ('M','MB','ME','MN','MR','MS','MV') THEN 'Mb' /*big leaf maple*/
WHEN UPPER(species_cd_2) IN ('P','PM','PR','PS','PX') THEN 'P'
WHEN UPPER(species_cd_2) IN ('PL','PLC','PLI') THEN 'Pl' /*Lodgepole pine*/
WHEN UPPER(species_cd_2) IN ('PY') THEN 'Py' /*yellow (ponderosa) pine*/
WHEN UPPER(species_cd_2) IN ('PW') THEN 'Pw' /*westrern white pine*/
WHEN UPPER(species_cd_2) IN ('PJ','PXJ') THEN 'Pj' /*jack pine*/
WHEN UPPER(species_cd_2) IN ('PF') THEN 'Pf' /*limber pine*/
WHEN UPPER(species_cd_2) IN ('PA') THEN 'Pa' /*whitebark pine*/
WHEN UPPER(species_cd_2) IN ('SB') THEN 'Sb' /*black spruce*/
WHEN UPPER(species_cd_2) IN ('SS') THEN 'Ss' /*sitka spruce*/
WHEN UPPER(species_cd_2) IN ('SE','SXE') THEN 'Se' /*engelmann spruce*/
WHEN UPPER(species_cd_2) IN ('SW','SXW') THEN 'Sw' /*white spruce*/
WHEN UPPER(species_cd_2) IN ('S','SA','SN','SX','SXB','SXL','SXS','SXX') THEN 'S' /*generic spruce?*/
ELSE species_cd_2
END  ;

/* Group species that are the same*/
Update yt_vri2011 set species_pct_1 = (species_pct_1 + species_pct_2) WHERE species_cd_1 = species_cd_2; 
Update yt_vri2011 set species_cd_2 = NULL, species_pct_2 = NULL WHERE species_cd_1 = species_cd_2;

/*Make the aggregated sepcies call*/
Alter TAble yt_vri2011 Add Column l3spp text ;
Update yt_vri2011 set l3spp = CASE
WHEN species_cd_2 IS NOT NULL AND species_pct_2 >= 20 THEN CONCAT(species_cd_1,species_cd_2)
WHEN species_cd_2 IS NOT NULL AND species_pct_2 < 20 THEN CONCAT(species_cd_1,'(',species_cd_2,')')
WHEN species_cd_2 IS NULL THEN species_cd_1
END;

Update yt_vri2011 set site_index = round(site_index / 2 ) * 2; /*round the site index to nearest meter*/

Alter TAble yt_vri2011 Add Column yc_grp text ;
Update yt_vri2011 set yc_grp = NULL;
Update yt_vri2011 set yc_grp = CONCAT(bec_zone_code,'_',l3spp,'_', site_index,'_',crown_closure_class_cd,'_', proj_height_class_cd_1) WHERE bec_zone_code IS NOT NULL
AND site_index > 0 and crown_closure_class_cd IS NOT NULL and proj_height_class_cd_1 IS NOT NULL;
/*select * from vdyp_vri2018 where bec_zone_code is null limit 3;*/
/*select yc_grp, sum(polygon_area) as area FROM vdyp_vri2018 group by yc_grp order by yc_grp;*/
/* Height Classes
1	0 – 10.4m
2	10.5 – 19.4m
3	19.5 – 28.4m
4	28.5 – 37.4m
5	37.5 – 46.4m
6	46.5 – 55.4m
7	55.5 – 64.4m
8	> 65.5m*/

--select * from yt_vri2011 where feature_id = 6614619;
-------------------------------------------------------------------------------
--STEP 5. Assign the interpolated yields projected from the meta-model
-----vdyp_test3: the meta model from VDYP
-----yt_vri2011: yc_grp
Create table yt_vri2011prj as
SELECT t.feature_id, t.yc_grp, t.bec_zone_code,
  (((k.prj_vol_dwb - y.prj_vol_dwb*1.0)/10)*(t.proj_age_1 - CAST(t.proj_age_1/10 AS INT)*10))+ y.prj_vol_dwb as itvol
  FROM yt_vri2011 t
  LEFT JOIN vdyp_test3 y 
  ON t.yc_grp = y.yc_grp AND CAST(t.proj_age_1/10 AS INT)*10 = y.prj_total_age
  LEFT JOIN vdyp_test3 k 
  ON t.yc_grp = k.yc_grp AND round(t.proj_age_1/10+0.5)*10 = k.prj_total_age WHERE t.proj_age_1 > 0
  ;
  
---Check
---select * from vdyp_test3 where yc_grp = 'SBPS_Pl(At)_16_7_4';
---select * from yt_vri2011prj where feature_id = 6614619;

--yt_vri2011prj is a lookup table to link back to the spatial via feature_id
---Spatial intersect -- done in R. Need a better query for this...
--SELECT UpdateGeometrySRID('public.whse_forest_vegetation_2011_veg_comp_poly','shape',3005);
--Update public.whse_forest_vegetation_2011_veg_comp_poly set shape = st_makevalid(shape) where st_isvalid(shape) = false;

-------------------------------------------------------------------------------
--STEP 6. Intersect the cnx_hbs geometry with yt_vri2011, calucalte area for the featureids,
----merge the interpolated yields from yt_vri2011prj
----calculate the volume with vol = area*itvol
----Summarize by timber_mrk the sum of vol
----write to shapefile

select * from yieldcurves where yc_grp = 'MS_SFd_18_5_4';


  
