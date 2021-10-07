      /TITLE MNTCUSTR - Update/Display a Customer Master
       //==============================================================
       // A maintenance or display program for a Customer Master Recds
       //
       //
       // Parameters
       // ----------
       //  1 In  Z4  Customer Id to, or 0 to add a new code
       //  2 In  CL1 Function
       //            E - Edit passed record
       //            D - Display passed record
       //            A - Add a new record
       //
       //    If no parms passed, close the display file and return.
       //==============================================================
       // Program is essentially without indicators. (Indicators are
       // stil lneeded to control the display file, but all have names.)
       //
       // Naming Conventions
       // ==================
       // - Lower case is the default for opcodes.
       // - TitleCase is used for program variables, subroutines and procedure
       //     names, e.g. MaxOrderQty, BldFkeyText, etc.
       // - Temporary variables are prefixed with "wk", e.g., wkDate.  Such
       //     variables contain valid data for only a short time and are never
       //     carried across subroutines.
       // - UPPERCASE is used for external names, i.e., files, fields, formats
       //     and anything else not directly coded in the program.
       //
       // - In the display file, this screen field naming convention is used:
       //     Screen Header:   Fields begin with SH_
       //     Detail           Fields begin with SD_
       //     Screen footer:   Fields begin with SFT_
       //==============================================================
       // Compilation
       //    Use CRTSQLRPGI command.
       //    Note that /INCLUDEs expects to find code in DEMO library,
       //    not the default of QRPGLESRC. Change as needed.
       //=============================================================

     h DftActGrp(*NO) ActGrp(*CALLER) option(*nodebugio: *srcstmt)
     h BndDir('UTIL_BND')
     h main(Main)

       //=== Display File =============================================
     fmTNCUSTD  CF   E             WorkStn INFDS(dfInfDS)
     f                                     INDDS(dfIndDS)
     f                                     USROPN

     d Main            pr                  extpgm('MTNCUSTR')
     d pID                                 like(CUSTID)
     d pMaintain                      1a

       //=== Service Program Prototypes ===============================
      /include copy_mbrs,Srv_Msg_P
      /include copy_mbrs,Srv_Str_P

       //=== Named hexadecimal constants for function keys ============
      /include copy_mbrs,##AIDBYTES

       //=== Fields read by SQL ========================================
       // NOTE: Only the fields in the SQL statement are populated!
     d CUSTMAST      e ds                  extname(CUSTMAST)

       //=== SQL State Constants ======================================
     d SQLSuccess      c                   '00000'
     d SQLNoData       c                   '02000'
     d SQLNoMoreData   c                   '02000'
     d SQLDupRecd      c                   '23505'
     d SQLRowLocked    c                   '57033'

       //=== Display File Information Data Structure ==================
       //    Allows us to determine which function key was pressed
     d dfInfDS         DS
     d Key                   369    369

       //=== Display File Indicator Data Structure ====================
       // This is a "private" indicator area for the display file.
     d dfIndDS         ds            99

       //--- 01-20 are not automatically cleared after EXFMT ----------
     d Protect_SD_ALL         10     10n

       //--- 21-99 are automatically cleared after EXFMT --------------
     d dfIndClr               21     99
     d RI_SD_ACTIVE           40     40n
     d PC_SD_ACTIVE           41     41n
     d RI_SD_NAME             42     42n
     d PC_SD_NAME             43     43n
     d RI_SD_ADDR             44     44n
     d PC_SD_ADDR             45     45n
     d RI_SD_CITY             46     46n
     d PC_SD_CITY             47     47n
     d RI_SD_STATE            48     48n
     d PC_SD_STATE            49     49n
     d RI_SD_ZIP              50     50n
     d PC_SD_ZIP              51     51n
     d RI_SD_ACCTPH           52     52n
     d PC_SD_ACCTPH           53     53n
     d RI_SD_ACCTMGR          54     54n
     d PC_SD_ACCTMGR          55     55n
     d RI_SD_CORPPH           56     56n
     d PC_SD_CORPPH           57     57n
     d DSP_SD_STAMP           61     61n

       //=== Screen Header Text =======================================
     d H2TextE         s                   like(SH_FUNCT)
     d                                     inz('Change Customer')
     d H2TextA         s                   like(SH_FUNCT)
     d                                     inz('Add Customer')
     d H2TextD         s                   like(SH_FUNCT)
     d                                     inz('Displaying Customer')

       //=== Text for function keys ===================================
     d F3Text          c                   'F3=Exit'
     d F4Text          c                   'F4=Prompt+'
     d F5Text          c                   'F5=Refresh'
     d F12Text         c                   'F12=Cancel'

       //=== External Programs Prototypes =============================
     d PmtState        PR                  EXTPGM('PMTSTATER')
     d  TheState                           like(STATE)
     d
       //=== Global Switches ==========================================
     d SflMsgSnt       s               n
     d CowsComeHome    c                   const('0')
     d Function        s              1a
     d Displaying      c                   const('D')
     d Editing         c                   const('E')
     d Adding          c                   const('A')
     d NoErrors        s               n

       // === Global Fields ===========================================
     d Orig_CHGTIME    s               z

       //=== Work Fields ==============================================
     d wkInt           s             10i 0
     d wkMsgText       s            256a   varying

       // === Next available customer number ==========================
       // CUSTNEXT        ds                  dtaara(CUSTNEXT)
     d Cust_Next       s              4p 0 dtaara(CUSTNEXT)

       //=== Program Status Data Structure ============================
     d ProgStatus     sds
     d PgmName           *PROC
     d  CURR_USER            358    367                                         * Current user

     d MainProc        S             10a

       //==============================================================
       //==============================================================
       // === Program Starts Here =====================================
       //==============================================================

     p Main            b
     d Main            pi
     d pID                                       like(CUSTID)
     d pMaintain                      1a

      /FREE

       //=== Set SQL Options ===============================
       exec sql set option datfmt=*iso,
                           closqlcsr=*endmod,
                           commit = *NONE;

       //=== Initialization Logic ===================================
       exsr Init;

       //--- Establish window that other formats refer to ---
       write SH_HDR;

       //============================================================
       // === Main Program Loop =====================================
       //============================================================
       // Loops until logic decides to exit.
       dou CowsComeHome;

         select;
           // =======================================================
           // === Displaying an existing Customer ===================
           // =======================================================
           when  Function = Displaying;
             exsr ReadRecd;
             if SQLSTT = SQLNoData;
               SQLProblem('Calling error 1: Code passed in does not exist.');
             endif;
             exsr FillScreenFields;
             // All Fields protected
             exsr ProtectAll;
             exsr ScreenIO;
             exsr CloseDownPgm;
             return;

           // =======================================================
           // === Updating an existing Customer =====================
           // =======================================================
           when Function = Editing;
             exsr ReadRecd;
             if SQLSTT = SQLNoData;
               SQLProblem('Calling error 2: Code passed in does not exist.');
             endif;
             exsr FillScreenFields;

             // Write/read screen until all data is valid,
             // then re-display for confirmation to update.
             dou NoErrors;
               exsr ScreenIO;
               select;

                 when Key = F12;
                   exsr CloseDownPgm;
                   return;

                 when Key = F05;
                     exsr ReadRecd;
                     if SQLSTT = SQLNoData;
                         // Record vanished!
                     SflMsgSnt= SndSflMsg('DEM0599'); //Delete, redo search
                         clear CUSTMAST;
                     endif;
                     NoErrors = *off;

                 when Key = F04;
                     exsr F04Prompt;

                 when Key = Enter;
                   exsr EditUpdData;
                   if NoErrors;
                     // Re-display screen fields for confirmation
                     exsr ProtectAll;
                     exsr FillScreenFields;
                     SflMsgSnt = SndSflMsg('DEM0000'); // Enter to update ...
                     exsr ScreenIO;
                     select;
                       when Key = F12 or Key = F05;
                         // Loop again
                       when Key = Enter;
                         exsr UpdateRecd;
                         if NoErrors;
                           exsr CloseDownPgm; // Success! Exit program
                           return;
                         endif;
                       other;
                         SflMsgSnt = SndSflMsg('DEM0003'); // Key not active
                         NoErrors = *off;
                     endsl;
                   endif;
                   // Open up fields for correction of errors
                   exsr UnprotectAll;

                 other;
                   SflMsgSnt = SndSflMsg('DEM0003'); // Key not active
                   NoErrors = *off;                  // Stay in dou NoErrors
               endsl;
             enddo;

           // =======================================================
           // === Adding a new Customer =============================
           // =======================================================
           when  Function=Adding;
             clear  CUSTMAST;
             //Default status to active
             ACTIVE = 'Y';
             exsr FillScreenFields;

             dou NoErrors;
               // Write/read screen until all data is valid,
               // then re-display for confirmation to update.
               //All fields can be keyed
               exsr UnProtectAll;
               exsr ScreenIO;
               select;
                 when Key = F12;
                   exsr CloseDownPgm;
                   return;

                 when Key = F04;
                     exsr F04Prompt;

                 when Key = F05;
                     clear CUSTMAST;
                     ACTIVE = 'Y';
                     exsr FillScreenFields;

                 when Key = Enter;
                   exsr EditAddData;
                   if NoErrors;
                     // Re-display field for confirmation
                     exsr ProtectAll;
                     SflMsgSnt = SndSflMsg('DEM0009'); // Enter to add ...
                     exsr FillScreenFields;
                     exsr ScreenIo;
                     select;
                       when Key=F12;
                         exsr FillScreenFields;
                       when Key = Enter;
                         exsr AddRecd;
                         if NoErrors;
                           exsr CloseDownPgm;
                           return;
                         endif;
                       other;
                         SflMsgSnt = SndSflMsg('DEM0003'); // Key not active
                         NoErrors = *off;
                     endsl;
                   endif;
                 other;
                   SflMsgSnt = SndSflMsg('DEM0003'); // Key not active
               endsl;
             enddo;

           other;
           // =======================================================
           //=== Goofed - Should ever happen ========================
           // =======================================================
             dump(a);
             SflMsgSnt = SndSflMsg('DEM9999'); // Contact IT now ...
             return;
         endsl;

       enddo;
       exsr CloseDownPgm;     // Should never happen
       return;

       //============================================================
       //=== End of Main Program Loop ===============================
       //============================================================
       return;

       //=== ReadRecd ===============================================
       begsr ReadRecd;
       exec sql
        select
             CUSTID
            ,NAME
            ,ADDR
            ,CITY
            ,STATE
            ,ZIP
            ,CORPPHONE
            ,ACCTMGR
            ,ACCTPHONE
            ,ACTIVE
            ,CHGTIME
            ,CHGUSER
        into       :CUSTMAST
        from      CUSTMAST
        where      CUSTID = :pID
               ;
       if SQLSTT <> SQLSuccess and SQLSTT <> SQLNoData;
         SQLProblem('ReadRecd');
       endif;
       Orig_CHGTIME = CHGTIME;   // Save for update comparison
       endsr;

       //=== FillScreenFields =======================================
       begsr FillScreenFields;
           SD_CUSTID = CUSTID;
           SD_NAME = NAME;
           SD_ADDR = ADDR;
           SD_CITY = CITY;
           SD_STATE = STATE;
           SD_ZIP = ZIP;
           SD_ACTIVE = ACTIVE;
           SD_ACCTPH = ACCTPHONE;
           SD_ACCTMGR =ACCTMGR;
           SD_CORPPH = CORPPHONE;
           SD_CHGTIME = ' ';
           SD_CHGUSER = ' ';
           // Show Changed stamp info
           if CHGUSER <> '*SYSTEM*' and CHGUSER <> ' ';
               exec sql VALUES
                   varchar_format(:CHGTIME, 'YYYY-Mon-DD')
                   concat ' at ' concat
                   varchar_format(:CHGTIME,'HH24:MI:SS')
                   into :SD_CHGTIME;
               SD_CHGUSER = CHGUSER;
               DSP_SD_STAMP = *on;
           endif;
       endsr;

       //=== F04Prompt ==============================================
       // CF04 reads the screen data. We then prompt and replace
       // anything in the state field, then we redisplay and
       // re-edit the screen data.
       // Always sets NoError to *off to force re-edit
       begsr F04Prompt;
           select;
           //  --- Prompt for State Code
             when SD_PMT_FLD = 'SD_STATE';
               PmtState(STATE);
               SD_STATE = STATE;
               PC_SD_STATE = *ON;
             // --- Field not promptable
             other;
             //   Use F4 only in field followed by + sign
             SflMsgSnt= SndSflMsg('DEM0005');
           endsl;
           NoErrors = *off;        // DOU Loop again
       endsr;

       //=== EditUpdData ============================================
       // Edit the screen fields that can be changed on a update.
       // Give up when the first error found.
       // A valid screen field is moved to the database record.
       begsr EditUpdData;
       NoErrors = *on;

       // ACTIVE Status
       exsr Edit_SD_ACTIVE;
       if NoErrors = *off;
           leavesr;
       endif;
       // Name
       exsr Edit_SD_NAME;
       if NoErrors = *off;
           leavesr;
       endif;
       // Addr
       exsr Edit_SD_ADDR;
       if NoErrors = *off;
           leavesr;
       endif;
       // City
       exsr Edit_SD_CITY;
       if NoErrors = *off;
           leavesr;
       endif;
       // State
       exsr Edit_SD_STATE;
       if NoErrors = *off;
           leavesr;
       endif;
       // ZIP
       exsr Edit_SD_ZIP;
       if NoErrors = *off;
           leavesr;
       endif;
       // Account Phone
       exsr Edit_SD_ACCTPH;
       if NoErrors = *off;
           leavesr;
       endif;
       // Account Manager
       exsr Edit_SD_ACCTMGR;
       if NoErrors = *off;
           leavesr;
       endif;
       // Corporate Phone
       exsr Edit_SD_CORPPH;
       if NoErrors = *off;
           leavesr;
       endif;

       endsr;

       //=== EditAddData ============================================
       // Edit the screen fields needed to add a record.
       // Give up when the first error found.
       // A valid screen field is moved to the database record.
       begsr EditAddData;
           // For this program. same data for edit and add.
           exsr EditUpdData;
       endsr;

       //=== Edit_SD_ACTIVE==========================================
       begsr Edit_SD_ACTIVE;
           if SD_ACTIVE = 'Y' or SD_ACTIVE = 'N';
               ACTIVE = SD_ACTIVE;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0501': 'Active Status');
           NoErrors = *off;
           RI_SD_ACTIVE = *on;
           PC_SD_ACTIVE = *on;
       endsr;

       //=== Edit_SD_NAME ===========================================
       begsr Edit_SD_NAME;
           if SD_NAME <> ' ';
               NAME = SD_NAME;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0502': 'Name');
           NoErrors= *off;
           RI_SD_NAME = *ON;
           PC_SD_NAME = *ON;
       endsr;

       //=== Edit_SD_ADDR ===========================================
       begsr Edit_SD_ADDR;
           if SD_ADDR <> ' ';
               ADDR = SD_ADDR;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0502': 'Address');
           NoErrors= *off;
           RI_SD_ADDR = *ON;
           PC_SD_ADDR = *ON;
       endsr;

       //=== Edit_SD_CITY ===========================================
       begsr Edit_SD_CITY;
           if SD_CITY <> ' ';
               CITY = SD_CITY;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0502': 'City');
           NoErrors= *off;
           RI_SD_CITY = *ON;
           PC_SD_CITY = *ON;
       endsr;

       //=== Edit_SD_STATE ==========================================
       begsr Edit_SD_STATE;
           exec sql select STATE into :STATE
           from STATES
           where STATE = :SD_STATE;
           if SQLSTT = SQLSuccess;
               STATE = SD_STATE;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0503');
           NoErrors= *off;
           RI_SD_STATE= *ON;
           PC_SD_STATE = *ON;
       endsr;

       //=== Edit_SD_ZIP ============================================
       begsr Edit_SD_ZIP;
           if SD_ZIP <> ' ';
               ZIP = SD_ZIP;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0502': 'ZIP');
           NoErrors= *off;
           RI_SD_ZIP= *ON;
           PC_SD_ZIP = *ON;
       endsr;

       //=== Edit_SD_ACCTPH =========================================
       begsr Edit_SD_ACCTPH;
           if SD_ACCTPH <> ' ';
               ACCTPHONE = SD_ACCTPH;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0502': 'Account Manager Phone');
           NoErrors= *off;
           RI_SD_ACCTPH= *ON;
           PC_SD_ACCTPH = *ON;
       endsr;

       //=== Edit_SD_ACCTMGR =========================================
       begsr Edit_SD_ACCTMGR;
           if SD_ACCTMGR <> ' ';
               ACCTMGR = SD_ACCTMGR;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0502': 'Account Manager Name');
           NoErrors= *off;
           RI_SD_ACCTMGR= *ON;
           PC_SD_ACCTMGR = *ON;
       endsr;

       //=== Edit_SD_CORPPH =========================================
       begsr Edit_SD_CORPPH;
           if SD_CORPPH <> ' ';
               CORPPHONE = SD_CORPPH;
               leavesr;
           endif;
           SflMsgSnt = SndSflMsg('DEM0502': 'Corporate Phone');
           NoErrors= *off;
           RI_SD_CORPPH= *ON;
           PC_SD_CORPPH = *ON;
       endsr;

       //=== AddRecd ================================================
       // Insert a record into the file.
       // Returns:  NoErrors = *on if the add was successful.
       begsr AddRecd;
         NoErrors = *on;
         in *LOCK Cust_Next;
         Cust_Next += 1;
         Out Cust_Next;
         CUSTID= Cust_Next;
         CHGTIME = %timestamp();
         CHGUSER = CURR_USER;
         exec sql
         insert into custmast
           values(:CUSTMAST)
           ;
         // There is no good reason why insert should fail.
         if SQLSTT <> SQLSuccess;
           SQLProblem('Insert into CUSTMAST ...');
         endif;
       endsr;

       //=== UpdateRecd =============================================
       // Updates the record with the screen data.
         // The SQL WHERE checks the last time stamp and if different,
         // doesn't update because someone else updated the record.
         // (This isn't the only way to avoid pessimistic locking.)
         // SQLERRD(3) contains the actual number of records updated
         // when the update is successful.
       begsr UpdateRecd;
         NoErrors = *on;
         exec sql
         update CUSTMAST
         SET NAME = :SD_NAME,
             ADDR = :SD_ADDR,
             CITY = :SD_CITY,
             STATE = :SD_STATE,
             ZIP = :SD_ZIP,
             CORPPHONE = :SD_CORPPH,
             ACCTMGR = :SD_ACCTMGR,
             ACCTPHONE = :SD_ACCTPH,
             ACTIVE = :SD_ACTIVE,
             CHGTIME = CURRENT TIMESTAMP,
             CHGUSER = :CURR_USER
         where CUSTID = :CUSTID
            -- and compare timestamp
               and CHGTIME = :Orig_CHGTIME;
         select;
             when SQLSTT = SQLNOData;            // Update Failed
               SflMsgSnt = SndSflMsg('DEM1002'); // Record changed, review.
               NoErrors = *off;
               // Show the changed data
               exsr ReadRecd;
               exsr FillScreenFields;

             when SQLSTT =SQLRowLocked;          // Row locked
                 sflMsgSnt = SndSflMsg('DEM1001' : SQLERRMC);
                 NoErrors = *off;
             when SQLSTT = SQLSuccess;

             other;
               SQLProblem('Update CUSTMAST');
         endsl;
       endsr;

       //=== ClearScreenData ========================================
       begsr ClearScreenData;
         clear DETAILS;
       endsr;

       //=== ProtectAll =============================================
       begsr ProtectAll;
           Protect_SD_ALL = *on;
       endsr;

       //=== UnProtectAll ===========================================
       begsr UnProtectAll;
           Protect_SD_ALL = *off;
       endsr;

       //=== ScreenIO ===============================================
       // Writes and Reads the screen
       begsr ScreenIO;

         write SH_HDR;
         write SFT_FKEY;

         // Show any messages in the error subfile.
         if SflMsgSnt = *on;
           write MSGCTL;
         endif;

         exfmt Details;

         // Clear most display file indicators
         clear dfIndClr;

         // Clear any messages in the error subfile.
         if SflMsgSnt = *on;
           SflMsgSnt = ClrMsgPgmQ(MainProc);
           write MSGCTL;
         endif;

       endsr;

       //=== BldFKeyText ============================================
       // Build the Function key text for the bottom of the screen.
       begsr BldFkeyText;
         SFT_KEYS=' ';
         SFT_KEYS = CatB(SFT_KEYS : F4Text);
         SFT_KEYS = CatB(SFT_KEYS : F5Text);
         SFT_KEYS = CatB(SFT_KEYS : F12Text);
       endsr;

       //=== CloseDownPgm ===========================================
       // Things to do before we issue a return to the caller
       begsr CloseDownPgm;
       //  Closing the display file may cause any subfile display in
       //  the caller to blank out.
       endsr;

       //=== Init ===================================================
       // Every time initialization logic
       begsr Init;

       //--- Analyse parameters ---
       if %parms() = 0;     // Close down
          if %open(MTNCUSTD);
             close MTNCUSTD;
          endif;
          *inlr = *on;
          return;
       endif;

       select;
         when  %parms() = 1;
             function = displaying;
         when  %parms() >= 2;
             select;
               when  pMaintain = Adding;
                   Function = Adding;
                   SH_FUNCT = CenterStr(H2TextA);
               when pMaintain = Editing;
                   Function = Editing;
                   SH_FUNCT = CenterStr(H2TextE);
               other;
                   Function = Displaying;
                   SH_FUNCT = CenterStr(H2TextD);
           endsl;
         other;
             // Should never happen
       endsl;

       //--- Miscellaneous setup ---
       MainProc = %proc();
       MSGPGMQ = MainProc;
       SH_PGM = PgmName;
       clear CUSTMAST;
       clear dfIndDS;
       exsr BldFkeyText;

       //--- Open display file ---
       if not %open(MTNCUSTD);
         open MTNCUSTD;
       endif;
       endsr;
      /END-FREE
     p Main            e

       //============================================================
       //   S u b  P r o c e d u r e s
       //============================================================

       //=== CatB ===================================================
       // Concatenates a string to another string with a blank between.
       // If the target string is all blank to start with it will not
       // end up with a leading blank.
     pcatB             b
     dcatB             PI            79    varying
     d ToStr                         79    varying value
     d AddStr                        79    varying value
      /FREE
       if ToStr=' ';
         return AddStr;
       else;
         return %trimr(ToStr) + ' ' + AddStr;
       endif;
      /END-FREE
     pcatB             e
     p
       //=== SQLProblem ===============================================
       // For those "Never should happen" SQL errors.
       // Issues DUMP(A) to dump memory, then ends program by
       // sending an *ESCAPE message of the supplied debugging text.
     p SQLProblem      B
     d SQLProblem      PI
     d piSQLDebug                  1024    varying value

       //--- Local Variables ------------------------------------------
     d wkSQLDebug      s           1024    varying

      /free
       wkSQLDebug = 'SQLSTT ' + SQLSTT
                    + ' << Unexpected SQL Return Code: '
                    + piSQLDebug;
       dump(a);
       SndEscMsg(wkSqlDebug);
       return;
      /end-free
     p SQLProblem      E

       //--------------------------------------------------------------
       // Procedure name: SndSflMsg
       // Purpose:        Send a message to the Error Subfile
       // Returns:        *ON
       // Parameter:      ErrMsgId => Msg Id to Send
       // Parameter:      ErrMsgData => Optional Error Message Data
       // Parameter:      ErrMsgFile => Optional Error Message File
       //                 Defaults to CUSTMSGF
       //--------------------------------------------------------------
     p SndSflMsg       B
     d SndSflMsg       PI              N
     d  ErrMsgId                      7A   CONST
     d  ErrMsgData                   80A   CONST
     d                                     OPTIONS(*NOPASS:*VARSIZE)
     d  ErrMsgFile                   10A   CONST
     d                                     OPTIONS(*NOPASS)
       // Local fields
     d retField        S               N
     d wkMsgId         s              7a
     d wkMsgFile       s             10a
     d wkMsgData       s             80a   varying

      /FREE
       if %parms >2;
         wkMsgFile = ErrMsgFile;
       else;
         wkMsgFile = 'CUSTMSGF';
       ENDIF;
       if %parms > 1;
         wkMsgData = ErrMsgData;
       else;
         wkMsgData = ' ';
       ENDIF;
       wkMsgId = ErrMsgId;
       SNDMSGPGMQ(MainProc:
             wkMsgid:
             wkMsgFile:
             wkMsgData);

        retField = *on;
        RETURN retField;

      /END-FREE
     p SndSflMsg       E

