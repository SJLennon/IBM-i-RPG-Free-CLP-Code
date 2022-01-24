**FREE
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

ctl-opt dftactgrp(*no) actgrp(*caller) option(*nodebugio: *srcstmt)
bnddir('UTIL_BND':'ADRVAL_BND') main(main);

//=== Display File =============================================
dcl-f MTNCUSTD workstn infds(dfinfds) indds(dfindds) usropn;

//=== Service Program Prototypes ===============================
/include copy_mbrs,Srv_Msg_P
/include copy_mbrs,Srv_Str_P
/include usps,USAdrVal_p

//=== Named hexadecimal constants for function keys ============
/include copy_mbrs,##AIDBYTES

//=== USAdrVal Paramter DS ======================================
/include usps,USAdrvalDS
dcl-ds AdrIn  likeds (USAdrValDS);
dcl-ds AdrOut likeds (USAdrValDS);

//=== Fields read by SQL ========================================
// NOTE: Only the fields in the SQL statement are populated!
dcl-ds CUSTMAST extname('CUSTMAST') end-ds;

//=== SQL State Constants ======================================
dcl-c SQLSUCCESS '00000';
dcl-c SQLNODATA '02000';
dcl-c SQLNOMOREDATA '02000';
dcl-c SQLDUPRECD '23505';
dcl-c SQLROWLOCKED '57033';

//=== Display File Information Data Structure ==================
//    Allows us to determine which function key was pressed
dcl-ds dfInfDS;
  Key char(1) pos(369);
end-ds;

//=== Display File Indicator Data Structure ====================
// This is a "private" indicator area for the display file.

//--- 01-20 are not automatically cleared after EXFMT ----------
dcl-ds dfIndDS len(99);

  //--- 21-99 are automatically cleared after EXFMT --------------
  Protect_SD_ALL ind pos(10);
  dfIndClr char(79) pos(21);
  RI_SD_ACTIVE ind pos(40);
  PC_SD_ACTIVE ind pos(41);
  RI_SD_NAME ind pos(42);
  PC_SD_NAME ind pos(43);
  RI_SD_ADDR ind pos(44);
  PC_SD_ADDR ind pos(45);
  RI_SD_CITY ind pos(46);
  PC_SD_CITY ind pos(47);
  RI_SD_STATE ind pos(48);
  PC_SD_STATE ind pos(49);
  RI_SD_ZIP ind pos(50);
  PC_SD_ZIP ind pos(51);
  RI_SD_ACCTPH ind pos(52);
  PC_SD_ACCTPH ind pos(53);
  RI_SD_ACCTMGR ind pos(54);
  PC_SD_ACCTMGR ind pos(55);
  RI_SD_CORPPH ind pos(56);
  PC_SD_CORPPH ind pos(57);
  DSP_SD_STAMP ind pos(61);
end-ds;

//=== Screen Header Text =======================================
dcl-s H2TextE like(sh_funct) inz('Change Customer');
dcl-s H2TextA like(sh_funct) inz('Add Customer');
dcl-s H2TextD like(sh_funct) inz('Displaying Customer');

//=== Text for function keys ===================================
dcl-c F3TEXT 'F3=Exit';
dcl-c F4TEXT 'F4=Prompt+';
dcl-c F5TEXT 'F5=Refresh';
dcl-c F12TEXT 'F12=Cancel';

//=== External Programs Prototypes =============================
dcl-pr PmtState extpgm('PMTSTATER');
  *n like(state); // TheState
end-pr;
//=== Global Switches ==========================================
dcl-c COWSCOMEHOME  const('0');
dcl-c DISPLAYING    const('D');
dcl-c EDITING       const('E');
dcl-c ADDING        const('A');

dcl-s SflMsgSnt     ind;
dcl-s Function      char(1);
dcl-s NoErrors      ind;

// === Global Fields ===========================================
dcl-s Orig_CHGTIME timestamp;

//=== Work Fields ==============================================
dcl-s wkInt int(10);
dcl-s wkMsgText varchar(256);

// === Next available customer number ==========================
dcl-s Cust_Next packed(4) dtaara('CUSTNEXT');

//=== Program Status Data Structure ============================
dcl-ds ProgStatus PSDS;
  PgmName *PROC;
  CURR_USER char(10) pos(358); // * Current user
end-ds;

dcl-s MainProc char(10);

//==============================================================
//==============================================================
// === Program Starts Here =====================================
//==============================================================

dcl-proc Main;
  dcl-pi Main;
    pID like(custid);
    pMaintain char(1);
  end-pi;


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
  dou (COWSCOMEHOME);
    select;
        // =======================================================
        // === DISPLAYING an existing Customer ===================
        // =======================================================
      when ( Function = DISPLAYING);
        exsr ReadRecd;
        if (SQLSTT = SQLNODATA);
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
      when (Function = EDITING);
        exsr ReadRecd;
        if (SQLSTT = SQLNODATA);
          SQLProblem('Calling error 2: Code passed in does not exist.');
        endif;
        exsr FillScreenFields;

        // Write/read screen until all data is valid,
        // then re-display for confirmation to update.
        dou (NoErrors);
          exsr ScreenIO;
          select;

            when (Key = F12);
              exsr CloseDownPgm;
              return;

            when (Key = F05);
              exsr ReadRecd;
              if (SQLSTT = SQLNODATA);
                // Record vanished!
                SflMsgSnt= SndSflMsg('DEM0599'); //Delete, redo search
                clear CUSTMAST;
              endif;
              NoErrors = *off;

            when (Key = F04);
              exsr F04Prompt;

            when (Key = Enter);
              exsr EditUpdData;
              if (NoErrors);
                // Re-display screen fields for confirmation
                exsr ProtectAll;
                exsr FillScreenFields;
                SflMsgSnt = SndSflMsg('DEM0000'); // Enter to update ...
                exsr ScreenIO;
                select;
                  when (Key = F12 or Key = F05);
                    // Loop again
                  when (Key = Enter);
                    exsr UpdateRecd;
                    if (NoErrors);
                      exsr CloseDownPgm; // Success! Exit program
                      return;
                    endif;
                  other;
                    SflMsgSnt = SndSflMsg('DEM0003'); // Key not active
                    NoErrors = *off;
                endsl;
              endif;
              // Open up fields for correction of errors
              exsr UnProtectAll;

            other;
              SflMsgSnt = SndSflMsg('DEM0003'); // Key not active
              NoErrors = *off;                  // Stay in dou NoErrors
          endsl;
        enddo;

        // =======================================================
        // === Adding a new Customer =============================
        // =======================================================
      when ( Function=ADDING);
        clear  CUSTMAST;
        //Default status to active
        ACTIVE = 'Y';
        exsr FillScreenFields;

        dou (NoErrors);
          // Write/read screen until all data is valid,
          // then re-display for confirmation to update.
          //All fields can be keyed
          exsr UnProtectAll;
          exsr ScreenIO;
          select;
            when (Key = F12);
              exsr CloseDownPgm;
              return;

            when (Key = F04);
              exsr F04Prompt;

            when (Key = F05);
              clear CUSTMAST;
              ACTIVE = 'Y';
              exsr FillScreenFields;

            when (Key = Enter);
              exsr EditAddData;
              if (NoErrors);
                // Re-display field for confirmation
                exsr ProtectAll;
                SflMsgSnt = SndSflMsg('DEM0009'); // Enter to add ...
                exsr FillScreenFields;
                exsr ScreenIO;
                select;
                  when (Key=F12);
                    exsr FillScreenFields;
                  when (Key = Enter);
                    exsr AddRecd;
                    if (NoErrors);
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
    into    :CUSTMAST
    from    CUSTMAST
    where   CUSTID = :pID
        ;
    if (SQLSTT <> SQLSUCCESS and SQLSTT <> SQLNODATA);
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
    if (CHGUSER <> '*SYSTEM*' and CHGUSER <> ' ');
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
      when (SD_PMT_FLD = 'SD_STATE');
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
    if (NoErrors = *off);
      leavesr;
    endif;
    // Name
    exsr Edit_SD_NAME;
    if (NoErrors = *off);
      leavesr;
    endif;
    // // Addr
    // exsr Edit_SD_ADDR;
    // if (NoErrors = *off);
    //   leavesr;
    // endif;
    // // City
    // exsr Edit_SD_CITY;
    // if (NoErrors = *off);
    //   leavesr;
    // endif;
    // // State
    // exsr Edit_SD_STATE;
    // if (NoErrors = *off);
    //   leavesr;
    // endif;
    // // ZIP
    // exsr Edit_SD_ZIP;
    // if (NoErrors = *off);
    //   leavesr;
    // endif;

    // Account Phone
    exsr Edit_SD_ACCTPH;
    if (NoErrors = *off);
      leavesr;
    endif;
    // Account Manager
    exsr Edit_SD_ACCTMGR;
    if (NoErrors = *off);
      leavesr;
    endif;
    // Corporate Phone
    exsr Edit_SD_CORPPH;
    if (NoErrors = *off);
      leavesr;
    endif;
    // Address
    exsr Edit_Address;
    if (NoErrors = *off);
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

  //=== Edit Address ===========================================
  begsr Edit_Address;
    clear AdrIn;
    AdrIn.Address2 = SD_ADDR;
    AdrIn.City = SD_CITY;
    AdrIn.State = SD_STATE;
    AdrIn.Zip5 = %subst(SD_ZIP :1 :5);

    AdrOut = USAdrVal(AdrIn);
    // Good address-copy from USPS data & return
    if (AdrOut.City <> ' ');
      ADDR = AdrOut.Address2;
      CITY = AdrOut.City;
      STATE = AdrOut.State;
      if (AdrOut.Zip4 <> ' ');
        ZIP = AdrOut.Zip5 + '-' + AdrOut.Zip4;
      else;
        ZIP = AdrOut.Zip5;
      endif;
      leavesr;
    endif;
    // Bad address-send USPS error message
    SflMsgSnt = SndSflMsg('DEM9898' : AdrOut.Description);
    NoErrors = *off;
    PC_SD_ADDR = *ON;
    RI_SD_ADDR = *ON;
    RI_SD_CITY = *ON;
    RI_SD_STATE= *ON;
    RI_SD_ZIP= *ON;
  endsr;

  //=== Edit_SD_ACTIVE==========================================
  begsr Edit_SD_ACTIVE;
    if (SD_ACTIVE = 'Y' or SD_ACTIVE = 'N');
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
    if (SD_NAME <> ' ');
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
    if (SD_ADDR <> ' ');
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
    if (SD_CITY <> ' ');
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
    if (SQLSTT = SQLSUCCESS);
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
    if (SD_ZIP <> ' ');
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
    if (SD_ACCTPH <> ' ');
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
    if (SD_ACCTMGR <> ' ');
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
    if (SD_CORPPH <> ' ');
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
    insert into CUSTMAST
    values(:CUSTMAST)
    ;
    // There is no good reason why insert should fail.
    if (SQLSTT <> SQLSUCCESS);
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
      when (SQLSTT = SQLNODATA);            // Update Failed
        SflMsgSnt = SndSflMsg('DEM1002'); // Record changed, review.
        NoErrors = *off;
        // Show the changed data
        exsr ReadRecd;
        exsr FillScreenFields;

      when (SQLSTT =SQLROWLOCKED);          // Row locked
        SflMsgSnt = SndSflMsg('DEM1001' : SQLERRMC);
        NoErrors = *off;
      when (SQLSTT = SQLSUCCESS);

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
    if (SflMsgSnt = *on);
      write MSGCTL;
    endif;

    exfmt Details;

    // Clear most display file indicators
    clear dfIndClr;

    // Clear any messages in the error subfile.
    if (SflMsgSnt = *on);
      SflMsgSnt = ClrMsgPgmQ(MainProc);
      write MSGCTL;
    endif;

  endsr;

  //=== BldFKeyText ============================================
  // Build the Function key text for the bottom of the screen.
  begsr BldFkeyText;
    SFT_KEYS=' ';
    SFT_KEYS = catB(SFT_KEYS : F4TEXT);
    SFT_KEYS = catB(SFT_KEYS : F5TEXT);
    SFT_KEYS = catB(SFT_KEYS : F12TEXT);
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
    if (%parms() = 0);     // Close down
      if (%open(MTNCUSTD));
        close MTNCUSTD;
      endif;
      *inlr = *on;
      return;
    endif;

    select;
      when ( %parms() = 1);
        Function = DISPLAYING;
      when ( %parms() >= 2);
        select;
          when ( pMaintain = ADDING);
            Function = ADDING;
            SH_FUNCT = CenterStr(H2TextA);
          when (pMaintain = EDITING);
            Function = EDITING;
            SH_FUNCT = CenterStr(H2TextE);
          other;
            Function = DISPLAYING;
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
    if (not %open(MTNCUSTD));
      open MTNCUSTD;
    endif;
  endsr;
end-proc;

//============================================================
//   S u b  P r o c e d u r e s
//============================================================

//=== CatB ===================================================
// Concatenates a string to another string with a blank between.
// If the target string is all blank to start with it will not
// end up with a leading blank.
dcl-proc catB;
  dcl-pi catB varchar(79);
    ToStr varchar(79) value;
    AddStr varchar(79) value;
  end-pi;
  if (ToStr=' ');
    return AddStr;
  else;
    return %trimr(ToStr) + ' ' + AddStr;
  endif;
end-proc;
//=== SQLProblem ===============================================
// For those "Never should happen" SQL errors.
// Issues DUMP(A) to dump memory, then ends program by
// sending an *ESCAPE message of the supplied debugging text.
dcl-proc SQLProblem;
  dcl-pi SQLProblem;
    piSQLDebug varchar(1024) value;
  end-pi;

  //--- Local Variables ------------------------------------------
  dcl-s wkSQLDebug varchar(1024);

  wkSQLDebug = 'SQLSTT ' + SQLSTT
            + ' << Unexpected SQL Return Code: '
            + piSQLDebug;
  dump(a);
  SndEscMsg(wkSQLDebug);
  return;
end-proc;

//--------------------------------------------------------------
// Procedure name: SndSflMsg
// Purpose:        Send a message to the Error Subfile
// Returns:        *ON
// Parameter:      ErrMsgId => Msg Id to Send
// Parameter:      ErrMsgData => Optional Error Message Data
// Parameter:      ErrMsgFile => Optional Error Message File
//                 Defaults to CUSTMSGF
//--------------------------------------------------------------
dcl-proc SndSflMsg;
  dcl-pi SndSflMsg ind;
    ErrMsgId char(7) const;
    ErrMsgData char(512) const options(*nopass:*varsize);
    ErrMsgFile char(10) const options(*nopass);
  end-pi;
  // Local fields
  dcl-s retField ind;
  dcl-s wkMsgId char(7);
  dcl-s wkMsgFile char(10);
  dcl-s wkMsgData varchar(512);

  if (%parms >2);
    wkMsgFile = ErrMsgFile;
  else;
    wkMsgFile = 'CUSTMSGF';
  ENDIF;
  if (%parms > 1);
    wkMsgData = ErrMsgData;
  else;
    wkMsgData = ' ';
  ENDIF;
  wkMsgId = ErrMsgId;
  SNDMSGPGMQ(MainProc:
      wkMsgId:
      wkMsgFile:
      wkMsgData);

  retField = *on;
  RETURN retField;

end-proc;
