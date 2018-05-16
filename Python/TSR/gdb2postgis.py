#Import GDB
import sys,os,subprocess
import psycopg2


def LoadFC_to_Postgres(srcGDB, srcFC, tableName):
    conn = psycopg2.connect(database='postgres')
    cur = conn.cursor()
    #Import Layer to PostGIS
    print 'importing [{0}] from [{1}] to table [{2}]\n'.format(srcGDB, srcFC, tableName)
    cmd = ["ogr2ogr",      								# ogr2ogr.exe must be found in the path
    "-a_srs", "EPSG:3005", 							# set SRID
    "-nln", tableName,		 						# name of the new table
    "-f" , "PostgreSQL", "PG:dbname=postgres" , 	# define destination as PostgreSQL
    srcGDB, 										# source file (gdb)
    srcFC]										# source layer

    print cmd
    process = subprocess.Popen(cmd,stdout=subprocess.PIPE)
    process.wait()

    #rename the geometry
    sql = 'alter table {0} rename wkb_geometry to geom;'.format(tableName)
    cur.execute(sql)
    conn.commit()

    return

if __name__ == '__main__':
    #this executes when script run
    srcGDB = sys.argv[1]
    srcFC = sys.argv[2]
    tableName = sys.argv[3]

