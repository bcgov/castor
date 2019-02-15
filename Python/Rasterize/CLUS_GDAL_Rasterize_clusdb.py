#-------------------------------------------------------------------------------
# Name:        CLUS_GDAL_Rasterize_VRI
# Purpose:     This script is designed to read a list of input PostGIS source
#               Vectors and Rasterize them to GeoTiff using GDAL Rasterize and
#               then load them into PostGIS as rasters using raster2pgsql
#
# Author:       Mike Fowler
#               Spatial Data Analyst
#               Forest Analysis and Inventory Branch - BC Government
#               Workflow developed by Kyle Lochhead, converted into Python Script
#
# Created:     30-01-2019
#
#-------------------------------------------------------------------------------

import os, sys, subprocess
import shutil, getpass, datetime
#--Globals
global kennyloggins
pfx = '{0}_'.format(os.path.basename(os.path.splitext(sys.argv[0])[0]))
logTime = ''
def WriteOutErrors(lstErrors):
    errLog = os.path.join(os.path.dirname(sys.argv[0]), pfx + logTime + ".errors.log")
    fLog = open(errLog, 'w')
    lstLog = []
    lstLog.append("------------------------------------------------------------------\n")
    lstLog.append("Error Log file for {0}\n".format(sys.argv[0]))
    lstLog.append("Date:{0} \n".format(datetime.datetime.now().strftime("%B %d, %Y - %H%M")))
    lstLog.append("User:{}\n".format(getpass.getuser()))
    lstLog.append("\n")
    lstLog.append("------------------------------------------------------------------\n")
    sLog = ''.join(lstLog)
    fLog.write(sLog)
    fLog.write("List of Errors from Script------------------------------------------------------------\n")
    for err in lstErrors:
        fLog.write('{0}\n'.format(str(err)))
    fLog.write("------------------------------------------------------------------\n")
    fLog.close()
def CreateLogFile(srcDB, outDB, tiffDir, bMsg=False):
    global logTime
    logTime = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    currLog = os.path.join(os.path.dirname(sys.argv[0]), pfx + datetime.datetime.now().strftime("%Y%m%d_%H%M%S.log"))
    fLog = open(currLog, 'w')
    lstLog = []
    lstLog.append("------------------------------------------------------------------\n")
    lstLog.append("Log file for {0}\n".format(sys.argv[0]))
    lstLog.append("Date:{0} \n".format(datetime.datetime.now().strftime("%B %d, %Y - %H%M")))
    lstLog.append("User:{}\n".format(getpass.getuser()))
    lstLog.append("Source DB:{}\n".format(srcDB))
    lstLog.append("Output DB:{}\n".format(outDB))
    lstLog.append("TIFF Directory:{}\n".format(tiffDir))
    lstLog.append("\n")
    lstLog.append("------------------------------------------------------------------\n")
    sLog = ''.join(lstLog)
    fLog.write(sLog)
    if bMsg:
        print(sLog)
    return fLog
def WriteLog(fLog, sMessage, bMsg=False):
    ts = datetime.datetime.now().strftime("%B %d, %Y - %H%M")
    sMsg = '{0} - {1}'.format(ts, sMessage)
    fLog.write(sMsg)
    if bMsg:
        print(sMsg)
def LoadListFromCSV(inCSV):
    import csv
    processLst = []
    with open(inCSV) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                pass
            else:
                #processLst.append([row[0], row[1], row[2], row[3]])
                processLst.append(row)
            line_count += 1
    return processLst
def Rasterize(db, sql, fld, outWrk, outName):
    WriteLog(kennyloggins, 'Rasterize..........................\n', True)
    db = 'PG:"{0}"'.format(db)
    fld = fld.lower()
    outTIFF = os.path.join(outWrk, '{0}.tif'.format(outName))
    sql = '"{0}"'.format(sql)
    WriteLog(kennyloggins, '-----{0}\n'.format(db), True)
    WriteLog(kennyloggins, '-----{0}\n'.format(fld), True)
    WriteLog(kennyloggins, '-----{0}\n'.format(outTIFF), True)
    WriteLog(kennyloggins, '-----{0}\n'.format(sql), True)
    #--Build the command to run the GDAL Rasterize
    cmd =  'gdal_rasterize -tr 100 100 -te 273287.5 359687.5 1870587.5 1735787.5 -a {0} {1} -sql {2} {3}'.format(fld, db, sql, outTIFF)
    WriteLog(kennyloggins, '-----Running CMD:\n', True)
    WriteLog(kennyloggins, '{0}\n'.format(cmd), True)
    try:
        subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        WriteLog(kennyloggins, '{0}\n'.format(str(e.output)), True)
        raise Exception(str(e.output))
    return outTIFF
def TIFF2PostGIS(tiff, db, outSchema, outName):
    WriteLog(kennyloggins, 'TIFF2PostGIS..........................\n', True)
    WriteLog(kennyloggins, '-----{0}\n'.format(tiff), True)
    WriteLog(kennyloggins, '-----{0}\n'.format(db), True)
    WriteLog(kennyloggins, '-----{0}\n'.format(outName), True)
    cmd = 'raster2pgsql -s 3005 -d -I -C -M {0} -t 100x100 {1}.{2} | psql {3}'.format(tiff, outSchema, outName, db)
    WriteLog(kennyloggins, '-----Running CMD:\n', True)
    WriteLog(kennyloggins, '{0}\n'.format(cmd), True)
    try:
        #subprocess.call(cmd, shell=True)
        subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        WriteLog(kennyloggins, '{0}\n'.format(str(e.output)), True)
        raise Exception(str(e.output))

if __name__ == '__main__':
    #--Read inputs into a Processing List
    inputCSV = os.path.join(os.path.dirname(sys.argv[0]), '{0}Input.csv'.format(pfx))
    #--Read the input CSV to get the list of queries,layers to rasterize
    processList =LoadListFromCSV(inputCSV)
    errList = []
    #--Setting the source DB and Output DB arguments.  If not supplied we will defalut to localhost, postgres
    if len(sys.argv) > 1:
        srcDB = sys.argv[1]
    else:
        srcDB = "host='localhost' dbname = 'clus' port='5432' user='postgres' password='postgres'"
        #srcDB = "host='DC052586.idir.bcgov' dbname = 'clus' port='5432' user='postgres' password='postgres'"
    if len(sys.argv) > 2:
        outDB = sys.argv[2]
    else:
        outDB = "-d clus"
        #outDB = "-d clus"
        #outDB = "-d clus -h DC052586.idir.bcgov -U postgres"
    tiffWork = os.path.join(os.environ['TEMP'], '{0}TIFF'.format(pfx))
    #--Create a Log File
    kennyloggins = CreateLogFile(srcDB, outDB, tiffWork, True)

    if not os.path.exists(tiffWork):
        os.makedirs(tiffWork)

    WriteLog(kennyloggins, '--------------------------------------------------------------------------------------\n', True)
    for itm in processList:
        bRemoveTIFF = False
        #--Only process the input records with a PROCESS = 'Y'
        if itm[4].upper() == 'Y':
            WriteLog(kennyloggins, '--------------------------------------------------------------------------------------\n', True)
            outSchema = itm[0]
            outName = itm[1]
            fld = itm[2]
            sql = itm[3]
            retainTIFF = itm[5].upper()
            if retainTIFF =='N': bRemoveTIFF = True
            WriteLog(kennyloggins, 'Processing:{0}\n'.format(str(itm)), True)
            try:
                WriteLog(kennyloggins, 'Running Rasterize....\n', True)
                #--Rasterize the source to Tiff
                outTIFF = Rasterize(srcDB, sql, fld, tiffWork, outName)
                WriteLog(kennyloggins, 'Running TIFF2PostGIS....\n', True)
                #--Load the TIFF to Postgres
                TIFF2PostGIS(outTIFF, outDB, outSchema, outName)
                #--Delete the TIFF if flagged to do so
                if bRemoveTIFF:
                    os.remove(outTIFF)
                WriteLog(kennyloggins, '--------------------------------------------------------------------------------------\n', True)
            except:
                WriteLog(kennyloggins, '--------------------------------------------------------------------------------------\n', True)
                #WriteLog(kennyloggins, 'Error: {0}\n'.format(str(e)), True)
                errList.append(itm)
    if len(errList) > 0:
        WriteLog(kennyloggins, 'Writing out Errors......\n', True)
        WriteOutErrors(errList)
    WriteLog(kennyloggins, '--------------------------------------------------------------------------------------\n', True)
    WriteLog(kennyloggins, 'Script Complete-----------------------------------------------------------------------\n', True)
    WriteLog(kennyloggins, '--------------------------------------------------------------------------------------\n', True)
    kennyloggins.close()


