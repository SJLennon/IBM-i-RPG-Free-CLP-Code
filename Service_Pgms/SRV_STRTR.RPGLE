**free
// === Test the SRV_STR service program========================

ctl-opt dftactgrp(*no) actgrp(*caller) option(*nodebugio: *srcstmt)
       bnddir('UTIL_BND');

dcl-s X1 char(1) inz('1');
dcl-s X2 char(2) inz('2 ');
dcl-s X3 char(3) inz('3  ');
dcl-s X4 char(4) inz('4   ');
dcl-s X5 char(5) inz('5    ');
dcl-s X6 char(6) inz('6     ');
dcl-s X7 char(7) inz('    7  ');
dcl-s X8 char(8) inz('   8    ');
dcl-s X0 char(5) inz('     '); // all blank
dcl-s XL char(20) inz(' 20-chars'); // longer
dcl-s XM char(21) inz(' 21-Chars'); // longer
dcl-s XV varchar(20) inz('20-vary');                // Varying-fails
dcl-s XW varchar(21) inz(' 21-vary             ');  // Varying-fails

// dcl-s l1 char(20) inz('           ABCDE  '); // Left align
// dcl-s l2 char(20) inz('Left already      '); // Left align
// dcl-s r1 char(20) inz('abc'); // Right align
// dcl-s r2 char(20) inz('   defgh  '); // Right align

/include ../Copy_Mbrs/SRV_STR_P.RPGLE
/include ../Copy_Mbrs/PRT_P.RPGLE

PRT('*** Testing SRV_STR Service Program ***' : '*H1');
CenterIt(X1);
CenterIt(X2);
CenterIt(X3);
CenterIt(X4);
CenterIt(X5);

CenterIt(X6);
CenterIt(X7);
CenterIt(X8);

CenterIt(X0);

CenterIt(XL);

CenterIt(XM);

CenterIt(XV);
CenterIt(XW);

// dsply ('---- Left Justify ---');
// dsply ('-' + l1 + '-');
// l1 =%trim(l1);
// dsply ('-' + l1 + '-');

// dsply ('-' + l2 + '-');
// l2 =%trim(l2);
// dsply ('-' + l2 + '-');

// dsply ('---- Right Justify ---');
// dsply ('-' + r1 + '-');
// evalr r1 = %trim(r1);
// dsply ('-' + r1 + '-');

// dsply ('-' + r2 + '-');
// evalr r2 = %trim(r2);
// dsply ('-' + r2 + '-');

PRT(' ' :'*CLOSE');
*inlr = *on;
return;

dcl-proc CenterIt;
    dcl-pi CenterIt;
        II varchar(50) const;
    end-pi;
    dcl-s wk varchar(50) inz;
    wk = CenterStr(II);
    %len(wk) = %len(II);
    PRT('-1234567890123456789012345');
    PRT('-' + II + '-');
    PRT('-' + wk + '-');
    return;
end-proc;
