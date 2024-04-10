**free
//=== Tests procedures in SRV_MSG service program =============
ctl-opt dftactgrp(*no) actgrp(*caller) option(*nodebugio: *srcstmt)
       bnddir('UTIL_BND');

//=== Display File ============================================
dcl-f SRV_MSGTD workstn infds(dfInfDS) indds(dfIndDS) usropn;

//=== Service Program Prototypes ==============================
/INCLUDE ../Copy_Mbrs/SRV_MSG_P.RPGLE

//=== Named hexadecimal constants for function keys ===========
/INCLUDE ../Copy_Mbrs/AIDBYTES.RPGLE

//=== Display File Information Data Structure =================
//    Allows us to determine which function key was pressed
dcl-ds dfInfDS;
  Key char(1) pos(369);
end-ds;
//=== Display File Indicator Data Structure ===================
// This is a "private" indicator area for the display file.
dcl-ds dfIndDS len(99);
  SH_ERR ind pos(40);
end-ds;

//=== Global Switches =========================================
dcl-s SflMsgSnt ind;
dcl-c COWSCOMEHOME const('0');

//=== Work Fields =============================================
dcl-s inx int(10);


//=== Program Status Data Structure ===========================
dcl-ds ProgStatus PSDS;
  PgmName *PROC;
end-ds;

//=============================================================
// === Main Program Loop ======================================
//=============================================================
Init();
SFT_KEYS='F3/F12=Exit';
SH_Cnt = 2;
SH_MSG = 'This is a fine pickle Ollie!';

dou COWSCOMEHOME;
  write SH_HDR;
  write SFT_FKEY;
  if SflMsgSnt = *on;
    write MSGCTL;
  endif;

  exfmt SH_HDR;
  SH_ERR = *off;

  if key = F03 or Key = F12;
    CloseDownPgm();
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
    other;

  endsl;
enddo;

//=============================================================
//=== End of Main Program Loop ================================
//=============================================================

//=== CloseDownPgm ============================================
// Things to do before we issue a return to the caller
Dcl-Proc CloseDownPgm;
  *inlr = *on;
  close SRV_MSGTD;
End-Proc;

//=== Init ====================================================
Dcl-Proc Init;
  MSGPGMQ = PgmName;
  SH_PGM = PgmName;
  if not %open(SRV_MSGTD);
    open SRV_MSGTD;
  endif;
End-Proc;

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
dcl-proc SndSflMsg;
  dcl-pi SndSflMsg ind;
    ErrMsgId char(7) const;
    ErrMsgData char(80) const options(*nopass:*varsize);
    ErrMsgFile char(10) const options(*nopass);
  end-pi;

    // Local fields
  dcl-s retField ind;
  dcl-s wkMsgId char(7);
  dcl-s wkMsgFile char(10);
  dcl-s wkMsgData varchar(512);

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
  SndMsgPgmQ(PgmName:
             wkMsgId:
             wkMsgFile:
             wkMsgData);

  retField = *on;
  RETURN retField;

end-proc;
