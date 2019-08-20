select r_table_name, srid, blocksize_x, blocksize_y, ST_AsText(ST_Envelope(extent)) from raster_columns order by r_table_name;
