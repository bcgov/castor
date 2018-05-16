#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'''
    Author:  Sasha Lees
    For ArcGIS v.10.1
    Purpose:  Add a field for Road Use Classification, based on best guess for road use
                (1 = high, 2 = mod, 3 = low)
                Type is integer, as this field will be used to convert to raster.  Description is text.

                The classification was initially derived for Grizzly Bear Assmnt, but could be used for other purposes/values.

    NOTE:  This is applicable to available attribute values for the 2015 v2 dataset.  If a revised provincial dataset is built,
            check for additional attributes that may not have been accounted for!

    Date:   22-Jan-2015
    Note: Updated June 15/17 to point to layer in my Okanagan TSR5 netdown geodb. Edited road classes after discussion with Paul Blomberg. Cheryl Delwisch.

    Update: May 4, 2018 - Mike Fowler - Spatial Data Analyst - Caribou Recovery Project (CRP)
            Added additional classification for use in the CRP
            Processing of roads by TSA in Caribou Herd Boundaries and incorporating additional roads from FTA and merging
'''
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--Imports
import arcpy
import os
#--Globals
global cboo, tsa, fta, intRdsSrc, connInstance
cboo = "WHSE_WILDLIFE_INVENTORY.GCPB_CARIBOU_POPULATION_SP"
tsaSRC = "WHSE_ADMIN_BOUNDARIES.FADM_TSA"
fta = 'WHSE_FOREST_TENURE.FTEN_ROAD_SECTION_LINES_SVW'
intRdsSrc = r'\\spatialfiles.bcgov\Work\srm\bcce\shared\data_library\roads\2017\BC_CE_IntegratedRoads_2017_v1_20170214.gdb\integrated_roads'

connInstance = r'bcgw.bcgov/idwprod1.bcgov'

def CopyIntRoads(rdsSRC, outDB, outName):
    outFC = os.path.join(outDB, outName)
    if arcpy.Exists(outFC):
        arcpy.Delete_management(outFC)
    print 'Copying integrated roads ({0}) to Output location {1}....'.format(rdsSRC, outFC)
    arcpy.FeatureClassToFeatureClass_conversion(rdsSRC, outDB, outName)

    #Add New Field
    if not arcpy.ListFields(outFC, 'INT_ROADS_ID'):
        print 'Adding INT_ROADS_ID field'
        arcpy.AddField_management(outFC,'INT_ROADS_ID','LONG')

    lyrFC = 'lyrFC'
    lyrFC = arcpy.MakeFeatureLayer_management(outFC, lyrFC)
    arcpy.SelectLayerByAttribute_management(lyrFC,"NEW_SELECTION")
    print 'Calculating INT_ROADS_ID = OBJECTID....'
    arcpy.CalculateField_management(outFC, 'INT_ROADS_ID', '!OBJECTID!', "PYTHON_9.3")
    arcpy.Delete_management(lyrFC)

def SpatialJoinFTAtoIntRoads(wrk, intRoads, ftaRoads):
    sjFC = os.path.join(wrk, "CEF_IntRoads_FTA_SJ")
    print 'Spatially joining FTA Roads attributes to the Integrated Roads data....'
    fMap = """INT_ROADS_ID "INT_ROADS_ID" true true false 4 Long 0 0 ,First,#, {0}, INT_ROADS_ID,-1,-1;
            FOREST_FILE_ID "FOREST_FILE_ID" true false false 10 Text 0 0 ,First,#,{1},FOREST_FILE_ID,-1,-1;
            ROAD_SECTION_ID "ROAD_SECTION_ID" true false false 30 Text 0 0 ,First,#,{1},ROAD_SECTION_ID,-1,-1;
            RETIREMENT_DATE "RETIREMENT_DATE" true true false 36 Date 0 0 ,First,#,{1},RETIREMENT_DATE,-1,-1;
            ROAD_SECTION_NAME "ROAD_SECTION_NAME" true true false 50 TEXT 0 0 ,First,#,{1},ROAD_SECTION_NAME,-1,-1;
            FILE_TYPE_DESCRIPTION "FILE_TYPE_DESCRIPTION" true true false 120 Text 0 0 ,First,#,{1},FILE_TYPE_DESCRIPTION,-1,-1;
            FEATURE_LENGTH_M "FEATURE_LENGTH_M" true true false 8 Double 4 19 ,First,#,{1},FEATURE_LENGTH_M,-1,-1""".format(intRoads, ftaRoads)

    DeleteExists(sjFC)
    arcpy.SpatialJoin_analysis(intRoads, ftaRoads, sjFC, join_operation="JOIN_ONE_TO_ONE", join_type="KEEP_ALL", field_mapping=fMap, match_option="INTERSECT", search_radius="1 Meters")

def CreateBCGWConn(dbUser, dbPass):
    connBCGW = os.path.join(os.path.dirname(arcpy.env.scratchGDB), 'RdClass_BCGW.sde')
    if os.path.isfile(connBCGW):
        os.remove(connBCGW)
    #print "Creating new BCGW Connection File..."
    #connInstance = r'bcgw.bcgov/idwprod1.bcgov'
    try:
        arcpy.CreateDatabaseConnection_management(os.path.dirname(connBCGW), os.path.basename(connBCGW), 'ORACLE', connInstance, username=dbUser, password=dbPass)
    except:
        print 'Error Creating BCGW connection....'
        connBCGW = None
    return connBCGW

def GetCaribouTSAList(dbUser, dbPass):
    conn = CreateBCGWConn(dbUser, dbPass)
    lyrBoo = 'lyrBoo'
    lyrTSA = 'lyrTSA'
    #--Create a layer of Cariboo herd locations
    arcpy.MakeFeatureLayer_management(os.path.join(conn, cboo), lyrBoo)
    #--Get a layer of just the TSA's
    arcpy.MakeFeatureLayer_management(os.path.join(conn, tsaSRC), lyrTSA, where_clause="TSB_NUMBER IS NULL")
    tsaLyr = arcpy.mapping.Layer(lyrTSA)
    arcpy.SelectLayerByLocation_management(lyrTSA, 'INTERSECT', lyrBoo)
    lstTSA = []
    with arcpy.da.SearchCursor(lyrTSA, ['TSA_NUMBER']) as cursor:
        for row in cursor:
            #print row[0]
            lstTSA.append(row[0])

    arcpy.Delete_management(lyrBoo)
    return [sorted(set(lstTSA)), tsaLyr]

def ProcessRoadsByTSA(wrk, dbUser, dbPass, tsaLst=None):
    tsaRslt = GetCaribouTSAList(dbUser, dbPass)
    #---------------------------------------------------------------------------
    #--If the tsaLst is None then we run for all herd, TSA boundaries otherwise
    #--we run the TSA's supplied in the list
    #---------------------------------------------------------------------------
    if tsaLst is None:
        #--Get TSA information that intersect Caribour Herd Data
        tsaLst = tsaRslt[0]
    tsaLyr = tsaRslt[1]

    bcgwconn = CreateBCGWConn(dbUser, dbPass)
    ftaRdsSrc = os.path.join(bcgwconn, fta)
    #intRdsSrc = r'\\spatialfiles.bcgov\Work\srm\bcce\shared\data_library\roads\2017\BC_CE_IntegratedRoads_2017_v1_20170214.gdb\integrated_roads'
    #--Loop through the pertinent TSA's
    for tsa in tsaLst:
        print 'Processing TSA: {0}'.format(tsa)
        #--Select TSA we need
        arcpy.SelectLayerByAttribute_management(tsaLyr, "NEW_SELECTION", "TSA_NUMBER = '{0}' AND TSB_NUMBER IS NULL AND RETIREMENT_DATE IS NULL".format(tsa))
        arcpy.env.extent = arcpy.Describe(tsaLyr).extent
        DeleteExists(os.path.join(wrk, 'CLUS_IntRoads_TSA{0}.gdb'.format(tsa)))
        arcpy.CreateFileGDB_management(wrk, 'CLUS_IntRoads_TSA{0}'.format(tsa))
        arcpy.CreateFeatureDataset_management(os.path.join(wrk, 'CLUS_IntRoads_TSA{0}.gdb'.format(tsa)), "Data", arcpy.SpatialReference(3005))
        arcpy.env.workspace = os.path.join(wrk, 'CLUS_IntRoads_TSA{0}.gdb'.format(tsa), "Data")

        tsaIntRds = os.path.join(arcpy.env.workspace, "CEF_IntRoads_TSA{0}".format(tsa))
        tsaFTARds = os.path.join(arcpy.env.workspace, "FTA_Roads_TSA{0}".format(tsa))

        print '\tClipping Integrated Roads to TSA....'
        arcpy.Clip_analysis(intRdsSrc, tsaLyr, "CEF_IntRoads_TSA{0}".format(tsa), "0.001 meters")
        print '\tClipping FTA Roads to TSA....'
        arcpy.Clip_analysis(ftaRdsSrc, tsaLyr, "FTA_Roads_TSA{0}".format(tsa), "0.001 meters")
        #-----------------------------------------------------------------------------------------------------
        #-Prepping the Inegrated, DRA Roads portion
        #-----------------------------------------------------------------------------------------------------
        AddCLUSClassFields(tsaIntRds)
        print '\tClassifying DRA Roads....'
        RUN_CEF_RoadClass(tsaIntRds)
        RUN_DRA_RoadClass(tsaIntRds)
        tsaIntRdsLyr = 'tsaIntRdsLyr'
        #--Calculate the CLUS_ROAD_CLASS = 1 where assigned high use (1) by the CEF Classification
        arcpy.MakeFeatureLayer_management(tsaIntRds, tsaIntRdsLyr, "CEF_RD_USE_CLASS = 1")
        arcpy.CalculateField_management(tsaIntRdsLyr, "CLUS_ROAD_CLASS", '1', "PYTHON_9.3")
        arcpy.CalculateField_management(tsaIntRdsLyr, "CLUS_ROAD_CLASS_DESC", "'CEF-High Use'", "PYTHON_9.3")
        #--Delete the features that are not High Classed (1, 1B, 1C)
        DeleteExists(tsaIntRdsLyr)
        arcpy.MakeFeatureLayer_management(tsaIntRds, tsaIntRdsLyr)
        arcpy.SelectLayerByAttribute_management(tsaIntRdsLyr, "NEW_SELECTION", "CLUS_ROAD_CLASS NOT IN ('1', '1B', '1C') OR CLUS_ROAD_CLASS IS NULL")
        arcpy.DeleteFeatures_management(tsaIntRdsLyr)
        #-----------------------------------------------------------------------------------------------------
        #-Prepping the FTA Roads portion
        #-----------------------------------------------------------------------------------------------------
        arcpy.AddField_management(tsaFTARds, "BCGW_SOURCE", 'TEXT', 255)
        arcpy.CalculateField_management(tsaFTARds, "BCGW_SOURCE", "'WHSE_FOREST_TENURE.FTEN_ROAD_SECTION_LINES_SVW'", "PYTHON_9.3")
        AddCLUSClassFields(tsaFTARds)
        print '\tClassifying FTA Roads....'
        RUN_FTA_RoadClass(tsaFTARds)
        tsaFTARdsLyr = 'tsaFTARdsLyr'
        #--Delete the features that are not High Classed FTA (1D, 1E)
        arcpy.MakeFeatureLayer_management(tsaFTARds, tsaFTARdsLyr, "CLUS_ROAD_CLASS NOT IN ('1D', '1E') OR CLUS_ROAD_CLASS IS NULL")
        arcpy.DeleteFeatures_management(tsaFTARdsLyr)
        #-----------------------------------------------------------------------------------------------------
        #-Union the Results together
        #-----------------------------------------------------------------------------------------------------
        outFC = 'CLUS_IntRoads_TSA{0}'.format(tsa)
        #print 'Doing a Union to combine the CEF and FTA classified road datasets....'
        #arcpy.Union_analysis([[tsaIntRds, 1],[tsaFTARds, 2]], outFC, cluster_tolerance=7)
        print '\tDoing a Merge to combine the CEF and FTA classified road datasets....'
        arcpy.Merge_management([tsaIntRds, tsaFTARds], outFC)
        #--Delete the Integrated Roads and FTA datasets used to create the product
        lstFldsKeep = []
        for fld in arcpy.ListFields(tsaIntRds):
            lstFldsKeep.append(fld.name)
        for fld in arcpy.ListFields(outFC):
            if fld.name not in lstFldsKeep:
                try:
                    arcpy.DeleteField_management(outFC, fld.name)
                except:
                    pass
        arcpy.Delete_management(tsaIntRds)
        arcpy.Delete_management(tsaFTARds)
        #--Cleanup layers from memory
        arcpy.Delete_management(tsaFTARdsLyr)
        arcpy.Delete_management(tsaIntRdsLyr)


        print '\tProcessing TSA {0} Complete....'.format(tsa)

    arcpy.Delete_management(tsaLyr)
    print 'Process Roads by TSA Complete....'.format(tsa)
    return

def DeleteExists(data):
    if arcpy.Exists(data):
        arcpy.Delete_management(data)
        return True
    else:
        return False
def AddCLUSClassFields(fc):
    #--Adding Caribou Recovery Project Fields for road classification
    if not arcpy.ListFields(fc,'CLUS_ROAD_CLASS'):
        #print 'Adding CLUS_ROAD_CLASS'
        arcpy.AddField_management(fc,'CLUS_ROAD_CLASS','TEXT', field_precision='2')
    if not arcpy.ListFields(fc,'CLUS_ROAD_CLASS_DESC'):
        #print 'Adding CLUS_ROAD_CLASS_DESC'
        arcpy.AddField_management(fc,'CLUS_ROAD_CLASS_DESC','TEXT','','','50')

def RUN_DRA_RoadClass(rdsFC):
    draLyr = 'draLyr'
    arcpy.MakeFeatureLayer_management(rdsFC, draLyr)
    #--Calculate 1B DRA Local, Loose and Named
    #print 'Calculating 1B for DRA Local, Loose roads with a Name...'
    qry = "(UPPER(ROAD_CLASS) = 'LOCAL' AND UPPER(ROAD_SURFACE) = 'LOOSE' AND ROAD_NAME_FULL IS NOT NULL)"
    #print qry
    arcpy.SelectLayerByAttribute_management(draLyr,"NEW_SELECTION",qry)
    arcpy.CalculateField_management(draLyr, 'CLUS_ROAD_CLASS', "'1B'", "PYTHON_9.3")
    arcpy.CalculateField_management(draLyr, 'CLUS_ROAD_CLASS_DESC', "'DRA-Local,Loose,Named'", "PYTHON_9.3")
    #--Calculate 1C DRA Resource,Mainline
    #print 'Calculating 1C for DRA Resource,Mainline...'
    qry = "(UPPER(ROAD_CLASS) = 'RESOURCE' AND UPPER(ROAD_SURFACE) = 'LOOSE' AND UPPER(ROAD_NAME_FULL) LIKE '%MAINLINE%')"
    #print qry
    arcpy.SelectLayerByAttribute_management(draLyr,"NEW_SELECTION",qry)
    arcpy.CalculateField_management(draLyr, 'CLUS_ROAD_CLASS', "'1C'", "PYTHON_9.3")
    arcpy.CalculateField_management(draLyr, 'CLUS_ROAD_CLASS_DESC', "'DRA-Local,Loose,Named'", "PYTHON_9.3")

    arcpy.Delete_management(draLyr)

def RUN_FTA_RoadClass(rdsFC):
    ftaLyr = 'ftaLyr'
    arcpy.MakeFeatureLayer_management(rdsFC, ftaLyr)
    #--Calculate FTA related Main Branches and Mainlines
    #print 'Calculating Type for FTA active roads Main Branches and Mainlines...'
    qry = "((FILE_TYPE_DESCRIPTION = 'Road Permit' and UPPER(ROAD_SECTION_NAME) LIKE '%MAINLINE%') OR (FILE_TYPE_DESCRIPTION = 'Forest Service Road' and UPPER(ROAD_SECTION_ID) = '01')) AND RETIREMENT_DATE IS NULL"
    #print qry
    arcpy.SelectLayerByAttribute_management(ftaLyr,"NEW_SELECTION",qry)
    arcpy.CalculateField_management(ftaLyr, 'CLUS_ROAD_CLASS', "'1D'", "PYTHON_9.3")
    arcpy.CalculateField_management(ftaLyr, 'CLUS_ROAD_CLASS_DESC', "'FTA-Current and Main Branches,Mainlines'", "PYTHON_9.3")
    #--Calculate FTA related roads > 10km in length as proxy for Main Roads as well.
    #print 'Calculating Type for FTA active roads that are > 10km...'
    qry = "FILE_TYPE_DESCRIPTION IN ('Road Permit', 'Forest Service Road') AND RETIREMENT_DATE IS NULL AND FEATURE_LENGTH_M >= 10000"
    #print qry
    arcpy.SelectLayerByAttribute_management(ftaLyr,"NEW_SELECTION",qry)
    arcpy.CalculateField_management(ftaLyr, 'CLUS_ROAD_CLASS', "'1E'", "PYTHON_9.3")
    arcpy.CalculateField_management(ftaLyr, 'CLUS_ROAD_CLASS_DESC', "'FTA-Current and GT 10km'", "PYTHON_9.3")

    arcpy.Delete_management(ftaLyr)

def RUN_CEF_RoadClass(rdsFC):
    #Add New Field
    if not arcpy.ListFields(rdsFC,'CEF_RD_USE_CLASS'):
        #print 'Adding CEF_RD_USE_CLASS field'
        arcpy.AddField_management(rdsFC,'CEF_RD_USE_CLASS','SHORT')
    if not arcpy.ListFields(rdsFC,'CEF_RD_USE_CLASS_DESC'):
        #print 'Adding CEF_RD_USE_CLASS_DESC field'
        arcpy.AddField_management(rdsFC,'CEF_RD_USE_CLASS_DESC','TEXT','','','15')

    #Set Calculation criteria
    # Note recalc for road_class == 'resource' and road_surface == 'paved'  from moderate to high
    DRA_Type_Code = """def getType(road_class,road_surface):
                if road_class in ['alleyway', 'arterial', 'collector', 'driveway', 'freeway', 'highway', 'lane', 'ramp', 'strata']:
                    return 1
                if road_class == 'local':
                    if road_surface == 'paved':
                        return 1
                    if road_surface == 'loose':
                        return 2
                    if road_surface in ['rough','unknown']:
                        return 2
                if road_class in ['recreation', 'resource','service']:
                    if road_surface in ['paved','loose']:
                        return 2
                    if road_surface in ['rough','unknown','overgrown']:
                        return 2
                if road_class == 'resource' and road_surface == 'paved':
                    return 1
                if road_class in ['restricted', 'skid','trail']:
                    return 3
                if road_class == 'unclassified':
                    return 3
                    if road_surface == 'paved':
                        return 2
                if road_class is None or road_class == '':
                    return 3 """



    TRIM_Type_Code = """def getType(fcode):
                if fcode in ['DA25000110', 'DA25000120', 'DA25000130', 'DA25000160', 'DA25000170', 'DA25000220', 'DA25150140', 'DA25150150']:
                    return 2
                if fcode in ['DA25150000', 'DA25150100', 'DA25150120']:
                    return 3 """

    FTEN_Type_Code = """def getType(fType):
                if fType == 'Forest Service Road':
                    return 2
                else:
                    return 3"""

    OGC_Type_Code = """def getType(ogcType):
                if ogcType == 'HIGH':
                    return 2
                if ogcType in ['LOW', 'WINTER']:
                    return 3"""

    Descr_Type_Code = """def getType(gbType):
                if gbType == 1:
                    return 'High Use'
                if gbType == 2:
                    return 'Moderate Use'
                if gbType == 3:
                    return 'Low Use'
                """

    #Calculate Values
    arcpy.MakeFeatureLayer_management(rdsFC, 'rdLyr')

    #print 'Calculating Type for DRA...'
    DRAqry = "BCGW_SOURCE = 'WHSE_BASEMAPPING.DRA_DGTL_ROAD_ATLAS_MPAR_SP' and ROAD_SURFACE <> 'boat'"
    arcpy.SelectLayerByAttribute_management('rdLyr',"NEW_SELECTION",DRAqry)
    arcpy.CalculateField_management('rdLyr', 'CEF_RD_USE_CLASS', "getType(!ROAD_CLASS!,!ROAD_SURFACE!)", "PYTHON_9.3", DRA_Type_Code)

    #print 'Calculating Type for TRIM...'
    TRIMqry = "BCGW_SOURCE = 'WHSE_BASEMAPPING.TRIM_TRANSPORTATION_LINES'"
    arcpy.SelectLayerByAttribute_management('rdLyr',"NEW_SELECTION",TRIMqry)
    arcpy.CalculateField_management('rdLyr', 'CEF_RD_USE_CLASS', "getType(!FCODE!)", "PYTHON_9.3", TRIM_Type_Code)

    #print 'Calculating Type for FTEN...'
    FTENqry = "BCGW_SOURCE = 'WHSE_FOREST_TENURE.FTEN_ROAD_SECTION_LINES_SVW'"
    arcpy.SelectLayerByAttribute_management('rdLyr',"NEW_SELECTION",FTENqry)
    arcpy.CalculateField_management('rdLyr', 'CEF_RD_USE_CLASS', "getType(!FILE_TYPE_DESCRIPTION!)", "PYTHON_9.3", FTEN_Type_Code)

    #print 'Calculating Type for OGC...'
    OGCqry = "BCGW_SOURCE = 'WHSE_MINERAL_TENURE.OG_PETRLM_ACCESS_ROADS_PUB_SP'"
    arcpy.SelectLayerByAttribute_management('rdLyr',"NEW_SELECTION",OGCqry)
    arcpy.CalculateField_management('rdLyr', 'CEF_RD_USE_CLASS', "getType(!PETRLM_ACCESS_ROAD_TYPE!)", "PYTHON_9.3", OGC_Type_Code)

    #print 'Calculating Type for Misc...'
    inQry = "BCGW_SOURCE in ('WHSE_FOREST_TENURE.ABR_ROAD_SECTION_LINE','WHSE_FOREST_VEGETATION.RSLT_FOREST_COVER_INV_SVW','WHSE_MINERAL_TENURE.OG_PETRLM_DEV_RDS_PRE06_PUB_SP','WHSE_MINERAL_TENURE.OG_PETRLM_DEV_ROADS_PUB_SP')"
    arcpy.SelectLayerByAttribute_management('rdLyr',"NEW_SELECTION",inQry)
    arcpy.CalculateField_management('rdLyr', 'CEF_RD_USE_CLASS', '3', "PYTHON_9.3")

    #print 'Final Description...'
    qry = "CEF_RD_USE_CLASS > 0"
    arcpy.SelectLayerByAttribute_management('rdLyr',"NEW_SELECTION",qry)
    arcpy.CalculateField_management('rdLyr', 'CEF_RD_USE_CLASS_DESC', "getType(!CEF_RD_USE_CLASS!)", "PYTHON_9.3", Descr_Type_Code)

    arcpy.Delete_management('rdLyr')

    #print 'Function Complete! - CEF Road Class'
    return

#-----------------------------------------------
if __name__ == '__main__':
    outWrk = sys.argv[1]
    dbUser = sys.argv[2]
    dbPass = sys.argv[3]
    ProcessRoadsByTSA(outWrk, dbUser, dbPass)
##    rslt = GetCaribouTSAList(dbUser, dbPass)
##    print rslt[0]
##    i = 1
##    wc = "("
##    for i in range(0, len(rslt[0])):
##        if i == len(rslt[0]) -1:
##            wc = wc + "'{0}'".format(rslt[0][i])
##        else:
##            wc = wc + "'{0}',".format(rslt[0][i])
##        i = i + 1
##    wc = wc + ")"
##    print wc
    #pass

