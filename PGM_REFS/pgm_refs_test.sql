-- Depth field starts at 0, type of *PGM assumed
call lennons1.pgm_refs('LENNONS1', 'MTNCUSTR'); 
call lennons1.pgm_refs(p_inlib => 'LENNONS1', p_inpgm => 'MTNCUSTR');

-- Depth field starts at 6789, an arbitrary number
call lennons1.pgm_refs('LENNONS1', 'MTNCUSTR','*PGM', 6789);
call lennons1.pgm_refs(p_depth => 6789, p_inlib => 'LENNONS1', p_inpgm => 'MTNCUSTR');
call lennons1.pgm_refs('FASTBREED', 'FSTMAINR','*PGM', 0);

-- Start with a *MODULE 
call lennons1.pgm_refs(p_inlib => 'LENNONSB', p_inpgm => 'ART300', p_INTYPE => '*MODULE');

-- Start with a *SRVPGMMODULE 
call lennons1.pgm_refs(p_inlib => 'LENNONSB', p_inpgm => 'FVAT', p_INTYPE => '*SRVPGM');
 
-- On PUB400.COM, give the program a work out and get some errors. 
call lennons1.pgm_refs('FASTBREED', 'FSTMAINR'); 

-- Find errors.  If you have a lot it's probably a library list issue.
select * from lennonsb.refs where USES_LIBRARY = '*ERROR';

-- List the output file of objects used
select * from lennonsb.refs 
order by DEPTH, CALLER_LIBRARY, CALLER_NAME, CALLER_TYPE, 
         USES_LIBRARY, USES_NAME, USES_TYPE;

-- Find the procedures you created        
 select * from qsys2.sysprocs where ROUTINE_DEFINER = 'LENNONS';

-- Get rid off procedure regardless of signature
drop specific procedure lennons1.pgm_refs;