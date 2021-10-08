### SQL_SKELETON

Batch program with SQL embedded in RPGLE. Includes error checking and handling.  It could be the starting point for any embedded SQL program. There are versions in completely free format and in not free format where the D-Specs are in fixed format.

*SQL_SKEL* is completely free format, i.e., code begins in column 1.

*SQL_SKELNF* is not totally free format, because the D_SPECS are in fixed format.  This should be compatible back to V5R4 I think and compatible with coding in SEU.

*SQL_SKEL2* is an upgrade to SQL_SKEL.  The SQLProblem procedure is now in the SRV_SQL service program, so the code is much shorter. This is completely free format.

  **NOTE:** There is a deliberate duplicated line in the SQL_SKEL2 code so that it triggers the SQLProblem handling procedure.

You should be able to compile any version of the program without any changes and run it on virtually any IBM i with a reasonably current OS release.  I developed it on a V7R4 machine.  If you are at an older release then the not totally free version will probably compile.

*SQLC and SQLC2* are simple CL program that call SQL_SKEL and SQL_SKEL2, so that you can see the difference in how SQL errors are reported. Call them from QCMD or the Main Menu.
