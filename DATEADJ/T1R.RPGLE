**free
ctl-opt DftActGrp(*NO) ActGrp(*new) option(*nodebugio: *srcstmt)
main(Main);
ctl-opt BndDir('UTIL_BND');
/COPY ../Copy_Mbrs/SRV_MSG_P.RPGLE
/COPY ../Copy_Mbrs/PRT_P.RPGLE

dcl-proc Main;

  // CL pgm that executes DATEADJ command
  dcl-pr datet extpgm('T1C');
    indate char(10);
    indays packed(5:0);
    inType char(7);
    inFmt char(10);
    outFmt char(10);
    outDate char(10);
    outEsc char(100);
  end-pr;

  dcl-s indate  char(10);
  dcl-s days    packed(5:0);
  dcl-s inType  char(7);
  dcl-s inFmt     char(10);
  dcl-s outFmt    char(10);
  dcl-s outEsc    char(100);

  dcl-s outDate char(10);

  dcl-ds line len(132) qualified;
    inFmt   char(10);
    *n      char(1);
    indate  char(10);
    *n      char(1);
    days    char(5);
    *n      char(1);
    inType  Char(7);
    *n      char(1);
    outDate char(10);
    *n      char(1);
    outFmt  char(10);
  end-ds;

  dcl-ds head likeds(line);
  head.inFmt = 'InFmt';
  head.indate = 'inDate';
  head.days = ' Adj';
  head.inType = 'Type';
  head.outDate = 'OutDate';
  head.outFmt = 'OutFmt';
  PRT(head :'*H1') ;

  // === Test default stuff ====
  inType = '*DAYS';
  // --------------------------------
  PRT('=== Testing SYSTEM date') ;
  days = 1;
  indate = '*SYSTEM';
  inFmt = '*JOBFMT';
  outFmt = '*INFMT';
  exsr doit;
  outFmt = '*MDY';
  exsr doit;
  inFmt = '*LONGJUL';
  exsr doit;
  outFmt = '*ISO';
  exsr doit;

  // --------------------------------
  PRT('=== Testing date: *JOBDATE');
  indate ='*JOBDATE';
  inFmt = '*JUL';
  outFmt = '*INFMT';
  exsr doit;
  outFmt = '*EUR';
  exsr doit;
  days =-1;
  exsr doit;
  days = 0;
  exsr doit;

  // == Test all input formats
  PRT(' ' : '*NEWPAGE');
  PRT('=== Testing Input formats ===');
  days = 1;
  outFmt = '*ISO';
  // -------------------------------
  indate = '99/12/31';
  inFmt = '*YMD';
  exsr doit;
  // -------------------------------
  indate = '12/31/99';
  inFmt = '*MDY';
  exsr doit;
  // -------------------------------
  indate = '31/12/99';
  inFmt = '*DMY';
  exsr doit;

  // -------------------------------
  indate = '991231';
  inFmt = '*YMD0';
  exsr doit;
  // -------------------------------
  indate = '123199';
  inFmt = '*MDY0';
  exsr doit;
  // -------------------------------
  indate = '311299';
  inFmt = '*DMY0';
  exsr doit;

  // -------------------------------
  indate = '099/12/31';
  inFmt = '*CYMD';
  exsr doit;
  // -------------------------------
  indate = '012/31/99';
  inFmt = '*CMDY';
  exsr doit;
  // -------------------------------
  indate = '031/12/99';
  inFmt = '*CDMY';
  exsr doit;
  // -------------------------------
  indate = '0991231';
  inFmt = '*CYMD0';
  exsr doit;
  // -------------------------------
  indate = '0123199';
  inFmt = '*CMDY0';
  exsr doit;
  // -------------------------------
  indate = '0311299';
  inFmt = '*CDMY0';
  exsr doit;

  // -------------------------------
  indate = '1999-12-31';
  inFmt = '*ISO';
  exsr doit;
  // -------------------------------
  indate = '12/31/1999';
  inFmt = '*USA';
  exsr doit;
  // -------------------------------
  indate = '31.12.1999';
  inFmt = '*EUR';
  exsr doit;
  // -------------------------------
  indate = '1999-12-31';
  inFmt = '*JIS';
  exsr doit;

  // -------------------------------
  indate = '19991231';
  inFmt = '*ISO0';
  exsr doit;
  // -------------------------------
  indate = '12311999';
  inFmt = '*USA0';
  exsr doit;
  // -------------------------------
  indate = '31121999';
  inFmt = '*EUR0';
  exsr doit;
  // -------------------------------
  indate = '19991231';
  inFmt = '*JIS0';
  exsr doit;

  // -------------------------------
  indate = '99/365';
  inFmt = '*JUL';
  exsr doit;

  // -------------------------------
  indate = '1999/365';
  inFmt = '*LONGJUL';
  exsr doit;
  // -------------------------------
  indate = '03/17/21';
  inFmt = '*SYSTEM';
  days =31;
  exsr doit;
  // -------------------------------
  indate = '03/21/21';
  inFmt = '*JOBFMT';
  days =61;
  exsr doit;


  // === Test all output formats ===
  PRT(' ' : '*NEWPAGE');
  PRT('=== Testing Output formats ===');
  days = 1;
  // -------------------------------
  indate = '03/17/21';
  inFmt = '*JOBFMT';
  exsr doit;
  // -------------------------------
  indate ='24/02/28';
  inFmt = '*YMD';
  outFmt = '*YMD';
  exsr doit;
  // -------------------------------
  outFmt = '*MDY';
  exsr doit;
  // -------------------------------
  outFmt = '*DMY';
  exsr doit;
  // -------------------------------
  indate ='24/02/28';
  inFmt = '*YMD';
  outFmt = '*YMD0';
  exsr doit;
  // -------------------------------
  outFmt = '*MDY0';
  exsr doit;
  // -------------------------------
  outFmt = '*DMY0';
  exsr doit;

  // -------------------------------
  days = 2;
  indate ='80/02/28';
  inFmt = '*YMD';
  outFmt = '*CYMD';
  exsr doit;
  // -------------------------------
  outFmt = '*CMDY';
  exsr doit;
  // -------------------------------
  outFmt = '*CDMY';
  // -------------------------------
  exsr doit;
  outFmt = '*CYMD0';
  exsr doit;
  // -------------------------------
  outFmt = '*CMDY0';
  exsr doit;
  // -------------------------------
  outFmt = '*CDMY0';
  exsr doit;

  // -------------------------------
  outFmt = '*ISO';
  exsr doit;
  // -------------------------------
  outFmt = '*ISO0';
  exsr doit;

  // -------------------------------
  outFmt = '*USA';
  exsr doit;
  // -------------------------------
  outFmt = '*USA0';
  exsr doit;

  // -------------------------------
  outFmt = '*EUR';
  exsr doit;
  // -------------------------------
  outFmt = '*EUR0';
  exsr doit;

  // -------------------------------
  outFmt = '*JIS';
  exsr doit;
  // -------------------------------
  outFmt = '*JIS0';
  exsr doit;

  // -------------------------------
  outFmt = '*JUL';
  exsr doit;
  // -------------------------------
  outFmt = '*LONGJUL';
  exsr doit;
  // -------------------------------
  outFmt = '*SYSTEM';
  exsr doit;
  // -------------------------------
  outFmt= '*ISO';
  inFmt = '*MDY';
  indate = '03/01/80';
  days = -2;
  exsr doit;
  days = -1;
  exsr doit;
  // -------------------------------
  indate = '03/17/21';
  outFmt = '*JOBFMT';
  exsr doit;
  // -------------------------------
  days = 0;
  inFmt = '*ISO';
  indate = '1999-01-01';
  exsr doit;
  // -------------------------------
  days = 365;
  exsr doit;
  // -------------------------------

  // === Test error Handling
  PRT(' ' : '*NEWPAGE');
  PRT('=== Testing Error Handling ===');
  indate = '2039-12-31';
  days = 1;
  inFmt = '*ISO';
  outFmt = '*YMD';
  exsr doit;
  // -------------------------------
  inFmt = 'XXX';
  exsr doit;
  // -------------------------------
  inFmt = '*ISO';
  outFmt = 'YYY';
  exsr doit;
  // -------------------------------
  indate = '2039-13-31';
  outFmt = '*ISO';
  exsr doit;
  // -------------------------------
  indate = '01/01/40';
  inFmt = '*MDY';
  days = -1;
  outFmt = '*INFMT';
  exsr doit;
  // -------------------------------
  indate = '01/01/19';
  inType = '*CENTURY';
  exsr doit;

  // === Testing *MONTH
  PRT(' ' : '*NEWPAGE');
  // get first day of this month
  indate = '*JOBDATE';
  inType = '*DAYS';
  days  = 1 - %subdt(%date(udate) :*days);
  outFmt = '*INFMT';
  exsr doit;
  // get first day of last month
  indate = outDate;
  inType = '*MONTHS';
  days = -1;
  exsr doit;
  // first day of this year
  indate = '*JOBDATE';
  days  = 1 - %subdt(%date(udate) :*months);
  inType = '*MONTHS';
  exsr doit;
  // first day of last year
  indate = outDate;
  days = -1;
  inType = '*YEARS';
  exsr doit;

  return;

  begsr doit;
    datet(indate : days : inType : inFmt : outFmt : outDate : outEsc);

    line.inFmt = inFmt;
    line.indate = indate;
    evalr line.days = %trim(%char(days));
    line.inType = inType;
    line.outDate = outDate;
    line.outFmt  = outFmt;
    PRT(line);
    if (outEsc <> ' ');
      PRT('  +++ ERROR +++  Msg: ' +outEsc);
    endif;
  endsr;
end-proc;

