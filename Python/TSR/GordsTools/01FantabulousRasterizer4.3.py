#------------------------------------------
# Fantabulous Rasterizer 
version = '4.3 the Postgres Version'
date = '2016-05-04'
#	- option to import fileGDB into Postgres
#	- text attributes identified based on database field type
#	- unique text items are sorted and numbered by database query
#	- text items and numbering are stored in table 'legend' and written to cat file
#   
#   Release Notes:
#   - 2.0 - switch to using pyshp 'shapefile' and made modules generic
#   - 2.01 - use dbf field type to determine if character to numeric conversion is required in place of 'try float / except'
#   - 2.02 - switch to use OSGEO OGR to read the shape data for only the attribute of interest
#   - 2.1 - added option to force numeric or text encoding if column format is typed wrong
#		- added feature that opens pickled legend and adds to it if it exists
#		- also removes legend items if force numeric option is specified
#	- 2.2 - created DTS option for using GDAL as a local application on the remote host
#		- added a default 'noData' keyed as zero to the pickled legend to prevent key errors for area outside of data sets
#	- 3.0 - major rewrite to utilize File Geodatabase source data and clean up logical flow of code
#	- 4.0 - major rewrite to load in PostgreSQL and create resultant
#	- 4.1 - clean up preservation of data types
#	- 4.2 - added tracking of no data to be carried over as NULL in postgres
#	- 4.3 - fixed error where noData was not actually read from parms file
#		  - added project specific legend for text attribute lookup
#
#------------------------------------------

print '\n(((The Fantabulous Rasterizer {0})))	[{1}]\n'.format(version, date)

#system module
import sys,os,subprocess

if len(sys.argv) == 2:
	parmsFile = sys.argv[1]
	print '----> using parameter file [{0}]\n'.format(parmsFile)
else:
	parmsFile = 'parmsFR4.3.csv'

#gdal module
import gdal

#PostgreSQL connection
import psycopg2
conn = psycopg2.connect(database='postgres')
cur = conn.cursor()


#------------------------------------------
# Read Parameter File

#open parameters file
infile = open(parmsFile, 'r')

gdbList = []
dataList = []

section = 0
#read in data lines
for line in infile:

	line = line.replace('\n', '')				  #remove line break character
	linelist = line.split(',')					  #split into a list on comma

	if linelist[0] == '((Parameters))':						#section 1 contains parameters to be executed
		section = 1
		continue
	elif linelist[0] == '((Import))':						#section 2 GDB data to be imported
		section = 2
		continue
	elif linelist[0] == '((Data))':							#section 3 contains data to be read
		section = 3
		continue

	if section == 1:
		if linelist[0] == '' or linelist[0][0] == '#': continue				#skip if input blank or commented out
		try: 
			linelist[1] * 1
			exec('{0} = {1}'.format(linelist[0], linelist[1]))				#assign numeric value
		except:
			exec('{0} = "{1}"'.format(linelist[0], linelist[1]))			#assign	text value		
	
	elif section == 2:
		if linelist[0] == '' or linelist[0][0] == '#': continue				#skip if input blank or commented out			
		gdbList.append(linelist)
		
	elif section == 3:
		if linelist[0] == '' or linelist[0][0] == '#': continue				#skip if input blank or commented out			
		dataList.append(linelist)				   							#add to data list
		

#close it
infile.close()


#------------------------------------------
# Import GDB to Postgres

for gdbFile in gdbList:

	srcFile = gdbFile[0] 
	srcLayer = gdbFile[1]
	tableName = gdbFile[2]
	
	print '((Importing)))   [{0}\{1}] as table [{2}] in Postgres\n'.format(srcFile, srcLayer, tableName)
	
	#drop table
	sql = 'drop table if exists {0};'.format(tableName)
	cur.execute(sql)
	conn.commit()	
		
	#import using ogr2ogr
	cmd = ["ogr2ogr", 									# ogr2ogr.exe must be found in the path
		"-a_srs", "EPSG:3005", 							# set SRID
		"-nln", tableName,		 						# name of the new table	(same as layer name but lower case)		
		"-f" , "PostgreSQL", "PG:dbname=postgres" , 	# define destination as PostgreSQL
		srcFile, 										# source file (gdb)
		srcLayer]										# source layer
	
	process = subprocess.Popen(cmd,stdout=subprocess.PIPE)
	process.wait()

	#rename the geometry
	sql = 'alter table {0} rename wkb_geometry to geom;'.format(tableName)
	cur.execute(sql)
	conn.commit()	



#------------------------------------------
# Work through data list
	
for dataFiles in dataList:

	layerName = dataFiles[0]
	attribute = dataFiles[1]
	outRaster = dataFiles[2]
	forcenum = dataFiles[3]

	print '((Processing)))   [{0}] with attribute [{1}]\n'.format(layerName, attribute)


#------------------------------------------
# Identify attribute format

	fieldType = 0
	field_types = {21: 'Int32', 23:'Int32', 700:'Float64', 701:'Float64', 1043:'varchar', 1184:'varchar', 1700:'Float64', 16399:'geom'}
	
	sql = 'select * from {0} limit 0;'.format(layerName)
	cur.execute(sql)
	
	#scan through attribute descriptions
	for desc in cur.description:	
		if desc[0] == attribute.lower():
			fieldType = field_types[desc[1]]
			
			
	'''
	pg_types = {
		16: {"bin_in": boolrecv},
		17: {"bin_in": bytearecv},
		19: {"bin_in": varcharin}, # name type
		20: {"bin_in": int8recv},
		21: {"bin_in": int2recv},
		23: {"bin_in": int4recv},
		25: {"bin_in": varcharin}, # TEXT type
		26: {"txt_in": numeric_in}, # oid type
		700: {"bin_in": float4recv},
		701: {"bin_in": float8recv},
		829: {"txt_in": varcharin}, # MACADDR type
		1000: {"bin_in": array_recv}, # BOOL[]
		1003: {"bin_in": array_recv}, # NAME[]
		1005: {"bin_in": array_recv}, # INT2[]
		1007: {"bin_in": array_recv}, # INT4[]
		1009: {"bin_in": array_recv}, # TEXT[]
		1014: {"bin_in": array_recv}, # CHAR[]
		1015: {"bin_in": array_recv}, # VARCHAR[]
		1016: {"bin_in": array_recv}, # INT8[]
		1021: {"bin_in": array_recv}, # FLOAT4[]
		1022: {"bin_in": array_recv}, # FLOAT8[]
		1042: {"bin_in": varcharin}, # CHAR type
		1043: {"bin_in": varcharin}, # VARCHAR type
		1082: {"txt_in": date_in},
		1083: {"txt_in": time_in},
		1114: {"bin_in": timestamp_recv},
		1184: {"bin_in": timestamptz_recv}, # timestamp w/ tz
		1186: {"bin_in": interval_recv},
		1231: {"bin_in": array_recv}, # NUMERIC[]
		1263: {"bin_in": array_recv}, # cstring[]
		1700: {"bin_in": numeric_recv},
		2275: {"bin_in": varcharin}, # cstring
	}
	'''	

	if fieldType == 'geom':
		print '----> Can not rasterize geometry attribute'
		sys.exit()
	if fieldType == 0:
		print '----> Could not find [{0}] in [{1}]\n'.format(attribute, layerName)
		sys.exit()


#------------------------------------------
# Text to Numeric Conversion

	if ( fieldType == 'varchar' or forcenum == 'txt' ) and forcenum != 'num':
		forced = 'FORCED ' if forcenum == 'txt' else ''
		print '----> {0}character formatted attribute:\n'.format(forced)
		
		#clear column rasterNumber if it exists
		sql = 'alter table {0} drop column if exists rasterNumber;'.format(layerName)
		cur.execute(sql)
		conn.commit()
		
		#add new clear rasterNumber column
		sql = 'alter table {0} add column rasterNumber int;'.format(layerName)
		cur.execute(sql)
		conn.commit()

		#create legend table if it doesn't already exist
		sql = 'create table if not exists {0} (layer text, attribute text, text text, number int);'.format(legend)
		cur.execute(sql)
		conn.commit()
		
		#clean legend of possible old entries
		sql = "delete from {2} where layer = '{0}' and attribute = '{1}';".format(layerName, outRaster, legend)
		cur.execute(sql)
		conn.commit()
		
		#add unique text to legend
		sql = "insert into {3} (layer, attribute, text, number) select '{0}', '{1}', {2}, dense_rank() over (order by {2}) from {0} group by 3;".format(layerName, outRaster, attribute, legend)
		cur.execute(sql)
		conn.commit()
		
		#fill in raster number
		sql = "update {0} set rasterNumber = (select number from {3} where layer = '{0}' and attribute = '{1}' and text = cast({2} as text));".format(layerName, outRaster, attribute, legend)
		cur.execute(sql)
		conn.commit()

		#reassign attribute to 'rasterNumber' for rasterization
		attribute = 'rasterNumber'
		fieldType = 'Int32'

#------------------------------------------
# Write Cat File

		#open cat file using attribute name
		catFile = open('{0}\{1}'.format(catsDir, outRaster), 'w')	

		sql = "select number, text from {2} where layer = '{0}' and attribute = '{1}' order by 1;".format(layerName, outRaster, legend)
		cur.execute(sql)
		legendItems = cur.fetchall()
		
		#write to file
		for item in legendItems:		
			catFile.writelines('{0}:{1}\n'.format(item[0], item[1]))

		catFile.close()

		
#------------------------------------------
# Numeric Data

	else:
		#screen message
		forced = 'FORCED ' if forcenum == 'num' else ''
		print '----> {0}numeric formatted attribute:\n'.format(forced)
		
		
#------------------------------------------
# Rasterization

	cmd = 'gdal_rasterize -a {7} -a_nodata {0} -tr {1} {1} -te {2} {3} {4} {5} -ot {6}  -sql "select {7}, geom from {8}" PG:"host=localhost" {9}\{10}.tif' \
	.format(noData, cellRes, xmin, ymin, xmax, ymax, fieldType, attribute, layerName, rasterDir, outRaster)
	process = subprocess.Popen(cmd,stdout=subprocess.PIPE)
	process.wait()
	
	print '----> wrote raster [{0}.tif]\n'.format(outRaster)

	#remove rasterNumber column
	sql = 'alter table {0} drop column if exists rasterNumber;'.format(layerName)
	cur.execute(sql)
	conn.commit()

conn.close()	

