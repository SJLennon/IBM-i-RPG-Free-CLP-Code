**free
Ctl-Opt option(*nodebugio) dftactgrp(*no) actgrp(*caller);
Dcl-F B2 WORKSTN;
dcl-c O_AVAIL      0;
DCL-C O_SELECTED   1;
DCL-C O_UNAVAIL    4;
DCL-C I_UNSELECTED 0;
DCL-C I_SELECTED   1;
dcl-s j int(10);
dcl-ds SingleDS ; // SNGCHCFLD CHCCTL fields
  A#SNG1 ;
  A#SNG2 ;
  A#SNG3 ;
  SingleArr like(A#SNG1) dim(3) pos(1);
end-ds;
dcl-ds SingleTextDS; // Text on the SNGCHCFLD fields
  A#SNG1T;
  A#SNG2T;
  A#SNG3T;
  SingleTextArr like(A#SNG1T) dim(3) pos(1);
end-ds;
dcl-ds MultDS; // MLTCHCFLD CHCCTL fields
  A#MLT1;
  A#MLT2;
  A#MLT3;
  MultArr like(A#MLT1) dim(3) pos(1);
end-ds;
dcl-ds MultTextDS; // Text for MLTCHCFLD fields
  A#MLT1T;
  A#MLT2T;
  A#MLT3T;
  MultTextArr like(A#MLT1T) dim(3) pos(1);
end-ds;
dcl-ds MultTextSel; // Text to re-display the MLTCHCFLD choices
  P2DESC1;
  P2DESC2;
  P2DESC3;
  MultTextSelArr like(P2DESC1) dim(3) pos(1);
end-ds;
// Populate the SNGCHCFLD & MLTCHCFLD display values
A#SNG1T = 'Sel 1';
A#SNG2T = 'Sel 2';
A#SNG3T = 'Sel 3';

A#MLT1T = 'Mlt 1';
A#MLT2T = 'Mlt 2';
A#MLT3T = 'Mlt 3';
SingleArr = O_AVAIL;  // All SNGCHCFLD Fields available
MultArr = O_AVAIL;    // All MLTCHCFLD Fields available
P1ANR = 1;            // Set default for SNGCHCFLD
A#MLT1 = O_SELECTED;  // Set Default for MLTCHCFLD

// Display for entry
dow (1=1);
  *IN02 = *off;
  exfmt TESTR;
// Build Confirmation fields
  P1DESC = SingleTextArr(P1ANR);
  for j = 1 to %elem(MultArr);
    if MultArr(j) = I_SELECTED;
      MultTextSelArr(j) = MultTextArr(j);
    endif;
  endfor;
// Confirmation Display
  MSG = 'Enter to accept, F12 to Modify';
  *in02 = *on;
  exfmt TESTR;
  if not (*IN12 = *ON);
    leave;
  endif;
enddo;
*inlr = *on;
return;
