      /TITLE PMTSTATE Search and return a USA State Code
       //==============================================================*
       // This is a "load all" subfile, where the system takes care or
       // paging up and down. All selected data is loaded into the
       // subfile. STATES table has only 58 rows, so selecting all
       // is approptiate.
       // For larger numbers of rows, a "page at at time" approach
       // may make more sense.
       //==============================================================*
       // Displays USA state names and their 2-char codes in a window.
       // Can sort the display by name or code.
       // Optionally can select and return a 2-char code.
       //
       // Parameters
       // ----------
       //    Out  CL2  Selected 2-Char State Code (optional)
       //
       //===============================================================
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
       // - In the display file, this field naming convention is used:
       //     Screen Header:   Fields begin with SH_
       //     Subfile:         Fields begin with SF_
       //     Subfile Control: Fields begin with SC_
       //     Screen footer:   Fields begin with SFT_
       //===============================================================
       // Compilation
       //    Use CRTSQLRPGI command.
       //    Note that /INCLUDEs expects to find code in DEMO library,
       //    not the default of QRPGLESRC. Change as needed.
       //=============================================================

     h DftActGrp(*NO) ActGrp(*CALLER) option(*nodebugio: *srcstmt)
     h BndDir('UTIL_BND')
     h main(Main)

       //=== Display File ==============================================
     fPMTSTATED CF   E             WorkStn INFDS(dfInfDS)
     f                                     INDDS(dfIndDS)
     f                                     SFILE(SFL:SflRRN)
     f                                     USROPN

     d Main            pr                  extpgm('PMTSTATER')
     d ReturnState                    2A

       //=== Service Program Prototypes ================================
      /include copy_mbrs,Srv_Msg_P

       //=== Named hexadecimal constants for function keys =============
      /include copy_mbrs,##AIDBYTES

       //=== Fields read by SQL ========================================
       // NOTE: Only the fields in fetchData which are fetched by the
       // SQL Cursor are populated.
     d STATES        e ds                  extname(STATES)
     d                                     qualified template
     d FetchData       ds                  likeds(STATES)

       //=== SQL State Constants =======================================
     d SQLSuccess      c                   '00000'
     d SQLNoData       c                   '02000'
     d SQLNoMoreData   c                   '02000'
     d SQLDupRecd      c                   '23505'
     d SQLRowLocked    c                   '57033'

       //=== Display File Information Data Structure ===================
       //    Allows us to determine which function key was pressed
     d dfInfDS         DS
     d Key                   369    369
       //=== Display File Indicator Data Structure =====================
       // This is a "private" indicator area for the display file.
     d dfIndDS         ds            99

       //--- 01-20 are not automatically cleared after EXFMT ----------
     d scCodeHi               01     01
     d scNameHi               02     02

       //--- 21-99 automatically cleared after EXFMT ------------------
     d dfIndClr               21     99

       //--- Subfile indicators (prefix "sf") -------------------------
     d sfSflNxtChg            80     80n
     d sfOPT_RI               81     81n
     d sfOPT_PC               82     82n

       //--- Subfile Control indicators (prefix "sc") ----------------
     d scMDT                  95     95n
     d scNoDta                96     96n
     d scSflEnd               97     97n
     d scSflDsp               98     98n
     d scSflClr               99     99n

       //=== Fields to control the subfile screen ======================
     d  SflRRN         s              5i 0
     d  RcdsInSfl      s              5i 0
     d  SflPageSize    c                    6
     d  SflMaxRecd     s              5i 0  inz(9999)
       // SC_CSR_RCD is defined in the display file and is set with a
       // RRN which determines which subfile page is displayed and on
       // which record the cursor is positioned.

       //=== Program Status Data Structure =============================
     d ProgStatus     sds
     d PgmName           *PROC

     d MainProc        S             10a

       //=== Text for function keys ====================================
     d F3Text          c                   'F3=Exit'
     d F5Text          c                   'F5=Refresh'
     d F12Text         c                   'F12=Cancel'
     d F7Text1         c                   'F7=By '
     d F7Text2         s              5a   inz(' ')
     d F7Text          S             11a   inz(' ')

       //SortSeq is used in SQL Order By in a CASE construct.
     d SQLSortSeq      s              4a   inz(' ')
     d SortbyName      s              4a   inz('Name')
     d SortbyCode      s              4a   inz('Code')

       //=== Options Text ==============================================

     d Opt1Text        c                   '1=Select'

       //=== Search Criteria Screen Fields =============================
     d SearchCriteria  ds                  inz
     d SC_NAME

       //=== Last Search Criteria Fields ===============================
     d LastSearchCriteria...
     d                 ds                  inz
     d LastSC_NAME                         Like(SC_NAME)

       //=== SQL Search Variables ======================================
     d DESCLike        S             12    varying

       //=== Global Switches ===========================================
     d EofData         s               n
     d CursorOpen      s               n
     d NewSearchCriteria...
     d                 s               n
     d SflMsgSnt       s               n
     d Opt1OK          s               n
     d OptError        s               n
     d CowsComeHome    c                   const('0')

       //=== Work Fields ===============================================
     d inx             s             10i 0

       //=============================================================
       //== Program Starts Here ======================================
       //=============================================================
     p Main            b
     d Main            pi
     d pState                              Like(FetchData.STATE)

      /FREE
       exsr Init;
       exsr BldFkeyText;

       //=== Set SQL Options =========================================
       exec sql set option datfmt=*iso,
                           closqlcsr=*endmod;
       //=== SQL Cursor Definitions ==================================
       // Sort Order is controlled by field SQLSortSeq which is
       // used in a CASE statement.
       exec SQL
        declare DataCur cursor for
        select
                 STATE,
                 NAME
        from     STATES
        where    upper(NAME) like :DescLike
        order by case :SQLSortSeq
                      when :SortByName then NAME
                      when :SortByCode then STATE
                      else '1'
                 end
        for fetch only;

       // === Initial screen display =================================
       write SH_HDR;
       SflClear();
       exsr ProcessSearchCriteria;
       exsr SflLoadAll;

       //=============================================================
       // === Main Program Loop ======================================
       //=============================================================
       dou CowsComeHome;
         // Put the last search criteria back on the screen.
         SearchCriteria = LastSearchCriteria;
         // Set "*More" display
         scSflEnd = EofData;

         // If switching display order, reload first page
         if Key = F07;
           exsr ProcessSearchCriteria;
           exsr SflLoadAll;
         endif;

         // Write/Read the screen
         exsr ScreenIO;

         //-- Enter Key --------------------------------------------
         If Key = Enter;
           // Either new Search Criteria entered or option(s) entered.
           // New Search Criteria takes precedence over option(s).
           if SearchCriteria <> LastSearchCriteria
             or NewSearchCriteria = *on;
             SflClear();
             exsr ProcessSearchCriteria;
             exsr SflLoadAll;
           else;
             exsr ProcessOption;
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
           SflMsgSnt = ClrMsgPgmQ(MainProc);
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

           //--- F5: Refresh all search fields ----------------------
         when Key = F05;
           clear LastSearchCriteria;
           NewSearchCriteria = *on;
           SflClear();

           //--- F7: Toggle Sort Sequence ---------------------------
         when Key = F07;
           if SQLSortSeq=SortByName;
             SQLSortSeq = SortByCode;
             SC_SORTED = SortByCode;
             scCodeHi = *on;
             scNameHi = *off;
             F7Text2 = SortByName;
           else;
             SQLSortSeq = SortByName;
             SC_SORTED = SortByName;
             scNameHi = *on;
             scCodeHI = *off;
             F7Text2 = SortbyCode;
           endif;
           F7Text = F7Text1 + F7Text2;
           exsr BldFkeyText;
           NewSearchCriteria = *on;
           SflClear();

           //--- Other keys: Function key not active message ---------
         other;
           SflMsgSnt= SndSflMsg('DEM0003');
         endsl;

       endsr;

       //=== ProcessOption ===========================================
       // Did user enter an option?  If so, process it.
       //   May not return from this subroutine.

       begsr ProcessOption;
         if RcdsInSfl > 0;
           OptError = *off;

           // Don't know yet which page to display next time.
           SC_CSR_RCD = 0;

           // Loop through changed records in the subfile.
           readc SFL;
           dow not %eof;
             select;

               //--- 1 = Select ------------------------------------------
               when SF_OPT = '1' and Opt1OK;
                 // Return Code to caller
                 pSTATE = SF_CODE;
                 exsr CloseDownPgm;
                 *inlr = *on;
                 return;

               //--- Opt is blank ----------------------------------------
               when SF_OPT = ' ';
                 // If changed, assume clearing an error from last time
                 sfOPT_PC = *off;
                 sfOPT_RI = *off;
                 update SFL;

               //--- Other -----------------------------------------------
               other;
                 // Send message about invalid selection.
                 // Position cursor and page at first error.
                 // Always force to be read again next time & reverse image.

                 // Not a valid option at this time
                 SflMsgSnt= SndSflMsg('DEM0004':SF_OPT);
                 // Leave cursor at first invalid option
                 exsr SetScreenCursorPosition;
                 optError = *on;

                 // SFLNXTCHG forces this record to be read again
                 // even if user doesn't correct it, so we can
                 // check it again for validity.
                 sfSflNxtChg = *on;
                 sfOPT_RI = *on;

                 update SFL;
                 // set off indicators applying to just this recd.
                 sfSflNxtChg = *off;
                 sfOPT_RI = *off;

             endsl;

             readc SFL;
           enddo;

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

       //=== SflLoadAll ==============================================
       // Loads all selected records to the subfile.

       // Returns:
       //   EofData = *on  (there are no more data records.)
       //   RcdsInSfl contains relative record number of last record
       //             written to the subfile.
       //   SC_CSR_RCD contains relative record number of 1st record
       //             on the page & positions cursor there.

       begsr SflLoadAll;

           // Position cursor at first record on the subfile page.
           SC_CSR_RCD = 1;

           for inx = 1 to SflMaxRecd;
             EofData = FetchNextData();
             if EofData = *on;
               leave;
             endIf;
             // Build/Format the subfile record
             clear SF_OPT;
             SF_CODE = FetchData.STATE;
             SF_NAME = FetchData.NAME;

             SflRRN = inx;
             RcdsinSfl = RcdsInSfl + 1;
             write SFL;

             // Can't display more than 9,9999 records.
             if SflRRN = SflMaxRecd;
               EofData = *on;
               SflMsgSnt= SndSflMsg('DEM0006');
               leave;
             endif;

           endfor;

       endsr;

       //=== ProcessSearchCriteria====================================
       // Examines the data entered in the search fields and sets up
       // variables used in the SQL Cursor.
       //
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
         CloseCursor();

         //---------------------------------------------------------------
         if SC_NAME = ' ';
           // Not searching, take all
           DESCLike = '%%';
         else;
           DESCLike = '%' + %trim(SC_NAME) + '%';
          endif;
         //---------------------------------------------------------------

         // If no errors in search criteria, open the SQL cursor
         if NewSearchCriteria = *off;
           exec sql open DataCur;
           if SQLSTT  <> SQLSuccess;
             SQLProblem('Open DataCur');
           endif;
           CursorOpen = *on;
         endif;

       endsr;

       //=== SetCursorPostion ========================================
       // If Invalid Option, position screen cursor on first one,
       // else postion cursor on the last valid option.
       begsr SetScreenCursorPosition;
         if OptError = *off;
           SC_CSR_RCD=SflRRN;
         endif;
       endsr;

       //=== BldFKeyText =============================================
       // Build the Function key text for the bottom of the screen.
       begsr BldFkeyText;
         SFT_KEYS=' ';
         SFT_KEYS = CatB(SFT_KEYS : F3Text);
         SFT_KEYS = CatB(SFT_KEYS : F5Text);
         SFT_KEYS = CatB(SFT_KEYS : F7Text);
         SFT_KEYS = CatB(SFT_KEYS : F12Text);
       endsr;

       //=== CloseDownPgm ============================================
       // Things to do before we issue a return to the caller
       begsr CloseDownPgm;
           CloseCursor();
         if %open(PMTSTATED);
           close PMTSTATED;
         endif;
       endsr;

       //=== Init ====================================================
       // Must be executed each time program is entered
       begsr Init;
         SQLSortSeq = SortByName;
         SC_SORTED = SortByName;
         scNameHi = *on;       // Name highlighted
         scCodeHi = *off;
         F7Text2 = SortByCode;
         F7Text = F7Text1 + F7Text2;

       //--- Analyse parameters ---
         Opt1OK = *off;
         if %parms() > 0;
           Opt1OK = *on;
         endif;
         // Set up for subfile message queue
         MainProc = %proc();
         MSGPGMQF = MainProc;
         MSGPGMQC = MSGPGMQF;
         SH_PGM = PgmName;

         if not %open(PMTSTATED);
           open PMTSTATED;
         endif;

         // Clear fields left over from previous F12.
         reset LastSearchCriteria;
         reset SearchCriteria;

         // Build options string.
         clear SC_OPTIONS;
         if Opt1OK;
           SC_OPTIONS = Opt1Text;
         endif;
         endsr;
     p Main            e

       //=============================================================
       //   S u b  P r o c e d u r e s
       //=============================================================

       //=== CatB ====================================================
       // Concatenates a string to another string with a blank between.
       // If the target string is all blank to start with it will not
       // end up with a leading blank.
      /END-FREE
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

       // === SQLProblem ================================================
       // For those "Never should happen" SQL errors.
       // Issues DUMP(A) to dump memory, then ends program by
       // sending an *ESCAPE message of the supplied debugging text.
     p SQLProblem      B
     d SQLProblem      PI
     d piSQLDebug                  1024    varying value

       //--- Local Variables ---------------------------------
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

       //--------------------------------------------------
       // Procedure name: FetchNextData
       // Purpose:        Fetch the next row from the cursor
       // Returns:        End of data Indicator:
       //                   *ON   No more data, nothing returned
       //                   *OFF  Data returned
       //--------------------------------------------------
     p FetchNextData   B
     d FetchNextData   PI              N

       // Local fields
     d wkEof           S               N
      /FREE
         wkEoF= *off;
           exec sql fetch DataCur into
                             :FetchData.STATE,
                             :FetchData.NAME
           ;
           select;
             when SQLSTT = SQLSuccess;
                 wkEof = *off;
             when SQLSTT = SQLNoMoreData;
               wkEof = *on;
             Other;
               SQLProblem('Fetch DATACUR');
           endsl;

         RETURN wkEof;

      /END-FREE
     p FetchNextData   E

       //--------------------------------------------------
       // Procedure name: SndSflMsg
       // Purpose:        Send a message to the Error Subfile
       // Returns:        *ON
       // Parameter:      ErrMsgId => Msg Id to Send
       // Parameter:      ErrMsgData => Optional Error Message Data
       // Parameter:      ErrMsgFile => Optional Error Message File
       //                 Defaults to CUSTMSGF
       //--------------------------------------------------
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

       //--------------------------------------------------
       // Procedure name: CloseCurssor
       // Purpose:        Closes the SQL Cursor
       //--------------------------------------------------
     p CloseCursor     B
     d CloseCursor     PI
      /FREE
        if CursorOpen = *on;
            exec sql close DataCur;
            if SQLSTT <> SQLSuccess;
              SQLProblem('Close DATACUR');
            endif;
          CursorOpen = *off;
        endif;
        RETURN;
      /END-FREE
     p CloseCursor     E

       //--------------------------------------------------
       // Procedure name: SflClear
       // Purpose:        Clears the Subfile
       // Returns:
       //--------------------------------------------------
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
