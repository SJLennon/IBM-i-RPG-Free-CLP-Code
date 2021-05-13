      *==============================================================
      * When an interactive program tries to update a record that is
      * locked by another user, often the program doesn't handle it.
      * The RPG error routines kick in and give the user a confusing
      * error message.
      *
      * Instead, trap the error and handle it by calling this program.
      *
      * This program communicates info about a locked record to an
      * interactive user telling who has the lock.

      * See program RCDLCKDEMO for a usage example.
      *
      * RCDLCKDSP accepts a continuation reply from the user and
      * passes it back to the caller.
      *
      * If the status is not 1218, then it is considered an
      * unexpected error and a slightly different dialog is
      * presented, asking the user to contact IT. You can
      * customize this as you see fit. Or add other statuses.
      *
      * Information is retrieved from the *PSDS passed from the caller.
      *
      *==============================================================
      * Parameters
      * ==========
      * 1  Output CL1 User's reply about what to do:
      *               R - Retry the IO operation that failed
      *               C - Cancel the program
      *               D - DUmp the program and cancel
      * 2  Input   *  Pointer to the *PSDS in the calling program.
      *               (A pointer is used because the *PDSD is not
      *                always the same length in a program.)
      *==============================================================
      * Create with CRTBNDRPG
      * New activation group so we destroy nothing in the caller.
      * No worries about overhead since rarely called.
     h  OPTION(*NODEBUGIO: *SRCSTMT)
     H  DFTACTGRP(*NO) ACTGRP(*NEW)
      *==============================================================

     FrcdlckdspdCF   E             WORKSTN

     d RCDLCKDSP       pr
     D  poReply                       1A
     D  piPSDS                         *

     d RCDLCKDSP       pi
     D  poReply                       1A
     D  piPSDS                         *

      * === The caller's Program Status Data Structure ===============
      * Many fields not currently used.
     D PSDS            DS                  qualified based(piPSDS)
     D  PROC_NAME              1     10                                         * Procedure name
     D  PGM_STATUS            11     15s 0                                      * Status code
     D  PRV_STATUS            16     20S 0                                      * Previous status
     D  LINE_NUM              21     28                                         * Src list line num
     D  ROUTINE               29     36                                         * Routine name
     D  PARMS                 37     39                                         * Num passed parms
     D  EXCP_TYPE             40     42                                         * Exception type
     D  EXCP_NUM              43     46                                         * Exception number
     D  PGM_LIB               81     90                                         * Program library
     D  EXCP_DATA             91    170                                         * Exception data
     D  EXCP_ID              171    174                                         * Exception Id
     D  LAST_FILE_IO         175    184                                         * Last file used
     D  DATE                 191    198                                         * Date (*DATE fmt)
     D  YEAR                 199    200S 0                                      * Year (*YEAR fmt)
     D  LAST_FILE            201    208                                         * Last file used
     D  FILE_INFO_STATUS...
     D                       209    213S 0                                      * Last file status
     D                                                                          *   Code
     D  FILE_INFO_OPCODE...
     D                       214    219                                         * Last file opcode
     D  FILE_INFO_ROUTINE...
     D                       220    227                                         * Last file RPG
     D                                                                          *   routine
     D  FILE_INFO_LIST_NUM...
     D                       228    235                                         * Last file listing
     D                                                                          *   line
     D  FILE_INFO_RECORD...
     D                       236    243I 0                                      * Last file record
     D                                                                          *   name
     D  JOB_NAME             244    253                                         * Job name
     D  USER                 254    263                                         * User name
     D  JOB_NUM              264    269S 0                                      * Job number
     D  JOB_DATE             270    275S 0                                      * Date (UDATE fmt)
     D  RUN_DATE             276    281S 0                                      * Run date (UDATE)
     D  RUN_TIME             282    287S 0                                      * Run time (UDATE)
     D  CRT_DATE             288    293                                         * Create date
     D  CRT_TIME             294    299                                         * Create time
     D  CPL_LEVEL            300    303                                         * Compiler level
     D  SRC_FILE             304    313                                         * Source file
     D  SRC_LIB              314    323                                         * Source file lib
     D  SRC_MBR              324    333                                         * Source file mbr
     D  PROC_PGM             334    343                                         * Pgm Proc is in
     D  PROC_MOD             344    353                                         * Mod Proc is in
     D  LINE_NUM_SRCID...
     D                       354    355I 0                                      * Src list source ID
     D  FILE_INFO_LIST_NUM_SRCID...
     D                       356    357I 0                                      * Last file listing
     D                                                                          *   source ID
     D  CURR_USER            358    367                                         * Current user
     D                                                                          *   profile
     D  EXTERNAL_RC          368    371I 0                                      * External return
     D                                                                          *   code
     D  NUM_XML_ELEMS        372    379I 0                                      * Number of XML
     d                                                                          *   elements
      *=== My Variables ==============================================
     D MyPSDS         sDS
     D  MyName                 1     10                                         * This program

     D User            c                   'User: '
     D UserPrf         S             10A   inz(' ')
     D UserName        S             40A   inz(' ')

     D wkI             s             10I 0
     D wkJ             s             10I 0

     d myStatus        s              4S 0
     D*AAA             DS                  likeds(PSDS)
      /FREE
        // AAA = PSDS;  // Eases Debugging...

        SH_PGM = MyName;

        // Sometimes the Status is not numeric
        monitor;
            myStatus = psds.FILE_INFO_STATUS;
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
                SC_USER3 = User + '*Unknown* -- Call IT Now.';
            when UserName = ' ';
                 SC_USER3 = User + UserPrf;
            other;
                 SC_USER3 = User + UserName;
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

        exfmt dspwin;

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
                if WkJ <> 0;
                     wkJ = WkJ - wkI;
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
      /END-FREE
