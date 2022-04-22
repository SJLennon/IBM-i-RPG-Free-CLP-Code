**free
// Demo of PRTCTL Data Structure Controlled Printing
ctl-opt option(*srcstmt) actgrp(*new) main(Prt);
dcl-f   QPRINT printer(132) oflind(*in99) prtctl(pCtl);
dcl-ds  pCtl len(15) qualified inz;
    sp_b4    char(3);   // Space before
    sp_aft   char(3);   // Space after
    sk_b4    char(3);   // Skip to line num before
    sk_aft   char(3);   // Skip to line num after
    linenum  char(3);
end-ds;
dcl-proc Prt;
    dcl-c TOP '005';       // Skip to top of  page
    dcl-c S1  '001';       // Space 1 line & print
    dcl-c S2  '002';       // Space 2 lines & print
    dcl-c S3  '003';       // Space 3 lines & Print
    dcl-c S0  '000';       // Space 0, overprint
    dcl-ds line  len(132) inz qualified;
        *n       char(6) ;          // left margin
        text     Char(126);          // Ad-hoc text
        num      char(6)    overlay(text:*next);
        *n       char(6)    overlay(text:*next);
        ts       char(26)   overlay(text:*next);
    end-ds;
    dcl-ds   lCtl likeds(pCtl);
    dcl-ds   head1 likeds(line);
    dcl-ds   h1Ctl likeds(pCtl);
    dcl-ds   head2 likeds(line);
    dcl-ds   h2Ctl likeds(pctl);
    dcl-ds   head3 likeds(line);
    dcl-ds   h3Ctl likeds(pCtl);
    dcl-s    k   int(10);
    // Initialization
    h1Ctl.sk_b4 = TOP;
    h1Ctl.sp_aft = S2;
    head1.text = 'Sample Report Using Concocted Data';
    h2Ctl.sp_aft = S0;
    head2.num = 'Number';
    head2.ts = 'Time Stamp';
    h3Ctl.sp_aft = S1;
    head3.num = *all'_';
    head3.ts = *all'_';
    *in99 = *on;    // First page is always skip

    for k = 1 to 70;
        if (*in99 = *on);
            *in99 = *off;
            prtLine(head1:h1Ctl);
            prtLine(head2:h2Ctl);
            prtLine(head3:h3Ctl);
        endif;
        evalr line.num = %trim(%char(k));
        line.ts = %char(%timestamp());
        lCtl.sp_b4 = S1;
        prtLine(line:lCtl);
    endfor;
    lCtl.sp_b4 = S3;
    line.text = '*** End of Report ***';
    prtLine(line:lCtl);
    return;
end-proc;
// Procedure to print a line
dcl-proc prtLine;
    dcl-pi prtLine;
        theLine char(132);
        ctl likeds(pCtl);
    end-pi;
    dcl-ds line len(132) qualified;
    end-ds;
    pCtl = Ctl;
    line = theLine;
    write QPRINT line;
end-proc;
