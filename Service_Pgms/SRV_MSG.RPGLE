**free
//==============================================================
//=== SRV_MSG service program contains prodcedure for sending
//=== messages:
//   1) With QMHSNDPM
//   2) With Qp0zLprintf (to job log.)
//==============================================================
// CRTRPGMOD MODULE(SRV_MSG)
//
// CRTSRVPGM SRVPGM(SRV_MSG)
//   SRCFILE(*LIBL/SRV_PGMS) SRCMBR(SRV_MSGBND)
//   TEXT('Messages service program')
//
// ADDBNDDIRE BNDDIR(UTIL_BND) OBJ((SRV_MSG *SRVPGM *DEFER))
//==============================================================
// 12/2023  Convert to totally **FREE
//==============================================================

ctl-opt nomain option(*nodebugio: *srcstmt);
/INCLUDE ../Copy_Mbrs/SRV_MSG_P.RPGLE

//=== QMHSNDPM internal prototype =============================
dcl-pr QMHSNDPM extpgm('QMHSNDPM');
    *n char(7) const; // piMsgId
    *n char(20) const; // piMsgFile
    *n char(1024) const options(*varsize); // piMsgData
    *n int(10) const; // piMsgDataLgth
    *n char(10) const; // piMsgType
    *n char(10) const; // piCallStk
    *n int(10) const; // piRelCallStk
    *n char(4); // piRtnMsgKey
    *n char(17); // apiErrorDS
end-pr;

//=== QMHRMVPM internal prototype =============================
dcl-pr QMHRMVPM extpgm('QMHRMVPM');
    *n char(10); // pPgmMsgQ
    *n int(10); // PgmStk
    *n char(4); // MsgKey
    *n char(10); // Remove
    *n char(17); // apiErrorDS
end-pr;

//=== Qp0zLprintf =============================================
dcl-pr printF extproc('Qp0zLprintf');
    *n pointer value options(*string); // piMsg
end-pr;

//=== SNDMSGPGMQ ===============================================
//    SeND a MeSsaGe to a ProGraM message Queue.
// Sends a pre-defined message to a program message queue
// that you provide as a parameter.
// Primarily designed to be used in interactive programs
// that send messages via a message subfile.
// See also CLRMSGPGMQ which clears messages from a program
// message queue.
//==============================================================
// Conceptual call:
//=================
// H BndDir('UTIL_BND')
//  /include ../Copy_Mbrs/SRV_MSG_P.RPGLE   
// D ProgStatus     sds
// D PgmName           *PROC
//  SNDMSGPGMQ(PgmName:
//             Msgid:
//             MsgFile:
//             MsgDta);
//==============================================================
dcl-proc SndMsgPgmQ export;
    dcl-pi SndMsgPgmQ;
        pMsgQ char(10);
        pMsgid char(7);
        pMsgFile char(10);
        pMsgDta varchar(512) options(*nopass);
    end-pi;
//=== Calling Parameters =======================================
// Parm        I/O/B  Description
// ----        -----  -----------
// pMsgQ       I      Message queue to send to.  Usually the
//                    program name, or the MAIN procedure name
//                    obtained with %proc().
// pMsgId      I      Predefined message id, e.g. CPF9898.
// pMsgFile    I      Message file containing pMsgid. (Library
//                    is assumed as *LIBL.)
// pMsgDta     I      Optional: Data to substitute into the message.
//                    (Trailing blanks will be truncated before use.)
//=== API Error Code Structure ==================================
// We don't provide any bytes, so an error will cause a crash,
// because if we get an error here something bad has happened.
    dcl-ds APIError len(272);
        APIEProv int(10) inz(0) pos(1);
        APIEAvail int(10) inz(0) pos(5);
        APIErrId char(7) inz(*blanks) pos(9);
    end-ds;
//=== QMHSNDPM Parameters =======================================
    dcl-s QMsgFile char(20);
    dcl-s MsgType char(10) inz('*INFO');
    dcl-s StackCntr int(10) inz(0);
    dcl-s MsgKey char(4) inz(' ');
    dcl-s MsgDta char(256) inz(' ');
    dcl-s MsgDtaLgth int(10);
//=== SNDMSGPGMQ execution starts here ==========================
    QMsgFile = pMsgFile + '*LIBL';
         // Message data length for QMHSNDPM is optional.  If supplied,
         // use, else default to 0.
    if %parms > 3;
        MsgDta = pMsgDta;
        MsgDtaLgth = %len(%trimr(MsgDta));
    else;
        MsgDtaLgth = 0;
    endif;
//=== Send message with API =====================================
    QMHSNDPM (pMsgid
                  :QMsgFile
                  :MsgDta
                  :MsgDtaLgth
                  :MsgType
                  :pMsgQ
                  :StackCntr
                  :MsgKey
                  :APIError);
    // Exit with LR off. This is a tiny routine which will probably
    // be called again.
    return;
end-proc;
//=== CLRMSGPGMQ =-=============================================
//    CLeaRs all MeSsaGes from a ProGraM message Queue
// Clears all the messages from a program message queue that
// you specify as a parameter.
// It is primarily designed for use by interactive programs that
// send messages through a message subfile.
// See also SNDMSGPGMQ which sends a message to the program queue.
//
// Always returns *OFF
//===============================================================
// Conceptual call:
//=================
// H BndDir('UTIL_BND')
//  /include ../Copy_Mmbrs/SRV_MSG_P.RPGLE   
// D ProgStatus     sds
// D PgmName           *PROC
//  CLRMSGPGMQ(PgmName)

dcl-proc ClrMsgPgmQ export;
    dcl-pi ClrMsgPgmQ ind;
        pPgmMsgQ char(10);
    end-pi;

    //=== API Error Code Structure ==================================
    // We don't provide any bytes, so an error will cause a crash,
    // because if we get an error here something bad has happened.
    dcl-ds APIError len(272);
        APIEProv int(10) inz(0) pos(1);
        APIEAvail int(10) inz(0) pos(5);
        APIErrId char(7) inz(*blanks) pos(9);
    end-ds;
    //=== Parameters for QMHRMVPM API ===============================
    dcl-s PgmStk int(10) inz(0);
    dcl-s MSgKey char(4) inz(*blanks);
    dcl-s Remove char(10) inz('*ALL');

  //=== Calling Parameters =============================================
  // Parm      I/O/B    Description
  // ----      -----    -----------
  // pPGMMsgQ    I      Program message queue to clear.
  //=== ClrMsgPgmQ execution starts here ==========================
    QMHRMVPM(pPgmMsgQ
                 :PgmStk
                 :MSgKey
                 :Remove
                 :APIError);

    // Exit with LR off.  This is a tiny routine which will probably
    // be called again.
    return *off;

end-proc;

//=== SndEscMsg ===============================================
// Sends CPF9898 Escape message of the provided text.
// This will kill the current program and cause an
// exception in the one that called it.

dcl-proc SndEscMsg export;

    dcl-pi SndEscMsg;
        piMsg varchar(512) const;
        piStackEnt int(10) const options(*nopass);
    end-pi;

       //--- Parameters for QMHSNDPM -------------------------
    dcl-c MSGID const('CPF9898');
    dcl-c MSGF const('QCPFMSG   *LIBL     ');
    dcl-c MSGTYPE const('*ESCAPE   ');
    dcl-c PGMQUE const('*         ');
    dcl-s InvCount int(10) inz(2);
    dcl-s ApiError char(17) inz(x'00');
    dcl-s RetMsgKey char(4);
    dcl-s DataLen int(10);

    //--- Local Variables ---------------------------------
    dcl-s MsgData char(1024);

    DataLen = %len(piMsg);
    MsgData = piMsg;

    if %parms = 2;
        InvCount = piStackEnt;
    else;
        InvCount = 2;
    endif;

    QMHSNDPM(MSGID
                  :MSGF
                  :MsgData
                  :DataLen
                  :MSGTYPE
                  :PGMQUE
                  :InvCount
                  :RetMsgKey
                  :ApiError);
    return;


end-proc;

//=== SndInfMsg ===============================================
// Sends CPF9898 Info message of the provided text to the
// external message queue.
// Useful for debugging. See also JobLogMsg.

dcl-proc SndInfMsg export;

    dcl-pi SndInfMsg;
        piMsg varchar(512) const;
    end-pi;

    //--- Parameters for QMHSNDPM -------------------------
    dcl-c MSGID const('CPF9898');
    dcl-c MSGF const('QCPFMSG   *LIBL     ');
    dcl-c MSGTYPE const('*INFO     ');
    dcl-c PGMQUE const('*EXT      ');
    dcl-c INVCOUNT const(2);
    dcl-s ApiError char(17) inz(x'00');
    dcl-s RetMsgKey char(4);
    dcl-s DataLen int(10);

    //--- Local Variables ---------------------------------
    dcl-s MsgData char(1024);

    DataLen = %len(piMsg);
    MsgData = piMsg;

    QMHSNDPM(MSGID
                  :MSGF
                  :MsgData
                  :DataLen
                  :MSGTYPE
                  :PGMQUE
                  :INVCOUNT
                  :RetMsgKey
                  :ApiError);
    return;

end-proc;

//=== JobLogMsg ===============================================
// Write arbitray message to the Job log.
// Uses Qp0zLprintf, which is a C function.
// Useful for debugging. See also SndInfMsg.

dcl-proc JobLogMsg export;

    dcl-pi JobLogMsg;
        piMsg varchar(512) value;
    end-pi;

    dcl-s wkMsg like(piMsg:+1);
    dcl-c EOL x'25';

    wkMsg = piMsg + EOL;
    printF(wkMsg);
    return;
end-proc;
