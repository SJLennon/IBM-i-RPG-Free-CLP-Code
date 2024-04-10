 -- Creates CUSTMAST and Indexes -------------------------------
 -- Can then  "CALL LOADCUST2 nnn" to load nnn random records.

 -- 02/2024 Change CustID to char to allow alpha/numeric keys
 
 set schema lennons1;  -- <<<<< Change to your library <<<<<<
 DROP TABLE custmast;

CREATE TABLE custmast (
    CustID CHAR(4) NOT NULL
    ,Name CHAR(40) NOT NULL
    ,Addr CHAR(40) NOT NULL
    ,City CHAR(20) NOT NULL
    ,State CHAR(2) NOT NULL
    ,Zip CHAR(10) NOT NULL
    ,CorpPhone CHAR(20) DEFAULT ' '
    ,AcctMgr CHAR(40) DEFAULT ' '
    ,AcctPhone CHAR(20) DEFAULT ' '
    ,Active CHAR(1) DEFAULT 'Y'
    ,ChgTime TIMESTAMP not null DEFAULT CURRENT_TIMESTAMP
    ,ChgUser varchar(18) not null DEFAULT USER
,PRIMARY KEY (Custid)
)
RCDFMT CUSTMASTF;
-- Indexes --
drop index if exists custmast_name;
create index custmast_name on custmast(name);
drop index if exists custmast_city;
create index custmast_city on custmast(city);
drop index if exists custmast_state;
create index custmast_state on custmast(state);
