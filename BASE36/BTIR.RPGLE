**FREE
//====================================================================
// Interactive program to demonstrate/exercise BASE36ADD.
// Enter a value up to 20 characters. Press enter and the value + 1
// is displayed.  Each enter increments by 1 and the values roll
// up the screen.
// Not a lot of error checking.  You can see what happens if you
// enter a character that is not A-Z or 0-9.
//====================================================================

ctl-opt debug  option(*nodebugio: *srcstmt) dftactgrp(*no)
        actgrp(*caller) bnddir('SRV_BASE36')
        main(Main);
/include base36,base36_p

dcl-f   BTID    WORKSTN     INFDS(dfInfDS) Usropn;
dcl-ds dfInfDS;
    Key char(1) pos(369);
end-ds;

dcl-c   F03     x'33';
dcl-c   F05     x'35';
dcl-s   ValVar  varchar(20);
dcl-s   j       int(10);

dcl-ds  *N;     // Rolling screen fields
    Val1;
    Val2;
    Val3;
    Val4;
    val5;
    val6;
    val7;
    val8;
    val9;
    val10;
    val11;
    val12;
    val13;
    val14;
    val15;
    val16;
    val17;
    val18;
    Values  char(20) dim(18) pos(1);
end-ds;

dcl-proc Main ;
if not %open(BTID);
    open    BTID;
endif;

exsr GetVal;

dow Key <> F03;
    *in40 = *on;
    if Key = F05;
        exsr GetVal;
        iter;
    endif;

    // Roll values up the screen
    for j = 1 to %elem(Values)-1;
        Values(j) = Values(J+1);
    endfor;
    Val18 = Val;

    // Increment by 1
    valVar = %trim(val);
    valVar = BASE36ADD(ValVar);
    Val = ValVar;
    exfmt SCREEN;
enddo;

close BTID;
*inlr=*on;

// Get the starting value
begsr GetVal;
    *in40 = *off;
    Values = *blanks;
    dou Val <> *blanks;
        exfmt SCREEN;
        if Key = F03;
            return;
        endif;
    enddo;
endsr;

end-proc;
