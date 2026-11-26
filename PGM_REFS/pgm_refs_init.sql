-- Creates (or resets) the two tables PGM_REFS needs, in whatever
-- library you pass in. Run this once before using PGM_REFS, or
-- any time you want to wipe out old results and start a fresh run.
--
-- This replaces the old approach of hand-editing "pgm.refs_Tbl.sql"
-- in two places to change the library name.
--
-- Usage:
--   call pgm_refs_init('MYLIB');
--
-- Tables created:
--   MYLIB.REFS               - every CALLER -> USES edge found
--   MYLIB.PGM_REFS_VISITED   - objects already expanded by DSPPGMREF
--                              in a run (new - used for memoization,
--                              see pgm_refs.sql)

CREATE OR REPLACE PROCEDURE PGM_REFS_INIT (
     IN p_RefsLib varchar(128)
    )
    LANGUAGE SQL
    NOT DETERMINISTIC
    MODIFIES SQL DATA
    SET OPTION dbgview = *source, commit = *none
begin
    declare Cmd varchar(2048);

    -- REFS: every caller -> uses edge discovered by DSPPGMREF.
    set Cmd = 'drop table if exists ' concat trim(p_RefsLib) concat '.REFS';
    execute immediate Cmd;

    set Cmd = 'create table ' concat trim(p_RefsLib) concat '.REFS (
         DEPTH          integer
        ,CALLER_LIBRARY VarCHAR(10) NOT NULL
        ,CALLER_NAME    VarCHAR(10) NOT NULL
        ,CALLER_TYPE    VarCHAR(10) NOT NULL
        ,CALLER_TEXT    Varchar(30) NOT NULL
        ,USES_LIBRARY   VarCHAR(10) NOT NULL
        ,USES_NAME      VarCHAR(10) NOT NULL
        ,USES_TYPE      VarCHAR(10) NOT NULL
        ,CONSTRAINT     ' concat trim(p_RefsLib) concat '.refs_pk PRIMARY KEY (
            CALLER_LIBRARY, CALLER_NAME, CALLER_TYPE,
            USES_LIBRARY, USES_NAME, USES_TYPE
        )
    )';
    execute immediate Cmd;

    -- PGM_REFS_VISITED: objects we have already run DSPPGMREF against
    -- in this run, so PGM_REFS never re-scans the same object twice -
    -- see the memoization check at the top of pgm_refs.sql.
    set Cmd = 'drop table if exists ' concat trim(p_RefsLib) concat '.PGM_REFS_VISITED';
    execute immediate Cmd;

    set Cmd = 'create table ' concat trim(p_RefsLib) concat '.PGM_REFS_VISITED (
         OBJ_LIBRARY    VarCHAR(10) NOT NULL
        ,OBJ_NAME       VarCHAR(10) NOT NULL
        ,OBJ_TYPE       VarCHAR(10) NOT NULL
        ,CONSTRAINT     ' concat trim(p_RefsLib) concat '.pgm_refs_visited_pk
            PRIMARY KEY (OBJ_LIBRARY, OBJ_NAME, OBJ_TYPE)
    )';
    execute immediate Cmd;
end;
