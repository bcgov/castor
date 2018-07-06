#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'''
Script for generating Buffers of Caribou Herd areas within existing Herd Buffer Dataset


Mike Fowler
GIS Analyst
July 2018
'''
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--Imports
import arcpy
import os
#--Globals
global cboo, connInstance
srcCboo = "WHSE_WILDLIFE_INVENTORY.GCPB_CARIBOU_POPULATION_SP"
connInstance = r'bcgw.bcgov/idwprod1.bcgov'

wrk = os.environ['TEMP']
#wrk = r"\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI"

def BufferFC(wrk, src, dist):
    outFC = os.path.join(wrk, "zzTmpBuff")
    DeleteExists(outFC)
    arcpy.Buffer_analysis(src, outFC, dist)
    return outFC

def CreateBCGWConn(dbUser, dbPass):
    connBCGW = os.path.join(os.path.dirname(arcpy.env.scratchGDB), 'BooBuffer.sde')
    if os.path.isfile(connBCGW):
        os.remove(connBCGW)
    try:
        arcpy.CreateDatabaseConnection_management(os.path.dirname(connBCGW), os.path.basename(connBCGW), 'ORACLE', connInstance, username=dbUser, password=dbPass)
    except:
        print 'Error Creating BCGW connection....'
        connBCGW = None
    return connBCGW

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
    spattabwrk = CreateTempDB(wrk, 'PERSONAL', 'SPI_DataAnalysis_Spatial')

    bcgwconn = CreateBCGWConn(dbUser, dbPass)


    boo25k = BufferBoo(spatwrk, os.path.join(bcgwconn, srcCboo))
    srcs = []
    #srcs.append(['WHSE_WILDLIFE_INVENTORY.SPI_INCID_OBS_ALL_SP', "SPI_INCID", "SPECIES_CODE IN ('M-RATA', 'M-ALAM', 'M-CALU')", ['INCIDENTAL_OBSERVATION_ID']])
    srcs.append(['WHSE_WILDLIFE_INVENTORY.SPI_SURVEY_OBS_ALL_SP', "SPI_SURVEY", "SPECIES_CODE IN ('M-RATA', 'M-ALAM', 'M-CALU')", ['SURVEY_OBSERVATION_ID']])
    srcs.append(['WHSE_WILDLIFE_INVENTORY.SPI_TELEMETRY_OBS_ALL_SP', "SPI_TELEM", "SPECIES_CODE IN ('M-RATA', 'M-ALAM', 'M-CALU')", ['TELEMETRY_OBSERVATION_ID']])
    sjs = []
    sjs.append([boo25k, "CBOO_25KM", None])
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


#-----------------------------------------------
if __name__ == '__main__':
    dbUser = 'mwfowler'
    dbPass = 'Vedder03'
    ProcessSPI(wrk, dbUser, dbPass)

