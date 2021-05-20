-- Test DATE_YMD UDF
set path   lennons1;  -- Change to your library
set schema session;   -- QTEMP

declare global temporary TABLE test_ymd (
    Date_6 NUM(6) ,Date_6Char CHAR(6),
    Date_8 NUM(8), Date_8Char CHAR(8)
);
insert into test_ymd values(480321, '480321', 19480321, '19480321');
insert into test_ymd values(210317, '210317', 20210317, '20210317');
insert into test_ymd values(200229, '200229', 20200229, '20200229');
insert into test_ymd values(210229, '210229', 20210229, '20210229');
insert into test_ymd values(480332, '480332', 19480332, '19480332');
insert into test_ymd values(null, null, null, null);

SELECT Date_6
       ,date_ymd(Date_6) AS True_6
       ,Date_6Char
       ,date_ymd(date_6Char) AS True_6Char
       ,Date_8
       ,date_ymd(date_8) AS True_8
       ,Date_8Char
       ,date_ymd(date_8Char) AS True_8Char
FROM test_ymd;

