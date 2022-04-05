**free
// ==================================================================
// Use the DATEADJ command to invoke this program.
// Logic to add or subtract from a date with specified input and
// output formats.
// ==================================================================
// Note: ACTGRP *NEW is specified so that the activation group goes
//       away on return. This ensures that a new job date in
//       an interactive session is picked up.
//       Yes, some overhead, but I doubt if this will be noticed in
//       most CL programs.
ctl-opt option(*nodebugio: *srcstmt)
  actgrp(*new)
  main(Main);
ctl-opt BndDir('UTIL_BND');
/COPY copy_mbrs,Srv_Msg_P
dcl-pr getSpecFmts extpgm('DATEADJC');
  jobfmt char(4);
  sysvalfmt char(3);
end-pr;

dcl-proc Main;
  dcl-pi Main;
    piInDate    char(10);
    poOutDate   char(10);
    piAdj       packed(5);
    piAdjType   char(7);
    piInFmt     char(10);
    piOutFmt    char(10);
  end-pi;

  dcl-s wkInDate  like(piInDate);
  dcl-s wkInFmt   like(piInFmt);
  dcl-s wkOutFmt  like(piOutFmt);

  dcl-s JobDateFmt  char(4);
  dcl-s QDatFmt     char(3);

  dcl-s wkDate  date;

  poOutDate ='9999/99/99';

  // === Move input parameters to work variables ====================
  wkInDate = piInDate;
  wkInFmt = piInFmt;
  wkOutFmt =piOutFmt;

  // === Handle special values in and out fmts =======================
  if (piInFmt ='*JOBFMT'
      or piInFmt ='*SYSTEM'
      or piOutFmt = '*JOBFMT'
      or piOutFmt = '*SYSTEM');
    getSpecFmts(JobDateFmt:QDatFmt);
  endif;

  if (piInFmt = '*JOBFMT');
    wkInFmt = JobDateFmt;
  endif;

  if (piInFmt = '*SYSTEM');
    wkInFmt = '*' + QDatFmt;
  endif;

  if (piOutFmt = '*JOBFMT');
    wkOutFmt = JobDateFmt;
  endif;

  if (piOutFmt = '*SYSTEM');
    wkOutFmt = '*' + QDatFmt;
  endif;

  if (piOutFmt = '*INFMT');
    wkOutFmt = wkInFmt;
  endif;

  // === Handle special date values =================================
  if (piInDate = '*SYSTEM');
    wkInDate = %char(%date : *ISO);
    wkInFmt = '*ISO';  // ignore INFMT value
  endif;

  if (piInDate = '*JOBDATE');
    wkInDate =%char(%date(UDATE) :*ISO);
    wkInFmt = '*ISO';  // ignore INFMT value
  endif;

  *inlr = *on;

  // === Do the calculation and return the date =====================
  // wkInfmt & wkOutFmt control conversions.
  monitor;
    wkDate = CvtInDate(wkInDate : wkInFmt);
  on-error;
    badInDate(wkInDate : wkInFmt);
  endmon;

  select;
    when (piAdjType = '*DAYS');
      wkDate = wkDate + %days(piAdj);
    when (piAdjType = '*MONTHS');
      wkDate = wkDate + %months(piAdj);
    when (piAdjType = '*YEARS');
      wkDate = wkDate + %years(piAdj);
    other;
      SndEscMsg('ADJTYPE: '+ piAdjType + ' not supported' :4);
  endsl;

  monitor;
    poOutDate = toOutDate(wkDate : wkOutFmt);
  on-error;
    badOutDate(wkDate : piOutFmt);
  endmon;

  return;
end-proc;

// === Convert the input char string to a date =======================
dcl-proc CvtInDate;
  dcl-pi CvtInDate date;
    inChar  char(10);
    inFmt   char(10);
  end-pi;
  dcl-s outDate   date;
  select;
    when (inFmt = '*YMD');
      outDate = %date(inChar : *YMD);
    when (inFmt = '*MDY');
      outDate = %date(inChar : *MDY);
    when (inFmt = '*DMY');
      outDate = %date(inChar : *DMY);

    when (inFmt = '*YMD0');
      outDate = %date(inChar : *YMD0);
    when (inFmt = '*MDY0');
      outDate = %date(inChar : *MDY0);
    when (inFmt = '*DMY0');
      outDate = %date(inChar : *DMY0);

    when (inFmt = '*CYMD');
      outDate = %date(inChar : *CYMD);
    when (inFmt = '*CMDY');
      outDate = %date(inChar : *CMDY);
    when (inFmt = '*CDMY');
      outDate = %date(inChar : *CDMY);

    when (inFmt = '*CYMD0');
      outDate = %date(inChar : *CYMD0);
    when (inFmt = '*CMDY0');
      outDate = %date(inChar : *CMDY0);
    when (inFmt = '*CDMY0');
      outDate = %date(inChar : *CDMY0);

    when (inFmt = '*ISO');
      outDate = %date(inChar : *ISO);
    when (inFmt = '*ISO0');
      outDate = %date(inChar : *ISO0);

    when (inFmt = '*USA');
      outDate = %date(inChar : *USA);
    when (inFmt = '*USA0');
      outDate = %date(inChar : *USA0);

    when (inFmt = '*EUR');
      outDate = %date(inChar : *EUR);
    when (inFmt = '*EUR0');
      outDate = %date(inChar : *EUR0);

    when (inFmt = '*JIS');
      outDate = %date(inChar : *JIS);
    when (inFmt = '*JIS0');
      outDate = %date(inChar : *JIS0);

    when (inFmt = '*JUL');
      outDate = %date(inChar : *JUL);
    when (inFmt = '*LONGJUL');
      outDate = %date(inChar : *LONGJUL);

    other;    // Should never happen
      SndEscMsg('INFMT; ' + inFmt + ' not supported':4);
  endsl;
  return outDate;
end-proc;

// === Convert date to character =====================================
// Returns input date in format specified
dcl-proc toOutDate;
  dcl-pi toOutDate char(10);
    theDate date;
    outFmt char(10);
  end-pi;
  dcl-s   wkChar char(10);
  select;
    when (outFmt = '*YMD');
      wkChar = %char(theDate : *YMD);
    when (outFmt = '*MDY');
      wkChar = %char(theDate : *MDY);
    when (outFmt = '*DMY');
      wkChar = %char(theDate : *DMY);

    when (outFmt = '*YMD0');
      wkChar = %char(theDate : *YMD0);
    when (outFmt = '*MDY0');
      wkChar = %char(theDate : *MDY0);
    when (outFmt = '*DMY0');
      wkChar = %char(theDate : *DMY0);

    when (outFmt = '*CYMD');
      wkChar = %char(theDate : *CYMD);
    when (outFmt = '*CMDY');
      wkChar = %char(theDate : *CMDY);
    when (outFmt = '*CDMY');
      wkChar = %char(theDate : *CDMY);

    when (outFmt = '*CYMD0');
      wkChar = %char(theDate : *CYMD0);
    when (outFmt = '*CMDY0');
      wkChar = %char(theDate : *CMDY0);
    when (outFmt = '*CDMY0');
      wkChar = %char(theDate : *CDMY0);

    when (outFmt = '*ISO');
      wkChar = %char(theDate : *ISO);
    when (outFmt = '*ISO0');
      wkChar = %char(theDate : *ISO0);

    when (outFmt = '*USA');
      wkChar = %char(theDate : *USA);
    when (outFmt = '*USA0');
      wkChar = %char(theDate : *USA0);

    when (outFmt = '*EUR');
      wkChar = %char(theDate : *EUR);
    when (outFmt = '*EUR0');
      wkChar = %char(theDate : *EUR0);

    when (outFmt = '*JIS');
      wkChar = %char(theDate : *JIS);
    when (outFmt = '*JIS0');
      wkChar = %char(theDate : *JIS0);

    when (outFmt = '*JUL');
      wkChar = %char(theDate : *JUL);
    when (outFmt = '*LONGJUL');
      wkChar = %char(theDate : *LONGJUL);
    other;    // Should never happen
      SndEscMsg('OUTFMT; ' + outFmt + ' not supported':4);
  endsl;
  return wkChar;
end-proc;

// === Crash if input bad ============================================
// Standardizes the message for all input variations
dcl-proc badInDate;
  dcl-pi badInDate;
    theChar  char(10);
    theFmt   char(10);
  end-pi;
  SndEscMsg('Input date "' + %trim(theChar)
              + '" not valid or not compatible with input format "'
              + %trim(theFmt) + '"'
              :4);
end-proc;

// === Crash if incompatible output format ===========================
dcl-proc badOutDate;
  dcl-pi badOutDate;
    theDate date;
    theFmt  char(10);
  end-pi;
  SndEscMsg('Calculated date "' +%char(theDate)
            + '" is not compatible with output format "'
            + %trim(theFmt) + '"'
            :4);
end-proc;
