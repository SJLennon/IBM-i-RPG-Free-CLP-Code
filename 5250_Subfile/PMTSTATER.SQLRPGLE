**free
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
//    Note that /INCLUDEs expects to find code in Copy_Mbrs file,
//    not the default of QRPGLESRC. Change as needed.
//=============================================================
// 12/2023 Converted to totally **FREE
//         Use SQLPROBLEM service program
//=============================================================
ctl-opt dftactgrp(*no) actgrp(*caller) option(*nodebugio: *srcstmt)
bnddir('UTIL_BND': 'SQL_BND');

// === Program parameters =======================================
dcl-pi *n;
  pState like(FetchData.state);
end-pi;

//=== Display File ==============================================
dcl-f PMTSTATED workstn infds(dfInfDS) indds(dfIndDS) sfile(SFL:SflRRN)
usropn;
//=== Service Program Prototypes ================================
/INCLUDE ../Copy_Mbrs/SRV_MSG_P.RPGLE
/INCLUDE ../Copy_Mbrs/SRV_SQL_P.RPGLE
//=== Named hexadecimal constants for function keys =============
/INCLUDE ../Copy_Mbrs/AIDBYTES.RPGLE
//=== Fields read by SQL ========================================
// NOTE: Only the fields in fetchData which are fetched by the
// SQL Cursor are populated.
dcl-ds STATESds extname('STATES') qualified template end-ds;
dcl-ds FetchData likeds(STATESds);
//=== SQL State Constants =======================================
dcl-c SQLSUCCESS '00000';
dcl-c SQLNODATA '02000';
dcl-c SQLNOMOREDATA '02000';
dcl-c SQLDUPRECD '23505';
dcl-c SQLROWLOCKED '57033';
//=== Display File Information Data Structure ===================
//    Allows us to determine which function key was pressed
dcl-ds dfInfDS;
  Key char(1) pos(369);
end-ds;
//=== Display File Indicator Data Structure =====================
// This is a "private" indicator area for the display file.
//--- 01-20 are not automatically cleared after EXFMT ----------
dcl-ds dfIndDS len(99);
  scCodeHi char(1) pos(1);
//--- 21-99 automatically cleared after EXFMT ------------------
  scNameHi char(1) pos(2);
//--- Subfile indicators (prefix "sf") -------------------------
  dfIndClr char(79) pos(21);
  sfSflNxtChg ind pos(80);
  sfOPT_RI ind pos(81);
//--- Subfile Control indicators (prefix "sc") ----------------
  sfOPT_PC ind pos(82);
  scMDT ind pos(95);
  scNoDta ind pos(96);
  scSflEnd ind pos(97);
  scSflDsp ind pos(98);
  scSflClr ind pos(99);
end-ds;
//=== Fields to control the subfile screen ======================
dcl-s SflRRN int(5);
dcl-s RcdsInSfl int(5);
dcl-c SFLPAGESIZE 6;
dcl-s SflMaxRecd int(5) inz(9999);
// SC_CSR_RCD is defined in the display file and is set with a
// RRN which determines which subfile page is displayed and on
// which record the cursor is positioned.
//=== Program Status Data Structure =============================
dcl-ds ProgStatus PSDS;
  PgmName *PROC;
end-ds;
dcl-s MainProc char(10);
//=== Text for function keys ====================================
dcl-c F3TEXT 'F3=Exit';
dcl-c F5TEXT 'F5=Refresh';
dcl-c F12TEXT 'F12=Cancel';
dcl-c F7TEXT1 'F7=By ';
dcl-s F7Text2 char(5) inz(' ');
dcl-s F7Text char(11) inz(' ');
//SortSeq is used in SQL Order By in a CASE construct.
dcl-s SQLSortSeq char(4) inz(' ');
dcl-s SortbyName char(4) inz('Name');
dcl-s SortbyCode char(4) inz('Code');
//=== Options Text ==============================================
dcl-c OPT1TEXT '1=Select';
//=== Search Criteria Screen Fields =============================
dcl-ds SearchCriteria inz;
  SC_NAME;
end-ds;
//=== Last Search Criteria Fields ===============================
dcl-ds LastSearchCriteria inz;
  LastSC_NAME like(sc_name);
end-ds;
//=== SQL Search Variables ======================================
dcl-s DESCLike varchar(12);
//=== Global Switches ===========================================
dcl-s EofData ind;
dcl-s CursorOpen ind;
dcl-s NewSearchCriteria ind;
dcl-s SflMsgSnt ind;
dcl-s Opt1OK ind;
dcl-s OptError ind;
//=== Work Fields ===============================================
dcl-s inx int(10);
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
 where    upper(NAME) like :DESCLike
 order by case :SQLSortSeq
               when :SortbyName then NAME
               when :SortbyCode then STATE
               else '1'
          end
 for fetch only;
//=============================================================
//== Program Starts Here ======================================
//=============================================================
//--- Analyse parameters ---
Opt1OK = *off;
if %parms() > 0;
  Opt1OK = *on;
endif;
Init();
BldFkeyText();
// === Initial screen display =================================
write SH_HDR;
SflClear();
ProcessSearchCriteria();
SflLoadAll();
//=============================================================
// === Main Program Loop ======================================
//=============================================================
dow *INLR = *OFF;
  // To exit this program, some procedures tuen on *INLR

  // Put the last search criteria back on the screen.
  SearchCriteria = LastSearchCriteria;
  // Set "*More" display
  scSflEnd = EofData;
  // If switching display order, reload first page
  if Key = F07;
    ProcessSearchCriteria();
    SflLoadAll();
  endif;
  // Write/Read the screen
  ScreenIO();
  //-- Enter Key --------------------------------------------
  If Key = Enter;
    // Either new Search Criteria entered or option(s) entered.
    // New Search Criteria takes precedence over option(s).
    if SearchCriteria <> LastSearchCriteria
      or NewSearchCriteria = *on;
      SflClear();
      ProcessSearchCriteria();
      SflLoadAll();
    else;
      ProcessOption();
    endif;
    iter;
  endif;
  //--- Any other entry must be a function key ---------------
  ProcessFunctionKey();
enddo;
return; // to Caller
//=============================================================
//=== End of Main Program Loop ================================
//=============================================================

//=== ScreenIO ================================================
// Writes and Reads the screen
Dcl-Proc ScreenIO;
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
End-Proc;

//=== ProcessFunctionKey ======================================
// Process whatever keyboard entry was made.
//   Will not return from subroutine if F3 or F12 was pressed.
//   May not return from subroutine when an option is entered.
Dcl-Proc ProcessFunctionKey;
  select;
    //--- F3 or F12: Exit, close down program -----------------------
    when (Key = F03 or Key = F12);
      CloseDownPgm();
      *inlr = *on;
      return;
    //--- F5: Refresh all search fields ----------------------
    when Key = F05;
      clear LastSearchCriteria;
      NewSearchCriteria = *on;
      SflClear();
    //--- F7: Toggle Sort Sequence ---------------------------
    when Key = F07;
      if SQLSortSeq=SortbyName;
        SQLSortSeq = SortbyCode;
        SC_SORTED = SortbyCode;
        scCodeHi = *on;
        scNameHi = *off;
        F7Text2 = SortbyName;
      else;
        SQLSortSeq = SortbyName;
        SC_SORTED = SortbyName;
        scNameHi = *on;
        scCodeHI = *off;
        F7Text2 = SortbyCode;
      endif;
      F7Text = F7TEXT1 + F7Text2;
      BldFkeyText();
      NewSearchCriteria = *on;
      SflClear();
    //--- Other keys: Function key not active message ---------
    other;
      SflMsgSnt= SndSflMsg('DEM0003');
  endsl;
End-Proc;

//=== ProcessOption ===========================================
// Did user enter an option?  If so, process it.
//   May not return from this subroutine.
Dcl-Proc ProcessOption;
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
          pState = SF_CODE;
          CloseDownPgm();
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
          SetScreenCursorPosition();
          OptError = *on;
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
        ( %int( (RcdsInSfl-1) / SFLPAGESIZE )
        * SFLPAGESIZE
        ) + 1;
  endif;
End-Proc;

//=== SflLoadAll ==============================================
// Loads all selected records to the subfile.
// Returns:
//   EofData = *on  (there are no more data records.)
//   RcdsInSfl contains relative record number of last record
//             written to the subfile.
//   SC_CSR_RCD contains relative record number of 1st record
//             on the page & positions cursor there.
Dcl-Proc SflLoadAll;
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
    RcdsInSfl = RcdsInSfl + 1;
    write SFL;
      // Can't display more than 9,9999 records.
    if SflRRN = SflMaxRecd;
      EofData = *on;
      SflMsgSnt= SndSflMsg('DEM0006');
      leave;
    endif;
  endfor;
End-Proc;

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
Dcl-Proc ProcessSearchCriteria;
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
    if SQLSTT  <> SQLSUCCESS;
      SQLProblem('Open DataCur');
    endif;
    CursorOpen = *on;
  endif;
End-Proc;

//=== SetScreenCursorPostion ===================================
// If Invalid Option, position screen cursor on first one,
// else postion cursor on the last valid option.
Dcl-Proc SetScreenCursorPosition;
  if OptError = *off;
    SC_CSR_RCD=SflRRN;
  endif;
End-Proc;

//=== BldFKeyText =============================================
// Build the Function key text for the bottom of the screen.
Dcl-Proc BldFkeyText;
  SFT_KEYS=' ';
  SFT_KEYS = CatB(SFT_KEYS : F3TEXT);
  SFT_KEYS = CatB(SFT_KEYS : F5TEXT);
  SFT_KEYS = CatB(SFT_KEYS : F7Text);
  SFT_KEYS = CatB(SFT_KEYS : F12TEXT);
End-Proc;

//=== CloseDownPgm ============================================
// Things to do before we issue a return to the caller
Dcl-Proc CloseDownPgm;
  CloseCursor();
  if %open(PMTSTATED);
    close PMTSTATED;
  endif;
End-Proc;

//=== Init ====================================================
// Must be executed each time program is entered
Dcl-Proc Init;
  SQLSortSeq = SortbyName;
  SC_SORTED = SortbyName;
  scNameHi = *on;       // Name highlighted
  scCodeHi = *off;
  F7Text2 = SortbyCode;
  F7Text = F7TEXT1 + F7Text2;
  // Set up for subfile message queue
  MainProc = PgmName;
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
    SC_OPTIONS = OPT1TEXT;
  endif;
End-Proc;

//=== CatB ====================================================
// Concatenates a string to another string with a blank between.
// If the target string is all blank to start with it will not
// end up with a leading blank.
dcl-proc CatB;
  dcl-pi CatB varchar(79);
    ToStr varchar(79) value;
    AddStr varchar(79) value;
  end-pi;
  if ToStr=' ';
    return AddStr;
  else;
    return %trimr(ToStr) + ' ' + AddStr;
  endif;
end-proc;

// === SQLProblem ================================================
// For those "Never should happen" SQL errors.
// Issues DUMP(A) to dump memory, then ends program by
// sending an *ESCAPE message of the supplied debugging text.
// dcl-proc SQLProblem;
//   dcl-pi SQLProblem;
//     piSQLDebug varchar(1024) value;
//   end-pi;
// //--- Local Variables ---------------------------------
//   dcl-s wkSQLDebug varchar(1024);
//   wkSQLDebug = 'SQLSTT ' + SQLSTT
//              + ' << Unexpected SQL Return Code: '
//              + piSQLDebug;
//   dump(a);
//   SndEscMsg(wkSQLDebug);
//   return;
// end-proc;

//--------------------------------------------------
// Procedure name: FetchNextData
// Purpose:        Fetch the next row from the cursor
// Returns:        End of data Indicator:
//                   *ON   No more data, nothing returned
//                   *OFF  Data returned
//--------------------------------------------------
dcl-proc FetchNextData;
  dcl-pi FetchNextData ind end-pi;
// Local fields
  dcl-s wkEof ind;
  wkEof= *off;
  exec sql fetch DataCur into
                      :FetchData.STATE,
                      :FetchData.NAME
    ;
  select;
    when SQLSTT = SQLSUCCESS;
      wkEof = *off;
    when SQLSTT = SQLNOMOREDATA;
      wkEof = *on;
    Other;
      SQLProblem('Fetch DATACUR');
  endsl;
  RETURN wkEof;
end-proc;

//--------------------------------------------------
// Procedure name: SndSflMsg
// Purpose:        Send a message to the Error Subfile
// Returns:        *ON
// Parameter:      ErrMsgId => Msg Id to Send
// Parameter:      ErrMsgData => Optional Error Message Data
// Parameter:      ErrMsgFile => Optional Error Message File
//                 Defaults to CUSTMSGF
//--------------------------------------------------
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
    wkMsgFile = 'CUSTMSGF';
  ENDIF;
  if %parms > 1;
    wkMsgData = ErrMsgData;
  else;
    wkMsgData = ' ';
  ENDIF;
  wkMsgId = ErrMsgId;
  SndMsgPgmQ(MainProc:
           wkMsgId:
           wkMsgFile:
           wkMsgData);
  retField = *on;
  RETURN retField;
end-proc;

//--------------------------------------------------
// Procedure name: CloseCurssor
// Purpose:        Closes the SQL Cursor
//--------------------------------------------------
dcl-proc CloseCursor;
  dcl-pi CloseCursor end-pi;
  if CursorOpen = *on;
    exec sql close DataCur;
    if SQLSTT <> SQLSUCCESS;
      SQLProblem('Close DATACUR');
    endif;
    CursorOpen = *off;
  endif;
  RETURN;
end-proc;

//--------------------------------------------------
// Procedure name: SflClear
// Purpose:        Clears the Subfile
// Returns:
//--------------------------------------------------
dcl-proc SflClear;
  dcl-pi SflClear end-pi;
  clear SflRRN;
  clear RcdsInSfl;
  scSflClr = *ON;
  write SFLCTL;
  scSflClr = *OFF;
  return;
end-proc;
