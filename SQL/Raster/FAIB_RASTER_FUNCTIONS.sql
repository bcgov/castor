/*----------------------------------------------------------------------------------------------------------------------------------------------------------
FAIB RASTER FUNCTIONS

A suite of functions to support various Raster manipulation and processing needs.  
Outputs will align with the BC Raster Grid standard

Documentation can be found here:
\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Scripts\SQL\Raster\Documentation\FAIB_PostGIS_Raster_Function_Documentation.html


Mike Fowler
Spatial Data Analyst
October 26, 2018
----------------------------------------------------------------------------------------------------------------------------------------------------------*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FAIB_FC_TO_RASTER(
fc VARCHAR, 
valFld VARCHAR, --This will be tested, if Char then create a VAT, else generate the Raster using this field value (acts like vatFld)
outRaster VARCHAR, 
vat VARCHAR DEFAULT NULL,
rastSize NUMERIC DEFAULT 100.00, 
rastPixType VARCHAR DEFAULT '32BF', 
noData NUMERIC DEFAULT 0, 
tile BOOLEAN DEFAULT False
)
RETURNS VOID
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
	valFldType VARCHAR;
	outVAT VARCHAR;
	geom VARCHAR;
	cursExt REFCURSOR; 
BEGIN
	geom = FAIB_GET_GEOMETRY_COLUMN(UPPER(fc));

	valFldType := FAIB_GET_DATA_TYPE(fc, valFld);
	IF FAIB_DATATYPE_ISNUM(valFldType) THEN
		qry := 	'CREATE TABLE ' || outRaster ||' AS
			SELECT ROW_NUMBER() OVER () AS RID, ''' || fc || ''' AS SOURCE_FC,  ''' || valFld || ''' AS SOURCE_FIELD, ST_UNION(
			ST_TRANSFORM(ST_ASRASTER(' ||
			geom || ', ' || rastSize::DECIMAL(6,2) || ',' || rastSize::DECIMAL(6,2) ||', (FAIB_GET_BC_RASTER_ORIGIN(''' || fc || ''', ''' || geom ||''', ''UL''))[1], 
			(FAIB_GET_BC_RASTER_ORIGIN(''' || fc || ''', ''' || geom || ''', ''UL''))[2],''' || rastPixType || ''',' || valFld || ',' || noData
			|| '), 3005)) RAST
			FROM ' || fc || ';';
	ELSIF FAIB_DATATYPE_ISCHAR(valFldType) THEN
		IF vat IS NULL THEN
			vat := format('%1$s_VAT', outRaster);
			RAISE NOTICE 'Generating VAT: %', vat;
			EXECUTE FAIB_CREATE_VAT(fc, valFld, outTab:=vat);
		END IF;
		qry := 	format('CREATE TABLE %1$s AS
			SELECT ROW_NUMBER() OVER () AS RID, ''%2$s'' AS SOURCE_FC,  ''%3$s'' AS SOURCE_FIELD, ST_UNION(
			ST_TRANSFORM(ST_ASRASTER(%4$s, %6$s,%6$s, (FAIB_GET_BC_RASTER_ORIGIN(''%2$s'', ''%4$s'', ''UL''))[1], 
			(FAIB_GET_BC_RASTER_ORIGIN(''%2$s'', ''%4$s'', ''UL''))[2],''%7$s'',B.VAL,0), 3005)) RAST
			FROM %2$s A LEFT JOIN %5$s B ON A.%3$s = B.%3$s', outRaster, fc, valFld, geom, vat, rastSize::DECIMAL(6,2), rastPixType);
	ELSE
		RAISE EXCEPTION 'valFld Parameter is wrong type.  Must be Number (generate raster using value) or Character(generate VAT and use value). %', valFld;
	END IF; 
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
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_RASTER_FROM_VECTOR(
outRaster VARCHAR, 
drawPoly TEXT, 
srcVect VARCHAR, 
whereClause VARCHAR DEFAULT '*', 
vatFld VARCHAR DEFAULT NULL,
vat VARCHAR DEFAULT NULL,
mask BOOLEAN DEFAULT FALSE,
rastSize NUMERIC DEFAULT 100.00, 
rastPixType VARCHAR DEFAULT '32BF', 
noData NUMERIC DEFAULT 0, 
tile BOOLEAN DEFAULT False
) RETURNS VOID
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
	qry TEXT;
	srcGeom VARCHAR;
	tmpVector VARCHAR DEFAULT 'ZZ_FAIB_PG_TEMPVECTOR';
	vatFldType VARCHAR;
	outVAT VARCHAR;
	valFld VARCHAR;
BEGIN
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcVect = TRIM(BOTH '''' FROM srcVect);
	srcGeom = TRIM(BOTH '''' FROM srcGeom);
	whereClause = TRIM(BOTH '''' FROM whereClause);
	srcGeom = FAIB_GET_GEOMETRY_COLUMN(UPPER(srcVect));

	/*----------------------------------------------------------------------------------------------------------------
	The logic here is this.  This function produces a raster from a source vector feature class table limited to the area of drawPoly and output filter by the whereclause, no data where not in clause
	The output raster can be a mask (1, No Data) or values generated from a VAT (value attribute table) or from a numeric field in source in vatFld.  

	If VAT is not supplied and the vatFld is character then a VAT table will be created.  The name of that VAT will be the srcVect_VAT. 
	----------------------------------------------------------------------------------------------------------------*/
	IF NOT mask THEN 
	--We only care about VAT, vatFld if we are NOT masking.  Assigning values to output raster. 
		IF vat IS NULL THEN
			vatFldType := FAIB_GET_DATA_TYPE(srcVect, vatFld);
			IF FAIB_DATATYPE_ISNUM(vatFldType) THEN
				RAISE NOTICE 'We have a Numeric vatFld.  We will process the output with this field';
				RAISE NOTICE 'The vatFld Type is Numeric.  We will generate the output raster using those values, no VAT to create'; 
				--Build the Query for No Vat, Numeric Source Value
				qry := 	format('CREATE TABLE %1$s AS 
					SELECT SRC.%2$s AS VAL, 
					ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%3$s), 3005) AS WKB_GEOMETRY FROM
					%4$s SRC,
					(SELECT ST_TRANSFORM(ST_GEOMFROMTEXT(''%5$s'', 4326), 3005) GEOM) DRAWN
					WHERE ST_INTERSECTS(DRAWN.GEOM, SRC.%3$s)', tmpVector, vatFld, srcGeom, srcVect, drawPoly);
			ELSIF FAIB_DATATYPE_ISCHAR(vatFldType) THEN
			--VAT is null and the VAT Field is Character - Valid to Continue to process and build a VAT
				outVAT := format('%1$s_VAT', outRaster);
				RAISE NOTICE 'The vatFld Type is Character.  We will generate a VAT and generate output raster using VAT: %', outVAT;
				EXECUTE FAIB_CREATE_VAT(srcVect, vatFld, outVAT); 
				vat:=outVAT;
				--Build the Query for No Vat, Character Source Value - genereated VAT
				qry := format('CREATE TABLE %6$s AS 
				SELECT VAT.VAL,  
				ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%1$s), 3005) AS WKB_GEOMETRY FROM
				%2$s SRC LEFT JOIN %3$s VAT ON SRC.%4$s = VAT.%4$s, 
				(SELECT ST_TRANSFORM(ST_GEOMFROMTEXT(''%5$s'', 4326), 3005) GEOM) DRAWN
				WHERE ST_INTERSECTS(DRAWN.GEOM, SRC.%1$s)', srcGEom, srcVect, vat, vatFld, drawPoly, tmpVector);
			ELSE
				RAISE EXCEPTION 'vatFld is Incorrect Type.  Must be Numeric, Character, Text, Varchar. Field%-Type%', vatFld, vatFldType;
			END IF;
		ELSE
			RAISE NOTICE 'We have a VAT.  Apply the VAT to the output raster';
			qry := format('CREATE TABLE ZZ_FAIB_PG_TEMPVECTOR AS 
				SELECT VAT.VAL,  
				ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%1$s), 3005) AS WKB_GEOMETRY FROM
				%2$s SRC LEFT JOIN %3$s VAT ON SRC.%4$s = VAT.%4$s, 
				(SELECT ST_TRANSFORM(ST_GEOMFROMTEXT(''%5$s'', 4326), 3005) GEOM) DRAWN
				WHERE ST_INTERSECTS(ST_TRANSFORM(DRAWN.GEOM, 3005), SRC.%1$s)', srcGeom, srcVect, vat, vatFld, drawPoly); 
		END IF;
	ELSE
	--We are going to mask
		RAISE NOTICE 'We have a Mask';
		qry = format('CREATE TABLE %1$s AS 
			SELECT 1 as VAL, ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%2$s), 3005) AS WKB_GEOMETRY FROM %3$s SRC, 
			(SELECT ST_TRANSFORM(ST_GEOMFROMTEXT(''%4$s'', 4326), 3005) GEOM) DRAWN
			WHERE ST_INTERSECTS(DRAWN.GEOM, SRC.%2$s)', tmpVector, srcGeom, srcVect, drawPoly);
	END IF;
	--Delete any existing temporary vector dataset
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Build the query to execute to create the temporary vector representing area to mask
	
	IF NOT whereClause = '*' THEN
			IF strpos(UPPER(whereClause), UPPER(vatFld)) > 0 THEN
				qry = qry || ' AND (' || replace(UPPER(whereClause), UPPER(vatFld), 'SRC.' || vatFld) ||')';
			ELSE
				qry = qry || ' AND (' || whereClause || ')';
			END IF;
	END IF;
	qry = qry || ';';
	RAISE NOTICE '%', qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE qry;
	EXECUTE 'DROP INDEX IF EXISTS ' || tmpVector || '_IDX;';
	EXECUTE 'CREATE INDEX ' || tmpVector || '_IDX ON ' || tmpVector || ' USING GIST(WKB_GEOMETRY);';
	--Execute the query to create the temporary vector feature class
	--EXECUTE 'SELECT FAIB_FC_TO_RASTER(''' || tmpVector ||''', ''VAL'', ''' || outRaster || ''');';
	EXECUTE format('SELECT FAIB_FC_TO_RASTER(''%1$s'', ''VAL'', ''%2$s'', tile:=%3$s, noData:=%4$s, rastSize:=%5$s, rastPixType:=''%6$s'');', tmpVector, outRaster, UPPER(tile::text), noData, rastSize, rastPixType);
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
	
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_RASTER_FROM_VECTOR(
outRaster VARCHAR, 
drawPoly GEOMETRY, 
srcVect VARCHAR, 
whereClause VARCHAR DEFAULT '*', 
vatFld VARCHAR DEFAULT NULL,
vat VARCHAR DEFAULT NULL,
mask BOOLEAN DEFAULT FALSE,
rastSize NUMERIC DEFAULT 100.00, 
rastPixType VARCHAR DEFAULT '32BF', 
noData NUMERIC DEFAULT 0, 
tile BOOLEAN DEFAULT False
) RETURNS VOID
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
	qry TEXT;
	srcGeom VARCHAR;
	tmpVector VARCHAR DEFAULT 'ZZ_FAIB_PG_TEMPVECTOR';
	vatFldType VARCHAR;
	outVAT VARCHAR;
	valFld VARCHAR;
BEGIN
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcVect = TRIM(BOTH '''' FROM srcVect);
	srcGeom = TRIM(BOTH '''' FROM srcGeom);
	whereClause = TRIM(BOTH '''' FROM whereClause);
	srcGeom = FAIB_GET_GEOMETRY_COLUMN(UPPER(srcVect));

	/*----------------------------------------------------------------------------------------------------------------
	The logic here is this.  This function produces a raster from a source vector feature class table limited to the area of drawPoly and output filter by the whereclause, no data where not in clause
	The output raster can be a mask (1, No Data) or values generated from a VAT (value attribute table) or from a numeric field in source in vatFld.  

	If VAT is not supplied and the vatFld is character then a VAT table will be created.  The name of that VAT will be the srcVect_VAT. 
	----------------------------------------------------------------------------------------------------------------*/
	IF NOT mask THEN 
	--We only care about VAT, vatFld if we are NOT masking.  Assigning values to output raster. 
		IF vat IS NULL THEN
			vatFldType := FAIB_GET_DATA_TYPE(srcVect, vatFld);
			IF FAIB_DATATYPE_ISNUM(vatFldType) THEN
				RAISE NOTICE 'We have a Numeric vatFld.  We will process the output with this field';
				RAISE NOTICE 'The vatFld Type is Numeric.  We will generate the output raster using those values, no VAT to create'; 
				--Build the Query for No Vat, Numeric Source Value
				qry := 	format('CREATE TABLE %1$s AS 
					SELECT SRC.%2$s AS VAL, 
					ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%3$s), 3005) AS WKB_GEOMETRY FROM
					%4$s SRC,
					(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN
					WHERE ST_INTERSECTS(DRAWN.GEOM, SRC.%3$s)', tmpVector, vatFld, srcGeom, srcVect);
			ELSIF FAIB_DATATYPE_ISCHAR(vatFldType) THEN
			--VAT is null and the VAT Field is Character - Valid to Continue to process and build a VAT
				outVAT := format('%1$s_VAT', outRaster);
				RAISE NOTICE 'The vatFld Type is Character.  We will generate a VAT and generate output raster using VAT: %', outVAT;
				EXECUTE FAIB_CREATE_VAT(srcVect, vatFld, outVAT); 
				vat:=outVAT;
				--Build the Query for No Vat, Character Source Value - genereated VAT
				qry := format('CREATE TABLE %5$s AS 
				SELECT VAT.VAL,  
				ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%1$s), 3005) AS WKB_GEOMETRY FROM
				%2$s SRC LEFT JOIN %3$s VAT ON SRC.%4$s = VAT.%4$s, 
				(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN
				WHERE ST_INTERSECTS(DRAWN.GEOM, SRC.%1$s)', srcGeom, srcVect, vat, vatFld, tmpVector);
			ELSE
				RAISE EXCEPTION 'vatFld is Incorrect Type.  Must be Numeric, Character, Text, Varchar. Field%-Type%', vatFld, vatFldType;
			END IF;
		ELSE
			RAISE NOTICE 'We have a VAT.  Apply the VAT to the output raster';
			qry := format('CREATE TABLE ZZ_FAIB_PG_TEMPVECTOR AS 
				SELECT VAT.VAL,  
				ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%1$s), 3005) AS WKB_GEOMETRY FROM
				%2$s SRC LEFT JOIN %3$s VAT ON SRC.%4$s = VAT.%4$s, 
				(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN
				WHERE ST_INTERSECTS(ST_TRANSFORM(DRAWN.GEOM, 3005), SRC.%1$s)', srcGeom, srcVect, vat, vatFld); 
		END IF;
	ELSE
	--We are going to mask
		RAISE NOTICE 'We have a Mask';
		qry = format('CREATE TABLE %1$s AS 
			SELECT 1 as VAL, ST_SETSRID(ST_INTERSECTION(DRAWN.GEOM, SRC.%2$s), 3005) AS WKB_GEOMETRY FROM %3$s SRC, 
			(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN
			WHERE ST_INTERSECTS(DRAWN.GEOM, SRC.%2$s)', tmpVector, srcGeom, srcVect);
	END IF;
	--Delete any existing temporary vector dataset
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Build the query to execute to create the temporary vector representing area to mask
	
	IF NOT whereClause = '*' THEN
			IF strpos(UPPER(whereClause), UPPER(vatFld)) > 0 THEN
				qry = qry || ' AND (' || replace(UPPER(whereClause), UPPER(vatFld), 'SRC.' || vatFld) ||')';
			ELSE
				qry = qry || ' AND (' || whereClause || ')';
			END IF;
	END IF;
	qry = qry || ';';
	RAISE NOTICE '%', qry;
	--Execute the query to create the temporary vector feature class
	EXECUTE qry USING drawPoly;
	EXECUTE 'DROP INDEX IF EXISTS ' || tmpVector || '_IDX;';
	EXECUTE 'CREATE INDEX ' || tmpVector || '_IDX ON ' || tmpVector || ' USING GIST(WKB_GEOMETRY);';
	--Execute the query to create the temporary vector feature class
	--EXECUTE 'SELECT FAIB_FC_TO_RASTER(''' || tmpVector ||''', ''VAL'', ''' || outRaster || ''');';
	EXECUTE format('SELECT FAIB_FC_TO_RASTER(''%1$s'', ''VAL'', ''%2$s'', tile:=%3$s, noData:=%4$s, rastSize:=%5$s, rastPixType:=''%6$s'');', tmpVector, outRaster, UPPER(tile::text), noData, rastSize, rastPixType);
	EXECUTE 'DROP TABLE IF EXISTS ' || tmpVector || ';';
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
	
END;
$$ LANGUAGE plpgsql;
/*------------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_RASTER_FROM_RASTER(
outRaster VARCHAR, 
drawPoly TEXT, 
srcRast VARCHAR, 
rastVal VARCHAR DEFAULT '*', 
rastVAT VARCHAR DEFAULT NULL, 
mask BOOLEAN DEFAULT FALSE,
rastSize NUMERIC DEFAULT 100.00, 
rastPixType VARCHAR DEFAULT '32BF', 
noData NUMERIC DEFAULT 0, 
tile BOOLEAN DEFAULT False
) RETURNS VOID
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
	qry TEXT;
	srcRastCol VARCHAR;
	opposite_vals TEXT;
	query_vals TEXT;
	outVal INTEGER;
	reClass VARCHAR = '';
	arr VARCHAR[];
	i NUMERIC;
	bSingleVal BOOLEAN := FALSE;
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

	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP2;';
	IF rastVal <> '*' THEN 
		rastVal := FAIB_FORMAT_RASTVALS(rastVal);
		IF (position(',' IN rastVal) > 0) AND rastVAT IS NULL THEN
			IF NOT MASK THEN --Not masking, retainting values
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, (pvc).VALUE out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			ELSE  --Masking
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, 1 out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			END IF;
			EXECUTE qry; --Execute the query to create the lookup table to process output raster
			--Set values in lookup table where not in query values to noData, 0
			opposite_vals = FAIB_GET_RASTVALS_OPPOSITE(outRaster, rastVal);
			IF NOT opposite_vals IS NULL THEN
				qry := format('UPDATE ZZ_TMP_LOOKUP SET out_val = %1$s WHERE val IN (%2$s)', noData, opposite_vals);
				EXECUTE qry;  --Update the lookup table
			END IF;
		ELSIF  NOT (rastVAT IS NULL OR UPPER(rastVAT) = 'NONE') THEN  
			--We have a VAT table to use. 
			--Create lookup table.  If Mask out_val = 1, else original value
			IF NOT mask THEN --We are not masking. 
				--Create starting lookup tables that has existing values in the outRaster.  Populate val, out_val the same for now
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, (pvc).VALUE out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			ELSE --We are masking
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, 1 out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			END IF;
			EXECUTE qry;
			--Now we use the query where clause (rastVal) agains the Vat to determine what we want to retain.  Then we build a list of the opposites to set to 
			--NoData value in the lookup table to drive the Reclass. .
			qry := 'CREATE TABLE ZZ_TMP_LOOKUP2 AS SELECT val FROM ' || rastVAT || ' WHERE ' || rastVal || ' ;';
			EXECUTE qry;
			SELECT string_agg(val::text, ',') INTO query_vals FROM ZZ_TMP_LOOKUP2;
			opposite_vals := FAIB_GET_RASTVALS_OPPOSITE(outRaster, query_vals);
			IF NOT opposite_vals IS NULL THEN
				qry := format('UPDATE ZZ_TMP_LOOKUP SET out_val = %1$s WHERE val IN (%2$s)', noData, opposite_vals);
				EXECUTE qry;
			END IF;
		ELSE
			--We have a single value in the rastVal (no commas after sending through FORMATVALS function)
			--Build a query to reclass the raster to 1 where defined by rastVal, else NoData as 0
			bSingleVal := TRUE;
			IF MASK THEN
				qry = format('UPDATE %1$s SET RAST = ST_RECLASS(rast, 1, ''%2$s:%3$s'', ''32BUI'', %4$s);', outRaster, rastVal, 1, noData);
				EXECUTE qry;
			ELSE
				qry = format('UPDATE %1$s SET RAST = ST_RECLASS(rast, 1, ''%2$s:%2$s'', ''32BUI'', %3$s);', outRaster, rastVal, noData);
				EXECUTE qry;
			END IF;
		END IF;
	ELSE
	--We are dealing with a rastVal * scenario.  Retain all pixels in the output. 
		IF mask THEN
			qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, 1 out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			EXECUTE qry;
			qry = format('UPDATE %1$s SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', out_val), '','')  FROM zz_tmp_lookup), ''32BUI'', %2$s)::reclassarg);', outRaster, noData);
			EXECUTE qry;	
		END IF;
	END IF;
	IF (NOT bSingleVal) AND (rastVal <> '*') THEN
		---Output reclass lookup table is built.  Now we can reclass the output raster based on the values in that table.
		qry = format('UPDATE %1$s SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', out_val), '','')  FROM zz_tmp_lookup), ''32BUI'', %2$s)::reclassarg);', outRaster, noData);
		EXECUTE qry;	
	END IF;

	--Drop the Temporary Lookup tables
	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP2;';
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRaster || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRaster || '_RAST ON ' || outRaster || ' USING GIST (ST_CONVEXHULL(RAST));';
END;
$$ LANGUAGE plpgsql;
/*-------------------------------------------------------------------------------------*//*-------------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------------*//*-------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_RASTER_FROM_RASTER(
outRaster VARCHAR, 
drawPoly GEOMETRY, 
srcRast VARCHAR, 
rastVal VARCHAR DEFAULT '*', 
rastVAT VARCHAR DEFAULT NULL, 
mask BOOLEAN DEFAULT FALSE,
rastSize NUMERIC DEFAULT 100.00, 
rastPixType VARCHAR DEFAULT '32BF', 
noData NUMERIC DEFAULT 0, 
tile BOOLEAN DEFAULT False
) RETURNS VOID
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
	qry TEXT;
	srcRastCol VARCHAR;
	opposite_vals TEXT;
	query_vals TEXT;
	outVal INTEGER;
	reClass VARCHAR = '';
	arr VARCHAR[];
	i NUMERIC;
	bSingleVal BOOLEAN := FALSE;
BEGIN
	outRaster = TRIM(BOTH '''' FROM outRaster);
	srcRast = TRIM(BOTH '''' FROM srcRast);
	rastVal = TRIM(BOTH '''' FROM rastVal);
	srcRastCol = FAIB_GET_RASTER_COLUMN(UPPER(srcRast));

	--Drop the output raster if it exists
	EXECUTE 'DROP TABLE IF EXISTS ' || outRaster ||';';
	--Build the query to clip the raster by the draw poly

	
	qry = 'CREATE TABLE ' || outRaster || ' AS 
 	SELECT ROW_NUMBER() OVER () AS RID, ST_CLIP(ST_TRANSFORM(SRC.RAST, 3005), ST_TRANSFORM(DRAWN.GEOM, 3005)) AS RAST 
 	FROM
 	(SELECT ST_UNION(RAST) RAST FROM  ' || srcRast || ' WHERE 
 	ST_INTERSECTS(ST_TRANSFORM($1, 3005), RAST)) SRC, 
	(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN;';
		/*
	qry = 'CREATE TABLE ' || outRaster || ' AS 
 	SELECT ROW_NUMBER() OVER () AS RID, ST_CLIP(ST_TRANSFORM(SRC.RAST, 3005), ST_TRANSFORM(DRAWN.GEOM, 3005)) AS RAST FROM
 	(SELECT ST_UNION(RAST) RAST FROM  ' || srcRast || ' WHERE 
 	ST_INTERSECTS(ST_TRANSFORM(DRAWN.GEOM, 3005), RAST)) SRC, 
	(SELECT ST_TRANSFORM($1, 3005) GEOM) DRAWN;';
	*/
	RAISE NOTICE '%', drawPoly;
	RAISE NOTICE '%', qry;
	EXECUTE qry USING drawPoly;

	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP2;';
	IF rastVal <> '*' THEN 
		rastVal := FAIB_FORMAT_RASTVALS(rastVal);
		IF (position(',' IN rastVal) > 0) AND rastVAT IS NULL THEN
			IF NOT MASK THEN --Not masking, retainting values
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, (pvc).VALUE out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			ELSE  --Masking
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, 1 out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			END IF;
			EXECUTE qry; --Execute the query to create the lookup table to process output raster
			--Set values in lookup table where not in query values to noData, 0
			opposite_vals = FAIB_GET_RASTVALS_OPPOSITE(outRaster, rastVal);
			IF NOT opposite_vals IS NULL THEN
				qry := format('UPDATE ZZ_TMP_LOOKUP SET out_val = %1$s WHERE val IN (%2$s)', noData, opposite_vals);
				EXECUTE qry;  --Update the lookup table
			END IF;
		ELSIF  NOT (rastVAT IS NULL OR UPPER(rastVAT) = 'NONE') THEN  
			--We have a VAT table to use. 
			--Create lookup table.  If Mask out_val = 1, else original value
			IF NOT mask THEN --We are not masking. 
				--Create starting lookup tables that has existing values in the outRaster.  Populate val, out_val the same for now
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, (pvc).VALUE out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			ELSE --We are masking
				qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, 1 out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			END IF;
			EXECUTE qry;
			--Now we use the query where clause (rastVal) agains the Vat to determine what we want to retain.  Then we build a list of the opposites to set to 
			--NoData value in the lookup table to drive the Reclass. .
			qry := 'CREATE TABLE ZZ_TMP_LOOKUP2 AS SELECT val FROM ' || rastVAT || ' WHERE ' || rastVal || ' ;';
			EXECUTE qry;
			SELECT string_agg(val::text, ',') INTO query_vals FROM ZZ_TMP_LOOKUP2;
			opposite_vals := FAIB_GET_RASTVALS_OPPOSITE(outRaster, query_vals);
			IF NOT opposite_vals IS NULL THEN
				qry := format('UPDATE ZZ_TMP_LOOKUP SET out_val = %1$s WHERE val IN (%2$s)', noData, opposite_vals);
				EXECUTE qry;
			END IF;
		ELSE
			--We have a single value in the rastVal (no commas after sending through FORMATVALS function)
			--Build a query to reclass the raster to 1 where defined by rastVal, else NoData as 0
			bSingleVal := TRUE;
			IF MASK THEN
				qry = format('UPDATE %1$s SET RAST = ST_RECLASS(rast, 1, ''%2$s:%3$s'', ''32BUI'', %4$s);', outRaster, rastVal, 1, noData);
				EXECUTE qry;
			ELSE
				qry = format('UPDATE %1$s SET RAST = ST_RECLASS(rast, 1, ''%2$s:%2$s'', ''32BUI'', %3$s);', outRaster, rastVal, noData);
				EXECUTE qry;
			END IF;
		END IF;
	ELSE
	--We are dealing with a rastVal * scenario.  Retain all pixels in the output. 
		IF mask THEN
			qry := format('CREATE TABLE ZZ_TMP_LOOKUP AS SELECT (pvc).VALUE val, 1 out_val from (SELECT ST_ValueCount(rast) As pvc FROM %1$s) pvc;', outRaster);
			EXECUTE qry;
			qry = format('UPDATE %1$s SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', out_val), '','')  FROM zz_tmp_lookup), ''32BUI'', %2$s)::reclassarg);', outRaster, noData);
			EXECUTE qry;	
		END IF;
	END IF;
	IF (NOT bSingleVal) AND (rastVal <> '*') THEN
		---Output reclass lookup table is built.  Now we can reclass the output raster based on the values in that table.
		qry = format('UPDATE %1$s SET rast = ST_Reclass(rast, ROW(1, (SELECT string_agg(concat(''['',val,''-'',val,'']:'', out_val), '','')  FROM zz_tmp_lookup), ''32BUI'', %2$s)::reclassarg);', outRaster, noData);
		EXECUTE qry;	
	END IF;

	--Drop the Temporary Lookup tables
	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP;';
	EXECUTE 'DROP TABLE IF EXISTS ZZ_TMP_LOOKUP2;';
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
CREATE OR REPLACE FUNCTION FAIB_RASTER_CLIP(outRast VARCHAR, srcRast VARCHAR, clipper TEXT) RETURNS VARCHAR
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
	qry TEXT;
BEGIN
	EXECUTE 'DROP TABLE IF EXISTS ' || outRast || ';';
	
	qry = 'CREATE TABLE ' || outRast || ' AS
		SELECT ROW_NUMBER() OVER () AS RID, ST_CLIP(ST_TRANSFORM(SRC.RAST, 3005), ST_TRANSFORM(ST_GEOMFROMTEXT(''' || clipper || ''' , 4326), 3005)) AS RAST FROM
		(SELECT ST_UNION(RAST) RAST FROM  ' || srcRast || ' WHERE 
		ST_INTERSECTS(ST_TRANSFORM(ST_GEOMFROMTEXT(''' || clipper || ''' , 4326), 3005), RAST)) SRC;';
	--RAISE NOTICE '%', qry;
	--RAISE NOTICE '%', clipper;
	--RAISE NOTICE '%', qry;
	--EXECUTE qry USING clipper;
	EXECUTE qry;
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRast || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRast || '_RAST ON ' || outRast || ' USING GIST (ST_CONVEXHULL(RAST));';
	RETURN outRast;
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
/*---------------------------------------------------------------------------------------*//*---------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_R_RASTERINFO(srcRast VARCHAR) RETURNS DOUBLE PRECISION[]
/*------------------------------------------------------------------------------------------------------------------
Mike Fowler
Spatial Data Analyst
August 2018
------------------------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
	rc REFCURSOR;
	qry VARCHAR;
	info DOUBLE PRECISION[];
	vals DOUBLE PRECISION[];
	xmn DOUBLE PRECISION;
	xmx DOUBLE PRECISION;
	ymn  DOUBLE PRECISION;
	ymx  DOUBLE PRECISION;
	ncols INTEGER;
	nrows INTEGER;
	rastCol VARCHAR;
BEGIN
	rastCol = FAIB_GET_RASTER_COLUMN(UPPER(srcRast));
	--Build a query to extract out extents, cols, rows of raster
	qry = 	format('SELECT
		st_xmax(st_envelope(rast)) as xmx,
		st_xmin(st_envelope(rast)) as xmn,
		st_ymax(st_envelope(rast)) as ymx,
		st_ymin(st_envelope(rast)) as ymn,
		st_width(rast) as cols,
		st_height(rast) as rows
		FROM
	(SELECT ST_UNION(%s, 1) RAST FROM %s) A', rastCol, srcRast);
	--RAISE NOTICE '%', qry;
	EXECUTE qry INTO xmx, xmn, ymx, ymn, ncols, nrows; 
	info := ARRAY[xmx, xmn, ymx, ymn, ncols, nrows];
	--Build a query to extract out the raster values of raster
	qry = format('SELECT array_agg(FAIB_R_RASTERVALS) vals FROM FAIB_R_RASTERVALS(''%s'')', srcRast);
	--qry = format('SELECT FAIB_R_RASTERVALS vals FROM FAIB_R_RASTERVALS(''%s'')', srcRast);
	OPEN rc FOR EXECUTE qry;
	FETCH rc INTO vals;
	CLOSE rc;
	--Append the arrays together for a single return
	info := array_cat(info, vals);
	RETURN info;
END;
$$ LANGUAGE plpgsql;
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_CREATE_VAT(srcTab VARCHAR, vatFld VARCHAR, outTab VARCHAR) RETURNS VOID
/*------------------------------------------------------------------------------------------------------------------
Mike Fowler
Spatial Data Analyst
August 2018
------------------------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------------------*/
AS $$
DECLARE
  qry character varying;
BEGIN
	EXECUTE format('DROP TABLE IF EXISTS %1$s', outTab);
	qry := format(	'CREATE TABLE %1$s AS 
			SELECT ROW_NUMBER() OVER () AS VAL, ''%3$s''::VARCHAR AS SOURCE_TABLE,  %2$s 
			FROM %3$s
			GROUP BY %2$s 
			ORDER BY %2$s ASC', outTab, vatFld, srcTab);	
	RAISE NOTICE '%', qry;
	EXECUTE qry;
	--RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_DATA_TYPE(tab regclass, col text)
  RETURNS text AS
$body$
DECLARE
    _schema text;
    _table text;
    data_type text;
BEGIN
-- Prepare names to use in index and trigger names
IF tab::text LIKE '%.%' THEN
    _schema := regexp_replace (split_part(tab::text, '.', 1),'"','','g');
    _table := regexp_replace (split_part(tab::text, '.', 2),'"','','g');
    ELSE
        _schema := 'public';
        _table := regexp_replace(tab::text,'"','','g');
    END IF;

    data_type := 
    (
        SELECT format_type(a.atttypid, a.atttypmod)
        FROM pg_attribute a 
        JOIN pg_class b ON (a.attrelid = b.oid)
        JOIN pg_namespace c ON (c.oid = b.relnamespace)
        WHERE
            UPPER(b.relname) = UPPER(_table) AND
            UPPER(c.nspname) = UPPER(_schema) AND
            UPPER(a.attname) = UPPER(col)
     );

    RETURN data_type;
END
$body$ LANGUAGE plpgsql;
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_DATATYPE_ISNUM(type text)
  RETURNS BOOLEAN AS
$body$
DECLARE
  bNum BOOLEAN := FALSE;
BEGIN
	CASE UPPER(type)
	WHEN 'SMALLINT', 'INTEGER', 'BIGINT', 'DECIMAL', 'NUMERIC', 'REAL', 'DOUBLE PRECISION', 'SMALLSERIAL', 'SERIAL', 'BIGSERIAL' THEN
		bNum = TRUE;
	ELSE
		bNum = FALSE;

	END CASE;
	RETURN bNum;
END
$body$ LANGUAGE plpgsql;
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_DATATYPE_ISCHAR(type text)
  RETURNS BOOLEAN AS
$body$
DECLARE
  bChar BOOLEAN := FALSE;
BEGIN
	IF position('(' in type) > 0 THEN
		type := substring(type from 0 for position('(' in type));
		--RAISE NOTICE '%', type;
	END IF;
	CASE UPPER(type)
	WHEN 'CHARACTER VARYING', 'CHARACTER', 'VARCHAR', 'TEXT' THEN
		bChar = TRUE;
	ELSE
		bChar = FALSE;

	END CASE;
	RETURN bChar;
END
$body$ LANGUAGE plpgsql;
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_FORMAT_RASTVALS(valText text)
  RETURNS VARCHAR AS
$body$
DECLARE
  rastVals VARCHAR;
  rastValsArr VARCHAR[];
  rangeStart NUMERIC;
  rangeEnd NUMERIC;
  val VARCHAR;
  i INTEGER;
BEGIN
	FOREACH val IN ARRAY regexp_split_to_array(valText, ',') LOOP
		--RAISE NOTICE '%', trim(both from val);
		val := trim(both from val);
		IF strpos(val, '-') > 0 THEN
			--We have a range of values component
			rangeStart := substr(val, 0, strpos(val, '-'))::NUMERIC;
			rangeEnd   := substr(val, strpos(val, '-') +1, (length(val) - strpos(val, '-')))::NUMERIC;
			IF rangeStart > rangeEnd THEN
				RAISE EXCEPTION 'Range Value % contains invalid Entry.  Start > End.', val;
			END IF; 
			FOR i IN rangeStart..rangeEnd LOOP
				rastValsArr := array_append(rastValsArr, i::VARCHAR);
			END LOOP;
		ELSE
			rastValsArr := array_append(rastValsArr, val);
		END IF;
	END LOOP;
	rastVals = array_to_string(rastValsArr, ',');
	RETURN rastVals;
END
$body$ LANGUAGE plpgsql;
/*----------------------------------------------------------------------------------------------------------------*//*----------------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION FAIB_GET_RASTVALS_OPPOSITE(srcRast VARCHAR, rastVals text)
  RETURNS VARCHAR AS
$body$
DECLARE
  qry VARCHAR;
  rastCol VARCHAR;
  rastValsOpposite VARCHAR;
  val VARCHAR;
  i INTEGER;
BEGIN
	RAISE NOTICE '%', rastVals;
	rastCol := FAIB_GET_RASTER_COLUMN(srcRast);
	
	qry := format('SELECT string_agg(value::text, '','') val
		FROM 
		( SELECT (pvc).* FROM 
		(SELECT ST_ValueCount(%1$s) As pvc
		FROM %2$s) As foo
		) a
		WHERE value NOT IN (%3$s);', rastCol, srcRast, rastVals);
	--RAISE NOTICE '%', qry;	
	EXECUTE qry INTO rastValsOpposite;
	RETURN rastValsOpposite;
END
$body$ LANGUAGE plpgsql;

