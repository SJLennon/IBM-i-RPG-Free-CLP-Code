**free
// Test Rand_Int procedure by generating many randon integers and
// writing them to file RNUM.
ctl-opt DftActGrp(*NO) ActGrp(*CALLER) option(*nodebugio: *srcstmt)
      BndDir('UTIL_BND');
/COPY copy_mbrs,srv_rand_p
exec sql set  option datfmt=*iso,
              commit=*none,
              closqlcsr=*endmod;

dcl-s min int(10) inz(3);
dcl-s max int(10) inz(14);

dcl-s wk int(10);
dcl-s j int(10);
exec sql drop table lennons1.rnum;
exec sql create or replace table lennons1.rnum (num integer);

for j = 1 to 100000;
  wk = Rand_Int(min:max);
  exec sql insert into lennons1.rnum values :wk;
endfor;

*inlr = *on;
return;

