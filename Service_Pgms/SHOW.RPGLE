**free
// +---------------------------------------------------------------+
// + SHOW (display) text in an IBM i 5250 pop-up window            +
// +---------------------------------------------------------------+
// Replacement (partial) for the DSPLY opcode:
//    1. Accepts text lenths much great than 52.
//    2. Does not accept input.
//
//  Uses the Display Long Text (QUILNGTX) API to display a pop-up
//  window containing the passed string.
//  API doesn't display bidirectional right to left text.
//
// Error Messages
// Message ID Error Message Text
// CPF3C90 E Literal value cannot be changed
// CPF6A4C E At least one parameter value is not correct. Reason code is &1
// CPF9871 E Error occurred while processing
// "Inspired" by others.  Thanks to:
//    Nick Litten https://www.nicklitten.com/dsply-sucks-quilngtx-rocks/
//    Michael Sansoterra  https://www.itjungle.com/2011/09/21/fhg092111-story02/
//
// == NOTE =====================================================================
// This should probably be part of the SRV_MSG service program, but since this
// is **FREE and SRV_MSG is only partially free, I'm leaving it as a separate
// program. For now, anyway...
//
// Probably only useful for testing/debugging and the JOBLOGMSG procdure in
// SRV_PGM is probably more useful.
// =============================================================================

ctl-opt option(*NoDebugIo: *srcstmt)
    dftactgrp(*no) actgrp(*caller)
    main(Show);

dcl-proc Show ;
    dcl-pi Show;
        p_Text varchar(8192) const;
        p_MsgId char(7) Options(*nopass:*omit);
        p_MsgFile char(21) Options(*nopass:*omit);
    end-pi;

    dcl-ds myApiError ;
        APIEProv int(10) inz(%SIZE(APIEData)) pos(1);
        APIEAvail int(10) inz(0) pos(5);
        APIErrID char(7) pos(9);
        APIErrRsv char(1);
        APIEData char(256);
    end-ds;

    dcl-pr QUILNGTX extpgm('QUILNGTX');
        *n char(8192) const; // MsgText
        *n int(10) const; // MsgLength
        *n char(7) const; // MessageId
        *n char(21) const; // MessageFile
        *n options( *omit: *varsize ) like( myApierror ); // ErrorDS
    end-pr;

    dcl-s MsgId like(p_MsgId);
    dcl-s MsgFile like(p_MsgFile);

    If %Parms = 1;
        MsgId = 'CAE0103'; // 'Press Enter to continue.'
        MsgFile = 'QCPFMSG   *LIBL';
    Elseif %Parms = 2;
        MsgId = p_MsgId;
        MsgFile = 'QCPFMSG   *LIBL';
    Elseif %Parms = 3;
        MsgId = p_MsgId;
        MsgFile = p_MsgFile;
    Endif;
    APIEAvail = 0;  // Errors cause a crash.
    QUILNGTX ( p_Text
           : %Len(p_Text)
           : MsgId
           : MsgFile
           : myApiError
           );
    return;
end-proc;
