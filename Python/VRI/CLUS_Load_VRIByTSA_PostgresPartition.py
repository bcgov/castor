#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'''
Script for loading VRI data by TSA into Postgres using the GDAL Python API

Mike Fowler
Spatial Data Analyst
January 2019
'''
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--Imports
import datetime
import sys
import os
import shutil
import getpass
#import arcpy as gp
from osgeo import ogr
from osgeo import gdal
import psycopg2

#--Globals
global kennyloggins

dirLogFile = os.path.dirname(sys.argv[0])
sLogPrefix = "CLUS_LoadVRI_By_TSA_Postgres"


def send_email(user, pwd, recipient, subject, body):
    import smtplib

    FROM = user
    TO = recipient if isinstance(recipient, list) else [recipient]
    SUBJECT = subject
    TEXT = body

    # Prepare actual message
    message = """From: %s\nTo: %s\nSubject: %s\n\n%s
    """ % (FROM, ", ".join(TO), SUBJECT, TEXT)
    try:
        #server = smtplib.SMTP("smtp.gmail.com", 587)
        server = smtplib.SMTP_SSL("smtp.gmail.com", 465)
        server.ehlo()
        #server.starttls()
        server.login(user, pwd)
        server.sendmail(FROM, TO, message)
        server.close()
        WriteLog(kennyloggins, 'Successfully sent the mail')
    except Exception as e:
        WriteLog(kennyloggins, "****Failed to send mail****")
def DeleteExists(data):
    if arcpy.Exists(data):
        arcpy.Delete_management(data)
        return True
    else:
        return False
def CreateLogFile(db, bMsg=False):
    currLog = os.path.join(dirLogFile, sLogPrefix + datetime.datetime.now().strftime("%Y%m%d_%H%M%S.log"))
    fLog = open(currLog, 'w')
    lstLog = []
    lstLog.append("------------------------------------------------------------------\n")
    lstLog.append("Log file for CLUS Load VRIByTSA Postgres Partition\n")
    lstLog.append("Date:{0} \n".format(datetime.datetime.now().strftime("%B %d, %Y - %H%M")))
    lstLog.append("User:{}\n".format(getpass.getuser()))
    lstLog.append("Script:{}\n".format(sys.argv[0]))
    lstLog.append("Output DB:{}\n".format(db))
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
def FieldExists(fc, fld):
    bExists = False
    if fld.upper() in [f.name.upper() for f in arcpy.ListFields(fc)]:
        bExists = True
    return bExists
def GetAreaField(fc):
    for fld in gp.ListFields(fc):
        if fld.name.upper() in ['GEOMETRY_AREA', 'FEATURE_AREA', 'SHAPE_AREA']:
            return fld.name
def GetFGDBLayers(fgdb, wc, retType='NAME'):
    #--type can be NAME OR LAYER. Name will return the name of the layer, LAYER will return layer objects.
    #--The function can accept
    if type(fgdb) is str:
        #print 'DS not provided'
        driver = ogr.GetDriverByName("FileGDB")
        ds = driver.Open(fgdb, 0)
    elif isinstance(fgdb, ogr.DataSource):
        #print 'DS provided'
        ds = fgdb

    lstLayers = []
    for i in range(0, ds.GetLayerCount()):
        lyrObj = ds.GetLayerByIndex(i)
        lyr = lyrObj.GetName()
        if lyr.upper().find(wc.upper(), 0)>=0:
            if retType == 'NAME':
                lstLayers.append(lyr)
            elif retType== 'LAYER':
                lstLayers.append(lyrObj)
    return lstLayers
def CreatePostLoadIndexes(dbConnStr, tab, idFld, geomFld=None, geom=False):
    try:
        #dbConnStr = "host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"
        conn = None
        cur = None
        conn = psycopg2.connect(dbConnStr)
        cur = conn.cursor()
        cmd = 'DROP INDEX IF EXISTS IDX_{0}_{1};'.format(tab, idFld)
        cur.execute(cmd)
        cmd = 'CREATE INDEX IDX_{0}_{1} ON {0} ({1});'.format(tab, idFld)
        cur.execute(cmd)
        if geom:
            cmd = 'DROP INDEX IF EXISTS IDX_{0}_{1};'.format(tab, geomFld)
            cur.execute(cmd)
            cmd = 'CREATE INDEX IDX_{0}_{1} ON {0} USING GIST({1});'.format(tab, geomFld)
            cur.execute(cmd)
        conn.commit()
        #--Cleanup
        cur.close()
        conn.close()
        return 'Done-Success'
    except Exception, e:
        if not cur is None:
            cur.close()
        if not conn is None:
            conn.close()
        return 'Fail-{0}'.format(str(e))

def VacuumDB(dbConnStr, analyze=True, tab=''):
    try:
        #dbConnStr = "host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"
        conn = psycopg2.connect(dbConnStr)
        cur = conn.cursor()
        if analyze:
            cmd = 'VACUUM ANALYZE {0};'.format(tab)
        else:
            cmd = 'VACUUM {0};'.format(tab)
        isoLevel = conn.isolation_level
        conn.set_isolation_level(0)
        cur.execute(cmd)
        conn.set_isolation_level(isoLevel)
        #conn.commit()
        #--Cleanup
        cur.close()
        conn.close()
        return 'Done-Success'
    except Exception, e:
        if not cur is None:
            cur.close()
        if not conn is None:
            conn.close()
        return 'Fail-{0}'.format(str(e))

def CreateMetadataTable(dbConnStr):
    try:
        #dbConnStr = "host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"
        conn = psycopg2.connect(dbConnStr)
        cur = conn.cursor()
        cur.execute('DROP TABLE IF EXISTS vri_tsa_process_metadata CASCADE;')
        cur.execute('CREATE TABLE VRI_TSA_PROCESS_METADATA (ID SERIAL PRIMARY KEY, TSA_NUMBER CHAR(2), TSA_NAME VARCHAR(50), POLY_COUNT_ORIG INTEGER, POLY_COUNT_ELIM INTEGER, SIMPLIFY_TOLERANCE INTEGER, VERTICES_PRE_SIMPLIFY INTEGER, VERTICES_POST_SIMPLIFY INTEGER, VERTICES_REDUCE_PCT REAL);')
        conn.commit()
        #--Cleanup
        cur.close()
        conn.close()
        return 'Done-Success'
    except Exception, e:
        if not cur is None:
            cur.close()
        if not conn is None:
            conn.close()
        return 'Fail-{0}'.format(str(e))

def CreateAllTable(dbConnStr):
    try:
        #dbConnStr = "host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"
        conn = psycopg2.connect(dbConnStr)
        cur = conn.cursor()
        cur.execute('DROP TABLE IF EXISTS vri_tsa_all CASCADE;')
        cur.execute('CREATE TABLE VRI_TSA_ALL (ID SERIAL PRIMARY KEY, FEATURE_ID_WITH_TFL INTEGER, GEOM GEOMETRY(MultiPolygon,3005), TSA_NUMBER CHAR(2), TSA_NAME VARCHAR(50));')
        conn.commit()
        #--Cleanup
        cur.close()
        conn.close()
        return 'Done-Success'
    except Exception, e:
        if not cur is None:
            cur.close()
        if not conn is None:
            conn.close()
        return 'Fail-{0}'.format(str(e))

def CreatePartitionParentTable(dbConnStr):
    try:
        #dbConnStr = "host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"
        conn = psycopg2.connect(dbConnStr)
        cur = conn.cursor()
        cur.execute('DROP TABLE IF EXISTS vri_tsa CASCADE;')
        cur.execute('CREATE TABLE VRI_TSA (ID SERIAL PRIMARY KEY, FEATURE_ID_WITH_TFL INTEGER, GEOM GEOMETRY(MultiPolygon,3005), TSA_NUMBER CHAR(2), TSA_NAME VARCHAR(50));')
        conn.commit()
        #--Cleanup
        cur.close()
        conn.close()
        return 'Done-Success'
    except Exception, e:
        if not cur is None:
            cur.close()
        if not conn is None:
            conn.close()
        return 'Fail-{0}'.format(str(e))

def CreatePartitionChildTable(dbConnStr, tsa):
    try:
        #dbConnStr = "host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"
        conn = psycopg2.connect(dbConnStr)
        cur = conn.cursor()
        cur.execute('DROP TABLE IF EXISTS vri_tsa_{0};'.format(tsa))
        cur.execute("CREATE TABLE VRI_TSA_{0} (ID INTEGER DEFAULT nextval('public.vri_tsa_id_seq'::regclass), FEATURE_ID_WITH_TFL INTEGER, GEOM GEOMETRY(MultiPolygon,3005), TSA_NUMBER CHAR(2), TSA_NAME VARCHAR(50)) INHERITS (public.vri_tsa);".format(tsa))
        #--Add Constraint
        cur.execute("ALTER TABLE ONLY VRI_TSA_{0} ADD CONSTRAINT VRI_TSA_{0}_PKEY PRIMARY KEY (ID);".format(tsa))
        cur.execute("ALTER TABLE ONLY VRI_TSA_{0} ADD CONSTRAINT VRI_TSA_{0}_TSA CHECK(TSA_NUMBER = '{0}');".format(tsa))
        #-----------------------
        conn.commit()
        #--Cleanup
        cur.close()
        conn.close()
        return 'Done-Success'
    except Exception, e:
        if not cur is None:
            cur.close()
        if not conn is None:
            conn.close()
        return 'Fail-{0}'.format(str(e))


def Layers_to_PostGIS(gdb, fc, flds=None, outName=None, mode='overwrite', dbConnStr="host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"):
    try:
        srcDS = gdal.OpenEx(gdb, 0)
        dbConnStr = "PG:{0}".format(dbConnStr)
        if flds is None:
            if outName is None:
                ds = gdal.VectorTranslate(dbConnStr, srcDS, format='PostgreSQL', accessMode = mode, layers=fc, selectFields=flds)
            else:
                ds = gdal.VectorTranslate(dbConnStr, srcDS, format='PostgreSQL', layerName=outName, accessMode = mode, layers=fc, selectFields=flds)
        else:
            if outName is None:
                ds = gdal.VectorTranslate(dbConnStr, srcDS, format='PostgreSQL', accessMode = mode, layers=fc, selectFields=flds)
            else:
                ds = gdal.VectorTranslate(dbConnStr, srcDS, format='PostgreSQL', layerName=outName, accessMode = mode, layers=fc, selectFields=flds)
        return 'Done'
    except Exception, e:
        return 'Error running gdal.VectorTranslate - {0}'.format(str(e))

def GetGDBList(wrk, wc='VRI_BY_TSA'):
    lstGDB = []
    for root, dirs, files in os.walk(wrk, topdown=True):
        for dr in dirs:
            if dr.upper().find(wc.upper(), 0) >= 0:
                fgdb = os.path.join(root, dr)
                lstGDB.append(fgdb)
    return lstGDB
def LoadVRTByTSA(db, wrk, loadVRIByTSA=True, loadMetadata=False, loadVRIAtt=False, loadAll=False, Vac=True):
    if loadVRIAtt:
        #---------------------------------------------------------------------------------------------------
        #--Time to load the VRI_Attributes
        #---------------------------------------------------------------------------------------------------
        gdbAtt = GetGDBList(wrk, 'VRI_TFL_GEOM_ATT')
        WriteLog(kennyloggins, 'Going to load VRI_TFL_GEOM_ATT to VRI_TSA_ATT from {0}\n'.format(gdbAtt[0]), True)
        res = Layers_to_PostGIS(gdbAtt[0], ['VRI_TFL_GEOM_ATT'], None, 'VRI_TSA_ATT', 'overwrite', dbConnStr=db)
        WriteLog(kennyloggins, '{0}\n'.format(res), True)
        WriteLog(kennyloggins, 'Creating Index on VRI_TSA_ATT\n', True)
        res = CreatePostLoadIndexes(db, 'VRI_TSA_ATT', 'feature_id_with_tfl', None, False)
        WriteLog(kennyloggins, '{0}\n'.format(res), True)

    #--Get List of GDB's in the Workspace
    lstGDB = GetGDBList(wrk, 'VRI_BY_TSA')
    flds =  ['FEATURE_ID_WITH_TFL', 'TSA_NUMBER', 'TSA_NAME']
    idx = 1
    bCreateParent = True
    lyrIdx = 1
    for gdb in lstGDB:
        #WriteLog(kennyloggins, '{0}\n'.format(gdb), True)
        if loadMetadata:
            #---------------------------------------------------------------------------------------------------
            #--Add the PROCESS_METADATA information to POSTGIS
            #---------------------------------------------------------------------------------------------------
            WriteLog(kennyloggins, '{0}\n'.format('Appending the PROCESS_METADATA data....\n'), True)
            if idx == 1:
                res = CreateMetadataTable(db)
            res = Layers_to_PostGIS(gdb, ['PROCESS_METADATA'], None, 'vri_tsa_process_metadata', 'append', dbConnStr=db)
            idx += 1
            WriteLog(kennyloggins, 'Load PROCESS_METADATA for {0} result:{1}\n'.format(gdb, res), True)
        #---------------------------------------------------------------------------------------------------
        #--Loading the vri_tsa data into Partition Child Tables
        #---------------------------------------------------------------------------------------------------
        if loadVRIByTSA:
            if bCreateParent:
                WriteLog(kennyloggins, '{0}\n'.format('Creating Parent Partition\n'), True)
                res = CreatePartitionParentTable(db)
                bCreateParent = False
                print res
            #---------------------------------------------------------------------------------------------------
            #--Get Layer list
            #---------------------------------------------------------------------------------------------------
            lyrs = GetFGDBLayers(gdb, 'vri_tsa', retType='NAME')
            WriteLog(kennyloggins, '{0}\n'.format('GDB {0} - TSAs {1}'.format(gdb, str(lyrs))), True)
            #---------------------------------------------------------------------------------------------------
            #--Loop through the layers and create child tables
            #---------------------------------------------------------------------------------------------------
            for lyr in lyrs:
                tsa = lyr[len(lyr)-2:len(lyr)]
                WriteLog(kennyloggins, '{0}\n'.format('--Creating Child Partition for TSA {0}'.format(tsa)), True)
                res = CreatePartitionChildTable(db, tsa)
                WriteLog(kennyloggins, '{0}\n'.format(res), True)
            WriteLog(kennyloggins, '{0}\n'.format("Running GDAL Vector Translate to load TSA's-{0}".format(str(lyrs))), True)
            #---------------------------------------------------------------------------------------------------
            #--Now load the layers into the child tables in a bulk VectorTranslate Call
            #---------------------------------------------------------------------------------------------------
            Layers_to_PostGIS(gdb, lyrs, flds, mode='append',  dbConnStr=db)
            #---------------------------------------------------------------------------------------------------
            #--Create Indexes on the Tables
            #---------------------------------------------------------------------------------------------------
            for lyr in lyrs:
                WriteLog(kennyloggins, '{0}\n'.format('Creating indexes for {0}'.format(lyr)), True)
                res = CreatePostLoadIndexes(db, lyr, 'feature_id_with_tfl', 'geom', True)
                WriteLog(kennyloggins, '{0}\n'.format(res), True)
        #---------------------------------------------------------------------------------------------------
        #--Need to create a single output table (no partitioning) to compare performance results
        #---------------------------------------------------------------------------------------------------
        if loadAll:
            tsaAllName = 'VRI_TSA_ALL'
            for lyr in lyrs:
                WriteLog(kennyloggins, '{0}\n'.format('Loading {0} into single output table - {1}'.format(lyr, tsaAllName)), True)
                if lyrIdx == 1:
                    CreateAllTable(db)
                res = Layers_to_PostGIS(gdb, [lyr], flds, tsaAllName, 'append',  dbConnStr=db)
                WriteLog(kennyloggins, '{0}\n'.format(res), True)
                lyrIdx += 1
            WriteLog(kennyloggins, '{0}\n'.format('Creating indexes for {0}'.format(lyr)), True)
            res = CreatePostLoadIndexes(db, tsaAllName, 'feature_id_with_tfl', 'geom', True)
            WriteLog(kennyloggins, '{0}\n'.format(res), True)
    if Vac:
        #---------------------------------------------------------------------------------------------------
        #--Vacuum and Analyze the Database
        #---------------------------------------------------------------------------------------------------
        WriteLog(kennyloggins, '{0}\n'.format('Vacuuming and Analyzing the Database'), True)
        res = VacuumDB(db, True)
        WriteLog(kennyloggins, '{0}\n'.format(res), True)
    return True
if __name__ == '__main__':
    #db = "host='localhost' dbname='postgres' port='5432' user='postgres' password='postgres'"
    db = "host='DC052586.idir.bcgov' dbname='clus' port='5432' user='postgres' password='postgres' keepalives=1 connect_timeout=20 keepalives_idle=10"
    #db = "host='DC052586.idir.bcgov' dbname='clus' port='5432' user='postgres' password='postgres'"
    wrk = r"X:\FOR\VIC\HTS\ANA\PROJECTS\CLUS\Data\vri_tfl"
    #--Create the log file
    kennyloggins = CreateLogFile(db, True)
    try:
        #LoadVRTByTSA(db, wrk, loadVRIByTSA=True, loadMetadata=True, loadVRIAtt=True, loadAll=True, Vac=True)
        #LoadVRTByTSA(db, wrk, loadVRIByTSA=True, loadMetadata=True, loadVRIAtt=False, loadAll=True, Vac=True)
        #LoadVRTByTSA(db, wrk, loadVRIByTSA=True, loadMetadata=False, loadVRIAtt=True, loadAll=False, Vac=True)
        LoadVRTByTSA(db, wrk, loadVRIByTSA=False, loadMetadata=False, loadVRIAtt=False, loadAll=False, Vac=True)

##        msg = 'Script has completed for Database - {0}'.format(db)
##        print 'Sending Email'
##        send_email('mfowler.bc@gmail.com', '******', 'Mike.Fowler@gov.bc.ca', 'Load Partition Script Complete', msg)
        #------------------Done
        WriteLog(kennyloggins, '-----------------------------------------------------------\n', True)
        WriteLog(kennyloggins, 'Script Complete--------------------------------------------\n', True)
        WriteLog(kennyloggins, '-----------------------------------------------------------\n', True)
        kennyloggins.close()
    except Exception, e:
##        msg = 'Script for DB ({0}) has an error: \n {1}'.format(db, str(e))
##        print 'Sending Email'
##        send_email('mfowler.bc@gmail.com', '*****', 'Mike.Fowler@gov.bc.ca', '**Load Partition Script Error**', msg)

        WriteLog(kennyloggins, '-----------------------------------------------------------\n', True)
        WriteLog(kennyloggins, 'Error in the Script.\n', True)
        WriteLog(kennyloggins, 'Error Message:\n{0}\n'.format(str(e)), True)
        WriteLog(kennyloggins, '-----------------------------------------------------------\n', True)
        WriteLog(kennyloggins, str(e), True)
        kennyloggins.close()







