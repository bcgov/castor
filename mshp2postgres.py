#-------------------------------------------------------------------------------
# Name:        mShp2postgres
# Purpose:    Import multiple shapefiles into a postgres database
#
# Author:      KLOCHHEA
#
# Created:     11-04-2018
# Copyright:   (c) KLOCHHEA 2018
# Licence:     <your licence>
#-------------------------------------------------------------------------------

import os, subprocess

# Choose your PostgreSQL version here
os.environ['PATH'] += r';C:\Program Files (x86)\PostgreSQL\8.4\bin'
# http://www.postgresql.org/docs/current/static/libpq-envars.html
os.environ['PGHOST'] = 'localhost'
os.environ['PGPORT'] = '5432'
os.environ['PGUSER'] = 'someuser'
os.environ['PGPASSWORD'] = 'clever password'

base_dir = r"c:\shape_file_repository"
full_dir = os.walk(base_dir)
shapefile_list = []
for source, dirs, files in full_dir:
    for file_ in files:
        if file_[-3:] == 'shp':
            shapefile_path[1] = os.path.join(base_dir, file_)
            shapefile_path[2] = file_
            shapefile_list.append(shapefile_path)
for shape_path in shapefile_list:
    cmds = 'shp2pgsql "' + shape_path + '" new_shp_table | psql '
    subprocess.call(cmds, shell=True)
