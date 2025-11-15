**free

ctl-opt DftActGrp(*NO) ActGrp(*new) // <--- Needed 
      option(*nodebugio: *srcstmt)
      BndDir('STATE_BND' : 'UTIL_BND');
/COPY ../Copy_Mbrs/SRV_STE_P.RPGLE
/COPY ../Copy_Mbrs/SRV_MSG_P.RPGLE
dcl-s myCode char(2);
dcl-s myName char(30);
dcl-s msg varchar(50);
dcl-s ind ind;

// === Test at limits: first and last
myCode = 'AA';
ind = StateVal(myCode:myName);
prt();
myCode = 'WY';
ind = StateVal(myCode:myName);
prt();

// === test awau from limits
myCode = 'OK';
ind = StateVal(myCode:myName);
prt();
myCode = 'OH';
ind = StateVal(myCode:myName);
prt();

// === test lower case ===
myCode = 'mp';
ind = StateVal(myCode:myName);
prt();
myCode = 'Dc';
ind = StateVal(myCode:myName);
prt();

// === test bad state code
myCode = 'xx';
myName = 'Should be cleared';
ind = StateVal(myCode:myName);
prt();

// === test with 1 parameter ===
myCode = 'fl';
ind = StateVal(myCode:myName);
prt();
myCode = 'fl';
myName = 'Should be unchanged';
ind = StateVal(myCode);
prt();
myCode = '**';
myName = 'code was ** ';
ind = StateVal(myCode);
prt();

*inlr = *on;

dcl-proc prt;
  msg = 'RET: ' + %char(ind);
  msg = msg + ' Code: ' + myCode + ' Name: ' + myName;
  JobLogMsg(msg);
end-proc;