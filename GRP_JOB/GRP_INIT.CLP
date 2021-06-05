GR_INIT: +
  PGM

/*=== Initial program to run in a programmer group job =============*/
/* Called from GRP.                                                 */
/*    Command to run is in *GDA                                     */
/*    Library list is inherited from calling job                    */
/* Simply establishes the job, does setup, and transfers back       */
/*==================================================================*/

  DCL VAR(&GDA)        TYPE(*CHAR) LEN(512)

/*== Get command to run ============================================*/
  RTVDTAARA DTAARA(*GDA) RTNVAR(&GDA)

/*=== Set my own attention program for this job ====================*/
  SETATNPGM PGM(GRP_ATN)

/*=== Fix print files to sensible defaults =========================*/
  OVRPRTF FILE(QPQXPRTF) PAGESIZE(*N 132)

/*=== And go right back to caller to continue initialization =======*/
  TFRGRPJOB GRPJOB(*PRV)

/*=== Resume here when selected from menu ==========================*/
/* -- Run the command specified in the *GDA                   */
/* -- Hitting the attention key suspends this job and invokes */
/*    the attention program.  This job may resume, or another */
/*    job may resume.                                         */
/* -- Exit from running program cleans up the environment,    */
/*    then loops back to start the program again.             */

LOOP: +
  CALL PGM(QCMDEXC) PARM(&GDA 512)
  RCLRSC
  RCLACTGRP ACTGRP(*ELIGIBLE) /* Not a good practice in production*/
  GOTO CMDLBL(LOOP)

ENDPGM: +
  ENDPGM
