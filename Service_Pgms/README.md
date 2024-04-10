# Service Programs

Utility Service Programs that are used in various places.

## SRV_MSG
  
Contains procedures to send messages from an RPG program.

  **SndMSgPgmQ**: Send message to a provided program queue. (Interactive programming.)

  **ClrMsgPgmQ**:  Clear all messages from the provided program queue. (Interactive programming.)

  **SndEscMsg**:    Send provided text as an escape message. (Note that the SND-MSG opcode can replace this in newer compiler versions.)

  **SndInfMsg**:   Send provided text as info message to the external message queue. (Note that the SND-MSG opcode can replace this in newer compiler versions.)

  **JobLogMsg**:   Send provided text to the job log using Qp0zLprintf, a C function. For testing, a convenient alternative to the DSPLY opcode for longer messages.

## SRV_RANDOM

Convenience procedures relating to pseudo random number generation.

**Rand_Int**
    
 Return a random integer with a specified range.

## SRV_STR

Contains procedures to manipulate strings in an RPG program.

**CenterStr**:  Center a string.
  
## SRV_SQL
  
  Helper procedures for RPG programs using embedded SQL.

  **SQLProblem**:  For those "never should happen" SQL errors. Does DUMP(A) and sends escape message of the provided text and adds as much SQL diagnostics as will fit in a 512 byte message.
  
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

## SHOW

  RPG program to display a 5250 message using the QUILNGTX API. Useful for testing, but possibly
  JobLogMsg in SRV_MSG is more useful. Really should be part of SRV_MSG.

  * SHOW_T   RPG program to test & exercise SHOW.
