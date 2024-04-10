**free
//=== Tests the SHOW program (the QUILNGTX API) ====== ========
Ctl-Opt DftActGrp(*NO) ActGrp(*CALLER) option(*nodebugio: *srcstmt);
Ctl-Opt BndDir('UTIL_BND');

//=== Service Program Prototypes ==============================
/include ../Copy_Mbrs/SRV_MSG_P.RPGLE

dcl-s short1 char(30) inz('A typical short msg.');

dcl-s msg68 char(68)
    inz('This is a 68 char long field with trailing blanks');
dcl-s msg68LB char(68)
    inz('          A 68 char field with 10 leading blanks (removed) ');
dcl-s name76  char(76) inz;

dcl-s scale1 char(68)
    inz('12345678901234567890123456789012345678901234567890123456789012345678');
dcl-s scale2 char(68)
    inz('<        1         2         3         4         5         6       >');
dcl-s loong char(8192) inz(' ');
dcl-s wrap char(272) INZ(
        'This is a very very long message and wrapping +
         is expected at a suita+
         ble break point.  Like at a blank.');

show(scale1 + scale2);
show(scale1+scale2+scale1+scale2+scale1+scale2+scale1+scale2+scale1);

show(short1);

show(msg68);

msg68 = '68 bytes, with 67 & 68 non-blank';
%subst(msg68:67:2) = '<<';
show(msg68);

%subst(msg68lb:67:2) = '<<';
show(msg68LB);

name76 = 'Wrap after 68';
%subst(name76 :68) = ' A wrap!';
Show(name76);

show('This is an extemporaneous mesage');

show(wrap);

loong = '< 8192 long field of blanks. Blank lines are removed.';
%subst(loong:4096) = 'This is text starting at 4096 of the 8192 field.';
%subst(loong :8191 :1) = '>';
show(loong);

show('With a BAD message id' : 'ZZZ9999');
show('With a message id: CAE9049 (picked purely for demo purposes).' : 'CAE9049');

*inlr = *on;
