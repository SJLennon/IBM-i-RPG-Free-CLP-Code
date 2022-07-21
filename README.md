# RPGLE free format, SQL and CLP Code for the IBM i

More developers are learning about the **IBM i** as a wonderful business platform. (It was formerly known as the **AS/400**.)

This repository contains *working* example code, using RPGLE free-format, enbedded SQL and CLP for the IBM i.

My intent is to provide real programs that help you learn and/or improve your current understanding. Explore and adapt the code to your needs. Some of the code may be of use "as is" but no guarantee is provided.

**Each folder has its own ReadMe with additional infomation/documentation.**

Feel free to provide comments and feedback as issues.

## Copy_Mbrs

Code to be copied into other programs.

## Service_Pgms

Utility support routines that are called from other code.

## SQL_SKELETON

Batch program with SQL embedded in RPGLE. Includes error checking and handling.  There are two versions, one in completely free format and one not free with the D-Specs in fixed format.

## 5250 Subfile

Many shops are still using 5250 "green screen" applications and these need to be maintained and/or extended. This is a fully functional modernized 5250 "green screen" Customer Master maintenance and prompting application, with full screen and window displays, modular code, service programs, message files and a sample database.

## BASE36

A service program to add 1 to an alpha-numeric string of any length.

## DATE_UDF

SQL User Defined Functions to convert legacy dates to true dates.  Written in RPG.

## RCDLCKDSP

A standardized way to handle locked records in an interactive program, and display information about who is holding the lock.  For programs that use native IO.

## APIs

Commands, with CLP and RPG programs, calling IBM i APis.

## APIs_SQL

Commands, CLLE, SQLRPGLE using SQL access to APIs.

## Printing Techniques in RPG/**FREE 

Printing without O-Specs or Externally Defined Printer Files

## GRP_JOB

Sets up group jobs suitable for an IBM i developer.

## USPS_Address

SQL QSYS2.HTTP_GET call to the US Post Office webtools API AddressValidateRequest.
RPG service program to call the API and parse the returned XML.

## Utils

Developer Utilities.

    QRY - Qry (List) Contents of a file
    
    RC - Display File Record count
