import os
import sys
import arcpy

BCGWmdpath = r'\\bctsdata.bcgov\tsg_root\GIS_Workspace\Mike_F\Scripts\Python\BCGWMetadata'
MXDpath = "H:\GIS\CRP\Maps\DataExplore.mxd"
MDmdb = r"\\bctsdata.bcgov\tsg_root\GIS_Workspace\Mike_F\Scripts\Python\BCGWMetadata\BCGW_Metadata.accdb"

sys.path.append(BCGWmdpath)

#--------------Suppressing Messaging--------------------------------------------
from contextlib import contextmanager
import sys, os

@contextmanager
def suppress_stdout():
    with open(os.devnull, "w") as devnull:
        old_stdout = sys.stdout
        sys.stdout = devnull
        try:
            yield
        finally:
            sys.stdout = old_stdout
#--------------Suppressing Messaging--------------------------------------------
import BCGW_Metadata
dctGeo = BCGW_Metadata.GetBCGWGeograhicDataList()

with suppress_stdout():
    mxd = arcpy.mapping.MapDocument(MXDpath)
    for lyr in arcpy.mapping.ListLayers(mxd, "*"):
        if lyr.isGroupLayer:
            print "--Group Layer:" + lyr.name
        else:
            if lyr.supports("DATASETNAME"):
                srch = lyr.datasetName
                md = BCGW_Metadata.ProcessMetadata(srch, dctGeo)
                print "Loading Metadata for:" + srch
                BCGW_Metadata.Load_Metadata_Access(MDmdb, md)



