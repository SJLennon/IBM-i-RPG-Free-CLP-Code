-- Test DATE_CYMD UDF
set path   lennons1;  -- Change to your library
set schema session;   -- QTEMP

declare global temporary TABLE test_cymd (
    Date_7 NUM(7) ,Date_7Char CHAR(7)
);
insert into test_cymd values(0480321, '0480321');
insert into test_cymd values(0010101, '0010101');
insert into test_cymd values(1480321, '1480321');
insert into test_cymd values(1720229, '1720229');
insert into test_cymd values(1710229, '1710229'); --bad
insert into test_cymd values(0210321, '0210321');
insert into test_cymd values(0210332, '0210332'); --bad
insert into test_cymd values(null, null);

SELECT Date_7
       ,date_cymd(Date_7) AS True_7
       ,Date_7Char
       ,date_cymd(date_7Char) AS True_7Char
FROM test_cymd;

