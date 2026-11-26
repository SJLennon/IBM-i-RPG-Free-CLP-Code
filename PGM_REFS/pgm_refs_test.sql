-- Sample calls for PGM_REFS, updated for the fork enhancements:
-- the library for REFS/PGM_REFS_VISITED is now a parameter, and
-- objects already visited are skipped automatically (memoization).

-- 1. One-time setup: create REFS and PGM_REFS_VISITED in your library.
--    Re-run this any time you want to wipe results and start fresh.
call pgm_refs_init('LENNONSB');

-- 2. Depth field starts at 0, type of *PGM assumed. RefsLib given
--    explicitly so results land in LENNONSB regardless of your
--    current schema.
call lennons1.pgm_refs(
    p_inlib => 'LENNONS1', p_inpgm => 'MTNCUSTR', p_RefsLib => 'LENNONSB');

-- Positional form still works: lib, pgm, type, depth, refslib, maxdepth
call lennons1.pgm_refs('LENNONS1', 'MTNCUSTR', '*PGM', 0, 'LENNONSB');

-- Depth field starts at 6789, an arbitrary number
call lennons1.pgm_refs(
    p_inlib => 'LENNONS1', p_inpgm => 'MTNCUSTR',
    p_depth => 6789, p_RefsLib => 'LENNONSB');

call lennons1.pgm_refs(
    p_inlib => 'FASTBREED', p_inpgm => 'FSTMAINR', p_RefsLib => 'LENNONSB');

-- Start with a *MODULE
call lennons1.pgm_refs(
    p_inlib => 'LENNONSB', p_inpgm => 'ART300',
    p_INTYPE => '*MODULE', p_RefsLib => 'LENNONSB');

-- Start with a *SRVPGM
call lennons1.pgm_refs(
    p_inlib => 'LENNONSB', p_inpgm => 'FVAT',
    p_INTYPE => '*SRVPGM', p_RefsLib => 'LENNONSB');

-- Cap recursion depth as an extra safety net on a very deep system.
call lennons1.pgm_refs(
    p_inlib => 'FASTBREED', p_inpgm => 'FSTMAINR',
    p_RefsLib => 'LENNONSB', p_MaxDepth => 50);

-- On PUB400.COM, give the program a work out and get some errors.
call lennons1.pgm_refs(
    p_inlib => 'FASTBREED', p_inpgm => 'FSTMAINR', p_RefsLib => 'LENNONSB');

-- Find errors. If you have a lot it's probably a library list issue.
select * from lennonsb.refs where USES_LIBRARY = '*ERROR';

-- List the output file of objects used
select * from lennonsb.refs
order by DEPTH, CALLER_LIBRARY, CALLER_NAME, CALLER_TYPE,
         USES_LIBRARY, USES_NAME, USES_TYPE;

-- See which objects were expanded at least once this run (one row per
-- object, regardless of how many parents reached it)
select * from lennonsb.pgm_refs_visited
order by OBJ_LIBRARY, OBJ_NAME, OBJ_TYPE;

-- Find the procedures you created
select * from qsys2.sysprocs where ROUTINE_DEFINER = 'LENNONS';

-- Get rid off procedures regardless of signature
drop specific procedure lennons1.pgm_refs;
drop specific procedure lennons1.pgm_refs_init;
