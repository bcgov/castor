-------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FAIB_FC_TO_RASTER(fc VARCHAR, valFld VARCHAR, outRaster VARCHAR, rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT True) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
A function to return the lower left coordinates for a feature class that will align with the BC Raster Standard
Gets the lower left (xMin, yMin) of the Feature Class table object and return an 2 index array [1] xMin,  [2] yMin

Raster Pixel Types:
-----------------------------------
1BB - 1-bit boolean
2BUI - 2-bit unsigned integer
4BUI - 4-bit unsigned integer
8BSI - 8-bit signed integer
8BUI - 8-bit unsigned integer
16BSI - 16-bit signed integer
16BUI - 16-bit unsigned integer
32BSI - 32-bit signed integer
32BUI - 32-bit unsigned integer
32BF - 32-bit float
64BF - 64-bit float

Arguments: PostGIS Vector Feature Class Table, Geometry Field, Raster Value Field, Output Raster Name, Raster Size - Default 100, Raster Pixel Type - Default 32Bit Float, No Data Value - Default 0

Usage: SELECT FAIB_FC_TO_RASTER('BEC_ZONE_CLIP', 'BEC_KEY', 'BEC_ZONE_CLIP_RASTER', 100);

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
	tmpRaster VARCHAR;
	geom VARCHAR;
	cursExt REFCURSOR; 
BEGIN
	geom = FAIB_GET_GEOMETRY_COLUMN(UPPER(fc));
	qry := 	'CREATE TABLE ' || outRaster ||' AS
		SELECT ROW_NUMBER() OVER () AS RID, ''' || fc || ''' AS SOURCE_FC,  ''' || valFld || ''' AS SOURCE_FIELD, ST_UNION(
		ST_ASRASTER(' ||
		geom || ', ' || rastSize::DECIMAL(6,2) || ',' || rastSize::DECIMAL(6,2) ||', (FAIB_GET_BC_RASTER_ORIGIN(''' || fc || ''', ''' || geom ||''', ''UL''))[1], 
		(FAIB_GET_BC_RASTER_ORIGIN(''' || fc || ''', ''' || geom || ''', ''UL''))[2],''' || rastPixType || ''',' || valFld || ',' || noData
		|| ')) RAST
		FROM ' || fc || ';';
	RAISE NOTICE '%', qry;
	EXECUTE 'DROP TABLE IF EXISTS ' || outRaster ||';';
	EXECUTE qry;
	IF tile THEN
		--RAISE NOTICE 'We are going to do some tiling!!';
		tmpRaster = 'ZZ_' || outRaster;
		EXECUTE 'DROP TABLE IF EXISTS ' || tmpRaster ||';';
		qry = 'CREATE TABLE ' || tmpRaster || '
		AS
		SELECT ROW_NUMBER() OVER () RID, SOURCE_FC, SOURCE_FIELD, RAST
		FROM (
		SELECT ROW_NUMBER() OVER () RID, SOURCE_FC, SOURCE_FIELD, ST_TILE(rast, 100, 100) rast
		FROM ' || outRaster || ') A;';
		--RAISE NOTICE '%s', qry;
		EXECUTE qry;
		EXECUTE 'DROP TABLE IF EXISTS ' || outRaster || ';';
		EXECUTE 'ALTER TABLE ' || tmpRaster || ' RENAME TO ' || outRaster || ';';
	ELSE
		--RAISE NOTICE 'We are NOT tiling!!';
		NULL;
	END IF;
	--RAISE NOTICE 'Spatial Indexing %s', outRaster;
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || fc || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || fc || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
	--RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
-------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FAIB_GET_BC_RASTER_ORIGIN(fc VARCHAR, geom VARCHAR, origin CHAR(2) DEFAULT 'UL') RETURNS NUMERIC[]
/*------------------------------------------------------------------------------------------------------------------
A function to return an origin location set of coordinates (LL, UL, UR, LR) for a feature class that will align with the BC Raster Standard

UL - Upper Left - Gets the upper left (xMin, yMax) of the Feature Class table object and return an 2 index array [1] xMin,  [2] yMax
LL - Lower Left - Gets the lower left (xMin, yMin) of the Feature Class table object and return an 2 index array [1] xMin,  [2] yMin
UR - Upper Right - Gets the upper right (xMax, yMax) of the Feature Class table object and return an 2 index array [1] xMax,  [2] yMax
LR - Lower Right - Gets the lower right (xMax, yMin) of the Feature Class table object and return an 2 index array [1] xMax,  [2] yMin

Arguments: feature class table object, geometry column name, origin - 2 character code or which extent origin to return

Usage: 
SELECT (FAIB_GET_BC_RASTER_ORIGIN('CLUS_CARIBOU_HERDS_25K', 'WKB_GEOMETRY', 'LL'))[1] - returns xMin
SELECT (FAIB_GET_BC_RASTER_ORIGIN('CLUS_CARIBOU_HERDS_25K', 'WKB_GEOMETRY', 'LL'))[2] - returns yMin
SELECT (FAIB_GET_BC_RASTER_ORIGIN('CLUS_CARIBOU_HERDS_25K', 'WKB_GEOMETRY'))    - returns both as an Array

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	coordset NUMERIC[];
	qry VARCHAR;
	xVal NUMERIC;
	yVal NUMERIC;
	last2 NUMERIC;
	xType VARCHAR;
	yType VARCHAR;
	cursExt REFCURSOR; 
	
BEGIN
	IF origin = 'UL' THEN
		qry := 'SELECT ST_XMIN(BOX) AS X, ST_YMAX(BOX) Y FROM(
				SELECT  ST_EXTENT(' || geom || ') as BOX FROM ' || fc || ') A;';
		xType = 'SHRINK';
		yType = 'GROW';
	ELSIF origin = 'LL' THEN
		qry := 'SELECT ST_XMIN(BOX) AS X, ST_YMIN(BOX) Y FROM(
				SELECT  ST_EXTENT(' || geom || ') as BOX FROM ' || fc || ') A;';
		xType = 'SHRINK';
		yType = 'SHRINK';
	ELSIF origin = 'UR' THEN
		qry := 'SELECT ST_XMAX(BOX) AS X, ST_YMAX(BOX) Y FROM(
				SELECT  ST_EXTENT(' || geom || ') as BOX FROM ' || fc || ') A;';
		xType = 'GROW';
		yType = 'GROW';
	ELSIF origin = 'LR' THEN
		qry := 'SELECT ST_XMAX(BOX) AS X, ST_YMIN(BOX) Y FROM(
				SELECT  ST_EXTENT(' || geom || ') as BOX FROM ' || fc || ') A;';
		xType = 'GROW';
		yType = 'SHRINK';
	END IF;
	--RAISE NOTICE '%', qry;
	OPEN cursExt FOR EXECUTE qry;
	FETCH cursExt INTO xVal, yVal;
	CLOSE cursExt;
	xVal := FAIB_GET_BC_RASTER_COORDVAL(xVal, xType);
	yVal := FAIB_GET_BC_RASTER_COORDVAL(yVal, yType);
	coordset[1] := xVal;
	coordset[2] := yVal;
	RETURN coordset;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FAIB_GET_BC_RASTER_COORDVAL(coord NUMERIC, type VARCHAR DEFAULT 'SHRINK') RETURNS NUMERIC
/*------------------------------------------------------------------------------------------------------------------
This function is a dependency for GET_BC_RASTER_ORIGIN function.

A function to return the BC Raster Standard for a coordinate.  Takes a numeric coordinate value and returns the corresponding 
BC Raster Standard to use for that coordinate.  

Arguments: 	coordinate NUMERIC
		type VARCHAR - DEFAULT 'SHRINK' .  Valid values GROW or SHRINK.  Whether to expand or shrink the value. Depends on what origin you are going for as to whether you need to grow, expand to accommodate. 

Usage: 
SELECT GET_BC_RASTER_COORDVAL(445579.052200001) - returns 445487.500000000
SELECT GET_BC_RASTER_COORDVAL(445587.449, 'GROW')       - returns 445487.500
SELECT GET_BC_RASTER_COORDVAL(445625.223, 'SHRINK')       - returns 445587.500

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	last2 NUMERIC;
	retCoord NUMERIC;
	coordTrunc NUMERIC;
	coordDec NUMERIC;
BEGIN	
	coordTrunc := trunc(coord);
	coordDec := coord - coordTrunc;
	last2 := CAST(RIGHT(CAST(coordTrunc AS VARCHAR), 2) AS NUMERIC);
	--RAISE NOTICE '%', last2;
	--RAISE NOTICE '%', coordDec;
	IF type = 'SHRINK' THEN
		--RAISE NOTICE 'SHRINK Coordinate';
		IF last2 + coordDec >= 87.5 THEN
			--RAISE NOTICE 'Bigger than 87.5';
			retCoord := coord - ((last2 + coordDec)  - 87.5);
		ELSE
			--RAISE NOTICE 'Less than 87.5';
			retCoord := coord - (last2 + coordDec + 12.5);
		END IF;
	ELSIF type = 'GROW' THEN
		--RAISE NOTICE 'GROW Coordinate';
		IF last2 + coordDec <= 87.5 THEN
			--RAISE NOTICE 'Less than 87.5';
			retCoord := coord + (87.5 - (last2 + coordDec));
		ELSE
			--RAISE NOTICE 'Less than 87.5';
			retCoord := coord + (100 - (last2 + coordDec) + 87.5);
		END IF;
	END IF;
	RETURN retCoord;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FAIB_GET_MASK_RASTER_FROM_VECTORLINKRASTER(outRaster VARCHAR, drawPoly VARCHAR, refRaster VARCHAR, srcVect VARCHAR, srcKey VARCHAR, whereClause VARCHAR DEFAULT '*', rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT True) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
This is a function that will generate a mask raster.  Value of 1 for area of interest query, noddata elsewhere.  
The goal of this function is to support the CLUS application where the user draws a polygon.  That polygon list of coordinates can be supplied to this function along with a where clause to generate
a mask rasters for the area within the drawn polygon that matches the where clause expression.

Arguments:
refRaster VARCHAR - The reference raster
outRaster VARCHAR - The name of the output mask raster
drawPoly VARCHAR - Polygon area of interest as a list of coordinates formatted like:
			'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))'
srcVect VARCHAR - The source vector data that generated the reference raster
srcKey VARCHAR - The key value of the source vector and reference raster
whereClause VARCHAR DEFAULT '*' - The where clause of what data in the source vector you want in the mask raster within the drawn polygon.  * Represents selecting everything. 
rastSize NUMERIC DEFAULT 100.00 - The raster size. Default 100m (1ha per pixel)
rastPixType VARCHAR DEFAULT '32BF' - The raster pixel type.  Defaults to 32 Bit, Float
noData NUMERIC DEFAULT 0  - The raster noData value.  Default is 0
tile BOOLEAN DEFAULT True - Boolean flag as to whether to tile the output raster.  Default is True

Example Call:

SELECT FAIB_GET_MASK_RASTER_FROM_VECTORLINKRASTER(
	'BEC_ZONE_CLIP_RASTER', 
	'CLUS_APPRUNTIME_GMR_BECZONE', 
	'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))', 
	'BEC_ZONE_CLIP', 
	'BEC_KEY', 
	'ZONE = ''ESSF'' AND UPPER(SUBZONE) = ''WC'' ' (Must have the space to ensure the embedded quotes are retained.) 
	)

Use FAIB_FC_TO_RASTER to generate the refRaster. 

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
	srcGeom VARCHAR;
	tmpVector VARCHAR DEFAULT 'ZZ_GMR_TEMPVECTOR';

BEGIN
	refRaster = TRIM(BOTH '''' FROM refRaster);
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcVect = TRIM(BOTH '''' FROM srcVect);
	srcKey = TRIM(BOTH '''' FROM srcKey);
	whereClause = TRIM(BOTH '''' FROM whereClause);
	srcGeom = FAIB_GET_GEOMETRY_COLUMN(UPPER(srcVect));
	
	
	--Delete any existing temporary vector dataset
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Build the query to execute to create the temporary vector representing area to mask
	qry = 
	'CREATE TABLE ' || tmpVector || ' AS 
	SELECT 1 as VAL, ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, B. ' || srcGeom || '), 3005) AS WKB_GEOMETRY FROM
	(SELECT ST_TRANSFORM(ST_GEOMFROMTEXT(''' || drawPoly || ''', 4326), 3005) GEOM) DRAWN,
	(
	SELECT ROW_NUMBER() OVER () AS RID,  R.KEY_VALUE, R.TOTAL_HA, S.*
	FROM
	(
	SELECT VALUE AS KEY_VALUE, SUM(COUNT) AS TOTAL_HA
	FROM (
	SELECT (PVC).* FROM 
	(
	SELECT RID, ST_VALUECOUNT(rast) PVC
	FROM ' || refRaster || '  
	WHERE ST_INTERSECTS
	(
	RAST, 
	ST_TRANSFORM(ST_GEOMFROMTEXT(''' || drawPoly || ''', 4326), 3005)
	)) A) FOO
	GROUP BY VALUE
	ORDER BY VALUE ASC) R LEFT JOIN ' || srcVect|| ' S ON R.KEY_VALUE = S.' || srcKey || ') B
	WHERE ST_INTERSECTS(DRAWN.GEOM, B.' || srcGeom || ')';
	
	IF NOT whereClause = '*' THEN
			qry = qry || ' AND ' || whereClause;
	END IF;
	qry = qry || ';';
	RAISE NOTICE '%', qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE 'SELECT FAIB_FC_TO_RASTER(''' || tmpVector ||''', ''VAL'', ''' || outRaster || ''');';
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_MASK_RASTER_FROM_VECTORLINKRASTER(outRaster VARCHAR, drawPoly GEOMETRY, refRaster VARCHAR, srcVect VARCHAR, srcKey VARCHAR, whereClause VARCHAR DEFAULT '*', rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT True) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
This is a function that will generate a mask raster.  Value of 1 for area of interest query, noddata elsewhere.  
The goal of this function is to support the CLUS application where the user draws a polygon.  That polygon list of coordinates can be supplied to this function along with a where clause to generate
a mask rasters for the area within the drawn polygon that matches the where clause expression.

Arguments:
refRaster VARCHAR - The reference raster
outRaster VARCHAR - The name of the output mask raster
drawPoly VARCHAR - Polygon area of interest as a list of coordinates formatted like:
			'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))'
srcVect VARCHAR - The source vector data that generated the reference raster
srcKey VARCHAR - The key value of the source vector and reference raster
whereClause VARCHAR DEFAULT '*' - The where clause of what data in the source vector you want in the mask raster within the drawn polygon.  * Represents selecting everything. 
rastSize NUMERIC DEFAULT 100.00 - The raster size. Default 100m (1ha per pixel)
rastPixType VARCHAR DEFAULT '32BF' - The raster pixel type.  Defaults to 32 Bit, Float
noData NUMERIC DEFAULT 0  - The raster noData value.  Default is 0
tile BOOLEAN DEFAULT True - Boolean flag as to whether to tile the output raster.  Default is True

Example Call:

SELECT FAIB_GET_MASK_RASTER_FROM_VECTORLINKRASTER(
	'RASTER_TSA_REVELSTOKE_MASKRASTER_FROMVECTORLINK', 
	(SELECT WKB_GEOMETRY FROM TSA_CLIP WHERE TSA_NUMBER = '27'), 
	'BEC_ZONE_CLIP_RASTER', 
	'BEC_ZONE_CLIP', 
	'BEC_KEY', 
	'ZONE IN (''ESSF'') '
	)

Use FAIB_FC_TO_RASTER to generate the refRaster. 

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
	srcGeom VARCHAR;
	tmpVector VARCHAR DEFAULT 'ZZ_GMR_TEMPVECTOR';

BEGIN
	refRaster = TRIM(BOTH '''' FROM refRaster);
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcVect = TRIM(BOTH '''' FROM srcVect);
	srcKey = TRIM(BOTH '''' FROM srcKey);
	whereClause = TRIM(BOTH '''' FROM whereClause);
	srcGeom = FAIB_GET_GEOMETRY_COLUMN(UPPER(srcVect));
	
	
	--Delete any existing temporary vector dataset
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Build the query to execute to create the temporary vector representing area to mask
	qry = 
	'CREATE TABLE ' || tmpVector || ' AS 
	SELECT 1 as VAL, ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, B. ' || srcGeom || '), 3005) AS WKB_GEOMETRY FROM
	(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN,
	(
	SELECT ROW_NUMBER() OVER () AS RID,  R.KEY_VALUE, R.TOTAL_HA, S.*
	FROM
	(
	SELECT VALUE AS KEY_VALUE, SUM(COUNT) AS TOTAL_HA
	FROM (
	SELECT (PVC).* FROM 
	(
	SELECT RID, ST_VALUECOUNT(rast) PVC
	FROM ' || refRaster || '  
	WHERE ST_INTERSECTS
	(
	RAST, 
	ST_TRANSFORM($1, 3005)
	)) A) FOO
	GROUP BY VALUE
	ORDER BY VALUE ASC) R LEFT JOIN ' || srcVect|| ' S ON R.KEY_VALUE = S.' || srcKey || ') B
	WHERE ST_INTERSECTS(DRAWN.GEOM, B.' || srcGeom || ')';
	
	IF NOT whereClause = '*' THEN
			qry = qry || ' AND ' || whereClause;
	END IF;
	qry = qry || ';';
	RAISE NOTICE '%', qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE qry USING drawPoly;
	--Execute the query to create the temporary vector feature class
	EXECUTE 'SELECT FAIB_FC_TO_RASTER(''' || tmpVector ||''', ''VAL'', ''' || outRaster || ''');';
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_MASK_RASTER_FROM_VECTOR(outRaster VARCHAR, drawPoly VARCHAR, srcVect VARCHAR, whereClause VARCHAR DEFAULT '*', rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT True) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
This is a function that will generate a mask raster.  Value of 1 for area of interest query, noddata elsewhere.  
The goal of this function is to support the CLUS application where the user draws a polygon.  That polygon list of coordinates can be supplied to this function along with a where clause to generate
a mask rasters for the area within the drawn polygon that matches the where clause expression.

Arguments:
outRaster VARCHAR - The name of the output mask raster
drawPoly VARCHAR - Polygon area of interest as a list of coordinates formatted like:
			'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))'
srcVect VARCHAR - The source vector data that generated the reference raster
whereClause VARCHAR DEFAULT NULL - The where clause of what data in the source vector you want in the mask raster within the drawn polygon
rastSize NUMERIC DEFAULT 100.00 - The raster size. Default 100m (1ha per pixel)
rastPixType VARCHAR DEFAULT '32BF' - The raster pixel type.  Defaults to 32 Bit, Float
noData NUMERIC DEFAULT 0  - The raster noData value.  Default is 0
tile BOOLEAN DEFAULT True - Boolean flag as to whether to tile the output raster.  Default is True

Example Call:

SELECT FAIB_GET_MASK_RASTER_FROM_VECTOR(
	'CLUS_APPRUNTIME_GMR_BECZONE', 
	'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))', 
	'BEC_ZONE', 
	'ZONE = ''ESSF'' '
	)

SELECT FAIB_GET_MASK_RASTER_FROM_VECTOR(
	'CLUS_APPRUNTIME_GMR_VRI', 
	'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))', 
	'VEG_COMP_LYR_L1_POLY', 
	'SPECIES_CD_1 IN (''H'', ''S'')  '
	)


Use FC_TO_RASTER to generate the refRaster. 

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
	srcGeom VARCHAR;
	tmpVector VARCHAR DEFAULT 'ZZ_GMR_TEMPVECTOR';

BEGIN
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcVect = TRIM(BOTH '''' FROM srcVect);
	srcGeom = TRIM(BOTH '''' FROM srcGeom);
	whereClause = TRIM(BOTH '''' FROM whereClause);
	srcGeom = FAIB_GET_GEOMETRY_COLUMN(UPPER(srcVect));
	
	--Delete any existing temporary vector dataset
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Build the query to execute to create the temporary vector representing area to mask
	qry = 
	'CREATE TABLE ' || tmpVector || ' AS 
	SELECT 1 as VAL, ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.' || srcGeom || '), 3005) AS WKB_GEOMETRY FROM
	' || srcVect || ' SRC, 
	(SELECT ST_TRANSFORM(ST_GEOMFROMTEXT(''' || drawPoly || ''', 4326), 3005) GEOM) DRAWN
	WHERE ST_INTERSECTS(DRAWN.GEOM, SRC.' || srcGeom || ')';
	
	IF NOT whereClause = '*' THEN
			qry = qry || ' AND ' || whereClause;
	END IF;
	qry = qry || ';';
	--RAISE NOTICE '%', qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE 'SELECT FAIB_FC_TO_RASTER(''' || tmpVector ||''', ''VAL'', ''' || outRaster || ''');';
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_MASK_RASTER_FROM_VECTOR(outRaster VARCHAR, drawPoly GEOMETRY, srcVect VARCHAR, whereClause VARCHAR DEFAULT '*', rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT True) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
This is a function that will generate a mask raster.  Value of 1 for area of interest query, noddata elsewhere.  
The goal of this function is to support the CLUS application where the user draws a polygon.  That polygon list of coordinates can be supplied to this function along with a where clause to generate
a mask rasters for the area within the drawn polygon that matches the where clause expression.

Arguments:
outRaster VARCHAR - The name of the output mask raster
drawPoly GEOMETRY - Polygon area of interest as a list of coordinates formatted like:
			'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))'
srcVect VARCHAR - The source vector data that generated the reference raster
whereClause VARCHAR DEFAULT NULL - The where clause of what data in the source vector you want in the mask raster within the drawn polygon
rastSize NUMERIC DEFAULT 100.00 - The raster size. Default 100m (1ha per pixel)
rastPixType VARCHAR DEFAULT '32BF' - The raster pixel type.  Defaults to 32 Bit, Float
noData NUMERIC DEFAULT 0  - The raster noData value.  Default is 0
tile BOOLEAN DEFAULT True - Boolean flag as to whether to tile the output raster.  Default is True

Example Call:

SELECT FAIB_GET_MASK_RASTER_FROM_VECTOR(
	'RASTER_TSA_REVELSTOKE_MASKRASTER_FROMVECTOR', 
	(SELECT WKB_GEOMETRY FROM TSA_CLIP WHERE TSA_NUMBER = '27'), 
	'BEC_ZONE_CLIP', 
	'ZONE IN (''ESSF'') '
	) 



Use FC_TO_RASTER to generate the refRaster. 

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
	srcGeom VARCHAR;
	tmpVector VARCHAR DEFAULT 'ZZ_GMR_TEMPVECTOR';

BEGIN
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcVect = TRIM(BOTH '''' FROM srcVect);
	srcGeom = TRIM(BOTH '''' FROM srcGeom);
	whereClause = TRIM(BOTH '''' FROM whereClause);
	srcGeom = FAIB_GET_GEOMETRY_COLUMN(UPPER(srcVect));
	
	--Delete any existing temporary vector dataset
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Build the query to execute to create the temporary vector representing area to mask
	qry = 
	'CREATE TABLE ' || tmpVector || ' AS 
	SELECT 1 as VAL, ST_SETSRID(ST_INTERSECTION($1, SRC.' || srcGeom || '), 3005) AS WKB_GEOMETRY FROM
	' || srcVect || ' SRC, 
	(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN
	WHERE ST_INTERSECTS($1, SRC.' || srcGeom || ')';
	
	IF NOT whereClause = '*' THEN
			qry = qry || ' AND ' || whereClause;
	END IF;
	qry = qry || ';';
	RAISE NOTICE '%', qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE qry USING drawPoly;
	--Execute the query to create the temporary vector feature class
	EXECUTE 'SELECT FAIB_FC_TO_RASTER(''' || tmpVector ||''', ''VAL'', ''' || outRaster || ''');';
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_MASK_RASTER_FROM_RASTER(outRaster VARCHAR, drawPoly VARCHAR, srcRast VARCHAR, rastVal VARCHAR DEFAULT '*', rastVAT VARCHAR DEFAULT NULL, rastVATFld VARCHAR DEFAULT NULL, rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT True) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
This is a function that will generate a mask raster.  Value of 1 for area of interest query, noddata elsewhere.  
The goal of this function is to support the CLUS application where the user draws a polygon.  That polygon list of coordinates can be supplied to this function along with a where clause to generate
a mask rasters for the area within the drawn polygon that matches the where clause expression.

Arguments:
outRaster VARCHAR - The name of the output mask raster
drawPoly VARCHAR - Polygon area of interest as a list of coordinates formatted like:
			'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))'
srcRast VARCHAR - The source raster data that we will query and use to generate the mask form within the drawn poly area
whereClause VARCHAR DEFAULT NULL - The where clause of what data in the source vector you want in the mask raster within the drawn polygon
rastSize NUMERIC DEFAULT 100.00 - The raster size. Default 100m (1ha per pixel)
rastPixType VARCHAR DEFAULT '32BF' - The raster pixel type.  Defaults to 32 Bit, Float
noData NUMERIC DEFAULT 0  - The raster noData value.  Default is 0
tile BOOLEAN DEFAULT True - Boolean flag as to whether to tile the output raster.  Default is True

Example Call:

SELECT FAIB_GET_MASK_RASTER_FROM_RASTER(
	'CLUS_APPRUNTIME_GMR_BECZONE', 
	'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))', 
	'BEC_ZONE', 
	'ZONE = ''ESSF'' '
	)

SELECT FAIB_GET_MASK_RASTER_FROM_RASTER(
	'CLUS_APPRUNTIME_GMR_VRI', 
	'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))', 
	'VEG_COMP_LYR_L1_POLY', 
	'SPECIES_CD_1 IN (''H'', ''S'')  '
	)

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
	srcRastCol VARCHAR;
	val VARCHAR;
	reClass VARCHAR = '';
	arr VARCHAR[];
	i NUMERIC;
BEGIN
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcRast = TRIM(BOTH '''' FROM srcRast);
	rastVal = TRIM(BOTH '''' FROM rastVal);
	srcRastCol = FAIB_GET_RASTER_COLUMN(UPPER(srcRast));

	--Drop the output raster if it exists
	EXECUTE 'DROP TABLE IF EXISTS ' || outRaster ||';';
	--Build the query to clip the raster by the draw poly
	
	qry = 'CREATE TABLE ' || outRaster || ' AS 
 	SELECT ROW_NUMBER() OVER () AS RID, ST_CLIP(ST_TRANSFORM(SRC.RAST, 3005), ST_TRANSFORM(DRAWN.GEOM, 3005)) AS RAST FROM
 	(SELECT ST_UNION(RAST) RAST FROM  ' || srcRast || ' WHERE 
 	ST_INTERSECTS(ST_TRANSFORM(
 	ST_GEOMFROMTEXT(''' || drawPoly || ''', 4326), 3005), RAST)) SRC, 
	(SELECT ST_TRANSFORM(ST_GEOMFROMTEXT(''' || drawPoly || ''' , 4326), 3005) GEOM) DRAWN;';

	--RAISE NOTICE '%', qry;
	EXECUTE qry;
	IF rastVal <> '*' THEN 
		IF (position(',' IN rastVal) > 0) AND rastVAT IS NULL THEN
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
			qry = 'CREATE TABLE ZZ_TMP_LOOKUP AS SELECT unnest(REGEXP_SPLIT_TO_ARRAY(''' || rastVal || ''', '','')) val;';
			--RAISE NOTICE '%', qry;
			EXECUTE qry;
			qry = 'UPDATE ' || outRaster ||  ' SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', 1), '','') FROM zz_tmp_lookup), ''4BUI'', 0)::reclassarg);';
			--RAISE NOTICE '%', qry;
			EXECUTE qry;
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
		ELSIF  NOT (rastVAT IS NULL OR UPPER(rastVAT) = 'NONE') THEN  
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
			qry = 'CREATE TABLE ZZ_TMP_LOOKUP AS SELECT ' || rastVATFld || ' val FROM ' || rastVAT || ' WHERE ' || rastVal || ' ;';
			EXECUTE qry;
			qry = 'UPDATE ' || outRaster ||  ' SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', 1), '','') FROM zz_tmp_lookup), ''4BUI'', 0)::reclassarg);';
			--RAISE NOTICE '%', qry;
			EXECUTE qry;
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
		ELSE
			--Build a query to reclass the raster to 1 where defined by rastVal, else NoData as 0
			qry = 'UPDATE '  || outRaster || ' SET RAST = ST_RECLASS(rast, 1, ''' || rastVal || ':1'', ''4BUI'', 0);';
			EXECUTE qry;
		END IF;
	END IF;
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
	
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION FAIB_GET_MASK_RASTER_FROM_RASTER(outRaster VARCHAR, drawPoly GEOMETRY, srcRast VARCHAR, rastVal VARCHAR DEFAULT '*', rastVAT VARCHAR DEFAULT NULL, rastVATFld VARCHAR DEFAULT NULL, rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT True) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
This is a function that will generate a mask raster.  Value of 1 for area of interest query, noddata elsewhere.  
The goal of this function is to support the CLUS application where the user draws a polygon.  That polygon list of coordinates can be supplied to this function along with a where clause to generate
a mask rasters for the area within the drawn polygon that matches the where clause expression.

Arguments:
outRaster VARCHAR - The name of the output mask raster
drawPoly VARCHAR - Polygon area of interest as a list of coordinates formatted like:
			'POLYGON((-117.6649 51.50532, -117.5482 51.50190, -117.3916 51.48224, -117.2721 51.41120, -117.3106 51.22839, -117.5647 51.22667, -117.6910 51.27051, -117.6649 51.50532))'
srcRast VARCHAR - The source raster data that we will query and use to generate the mask form within the drawn poly area
whereClause VARCHAR DEFAULT NULL - The where clause of what data in the source vector you want in the mask raster within the drawn polygon
rastSize NUMERIC DEFAULT 100.00 - The raster size. Default 100m (1ha per pixel)
rastPixType VARCHAR DEFAULT '32BF' - The raster pixel type.  Defaults to 32 Bit, Float
noData NUMERIC DEFAULT 0  - The raster noData value.  Default is 0
tile BOOLEAN DEFAULT True - Boolean flag as to whether to tile the output raster.  Default is True

Example Call:
SELECT FAIB_GET_MASK_RASTER_FROM_RASTER(
	'RASTER_TSA_REVELSTOKE_MASKRASTER_FROMRASTER', 
	(SELECT WKB_GEOMETRY FROM TSA_CLIP WHERE TSA_NUMBER = '27'), 
	'BEC_ZONE_CLIP_RASTER', 
	'ZONE IN (''ESSF'') ', 
	'BEC_ZONE_VAT', 
	'BEC_KEY'
	)


Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
	srcRastCol VARCHAR;
	val VARCHAR;
	reClass VARCHAR = '';
	arr VARCHAR[];
	i NUMERIC;
BEGIN
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcRast = TRIM(BOTH '''' FROM srcRast);
	rastVal = TRIM(BOTH '''' FROM rastVal);
	srcRastCol = FAIB_GET_RASTER_COLUMN(UPPER(srcRast));

	--Drop the output raster if it exists
	EXECUTE 'DROP TABLE IF EXISTS ' || outRaster ||';';
	--Build the query to clip the raster by the draw poly
	
	qry = 'CREATE TABLE ' || outRaster || ' AS 
 	SELECT ROW_NUMBER() OVER () AS RID, ST_CLIP(ST_TRANSFORM(SRC.RAST, 3005), ST_TRANSFORM($1, 3005)) AS RAST FROM
 	(SELECT ST_UNION(RAST) RAST FROM  ' || srcRast || ' WHERE 
 	ST_INTERSECTS(ST_TRANSFORM($1, 3005), RAST)) SRC, 
	(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN;';

	--RAISE NOTICE '%', qry;
	EXECUTE qry USING drawPoly;
	IF rastVal <> '*' THEN 
		IF (position(',' IN rastVal) > 0) AND rastVAT IS NULL THEN
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
			qry = 'CREATE TABLE ZZ_TMP_LOOKUP AS SELECT unnest(REGEXP_SPLIT_TO_ARRAY(''' || rastVal || ''', '','')) val;';
			--RAISE NOTICE '%', qry;
			EXECUTE qry;
			qry = 'UPDATE ' || outRaster ||  ' SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', 1), '','') FROM zz_tmp_lookup), ''4BUI'', 0)::reclassarg);';
			--RAISE NOTICE '%', qry;
			EXECUTE qry;
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
		ELSIF  NOT (rastVAT IS NULL OR UPPER(rastVAT) = 'NONE') THEN  
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
			qry = 'CREATE TABLE ZZ_TMP_LOOKUP AS SELECT ' || rastVATFld || ' val FROM ' || rastVAT || ' WHERE ' || rastVal || ' ;';
			EXECUTE qry;
			qry = 'UPDATE ' || outRaster ||  ' SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', 1), '','') FROM zz_tmp_lookup), ''4BUI'', 0)::reclassarg);';
			--RAISE NOTICE '%', qry;
			EXECUTE qry;
			EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
		ELSE
			--Build a query to reclass the raster to 1 where defined by rastVal, else NoData as 0
			qry = 'UPDATE '  || outRaster || ' SET RAST = ST_RECLASS(rast, 1, ''' || rastVal || ':1'', ''4BUI'', 0);';
			EXECUTE qry;
		END IF;
	END IF;
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
	
END;
$$ LANGUAGE plpgsql;

/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_GEOMETRY_COLUMN(fcName VARCHAR) RETURNS VARCHAR
/*------------------------------------------------------------------------------------------------------------------
This function takes the name of a vector feature class object and will return the geometry column for it

Arguments:
fcName VARCHAR - The name of the vector feature class that you want to know the geometry column for

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	geomCol VARCHAR;
	qry VARCHAR;
	cursGeom REFCURSOR; 
BEGIN
	fcName = UPPER(fcName);
	qry = 'SELECT f_geometry_column from geometry_columns where UPPER(f_table_name) = ''' || fcName || ''';';
	OPEN cursGeom FOR EXECUTE qry;
	FETCH cursGeom INTO geomCol;
	CLOSE cursGeom;
	RETURN geomCol;
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_RASTER_COLUMN(raster VARCHAR) RETURNS VARCHAR
/*------------------------------------------------------------------------------------------------------------------
This function takes the name of a raster object and will return the raster column for it

Arguments:
raster VARCHAR - The name of the raster that you want to know the raster column for

Mike Fowler
Spatial Data Analyst
July 2018
------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	rastCol VARCHAR;
	qry VARCHAR;
	cursRast REFCURSOR; 
BEGIN
	raster = UPPER(raster);
	qry = 'SELECT r_raster_column from raster_columns where UPPER(r_table_name) = ''' || raster || ''';';
	--RAISE NOTICE '%', qry;
	OPEN cursRast FOR EXECUTE qry;
	FETCH cursRast INTO rastCol;
	CLOSE cursRast;
	RETURN rastCol;
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_RASTER_CLIP(outRast VARCHAR, srcRast VARCHAR, clipper GEOMETRY) RETURNS VARCHAR
/*------------------------------------------------------------------------------------------------------------------
This function takes the name of a raster object and will return the raster column for it

Arguments:
outRast VARCHAR - The name of the raster that you want to output after teh clip
srcRast VARCHAR - The name of the source raster to clip
clipper GEOMETRY - The geometry (or geometry product of a query) to CLIP the raster to

Usage:

SELECT FAIB_RASTER_CLIP('RASTER_TSA_REVELSTOKE', 'BEC_ZONE_RASTER', (SELECT WKB_GEOMETRY FROM TSA WHERE TSA_NUMBER = '27'))


Mike Fowler
Spatial Data Analyst
August 2018
------------------------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	qry VARCHAR;
BEGIN
	EXECUTE 'DROP TABLE IF EXISTS ' || outRast || ';';
	
	qry = 'CREATE TABLE ' || outRast || ' AS
		SELECT ROW_NUMBER() OVER () AS RID, ST_CLIP(ST_TRANSFORM(SRC.RAST, 3005), ST_TRANSFORM($1, 3005)) AS RAST FROM
		(SELECT ST_UNION(RAST) RAST FROM  ' || srcRast || ' WHERE 
		ST_INTERSECTS(ST_TRANSFORM($1, 3005), RAST)) SRC;';
	--RAISE NOTICE '%', qry;
	RAISE NOTICE '%', qry;
	EXECUTE qry USING clipper;
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRast || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRast || '_RAST ON ' || outRast || ' USING GIST (ST_CONVEXHULL(RAST));';
	RETURN outRast;
END;
$$ LANGUAGE plpgsql;
