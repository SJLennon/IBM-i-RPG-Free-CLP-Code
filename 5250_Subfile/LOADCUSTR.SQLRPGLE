**free
// === Program to create "n" records of test data in CUSTMAST =====
// ===  Assumes CUSTMAST is exists and will clear it first.
// === City name, state and zip are generated from USPS data, 
//      file CSZ, created from upload from USPS.COM with iACS.
//      See https://www.unitedstateszipcodes.org/zip-code-database/
//      Rest of the data i randomly generated.
// This was an experimental program to use randomn number and
// variable sized arrays.  But it was fun to write...

ctl-opt DftActGrp(*no) ActGrp('QILE') BndDir('UTIL_BND':'SQL_BND':'SRV_BASE36');
ctl-opt Option(*nounref: *nodebugio: *srcstmt);
ctl-opt ExprOpts(*ResDecPos) ExtBinInt( *Yes );
ctl-opt Debug(*constants : *retval);
ctl-opt Indent('| ');
/COPY ../Copy_Mbrs/SRV_SQL_P.RPGLE
/COPY ../Copy_Mbrs/SRV_RAND_P.RPGLE
/COPY ../Copy_Mbrs/BASE36_P.RPGLE

// === Program Parameter =======================================
dcl-pi *n;
  parm_recds packed(15 : 5); // Number of records to create
end-pi;
dcl-s p_recds int(10);

dcl-ds Fld ExtName('CUSTMAST') Qualified;
end-ds;
// === SQL State Constants =====================================
dcl-c SQLSUCCESS      '00000';
dcl-c SQLNODATA       '02000';
dcl-c SQLNOMOREDATA   '02000';
dcl-c SQLNOTJOURNALED '01567';

dcl-s companyType varchar(10) dim(*auto : 30);
dcl-s streetType varchar(10) dim(*auto : 30);
dcl-s varCUSTID varchar(4);
// === City/state/zip record ===
dcl-ds csz qualified;                        
  zip int(10);
  ziptype char(10);
  city char(20);
  st char(2);
end-ds;

// === Arrary of City, State and Zip records ===
dcl-ds csz_a likeds(csz) dim(*auto : 50000) ;

dcl-s cszCount int(10);
dcl-s MaxL int(10);
dcl-s csz_I int(10);
dcl-s j int(10);
// dcl-s t int(10);
DCL-S adrX int(10);
dcl-s nRecds int(10);
dcl-s wk10 char(10);
dcl-s wkStr varchar(50);

// === Build array of Company types ===
companyType(1) = 'INC';
companyType(*next) = 'LLC';
companyType(*next) = 'LLP';
companyType(*next) = 'COMPANY';
companyType(*next) = '& SONS';
companyType(*next) = 'ET FILS';
companyType(*next) = 'PLC';
companyType(*next) = 'CORP';
companyType(*next) = 'LTD';
companyType(*next) = 'SOLE';
companyType(*next) = 'PARTNERS';
companyType(*next) = 'ASSOC';

// === Build array of street types ===
streetType(1) = 'STREET';
streetType(*next) = 'ST';
streetType(*next) = 'ROAD';
streetType(*next) = 'RD';
streetType(*next) = 'AVENUE';
streetType(*next) = 'AVE';
streetType(*next) = 'PLACE';
streetType(*next) = 'CIRCLE';
streetType(*next) = 'SQUARE';
streetType(*next) = 'HWY';
streetType(*next) = 'VISTA';
streetType(*next) = 'CALLE';
streetType(*next) = 'RANCH';
streetType(*next) = 'CRESCENT';
streetType(*next) = 'COURT';
streetType(*next) = 'WAY';

exec sql set  option datfmt=*iso,
              commit=*none,
              closqlcsr=*endmod;
              
// === Clear Custmast file ===              
exec sql truncate  lennons1.custmast;
if (SQLSTT <> SQLSUCCESS and SQLSTT <> SQLNODATA);
  SQLProblem('truncate custmast');
endif;

// === Size the City/State/Zip array ===
exec sql select count(*) into :cszCount
  from lennons1.csz
  where length(trim(city)) <= 20;
if (SQLSTT <> SQLSUCCESS);
  SQLProblem('select count(*)');
endif;
%elem(csz_a : *alloc) = cszCount + 1;

// === Populate csz_a ===
exec sql declare csz_cur cursor for
  select zip, type, upper(city), trim(state)
  from lennons1.csz
  where length(trim(city)) <= 20;
exec sql open csz_cur;
if (SQLSTT <> SQLSUCCESS );
  SQLProblem('Open csz_cur');
endif;
j=1;
dow (1=1);
  exec sql fetch from csz_cur into :csz; 
  if SQLSTT = SQLNOMOREDATA;
    leave;
  endif;
  if SQLSTT <> SQLSUCCESS;
    SQLProblem('fetch fron csz_cur');
  endif;
  csz_a(j) = csz;
  j += 1;
enddo;

// === Build CUSTMAST records =================================
p_recds = parm_recds;
varCUSTID = '1001';
for nRecds = 1 to p_recds;
  clear Fld;
  Fld.CUSTID = varCUSTID;
  varCUSTID = BASE36ADD(varCUSTID); // Alpha-numeric key
  Fld.ACTIVE = 'Y';
  if (%rem(nRecds : 7) = 0);
    Fld.ACTIVE = 'N';
  endif;

  // === City/State Zip ===
  csz_I = Rand_Int(1:%elem(csz_a));
  Fld.STATE = csz_a(csz_I).st;
  Fld.CITY = csz_a(csz_I).city;
  wk10 = %editc(csz_a(csz_I).zip:'X');
  Fld.ZIP = %subst(wk10 :6 :5);

  // === Company Name ===
  clear wkStr; 
  // Specify a random name length leaving space for 
  // a company6y type suffix.
  MaxL = Rand_Int(5 : %len(Fld.Name) - 12);
  wkStr = wkStr + genWord(5:11) + ' ';
  dow %len(wkStr) <= MaxL;
    wkStr = wkStr + genWord(5:11) + ' ';
  enddo;

  // Add  company "types" to some records
  j = Rand_Int(1:(%elem(companyType) * 1.8));
  if j <= %elem(companyType);
    wkStr = %trim(wkStr) + ' ' + companyType(j);
  endif;
  Fld.NAME = wkStr;

  // === Address ===
  clear wkStr;
  adrX = %rem(nRecds :4);
  MaxL = Rand_Int(5 : %len(Fld.ADDR) - 12);
  if adrX <> 0; //Add street number to most
    wkStr = %trim(%editc(Rand_Int(1:5000) : '3')) + ' ';
  endif;
  wkStr = wkStr + genWord(5:11) + ' ';
  dow %len(wkStr) <= MaxL;
    wkStr = wkStr + genWord(5:11) + ' ';
  enddo;
  // Add street "types" to some records
  j = Rand_Int(1:(%elem(streetType) * 1.75));
  if j <= %elem(streetType);
    wkStr = %trim(wkStr) + ' ' + streetType(j);
  endif;
  Fld.ADDR = wkStr;

  // === Phone numbers ===
  Fld.CORPPHONE = genPhone();
  Fld.ACCTPHONE = genPhone();

  // === Account Manager ===
  if %rem(nRecds :3) = 0;
    wkStr = genWord(1:1) + ' ';
    wkStr += genWord(1:1) + ' ';
    wkStr += genWord(4:10);
  else;
    wkStr = genWord(3:6) + ' ';
    wkStr += genWord(5:9);
  endif;
  Fld.ACCTMGR = wkStr;

  Fld.CHGUSER = '*SYSTEM*';

  // === Write out a record ======================================
  exec sql insert into lennons1.custmast values(:Fld);
  if (SQLSTT <> SQLSUCCESS);
    SQLProblem('Insert into custmast');
  endif;
endfor;

// === All finished ============================================
*inlr = *on;
return;

// === Generate a word =========================================
dcl-proc genWord;
  dcl-pi genWord varchar(30);
    MinL int(10) const;
    MaxL int(10) const;
  end-pi;
  // Straight alphabetic
  dcl-s Alpha varchar(50)
  inz('ABCDEFGHIIJKLMNOPQRSTUVWXYZZ');
  // Biased towards vowels
  dcl-s vAlpha varchar(50)
  inz('AAAAABCDEEEEEFGHIIIIIJKLMNOOOOOPQRSTUUUVWXYZZ');

  dcl-s wk30 varchar(30) inz;
  dcl-s TgtL int(10);
  dcl-s j int(10);

  wk30 = %subst(Alpha : Rand_Int(1 : %len(Alpha)) : 1);
  if (MinL<> 1 and MaxL <> 1);
    wk30 += %subst(vAlpha : Rand_Int(1 : %len(vAlpha)) : 1);
  endif;
  TgtL = Rand_Int(MinL:MaxL) - 2;    
  for j=1 by 2 to TgtL;     
    wk30 += %subst(Alpha : Rand_Int(1 : %len(Alpha)) : 1);
    wk30 += %subst(vAlpha : Rand_Int(1 : %len(vAlpha)) : 1);
  endfor;
  return wk30;
end-proc;

// === Generate a phone like (800) 231-1876 ====================
dcl-proc genPhone;
  dcl-pi genPhone varchar(20);
  end-pi;
  dcl-s wkret varchar(20);
  dcl-s wk3 char(3);
  dcl-s wk4 char(4);
  wk3 = %editc(%dec(Rand_Int(100:900):3 :0) : 'X');
  wkret = '(' + wk3 + ') ';
  wk3 = %editc(%dec(Rand_Int(1:998) :3 :0) : 'X');
  wkret += wk3 + '-';
  wk4 = (%editc(%dec(Rand_Int(1:9900) :4 :0) : 'X'));
  wkret += wk4;
  return wkret;
end-proc;
