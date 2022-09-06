 /*=== Demo a more complex report ================================*/
 /* List files & members with record count and description.  */
 /* Has heading lines, an underscored heading & page number. */
 PGM
    DCL (&LINE)  (*CHAR) LEN(132)
    /* Define data columns in &LINE */
    DCL (&LIB)   (*CHAR) STG(*DEFINED) LEN(10) DEFVAR(&LINE)
    DCL (&FILE)  (*CHAR) STG(*DEFINED) LEN(10) DEFVAR(&LINE 12)
    DCL (&MBR)   (*CHAR) STG(*DEFINED) LEN(10) DEFVAR(&LINE 33)
    DCL (&RCDS)  (*CHAR) STG(*DEFINED) LEN(8)  DEFVAR(&LINE 44)
    DCL (&TEXT)  (*CHAR) STG(*DEFINED) LEN(50) DEFVAR(&LINE 53)
    DCL (&UNDER) (*CHAR) LEN(60) +
         VALUe('____________________________________________________________')
   /* Create some data */
    DCLF  FILE(QAFDMBRL)
    DSPFD FILE(*CURLIB/Q*) TYPE(*MBRLIST) +
            OUTPUT(*OUTFILE) FILEATR(*PF) +
            OUTFILE(QTEMP/MBRLIST)
    OVRDBF FILE(QAFDMBRL) TOFILE(QTEMP/MBRLIST)

    /* Define heading lines.  Second heading is underscored */
    PRTLN      LINE('Member List') HEADING(Y) HEAD(1 Y)

    CHGVAR     (&LIB)   ('Library')
    CHGVAR     (&FILE)  ('File')
    CHGVAR     (&MBR)   ('Member')
    CHGVAR     (&RCDS)  ('#Records')
    CHGVAR     (&TEXT)  ('Description')
    PRTLN      LINE(&LINE) HEADING(Y) HEAD(2)

    CHGVAR     (&LIB)   (&UNDER)
    CHGVAR     (&FILE)  (&UNDER)
    CHGVAR     (&MBR)   (&UNDER)
    CHGVAR     (&RCDS)  (&UNDER)
    CHGVAR     (&TEXT)  (&UNDER)
    PRTLN      LINE(&LINE) SPACE(S0) HEADING(Y) HEAD(3)

/* Loop thru the data and print */
 LOOP:
   RCVF     RCDFMT(QWHFDML)
      MONMSG   MSGID(CPF0864) EXEC(GOTO CMDLBL(EOF))
      CHGVAR   (&LIB)   (&MLLIB)
      CHGVAR   (&FILE)  (&MLFILE)
      CHGVAR   (&MBR)   (&MLNAME)
      CHGVAR   (&RCDS)  (%CHAR(&MLNRCD))
      CHGVAR   (&TEXT)  (&MLMTXT)
      PRTLN   LINE(&LINE)
   GOTO    CMDLBL(LOOP)
 EOF: PRTLN CONTROL(*CLOSE)
    ENDPGM
