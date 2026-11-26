-- DEPRECATED in this fork: PGM_REFS_INIT (pgm_refs_init.sql) now
-- creates this table (and a PGM_REFS_VISITED table) in the library
-- you pass as a parameter, so you no longer need to hand-edit this
-- file or the procedure. Kept here for reference only.
--
-- Table created by the PGM_REFS SQL procedure
-- Change LENNONSB to your library name to suit and make
-- a similar change in PGM_REFS.
DROP TABLE LENNONSB.REFS;
create or replace  TABLE LENNONSB.REFS (
     DEPTH          integer
    ,CALLER_LIBRARY VarCHAR(10) NOT NULL
    ,CALLER_NAME    VarCHAR(10) NOT NULL
    ,CALLER_TYPE    VarCHAR(10) NOT NULL
    ,CALLER_TEXT    Varchar(30) NOT NULL
    ,USES_LIBRARY   VarCHAR(10) NOT NULL
    ,USES_NAME      VarCHAR(10) NOT NULL
    ,USES_TYPE      VarCHAR(10) NOT NULL
    ,CONSTRAINT     LENNONSB.refs_pk PRIMARY KEY (
        CALLER_LIBRARY
        ,CALLER_NAME
        ,CALLER_TYPE
        ,USES_LIBRARY
        ,USES_NAME
        ,USES_TYPE
    )
);
