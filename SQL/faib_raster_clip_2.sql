CREATE OR REPLACE FUNCTION public.faib_raster_clip2(
    outrast character varying,
    srcrast character varying,
    clippoly character varying,
    geom character varying,
    where_clause character varying
    )
  RETURNS character varying AS
$BODY$
DECLARE qry TEXT;
BEGIN
	EXECUTE 'DROP TABLE IF EXISTS ' || outRast || ';';
	
	qry = 'CREATE TABLE ' || outRast || ' AS
		(SELECT st_union(ST_Clip(foo.rast, 1, foo.'|| geom ||',-9999, true)) as rast FROM 
		(SELECT st_union(rast) as rast,' || geom ||' from ' || srcrast||', ' || clippoly|| '
		WHERE ' || where_clause || ' AND ST_Intersects(rast, '|| geom ||') group by '|| geom ||' ) as foo
        ) ;';

	EXECUTE qry ;
	--Create an index on the output raster
	EXECUTE 'DROP INDEX IF EXISTS IDX_' || outRast || '_RAST;';
	EXECUTE 'CREATE INDEX IDX_' || outRast || '_RAST ON ' || outRast || ' USING GIST (ST_CONVEXHULL(RAST));';
	RETURN outRast;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.faib_raster_clip2(character varying, character varying,character varying,character varying,character varying)
  OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.faib_raster_clip2(character varying, character varying,character varying,character varying,character varying) TO public;
GRANT EXECUTE ON FUNCTION public.faib_raster_clip2(character varying, character varying,character varying,character varying,character varying) TO postgres;
GRANT EXECUTE ON FUNCTION public.faib_raster_clip2(character varying, character varying,character varying,character varying,character varying) TO clus_project;
