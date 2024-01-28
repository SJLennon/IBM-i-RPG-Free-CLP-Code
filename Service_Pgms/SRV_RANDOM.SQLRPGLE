**free
//==============================================================
//=== SRV_RANDOM service program contains convenience prodcedures
//    for generating pseudo random numbers.
//==============================================================
ctl-opt nomain option(*nodebugio: *srcstmt);
 // ------------------------------------------------------------
// RAND_INT -  function to returns a pseudo randon integer
// such that the value is >= p_Low and <= p_High.
 // ------------------------------------------------------------

// No validity checking on the parameters.

// Testing shows that a fairly even distribution is
// produced, but p_High is much less frequently returned.
// The underlying SQL function returns a number that is
// >= .0 and <= .1, but it rarely returns .1.

// CRTSRVPGM SRVPGM(LENNONS1/SRV_RAND) MODULE(Rand_Int) EXPORT(*ALL)

dcl-proc Rand_Int export;
  dcl-pi Rand_Int int(10);
    p_Low int(10) value;
    p_High int(10) value;
  end-pi;

  dcl-s rf float(8);
  dcl-s wk int(10);

  exec sql set :rf = random();
  wk = %int( (rf *(p_High - p_Low) + p_Low) );
  return wk;
end-proc;
