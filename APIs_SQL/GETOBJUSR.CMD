 GETOBJUSR:  CMD        PROMPT('Get Users of an Object')
 /*-----------------------------------------------------------------*/
 /* CPP is GETOBJUC                                                 */
 /* Compile:                                                        */
 /*   CRTCMD CMD(GETOBJUSR) PGM(GETOBJUC)                           */
 /*         ALLOW(*BPGM *IPGM *BMOD *IMOD)                          */
 /*-----------------------------------------------------------------*/
 /* 12/00/97 LENNON Original writting                               */
 /*-----------------------------------------------------------------*/
             PARM       KWD(OBJECT) TYPE(Q1) MIN(1) PROMPT('Object +
                          Name')

             PARM       KWD(TYPE) TYPE(*CHAR) LEN(10) RSTD(*YES) +
                          VALUES(*ALRTBL *AUTL *BNDDIR *CFGL +
                          *CHTFMT *CLD *CLS *CMD *CNNL *COSD *CRQD +
                          *CSI *CSPMAP *CSPTBL *CTLD *DEVD *DOC +
                          *DTAARA *DTADCT *DTAQ *EDTD *EXITRG *FCT +
                          *FILE *FLR *FNTRSC *FNTTBL *FORMDF *FTR +
                          *GSS *IPXD *JOBD *JOBQ *JOBSCD *JRN +
                          *JRNRCV *LIB *LIND *LOCALE *MENU *MODD +
                          *MODULE *MSGF *MSGQ *M36 *M36CFG *NODL +
                          *NTBD *NWID *NWSD *OUTQ *OVL *PAGDFN +
                          *PAGSEG *PDG *PGM *PNLGRP *PRDAVL *PRDDFN +
                          *PRDLOD *PSFCFG *QMFORM *QMQRY *QRYDFN +
                          *SBSD *SCHIDX *SPADCT *SQLPKG *SRVPGM +
                          *SSND *S36 *TBL *USRIDX *USRPRF *USRQ +
                          *USRSPC *WSCST) MIN(1) PROMPT('Object Type')

             PARM       KWD(MEMBER) TYPE(*NAME) LEN(10) DFT(*ALL) +
                          SPCVAL((*ALL) (*FIRST) (*NONE)) +
                          PMTCTL(ISFILE) PROMPT('Member')

             PARM       KWD(RETMSG) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          DFT(*YES) VALUES(*YES *NO) PROMPT('Return +
                          a message?')

             PARM       KWD(MSGFLD) TYPE(*CHAR) LEN(200) +
                          RTNVAL(*YES) PMTCTL(RETMSGY) +
                          PROMPT('Return Message Field')

             PARM       KWD(RETFILE) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          DFT(*NO) VALUES(*YES *NO) PROMPT('Return +
                          file QTEMP/GETOBJUSRP?')

 Q1:         QUAL       TYPE(*NAME) LEN(10) MIN(1)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL) (*CURLIB)) PROMPT('Library')

 RETMSGY:    PMTCTL     CTL(RETMSG) COND((*EQ *YES))
 ISFILE:     PMTCTL     CTL(TYPE) COND((*EQ *FILE))
