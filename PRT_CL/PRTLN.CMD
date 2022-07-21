 PRTLN:      CMD        PROMPT('Print a line ')
/* ================================================================*/
/*  PRTLNC is the command processing program                       */
/*  CRTCMD CMD(PRTLN) PGM(*LIBL/PRTLNC) SRCFILE(PRT_CL)            */
/*     VLDCKR(*LIBL/PRTLNCV)                                       */
/*     ALLOW(*IPGM *BPGM *IMOD *IPGM *INTERACT)                    */
/*     HLPPNLGRP(PRTLNP) HLPID(*CMD)                               */
/* ================================================================*/
             PARM       KWD(LINE) TYPE(*CHAR) LEN(132) MIN(0) +
                          EXPR(*YES) PROMPT('Line text')

             PARM       KWD(SPACE) TYPE(*CHAR) LEN(2) RSTD(*YES) +
                          DFT(S1) VALUES('S1' 'S2' 'S3' 'S0') +
                          MIN(0) PROMPT('Line spacing')

             PARM       KWD(HEADING) TYPE(*CHAR) LEN(1) RSTD(*YES) +
                          DFT(N) VALUES(Y N) PROMPT('Defining +
                          heading line?')

             PARM       KWD(HEAD) TYPE(HDEF) PMTCTL(HEAD) +
                          PROMPT('Heading definitions')
             PARM       KWD(CONTROL) TYPE(*CHAR) LEN(10) RSTD(*YES) +
                          VALUES(*NEWPAGE *CLOSE) PMTCTL(CTRL) +
                          PROMPT('Non-printing control functions')

 HDEF:       ELEM       TYPE(*CHAR) LEN(1) DFT(1) RANGE(1 9) MIN(0) +
                          PROMPT('Header line number')
             ELEM       TYPE(*CHAR) LEN(1) RSTD(*YES) DFT(N) +
                          VALUES(N Y) PROMPT('Include page number')

 HEAD:       PMTCTL     CTL(HEADING) COND((*EQ 'Y'))
 CTRL:       PMTCTL     CTL(LINE) COND((*EQ ' '))

