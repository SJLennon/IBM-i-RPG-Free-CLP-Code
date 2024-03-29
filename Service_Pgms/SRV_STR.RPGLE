      //==============================================================
      //=== SRV_STR service program contains procedures working
      //=== with strings
      //==============================================================
      // CRTRPGMOD MODULE(SRV_STR)
      // CRTSRVPGM SRVPGM(SRV_STR) EXPORT(*ALL)
      // ADDBNDDIRE BNDDIR(UTIL_BND) OBJ((SRV_STR *SRVPGM *DEFER))

      //=== CenterStr ================================================
      // Return the centered string. The input string is normally
      // fixed length and RPG will promote it to varying on the
      // call. A varying string is returned which RPG will reset
      // to fixed if needed.
      // It will also execute with a varying string input but the
      // result may not be what you expect.
      //
      // Conceptual call:
      //=================
      // H BndDir('UTIL_BND')
      //  /include copy_mbrs,Srv_Str_P
      // d Head            S             20A   inz('Inquiry')
      //       Head = CenterStr(Head);
      // Notes:
      // CenterStr is small, but it is convenient.
      // Could add left and right justify, but...
      //   Left justify is simple in RPG:
      //      str = %trim(str);
      //   Right justify is also simple:
      //      evalr str = %trim(str);

     h nomain option(*NoDebugIo: *srcstmt)
      /include copy_mbrs,SRV_STR_P
     p CenterStr       b                   export
     d CenterStr       pi           256a   varying
     d InStr                        256a   varying const
     d
     d blanks          s            256a   varying inz
     d trimInStr       s            256a   varying
      /free
       trimInStr = %trim(InStr);
       // Set length to materialize required leading blanks.
       %len(blanks) = %int((%len(inStr) - %len(trimInStr))/2);
       return  blanks + trimInStr;
      /end-free
     p CenterStr       e
