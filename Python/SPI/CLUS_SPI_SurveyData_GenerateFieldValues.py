#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      mwfowler
#
# Created:     31/05/2018
# Copyright:   (c) mwfowler 2018
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import pyodbc
import os

fcTarget = 'WHSE_WILDLIFE_INVENTORY.SPI_SURVEY_OBS_ALL_SP'

def CreateBCGWConn_SDE(dbUser, dbPass):
    connBCGW = os.path.join(os.path.dirname(arcpy.env.scratchGDB), 'SPI_DataAnalysis.sde')
    if os.path.isfile(connBCGW):
        os.remove(connBCGW)
    try:
        arcpy.CreateDatabaseConnection_management(os.path.dirname(connBCGW), os.path.basename(connBCGW), 'ORACLE', connInstance, username=dbUser, password=dbPass)
    except:
        print 'Error Creating BCGW connection....'
        connBCGW = None
    return connBCGW

def ConnectBCGW(dbUser, dbPass):
    connstr = "Driver={0};Server=IDWPROD1.BCGOV;Uid={1};Pwd={2};".format("Microsoft ODBC for Oracle", dbUser, dbPass)
    conn = pyodbc.connect(connstr)
    return conn

def pq(str, type='s'):
    # pq stands for pad quotes
    # type 's' for single quotes, type 'd' for double quotes
    if type == 'd':
        return '"' + str.replace("'", "''") + '"'
    else:
        return "'" + str.replace("'", "''") + "'"
def ProcessSurveyExplore(dbUser, dbPass):
    conn= ConnectBCGW(dbUser, dbPass)
    wc= "SPECIES_CODE IN ('M-RATA', 'M-ALAM', 'M-CALU')"
    #--------------------------------------------------------------------------
    #--Create an output CSV to hold the data
    #--------------------------------------------------------------------------
    outCSV = os.path.join(os.environ['TEMP'], 'SPI_SURVEY_FieldData.csv')
    if os.path.isfile(outCSV):
        os.remove(outCSV)
    f = open(outCSV, 'w')
    f.write("{0},{1},{2},{3}\n".format("FIELD_NAME", "SPECIES", "FIELD_VALUE", "DATA_VALUE"))
    for i in range(1, 32):
    #for i in range(1, 2):
        fld = "FIELD_NAME_{0}".format(i)
        data = "DATA_{0}".format(i)
        sql = "SELECT SPECIES_CODE, {0} FROM {1} WHERE {2} GROUP BY SPECIES_CODE, {0}".format(fld, fcTarget, wc)
        cursor = conn.cursor()
        print "----{0}----".format(fld)
        for row in cursor.execute(sql):
            spc = row[0]
            fldVal = row[1]
            subwc = "SPECIES_CODE = '{0}' AND {1} = '{2}'".format(spc, fld, fldVal)
            subsql = "SELECT {0} FROM {1} WHERE {2} GROUP BY {0}".format(data, fcTarget, subwc)
            subcursor = conn.cursor()
            for subrow in subcursor.execute(subsql):
                sRow = "{0},{1},{2},{3}\n".format(fld, spc, fldVal, subrow[0])
                f.write(sRow)
                print "\t{0}-{1}-{2}".format(row[0], row[1], subrow[0])
    f.close()


if __name__ == '__main__':
    ProcessSurveyExplore('mwfowler', 'Vedder03')
