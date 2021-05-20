# DATE_UDF - SQL **U**ser **D**efined **F**unctions to Convert a Legacy Date to a True Date

Legacy databases on the IBM i stored dates in numeric (or character) fields. Doing validation or arithmetic on such fields was complex.  IBM finally added a true date type to the database as Y2K approached.

 After Y2K, many of these dates still existed in databases. I developed these SQL UDFs to convert a legacy date to a true date, largely so I could do date arithmetic.  For example:

    SELECT ...  FROM CUSTMAST WHERE DATE_YMD(DUEDATE) <= CURDATE() - 9O DAYS 

 The most common formats where month-day-year (in the USA) and year-month-day. Often there was no century included.  There was also an IBM sanctioned format, CYMD, where the C was a 1-digit century, with 0 meaning 19, and 1 meaning 20.

## Development

What these functions do can also be done, with some work, directly in SQL. And I'm aware there are other open source date UDFs avaliable, e.g. [iDate](https://www.think400.dk/downloads.htm).

However...

1. When I wrote this I was not aware of any similar functions, and there may not have been any. (Though I probably got the idea from [Scott Klement](https://www.scottklement.com/udtf/)).
2. This is an efficient, light weight implementation in RPG.
3. Each function requires only 1 parameter and I like that convenience.
4. The code demonstrates creating an SQL UDF in RPG.

## Functions

There are three functions,each taking a numeric field as input. *Note:* Newer versions of SQL will automatically cast character fields to numeric, otherwise you have to cast to numeric manually.

* **DATE_YMD** to convert dates in either YYMMDD or CCYYMMD format.
  * Example: 980129 or 19980129.
  * Example: 210319 or 20210319

* **DATE_MDY** to convert dates in MMDDYY or MMDDCCYY format.
  * Example: 012998 or 01291998
  * Example: 031921 or 03192021

* **DATE_CYMD** to convert dates in CYYMMDD format.
  * Example: 0990317
  * Example: 1210317

### Invalid Input

An invalid input value will return a null value and give a 01H99 SQLSTATE warning.

## DATE_SQL

The RPG code for the DATE_SQL service program, which contains the functions.  It is free forms but the D-Specs are still fixed, and it can be edited in SEU. (When I originally wrote it, it was in fixed form RPGIV.)

## DATE_SQLFR

This is DATE_SQL but converted to totally free form. I converted it using [RpgFreeWeb](https://github.com/worksofbarry/rpgfreeweb), which does a nice job.

## DATECRTFN

This is SQL "Create Function" code that tells SQL where the functions are.

## TEST_CYMD/TEST_MDY/TEST_YMD

There are example SQL statements that can be used to test the three functions.
