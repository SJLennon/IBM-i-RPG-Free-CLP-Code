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
// -----------------------------------------------------------------
// 10/--/2021 Lennon.  This is a revised version of the original
//            SQL_SKEL program.
//            I trimmed down the code by moving the SQLProblem
//            logic into the SRV_SQL service program. The SQLProblem
//            messaging is also improved.
// 05/--/2024 Lennon. This is a revised version of SQL_SKEL2 and uses
//            procedures instead of subroutines and attempts to avoid
//            global variables.
//            I have also changed the naming approach.

ctl-opt option(*nodebugio:*srcstmt) dftactgrp(*no) actgrp(*caller)
    bnddir('SQL_BND')
    main(SQL_SKEL);

// === Prototypes ======================================
/include ../Copy_Mbrs/SRV_SQL_P.RPGLE

// === SQL State Constants =============================
dcl-c SQLSUCCESS    '00000';
dcl-c SQLNODATA     '02000';
dcl-c SQLNOMOREDATA '02000';
dcl-c SQLDUPRECD    '23505';
dcl-c SQLROWLOCKED  '57033';

// === Templates =======================================
dcl-ds InTbl extname('QIWS/QCUSTCDT') template
end-ds;

// The data returned from balanceCursor 
dcl-ds t_balancesData qualified template;
  LstNam  like(lstnam);
  Init    like(init);
  BalDue  like(baldue);
end-ds;

// =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
// === Main Program ===                                =
// =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
dcl-proc SQL_SKEL;
  dcl-pi *n;
    piState char(2);
  end-pi;

  // === Global variables ==============================
  // SQL balanceCursor returns data here.
  dcl-ds balanceData likeds(t_balancesData);

  dcl-s recordsRead packed(7) inz(0);

  // === Set SQL Options ===============================
  // Note: Compile time only.  Not executable.
  exec sql set option datfmt=*iso,
                     closqlcsr=*endmod,
                     commit=*none;
  // === Cursor ========================================
  exec sql declare balanceCursor cursor for
          select
                    LSTNAM,
                    INIT,
                    BALDUE
          from      QIWS/QCUSTCDT
          where     STATE = :piState
          order by  BALDUE desc
      ;
      
  // === Initialization ================================
  exec sql open balanceCursor;
  if SQLSTT <> SQLSUCCESS;
    SQLProblem('open balanceCursor');
  endif;

  // === Main Logic loop ===============================
  balanceFetch(balanceData);
  dow SQLSTT = SQLSUCCESS;
    recordsRead += 1;
    // >>>>>>>> Real program logic goes here <<<<<<<<<<
    // Demo code just to prove data is returned
    snd-msg *INFO 'Balance for ' + 
                  balanceData.Init + ' ' +
                  balanceData.LstNam + ': ' +
                   %char(balanceData.BalDue);
    balanceFetch(balanceData);
  enddo;

  // === Termination ===================================
  snd-msg *INFO (piState + ' records read: ' + %char(recordsRead) );
  exec sql close balanceCursor;
  if SQLSTT <> SQLSUCCESS;
    SQLProblem('close balanceCursor');
  endif;
  *inlr = *on;
  // =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
  // === End of Main Program ===                         =
  // =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
end-proc;

// =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
// === Procedures ===                                  =
// =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

// --- balanceFetch(target DS) -----------------------
// Populates a data structure defined like t_balancesData  
// with the next row from balanceCursor.
// Returns: SQLSUCCESS, with data
//          SQLNoMoreData, no data returned
dcl-proc balanceFetch;
  dcl-pi balanceFetch ;
    balDS  likeds(t_balancesData);
  end-pi;
  exec sql fetch balanceCursor into :balDS; 
  if SQLSTT <> SQLSUCCESS and SQLSTT <> SQLNOMOREDATA;
    SQLProblem('fetch balanceCursor');
  endif;
end-proc ;