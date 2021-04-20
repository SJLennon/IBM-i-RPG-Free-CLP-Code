**FREE
//====================================================================
// Test program to exercise BASE36ADD in batch.
// Result values are written out to table BTB.
// Call with two parameters:
//  1) Starting value to increment,  e.g. '988'
//  2) Ending value, e.g. '992'
//  Examples:
//   CALL PGM(BTBR) PARM('988' '992')
//        Should write 31 records.
//   CALL PGM(BTBR) PARM('1B999999999999999998' '1CAAAAAAAAAAAAAAAAAD')
//        Should write 6 records.
// SQL error checking is functional but it is not production
// quality.  Do not copy!
//====================================================================

ctl-opt debug  option(*nodebugio: *srcstmt) dftactgrp(*no)
        actgrp(*caller) bnddir('SRV_BASE36')
        main(Main);
/include base36,base36_p

dcl-proc Main ;
dcl-pi *N extpgm('BTBR');
    pi_First char(20);
    pi_Last  char(20);
end-pi;

dcl-s wkNext varchar(50);
dcl-s wkLast varchar(50);
dcl-s count int(10) inz(0);
dcl-s msg char(52);

*inlr = *on;
exec sql set option
    datfmt=*iso,
    closqlcsr=*endmod,
    commit=*none
;
//===  Convert input parms to varchar ================================
wkNext = %trim(pi_First);
wkLast = %trim(pi_Last);

//=== Drop and recreate output Table =================================
exec sql set schema lennons1; // <-----  Change this to your library!
exec sql drop table btb;
exec sql create table btb (
    theSeq int,
    theValue varchar(50),
    constraint value_primary primary key( theValue )
);
if SQLSTATE <> '00000' and SQLSTATE <> '01567';
    dsply 'Create Table failed';
    return;
endif;
exec sql alter table btb
        add constraint seq_unique unique( theSeq )
;
if SQLSTATE <> '00000';
    dsply 'Alter Table failed';
    return;
endif;

//=== Run the Test ===================================================
dow wkNext <=  wkLast;
    wkNext = BASE36ADD(wkNext);
    count += 1;
    exec sql insert into btb values (:count, :wkNext);
    if SQLSTATE <> '00000';
        dsply 'Insert failed';
        count -= 1;
        leave;
    endif;
enddo;

msg = 'Records written: ' +%char(count);
dsply msg;
return;

end-proc;
