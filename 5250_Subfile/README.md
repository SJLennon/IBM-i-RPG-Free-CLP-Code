### 5250 Subfile: Full Screen and Windows

(__Under Construction__)

This is a working application that allows display, selection and maintenance of a customer master. The screens are _similar_ to what you see in PDM. The code is modular and there are several programs that can be called from multiple places.  SQL is used for all database IO. There are full screen subfiles and subfiles in a window.

#### Sample Inquiry Screens

![Inquiry Subfile](Images/Inquiry_Subfile.png)

![Inquiry Subfile](Images/Inquiry_Display.png)

#### Sample Maintenance Screen
![Inquiry Subfile](Images/Maintenance_Display.png)

* PMTCUSTR 

    RPG program that puts up a 5250 subfile that allows searching by customer name, city and state. Display of Inactive records can be toggled using F9.
    
    There are 3 functions, or modes, controlled by the first parameter passsed:  Inquiry to display a record; Maintenance to change a record;, Selection to return a customer id.

        - I gives 5=Display
        - M gives 2=Edit 5=Display
        - S gives 1=select 5=Display
     Conceptually, you can call this program from almost anywhere and  access to it is contolled by whatever menuing or security system you have in place. The general user population would progably get Inquiry and Sales would have Maintanance. Selection could be used for any in-house program that needed to prompt for  a customer id number.
    
* PMTCUSTD
  
  This is the display file for PMTCUSTR.

* CustMast.SQL

  SQL code to create and populate the CUSTMAST tsble. You will need to change the _set schema_ to your target library.

  Contains 300 randomly generate rows, courtesy of the fine folk at _http://generatedata.com/_, plus a little tweaking by hand.   