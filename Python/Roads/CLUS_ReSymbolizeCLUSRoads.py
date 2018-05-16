#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      mwfowler
#
# Created:     11/05/2018
# Copyright:   (c) mwfowler 2018
# Licence:     <your licence>
#-------------------------------------------------------------------------------

import arcpy
import os

def ReSymbolizeCLUSRoads():
    mxd = arcpy.mapping.MapDocument("CURRENT")
    df = mxd.activeDataFrame
    for lyrs in arcpy.mapping.ListLayers(mxd, "Symbology", df):
        print "Got Symbology Layer {0}".format(lyrs)
        symLyr = lyrs


    for lyr in arcpy.mapping.ListLayers(mxd, "CLUS_IntRoads_TSA*", df):
        print lyr.name
        arcpy.ApplySymbologyFromLayer_management(lyr, symLyr)

    arcpy.RefreshTOC()








