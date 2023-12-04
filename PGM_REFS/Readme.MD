# SQL Procedure to find Program Usage recursively using DSPPGMREF

Given a program (or any of the objects that DSPPGMREF handles), the PGM_REFS stored procedure will find all the obects that the program uses, and then recursively finds all that objects that they use, and so on, to an essentally unlimited depth.

This is the product of my experimentation with SQL Procedures Language (SQL PL). It may be short on error handling, and it doesn't do any validity checking on the parameters. But since I expect you are a developer, you can probaly live with that. Or improve it.

If you have more experience than me, please feel free to suggest better coding techniques.

So far I have not found a decent manual or turorial. If you know of any please pass them on. 

My primary approach was trial and error, with help
from these articles on IT Jungle:
    [Ted HolT Article 1](https://www.itjungle.com/2017/06/12/guru-error-handling-sql-pl-part-1/) and 
    [Ted Holt Article 2](https://www.itjungle.com/2017/10/16/guru-error-handling-sql-pl-part-2/)
and browsing [Scott Forstie Gists on Github](https://gist.github.com/forstie
)

In no way does this replace a real cross reference utilily, such as Hawkeye
or X-Analysis. If you don't have one, this *might* be somewhat useful.

## pgm_refs_Tbl.sql

This is the DDL to create the REFS file that the procedure builds. 

Change the library of the REFS table to one of your libraries and then run this first.

## pgm_refs.sql
This is the code to create the PGM_REFS procedure. Change the library of the REFS table to the library you used above.
There are two places to change following a comments like this: <<<<<< Change this table library >>>>>>>

## pgm_refs_test.SQL

These are some samples of calling the procedure to test it. I used iACS Run SQL Scripts. You could also call it in a CL program using the RUNSQLSTM command. (Or run it in STRSQL.)

## Running

### Parameters
See pgm_refs_test.sql for some sample call.

You need to supply library and name. The type will default to `*PGM` and the depth will default to `0` if not supplied.

### Library list

Since many objects will have a library of `*LIBL`, that is what will get passed to DSPPGMREF for expansion. So you need to have your library list contain all libraries whose objects you want expanded.

### DSPPGMREF Failure

If DSPPGMREF fails internally, `*ERROR` will appear in the three `USES_*` fields in the REFS file. If you get a lot of these check you have your library list correct.

## Sample Output File Contents

![Sample ](Images/Sample1.png)

## Debugging

I had difficulty debugging this. 

1. I was working on PUB400.COM and the System Debugger in iACS shows the source, but it would never stop on breakpoints. You can debug on the green screen but it isn't as convenient.
2. The DSPPGMREF outfiles are in QTEMP. You can make a single change to put them in one of you libraries if you want to look at them. You will also have to comment out the delete at the bottom of the loop.
