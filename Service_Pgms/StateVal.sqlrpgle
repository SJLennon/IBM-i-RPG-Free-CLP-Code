**free 
// StateVAL - Validates a 2-character USA State Code
// Returns * ON if the passed code is valid, otherwise *OFF
// Optionally returns the 30 character state name
// Note: Modifies data in the caller:
//    1) Ensures the state code is upper case.
//    2) If optional state name parameter is passed it is modified.

// CRTBNDDIR BNDDIR(LENNONS1/STATE_BND) TEXT('For STATEVAL')
// ADDBNDDIRE BNDDIR(STATE_BND) OBJ((SRV_STE *SRVPGM *DEFER))
// CRTSRVPGM SRVPGM(SRV_STE) MODULE(STATEVAL) EXPORT(*ALL)

ctl-opt nomain option(*nodebugio:*srcstmt) 
    bnddir('SQL_BND' : 'UTIL_BND');

dcl-proc StateVal export;
  dcl-pi StateVal ind;
    p_code like(States_T.code); 
    p_name like(States_T.name) options(*nopass); 
  end-pi;

  /include ../Copy_Mbrs/SRV_SQL_P.RPGLE
  /include ../Copy_Mbrs/SRV_MSG_P.RPGLE
  dcl-c SQLSUCCESS '00000';

  dcl-ds States_T template qualified;
    code char(2);
    name char(30);
  end-ds;
  dcl-s ix int(10);
  
  // === Static variables ===
  // Array of State info loaded once first time.
  dcl-ds States_A likeds(States_T) dim(*auto :100) static;
  dcl-s StatesLoaded ind static;

  // === One time load of State info ===================================
  if (StatesLoaded = *off);
    // Job log message to confirm load occurs only once.
    JobLogMsg('StateVal: Loading States');
    EXEC SQL
    DECLARE  states_cursor CURSOR FOR select state, name from states
      order by state;
    EXEC SQL
    OPEN  states_cursor;
    if sqlstate <>  SQLSUCCESS;
      SQLProblem('Open of states_cursor failed');
    endif;
    // Loading all in one fetch since we know there are alway fewer
    // than 100 USA states and territories.
    EXEC SQL
    FETCH from states_cursor for 100 rows into :States_A;
    if sqlstate <>  SQLSUCCESS;
      SQLProblem('Fetch from states_cursor failed');
    endif;
    EXEC SQL
    CLOSE states_cursor ;
    if sqlstate <>  SQLSUCCESS;
      SQLProblem('Close of states_cursor failed');
    endif;
    StatesLoaded = *on;
  endif;

  // === Lookup the provided state code ================================
  p_code = %upper(p_code); // Ensure it is upper case
  ix=%lookup(p_code : States_A(*).code);
  // === State code found ===
  if ix <> 0;
    if %passed(p_name);
      p_name = States_A(ix).name;
    endif;
    return *on;
  else;
    // === State not found ===
    if %passed(p_name);
      p_name = *blanks;
    endif;
    return *off;
  endif;

end-proc;