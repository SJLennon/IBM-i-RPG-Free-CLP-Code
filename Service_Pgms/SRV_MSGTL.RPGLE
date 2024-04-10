**FREE
//=== Tests JobLogMsg procedures in SRV_MSG service program ========
ctl-opt  option(*NoDebugIo: *SrcStmt :*NoUnref) indent(' |')
    ActGrp('QILE') DftActGrp(*no)
    BndDir('UTIL_BND')
    Main(Main);

/INCLUDE ../Copy_Mbrs/SRV_MSG_P.RPGLE

dcl-proc Main  ;
    dcl-pi *n extpgm('SRV_MSGTL');
    end-pi;

    dcl-s name      char(72) inz('Name72');
    dcl-s name73    char(73) inz;
    dcl-s name76    char(76) inz;

    dcl-s scale2 char(73) inz(
        '1234567890123456789012345678901234567890123456789012345678901234567890123');
    dcl-s scale char(73) inz(
        '         1         2         3         4         5         6         7   ');
    *inlr = *on;
    JobLogMsg(scale );
    JobLogMsg(scale2 );
    JobLogMsg(name );

    name = 'No wrap 73';
    name73 = name + 'Y';
    JobLogMsg(name73 );

    name = 'Wrap after 73';
    name76 = name + 'WRAP';
    JobLogMsg(name76 );

    // JobLogMsg(scale2 );
    // JobLogMsg(scale );

    SndInfMsg('SndInfMsg - to compare to JobLogMsg');
    JobLogMsg('JobLogMsg - to compare to SndInfMsg');
end-proc;
