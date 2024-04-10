**free
// ==============================================================
// RPG demo of the PRT program: Printing a file format listing.
// ==============================================================
//  - Uses SQL input from QSYS2.SYSCOLUMNS2 and QSYS.TABLES.
//  - Specify a single file or generic. Source files are omitted.
//  - Each file starts on a new page.
//  - Report is sorted by file and either field name or sequence.
// Parms
//  1 Library:      Char 10.
//  2 File name:    Char 10.
//                  For generic, append *, e.g., LINE* will print all
//                  all files that start with LINE.
//  3 Order         Char(1)
//                  N: sort by field name (default)
//                  S: sort by ordinal sequence of fields
// Sample call:
// CALL PGM(DEMO_RPG1) PARM((LENNONS1) (BOMMASPF) (S))
// If you plan to use this, creating a command is recommended.
ctl-opt option(*srcstmt: *nodebugio)
    bnddir('SQL_BND')
    actgrp(*new) main(Main);
/COPY ../Copy_Mbrs/PRT_P.RPGLE
/COPY ../Copy_Mbrs/SRV_SQL_P.RPGLE

dcl-proc Main;
    dcl-pi Main;
        pi_library  char(10);
        pi_filelike char(10);
        pi_order    char(1);
    end-pi;
    dcl-c SQLSUCCESS    '00000';
    dcl-c SQLNODATA     '02000';
    dcl-c SQLNOMOREDATA '02000';

    dcl-s theLibrary    varchar(10) ;
    dcl-s theFile       varchar(10);
    dcl-s theSeq        char(1) inz('N');
    dcl-s lastFile      char(10) inz(' ');
    dcl-s eofSW         ind inz(*off);

    dcl-ds   inSQL  qualified ;  // SQL data returned here
        library     char(10);
        file        char(10);
        file_desc   char(50);
        field_name  char(10);
        type        char(8);
        length      int(10);
        decimals    int(10);
        field_desc  char(50);
        col_head    char(60);
        seq         int(10);
    end-ds;

    dcl-ds  line len(132)   qualified;   // Line layout
        seq     char(4);
        *n      char(2);
        field_name  char(10);
        *n      char(2);
        type    char(8);
        *n      char(2);
        length  char(10);
        *n      char(2);
        decimal char(3);
        *n      char(2);
        text    char(50);
    end-ds;

    dcl-ds h1 qualified;            // Header 1
        *n char(15)  inz('Field Listing: ');
        lib_file char(21);
        file_desc char(50);
    end-ds;

    dcl-ds h2    likeds(line);      // Header 2 layout.

    exsr init;

    // Set up second heading line
    h2.seq = ' Seq';
    h2.field_name = 'Field Name';
    h2.type = 'Type';
    h2.length = 'Length';
    h2.decimal = 'Dec';
    h2.text = 'Description';
    PRT(h2 : '*H2: S2');

    // Underline second heading line
    h2.seq = *all'_';
    h2.field_name = *all'_';
    h2.type = *all'_';
    h2.length = *all'_';
    h2.decimal = *ALL'_';
    h2.text = *all'_';
    PRT(h2 : '*H3: S0');

    // === Loop through the data and print lines
    // === Skip to new page if library changes
    exsr fetch;
    dow (eofSW = *off);
        if (inSQL.file <> lastFile);
            PRT(' ' : '*NEWPAGE');
            h1.lib_file = %trim(inSQL.library) + '/' + inSQL.file;
            h1.file_desc = inSQL.file_desc;
            PRT(h1  : '*H1: *P');
            lastFile = inSQL.file;
        endif;
        // Fill line with the rest of the data
        evalr line.seq = %trim(%char(inSQL.seq));
        line.field_name = inSQL.field_name;
        line.type = inSQL.type;
        evalr line.length = %trim(%char(inSQL.length));
        if (inSQL.decimals >=0);
            evalr line.decimal = %trim(%char(inSQL.decimals));
        else;
            line.decimal = ' ';
        endif;
        line.text  = inSQL.field_desc;

        PRT(line);
        exsr fetch;
    enddo;
    PRT(' '  : '*NEWPAGE');
    PRT('SQL parms: Library-' + theLibrary +
        ' File-' + theFile + ' Order-' + theSeq: 'S2');
    PRT('** End of Report **' : 'S2');
    PRT(' ' : '*CLOSE');
    return;

    // ==============================================================
    // === Initial Paramets and SQL setup ===========================
    begsr init;
        // === Process paramters
        if (%parms = 0);  //no parms, set defaults for testing
            theLibrary = 'LENNONS1';
            theFile = 'ECL*';
            theSeq = 'S';
        endif;
        if (%parms = 1 ) ;
            theLibrary = %upper(%trim(pi_library));
            theFile = 'ECL*';
            theSeq = 'S';
        endif;
        if (%parms = 2);
            theLibrary = %upper(%trim(pi_library));
            theFile = %upper(%trim(pi_filelike));
            theSeq = 'S';
        endif;
        if (%parms = 3);
            theLibrary = %upper(%trim(pi_library));
            theFile = %upper(%trim(pi_filelike));
            theSeq = %upper(pi_order);
        endif;

        // === Handle generic file
        theFile = %xlate('*' : '%' : theFile);

        exec sql set option datfmt=*iso,
                     closqlcsr=*endmod,
                     commit=*none;

        // === Cursor to get the data
        exec sql declare  data_cursor cursor for
        SELECT TABLE_SCHEMA as library
            ,cols.SYSTEM_TABLE_NAME AS file_name
            ,char(tbls.TABLE_TEXT, 50) as file_desc
            ,cols.SYSTEM_COLUMN_NAME AS field_name
            ,char(cols.DATA_TYPE, 8) AS type
            ,cols.LENGTH
            ,cOALESCE(cols.NUMERIC_SCALE, -1) AS decimals
            ,char(coalesce(cols.COLUMN_TEXT, ' '), 50) as field_desc
            ,cHAR(COALESCE(cols.COLUMN_HEADING, ' '), 60) AS col_head
            ,cols.ORDINAL_POSITION AS seq
        FROM QSYS2.SYSTABLES tbls
        JOIN QSYS2.SYSCOLUMNS2 cols
            using (TABLE_SCHEMA, TABLE_NAME)
        WHERE TABLE_SCHEMA = :theLibrary
            AND tbls.FILE_TYPE <> 'S' // omit source files
            AND trim(cols.SYSTEM_TABLE_NAME) like :theFile
        ORDER BY cols.SYSTEM_TABLE_NAME,
              case :theSeq
                when 'N'  then cols.SYSTEM_COLUMN_NAME
                else  digits(cols.ORDINAL_POSITION)
              end
        ;
        //== Open cursor
        exec sql open  data_cursor;
        if (sqlstate <> SQLSUCCESS);
            SQLProblem('Open failed');
        endif;
    endsr;

    // === Fetch next row from cursor ===============================
    begsr fetch;
        exec sql fetch data_cursor into :inSQL;
        if (sqlstate = SQLNOMOREDATA);
            eofSW = *on;
            leavesr;
        endif;
        if (sqlstate = SQLSUCCESS);
            eofSW = *off;
            leavesr;
        else;
            SQLProblem('Fetch failed');
        endif;
    endsr;

end-proc Main;
