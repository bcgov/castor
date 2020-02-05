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
pfx = os.path.basename(os.path.splitext(sys.argv[0])[0])
logTime = ''
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
def CreateLogFile(bMsg=False):
    global logTime
    logTime = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    currLog = os.path.join(os.path.dirname(sys.argv[0]), pfx + datetime.datetime.now().strftime("%Y%m%d_%H%M%S.log"))
    fLog = open(currLog, 'w')
    lstLog = []
    lstLog.append("------------------------------------------------------------------\n")
    lstLog.append("Log file for {0}\n".format(sys.argv[0]))
    lstLog.append("Date:{0} \n".format(datetime.datetime.now().strftime("%B %d, %Y - %H%M")))
    lstLog.append("User:{}\n".format(getpass.getuser()))
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
                #print(row)
            else:
                #print('{0}-{1}-{2}'.format(row[0], row[1], row[2]))
                processLst.append([row[0], row[1], row[2], row[3]])
            line_count += 1
    return processLst
def Rasterize(db, sql, fld, outWrk, outName):
    print('Rasterize..........................')
    db = 'PG:"{0}"'.format(db)
    fld = fld.lower()
    outTIFF = os.path.join(outWrk, '{0}.tif'.format(outName))
    sql = '"{0}"'.format(sql)
    print('-----{0}'.format(db))
    print('-----{0}'.format(fld))
    print('-----{0}'.format(outTIFF))
    print('-----{0}'.format(sql))
    #--Build the command to run the GDAL Rasterize
    cmd =  'gdal_rasterize -tr 100 100 -te 273287.5 359687.5 1870587.5 1735787.5 -a {0} {1} -sql {2} {3}'.format(fld, db, sql, outTIFF)
    print ('-----Running CMD:\n-----{0}'.format(cmd) )
    print (outTIFF )
    try:
        #subprocess.call(cmd, shell=True)
        subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        print(e.output)
        raise Exception(str(e.output))
    except :
        print(str(e))
        raise Exception(str(e))
    return outTIFF
def TIFF2PostGIS(tiff, db, outName):
    print('TIFF2PostGIS..........................')
    print('-----{0}'.format(tiff))
    print('-----{0}'.format(db))
    print('-----{0}'.format(outName))
    cmd = 'raster2pgsql -s 3005 -d -I -C -M {0} -t 100x100 {1} | psql {2}'.format(tiff, outName, db)
    print ('-----Running CMD:\n-----{0}'.format(cmd) )
    try:
        #subprocess.call(cmd, shell=True)
        subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        print(e.output)
        raise Exception(str(e.output))
    except:
        print(str(e))
        raise Exception(str(e))

if __name__ == '__main__':
    emailPwd = 'bruins26'
    #--Create a Log File
    kennyloggins = CreateLogFile(True)
    #--Read inputs into a Processing List
    inputCSV = os.path.join(os.path.dirname(sys.argv[0]), 'CLUS_GDAL_Rasterize_VRI_Input.csv')
    processList =LoadListFromCSV(inputCSV)


    errList = []
    bRemoveTIFF = False
    bSendEmails = True
    #srcDB = "host='localhost' dbname = 'postgres' port='5432' user='postgres' password='postgres'"
    #outDB = "-d postgres"
    #tiffWork = r'C:\Users\mwfowler\tiff'
    tiffWork = r'C:\Users\KLOCHHEA'
    srcDB = "host='DC052586.idir.bcgov' dbname = 'clus' port='5432' user='postgres' password='postgres'"
    outDB = "-d clus"
    for itm in processList:
        #--Only process the input records with a PROCESS = 'Y'
        if itm[3].upper() == 'Y':
            outName = itm[0]
            fld = itm[1]
            sql = itm[2]
            WriteLog(kennyloggins, 'Processing:{0}\n'.format(str(itm)), True)
            try:
                WriteLog(kennyloggins, 'Running Rasterize....\n', True)
                #--Rasterize the source to Tiff
                outTIFF = Rasterize(srcDB, sql, fld, tiffWork, outName)
                WriteLog(kennyloggins, 'Running TIFF2PostGIS....\n', True)
                #--Load the TIFF to Postgres
                TIFF2PostGIS(outTIFF, outDB, outName)
                #--Delete the TIFF if flagged to do so
                if bRemoveTIFF:
                    os.remove(outTIFF)
                if bSendEmails:
                    #send_email('mfowler.bc@gmail.com', emailPwd, 'mike.fowler@gov.bc.ca', 'CLUS-Rasterize-Processed', '{0}\n{1}\n'.format(outDB, str(itm)))
                    print()
            except:
                WriteLog(kennyloggins, 'Error: {0}\n'.format(str(e)), True)
                if bSendEmails:
                    #send_email('mfowler.bc@gmail.com', emailPwd, 'mike.fowler@gov.bc.ca', '***CLUS-Rasterize-Error***', '{0}\n{1}'.format(str(itm), str(e)))
                errList.append(itm)
    if len(errList) > 0:
        WriteLog(kennyloggins, 'Writing out Errors......\n', True)
        WriteOutErrors(errList)
    if bSendEmails:
        send_email('mfowler.bc@gmail.com', emailPwd, 'mike.fowler@gov.bc.ca', 'CLUS-Rasterize-Complete', 'The script finished\n')
    kennyloggins.close()


