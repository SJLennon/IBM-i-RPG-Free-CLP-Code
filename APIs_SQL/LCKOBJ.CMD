 LCKOBJ:     CMD        PROMPT('Get a lock on an object')
 /*-----------------------------------------------------------------*/
 /* CPP is LCKOBJC                                                  */
 /* 02/00/97 LENNON Original writting                               */
 /*-----------------------------------------------------------------*/
             PARM       KWD(OBJ) TYPE(OBJSTUFF) MIN(1) +
                          PROMPT('Object Name')

             PARM       KWD(WAIT) TYPE(*DEC) LEN(5) DFT(*CLS) +
                          RANGE(30 32767) SPCVAL((*CLS 99999) (0)) +
                          PROMPT('Seconds to wait')

             PARM       KWD(OPMAYCAN) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          DFT(*NO) VALUES(*YES *NO) PROMPT('May +
                          operator cancel job?')

OBJSTUFF:    ELEM       TYPE(Q1) MIN(1) PROMPT('Object Name')

             ELEM       TYPE(*CHAR) LEN(8) RSTD(*YES) VALUES(*AUTL +
                          *BNDDIR *CLD *CRQD *CSI *CSPMAP *CSPTBL +
                          *DEVD *DTAARA *DTADCT *DTAQ *FCT *FILE +
                          *FNTRSC *FNTTBL *FORMDF *IPXD *LIB +
                          *LOCALE *MENU *MODULE *MSGQ *NODL *NTBD +
                          *NWSD *OVL *PAGDFN *PAGSEG *PDG *PGM +
                          *PNLGRP *PSFCFG *QMFORM *QMQRY *QRYDFN +
                          *SBSD *SCHIDX *SQLPKG *SRVPGM *SSND *S36 +
                          *USRIDX *USRQ *USRSPC *WSCST) MIN(1) +
                          PROMPT('Object Type')

             ELEM       TYPE(*CHAR) LEN(8) RSTD(*YES) VALUES(*SHRRD +
                          *SHRNUP *SHRUPD *EXCLRD *EXCL) MIN(1) +
                          PROMPT('Lock state')

             ELEM       TYPE(*NAME) LEN(10)  +
                          EXPR(*NO) PROMPT('Member, if data base file')

 Q1:         QUAL       TYPE(*NAME) LEN(10) MIN(1)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL) (*CURLIB)) PROMPT('Library')
