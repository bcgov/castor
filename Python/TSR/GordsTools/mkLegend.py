#------------------------------------------
# Load a Cat file to Postgres legend
#------------------------------------------

#system module
import sys,os,subprocess

#PostgreSQL connection
import psycopg2
conn = psycopg2.connect(database='postgres')
cur = conn.cursor()


#------------------------------------------
# Read Cat File

unit = sys.argv[1]
catFile = sys.argv[2]

print '((mkLegend)) adding [{0}] to [{1}_legend]'.format(catFile, unit)

inFile = open(catFile, 'r')

dataList = []

#read in data lines

for line in inFile:

	line = line.replace('\n', '')				  #remove line break character
	lineList = line.split(':')					  #split into a list on colon

	dataList.append(lineList)				   		#add to data list
		
inFile.close()

for dataFile in dataList:

	number, text = dataFile

	#create legend table if it doesn't already exist
	sql = 'create table if not exists {0}_legend (layer text, attribute text, text text, number int);'.format(unit)
	cur.execute(sql)
	conn.commit()
			
	#fill in raster number
	sql = "insert into {0}_legend values ('{0}_{1}', '{1}', '{2}', '{3}');".format(unit, catFile, text, number)
	print sql
	cur.execute(sql)
	conn.commit()
	
	
	
	
	