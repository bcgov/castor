#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'''
Script for processing SPI Data for use in CLUS Caribou Project

Mike Fowler
Spatial Data Analyst
June 2018
'''
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--Imports
import datetime
import sys
import os
import shutil
import getpass
import arcpy as gp
import gc
#--Globals
global tsa, connInstance, kennyloggins
#srcTSA = r"\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\tsa\tsa.gdb\data\tsa_study_area_test"
#srcTSA = r"\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\tsa\tsa.gdb\data\tsa_study_area"
srcTSA = r'C:\Users\mwfowler\AppData\Local\Temp\tsa.gdb\data\tsa_study_area'
#srcTSA = r'C:\Users\mwfowler\AppData\Local\Temp\tsa.gdb\data\tsa_study_area_for_processing'

#srcTSA = "C:\Users\mwfowler\AppData\Local\Temp\tsa.gdb\data\tsa_study_area"
#srcVRI = r"C:\Users\mwfowler\AppData\Local\Temp\VRI_TFL.gdb\VEG_COMP_LYR_R1_POLY_with_TFL"
#srcVRI = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\vri_tfl.gdb\vri_tfl'
#srcVRI = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\vri_test.gdb\data\vri_test'
#srcVRI = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\VRI_TFL_GEOM.gdb\VRI_TFL_GEOM'
srcVRI = r'C:\Users\mwfowler\AppData\Local\Temp\VRI_TFL_GEOM.gdb\VRI_TFL_GEOM'

fldTSANum = 'TSA_NUMBER'
fldTSANam = 'TSA_NUMBER_DESCRIPTION'
connInstance = r'bcgw.bcgov/idwprod1.bcgov'
simplifyTol = 3
processGroup = 'Z40'

wrk = os.environ['TEMP']
#wrk = r"\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI"
#wrk = r"C:\Users\mwfowler\AppData\Local\Temp"
#wrk = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl'
#dirLogFile = r"\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Scripts\Python\VRI\log"
dirLogFile = wrk
sLogPrefix = "CLUS_ProcessByTSA_Group{0}_".format(processGroup)

def CreateTempDB(wrk, sType='FILE', name='VRI_by_TSA'):
    if sType == 'FILE':
        tmpName = '{0}.gdb'.format(name)
        tmpWrk = os.path.join(wrk, tmpName)
        if not arcpy.Exists(os.path.join(wrk, tmpName)):
            #DeleteExists(tmpWrk)
            arcpy.CreateFileGDB_management(wrk, tmpName)
        if not arcpy.Exists(os.path.join(wrk, tmpName, "Data")):
            arcpy.CreateFeatureDataset_management(tmpWrk, "Data", arcpy.SpatialReference(3005))
        return os.path.join(tmpWrk, "Data")
    elif sType == 'PERSONAL':
        tmpName = '{0}.mdb'.format(name)
        tmpWrk = os.path.join(wrk, tmpName)
        if not arcpy.Exists(tmpWrk):
            #DeleteExists(tmpWrk)
            arcpy.CreatePersonalGDB_management(wrk, tmpName)
        return tmpWrk

def DeleteExists(data):
    if arcpy.Exists(data):
        arcpy.Delete_management(data)
        return True
    else:
        return False
def CreateLogFile(bMsg=False):
    currLog = os.path.join(dirLogFile, sLogPrefix + datetime.datetime.now().strftime("%Y%m%d_%H%M%S.log"))
    fLog = open(currLog, 'w')
    lstLog = []
    lstLog.append("------------------------------------------------------------------\n")
    lstLog.append("Log file for VRI Process By TSA - Group {0} \n".format(processGroup))
    lstLog.append("Date:{0} \n".format(datetime.datetime.now().strftime("%B %d, %Y - %H%M")))
    lstLog.append("User:{}\n".format(getpass.getuser()))
    lstLog.append("Script:{}\n".format(sys.argv[0]))
    lstLog.append("Source VRI:{}\n".format(srcVRI))
    lstLog.append("Source TSA:{}\n".format(srcTSA))
    lstLog.append("Output Directory:{}\n".format(os.path.join(wrk, 'VRI_by_TSA.gdb')))
    lstLog.append("\n")
    lstLog.append("------------------------------------------------------------------\n")
    sLog = ''.join(lstLog)
    fLog.write(sLog)
    if bMsg:
        print sLog
        #gp.AddMessage(sLog)
    return fLog
def WriteLog(fLog, sMessage, bMsg=False):
    ts = datetime.datetime.now().strftime("%B %d, %Y - %H%M")
    sMsg = '{0} - {1}'.format(ts, sMessage)
    fLog.write(sMsg)
    if bMsg:
        print sMsg
        #gp.AddMessage(sMsg)
def CreateProcessMetadataTable(wrk):
    tab = 'PROCESS_METADATA'
    #DeleteExists(os.path.join(wrk, tab))
    if not arcpy.Exists(os.path.join(wrk, tab)):
        arcpy.CreateTable_management(wrk, tab)
        arcpy.AddField_management(os.path.join(wrk, tab), "TSA_NUMBER", "TEXT", 3)
        arcpy.AddField_management(os.path.join(wrk, tab), "TSA_NAME", "TEXT", 50)
        arcpy.AddField_management(os.path.join(wrk, tab), "POLY_COUNT_ORIG", "LONG", 9)
        arcpy.AddField_management(os.path.join(wrk, tab), "POLY_COUNT_ELIM", "LONG", 9)
        arcpy.AddField_management(os.path.join(wrk, tab), "SIMPLIFY_TOLERANCE", "SHORT", 2)
        arcpy.AddField_management(os.path.join(wrk, tab), "VERTICES_PRE_SIMPLIFY", "LONG", 12)
        arcpy.AddField_management(os.path.join(wrk, tab), "VERTICES_POST_SIMPLIFY", "LONG", 12)
        arcpy.AddField_management(os.path.join(wrk, tab), "VERTICES_REDUCE_PCT", "FLOAT", 6, 6)
    return os.path.join(wrk, tab)
def FieldExists(fc, fld):
    bExists = False
    if fld.upper() in [f.name.upper() for f in arcpy.ListFields(fc)]:
        bExists = True
    return bExists
def GetAreaField(fc):
    for fld in gp.ListFields(fc):
        if fld.name.upper() in ['GEOMETRY_AREA', 'FEATURE_AREA', 'SHAPE_AREA']:
            return fld.name
def EliminatebyGrid(tsa, vri, outFC, fraction=2):
    #--Need a temporary DB to assemble this stuff
    DeleteExists(os.path.join(os.environ['TEMP'], 'ElimTemp{0}.gdb'.format(processGroup)))
    elimDB = CreateTempDB(os.environ['TEMP'], name='ElimTemp{0}'.format(processGroup))
    #--Get Extents of Grids to create as fraction of TSA width, height
    lyrTSA = 'lyrTSA'
    gp.MakeFeatureLayer_management(tsa, lyrTSA)
    desc = gp.Describe(lyrTSA)
    ext = gp.Describe(lyrTSA).extent
    extW = ((ext.XMax - ext.XMin)/fraction) + 1 #--Add 1m to ensure we are not touching edge of grids
    extH = ((ext.YMax - ext.YMin)/fraction) + 1
    gridTemp = os.path.join(elimDB, 'Grid')
    idTemp = os.path.join(elimDB, 'VRI_ID')
    #WriteLog(kennyloggins, 'extW - {0}\n'.format(str(extW)), True)
    #WriteLog(kennyloggins, 'extH - {0}\n'.format(str(extH)), True)
    gp.GridIndexFeatures_cartography(gridTemp, tsa, "INTERSECTFEATURE", "NO_USEPAGEUNIT", polygon_width=extW, polygon_height=extH)
    gp.Identity_analysis(vri, gridTemp, idTemp, "ALL", 1)
    outElims = []
    with arcpy.da.SearchCursor(gridTemp,['SHAPE@', 'PageName']) as cursor:
        for row in cursor:
            try:
                pg = row[1]
                WriteLog(kennyloggins, '----Doing Sub-Eliminate on - {0}\n'.format(str(pg)), True)
                lyrIDTemp = 'lyrIDTemp'
                lyrGridTemp = 'lyrGridTemp'
                outGrid = os.path.join(elimDB, 'Temp_{0}_1Grid'.format(pg))
                outElim = os.path.join(elimDB, 'Temp_{0}_2Elim'.format(pg))
                arcpy.MakeFeatureLayer_management(idTemp, lyrIDTemp, "PageName = '{0}'".format(pg))
                arcpy.env.extent = arcpy.Describe(lyrIDTemp).extent
                arcpy.CopyFeatures_management(lyrIDTemp, outGrid)
                arcpy.Delete_management(lyrIDTemp)
                arcpy.MakeFeatureLayer_management(outGrid, lyrGridTemp)
                arcpy.SelectLayerByAttribute_management(lyrGridTemp, "NEW_SELECTION", "({0}/10000) <= 0.5".format(GetAreaField(outGrid)))
                arcpy.Eliminate_management(lyrGridTemp, outElim, "LENGTH", ex_features=gridTemp)
                outElims.append(outElim)
                arcpy.Delete_management(lyrGridTemp)
                arcpy.Delete_management(outGrid)
                WriteLog(kennyloggins, '----Done Sub-Eliminate - {0}\n'.format(str(outElims)), True)
            except Exception, e:
                WriteLog(kennyloggins, '***Error in Grid by Fraction - {0}\n'.format(str(e)), True)

    WriteLog(kennyloggins, '----Merge the Output Sub-Eliminate grids\n', True)
    arcpy.Merge_management(inputs=outElims, output=outFC)
    WriteLog(kennyloggins, '----Outputs Merged - {0}\n'.format(str(outFC)), True)
    DeleteExists(os.path.join(os.environ['TEMP'], 'ElimTemp{0}.gdb'.format(processGroup)))
    return

def ProcessByTSA(outWrk, tsaWC=None):
    lyrTSA = 'lyrTSA'
    #--Create Table in TSA Database to track Processing Metadata
    processMDTab = CreateProcessMetadataTable(os.path.dirname(outWrk))
    if tsaWC == None:
        arcpy.MakeFeatureLayer_management(srcTSA, lyrTSA)
    else:
        arcpy.MakeFeatureLayer_management(srcTSA, lyrTSA, tsaWC)
    with arcpy.da.SearchCursor(lyrTSA,['SHAPE@', fldTSANum, fldTSANam]) as cursor:
        for row in cursor:
            try:
                #--Get values from the TSA into Variables
                geom = row[0]
                tsa_num = row[1].zfill(2)
                tsa_nam = row[2]
                polyCountClip = 0
                polyCountElim = 0
                iInVerts = 0
                iOutVerts = 0
                reductionRatio = 0.00
                lyrVRI = 'lyrVRI'
                lyrTSA = 'lyrTSA'
                #--Set the Geoprocessing Extent to the current TSA
                arcpy.env.extent = geom.extent
                gp.MakeFeatureLayer_management(geom, lyrTSA)
                WriteLog(kennyloggins, '---------------------------------------------------------------------------\n'.format(tsa_num), True)
                WriteLog(kennyloggins, '----Starting to Process TSA-{0}-{1}\n'.format(tsa_num, tsa_nam), True)
                WriteLog(kennyloggins, '----Creating the VRI Layer....\n', True)
                arcpy.MakeFeatureLayer_management(srcVRI, lyrVRI)
                #---------------------------------------------------------------------
                #--Prepare to select the VRI using the TSA Area.  Speeds up the clip
                #---------------------------------------------------------------------
                #-Select the VRI Using the Current TSA
                arcpy.SelectLayerByLocation_management (lyrVRI, "INTERSECT", geom)
                try:
                    #---------------------------------------------------------------------
                    #--Prepare to do the Geometry Simplify
                    #---------------------------------------------------------------------
                    elimTemp = os.path.join(outWrk, 'vri_tsa_{0}_02Elim'.format(tsa_num))
                    simpTemp = os.path.join(outWrk, 'vri_tsa_{0}_03Simp'.format(tsa_num))

                    WriteLog(kennyloggins, '----Going to try to Simplify with Grid Features 20,000m TSA-{0}\n'.format(tsa_num), True)
                    lyrElimTemp = 'lyrElim'
                    partTemp = os.path.join(outWrk, 'vri_tsa_{0}_02Part'.format(tsa_num))
                    arcpy.MakeFeatureLayer_management(elimTemp, lyrElimTemp)
                    arcpy.GridIndexFeatures_cartography(partTemp, lyrElimTemp, "INTERSECTFEATURE", "NO_USEPAGEUNIT", polygon_width=10000, polygon_height= 10000)
                    arcpy.env.cartographicPartitions = partTemp
                    res = arcpy.cartography.SimplifyPolygon(elimTemp, simpTemp, "POINT_REMOVE", simplifyTol, 5000, "RESOLVE_ERRORS", "NO_KEEP")
                    DeleteExists(partTemp)
                    arcpy.env.cartographicPartitions = None
                    #-----------------------------------------------------------------------------------------
                    #Gather stats on the number of vertices removed
                    #-----------------------------------------------------------------------------------------
                    iInVerts = 0
                    iOutVerts = 0
                    for i in range(0, res.messageCount):
                        msg = res.getMessage(i).upper()
                        if msg.find('INPUT VERTEX COUNT', 0) >= 0:
                            iInVerts = iInVerts + int(msg[19:len(msg)])
                        if msg.find('OUTPUT VERTEX COUNT', 0 ) >= 0:
                            iOutVerts = iOutVerts + int(msg[20:len(msg)])
                    WriteLog(kennyloggins, '----Total Polys before Eliminate-{0}\n'.format(str(polyCountClip)), True)
                    WriteLog(kennyloggins, '----Total Polys after Eliminate-{0}\n'.format(str(polyCountElim)), True)
                    WriteLog(kennyloggins, '----Total In Vertices-{0}\n'.format(str(iInVerts)), True)
                    WriteLog(kennyloggins, '----Total Out Vertices-{0}\n'.format(str(iOutVerts)), True)
                    keepRatio = float(float(iOutVerts)/float(iInVerts))
                    reductionRatio = float(float(iInVerts - iOutVerts)/iInVerts)
                    WriteLog(kennyloggins, '----Reduction %-{0}\n'.format(str(reductionRatio)), True)
                    currOutput = simpTemp
                    WriteLog(kennyloggins, '----End Simplify TSA-{0}\n'.format(tsa_num), True)
                except Exception, e:
                    WriteLog(kennyloggins, '----Simplify with Grid Features 10,000m  Failed! TSA-{0}\n'.format(tsa_num), True)
                    WriteLog(kennyloggins, '----Error Message:\n {0}\n'.format(str(e)), True)
                    #--Unable to Simplify by Partition or Grid.  Give up.  Toss Exception, move on to next TSA
                    raise Exception('Cartographic Partitions and Grid Index Attempts on Simplify Failed.  I Give Up.')

                    #---------------------------------------------------------------------
                    #--Add TSA Information Columns
                    #---------------------------------------------------------------------
                    arcpy.AddField_management(currOutput, "TSA_NUMBER", "TEXT", 3)
                    arcpy.AddField_management(currOutput, "TSA_NAME", "TEXT", 50)
                    with arcpy.da.UpdateCursor(currOutput, ["TSA_NUMBER", "TSA_NAME"]) as cursor:
                        for row in cursor:
                            row[0] = tsa_num
                            row[1] = tsa_nam
                            cursor.updateRow(row)
                    #---------------------------------------------------------------------
                    #--Update the Process Metadata
                    #---------------------------------------------------------------------
                    cursor = arcpy.da.InsertCursor(processMDTab,["TSA_NUMBER", "TSA_NAME", "POLY_COUNT_ORIG", "POLY_COUNT_ELIM", "VERTICES_PRE_SIMPLIFY", "VERTICES_POST_SIMPLIFY", "VERTICES_REDUCE_PCT", "SIMPLIFY_TOLERANCE"])
                    cursor.insertRow((tsa_num, tsa_nam, polyCountClip, polyCountElim, iInVerts, iOutVerts, reductionRatio, simplifyTol))
                    del cursor
                    #---------------------------------------------------------------------
                    #--Rename and Cleanup Temp Datasets
                    #---------------------------------------------------------------------
                    finData = os.path.join(outWrk, 'vri_tsa_{0}'.format(tsa_num))
                    DeleteExists(finData)
                    arcpy.Rename_management(currOutput, finData)
                    DeleteExists(simpTemp)
                    DeleteExists(simpTempPnt)
                    DeleteExists(clipTemp)
                    DeleteExists(elimTemp)
                    #--Clean up Layers to free up memory
                    lyrVRI = ''
                    lyrClipTemp = ''
                    lyrElimTemp = ''
                    lyrTSA = ''
                    DeleteExists(lyrVRI)
                    DeleteExists(lyrClipTemp)
                    DeleteExists(lyrTSA)
                    DeleteExists(lyrElimTemp)
                    del lyrVRI, lyrClipTemp, lyrElimTemp
                    gc.collect()
                    WriteLog(kennyloggins, '----Done Processing TSA-{0}\n'.format(tsa_num), True)
                    WriteLog(kennyloggins, '----Output Data is {1} TSA-{0}\n'.format(tsa_num, finData), True)
                    WriteLog(kennyloggins, '---------------------------------------------------------------------------\n'.format(tsa_num), True)
                except Exception, e:
                    WriteLog(kennyloggins, 'Error Message:\n {0}\n'.format(str(e)), True)
                    #---------------------------------------------------------------------
                    #--Add TSA Information Columns
                    #---------------------------------------------------------------------
                    arcpy.AddField_management(currOutput, "TSA_NUMBER", "TEXT", 3)
                    arcpy.AddField_management(currOutput, "TSA_NAME", "TEXT", 50)
                    with arcpy.da.UpdateCursor(currOutput, ["TSA_NUMBER", "TSA_NAME"]) as cursor:
                        for row in cursor:
                            row[0] = tsa_num
                            row[1] = tsa_nam
                            cursor.updateRow(row)
                    #---------------------------------------------------------------------
                    #--Update the Process Metadata
                    #---------------------------------------------------------------------
                    cursor = arcpy.da.InsertCursor(processMDTab,["TSA_NUMBER", "TSA_NAME", "POLY_COUNT_ORIG", "POLY_COUNT_ELIM", "VERTICES_PRE_SIMPLIFY", "VERTICES_POST_SIMPLIFY", "VERTICES_REDUCE_PCT", "SIMPLIFY_TOLERANCE"])
                    cursor.insertRow((tsa_num, tsa_nam, polyCountClip, polyCountElim, iInVerts, iOutVerts, reductionRatio, simplifyTol))
                    del cursor
                    #---------------------------------------------------------------------
                    #--Rename and Cleanup Temp Datasets
                    #---------------------------------------------------------------------
                    finData = os.path.join(outWrk, 'vri_tsa_{0}'.format(tsa_num))
                    DeleteExists(finData)
                    arcpy.Rename_management(currOutput, finData)
                    DeleteExists(simpTemp)
                    DeleteExists(simpTempPnt)
                    DeleteExists(clipTemp)
                    DeleteExists(elimTemp)
                    DeleteExists(partTemp)
                  #--Clean up Layers to free up memory
                    lyrVRI = ''
                    lyrClipTemp = ''
                    lyrElimTemp = ''
                    lyrTSA = ''
                    DeleteExists(lyrVRI)
                    DeleteExists(lyrClipTemp)
                    DeleteExists(lyrTSA)
                    DeleteExists(lyrElimTemp)
                    del lyrVRI, lyrClipTemp, lyrElimTemp
                    gc.collect()
                    WriteLog(kennyloggins, '----Done Processing TSA-{0}\n'.format(tsa_num), True)
                    WriteLog(kennyloggins, '----Output Data is {1} TSA-{0}\n'.format(tsa_num, finData), True)
                    WriteLog(kennyloggins, '---------------------------------------------------------------------------\n'.format(tsa_num), True)
            except Exception, e:
                WriteLog(kennyloggins, '*****Error Processing TSA-{0}\n'.format(tsa_num), True)
                WriteLog(kennyloggins, '*****Error Message:\n {0}\n'.format(str(e)), True)
                WriteLog(kennyloggins, '---------------------------------------------------------------------------\n'.format(tsa_num), True)
    WriteLog(kennyloggins, '---------------------------------------------------------------------------\n', True)
    WriteLog(kennyloggins, '----Script Complete\n', True)
    WriteLog(kennyloggins, '---------------------------------------------------------------------------\n', True)
#-----------------------------------------------
if __name__ == '__main__':
    #--Setup Environment parameters
    arcpy.env.parallelProcessingFactor = "100%"
    arcpy.env.overwriteOutput = True
    arcpy.env.outputMFlag = "Disabled"
    #--Start a log file
    kennyloggins = CreateLogFile(True)
    #--Create the Output GDB
    #CalcOIDColumn(srcVRI)
    #ProcessByTSA(outWrk)
    outWrk = CreateTempDB(wrk, name='VRI_By_TSA_Group{0}'.format(processGroup))
    ProcessByTSA(outWrk, tsaWC="TSA_NUMBER IN ('40')".format(processGroup))
    #ProcessByTSA(outWrk, tsaWC="TSA_NUMBER IN ('99', '98')")
    #ProcessByTSA(outWrk, tsaExcl="'04', '26'")
    #GetAreaField(r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\VRI_by_TSA.gdb\Data\vri_tsa_05_01Clip')
    #-----------------------------------------------------------
    #-Close the Log File
    #-----------------------------------------------------------
    kennyloggins.close()

