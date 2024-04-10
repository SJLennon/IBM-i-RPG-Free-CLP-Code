**FREE
// ====================================================================
// Contains BASE36ADD procedure to increments by 1 a Character value.
// Pass in a value and it returns the value incremtented by 1.
// ====================================================================
//  - It works on any string length up to an arbitrary 50 characters.
//    So the value must be passed in as varying character and the
//    incremented value is returned as varying character.
//  - It is the callers responsibility to ensure that if the absolute
//    maximum value is returned then some action must be taken to
//    report/handle the situation where no more values are available.
//    If called with the maximum value it will roll over to the minimum
//    value.  E.g., call  with 999 and AAA will be returned.
//  - This code is based on the 36 character set A-Z and 0-9.
//  - As coded, the sequence of the values follows the EBCDIC raw
//    sorting sequence.
//  - If a different character set is needed, e.g., you wish to omit
//    O and L because they look to much like 0 and 1, simply
//    remove them from the "From" and "To" strings.
//
// 1) CRTRPGMOD MODULE(SRV_BASE36)
// 2) CRTSRVPGM SRVPGM(SRV_BASE36) EXPORT(*ALL) TEXT('BASE36 Service Pgm')
// 3) ADDBNDDIRE BNDDIR(SRV_BASE36) OBJ((SRV_BASE36 *SRVPGM  *DEFER))

ctl-opt debug nomain option(*nodebugio: *srcstmt) ;

/include ../BASE36/BASE36_P.RPGLE

dcl-proc BASE36ADD export ;
    dcl-pi BASE36ADD varchar(50);
        PI_Value varchar(50) const; // Input value
    end-pi BASE36ADD;

dcl-s wkValue like(PI_Value);
dcl-s inx int(10);

// Ascending values of a postion is A,B,...,Y,Z,0,1,2,...,7,8,9.
dcl-c FROM 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
dcl-c TO   'BCDEFGHIJKLMNOPQRSTUVWXYZ0123456789A';

wkValue = PI_Value;
// Increment the last position in the input value. If it now is
// equal to the last character in "To" then it has rolled over,
// so move to the prior input value field and repeat.
inx = %len(PI_Value);
dow inx > 0;
    %subst(wkValue:inx:1) = %xlate(FROM:TO:%subst(wkValue:inx:1));
    // if %subst(wkValue:inx:1) <> 'A';  // Not rolled over
    if %subst(wkValue:inx:1) <> %subst(TO:%size(TO):1) ;  // Not rolled over
        leave;
    endif;
    inx -= 1;
enddo;
return wkValue;  // return incremented value
end-proc BASE36ADD;
