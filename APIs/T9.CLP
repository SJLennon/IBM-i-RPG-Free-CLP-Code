             PGM
             DCL        VAR(&MSG) TYPE(*CHAR) LEN(200)
             GETOBJUSR  OBJECT(QIWS/QCUSTCDT) TYPE(*FILE) +
                          MSGFLD(&MSG) RETFILE(*YES)
             SNDMSG     MSG(&MSG) TOUSR(*REQUESTER)
             ENDPGM
