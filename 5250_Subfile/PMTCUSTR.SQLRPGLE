      /TITLE Demo Expanding Subfile Search using SQL for IO
       //=============================================================
       // This is an customer master prompt/search program.
       // It can be called to return a selected customer number or
       // just to provide general inquiry functionality from a menu.
       //
       // Detailed Item information is displayed in a window by
       // call another program, MTNCUSTR.
       //
       // Parameters:
       // -----------
       // 1  Char 1  Type of parameter
       //            S - Return Selected Customer Id: 1=Select
       //            M - Allow maintenance: 2=Edit, F6=Add
       //            I - Inquiry, read only: 5=Display
       // 2  Char 4  Selected customer id if parm 1 is S.
       //
       //=============================================================
       // Program uses a full screen expanding subfile to select
       // a Customer Master record.
       //
       // The screen layout is similar to PDM.
       //
       // Instead of using native IO it uses SQL to retrieve records.
       //
       // It is essentially without indicators.  (Indicators are still
       // needed to control the display file, but they all have names.)
       //
       // It is possible to use F4 to prompt for the State abbreviation
       // when the cursor is in the ST field.
       //
       // F09 is a toggle to display or not display inactive Customers.
       //
       //=============================================================
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

       // - In the display file, this field naming convention is used:
       //     Screen Header:   Fields begin with SH_
       //     Subfile:         Fields begin with SF_
       //     Subfile Control: Fields begin with SC_
       //     Screen footer:   Fields begin with SFT_
       //=============================================================
       // Compilation
       //    Use CRTSQLRPGI command.
       //    Note that /INCLUDEs expects to find code in DEMO library,
       //    not the default of QRPGLESRC. Change as needed.
       //=============================================================

     h DftActGrp(*NO) ActGrp(*CALLER) option(*nodebugio: *srcstmt)
     h BndDir('UTIL_BND')

       //=== Display File ============================================
     fPMTCUSTD  CF   E             WorkStn INFDS(dfInfDS)
     f                                     INDDS(dfIndDS)
     f                                     SFILE(SFL:SflRRN)
     f                                     USROPN
       // File is closed when returning with LR off. This avoids an
       // annoying resdisplay of the last subfile on re-entry.

       //=== Service Program Prototypes ==============================
      /include copy_mbrs,Srv_Msg_P
      /include copy_mbrs,Srv_Str_P

       //=== Named hexadecimal constants for function keys ===========
      /include copy_mbrs,##AIDBYTES

       //=== Display File Information Data Structure =================
       //    Allows us to determine which function key was pressed
     d dfInfDS         DS
     d Key                   369    369
       //=== Display File Indicator Data Structure ===================
       // This is a "private" indicator area for the display file.
     d dfIndDS         ds            99

       //--- 01-20 are not automatically cleared after EXFMT ----------
     d scIncActInc            03     03n

       //--- 21-99 automatically cleared after EXFMT ------------------
     d dfIndClr               21     99

       //--- Subfile indicators (prefix "sf") ---
     d SC_NAME_PC             79     79n
     d sfSflNxtChg            80     80n
     d sfOPT_RI               81     81n
     d sfOPT_PC               82     82n
     d sfInAct                83     83n

       //--- Subfile Control indicators (prefix "sc") ---
     d*scNoDta                96     96n
     d scSflEnd               97     97n
     d scSflDsp               98     98n
     d scSflClr               99     99n

       //=== Fields to control the subfile screen ====================
     d  SflRRN         s              5  0
     d  RcdsInSfl      s              5  0
     d  SflPageSize    c                   12
       // SC_CSR_RCD is defined in the display file and is set with a
       // RRN which determines which subfile page is displayed and on
       // which record the cursor is positioned.

       //=== Text for function keys ==================================
     d F3Text          c                   'F3=Exit'
     d F4Text          c                   'F4=Prompt+'
     d F5Text          c                   'F5=Reset'
     d F6Text          c                   'F6=Add'
     d F12Text         c                   'F12=Cancel'
     d F9Text          s             25

       //=== Options Text ============================================
     d Opt1Text        c                   '1=Select'
     d Opt2Text        c                   '2=Edit'
     d Opt5Text        c                   '5=Display'

       //=== Screen Header Text=======================================
     d HdrInq          s                   like(SH_FUNCT)
     d                                     inz('Inquiry')
     d HdrSelect       s                   like(SH_FUNCT)
     d                                     inz('Selection')
     d HdrMaint        s                   like(SH_FUNCT)
     d                                     inz('Maintenance')
     d HdrBad          s                   like(SH_FUNCT)
     d                                     inz('-> Bad Parm 1 <-')
     d

       //=== Search Criteria Screen Fields ===========================
     d SearchCriteria  ds                  inz
     d SC_NAME
     d SC_CITY
     d SC_STATE

       //=== Last Search Criteria Fields =============================
     d LastSearchCriteria...
     d                 ds                  inz
     d LastSC_NAME                         Like(SC_NAME)
     d LastSC_CITY                         Like(SC_CITY)
     d LastSC_STATE                        Like(SC_STATE)

       //=== SQL Search Variables ====================================
     d Stmt            s           1024    varying                              Select Statement

       //=== SQL State Constants =====================================
     d SQLSuccess      c                   '00000'
     d SQLNoData       c                   '02000'
     d SQLNoMoreData   c                   '02000'
     d SQLDupRecd      c                   '23505'
     d SQLRowLocked    c                   '57033'

       //== CUSTMAST - define fields for SQL =========================
       // NOTE: Only the fields read by SQL are populated!
     d CustMast      e ds                  extname(CUSTMAST) template

       // Records from SQL CURSOR read into CustCursor
     d CustCursor      ds                  likeds(Custmast)

       // Records from SQL SELECT read into CustSelect
     d CustSelect      ds                  likeds(CustMast)

       //=== External Programs Prototypes ============================

     d CustDsp         pr                  extpgm('MTNCUSTR')
     d CustID                              options(*nopass) like(CUSTID)
     d Maintain                       1a   options(*nopass)

     d PmtState        PR                  EXTPGM('PMTSTATER')
     d  TheState                           like(STATE)
     d

       //=== Global Switches =========================================
     d EofData         s               n
     d CursorOpen      s               n
     d NewSearchCriteria...
     d                 s               n
     d SflMsgSnt       s               n
     d Opt1_OK         s               n
     d OptError        s               n
     d Maint_OK        s               n
     d CowsComeHome    c                   const('0')
     d MaxSflRecds     c                   const(9999)

       //=== Work Fields =============================================
     d inx             s             10i 0

       // Would prefer to defind these as  like(SC_NAME)
       // But SQL precompiler throws an error SQL0312, reason code 1
     d wkName          s             13a   varying
     d wkCity          s             13a   varying

       //=== Parm fields for MTNCUSTR ================================
     d wkCustid        s                   like(CUSTID)
     d CustDspParm     s              1a
     d CustDspEdit     c                   const('E')
     d CustDspAdd      c                   const('A')
     d CustDspDsply    c                   const('D')
     d

       //=== Program Status Data Structure ===========================
     d ProgStatus     sds
     d PgmName           *PROC

       //=== Program Parameters ======================================
     d pParmType       S              1A
     d pCustID         s                   Like(CUSTID)

       //=============================================================
       // === Program Starts Here ====================================
       //=============================================================
     c     *Entry        plist
     c                   parm                    pParmType
     c                   parm                    pCustID

      /FREE
       //=== Set SQL Options =========================================
       exec sql set option datfmt=*iso,
                           closqlcsr=*endmod;

       // === Set up for the first screen IO =========================
       exsr Init;
       exsr BldFkeyText;
       SflClear();

       // Force evalualtion if enter pressed with no data
       NewSearchCriteria = *on;

       // If we are to return a customer number, Clear the return field
       // in case nothing is selected
       if  Opt1_OK = *on;
         clear pCustID;
       endif;

       // If just doing inquiry, load first subfile page
       if %parms() > 0;
         if pParmType = 'I' ;
           exsr SflFirstPage;
         endif;
       endif;

       //=============================================================
       // === Main Program Loop ======================================
       //=============================================================
       dou CowsComeHome;

         // Set "*More" display
         scSflEnd = EofData;

         // Write/Read the sreen
         exsr ScreenIO;

         //-- Enter Key ---------------------------------------------
         If Key = Enter;
           // Either new Search Criteria entered or option(s) entered.
           // New Search Criteria takes precedence over option(s).
           if SearchCriteria <> LastSearchCriteria
             or NewSearchCriteria = *on;
             SflClear();
             exsr SflFirstPage;
           else;
             exsr ProcessOption;
           endif;
           iter;
         endif;

         //--- Page Down --------------------------------------------
         if Key = PageDown;
           if RcdsInSfl > 0;
             exsr SflFillPage;
                 if SflRRN = MaxSflRecds;
                    SflMsgSnt= SndSflMsg('DEM0006');
                    iter;
                 endif;
           else;
             // Key not active msg
             SflMsgSnt= SndSflMsg('DEM0003');
           endif;
           iter;
         endif;

         //--- Any other entry must be a function key ---------------
         exsr ProcessFunctionKey;

       enddo;

       //=============================================================
       //=== End of Main Program Loop ================================
       //=============================================================

       //=== ScreenIO ================================================
       // Writes and Reads the screen
       begsr ScreenIO;

         write SH_HDR;
         write SFT_FKEY;

         // Show any messages in the error subfile.
         if SflMsgSnt = *on;
           write MSGCTL;
         endif;

         // If we have records in the subfile, display them.
         if RcdsInSfl > 0;
           scSflDsp = *ON;
         else;
           scSflDsp = *OFF;
         ENDIF;

         // Write/read the subfile.  SC_CSR_RCD contains a RRN and
         // determines which page will be on the screen and where the
         // cursor will be.
         exfmt SFLCTL;

         // Clear most display file indicators
         clear dfIndClr;

         // Clear any messages in the error subfile.
         if SflMsgSnt = *on;
           SflMsgSnt = ClrMsgPgmQ(PgmName);
           write MSGCTL;
         endif;

       endsr;

       //=== ProcessFunctionKey ======================================
       // Process whatever keyboard entry was made.
       //   Will not return from subroutine if F3 or F12 was pressed.
       //   May not return from subroutine when an option is entered.

       begsr ProcessFunctionKey;

         select;

           //--- F3: Exit, close down program -----------------------
         when Key = F03;
           exsr CloseDownPgm;
           *inlr = *on;
           return;

           //--- F12: Return to caller, leave program active ---------
         when Key = F12;
           exsr CloseDownPgm;
           return;

           //--- F4: Prompt to fill the field -----------------------
         when Key = F04;
           //           The result of a successful F4 is as if the field
           //           had been keyed from the screen.
           select;
             //  --- Prompt for State Code
             when SC_PMT_FLD = 'SC_STATE';
               PmtState(SC_STATE);
               if SC_STATE <> LastSC_STATE;
                 SflClear();
                 NewSearchCriteria = *on;
               endif;
             // --- Field not promptable
             other;
             //   Use F4 only in field followed by + sign
             SflMsgSnt= SndSflMsg('DEM0005');
           endsl;

           //--- F5: Refresh all search fields ----------------------
         when Key = F05;
           clear LastSearchCriteria;
           clear SearchCriteria;
           SflClear();
           NewSearchCriteria = *on;
           scIncActInc = *off;

           //--- F6: Add a record. ----------------------------------
         when Key = F06;
             if Maint_Ok = *on;
                 CustDspParm = CustDspAdd;
                   CustDsp(wkCustId : CustDspParm);
             else;
                 // Function key not active
                 SflMsgSnt= SndSflMsg('DEM0003');
             endif;

           //--- F9: Toggle Include InActive ------------------------
         when Key = F09;
           CloseCursor();
           scIncActInc = not scIncActInc;
           exsr BldFkeyText;
           SflClear();
           NewSearchCriteria = *on;
           exsr SflFirstPage;

           //--- Other keys: Function key not active message ---------
         other;
           SflMsgSnt= SndSflMsg('DEM0003');
         endsl;

       endsr;

       //=== ProcessOption ===========================================
       // Did user enter one or more options?  Loop through the
       //     subfile and process them all.
       // May not return from this subroutine for some options.

       begsr ProcessOption;
         if RcdsInSfl > 0;
           OptError = *off;

           // Don't know yet which sfl page to display next time.
           SC_CSR_RCD = 0;

           // Loop through changed records in the subfile.
           readc SFL;
           dow not %eof;
             select;
               //--- 1 = Select -------------------------------------
               when SF_OPT = '1'
                     and  Opt1_OK = *on;
                 // Return customer number to caller
                 pCustID = %dec(SF_CUST_H:4:0);
                 exsr CloseDownPgm;
                 return;
               //--- 2 = Edit with external program -----------------
               when SF_OPT = '2' and Maint_OK = *on;
                   wkCustId = %dec(SF_CUST_H:4:0);
                   CustDspParm = CustDspEdit;
                   CustDsp(wkCustId : CustDspParm);
                   // Reset Opt and leave cursor at last valid option
                   SF_OPT = ' ';
                   exsr SetCursorPosition;
                   // Re-read the changed record & update subfile
                   ReadByKey(wkCustid : CustSelect);
                   BuildSflRecd(CustSelect);
                   exsr UpdSflRecd;

               //--- 5 = Display Detail with external program -------
               when SF_OPT = '5';
                   wkCustId = %dec(SF_CUST_H:4:0);
                   CustDspParm = CustDspDsply;
                   CustDsp(wkCustId : CustDspParm);
                   // Reset Opt and leave cursor at last valid option
                   SF_OPT = ' ';
                   exsr SetCursorPosition;
                   exsr UpdSflRecd;

               //--- Opt is blank -----------------------------------
               when SF_OPT = ' ';
                 // If changed, assume clearing an error from last time
                 sfOPT_PC = *off;
                 sfOPT_RI = *off;
                 exsr UpdSflRecd;

               //--- Other ------------------------------------------
               other;
                 // Send message about invalid selection.
                 // Position cursor and page at first error.
                 // Always force to be read again next time & reverse image.

                 // Not a valid option at this time
                 SflMsgSnt= SndSflMsg('DEM0004':SF_OPT);
                 // Leave cursor at first invalid option
                 exsr SetCursorPosition;
                 optError = *on;

                 // SFLNXTCHG forces this record to be read again
                 // (even if user doesn't correct it) so we can
                 // check it again for validity.
                 sfSflNxtChg = *on;
                 sfOPT_RI = *on;

                 exsr UpdSflRecd;
                 // set off indicators applying to just this recd.
                 sfSflNxtChg = *off;
                 sfOPT_RI = *off;

             endsl;

             readc SFL;
           enddo;
           CustDsp();    // Closes Window DSPF & restores our subfile
         endif;

         // If no positioning done, display last page, cursor on 1st recd.
         // (Enter with no option takes you to the last page of subfile.)
         if SC_CSR_RCD = 0;
           SC_CSR_RCD =
               ( %int( (RcdsInSfl-1) / SflPageSize )
               * SflPageSize
               ) + 1;
         endif;

       endsr;

       //=== SflFirstPage ============================================
       // Processes the Search fields in the Sub file control, then
       // fills the first page of the subfile.
       // If any errors in the search  fields then no records are
       // are added to the subfile.

       // Returns:
       //   EofData = *on  if there are no more data records
       //             *off if there is at least one more data
       //                  record.
       //   NewSearchCriteria = *on  Next time evaluate the
       //                  search fields again.
       //   RcdsInSfl  contains relative record number of last record
       //              written to the subfile.

       begsr SflFirstPage;
         exsr ProcessSearchCriteria;
         if NewSearchCriteria = *off;
           EofData = FetchNextData(CustCursor);
           if EofData = *off;
             exsr SflFillPage;
           else;
             // No records match selection criteria
             SflMsgSnt= SndSflMsg('DEM0002');
             NewSearchCriteria = *on;
           endif;

         endif;
       endsr;

       //=== SflFillPage =============================================
       // Adds a page worth of records to the subfile.

       // Assumes:
       //   One record is already read from the SQL cursor.

       // Returns:
       //   EofData = *on  if no more data records.
       //             *off if at least one data record is read
       //                  and has not been displayed.
       //   RcdsInSfl contains relative record number of last record
       //             written to the subfile.
       //   SC_CSR_RCD contains relative record number of 1st record
       //             on the page & positions cursor there.

       begsr SflFillPage;
         select;

         when EofData = *on;
           // do nothing
         other;
           // Add a subfile page.  If not EOF, then one extra recd is
           // read for the next time.
           // Position cursor at first record on the subfile page.
           SC_CSR_RCD = 0;
           for inx = 1 to SflPageSize;
             // Build/Format the subfile record
             clear SF_OPT;
             BuildSflRecd(CustCursor);

             RcdsinSfl = RcdsInSfl + 1;
             SflRRN = RcdsInSfl;
             write SFL;

             // Leave curson on first SFL record
             if SC_CSR_RCD = 0;
               SC_CSR_RCD = SflRRN;
             endif;

             // Can't display more than 9,999 records.
             if SflRRN = MaxSflRecds;
               EofData = *on;
               SflMsgSnt= SndSflMsg('DEM0006');
               leave;
             endif;

             EofData = FetchNextData(CustCursor);
             if EofData = *on;
               leave;
             endIf;

           endfor;

         endsl;

       endsr;


       //=== Update Subfile Recd =====================================
       begsr UpdSflRecd;
           // Set on indicator based on saved SFL fields
           if SF_ACT_H = 'N';
              sfInAct = *on;
           endif;
           update SFL;
           sfInAct = *off;
           write DUMMY; // Supposed to help restore SFL display
       endsr;

       //=== ProcessSearchCriteria ===================================
       // Examine the data entered in the search fields and build an
       // SQL statement. Note that NAME and CITY search use a LIKE
       // predicate with a % on the end to match any string.
       // You can also use _ to match any single character. For example,
       // NEC_C would find NEC CORP but not NEC FOUNDATION.
       // Putting % at the beginning will also work, for example,
       // %LLC will find all Customers with LLC in their name,
       // but likely will be quite slow depending on file size..

       // Success:
       //    NewSearchCriteria is set off
       //    SQL Cursor is open
       //
       // Failure:
       //    NewSearchCriteria is left on
       //    Error message is sent to the msg sufile
       //    Cursor is postioned at the field in error

       begsr ProcessSearchCriteria;
         // Reset switches
         NewSearchCriteria = *off;
         // Save entered values.  (Never change screen fields.)
         LastSearchCriteria = SearchCriteria;
         //exsr SaveSearchCriteria;
         CloseCursor();
         // Build select statement
         //    Using parameter markers protects against
         //    SQL injection attacks.
         clear wkNAME;
         clear wkCity;
         Stmt = 'select NAME +
                       ,CITY +
                       ,STATE +
                       ,ZIP +
                       ,ACTIVE +
                       ,CUSTID +
                from    CUSTMAST +
                where   NAME LIKE ? +
                   and  CITY like ? ';
         wkName =  %trim(SC_NAME) + '%';
         wkCity = %trim(SC_CITY) + '%';

         if SC_STATE <> ' ';
             if %len(%trim(SC_STATE)) <> 2;
                 NewSearchCriteria=*on;
                 SflMsgSnt = ClrMsgPgmQ(PgmName);
                 SflMsgSnt= SndSflMsg('DEM0007');
             endif;
             Stmt += ' and STATE =' + Quote(SC_STATE);
         endif;

         If scIncActInc = *off;
             Stmt += ' and ACTIVE = ' + quote('Y');
         endif;

         stmt += ' order by NAME, CITY';
         Stmt += ' optimize for 13 rows';
         Stmt += ' for fetch only';
       //  SndInfMsg(Stmt);     // Testing...

         //----------------------------------------------------------
         // If stmt bulit without errors open the SQL cursor
         if NewSearchCriteria = *off;
           exec sql prepare mySelect from :Stmt;
           if SQLSTT <> SQLSuccess;
               SQLProblem('Prepare mySelect');
           endif;
           exec sql declare ItemCur cursor for mySelect;
           exec sql open ItemCur using :wkName,:wkCity ;
           if SQLSTT  <> SQLSuccess;
             SQLProblem('Open ItemCur');
           endif;
           CursorOpen = *on;
         endif;
       endsr;

       //=== SetCursorPostion ========================================
       // If Invalid Option, position screen cursor on first one,
       // else postion cursor on the last valid option.
       begsr SetCursorPosition;
         if OptError = *off;
           SC_CSR_RCD=SflRRN;
         endif;
       endsr;

       //=== BldFKeyText =============================================
       // Build the Function key text for the bottom of the screen.
       begsr BldFkeyText;
         SFT_KEYS=' ';
         SFT_KEYS = CatB(SFT_KEYS : F3Text);
         SFT_KEYS = CatB(SFT_KEYS : F4Text);
         SFT_KEYS = CatB(SFT_KEYS : F5Text);
         if pParmType = 'M';
             SFT_KEYS = CatB(SFT_KEYS : F6Text);
             Maint_OK = *on;
         endif;
         if scIncActInc = *on;
             F9Text = 'F9=Exclude Inactive';
         else;
             F9Text = 'F9=Include Inactive';
         endif;
         SFT_KEYS = CatB(SFT_KEYS : F9Text);
         SFT_KEYS = CatB(SFT_KEYS : F12Text);
       endsr;

       //=== CloseDownPgm ============================================
       // Things to do before we issue a return to the caller
       begsr CloseDownPgm;
           CloseCursor();
           close PMTCUSTD;
           CustDsp();        // Close Window display file.
       endsr;

       //=== Init ====================================================
       // Must be executed each time program is entered, because F12
       // and Enter key leave with LR off.
       begsr Init;
         MSGPGMQ = PgmName;
         SH_PGM = PgmName;
         SH_FUNCT = CenterStr(HdrBad);
         if not %open(PMTCUSTD);
           open PMTCUSTD;
         endif;
         // Clear fields left over from previous F12.
         reset LastSearchCriteria;
         reset SearchCriteria;
         scIncActInc = *off;
         Maint_OK = *off;

         // Put cursor in first field if inquiry
         if pParmType = 'I';
             SC_NAME_PC = *ON;
             SH_FUNCT = CenterStr(HdrInq);
         endif;

         // Build options string.
         // If we have a field to return customer number and we
         // are doing selection, set 1=Select option.
         clear SC_OPTIONS;

         Opt1_OK = *off;
         If pParmType = 'S' and %parms > 1;
               SC_OPTIONS = Opt1Text;
               Opt1_OK = *on;
               SH_FUNCT = CenterStr(HdrSelect);
            endif;

        if pParmType = 'M';
           SC_OPTIONS = CatB(SC_OPTIONS : Opt2Text);
           SH_FUNCT = CenterStr(HdrMaint);
        endif;
         SC_OPTIONS = CatB(SC_OPTIONS : Opt5Text);
         endsr;

       //=============================================================
       //   S u b  P r o c e d u r e s
       //=============================================================

       // === Quote ==================================================
       // Sanatize and puts quotes around a string
      /END-FREE
     pQuote            b
     dQuote            pi           100    varying
     dStr                           100    varying value
      /free
       return '''' + %trim(Sanatize(str)) +'''';

      /END-FREE
     p                 e
       //=============================================================
       // === Sanatize ===============================================
       // Sanatize an entered search string field that is not using
       // parameter markers.
       //  - Remove any single quotes, otherwise the built SQL prepare
       //    will fail.
       //    Double quotes are OK.

     pSanatize         b
     dSanatize         pi           100    varying
     dStr                           100    varying value

     d wkStr           s                   like(Str)
     dQuotesTwo        c                   ''''''
     dQuotesOne        c                   ''''
      /free
       wkSTR = %scanrpl(QuotesTwo:x'ff':Str);
       wkStr = %scanrpl(QuotesOne:'':wkStr);
       wkStr = %scanrpl(x'ff':QuotesTwo:wkStr);
       return wkStr;
      /END-FREE
     p                 e

       //=== CatB ====================================================
       // Concatenates a string to another string with a blank between.
       // If the target string is all blank to start with it will not
       // end up with a leading blank.
     pCatB             b
     dCatB             PI            79    varying
     d ToStr                         79    varying value
     d AddStr                        79    varying value
      /FREE
       if ToStr=' ';
         return AddStr;
       else;
         return %trimr(ToStr) + ' ' + AddStr;
       endif;
      /END-FREE
     pCatB             e

       //=== SQLProblem ==============================================
       // For those "Never should happen" SQL errors.
       // Issues DUMP(A) to dump memory, then ends program by
       // sending an *ESCAPE message of the supplied debugging text.
     p SQLProblem      B
     d SQLProblem      PI
     d piSQLDebug                  1024    varying value

       //--- Local Variables ----------------------------------------
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

       //=== FetchNextData ===========================================
       // Fetch the next row from the cursor
       // Returns:        End of data Indicator:
       //                   *ON   No more data, nothing returned
       //                   *OFF  Data returned
       //------------------------------------------------------------
     p FetchNextData   B
     d FetchNextData   PI              N
     d TheRecd                             likeds(Custmast)

       // Local fields
     d wkEof           S               N
      /FREE
         wkEoF= *off;
           exec sql fetch ItemCur into
                             :TheRecd.NAME,
                             :TheRecd.CITY,
                             :TheRecd.STATE,
                             :TheRecd.ZIP,
                             :TheRecd.ACTIVE,
                             :TheRecd.CUSTID
                        ;
           select;
             when SQLSTT = SQLSuccess;
                 wkEof = *off;
             when SQLSTT = SQLNoMoreData;
               wkEof = *on;
             Other;
               SQLProblem('Fetch ITEMCUR');
           endsl;

         RETURN wkEof;

      /END-FREE

     p FetchNextData   E

       //=== ReadByKey ===============================================
       // Read the record by key into the specified data record
       // using the key passed in.
     p ReadByKey       B
     d ReadByKey       PI
     d TheKey                              like(CUSTID)
     d TheRecd                             likeds(CustMast)
      /FREE
       exec sql select
                         NAME,
                         CITY,
                         STATE,
                         ZIP,
                         ACTIVE,
                         CUSTID
                into
                         :TheRecd.NAME,
                         :TheRecd.CITY,
                         :TheRecd.STATE,
                         :TheRecd.ZIP,
                         :TheRecd.ACTIVE,
                         :TheRecd.CUSTID
                from     CUSTMAST
                where    CUSTID = :TheKey
       ;
      /END-FREE

     p ReadByKey       E

       //=== BuildSFLRecd ============================================
       // Builds a SFL record from the specified data record
     p BuildSflRecd    b
     d BuildSflRecd    PI
     d CustRecd                            likeds(CUSTMAST)
      /FREE
             SF_NAME = CustRecd.NAME;
             SF_CITY = CustRecd.CITY;
             SF_STATE = CustRecd.STATE;
             SF_ZIP = CustRecd.ZIP;
             // Save Id in case we need it for 5=Display
             SF_CUST_H = %editc(CustRecd.CUSTID:'3');
             // Change color if record is inactive
             if CustRecd.ACTIVE = 'N';
                 sfInAct = *on;
             else;
                 sfInAct= *off;
             endif;
             // Save Active status in case we update subfile
             SF_ACT_H = CustRecd.ACTIVE;
      /END-FREE
     p BuildSFLRecd    E

       //=== Procedure name: CloseCurssor ============================
       // Closes the SQL Cursor if open
       //------------------------------------------------------------
     p CloseCursor     B
     d CloseCursor     PI
       // Local fields
       //CursorOpen      s               n   static
      /FREE
        if CursorOpen = *on;
            exec sql close ItemCur;
            if SQLSTT <> SQLSuccess;
              SQLProblem('Close ITEMCUR');
            endif;
          CursorOpen = *off;
        endif;
        RETURN;
      /END-FREE
     p CloseCursor     E

       //=== SndSflMsg ===============================================
       // Send a message to the Error Subfile
       // Returns:        *ON
       // Parameter:      ErrMsgId => Msg Id to Send
       // Parameter:      ErrMsgData => Optional Error Message Data
       // Parameter:      ErrMsgFile => Optional Error Message File
       //                 Defaults to CUSTMSGF
       //------------------------------------------------------------
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
     d wkMsgData       s            512a   varying

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
       SNDMSGPGMQ(PgmName:
             wkMsgid:
             wkMsgFile:
             wkMsgData);

        retField = *on;
        RETURN retField;

      /END-FREE
     p SndSflMsg       E

       //=== SflClear ================================================
       // Clears the Subfile
       //------------------------------------------------------------
     p SflClear        B
     d SflClear        PI
      /FREE
         clear SflRRN;
         clear RcdsInSfl;
         scSflClr = *ON;
         write SFLCTL;
         scSflClr = *OFF;
         return;
      /END-FREE
     p SflClear        E


