**FREE
//==============================================================
//=== SRV_SQL service program contains prodcedure relating to
//=== processing embedded SQL.
//==============================================================
// CRTRPGMOD MODULE(SRV_SQL)
// CRTSRVPGM SRVPGM(SRV_SQL) EXPORT(*ALL)
// ADDBNDDIRE BNDDIR(SQL_BND) OBJ((SRV_SQL *SRVPGM *DEFER))

ctl-opt nomain
      bnddir('UTIL_BND')
      option(*NoDebugIo: *srcstmt);

//=== SQLProblem ===============================================
// For those "Never should happen" SQL errors.
// Issues DUMP(A) to dump memory, then ends program by
// sending an *ESCAPE message of the supplied debugging message,
// plus whatever SQL diagnostics we can fit into 512 chars.
dcl-proc SQLProblem export;
  dcl-pi SQLProblem;
    piSQLDebug varchar(200) const;
  end-pi;

  /include copy_mbrs,Srv_Msg_P

  //--- Local Variables ---------------------------------
  dcl-s myDebugMsg varchar(512); //Max CPF9898 supports
  dcl-s wkRem int(10);

  // Returned SQL diagnostic info
  dcl-s mySQLState CHAR(5);
  dcl-s mySQLMsgTxt varchar(32740);
  dcl-s mySQLMsgLgth int(5);

  exec sql get diagnostics condition 1
      :mySQLState = RETURNED_SQLSTATE,
      :mySQLMsgTxt = MESSAGE_TEXT,
      :mySQLMsgLgth = MESSAGE_LENGTH
  ;
  myDebugMsg =  piSQLDebug
      + ' - Unexpected SQL return: SQLSTATE='
      + mySQLState
      + '. "';

  // Fit in as much of mySQLMsgTxt as possible.
  wkRem = (%size(myDebugMsg)-2) - %len(myDebugMsg);
  if wkRem >= mySQLMsgLgth +1;
    myDebugMsg += (mySQLMsgTxt +'"');
  else;
    myDebugMsg += (%subst(mySQLMsgTxt: 1 :wkRem -5) + ' ..."');
  endif;

  dump(a);
  SndEscMsg(myDebugMsg);
  return;
end-proc;
