---
title: "Migrate Oracle to PostgreSQL"
author: "Kyle Lochhead"
date: "April 24, 2019"
output:
  html_document:
    keep_md: yes
---



## Description

ora2pg moves an Oracle database to PostgreSQL. An entire schema or a single table can be migrated from Oracle to PostgrSQL. The documentation for this tool can be found [here](http://ora2pg.darold.net/documentation.html).

To get this tool working there are a series of steps

* Get [Perl](https://www.perl.org/)
* Get [ora2pg](http://ora2pg.darold.net/)
* Set `ENV`
* Install Oracle Perl Library
* Use ora2pg (ex. for a single table)

### Get [Perl](http://strawberryperl.com/) for MS Windows
	#Strawberry Perl 5.28.1.1 (64 bit)
	#check the install with 
	
`cmd.exe perl -version`

### Get [ora2pg](https://github.com/darold/ora2pg/releases)

Save in C:/Data/temp_install

Unzip it

In cmd.exe:

`cd <un tarred location>\ora2pg-20.0`

`perl Makefile.PL`

`gmake && gmake install`

### Set the environment variables

`ORACLE_HOME= <ORACLE_CLIENT_SOFTWARE_LOCATION>` ex-> "C:/ORACLE/ORAHOME_11g""

`LD_LIBRARY_PATH= <ORACLE_CLIENT_HOME>/lib`

### Install DBD::Oracle libraries - Internet is must

`perl -MCPAN -e "install DBD::Oracle"`
	
### Use ora2pg
#### Update the configuration file in c:/ora2pg/ora2pg.conf

ORACLE_HOME	`C:/ORACLE/ORAHOME_11g`

ORACLE_DSN	dbi:Oracle:host=BCGW.BCGOV;sid=IDWPROD11;port=1521

ORACLE_USER	`<USER>`

ORACLE_PWD	`<PSWRD>`

USER_GRANTS     1

SCHEMA	`WHSE_BASEMAPPING`

ALLOW		`TRIM_EBM_WATERBODIES`

FTS_INDEX_ONLY	1

DISABLE_SEQUENCE	1

DISABLE_TRIGGERS 1

PG_DSN		`dbi:Pg:dbname= <dbName>; host=localhost;port=5432`

PG_USER	`<USER>`

PG_PWD	`<PSWRD>`

OUTPUT		output.sql

DATA_LIMIT	150000

DROP_INDEXES	1

PG_VERSION	9.5

AUTODETECT_SPATIAL_TYPE	1

DEFAULT_SRID		3005

GEOMETRY_EXTRACT_TYPE	INTERNAL

#### Run the ora2pg.conf to create the table 
`TYPE TABLE`

#### Run psql

`psql -h localhost -d <dbName> -a -f c:/ora2pg/output.sql`

#### Run the ora2pg.conf to load the table
`TYPE TABLE, INSERT`
