#-------------------------------------------------------------------------------
# This script is designed to extract BC Data Catalogue Metadta by
# BCGW object name.  (user.object)
# The metadata is then inserted into a Metadata Database
#
# Mike Fowler
# Spatial Data Analyst
# Forest Analysis & Inventory Branch
# April 17, 2018
#-------------------------------------------------------------------------------
import requests
import json, os
import pyodbc
import sys
import datetime
#-------------------------------------------------------------------------------
#Classes
#-------------------------------------------------------------------------------
class BCGW_Metadata:
    #-A Class for modelling a metadata record returned from the BCGW API
    def __init__(self, source, fc_objname, title, data_group='Empty', data_subgroup='Empty'):
        self.source = source
        #--If the object has a period, we assume a BCGW source
        if fc_objname.find(".") > 0:
            self.object_name_full = fc_objname
            self.object_owner = self.object_name_full.split(".")[0]
            self.object_name = self.object_name_full.split(".")[1]
        else:
            self.object_name_full = os.path.join(source, fc_objname)
            self.object_owner = ""
            self.object_name = fc_objname
        self.title = title
        self.data_group = data_group
        self.data_subgroup = data_subgroup
        self.purpose = ''
        self.lineage = ''
        self.comments = ''
        self.fields = []
        self.contacts = []

    def add_field(self, bcgw_field):
        self.fields.append(bcgw_field)

    def add_contact(self, bcgw_contact):
        self.contacts.append(bcgw_contact)

class BCGW_Metadata_Field:
    #-A Class for modelling the fields for each metadata record
    def __init__(self, full_name, short_name='Empty', data_type='Empty', data_length=0, description='Empty'):
        self.full_name = full_name
        self.short_name = short_name
        self.data_type = data_type
        self.data_length = data_length
        self.description = description

class BCGW_Metadata_Contact:
    #-A Class for modelling the contacts for each metadata record
    def __init__(self, name, email='Empty', org='Empty', sub_org='Empty', role='Empty'):
        self.name = name
        self.email = email
        self.role = role
        self.org = org
        self.sub_org = sub_org
#-------------------------------------------------------------------------------
#Functions
#-------------------------------------------------------------------------------
def GetBCGWGeograhicDataList():
    #---------------------------------------------------------------------------
    #--A Function to get the CSV List from the BCGW Metatdata that contains the
    #--ID value and the Object name.
    #--The CSV can then be used as a lookup for the Spatial Object name to ID
    #--to extract the correct metatdata records
    #---------------------------------------------------------------------------
    dctGeo = {}
    url = r'https://catalogue.data.gov.bc.ca/dataset/42f7ca99-e7f3-40f7-93d7-f2500cccc315/resource/63f43e07-e745-4420-ba67-aa47c2ccd531/download/geographic-1.csv'
    req = requests.get(url)
    csv_src = os.path.join(os.environ['TMP'], 'BCGW_Geographic.csv')
    #--Write the CSV request out to file.  All fields included
    if os.path.isfile(csv_src):
        os.remove(csv_src)
    with open(csv_src, 'wb') as fd:
        for chunk in req.iter_content(chunk_size=128):
            fd.write(chunk)
    #--Create a new CSV file with just the 2 fields we need
    import csv
    with open(csv_src, 'rb') as source:
        rdr = csv.reader(source)
        i = 1
        for r in rdr:
            #--Writing out the ID and Object Name values to the CSV.  It's all we need.
            if i > 1:
                if not r[20] == '':
                    dctGeo[r[20]] = r[3]
            i = i + 1
    #--Delete the source CSV
    if os.path.isfile(csv_src):
        os.remove(csv_src)

    return dctGeo

def get_org(id):
    org = 'None'
    url_call = r'https://catalogue.data.gov.bc.ca/api/3/action/organization_show?id=' + id
    try:
        req = requests.get(url_call)
        req_json = req.json()
        org = req_json['result']['title']
    except:
        pass
    return org

def pq(str, type='s'):
    # pq stands for pad quotes
    # type 's' for single quotes, type 'd' for double quotes
    if type == 'd':
        return '"' + str.replace("'", "''") + '"'
    else:
        return "'" + str.replace("'", "''") + "'"

def nz_d(dct, val):
    #--This functions returns a None string for empty dictionary key values
    try:
        #return dct[val].encode('utf-8')
        return dct[val]
    except KeyError:
        return 'None'
def nz_dn(dct, val):
    #--This functions returns a 0 value empty dictionary key values that are numbers
    try:
        return int(dct[val])
    except KeyError:
        return 0
def ProcessMetadata(searchTerm, dctGEO=None):
    if dctGEO==None:
        dctGEO = GetBCGWGeograhicDataList()
    bcdcUrl = r"https://catalogue.data.gov.bc.ca/api/3/action/package_show?id="
    try:
        srch = bcdcUrl + dctGEO[searchTerm]
    except KeyError:
        srch = bcdcUrl
    bcgw_metadata = BCGW_Metadata("BCGW-Prod", searchTerm, searchTerm)
    try:
        req = requests.get(srch)
        req_json = req.json()
        rec = req_json['result']
        #--We have a metadata record that matches our search specifically
        if 'object_name' in rec.keys():
            print searchTerm + "-" + rec['id'] + "-" + rec['object_name']
            if rec['object_name'] == searchTerm:
                bcgw_metadata = BCGW_Metadata("BCGW-Prod", rec['object_name'], nz_d(rec, 'title'))
                bcgw_metadata.purpose = nz_d(rec, 'purpose')
                bcgw_metadata.lineage = nz_d(rec, 'lineage_statement')
                #--Work through the contacts for the data
                for cnt in rec['contacts']:
                    bcgw_cnt = BCGW_Metadata_Contact(nz_d(cnt, 'name'), nz_d(cnt, 'email'), nz_d(cnt, 'organization'), nz_d(cnt, 'branch'), nz_d(cnt, 'role'))
                    bcgw_cnt.org = get_org(bcgw_cnt.org)
                    bcgw_cnt.sub_org = get_org(bcgw_cnt.sub_org)
                    bcgw_metadata.add_contact(bcgw_cnt)
                #--Work through the fields for the data
                for fld in rec['details']:
                    bcgw_fld = BCGW_Metadata_Field(nz_d(fld, 'column_name'), nz_d(fld, 'short_name'), nz_d(fld, 'data_type'), nz_dn(fld, 'data_precision'), nz_d(fld, 'column_comments'))
                    bcgw_metadata.add_field(bcgw_fld)
    except:
        #--On errors, we return an empty/default BCGW_Metadata object
        pass
    #--Return the Metadata Object
    return bcgw_metadata

def Connect_Access(path):
    conn_str =  r"Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=" + path + ";"
    conn = pyodbc.connect(conn_str)
    return conn

def Check_Record_Exists(conn, metadata, type, dataID=0):
    #conn = Connect_Access(mdb)
    bExists = False
    retID = -99
    if type == 'DATASET':
        sql = "SELECT DATASET_ID FROM DATASETS WHERE OBJECT_NAME_FULL = " + pq(metadata.object_name_full)
    elif type == 'CONTACT':
        sql = "SELECT CONTACT_ID FROM CONTACTS WHERE NAME = " + pq(metadata.name) + ' AND ROLE = ' + pq(metadata.role)
    elif type == 'FIELD':
        sql = "SELECT FIELD_ID FROM FIELDS WHERE FULL_NAME = " + pq(metadata.full_name) + ' AND FK_DATASET = ' + str(dataID)
    cursor = conn.cursor()
    #print "************" + sql
    cursor.execute(sql)
    row = cursor.fetchone()
    if row:
            bExists = True
            retID = row[0]
    #conn.close()
    return [bExists, retID]

def Check_JCT_Exists(conn, jctTab, fk1name, fk1, fk2name, fk2):
    #conn = Connect_Access(mdb)
    bExists = False
    sql = "SELECT {1}, {3} FROM {0} WHERE {1} = {2} AND {3} = {4}".format(jctTab, fk1name, fk1, fk2name, fk2)
    cursor = conn.cursor()
    cursor.execute(sql)
    row = cursor.fetchone()
    if row:
        bExists = True
    #conn.close()
    return bExists

def Load_Metadata_Access(mdb, bcgw_metadata):
    conn = Connect_Access(mdb)
    cursor = conn.cursor()
    curr_date = pq(str(datetime.date.today()))
    #---------------------------------------------------------------------------
    #---Insert Operation for the Dataset
    #---------------------------------------------------------------------------
    rslt = Check_Record_Exists(conn, bcgw_metadata, 'DATASET')
    if rslt[0]:
        #--If the Dataset already exists we Update
        #print 'Dataset - Update' + bcgw_metadata.object_name_full
        sql = u"UPDATE DATASETS SET UPDATE_DATE = {0}, SOURCE = {1}, OBJECT_NAME_FULL = {2}, OBJECT_OWNER = {3}, OBJECT_NAME = {4}, TITLE = {5}, PURPOSE = {6}, LINEAGE = {7}, COMMENTS = {8}, DATASET_GROUP = {9}, DATASET_SUBGROUP = {10} WHERE DATASET_ID = {11}".format(
        curr_date, pq(bcgw_metadata.source), pq(bcgw_metadata.object_name_full), pq(bcgw_metadata.object_owner), pq(bcgw_metadata.object_name), pq(bcgw_metadata.title), pq(bcgw_metadata.purpose), pq(bcgw_metadata.lineage), pq(bcgw_metadata.comments),pq(bcgw_metadata.data_group), pq(bcgw_metadata.data_subgroup), (rslt[1])
        )
        dataID = rslt[1]
        cursor.execute(sql)
        cursor.commit()
    else:
        sql = u"INSERT INTO DATASETS(UPDATE_DATE, SOURCE, OBJECT_NAME_FULL, OBJECT_OWNER, OBJECT_NAME, TITLE, PURPOSE, LINEAGE, COMMENTS, DATASET_GROUP, DATASET_SUBGROUP) VALUES ({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10})".format(
        curr_date, pq(bcgw_metadata.source), pq(bcgw_metadata.object_name_full), pq(bcgw_metadata.object_owner), pq(bcgw_metadata.object_name), pq(bcgw_metadata.title), pq(bcgw_metadata.purpose), pq(bcgw_metadata.lineage), pq(bcgw_metadata.comments), pq(bcgw_metadata.data_group), pq(bcgw_metadata.data_subgroup)
        )
        #print sql + "-" + str(rslt[0]) + "-" + str(rslt[1])
        cursor.execute(sql)
        cursor.commit()
        row = cursor.execute("SELECT @@IDENTITY").fetchone()
        dataID = row[0]
    #---------------------------------------------------------------------------
    #--Insert operation for the Contact(s)
    #---------------------------------------------------------------------------
    for cnt in bcgw_metadata.contacts:
        rslt = Check_Record_Exists(conn, cnt, 'CONTACT')
        if rslt[0]:
            #--If the Contact already exists in the DB, we update
            #print 'Contact - Update' + cnt.name
            cntID = rslt[1]
            sql = u"UPDATE CONTACTS SET UPDATE_DATE = {0}, NAME = {1}, EMAIL = {2}, ROLE = {3}, ORG = {4}, SUB_ORG = {5} WHERE CONTACT_ID = {6}".format(
            curr_date, pq(cnt.name), pq(cnt.email), pq(cnt.role), pq(cnt.org), pq(cnt.sub_org), str(cntID)
            )
            cursor.execute(sql)
            cursor.commit()
            #--It's possible to have an existing contact that is not linked to the current dataset.  Need to update the junction table to link them
            if not Check_JCT_Exists(conn, 'JCT_DATASETS_CONTACTS', 'FK_DATASET', dataID, 'FK_CONTACT', cntID):
                sql = u"INSERT INTO JCT_DATASETS_CONTACTS(FK_DATASET, FK_CONTACT) VALUES ({0}, {1})".format(
                dataID, cntID
                )
            cursor.execute(sql)
            cursor.commit()
        else:
            sql = u"INSERT INTO CONTACTS(UPDATE_DATE, NAME, EMAIL, ROLE, ORG, SUB_ORG) VALUES ({0}, {1}, {2}, {3}, {4}, {5})".format(
            curr_date, pq(cnt.name), pq(cnt.email), pq(cnt.role), pq(cnt.org), pq(cnt.sub_org)
            )
            cursor.execute(sql)
            cursor.commit()
            row = cursor.execute("SELECT @@IDENTITY").fetchone()
            cntID = row[0]
            sql = u"INSERT INTO JCT_DATASETS_CONTACTS(FK_DATASET, FK_CONTACT) VALUES ({0}, {1})".format(
            dataID, cntID
            )
            cursor.execute(sql)
            cursor.commit()
    #---------------------------------------------------------------------------
    #--Insert operation for the Field(s)
    #---------------------------------------------------------------------------
    for fld in bcgw_metadata.fields:
        rslt = Check_Record_Exists(conn, fld, 'FIELD', dataID)
        if rslt[0]:
            #print 'Field - Update' + fld.full_name
            sql = u"UPDATE FIELDS SET UPDATE_DATE = {0}, FK_DATASET = {1}, FULL_NAME = {2}, SHORT_NAME = {3}, DATA_TYPE = {4}, DATA_LENGTH = {5}, DESCRIPTION = {6} WHERE FIELD_ID = {7}".format(
            curr_date, dataID, pq(fld.full_name), pq(fld.short_name), pq(fld.data_type), fld.data_length, pq(fld.description), str(rslt[1])
            )
        else:
            sql = u"INSERT INTO FIELDS(UPDATE_DATE, FK_DATASET, FULL_NAME, SHORT_NAME, DATA_TYPE, DATA_LENGTH, DESCRIPTION) VALUES ({0}, {1}, {2}, {3}, {4}, {5}, {6})".format(
            curr_date, dataID, pq(fld.full_name), pq(fld.short_name), pq(fld.data_type), fld.data_length, pq(fld.description)
            )
        #print sql
        cursor.execute(sql)
        cursor.commit()

    #conn.close()
#-------------------------------------------------------------------------------
#Main
#-------------------------------------------------------------------------------
if __name__ == '__main__':
    fclist = ['WHSE_FOREST_VEGETATION.F_OWN', 'WHSE_FOREST_VEGETATION.VEG_COMP_POLY', 'WHSE_WILDLIFE_MANAGEMENT.WCP_UNGULATE_WINTER_RANGE_SP', 'WHSE_FOREST_VEGETATION.RSLT_OPENING_SVW', 'REG_HUMAN_CULTURAL_ECONOMIC.TOURISM_FEATURES_DSC_LINE']
    #fclist = ['WHSE_FOREST_VEGETATION.F_OWN', 'WHSE_FOREST_VEGETATION.VEG_COMP_POLY', 'WHSE_WILDLIFE_MANAGEMENT.WCP_UNGULATE_WINTER_RANGE_SP', 'WHSE_FOREST_VEGETATION.RSLT_OPENING_SVW']
    #fclist = ['WHSE_FOREST_VEGETATION.RSLT_OPENING_SVW']
    #fclist = ['WHSE_FOREST_VEGETATION.F_OWN', 'WHSE_FOREST_VEGETATION.VEG_COMP_POLY', 'WHSE_WILDLIFE_MANAGEMENT.WCP_UNGULATE_WINTER_RANGE_SP']
    #mdb = r"\\bctsdata.bcgov\tsg_root\GIS_Workspace\Mike_F\Scripts\Python\BCGWMetadata\BCGW_Metadata.accdb"
    mdb = r"H:\GIS\CRP\Scripts\Python\BCGWMetadata\BCGW_Metadata.accdb"
    for fc in fclist:
        md = ProcessMetadata(fc)
        if not md == None:
            Load_Metadata_Access(mdb, md)
        else:
            print 'No Metadata Found - ' + fc

    pass
