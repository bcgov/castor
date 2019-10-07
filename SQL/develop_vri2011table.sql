/*a. Create a simpflified VEG_COMP table with the necessay information for the aggregated key*/
CREATE TABLE yt_vri2011 AS SELECT feature_id, reference_year, bec_zone_code, bclcs_level_3, 
basal_area, crown_closure, crown_closure_class_cd, proj_age_1, age_class, proj_height_1, proj_height_class_cd_1, 
site_index, line_3_tree_species, species_cd_1, species_pct_1, species_cd_2, species_pct_2, species_cd_3,
species_pct_3, species_cd_4,species_pct_4, polygon_area, geometry  
FROM public.veg_comp_lyr_r1_poly2011
WHERE bclcs_level_2 = 'T' AND species_pct_1 > 0 and opening_id IS NULL AND for_cover_rank_cd = '1';

delete from yt_vri2011 where UPPER(species_cd_1) IN ('G','GP','GR','J','JD','JH','JR','K','KC','OA','OB','OC','OD','OE','OF','OG','OH','OI','Q','QE','QG','QW','R','RA','T','TW','U','UA','UP',
'V','VB','VP','VS','VV','VW','W','WA','WB','WD','WP','WS','WT','X','XC','XH','YP','Z','ZC','ZH'); /*non commercial species*/ 

CREATE INDEX yt_vri2011_feature_id_idx /*Create an index which will be used to link with the vdyp output*/
  ON public.vdyp_vri2018
  USING btree
  (feature_id);

/*b. Create an aggregated species call similar to line_3_tree_species in the VEG_COMP --i.e., A list of major species (minor species), ordered by percentage. 
The species symbols are F (Douglas fir), C (western red cedar), H (hemlock), B (balsam), S (spruce), Sb (black spruce), Yc (yellow cedar), P (pine), L (larch), 
Ac (Populus), D (red alder), Mb (broadleaf maple), E (birch), O (non-commercial). 
see https://www2.gov.bc.ca/assets/gov/farming-natural-resources-and-industry/forestry/stewardship/forest-analysis-inventory/data-management/standards/vegcomp_poly_rank1_data_dictionary_draft40.pdf*/ 

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
--WHEN species_cd_3 IS NOT NULL AND species_pct_3 >= 20 THEN CONCAT(species_cd_1,species_cd_2,species_cd_3)
--WHEN species_cd_3 IS NOT NULL AND species_pct_3 < 20 THEN CONCAT(species_cd_1,species_cd_2,'(', species_cd_3,')')
--WHEN species_cd_3 IS NULL AND species_cd_2 IS NOT NULL AND species_pct_2 >= 20 THEN CONCAT(species_cd_1,species_cd_2)
--WHEN species_cd_3 IS NULL AND species_cd_2 IS NOT NULL AND species_pct_2 < 20 THEN CONCAT(species_cd_1,'(',species_cd_2,')')
--WHEN species_cd_3 IS NULL AND species_cd_2 IS NULL THEN species_cd_1
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
