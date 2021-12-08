
       //=== Prototypes for SRV_MSG routines ========================
       //============================================================
     D SndMsgPgmQ      pr                                                       Send Msg to PGM Q
     D  pMsgQ                        10
     D  pMsgid                        7
     D  pMsgFile                     10
     D  pMsgDta                      80    options(*NOPASS)
     D                                     Varying
       //============================================================
     D ClrMsgPgmQ      pr              N                                        Clear PGM Msg Q
     D pPgmMsgQ                      10

       //============================================================
     D SndEscMsg       pr                                                       Send ESC Msg
     D piMsg                        512a   Const Varying

       //============================================================
     D SndInfMsg       pr                                                       Send INF Msg
     D piMsg                        512a   Const Varying

       //============================================================
     D JobLogMsg       Pr
     D piMsg                        512a   Value Varying                        Msg to job log

       //============================================================
     D Show            pr                  extpgm('SHOW')                       Show popup msg
     D piPext                      8192a   Const Varying
     D piMsgId                        7a   Const options(*NOPASS)
     d piMsgFile                     21a   Const options(*NOPASS)


       //=== End of Prototypes forSRV_MSG Routines ==================
