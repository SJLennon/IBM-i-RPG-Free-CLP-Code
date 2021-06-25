# RPGLE free format, SQL and CLP Code for the IBM i

This repository contains *working* example code, using RPGLE free-format, enbedded SQL and CLP for the IBM i

My intent is to provide real programs that help you learn, or improve your current understanding, and which you can adapt to you needs.

More developers are learning about the **IBM i** as a wonderful business platform. ( It was formerly known as the **AS/400**.)

Feel free to provide comments and feedback as issues.

**Each folder has its own ReadMe with additional infomation/documentation.**

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

## GRP_JOB

Sets up group jobs suitable for an IBM i developer.

## Utils

Developer Utilities.

    QRY - Qry (List) Contents of a file
    
    RC - Display File Record count