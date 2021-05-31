---
title: "CLUS Quick Start Tutorial"
author: "Tyler Muhly"
date: "02/12/2020"
output: 
  html_document:
    keep_md: true
---

# Caribou and Land Use Simulator (CLUS) Quick Start Tutorial
The CLUS quick-start tutorial provides step-by-step instructions on how to use CLUS. It is designed to familiarize you with creating and running a simple forest harvest scenario analysis with CLUS. It takes you through all the steps needed to set-up and run CLUS from scratch.

For an overview of how the CLUS model works, we recommend reading our [wiki](https://github.com/bcgov/clus/wiki). This provides an introduction to the framework and components of CLUS that may facilitate understanding this tutorial. 

## 1. Download Software
CLUS is primarily built using the [R programming language](https://www.r-project.org/), and thus requires you to install R software. You can download program R for Windows [here](https://cran.r-project.org/bin/windows/base/). Program R has a very simple graphical user interface, and therefore we also recommend that you download the free version of [RStudio](https://rstudio.com/products/rstudio/download/). RStudio is an integrated development environment for working with R code. It provides various windows and tabs for interacting with and running R code, downloading and loading R packages, interfacing with GitHub (more on that below), and managing R ['objects'](https://www.datacamp.com/community/tutorials/data-types-in-r). We also recommend you download ['git' software](https://gitforwindows.org/) to interface and work with the model code. 

To work with our databases, you will also need to download [pgAdmin](https://www.pgadmin.org/) software. This software will allow you to connect to and work with PostgreSQL databases, which are the key data structure used by CLUS. 

To manage and work with spatial data, you will also need to download [OSGeo4W](https://trac.osgeo.org/osgeo4w/). This contains QGIS, GDAL/OGR, and GRASS open source software programs that are needed to do some spatial data manipulation.

If you are a government employee, you may want to download these software as approved by your information technology department.

In summary, the first step of working with CLUS is to download the following software

* [program R](https://cran.r-project.org/bin/windows/base/)
* [RStudio](https://rstudio.com/products/rstudio/download/)
* [git](https://gitforwindows.org/)
* [pgAdmin](https://www.pgadmin.org/)
* [OSGeo4W](https://trac.osgeo.org/osgeo4w/)

### 1.1 R Packages
When working with R you will soon find that you need to download various [packages](https://rstudio.com/products/rpackages/). Packages are essentially bundles of specialized, self-contained code functions to manipulate, analyze or visualize information. Packages are written by R developers and stored on the [Comprehensive R Archive Network (CRAN) repository](https://cran.r-project.org/web/packages/available_packages_by_name.html). These packagaes must meet certain QA/QC
standards, and are typically reliable and stable. 

Here we do not list all of the R Packages needed to use the CLUS model. There are many packages, they will vary depending on what aspects of CLUS are used, and they will likely evolve over time. Instead, here I provide a brief description of how to download R packages from RStudio.

Within the RStudio interface you will see in the bottom-right window a "Packages" tab, with a button to "Install", and beneath that a list of packages downloaded in your package library. If you click on the "Install" button it will open a window where you can enter the package name to install it from CRAN. Once a pacakge is downloaded, you don't need to download it again (unless an update is required).  

![](images/rstudio_pakages.jpg)

Packages that you will need to run CLUS are typically listed within specific CLUS model scripts, so you can download them as you need them. Packages you need are called using the *library()* or *require()* commands in the script. You'll also find that you will get an error if you are missing a package needed to run a specific R function. In this case, check which function is getting the error and download the necessary package. 

## 2. Download the Model Code from GitHub
Once you are up and running with R Studio you can 'clone' the CLUS model code (i.e., make local copy of it) so you can run it from your computer. We store the CLUS model code in the [BC government GitHub repositories](https://github.com/bcgov). If you are a BC government employee, we recommend that you sign-up for a GitHub account, and review the [BC government policies](https://github.com/bcgov/BC-Policy-Framework-For-GitHub/blob/master/BC-Open-Source-Development-Employee-Guide/README.md) on its use. 

The CLUS repository is located [here](https://github.com/bcgov/clus.git). You will notice the GitHub webpage contains a 'folder' structure with all the code. This can be considered as a 'master' copy of the code. GitHub allows for multiple people to work with the code simultaneously. You will work with a local copy of the code. In the next section we will describe more how to use Git and GitHub.

To clone the CLUS repository, open RStudio, click on the "File" tab in the top left and then click "New Project". This will open a new window:

![](images/git.jpg)

In this window, select "Version Control" and then select "Git". This will open a window where you enter the Repository URL (https://github.com/bcgov/clus.git), the name of the directory (clus) and then location where you want to save a copy of the repository. We recommend copying the code to a local folder (not a network folder).

![](images/git_repo.jpg)

Once you create the repository, it will copy the code to the folder directory you created. You will notice it has the same folder structure as the website. 

In your RStudio console, the bottom-right window "Files" tab shows the directory for the code repository. We will describe later how to navigate these folders to run CLUS. 

## 3. Version Control and Working with GitHub
In the top-right window or RStudio you will see a "Git" tab. If you click on that you will see a series of buttons beneath it, including: "Diff", "Commit", "Pull", and "Push". You will also see that above the tab in the the top-right there is some text beside an "R-box" symbol. This indicates the repository you are currently using. It should say "clus". You will also notice a symbol with two purple rectangles, beside some text that says "master". This indicates the 'branch' of the repository that you are working in.

![](images/git_rstudio.jpg)

GitHub branches can be considered as 'working copies' of code (see image below). Conceptually, they are used to 'split off' working code from the master branch. This work flow is designed to minimize frequent small changes to the 'master' copy of the code. However, this also requires you to re-integrate your branch with the main branch (called a "Pull Request") when you want to incorporate your changes to the code into the master branch. Typically you do this after you have made significant changes to the code, have tested the code to make sure it functions properly, and are reasonably confident that it will not conflict with the master code.  

![](images/github_branch.png)

For now, we will create a new branch of the master code for you to work in. This will minimize the potential for creating errors in the model code. To create a new branch click on the symbol with two purple rectangles. This will open a new window called "New Branch" where you can enter a branch name (we recommend you use your last name for now). Leave the Remote as "origin" and "Sync branch with remote" checked.

![](images/git_branch2.jpg)

You will now notice that the name of the new branch appears in the text drop-down. Now you are working in a separate branch of the code. Any changes you make to the code will only occur in the branch you created, as long as it is the selected branch in the drop-down text box. 

Now, in the "File" tab of the bottom-right window of RStudio, click on the "README.md" file. This should open a script document in the top-left window of RStudio, and you should see some text describing CLUS. The README.md file is a 'front page' for the CLUS GitHub repository, providing users some basic information about what CLUS is, and how to learn more. 

Scroll down to the "Contributors" section of the README.md file and add your name and contact details to the list of contributors. Save the edits (you can click the floppy disk symbol in the top left of the window), and then click on the "Git" tab in the top-right window of RStudio. You should see the README.md file show up in the window under "Path". 

Click on the "Commit" button and it opens a new window with three windows in it. This window is used to commit changes to the code to the repository. In the top-left you will see the file name under "Path", with a check box (under 'staged') and a blue box with 'M' in it under "Status". Beneath that window you will see a window with the 'code' (simple text in this case), and the code you added highlighted in green. In the top-right is a window where you an add text to add a message to the commit (e.g., a description of the changes you made to the code).  

![](images/git_commit.jpg)

In this window, click the "Staged" box; this defines the files that you want to change. Add a message (e.g., "added Dwight Schrute to list of contributors"), then click the "Commit" button. Another window will open with the command line git code that was run to make the commit, and the result fo the commit (e.g., "1 file changed, 1 insertion(+)"). Close that box, then click the "Push" button. Another window will open, again with command line git code that was run to push the commit to the GitHub repository. This 'saves' the changes to your branch of the file to the GitHub repository. Note that if other people are working in the same branch of the repository, it is good to get in the habit of clicking the "Pull" button (top right window of RStudio). This will integrate changes to the code made by others into your code. 

Since you are working in an independent branch, you will be committing changes to your own version of the model code. However, at some point you will likely want to integrate your code back to the "Master" branch, or integrate changes made to the "Master" branch of code into your branch of code. These are managed through "Pull Requests". Pull Requests are managed through the [CLUS GitHub website](https://github.com/bcgov/clus). You will see a tab called "Pull Request" on the main page of the website. Click on this tab and you will see a green button on the middle-right of the page labeled "New pull request". 

![](images/github_pull1.jpg)

Click on the "New pull request" button. This will open a new page with "Comparing changes" at the top. Underneath that you will see two buttons "base:master" and "compare:master" with an arrow between them pointing right to left. Click on the "base" button and you will get a drop-down menu with the name of the different branches. Select your branch and then click the green "Create pull request" button. This will open a new page where you can add a message to describe the pull request (e.g., "added my name to the contributors list"). Click again on the the green "Create pull request" button. This will send a request to the CLUS team to integrate changes to the code to the master. They will review and approve those changes. Congratulations, you are now a contributor to CLUS! You now have a working understanding of how to use Git and GitHub to manage edits to your CLUS code.

![](images/github_pull2.jpg)

## 4. Set-up a Keyring
CLUS uses networked PostgreSQL databases to store and manage data. To keep these databases and the network secure, we do not post the database access credentials (e.g., password) in the CLUS code. Instead we use the [R package "keyring"](https://cran.r-project.org/web/packages/keyring/keyring.pdf) to store credentials locally and use the "keyring" function to call those credentials from R scripts. 

We have developed an R markdown document for setting up a keyring. In the CLUS repository, navigate to R-> functions->keyring_init.Rmd and open the file. Follow the instructions in the document to set-up the keyring on your local computer. Contact the CLUS core team (Kyle.Lochhead@gov.bc.ca or Elizabeth.Kleynhans@gov.bc.ca or Tyler.Muhly@gov.bc.ca) to obtain the credentials for the PostgreSQL databases. 

Once you are set-up with keyring, you can also use the credentials information to connect to the PostgreSQL databases using PGAdmin software. You may want to connect to the databases using PGAdmin to familiarize yourself with the data. In the 'clus' database on our local network computer, within the "public" schema, there is a table called "pgdbs_data_list". This table describes all the data in the PostgreSQL databases. In addition, within the 'documentation' folder of CLUS, there is a "data_management_guide.Rmd" that describes the "pgdbs_data_list" table and instructions on how to add and update the table, in the event that you need to do so. 

## 5. Create a Shapefile for a Hypothetical Forest Harvest Scenario
Now that you are familiar with the software, some of the model code and some of the CLUS data, we want to introduce you to the process of developing a model to address a hypothetical forest management scenarios. To do that, you will use one of CLUS' web applications to create a shapefile, then develop a hypothetical land use constraint parameter from this shapefile that you will use in the model you are going to build and run.

To create the shapefile, go to the [FAIB apps webpage](http://206.12.91.188:8787/login). Note that you will need to contact Kyle.Lochhead@gov.bc.ca for a username and password. Once you log in, click on the "CLUS Scenario Tool" link. This will take you to a web application with a map on it, and several tabs at the bottom. Note that the app was designed for caribou recovery planning, and thus much of the information within it is tailored to support that. Nevertheless, the app can be used to support any spatial forest management planning problem, i.e., to implement a hypothetical management regime requires a location (e.g., polygon) and a land use order (i.e., the constraint to apply within the defined location).

![](images/scen_tool.jpg)

Here we will use the app to draw a polygon, download it and then create a parameter from it to apply in the CLUS model. We will use the Columbia North caribou herd and the Revelstoke timebr supply area (TSA) as our 'example'. Click on the "Columbia North" herd boundary (located north of Revelstoke). The app will zoom into that herd area. In the top right box of the map, turn on the world imagery, ungulate winter ranges (UWRs) and wildlife habitat areas (WHAs). 

![](images/scen_tool_cn.jpg)

Now 'zoom in' to a portion of the map where you can see cutblocks around the UWRs. Within that area, draw a new polygon (click on the button with a pentagon shape on the left side of the map) in an area between the UWRs, preferably that is forested and where you can see some forestry activity. Once you are done, name the polygon and click on the "Drawn" drop down box; this should display it on the map. You can also edit this polygon by clicking on the button with the box with a pen in it on the left side of the map. 

![](images/scen_tool_cn2.jpg)

Once you have a reasonable polygon that covers a large area, click the "Download Drawn/Edited Shapefile" button. This will save a shapefile in a zipped folder of your downloads folder. Unzip the folder and copy the shapefile to your working folder.  

To create a spatial parameter for the CLUS model, you will need to upload this polygon data to the PostgreSQL database. This needs to be run from the OSGeo4W shell via QGIS (unfortunately, there does not appear to be a way to run the shell directly through R). To use OSGeo4W, search for it in your Windows search bar. Open the app and you will get a simple command line prompt with *C:\>* 

![](images/osgeo.jpg)

Below we provide a chunk of code to upload a shapefile to the PostgreSQL database using gdal functionality (ogr2ogr command) through the OSGeo4W command line interface. Here, if you have not already done so, you will also need to contact the CLUS core team to get database credentials. Within the line of code, *-f* declares the output file format (here we use PostgreSQL); *PG:"dbname=xxxx port=xxxx user=xxxx password=xxxx host=xxxx"*  are the credentials needed to access the database; you need to provide the location of the shapefile on your hard drive; *-overwrite* allows you to delete and recreate any existing data; *-a_srs* refers to the spatial reference system, and here we use *EPSG:3500* (which is NAD83/BC Albers, the provincial standard for spatial data); *-progress* displays a progress bar in the command line terminal; *--config* is a configuration command, and here we use it to apply the *PG_USE_COPY* command, which uses the PostgreSQL COPY command for inserting data to PostgreSQL that is faster than the default INSERT.COPY command; *-nlt* is used to define the geometry of spatial data (e.g., point, line, polygon), and here we use the *PROMOTE_TO_MULTI* which promotes spatial data that mix polygon or multipolygons (which is the case for many polygonal datasets) to the multipolygons type. Copy and paste the code below into the OSGeo4W command line and hit enter. 

For more on gdal and ogr2ogr command functionality see [here](https://gdal.org/programs/ogr2ogr.html) and [here](https://gdal.org/drivers/vector/pg.html).


```r
ogr2ogr -f PostgreSQL PG:"dbname=xxxx port=xxxx user=xxxx password=xxxx host=xxxx" C:\\Work\\shapefile_name.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI
```

Once the command has finished running, open the pgAdmin application. You will need to use the same credentials to connect to the database using pgAdmin. To do this, right click on "Servers", select "Create", "Server" and then enter the credentials in the "Connection" tab of the window that opens. You will then see the "clus" server in the list of servers.     
![](images/pgadmin.jpg)

Click on the "clus" server and it opens up a series of drop down menus. Click on "Schemas", then "Public" and "Tables". This is where much of the CLUS data is stored, and you should be able to navigate to and view the data table you just created. 

You will note that the "clus" database is organized into schemas: "archive", "caribou", "public", and "rast".  The "archive" schema is where we keep data that were previously used in analysis and are no longer used regularly, but may need to be re-used in the future. The "caribou" schema contains several caribou-specific datasets, including resource selection function (RSF) habitat models. 

![](images/pgadmin2.jpg)

For spatial data in the database, you can also view it using QGIS. To do this, open the QGIS app and start a new project. Click on the "Open Data Source Manager Button" (it's in the top left and looks like three squares with a plus sign) to open a new window. Click on "PostgreSQL" on the left side and it will open a "Connections" tab. Click on the "New" button and it will open another window called "Create a New PostGIS Connection". Here you can enter the clus database credentials, close the window by clicking "Ok" and then click the "Connect" and once connected, the "Close" button. 

![](images/qgis.jpg)

You can open and view a spatial dataset by clicking the "Database" tab at the top of the app, and then select "DB Manager". This will open a new window, where you can select "PostGIS" and then the name of the clus database, and public schema. You should see the spatial data you added. Right click on the table select "add to Canvas" to add it to the viewer. Here you can check that the spatial data is accurately represented.

![](images/qgis2.jpg)

The above provide a set of tools to create, check and visualize spatial data in the CLUS PostgreSQL database. In the next steps you will create a spatial parameter for a CLUS model. 

## 6. Create a Spatial Model Parameter for CLUS Using the Shapefile
Here we take the shapefile you created and make it a spatial parameter for a CLUS model scenario. This parameter will be a new spatial constraint on forest harvest activity. We'll apply the constraint to the Revelstoke TSA, which overlaps the Columbia North caribou herd, where you drew your polygon.

Many of the model parameters in CLUS are created in the "R->Params" folder. In this folder there are several .Rmd files with scripts and text describing how to create those parameters. You can look in this folder to see how we defined various parameters used in CLUS. The spatial parameter scripts convert spatial polygons to raster data with an associated table that defines the constraint to be applied to the spatial area.

In the code chunk below we provide a similar script as an example that you can use to learn the process. 


```r
# Load packages and source scripts
library (raster)
library (fasterize)
library (sf)
library (DBI)
library (here)
source (paste0(here::here(), "/R/functions/R_Postgres.R"))

# 1. Connect to database and get polygon data
conn <- DBI::dbConnect (dbDriver ("PostgreSQL"), 
                        host = keyring::key_get('dbhost', keyring = 'postgreSQL'), 
                        dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), 
                        port = '5432',
                        user = keyring::key_get('dbuser', keyring = 'postgreSQL'),
                        password = keyring::key_get('dbpass', keyring = 'postgreSQL'))
poly.data <- getSpatialQuery ("SELECT * FROM public.name_of_your_poly_table")

# 2. Create provincial raster 
prov.rast <- raster::raster ( # standardized provincial raster with no data in it
                              nrows = 15744, ncols = 17216, 
                              xmn = 159587.5, xmx = 1881187.5, 
                              ymn = 173787.5, ymx = 1748187.5, 
                              crs = st_crs(poly.data)$proj4string, 
                              resolution = c(100, 100), 
                              vals = 0)

# 3. Create an integer value attributed to each unique zone in the polygon
poly.data$zone <- as.integer (1) # create a zone field with integer value of 1
# OR 
poly.data$zone <- as.integer (as.factor (poly.data$zone)) # if there is an existing zone field, create an integer to define each zone (factor)

# 4. Create a raster and upload to the postgres database
ras.data <-fasterize::fasterize (poly.data, prov.rast, field = "zone") # converts polygon to raster
writeRaster (ras.data, file = "raster_test.tif", format = "GTiff", overwrite = TRUE) # saves the raster to your local folder
system ("cmd.exe", input = paste0('raster2pgsql -s 3005 -d -I -C -M -N 2147483648  ', 
                                  here::here (), 
                                  '/R/params/raster_test.tif -t 100x100 rast.raster_test | psql postgresql://user:dbname@host:port/dbname'), 
        show.output.on.console = FALSE, 
        invisible = TRUE) #upload to db

# 5. Create Look-up Table of the zone integers
poly.data$zone_name <- as.character ("test_scenario")
lu.poly.data <- unique (data.table (cbind (poly.data$zone, poly.data$zone_name)))
lu.poly.data <- lu.poly.data [order(V1)]
setnames (lu.poly.data, c("V1", "V2"), c("raster_integer", "zone_name"))
DBI::dbWriteTable (conn, 
                   c("public", "vat_test"),
                   value = lu.poly.data, 
                   row.names = FALSE, 
                   overwrite = TRUE)

# 6. Create zone constraint table
zone_test <- data.table (zoneid = 1, 
                         type = 'ge', 
                         variable = 'age', 
                         threshold = as.numeric(80), 
                         reference_zone = 'rast.raster_test', 
                         percentage = 90, 
                         ndt = as.integer(0), 
                         multi_condition = as.character(NA))
DBI::dbWriteTable (conn, c("public", "zone_test"), # commit tables to pg
                   value = zone_test, 
                   row.names = FALSE, 
                   overwrite = TRUE) 
dbExecute (conn, paste0("ALTER TABLE zone_test INHERIT zone_constraints"))
dbDisconnect (conn)
```

To run the script, you will need the [raster](https://cran.r-project.org/web/packages/raster/raster.pdf), [fasterize](https://cran.r-project.org/web/packages/fasterize/fasterize.pdf), [sf](https://cran.r-project.org/web/packages/sf/sf.pdf), [here](https://cran.r-project.org/web/packages/here/here.pdf), [data.table](https://cran.r-project.org/web/packages/data.table/data.table.pdf) and [DBI](https://cran.r-project.org/web/packages/DBI/DBI.pdf) packages; these can be downloaded via RStudio if you do not already have them. You will also need to load our R_Postgres.R script, using the *source ()* command. This script contains specific functions created for querying PostgreSQL data from R (located in the "R->functions" folder).

First, you will connect to the PostgreSQL database (using the *dbConnect()* function, and the keyring for credentials). You will then use the *getSpatialQuery()* function (one of our custom functions) to SELECT the table that you created in the previous step from the database as an SQL query (enter the name of the table you created in place of "name_of_your_poly_table").  

Second, you create an 'empty' raster object (all pixels will have a 0 value) configured to the provincial standard. We use this for all rasters to ensure that all of our data aligns. Make sure yuo do not to change the parameters of the raster (e.g., nrows, xmn, etc.).

Third, you create an integer value for each unique type or 'zone' within the polygon data. Here, we are using a single polygon with a single 'zone', and therefore we create a 'zone' field where zone = 1. In the Params folder you will find examples of spatial polygons with unique 'zones', for example, caribou herd boundary polygons, where each herd is a unique zone. Essentially we are creating an integer value for each unique zone that will be the value attributed to the raster. Thus, the raster represents the spatial location of each zone. 

Fourth, you will convert the polygon to a raster across the extent of BC, using the provincial standard as a template. This is done to ensure that each unique raster in the data is aligned with each other, and raster data can then be 'stacked' to measure multiple raster values at the same location. In this step, the raster is saved to a local drive, and then a command line is called from R to upload the data to the PostgreSQL using the *raster2pgsql* function. Within this function, *-s* assigns the spatial reference system, which is *3005* (BC Albers); *-d* drops (deletes) any existing raster in the database with the same name and creates a new one; *-I* creates an index for the raster data; *-C* applies constraints to the raster to ensure it is registered properly (e.g., correct pixel size); *-M* 'vacuums' the data, which reclaims any obsolete or deleted data; *-N* applies a "NODATA" value to where there is no data; *2147483648* defines the raster as a 32-bit integer; *-t* defines the number of 'tiles' or rows in the database, and here we use 100x100 to create a tile for each pixel; *rast.raster_test* defines the schema and table name to save in the PostgreSQL database; the *psql* statement defines the credentials for the database (fill in the appropriate credentials). 

Fifth, you create a 'look-up table' that links each raster integer zone to a zone name. In the example here, we create a name for the 'zone'. In the Params folder you will find examples with polygonal data that have multiple zones and zone names (e.g., caribou herds). Once the table is created, you upload it to the PostgreSQL database.

In the sixth and final step, you create a table that defines a forest harvest constraint for each zone. In this example, you create a zone constraint that requires 90% of the forest within the zone to be greater than or equal to 80 years old. Within the table, you need to define several fields, including: *reference_zone*, which is the name of the raster in the PostgreSQL database that you want to apply the constraint (note that the schema is also included); *zoneid*, which is the integer id for the zone in the raster that you want to assign the constraint; *variable*, which is the variable in the database that defines the constraint (equivalent clearcut area ("eca"), disturbance ("dist") and "height" are other examples); *threshold* is the value variable at which to apply the threshold; *type* defines whether the threshold is greater than or equal to (i.e., 'ge') or less than or equal to (i.e., 'le'); *percentage* is the percent of the zone that must meet the variable threshold; *ndt* is the natural disturbance threshold to apply to the zone (typically 0); *multi_condition* is a field that can be used to develop more complicated criteria for constraints, e.g., "crown_closure >= 30 & basal_area >= 30" would apply the constraint where crown closure and basal area of the forest stand meet the defined, specific characteristics. Note that in this example we are creating a constraint for a single zone (i.e., one row). For more complicated zoning schemes, constraints for multiple rows (i.e., unique zoneid's) may need to be created.

Once the table is created in R, you will save it to the database. Then, you will send an SQL command to the PostgreSQL database using the "dbExecute" function. This command will incorporate the new table into the a 'zone_constraints' table in the database. The 'zone_constraints' table contains all the data for each zone that was created as a parameter. You will see later that this table is used to define all zone constraints to be applied in a simulator model, thus it is critical to ensure that any zone constraint you create gets incorporated into this table. 

## 7. Use dataLoaderCLUS to Create a CLUS SQLite Database
The CLUS simulator model does not run directly off of the PostgreSQL database. Instead CLUS has a module called *dataLoaderCLUS* that consolidates data from the PostgreSQL database into a portable SQLite database. The SQLite database contains all the data needed to run the simulator modules for the area and constraints of interest. This approach has a great degree of flexibility, as it creates a self-contained, realtively low memory database that can be easily shared among users. One way to think about the CLUS data structure, is that the PostgreSQL database serves as the repository for provincial-scale and comprehensive datasets, such as for example, the forest inventory. The SQLite database typically applies to a subset of the province and is designed to compile data for a specific group of similar scenarios.  

In this section you will learn how to use the *dataLoaderCLUS* module to create a SQLite database to run in the forestry simulator model. The *dataLoaderCLUS* module is located in the "R->SpaDES-modules" folder. Within the folder you will find a single dataLoaderCLUS.R file and several variations of a dataLoaderCLUS_xxxx.Rmd. The .R file is the script that contains the functions that consolidate the data. This script should only be changed if there is a need to modify or add to the fundamental process of creating the SQLite database. The .Rmd file is used to define the scenario specific parameters that get implemented in the .R file, thus it is more flexible and can be copied and modified as needed.  

Previously you created a spatial parameter to run for the Revelstoke TSA, therefore, you can open the "dataLoaderCLUS_revelstoketsa.Rmd" to get started with many of the existing parameters needed to create a database of the TSA. Save a copy of the .Rmd as "dataLoaderCLUS_tutorial.Rmd".

Within the .Rmd you will notice features of the SpaDES module structure. It starts with a bit of a text overview of the .Rmd. Beneath that is a code "chunk". Within this chunk are listed the modules, parameters and objects needed to run the .R code. 

![](images/dataloader1.jpg)

You will notice some buttons on the right-hand side of the chunk for running or modifying the chunks. At the top of he code chunk  you will see the packages and source code needed to run the script, some commands for setting the environment for using JAVA and the directory paths for the module inputs and outputs. 

Next you will see a list object called *times*. Since *dataLoaderCLUS* is not a dynamic simulation, and is a single event process to create a database, you will see that the *start* and end *times* are equal to 0.  

Beneath that you will a list object called *parameters*. This is a relatively large list of parameters needed to run the *dataLoaderCLUS* module. Importantly, you will notice that there is a unique list for each module (i.e., a list within the list). Thus, the list contains a list of modules needed to run the analysis (in this case create the database), that each have a list of the parameters needed to run the module. This approach provides flexibility and structure in that modules can be added or removed from the list, as needed, rather than needing to keep track of all of the parameters.

Here you will see that we include parameters for the *dataLoaderCLUS*, *blockingCLUS*, *roadCLUS*, *rsfCLUS*, *survivalCLUS*, *uploaderCLUS*, *yieldUncertaintyCLUS*, and *disturbanceCalcCLUS*. We will only be using *dataLoaderCLUS*, *blockingCLUS*, *roadCLUS* and *uploaderCLUS* for the purposes of this tutorial, so you can either delete these modules or use the # symbol to 'comment out' those modules (the # symbol is used in R to indicate to the program to not run the code contained on the same line; is is often used to annotate comments to the code, but can be used to turn unused pieces of code 'off'; see example below). 

![](images/code_comment.jpg)

Beneath the list object of module parameters, you will notice some additional data.table objects, including *rsf_model_coeff*, *scenario*, and *patchSizeDist*. The  *rsf_model_coeff* is specific to *rsfCLUS*, and can be deleted or commented out. The *scenario* object provides the name and a text description of the scenario and associated outputs that will be uploaded to a PostgreSQL database. Since this is the data creation step, the scenario name and description is not that important. However, you can label it using something similar to the example below. In addition, it is important to note that there is a 63 character limit for tables in PostgreSQL, so you need to be careful with keeping the name relatively succinct. Consider that some of the raster outputs (we will discuss these later) have up to 11 characters as part of their name (i.e., "_contraints"), therefore we recommend a maximum length of 50 characters. 


```r
scenario = data.table (name = "tutorial", 
                       description = "Using dataloaderCLUS for tutorial.")
```

The *patchSizeDist* object describes the size and frequency of harvest block sizes for natural disturbance types (NDTs) in British Columbia, following the [biodiversity guidebook](https://www.for.gov.bc.ca/hfd/library/documents/bib19715.pdf). The object gets used within the *blockingCLUS* to create a range of pre-defined harvest block sizes that follow the NDT distribution. We recommend leaving these as-is unless there is an alternative distribution that is more appropriate for your area of interest. 

You will then notice some more list objects, including *modules* and *objects* (see example below). The *modules* list object simply lists the modules that you want to run as part of the code chunk. Here you will want to include *dataLoaderCLUS*, *blockingCLUS*, *roadCLUS* and *uploaderCLUS* in the list, and comment out or delete other modules. The *objects* list includes any other objects outside of the modules that are created within the code chunk. Here we include the *patchSizeDist* and *scenario* objects.


```r
modules <- list("dataLoaderCLUS", 
                "blockingCLUS",
                "roadCLUS",
                "uploaderCLUS")

objects <- list(patchSizeDist = patchSizeDist, 
                scenario = scenario)
```

Finally, you will see a *simInit* object called *mySim*. This object contains the names of all the objects needed to run the module "simulation". The *simInit* object is what gets used by the SpaDES framework to organize the simulation analysis. These must be populated for the code chunk to function (see example below). 


```r
mySim <- simInit(times = times, 
                 params = parameters, 
                 modules = modules,
                 objects = objects)
```

Now that you've familiarized yourself with *dataLoaderCLUS* we will use it to create an SQLite database for a harvest simulation. Below we provide an example of the code chunk you can use to run the script, with annotations that describe each parameter. Here we will highlight the key parameters need to run *dataLoaderCLUS* successfully. 


```r
# R Packages need to run the script
library (SpaDES) 
library (SpaDES.core)
library (data.table)
library (keyring)

source (here::here("R/functions/R_Postgres.R")) # R functions needed to run the script

Sys.setenv(JAVA_HOME='C:\\Program Files\\Java\\jdk-14.0.1') # Location of JAVA program; make sure the version is correct

setPaths(modulePath = here::here("R/SpaDES-modules")) # location of the SpaDES modules; uses here() function to use relative file paths

getPaths () # shows the module paths

times <- list (start = 0, end = 0) # sets start and end time parameters; here both = 0 since this is a data creation step

parameters <-  list( # list of all parameters in the model, by module
  .progress = list(type = NA, interval = NA), # whether to include a progress meter; not needed
  .globals = list(), # any global parameters; not needed
  dataLoaderCLUS = list (dbName = 'clus', # name of the PostgreSQL database
                         save_clusdb = TRUE, # save the SQLite database; make sure = T
                         nameBoundaryFile = "tsa_aac_bounds", # name of the polygon table in the Postgres database you want to use to define the analysis area
                         nameBoundaryColumn = "tsa_name", # name of the column in the polygon table for identifying analysis area
                         nameBoundary = "Revelstoke_TSA", # name of the analysis area within the column and polygon table 
                         nameBoundaryGeom = 'wkb_geometry', # name of the spatial geometry column of the polygon table 
                         nameCompartmentRaster = "rast.tsa_aac_boundary", # name of the raster table in the Postgres database you want to use to define the analysis area; note the inclusion of "rast.", which indicates the data is in the rast schema of the database
                         nameCompartmentTable = "tsa_aac_bounds_vat", # name of the value attribute table for identifying the associated names of the integer values in the raster table
                         nameMaskHarvestLandbaseRaster = 'rast.bc_thlb2018', # name of the raster table that contains the timber harvest land base area 
                         nameZoneRasters = c("rast.zone_cond_beo", 
                                             "rast.zone_cond_vqo", 
                                             "rast.zone_cond_wha", 
                                             "rast.zone_cond_uwr",
                                             "rast.zone_cond_fsw", 
                                             "rast.zone_cond_nharv", 
                                             "rast.zone_cond_cw",
                                             "rast.raster_test" # the raster you created and uploaded to the Postgres database
                          ), 
                         nameZoneTable = "zone_constraints", 
                        # nameZonePriorityRaster = "rast.zone_cond_beo",
                         nameYieldsRaster = "rast.ycid_vdyp", 
                         nameYieldTable = "yc_vdyp", 
                         nameYieldsTransitionRaster = "rast.tipsy2018_id", 
                         nameYieldTransitionTable = "yc_tipsy", 
                         nameForestInventoryRaster = "rast.vri2019_id", 
                         nameForestInventoryKey = "feature_id", 
                         nameForestInventoryTable = "veg_comp_lyr_r1_poly2019", 
                         nameForestInventoryAge = "proj_age_1", 
                         nameForestInventoryHeight = "proj_height_1", 
                         nameForestInventoryCrownClosure = "crown_closure", 
                         nameForestInventoryTreed = "bclcs_level_2",
                         nameForestInventorySiteIndex = "site_index" 
                    ),
  blockingCLUS = list(blockMethod = 'pre', 
                      patchZone = 'rast.zone_cond_beo', 
                      patchVariation = 6,
                      nameCutblockRaster ="rast.cns_cut_bl", 
                      useLandingsArea = FALSE),
  roadCLUS = list(roadMethod = 'pre',
                  nameCostSurfaceRas = 'rast.rd_cost_surface', 
                  nameRoads =  'rast.crds_all'
                  ),
  uploaderCLUS = list(aoiName = 'tutorial',
                      dbInfo  = list(keyring::key_get("vmdbhost", keyring="postgreSQL"), 
                                     keyring::key_get("vmdbuser", keyring="postgreSQL"), 
                                     keyring::key_get("vmdbpass", keyring="postgreSQL"),  
                                     keyring::key_get("vmdbname", keyring="postgreSQL")))
  )


scenario = data.table (name = "tutorial", 
                       description = "Using dataloaderCLUS for tutorial.")

patchSizeDist <- data.table(ndt= c(1,1,1,1,1,1,
                                  2,2,2,2,2,2,
                                  3,3,3,3,3,3,
                                  4,4,4,4,4,4,
                                  5,5,5,5,5,5), 
                           sizeClass = c(40,80,120,160,200,240), 
                           freq = c(0.3,0.3,0.1,0.1,0.1, 0.1,
                                    0.3,0.3,0.1,0.1,0.1, 0.1,
                                    0.2, 0.3, 0.125, 0.125, 0.125, 0.125,
                                    0.1,0.02,0.02,0.02,0.02,0.8,
                                    0.3,0.3,0.1,0.1,0.1, 0.1))
modules <- list("dataLoaderCLUS", 
                "blockingCLUS",
                "roadCLUS",
                "uploaderCLUS")

objects <- list(patchSizeDist = patchSizeDist, 
                scenario = scenario
                )

inputs <- list()
outputs <- list()

mySim <- simInit(times = times, 
                 params = parameters, 
                 modules = modules,
                 objects = objects)

system.time({
mysimout<-spades(mySim)
})
```

Within the parameters list, the *dataLoaderCLUS* list are a set of parameters for defining the analysis area of interest (i.e., spatial area where you want to run simulations).  These include *dbName*, *nameBoundaryFile*, *nameBoundaryColumn*, *nameBoundary*, *nameBoundaryGeom*, *nameCompartmentRaster*, *nameCompartmentTable* and *nameMaskHarvestLandbaseRaster*. In combination, these parameters tell *dataLoaderCLUS* the area of the province where you want to complete your simulation analysis. The module takes this information and proceeds to 'clip' the datasets needed for the simulation accordingly. 

Note that you can include multiple areas of interest (i.e., *nameBoundary*) together within the same by using the concatenation ([c()](https://stat.ethz.ch/R-manual/R-patched/library/base/html/c.html)) function in R, e.g., c ("Revelstoke_TSA", "Golden_TSA"). 

The next set of important parameters are the *nameZoneRasters* and *nameZoneTable*. In the CLUS vernacular, 'zones' refer to areas where a constraint is applied to a land use activity (e.g., a forest cover constraint on harvest). Here you will see a concatenation of several raster datasets. For forestry simulations, there are some key zones that should be included in the database, these include: 

* rast.zone_cond_beo 
* rast.zone_cond_vqo
* rast.zone_cond_wha 
* rast.zone_cond_uwr
* rast.zone_cond_fsw 
* rast.zone_cond_nharv 
* rast.zone_cond_cw

You will notice each of these are in the "rast" schema of the database and have the "zone_cond" naming. These rasters were all created using scripts within the [Params](https://github.com/bcgov/clus/tree/master/R/Params) folder of the repository. These scripts are intended to provide documentation of how these constraints were created, and can be updated or modified as needed. In these scripts you will see they take spatial polygonal data, interpret a forest harvest constraint for that polygon, create a raster integer identifier for unique 'zones' within the polygon, and create an associated table that defines a constraint for each identifier.  

Several of the parameters were created in the [prov_manage_objs.Rmd](https://github.com/bcgov/clus/blob/master/R/Params/prov_manage_objs.Rmd). Specifically, biodiversity emphasis option (BEO) zones (i.e., landscape units) are spatially defined as *rast.zone_cond_beo*, using the [Biodiversity Guidebook](https://www.for.gov.bc.ca/ftp/hfp/external/!publish/FPC%20archive/old%20web%20site%20contents/fpc/fpcguide/BIODIV/chap1.htm#bid), visual quality constraints are spatially defined as *rast.zone_cond_vqo*, fisheries sensitive watersheds and equivalent clearcut area are spatially defined as *rast.zone_cond_fsw*, spatial "no harvest" areas, including spatial old growth management areas (OGMAs) and parks and protected areas, are spatially defined as *rast.zone_cond_nharv* and community watershed areas are spatially defined as *rast.zone_cond_cw*. 

Wildlife-specific parameters, including wildlife habitat areas (WHAs) and ungulate winter ranges (UWRs) are defined in separate scripts. WHAs are spatially defined as *rast.zone_cond_wha* in the [wha_cond_harvest.Rmd](https://github.com/bcgov/clus/blob/master/R/Params/wha_cond_harvest.Rmd). UWRs are spatially defined as *rast.zone_cond_uwr* in the [wha_cond_harvest.Rmd](https://github.com/bcgov/clus/blob/master/R/Params/uwr_cond_harvest.Rmd). 

As standard practice we recommend including all of these in the "business-as-usual" or "base case" scenarios. These are existing land use orders that should be incorporated in scenarios that are meant to represent current management. 

In teh *nameZoneRasters* list you will also want to include the hypothetical constraint you created (i.e., *rast.raster_test*, or however you named it, with the *rast.* prefix to indicate the schema of the postgreSQL data it is stored). 

The *nameZoneTable* is the table that defines all of the constraints for the rasters included in *nameZoneRasters*. You will notice this is a single table called *zone_constraints*, rather than a unique table for each raster. This is because the *zone_constraints* table is an amalgamation of tables created for each raster. You may remember this step from when you created *rast.raster_test*. 

The next set of *dataLoaderCLUS* parameters are related to forest inventory and growth and yield data. The *nameForestInventoryRaster* parameter is a raster with an integer identifier created from the *feature_id* field, for each unique polygon in the forest inventory. The raster is created in the [raster_data.Rmd](https://github.com/bcgov/clus/blob/master/R/Params/raster_data.Rmd) in the "Params" folder, and you will notice it has the year of the inventory in the raster name. Related, the *nameForestInventoryTable* is the polygonal forest inventory data from which you will draw the forest inventory data. Notably, the *nameForestInventoryKey* is the *feature_id* that is used to link the raster to forest attributes, i.e., the integer identifier is consistent between the raster and polygonal data. The *nameForestInventoryAge*, *nameForestInventoryHeight*, *nameForestInventoryCrownClosure*, *nameForestInventoryTreed* and *nameForestInventorySiteIndex* parameters are all related to information that is extracted from the polygonal forest inventory data, including age, height, crown closure, treed and site index, respectively. These are extracted for each hectare of the rates by each feature_id. Growth and yield data is obtained from [variable density yield projection (VDYP)](https://www2.gov.bc.ca/gov/content/industry/forestry/managing-our-forest-resources/forest-inventory/growth-and-yield-modelling/variable-density-yield-projection-vdyp) and [table interpolation program for stand yields (TIPSY)](https://www2.gov.bc.ca/gov/content/industry/forestry/managing-our-forest-resources/forest-inventory/growth-and-yield-modelling/table-interpolation-program-for-stand-yields-tipsy) stand development models.

VDYP stand development curves are created in the [vdyp_curves.Rmd](https://github.com/bcgov/clus/blob/master/R/Params/vdyp_curves.Rmd) and consist of a *nameYieldTable* parameter that contains the yield model outputs and a *nameYieldsRaster* parameter, which is a raster identifier indicating the location where each unique stand model output is applied. TIPSY stand development curves are created in the [tipsy_curves.Rmd](https://github.com/bcgov/clus/blob/master/R/Params/tipsy_curves.Rmd) and consist of a *nameYieldTransitionTable* parameter that contains the yield model outputs and a *nameYieldsTransitionRaster* parameter, which is a raster identifier indicating the location where each unique stand model output is applied.

The *dataLoaderCLUS* module can be run with the parameters described above. However, here we want to include the *blockingCLUS*, *roadCLUS* and *uploaderCLUS* so we can pre-define harvest blocks and roads, and upload data to PostgreSQL database hosted on our remote server.  
                  
We will use the *blockingCLUS* module to pre-define homogenous forest harvest blocks based on similarity metrics of forest inventory stands (see documentation [here](https://github.com/bcgov/clus/blob/master/reports/harvest/draft-CLUS-blocking.md)). Set the *blockMethod* to 'pre' to use this method. The *patchZone* parameter is a raster that defines areas or zones with unique patch size distributions Here we use *rast.zone_cond_beo*, which represent unique landscape units that have defined patch sizes based on natural disturbance types (more on this below). The *patchVariation* parameter defines a  cut-off for aggregating neighbouring pixels. We recommend setting this to 6, as it roughly corresponds to a statistical significance p-value of 0.05 (i.e., probability that the neighbouring pixels are similar by random chance). The *nameCutblockRaster* parameter identifies existing cutblock locations by their integer identifier (created in the [raster_data.Rmd](https://github.com/bcgov/clus/blob/master/R/Params/raster_data.Rmd)). The *useLandingsArea* parameter can be used to pre-define the location of forest harvest landings, when known. Otherwise, it will use the centroid of each pre-defined block.

We will use the *roadCLUS* module to define a road network to the pre-defined harvest blocks. Set the *roadMethod* to 'pre' to create a road network that links each harvest landing (here it is pre-defined by *blockingCLUS*) to the existing road network following a least-cost path (see documentation [here](https://github.com/bcgov/clus/blob/master/reports/roads/draft-CLUS-roads.md)). The *rast.rd_cost_surface* defines the least-cost path raster that the module will use, and the *nameRoads* raster defines the raster of the existing road network. 
 
Finally, we will use the *uploaderCLUS* module to upload some of the summary data to a PostgreSQL database. Here set the *aoiName* to 'tutorial'; this sets the name of the schema that gets created in the PostgreSQL database where the data gets stored. The *dbInfo* parameter is a list of keyring parameters that you set-up in step 4. 

The remaining parameters include other objects within the code chunk that are not directly related to a specific module, but are important components of the SpaDES software. The *scenario* object is a data.table that contains the name and description of a simulation scenario. This information gets loaded to the PostgreSQL database, and is useful for tracking alternative scenarios. As this is a data creation step, the *scenario* object is not that important here, but here we recommend calling the name "tutorial" and the description as "Using dataloaderCLUS for tutorial." 

The *patchSizeDist* is also a data.table object and it contains information on the frequency (*freq*) and size (*sizeClass*) of forest harvest blocks by natural disturbance type (*ndt*). These are from the [Biodiversity Guidebook](https://www.for.gov.bc.ca/ftp/hfp/external/!publish/FPC%20archive/old%20web%20site%20contents/fpc/fpcguide/BIODIV/chap1.htm#bid), and we recommend keeping them as-is, unless there is good justification for changing them.

The *objects* object is simply a list of the data.table objects contained in the code chunk (i.e., *scenario* and *patchSizeDist*).

The *modules* object includes the list of modules used in the code chunk. Here we use *dataLoaderCLUS*, *blockingCLUS*, *roadCLUS* and *uploaderCLUS*.

The *inputs* and *outputs* list objects are empty, as there are no additional inputs or outputs to the module outside of the paramters described above.  

The *mySim* object is a SpaDES object that contains the names of the *times*, *params*, *modules* and *objects* objects for it to reference during the simulation. These shoudl be consistent with the naming within the code chunk. 

Finally, you will see a [system.time()](https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/system.time) function that us used to output the time it too to run the SpaDES "simulation" object (mySim). 

Now that you've parameterized the module, you can run it! Click on the green "Play" symbol on the top-right of the code chunk. The script should start to run, and you will see messages as some parts of the script are run. The Revelstoke TSA is relatively small, and it should take less than an hour to complete the script.  

![](images/dataloader_run.jpg)

At the end of the analysis, you should see a .sqlite database object created in the dataLoaderCLUS folder of your local copy of the CLUS code. The database will have the name of the *nameBoundary* parameter, in this case, *Revelstoke_TSA_clusdb.sqlite*. You will also notice some raster files, including *hu.tif*, *Revelstoke_TSA_pre_0.tif* and *roads_0.tif*. These are intermediary outputs from the modules (the same data is saved in .sqlite database tables), and can be viewed to check for any errors or deleted. The *hu.tif* is the harvest units output from *blockingCLUS*, and  *Revelstoke_TSA_pre_0.tif* and *roads_0.tif* are the simulated roads outputs from *roadCLUS*. 

Below are some scripts to query the .sqlite database. First, connect to the database using the *dbConnect* function in the DBI package. You can then list the tables using the *dbListTables*. You will notice there are seven tables in the database including: 

* adjacentBlocks  
* blocks          
* pixels         
* roadslist       
* yields          
* zone           
* zoneConstraints

Below we will explore each of these a little bit to help with understanding the data structure that you will use in the forestry simulation. You can load each of these tables into your computer memory as an R object using the *dbGetQuery* function. 

The *adjacentBlocks* table is a table of each harvest block in the area of interest (*blockid*) and the neighbouring blocks (*adjblockid*). This gets used if you use the adjacency constraint in *forestryCLUS*. 

The *blocks* table is a table that contains age, height, volume and distance to 'disturbance' (only if using *disturbanceCalcCLUS*) and landing pixel location of each harvest block in the area of interest. This table gets used and updated during the forestry simulation to assess characteristics of harvest blocks for adjacency, to establish the forest harvest queue, and to identify landing locations. 

The *pixels* table is the largest table in the database and contains a lot of information. Specifically, it contains data on each pixel (*pixelid*) in the province, although much of this data is NULL, as it is outside of the study area. For pixels within the study area, the *pixels* table identifies the harvest compartments (*compartid*), the ownership (*own*), the growth and yield curve identifiers (*yieldid* and *yieldid_trans*), zone constraint identifier (*zone_const*), forest stand characteristics, where relevant, including whether it is forested (*treed*), within the timber harvest land base (*thlb*), it's elevation (*elv*, but only if using *yieldUncertaintyCLUS*), age (*age*), volume (*vol*), it's distance to 'disturbance' (*dist*, but only if using *disturbanceCalcCLUS*), crown closure (*corwnclosure*), height (*height*), site index (*siteindex*), percent deciduous (*dec_pcnt*), equivalent clearcut area (*eca*), road year (*roadyear*, all roaded areas are 0 since we don't have road year data), a column (*zone1*, *zone2*, *zone3*... etc.) for each zone constraint area (i.e., one for each *nameZoneRasters*; see the *zone* table below) that provides the unique constraint identifier integer within that zone constraint area that applies to that pixel, and the harvest block identifier (*blockid*) that identifies which block the pixel belongs to. This table gets queried and updated to report on or change the state of the landscape. For example, *age* can be queried to report on current age of the forest, and gets updated as forest harvest occurs.    

The *roadslist* table provides a table of each pixel with a forest harvest block landing (*landing*), and a list of pixels that would need to be converted to roads to 'attach' it to the existing road network. These are pre-populated if you run the *roadCLUS* module, and when a block gets harvested during a time setp of the simulation, the landing and roads linking the landing to the existing road network gets 'built'. Those road pixels associated with the landing get converted to a road type.

The *yields* table provides a table of the information associated with each yield curve. They provide the volume and height of yield curve (*yeildid*) at 10 year intervals. 

The *zone* table provides a table of the name of each raster associated with each zone constraint column (*zone1*, *zone2*, *zone3*... etc.)  in the *pixels* table. This gets used to associate *nameZoneRasters* with their constraints.  

The *zoneConstraints* table provides a table of all of the specific zone constraint definitions that apply to the zone constraint rasters.The *zoneid* column is the specific integer value within each *nameZoneRasters* (i.e., the *reference_zone* and *zone* columns) where a constraint is applied. The constraint consists of a natural disturbance type class (*ndt*), the variable type that is being constrained (*variable*), for example, age or height, the threshold of the variable at which the constraint is applied (*threshold*), for example, 150 years old, the type of threshold (*type*), i.e., greater than or equal to (*ge*) or less than or equal to (*le*), the percentage of the area for which the constraint needs to apply (*percentage*), the SQL script for areas with multiple constraints (*multi_condition*) and the total area (*t_area*) of the zone. Note that we do not use multiple constraints here, but they could be used, for example, if you want to constrain on the age and height of forest stands in the same area.  

You can view constraints for a specific zone (e.g., the raster zone you created, *rast.raster_test*), by using the WHERE clause in the SQL script. 


```r
library (DBI)

# Connect to the clusdb.sqlite database for the AOI
clusdb <- dbConnect (RSQLite::SQLite(), dbname = paste0(here::here(), "/R/SpaDES-modules/dataLoaderCLUS/Revelstoke_TSA_clusdb.sqlite")) 

# List tables in the 
dbListTables (clusdb)

# Load a table as an R object
adjacentBlocks <- dbGetQuery (clusdb, "SELECT * from adjacentBlocks")
blocks <- dbGetQuery (clusdb, "SELECT * from blocks")
pixels <- dbGetQuery (clusdb, "SELECT * from pixels")
roadslist <- dbGetQuery (clusdb, "SELECT * from roadslist")
yields <- dbGetQuery (clusdb, "SELECT * from yields")
zone <- dbGetQuery (clusdb, "SELECT * from zone")
zoneConstraints <- dbGetQuery (clusdb, "SELECT * from zoneConstraints")

# To remove R objects from memory
rm (adjacentBlocks)
gc () # 'garbage collection' command; useful command for freeing computer memory after removing an R object

#  To view the constraints of a specific zone
zoneconstraints<-dbGetQuery(clusdb, "SELECT * from zoneConstraints WHERE reference_zone = 'rast.raster_test'") # Note: the reference_zone is the name of the raster in the rast schema. If there is no 'WHERE' clause this may return 1000's of zones
```

The forestry simulation essentially queries and updates the tables within the sqlite database, which simplifies the data management process. If you want to take a deep dive into how these data are used and modified by the forestry simulation model, you can open up the [forestryCLUS](https://github.com/bcgov/clus/blob/master/R/SpaDES-modules/forestryCLUS/forestryCLUS.R) module and look at the queries of the sqlite database. 

In the next step we will begin to use the forestry simulator, first, by creating a sustained yield forest harvest flow.

## 8. Creating a Sustained Yield Forest Harvest Flow Using forestryCLUS
In the following steps we will learn to use *forestryCLUS* to run forest harvest simulations. First, we will provide an overview of the *forestryCLUS*. Then we will use the module to create a sustained yield forest harvest flow under current management practice. Finally, we will then add the new constraint you created to the simulation to see if and how the new constraint could impact the harvest flow. 

### Overview of the forestryCLUS Module
We will start by opening a version of the forestryCLUS.Rmd file. Specifically, open the [forestryCLUS_tutorial.Rmd](https://github.com/bcgov/clus/blob/master/R/SpaDES-modules/forestryCLUS/forestryCLUS_tutorial.Rmd). Save a working copy with your name in the file, as *forestryCLUS_tutorial_yourname.Rmd*. 

Similar to *dataLoaderCLUS*, you will see a header, followed by some text, which describes details of the module. Below that you will see a description specific to the Revelstoke TSA, the area of interest. As standard practice we provide a brief description of the TSA, the simulation scenarios that were run, and some details on the key parameters used in the simulations.  

You will note that we describe two scenarios, a 'business-as-usual' (BAU) scenario and then an alternate scenario that will include your hypothetical management zone. Both scenarios will include 'existing management' practice on the land base. You will see we use an 'oldest first' harvest priority queue, which is comparable to the timber supply model used in the allowable annual cut (AAC). You will also see that we simulate over a 200 year period at 5 year intervals. 

In the description we describe some 'standard' parameters we use in forest harvest simulation models. For example, our current practice for assessing impacts of hypothetical management zone is to create a BAU scenario that has a long-term sustained yield harvest flow (i.e., non-declining even flow), where the harvest target remains flat. This simplifies comparing harvest volume across scenarios, however, alternative types of harvest flows could be created and compared by partitioning the *harvestFlow* parameters by time periods (more on that below). Similarly, the harvest priority queue, minimum harvest and adjacency constraints can be adjusted as you see fit, and should be noted in the text.      

#### ForestryCLUS Parameters
Below is a copy of the code chunk in the *forestryCLUS_tutorial.Rmd*. Here we will review each parameter in some detail. 

First you will notice some [library()](https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/library) and [source()](https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/source) function calls. These load the R packages and functions needed to run the simulation. 

Next you will see some file paths for indicating where the modules (*moduleDir*), inputs (*inputDir*), outputs (*outputDir*) and cache (*cacheDir*) are located. Again, we use the [here()](https://www.rdocumentation.org/packages/here/versions/0.1) function to set relative paths. Be sure you have the correct directory for the SpaDES modules. You can change the location of the other objects if you like, but we recommend using them as-is. 

You will likely recognize the *times* parameter from *dataLoaderCLUS*. It is an important parameter in the *forestryCLUS* module since we are simulating forest harvest over time. Here you need to provide the start time as 0 and end time as 40, as we typically simulate forest harvest at 5 years intervals for 200 years; i.e., 40 intervals are needed to achieve a 200 year simulation. However, feel free to change the number of intervals, but make sure it is in consistent with the *harvestFlow* parameter in  *forestryCLUS* and the *periodLength* parameter in *growingStockCLUS* (we will provide more explanation on that below).

Next, again you will recognize the *parameters* list, that consists of all the modules and the lists of parameters within them. The *dataLoaderCLUS* parameters should be consistent with what you used when running that module previously. However, the *forestryCLUS* module only uses a some of these directly. In particular, the path to the SQLite database needs to be set (*useCLUSdb*). In addition, you can modify the *nameZoneRasters* you want to include in a given scenario (which we will do below). Otherwise, the parameters can generally be ignored, as they will not impact the *forestryCLUS* simulation analysis.   

Since we used the *blockingCLUS* module as part of *dataLoaderCLUS* to pre-define the harvest blocks, we use the *blockingCLUS* module within *forestryCLUS*. In this case, it is important to set the *blockMethod* parameter to 'pre'. This tells the *forestryCLUS* module that the blocks were pre-defined in the SQLite database. The other parameters are either used within the *dataLoaderCLUS* step, and are thus not important within *forestryCLUS*, or if you did not use the pre-blocking method in *dataLoaderCLUS*, you can use the 'dynamic' *blockMethod* in *forestryCLUS*. This creates harvest blocks 'on-the-fly' by randomly spreading from selected pixels, following the size distribution from natural disturbance types. Using the 'dynamic' method requires these other parameters (i.e., the *patchZone* parameter and *patchSizeDist* object) to be set. The *useSpreadProbRas* also needs to be set to TRUE, so that the model will restrict the location of cutblocks (i.e., only allow them to "spread") to within the THLB.   

The *forestryCLUS* module itself consists of parameters for establishing the priority for harvesting forest stands and zones in the model, reporting of forest harvest constraints and an adjacency constraint setting. We describe these in mroe detail below. 

You can set the forest stand harvest priority criteria using the *harvestBlockPriority* parameter. The parameter is a SQL query of the 'pixels' table within the SQLite database. It selects each unique 'block' (predefined using *blockingCLUS*, or else it prioritizes at the pixel scale) and orders them, according to the SQL query criteria. Here we use 'oldest first' as the priority criteria using the "age DESC" query (i.e., order blocks by descending age). You can use any data incorporated in the 'pixels' table to establish the priority queue (e.g., volume, height or distance to disturbance). You can also prioritize using multiple criteria, e.g., "age DESC, vol DESC" will order the blocks by age and then volume, and thus prioritize the oldest blocks with the highest volume in the priority queue. The model then essentially 'harvests' (sets the stand as a cutblock, by setting age, height and volume to 0) and calculates volume from that stand according to the estimate from the appropriate growth and yield model. 

You also have the option to set a harvest priority criteria within pre-defined management zones within the area of interest. Thus, you can set harvest priority at two scales, at the scale of a single stand and at the scale of groups of stands within some pre-defined areas. To do this you will have needed to define these priority areas when running the *dataLoaderCLUS* by setting the *nameZonePriorityRaster* parameter. The *nameZonePriorityRaster* is a raster that must have a zone priority identifier for each pixel in the area of interest (otherwise that pixel will never be harvested in the simulator). When creating the *nameZonePriorityRaster* you can specify that the unique identifier for the priority zones is equivalent to the order you want them harvested. For example, if you have two zones called 'east' and west' and want to prioritize harvest in the 'west' zone, then make the integer identifier for 'west' = 1 and 'east' = 2. This way, you can establish the harvest priority criteria with an SQL query of the integer identifier (e.g., "zone_column ASC"). Alternatively, you can prioritize based on forest stand characteristics within the *nameZonePriorityRaster*. To use the zone harvest priority criteria you need to set the *harvestZonePriority* parameter as a SQL query with the criteria you want to prioritize by, including age, volume and distance to disturbance (similar to the stand-level query). For example, if you want to prioritize harvest to the region with the oldest stands, then use "age DESC". You will also need to set the *harvestZonePriorityInterval* parameter, which defines how frequently the model re-calculates the harvest. For example, *harvestZonePriorityInterval* = 1 will re-calculate the zone priority at each interval, in this case every 5 years. If using the zone harvest priority parameters you also need to define the *nameZonePriorityRaster* parameter in the *dataLoaderCLUS* parameter list. Here we do not prioritize harvest by zone, and thus you will notice these parameters are "commented out". 

The *reportHarvestConstraints* parameter in the *forestryCLUS* module can be used to output a table from the simulation that reports the constraint values for each zone constraint area. For example, if a zone has a constraint threshold on the proportion of the area of the zone that can be less then a specified stand age, it will report out the proportion of the zone that meets that threshold. This can be useful for double-checking whether a constraints is being modeled properly, or to assess when a constraint is or is not being met during a simulation. Here we set the parameter to TRUE so we can use that functionality. We will show you how to use this information in more detail later. 

The *adjacencyConstraint* parameter in the *forestryCLUS* module can be used to simulate a 'green-up' requirement for adjacent harvest blocks. The parameter is the minimum threshold of the height of the stand in the adjacent blocks before a block is allowed to be harvested. Here we set it to '3', which is to say that the adjacent blocks must be minimum 3 m in height before a block is harvested. 

Here we use the *growingStockCLUS* module to calculate and update the stand characteristics from the appropriate growth and yield curves. You only need to set one parameter within the module, *periodLength*, which is the lenght of time, in years, that a time interval is in the simulation. Here we set it to '5', as we are simulating 40 intervals over a 200 year period, which is equivalent to a five year interval. If we changed this to 20 intervals over a 100 year period, for example, it would also be 5. Or, for example, if we changed it to 20 intervals over a 200 year period the *periodLength* should be set to '10'. 

We also use the *roadCLUS* module in this example to show how CLUS simulates roads. The module consists of three parameters: *roadMethod*, *nameCostSurfaceRas* and *nameRoads*. You will notice that these are the same parameter settings used in the *dataLoaderCLUS_tutorial.Rmd.* Since we used the 'pre' *roadMethod* in *dataLoaderCLUS*, the road network to all possible cublock landings has already been solved in the SQLite database. Therefore, when running the *forestryCLUS* simulation, the *roadCLUS* module takes the pre-solved network and 'converts' a pixel to a road along the pre-defined network when a block is harvested between that blocks landing and the existing road network. It also sets the 'roadyear' value to the period in the simulation when the road was created. If using other methods (i.e., 'snap', 'lcp', or 'mst') then the network gets created during the simulation. Here we will continue to use the 'pre' method, and we set the parameters the same as was used in the *dataLoaderCLUS*.  

Finally, we use the *uploaderCLUS* module to output the results of the simulation to a PostgreSQL database on a cloud server. Here you need to define the connection to the cloud server (*dbInfo*), which consists of a list of the database host amd name, and the username and password. Again we use the ["keyring"](https://cran.r-project.org/web/packages/keyring/keyring.pdf) package to maintain database security. You also need to set the *aoiName* parameter. This parameter is the name of the schema (i.e., a namespace for containing a group of data) within the PostgreSQL database where the results of the simulation will be saved. This can be a new schema or a previously created one. Here we will use the 'tutorial' schema. 

In addition to the list of parameters, there are several objects that need to be created to run the *forestryCLUS* simulation. This includes the list of *modules* used in the analysis, a data.table that describes the simulation *scenario*, a list of data.table's that define the harvest flow (*harvestFlow*), a data.table that defines the patch size distribution for cutblocks (*patchSizeDist*), a list of the *objects*, a list of the simulation file paths (*paths*), and the simInit object (*mySim*) that defines all of these things for the SpaDES package to run the simulation. You  can define a data.frame object that identifies all of the output 'reports' to save from the simulation analysis (*outputs()*). 
In the *modules* object, here we list all of the modules described above, including *dataLoaderCLUS*, *growingStockCLUS*, *blockingCLUS*, *forestryCLUS*, *roadCLUS*, and *uploaderCLUS.*

In the *scenario* object, we provide two parameters, a *name* and a *description* of the scenario being simulated in a given run of the model. These should be unique to each set of parameters input into the model. For example, if you are testing the effect of changing the harvest priority parameter from oldest first to highest volume first, these scenarios should have a different name and description. A scenario with the same name will get copied over the previous scenario. For the *name*, we suggest including the harvest unit name (e.g., TSA or TFL) and some acronyms describing the scenario. We again note that there is a 63 character limit for tables in PostgreSQL, and some of the table outputs from the scenario incorporate the scenario name, thus we recommended keeping the name as short as possible. For each harvest unit we typically simulate a business-as-usual scenario, which is characterized in the *name* with the acronym 'bau'. The 'bau' is intended to represent a baseline scenario for the harvest unit, essentially including all of the existing legal constraints, forest inventory and growth and yield models as-is, and harvest rules that are sensible for the harvest unit (i.e., uses parameters similar to what were used in the recent timber supply review analysis for the harvest unit). The BAU scenario also has even harvest volume flow, i.e., harvested flow is set at the maximum volume that can be harvested without causing a decline in harvest volume during the 200 year simulation period. An alternative scenario might include a hypothetical constraint, and therefore it would be useful to incorporate the constraint name and perhaps some of the parameters into the scenario *name*, e.g., 'revelstoke_newzone_25p_agele15' might describe a new zone with a constraint threshold of maximum 25 percent of the area of forest stands with an age less than or equal to 15 years old. The *description* parameter can be used to provide much more detail on the scenario. Here you can describe specifics of the parameters used in the analysis. As standard practice we describe the constraints (e.g., business as usual, or including a hypothetical constraint), the target harvest flow (typically the even-flow harvest rate from the bau scenario), adjacency constraints, the harvest priority criteria, and any other relevant information to the scenario.    

The *harvestFlow* is a list of parameters describing the volume target for the harvest unit. It can be used to set targets within multiple compartments in a harvest unit by creating a data.table for each unique compartment. Note that if you are simulating multiple compartments these will need to have been defined in *dataLoaderCLUS* and thus align with the compartments as defined in the SQLite database. The *compartment* parameter is the name of each harvest unit in the analysis, as defined in the SQLite database, as taken from the spatial harvest unit boundaries defined in *dataLoaderCLUS*. Here we use "Revelstoke_TSA", as that is the name of the TSA in the *nameBoundaryFile* we use to define harvest units. The *partition* parameter is an SQL query that may be used to further limit where forest can be harvested within the simulation. Here we use ' vol > 150 ' to limit harvest to stands that achieve a miniumum volume of 150 m^3^. This parameter could also be used to partition harvest according to other inforamtion itn he 'pixels', for example, to target deciduous stands (' dec_pcnt > 50 '). The *year* parameter is used to define the time period and steps of the simulation. You will remember that we set the *times* parameter as 40 intervals, and with the intent of simulating a 200 year period, that is equivalent to a 5 year interval. The *year* parameter specifies the sequence of years (the *seq()* function) of the analysis, including the calendar year start (the *from* parameter, which is typically the year of the forest inventory data used in the analysis, which in thsi case is 2019), the end year (the *to* parameter; add the number of desired simulation years, which in this case is 200, and thus the value is 2219), the interval in years (the *to* parameter, which in this case is 5, since there are 5 years in each interval, or 200/5). The *flow* parameter sets the harvest target for each time interval. The model will harvest up to that amount at each interval. Thus, if the interval is 5 years, it is the 5 year target. You will likely want to consider harvest targets on an annual basis, so make sure you convert the annual target to the appropriate interval (e.g., if the annual target is 200,000m^3^/year, and the interval is 5 years, the *flow* is 1,000,000m^3^)

The *patchSizeDist* parameter provides the frequency distribution for cutblock sizes, by natural disturbance type, following the [biodiversity guidebook](https://www.for.gov.bc.ca/hfd/library/documents/bib19715.pdf). You likely recall that the same parameter was used in *dataLoaderCLUS* within the *blockingCLUS* module to create a range of pre-defined harvest block sizes that follow the NDT distribution. Here it can be ignored, but is included in case you want to create cutblocks on-the-fly using the 'dynamic' method. Under thsi method, cutblocks will be simulated with a spread algorithm, limited by the *patchSizeDist* frequency distribution.

The *objects* parameter is necessary for SpaDES to function properly by declaring the objects it needs to track. If you do not list the object, then it will be ignored in the simulation and result in a model error. Here we list the *harvestFlow*, *patchSizeDist* and *scenario* objects we described above. 

Similarly, the *paths* parameter is necessary for SpaDES to know where the model input data are located and where outputs should be stored. Failure to incldue these may also result in an error.

The *mySim* object is another SpaDES object where various parameters and components of the model must be decalred for the SpaDES simulation to function. Here you declare the name of the *times*, *params*, *objects* and *paths* objects for the model. 

The *outputs()* function is a SpaDES function for declaring the objects within the simulation that get output to the *outputDir*. These are created in the module .R scripts, for example, the "harvestReport" is created in the forestryCLUS.R script and the "growingStockReport" is created in the growingStockCLUS.R script. You will need to familiarize yourself with the module scripts to understand what reports can be output but for now you can use "harvestReport" and "growingStockReport". The "harvestReport" outputs things like the amount of volume harvested at each time interval in a scenario and compartment, and the "growingStockReport" outputs the amount of grwoing stock at each time interval in a scenario and compartment. 

Finally, you can save the SpaDES simulation (in this case the *mySim* object) run with the *spades()* function. Note that here we embed that function in the *system.time()* function to obtain the total time the model took to finish the simulation. 


```r
library (SpaDES.core)
library (data.table)
source (paste0(here::here(), "/R/functions/R_Postgres.R"))

moduleDir <- file.path(paste0(here::here(), "/R/SpaDES-modules"))
inputDir <- file.path(paste0(here::here(), "/R/SpaDES-modules/forestryCLUS/inputs")) %>% reproducible::checkPath(create = TRUE)
outputDir <- file.path(paste0(here::here(), "/R/SpaDES-modules/forestryCLUS/outputs"))
cacheDir <- file.path(paste0(here::here(), "/R/SpaDES-modules/forestryCLUS"))

times <- list(start = 0, end = 40) # 5 year interval; 200 years = 40 intervals

parameters <- list(
  .progress = list(type = NA, interval = NA),
  .globals = list(),
  dataLoaderCLUS = list (  dbName='clus',
                           save_clusdb = FALSE,
                           useCLUSdb = paste0(here::here(), "/R/SpaDES-modules/dataLoaderCLUS/Revelstoke_TSA_clusdb.sqlite"),
                           nameBoundaryFile = "tsa_aac_bounds",
                           nameBoundaryColumn = "tsa_name",
                           nameBoundary = "Revelstoke_TSA",
                           nameBoundaryGeom = 'wkb_geometry',
                           nameCompartmentRaster = "rast.tsa_aac_boundary",
                           nameCompartmentTable = "tsa_aac_bounds_vat",
                           nameMaskHarvestLandbaseRaster = 'rast.bc_thlb2018',
                           nameZoneRasters = c("rast.zone_cond_beo", 
                                             "rast.zone_cond_vqo", 
                                             "rast.zone_cond_wha", 
                                             "rast.zone_cond_uwr",
                                             "rast.zone_cond_fsw", 
                                             "rast.zone_cond_nharv", 
                                             "rast.zone_cond_cw"
                                             # "rast.raster_test"
                                               ),
                           nameZoneTable = "zone_constraints",
                           # nameZonePriorityRaster = "rast.zone_cond_beo",
                           nameYieldsRaster = "rast.ycid_vdyp",
                           nameYieldTable = "yc_vdyp",
                           nameYieldsTransitionRaster = "rast.tipsy2018_id",
                           nameYieldTransitionTable = "yc_tipsy",
                           nameForestInventoryRaster = "rast.vri2019_id",
                           nameForestInventoryKey = "feature_id",
                           nameForestInventoryTable = "veg_comp_lyr_r1_poly2019",
                           nameForestInventoryAge = "proj_age_1",
                           nameForestInventoryHeight = "proj_height_1",
                           nameForestInventoryTreed = "bclcs_level_2",
                           nameForestInventoryCrownClosure = "crown_closure",
                           nameForestInventoryTreed = "bclcs_level_2",
                           nameForestInventorySiteIndex = "site_index"),
  blockingCLUS = list(blockMethod ='pre', 
                      patchZone = 'rast.zone_cond_beo',
                      patchVariation = 6,
                      nameCutblockRaster ="rast.cns_cut_bl",
                      useLandingsArea = FALSE, 
                      useSpreadProbRas = FALSE),
  forestryCLUS = list(harvestBlockPriority = "age DESC", 
                      #harvestZonePriority = "age DESC",
                      #harvestZonePriority = 1,
                      reportHarvestConstraints = TRUE,
                      adjacencyConstraint = 3),
  growingStockCLUS = list (periodLength = 5),
  roadCLUS = list(roadMethod = 'pre', 
                  nameCostSurfaceRas = 'rast.rd_cost_surface', 
                  nameRoads =  'rast.crds_all'),
  uploaderCLUS = list(aoiName = 'tutorial', 
                      dbInfo  = list(keyring::key_get("vmdbhost", keyring="postgreSQL"), 
                                     keyring::key_get("vmdbuser", keyring="postgreSQL"), 
                                     keyring::key_get("vmdbpass", keyring="postgreSQL"),  
                                     keyring::key_get("vmdbname", keyring="postgreSQL"))
                  )
)

modules <- list("dataLoaderCLUS", 
                "growingStockCLUS", 
                "blockingCLUS", 
                "forestryCLUS", 
                "roadCLUS",  
                "uploaderCLUS"
                )


### SCENARIOS ###
scenario = data.table (name = "revelstoke_bau", 
                       description = "Business-as-usual case; sustainable flow = 210,000m^3^/year. Adjacency = 3m. Oldest first. 150m3/ha minimum volume.")



harvestFlow <- rbindlist(list(data.table(compartment ="Revelstoke_TSA",
                                         partition = ' vol > 150 ', 
                                         year = rep(seq (from = 2019, 
                                                         to = 2219, 
                                                         by = 5),
                                                    1), 
                                         flow = 1050000) # 210,000m^3^/year
))

#harvestFlow<-rbindlist(list(harvestFlowA,harvestFlowB,harvestFlowC)) # if > 1 harvest flow

patchSizeDist<- data.table(ndt= c(1,1,1,1,1,1,
                                  2,2,2,2,2,2,
                                  3,3,3,3,3,3,
                                  4,4,4,4,4,4,
                                  5,5,5,5,5,5), 
                           sizeClass = c(40,80,120,160,200,240), 
                           freq = c(0.3,0.3,0.1,0.1,0.1, 0.1,
                                    0.3,0.3,0.1,0.1,0.1, 0.1,
                                    0.2, 0.3, 0.125, 0.125, 0.125, 0.125,
                                    0.1,0.02,0.02,0.02,0.02,0.8,
                                    0.3,0.3,0.1,0.1,0.1, 0.1))

objects <- list(harvestFlow = harvestFlow, 
                patchSizeDist = patchSizeDist, 
                scenario = scenario)

paths <- list(cachePath = cacheDir,
              modulePath = moduleDir,
              inputPath = inputDir,
              outputPath = outputDir)

mySim <- simInit(times = times, 
                 params = parameters, 
                 modules = modules,
                 objects = objects, 
                 paths = paths)

# outputs to keep; these are tables that get used in the uploader
outputs(mySim) <- data.frame (objectName = c("harvestReport",
                                             "growingStockReport"))

#Run the model 1 time
system.time({mysimout<-spades(mySim)})
```

Now that your familiar with the elements of the *forestryCLUS* module, we will run some simulation scenarios so you can get familiar with its functionality and in particular, the model outputs. Open the *forestryCLUS_tutorial.Rmd*. You will see the file has a [yaml header](https://monashdatafluency.github.io/r-rep-res/yaml-header.html), bounded by three dashes (---) at the top and the bottom. This header contains commands related to how the .Rmd is formatted in an output document (typically a html, pdf or Word file). We won't get into detail on yaml header options here, but you will note this one contains commands for a *title*, *author* and *date*; feel free to modify these as you like. The *output* command specifies that the output is a html file (*html_document*), adn that a markdown (.md) document of the file will be created for web viewing on github (*keep_md: yes*).  


```r
---
title: "forestryCLUS_tutorial.RmD"
author: "Tyler Muhly"
date: "23 April 2021"
output:
  html_document: 
    keep_md: yes
---
```

Below the yaml header you will see some text. Here you can describe the specific module being developed. Our general approach has been to save unique .Rmd files for each unique harvest unit (e.g., TSA or TFL) being analyzed, but there may be other reasons for creating a unique file. Typically in this text portion of the file we provide an overview of the *foretryCLUS* module, followed by details on the harvest unit being simulated. For example, in the *forestryCLUS_tutorial.Rmd* we describe the Revelstoke TSA, including referencing the webpage where additional information can be obtained. 

We also describe each scenario simulated within the harvest unit (i.e., in a *Scenarios* section). This will typically consist of a description of the BAU scenario and alternative scenarios to the BAU. These should generally describe the modification to the BAU, for example, any additional constraints or changes to harvest flow. We also describe the *Key Parameters* used in the scenarios, including BAU and the alternatives. These include description of the zone constraints, details on the harvest priority queue and harvest flow, minimum harvest criteria and adjacency constraints. It is good practice to include as much detail as possible here. 

Below the text is the 'code chunk' to 'run' or initiate the simulation, and you can 'run' it by pressing the green 'Play' button at the top-right of the chunk. This will read and action the code in the chunk, which will action all of the code in the .R modules referenced in the chunk. 

To run the BAU, make sure to have all of the *nameZoneRasters* listed except *rast.raster_test*, which can be 'commented out' with a # symbol (note: make sure there is no comma at the end of the list).  You can leave all of the remaining parameters as they are, but confirm that the harvest flow is described as above, to ensure a maximum non-declining harvest yield. For the BAU scenario, we recommend using "revelstoke_bau" as the *name*. The description should provide a little bit of information about the scenario, including constraints, harvest flow and queue, adjacency and minimum harvest criteria.

Also confirm that in the *uploaderCLUS* module parameters that *aoiName* = 'tutorial'. This will be the name of the schema in the PostgreSQL database where the scenario outputs will be uploaded and saved (more on that below).  

Run the scenario and you will see a green 'line' down the side of the code chunk, and in the console window you will see outputs messages from the modules. You will notice that model progress output is provided, including time elapsed, the time interval of the model (in this case between 0 and 40), and the module currently being run by the model. 

![](images/scen_run.jpg) 

At the end of the run the progress meter will stop and you will see some white text with the time elapsed to complete the simulation run. 

![](images/scen_end.jpg) 

## 9. Running Alternative Scenarios in forestryCLUS
Next, you can run the alternative scenario. In the *forestryCLUS_tutorial.Rmd* you can now include the raster you created (i.e., *rast.raster_test*, or whatever name you used; note: remember to include the *rast.* prefix, which refers to the schema in the PostgreSQL database where the raster data is stored) in the list of *nameZoneRasters*. 

Also, copy the *scenario* object and paste it below the existing object. 'Comment out' the previously used BAU scenario object and edit the scenario you copied. It is good practice to keep the previously used *scenario* objects so you can see which scenarios were completed, and re-use them, if corrections or changes are necessary later. 

Change the name of the copied *scenario* object to identify your alternative scenario. You may want to include details of the constraint, for example, "revelstoke_alt_agelt40_t30p", could indicate that for the alternate constraint area had an age less than 40 (agelt40) at a threshold of 30 percent of the area (t30p) constraint. You can use the *description* parameter to describe the scenario in more detail. 

Once, that is done, click the 'Play' arrow again in the code chunk and let the simulation complete. 

You are welcome to try additional scenarios here if you like, for example, adjusting the harvest queue, but remember to use unique *scenario* parameters for each, or else you will copy over previous results. 

## 10. Checking Scenario Outputs
As described above, the *uploaderCLUS* module is where you define the parameters for where simulation outputs are stored. We currently store this output data in a PostgreSQL database deployed on a virtual machine under a Compute Canada account. You can use the PGAdmin software to connect to the database and navigate to the outputs. You will need to obtain the credentials from the CLUS team to make the connection. 

If you can make the connection to the database, navigate to the "tutorial" schema, and open it, then click and open the "Tables". This will open a directory list of the outputs saved by *uploaderCLUS*. You will see several tables, including  "growing stock", "harvest", "scenarios", and "state", which are all data tables, and some tables that end with "_constraint", "_cutblocks", and "_roads", which are raster outputs from each scenario, and thus have the scenario name and harvest unit as their prefix (we won't discuss the other tables here).

![](images/pgadmin_output.jpg) 

Navigate to the "growing stock" table, right click on it, click on "View/Edit Data", then "All Rows". This will open the table in the lower right of the PGAdmin viewer. This table provides information on how much volume is available (gs), including within the timber harvest land base (m_gs), and percentage that is deciduous (m_dec_gs) for each time interval (timeperiod), timber harvest unit (compartment) and scenario (scenario). This can be used to track the 'stock' of volume available to be harvested at each time interval.   

![](images/pgadmin_table.jpg) 

Similarly, open the "harvest" table and explore the data. For each scenario (scenario), time interval (timeperiod), and harvest unit (compartment), this table provides the amount of volume (volume) of timber harvested in m^3^. It also provides the area harvested (area), and the area (transition_area) and volume (transition_volume) harvested from 'managed stands', i.e., stands that have been previously harvested and replanted. In addition, it provides the area-weighted age of the harvested stands (age), and the area of THLB that is unconstrained, available to harvest. 

Finally, the "scenarios" table documents the scenario name and description parameters for each simulated scenario, and the "state" table describes the initial state of the simulated landscape, including the area of road (i.e., pixels with a road), old (>139 year old), mature (41 to 139 year old) and early (< 41 year old) seral forest and THLB, by harvest unit (compartment). 

Alternatively, much of this information can be accessed in summary form using the "CLUS Explorer" web application. Similar to the "CLUS Scenario" app, you can access it by going to the [FAIB apps webpage](http://206.12.91.188:8787/login). Note if you haven't already done so, you will need to contact Kyle.Lochhead@gov.bc.ca for a username and password. Once you log in, click on the "CLUS Explorer Tool" link. This will take you to a simple webpage with a list of tabs on the left side of the page. Click on the "Dashboard" tab, and it will open a list tabs specific to indicators tracked by the model (e.g., "Forestry" and "Caribou"). Click on the "Scenario" tab, and it will open two boxes in the main window: "Area of interest" and "Scenarios".

![](images/clus_explorer_home.jpg) 
In the "Area of interest" box you can click the arrow on the right side to select from a drop down list of the harvest units (e.g., TSAs and TFLs) where simulations were run. These consist of the names of the 'schemas' in the PostgreSQL database, and you should see the "tutorial" area of interest/schema. Select it, and you will see some check boxes appear in the "Scenarios" box, and a "Current State" display will appear on the right side of the main window. 

The check boxes correspond to the scenario names that were simulated for the harvest unit, by reading the "scenarios" table in the PostgreSQL database. The "Current State" display shows the characteristics of the landscape of the harvest unit, at the start of the simulation. It reads the "state" table in the PostgreSQL database and provides information on things such as the age structure of the forest, the amount THLB and roaded area and the average volume/ha of available stands. Click on the "tutorial" text box to mark it with a check, and then click the "forestry" tab on the left side.  

![](images/clus_explorer_aoi.jpg) 

Here you will see a stack of green boxes with a title on the left side and plus sign non the right side. Each of these boxes can be opened to obtain a figure of a forest harvest characteristics of the simulation. Click on the plus sign on the "Harvest Flow" box and you will get a figure showing the area (top) and volume (bottom) of forest harvested at each time interval. You will notice the BAU scenario harvest volume is a flat line, indicating the maximum non-declining harvest yield.

![](images/clus_explorer_harvestflow.jpg) 

Click on the various boxes to explore the outputs. The "Transition Harvest" box illustrates the amount of volume harvested from managed stands at each time interval. The "Available THLB" box illustrates how much area of THLB is available and the "Growing Stock" illustrates how much volume is available at each time interval. You can also explore some of the other tabs, but note that some of these may not function, as he information may not be output for the scenario. Also note that the web application should be considered as a 'beta version', and requires some improvements.

Also note that you can visualize some spatial outputs (i.e., rasters of cutblocks, roads and constraint areas) from each scenario. To do this, click on "Map Viewer" tab on the left hand side of the page. This will open a "Map Query" box in the middle of the page with a drop down box. From the drop down box you can select the raster outputs specific to the scenarios you checked. These raster names correspond to the rasters output from the simulation. Click on the raster ending with "_cutblocks" and click on "Load" and you will see a raster layer colour-coded to the year that a blockwas last harvested.

![](images/clus_explorer_map.jpg) 

Also note that there is a "Query Builder" tab on the left side of the page, that you can use to build SQL queries of data in the PostgeSQL database, by selecting the Table, Tables and Columns, and data summary type. 

The above provides you with some tools and examples of how to download and illustrate the data to explore simulation scenarios. There is a high degree of flexibility in that you can use the tools provided in the web app, download the data yourself and create your own figures and tables, modify the web app to include different ouptuts and even design your own output "reports" in the CLUS modules.

## 11. Conclusion
Congratulations! You have completed the tutorial and are well on your way to becoming an expert in the CLUS model. Feel free to contact the CLUS team with questions or comments. 

We are always looking for ways to improve the CLUS framework, so please contact us via our GitHub page with any issues or requests, or go ahead and start a new branch and make some suggestions by editing the code directly. Happy modeling!




  
