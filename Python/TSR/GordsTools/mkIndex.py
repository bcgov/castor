#------------------------------------------
# PyDataPrep
# General template for raster manipulation and creation
version = '1.0'
date = '2013-09-10'
#   - typically for combining rasters in preparation for use in SELES (ie lu-bec-leading species layer)
#   - identifies all unique combinations in new layers, creates cat file and adds to legend file
#------------------------------------------


import numpy
import sys
import subprocess
from osgeo import gdal
from osgeo.gdalconst import *
import random
random.seed(740709)


# register all of the GDAL drivers
gdal.AllRegister()

# Define Constant Parameters
workspace = sys.path[0]  #current directory
tiffdir = 'tif'
ascdir = 'asc'
catsdir = 'cats'
gdallocation = ''	#leave blank for DTS

# Define Global Variables
rows = 0
cols = 0

test = 100

#------------------------------------------
# Input
#------------------------------------------

if len(sys.argv) == 2:
	srcFile = sys.argv[1]
	
#Provide usage syntax
else:
	print 'usage: provide name of reference raster in tif directory\n'
	exit()
	
	
#------------------------------------------
# Modules
#------------------------------------------


# Open a tiff image
# returns a data array
def opentiff(tifffile):

	global rows
	global cols
	global intiff

	print 'Opening {0}.tif ...'.format(tifffile) 
	
	# open tiff using gdal
	intiff = gdal.Open('{0}\{1}\{2}.tif'.format(workspace, tiffdir, tifffile))
	if intiff is None:
		print 'Could not open image file'
		sys.exit(1)

	# read in the band data and get info about it
	band1 = intiff.GetRasterBand(1)

	tiffrows = intiff.RasterYSize
	tiffcols = intiff.RasterXSize


   # check to make sure all rasters are the same size
	if rows == 0:
		rows = tiffrows
	elif tiffrows != rows:
		print 'Rasters are not equal number of rows'
		sys.exit(1)

	if cols == 0:
		cols = tiffcols
	elif tiffcols != cols:
		print 'Rasters are not equal number of rows'
		sys.exit(1)


	# read in data array from
	indata = band1.ReadAsArray(0,0,cols,rows)

	return indata


# Write Cat File	
# and add to legend dictionary
def writecat(dict, filename):

	global legend
	
	outfile = open('{0}\{1}\{2}'.format(workspace, catsdir, filename), 'w')

	for x, item in sorted(dict.iteritems()):
		
		#write to cat file
		outfile.writelines('{0}:{1}\n'.format(x, item))
		
		#add to legend
		if filename in legend:
			legend[filename][x] = item
		else:
			legend[filename] = {}
			legend[filename][0] = 'noData'
			legend[filename][x] = item
		
	outfile.close()	


# Write Tiff
def writetiff(outarray, filename):

	# create the output image
	driver = intiff.GetDriver()

	#print driver
	outtiff = driver.Create('{0}\{1}\{2}.tif'.format(workspace, tiffdir, filename), cols, rows, 1, GDT_Int32, [ 'COMPRESS=LZW' ] )
	if outtiff is None:
		print 'Could not create', filename
		sys.exit(1)

	outBand = outtiff.GetRasterBand(1)

	# write the data
	outBand.WriteArray(outarray, 0, 0)

	# flush data to disk, set the NoData value and calculate stats
	outBand.FlushCache()
	outBand.SetNoDataValue(0)

	# georeference the image and set the projection
	outtiff.SetGeoTransform(intiff.GetGeoTransform())
	outtiff.SetProjection(intiff.GetProjection())


#------------------------------------------
# Script
#------------------------------------------

#------------------------------------------
# Create an Index on FMLB

vars()['mask'] = opentiff(srcFile)
index = numpy.zeros((rows,cols), numpy.int32)

x = 1

#cycle through raster
for i in range(0, rows):
	for j in range(0, cols):
		if mask[i,j] > 0:
			index[i,j] = x
			x += 1

writetiff(index, 'index_{0}'.format(srcFile))





quit()

