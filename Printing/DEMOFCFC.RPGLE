**free
// Demo of First Character Form Control (FCFC) Printing
ctl-opt option(*srcstmt) actgrp(*new) main(Prt);
dcl-f   MYPRT printer(133) oflind(*in99);
dcl-proc Prt;
    dcl-c TOP '1';       // Skip to top of  page
    dcl-c S1  ' ';       // Space 1 line & print
    dcl-c S2  '0';       // Space 2 lines & print
    dcl-c S3  '-';       // Space 3 lines & Print
    dcl-c S0  '+';       // Space 0, overprint
    dcl-ds line len(133) inz qualified;
        fcfc     char(1);
        *n       char(6);        // left margin
        text     Char(126);      // Ad-hoc text
        num      char(6)    overlay(text:*next);
        *n       char(6)    overlay(text:*next);
        ts       char(26)   overlay(text:*next);
    end-ds;
    dcl-ds   head1 likeds(line);
    dcl-ds   head2 likeds(line);
    dcl-ds   head3 likeds(line);
    dcl-s    k   int(10);
    // Initialization
    head1.fcfc = TOP;
    head1.text = 'Sample Report Using Concocted Data';
    head2.fcfc = S2;
    head2.num = 'Number';
    head2.ts = 'Time Stamp';
    head3.fcfc = S0;
    head3.num = *all'_';
    head3.ts = *all'_';
    *in99 = *on;    // First page is always skip

    for k = 1 to 70;
        if (*in99 = *on);
            *in99 = *off;
            write MYPRT head1;
            write MYPRT head2;
            write MYPRT head3;
        endif;
        evalr line.num = %trim(%char(k));
        line.ts = %char(%timestamp());
        line.fcfc = S1;
        write MYPRT line;
    endfor;
    line.fcfc = S3;
    line.text = '*** End of Report ***';
    write MYPRT line;
    return;
end-proc;
// CRTPRTF FILE(LENNONS1/MYPRT) CTLCHAR(*FCFC) CHLVAL((1 (3)))
// OVRPRTF FILE(QPRINT) CTLCHAR(*FCFC) CHLVAL((1 (3)))
