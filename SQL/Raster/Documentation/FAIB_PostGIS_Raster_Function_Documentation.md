---
title: "FAIB PostGIS Raster Function Documentation"
author: "Mike Fowler"
date: "October 12, 2018"
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: false
    collapsed: false
    theme: united
    #highlight: tango
    #highlight: textmate #--This one is problematic for some reason. 
    #highlight: espresso
    #highlight: zenburn
    #highlight: pygments
    #highlight: kate
    #highlight: monochrome
    highlight: haddock
    keep_md: yes
    mathjax: null
---
******

[Top]  
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->  

# Overview

## Description
A series of PL/PGSQL (Procedural Language - PostgreSQL) functions have been written to support Raster processing and analysis.  These functions have been written to be flexible and to handle a multitude of scenarios where Rasters need to be processed including from Vector, Clipped, Filtered and/or Reclassed according to particular needs.  The functions output Rasters that align with the BC Raster Grid standard.  (The standard being used by FAIB for aligning rasters to a consistent grid provinically to allow for province-wide compilation and analysis of rasters.)

These functions have been created to support the Caribou Recovery work and the Caribou Land-Use Simulator (CLUS).  However, the hope is that they should have broader application throught FAIB for working with Raster data in PostgreSQL.

## Installation

The functions reside in an .SQL file.  That file can be loaded into an SQL Window in PG Admin and then all the text can be selected an executed.  
The SQL file lives here:  

(Right Click and Copy Link - Paste into Windows Explorer)  

<a href="file:\\spatialfiles2.bcgov\work\FOR\VIC\HTS\ANA\Workarea\mwfowler\CLUS\Scripts\SQL\Raster">\\\\spatialfiles2.bcgov\\work\\FOR\\VIC\\HTS\\ANA\\Workarea\\mwfowler\\CLUS\\Scripts\\SQL\\Raster</a>     

<strong>FAIB_RASTER_FUNCTIONS.sql</strong>

Steps

1. Open an SQL Window on the user/db that you want the functions installed to  
2. Ctl+Home + Ctl+End - Selects all the Text.   
3. F5 - Executes the code.   
4. Boom - you are done.  Functions are installed.   

![](RasterFunctions/FAIB_RASTER_FUNCTIONS_INSTALL_1.PNG)    

******  
[Top](#TOP)  

<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
# Main Raster Functions  
******  

## FAIB_FC_TO_RASTER  

#### Description:  
This function convert an existing Postgres feature class table to a Raster.  

The output raster will align with BC Raster Grid standard and be in BC Albers (SRID:3005) projection. 

#### Assumptions & Cautionary Notes:  
If output raster already exists it will be dropped then recreated with the new raster from this function - be careful!!

The funtion will automatically generate a VAT to apply to the output raster if no VAT is supplied and the valFld is Character type.  This auto generated VAT will have the name of the output Raster with _VAT tagged to the end.  If this object already exists in the Database it will be dropped and overwritten.  Handle with Care. 

#### Implementation:  

```sql
FAIB_FC_TO_RASTER(fc VARCHAR, valFld VARCHAR,outRaster VARCHAR, vat VARCHAR DEFAULT NULL,rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT False) RETURNS VOID
```


#### Parameters:  

<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="3"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> fc </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> Source feature class table </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> valFld </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The value field in the source feature class to rasterize on if Numeric type.  If no VAT is supplied and this field is Character type then a VAT will be generated and applied to the output raster. If a VAT is supplied this field must exist/join to the VAT where the VAL column from the VAT will be applied to the output raster </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> outRaster </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the output Raster </td>
  </tr>
  <tr grouplength="5"><td colspan="4" style="border-bottom: 1px solid;"><strong>Optional Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> vat </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> The value attribute table to apply to output raster values, if applicable. VAT must have column named VAL and a columun that     joins to to valFld.  If no VAT is supplied (NULL) and the valFld is Character type then a VAT will be generated on the fly and applied to the output raster.  The autogenerated VAT will be named the same as the outRaster with _VAT on the end. </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastSize </td>
   <td style="text-align:left;"> NUMERIC </td>
   <td style="text-align:left;"> 100 </td>
   <td style="text-align:left;"> The size of raster pixels </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastPixType </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> 32BF </td>
   <td style="text-align:left;"> The output raster pixel data type </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> noData </td>
   <td style="text-align:left;"> NUMERIC </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> NoData value in output raster </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> tile </td>
   <td style="text-align:left;"> BOOLEAN </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> Whether to tile the output raster </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   

Create a raster from a vector table using an integer (number) field to define output values.  


```sql
SELECT FAIB_FC_TO_RASTER(
'TSA_CLIP', 
'TSA_NUMBER_INT', 
'TSA_CLIP_RASTER_INTFLD'
)  
```

![](RasterFunctions/FAIB_FC_TO_RASTER_1.PNG)      


Create a raster from a vector tagble using a character field.  A VAT is not supplied to map the output raster values and the function will create one on the fly and apply the values to the output raster.  The created VAT will have the name of the output with _VAT tagged onto it.  


```sql
SELECT FAIB_FC_TO_RASTER(
'TSA_CLIP', 
'TSA_NAME', 
'TSA_CLIP_RASTER_NAMEFLD'
)    
```

![](RasterFunctions/FAIB_FC_TO_RASTER_2.PNG)    


Create a raster from a vector table using VAT to define the output values.  The VAT must have a VAL column that defines the output values and must link to the VAT with the valFld argument provided (TSA_NAME in the example)  


```sql
SELECT FAIB_FC_TO_RASTER(
'TSA_CLIP', 
'TSA_NAME', 
'TSA_CLIP_RASTER_NAMEFLD_FROMVAT', 
'TSA_CLIP_RASTER_NAMEFLD_VATEXAMPLE'
)    
```

![](RasterFunctions/FAIB_FC_TO_RASTER_3.PNG)  


[Top](#TOP)    

******
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_RASTER_CLIP  
  
#### Description:  

This function will clip an existing raster by the geometry that you supply to it.  The geometry can be a select GEOMETRY from another feature
class table in Postgres. This function is overloaded and will also accept a WKT Polygon reprsentation to clip by.  See examples.  

The output raster will align with BC Raster Grid standard. 

#### Assumptions & Cautionary Notes:  

The function assumes that the source Raster is in BC Albers projection (SRID: 3005).  
If output raster already exists it will be dropped then recreated with the new raster from this function - be careful!!
  
#### Implementation:   
This is an overloaded function - there are 2 different ways to execute this function.  Same function name call but you can use either a text Polygon Constructor or a Geometry to define the Area of Interest - drawPoly  
  
 

```sql
FAIB_RASTER_CLIP(outRaster VARCHAR, srcRaster VARCHAR, clipper GEOMETRY) RETURNS VARCHAR
```
  
**Note: drawPoly must be a text Polygon Constructor.**
[PostGIS Well Known Text](https://postgis.net/docs/using_postgis_dbmanagement.html#OpenGISWKBWKT)


```sql
FAIB_RASTER_CLIP(outRast VARCHAR, srcRast VARCHAR, clipper TEXT) RETURNS VARCHAR  
```
    
#### Parameters:   
<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="3"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> outRaster </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> Output Raster Name </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> srcRaster </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The source Raster to clip from </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> clipper </td>
   <td style="text-align:left;"> GEOMETRY or TEXT WKT Polygon </td>
   <td style="text-align:left;"> '*' </td>
   <td style="text-align:left;"> The Geometry to clip the source Raster by or a WKT Polygon text </td>
  </tr>
</tbody>
</table>

#### Usage & Examples: 

Clip a raster using a single geometry (returned from subquery against vector table)    


```sql
SELECT FAIB_RASTER_CLIP(
'BEC_TSA_EXTENT_RASTER_TSA27', 
'BEC_TSA_EXTENT_RASTER', 
(SELECT WKB_GEOMETRY FROM TSA_CLIP WHERE TSA_NUMBER = '27')
)
```

![](RasterFunctions/FAIB_RASTER_CLIP_1.PNG)  


Clip a raster using multiple geometries (returned from subquery against vector table)    


```sql
SELECT FAIB_RASTER_CLIP(
'BEC_TSA_EXTENT_RASTER_TSA270111', 
'BEC_TSA_EXTENT_RASTER', 
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE TSA_NUMBER IN ('27', '01', '11'))
)  
```

![](RasterFunctions/FAIB_RASTER_CLIP_2.PNG)   

[Top](#TOP)

******
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_RASTER_FROM_VECTOR  
  
#### Description:  
This function is designed to generate a raster from a source vector table within an area of interest (drawPoly).

The area of interest can be a WGS 84 Well Known Text Polygon constructor (as would be created by a use in the CLUS Caribou App) or can be a Geometry object supplied by a query to another vector table. 

The function allows you to generate a mask (1 value) raster output or generate values using a Numeric field from the vector source or with a  Value Attribute Table.  

You can further supply a where clause to filter what features from the source vector table that you would like to have included in the output raster.   

See examples for the possibilities. 

The output raster will align with BC Raster Grid standard. 

#### Assumptions & Cautionary Notes:  
The function assumes that the source Raster is in BC Albers projection (SRID: 3005).  

If using a WKT Text Polygon as the drawPoly, it must be composed with coordinates in WGS 84 (SRID:4326)

If output raster already exists it will be dropped then recreated with the new raster from this function - be careful!!

If including a whereClause with enclosed strings in the criteria you must put a space at the end to enable proper quote embedding.  
For example: whereClause:='ZONE_ALL LIKE ''ESSF%'' '  (NOT - whereClause:='ZONE_ALL LIKE ''ESSF%''')

#### Implementation:  
**This is an overloaded function - there are 2 different ways to execute this function.  Same function name call but you can use either a text Polygon Constructor or a Geometry to define the Area of Interest - drawPoly**  


```sql
FAIB_RASTER_FROM_VECTOR(outRaster VARCHAR, drawPoly TEXT, srcVect VARCHAR, whereClause VARCHAR DEFAULT '*', vatFld VARCHAR DEFAULT NULL, vat VARCHAR DEFAULT NULL, mask BOOLEAN DEFAULT FALSE, rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT False) RETURNS VOID
```

**Note: drawPoly must be a text Polygon Constructor.**  
[PostGIS Well Known Text](https://postgis.net/docs/using_postgis_dbmanagement.html#OpenGISWKBWKT)       


```sql
FAIB_RASTER_FROM_VECTOR(outRaster VARCHAR, drawPoly GEOMETRY, srcVect VARCHAR, whereClause VARCHAR DEFAULT '*', vatFld VARCHAR DEFAULT NULL, vat VARCHAR DEFAULT NULL, mask BOOLEAN DEFAULT FALSE, rastSize NUMERIC DEFAULT 100.00, rastPixType VARCHAR DEFAULT '32BF', noData NUMERIC DEFAULT 0, tile BOOLEAN DEFAULT False) RETURNS VOID
```
 


#### Parameters:  
<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="3"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> outRaster </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> Output Raster Name </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> drawPoly </td>
   <td style="text-align:left;"> TEXT (WKT Polygon) or GEOMETRY </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The area of interest, represented as a WKT Polygon text string or a Geometry </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> srcVect </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The source vector table to generate the raster from </td>
  </tr>
  <tr grouplength="8"><td colspan="4" style="border-bottom: 1px solid;"><strong>Optional Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> whereClause </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> '*' </td>
   <td style="text-align:left;"> A Where clause to define what we want to include in the output from the source, within the area of interest </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> vatFld </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> The field in the source vector and VAT to join to </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> vat </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> The name of the VAT </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> mask </td>
   <td style="text-align:left;"> BOOLEAN </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> Whether to Mask the output.  Mask will create an output with values of 1 where criteria met, within AOI.  False will retain values from VAT </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastSize </td>
   <td style="text-align:left;"> NUMERIC </td>
   <td style="text-align:left;"> 100 </td>
   <td style="text-align:left;"> Size of output raster cells </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastPixType </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> 32BF </td>
   <td style="text-align:left;"> Pixel type of output raster </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> noData </td>
   <td style="text-align:left;"> NUMERIC </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> No Data value </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> tile </td>
   <td style="text-align:left;"> BOOLEAN </td>
   <td style="text-align:left;"> False </td>
   <td style="text-align:left;"> Whether to tile the ouptut raster </td>
  </tr>
</tbody>
</table>

#### Usage & Examples: 

#####  Examples using a WKT Polygon for AOI

Generate an output raster with a WKT Polygon using a Character field.  VAT is automatically generated and applied to output.  All values (\*) are retained in the output. 


```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_NOVAT_CHARFIELD', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_ZONE_CLIP', 
mask:=FALSE, 
whereClause:='*', 
vatFld:='ZONE_ALL'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_1.PNG)  

Generate an output raster with a WKT Polygon using the VAT from the above example.  Use a where clause to select values based on a selection from the associated VAT. 


```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_VAT_FILTER', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_ZONE_CLIP', 
mask:=FALSE, 
whereClause:='ZONE_ALL LIKE ''ESSF%'' ', 
vatFld:='ZONE_ALL', 
vat:='BEC_ZONE_CLIP_RASTER_NOVAT_CHARFIELD_VAT'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_2.PNG)  

Generate an output raster with a WKT Polygon using the VAT from the above example.  Use a where clause to select values based on a selection from the associated VAT but Mask the output. 


```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_VAT_FILTER_MASK', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))',
'BEC_ZONE_CLIP', 
mask:=TRUE, 
whereClause:='ZONE_ALL LIKE ''ESSF%'' ', 
vatFld:='ZONE_ALL', 
vat:='BEC_ZONE_CLIP_RASTER_NOVAT_CHARFIELD_VAT'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_3.PNG) 

Generate an output raster with a WKT Polygon and Mask the output.  All values (\*) are retained in the output. 


```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_MASK_ALL',
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_ZONE_CLIP', 
mask:=TRUE
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_4.PNG)  


#####  Examples using a Geometry for AOI


Generate an output raster with a Geometry as AOI with a Character field for rasterizing.  A VAT will automatically be generated with the name of the output raster with _VAT tagged on the end. Include all features within the AOI using the wildcard \* whereClause.  


```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_FROMGEOM_NOVAT_CHARFIELD',
(SELECT WKB_GEOMETRY FROM TSA_CLIP WHERE UPPER(TSA_NAME) LIKE 'REV%'), 
'BEC_ZONE_CLIP', 
mask:=FALSE, 
whereClause:='*', 
vatFld:='ZONE_ALL'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_5.PNG)  


Generate an output raster with a Geometry as AOI (multiple geometries unioned) with a VAT lookup and whereClause to filter the output. 


```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_FROMGEOM_VAT_FILTER', 
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE UPPER(TSA_NAME) IN ('OKANAGAN TSA', 'ROBSON VALLEY TSA')), 
'BEC_ZONE_CLIP', 
mask:=FALSE, 
whereClause:='ZONE_ALL LIKE ''ESSF%'' OR ZONE_ALL LIKE ''ICH%'' ', 
vatFld:='ZONE_ALL', 
vat:= 'BEC_ZONE_CLIP_RASTER_FROMGEOM_NOVAT_CHARFIELD_VAT'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_6.PNG)  

Generate an output raster with a Geometry as AOI (multiple geometries unioned) with a VAT lookup and whereClause to filter the output. Mask the output.  


```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_FROMGEOM_VAT_FILTER',
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE UPPER(TSA_NAME) IN ('OKANAGAN TSA', 'ROBSON VALLEY TSA')), 
'BEC_ZONE_CLIP', 
mask:=TRUE, 
whereClause:='ZONE_ALL LIKE ''ESSF%'' OR ZONE_ALL LIKE ''ICH%'' ', 
vatFld:='ZONE_ALL', 
vat:= 'BEC_ZONE_CLIP_RASTER_FROMGEOM_NOVAT_CHARFIELD_VAT'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_7.PNG)  


Generate an output raster with a Geometry as AOI with and Mask the entire output area.  



```sql
SELECT FAIB_RASTER_FROM_VECTOR(
'BEC_ZONE_CLIP_RASTER_FROMGEOM_MASK_ALL', 
(SELECT WKB_GEOMETRY FROM TSA_CLIP WHERE UPPER(TSA_NAME) LIKE 'REVEL%'), 
'BEC_ZONE_CLIP', 
mask:=TRUE,
whereClause:='*'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_VECTOR_8.PNG)  


[Top](#TOP)

******
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_RASTER_FROM_RASTER  
  
#### Description:  
This function is designed to generate a raster from a existing source raster within an area of interest (drawPoly).

The area of interest can be a WGS 84 Well Known Text Polygon constructor (as would be created by a use in the CLUS Caribou App) or can be a Geometry object supplied by a query to another vector table. 

The function allows you to generate a mask (1 value) raster output or generate values using a Value Attribute Table (VAT) to map the output values.  

You can further supply a where clause to filter what features from the source vector table that you would like to have included in the output raster.  The where clause can be related to the VAT that you supply to filter for values or you can use a list of raster numeric values or a range of values or a combination therof.  (1, 2, 3) or (1, 2, 3, 10-40, 50-90) or (1-10) etc.   

See examples for the possibilities. 

The output raster will align with BC Raster Grid standard. 

#### Assumptions & Cautionary Notes:  
The function assumes that the source Raster is in BC Albers projection (SRID: 3005).  

If using a WKT Text Polygon as the drawPoly, it must be composed with coordinates in WGS 84 (SRID:4326)

If output raster already exists it will be dropped then recreated with the new raster from this function - be careful!!

If including a whereClause with enclosed strings in the criteria you must put a space at the end to enable proper quote embedding.  
For example: whereClause:='ZONE_ALL LIKE ''ESSF%'' '  (NOT - whereClause:='ZONE_ALL LIKE ''ESSF%''')

#### Implementation:  
**This is an overloaded function - there are 2 different ways to execute this function.  Same function name call but you can use either a text Polygon Constructor or a Geometry to define the Area of Interest - drawPoly**  


```sql
FAIB_RASTER_FROM_RASTER(
outRaster VARCHAR, 
drawPoly TEXT, 
srcRast VARCHAR, 
rastVal VARCHAR DEFAULT '*', 
rastVAT VARCHAR DEFAULT NULL, 
mask BOOLEAN DEFAULT FALSE,
rastSize NUMERIC DEFAULT 100.00, 
rastPixType VARCHAR DEFAULT '32BF', 
noData NUMERIC DEFAULT 0, 
tile BOOLEAN DEFAULT False
) RETURNS VOID
```

**Note: drawPoly must be a text Polygon Constructor.**  
[PostGIS Well Known Text](https://postgis.net/docs/using_postgis_dbmanagement.html#OpenGISWKBWKT)       


```sql
FAIB_RASTER_FROM_RASTER(
outRaster VARCHAR, 
drawPoly GEOMETRY, 
srcRast VARCHAR, 
rastVal VARCHAR DEFAULT '*', 
rastVAT VARCHAR DEFAULT NULL, 
mask BOOLEAN DEFAULT FALSE,
rastSize NUMERIC DEFAULT 100.00, 
rastPixType VARCHAR DEFAULT '32BF', 
noData NUMERIC DEFAULT 0, 
tile BOOLEAN DEFAULT False
) RETURNS VOID
```
 


#### Parameters:  
<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="3"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> outRaster </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> Output Raster Name </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> drawPoly </td>
   <td style="text-align:left;"> TEXT (WKT Polygon) or GEOMETRY </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The area of interest, represented as a WKT Polygon text string or a Geometry </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> srcRast </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The source raster to generate the raster from </td>
  </tr>
  <tr grouplength="7"><td colspan="4" style="border-bottom: 1px solid;"><strong>Optional Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastVal </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> '*' </td>
   <td style="text-align:left;"> The value or list of values from the source raster to include in the output.  If using a VAT you can form this parameter as a Where clause to define what we want to include in the output from the source, within the area of interest </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastVAT </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> The VAT to apply for using a Where Clause in the rastVal parameter </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> mask </td>
   <td style="text-align:left;"> BOOLEAN </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> Whether to Mask the output.  Mask will create an output with values of 1 where criteria met, within AOI.  False will retain values from VAT </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastSize </td>
   <td style="text-align:left;"> NUMERIC </td>
   <td style="text-align:left;"> 100 </td>
   <td style="text-align:left;"> Size of output raster cells </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> rastPixType </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> 32BF </td>
   <td style="text-align:left;"> Pixel type of output raster </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> noData </td>
   <td style="text-align:left;"> NUMERIC </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> No Data value </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> tile </td>
   <td style="text-align:left;"> BOOLEAN </td>
   <td style="text-align:left;"> False </td>
   <td style="text-align:left;"> Whether to tile the ouptut raster </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   

#####  Examples using a WKT Polygon for AOI  

Generate an output raster with a WKT Polygon with no filtering output.  


```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_AOI_MASK', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_TSA_EXTENT_RASTER', 
mask:=TRUE
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_1.PNG)  


Generate an output raster with a WKT Polygon retaining all values.  


```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_AOI_RETAIN', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_TSA_EXTENT_RASTER'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_2.PNG)  


Generate an output raster with a WKT Polygon querying the VAT for ESSF and ICH zones and retaining source raster values.  


```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_AOI_RETAIN_ESSFICH', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_TSA_EXTENT_RASTER', 
rastVal:= 'ZONE IN (''ESSF'', ''ICH'') ', 
rastVAT:= 'BEC_TSA_EXTENT_RASTER_VAT'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_3.PNG)  



Generate an output raster with a WKT Polygon querying the VAT for ESSF and ICH zones and masking.   


```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_AOI_RETAIN_ESSFICH', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_TSA_EXTENT_RASTER', 
rastVal:= 'ZONE IN (''ESSF'', ''ICH'') ', 
rastVAT:= 'BEC_TSA_EXTENT_RASTER_VAT',
mask:=TRUE
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_4.PNG)  



Generate an output raster with a WKT Polygon and retain all the values from the source raster within that area.   


```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_AOI_RASTVALS_ALL', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_TSA_EXTENT_ZONEALL_RASTER', 
rastVal:= '*', 
mask:=FALSE
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_5.PNG)  


Generate an output raster with a WKT Polygon and select for particular values and a range of values using the rastVAl parameter.   

When querying for source raster values you can use individual values or a range of values.  

Examples:  
rastVal:= '*'   
rastVal:= '4, 8, 48'     
rastVal:= '4, 8-10, 12, 30-35'  
etc.  


```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_AOI_RASTVALS_EX1', 
'POLYGON((-118.473196412943 51.6955188330737,-118.982643618749 51.3438924145354,-118.444851411751 51.0748582423647,-117.985076049477 51.3973510159727,-118.473196412943 51.6955188330737))', 
'BEC_TSA_EXTENT_ZONEALL_RASTER', 
rastVal:= '4, 8, 30-50', 
mask:=FALSE
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_6.PNG)  


Generate an output raster using the geometry from another vector table as the area of interest.  Masking the output. No query filter (rastVAl) applied.   



```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_GEOM_MASK', 
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE UPPER(TSA_NAME) LIKE '%OO%'), 
'BEC_TSA_EXTENT_RASTER', 
mask:=TRUE
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_7.PNG)  


Generate an output raster using the geometry from another vector table as the area of interest.  Retain source values in the output. No query filter (rastVal) applied. 



```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_GEOM_RETAIN', 
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE UPPER(TSA_NAME) LIKE '%OO%'), 
'BEC_TSA_EXTENT_RASTER', 
mask:=FALSE
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_8.PNG)  

Generate an output raster using the geometry from another vector table as the area of interest.  Retain source values in the output. Query for Zones ICH and ESSF using a related VAT. 



```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_GEOM_RETAIN_ESSFICH', 
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE UPPER(TSA_NAME) LIKE '%OO%'), 
'BEC_TSA_EXTENT_RASTER', 
mask:=FALSE,
rastVal:= 'ZONE IN (''ESSF'', ''ICH'') ', 
rastVAT:= 'BEC_TSA_EXTENT_RASTER_VAT'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_9.PNG) 


Generate an output raster using the geometry from another vector table as the area of interest.  Mask the values in the output. Query for Zones ICH and ESSF using a related VAT. 



```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_GEOM_RETAIN_ESSFICH', 
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE UPPER(TSA_NAME) LIKE '%OO%'), 
'BEC_TSA_EXTENT_RASTER', 
mask:=TRUE,
rastVal:= 'ZONE IN (''ESSF'', ''ICH'') ', 
rastVAT:= 'BEC_TSA_EXTENT_RASTER_VAT'
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_10.PNG) 


Generate an output raster using the geometry from another vector table as the area of interest.  Mask the values in the output. Query for Zones ICH and ESSF using a related VAT. 



```sql
SELECT FAIB_RASTER_FROM_RASTER(
'BEC_TSA_GEOM_RETAIN_RASTVALS', 
(SELECT ST_UNION(WKB_GEOMETRY) FROM TSA_CLIP WHERE UPPER(TSA_NAME) LIKE '%OO%'), 
'BEC_TSA_EXTENT_RASTER', 
mask:=FALSE,
rastVal:= '1, 3, 8', 
)
```

![](RasterFunctions/FAIB_RASTER_FROM_RASTER_11.PNG) 

[Top](#TOP)  

******  
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
# Other Functions  

Theese are some other functions that support the Main functions but might have some utility on their own outside the dependency of the above functions.

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_GET_GEOMETRY_COLUMN

#### Description:  
This function will return the name of the geometry column for the supplied table name.  

#### Assumptions & Cautionary Notes:  

N/A

#### Implementation:  

```sql
FAIB_GET_GEOMETRY_COLUMN(fcName VARCHAR) RETURNS VARCHAR
```


#### Parameters:  

<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="1"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> fcName </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the feature class table you want the Geometry Column name of </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   


```sql
SELECT FAIB_GET_GEOMETRY_COLUMN('TSA_CLIP')
```

![](RasterFunctions/FAIB_GET_GEOMETRY_COLUMN_1.PNG)      

[Top](#TOP)  

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_GET_RASTER_COLUMN

#### Description:  
This function will return the name of the raster column for the supplied table name.  

#### Assumptions & Cautionary Notes:  

N/A

#### Implementation:  

```sql
FAIB_GET_RASTER_COLUMN(raster VARCHAR) RETURNS VARCHAR
```


#### Parameters:  

<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="1"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> raster </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the raster table you want the Raster Column name of </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   


```sql
SELECT FAIB_GET_RASTER_COLUMN('BEC_TSA_EXTENT_RASTER')  
```

![](RasterFunctions/FAIB_GET_RASTER_COLUMN_1.PNG)      

[Top](#TOP)  

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_CREATE_VAT

#### Description:  
This function will generate a Value Atrribute Table using the source table and field specified.  The function groups the source table on the field supplied and then generates a sequential, unique number for each grouping into the output table name.  The output table will contain a VAL field with the numerica value assigned to the source field group, will have a 'Source_Table' field track the source of the output data and will have the vatFld supplied. 

#### Assumptions & Cautionary Notes:  

Will overwrite any existing output table name. 

#### Implementation:  

```sql
FAIB_CREATE_VAT(srcTab VARCHAR, vatFld VARCHAR, outTab VARCHAR) RETURNS VOID
```


#### Parameters:  

<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="3"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> srcTab </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the source table to generate the VAT from </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> vatFld </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the field in the Source Table to genrate the VAT from </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> outTab </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the output VAT table </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   


```sql
SELECT FAIB_CREATE_VAT('TSA_CLIP', 'TSA_NAME', 'TSA_CLIP_NAME_VAT')
```

![](RasterFunctions/FAIB_CREATE_VAT_1.PNG)      

[Top](#TOP)  

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_GET_BC_RASTER_ORIGIN

#### Description:  
This function is used by the FAIB_FC_TO_RASTER function and is used to return an origin from a source vector feature class that will align with the BC Standard Raster grid.  Raster functions in PosgGIS use and Upper Left (UL) origin but this function can generate a BC standard origin for Upper Left (UL), Lower Left (LL), Upper Right (UR) or Lower Right (LR) origins as well.  If those are needed for some reason!

#### Assumptions & Cautionary Notes:  

Returns a Numeric array.  Index 1 is X value, Index 2 is Y value

#### Implementation:  

```sql
FAIB_GET_BC_RASTER_ORIGIN(fc VARCHAR, geom VARCHAR, origin CHAR(2) DEFAULT 'UL') RETURNS NUMERIC[]
```


#### Parameters:  

<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="3"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> fc </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the source vector feature class table to generate origin from </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> geom </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the geometry field in the Source Table </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> origin </td>
   <td style="text-align:left;"> CHAR(2) </td>
   <td style="text-align:left;"> UL </td>
   <td style="text-align:left;"> The origin that you want returned.  UL, UR, LL, LR </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   


```sql
SELECT unnest(FAIB_GET_BC_RASTER_ORIGIN('TSA_CLIP', 'WKB_GEOMETRY', 'UL'))
```

![](RasterFunctions/FAIB_GET_BC_RASTER_ORIGIN_1.PNG)      


```sql
SELECT (FAIB_GET_BC_RASTER_ORIGIN('TSA_CLIP', 'WKB_GEOMETRY', 'UL'))[1]
```

![](RasterFunctions/FAIB_GET_BC_RASTER_ORIGIN_2.PNG)      


```sql
SELECT (FAIB_GET_BC_RASTER_ORIGIN('TSA_CLIP', 'WKB_GEOMETRY', 'UL'))[2]
```

![](RasterFunctions/FAIB_GET_BC_RASTER_ORIGIN_3.PNG)      



[Top](#TOP)  

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_GET_BC_RASTER_COORDVAL

#### Description:  
This function is used by the FAIB_GET_BC_RASTER_ORIGIN function.  This functions takes a coordinate value and will either 'SHRINK' or 'GROW' the value to create a value that is nearest to align with the BC Raster Grid Standard.

#### Assumptions & Cautionary Notes:  

N/A

#### Implementation:  

```sql
FAIB_GET_BC_RASTER_COORDVAL(coord NUMERIC, type VARCHAR DEFAULT 'SHRINK') RETURNS NUMERIC
```


#### Parameters:  

<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="2"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> coord </td>
   <td style="text-align:left;"> NUMERIC </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The coordinate value to align </td>
  </tr>
  <tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> type </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> SHRINK </td>
   <td style="text-align:left;"> Whether to Grow or Shrink the value.  This would be dependent on whether you are trying to align to a UL, LL, UR, LR orign type and whether the coordinate is the X or the Y. </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   


```sql
SELECT FAIB_GET_BC_RASTER_COORDVAL(1423260.47995651, 'GROW')
```

![](RasterFunctions/FAIB_GET_BC_RASTER_COORDVAL_1.PNG)      



```sql
SELECT FAIB_GET_BC_RASTER_COORDVAL(1423260.47995651, 'SHRINK')
```

![](RasterFunctions/FAIB_GET_BC_RASTER_COORDVAL_2.PNG)    


```sql
SELECT FAIB_GET_BC_RASTER_COORDVAL((SELECT ST_YMIN(geom) FROM (SELECT ST_EXTENT(WKB_GEOMETRY) geom FROM TSA_CLIP) foo)::NUMERIC, 'GROW')
```

![](RasterFunctions/FAIB_GET_BC_RASTER_COORDVAL_3.PNG)    

[Top](#TOP)  

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
## FAIB_R_RASTERINFO

#### Description:  
This function is deisnged to be used/called from R.  It returns a numeric array of data that can be used to create a raster layer object in R from the source raster provided.  The values returned in the array are: XMax, XMin, YMax, YMin, Number of Columns, Number of Rows, then a list of all the values of the raster. 

#### Assumptions & Cautionary Notes:  

N/A

#### Implementation:  

```sql
FAIB_R_RASTERINFO(srcRast VARCHAR) RETURNS DOUBLE PRECISION[]
```


#### Parameters:  

<table class="table table-striped table-bordered table-hover" style="font-size: 14px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Name </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Type </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Default </th>
   <th style="text-align:left;background-color: #e6e6e6;text-align: center;font-size: 16px;"> Description </th>
  </tr>
 </thead>
<tbody>
  <tr grouplength="1"><td colspan="4" style="border-bottom: 1px solid;"><strong>Required Parameters</strong></td></tr>
<tr>
   <td style="text-align:left; padding-left: 2em;font-weight: bold;" indentlevel="1"> srcRast </td>
   <td style="text-align:left;"> VARCHAR </td>
   <td style="text-align:left;"> N/A </td>
   <td style="text-align:left;"> The name of the raster to generate information for </td>
  </tr>
</tbody>
</table>

#### Usage & Examples:   


```sql
SELECT unnest(FAIB_R_RASTERINFO('BEC_TSA_EXTENT_RASTER'))
```

![](RasterFunctions/FAIB_R_RASTERINFO_1.PNG)    

[Top](#TOP)  

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
# Helper Functions  
This are functions that are also dependents of the Main functions.  These ones likely have little use outside of their dependent use or are quite straightforward to understaand what they do. 

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->

## FAIB_GET_DATA_TYPE

#### Description:  
This function returns the data type of table column.  Is used to determine whether a field is Numerice or Character to define whether to create  Value Attribute Table or raster off of supplied column if Numeric. 

#### Implementation:  

```sql
FAIB_GET_DATA_TYPE(tab regclass, col text)
```

[Top](#TOP)  

****** 
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->

## FAIB_DATATYPE_ISNUM

#### Description:  
This function returns a boolean (True) if the datatype is Numeric.  Used in combination with FAIB_GET_DATA_TYPE. 

#### Implementation:  

```sql
FAIB_DATATYPE_ISNUM(type text)
```

[Top](#TOP)  

****** 

<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->

## FAIB_DATATYPE_ISCHAR

#### Description:  
This function returns a boolean (True) if the datatype is Character.  Used in combination with FAIB_GET_DATA_TYPE. 

#### Implementation:  

```sql
FAIB_DATATYPE_ISCHAR(type text)
```

[Top](#TOP)  

****** 

<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->

## FAIB_FORMAT_RASTVALS

#### Description:  
This function takes a text representation of raster values ('1, 2, 3, 4-10, 20-25') and returns a list of all the values.  In other words, it formats the string to draw out the values with a range (x-y) and is used in the FAIB_RASTER_FROM_RASTER function to properly format a seledction to apply to queries to generate output raster.  

#### Implementation:  

```sql
FAIB_FORMAT_RASTVALS(valText text)
```

#### Usage & Examples:   


```sql
SELECT FAIB_FORMAT_RASTVALS('1,2,3-8,12')
```

![](RasterFunctions/FAIB_FORMAT_RASTVALS_1.PNG)      


```sql
SELECT FAIB_FORMAT_RASTVALS('1-10, 14, 18, 20-25')
```

![](RasterFunctions/FAIB_FORMAT_RASTVALS_2.PNG)     

[Top](#TOP)    

******  
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->
<!-- -------------------------------------------------------------------------------------------------------------------------------- -->

## FAIB_GET_RASTVALS_OPPOSITE

#### Description:  
This function takes a text representation of raster values and a source raster and will return values in the raster that are not contained in hte supplied list.  This is needed for doing masking and value reclassification in the FAIB_RASTER_FROM_RASTER function.    

#### Implementation:  

```sql
FAIB_GET_RASTVALS_OPPOSITE(srcRast VARCHAR, rastVals text)  
```

#### Usage & Examples:   


```sql
SELECT (pvc).VALUE, (pvc).COUNT FROM (SELECT ST_VALUECOUNT(rast, 1) pvc FROM BEC_TSA_AOI_RASTVALS_EX1) foo ORDER BY (PVC).VALUE ASC

SELECT FAIB_GET_RASTVALS_OPPOSITE('BEC_TSA_AOI_RASTVALS_EX1', '4, 8, 31')
```

![](RasterFunctions/FAIB_GET_RASTVALS_OPPOSITE_1.PNG)   


![](RasterFunctions/FAIB_GET_RASTVALS_OPPOSITE_2.PNG)    



```sql

SELECT FAIB_GET_RASTVALS_OPPOSITE('BEC_TSA_AOI_RASTVALS_EX1', (SELECT FAIB_FORMAT_RASTVALS('40-50')))
```

![](RasterFunctions/FAIB_GET_RASTVALS_OPPOSITE_3.PNG)      

[Top](#TOP)  

******   

