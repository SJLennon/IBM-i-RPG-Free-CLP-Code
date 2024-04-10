**free
// Sample Skeleton SQL RPG program. This is a linear main program
// so there is no RPG cycle logic included. There is no RPG file
// IO. Data is read with SQL. It uses an SQL Cursor, but this is
// just one way to retrieve data with SQL.
//
// After *executable* SQL statements I check for the SQL States
// that I expect. Any unexpected state causes the program to dump
// and crash, because this requires investigation.
// Common states are defined below in SQL State Constants.
//
// Your shop error handling standards may be different and you
// may want to rewrite the SQLProblem procedure.

// Program reads table QIWS/QCUSTCDT which is on all(?) machines.
// Pass a two character State parameter, e.g. PARM('NY').
//-----------------------------------------------------------------
// 10/--/2021 Lennon.  This is a revised version of the original
//            SQL_SKEL program.
//            I trimmed down the code by moving the SQLProblem
//            logic into the SRV_SQL service program. The SQLProblem
//            messaging is also improved.

 ctl-opt option(*nodebugio:*srcstmt) dftactgrp(*no) actgrp(*caller)
    bnddir('SQL_BND')
    main(SQL_SKEL);

//=== Prototypes ======================================
/include ../Copy_Mbrs/SRV_SQL_P.RPGLE

//=== SQL State Constants =============================
dcl-c SQLSUCCESS    '00000';
dcl-c SQLNODATA     '02000';
dcl-c SQLNOMOREDATA '02000';
dcl-c SQLDUPRECD    '23505';
dcl-c SQLROWLOCKED  '57033';

//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
//    Main Program                                    =
//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
dcl-proc SQL_SKEL;
  dcl-pi *n;
    piState char(2);
  end-pi;

//=== Program (Global) Variables ======================
  dcl-ds InTbl extname('QIWS/QCUSTCDT') template
  end-ds;

  dcl-s MyCusNum like(cusnum);
  dcl-s MyLstNam like(lstnam);
  dcl-s MyInit like(init);
  dcl-s MyState like(state);
  dcl-s MyBalDue like(baldue);
  dcl-s RecordsRead packed(7) inz(0);

//=== Set SQL Options ===============================
// Note: Compile time only.  Not executable.
  exec sql set option datfmt=*iso,
                     closqlcsr=*endmod,
                     commit=*none;
//=== Cursor ========================================
  exec sql declare DemoCursor cursor for
          select
                    CUSNUM,
                    LSTNAM,
                    INIT,
                    STATE,
                    BALDUE
          from      QIWS/QCUSTCDT
          where     STATE = :piState
          order by  BALDUE desc
      ;
//=== Initialization ================================
  exec sql open  DemoCursor;
  if SQLSTT <> SQLSUCCESS;
    SQLProblem('open DemoCursor');
  endif;
//=== Main Logic ====================================
  exsr FetchCur;
  dow SQLSTT = SQLSUCCESS;
    RecordsRead += 1;
     // Real program logic goes here <<<<<<<<<<
    exsr FetchCur;
  enddo;
//=== Termination ===================================
  dsply ('Records read: ' + %char(RecordsRead) );
  exec sql close DemoCursor;
  // ---- Deliberate bug to exercise SQLProblem -----
  exec sql close DemoCursor;
  // ------------------------------------------------
  if SQLSTT <> SQLSUCCESS;
    SQLProblem('close DemoCursor');
  endif;
  *inlr = *on;
//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
//    End of Main Program                             =
//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

//=== Subroutines ===================================

//--- FetchCur --------------------------------------
// Get the next row from the cursor
// Returns: SQLSUCCESS, with data
//          SQLNoMoreData, no data returned
  begsr FetchCur;
    exec sql fetch DemoCursor into
                :MyCusNum,
                :MyLstNam,
                :MyInit,
                :MyState,
                :MyBalDue
      ;
    if SQLSTT <> SQLSUCCESS
      and SQLSTT <> SQLNOMOREDATA;
      SQLProblem('fetch DemoCursor');
    endif;
  endsr;

end-proc;
