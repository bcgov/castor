-- Function: public.getha(geometry)

-- DROP FUNCTION public.getha(geometry);

CREATE OR REPLACE FUNCTION public.getha(ingeom geometry)
  RETURNS numeric AS
$BODY$
DECLARE HA NUMERIC(27,9);
BEGIN
	HA = ST_AREA(inGeom)/10000;
	RETURN HA;
END;	

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.getha(geometry)
  OWNER TO postgres;
