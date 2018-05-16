#Import GDB
import sys,os,subprocess
import psycopg2
conn = psycopg2.connect(database='postgres')
cur = conn.cursor()

#Query Layers in GDB
if len(sys.argv) == 2:
	srcFile = sys.argv[1]

	cmd = ["ogrinfo", 									# provides information on the GDB
		"-so", 											# summary only
		srcFile] 										# source file (gdb)
	process = subprocess.Popen(cmd, stdout=subprocess.PIPE)
	(output, err) = process.communicate()
	process.wait()
	print output
	
	exit()

#Import Layer to PostGIS
elif len(sys.argv) == 4:
	srcFile = sys.argv[1]
	srcLayer = sys.argv[2]
	tableName = sys.argv[3]
	print 'importing [{0}] from [{1}] to table [{2}]\n'.format(srcFile, srcLayer, tableName)

	cmd = ["ogr2ogr", 									# ogr2ogr.exe must be found in the path
		"-a_srs", "EPSG:3005", 							# set SRID
		"-nln", tableName,		 						# name of the new table		
		"-f" , "PostgreSQL", "PG:dbname=postgres" , 	# define destination as PostgreSQL
		srcFile, 										# source file (gdb)
		srcLayer]										# source layer
	process = subprocess.Popen(cmd,stdout=subprocess.PIPE)
	process.wait()
	
	#rename the geometry
	sql = 'alter table {0} rename wkb_geometry to geom;'.format(tableName)
	cur.execute(sql)
	conn.commit()	

	exit()

#Provide usage syntax
else:
	print 'usage:\n list layers --> python gdb2postgis.py [srcFile]\n import layer --> python gdb2postgis.py [srcFile] [srcLayer] [tableName]\n'
	exit()

