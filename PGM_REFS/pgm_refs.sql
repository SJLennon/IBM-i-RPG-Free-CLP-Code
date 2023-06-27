--  Procedure to run DPSPGMREF, then run DSPPGMREF on each of its objects
--  by calling itself recursively.
--  Result is a file named REFS containing all the objects that 
--  DSPPGMREF knows about an object, to an essentially unlimited depth.
CREATE OR REPLACE PROCEDURE PGM_REFS (
     IN p_INLIB     varCHAR(10)
    ,IN p_INPGM     varCHAR(10)
    ,IN p_INTYPE    varCHAR(10) default '*PGM'
    ,in p_Depth     integer     default(0)
    )
    LANGUAGE SQL
    NOT DETERMINISTIC
    MODIFIES SQL DATA
    SET OPTION dbgview = *source, commit = *none
begin
    -- Define DSPPGMREF library and file names
    declare WrkLib          varchar(10) default 'QTEMP'; 
    declare WrkFileOS       varchar(20) default '/WRK' ;
    declare WrkFileSQL      varchar(20) default '.WRK';

    declare sqlstate        char(5);
    declare my_sqlstate     char(5);
    declare no_more_data    char(5) default '02000';
    declare duplicate_key   char(5) default '23505';

    declare Cmd             varchar(1024);
    declare ref_cursor_txt  varchar(512) default  
        'select WHLIB, WHPNAM, WHTEXT, WHLNAM, WHFNAM, WHOTYP 
        from ' ;

    -- Our cross ref fields for the REFS file
    declare CALLER_LIBRARY varchar(10);
    declare CALLER_NAME    varchar(10);
    declare CALLER_TYPE    varchar(10);
    declare CALLER_TEXT    varchar(30);
    declare USES_LIBRARY   varchar(10);
    declare USES_NAME      varchar(10);
    declare USES_TYPE      varchar(10);
    declare USES_TEXT      varchar(30);

    declare duplicate_object condition for sqlstate '23505';
    declare ref_cursor cursor for ref_cursor_stmt;

    declare continue handler for duplicate_object
        begin
            set my_sqlstate = duplicate_key;
        end;            
      
    -- Build pgm refs work  file from DSPPGMREF command.
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
    
    -- Open cursor over the outfile from DSPPGMREF 
    set WrkFileSQL = WrkLib 
        concat trim(WrkFileSQL) 
        concat trim(char(p_Depth));
    set ref_cursor_txt = ref_cursor_txt concat WrkFileSQL;
    prepare ref_cursor_stmt from ref_cursor_txt;
    open    ref_cursor;
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
        -- <<<< Change this table library >>>>>
        insert into lennonsb.refs values (
             p_Depth
            ,CALLER_LIBRARY
            ,CALLER_NAME   
            ,p_INTYPE
            ,CALLER_TEXT   
            ,USES_LIBRARY  
            ,USES_NAME     
            ,USES_TYPE     
            );
            -- If used object already exists don't add again
            if my_sqlstate = duplicate_key then
                set my_sqlstate = ' ';
                iterate Refs_Loop;
            end if; 
            -- Don't expand IBM stuff further
            if substr(USES_NAME, 1, 1) = 'Q' then
                iterate Refs_Loop;
            end if; 
            -- No further expansion if DSPPGMREF doesn't handle object 
            if USES_TYPE not in 
                ( '*PGM', '*SRVPGM', '*MODULE', '*QRYDFN', '*SQLPKG') then
                iterate Refs_Loop;
            end if; 
            -- Recursively expand this object
            call pgm_refs(
                USES_LIBRARY, USES_NAME, trim(USES_TYPE), p_Depth+1);
    end loop; 

    close   ref_cursor;
    set Cmd = 'DLTF FILE(' concat WrkFileOS concat ')';
    CALL QSYS2.QCMDEXC (Cmd);

    -- drop table WrkFileSQL;
end;