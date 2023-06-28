# SQL Procedure to find Program Usage recursively using DSPPGMREF

Given a program (or any of the objects that DSPPGMREF handles), the PGM_REFS stored procedure will find all the obects that the program uses, and then recursively finds all that objects that they use, and so on, to an essentally unlimited depth.

This is the product of my experimentation with PL/SQL. It may be short on error handling, and it doesn't do any validity checking on the parameters. But since I expect you are a developer, you can probaly live with that. Or improve it.

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

Change the library and then run this first.

## pgm_refs.sql
This is the code to create the PGM_REFS procedure. The library in which the REFS file is built needs to be changed to suit your environment.

## pgm_refs_test.SQL

These are some samples of calling the procedure to test it. I used iACS Run SQL Scripts. You could also call it in a CL program using the RUNSQLSTM command. (Or run it in STRSQL.)

## Sample Output File Contents

![Sample ](Images/Sample1.png)

## Debugging

I had difficulty debugging this. 

1. I was working on PUB400.COM and the System Debugger in iACS shows the source, but it would never stop on breakpoints. 
2. The DSPPGMREF outfiles are in QTEMP. You can make a single change to put them in one of you libraries if you want to look at them. You will also have to comment out the delete at the bottom of the loop.