#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'''
    Script for counting survey observations for SPI data.

    Mike Fowler
    GIS Analyst
    July 2018
'''
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--Imports
import arcpy
import os
import pyodbc
import datetime
#--Globals
connInstance = r'bcgw.bcgov/idwprod1.bcgov'
dbName = "SPI_DataAnalysis_Spatial.mdb"
dbWork = os.environ['TEMP']
spattabDB = os.path.join(dbWork, dbName)

#spattabDB = r"W:\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\SPI\Analysis\SPI_DataAnalysis_Spatial.mdb"

def CreateTempDB(wrk, sType='FILE', name='SPI_DataAnalysis'):
    if sType == 'FILE':
        tmpName = '{0}.gdb'.format(name)
        tmpWrk = os.path.join(wrk, tmpName)
        DeleteExists(tmpWrk)
        arcpy.CreateFileGDB_management(wrk, tmpName)
        arcpy.CreateFeatureDataset_management(tmpWrk, "Data", arcpy.SpatialReference(3005))
        return os.path.join(tmpWrk, "Data")
    elif sType == 'PERSONAL':
        tmpName = '{0}.mdb'.format(name)
        tmpWrk = os.path.join(wrk, tmpName)
        DeleteExists(tmpWrk)
        arcpy.CreatePersonalGDB_management(wrk, tmpName)
        return tmpWrk

def ConnectDB(path):
    conn_str =  r"Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=" + path + ";"
    conn = pyodbc.connect(conn_str)
    return conn
def CalculateDataCount_Incidental(db):
    tStart = datetime.datetime.now()
    print "Starting CalculateDataCount_Incidental ({0})....".format(datetime.datetime.now())
    conn = ConnectDB(db)
    tabTarget = "SPI_INCID"
    lstValidSurveyFlds = ['ADULT_FEMALES', 'ADULT_MALES', 'ADULTS_UNCLASSED_SEX', 'JUVENILE_MALES', 'JUVENILE_FEMALES', 'JUVENILES_UNCLASSED_SEX', 'UNCLASSED_LIFE_STAGE_AND_SEX']

    sCountField = "CLUS_COUNT_TOTAL"
    sKeyFld = "INCIDENTAL_OBSERVATION_ID"
    AddCountField(conn, tabTarget, sCountField, "LONG")

    sFlds = sKeyFld + ","
    i = 1
    for fld in lstValidSurveyFlds:
        if i < len(lstValidSurveyFlds):
            sFlds = sFlds + "{0},".format(fld)
        else:
            sFlds = sFlds + "{0}".format(fld)
        i += 1
    sql = "SELECT {0} FROM {1}".format(sFlds, tabTarget)

    print sFlds
    cursor = conn.cursor()
    for row in cursor.execute(sql).fetchall():
        iTotal = 0
        for i in range(0, len(lstValidSurveyFlds)):
            #--------------------------------------------------------------------
            #--Add up the values contained in the above field list
            #--------------------------------------------------------------------
            val = getattr(row, lstValidSurveyFlds[i])
            if not val is None and not val == 'None' and str(val).strip <> '':
                    iTotal = iTotal + float(val)

        #--Update the Total Value by Key value
        print "Updating {0} to {1}....".format(getattr(row, sKeyFld), iTotal)
        sqlUpd = "UPDATE {0} SET {1} = {2} WHERE {3} = {4}".format(tabTarget, sCountField, iTotal, sKeyFld, getattr(row, sKeyFld))
        cursUpd = conn.cursor()
        conn.execute(sqlUpd)
        cursUpd.commit()
        cursUpd.close()

    print "Process Started : {0}".format(tStart)
    print "Process Complete: {0}".format(datetime.datetime.now())

def AddCountField(conn, tb, fld, type):
    curs = conn.cursor()
    curs = conn.execute("SELECT * FROM {0}".format(tb))
    if not fld in[(col.column_name) for col in curs.columns(table=tb)]:
        sql = "ALTER TABLE {0} ADD COLUMN {1} LONG".format(tb, fld)
        #print sql
        curs.execute(sql)
        curs.commit()
        print "Column {0} added....".format(fld)
    return
def CalculateDataCount_Survey(db):
    tStart = datetime.datetime.now()
    print "Starting CalculateDataCount_Survey ({0})....".format(datetime.datetime.now())
    conn = ConnectDB(db)
    tabTarget = "SPI_SURVEY"
    #---------------------------------------------------------------------------
    #-Build a list of valid field values to Count
    #---------------------------------------------------------------------------
    lutValidSurveyFlds = "VALID_FIELD_NAME"
    lutCol = "FIELD_NAME"
    cursor = conn.cursor()
    lstValidSurveyFlds = [(getattr(row, lutCol)) for row in cursor.execute("SELECT * FROM {0}".format(lutValidSurveyFlds))]
    #---------------------------------------------------------------------------
    #-Check for Total Count field in Destination Table
    #---------------------------------------------------------------------------
    sCountField = "CLUS_COUNT_TOTAL"
    sKeyFld = "SURVEY_OBSERVATION_ID"
    AddCountField(conn, tabTarget, sCountField, "LONG")
    #---------------------------------------------------------------------------
    #-Time to Add the Survey Results
    #---------------------------------------------------------------------------
    iRowCount = 0
    sFlds = sKeyFld + ","
    for i in range(1, 32):
        if not i == 31:
            sFlds = sFlds + "FIELD_NAME_{0}, DATA_{0},".format(i)
        else:
            sFlds = sFlds + "FIELD_NAME_{0}, DATA_{0}".format(i)
    sql = "SELECT {0} FROM {1}".format(sFlds, tabTarget)
    #---------------------------------------------------------------------------
    #--Add up the total counts by valid fields.  Need to scan all 31 field values
    #---------------------------------------------------------------------------
    #for row in cursor.execute(sql):
    for row in cursor.execute(sql).fetchall():
        iTotal = 0
        iRowCount += 1
        for i in xrange(1, 32):
            #--------------------------------------------------------------------
            #--If the values in FIELD_NAME_# is valid, we count the number
            #--A 'Valid' value to count is one where the field name is in the
            #--lookup table lutValidSurveyFlds = "VALID_FIELD_NAME"
            #--------------------------------------------------------------------
            fldnm = getattr(row, "FIELD_NAME_{0}".format(i))
            #if getattr(row, "FIELD_NAME_{0}".format(i)) in lstValidSurveyFlds:
            if fldnm in lstValidSurveyFlds:
                val = getattr(row, "DATA_{0}".format(i))
                if not val is None and not val == 'None' and not val.strip() == '':
                    #print val
                    iTotal = iTotal + float(val)

        #--Update the Total Value by Key value
        sqlUpd = "UPDATE {0} SET {1} = {2} WHERE {3} = {4}".format(tabTarget, sCountField, iTotal, sKeyFld, getattr(row, sKeyFld))
        #print "Updating {0} to {1}....Row({2})".format(getattr(row, sKeyFld), iTotal, iRowCount)
        #cursUpd = conn.cursor()
        conn.execute(sqlUpd)
        if iRowCount % 100 == 0:
            print "Commit to DB ({0})....".format(iRowCount)
            conn.commit()
            #cursUpd.commit()
            #cursUpd.close()
    #print iRowCount
    conn.commit()
    conn.close()
    print "Process Started : {0}".format(tStart)
    print "Process Complete: {0}".format(datetime.datetime.now())



def DeleteExists(data):
    if arcpy.Exists(data):
        arcpy.Delete_management(data)
        return True
    else:
        return False
#-----------------------------------------------
if __name__ == '__main__':
    CalculateDataCount_Survey(spattabDB)
    #CalculateDataCount_Incidental(spattabDB)
    pass

