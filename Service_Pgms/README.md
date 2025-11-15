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

## STATEVAL

  A service program to validate a 2-character USA state code.

  This demonstrates several techniques:
   
  - Using a variable sized array.
  
  - Loading the array with SQL on the first call.
  
  - In the first and subsequent calls using the array for the lookup.

  - Use of static variables

  - Passing an optional parameter.

### Couple or caveats:

  - Any program that call this service *must not* be in the default activation group, otherwise the arrary will be loaded every call. So code `ctl-opt DftActGrp(*NO) ActGrp(...)`.

  - %LOOKUP does a binary search, so the data loaded must be in sorted--note that I have an ORDER BY on the SQL select. In practical terms, a binary search of this size of table might be less efficent than just plain old LOOKUP. Theory says it is a tradeoff until you get to 100 or more items in the table.

  - You can find SQL to create/load the STATES table in the *5250 Subfile* folder.

#### STATEV_T
A program to test STATEVAL. Note the 'ActGrp(*new)'.


