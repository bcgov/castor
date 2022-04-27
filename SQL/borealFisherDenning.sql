select feature_id, bec_zone_code, bec_subzone from public.veg_comp_lyr_r1_poly2020 where 
(((SPECIES_CD_1 LIKE 'AC%'  or SPECIES_CD_2 LIKE 'AC%' or  SPECIES_CD_3 LIKE 'AC%') 
 and PROJ_AGE_1>=88 and QUAD_DIAM_125>=19.5 and PROJ_HEIGHT_1>=19) 
 or ((SPECIES_CD_1 LIKE 'AT%'  or SPECIES_CD_2 LIKE 'AT%' or  SPECIES_CD_3 LIKE 'AT%') 
	 and PROJ_AGE_1>=98 and QUAD_DIAM_125>=21.3 and PROJ_HEIGHT_1>=22.8)) 
	 AND ((bec_zone_code = 'BWBS' AND bec_subzone IN ('dk', 'mw', 'wk')) or 
(bec_zone_code ='SBS' and bec_subzone = 'wk' and bec_variant ='2'));