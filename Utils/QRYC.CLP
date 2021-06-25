/*  Gives a quick and dirty look at the contents of a file.          */
/*  Front end to "RUNQRY *NONE filename" to save me entering *NONE.  */
/*  (I'm lazy...)                                                    */
/*  You can also enter selection criteria if you so desire.          */

/*  Use the QRY command to invoke this program                      */

             PGM        PARM(&PI_FILE &PI_SEL)
             DCL        VAR(&PI_FILE) TYPE(*CHAR) LEN(20)
             DCL        VAR(&PI_SEL) TYPE(*CHAR) LEN(1)

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SEL) TYPE(*CHAR) LEN(4) VALUE(*NO)

             CHGVAR     VAR(&FILE) VALUE(%SST(&PI_FILE 1 10))
             CHGVAR     VAR(&LIB) VALUE(%SST(&PI_FILE 11 10))

             IF         COND(&PI_SEL = 'Y') THEN(CHGVAR VAR(&SEL) +
                          VALUE(*YES))

             RUNQRY     QRY(*NONE) QRYFILE((&LIB/&FILE)) RCDSLT(&SEL)
             ENDPGM
