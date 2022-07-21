**free
// ==================================================================
// PRT: A program that prints a report by printing a line at a time.
// A convenience routine for simple reports, since O-SPECs are not
// supported in **FREE RPG programs. It avoids having to create an
// externally defined printer file.
// ==================================================================
// Parms:
//
// 1) Char(132) Line text. (Or blank for certain control cases.)
//
// 2) Char(10)  Control field. Optional.
//    blank     Parm 1 contains the line to be printed with
//              single spacing.
//    Line control: How to print Parm 1:
//    S1       Space one line and print.
//             Omitted or blank is the same as S1.
//    S2       Space two lines and print.
//    S3       Space three lines and print.
//    S0       Overprint current line.
//
//    Definitions - no line are printed with this call.
//    *Hn       Define heading line "n", where n is 1 to 9
//              Parm 1 can be all blanks to print a blank line
//              heading line.
//    *Hn:Sx    Define heading line "n", where n is 1 to 9 and
//              "x" is the number of lines to space, where
//              x is 0 to 3. S0 will overprint prior line.
//    *Hn:*P:Sx Page number will be printed at the end of this
//              header line.
//
//    Special control funtions - no line is printed.
//    *NEWPAGE  Next line will print on a new page.
//              Parm 1 is ignored.

//    *CLOSE    Close the print file.
//              Parm 1 is ignored.

// ==================================================================
ctl-opt option(*srcstmt: *nodebugio)
        actgrp(*caller)
        main(Prt);

// ==================================================================
// === Program defined print file. ==================================
dcl-f MYPRT printer(133)  usropn oflind(*in99) extfile('MYPRT');
// Change extfile above to use another *FCFC print file.

// === Global Constants =============================================
dcl-c   SP0   'S0';   // Overprint
dcl-c   SP1   'S1';   // Space 1 & print
dcl-c   SP2   'S2';   // Space &2 print
dcl-c   SP3   'S3';   // Space 3 and print
dcl-c   TOP   'SK1';  // Skip to top and print
dcl-c   PAGELINE '*P';  // Header line has page #

// ==================================================================
// ===Prt procedure =================================================
dcl-proc Prt;
  dcl-pi Prt;
    pi_line   char(132);    // Line text
    pi_ctl    char(10);     // Control
  end-pi;

  // Data structure template for write to printer file
  dcl-ds  lines  qualified template;
    line char(132)    inz;
    isHdr   ind       inz;
    isPage  ind       inz;
    Ctl     char(2)   inz(SP1);
  end-ds;

  dcl-s   j           int(10);
  dcl-s   pageNumC    char(8);
  dcl-s   wk_Ctl      like(pi_ctl);
  dcl-ds  wkLn        likeds(lines);  // header line with page num
  dcl-s   headerSkip  ind;
  dcl-s   gotHeaders  ind;
  dcl-s   ctlValues   varchar(4) dim(*auto : 3); // Values split from Ctl

  // Array of Valid Spacing control chars.
  dcl-ds vs qualified;
    s1 char(3) inz('  ');
    *n char(3) inz(SP0);
    *n char(3) inZ(SP1);
    *n char(3) inZ(SP2);
    *n char(3) inZ(SP3);
    validSpaces char(3) dim(5) samepos(s1);
  end-ds;

  // Static fields: These need to be retained across calls
  dcl-ds hdrs likeds(lines) dim(9)  static; // Up to 9 header lines
  dcl-s  newPage    ind inz(*on)    static; // First page is a new page
  dcl-s  pageNum    packed(5)       static inz(1);

  // === Open printer file ===
  if (not %open(MYPRT));
    open MYPRT;
  endif;

  // ================================================================
  // === Main processing logic ======================================
  select;
    // A non-printing control function
    when (%parms = 2 and %subst(pi_ctl :1 :1) = '*');
      exsr doControl;
    // Print with a control
    when (%parms = 2);
      wk_Ctl = pi_ctl;
      exsr doPrint;
    // Print without a control -  default space 1
    when (%parms = 1);
      wk_Ctl = SP1;
      exsr doPrint;
    other;
      PrtLn('>>1>>>>>> Error: Called with missing/incorrect parmaters':SP1);
  endsl;
  return;

  // ================================================================
  // === Non-printing control functions =============================
  begsr doControl;
    wk_Ctl = %upper(pi_ctl);
    select;
      // Force a new page if next line won't be a new page
      when (pi_ctl = '*NEWPAGE');
        newPage = *on;

      // Handle closing the report
      when (pi_ctl = '*CLOSE');
        if (%open(MYPRT));
          close MYPRT;
        endif;
        // Reset static in case called again from same activation group
        reset newPage;
        reset pageNum;
        reset hdrs;
        *inlr =*on;

      // Save head line definitions
      when (%subst(wk_Ctl :1 :2) = '*H');
        // Split up the control function par,
        %elem(ctlValues) = 0;
        ctlValues = %split(wk_Ctl :':');
        // first one is *Hn, where n is 1=9
        if (%len(%trim(ctlValues(1))) > 3);
          PrtLn('>>2>>>>>> *Hn value too long: ' + %trim(pi_ctl)
              + '.  Missing ":" maybe?' : SP1);
        endif;
        j = %int(%subst(ctlValues(1) : 3 :1));
        hdrs(j).isHdr = *on;
        hdrs(j).line = pi_line;
        // Process 2nd and/or 3rd parms
        select;
          // If it is page control
          when (%elem(ctlValues) = 2);
            if (%trim(ctlValues(2)) = PAGELINE);
              hdrs(j).isPage = *on;
            else;
          // If no, should be spacing
              if (%trim(ctlValues(2)) in vs.validSpaces);
                hdrs(j).Ctl = %trim(ctlValues(2));
              else;
                PrtLn('>>3>>>>>> Space or page value is not valid: '  + %trim(pi_ctl) : SP1);
              endif;
            endif;
          // Process 2nd and 3rd parms
          when (%elem(ctlValues) = 3);
            // second must be paging
            if (%trim(ctlValues(2)) = PAGELINE);
              hdrs(j).isPage = *on;
            else;
              PrtLn('>>4>>>>>> Paging value is not valid: ' + %trim(pi_ctl) : SP1);
            endif;
            // 3rd is spacing
            if (%trim(ctlValues(3)) in vs.validSpaces);
              hdrs(j).Ctl = %trim(ctlValues(3));
            else;
              PrtLn('>5>>>>>>> Space value is not valid: ' + %trim(pi_ctl) : SP1);
            endif;
        endsl;

      other;
        PrtLn('>>7>>>>> Calling error. Control value not supported: ' + pi_ctl :SP1);
    endsl;

  endsr;

  // ================================================================
  // === Print the line =============================================
  begsr doPrint;
    select;
      // Need new page
      when  (newPage);
        exsr doHeaders;
        // If heading lines were printed, then print the line with
        // the specified spacing, else skip to a new page and print.
        If (gotHeaders);
          PrtLn(pi_Line : wk_Ctl);
        else;
          PrtLn(pi_line : TOP);
          newPage = *off;
        endif;
      // Just print the line
      other;
        PrtLn(pi_Line : wk_Ctl);
    endsl;

  // === If overflow, remember for next line ===
    if (*in99 = *on);
      newPage = *on;
      *in99 = *off;
    endif;

  endsr ;

  // ================================================================
  // === Print Headers ==============================================
  begsr doHeaders;
    if (newPage);
    // Print the Heading lines and page number.

    // No defined headers is possible.
      gotHeaders = *off;
    // Set up character page number
      pageNumC = 'Page +++';
      if (pageNum <= 999);
        pageNumC = 'Page ' + %char(pageNum);
      endif;
      // Loop through header definitions, printing those defined
      for j = 1 to 9;
        if (hdrs(j).isHdr);
          gotHeaders = *on;
          wkLn.line = hdrs(j).line;
          if (hdrs(j).isPage);
            %subst(wkLn.line :%len(wkLn.line) - %len(pageNumC) ) = pageNumC;
          endif;
          // First header line, and only the first, has to be a skip to top
          if (headerSkip = *off);
            PrtLn(wkLn.line : TOP);
            headerSkip = *on;
          else;
            PrtLn(wkLn.line : hdrs(j).Ctl);
          endif;
        endif;
      endfor;

      headerSkip = *off;
      newPage = *off;
      pageNum += 1;
    endif;
  endsr ;

end-proc Prt;

// ==================================================================
// === Procedure to print a line ====================================
dcl-proc PrtLn;
  dcl-pi PrtLn;
    pi_Line char(132) const;
    pi_Ctl  char(10) const;
  end-pi;
  dcl-ds line len(133) qualified;
  end-ds;
  // FCFC Definitions for printer file
  dcl-s SK1  char(1) inz('1');      // skip to channel 1
  dcl-s S1   char(1) inz(' ');      // space 1 and print
  dcl-s S2   char(1) inz('0');      // spacw 2 and print
  dcl-s S3   char(1) inz('-');      // Space 3 and print
  dcl-s S0   char(1) inz('+');      // Overprint (space 0)

  dcl-s fcFC char(1);

  select;
    when (pi_Ctl = SP1 or pi_Ctl = ' ');
      fcFC = S1;
    when (pi_Ctl = SP2);
      fcFC = S2;
    when (pi_Ctl = SP3);
      fcFC = S3;
    when (pi_Ctl = SP0);
      fcFC = S0;
    when (pi_Ctl = TOP);
      fcFC = SK1;
    other;
      PrtLn('>>>>>>>> Invalid spacing control: ' + pi_Ctl :SP1);
  endsl;

  // Write must be from a data structure
  line = fcFC + pi_Line;
  write MYPRT line;
end-proc PrtLn;
