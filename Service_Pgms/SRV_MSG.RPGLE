
      //==============================================================
      //=== SRV_MSG service program contains prodcedure for sending
      //=== messages:
      //   With QMHSNDPM
      //   With Qp0zLprintf (to job log.)
      //==============================================================
      // CRTRPGMOD MODULE(SRV_MSG)
      //
      // CRTSRVPGM SRVPGM(SRV_MSG)
      //   SRCFILE(*LIBL/SRV_PGMS) SRCMBR(SRV_MSGBND)
      //   TEXT('Messages service program')
      //
      // ADDBNDDIRE BNDDIR(UTIL_BND) OBJ((SRV_MSG *SRVPGM *DEFER))

     h nomain option(*NoDebugIo: *srcstmt)
      /include copy_mbrs,Srv_Msg_P

       //=== QMHSNDPM internal prototype =============================
     D QMHSNDPM        pr                  ExtPgm('QMHSNDPM')
     D  piMsgId                       7a   Const
     D  piMsgFile                    20a   Const
     D  piMsgData                  1024a   Const OPTIONS(*varsize)
     D  piMsgDataLgth                10i 0 Const
     D  piMsgType                    10a   Const
     D  piCallStk                    10a   Const
     D  piRelCallStk                 10i 0 Const
     D  piRtnMsgKey                   4a
     D  apiErrorDS                   17a

       //=== QMHRMVPM internal prototype =============================
     d QMHRMVPM        pr                  Extpgm('QMHRMVPM')
     d pPgmMsgQ                      10a
     d PgmStk                        10i 0
     d MsgKey                         4a
     d Remove                        10a
     D  apiErrorDS                   17a

       //=== Qp0zLprintf =============================================
     d printF          pr                  extproc('Qp0zLprintf')
     d piMsg                           *   value options(*string)

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
      //  /include copy_mbrs,Srv_Msg_P
      // D ProgStatus     sds
      // D PgmName           *PROC
      //  SNDMSGPGMQ(PgmName:
      //             Msgid:
      //             MsgFile:
      //             MsgDta);
      //==============================================================
     P SndMsgPgmQ      b                   export
     d SndMsgPgmQ      pi
     d  pMsgQ                        10
     d  pMsgid                        7
     d  pMsgFile                     10
     d  pMsgDta                     512    options(*NOPASS)
     d                                     Varying
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
     dAPIError         ds           272
     d APIEProv                1      4b 0 inz(0)
     d APIEAvail               5      8b 0 inz(0)
     d APIErrId                9     15    inz(*blanks)
      //=== QMHSNDPM Parameters =======================================
     d QMsgFile        s             20
     d MsgType         s             10    inz('*INFO')
     d StackCntr       s             10i 0 inz(0)
     d MsgKey          s              4    inz(' ')
     d MsgDta          s            256    inz(' ')
     d MsgDtaLgth      s             10i 0
      //=== SNDMSGPGMQ execution starts here ==========================
      /free
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
      /end-free
     p SndMsgPgmQ      e

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
      //  /include copy_mbrs,Srv_Msg_P
      // D ProgStatus     sds
      // D PgmName           *PROC
      //  CLRMSGPGMQ(PgmName)

     p ClrMsgPgmQ      b                   export
     D ClrMsgPgmQ      pi              N
     d pPgmMsgQ                      10

      //=== API Error Code Structure ==================================
      // We don't provide any bytes, so an error will cause a crash,
      // because if we get an error here something bad has happened.
     dAPIError         ds           272
     d APIEProv                1      4b 0 inz(0)
     d APIEAvail               5      8b 0 inz(0)
     d APIErrId                9     15    inz(*blanks)
      //=== Parameters for QMHRMVPM API ===============================
     d PgmStk          s             10i 0 inz(0)
     d MSgKey          s              4    inz(*blanks)
     d Remove          s             10    inz('*ALL')

       //=== Calling Parameters =============================================
       // Parm      I/O/B    Description
       // ----      -----    -----------
       // pPGMMsgQ    I      Program message queue to clear.

       //=== ClrMsgPgmQ execution starts here ==========================
       /free
          QMHRMVPM(pPgmMsgQ
                 :PgmStk
                 :MsgKey
                 :Remove
                 :APIError);

      /free
         // Exit with LR off.  This is a tiny routine which will probably
         // be called again.
         RETURN *off;
      /end-free

     p ClrMsgPgmQ      e

       //=== SndEscMsg ===============================================
       // Sends CPF9898 Escape message of the provided text.
       // This will kill the current program and cause an
       // exception in the one that called it.

     P SndEscMsg       B                   Export

     D SndEscMsg       PI
     D piMsg                        512a   Const Varying
     D piStackEnt                    10i 0 Const options(*Nopass)

       //--- Parameters for QMHSNDPM -------------------------
     D MsgId           c                   const('CPF9898')
     d MsgF            c                   const('QCPFMSG   *LIBL     ')
     d MsgType         c                   const('*ESCAPE   ')
     d PgmQue          c                   const('*         ')
     d InvCount        s             10i 0 inz(2)
     d ApiError        s             17a   inz(X'00')
     d RetMsgKey       s              4a
     D DataLen         s             10i 0

       //--- Local Variables ---------------------------------
     D MsgData         s           1024a

      /FREE

          DataLen = %len(PiMSG);
          MsgData = piMsg;

          if %parms = 2;
            InvCount = piStackEnt;
          else;
            InvCount = 2;
          endif;

          QMHSNDPM(MsgId
                  :MsgF
                  :MsgData
                  :DataLen
                  :MsgType
                  :PgmQue
                  :InvCount
                  :RetMsgKey
                  :APIError);
          return;

      /end-free

     P SndEscMsg       E

       //=== SndInfMsg ===============================================
       // Sends CPF9898 Info message of the provided text to the
       // external message queue.
       // Useful for debugging. See also JobLogMsg.

     P SndInfMsg       B                   Export

     D SndInfMsg       PI
     D piMsg                        512a   Const Varying

       //--- Parameters for QMHSNDPM -------------------------
     D MsgId           c                   const('CPF9898')
     d MsgF            c                   const('QCPFMSG   *LIBL     ')
     d MsgType         c                   const('*INFO     ')
     d PgmQue          c                   const('*EXT      ')
     d InvCount        c                   const(2)
     d ApiError        s             17a   inz(X'00')
     d RetMsgKey       s              4a
     D DataLen         s             10i 0

       //--- Local Variables ---------------------------------
     D MsgData         s           1024a

      /FREE

          DataLen = %len(PiMSG);
          MsgData = piMsg;

          QMHSNDPM(MsgId
                  :MsgF
                  :MsgData
                  :DataLen
                  :MsgType
                  :PgmQue
                  :InvCount
                  :RetMsgKey
                  :APIError);
          return;

      /end-free

     P SndInfMsg       E

       //=== JobLogMsg ===============================================
       // Write arbitray message to the Job log.
       // Uses Qp0zLprintf, which is a C function.
       // Useful for debugging. See also SndInfMsg.

     P JobLogMsg       B                   Export

     D JobLogMsg       PI
     D piMsg                        512a   Value Varying

     d wkMsg           s             +1    like(piMSg)
     d EOL             c                   x'25'

      /FREE
        wkMsg = piMsg + EOL;
        printF(wkMsg);
        return;
      /end-free
     P JobLogMsg       E
