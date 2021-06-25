             CMD        PROMPT('Query a file')
/* CPP is QRYC                                                       */
             PARM       KWD(FILE) TYPE(QUAL) PROMPT('File Name')
 QUAL:       QUAL       TYPE(*NAME) MIN(1)
             QUAL       TYPE(*NAME) DFT(*LIBL) SPCVAL((*LIBL +
                          *CURLIB)) PROMPT('Library')
             PARM       KWD(SELECT) TYPE(*CHAR) LEN(1) DFT(N) +
                          PROMPT('Select? (Y/N')
