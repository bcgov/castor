#------------------------------------------
# Resultant Generator 
version = '1.6'
date = '2017-11-03'
#	- smashes tif files together with a master index raster
#	- a mask can be applied to limit resultant size
#   
#   Release Notes:
#   - 1.0 - first go
#	- 1.1 - clean up preservation of data types
#		  - actually added the mask promised
#	- 1.2 - switched to string IO buffer and copy from postgres load
#		  - added save grid option
#	- 1.3 - made noData functional
#	- 1.4 - added project specific legend for text attribute lookup
#	- 1.5 - cleaned up memory usage by deleting lists
#	- 1.6 - entirely restructured code to iterate through raster data only once
#		  - stores resultant as concatenated text in a single list
#
#------------------------------------------

print '\n(((The Resultant Generator {0})))	[{1}]\n'.format(version, date)

#system module
import sys,os,subprocess

if len(sys.argv) == 2:
	parmsFile = sys.argv[1]
	print '----> using parameter file [{0}]\n'.format(parmsFile)
else:
	parmsFile = 'parmsRG1.4.csv'

#gdal module
import gdal
from osgeo.gdalconst import *
import struct

#PostgreSQL connection
import psycopg2
conn = psycopg2.connect(database='postgres')
cur = conn.cursor()

#IO
#from io import StringIO
from cStringIO import StringIO


#------------------------------------------
# Read Parameter File

#open parameters file
infile = open(parmsFile, 'r')

dataList = []

section = 0
#read in data lines
for line in infile:

	line = line.replace('\n', '')				  #remove line break character
	linelist = line.split(',')					  #split into a list on comma

	if linelist[0] == '((Parameters))':						#section 1 contains parameters to be executed
		section = 1
		continue
	elif linelist[0] == '((Data))':							#section 2 data to be imported
		section = 2
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
		dataList.append(linelist[0])
		
		

#close it
infile.close()

# insert raster index so it is first column in database
dataList.insert(0,referenceGrid)

# if there is a mask process it first of all rasters
if mask: dataList.insert(0,mask)
	

#------------------------------------------
# Load Legend File	

legendDict = {}
legendIndex = {}


#retrieve legend items
sql = "select layer, attribute, text, number from {0};".format(legend)
cur.execute(sql)
legendData = cur.fetchall()


#put into a dictionary
for item in legendData:
	layer, attribute, text, number = item

	#make sure it is not null
	if text:
	
		if '|' in text:
			print '----->  warning [{0}] [{1}] [{2}] replaced with [{3}]'.format(layer, attribute, text, text.replace('|', '_')) 
			text = text.replace('|', '_')
			
		legendDict[attribute, number] = text
		
		#add to legend index with maximum character width
		legendIndex[attribute] = len(text) if attribute not in legendIndex else max(legendIndex[attribute], len(text))


#------------------------------------------
# Work through data list

print '((Opening Rasters))\n'

#initialize resultant
resultant = []
resIndex = []
rasterMask = []

#initialize raster size parameters
rows = 0
cols = 0

#open raster as list
for dataFile in dataList:

	rasterFile = '{0}\{1}.tif'.format(rasterDir, dataFile)

	#open the raster file
	dataset = gdal.Open(rasterFile, GA_ReadOnly )
	if dataset is None:
		print 'Could not open [{0}]'.format(rasterFile)
		sys.exit(1)
	
	#Reading the raster properties
	band = dataset.GetRasterBand(1)	
	projectionfrom = dataset.GetProjection()
	geotransform = dataset.GetGeoTransform()
	xsize = band.XSize
	ysize = band.YSize
	dataType = gdal.GetDataTypeName(band.DataType)

	# check to make sure all rasters are the same size
	if rows == 0:
		rows = ysize
	elif ysize != rows:
		print 'Rasters are not equal number of rows'
		sys.exit(1)

	if cols == 0:
		cols = xsize
	elif xsize != cols:
		print 'Rasters are not equal number of cols'
		sys.exit(1)
	
	#Reading the raster values
	values = band.ReadRaster( 0, 0, xsize, ysize, xsize, ysize, band.DataType )
	
	#Conversion between GDAL types and python pack types (Can't use complex integer or float!!)
	data_types ={'Byte':'B','UInt16':'H','Int16':'h','UInt32':'I','Int32':'i','Float32':'f','Float64':'d'}	
	values = struct.unpack(data_types[dataType]*xsize*ysize,values)
	
	rasterData = list(values)

	print 'Opened [{0}] with [{1}] cells'.format(rasterFile, len(rasterData))

	#Create raster mask
	# -it will be the first raster if it exists
	# -used as mask it won't be included in the database
	if mask == dataFile and not rasterMask:
		rasterMask = rasterData
		continue


	#check if in legend and is character based
	if dataFile in legendIndex:
		dataType = 'varchar({0})'.format(legendIndex[dataFile])
		resIndex.append([dataFile, dataType])
	else:
		dataType = 'float' if dataType in ('Float64', 'Float32') else 'integer'
		resIndex.append([dataFile, dataType])

#------------------------------------------
# Cycle through raster data	

	#resultant index variable
	r = 0

	for x in range(len(rasterData)):	
		
		
		#check mask
		if mask and rasterMask[x] == noData:
			continue
		else:
		
			#initiate resultant with index
			if dataFile == referenceGrid:
				resultant.append(str(rasterData[x]))
			else:
			
				#character data
				if dataType[0] == 'v': 
					if rasterData[x] > 0:
						textItem = legendDict[dataFile, rasterData[x]]
						resultant[r] = '{0}|{1}'.format(resultant[r], textItem)
					else:
						#non legend items are set to NULL
						resultant[r] = '{0}|{1}'.format(resultant[r],'NULL')
				
				#numeric data
				else:
					if rasterData[x] == noData:
						resultant[r] = '{0}|{1}'.format(resultant[r],'NULL')
					else:
						resultant[r] = '{0}|{1}'.format(resultant[r],str(rasterData[x]))
		
			#increment resultant index
			r += 1
				
				
	#clear memory
	del rasterData	
	

		
#------------------------------------------
# Create Data Table	

print '\n((Creating Data Table))\n'

#drop previous version of table
sql = 'drop table if exists {0}_data;'.format(resName)
cur.execute(sql)
conn.commit()

#create new data table
schema = []

#write create table schema for table columns
for column in resIndex:
	attribute, type = column
	schema.append('{0} {1}'.format(attribute, type))

sql = 'create table {0}_data ({1});'.format(resName, ', '.join(schema))
cur.execute(sql)
conn.commit()


#------------------------------------------
# Insert resultant to a table of data	

#create text dump of resultant
resDump = StringIO()

for x in range(len(resultant)):
	dumpLine = unicode('{0}\n'.format(resultant[x]))
	resDump.write(dumpLine)
			
#clear resultant
del resultant

#rewind text dump		
resDump.seek(0)

#format database attributes
tableName = "{0}_data".format(resName)   
columnNames = (str(m[0]) for m in resIndex)

#copy into database
cur.copy_from(resDump, tableName, sep='|', null= 'NULL', columns=columnNames)
	
conn.commit()
resDump.close()


#------------------------------------------
# Polygonize the Reference Grid and Join Resultant		

#check if grid was previously saved else import it
cur.execute("select exists(select * from information_schema.tables where table_name=%s)", ('{0}_poly'.format(resName),))
if cur.fetchone()[0] is False:

	print '\n((Importing Grid Spatial Data))\n'
	
	print '-----> ignore this annoying error message below:'
	cmd = ['python', 'C:\Progra~1\GDAL\gdal_polygonize.py',
		'{0}\{1}.tif'.format(rasterDir, referenceGrid),
		'-f' , 'PostgreSQL', 'PG:dbname=postgres',
		'{0}_poly'.format(resName)]

	process = subprocess.Popen(cmd,stdout=subprocess.PIPE)
	process.wait()

	#rename the geometry
	sql = 'alter table {0}_poly rename wkb_geometry to geom;'.format(resName)
	cur.execute(sql)
	conn.commit()	

	#set projection
	sql = "select UpdateGeometrySRID('{0}_poly','geom',3005);".format(resName)
	cur.execute(sql)
	conn.commit()	

	#this speeds up QGIS menu
	#print '\n-----> cleaning up your database geometry columns:'
	#sql = "select populate_geometry_columns();"
	#cur.execute(sql)
	#conn.commit()
	
#------------------------------------------
# Join Resultant		

print '\n((Joining Spatial Data with Resultant))\n'

#drop previous version of table
sql = 'drop table if exists {0};'.format(resName)
cur.execute(sql)
conn.commit()

#join data and poly data to create resultant
sql = 'create table {0} as select {0}_poly.*, {0}_data.* from {0}_poly inner join {0}_data on {0}_poly.dn = {0}_data.{1};'.format(resName, referenceGrid)

cur.execute(sql)
conn.commit()	

print '-----> created resultant [{0}]\n'.format(resName)

#drop previous version of table
if saveGrid not in ('yes', 'Yes', 'Y'):
	sql = 'drop table if exists {0}_poly;'.format(resName)
	cur.execute(sql)
	conn.commit()

#drop previous version of table
sql = 'drop table if exists {0}_data;'.format(resName)
cur.execute(sql)
conn.commit()

conn.close()



