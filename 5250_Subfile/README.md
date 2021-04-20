# 5250 Subfile: Full Screen and Windows

This is a working application that allows display, selection and maintenance of a customer master. The screens are _similar_ to what you see in PDM. The code is modular and there are several programs that can be called from multiple places.  SQL is used for all database IO. There are  "page at a time" subfiles (full screen and in a window) and a "load all" subfile in a window. The windows show a couple of border styles.

## Sample Inquiry Screens

![Inquiry Subfile](Images/Inquiry_Subfile.png)

![Inquiry Subfile](Images/Inquiry_Display.png)

## Sample Maintenance Screen

![Inquiry Subfile](Images/Maintenance_Display.png)

## Prompting to Select a State

![State Prompt](Images/State_Prompt.png)

## General Notes

Some of the programs use /Include statements, which are found in the Copy_Mbrs directory.  In the code these programs refer to my DEMO library, so to compile you may need to change this.

The RPG code is free form, except that the D-Specs are fixed form. This probably allows more  developers who are still on older versions of the OS, or are still using the out of date SEU, to more easily use the code.  The code can be converted to totally free format using the free _**"JCRHFD - Rpg H,F,D to free form syntax"**_ command available at [JCRCMDS.COM](http://www.jcrcmds.com/jcrdown2.html#JCRHFD_tag). If there is interest I may post totally free form versions.

The genesis of these programs was code that I wrote in RPG IV for a Fortune 500 retailer circa 2002-2004. The code was then cloned as a standard approach by another team leader.  This code is a more modern version that I cleaned up in 2020.

The style tries to have consistent naming and I do not share field names between the RPG and the display files--I've seen too many accidental modifications in my support career.

The display file uses a private set of indicators, something I started doing to try to educate coworkers who were struggling with monolithic code where all 99 indicators were in use. You can also reset indicators and such in display files, but I prefer to do it myself.

### PMTCUSTR/PMTCUSTD

 RPG program that puts up a 5250 subfile that allows searching by customer name, city and state. Display of Inactive records can be toggled using F9.

 There are 3 functions, or modes, controlled by the first parameter passsed:  Inquiry to display a record; Maintenance to change a record; Selection to return a customer id.

        - I gives 5=Display
        - M gives 2=Edit 5=Display
        - S gives 1=select 5=Display
  If the cursor is in a field  with a + in the field name (ST+ here) you can press F4 to prompt the field.
  
  Conceptually, you can call this program from almost anywhere and control access to it  by whatever menuing or security system you have in place. The general user population would progably get Inquiry and Sales would have Maintenance. Selection could be used for any in-house program that needed to prompt for  a customer id number.
  
### MTNCUSTR/MTNCUSTD

  RPG program that maintains a customer.  Customer id is provided as the first parameter. It also adds or displays a customer. Function is controlled by the second parameter. It is called from PMTCUSTR, but it could be called from any program that has a customer id available, or which needs to add a customer.

  If the cursor is in a field  with a + in the field name (ST+ here) you can press F4 to prompt the field.

  The window has the default border, which may vary depending on which 5250 emulator you are using. The sample is using the iACS emulator from IBM.

### PMTSTATER/PMTSTATED

RPG program and window display file to prompt for a USA state code.  Called when F4 is used in PMTCUSTR or MTNCUSTR. Display can be sequenced by either state name or 2-character code, toggled by F7.

Strictly speaking, this is more of a demonstration program that may, or may not, have a lot of practical value in real life.

The window has a blue border of reverse image blanks. This will display consistently across most 5250 emulators.

#### CRTMSGF

  Creates the CUSTMSGF message file used by the programs.

#### CRTDTAARA
  
  Creates the CUSTNEXT data area that contains the next available customer id.

#### CustMast.SQL

  SQL code to create and populate the CUSTMAST table. You will need to change the _**set schema**_ in the first line to your target library.  You would put this file in the IFS and run it with the RUNSQLSTM command.

  Contains 300 randomly generate rows, courtesy of the fine folk at _http://generatedata.com/_, plus a little tweaking by hand.

### States.SQL

SQL Code to create and populate the STATES table, which is a table of USA state names and their 2-character abbreviations.
