#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
'''
Script for processing SPI Data for updating TSA attributes that got missed in the original script run

Mike Fowler
Spatial Data Analyst
January 2019
'''
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--Imports
import arcpy as gp
import os
wrk = r'C:\Users\mwfowler\AppData\Local\Temp'


def GetTSAName(mdTab, tsaNum):
    tsaName = 'Nully Furtado'
    with gp.da.SearchCursor(mdTab, ['TSA_NAME'], "TSA_NUMBER = '{0}'".format(tsaNum)) as cursor:
        for row in cursor:
            tsaName = row[0]
    return tsaName

def UpdateTSAAtts(wrk):
    gp.env.workspace = wrk
    iTSACount = 0
    #--Loop through each DB
    for wk in gp.ListWorkspaces('VRI_By_TSA*', "FileGDB"):
        gp.env.workspace = wk
        ds = os.path.join(wk, 'Data')
        mdTab = os.path.join(wk, 'PROCESS_METADATA')
        print mdTab
        for fc in gp.ListFeatureClasses('vri_tsa*', 'Polygon', 'Data'):
            iTSACount += 1
            tsaNum = fc[len(fc)-2:len(fc)]
            tsaName = GetTSAName(mdTab, tsaNum)
            #--Update the values in the VRI dataset
            print 'Updating TSA_NUMBER({0}) & TSA_NAME({1}) for {2}....'.format(tsaNum, tsaName, fc)
            with arcpy.da.UpdateCursor(os.path.join(wk, 'Data', fc), ['TSA_NUMBER', 'TSA_NAME']) as cursor:
                for row in cursor:
                    row[0] = tsaNum
                    row[1] = tsaName
                    # Update the cursor with the updated list
                    cursor.updateRow(row)


    #print 'TSA Count:{0}'.format(str(iTSACount))
if __name__ == '__main__':
    UpdateTSAAtts(wrk)
