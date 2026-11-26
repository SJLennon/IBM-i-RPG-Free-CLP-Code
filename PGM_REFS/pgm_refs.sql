--  Procedure to run DSPPGMREF, then run DSPPGMREF on each of its objects
--  by calling itself recursively.
--  Result is a table named REFS containing all the objects that
--  DSPPGMREF knows about an object, to an essentially unlimited depth.
--
-- Run PGM_REFS_INIT(p_RefsLib) once first (see pgm_refs_init.sql) to
-- create the REFS and PGM_REFS_VISITED tables in your library.
--
-- Changes from the original version (see PGM_REFS/Readme.MD "Fork
-- enhancements" section for the full writeup):
--
--  1. The REFS table's library is now a parameter (p_RefsLib) instead
--     of being hardcoded in two places in the source. It defaults to
--     CURRENT_SCHEMA if you don't pass it.
--
--  2. Memoization: a new PGM_REFS_VISITED table records every object
--     that has already been expanded with DSPPGMREF in this run. On
--     entry, PGM_REFS checks it first and returns immediately if the
--     object was already visited - so it never runs DSPPGMREF twice
--     on the same object. The original only deduped *edges* via the
--     REFS table's primary key, which still let "diamond" shaped
--     dependencies (an object reached via two different parents) or
--     real cycles re-run DSPPGMREF on the same object repeatedly.
--
--  3. p_MaxDepth (default 999) is a safety cap on recursion depth, so
--     a very deep or unexpectedly cyclic system stops cleanly instead
--     of risking the engine's own SQL PL recursion limit.

CREATE OR REPLACE PROCEDURE PGM_REFS (
     IN p_INLIB     varCHAR(10)
    ,IN p_INPGM     varCHAR(10)
    ,IN p_INTYPE    varCHAR(10) default '*PGM'
    ,in p_Depth     integer     default(0)
    ,IN p_RefsLib   varCHAR(128) default null
    ,IN p_MaxDepth  integer     default(999)
    )
    LANGUAGE SQL
    NOT DETERMINISTIC
    MODIFIES SQL DATA
    SET OPTION dbgview = *source, commit = *none
begin
    -- Define DSPPGMREF OUTFILE library and file names
    declare WrkLib          varchar(10) default 'QTEMP';
    declare WrkFileOS       varchar(20) default '/WRK' ;
    declare WrkFileSQL      varchar(20) default '.WRK';

    declare sqlstate        char(5);
    declare my_sqlstate     char(5);
    declare no_more_data    char(5) default '02000';
    declare duplicate_key   char(5) default '23505';
    declare error_msg       varchar(30) default ' ';
    declare Cmd             varchar(2048);
    declare DynSql          varchar(2048);
    declare ref_cursor_txt  varchar(512) default
        'select WHLIB, WHPNAM, WHTEXT, WHLNAM, WHFNAM, WHOTYP
        from ' ;

    -- Effective library for the REFS / PGM_REFS_VISITED tables
    declare RefsLib         varchar(128);
    declare AlreadyVisited  integer default 0;

    -- Our cross ref fields for the REFS file
    declare CALLER_LIBRARY varchar(10);
    declare CALLER_NAME    varchar(10);
    declare CALLER_TYPE    varchar(10);
    declare CALLER_TEXT    varchar(30);
    declare USES_LIBRARY   varchar(10);
    declare USES_NAME      varchar(10);
    declare USES_TYPE      varchar(10);

    declare duplicate_object condition for sqlstate '23505';
    declare QCMDEXC_Failure condition for sqlstate '38501';
    declare ref_cursor cursor for ref_cursor_stmt;

    declare continue handler for duplicate_object
        begin
            set my_sqlstate = duplicate_key;
        end;
    declare continue handler for QCMDEXC_Failure
        begin
            set error_msg = 'DSPPGMREF failed ' concat sqlstate;
        end;

    -- Which library holds REFS / PGM_REFS_VISITED. Run PGM_REFS_INIT
    -- once to create them there (see pgm_refs_init.sql). Defaults to
    -- CURRENT_SCHEMA so CALL PGM_REFS(lib, pgm) still works with no
    -- extra argument if you ran PGM_REFS_INIT from that same schema.
    set RefsLib = coalesce(trim(p_RefsLib), current_schema);

    -- Safety valve for very deep or unexpectedly cyclic systems. The
    -- VISITED check below already stops genuine cycles; this is a
    -- second net so we never get near the engine's own SQL PL
    -- recursion limit.
    if p_Depth > p_MaxDepth then
        return;
    end if;

    -- Memoization: have we already expanded this exact object earlier
    -- in this run? Then skip the DSPPGMREF call entirely - there is
    -- nothing new to learn, and this is what makes "diamond" shaped
    -- dependency graphs and genuine cycles cheap and safe instead of
    -- re-running the (slow) DSPPGMREF command on the same object over
    -- and over.
    set DynSql = 'select count(*) from ' concat trim(RefsLib)
        concat '.PGM_REFS_VISITED where OBJ_LIBRARY = ? and OBJ_NAME = ? and OBJ_TYPE = ?';
    prepare check_visited_stmt from DynSql;
    execute check_visited_stmt into AlreadyVisited
        using p_INLIB, p_INPGM, p_INTYPE;
    if AlreadyVisited > 0 then
        return;
    end if;

    -- Mark visited *before* we expand, so a cycle that leads back to
    -- this same object stops here instead of recursing forever.
    set DynSql = 'insert into ' concat trim(RefsLib)
        concat '.PGM_REFS_VISITED values (?, ?, ?)';
    prepare mark_visited_stmt from DynSql;
    execute mark_visited_stmt using p_INLIB, p_INPGM, p_INTYPE;

    -- Build pgm refs work file from DSPPGMREF command.
    set WrkFileOS = WrkLib
        concat trim(WrkFileOS)
        concat trim(char(p_Depth));
    set Cmd ='DSPPGMREF PGM('
        concat trim(p_INLIB)
        concat '/' concat trim(p_INPGM) concat ')'
        concat ' OBJTYPE(' concat p_INTYPE CONCAT ')'
        concat ' OUTPUT(*OUTFILE)'
        concat ' OUTFILE(' concat WrkFileOS concat ')'
        ;
    CALL QSYS2.QCMDEXC (Cmd);

    -- If DSPPGMREF failed, build a record showing error
    -- occurred and return.
    if error_msg <> ' ' then
        set DynSql = 'insert into ' concat trim(RefsLib)
            concat '.REFS values (?, ?, ?, ?, ?, ?, ?, ?)';
        prepare error_ins_stmt from DynSql;
        execute error_ins_stmt using
            p_Depth, p_INLIB, p_INPGM, p_INTYPE, error_msg,
            '*ERROR', '*ERROR', '*ERROR';
        set error_msg = ' ';
        return;
    end if;

    -- Open cursor over the outfile from DSPPGMREF
    set WrkFileSQL = WrkLib
        concat trim(WrkFileSQL)
        concat trim(char(p_Depth));
    set ref_cursor_txt = ref_cursor_txt concat WrkFileSQL;
    prepare ref_cursor_stmt from ref_cursor_txt;
    open    ref_cursor;

    set DynSql = 'insert into ' concat trim(RefsLib)
        concat '.REFS values (?, ?, ?, ?, ?, ?, ?, ?)';
    prepare refs_ins_stmt from DynSql;

    -- Read through the records from DSPPGMREF
    Refs_Loop: loop
        fetch   from ref_cursor into
         CALLER_LIBRARY
        ,CALLER_NAME
        ,CALLER_TEXT
        ,USES_LIBRARY
        ,USES_NAME
        ,USES_TYPE
        ;
        if sqlstate = no_more_data then
            leave Refs_Loop;
        end if;

        execute refs_ins_stmt using
             p_Depth
            ,CALLER_LIBRARY
            ,CALLER_NAME
            ,p_INTYPE
            ,CALLER_TEXT
            ,USES_LIBRARY
            ,USES_NAME
            ,USES_TYPE;

            -- If this exact edge already exists don't add again. This
            -- can still happen if DSPPGMREF lists the same used
            -- object more than once for the same caller (e.g. called
            -- from more than one place in the program).
            if my_sqlstate = duplicate_key then
                set my_sqlstate = ' ';
                iterate Refs_Loop;
            end if;
            -- Don't expand IBM stuff further
            if substr(USES_LIBRARY, 1, 1) = 'Q' then
                iterate Refs_Loop;
            end if;
            -- No further expansion if DSPPGMREF doesn't handle object
            if USES_TYPE not in
                ( '*PGM', '*SRVPGM', '*MODULE', '*QRYDFN', '*SQLPKG') then
                iterate Refs_Loop;
            end if;
            -- Recursively expand this object. The memoization check
            -- at the top of this procedure makes it safe to just call
            -- it even if we've already visited USES_LIBRARY/NAME/TYPE
            -- via another path - it will return immediately.
            call pgm_refs(
                USES_LIBRARY, USES_NAME, trim(USES_TYPE), p_Depth+1,
                RefsLib, p_MaxDepth);
    end loop;

    close   ref_cursor;
    set Cmd = 'DLTF FILE(' concat WrkFileOS concat ')';
    CALL QSYS2.QCMDEXC (Cmd);

    -- drop table WrkFileSQL;
end;
