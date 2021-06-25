 RC:         CMD        PROMPT('Display Record Count')
 /* CPP is RCC.                                                    */
             PARM       KWD(FILE) TYPE(Q1) PROMPT('File Name')
             PARM       KWD(MBR) TYPE(*NAME) LEN(10) DFT(*FIRST) +
                          SPCVAL((*FIRST)) MIN(0) PROMPT('Member')
 Q1:         QUAL       TYPE(*NAME) LEN(10) MIN(1)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL) (*CURLIB)) PROMPT('Library')
