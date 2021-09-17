**FREE
/TITLE GETOBJUR - Get users of an object
//--------------------------------------------------------------------
// Note:
//   The QSYS2.OBJECT_LOCK_INFO SQL service is used, so this code
//   probably won't run prior to OS 7.2.
//--------------------------------------------------------------------
// Given an object and type, this program finds all jobs that have
// locks on the object.  It returns a message suitable for sending
// to the system operator and/or a file, QTEMP/GETOBJUP, which
// could be used to send messages to all interactive users of the
// object, or for some other use. Or the jobname can be copied and
// pasted into a command, e.g. wrkjob 110080/LENNONS/QPAD142626.

// This program is called from CL program GETOBJUC.

// It uses the QSYS2.OBJECT_LOCK_INFO SQL view.
// Message looks like this:
//   QIWS/QCUSTCDT *FILE is in use by 110088/LENNONS/QPAD142626.
// Or this:
//   QIWS/QCUSTCDT *FILE is in use by 191174/LENNONS/QPAD160408,
//   191550/LENNONS/CUSTLST, 191551/LENNONS/INV_UPD, 191552/LENNONS/DAILYORD
//   plus 1 more.
//--------------------------------------------------------------------
// Compile: CRTBNDRPG PGM(GETOBJUR) SRCFILE(...) DBGVIEW(*LIST)
//--------------------------------------------------------------------
// 12/00/97 LENNON  Original Writing
// 07/--/2021 Converted to **FREE and Linear module.
//            There are SQL services now that can provide similar
//            infomations, but as far as I know there is no SQL
//            interface to QWCLOBJL.  And there certainly was not in
//            1997. This code probably performs better than existing
//            SQL interfaces. For most use cases performance may not
//            be a consideration.
// 08/--/2021 Converted to use QSYS2.OBJECT_LOCK_INFO and to create the
//            GETOBJUP file with SQL.
// 09/17/2021 - Fixed member logic by uppercasing CASE values
//            - Added input parms to GETOBJUP output file.
//--------------------------------------------------------------------
ctl-opt debug option(*nodebugio: *srcstmt)
    dftactgrp(*no) actgrp(*caller)
    bnddir('UTIL_BND')
    main(Main);
//=== Prototypes =====================================================
/include DEMO,Srv_Msg_P

// Gets job type entry for this job.
// Returns:  JobType has the job type. I=interactive, B=batch, etc.
dcl-pr GetJobType extpgm('GETJOBTR');
    *n char(26); // JobName26
    *n char(1); // JobType
end-pr;

//=== Program Parameters =============================================
// Input Parameters
//   1) pObject is object name (10c) + object library (10c)
//   2) pObjType is *FILE, *DTAARA, etc., standard OS/400 type
//   3) pObjMem is the member for files, or *NONE if just want users
//           of the file.
//   4) pMsgYN is *YES to create a message.
//   5) pFileYN is *YES if file GETOBJUP is to be created in QTEMP
// Output Parameter
//   PMsgFld is where the message gets created.

//=== Global Definitions =============================================
dcl-s JobName28 char(28);   // like '580065/JOBNM/USER''
dcl-c SQLSuccess       '00000';
dcl-c SQLNoData        '02000';
dcl-c SQLNoMoreData    '02000';
dcl-c SQLProcWarning   '01548';
dcl-c SQLFileNotFound  '42704';

//====================================================================
dcl-proc Main ;

    //=== Misc Field Definitions =====================================
    dcl-s NumJobs packed(5);
    dcl-c MaxJobs const(4); //Maximum jobs for detailed reporting.
    // If you increase MaxJobs, increase the message parameter by 30 bytes
    // for each additional job.
    dcl-s JobName26 char(26);   // is name(10) User(10) number(6)

    dcl-ds JobSQLDS;            // Output data for GETOBJUP
        JobName char(10);
        JobUser char(10);
        JobNum char(6);
        JobType char(1);
        JobNM28 char(28);
        JobOBJLIB CHAR(10);
        JobOBJNAME CHAR(10);
        JobOBJTYPE CHAR(10);
        JobOBJMBR CHAR(10);
    end-ds;

    dcl-s theLibrary char(10);
    dcl-s theObject char(10);
    dcl-s j int(10);
    // ---------------------------------------------------------
    dcl-pi *n extpgm('GETOBJUR');
        pObject char(20);
        pObjType char(10);
        pObjMem char(10);
        pMsgYN char(4);
        pMsgFld char(200);
        pFileYN char(4);
    end-pi;

    //=== Code starts here ===========================================
    exec sql set option datfmt=*iso,
                     closqlcsr=*endmod,
                     commit=*none;
    // === Initialize requested outputs ===============================
    if pMsgYN='*YES';
        clear  pMsgFld;
    endif;

    if pFileYN='*YES';
        exec sql drop table qtemp.GETOBJUP;
        if SQLSTATE <> SQLSuccess and SQLSTATE <> SQLFileNotFound;
            SQLProblem('Delete GETOBJUP');
        endif;
        exec sql declare global temporary table GETOBJUP (
            OUJOBNAME char(10),
            OUJOBUSER char(10),
            OUJOBNUM char(6),
            OUJOBTYPE char(1),
            OUJOBNAME28 CHAR(28),
            OUOBJLIB CHAR(10),
            OUOBJNAME CHAR(10),
            OUOBJTYPE CHAR(10),
            OUOBJMBR CHAR(10)
        );
        if SQLSTATE <> SQLSuccess;
            SQLProblem('Declare global tempory table GETOBJUP');
        endif;
    endif;

    // Split Library/Object
    theObject = %subst(pObject:1:10);
    theLibrary = %subst(pObject:11:10);

    // Put parms in output file data structure
    JobOBJLIB = theLibrary;
    JobOBJNAME = theObject;
    JobOBJTYPE = pObjType;
    JobOBJMBR = pObjMem;


    // === Find the locks ============================================
    exec sql declare Lock_Cursor cursor for
        select distinct JOB_NAME
        from QSYS2.OBJECT_LOCK_INFO
        where SYSTEM_OBJECT_SCHEMA = :thelibrary
          and SYSTEM_OBJECT_NAME = :theobject
          and OBJECT_TYPE = :pobjtype
          and ifnull(SYSTEM_TABLE_MEMBER,' ') =
            case when :pobjtype = '*FILE' and :pobjmem <> '*ALL' then  :pobjmem
                 else ' '
            END
        order by JOB_NAME
    ;
    exec sql open Lock_Cursor ;
    if SQLSTT <> SQLSuccess;
        SQLProblem('open Lock_Cursor');
    endif;

    // Loop through the cursor, building requested outputs
    fetchNext();
    dow SQLSTT <> SQLNoData;
        NumJobs += 1;
        if pFileYN='*YES';
            // Build JobName26, parm for GetJobType
            // JobName28 is  like '580065/USER/JOBNAME'
            //                     1234567890123456789
            JobNum = %subst(JobName28 :1 :6);      // Num Always 6
            j = %scan('/' : JobName28 :8);         // find 2nd '/' (j=12)
            JobUser= %subst(JobName28 :8 : j-8);   // User (lgth j-8 = 4)
            JobName = %subst(JobName28: j+1);      // Rest is Job Name
            JobName26= JobName + JobUser + JobNum;
            GetJobType(JobName26: JobType);
            exsr WriteRec;
        endif;

        if pMsgYN='*YES';
            exsr BldMsg;
        endif;

        fetchNext();
    enddo;

    // === End of Program ============================================
    if pMsgYN='*YES';
        select;
            when NumJobs >= 1 and NumJobs <=MaxJobs;
                pMsgfld=%trimr(pMsgFld) + '.';
            when NumJobs > MaxJobs;
                pMsgfld=%trimr(pMsgFld) + ' plus '
                  +  %trim(%editc(NumJobs-MaxJobs:'J'))
                  + ' more.';
            other;
        endsl;
    endif;

    *inlr=*on;

    // === BldMsg ====================================================
    // Adds current job to the message until MaxJobs have been added.
    begsr BldMsg;
        select;
            when NumJobs=1;
                pMsgFld=
                %trimr(%subst(pObject:11:10)) +'/' +
                %trimr(%subst(pObject:1:10)) + ' ' +
                %trimr(pObjType) +
                ' is in use by ' +
                JobName28;
            when NumJobs >= 2 and NumJobs <=MaxJobs;
                pMsgFld=%trimr(pMsgfld) + ', ' +
                JobName28;
        endsl;
    endsr;

    // === WriteRec ==================================================
    // Builds and writes a record to the file GETOBJUP
    begsr WriteRec;
        JobNM28 = JobName28;
        exec sql insert into qtemp.GETOBJUP values(:JobSQLDS);
        if SQLSTT <> SQLSuccess;
            sqlProblem('Insert into GETOBJUP');
        endif;
    endsr;
end-proc;

// === fetchNext =====================================================
dcl-proc fetchNext;
    exec sql fetch next from Lock_Cursor into :JobName28;
    if SQLSTT <> SQLSuccess
        and SQLSTT <> SQLNOData
        and SQLSTT <> SQLProcWarning;
        SQLProblem('fetchNext');
    endif;
end-proc;

//=== SQLProblem =====================================================
// For those "Never should happen" SQL errors.
// Issues DUMP(A) to dump memory, then ends program by
// sending an *ESCAPE message of the supplied debugging message,
// plus whatever SQL diagnostics we can fit into 512 chars.
dcl-proc SQLProblem;
    dcl-pi SQLProblem;
        piSQLDebug varchar(200) value;
    end-pi;

    //--- Local Variables ---------------------------------
    dcl-s myDebugMsg varchar(512); //Max CPF9898 supports
    dcl-s wkRem int(10);

    // Returned SQL diagnostic info
    dcl-s mySQLState CHAR(5);
    dcl-s mySQLMsgTxt varchar(32740);
    dcl-s mySQLMsgLgth int(5);

    exec sql get diagnostics condition 1
        :mySQLState = RETURNED_SQLSTATE,
        :mySQLMsgTxt = MESSAGE_TEXT,
        :mySQLMsgLgth = MESSAGE_LENGTH
    ;
    myDebugMsg =  piSQLDebug
        + ' - Unexpected SQL return: SQLSTATE='
        + mySQLState
        + '. "';

    // Fit in as much of mySQLMsgTxt as possible.
    wkRem = (%size(myDebugMsg)-2) - %len(myDebugMsg);
    if wkRem >= mySQLMsgLgth +1;
        myDebugMsg += (mySQLMsgTxt +'"');
    else;
        myDebugMsg += (%subst(mySQLMsgTxt: 1 :wkRem -5) + ' ..."');
    endif;

    dump(a);
    SndEscMsg(myDebugMsg);
    return;
end-proc;

