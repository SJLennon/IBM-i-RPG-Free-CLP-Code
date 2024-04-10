**free
//  ==============================================================
//   When an interactive program tries to update a record that is
//   locked by another user, often the program doesn't handle it.
//   The RPG error routines kick in and give the user a confusing
//   error message.
//  
//   Instead, trap the error and handle it by calling this program.
//  
//   This program communicates info about a locked record to an
//   interactive user telling who has the lock.

//   See program RCDLCKDEMO for a usage example.
//  
//   RCDLCKDSP accepts a continuation reply from the user and
//   passes it back to the caller.
//  
//   If the status is not 1218, then it is considered an
//   unexpected error and a slightly different dialog is
//   presented, asking the user to contact IT. You can
//   customize this as you see fit. Or add other statuses.
//  
//   Information is retrieved from the *PSDS passed from the caller.
//  
//  ==============================================================
//   Parameters
//   ==========
//   1  Output CL1 User's reply about what to do:
//                 R - Retry the IO operation that failed
//                 C - Cancel the program
//                 D - DUmp the program and cancel
//   2  Input   *  Pointer to the *PSDS in the calling program.
//                 (A pointer is used because the *PDSD is not
//                  always the same length in a program.)
//  ==============================================================
//   Create with CRTBNDRPG
//   New activation group so we destroy nothing in the caller.
//   No worries about overhead since rarely called.
       Ctl-Opt OPTION(*NODEBUGIO: *SRCSTMT);
       Ctl-Opt DFTACTGRP(*NO) ACTGRP(*NEW);
//  ==============================================================

Dcl-F rcdlckdspd WORKSTN;
Dcl-PR RCDLCKDSP;
  poReply        Char(1);
  piPSDS         Pointer;
 End-PR;
Dcl-PI RCDLCKDSP;
  poReply        Char(1);
  piPSDS         Pointer;
 End-PI;

//   === The caller's Program Status Data Structure ===============
//   Many fields not currently used.
Dcl-DS PSDS  QUALIFIED BASED(PIPSDS);
  PROC_NAME      Char(10)   Pos(1); //* Procedure name
  PGM_STATUS     Zoned(5:0) Pos(11); //* Status code
  PRV_STATUS     Zoned(5:0) Pos(16); //* Previous status
  LINE_NUM       Char(8)    Pos(21); //* Src list line num
  ROUTINE        Char(8)    Pos(29); //* Routine name
  PARMS          Char(3)    Pos(37); //* Num passed parms
  EXCP_TYPE      Char(3)    Pos(40); //* Exception type
  EXCP_NUM       Char(4)    Pos(43); //* Exception number
  PGM_LIB        Char(10)   Pos(81); //* Program library
  EXCP_DATA      Char(80)   Pos(91); //* Exception data
  EXCP_ID        Char(4)    Pos(171); //* Exception Id
  LAST_FILE_IO   Char(10)   Pos(175); //* Last file used
  DATE           Char(8)    Pos(191); //* Date (*DATE fmt)
  YEAR           Zoned(2:0) Pos(199); //* Year (*YEAR fmt)
  LAST_FILE      Char(8)    Pos(201); //* Last file used
  FILE_INFO_STATUS Zoned(5:0) Pos(209) ; //* Last file status
  FILE_INFO_OPCODE Char(6)    Pos(214); //* Last file opcode
  FILE_INFO_ROUTINE Char(8)    Pos(220) ; //* Last file RPG
  FILE_INFO_LIST_NUM Char(8)    Pos(228) ; //* Last file listing
  FILE_INFO_RECORD Int(20)    Pos(236) ; //* Last file record
  JOB_NAME       Char(10)   Pos(244); //* Job name
  USER           Char(10)   Pos(254); //* User name
  JOB_NUM        Zoned(6:0) Pos(264); //* Job number
  JOB_DATE       Zoned(6:0) Pos(270); //* Date (UDATE fmt)
  RUN_DATE       Zoned(6:0) Pos(276); //* Run date (UDATE)
  RUN_TIME       Zoned(6:0) Pos(282); //* Run time (UDATE)
  CRT_DATE       Char(6)    Pos(288); //* Create date
  CRT_TIME       Char(6)    Pos(294); //* Create time
  CPL_LEVEL      Char(4)    Pos(300); //* Compiler level
  SRC_FILE       Char(10)   Pos(304); //* Source file
  SRC_LIB        Char(10)   Pos(314); //* Source file lib
  SRC_MBR        Char(10)   Pos(324); //* Source file mbr
  PROC_PGM       Char(10)   Pos(334); //* Pgm Proc is in
  PROC_MOD       Char(10)   Pos(344); //* Mod Proc is in
  LINE_NUM_SRCID Int(5)     Pos(354); //* Src list source ID
  FILE_INFO_LIST_NUM_SRCID Int(5)     Pos(356) ; //* Last file listing
  CURR_USER      Char(10)   Pos(358) ; //* Current user
  EXTERNAL_RC    Int(10)    Pos(368) ; //* External return
  NUM_XML_ELEMS  Int(20)    Pos(372) ; //* Number of XML
 End-DS;
//  === My Variables ==============================================
Dcl-DS MyPSDS  PSDS;
         MyName         Char(10)   Pos(1); //* This program
        End-DS;

Dcl-C USER       'USER: ';
Dcl-S UserPrf      Char(10)   INZ(' ');
Dcl-S UserName     Char(40)   INZ(' ');
Dcl-S wkI          Int(10);
Dcl-S wkJ          Int(10);
Dcl-S myStatus     Zoned(4:0);
//Dcl-DS AAA  LIKEDS(PSDS);
// AAA = PSDS;  // Eases Debugging...
 SH_PGM = MyName;
 // Sometimes the Status is not numeric
 monitor;
     myStatus = PSDS.FILE_INFO_STATUS;
 on-error;
     myStatus = -0;
 ENDMON;
 // Display fields are prefixed with SC_.
 select;
 when myStatus = 1218; //Record locked
     SC_USER1 = 'Cannot continue until the user below completes';
     SC_USER2 = 'their transaction or exits their application.';
     exsr GetUserPrf;
     //exsr GetUserName;
     // Fill in user profile and user name
     select;
     when UserPrf = ' ' and UserName = ' ';
         SC_USER3 = USER + '*Unknown* -- Call IT Now.';
     when UserName = ' ';
          SC_USER3 = USER + UserPrf;
     other;
          SC_USER3 = USER + UserName;
     endsl;
     SC_INSTR = 'Enter R to Retry, C to Cancel';
 other;   //Unknown error
     SC_USER1 = 'An unexpected error has occurred.';
     SC_USER2 = 'Please contact IT now.';
     SC_INSTR = 'IT: D=Dump, C=Cancel; R=Retry';
 endsl;
 // We try to fill in this info for all conditions
 SC_IT_PGM = PSDS.PROC_NAME;
 SC_IT_STS = myStatus;
 SC_IT_FILE = PSDS.LAST_FILE;
 SC_IT_OPCD = PSDS.FILE_INFO_OPCODE;
 SC_IT_EM1 = %subst(PSDS.EXCP_DATA: 1: %len(SC_IT_EM1));
 SC_IT_EM2 = %subst(PSDS.EXCP_DATA: %len(SC_IT_EM1)+1);
 exfmt DSPWIN;
 poReply = 'R';  //Default to R
 if SC_RESP = 'C' or SC_RESP = 'R' or SC_RESP = 'D';
     poReply = SC_RESP;
 endif;
 *inlr = *on;
 return;
 begsr GetUserPrf;
 // Dig the user profile out of the error message (EXCP_DATA)
 // which looks like this:
 //  Record 3317 in use by job 018249/SLENNON/MISREMSAM
     UserPrf = ' ';
     wkI = %scan('/':PSDS.EXCP_DATA);
     if wkI <> 0;
         wkI = wkI +1;
         wkJ = %scan('/' :PSDS.EXCP_DATA: wkI);
         if wkJ <> 0;
              wkJ = wkJ - wkI;
             if wkI > 0;
                 UserPrf = %subst(PSDS.EXCP_DATA: wkI: wkJ);
             endif;
         endif;
     endif;
 endsr;
 begsr GetUserName;
 // If you have a way to connect a user name to a user
 // then set UserName here.
     UserName = ' ';
 endsr;
