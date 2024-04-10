**free
//  ==============================================================
//   Program that locks a record and then waits for input from
//   the operator.
//  
//   Call this program in two different sessions to see the effect.
//  ==============================================================
//   -  Locking the record first is a poor technique because
//      the record remains locked to all other users until the
//      transaction is completed, which may be in a few seconds or
//      after lunch.
//      It is used here to demonstate the RCDLCKDSP processing.
//  ==============================================================
//   - Pgm reads by RRN for convenience. This is generally not a
//     good idea is a production program.
//  
//  -  DSPLY is use to simulate a display file interaction with
//     the user. Not normally done in production.
//  
//   - QIWS/QCUSTCDT: believed to be on virtually all systems.
//  ==============================================================

Ctl-Opt DEBUG(*YES) OPTION(*NODEBUGIO:*SRCSTMT:*NOUNREF);
Ctl-Opt DFTACTGRP(*NO) ACTGRP(*NEW);

Dcl-F QCUSTCDT Usage(*Update:*Delete:*Output) 
    USROPN EXTDESC('QIWS/QCUSTCDT') RECNO(RRN)
//        INFSR(*PSSR)
;

Dcl-PR RCDLCKDSP  EXTPGM('RCDLCKDSP');
  poReply        Char(1);
  piPSDS         Pointer;
 End-PR;
Dcl-PR QCmdexc  EXTPGM('QCMDEXC');
  Cmd            Char(512);
  lgth           Packed(15:5) CONST;
 End-PR;
Dcl-S RRN          Packed(10:0) INZ(10);
Dcl-S reply        Char(1)    INZ('*');
Dcl-S Cmd          Char(512);
Dcl-DS myPSDS  PSDS;
 End-DS;
Dcl-S myPSDS_ptr   Pointer    INZ(%ADDR(myPSDS));
*inlr = *on;
// Set update file to a short wait time. Otherwise the file or
// system default wait time applies.
Cmd = ' OVRDBF FILE(QCUSTCDT) TOFILE(QIWS/QCUSTCDT) WAITRCD(1)';
QCmdexc(Cmd:512);
open QCUSTCDT;
dou not %error;
     chain(e) RRN QCUSTCDT;
     if %error;
         RCDLCKDSP(reply: myPSDS_ptr);
         if reply = 'R';
             iter;
         endif;
         if reply = 'C';
             exsr Prog_Cancelled;
         endif;
         if reply = 'D';
             dump(a);
             exsr Prog_Cancelled;
         endif;
     endif;
enddo;
if %found(QCUSTCDT);
     // Logic to update the record would be here.
     dsply 'Read for update' ' ' reply;
else;
     // Logic for record not found would be here
     dsply 'Record not found' ' ' reply;
endif;
// === End of Program =========================================
// Close file before returning
close QCUSTCDT;
return;
begsr Prog_Cancelled;
     close QCUSTCDT;
     // Put graceful ending logic & notification to user here
     return;
endsr;

// Often found in old programs. Uncomment INFSR(*PSSR) in the
// F-SPEC to make this active.
BEGSR *PSSR;
     dsply 'In the *PSSR' ' ' reply;
     dump(a);
ENDSR '*CANCL';
