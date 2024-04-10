**free
//=== USPHDR Description =============================================
// The list APIs which return data in a user space put a standard
// header at the start of the user space.  This descibes the header.
//=== Basing Pointer for Header ======================================
 dcl-s UspPtr pointer inz(*null);
//=== User Space Header Layout =======================================
 dcl-ds UspHdr based(uspptr);
  UspH char(192);
  UspUser char(64) overlay(usph:1);
  UspSize int(10) overlay(usph:65);
  UspInfSts char(1) overlay(usph:104);
  UspSpSize int(10) overlay(usph:105);
  UspInOff int(10) overlay(usph:109);
  UspInSize int(10) overlay(usph:113);
  UspHdrOfs int(10) overlay(usph:117);
  UspHdrSize int(10) overlay(usph:121);
  UspLstOfs int(10) overlay(usph:125);
  UspLstSize int(10) overlay(usph:129);
  UspLst#Ent int(10) overlay(usph:133);
  UspLstEntSz int(10) overlay(usph:137);
 end-ds;
// UspInfSts values
 dcl-c UspICmpl const('C');
 dcl-c UspIPrtl const('P');
 dcl-c UspIIncp const('I');
