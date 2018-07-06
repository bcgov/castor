#-------------------------------------------------------------------------------=
'''
Script to Load Spatial Data (FGDB or SHP) into Postgres Instance using OGR

Mike Fowler
GIS Analyst
July 2018

'''
#-------------------------------------------------------------------------------=
import sys
# continue importing modules
import os
from osgeo import ogr
import psycopg2
import time


def Data2PostGIS(workspace, fc, new_name=None, dbName='postgres', dbUser='postgres', dbPass='postgres', dbHost='localhost', dbPort=5432, type='FGDB'):
    print 'Start: {0}'.format(time.ctime())

    connection = psycopg2.connect("dbname={0} host={1} port={2} user={3} password={4}".format(dbName, dbHost, dbPort, dbUser, dbPass))
    cursor = connection.cursor()


    #------------------------------------------------------------------------------------------
    #------------------------------------------------------------------------------------------
    #PG:"dbname='databasename' host='addr' port='5432' user='x' password='y'"
    if type =='FGDB':
        if new_name is None:
            cmd = 'ogr2ogr -lco SPATIAL_INDEX=YES -f "PostgreSQL" PG:"dbname={0} host={1} port={2} user={3} password={4}" {5} {6} -overwrite -progress'.format(dbName, dbHost, dbPort, dbUser, dbPass, workspace,fc)
            outtab = fc
        else:
            cmd = 'ogr2ogr -lco SPATIAL_INDEX=YES -f "PostgreSQL" PG:"dbname={0} host={1} port={2} user={3} password={4}" {5} {6} -nln %s -overwrite -progress'.format(dbName, dbHost, dbPort, dbUser, dbPass, workspace,fc, new_name)
            outtab = new_name
    elif type == 'SHP':
        if new_name is None:
            cmd = 'ogr2ogr -lco SPATIAL_INDEX=YES -f "PostgreSQL" PG:"dbname={0} host={1} port={2} user={3} password={4}" {5} -overwrite -progress -nlt PROMOTE_TO_MULTI -lco precision=NO'.format(dbName, dbHost, dbPort, dbUser, dbPass, fc)
            outtab = fc
        else:
            cmd = 'ogr2ogr -lco SPATIAL_INDEX=YES -f "PostgreSQL" PG:"dbname={0} host={1} port={2} user={3} password={4}" {5} -nln {6} -overwrite -progress -nlt PROMOTE_TO_MULTI -lco precision=NO'.format(dbName, dbHost, dbPort, dbUser, dbPass, fc, new_name)
            outtab = new_name

    print 'Executing {0}'.format(cmd)
    os.system(cmd)
    #------------------------------------------------------------------------------------------
    #------------------------------------------------------------------------------------------

    #-- drop primary key
    stmt = 'alter table %s drop constraint %s_pkey;' % (outtab,outtab)
    print stmt
    cursor.execute(stmt)

    #-- drop NOT NULL constraint
    stmt = 'alter table %s alter column objectid drop NOT NULL;' % (outtab)
    print stmt
    cursor.execute(stmt)

    connection.commit()
    print 'Finish: {0}'.format(time.ctime())

if __name__ == '__main__':
    pass
    i = 1
##    for arg in sys.argv:
##        print '{0}:{1}'.format(arg, i)
##        i +=1
    #wrk = r'\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI\Analysis\Boo_TSA_Overlay_StageData.gdb\Data'

##    fcs = [[r'C:\Data\localApps\zzTemp\Herd_Clip.shp', 'Herd_Clip'], [r'C:\Data\localApps\zzTemp\TSA_Clip.shp', 'TSA_Clip']]
##    for fc in fcs:
##        print 'Processing {0}....'.format(fc)
##        Data2PostGIS(None, fc[0], fc[1],  type='SHP')


##    wrk = r'W:\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI\Analysis\Boo_TSA_Overlay_StageData.gdb'
##    fcs = [['TSA', 'CLUS_TSA'], ['CARIBOU_HERDS_25K', 'CLUS_CARIBOU_HERDS_25K']]
##    for fc in fcs:
##        print 'Processing {0}....'.format(fc)
##        Data2PostGIS(wrk, fc[0], fc[1])

