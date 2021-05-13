# RCDLCKDSP - Displaying Locked Record Info in Interactive Programs

Older interactive programs often read a record for update, then displayed it on the screen and wait for the user to make changes. The record might remain locked for a short time while date was keyed or it might wait until after a rest break or a phone call or some other interruption.

This requires less code, but is a poor technique that can increase Support/Help Desk call. It still exists in many older programs and some packaged software.

When an interactive program tries to update a record that is locked by another user and the program doesn't handle it the RPG error routines kick in and give the user a confusing, and potentially dangerous, error message.

In new programs, it is much better to trap the locked record condition and handle it by calling RCDLCKDSP. It shows who has the record locked so you can ask them to finsh up what they were doing and free up the record. It allows you to retry your update or allows you to cancel what you are doing.

Locking information is provided in a window, like this:

![window image](Images/RcdLckDsp%20Window.png)

The top half of the window is information for the current user of the interactive program.

The bottom half provides information for the IT Department should the need arise.

## RCDLCKDSP

This is the standalone RPG program that handles the window display. It is passed two parameters:

|   |   |            |   |
|---|---|------------|---|
|1. |Output |CL1|
||| User's reply about what to do:
|||R - Retry the IO operation that failed
|||C - Cancel the program
|||D - DUmp the program and cancel
|2. |Input|\*  
|||Pointer to the *PSDS in the calling program.
|||(A pointer is used because the *PDSD is not always the same length in the calling  program.)

See RCDLCKDEMO for a sample call.

## RCDLCKDSPD

This is the display file for the window.

## RCDLCKDEMO

This program demonstrates the consistent way to handle the situation in an interactive program where the record you are reading for update may be locked by another program.

Call it in two separate sessions to see a RCDLCKDSP pop up a window.

## RCDLCKBAD

This program demonstates what happens if you fail to account for the record you want to update is locked by someone else.  Typically the user get a message like this:

```Unable to allocate a record in file QCUSTCDT (R C G D F).```

None of the possible responses is particularly useful.
