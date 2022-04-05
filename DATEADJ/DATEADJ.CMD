             CMD        PROMPT('Add/Sub from a Date')
/* ================================================================*/
/*  DATEADJR is the command processing program                     */
/*  CRTCMD CMD(DATEADJ) PGM(*LIBL/DATEADJR) SRCFILE(DATEADJ)       */
/*  ALLOW(*IPGM *BPGM *IMOD *IPGM)  HLPPNLGRP(DATEADJP)            */
/*  HLPID(*CMD)                                                    */
/* ================================================================*/
             PARM       KWD(INDATE) TYPE(*CHAR) DFT('*JOBDATE') +
                          MIN(0) PROMPT('Input Date')

             PARM       KWD(OUTDATE) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) MIN(1) PROMPT('Output Date')

             PARM       KWD(ADJAMT) TYPE(*DEC) LEN(5) DFT(1) +
                          PROMPT('Amount to adjust by')

             PARM       KWD(ADJTYPE) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          DFT(*DAYS) VALUES(*DAYS *MONTHS *YEARS) +
                          PROMPT('Adjustment type')

             PARM       KWD(INFMT) TYPE(*CHAR) LEN(10) RSTD(*YES) +
                          DFT('*JOBFMT') VALUES('*JOBFMT'  +
                          '*YMD' '*MDY' '*DMY' +
                          '*YMD0' '*MDY0' '*DMY0' +
                          '*CYMD' '*CMDY' '*CDMY' +
                          '*CYMD0' '*CMDY0' '*CDMY0' +
                          '*ISO' '*USA' '*EUR' '*JIS'  +
                          '*ISO0' '*USA0' '*EUR0' '*JIS0'  +
                          '*JUL' '*LONGJUL' '*SYSTEM') PROMPT('Input Date +
                          Format')

             PARM       KWD(OUTFMT) TYPE(*CHAR) LEN(10) RSTD(*YES) +
                          DFT('*INFMT') VALUES('*JOBFMT'  +
                          '*YMD' '*MDY' '*DMY' +
                          '*YMD0' '*MDY0' '*DMY0' +
                          '*CYMD' '*CMDY' '*CDMY' +
                          '*CYMD0' '*CMDY0' '*CDMY0' +
                          '*ISO' '*USA' '*EUR' '*JIS'  +
                          '*ISO0' '*USA0' '*EUR0' '*JIS0'  +
                          '*JUL' '*LONGJUL' '*SYSTEM' '*INFMT') +
                          PROMPT('Output Date Format')
