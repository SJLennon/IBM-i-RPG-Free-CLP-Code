**FREE
/TITLE GETOBJUR - Get users of an object
//--------------------------------------------------------------------
// Given an object and type, this program finds all jobs that have
// locks on the object.  It returns a message suitable for sending
// to the system operator and/or a file, QTEMP/GETOBJUP, which
// could be used to send messages to all interactive users of the
// object, or for some other use.
// This program is called from CL program GETOBJUC.
// It calls the QWCLOBJL (List Object Locks) API.
// Message looks like this:
//   QIWS/QCUSTCDT *FILE is in use by QPAD165916/LENNONS/167740.
// Or this:
//   QIWS/QCUSTCDT *FILE is in use by CUSTLST/LENNONS/167922,
//     DAILYORD/LENNONS/167924, INV_UPD/LENNONS/167923,
//     QPAD165916/LENNONS/167740 plus 1 more.
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
//--------------------------------------------------------------------
ctl-opt debug option(*nodebugio: *srcstmt)
    dftactgrp(*no) actgrp(*caller)
    main(Main);
dcl-f GETOBJUP usage(*output) usropn block(*yes);
/copy USPHDR
//=== CRTUSRSPC (QUSCTRUS) Parameters ================================
dcl-ds *n;
    CusQName char(20);
    CusName char(10) overlay(cusqname) inz('GETOBJUSR');
    CusLib char(10) overlay(cusqname:11) inz('QTEMP');
end-ds;
dcl-s CusAttr char(10) inz('GETOBJUSR ');
dcl-s CusIntSize int(10);
dcl-s CusIntVal char(1) inz(x'00');
dcl-s CusAut char(10) inz('*CHANGE');
dcl-s CusText char(50) inz('GETOBJUSR Command');
//=== Send Pgm Message (QMHSNDPM) Parameters =========================
dcl-s MSNMsgId char(7);
dcl-s MSNFile char(20) inz('QCPFMSG   *LIBL     ');
dcl-s MSNData char(1);
dcl-s MSNLength int(10);
dcl-s MSNType char(10) inz('*ESCAPE');
dcl-s MSNStackE char(10) inz('*CTLBDY');
dcl-s MSNStackC int(10) inz(1);
dcl-s MSNMsgKey char(4);
//=== List Object Locks List Entry Layout ============================
dcl-ds LOLEntry based(loptr);
    LOJobName char(10);
    LOJobUser char(10);
    LOJobNum char(6);
    LOLckState char(10);
    LOLckStus int(10);
    LOLckType int(10);
    LOMemName char(10);
    LOShare char(1);
    LOReserved char(1);
end-ds;
dcl-s LOPtr pointer inz(*null);
dcl-s LOEndPtr pointer inz(*null);
//=== API Error Code Structure =======================================
dcl-ds APIError len(272);
    APIEProv int(10) inz(216) pos(1);
    APIEAvail int(10) inz(0) pos(5);
    APIErrID char(7) pos(9);
    APIErrRsv char(1);
    APIEData char(256);
end-ds;
//=== Misc Field Definitions =========================================
dcl-s LolFmt char(8) inz('OBJL0100');
dcl-s ObjMEM char(10);
dcl-s NumJobs packed(5);
dcl-c MaxJobs const(4); //Maximum jobs for detailed reporting.
// If you increase MaxJobs, increase the message parameter by 30 bytes
// for each additional job.
dcl-ds JobName26;
    SavJobName like(lojobname);
    SavJobUser like(lojobuser);
    SavJobNum like(lojobnum);
end-ds;
dcl-s Jobname28 char(28);
dcl-s JobType char(1);
//=== Parameters for SRTUSRSPC =======================================
// SKeyStart - Array of key starting positions
// SKeyLgth  - Array of key lengths
// SKeyAorD  - Array of ascending/descending sequences
// SKeyType  - Array of key field data types.
dcl-s SKeyStart packed(5) dim(10); // start position
dcl-s SKeyLgth packed(5) dim(10); // lengths
dcl-s SKeyAorD char(1) dim(10); // ascend/descend
dcl-s SKeyType char(1) dim(10); // data type
dcl-s S#Keys packed(3) inz(3);
dcl-s SError char(1);
//=== Program Entry and Parameters ===================================
dcl-proc Main ;
// Input Parameters
//   pObject is object name (10c) + object library (10c)
//   pObjType is *FILE, *DTAARA, etc., standard OS/400 type
//   pObjMem is the member for files, or *NONE if just want users
//           of the file.
//   pMsgYN is *YES to create a message.
//   pFileYN is *YES if file GETOBJUP is to be created in QTEMP
// Output Parameter
//   PMsgFld is where the message gets created.
// ---------------------------------------------------------
    dcl-pi *n extpgm('GETOBJUR');
        pObject char(20);
        pObjType char(10);
        pObjMem char(10);
        pMsgYN char(4);
        pMsgFld char(200);
        pFileYN char(4);
    end-pi;
    //------------------------------------------------------
    dcl-pr ListObjLck extpgm('QWCLOBJL');
        *n char(20);  // CusQName
        *n char(8);   // LolFmt
        *n char(20);  // pObject
        *n char(10);  // pObjType
        *n char(10);  // ObjMem
        *n char(272); // APIError
    end-pr;
    //------------------------------------------------------
    // Gets job type entry for this job.
    // Returns:  JobType has the job type. I=interactive, B=batch, etc.
    dcl-pr GetJobType extpgm('GETJOBTR');
        *n char(26); // JobName26
        *n char(1); // JobType
    end-pr;
    //------------------------------------------------------
    dcl-pr p_srtusrspc extpgm('SRTUSRSPC');
        *n char(10);  // CusName
        *n char(10);  // CusLib
        *n packed(3); // S#keys
        *n packed(5) dim(10); // KeyStart
        *n packed(5) dim(10); // KeyLgth
        *n char(1) dim(10);   // Key A or D
        *n char(1) dim(10);   // SKeyType
        *n char(1); // SError
    end-pr;
    //------------------------------------------------------
    dcl-pr SendMsg extpgm('QMHSNDPM');
        *n char(7);   // MSNMsgId
        *n char(20);  // MSNFile
        *n char(256); // APIEData
        *n int(10);   // MSNLength
        *n char(10);  // MSNType
        *n char(10);  // MSNStackE
        *n int(10);   // MSNStackC
        *n char(4);   // MSNMsgKey
        *n char(272); // APIError
    end-pr;
    //------------------------------------------------------
    dcl-pr UsrSpcCrt extpgm('QUSCRTUS');
        *n char(20); // CusQName
        *n char(10); // CusAttr
        *n int(10);  // CusIntSize
        *n  char(1); // CusIntVal
        *n char(10); // CusAut
        *n char(50); // Custext
    end-pr;
    //------------------------------------------------------
    dcl-pr UsrSpcDlt extpgm('QUSDLTUS');
        *n char(20); // CusQName
        *n char(272); // APIError
    end-pr;
    //------------------------------------------------------
    dcl-pr UsrSpcPointer extpgm('QUSPTRUS');
        *n char(20); // CusQName
        *n pointer;  // UspPtr
    end-pr;

    //=== Code starts here ===========================================
    exsr Initialize;
    //=== List the Object Locks ======================================
    // Object type should be *NONE if not a file.
    if pObjType='*FILE';
        ObjMem=pObjMem;
    else;
        ObjMem='*NONE';
    endif;
    APIEProv=0;
    ListObjLck(
            CusQName:
            LolFmt:
            pObject:
            pObjType:
            ObjMem:
            APIError);
    exsr srtusrspc;
    // === Main Program Loop =========================================
    // Loop through the entries in the list
    exsr NxtJob;
    dow LOPtr <> *NULL;
        if pFileYN='*YES';
            GetJobType(JobName26: JobType);
            exsr WriteRec;
        endif;
        if pMsgYN='*YES';
            exsr BldMsg;
        endif;
        exsr NxtJob;
    enddo;
    // === End of Program ============================================
    if pFileYN='*YES';
        close GETOBJUP;
    endif;
    if pMsgYN='*YES';
        select;
            when NumJobs >= 1 and NumJobs <=MaxJobs;
                pMsgfld=%trimr(pMsgFld) + '.';
            when NumJobs > MaxJobs;
                pMsgfld=%trimr(pMsgFld) + ' plus ' +
                %trim(%editc(NumJobs-MaxJobs:'J'))  +
                ' more.';
            other;
        endsl;
    endif;
    *inlr=*on;
    // === NxtJob ====================================================
    // A job can have more than one lock on an object. We just want a
    // job once.
    // Sets LOPtr to the first entry, or to the next different entry.
    // LOPtr assumed to be *NULL on first call.
        // Returns:  LOPtr=*NULL if no more entries.
        // NumJobs=number of unique jobs so far
    begsr NxtJob;
        select;
            when LOPtr=*NULL;
                if UspLst#Ent > 0;
                    LOPtr=UspPtr+UspLstOfs;
                    LOEndPtr=LOPtr+(UspLst#Ent*UspLstEntSz);
                    NumJobs=0;
                    exsr SavJobInf;
                endif;
            other;
                LOPtr=LOPtr+UspLstEntSz;
                dow LOPtr < LOEndPtr
                    and SavJobName=LOJobName
                    and SavJobUser=LOJobUser
                    and SavJobNum=LOJobNum ;
                    LOPtr=LOPtr+UspLstEntSz;
                enddo;
                if LOPtr < LOEndPtr;
                    exsr SavJobInf;
                else;
                    LOPtr=*NULL;
                endif;
        endsl;
    endsr;
    // === BldMsg ====================================================

    // Adds current job to the message until MaxJobs have been added.
    begsr BldMsg;
        JobName28=%trimr(SavJobName) + '/' +
        %trimr(SavJobUser) + '/' +
        SavJobNum;
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
    // === SavJobInf =================================================
        // Saves current job indentification information and counts
        // number of unique jobs found.
    // LOPtr must be initialized.
    begsr SavJobInf;
        NumJobs=NumJobs+1;
        SavJobName=LOJobName;
        SavJobUser=LOJobUser;
        SavJobNum=LOJobNum;
    endsr;
    // === WriteRec ==================================================

    // Builds and writes a record to the file GETOBJUP
    // LOPtr must be initialized.
    begsr WriteRec;
        OUJOBNAME=LOJobname;
        OUJOBUSER=LOJobUser;
        OUJOBNUM=LOJobNum;
        OUJOBTYPE=JobType;
        write GETOBJU;
    endsr;
    // === Sort User Space ===========================================

    begsr SrtUsrSpc;
        p_SRTUSRSPC(
            CusName:
            CusLib:
            S#keys:
            SKeyStart:
            SKeyLgth:
            SKeyAorD:
            SKeyType:
            SError);
    endsr;
    // ===============================================================
    // === Initialization ============================================
    begsr Initialize;
        // === Delete the User Space =================================
        APIEProv=%LEN(APIError);
        UsrSpcDlt(CusQName: APIError);
        // If user space doesn't exist, accept message CPF2105, else
        // something nasty is wrong - pass escape message back.
        if APIEAvail <> 0
            and APIErrId <> 'CPF2105';
            APIEProv=0;
            MSNMsgId=APIErrId;
            MSNLength=APIEAvail-16;
            SendMsg(
                MSNMsgId:
                MSNFile:
                APIEData:
                MSNLength:
                MSNType:
                MSNStackE:
                MSNStackC:
                MSNMsgKey:
                APIError);
        endif;
        // === Create User Space =====================================
        // Allow for 100,000 entries, which should be more than enough
        APIEProv = 0;
        CusIntSize=%size(UspHdr) + (%size(LOLentry)*100000);
        UsrSpcCrt(
            CusQName:
            CusAttr:
            CusIntSize:
            CusIntVal:
            CusAut:
            Custext);
        // === Get Pointer to User Space =============================
        UsrSpcPointer(CusQName: UspPtr);
        // === Initialize requested outputs ==========================
        if pFileYN='*YES';
            open GETOBJUP;
        endif;
        if pMsgYN='*YES';
            clear  pMsgFld;
        endif;
        // === Set SRTUSRSPC paremeters ==============================
        SKeyStart(1)=1;
        SKeyStart(2)=11;
        SKeyStart(3)=21;
        SKeyLgth(1)=10;
        SKeyLgth(2)=10;
        SKeyLgth(3)=6;
        SKeyAorD(1)='A';
        SKeyAorD(2)='A';
        SKeyAorD(3)='A';
        SKeyType(1)='C';
        SKeyType(2)='C';
        SKeyType(3)='C';
    endsr;
end-proc;
