      /title SQL UDFs to convert numeric to true dates
      //===============================================================
      // The DATE_SQL service program contains routines that are
      // registered as User Defined Functions to SQL and which
      // convert legacy numeric dates to true dates.  This makes doing
      // date arithmetic in SQL much easier.
      //
      // For example, if DSTPT is a 6-digit date in YYMMDD format, in SQL
      // you can code:
      //
      //   SELECT PNOPT FROM MVPSPRTP
      //   WHERE DATE_YMD(DSTPT) >= CURDATE() - 9O DAYS
      //
      // On alder versions of the OS,you may need to cast character dates
      // to numeric before using.
      // For example, WHERE DECIMAL(DATE_YMD(DSTPT)) >= ...
      //
      // Function included are:
      //   DATE_YMD       Accepts numeric dates in YMD format, with
      //                  either 6 or 8 digits.
      //   DATE_MDY       Accepts numeric dates in MDY format, with
      //                  either 6 or 8 digits.
      //   DATE_CYMD      Accepts 7 digit numeric dates. If the 1st
      //                  digit is 0 then it is in the 1900s and if
      //                  it is 1 then it is the 2000s. These are
      //                  standard IBM seven byte dates.
      //    ???????       Similar routines could be added to
      //                  accept other formats
      //
      // For YMD or MDY dates, it handles either 6 or 8 digits.
      // If the date passed is greater then 999999 then is it
      // assumed to already have the century.
      //
      // Invalid dates return a null value.  This means the UDFs will
      // not crash, but be aware that your results may be skewed if
      // you have bad data.  (Logic could be added to convert
      // "special" bad dates into some corporately acceptable value,
      // e.g., 999999 could be converted to 9999-12-31.)
      //
      // Originally coded late 1990s, before the Y2K cleanups. Since
      // tidied up and converted to free form..
      //
      // To Create
      // =========
      // 1) CRTRPGMOD MODULE(DATE_SQL) SRCFILE(DATE_UDF)
      //    OPTION(*EVENTF) DBGVIEW(*SOURCE)
      // 2) CRTSRVPGM SRVPGM(DATE_SQL) EXPORT(*ALL)
      //       TEXT('DATE_SQL Service Program')
      // 3) Run the CREATE_FNSQL statements to register to SQL
      //===============================================================

     H NoMain
      //=== Prototypes ================================================
     D Date_YMD        pr
     D  NumericDate                   8p 0 const
     d  RealDate                       d
     D  Indicators                    5i 0 dim(1)
     D  RetInd                        5i 0
     d  SQLSTATE                      5a
     d  FuncName                    517a   varying
     d  SpecificName                128a   varying
     d  ErrText                    1000a   varying

     D Date_CYMD       pr
     D  NumericDate                   8p 0 const
     d  RealDate                       d
     D  Indicators                    5i 0 dim(1)
     D  RetInd                        5i 0
     d  SQLSTATE                      5a
     d  FuncName                    517a   varying
     d  SpecificName                128a   varying
     d  ErrText                    1000a   varying

     D Date_MDY        pr
     D  NumericDate                   8p 0 const
     d  RealDate                       d
     D  Indicators                    5i 0 dim(1)
     D  RetInd                        5i 0
     d  SQLSTATE                      5a
     d  FuncName                    517a   varying
     d  SpecificName                128a   varying
     d  ErrText                    1000a   varying

      //===============================================================
      // DATE_YMD
      // ========
      // SQL User Defined Function (UDF) converts a 6 or 8 digit
      // numeric date in YMD format to a true date.
      //
      // Returns
      // =======
      // If input date is valid, then a true date.
      // If input date is invalid, returns null with warning 01H99.

     p Date_YMD        b                   export
     d Date_YMD        pi
     d  pDateIn                       8p 0 const
     d  pDateOut                       d
     d  pIndicators                   5i 0 dim(1)
     d  pRetInd                       5i 0
     d  pSQLSTATE                     5a
     d  pFuncName                   517a   varying
     d  pSpecificName               128a   varying
     d  pErrText                   1000a   varying

      /FREE
       pRetInd = 0;
       pSQLSTATE = '00000';
       monitor;
           select;
               // === 8 digit dates, yyyymmdd =================================
               when pDateIn > 999999;
                   pDateOut = %date(pDateIn: *ISO);
               // === 6 digit dates, yymmdd ===================================
               other;
                   pDateOut = %date(pDateIn: *YMD);
           endsl;
       on-error;
           pRetInd = -1;
           pDateOut = %date('9999-01-03');
           pSQLSTATE = '01H99';
           pErrText = %char(pDateIn) + ' is not a (numeric) date';
       endmon;
       return;
      /END-FREE
     p Date_YMD        e

      //===============================================================
      // DATE_CYMD
      // =========
      // SQL User Defined Function (UDF) converts a 7 digit
      // numeric date in CYMD format to a true date.
      //
      // Returns
      // =======
      // If input date is valid, then a true date.
      // If input date is invalid, returns null with warning 01H99.

     p Date_CYMD       b                   export
     d Date_CYMD       pi
     d  pDateIn                       8p 0 const
     d  pDateOut                       d
     d  pIndicators                   5i 0 dim(1)
     d  pRetInd                       5i 0
     d  pSQLSTATE                     5a
     d  pFuncName                   517a   varying
     d  pSpecificName               128a   varying
     d  pErrText                   1000a   varying

      /FREE
       pRetInd = 0;
       pSQLSTATE = '00000';
       monitor;
           pDateOut = %date(pDateIn: *CYMD);
       on-error;
           pRetInd = -1;
           pDateOut = %date('9999-01-01');
           pSQLSTATE = '01H99';
           pErrText = %char(pDateIn) + ' is not a (numeric) date';
        endmon;
        return;
      /END-FREE
     p Date_CYMD       e

      //===============================================================
      // DATE_MDY
      // ========
      // SQL User Defined Function (UDF) converts a 6 or 8 digit
      // numeric date in MDY format to a true date.
      //
      // Returns
      // =======
      // If input date is valid, then a true date.
      // If input date is invalid, returns null with warning 01H99.

     p Date_MDY        b                   export
     d Date_MDY        pi
     d  pDateIn                       8p 0 const
     d  pDateOut                       d
     d  pIndicators                   5i 0 dim(1)
     d  pRetInd                       5i 0
     d  pSQLSTATE                     5a
     d  pFuncName                   517a   varying
     d  pSpecificName               128a   varying
     d  pErrText                   1000a   varying

      /FREE
       pRetInd = 0;
       pSQLSTATE = '00000';
       monitor;
           select;
               // === 8 digit dates, mmddyyyy =================================
               when pDateIn > 999999;
                   pDateOut = %date(pDateIn: *USA);
               // === 6 digit dates, mmddyy ===================================
               other;
                   pDateOut = %date(pDateIn: *MDY);
           endsl;
       on-error;
           pRetInd = -1;
           pDateOut = %date('9999-01-02');
           pSQLSTATE = '01H99';
           pErrText = %char(pDateIn) + ' is not a (numeric) date';
       endmon;
       return;
      /END-FREE
     p Date_MDY        e
