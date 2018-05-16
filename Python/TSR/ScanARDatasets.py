import sys
import os
import arcpy as gp

ARHome = r'\\spatialfiles2.bcgov\Archive\FOR\VIC\HTS\ANA\workarea'


for dir in os.listdir(ARHome):
    if dir[0:2] == 'AR':
        print '\n' + dir
        if os.path.exists(os.path.join(ARHome, dir, 'units')):
            for unit in os.listdir(os.path.join(ARHome, dir, 'units')):
                #print "----{0}".format(unit)
                gdb = "{0}_{1}.gdb".format(unit, dir[-4:])
                gdb_path = os.path.join(ARHome, dir, 'units', unit, gdb)
                gdb_wrk = os.path.join(ARHome, dir, 'units', unit, gdb, 'fin')
                gp.env.workspace= gdb_wrk
                i = 1
                for fc in gp.ListFeatureClasses("*"):
                    if i == 1:
                        print "-----------------------------------------------------------------------------"
                        print gdb_path
                        print "fin dataset feature class list"
                        print "-----------------------------------------------------------------------------"
                    print fc
                    i = 1 + 1
                if i > 1:
                    print "-----------------------------------------------------------------------------"
                else:
                    print "-----------------------------------------------------------------------------"
                    print "No feature classes found in fin of {0}-{1}".format(dir, gdb)
                    print "-----------------------------------------------------------------------------"









