#-------------------------------------------------------------------------------
# Name:     PostgresBackup.py
# Purpose:  This script is designed to backup a Postgres Database.  Specifically
#           this script was created to backup the CLUS database that supports
#           the Caribou Land Use Simulator (CLUS) tool.
#
#
# Author:      MWFOWLER
#
# Created:     September 06, 2018
#-------------------------------------------------------------------------------
import gzip
import os
import sys
from subprocess import Popen, PIPE
from datetime import datetime
from time import gmtime, strftime
import time

kennyloggins = None

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
        log('Successfully sent the mail')
    except Exception as e:
        log("****Failed to send mail****")

def openlog(buDir):
    global kennyloggins
    logger = os.path.join(os.path.dirname(buDir), '{0}.log'.format(os.path.basename(buDir)))
    kennyloggins = open(logger, 'w')
    log('Log File Created:{0}'.format(logger))
    #return kennyloggins

def log(string):
        global kennyloggins
        msg = time.strftime("%Y-%m-%d-%H-%M-%S", time.localtime()) + ": " + str(string)
        print (msg)
        if not kennyloggins is None:
            kennyloggins.write('{0}\n'.format(msg))

def BackupDB(dbUser='postgres', dbPass='postgres', dbHost='DC052586', dbName='clus', backup_dir=r'F:\Data\PGBackups', backup_prefix='CLUS_DB_Backup', dbPort='5432', schema_only=False, gmailacct='k', gmailpass='k', notifyrecip='k'):
    global kennyloggins
    tstamp = str(strftime("%Y%m%d"))
    buDir = os.path.join(backup_dir, '{0}_{1}'.format(backup_prefix, tstamp))

    def CheckDir(chkdir):
        theTime = str(strftime("%H%M"))
        baseparts =  os.path.basename(buDir).split("_")
        stamp = baseparts[len(baseparts)-1]
        if os.path.exists(chkdir):
            if len(stamp) > 8 :
                if stamp[-4:]== theTime:
                    stamp = str(int(stamp) + 1)
                    return os.path.join(os.path.dirname(buDir), '{0}_{1}'.format(backup_prefix, stamp))
            else:
                return '{0}{1}'.format(chkdir, theTime)
        else:
            return chkdir

    buDir = CheckDir(buDir)

    #--Testing -s is just the schema
    if schema_only:
        params = ['pg_dump', '-U', dbUser, '-h', dbHost, '-p', dbPort, '-s', '-Fd', '-f', buDir, dbName]
    else:
        params = ['pg_dump', '-U', dbUser, '-h', dbHost, '-p', dbPort,  '-Fd' , '-f ', buDir , dbName, ]

    command = ""
    for p in params:
        command = command + p + ' '

    os.putenv('PGPASSWORD', dbPass)

    os.makedirs(buDir)
    openlog(buDir)
    log("Dump started for {0}".format(dbName))
    #--------------------------------------------------------------------------------------------------
    log("Command Executing: {0}".format(command))
    process = Popen(params, stdout=PIPE, stderr=PIPE)
    process.wait()
    output, error = process.communicate()
    if error:
        log("*****Error Executing Command: {0}".format(command))
        log("*****Error Performing Backup.")
        kennyloggins.close()
        #if not gmailacct is None:
          #  send_email(gmailacct, gmailpass, notifyrecip, 'CLUS -DB Backup - ERROR', 'The database did not finish backing up at: ' + time.strftime("%Y-%m-%d-%H-%M-%S", time.localtime()) + '\n\nError:{0}\n\nCommand Executed:{1}'.format(error, command))
    else:
        log("Dump finished for {0}".format(dbName))
        log("Backup Directory: {0}".format(buDir))
        log("Backup job complete.")
        kennyloggins.close()
        #if not gmailacct is None:
            #send_email(gmailacct, gmailpass, notifyrecip, 'CLUS -DB Backup - SUCCESS', 'The database finished backing up at: ' + time.strftime("%Y-%m-%d-%H-%M-%S", time.localtime()) + '\n\nCommand Executed:{0}\n\nBackup Directory Created:{1}'.format(command, buDir))
   #--------------------------------------------------------------------------------------------------
if __name__ == '__main__':

    #stashSpot = r'W:\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Data\CLUS_DB_Backups'
    stashSpot = r'F:\Data\PGBackups'
    #stashSpot = os.environ['TEMP']
    prefix = 'CLUS_DB_Backup'
    schemaMode = False
    #--Change the gmail account and password and notify recipient, or to omit this option leave gmailacct=None and it will be skipped.   See subsequent line call.
    BackupDB(backup_dir=stashSpot, backup_prefix=prefix, schema_only=schemaMode, gmailacct='', gmailpass='', notifyrecip='')
    #BackupDB(backup_dir=stashSpot, backup_prefix=prefix, schema_only=schemaMode, gmailacct=None)

