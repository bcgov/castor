CREATE FUNCTION lower_case_columns(_schemaname text) RETURNS void AS
$$
DECLARE
  colname text;
  tablename text;
  sql text;
BEGIN
  FOR tablename,colname in select table_name,column_name FROM information_schema.columns 
    WHERE table_schema=_schemaname AND column_name<>lower(column_name)
  LOOP
    sql:=format('ALTER TABLE %I.%I RENAME COLUMN %I TO %I',
       _schemaname,
       tablename,
       colname,
       lower(colname));
    raise notice '%', sql;
    execute sql;
  END LOOP;
END;
$$ LANGUAGE plpgsql;