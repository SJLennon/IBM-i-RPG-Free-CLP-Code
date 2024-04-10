**free
//==============================================================
//=== SRV_STR service program contains procedures working
//=== with fixed length strings
//==============================================================
// CRTRPGMOD MODULE(SRV_STR)
// CRTSRVPGM SRVPGM(SRV_STR) EXPORT(*ALL)
// ADDBNDDIRE BNDDIR(UTIL_BND) OBJ((SRV_STR *SRVPGM *DEFER))

//=== CenterStr ================================================
// Return the centered string. The input string is normally
// fixed length and RPG will promote it to varying on the
// call. A varying string is returned which RPG will reset
// to fixed.

//  **********************************************************
//  *** It will also execute with a varying string input   ***
//  *** but the result probably wont't be what you expect. ***
//  *** So don't use it on a varchar string.               ***
//  **********************************************************

// Conceptual call:
//=================
// H BndDir('UTIL_BND')
//  /include ../Copy_Mbrs,SRV_STR_P.RPGLE
// d Head            S             20A   inz('Inquiry')
//       Head = CenterStr(Head);
// Notes:
// CenterStr is small, but it is convenient.
// Could add left and right justify, but...
//   Left justify is simple in RPG:
//      str = %trim(str);
//   Right justify is also simple:
//      evalr str = %trim(str);

ctl-opt nomain option(*nodebugio: *srcstmt);
/INCLUDE ../Copy_Mbrs/SRV_STR_P.RPGLE
dcl-proc CenterStr export;
    dcl-pi CenterStr varchar(256);
        InStr varchar(256) const;
    end-pi;
    dcl-s blanks varchar(256) inz;
    dcl-s trimInStr varchar(256);
    trimInStr = %trim(InStr);
    // Set length to materialize required leading blanks.
    %len(blanks) = %int((%len(InStr) - %len(trimInStr))/2);
    return  blanks + trimInStr;
end-proc;
