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
#--Globals
global tsa, connInstance, kennyloggins
#srcTSA = r"\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\tsa\tsa.gdb\data\tsa_study_area_test"
#srcTSA = r"\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\tsa\tsa.gdb\data\tsa_study_area"
srcTSA = r'C:\Users\mwfowler\AppData\Local\Temp\tsa.gdb\data\tsa_study_area'
#srcTSA = "C:\Users\mwfowler\AppData\Local\Temp\tsa.gdb\data\tsa_study_area"
#srcVRI = r"C:\Users\mwfowler\AppData\Local\Temp\VRI_TFL.gdb\VEG_COMP_LYR_R1_POLY_with_TFL"
#srcVRI = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\vri_tfl.gdb\vri_tfl'
#srcVRI = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\vri_test.gdb\data\vri_test'
#srcVRI = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\VRI_TFL_GEOM.gdb\VRI_TFL_GEOM'
srcVRI = r'C:\Users\mwfowler\AppData\Local\Temp\VRI_TFL_GEOM.gdb\VRI_TFL_GEOM'

fldTSANum = 'TSA_NUMBER'
fldTSANam = 'TSA_NUMBER_DESCRIPTION'
connInstance = r'bcgw.bcgov/idwprod1.bcgov'

#wrk = os.environ['TEMP']
#wrk = r"\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI"
wrk = r"C:\Users\mwfowler\AppData\Local\Temp"
#wrk = r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl'
#dirLogFile = r"\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Scripts\Python\VRI\log"
dirLogFile = wrk
sLogPrefix = "CLUS_ProcessByTSA_"

def CalcOIDColumn(fc, newOIDField='SOURCE_OBJECTID'):
    if not newOIDField in [fld.name for fld in gp.ListFields(srcVRI)]:
        #WriteLog(kennyloggins, 'Deleting existing {0} field from {1}....'.format(newOIDField, fc), True)
        #arcpy.DeleteField_management(fc,[newOIDField])
        WriteLog(kennyloggins, 'Adding new field {0} field to {1}....'.format(newOIDField, fc), True)
        arcpy.AddField_management(fc, newOIDField, "LONG", 9)
        OIDFld = arcpy.Describe(fc).OIDFieldName
        #--Cursor through the data and update the new OID field to the OID Value
        WriteLog(kennyloggins, 'Computing value of {0} to {1}....\n'.format(newOIDField, fc), True)
        with arcpy.da.UpdateCursor(fc, [OIDFld, newOIDField]) as cursor:
            for row in cursor:
                row[1] = row[0]
                cursor.updateRow(row)

    return



def CreateBCGWConn(dbUser, dbPass):
    connBCGW = os.path.join(os.path.dirname(arcpy.env.scratchGDB), 'SPI_DataAnalysis.sde')
    if os.path.isfile(connBCGW):
        os.remove(connBCGW)
    try:
        arcpy.CreateDatabaseConnection_management(os.path.dirname(connBCGW), os.path.basename(connBCGW), 'ORACLE', connInstance, username=dbUser, password=dbPass)
    except:
        print 'Error Creating BCGW connection....'
        connBCGW = None
    return connBCGW

def GetFieldMap(tab1,tab1flds,tab2, tab2flds):
    #---------------------------------------------------------------------------
    #Builds a field map of two input tables retaining the fields specified in the
    #associated lists.  tab1(2)flds is a lst object for fields, or a string of "*" if keeping all fields
    #Example usage:
    #fc1 = r'C:\Users\mwfowler.IDIR\AppData\Local\Temp\7\SPI_DataAnalysis.gdb\Data\SPI_INCID'
    #fc1flds = ['INCIDENTAL_OBSERVATION_ID']
    #fc2 = r'C:\Users\mwfowler.IDIR\AppData\Local\Temp\7\SPI_DataAnalysis.gdb\Data\SPI_SURVEY'
    #fc2flds = "*"
    #fmap = GetFieldMap(fc1, fc1flds, fc2, fc2flds)
    #---------------------------------------------------------------------------
    fMaps = arcpy.FieldMappings()
    fMaps.addTable(tab1)
    fMaps.addTable(tab2)
    for fmap in fMaps.fieldMappings:
        if fmap.getInputTableName(0) == tab1:
            if tab1flds == "*":
                pass
            else:
                if not fmap.outputField.name in tab1flds:
                    #print "Removing {0} from {1}....".format(fmap.outputField.name, os.path.basename(fmap.getInputTableName(0)))
                    fMaps.removeFieldMap(fMaps.findFieldMapIndex(fmap.outputField.name))
        elif fmap.getInputTableName(0) == tab2:
            if tab2flds == "*":
                pass
            else:
                if not fmap.outputField.name in tab2flds:
                    #print "Removing {0} from {1}....".format(fmap.outputField.name, os.path.basename(fmap.getInputTableName(0)))
                    fMaps.removeFieldMap(fMaps.findFieldMapIndex(fmap.outputField.name))
    return fMaps

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

def ProcessSPI(wrk, dbUser, dbPass):
    spatwrk = CreateTempDB(wrk)
    tabwrk = CreateTempDB(wrk, 'PERSONAL')
    #spattabwrk = CreateTempDB(wrk, 'PERSONAL', 'SPI_DataAnalysis_Spatial')

    bcgwconn = CreateBCGWConn(dbUser, dbPass)
    boo25k = BufferBoo(spatwrk, os.path.join(bcgwconn, srcCboo))

    srcs = []
    srcs.append(['WHSE_WILDLIFE_INVENTORY.SPI_INCID_OBS_ALL_SP', "SPI_INCID", "SPECIES_CODE IN ('M-RATA', 'M-ALAM', 'M-CALU')", ['INCIDENTAL_OBSERVATION_ID']])
    srcs.append(['WHSE_WILDLIFE_INVENTORY.SPI_SURVEY_OBS_ALL_SP', "SPI_SURVEY", "SPECIES_CODE IN ('M-RATA', 'M-ALAM', 'M-CALU')", ['SURVEY_OBSERVATION_ID']])
    srcs.append(['WHSE_WILDLIFE_INVENTORY.SPI_TELEMETRY_OBS_ALL_SP', "SPI_TELEM", "SPECIES_CODE IN ('M-RATA', 'M-ALAM', 'M-CALU')", ['TELEMETRY_OBSERVATION_ID']])
    sjs = []
    sjs.append([boo25k, "CBOO_25KM", None])
    #sjs.append(["WHSE_WILDLIFE_INVENTORY.GCPB_CARIBOU_POPULATION_SP", "CBOO_25KM", None])
    #sjs.append(["WHSE_WILDLIFE_MANAGEMENT.WAA_WILDLIFE_MGMT_UNITS_SVW", "WMU", None])
    #sjs.append(["WHSE_ADMIN_BOUNDARIES.FADM_TSA", "TSA", None])
    for src in srcs:
        fcSRC = os.path.join(bcgwconn, src[0])
        lyrSRC = "lyrSRC"
        arcpy.MakeFeatureLayer_management(fcSRC, lyrSRC, src[2])
        print "Converting {0} to table....".format(src[1])
##        DeleteExists(os.path.join(spattabwrk, src[1]))
##        arcpy.TableToTable_conversion(lyrSRC, spattabwrk, src[1])
##        DeleteExists(os.path.join(spatwrk, src[1]))
##        arcpy.CopyFeatures_management(lyrSRC, os.path.join(spatwrk, src[1]))
        for sj in sjs:
            bClean = False
            fcSJOut = os.path.join(spatwrk, src[1] + "_" + sj[1])
            if sj[0][:4] == 'WHSE':
                sjFC = os.path.join(bcgwconn, sj[0])
            else:
                sjFC = sj[0]

            print "Peforming Spatial Join on {0} to {1}....".format(src[0], sj[0])
            DeleteExists(fcSJOut)
            fMap = GetFieldMap(fcSRC, src[3], sjFC, "*")
            arcpy.SpatialJoin_analysis(lyrSRC, sjFC, fcSJOut, join_operation="JOIN_ONE_TO_ONE", join_type="KEEP_ALL", match_option="INTERSECT", search_radius="1 Meters", field_mapping=fMap)
            tabSJOut = os.path.join(tabwrk, src[1] + "_" + sj[1])
            DeleteExists(tabSJOut)
            arcpy.TableToTable_conversion(fcSJOut, tabwrk, src[1] + "_" + sj[1])
            DeleteExists(fcSJOut)
            if bClean:
                DeleteExists(sjFC)

        DeleteExists(lyrSRC)
    return

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
    lstLog.append("Log file for VRI Process By TSA \n")
    lstLog.append("Date:{0} \n".format(datetime.datetime.now().strftime("%B %d, %Y - %H%M")))
    lstLog.append("User:{}\n".format(getpass.getuser()))
    lstLog.append("\n")
    lstLog.append("------------------------------------------------------------------\n")
    sLog = ''.join(lstLog)
    fLog.write(sLog)
    if bMsg:
        print sLog
        gp.AddMessage(sLog)
    return fLog
def WriteLog(fLog, sMessage, bMsg=False):
    ts = datetime.datetime.now().strftime("%B %d, %Y - %H%M")
    sMsg = '{0} - {1}'.format(ts, sMessage)
    fLog.write(sMsg)
    if bMsg:
        print sMsg
        gp.AddMessage(sMsg)
def GetAreaField(fc):
    for fld in gp.ListFields(fc):
        if fld.name.upper() in ['GEOMETRY_AREA', 'FEATURE_AREA', 'SHAPE_AREA']:
            return fld.name

def ProcessByTSA(outWrk, tsaExcl=None):
    lyrVRI = 'lyrVRI'
    lyrTSA = 'lyrTSA'
    WriteLog(kennyloggins, 'Creating the VRI Layer....\n', True)
    arcpy.MakeFeatureLayer_management(srcVRI, lyrVRI)
    if tsaExcl == None:
        arcpy.MakeFeatureLayer_management(srcTSA, lyrTSA)
    else:
        arcpy.MakeFeatureLayer_management(srcTSA, lyrTSA, 'TSA_NUMBER NOT IN ({0})'.format(tsaExcl))
    with arcpy.da.SearchCursor(lyrTSA,['SHAPE@', fldTSANum, fldTSANam]) as cursor:
        for row in cursor:
            try:
                #--Get values from the TSA into Variables
                geom = row[0]
                tsa_num = row[1].zfill(2)
                tsa_nam = row[2]
                WriteLog(kennyloggins, '---------------------------------------------------------------------------\n'.format(tsa_num), True)
                WriteLog(kennyloggins, '----Starting to Process TSA-{0}-{1}\n'.format(tsa_num, tsa_nam), True)
                #---------------------------------------------------------------------
                #--Prepare to select the VRI using the TSA Area.  Speeds up the clip
                #---------------------------------------------------------------------
                #--Set the Geoprocessing Extent to the current TSA
                arcpy.env.extent = geom.extent
                #-Select the VRI Using the Current TSA
                arcpy.SelectLayerByLocation_management (lyrVRI, "INTERSECT", geom)
                #---------------------------------------------------------------------
                #--Prepare to do the Clip
                #---------------------------------------------------------------------
                clipTemp = os.path.join(outWrk, 'vri_tsa_{0}_01Clip'.format(tsa_num))
                lyrClipTemp = 'lyrClipTemp'
                WriteLog(kennyloggins, '----Start Clip TSA-{0}\n'.format(tsa_num), True)
                arcpy.Clip_analysis(lyrVRI, geom, clipTemp)
                WriteLog(kennyloggins, '----End Clip TSA-{0}\n'.format(tsa_num), True)
                #---------------------------------------------------------------------
                #--Prepare to do the Eliminate
                #---------------------------------------------------------------------
                arcpy.MakeFeatureLayer_management(clipTemp, lyrClipTemp)
                arcpy.SelectLayerByAttribute_management(lyrClipTemp, "NEW_SELECTION", "({0}/10000) <= 0.5".format(GetAreaField(clipTemp)))
                elimTemp = os.path.join(outWrk, 'vri_tsa_{0}_02Elim'.format(tsa_num))
                WriteLog(kennyloggins, '----Start Eliminate TSA-{0}\n'.format(tsa_num), True)
                arcpy.Eliminate_management(lyrClipTemp, elimTemp, "LENGTH")
                WriteLog(kennyloggins, '----End Eliminate TSA-{0}\n'.format(tsa_num), True)
                #---------------------------------------------------------------------
                #--Prepare to do the Geometry Simplify
                #---------------------------------------------------------------------
                simpTemp = os.path.join(outWrk, 'vri_tsa_{0}_03Simp'.format(tsa_num))
                simpTempPnt = os.path.join(outWrk, 'vri_tsa_{0}_03Simp_Pnt'.format(tsa_num))
                WriteLog(kennyloggins, '----Start Simplify TSA-{0}\n'.format(tsa_num), True)
                try:
                    arcpy.cartography.SimplifyPolygon(elimTemp, simpTemp, "POINT_REMOVE", 3, 5000)
                except:
                    WriteLog(kennyloggins, '----Simplify Failed, will try to Partition and try TSA-{0}\n'.format(tsa_num), True)
                    partTemp = os.path.join(outWrk, 'vri_tsa_{0}_02Part'.format(tsa_num))
                    arcpy.cartography.CreateCartographicPartitions(elimTemp, partTemp, 10000)
                    arcpy.env.cartographicPartitions = partTemp
                    arcpy.cartography.SimplifyPolygon(elimTemp, simpTemp, "POINT_REMOVE", 3, 5000)
                    DeleteExists(partTemp)
                WriteLog(kennyloggins, '----End Simplify TSA-{0}\n'.format(tsa_num), True)
                #---------------------------------------------------------------------
                #--Add TSA Information Columns
                #---------------------------------------------------------------------
                arcpy.AddField_management(simpTemp, "TSA_NUMBER", "TEXT", 2)
                arcpy.AddField_management(simpTemp, "TSA_NAME", "TEXT", 50)
                with arcpy.da.UpdateCursor(simpTemp, ["TSA_NUMBER", "TSA_NAME"]) as cursor:
                    for row in cursor:
                        row[0] = tsa_num
                        row[1] = tsa_nam
                        cursor.updateRow(row)
                #---------------------------------------------------------------------
                #--Rename and Cleanup Temp Datasets
                #---------------------------------------------------------------------
                finData = os.path.join(outWrk, 'vri_tsa_{0}'.format(tsa_num))
                arcpy.Rename_management(simpTemp, finData)
                DeleteExists(simpTemp)
                DeleteExists(simpTempPnt)
                DeleteExists(clipTemp)
                DeleteExists(elimTemp)
                WriteLog(kennyloggins, '----Done Processing TSA-{0}\n'.format(tsa_num), True)
                WriteLog(kennyloggins, '----Output Data is {1} TSA-{0}\n'.format(tsa_num, finData), True)
                WriteLog(kennyloggins, '---------------------------------------------------------------------------\n'.format(tsa_num), True)
            except Exception, e:
                WriteLog(kennyloggins, '*****Error Processing TSA-{0}\n'.format(tsa_num), True)
                WriteLog(kennyloggins, '*****Error Message:\n {0}\n'.format(str(e)), True)
                WriteLog(kennyloggins, '---------------------------------------------------------------------------\n'.format(tsa_num), True)
#-----------------------------------------------
if __name__ == '__main__':
    #--Setup Environment parameters
    arcpy.env.parallelProcessingFactor = "100%"
    arcpy.env.overwriteOutput = True
    arcpy.env.outputMFlag = "Disabled"
    #--Start a log file
    kennyloggins = CreateLogFile(True)
    #--Create the Output GDB
    outWrk = CreateTempDB(wrk)
    #CalcOIDColumn(srcVRI)
    #ProcessByTSA(outWrk)
    ProcessByTSA(outWrk, tsaExcl="'13', '26', '27', '01', '03', '04', '07'")
    #ProcessByTSA(outWrk, tsaExcl="'04', '26'")
    #GetAreaField(r'\\spatialfiles2.bcgov\archive\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl\VRI_by_TSA.gdb\Data\vri_tsa_05_01Clip')
    #-----------------------------------------------------------
    #-Close the Log File
    #-----------------------------------------------------------
    kennyloggins.close()

