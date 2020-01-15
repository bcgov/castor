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
  Step 6. Build a yieldcurve table with all of the attribution needed in CLUS
-- --------------------------------------------------------------------------*/  
-- /*Step 1. Import the required data tables*/
-- /*a. Import the vdyp input table - useful for determining which is the primary layer*/
-- CREATE TABLE public.vdyp_input_tbl
-- (
--   feature_id integer,
--   tree_cover_layer_estimated_id integer,
--   map_id text,
--   polygon_number integer,
--   layer_level_code text,
--   vdyp7_layer_cd text,
--   layer_stockability boolean,
--   forest_cover_rank_code integer,
--   non_forest_descriptor_code text,
--   est_site_index_species_cd text,
--   estimated_site_index double precision,
--   crown_closure integer,
--   basal_area_75 double precision,
--   stems_per_ha_75 integer,
--   species_cd_1 text,
--   species_pct_1 double precision,
--   species_cd_2 text,
--   species_pct_2 double precision,
--   species_cd_3 text,
--   species_pct_3 double precision,
--   species_cd_4 text,
--   species_pct_4 double precision,
--   species_cd_5 text,
--   species_pct_5 double precision,
--   species_cd_6 text,
--   species_pct_6 integer,
--   est_age_spp1 integer,
--   est_height_spp1 double precision,
--   est_age_spp2 integer,
--   est_height_spp2 double precision,
--   adj_ind  double precision,
--   lorey_height_75 double precision,
--   basal_area_125  double precision,
--   ws_vol_per_ha_75  double precision,
--   ws_vol_per_ha_125  double precision,
--   cu_vol_per_ha_125  double precision,
--   d_vol_per_ha_125  double precision,
--   dw_vol_per_ha_125  double precision
-- )
-- WITH (
--   OIDS=FALSE
-- );
-- ALTER TABLE public.vdyp_input_tbl
--   OWNER TO clus_project;

-- /*Import the csv*/
-- COPY vdyp_input_tbl(feature_id, tree_cover_layer_estimated_id, map_id, polygon_number,               
-- layer_level_code, vdyp7_layer_cd, layer_stockability, forest_cover_rank_code,       
-- non_forest_descriptor_code, est_site_index_species_cd, estimated_site_index, crown_closure,                
-- basal_area_75, stems_per_ha_75, species_cd_1, species_pct_1, species_cd_2, species_pct_2,               
-- species_cd_3, species_pct_3, species_cd_4, species_pct_4, species_cd_5, species_pct_5, species_cd_6, species_pct_6,               
-- est_age_spp1, est_height_spp1, est_age_spp2, est_height_spp2, adj_ind, lorey_height_75, basal_area_125, ws_vol_per_ha_75,             
-- ws_vol_per_ha_125, cu_vol_per_ha_125, d_vol_per_ha_125, dw_vol_per_ha_125) 
-- FROM 'C:\Users\KLOCHHEA\clus\VDYP\VEG_COMP_VDYP7_INPUT_LAYER_TBL_2019.csv' DELIMITER ',' CSV HEADER;

-- CREATE TABLE public.vdyp_input_poly
-- (
--   feature_id integer,
--   map_id text,
--   polygon_number integer,
--   org_unit text,
--   tsa_name text,
--   tfl_name text,
--   inventory_standard_code text,
--   tsa_number text,
--   shrub_height double precision,
--   shrub_crown_closure integer,
--   shrub_cover_pattern integer,
--   herb_cover_type_code text,
--   herb_cover_pct integer,
--   herb_cover_pattern_code integer,
--   bryoid_cover_pct integer,
--   bec_zone_code text,
--   cfs_ecozone integer,
--   pre_disturbance_stockability double precision,
--   yield_factor double precision,
--   non_productive_descriptor_cd text,
--   bclcs_level1_code text,
--   bclcs_level2_code text,
--   bclcs_level3_code text,
--   bclcs_level4_code text,
--   bclcs_level5_code text,
--   photo_estimation_base_year integer,
--   reference_year integer,
--   pct_dead integer,
--   non_veg_cover_type_1 text,
--   non_veg_cover_pct_1 integer,
--   non_veg_cover_pattern_1 integer,
--   non_veg_cover_type_2 text,
--   non_veg_cover_pct_2 integer,
--   non_veg_cover_pattern_2 integer,
--   non_veg_cover_type_3 text,
--   non_veg_cover_pct_3 integer,
--   non_veg_cover_pattern_3 integer,
--   land_cover_class_cd_1 text,
--   land_cover_pct_1 integer,
--   land_cover_class_cd_2 text,
--   land_cover_pct_2 integer,
--   land_cover_class_cd_3 text,
--   land_cover_pct_3 integer
-- )
-- WITH (
--   OIDS=FALSE
-- );
-- ALTER TABLE public.vdyp_input_poly
--   OWNER TO clus_project;
-- /*Import the data*/
-- COPY vdyp_input_poly (feature_id, map_id, polygon_number, org_unit, tsa_name, tfl_name, inventory_standard_code, tsa_number, shrub_height, shrub_crown_closure,	
-- shrub_cover_pattern, herb_cover_type_code, herb_cover_pct, herb_cover_pattern_code, bryoid_cover_pct, bec_zone_code, cfs_ecozone, pre_disturbance_stockability,	
-- yield_factor, non_productive_descriptor_cd, bclcs_level1_code, bclcs_level2_code, bclcs_level3_code, bclcs_level4_code, bclcs_level5_code, photo_estimation_base_year,	
-- reference_year, pct_dead, non_veg_cover_type_1, non_veg_cover_pct_1, non_veg_cover_pattern_1, non_veg_cover_type_2, non_veg_cover_pct_2, non_veg_cover_pattern_2,	
-- non_veg_cover_type_3, non_veg_cover_pct_3, non_veg_cover_pattern_3, land_cover_class_cd_1, land_cover_pct_1, land_cover_class_cd_2, land_cover_pct_2, land_cover_class_cd_3, land_cover_pct_3		) 
-- FROM 'C:\Users\KLOCHHEA\clus\VDYP\VEG_COMP_VDYP7_INPUT_POLY_TBL_2019.csv' DELIMITER ',' CSV HEADER;

-- /*b. Import the vdyp output table with the projections of each stand*/
-- CREATE TABLE public.vdyp
-- (
--   table_num integer,
--   feature_id integer,
--   district text,
--   map_id text,
--   polygon_id integer,
--   layer_id text,
--   projection_year integer,
--   prj_total_age integer,
--   species_1_code text,
--   species_1_pcnt double precision,
--   species_2_code text,
--   species_2_pcnt double precision,
--   species_3_code text,
--   species_3_pcnt double precision,
--   species_4_code text,
--   species_4_pcnt double precision,
--   species_5_code text,
--   species_5_pcnt double precision,
--   species_6_code text,
--   species_6_pcnt double precision,
--   prj_pcnt_stock double precision,
--   prj_site_index double precision,
--   prj_dom_ht double precision,
--   prj_lorey_ht double precision,
--   prj_diameter double precision,
--   prj_tph double precision,
--   prj_ba double precision,
--   prj_vol_ws double precision,
--   prj_vol_cu double precision,
--   prj_vol_d double precision,
--   prj_vol_dw double precision,
--   prj_vol_dwb double precision,
--   prj_sp1_vol_ws double precision,
--   prj_sp1_vol_cu double precision,
--   prj_sp1_vol_d double precision,
--   prj_sp1_vol_dw double precision,
--   prj_sp1_vol_dwb double precision,
--   prj_sp2_vol_ws double precision,
--   prj_sp2_vol_cu double precision,
--   prj_sp2_vol_d double precision,
--   prj_sp2_vol_dw double precision,
--   prj_sp2_vol_dwb double precision,
--   prj_sp3_vol_ws double precision,
--   prj_sp3_vol_cu double precision,
--   prj_sp3_vol_d double precision,
--   prj_sp3_vol_dw double precision,
--   prj_sp3_vol_dwb double precision,
--   prj_sp4_vol_ws double precision,
--   prj_sp4_vol_cu double precision,
--   prj_sp4_vol_d double precision,
--   prj_sp4_vol_dw double precision,
--   prj_sp4_vol_dwb double precision,
--   prj_sp5_vol_ws double precision,
--   prj_sp5_vol_cu double precision,
--   prj_sp5_vol_d double precision,
--   prj_sp5_vol_dw double precision,
--   prj_sp5_vol_dwb double precision,
--   prj_sp6_vol_ws double precision,
--   prj_sp6_vol_cu double precision,
--   prj_sp6_vol_d double precision,
--   prj_sp6_vol_dw double precision,
--   prj_sp6_vol_dwb double precision,
--   prj_mode text
-- )
-- WITH (
--   OIDS=FALSE
-- );
-- ALTER TABLE public.vdyp
--   OWNER TO clus_project;
  
-- /*Import the data*/
-- COPY vdyp (table_num, feature_id, district, map_id, polygon_id, layer_id, projection_year,	prj_total_age, species_1_code, species_1_pcnt, species_2_code,
-- species_2_pcnt,	species_3_code,	species_3_pcnt,	species_4_code,	species_4_pcnt,	species_5_code,	species_5_pcnt,	species_6_code,	species_6_pcnt,	
-- prj_pcnt_stock,	prj_site_index,	prj_dom_ht, prj_lorey_ht, prj_diameter,	prj_tph, prj_ba, prj_vol_ws, prj_vol_cu, prj_vol_d, prj_vol_dw,	prj_vol_dwb,	
-- prj_sp1_vol_ws,	prj_sp1_vol_cu,	prj_sp1_vol_d,	prj_sp1_vol_dw,	prj_sp1_vol_dwb, prj_sp2_vol_ws, prj_sp2_vol_cu, prj_sp2_vol_d,	prj_sp2_vol_dw,	
-- prj_sp2_vol_dwb, prj_sp3_vol_ws, prj_sp3_vol_cu, prj_sp3_vol_d,	prj_sp3_vol_dw,	prj_sp3_vol_dwb, prj_sp4_vol_ws, prj_sp4_vol_cu, prj_sp4_vol_d,	
-- prj_sp4_vol_dw,	prj_sp4_vol_dwb, prj_sp5_vol_ws, prj_sp5_vol_cu, prj_sp5_vol_d,	prj_sp5_vol_dw,	prj_sp5_vol_dwb, prj_sp6_vol_ws, prj_sp6_vol_cu,	
-- prj_sp6_vol_d,	prj_sp6_vol_dw,	prj_sp6_vol_dwb, prj_mode ) 
-- FROM 'C:\Users\KLOCHHEA\clus\VDYP\VRI2018_U175.csv' DELIMITER ',' CSV HEADER;

-- /*Create an index*/
-- CREATE INDEX vdyp_feature_id_idx ON public.vdyp using btree(feature_id);

-- /*c. Import the vdyp error output - useful for determining which stands/projections need to be removed or set to NULL*/
-- CREATE TABLE public.vdyp_err
-- (
--   error text
-- )
-- WITH (
--   OIDS=FALSE
-- );
-- ALTER TABLE public.vdyp_err
--   OWNER TO clus_project;
-- /*Import the data*/
-- COPY vdyp_err 
-- FROM 'C:\Users\KLOCHHEA\clus\VDYP\Err_VRI2018_U175.txt' DELIMITER '|';

/*--------------------------------------------------------------------------*/
/*Step 2. Remove NON-PRIMARY layer for now. Consider aggregating the layers?*/
DELETE FROM vdyp_output WHERE layer_id = 'D'; /*Remove the dead layers*/
select distinct(layer_id) from vdyp_output;

WITH prim_lookup AS (SELECT feature_id, layer_level_code FROM vdyp_input_layer 
					 WHERE forest_cover_rank_code = 1)
DELETE FROM vdyp_output B
USING prim_lookup C
WHERE B.feature_id = C.feature_id AND B.layer_id <> C.layer_level_code;

/*Remove those secondary layers that are not labeled with a Primary label*/
WITH prim_lookup AS (select feature_id, layer_level_code FROM (
	select feature_id, layer_level_code, crown_closure, max(crown_closure) 
	over (partition by feature_id) as max from vdyp_input_layer where feature_id in 
	(select feature_id from vdyp_output group by feature_id having count(feature_id) > 35)) as foo 
					 WHERE crown_closure = max)
DELETE FROM vdyp_output B
USING prim_lookup C
WHERE B.feature_id = C.feature_id AND B.layer_id <> C.layer_level_code;

/*check
select feature_id from vdyp_output group by feature_id having count(feature_id) > 35
*/

/*--------------------------------------------------------------------------*/
/* Step 3a. Set "Back" projections to NULL*/
Update vdyp_output SET  prj_pcnt_stock  = NULL, prj_site_index = NULL, prj_dom_ht = NULL, prj_lorey_ht = NULL, prj_diameter = NULL,
  prj_tph = NULL, prj_ba = NULL, prj_vol_ws = NULL, prj_vol_cu = NULL, prj_vol_d = NULL, prj_vol_dw = NULL, prj_vol_dwb = NULL,
  prj_sp1_vol_ws = NULL, prj_sp1_vol_cu = NULL, prj_sp1_vol_d = NULL, prj_sp1_vol_dw = NULL, prj_sp1_vol_dwb = NULL,
  prj_sp2_vol_ws = NULL, prj_sp2_vol_cu = NULL, prj_sp2_vol_d = NULL, prj_sp2_vol_dw = NULL, prj_sp2_vol_dwb = NULL,
  prj_sp3_vol_ws = NULL, prj_sp3_vol_cu = NULL, prj_sp3_vol_d = NULL, prj_sp3_vol_dw = NULL, prj_sp3_vol_dwb = NULL,
  prj_sp4_vol_ws = NULL, prj_sp4_vol_cu = NULL, prj_sp4_vol_d = NULL, prj_sp4_vol_dw = NULL, prj_sp4_vol_dwb = NULL, 
  prj_sp5_vol_ws = NULL, prj_sp5_vol_cu = NULL, prj_sp5_vol_d = NULL, prj_sp5_vol_dw = NULL, prj_sp5_vol_dwb = NULL,
  prj_sp6_vol_ws = NULL, prj_sp6_vol_cu = NULL, prj_sp6_vol_d = NULL, prj_sp6_vol_dw = NULL, prj_sp6_vol_dwb= NULL
  WHERE prj_mode = 'Back';

 /*VACUUM vdyp_output; Clean up the table*/

/*--------------------------------------------------------------------------*/
/* Step 4. Remove Projections that have serious errors
	a. Add a column to vdyp_err to parse out the feature_id*/
ALTER TABLE vdyp_error Add Column feature_id integer;
UPDATE vdyp_error SET feature_id = CAST(substring(error, position(': ' in error) + 2, position(' ) ' in error) - position(': ' in error)-2) AS integer );

/*Add some new columns to store the error code*/
ALTER TABLE vdyp_error Add Column code text;
ALTER TABLE vdyp_error Add Column dcode text;
UPDATE vdyp_error SET code = substring(split_part(error, ' - ', 2),1,2), dcode = split_part(error, ' - ', 2) ;

/*Remove only the errors*/
DELETE FROM vdyp_output WHERE feature_id IN (SELECT feature_id FROM vdyp_error WHERE code = 'E '); 

/*--------------------------------------------------------------------------*/
/*Step 5. Merge in VRI forest Attribute information for creating aggregated key. */
select distinct(for_cover_rank_cd) from veg_comp_lyr_r1_poly;

/*a. Create a simpflified VEG_COMP table with the necessay information for the aggregated key*/
CREATE TABLE vdyp_vri2018 AS SELECT feature_id, reference_year, bec_zone_code, bclcs_level_3, 
basal_area, crown_closure, crown_closure_class_cd, proj_age_1, age_class, proj_height_1, proj_height_class_cd_1, 
site_index, line_3_tree_species, species_cd_1, species_pct_1, species_cd_2, species_pct_2, species_cd_3,
species_pct_3, species_cd_4,species_pct_4, polygon_area, geometry  
FROM public.veg_comp_lyr_r1_poly
WHERE bclcs_level_2 = 'T' AND species_pct_1 > 0 and opening_id IS NULL AND for_cover_rank_cd = '1';

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


/* Group species that are the same*/
Update vdyp_vri2018 set species_pct_1 = (species_pct_1 + species_pct_2) WHERE species_cd_1 = species_cd_2; 
Update vdyp_vri2018 set species_cd_2 = NULL, species_pct_2 = NULL WHERE species_cd_1 = species_cd_2;

/*Make the aggregated sepcies call*/
Alter TAble vdyp_vri2018 Add Column l3spp text ;
Update vdyp_vri2018 set l3spp = CASE
--WHEN species_cd_3 IS NOT NULL AND species_pct_3 >= 20 THEN CONCAT(species_cd_1,species_cd_2,species_cd_3)
--WHEN species_cd_3 IS NOT NULL AND species_pct_3 < 20 THEN CONCAT(species_cd_1,species_cd_2,'(', species_cd_3,')')
--WHEN species_cd_3 IS NULL AND species_cd_2 IS NOT NULL AND species_pct_2 >= 20 THEN CONCAT(species_cd_1,species_cd_2)
--WHEN species_cd_3 IS NULL AND species_cd_2 IS NOT NULL AND species_pct_2 < 20 THEN CONCAT(species_cd_1,'(',species_cd_2,')')
--WHEN species_cd_3 IS NULL AND species_cd_2 IS NULL THEN species_cd_1
WHEN species_cd_2 IS NOT NULL AND species_pct_2 >= 20 THEN CONCAT(species_cd_1,species_cd_2)
WHEN species_cd_2 IS NOT NULL AND species_pct_2 < 20 THEN CONCAT(species_cd_1,'(',species_cd_2,')')
WHEN species_cd_2 IS NULL THEN species_cd_1
END;

Update vdyp_vri2018 set site_index = round(site_index / 2 ) * 2; /*round the site index to nearest meter*/

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

create table vdyp_test as (SELECT * from (
	select yc_grp, polygon_area, b.feature_id, opening_id, 
										bclcs_level_2, prj_total_age, 
prj_site_index, prj_dom_ht, prj_lorey_ht, prj_diameter, prj_tph, prj_ba, prj_vol_ws, prj_vol_cu, 
										 prj_vol_d, prj_vol_dw, prj_vol_dwb, prj_sp1_vol_dwb, prj_sp2_vol_dwb,
	prj_sp3_vol_dwb, prj_sp4_vol_dwb, prj_sp5_vol_dwb, prj_sp6_vol_dwb, species_1_code, species_2_code,
	species_3_code,species_4_code,species_5_code,species_6_code
FROM vdyp_output
FULL JOIN (SELECT feature_id, yc_grp, polygon_area, opening_id, bclcs_level_2 FROM vdyp_vri2018) as b
ON vdyp_output.feature_id = b.feature_id) as foo);

/*----------OMISSION-----*/
DELETE from vdyp_test where opening_id is NOT NULL OR yc_grp Is NULL;
DELETE from vdyp_test where feature_id IN (select feature_id from vdyp_test where prj_total_age is NULL);

alter table vdyp_test add column perdec1 double precision; 
update vdyp_test set perdec1 = case when species_1_code IN ('AC','ACB','ACT','AT','AX','D','DR','E','EA','EP','ES','EW','M','MB','MV') then prj_sp1_vol_dwb end;

alter table vdyp_test add column perdec2 double precision; 
update vdyp_test set perdec2 = case when species_2_code IN ('AC','ACB','ACT','AT','AX','D','DR','E','EA','EP','ES','EW','M','MB','MV') then prj_sp2_vol_dwb end;

alter table vdyp_test add column perdec3 double precision; 
update vdyp_test set perdec3 = case when species_3_code IN ('AC','ACB','ACT','AT','AX','D','DR','E','EA','EP','ES','EW','M','MB','MV') then prj_sp3_vol_dwb end;

alter table vdyp_test add column perdec4 double precision; 
update vdyp_test set perdec4 = case when species_4_code IN ('AC','ACB','ACT','AT','AX','D','DR','E','EA','EP','ES','EW','M','MB','MV') then prj_sp4_vol_dwb end;

alter table vdyp_test add column perdec5 double precision; 
update vdyp_test set perdec5 = case when species_5_code IN ('AC','ACB','ACT','AT','AX','D','DR','E','EA','EP','ES','EW','M','MB','MV') then prj_sp5_vol_dwb end;

alter table vdyp_test add column perdec6 double precision; 
update vdyp_test set perdec6 = case when species_6_code IN ('AC','ACB','ACT','AT','AX','D','DR','E','EA','EP','ES','EW','M','MB','MV') then prj_sp6_vol_dwb end;

alter table vdyp_test add column decper double precision; 
update vdyp_test set decper = ((coalesce(perdec1,0) + coalesce(perdec2,0) + coalesce(perdec3,0)+coalesce(perdec4,0) +coalesce(perdec5,0) + coalesce(perdec6,0)) / prj_vol_dwb)
where prj_vol_dwb > 0;
update vdyp_test set decper = ROUND(CAST(decper as numeric), 2);



create table vdyp_test2 as (SELECT * from (select vdyp_test.yc_grp, polygon_area, total_area, polygon_area/total_area as wt, feature_id, opening_id, 
										bclcs_level_2, prj_total_age, 
prj_site_index, prj_dom_ht, prj_lorey_ht, prj_diameter, prj_tph, prj_ba, prj_vol_ws, prj_vol_cu, 
										 prj_vol_d, prj_vol_dw, prj_vol_dwb, decper
FROM vdyp_test
FULL JOIN (select yc_grp,  sum(polygon_area) as total_area 
							   from vdyp_test where prj_total_age = 10 group by yc_grp) as b
ON vdyp_test.yc_grp = b.yc_grp) as foo);


create table vdyp_test3 as (select prj_total_age, yc_grp,
sum(case when prj_site_index is not null then prj_site_index*wt end) / sum(case when prj_site_index is not null then wt end) as prj_site_index,
sum(case when prj_vol_ws is not null then prj_vol_ws*wt end) / sum(case when prj_vol_ws is not null then wt end) as prj_vol_ws,
sum(case when prj_vol_dwb is not null then prj_vol_dwb*wt end) / sum(case when prj_vol_dwb is not null then wt end) as prj_vol_dwb,
sum(case when prj_vol_cu is not null then prj_vol_cu*wt end) / sum(case when prj_vol_cu is not null then wt end) as prj_vol_cu,
sum(case when prj_diameter is not null then prj_diameter*wt end) / sum(case when prj_diameter is not null then wt end) as prj_diameter,
sum(case when prj_ba is not null then prj_ba*wt end) / sum(case when prj_ba is not null then wt end) as prj_ba,
sum(case when prj_tph is not null then prj_tph*wt end) / sum(case when prj_tph is not null then wt end) as prj_tph,
sum(case when prj_dom_ht is not null then prj_dom_ht*wt end) / sum(case when prj_dom_ht is not null then wt end) as prj_dom_ht,
sum(case when prj_lorey_ht is not null then prj_lorey_ht*wt end) / sum(case when prj_lorey_ht is not null then wt end) as prj_lorey_ht,
sum(case when decper is not null then decper*wt end) / sum(case when decper is not null then wt end) as prj_decper
FROM vdyp_test2
group by yc_grp, prj_total_age);

--select * from vdyp_test2 order by yc_grp limit 10000;
select * from vdyp_test3 where yc_grp like 'BWBS_At(Ac)%';
/*--------------------------------------------------------------------------*/
/*Step 6. build the yieldcurve table. */

Create table yc_vdyp as
SELECT ycid, yc_vdyp_vat.yc_grp, prj_total_age as age,
prj_vol_dwb as tvol, prj_dom_ht as height , prj_decper as dec_pcnt, (0) as eca FROM yc_vdyp_vat
JOIN vdyp_test3 ON
yc_vdyp_vat.yc_grp = vdyp_test3.yc_grp;

Update yc_vdyp set tvol = 0 where tvol is NULL;

--add the lower limit of the yield curve
insert into yc_vdyp (ycid, yc_grp, age, tvol, height, dec_pcnt, eca)
select distinct(ycid),  yc_grp, (0) as age, (0.0) as tvol, (0.0) as height, (0.0) as dec_pcnt, (0) as eca
from yc_vdyp;

/*STEP 7. Formatting */

--select * from yc_vdyp order by yc_grp, age limit 1000;
update yc_vdyp set dec_pcnt = ROUND(CAST(dec_pcnt as numeric), 2);
update yc_vdyp set height = ROUND(CAST(height as numeric), 2);
update yc_vdyp set tvol = ROUND(CAST(tvol as numeric), 2);

ALTER TABLE yc_vdyp
ALTER COLUMN eca TYPE double precision;

ALTER TABLE yc_vdyp
ALTER COLUMN ycid TYPE integer;

