      *==============================================================
      * Program that locks a record and then waits for input from
      * the operator.
      *
      * Call this program in two different sessions to see the effect.
      * Second program will typically get a error:
      *   'Unable to allocate a record in file' (RNX1218)
      * and the end user typically choses and unhelpful response.
      *==============================================================
      * Note: This is a poor technique because the record remains
      *       locked to all other users until the transaction is
      *       completed, which may be in a few seconds or after lunch.
      *       It is used here to demonstate the RCDLCKDSP processing.
      *
      *Note: Pgm reads by RRN for convenience. This is not a gopd
      *      idea is a production program.
      *
      *Note: DSPLY is use to simulate a display file interaction
      *      with the user.
      *
      *Note: QIWS/QCUSTCDT: believed to be on virtually all systems.
      *==============================================================

     H DEBUG(*YES) OPTION(*NODEBUGIO:*SRCSTMT:*NOUNREF)
     H DFTACTGRP(*NO) ACTGRP(*NEW)

     FQCUSTCDT  UF   E             DISK    USROPN EXTDESC('QIWS/QCUSTCDT')
     F                                     RECNO(RRN)
     F*                                    INFSR(*PSSR)

     D QCmdexc         PR                  EXTPGM('QCMDEXC')
     D  CMD                         512A
     D  lgth                         15P 5 const

     D RRN             s             10p 0 inz(10)
     D reply           S              1A   inz('*')
     D Cmd             S            512A

      /free
       *inlr = *on;

       // Set update file to a short wait time. Otherwise the file or
       // system default wait time applies.
       cmd = ' OVRDBF FILE(QCUSTCDT) TOFILE(QIWS/QCUSTCDT) WAITRCD(1)';
       QCMDEXC(cmd:512);
       open QCUSTCDT;

       chain RRN QCUSTCDT;

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

       // Often found in old programs. Uncomment INFSR(*PSSR) in the
       // F-SPEC to make this active.
       BEGSR *PSSR;
         dsply 'In the *PSSR' ' ' reply;
         dump(a);
       ENDSR '*CANCL';
