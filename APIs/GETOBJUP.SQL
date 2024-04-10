--  Generate SQL 
--  Version:                   	V7R5M0 220415 
--  Generated on:              	02/13/24 22:08:51 
--  Relational Database:       	PUB400 
--  Standards Option:          	Db2 for i 
CREATE or REPLACE TABLE LENNONS1.GETOBJUP ( 
--  SQL150B   10   REUSEDLT(*NO) in table GETOBJUP in LENNONS1 ignored. 
--  SQL1505   20   Number of members for GETOBJUP in LENNONS1 not valid. 
	OUJOBNAME CHAR(10) CCSID 37 NOT NULL DEFAULT '' , 
	OUJOBUSER CHAR(10) CCSID 37 NOT NULL DEFAULT '' , 
	OUJOBNUM CHAR(6) CCSID 37 NOT NULL DEFAULT '' , 
	OUJOBTYPE CHAR(1) CCSID 37 NOT NULL DEFAULT '' )   
	  
	RCDFMT GETOBJU    ; 
  
LABEL ON TABLE LENNONS1.GETOBJUP 
	IS 'Users of an object' ; 
  
LABEL ON COLUMN LENNONS1.GETOBJUP 
( OUJOBNAME IS 'Job                 Name' , 
	OUJOBUSER IS 'Job                 User' , 
	OUJOBNUM IS 'Job                 Number' , 
	OUJOBTYPE IS 'Type' ) ; 
  
LABEL ON COLUMN LENNONS1.GETOBJUP 
( OUJOBNAME TEXT IS 'Job Name' , 
	OUJOBUSER TEXT IS 'Job User' , 
	OUJOBNUM TEXT IS 'Job Number' , 
	OUJOBTYPE TEXT IS 'I=interact, other=non inter' ) ; 
  
GRANT ALTER , DELETE , INDEX , INSERT , REFERENCES , SELECT , UPDATE   
ON LENNONS1.GETOBJUP TO LENNONS WITH GRANT OPTION ; 
  
