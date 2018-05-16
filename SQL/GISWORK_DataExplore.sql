/*------------------------------------------------------------------------------
VRI
------------------------------------------------------------------------------*/
SELECT COUNT(*) FROM WHSE_FOREST_VEGETATION.VEG_COMP_LAYER@BCGW  --4,991,744
SELECT COUNT(*) FROM WHSE_FOREST_VEGETATION.VEG_COMP_POLY@BCGW   --4,677,411

SELECT COUNT(*) FROM 
(
SELECT FEATURE_ID, COUNT(*) AS TOT_FEAT
FROM WHSE_FOREST_VEGETATION.VEG_COMP_LAYER@BCGW
GROUP BY FEATURE_ID
ORDER BY TOT_FEAT DESC
) 
WHERE TOT_FEAT > 1


SELECT * 
FROM WHSE_FOREST_VEGETATION.VEG_COMP_LAYER@BCGW
WHERE FEATURE_ID = 10345920





/*------------------------------------------------------------------------------
Wildlife Management Units
------------------------------------------------------------------------------*/
CREATE OR REPLACE VIEW CRP_BCGW_WILDLIFE_MU
AS
SELECT * 
FROM WHSE_WILDLIFE_MANAGEMENT.WAA_WILDLIFE_MGMT_UNITS_SVW@BCGW;
/*------------------------------------------------------------------------------
Free Use Permits
------------------------------------------------------------------------------*/
SELECT * FROM WHSE_FOREST_TENURE.FTEN_FREE_USE_PERMIT_POLY_SVW@BCGW

SELECT FUP_COMMENT, COUNT(*)
FROM WHSE_FOREST_TENURE.FTEN_FREE_USE_PERMIT_POLY_SVW@BCGW
GROUP BY FUP_COMMENT
ORDER BY FUP_COMMENT ASC

/*------------------------------------------------------------------------------
Special Use Permits
------------------------------------------------------------------------------*/
SELECT * FROM WHSE_FOREST_TENURE.FTEN_SPEC_USE_PERMIT_POLY_SVW@BCGW

SELECT SPECIAL_USE_DESCRIPTION, COUNT(*)
FROM WHSE_FOREST_TENURE.FTEN_SPEC_USE_PERMIT_POLY_SVW@BCGW
GROUP BY SPECIAL_USE_DESCRIPTION
ORDER BY SPECIAL_USE_DESCRIPTION ASC
/*------------------------------------------------------------------------------
Commercial Recreation Tenures
------------------------------------------------------------------------------*/
SELECT * FROM WHSE_TANTALIS.TA_CROWN_TENURES_SVW@BCGW

SELECT TENURE_PURPOSE, TENURE_SUBPURPOSE, COUNT(*)
FROM WHSE_TANTALIS.TA_CROWN_TENURES_SVW@BCGW
GROUP BY TENURE_PURPOSE, TENURE_SUBPURPOSE
ORDER BY TENURE_PURPOSE ASC, TENURE_SUBPURPOSE ASC



