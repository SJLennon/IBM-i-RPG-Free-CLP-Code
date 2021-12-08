### Service Programs

Utility Service Programs.

* SRV_MSG

    Contains procedures to send messages from an RPG program.

    **SndMSgPgmQ**: Send message to a provided program queue. (Interactive programming.)

    **ClrMsgPgmQ**:  Clears all messages from the provided program queue. (Interactive programming.)

    **SndEscMsg**:    Send provided text as an escape message.

    **SndInfMsg**:   Send provided text as info message to the external message queue.

    **JobLogMsg**:   Send provided text to the job log using Qp0zLprintf, a C function. For testing, convenient alternative to the DSPLY opcode.

* SRV_STR

    Contains procedures to manipulate strings in an RPG program.

    **CenterStr**:  Center a string.
  
* SRV_SQL
  
  Helper procedures for RPG programs using embedded SQL.

  **SqlProblem**:  For those "never should happen" SQL errors. Does DUMP(A) and dends escape message of provided text and SQL diagnostics.
  
* CRTBNDDIR

   A CLLE program to create UTIL_BND, a binding directory for easy compiling of program that use SRV_MSG.

* SRVMSGBND
  
    Binder source used when creating SRV_MSG.
  
* SRV_MSGTR

     RPG program to test the procedures in SRV_MSG.

* SRV_MSGTD
  
  Display file used by SRV_MSGTR.

* SRVMSGTL

  RPG program to test and demonstate JobLogMsg in SRV_MSG.

* SRV_STRTR

     RPG program to test the procedures in SRV_STR.

* SHOW

  RPG program to display a 5250 message using the QUILNGTX API. Useful for testing, but possibly
  JobLogMsg in SRV_MSG is more useful. Really should be part of SRV_MSG, but it is totally *FREE for and I have left SRV_MSG partially fixed.

  SHOW_T

    RPG program to test & exercise SHOW
