**free
// === Test program to exercise the PRT program =====================
ctl-opt option(*srcstmt: *nodebugio) actgrp(*new) main(Main);
/COPY ../Copy_Mbrs/PRT_P.RPGLE
dcl-proc Main;
  dcl-pi Main;
    // pi_head   char(132);
  end-pi;
  dcl-s   myLine char(132);
  dcl-s   j int(10);


  // === Test without a heading
  for j = 1 to 121;
    myLine = %char(j);
    %subst(myLine :20) = %char(%timestamp());
    PRT(myLine);
  endfor;
  PRT(' ' : '*CLOSE');

  // === Test with a 4 line heading
  PRT('*** Test with 4 heading lines ***' : '*H1');
  PRT('    Indented header line 2':'*H2');
  PRT('Non-Indented header line 3 with page # & 2 spaces':'*H3:*P:S2');
  for j = 1 to 120;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ';
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Test with two headings
  PRT('<< Test with two header lines >>' : '*H1');
  PRT('++ Here is a second header(As H9!) with page # ++' : '*H9:*P');
  for j = 1 to 60;
    myLine = '<<< ' + %char(j);
    %subst(myLine :130 :3) = '>>>';
    PRT(myLine);
  endfor;
  PRT(' ' : '*CLOSE');

  // === Test with a single heading
  PRT('One header line:  This is quite a long single heading line w/ page #' : '*H1:*P');
  for j = 1 to 190;
    myLine = %char(j);
    %subst(myLine :20) = %char(%timestamp());
    PRT(myLine);
  endfor;
  PRT(' ' : '*CLOSE');

  // === Test with a 4 line heading, 2nd blank; 3rd under scored, with page num
  PRT('Test with 2nd blank, 3rd line underlined with page #, 4th blank' : '*H1');
  PRT('ABCDEFGH    ZXY ' : '*H2:s2');
  PRT('________    ___ ' : '*H5:*p:s0');
  PRT(' ':'*h8');
  for j = 1 to 70;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%time());
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Test with a 3 line heading, line 3 blank
  PRT('Test with line 3 blank' : '*H1');
  PRT('Blank header line should follow. Page # on this line. ' : '*H2:*P');
  PRT(' ' : '*H3');
  for j = 1 to 70;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Test a *NEWPAGE
  PRT('Testing a new page at line 80' : '*H1:*P');
  PRT('Section starting at line 1' : '*H2');
  for j = 1 to 150;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    if (j=80);
      PRT(' ':'*NEWPAGE');
      PRT('New Section - Line 80 is the start' :'*H2');
    endif;
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Test a *NEWPAGE - Break at overflow - 2
  PRT('Testing a new page at line 52 (overflow -2)' : '*H1:*P');
  for j = 1 to 150;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    if (j=52);
      PRT('*********** ':'*NEWPAGE');
    endif;
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Test a *NEWPAGE - Break at overflow - 1
  PRT('Testing a new page at line 53 (overflow -1)' : '*H1:*P');
  for j = 1 to 150;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    if (j=53);
      PRT(' ':'*NEWPAGE');
    endif;
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Test a *NEWPAGE - Break at overflow
  PRT('Testing a new page at line 54 (overflow)' : '*H1:*P');
  for j = 1 to 150;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    if (j=54);
      PRT(' ':'*NEWPAGE');
    endif;
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

    // === Test a *NEWPAGE - Break at overflow + 1
  PRT('Testing a new page at line 55 (overflow +1)' : '*H1:*P');
  for j = 1 to 150;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    if (j=55);
      PRT(' ':'*NEWPAGE');
    endif;
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

    // === Test a *NEWPAGE - Break at overflow + 2
  PRT('Testing a new page at line 56 (overflow +2)' : '*H1:*P');
  for j = 1 to 150;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    if (j=56);
      PRT(' ':'*NEWPAGE');
    endif;
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Test without a heading, double spaced
  for j = 1 to 121;
    myLine = %char(j);
    %subst(myLine :20) = %char(%timestamp());
    PRT(myLine : 'S2');
  endfor;
  PRT(' ' : '*CLOSE');

  // === Test with a heading, double spaced
  PRT('Double spaced test with heading and page #':'*H1:*P');
  for j = 1 to 121;
    myLine = %char(j);
    %subst(myLine :20) = %char(%timestamp());
    PRT(myLine : 'S2');
  endfor;
  PRT(' ' : '*CLOSE');

  // === Test with a heading, triple spaced
  PRT('Triple spaced test with heading and page #':'*H1:*P');
  PRT('Header line 2':'*H2');
  for j = 1 to 121;
    myLine = %char(j);
    %subst(myLine :20) = %char(%timestamp());
    if (j = 75);
      PRT('>>>>>> *** New header line 2':'*H2');
      PRT(' ':'*NEWPAGE');
    endif;
    PRT(myLine : 'S3');
  endfor;
  PRT(' ' : '*CLOSE');

  // ==== Testing errors ============================================
  // === Bad spacing contol value om H2, paging not specified
  PRT('!-!-!  Bad SP value specified in header 2, paging not specified  !-!-!' : '*H1');
  PRT('Bad SP value specified in header 2 ' : '*H2:s7');
  for j = 1 to 70;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

// === Bad spacing contol value om H2, paging specified
  PRT('!-!-!  Bad spacing contol value on H2, paging specified  !-!-!' : '*H1');
  PRT('Bad SP value specified in header 2 specified ' : '*H2:*P:s7');
  for j = 1 to 70;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Bad paging control value on H2
  PRT('!-!-!  Bad paging control value on H2  !-!-!' : '*H1');
  PRT('Bad paging value specified in header 2   ' : '*H2:*xX');
  for j = 1 to 70;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  // === Missing : after *Hn
  PRT('!-!-!  Bad paging control value on H2  !-!-!' : '*H1');
  PRT('*** Missing : in H2 *** ' : '*H2*P');
  for j = 1 to 70;
    myLine = %char(j) + ' ABCDEFGHIHJKLMNOPQRSTUVWXYZ ' + %char(%timestamp());
    PRT(myLine);
  endfor;
  PRT(' ' :'*CLOSE');

  PRT('++++  Testing Bad Contol values  ++++' : '*H1');
  PRT('Bad contol after line 30' : '*H2');
  for j = 1 to 70;
    myLine = %char(j) + '-ABCDEFGHIHJK- ' + %char(%timestamp());
    PRT(myLine);
    if (j=30);
      PRT(' ':'*Bad');
    endif;
  endfor;
  PRT(' ' :'*CLOSE');

  *inlr = *on;

end-proc;
