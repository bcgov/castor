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

def AddCLUSRoadsToMap():
    import arcpy
    import os
    wrk = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\Roads'
    mxd = arcpy.mapping.MapDocument("CURRENT")
    df = mxd.activeDataFrame
    for lyrs in arcpy.mapping.ListLayers(mxd, "Symbology", df):
        print "Got Symbology Layer {0}".format(lyrs)
        symLyr = lyrs

    wrk = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\Roads'
    for d in os.listdir(wrk):
        if d.find("CLUS_IntRoads_TSA") == 0:
            tsa = d[17:19]
            if int(tsa) > 44:
                fc =  os.path.join(wrk, d, "Data", d[:-4])

                lyrTmp = 'CLUS_IntRoads_TSA{0}'.format(tsa)
                arcpy.MakeFeatureLayer_management(fc, lyrTmp)
                #arcpy.ApplySymbologyFromLayer_management(lyrTmp, symLyr)
                arcpy.ApplySymbologyFromLayer_management(lyrTmp, "Symbology")
                print 'Adding Layer {0}'.format(fc)
                #arcpy.mapping.AddLayer(df,lyrTmp)

    arcpy.RefreshTOC()








