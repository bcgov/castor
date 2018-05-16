#-------------------------------------------------------------------------------
#--Imports and Globals
#-------------------------------------------------------------------------------
import os
import sys
import arcpy as gp
import pyodbc

CRPHome = r'\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS'

BCGWmdpath = os.path.join(CRPHome, r'Scripts\Python\BCGWMetadata')
MDmdb = os.path.join(CRPHome, r"Scripts\Python\BCGWMetadata\BCGW_Metadata.accdb")

sys.path.append(BCGWmdpath)
import BCGW_Metadata as md
#-------------------------------------------------------------------------------
#--Functions
#-------------------------------------------------------------------------------
def Load_TSB_Access(mdb, dataName, dctTSB):
    conn = Connect_Access(mdb)
    cursor = conn.cursor()
    curr_date = md.pq(str(datetime.date.today()))
    #---------------------------------------------------------------------------
    #---Insert Operation for the Dataset
    #---------------------------------------------------------------------------
    dataID = GetDatasetID(conn, dataName)
    for fid, tsb in dctTSB.items():
        rslt = Check_TSB_Exists(conn, tsb[0])
        if rslt[0]:
            #--If the Contact already exists in the DB, we update
            #print 'Contact - Update' + cnt.name
            cntID = rslt[1]
            sql = u"UPDATE TSB SET UPDATE_DATE = {0}, FEATURE_ID = {1}, TSA = {2}, TSB = {3}  WHERE TSB_ID = {4}".format(
            curr_date, md.pq(tsb[0]), md.pq(tsb[1]), md.pq(tsb[2]), rslt[1]
            )
            cursor.execute(sql)
            cursor.commit()
            #--It's possible to have an existing contact that is not linked to the current dataset.  Need to update the junction table to link them
            if not md.Check_JCT_Exists(conn, 'JCT_DATASETS_TSB', 'FK_DATASET', dataID, 'FK_TSB', rslt[1]):
                sql = u"INSERT INTO JCT_DATASETS_TSB(FK_DATASET, FK_TSB) VALUES ({0}, {1})".format(
                dataID, rslt[1]
                )
            cursor.execute(sql)
            cursor.commit()
        else:
            sql = u"INSERT INTO TSB(UPDATE_DATE, FEATURE_ID, TSA, TSB) VALUES ({0}, {1}, {2}, {3})".format(
            curr_date, md.pq(tsb[0]), md.pq(tsb[1]), md.pq(tsb[2])
            )
            cursor.execute(sql)
            cursor.commit()
            row = cursor.execute("SELECT @@IDENTITY").fetchone()
            tsbID = row[0]
            sql = u"INSERT INTO JCT_DATASETS_TSB(FK_DATASET, FK_TSB) VALUES ({0}, {1})".format(
            dataID, tsbID
            )
            cursor.execute(sql)
            cursor.commit()
    conn.close()
def Connect_Access(path):
    conn_str =  r"DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=" + path + ";"
    conn = pyodbc.connect(conn_str)
    return conn

def GetDatasetID(conn, dataName):
    dataID = -99
    sql = "SELECT DATASET_ID FROM DATASETS WHERE OBJECT_NAME_FULL = " + md.pq(dataName)
    cursor = conn.cursor()
    print sql
    cursor.execute(sql)
    row = cursor.fetchone()
    if row:
        dataID = row[0]
    return dataID

def Check_TSB_Exists(conn, featid):
    bExists = False
    retID = -99
    sql = "SELECT TSB_ID FROM TSB WHERE FEATURE_ID = {0}".format(md.pq(featid))
    cursor = conn.cursor()
    cursor.execute(sql)
    row = cursor.fetchone()
    if row:
            bExists = True
            retID = row[0]
    return [bExists, retID]

def Check_Exists(conn, dataName, type):
    bExists = False
    retID = -99
    if type == 'DATASET':
        sql = "SELECT DATASET_ID FROM DATASETS WHERE OBJECT_NAME_FULL = " + md.pq(dataName)
    elif type =='TSB':
        sql = "SELECT TSB_ID FROM TSB WHERE TSB = " + md.pq(dataName)
    cursor = conn.cursor()
    cursor.execute(sql)
    row = cursor.fetchone()
    if row:
            bExists = True
            retID = row[0]
    return [bExists, retID]

def Convert_To_WGS(inSRCode, pointX, pointY):
    import ogr, osr
    # Spatial Reference System
    #inputEPSG = 3857
    outputSRCode = 4326 #--WGS84

    # create a geometry from coordinates
    point = ogr.Geometry(ogr.wkbPoint)
    point.AddPoint(pointX, pointY)

    # create coordinate transformation
    inSpatialRef = osr.SpatialReference()
    inSpatialRef.ImportFromEPSG(inSRCode)

    outSpatialRef = osr.SpatialReference()
    outSpatialRef.ImportFromEPSG(outputSRCode)

    coordTransform = osr.CoordinateTransformation(inSpatialRef, outSpatialRef)

    # transform point
    point.Transform(coordTransform)

    # print point in EPSG 4326
    #print point.GetX(), point.GetY()
    return point

def CreateBCGWConn(dbUser, dbPass, dbInstance='Prod'):
    connBCGW = os.path.join(os.path.dirname(gp.env.scratchGDB), 'BCGW_Metadata_TSBExtract_{0}_temp.sde'.format(dbInstance))
    if os.path.isfile(connBCGW):
        os.remove(connBCGW)
    print "Creating new BCGW-{0} Connection File...".format(dbInstance)
    if dbInstance == 'Prod':
        connInstance = r'bcgw.bcgov/idwprod1.bcgov'
    elif dbInstance == 'Test':
        connInstance = r'bcgw-i.bcgov/idwtest1.bcgov'
    elif dbInstance == 'Delivery':
        connInstance = r'bcgw-i.bcgov/idwdlvr1.bcgov'
    try:
        gp.CreateDatabaseConnection_management(os.path.dirname(connBCGW), os.path.basename(connBCGW), 'ORACLE', connInstance, username=dbUser, password=dbPass)
    except:
        print 'Error Creating BCGW-{0} connection....'.format(dbInstance)
        connBCGW = None
    return connBCGW

def ProcessTSB(dataSRC, dataName, dbUser, dbPass):
    dctTSB = {}
    gp.env.overwriteOutput = True
    #--Get Production Connection for TSB Data
    tsb = 'WHSE_ADMIN_BOUNDARIES.FADM_TSA'
    connProd = CreateBCGWConn('mwfowler', 'vedder00', 'Prod')
    #--If a BCGW Data Source, get another connection if not Production
    if dataSRC[0:4] == "BCGW":
        dbInstance = dataSRC.split("-")[1]
        if not dbInstance == 'Prod':
            dataSRC = CreateBCGWConn(dbUser, dbPass, dbInstance)
        else:
            dataSRC = connProd

    dataSelect = os.path.join(dataSRC, dataName)
    lyrTSA = "lyrTSA"
    #--Make a Layer of the TSA then Select features from it based on Input Layer(Target)
    gp.MakeFeatureLayer_management(os.path.join(connProd, tsb), lyrTSA)

    desc = gp.Describe(os.path.join(dataSRC, dataName))
    if hasattr(desc, 'extent'):
        #---------------------------------------------------------------------------
        #Gotta do some work to deal with large, complex data.  ESRI can't handle it
        #---------------------------------------------------------------------------
        ext = desc.extent
        featCount = int(gp.GetCount_management(dataSelect).getOutput(0))
        if hasattr(desc, 'spatialReference'):
            poly = gp.Polygon(gp.Array([arcpy.Point(*coords) for coords in [[ext.XMin, ext.YMin], [ext.XMin, ext.YMax], [ext.XMax, ext.YMax], [ext.XMax, ext.YMin]]]))
        else:
            poly = gp.Polygon(gp.Array([arcpy.Point(*coords) for coords in [[ext.XMin, ext.YMin], [ext.XMin, ext.YMax], [ext.XMax, ext.YMax], [ext.XMax, ext.YMin]]]), desc.spatialReference)
        #print poly.area/10000
        #print featCount
        #----------------------------------------------------------------------------------------------------------------
        #--If the extent area of the Source is >= 100,000,000 ha (half of province roughly) or over 25,000 feature count
        #--These bounds taken from the CEF Integrated Roads dataset.  Used as a proxy for Provincial Dataset extent to limit processing provinical scale
        #LL:-134.877431771 x, 47.9184080124 y
        #UR:-110.429081044 x, 59.5720911188 y
        #----------------------------------------------------------------------------------------------------------------
        pntLL = Convert_To_WGS(desc.spatialReference.PCSCode, ext.XMin, ext.YMin)
        pntUR = Convert_To_WGS(desc.spatialReference.PCSCode, ext.XMax, ext.YMax)
        #print "LL:{0} x, {1} y".format(str(pntLL.GetX()), str(pntLL.GetY()))
        #print "UR:{0} x, {1} y".format(str(pntUR.GetX()), str(pntUR.GetY()))
        if pntLL.GetX() <= -134.8 and pntLL.GetY() <= 48.0 and pntUR.GetX() >= -110.5 and pntUR.GetY() >= 59.5:
            print 'Processing a Provincial Scope Dataset....'
            with gp.da.SearchCursor(lyrTSA,["FEATURE_ID", "TSA_NUMBER", "TSB_NUMBER"]) as cursor:
                for row in cursor:
                    #print row
                    dctTSB[row[0]]= [row[0], str(row[1]), str(row[2])]
        elif poly.area/10000 >= 100000000 or featCount > 25000:
            print 'Processing a large dataset.  Either half province area or > 25,0000 records....'
            #---------------------------------------------------------------------
            #--We will select TSA features by selecting by each TSB
            #---------------------------------------------------------------------
            with gp.da.SearchCursor(lyrTSA,["SHAPE@", "FEATURE_ID", "TSA_NUMBER", "TSB_NUMBER"]) as cursor:
                for row in cursor:
                    tsb = row[0]
                    gp.env.extent = tsb.extent
                    lyrSelect = "lyrSelect"
                    gp.MakeFeatureLayer_management(dataSelect, lyrSelect)
                    gp.env.XYTolerance = 10
                    gp.SelectLayerByLocation_management(lyrSelect, "INTERSECT", tsb)
                    if gp.GetCount_management(lyrSelect):
                        #print str(row)
                        dctTSB[row[1]]= [row[1], str(row[2]), str(row[3])]
            pass
        else:
            print 'Regular Processing - Selecting TSB\'s that intersect the source data....'
            #---------------------------------------------------------------------
            #--We will select TSA features by the input Dataset in question
            #---------------------------------------------------------------------
            gp.env.XYTolerance = 10
            gp.env.extent = ext
            gp.SelectLayerByLocation_management(lyrTSA, "INTERSECT", dataSelect)
            if gp.GetCount_management(lyrTSA):
                with gp.da.SearchCursor(lyrTSA,["FEATURE_ID", "TSA_NUMBER", "TSB_NUMBER"]) as cursor:
                    for row in cursor:
                        #print row
                        dctTSB[row[0]]= [row[0], str(row[1]), str(row[2])]


    return dctTSB
#-------------------------------------------------------------------------------
#--Main
#-------------------------------------------------------------------------------
if __name__ == '__main__':

##    BCGWfc = "WHSE_WILDLIFE_MANAGEMENT.CRIMS_SEALION_HAULOUTS_POINT"
##    bcgwmd = md.ProcessMetadata(BCGWfc)
##    md.Load_Metadata_Access(MDmdb, bcgwmd)
##    TSB = ProcessTSB(bcgwmd.source, bcgwmd.object_name_full, 'mwfowler', 'vedder00')
##    Load_TSB_Access(MDmdb, bcgwmd.object_name_full, TSB)

##    #intRdsWrk = r'\\spatialfiles.bcgov\work\srm\bcce\shared\data_library\roads\2017\BC_CE_IntegratedRoads_2017_v1_20170214.gdb'
##    intRdsWrk = r"\\bctsdata.bcgov\tsg_root\GIS_Workspace\Mike_F\zzTemp\IntRoads\IntRoads.gdb\Data"
##    #intRds = r'integrated_roads'
##    intRds = "IntRoads"
##    bcgwmd = md.BCGW_Metadata(intRdsWrk, intRds, "Integrated Roads Test", "Roads")
##    TSB = ProcessTSB(intRdsWrk, intRds, 'mwfowler', 'vedder00')
##    Load_TSB_Access(MDmdb, os.path.join(intRdsWrk, intRds), TSB)
##    HalfProvWrk = r"\\bctsdata.bcgov\tsg_root\GIS_Workspace\Mike_F\zzTemp\IntRoads\HalfProv.gdb\Data"
##    HalfProv = r'HalfProv'
##    bcgwmd = md.BCGW_Metadata(HalfProvWrk, HalfProv, "Half Prov", "TEST")
##    TSB = ProcessTSB(bcgwmd.source, bcgwmd.object_name, 'mwfowler', 'vedder00')
##    Load_TSB_Access(r"H:\GIS\CRP\Scripts\Python\BCGWMetadata\BCGW_Metadata.accdb", bcgwmd.object_name_full, TSB)
    #Load_TSB_Access(MDmdb, bcgwmd.object_name_full, TSB)

    #ProcessTSB("BCGW-Prod", "WHSE_WILDLIFE_INVENTORY.SPI_INCID_OBS_ALL_SP")
    #ProcessTSB("BCGW-Prod", "WHSE_WILDLIFE_MANAGEMENT.CRIMS_SEALION_HAULOUTS_POINT")
    #ProcessTSB("BCGW-Prod", "WHSE_WILDLIFE_MANAGEMENT.CRIMS_HERRING_SPAWN")
    pass



