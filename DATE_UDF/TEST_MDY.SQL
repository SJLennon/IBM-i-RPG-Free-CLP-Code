-- Test DATE_MDY UDF
set path   lennons1;  -- Change to your library
set schema session;   -- QTEMP

declare global temporary TABLE test_mdy (
    Date_6 NUM(6) ,Date_6Char CHAR(6),
    Date_8 NUM(8), Date_8Char CHAR(8)
);
insert into test_mdy values(031748, '031748', 03171948, '03171948');
insert into test_mdy values(031721, '031721', 03172021, '03172021');
insert into test_mdy values(033248, '033248', 03321948, '03321948');
insert into test_mdy values(null, null, null, null);

SELECT Date_6
       ,date_mdy(Date_6) AS True_6
       ,Date_6Char
       ,date_mdy(date_6Char) AS True_6Char
       ,Date_8
       ,date_mdy(date_8) AS True_8
       ,Date_8Char
       ,date_mdy(date_8Char) AS True_8Char
FROM test_mdy;
