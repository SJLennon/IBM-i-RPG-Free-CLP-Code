GRP: +
  PGM
/*==============================================================*/
/* Start-up group jobs suitable for a programmer.               */
/*==============================================================*/

  DCL VAR(&DFTLIBLPGM) TYPE(*CHAR) LEN(10)    VALUE('GRP_LIBL')
  DCL VAR(&DFTLIBLLIB) TYPE(*CHAR) LEN(10)    VALUE('LENNONS1')

  CHGJOB CCSID(37)

/*=== Set my library list ======================================*/
  CALL PGM(&DFTLIBLLIB/&DFTLIBLPGM)

/*=== Set QPQXPRTF to a sensible line length ===================*/
/* Defined by IBM as 80--132 is more practical */
  OVRPRTF FILE(QPQXPRTF) PAGESIZE(*N 132)

/*=== Change this job to a group job ===========================*/
  CHGGRPA GRPJOB(QCMD__1) TEXT('QCMD - 1')
  MONMSG MSGID(CPF1305) /* Already a group job with a name */

/*=== Start other group jobs. Command to run is in *GDA ========*/
/* Each job runs GRP_INIT which immediately transfers back */

  CHGDTAARA DTAARA(*GDA) VALUE('GO ASSIST')
  TFRGRPJOB GRPJOB(ASSIST) INLGRPPGM(*LIBL/GRP_INIT) TEXT('Oper+
     ational Assistant')

  CHGDTAARA DTAARA(*GDA) VALUE('Call QCMD')
  TFRGRPJOB GRPJOB(QCMD__2) INLGRPPGM(*LIBL/GRP_INIT) TEXT('QCMD - 2')

  CHGDTAARA DTAARA(*GDA) VALUE(STRPDM)
  TFRGRPJOB GRPJOB(PDM_2) INLGRPPGM(*LIBL/GRP_INIT) TEXT('PDM - 2')

  CHGDTAARA DTAARA(*GDA) VALUE(STRPDM)
  TFRGRPJOB GRPJOB(PDM_1) INLGRPPGM(*LIBL/GRP_INIT) TEXT('PDM - 1')

/*=== Set my own attention program for this job ================*/
  SETATNPGM PGM(*LIBL/GRP_ATN)

/*=== Any jobs added with F6 will start in QCMD ================*/
  CHGDTAARA DTAARA(*GDA) VALUE('Call QCMD')

/*=== Start QCMD for this job ==================================*/
/* On F3 from QCMD, cleans up environment and loops back */
LOOP: +
  CALL PGM(QCMD)
  RCLRSC
  RCLACTGRP ACTGRP(*ELIGIBLE) /* May not be a good practice */
  GOTO CMDLBL(LOOP)

  ENDPGM
