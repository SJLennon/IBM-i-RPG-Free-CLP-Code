**free
Ctl-Opt option(*nodebugio) dftactgrp(*no) actgrp(*caller);
Dcl-F BOOTH WORKSTN;
F1=7;                 // Prime Choice 7 as first default
dow *inkc = *off;     // Loop until F3
  *in01 = not(*in01); // Flip Choice 6 off and on
  // Set choice control values
  CHGCTL1 = 0;        // Available
  CHGCTL2 = 1;        // On output means "Selected"???
  CHGCTL3 = 2;        // Unavailable except if help is available
  CHGCTL4 = 3;        // Unavailable but can place cursor
  CHGCTL5 = 4;        // Never available
  CHGCTL6 = 0;        // Available
  CHGCTL7 = 0;        // Available
  // Show the current default
  if F1 = 0;
    F3 = 'There is no default Choice';
  else;
    F3 = 'Default Choice is ' + %char(F1);
  endif;
  // Display screen
  exfmt FMT01;
  //Show chosen choice
  F2 = 'Last Choice was ' + %char(F1);
enddo;

*inlr = *on;
return;
