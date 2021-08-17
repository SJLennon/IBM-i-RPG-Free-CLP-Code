/* Command ...... : MOVPGMMSG - Move Program Messages             */
/* CPP .......... : QMHMOVPM                                      */
/* Author ....... : Brian Rusch                                   */
/*                                                                */
/* This is a command interface over IBM's API.                    */
/*                                                                */
/* Published in Four Hundred Guru on May 2, 2012                  */
/* No warranties expressed or implied. Use at your own risk.      */
/*                                                                */
/* Compile with ALLOW(*BPGM *IPGM *BMOD *IMOD)                    */
/* CRTCMD CMD(MOVPGMMSG) PGM(QMHMOVPM) SRCFILE(yourlib/srcfile)   */
/*  ALLOW(*BPGM *IPGM *BMOD *IMOD)                                */


            CMD        PROMPT('Move Program Messages')

            PARM       KWD(MSGKEY) TYPE(*CHAR) LEN(4) CONSTANT(' ')

            PARM       KWD(MSGTYPE) TYPE(*CHAR) LEN(10) RSTD(*YES) +
                         DFT(*DIAG) VALUES(*COMP *DIAG *ESCAPE +
                         *INFO) PROMPT('Message type')

            PARM       KWD(NBRTYPS) TYPE(*INT4) CONSTANT(1)

            PARM       KWD(TOPGMQ) TYPE(*CHAR) LEN(10) RSTD(*YES) +
                         DFT(*PGMBDY) VALUES(* *CTLBDY *PGMBDY) +
                         PROMPT('Call stack entry')

            PARM       KWD(UPSTKCNT) TYPE(*INT4) CONSTANT(1)

            PARM       KWD(ERRCOD) TYPE(*CHAR) LEN(8) +
                         CONSTANT(X'0000000800000000')
