/*CREATE AND BUILD the required VDYP input and output tables*/
/*--------------------------------------------------------------------------
The following steps outline the process used to generate a provincial VDYP database of yield curves:

CLEAN-----
  Step 1:  Import the required data tables.
	a. Import the vdyp input table - useful for determining which is the primary layer
	b. Import the vdyp output table with the projections of each stand
	c. Import the vdyp error output - useful for determining which stands/projections need to be removed or set to NULL
	
  Step 2: Remove non primary layers. TODO: Need logic for aggregating secondary layers?
  Step 3: Set "back" projections to NULL - these back projections are not needed
  Step 4: Remove projections with errors
	a. Add required columns for primary key and description of error

BUILD-----
  Step 5: Import in the VRI information and create a forest attribute key the will be the primary key for yield curves

--------------------------------------------------------------------------*/  
/*Step 1. Import the required data tables*/
/*a. Import the vdyp input table - useful for determining which is the primary layer*/
CREATE TABLE public.vdyp_input_tbl
(
  feature_id integer,
  tree_cover_layer_estimated_id integer,
  map_id text,
  polygon_number integer,
  layer_level_code text,
  vdyp7_layer_cd text,
  layer_stockability boolean,
  forest_cover_rank_code integer,
  non_forest_descriptor_code text,
  est_site_index_species_cd text,
  estimated_site_index double precision,
  crown_closure integer,
  basal_area_75 double precision,
  stems_per_ha_75 integer,
  species_cd_1 text,
  species_pct_1 double precision,
  species_cd_2 text,
  species_pct_2 double precision,
  species_cd_3 text,
  species_pct_3 double precision,
  species_cd_4 text,
  species_pct_4 double precision,
  species_cd_5 text,
  species_pct_5 double precision,
  species_cd_6 text,
  species_pct_6 integer,
  est_age_spp1 integer,
  est_height_spp1 double precision,
  est_age_spp2 integer,
  est_height_spp2 double precision,
  adj_ind  double precision,
  lorey_height_75 double precision,
  basal_area_125  double precision,
  ws_vol_per_ha_75  double precision,
  ws_vol_per_ha_125  double precision,
  cu_vol_per_ha_125  double precision,
  d_vol_per_ha_125  double precision,
  dw_vol_per_ha_125  double precision
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.vdyp_input_tbl
  OWNER TO clus_project;

/*Import the csv*/
COPY vdyp_input_tbl(feature_id, tree_cover_layer_estimated_id, map_id, polygon_number,               
layer_level_code, vdyp7_layer_cd, layer_stockability, forest_cover_rank_code,       
non_forest_descriptor_code, est_site_index_species_cd, estimated_site_index, crown_closure,                
basal_area_75, stems_per_ha_75, species_cd_1, species_pct_1, species_cd_2, species_pct_2,               
species_cd_3, species_pct_3, species_cd_4, species_pct_4, species_cd_5, species_pct_5, species_cd_6, species_pct_6,               
est_age_spp1, est_height_spp1, est_age_spp2, est_height_spp2, adj_ind, lorey_height_75, basal_area_125, ws_vol_per_ha_75,             
ws_vol_per_ha_125, cu_vol_per_ha_125, d_vol_per_ha_125, dw_vol_per_ha_125) 
FROM 'C:\Users\KLOCHHEA\clus\VDYP\VEG_COMP_VDYP7_INPUT_LAYER_TBL_2019.csv' DELIMITER ',' CSV HEADER;


/*b. Import the vdyp output table with the projections of each stand*/
CREATE TABLE public.vdyp
(
  table_num integer,
  feature_id integer,
  district text,
  map_id text,
  polygon_id integer,
  layer_id text,
  projection_year integer,
  prj_total_age integer,
  species_1_code text,
  species_1_pcnt double precision,
  species_2_code text,
  species_2_pcnt double precision,
  species_3_code text,
  species_3_pcnt double precision,
  species_4_code text,
  species_4_pcnt double precision,
  species_5_code text,
  species_5_pcnt double precision,
  species_6_code text,
  species_6_pcnt double precision,
  prj_pcnt_stock double precision,
  prj_site_index double precision,
  prj_dom_ht double precision,
  prj_lorey_ht double precision,
  prj_diameter double precision,
  prj_tph double precision,
  prj_ba double precision,
  prj_vol_ws double precision,
  prj_vol_cu double precision,
  prj_vol_d double precision,
  prj_vol_dw double precision,
  prj_vol_dwb double precision,
  prj_sp1_vol_ws double precision,
  prj_sp1_vol_cu double precision,
  prj_sp1_vol_d double precision,
  prj_sp1_vol_dw double precision,
  prj_sp1_vol_dwb double precision,
  prj_sp2_vol_ws double precision,
  prj_sp2_vol_cu double precision,
  prj_sp2_vol_d double precision,
  prj_sp2_vol_dw double precision,
  prj_sp2_vol_dwb double precision,
  prj_sp3_vol_ws double precision,
  prj_sp3_vol_cu double precision,
  prj_sp3_vol_d double precision,
  prj_sp3_vol_dw double precision,
  prj_sp3_vol_dwb double precision,
  prj_sp4_vol_ws double precision,
  prj_sp4_vol_cu double precision,
  prj_sp4_vol_d double precision,
  prj_sp4_vol_dw double precision,
  prj_sp4_vol_dwb double precision,
  prj_sp5_vol_ws double precision,
  prj_sp5_vol_cu double precision,
  prj_sp5_vol_d double precision,
  prj_sp5_vol_dw double precision,
  prj_sp5_vol_dwb double precision,
  prj_sp6_vol_ws double precision,
  prj_sp6_vol_cu double precision,
  prj_sp6_vol_d double precision,
  prj_sp6_vol_dw double precision,
  prj_sp6_vol_dwb double precision,
  prj_mode text
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.vdyp
  OWNER TO clus_project;
  
/*Import the data*/
COPY vdyp (table_num, feature_id, district, map_id, polygon_id, layer_id, projection_year,	prj_total_age, species_1_code, species_1_pcnt, species_2_code,
species_2_pcnt,	species_3_code,	species_3_pcnt,	species_4_code,	species_4_pcnt,	species_5_code,	species_5_pcnt,	species_6_code,	species_6_pcnt,	
prj_pcnt_stock,	prj_site_index,	prj_dom_ht, prj_lorey_ht, prj_diameter,	prj_tph, prj_ba, prj_vol_ws, prj_vol_cu, prj_vol_d, prj_vol_dw,	prj_vol_dwb,	
prj_sp1_vol_ws,	prj_sp1_vol_cu,	prj_sp1_vol_d,	prj_sp1_vol_dw,	prj_sp1_vol_dwb, prj_sp2_vol_ws, prj_sp2_vol_cu, prj_sp2_vol_d,	prj_sp2_vol_dw,	
prj_sp2_vol_dwb, prj_sp3_vol_ws, prj_sp3_vol_cu, prj_sp3_vol_d,	prj_sp3_vol_dw,	prj_sp3_vol_dwb, prj_sp4_vol_ws, prj_sp4_vol_cu, prj_sp4_vol_d,	
prj_sp4_vol_dw,	prj_sp4_vol_dwb, prj_sp5_vol_ws, prj_sp5_vol_cu, prj_sp5_vol_d,	prj_sp5_vol_dw,	prj_sp5_vol_dwb, prj_sp6_vol_ws, prj_sp6_vol_cu,	
prj_sp6_vol_d,	prj_sp6_vol_dw,	prj_sp6_vol_dwb, prj_mode ) 
FROM 'C:\Users\KLOCHHEA\clus\VDYP\VRI2018_U175.csv' DELIMITER ',' CSV HEADER;

/*Create an index*/
CREATE INDEX vdyp_feature_id_idx ON public.vdyp using btree(feature_id);

/*c. Import the vdyp error output - useful for determining which stands/projections need to be removed or set to NULL*/
CREATE TABLE public.vdyp_err
(
  error text
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.vdyp_err
  OWNER TO clus_project;
/*Import the data*/
COPY vdyp_err 
FROM 'C:\Users\KLOCHHEA\clus\VDYP\Err_VRI2018_U175.txt' DELIMITER '|';

/*--------------------------------------------------------------------------*/
/*Step 2. Remove NON-PRIMARY layer for now. Consider aggregating the layers?*/
DELETE FROM vdyp WHERE layer_id = 'D'; /*Remove the dead layers*/

WITH prim_lookup AS (SELECT feature_id, layer_level_code FROM vdyp_input_tbl WHERE forest_cover_rank_code = 1)
DELETE FROM vdyp B
USING prim_lookup C
WHERE B.feature_id = C.feature_id AND B.layer_id <> C.layer_level_code;

/*Remove those secondary layers that are not labeled with a Primary label*/
WITH prim_lookup AS (select feature_id, layer_level_code FROM (select feature_id, layer_level_code, crown_closure, max(crown_closure) over (partition by feature_id) as max from vdyp_input_tbl where feature_id in (select feature_id from vdyp group by feature_id having count(feature_id) > 35)) as foo WHERE crown_closure = max)
DELETE FROM vdyp B
USING prim_lookup C
WHERE B.feature_id = C.feature_id AND B.layer_id <> C.layer_level_code;

/*check
select feature_id from vdyp group by feature_id having count(feature_id) > 35
*/

/*--------------------------------------------------------------------------*/
/* Step 3. Set "Back" projections to NULL*/
Update vdyp SET  prj_pcnt_stock  = NULL, prj_site_index = NULL, prj_dom_ht = NULL, prj_lorey_ht = NULL, prj_diameter = NULL,
  prj_tph = NULL, prj_ba = NULL, prj_vol_ws = NULL, prj_vol_cu = NULL, prj_vol_d = NULL, prj_vol_dw = NULL, prj_vol_dwb = NULL,
  prj_sp1_vol_ws = NULL, prj_sp1_vol_cu = NULL, prj_sp1_vol_d = NULL, prj_sp1_vol_dw = NULL, prj_sp1_vol_dwb = NULL,
  prj_sp2_vol_ws = NULL, prj_sp2_vol_cu = NULL, prj_sp2_vol_d = NULL, prj_sp2_vol_dw = NULL, prj_sp2_vol_dwb = NULL,
  prj_sp3_vol_ws = NULL, prj_sp3_vol_cu = NULL, prj_sp3_vol_d = NULL, prj_sp3_vol_dw = NULL, prj_sp3_vol_dwb = NULL,
  prj_sp4_vol_ws = NULL, prj_sp4_vol_cu = NULL, prj_sp4_vol_d = NULL, prj_sp4_vol_dw = NULL, prj_sp4_vol_dwb = NULL, 
  prj_sp5_vol_ws = NULL, prj_sp5_vol_cu = NULL, prj_sp5_vol_d = NULL, prj_sp5_vol_dw = NULL, prj_sp5_vol_dwb = NULL,
  prj_sp6_vol_ws = NULL, prj_sp6_vol_cu = NULL, prj_sp6_vol_d = NULL, prj_sp6_vol_dw = NULL, prj_sp6_vol_dwb= NULL
  WHERE prj_mode = 'Back';

  VACUUM vdyp; /*Clean up the table*/
  
/*--------------------------------------------------------------------------*/
/* Step 4. Remove Projections that have serious errors
	a. Add a column to vdyp_err to parse out the feature_id*/
ALTER TABLE vdyp_err Add Column feature_id integer;
UPDATE vdyp_err SET feature_id = CAST(substring(error, position(': ' in error) + 2, position(' ) ' in error) - position(': ' in error)-2) AS integer );

/*Add some new columns to store the error code*/
ALTER TABLE vdyp_err Add Column code text;
ALTER TABLE vdyp_err Add Column dcode text;
UPDATE vdyp_err SET code = substring(split_part(error, ' - ', 2),1,2), dcode = split_part(error, ' - ', 2) ;

/*Remove only the errors*/
DELETE FROM vdyp WHERE feature_id IN (SELECT feature_id FROM vdyp_err WHERE code = 'E '); 

/*--------------------------------------------------------------------------*/
/*Step 5. Merge in VRI forest Attribute information for creating aggregated key. */
/*a. Create a simpflified VEG_COMP table with the necessay information for the aggregated key*/
CREATE TABLE vdyp_vri2018 AS SELECT feature_id, bec_zone_code, bclcs_level_3, basal_area, crown_closure, crown_closure_class_cd, proj_height_1, proj_height_class_cd_1, site_index, 
line_3_tree_species, species_cd_1, species_pct_1, species_cd_2, species_pct_2, species_cd_3,species_pct_3, species_cd_4,species_pct_4, polygon_area, wkb_geometry  
FROM public.veg_comp_lyr_r1_poly_2018
WHERE bclcs_level_2 = 'T' AND species_pct_1 > 0;

delete from vdyp_vri2018 where UPPER(species_cd_1) IN ('G','GP','GR','J','JD','JH','JR','K','KC','OA','OB','OC','OD','OE','OF','OG','OH','OI','Q','QE','QG','QW','R','RA','T','TW','U','UA','UP',
'V','VB','VP','VS','VV','VW','W','WA','WB','WD','WP','WS','WT','X','XC','XH','YP','Z','ZC','ZH'); /*non commercial species*/ 

CREATE INDEX vdyp_vri2018_feature_id_idx /*Create an index which will be used to link with the vdyp output*/
  ON public.vdyp_vri2018
  USING btree
  (feature_id);

/*b. Create an aggregated species call similar to line_3_tree_species in the VEG_COMP --i.e., A list of major species (minor species), ordered by percentage. 
The species symbols are F (Douglas fir), C (western red cedar), H (hemlock), B (balsam), S (spruce), Sb (black spruce), Yc (yellow cedar), P (pine), L (larch), 
Ac (Populus), D (red alder), Mb (broadleaf maple), E (birch), O (non-commercial). 
see https://www2.gov.bc.ca/assets/gov/farming-natural-resources-and-industry/forestry/stewardship/forest-analysis-inventory/data-management/standards/vegcomp_poly_rank1_data_dictionary_draft40.pdf*/ 

/*We keep these codes and add in further decription as per VDYP species codes. Thus, Hw is western hemock versus mountain hemlock.*/
Update vdyp_vri2018 set species_cd_1 =
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

Update vdyp_vri2018 set species_cd_2 =
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

Update vdyp_vri2018 set species_cd_3 =
CASE 
WHEN UPPER(species_cd_3) IN ('D','DG','DM','DR') THEN 'Dr' /*Red alder*/
WHEN UPPER(species_cd_3) IN ('E','EB','EE','ES','EW','EX','EXP','EXW') THEN 'E' /*Birch*/
WHEN UPPER(species_cd_3) IN ('EA') THEN 'Ea' /*Alaskan Birch*/
WHEN UPPER(species_cd_3) IN ('EP') THEN 'Ep' /*Common paper Birch*/
WHEN UPPER(species_cd_3) IN ('A','AC','ACB','ACT','AD','AX') THEN 'Ac' /*Poplar*/
WHEN UPPER(species_cd_3) IN ('AT') THEN 'At' /*aspen*/
WHEN UPPER(species_cd_3) IN ('B','BB','BC','BM','BP') THEN 'B' /*True Fir*/
WHEN UPPER(species_cd_3) IN ('BL') THEN 'Bl' /*Apline fir*/
WHEN UPPER(species_cd_3) IN ('BG') THEN 'Bg' /*grand fir*/
WHEN UPPER(species_cd_3) IN ('BA') THEN 'Ba' /*amabillis fir*/
WHEN UPPER(species_cd_3) IN ('C','CW') THEN 'Cw' /*Western Red Cedar*/
WHEN UPPER(species_cd_3) IN ('Y','YC') THEN 'Yc' /*Yellow Cedar*/
WHEN UPPER(species_cd_3) IN ('F','FD','FDC','FDI') THEN 'Fd' /*Douglas Fir*/
WHEN UPPER(species_cd_3) IN ('H','HX','HXM') THEN 'H' /*Hemlock*/
WHEN UPPER(species_cd_3) IN ('HM') THEN 'Hm' /*Mountain hemlock*/
WHEN UPPER(species_cd_3) IN ('HW') THEN 'Hw' /*western hemlock*/
WHEN UPPER(species_cd_3) IN ('L','LD','LS','LW') THEN 'L' /*larch*/
WHEN UPPER(species_cd_3) IN ('LW') THEN 'Lw' /*western larch*/
WHEN UPPER(species_cd_3) IN ('LA') THEN 'La' /*alpine larch*/
WHEN UPPER(species_cd_3) IN ('LT') THEN 'Lt' /*tamarack*/
WHEN UPPER(species_cd_3) IN ('M','MB','ME','MN','MR','MS','MV') THEN 'Mb' /*big leaf maple*/
WHEN UPPER(species_cd_3) IN ('P','PM','PR','PS','PX') THEN 'P'
WHEN UPPER(species_cd_3) IN ('PL','PLC','PLI') THEN 'Pl' /*Lodgepole pine*/
WHEN UPPER(species_cd_3) IN ('PY') THEN 'Py' /*yellow (ponderosa) pine*/
WHEN UPPER(species_cd_3) IN ('PW') THEN 'Pw' /*westrern white pine*/
WHEN UPPER(species_cd_3) IN ('PJ','PXJ') THEN 'Pj' /*jack pine*/
WHEN UPPER(species_cd_3) IN ('PF') THEN 'Pf' /*limber pine*/
WHEN UPPER(species_cd_3) IN ('PA') THEN 'Pa' /*whitebark pine*/
WHEN UPPER(species_cd_3) IN ('SB') THEN 'Sb' /*black spruce*/
WHEN UPPER(species_cd_3) IN ('SS') THEN 'Ss' /*sitka spruce*/
WHEN UPPER(species_cd_3) IN ('SE','SXE') THEN 'Se' /*engelmann spruce*/
WHEN UPPER(species_cd_3) IN ('SW','SXW') THEN 'Sw' /*white spruce*/
WHEN UPPER(species_cd_3) IN ('S','SA','SN','SX','SXB','SXL','SXS','SXX') THEN 'S' /*generic spruce?*/
ELSE species_cd_3
END  ;


/* Group species that are the same*/
Update vdyp_vri2018 set species_pct_1 = (species_pct_1 + species_pct_2) WHERE species_cd_1 = species_cd_2; 
Update vdyp_vri2018 set species_pct_1 = (species_pct_1 + species_pct_3) WHERE species_cd_1 = species_cd_3;
Update vdyp_vri2018 set species_cd_2 = NULL, species_pct_2 = NULL WHERE species_cd_1 = species_cd_2;
Update vdyp_vri2018 set species_cd_3 = NULL, species_pct_3 = NULL WHERE species_cd_1 = species_cd_3;
Update vdyp_vri2018 set species_pct_2 = (species_pct_2 + species_pct_3) WHERE species_cd_2 = species_cd_3 ;
Update vdyp_vri2018 set species_cd_3 = NULL, species_pct_3 = NULL WHERE species_cd_2 = species_cd_3;

/*Make the aggregated sepcies call*/
Alter TAble vdyp_vri2018 Add Column l3spp text ;
Update vdyp_vri2018 set l3spp = CASE
WHEN species_cd_3 IS NOT NULL AND species_pct_3 >= 20 THEN CONCAT(species_cd_1,species_cd_2,species_cd_3)
WHEN species_cd_3 IS NOT NULL AND species_pct_3 < 20 THEN CONCAT(species_cd_1,species_cd_2,'(', species_cd_3,')')
WHEN species_cd_3 IS NULL AND species_cd_2 IS NOT NULL AND species_pct_2 >= 20 THEN CONCAT(species_cd_1,species_cd_2)
WHEN species_cd_3 IS NULL AND species_cd_2 IS NOT NULL AND species_pct_2 < 20 THEN CONCAT(species_cd_1,'(',species_cd_2,')')
WHEN species_cd_3 IS NULL AND species_cd_2 IS NULL THEN species_cd_1
END;

Update vdyp_vri2018 set site_index = round(site_index); /*round the site index to nearest meter*/

Alter TAble vdyp_vri2018 Add Column yc_grp text ;
Update vdyp_vri2018 set yc_grp = NULL;
Update vdyp_vri2018 set yc_grp = CONCAT(bec_zone_code,'_',l3spp,'_', site_index,'_',crown_closure_class_cd,'_', proj_height_class_cd_1) WHERE bec_zone_code IS NOT NULL
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

create table vdyptest as (SELECT * from (select yc_grp, polygon_area, b.feature_id, prj_total_age, prj_site_index, prj_dom_ht, prj_lorey_ht, prj_diameter, prj_tph, prj_ba, prj_vol_ws, prj_vol_cu, prj_vol_d, prj_vol_dw, prj_vol_dwb
FROM vdyp 
FULL JOIN (SELECT feature_id, yc_grp, polygon_area FROM vdyp_vri2018) as b
ON vdyp.feature_id = b.feature_id) as foo);

select * from vdyptest limit 100;
