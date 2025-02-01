**free
/TITLE Demo Expanding Subfile Search using SQL for IO
//=============================================================
// This is an customer master prompt/search program.
// It can be called to return a selected customer number or
// just to provide general inquiry functionality from a menu

// Detailed Item information is displayed in a window by
// calling another program, MTNCUSTR.

// Parameters:
// -----------
// 1  Char 1  Type of parameter
//            S - Return Selected Customer Id: 1=Select
//            M - Allow maintenance: 2=Edit, F6=Add
//            I - Inquiry, read only: 5=Display
// 2  Char 4  Selected customer id if parm 1 is S.

//=============================================================
// Program uses a full screen expanding subfile to select
// a Customer Master record.

// The screen layout is similar to PDM.

// Instead of using native IO it uses SQL to retrieve records.

// It is essentially without indicators.  (Indicators are still
// needed to control the display file, but they all have names.)

// It is possible to use F4 to prompt for the State abbreviation
// when the cursor is in the ST field.

// F09 is a toggle to display or not display inactive Customers.

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
//  This source is set up to compile from the IFS, with /COPY &
//  /INCLUDE files using relative paths. For example, a path
//  such as "/INCLUDE ../Copy_Mbrs/SRV_MSG_P.RPGLE".      
//
//  Use CRTSQLRPGI command with RPGPPOPT(*LVL2) specified. This means
//  the copy files are included using the relative path before the 
//  SQL preprocessor rewrites the code to a temporary location.

//  I edit using VS Code with the 'Code for IBM i" extension.
//============================================================
// 12/2023 Converted to totally **FREE
//         Changed to use SQLPROBLEM service pgm
// 01/2025 Require at least one parameter.
//         Remove commented SQLPROBLEM code.
//         Fix some issues with "Return selected customer" 
//============================================================

ctl-opt dftactgrp(*no) actgrp(*caller) option(*nodebugio: *srcstmt)
       bnddir('UTIL_BND':'SQL_BND');

// === Program parameters ====================================
dcl-pi *n;
    pParmType char(1);
    pCustID like(CUSTID);     
end-pi;

//=== External Programs Prototypes ============================
//--- Display/maintain customer ---
dcl-pr CustDsp extpgm('MTNCUSTR');
    *n options(*nopass) like(custid); // CustID
    *n char(1) options(*nopass); // Maintain
end-pr;
//--- Prompt for State
dcl-pr PmtState extpgm('PMTSTATER');
    *n like(state); // TheState
end-pr;

//=== Service Program Prototypes ==============================
/INCLUDE ../Copy_Mbrs/SRV_MSG_P.RPGLE
/INCLUDE ../Copy_Mbrs/SRV_STR_P.RPGLE 
/INCLUDE ../Copy_Mbrs/SRV_SQL_P.RPGLE

//=== Named hexadecimal constants for function keys ===========
/INCLUDE ../Copy_Mbrs/AIDBYTES.RPGLE

//=== Display File ===========================================
dcl-f PMTCUSTD workstn infds(dfInfDS) indds(dfIndDS) sfile(SFL:SflRRN)
       usropn;
// File is closed when returning with LR off. This avoids an
// annoying resdisplay of the last subfile on re-entry.

//=== Display File Information Data Structure =================
//    Allows us to determine which function key was pressed
dcl-ds dfInfDS;
    Key char(1) pos(369);
end-ds;

//=== Display File Indicator Data Structure ===================
// This is a "private" indicator area for the display file.
dcl-ds dfIndDS len(99);
    //--- 01-20 are not automatically cleared after EXFMT -----
    scIncActInc ind pos(3);
    //--- 21-99 automatically cleared after EXFMT -------------
    dfIndClr char(79) pos(21);
    SC_NAME_PC ind pos(79);
    // Subfile indicators (prefix "sf") ---
    sfSflNxtChg ind pos(80);
    sfOPT_RI ind pos(81);
    sfOPT_PC ind pos(82);
    sfInAct ind pos(83);
     // Subfile Control indicators (prefix "sc") -------------
    scSflEnd ind pos(97);
    scSflDsp ind pos(98);
    scSflClr ind pos(99);
end-ds;

//=== Fields to control the subfile screen ====================
dcl-s SflRRN packed(5);
dcl-s RcdsInSfl packed(5);
dcl-c SFLPAGESIZE 12;
// SC_CSR_RCD is defined in the display file and is set with a
// RRN which determines which subfile page is displayed and on
// which record the cursor is positioned.

//=== Search Criteria Screen Fields ===========================
dcl-ds SearchCriteria inz;
    SC_NAME;
    SC_CITY;
    SC_STATE;
end-ds;

//=== Last Search Criteria Fields =============================
dcl-ds LastSearchCriteria inz;
    LastSC_NAME like(sc_name);
    LastSC_CITY like(sc_city);
    LastSC_STATE like(sc_state);
end-ds;

//=== SQL State Constants =====================================
dcl-c SQLSUCCESS '00000';
dcl-c SQLNODATA '02000';
dcl-c SQLNOMOREDATA '02000';
dcl-c SQLDUPRECD '23505';
dcl-c SQLROWLOCKED '57033';

//== CUSTMAST - define fields for SQL =========================
dcl-ds CustMast extname('CUSTMAST') template end-ds;

// NOTE: !!! Only the fields read by SQL are populated !!!
// Records from SQL CURSOR read into CustCursor
dcl-ds CustCursor likeds(CustMast);

// Records from SQL SELECT read into CustSelect
dcl-ds CustSelect likeds(CustMast);

//=== Global Switches =========================================
dcl-s Quit_Pgm ind inz(*off);
dcl-s EofData ind;
dcl-s CursorOpen ind;
dcl-s NewSearchCriteria ind;
dcl-s SflMsgSnt ind;
dcl-s Opt1_OK ind;
dcl-s OptError ind;
dcl-s Maint_OK ind;
dcl-c COWSCOMEHOME const('0');
dcl-c MAXSFLRECDS const(9999);

//=== Parm fields for MTNCUSTR ================================
dcl-s wkCustid like(custid);
dcl-s CustDspParm char(1);
dcl-c CUSTDSPEDIT const('E');
dcl-c CUSTDSPADD const('A');
dcl-c CUSTDSPDSPLY const('D');

//=== Program Status Data Structure ===========================
dcl-ds ProgStatus PSDS;
    PgmName *PROC;
end-ds;

//=== Set SQL Options =========================================
// Note: Compile time settings 
exec sql set option datfmt=*iso,
                    closqlcsr=*endmod;
//=== SQL Cursor for SFL data selection =======================
    // Would prefer to defind these as  like(SC_NAME)
    // But SQL precompiler throws an error SQL0312, reason code 1
    dcl-s wkName varchar(13) ;
    dcl-s wkCity varchar(13) ;
    dcl-s wkStateLow varchar(2);
    dcl-s wkStateHigh varchar(2);
    dcl-s wkActiveLow char(1);
    dcl-s wkActiveHigh char(1);

exec sql declare ItemCur cursor for 
select NAME 
        ,CITY 
        ,STATE
        ,ZIP
        ,ACTIVE
        ,CUSTID
from    CUSTMAST
where   NAME LIKE :wkName
        and  CITY LIKE :wkCity 
        and STATE between :wkStateLow and :wkStateHigh
        and ACTIVE between :wkActiveLow and :wkActiveHigh
order by NAME, CITY, STATE
optimize for 13 rows
for fetch only
;

//=============================================================
// === Program Starts Here ====================================
//=============================================================
// Check at least one parameter. Calling from the command line
// without a parm caused confusion for newer developers.       
// In a production environment, this would be called from a 
// tested menu or some program that enforced security.
if %parms() = 0;
    snd-msg *DIAG (%trim(PgmName) + ': There must be at least one parameter'); 
    snd-msg *ESCAPE 'See previous diagnostic (*DIAG) message ';
endif;

// === Set up for the first screen IO =========================
Init(pParmType : pCustID);
BldFkeyText();
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
        SflFirstPage();
    endif;
endif;

//=============================================================
// === Main Program Loop ======================================
//=============================================================
dou COWSCOMEHOME;

  // Set "*More" display
    scSflEnd = EofData;

  // Write/Read the sreen
    ScreenIO();

    //-- Enter Key ---------------------------------------------
    If Key = Enter;
    // Either new Search Criteria entered or option(s) entered.
    // New Search Criteria takes precedence over option(s).
        if SearchCriteria <> LastSearchCriteria
             or NewSearchCriteria = *on;
            SflClear();
            SflFirstPage();
        else;
            ProcessOption();
        endif;
        if Quit_Pgm = *on;
            leave;
        endif;
        iter;
    endif;

    //--- Page Down --------------------------------------------
    if Key = PageDown;
        if RcdsInSfl > 0;
            SflFillPage();
            if SflRRN = MAXSFLRECDS;
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
    ProcessFunctionKey();
    if (Quit_Pgm = *on);
        leave;
    endif;

enddo;

return;

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
        SflMsgSnt = ClrMsgPgmQ(PgmName);
        write MSGCTL;
    endif;

End-Proc ScreenIO;

//=== ProcessFunctionKey ======================================
// Process whatever keyboard entry was made.
//   Will not return from subroutine if F3 or F12 was pressed.
//   May not return from subroutine when an option is entered.

Dcl-Proc ProcessFunctionKey;

    select;

        //--- F3: Exit, close down program -----------------------
        when Key = F03;
            CloseDownPgm();
            *inlr = *on;
            Quit_Pgm = *on;

        //--- F12: Return to caller, leave program active ---------
        when Key = F12;
            CloseDownPgm();
            Quit_Pgm = *on;

        //--- F4: Prompt to fill the field -----------------------
        when Key = F04;
        //  The result of a successful F4 is as if the field
        //   had been keyed from the screen.
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
                    //  Use F4 only in field followed by + sign
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
            if Maint_OK = *on;
                CustDspParm = CUSTDSPADD;
                CustDsp(wkCustid : CustDspParm);
            else;
            // Function key not active
                SflMsgSnt= SndSflMsg('DEM0003');
            endif;

        //--- F9: Toggle Include InActive ------------------------
        when Key = F09;
            CloseCursor();
            scIncActInc = not scIncActInc;
            BldFkeyText();
            SflClear();
            NewSearchCriteria = *on;
            SflFirstPage();

        //--- Other keys: Function key not active message ---------
        other;
            SflMsgSnt= SndSflMsg('DEM0003');
    endsl;

End-Proc ProcessFunctionKey;

//=== ProcessOption ===========================================
// Did user enter one or more options?  Loop through the
//     subfile and process them all.
// May not return from this subroutine for some options.

Dcl-Proc ProcessOption;
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
                    pCustID = SF_CUST_H;
                    CloseDownPgm();
                    Quit_Pgm = *on;
                    return;
                //--- 2 = Edit with external program -----------------
                when SF_OPT = '2' and Maint_OK = *on;
                    wkCustid = SF_CUST_H;
                    CustDspParm = CUSTDSPEDIT;
                    CustDsp(wkCustid : CustDspParm);
                    // Reset Opt and leave cursor at last valid option
                    SF_OPT = ' ';
                    SetCursorPosition();
                    // Re-read the changed record & update subfile
                    ReadByKey(wkCustid : CustSelect);
                    BuildSflRecd(CustSelect);
                    UpdSflRecd();

                //--- 5 = Display Detail with external program -------
                when SF_OPT = '5';
                    wkCustid = SF_CUST_H;
                    CustDspParm = CUSTDSPDSPLY;
                    CustDsp(wkCustid : CustDspParm);
                    // Reset Opt and leave cursor at last valid option
                    SF_OPT = ' ';
                    SetCursorPosition();
                    UpdSflRecd();

                //--- Opt is blank -----------------------------------
                when SF_OPT = ' ';
                // If changed, assume clearing an error from last time
                    sfOPT_PC = *off;
                    sfOPT_RI = *off;
                    UpdSflRecd();

               //--- Other ------------------------------------------
                other;
                // Send message about invalid selection.
                // Position cursor and page at first error.
                // Always force to be read again next time & reverse image.

                    // Not a valid option at this time
                    SflMsgSnt= SndSflMsg('DEM0004':SF_OPT);
                    // Leave cursor at first invalid option
                    SetCursorPosition();
                    OptError = *on;

                    // SFLNXTCHG forces this record to be read again
                    // (even if user doesn't correct it) so we can
                    // check it again for validity.
                    sfSflNxtChg = *on;
                    sfOPT_RI = *on;

                    UpdSflRecd();
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
               ( %int( (RcdsInSfl-1) / SFLPAGESIZE )
               * SFLPAGESIZE
               ) + 1;
    endif;

End-Proc ProcessOption;

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

Dcl-Proc SflFirstPage;
    ProcessSearchCriteria();
    if NewSearchCriteria = *off;
        EofData = FetchNextData(CustCursor);
        if EofData = *off;
            SflFillPage();
        else;
            // No records match selection criteria
            SflMsgSnt= SndSflMsg('DEM0002');
            NewSearchCriteria = *on;
        endif;

    endif;
End-Proc SflFirstPage;

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

Dcl-Proc SflFillPage;

    dcl-s inx int(10);
    select;
        when EofData = *on;
        // do nothing
        other;
        // Add a subfile page.  If not EOF, then one extra recd is
        // read for the next time.
            // Position cursor at first record on the subfile page.
            SC_CSR_RCD = 0;
            // Build/Format the subfile record
            for inx = 1 to SFLPAGESIZE;
                clear SF_OPT;
                BuildSflRecd(CustCursor);

                RcdsInSfl = RcdsInSfl + 1;
                SflRRN = RcdsInSfl;
                write SFL;

                // Leave curson on first SFL record
                if SC_CSR_RCD = 0;
                    SC_CSR_RCD = SflRRN;
                endif;

                // Can't display more than 9,999 records.
                if SflRRN = MAXSFLRECDS;
                    EofData = *on;
                    SflMsgSnt= SndSflMsg('DEM0006');
                    leave;
                endif;
                // Get next record from SQL cursor
                EofData = FetchNextData(CustCursor);
                if EofData = *on;
                    leave;
                endIf;
            endfor;
    endsl;
End-Proc SflFillPage;


//=== Update Subfile Recd =====================================
Dcl-Proc UpdSflRecd;
    // Set on indicator based on saved SFL fields
    if SF_ACT_H = 'N';
        sfInAct = *on;
    endif;
    update SFL;
    sfInAct = *off;
    write DUMMY; // Supposed to help restore SFL display
End-Proc UpdSflRecd;

//=== ProcessSearchCriteria ====================================
// Examine the data entered in the search fields and build an
// SQL statement.
// Success:
//    NewSearchCriteria is set off
//    SQL Cursor is open
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
    // Build SQL cursor host variables. Using host variables
    // protects against SQL injection attacks.
    wkName =  %trim(SC_NAME) + '%' ;
    wkCity = %trim(SC_CITY) + '%';
    if SC_STATE = ' '; // All states
        wkStateLow = ' ';
        wkStateHigh = 'ZZ';
    else;
        if %len(%trim(SC_STATE)) <> 2;
            NewSearchCriteria=*on;
            SflMsgSnt = ClrMsgPgmQ(PgmName);
            SflMsgSnt = SndSflMsg('DEM0007');
        endif;
        wkStateLow = SC_STATE;
        wkStateHigh = SC_STATE;
    endif;
    If scIncActInc = *off;  // Include just actives
        wkActiveLow = 'Y';
        wkActiveHigh = 'Y';
    else; 
        wkActiveLow = ' ';
        wkActiveHigh = 'Z';
    endif;
    // Open the Cursor
    if NewSearchCriteria = *off;
        exec sql open ItemCur 
            using :wkName,:wkCity, 
            :wkStateLow, :wkStateHigh, 
            :wkActiveLow,:wkActiveHigh;
        if SQLSTT  <> SQLSUCCESS;
            SQLProblem('Open ItemCur');
        endif;
        CursorOpen = *on;
    endif;
End-Proc ProcessSearchCriteria ;

//=== SetCursorPostion ========================================
// If Invalid Option, position screen cursor on first error,
// else postion cursor on the last valid option.
Dcl-Proc SetCursorPosition;
    if OptError = *off;
        SC_CSR_RCD=SflRRN;
    endif;
End-Proc SetCursorPosition;

//=== BldFKeyText =============================================
// Build the Function key text for the bottom of the screen.
Dcl-Proc BldFkeyText;
    //=== Text for function keys ==============================
    dcl-c F3TEXT 'F3=Exit';
    dcl-c F4TEXT 'F4=Prompt+';
    dcl-c F5TEXT 'F5=Reset';
    dcl-c F6TEXT 'F6=Add';
    dcl-c F12TEXT 'F12=Cancel';
    dcl-s F9Text char(25);

    SFT_KEYS=' ';
    SFT_KEYS = CatB(SFT_KEYS : F3TEXT);
    SFT_KEYS = CatB(SFT_KEYS : F4TEXT);
    SFT_KEYS = CatB(SFT_KEYS : F5TEXT);
    if pParmType = 'M';
        SFT_KEYS = CatB(SFT_KEYS : F6TEXT);
        Maint_OK = *on;
    endif;
    if scIncActInc = *on;
        F9Text = 'F9=Exclude Inactive';
    else;
        F9Text = 'F9=Include Inactive';
    endif;
    SFT_KEYS = CatB(SFT_KEYS : F9Text);
    SFT_KEYS = CatB(SFT_KEYS : F12TEXT);
End-Proc BldFkeyText ;

//=== CloseDownPgm ============================================
// Things to do before we issue a return to the caller
Dcl-Proc CloseDownPgm;
    CloseCursor();
    close PMTCUSTD;
    CustDsp(); // Close Window display file.
End-Proc CloseDownPgm;

//=== Init ====================================================
// Must be executed each time program is entered, because F12
// and Enter key leave with LR off.
Dcl-Proc Init;
    dcl-pi *n;
        pParmType char(1);
        pCustID like(CUSTID);     
    end-pi;

    //=== Options Text ========================================
    dcl-c OPT1TEXT '1=Select';
    dcl-c OPT2TEXT '2=Edit';
    dcl-c OPT5TEXT '5=Display';
    //=== Screen Header Text===================================
    dcl-s HdrInq like(sh_funct) inz('Inquiry');
    dcl-s HdrSelect like(sh_funct) inz('Selection');
    dcl-s HdrMaint like(sh_funct) inz('Maintenance');
    dcl-s HdrBad like(sh_funct) inz('--> Bad Parm 1 <--');

    Quit_Pgm = *off;
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
        SC_OPTIONS = OPT1TEXT;
        Opt1_OK = *on;
        SH_FUNCT = CenterStr(HdrSelect);
    endif;

    if pParmType = 'M';
        SC_OPTIONS = CatB(SC_OPTIONS : OPT2TEXT);
        SH_FUNCT = CenterStr(HdrMaint);
    endif;
    SC_OPTIONS = CatB(SC_OPTIONS : OPT5TEXT);
End-Proc Init;

//=============================================================
// ===  S u b  P r o c e d u r e s ============================
//=============================================================


//=== CatB ====================================================
// Concatenates a string to another string with a blank between.
// If the target string is all blank to start with it will not
// end up with a leading blank.
dcl-proc CatB;
    dcl-pi CatB varchar(79);
        ToStr varchar(79) value;
        AddStr varchar(79) value;
    end-pi;
    if ToStr = ' ';
        return AddStr;
    else;
        return %trimr(ToStr) + ' ' + AddStr;
    endif;
end-proc CatB;

//=== FetchNextData ===========================================
// Fetch the next row from the cursor
// Returns:        End of data Indicator:
//                   *ON   No more data, nothing returned
//                   *OFF  Data returned
//------------------------------------------------------------
dcl-proc FetchNextData;
    dcl-pi FetchNextData ind;
        TheRecd likeds(CustMast);
    end-pi;
// Local fields
    dcl-s wkEof ind inz(*off);

    exec sql fetch ItemCur into
                             :TheRecd.NAME,
                             :TheRecd.CITY,
                             :TheRecd.STATE,
                             :TheRecd.ZIP,
                             :TheRecd.ACTIVE,
                             :TheRecd.CUSTID
                        ;
    select;
        when SQLSTT = SQLSUCCESS;
            wkEof = *off;
        when SQLSTT = SQLNOMOREDATA;
            wkEof = *on;
        Other;
            SQLProblem('Fetch ITEMCUR');
    endsl;

    RETURN wkEof;

end-proc FetchNextData;

//=== ReadByKey ===============================================
// Read the record by key into the specified data record
// using the key passed in.
dcl-proc ReadByKey;
    dcl-pi ReadByKey;
        TheKey like(custid);
        TheRecd likeds(CustMast);
    end-pi;
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
end-proc ReadByKey;

//=== BuildSFLRecd ============================================
// Builds a SFL record from the specified data record
dcl-proc BuildSflRecd;
    dcl-pi BuildSflRecd;
        CustRecd likeds(CustMast);
    end-pi;
    SF_NAME = CustRecd.NAME;
    SF_CITY = CustRecd.CITY;
    SF_STATE = CustRecd.STATE;
    SF_ZIP = CustRecd.ZIP;
      // Save Id in case we need it for 5=Display
    SF_CUST_H = CustRecd.CUSTID;
      // Change color if record is inactive
    if CustRecd.ACTIVE = 'N';
        sfInAct = *on;
    else;
        sfInAct= *off;
    endif;
      // Save Active status in case we update subfile
    SF_ACT_H = CustRecd.ACTIVE;
end-proc BuildSflRecd;

//=== CloseCursor =============================================
// Closes the SQL Cursor if open
dcl-proc CloseCursor;
    dcl-pi CloseCursor end-pi;
// Local fields
    if CursorOpen = *on;
        exec sql close ItemCur;
        if SQLSTT <> SQLSUCCESS;
            SQLProblem('Close ITEMCUR');
        endif;
        CursorOpen = *off;
    endif;
    RETURN;
end-proc CloseCursor;

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
        wkMsgFile = 'CUSTMSGF';
    ENDIF;
    if %parms > 1;
        wkMsgData = ErrMsgData;
    else;
        wkMsgData = ' ';
    ENDIF;
    wkMsgId = ErrMsgId;
    SNDMSGPGMQ(PgmName:
             wkMsgId:
             wkMsgFile:
             wkMsgData);

    retField = *on;
    RETURN retField;

end-proc SndSflMsg;

//=== SflClear ================================================
// Clears the Subfile
dcl-proc SflClear;
    dcl-pi SflClear end-pi;
    clear SflRRN;
    clear RcdsInSfl;
    scSflClr = *ON;
    write SFLCTL;
    scSflClr = *OFF;
    return;
end-proc SflClear;
