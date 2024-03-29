
       //=== Tests procedures in SRV_MSG service program =============
     H DftActGrp(*NO) ActGrp(*CALLER) option(*nodebugio: *srcstmt)
     H BndDir('UTIL_BND')

       //=== Display File ============================================
     FSRV_MSGTD CF   E             WorkStn INFDS(dfInfDS)
     F                                     INDDS(dfIndDS)
     F                                     USROPN

       //=== Service Program Prototypes ==============================
      /include copy_mbrs,Srv_Msg_P

       //=== Named hexadecimal constants for function keys ===========
      /include copy_mbrs,##AIDBYTES

       //=== Display File Information Data Structure =================
       //    Allows us to determine which function key was pressed
     D dfInfDS         DS
     D Key                   369    369
       //=== Display File Indicator Data Structure ===================

       // This is a "private" indicator area for the display file.
     D dfIndDS         ds            99
     D SH_ERR                 40     40n


       //=== Global Switches =========================================
     D SflMsgSnt       s               n
     D CowsComeHome    c                   const('0')

       //=== Work Fields =============================================
     D inx             s             10i 0

       //=== Program Status Data Structure ===========================
     D ProgStatus     sds
     D PgmName           *PROC

      /FREE
       //=============================================================
       // === Main Program Loop ======================================
       //=============================================================
       exsr init;
       SFT_KEYS='F3/F12=Exit';
       SH_Cnt = 2;
       SH_MSG = 'This is a fine pickle Ollie!';

       dou CowsComeHome;
         write SH_HDR;
         write SFT_FKEY;
         if SflMsgSnt = *on;
           write MSGCTL;
         endif;

         exfmt SH_HDR;
         SH_ERR = *off;

         if key = F03 or Key = F12;
             exsr CloseDownPgm;
             return;
         endif;

         if SH_MSG = ' ';
             SH_ERR = *ON; // Please enter a message
             iter;
         endif;

         select;
         //-- Enter Key ---------------------------------------------
         when Key = Enter;

         //--- F04 --------------------------------------------------
         when Key = F04;
             SflMsgSnt= SndSflMsg('CPF9898' : SH_MSG);
           iter;

         //--- F05 --------------------------------------------------
         when Key = F05;
         if SflMsgSnt = *on;
           SflMsgSnt = ClrMsgPgmQ(PgmName);
           write MSGCTL;
           iter;
         endif;

         //--- F06 --------------------------------------------------
         when Key = F06;

            SndInfMsg(SH_MSG);
           iter;

         //--- F07 --------------------------------------------------
         when Key = F07;
            if SH_CNT = 0;
               SndEscMsg(SH_MSG);
            else;
               SndEscMsg(SH_MSG : SH_CNT);
            endif;
           iter;

         //--- F08 --------------------------------------------------
         when Key = F08;
             JobLogMsg(SH_MSG);
           iter;

         endsl;
       enddo;

       //=============================================================
       //=== End of Main Program Loop ================================
       //=============================================================


       //=== CloseDownPgm ============================================
       // Things to do before we issue a return to the caller
       begsr CloseDownPgm;
           *inlr = *on;
           close SRV_MSGTD;
       endsr;

       //=== Init ====================================================
       begsr Init;
         MSGPGMQ = PgmName;
         SH_PGM = PgmName;
         if not %open(SRV_MSGTD);
           open SRV_MSGTD;
         endif;
       endsr;

       //=============================================================
       //   S u b  P r o c e d u r e s
       //=============================================================

       //=== SndSflMsg ===============================================
       // Send a message to the Error Subfile
       // Returns:        *ON
       // Parameter:      ErrMsgId => Msg Id to Send
       // Parameter:      ErrMsgData => Optional Error Message Data
       // Parameter:      ErrMsgFile => Optional Error Message File
       //                 Defaults to CUSTMSGF
       //------------------------------------------------------------
      /END-FREE
     P SndSflMsg       B
     D SndSflMsg       PI              N
     D  ErrMsgId                      7A   CONST
     D  ErrMsgData                   80A   CONST
     D                                     OPTIONS(*NOPASS:*VARSIZE)
     D  ErrMsgFile                   10A   CONST
     D                                     OPTIONS(*NOPASS)

       // Local fields
     D retField        S               N
     D wkMsgId         s              7a
     D wkMsgFile       s             10a
     D wkMsgData       s            512a   varying

      /FREE
       if %parms >2;
         wkMsgFile = ErrMsgFile;
       else;
         wkMsgFile = 'QCPFMSG';
       ENDIF;
       if %parms > 1;
         wkMsgData = ErrMsgData;
       else;
         wkMsgData = ' ';
       ENDIF;
       wkMsgId = ErrMsgId;
       SNDMSGPGMQ(PgmName:
             wkMsgid:
             wkMsgFile:
             wkMsgData);

        retField = *on;
        RETURN retField;

      /END-FREE
     P SndSflMsg       E


