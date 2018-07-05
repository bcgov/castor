/*-------------------------------------------------------------------------------------
------------QUERY TO SUMMARIZE HERDS BY TSA--------------------------------------------

MIKE FOWLER
GIS ANALYST
JULY 20187
-------------------------------------------------------------------------------------*/
CREATE OR REPLACE VIEW V_CLUS_HERD_BY_TSA AS

SELECT MAIN.HERD_NAME, MAIN.HERD_TOTAL_AREA, MAIN.TSA_NUMBER, MAIN.TSA_NAME, MAIN.TSA_AREA, MAIN.HERD_COMPONENT_AREA AS HERD_TSA_AREA, 
CASE WHEN MAIN.TSA_AREA > 0 THEN (MAIN.HERD_COMPONENT_AREA/MAIN.TSA_AREA) * 100 ELSE 0 END AS HERD_PCT,
CASE WHEN MAIN.TSA_AREA > 0 THEN to_char((MAIN.HERD_COMPONENT_AREA/MAIN.TSA_AREA) * 100, '9999D99%') ELSE '--' END AS HERD_PCT_FORMAT
FROM 
(
SELECT 
SMAIN.HERD_NAME, MAX(SMAIN.HERD_AREA) AS HERD_TOTAL_AREA,
SMAIN.TSA AS TSA_NUMBER, SMAIN.TSA_DESC AS TSA_NAME, 
CASE WHEN MAX(SMAIN.TSA_AREA) IS NULL THEN 0 ELSE MAX(SMAIN.TSA_AREA) END AS TSA_AREA,
SUM(UNION_AREA) AS HERD_COMPONENT_AREA
FROM 
(
SELECT A.HERD_NAME, 
CASE WHEN A.TSA_NUMBER = '' THEN 'OUTSIDE-TSA' ELSE A.TSA_NUMBER END AS TSA,
CASE WHEN A.TSA_NUMBER_DESCRIPTION = '' THEN 'OUTSIDE-TSA' ELSE A.TSA_NUMBER_DESCRIPTION END AS TSA_DESC,
B.AREA_HA AS HERD_AREA,
C.AREA_HA AS TSA_AREA,
GETHA(A.WKB_GEOMETRY) AS UNION_AREA
FROM TSA_HERD_UNION A
LEFT JOIN (
/*-------------------------------------------------------------------------------------
------------QUERY TO GET AREA BY HERD---------------------------------------------------
-------------------------------------------------------------------------------------*/
SELECT SUBA.HERD_NAME, SUM(GETHA(SUBA.WKB_GEOMETRY)) AS AREA_HA
FROM TSA_HERD_UNION SUBA 
WHERE SUBA.CARIBOU_POPULATION_ID IS NOT NULL AND SUBA.CARIBOU_POPULATION_ID <> 0
GROUP BY SUBA.HERD_NAME
ORDER BY SUBA.HERD_NAME
) B ON A.HERD_NAME=B.HERD_NAME

LEFT JOIN (
/*-------------------------------------------------------------------------------------
------------QUERY TO GET AREA BY TSA---------------------------------------------------
-------------------------------------------------------------------------------------*/
SELECT SUBB.TSA_NUMBER, SUBB.TSA_NUMBER_DESCRIPTION, SUM(GETHA(SUBB.WKB_GEOMETRY)) AS AREA_HA
FROM TSA_HERD_UNION SUBB
WHERE SUBB.TSA_NUMBER <> ''
GROUP BY SUBB.TSA_NUMBER, SUBB.TSA_NUMBER_DESCRIPTION
ORDER BY SUBB.TSA_NUMBER
) C ON A.TSA_NUMBER = C.TSA_NUMBER

WHERE A.HERD_NAME IS NOT NULL AND A.HERD_NAME <> ''
ORDER BY A.HERD_NAME, A.TSA_NUMBER
) SMAIN
GROUP BY SMAIN.HERD_NAME, SMAIN.TSA, SMAIN.TSA_DESC
ORDER BY SMAIN.HERD_NAME, SMAIN.TSA, SMAIN.TSA_DESC
) MAIN;

/*-------------------------------------------------------------------------------------
------------QUERY TO GET AREA BY HERD---------------------------------------------------
-------------------------------------------------------------------------------------
SELECT HERD_NAME, SUM(GETHA(WKB_GEOMETRY)) AS AREA_HA
FROM TSA_HERD_UNION
WHERE CARIBOU_POPULATION_ID IS NOT NULL AND CARIBOU_POPULATION_ID <> 0
GROUP BY HERD_NAME
ORDER BY HERD_NAME;
/*-------------------------------------------------------------------------------------
------------QUERY TO GET AREA BY TSA---------------------------------------------------
-------------------------------------------------------------------------------------
SELECT TSA_NUMBER, TSA_NUMBER_DESCRIPTION, SUM(GETHA(WKB_GEOMETRY)) AS AREA_HA
FROM TSA_HERD_UNION
WHERE TSA_NUMBER <> ''
GROUP BY TSA_NUMBER, TSA_NUMBER_DESCRIPTION
ORDER BY TSA_NUMBER;