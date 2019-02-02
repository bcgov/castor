/*
SELECT * FROM VRI_SPECIES_GROUPS
DROP TABLE IF EXISTS VRI_SPECIES_GROUPS
CREATE UNIQUE INDEX IDX_VRI_TSA_SPECIES_GROUPS ON VRI_TSA_SPECIES_GROUPS(FEATURE_ID_WITH_TFL)
*/
--------------------------------------------------------------------------------------------
CREATE TABLE VRI_TSA_SPECIES_GROUPS AS
WITH UNPIVOT AS 
(
SELECT 
  feature_id_with_tfl,
  t1.i SPECIES_ORDER, 
  t1.SPECIES_CD,
  t1.SPECIES_PCT,
CASE 
WHEN UPPER(SPECIES_CD) IN ('D','DG','DM','DR','E','EA','EB','EE','EP','ES','EW','EX','EXP','EXW') THEN 'ALB'
WHEN UPPER(SPECIES_CD) IN ('A','AC','ACB','ACT','AD','AT','AX') THEN 'APC'
WHEN UPPER(SPECIES_CD) IN ('B','BA','BB','BC','BG','BL','BM','BP') THEN 'BAL'
WHEN UPPER(SPECIES_CD) IN ('C','CW') THEN 'CED'
WHEN UPPER(SPECIES_CD) IN ('Y','YC') THEN 'CYP'
WHEN UPPER(SPECIES_CD) IN ('F','FD','FDC','FDI') THEN 'FIR'
WHEN UPPER(SPECIES_CD) IN ('H','HM','HW','HX','HXM') THEN 'HEM'
WHEN UPPER(SPECIES_CD) IN ('L','LA','LD','LS','LT','LW') THEN 'LAR'
WHEN UPPER(SPECIES_CD) IN ('G','GP','GR','J','JD','JH','JR','K','KC','M','MB','ME','MN','MR','MS','MV','OA','OB','OC','OD','OE','OF','OG','OH','OI','Q','QE','QG','QW','R','RA','T','TW','U','UA','UP','V','VB','VP','VS','VV','VW','W','WA','WB','WD','WP','WS','WT','X','XC','XH','YP','Z','ZC','ZH') THEN 'OTH'
WHEN UPPER(SPECIES_CD) IN ('P','PA','PF','PJ','PL','PLC','PLI','PM','PR','PS','PW','PX','PXJ','PY') THEN 'PIN'
WHEN UPPER(SPECIES_CD) IN ('SB') THEN 'SPB'
WHEN UPPER(SPECIES_CD) IN ('S','SA','SE','SN','SS','SW','SX','SXB','SXE','SXL','SXS','SXW','SXX') THEN 'SPR'
END AS SPECIES_CD_CLASS, 
CASE 
WHEN UPPER(SPECIES_CD) IN ('B','BA','BB','BC','BG','BL','BM','BP','C','CW','F','FD','FDC','FDI','H','HM','HW','HX','HXM','L','LA','LD','LS','LT','LW','P','PA','PF','PJ','PL','PLC','PLI','PM','PR','PS','PW','PX','PXJ','PY','S','SA','SB','SE','SN','SS','SW','SX','SXB','SXE','SXL','SXS','SXW','SXX','Y','YC') THEN 'CON'
WHEN UPPER(SPECIES_CD) IN ('A','AC','ACB','ACT','AD','AT','AX','D','DG','DM','DR','E','EA','EB','EE','EP','ES','EW','EX','EXP','EXW') THEN 'DEC'
ELSE 'OTH'
END AS SPECIES_TYPE_CLASS
--FROM VRI_TFL vri
FROM VRI_TSA_ATT
--FROM VEG_COMP_LYR_R1_POLY_WITH_TFL vri
--FROM VEG_COMP_LYR_L1_POLY vri
CROSS JOIN LATERAL 
unnest(
array[SPECIES_CD_1,SPECIES_CD_2, SPECIES_CD_3,SPECIES_CD_4,SPECIES_CD_5,SPECIES_CD_6], 
array[coalesce(SPECIES_PCT_1, 0),coalesce(SPECIES_PCT_2, 0), coalesce(SPECIES_PCT_3, 0),coalesce(SPECIES_PCT_4, 0),coalesce(SPECIES_PCT_5, 0),coalesce(SPECIES_PCT_6, 0)]
) with ordinality as t1(SPECIES_CD, SPECIES_PCT, i) 
--LIMIT 100000 OFFSET 100000
) ,
-- Temp table of that sums the percent by species
SUM_SPECIES AS
(SELECT FEATURE_ID_WITH_TFL,
  SPECIES_CD_CLASS,
  sum(SPECIES_PCT) as species_pct
FROM UNPIVOT
WHERE SPECIES_PCT IS NOT NULL
GROUP BY   FEATURE_ID_WITH_TFL, SPECIES_CD_CLASS
order by FEATURE_ID_WITH_TFL),

SUM_SPECIES_TYP AS
(SELECT FEATURE_ID_WITH_TFL,
  SPECIES_TYPE_CLASS,
  sum(SPECIES_PCT) as species_pct
FROM UNPIVOT
WHERE SPECIES_PCT IS NOT NULL
GROUP BY   FEATURE_ID_WITH_TFL, SPECIES_TYPE_CLASS
order by FEATURE_ID_WITH_TFL),

--Assigns a rank to each species.  1 is the is the leading species
SUM_SPECIES_RANK AS
(
 SELECT
  A.FEATURE_ID_WITH_TFL,
  A.SPECIES_CD_CLASS,
 coalesce(A.SPECIES_PCT, 0) AS SPECIES_PCT,
 coalesce(B.SPECIES_PCT, 0) AS SPECIES_TYP_PCT,
 B.SPECIES_TYPE_CLASS,
  RANK() OVER (PARTITION BY A.FEATURE_ID_WITH_TFL ORDER BY A.SPECIES_PCT Desc) AS RANK,
  DENSE_RANK() OVER (PARTITION BY B.FEATURE_ID_WITH_TFL ORDER BY B.SPECIES_PCT Desc) AS RANK_TYP
from SUM_SPECIES A LEFT JOIN SUM_SPECIES_TYP B ON A.FEATURE_ID_WITH_TFL= B.FEATURE_ID_WITH_TFL
order by FEATURE_ID_WITH_TFL
),
-------------------------The Final Query
PRE_SUMMARY AS 
(
SELECT FEATURE_ID_WITH_TFL, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'ALB' THEN 
 coalesce(SPECIES_PCT , 0)
 END) ALB_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'APC' THEN 
 coalesce(SPECIES_PCT, 0)
 END) APC_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'BAL' THEN 
 coalesce(SPECIES_PCT, 0)
 END) BAL_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'CED' THEN 
 coalesce(SPECIES_PCT, 0) 
 END) CED_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'CYP' THEN 
 coalesce(SPECIES_PCT, 0) 
 END) CYP_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'FIR' THEN 
 coalesce(SPECIES_PCT, 0) 
 END) FIR_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'HEM' THEN 
 coalesce(SPECIES_PCT, 0) 
 END) HEM_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'LAR' THEN 
 coalesce(SPECIES_PCT, 0) 
 END) LAR_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'OTH' THEN 
 coalesce(SPECIES_PCT, 0) 
 END) OTH_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'PIN' THEN 
 coalesce(SPECIES_PCT, 0) 
 END) PIN_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'SPB' THEN 
 coalesce(SPECIES_PCT, 0)
 END) SPB_SPECIES_PCT, 
MIN(CASE 
 WHEN SPECIES_CD_CLASS = 'SPR' THEN 
 coalesce(SPECIES_PCT, 0)
 END) SPR_SPECIES_PCT,
-------------------------------------------
MIN(case
      when RANK = 1 
          then
                SPECIES_PCT
             END) PRIMARY_SPECIES_PCT,

MIN(case
      when RANK = 2 
          then
                SPECIES_PCT
             END) SECONDARY_SPECIES_PCT,

MIN(case
      when RANK = 3 
          then
                SPECIES_PCT
             END) TERTIARY_SPECIES_PCT,

 MIN(case
      when RANK = 1 
          then
                SPECIES_CD_CLASS
             END) PRIMARY_SPECIES,
             
 MIN(case
      when RANK = 2 
          then
                SPECIES_CD_CLASS
             END) SECONDARY_SPECIES,

 MIN(case
      when RANK = 3 
          then
                SPECIES_CD_CLASS
             END) TERTIARY_SPECIES
-------------------------------------------             
 from   SUM_SPECIES_RANK 
 GROUP  BY FEATURE_ID_WITH_TFL
 ),
------------------------------------------------------------------------------------------------------------
PRE_SUMMARY_TYP AS 
(
SELECT FEATURE_ID_WITH_TFL, 
MIN(CASE 
 WHEN SPECIES_TYPE_CLASS = 'CON' THEN 
 coalesce(SPECIES_TYP_PCT , 0)
 END) CON_SPECIES_TYP_PCT, 
MIN(CASE 
 WHEN SPECIES_TYPE_CLASS = 'DEC' THEN 
 coalesce(SPECIES_TYP_PCT , 0)
 END) DEC_SPECIES_TYP_PCT, 
MIN(CASE 
 WHEN SPECIES_TYPE_CLASS = 'OTH' THEN 
 coalesce(SPECIES_TYP_PCT , 0)
 END) OTH_SPECIES_TYP_PCT,
-------------------------------------------
MIN(case
      when RANK_TYP = 1 
          then
                SPECIES_TYP_PCT
             END) PRIMARY_SPECIES_TYP_PCT,

MIN(case
      when RANK_TYP = 2 
          then
                SPECIES_TYP_PCT
             END) SECONDARY_SPECIES_TYP_PCT,

MIN(case
      when RANK_TYP = 3 
          then
                SPECIES_TYP_PCT
             END) TERTIARY_SPECIES_TYP_PCT,
-------------------------------------------             
 MIN(case
      when RANK_TYP = 1 
          then
                SPECIES_TYPE_CLASS
             END) PRIMARY_SPECIES_TYPE,
             
 MIN(case
      when RANK_TYP = 2 
          then
                SPECIES_TYPE_CLASS
             END) SECONDARY_SPECIES_TYPE,

 MIN(case
      when RANK_TYP = 3 
          then
                SPECIES_TYPE_CLASS
             END) TERTIARY_SPECIES_TYPE
-------------------------------------------             
 from   SUM_SPECIES_RANK 
 GROUP  BY FEATURE_ID_WITH_TFL
 )
 
 ----------Final Query 
 SELECT 
 A.*, concat_ws('-', A.PRIMARY_SPECIES, A.SECONDARY_SPECIES, A.TERTIARY_SPECIES) AS TOP_3_SPECIES, 
 B.CON_SPECIES_TYP_PCT, B.DEC_SPECIES_TYP_PCT, B.OTH_SPECIES_TYP_PCT, B.PRIMARY_SPECIES_TYP_PCT, B.SECONDARY_SPECIES_TYP_PCT, B.TERTIARY_SPECIES_TYP_PCT, concat_ws('-', B.PRIMARY_SPECIES_TYPE, B.SECONDARY_SPECIES_TYPE, B.TERTIARY_SPECIES_TYPE) AS TOP_3_SPECIES_TYPE,
 ---
CASE WHEN round(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric, -1)/10::INT + round(coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric, -1)/10::INT > 10 THEN 
  CASE WHEN coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric > coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric THEN 
	(round(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric, -1)/10)::INT
  ELSE
	floor(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric/10)::INT
  END
 ELSE
 (round(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric, -1)/10)::INT
 END AS CON,
 ---
CASE WHEN round(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric, -1)/10::INT + round(coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric, -1)/10::INT > 10 THEN 
  CASE WHEN coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric > coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric THEN 
	(round(coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric, -1)/10)::INT
  ELSE
	floor(coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric/10)::INT
  END
 ELSE
 (round(coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric, -1)/10)::INT 
 END AS DEC,

 --Trying to create a column for a single CON-DEC raster output value
 CASE WHEN round(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric, -1)/10::INT + round(coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric, -1)/10::INT > 10 THEN 
 (10000 + (lpad((round(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric, -1)/10)::INT::CHAR(2), 2, '0') || lpad((floor((coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric)/10))::INT::CHAR(2), 2, '0'))::BIGINT)  
 ELSE
 (10000 + (lpad((round(coalesce(B.CON_SPECIES_TYP_PCT, 0)::numeric, -1)/10)::INT::CHAR(2), 2, '0') || lpad((round(coalesce(B.DEC_SPECIES_TYP_PCT, 0)::numeric, -1)/10)::INT::CHAR(2), 2, '0'))::BIGINT)  
 END AS CONDEC
 FROM PRE_SUMMARY A LEFT JOIN PRE_SUMMARY_TYP B ON A.FEATURE_ID_WITH_TFL = B.FEATURE_ID_WITH_TFL
 --WHERE FEATURE_ID IN (35192455); 9516487

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
