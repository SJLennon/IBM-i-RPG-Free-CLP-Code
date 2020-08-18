**free
// Sample Skeleton SQL RPG program. This is a linear main program
// so there is no RPG cycle logic included. There is no RPG file
// IO. Data is read with SQL. It uses an SQL Cursor, but this is
// just one way to retrieve data with SQL.
//
// After //executable// SQL statements I check for the SQL States
// that I expect. Any unexpected state causes the program to dump
// and crash, because this requires investigation.
// Common states are defined below in SQL State Constants.
//
// Your shop error handling standards may be different and you
// may want to rewrite the SQLProblem procedure.

// Program reads table QIWS/QCUSTCDT which is on all(?) machines.
// Pass a two character State parameter, e.g. PARM('NY').

 ctl-opt option(*nodebugio:*srcstmt) dftactgrp(*no) actgrp(*caller)
 main(sql_skel);

//=== Prototypes ======================================
 dcl-pr QMHSNDPM extpgm('QMHSNDPM');
  *n char(7) const;                      // MsgId
  *n char(20) const;                     // MsgFile
  *n char(1024) const options(*varsize); // MsgData
  *n int(10) const;                      // MsgDataLgth
  *n char(10) const;                     // MsgType
  *n char(10) const;                     // CallStk
  *n int(10) const;                      // RelCallStk
  *n char(4);                            //RtnMsgKey
  *n char(17);                           // apiErrorDS
 end-pr;

//=== SQL State Constants =============================
 dcl-c SQLSuccess    '00000';
 dcl-c SQLNoData     '02000';
 dcl-c SQLNoMoreData '02000';
 dcl-c SQLDupRecd    '23505';
 dcl-c SQLRowLocked  '57033';

//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
//    Main Program                                    =
//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
 dcl-proc SQL_SKEL;
 dcl-pi *n;
  piState char(2);
 end-pi;

//=== Program (Global) Variables ======================
 dcl-ds InTbl extname('QIWS/QCUSTCDT') template end-ds;

 dcl-s MyCusnum like(cusnum);
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
 if SQLSTT <> SQLSuccess;
     SQLProblem('open DemoCursor');
 endif;
//=== Main Logic ====================================
 exsr FetchCur;
 dow SQLSTT = SQLSuccess;
        RecordsRead += 1;
     // Real program logic goes here <<<<<<<<<<
     exsr FetchCur;
 enddo;
//=== Termination ===================================
 dsply ('Records read: ' + %char(RecordsRead) );
 exec sql close DemoCursor;
 if SQLSTT <> SQLSuccess;
     SQLProblem('close DemoCursor');
 endif;
 *inlr = *on;

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
 if SQLSTT <> SQLSuccess
     and SQLSTT <> SQLNoMoreData;
     SQLProblem('fetch DemoCursor');
 endif;
 endsr;

 end-proc;
//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
//    End of Main Program                             =
//=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

//=== Procedures ======================================

//=== SQLProblem ======================================
// For those "Never should happen" SQL errors.
// Issues DUMP(A) to dump memory, then ends program by
// sending an *ESCAPE message of the supplied debugging text.
 dcl-proc SQLProblem;
 dcl-pi SQLProblem;
  piSQLDebug varchar(1024) value;
 end-pi;

//--- Local Variables ---------------------------------
 dcl-s wkSQLDebug varchar(1024);

 wkSQLDebug = 'Unexpected SQL error in: ' + piSQLDebug;
 dump(a);
 SndEscMsg(wkSqlDebug);
 return;
 end-proc;

//=== SndEscMsg =======================================
// Sends CPF9898 Escape message of the provided text.
 dcl-proc SndEscMsg export ;

 dcl-pi SndEscMsg extProc(*dclcase) ;
  piMsg varchar(1024) const;
 end-pi;

//--- Parameters for QMHSNDPM -------------------------
 dcl-c MsgId const('CPF9898');
 dcl-c MsgF const('QCPFMSG   *LIBL     ');
 dcl-c MsgType const('*ESCAPE   ');
 dcl-c PgmQue const('*         ');
 dcl-c InvCount const(2);
 dcl-s ApiError char(17) inz(x'00');
 dcl-s RetMsgKey char(4);
 dcl-s DataLen int(10);

//--- Local Variables ---------------------------------
 dcl-s MsgData char(1024);

 DataLen = %len(PiMSG);
 MsgData = piMsg;
 QMHSNDPM(
          MsgId   :
          MsgF :
          MsgData :
          DataLen :
          MsgType   :
          PgmQue    :
          InvCount   :
          RetMsgKey :
          APIError);
 return ;
 end-proc;
