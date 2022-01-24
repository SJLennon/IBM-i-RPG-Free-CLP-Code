# USPS_Address - QSYS2_HTTP_GET calling the US Post Office webtools API AddressValidateRequest

USADRVAL is a service program in RPG Free which uses the QSYS2.HTTP_GET SQL function to call the USPS AddressValidateRequest API. The API returns a validated and standarized address (or an error) in an XML document, which is then parsed with the SQL XMLPARSE function and returned to the caller.

To use the USADRVAL you need to obtain a User Id from the US Post Office. [Follow link here](https://www.usps.com/business/web-tools-apis/general-api-developer-guide.htm#_Toc24631952) to register for a free User Id,

Included is a demo interactive program which is a rewritten version of MNTCUSTR in the [5250_Subfile](https://github.com/SJLennon/IBM-i-RPG-Free-CLP-Code/tree/master/5250_Subfile) directory.

## CRTBNDDIR.CLLE

Simple program to create the ADRVAL binding directory.

### MTNCUSTR/MTNCUSTD

Demo program and display file to maintain a customer master. To use the program you must compile the objects in the [5250_Subfile](https://github.com/SJLennon/IBM-i-RPG-Free-CLP-Code/tree/master/5250_Subfile) directory, then compile these two objects.

This program uses a single address line, which is passed as ADDRESS2 to the API. If you decide to use an additional address line, pass it in ADDRESS1.

(This program needs some additional coding to allow you to ignore the USPS standardized address.)

### USADRVAL_T

A program to exercise USADRVAL with a some addresses, writing the input and output side by side to QSYSPRT.

### USADRVAL

The service program. 

Input address and output address are passed in the USADRVALDS data structure, which is found in [Copy_Mbrs](https://github.com/SJLennon/IBM-i-RPG-Free-CLP-Code/commit/c875b751e3ea6055ca295f35caef498b9067f7bb)

A call looks like this:
 ``returned address  = USAdrVal(input address);``

If ADDRESS2 is non blank, they you have a valid address.  Otherwise find a description of the problem in the DESCRIPTION field.
