      * Sample Skeleton SQL RPG program. This is a linear main program
      * so there is no RPG cycle logic included. There is no RPG file
      * IO. Data is read with SQL. It uses an SQL Cursor, but this is
      * just one way to retrieve data with SQL.
      *
      * After *executable* SQL statements I check for the SQL States
      * that I expect. Any unexpected state causes the program to dump
      * and crash, because this requires investigation.
      * Common states are defined below in SQL State Constants.
      *
      * Your shop error handling standards may be different and you
      * may want to rewrite the SQLProblem procedure.

      * Program reads table QIWS/QCUSTCDT which is on all(?) machines.
      * Pass a two character State parameter, e.g. PARM('NY').

     h Option(*NODEBUGIO:*SRCSTMT)
     h DftActGrp(*no) ActGrp(*caller)
     h main(SQL_SKEL)

      *=== Prototypes ======================================
     d SQL_SKEL        pr                  extpgm('SQL_SKELM')
     d                                2a

     d SQLProblem      pr
     d piSQLDebug                  1024    varying value

     D SndEscMsg       pr
     D piMsg                       1024a   Const Varying

     D QMHSNDPM        pr                  ExtPgm('QMHSNDPM')
     D  piMsgId                       7a   Const
     D  piMsgFile                    20a   Const
     D  piMsgData                  1024a   Const OPTIONS(*varsize)
     D  piMsgDataLgth                10i 0 Const
     D  piMsgType                    10a   Const
     D  piCallStk                    10a   Const
     D  piRelCallStk                 10i 0 Const
     D  piRtnMsgKey                   4a
     D  apiErrorDS                   17a

      *=== SQL State Constants =============================
     d SQLSuccess      c                   '00000'
     d SQLNoData       c                   '02000'
     d SQLNoMoreData   c                   '02000'
     d SQLDupRecd      c                   '23505'
     d SQLRowLocked    c                   '57033'
      /free

      *=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
      *    Main Program                                    =
      *=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
     p SQL_SKEL        B
     d                 PI
     d piState                        2a

      *=== Program (Global) Variables ======================
     d InTbl         e ds                  EXTNAME('QIWS/QCUSTCDT') template

     d MyCusnum        s                   like(cusnum)
     d MyLstNam        s                   like(lstnam)
     d MyInit          s                   like(init)
     d MyState         s                   like(state)
     d MyBalDue        s                   like(baldue)
     d RecordsRead     s              7p 0 Inz(0)

      *=== Set SQL Options ===============================
      * Note: Compile time only.  Not executable.
       exec sql set option datfmt=*iso,
                           closqlcsr=*endmod,
                           commit=*none;
      *=== Cursor ========================================
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
      *=== Initialization ================================
       exec sql open  DemoCursor;
       if SQLSTT <> SQLSuccess;
           SQLProblem('open DemoCursor');
       endif;
      *=== Main Logic ====================================
       exsr FetchCur;
       dow SQLSTT = SQLSuccess;
              RecordsRead += 1;
           // Real program logic goes here <<<<<<<<<<
           exsr FetchCur;
       enddo;
      *=== Termination ===================================
       dsply ('Records read: ' + %char(RecordsRead) );
       exec sql close DemoCursor;
       if SQLSTT <> SQLSuccess;
           SQLProblem('close DemoCursor');
       endif;
       *inlr = *on;

      *=== Subroutines ===================================

      *--- FetchCur --------------------------------------
      * Get the next row from the cursor
      * Returns: SQLSUCCESS, with data
      *          SQLNoMoreData, no data returned
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

      /end-free
     p SQL_SKEL        e
      *=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
      *    End of Main Program                             =
      *=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

      *=== Procedures ======================================

      *=== SQLProblem ======================================
      * For those "Never should happen" SQL errors.
      * Issues DUMP(A) to dump memory, then ends program by
      * sending an *ESCAPE message of the supplied debugging text.
     p SQLProblem      B
     d SQLProblem      PI
     d piSQLDebug                  1024    varying value

      *--- Local Variables ---------------------------------
     d wkSQLDebug      s           1024    varying

      /free
       wkSQLDebug = 'Unexpected SQL error in: ' + piSQLDebug;
       dump(a);
       SndEscMsg(wkSqlDebug);
       return;
      /end-free
     p SQLProblem      E

      *=== SndEscMsg =======================================
      * Sends CPF9898 Escape message of the provided text.
     P SndEscMsg       B                   Export

     D SndEscMsg       PI
     D piMsg                       1024a   Const Varying

      *--- Parameters for QMHSNDPM -------------------------
     D MsgId           c                   const('CPF9898')
     d MsgF            c                   const('QCPFMSG   *LIBL     ')
     d MsgType         c                   const('*ESCAPE   ')
     d PgmQue          c                   const('*         ')
     d InvCount        c                   const(2)
     d ApiError        s             17a   inz(X'00')
     d RetMsgKey       s              4a
     D DataLen         s             10i 0

      *--- Local Variables ---------------------------------
     D MsgData         s           1024a

      /FREE
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
      /end-free
     P SndEscMsg       E

