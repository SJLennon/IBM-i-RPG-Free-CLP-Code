**free
ctl-opt debug option(*nodebugio: *srcstmt)
    dftactgrp(*no) actgrp('USPS')
    bnddir('UTIL_BND':'SQL_BND':'ADRVAL_BND')
    main(Main);
//====================================================================
// Program to exercise USADRVAL.
// Results are printed to QSYSPPRT.
//====================================================================
/copy ../Copy_Mbrs/USADRVALDS.RPGLE
/copy ../Copy_Mbrs/SRV_MSG_P.RPGLE
/copy ../Copy_Mbrs/USADRVAL_P.RPGLE

dcl-f qsysprt printer(132) usropn;

dcl-proc Main;

  dcl-ds pi likeds(USAdrValDS);
  dcl-ds po likeds(USAdrValDS);

  *inlr = *on;
  open qsysprt;

  pi.Address1 = 'Suite 2';
  pi.Address2 = '8 Wildwood Drive';
  pi.City = 'Old Lyme';
  pi.State = 'CT';
  pi.Zip5='';
  pi.Zip4 ='';

  po = USAdrVal(pi);
  DspAdr(pi:po);

  pi.Address1 = ' ';
  po = USAdrVal(pi);
  DspAdr(pi:po);

  pi.Address2 = 'Suite 2 ' + pi.Address2;
  po = USAdrVal(pi);
  DspAdr(pi:po);

  pi.Address2 = 'Wildwood Drive';
  po = USAdrVal(pi);
  DspAdr(pi:po);

  pi.Address2 = '8 Wildwood Drive, Suite 2';
  pi.City = ' ';
  pi.Zip5 = '06371';

  po = USAdrVal(pi);
  DspAdr(pi:po);

  pi.Address1 = '';
  pi.Address2 = '300 west green street';
  pi.City = 'pasadena';
  pi.State = 'ca';
  pi.Zip5='';
  pi.Zip4 ='';

  po = USAdrVal(pi);
  DspAdr(pi:po);

  pi.Address2 = '6802 rio grande blvd nw ';
  pi.City = 'los ranchos de albuquerque';
  pi.State = 'nm';
  pi.Zip5='';
  pi.Zip4 ='';

  po = USAdrVal(pi);
  DspAdr(pi:po);

  pi.Address1 = 'Apt 22 ';
  pi.Address2 = '13 SENDERO';
  pi.City = 'Rancho Santa Margarita';
  pi.State = 'ca';
  pi.Zip5='';
  pi.Zip4 ='';

  po = USAdrVal(pi);
  DspAdr(pi:po);

  close qsysprt;
  return;
end-proc Main;

//=== Routine to print input and output side by side =================
dcl-proc DspAdr;
  dcl-pi DspAdr;
    pi likeds(USAdrValDS);
    po likeds(USAdrValDS);
  end-pi;
  dcl-c WLOC 1;
  dcl-c ILOC 15;
  dcl-c OLOC 46;
  dcl-s tNum int(10) inz(1) static;

  dcl-s l char(132);
  %subst(l:ILOC) =   'INPUT';
  %subst(l:OLOC) = 'OUTPUT';
  writeln(l);

  %subst(l:WLOC:11) = 'Address1';
  %subst(l:ILOC)    =   pi.address1;
  %subst(l:OLOC)    = po.address1;
  writeln(l);

  %subst(l:WLOC:11) = 'Address2';
  %subst(l:ILOC)    =   pi.address2;
  %subst(l:OLOC)    = po.address2;
  writeln(l);

  %subst(l:WLOC:11) = 'City';
  %subst(l:ILOC)    =   pi.City;
  %subst(l:OLOC)    = po.City;
  writeln(l);

  %subst(l:WLOC:11) = 'State';
  %subst(l:ILOC)    =   pi.State;
  %subst(l:OLOC)    = po.State;
  writeln(l);

  %subst(l:WLOC:11) = 'Zip5';
  %subst(l:ILOC)    =   pi.Zip5;
  %subst(l:OLOC)    = po.ZIP5;
  writeln(l);

  %subst(l:WLOC:11) = 'Zip4';
  %subst(l:ILOC)    =   pi.Zip4;
  %subst(l:OLOC)    = po.Zip4;
  writeln(l);
  if (po.Description <> ' ');
    %subst(l:WLOC:11) = 'Number';
    %subst(l:OLOC)    = %char(po.Number);
    writeln(l);

    %subst(l:WLOC:11) = 'Source';
    %subst(l:OLOC)    = po.Source;
    writeln(l);

    %subst(l:WLOC:11) = 'Description';
    %subst(l:OLOC)    = po.Description;
    writeln(l);
  endif;

  writeln('------------------------------------------------------------');
  tNum += 1;

  return;
end-proc DspAdr;

//=== WriteLn: Courtesy of Ted Hold and ITJungle.com =================
// https://www.itjungle.com/2021/10/25/guru-quick-and-handy-rpg-output-take-2/
dcl-proc writeln;
  dcl-pi *n;
    inString   varchar(132)   const;
    inPosition uns(3)         const   options(*nopass);
  end-pi;

  dcl-ds  prtLineDS qualified;
    line    char(132);
  end-ds;

  dcl-ds  prtLine likeds(prtLineDS);
  dcl-s   Posn    uns(3);

  if (%parms() >= %ParmNum(inPosition));
    Posn = inPosition;
  else;
    Posn = 1;
  endif;

  %subst(prtLine.line: Posn) = inString;
  write qsysprt prtLine;
end-proc writeln;
