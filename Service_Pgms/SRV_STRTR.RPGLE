
       //=== Test the SRV_STR service program========================

     H DftActGrp(*NO) ActGrp(*CALLER) option(*nodebugio: *srcstmt)
     H BndDir('UTIL_BND')

     d X1              S              1A   inz('A')                             One char
     d X2              S              2A   inz('B ')                            Two char
     d X3              S              4A   inz('C   ')                          3 blanks
     d X4              S              5A   inz('D    ')                         4 blanks
     d X5              S              6A   inz('E    ')                         5 blanks
     d X0              S              5A   inz('     ')                         all blank
     d Xl              S             20A   inz('20-chars  ')                    longer
     d Xm              S             21A   inz('       21-Chars')               longer
     d Xv              S             24    inz('    24-varying  ') varying      Varying-note result
     d l1              S             20A   inz('           ABCDE  ')            Left align
     d l2              S             20A   inz('Left already      ')            Left align
     d r1              S             20A   inz('abc')                           Right align
     d r2              S             20A   inz('   defgh  ')                    Right align
      /include copy_mbrs,SRV_STR_P
      /free
         x1 = tst(x1);
         dsply ('-' + x1 + '-');

         x2 = tst(x2);
         dsply ('-' + x2 + '-');

         x3 = tst(x3);
         dsply ('-' + x3 + '-');

         x4=tst(x4);
         dsply ('-' + x4 + '-');

         x5 = tst(x5);
         dsply ('-' + x5 + '-');

         x0 = tst(x0);
         dsply ('-' + x0 + '-');

         xl = tst(xl);
         dsply ('-' + xl + '-');

         xm = tst(xm);
         dsply ('-' + xm + '-');

         xv = tst(xv);
         dsply ('-' + xv + '-');

         dsply ('---- Left Justify ---');
         dsply ('-' + l1 + '-');
         l1 =%trim(l1);
         dsply ('-' + l1 + '-');

         dsply ('-' + l2 + '-');
         l2 =%trim(l2);
         dsply ('-' + l2 + '-');

         dsply ('---- Right Justify ---');
         dsply ('-' + r1 + '-');
         evalr r1 = %trim(r1);
         dsply ('-' + r1 + '-');

         dsply ('-' + r2 + '-');
         evalr r2 = %trim(r2);
         dsply ('-' + r2 + '-');

         *inlr = *on;
         return;
      /END-FREE
     p tst             b
     d tst             pi            50a   varying
     d II                            50a   varying const
      /free
       dsply '---------------------';
         DSPLY ('-' + ii + '-');
         return CenterStr(ii);
      /end-free
     p tst             e
