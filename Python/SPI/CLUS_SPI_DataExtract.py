#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'''
Script for processing SPI Data for use in CLUS Caribou Project

Mike Fowler
Spatial Data Analyst
June 2018
'''
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--Imports
import arcpy
import os
#--Globals
global cboo, wmu, tsa, connInstance
srcCboo = "WHSE_WILDLIFE_INVENTORY.GCPB_CARIBOU_POPULATION_SP"
srcWMU = "WHSE_WILDLIFE_MANAGEMENT.WAA_WILDLIFE_MGMT_UNITS_SVW"
srcTSA = "WHSE_ADMIN_BOUNDARIES.FADM_TSA"
connInstance = r'bcgw.bcgov/idwprod1.bcgov'

wrk = os.environ['TEMP']
#wrk = r"\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI"

def BufferFC(wrk, src, dist):
    outFC = os.path.join(wrk, "zzTmpBuff")
    DeleteExists(outFC)
    arcpy.Buffer_analysis(src, outFC, dist)
    return outFC

def SpatialJoin(wrk, outName, fcSrc, fcJoin, spatrel="INTERSECT", searchrad="1 Meters"):
    outFC = os.path.join(wrk, outName)
    DeleteExists(outFC)
    arcpy.SpatialJoin_analysis(fcSrc, fcJoin, outFC, join_operation="JOIN_ONE_TO_ONE", join_type="KEEP_ALL", match_option=spatrel, search_radius=searchrad)

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

def CreateTempDB(wrk, sType='FILE', name='SPI_DataAnalysis'):
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

def Boo_TSA_Overlay_StageData(outWrk, dbUser, dbPass):
    tmpName = '{0}.gdb'.format("Boo_TSA_Overlay_StageData")
    tmpWrk = os.path.join(outWrk, tmpName)
    if not arcpy.Exists(tmpWrk):
        arcpy.CreateFileGDB_management(outWrk, tmpName)
    if not arcpy.Exists(os.path.join(outWrk, tmpName, "Data")):
        arcpy.CreateFeatureDataset_management(tmpWrk, "Data", arcpy.SpatialReference(3005))

    outWrk = os.path.join(tmpWrk, "Data")

    #--Get a BCGW Connection
    bcgwconn = CreateBCGWConn(dbUser, dbPass)
    #--Create the TSA Layer
    wc = 'TSB_NUMBER IS NULL AND RETIREMENT_DATE IS NULL'
    lyrTSA = r'in_memory\lyrTSA'
    print 'Creating layer {0}....'.format(lyrTSA)
    arcpy.MakeFeatureLayer_management(os.path.join(bcgwconn, srcTSA), lyrTSA, wc)
    fcTSAOut = os.path.join(outWrk, "TSA")
    DeleteExists(fcTSAOut)
    arcpy.CopyFeatures_management(lyrTSA, fcTSAOut)

    print 'Creating layer {0}....'.format("Caribou Buffer")
    #--Create the Boo Layer
    fcBoo25 = BufferBoo(outWrk, os.path.join(bcgwconn, srcCboo))

    print 'Data staging complete....'
    return ([outWrk,fcBoo25,fcTSAOut])

def Boo_TSA_Overlay(wrk, tsa, boo):
    arcpy.env.overwriteOutput = True
    print 'Establishing local Workspace....'
    spatwrk = CreateTempDB(wrk)
    print 'Creating BCGW connection....'
    bcgwconn = CreateBCGWConn(dbUser, dbPass)

    #wc = 'TSB_NUMBER IS NOT NULL AND RETIREMENT_DATE IS NULL'
    wc = 'TSB_NUMBER IS NULL AND RETIREMENT_DATE IS NULL'
    lyrTSA = r'in_memory\lyrTSA'
    print 'Creating layer {0}....'.format(lyrTSA)
    fcTSADissOut = os.path.join(spatwrk, "TSADiss")
    fcTSADiss = r"in_memory\TSADiss"

    arcpy.MakeFeatureLayer_management(os.path.join(bcgwconn, tsa), lyrTSA, wc)

    fcTSASelect = os.path.join(spatwrk, 'TSASelect')
    arcpy.CopyFeatures_management(lyrTSA, fcTSASelect)

    DeleteExists(fcTSADiss)
    print 'Dissolving on TSA Number....'
    arcpy.env.extent = fcTSASelect
    arcpy.Dissolve_management(fcTSASelect, fcTSADiss, ['TSA_NUMBER','TSA_NUMBER_DESCRIPTION'], multi_part='MULTI_PART')
    #dissOut = DissolveFC(fcTSASelect, fcTSADiss, ['TSA_NUMBER','TSA_NUMBER_DESCRIPTION'])
    #DeleteExists(fcTSADissOut)
    #arcpy.CopyFeatures_management(fcTSADiss, fcTSADissOut)
    arcpy.Delete_management(lyrTSA)


    outUnion = os.path.join(spatwrk, "TSA_Herd_Union")

    lyrBoo = "lyrBoo"
    arcpy.MakeFeatureLayer_management(os.path.join(bcgwconn, boo), lyrBoo, 'HERD_NAME IS NOT NULL')
    tmpBoo = os.path.join(spatwrk, 'tmpBoo')
    arcpy.CopyFeatures_management(lyrBoo, tmpBoo)
    boo25 = BufferBoo(spatwrk, tmpBoo)

    print 'Peforming a Union....'
    arcpy.Union_analysis([fcTSADiss, boo25], outUnion, cluster_tolerance=1)

def DissolveFC(inFC, outFC, fields, delLst=None, i=1):
    tmpFC = "{0}_{1}".format(outFC, i)
    DeleteExists(tmpFC)
    arcpy.Dissolve_management(inFC, tmpFC, fields, multi_part='MULTI_PART', unsplit_lines="DISSOLVE_LINES")

    tmpTab = os.path.join(arcpy.env.scratchGDB, "zzFreq")
    DeleteExists(tmpTab)
    arcpy.Frequency_analysis(tmpFC, tmpTab, fields)
    freq = 1
    try:
        freq = int(next(arcpy.da.SearchCursor(tmpTab, ['FREQUENCY'], "FREQUENCY > 1"))[0])
    except:
        freq = 1
    if freq > 1:
        print 'We have a tiled output....'
        if i > 5:
            'We have run more than 5 times, we will stop and return tiled output....'
            for tmp in delLst:
                print 'Deleting temp data....{0}'.format(tmp)
                DeleteExists(tmp)
            print 'Renaming temp data to final output....'
            arcpy.Rename_management(tmpFC, outFC)
            return outFC
        else:
            'Going to run dissolve again....{0}:{1}'.format(tmpFC, outFC)
            if not delLst is None:
                delLst.append(tmpFC)
            else:
                delLst = [tmpFC]
            i += 1
            DissolveFC(tmpFC, outFC, fields, delLst, i)
    else:
        if not delLst is None:
            for tmp in delLst:
                print 'Deleting temp data....{0}'.format(tmp)
                DeleteExists(tmp)
        print 'Renaming temp data to final output....'
        arcpy.Rename_management(tmpFC, outFC)
        return outFC

def BufferBoo(wrk, srcboofc, dist=25000):
    tmpFC = os.path.join(wrk, 'CARIBOU_HERDS_25K')
    DeleteExists(tmpFC)
    arcpy.CopyFeatures_management(srcboofc, tmpFC)
    fldLst = ['SHAPE@']
    for fld in arcpy.ListFields(tmpFC):
        fldLst.append(fld.name)
    lstUpdate = []
    with arcpy.da.SearchCursor(tmpFC, fldLst) as cursor:
        for row in cursor:
            h25k = "{0} - 25k".format(row[cursor.fields.index("HERD_NAME")])
            cID = row[cursor.fields.index("CARIBOU_POPULATION_ID")] + 250000
            h25kgeom = row[0].buffer(dist)
            rowUpd = list(row)
            rowUpd[0] = h25kgeom
            rowUpd[cursor.fields.index("CARIBOU_POPULATION_ID")] = cID
            rowUpd[cursor.fields.index("HERD_NAME")] = h25k
            rowUpd[cursor.fields.index("CARIBOU_TAG")] = h25k
            lstUpdate.append(rowUpd)



    insCur = arcpy.da.InsertCursor(tmpFC, fldLst)
    for row in lstUpdate:
        insCur.insertRow(tuple(row))
    del insCur

    return tmpFC
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


def CalculateDataCount_Survey(db, tabTarget, tabColumn):

    #--Pyodbc Checking for Table
    for row in cursor.tables():
        print(row.table_name)

    # Does table 'x' exist?
    if cursor.tables(table='x').fetchone():
        print('yes it does')

    #--Pyodbc Checking for Column
    for row in cursor.columns(table='x'):
        print(row.column_name)
    pass

def DeleteExists(data):
    if arcpy.Exists(data):
        arcpy.Delete_management(data)
        return True
    else:
        return False


#-----------------------------------------------
if __name__ == '__main__':
    #outWrk = sys.argv[1]
    #dbUser = sys.argv[2]
    #dbPass = sys.argv[3]
    dbUser = 'mwfowler'
    dbPass = 'Vedder03'
    #Boo_TSA_Overlay_StageData(r"\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI\Analysis", dbUser, dbPass)
    Boo_TSA_Overlay(wrk, srcTSA, srcCboo)

    #ProcessSPI(wrk, dbUser, dbPass)

