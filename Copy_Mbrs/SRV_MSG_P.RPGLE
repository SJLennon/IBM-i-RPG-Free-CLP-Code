
       //=== Prototypes for SRV_MSG routines ========================
       //============================================================
       dcl-pr SndMsgPgmQ;   // Send Msg to PGM Q
        *n char(10);                      // pMsgQ
        *n char(7);                       // pMsgid
        *n char(10);                      // pMsgFile
        *n varchar(512) options(*nopass); // pMsgDta
       end-pr;
       //============================================================
       dcl-pr ClrMsgPgmQ ind; // Clear PGM Msg Q
        *n char(10);            // pPgmMsgQ
       end-pr;
       //============================================================
       dcl-pr SndEscMsg;        // Send ESC Msg
        *n varchar(512) const;             // piMsg
        *n int(10) const options(*nopass); // pStackEnt
       end-pr;
       //============================================================
       dcl-pr SndInfMsg;        // Send INF Msg
        *n varchar(512) const;    // piMsg
       end-pr;
       //============================================================
       dcl-pr JobLogMsg;
        *n varchar(512) value; // piMsg  Msg to job log
       end-pr;
       //============================================================
       dcl-pr Show extpgm('SHOW'); // Show popup msg
        *n varchar(8192) const; // piPext
        *n char(7) const options(*nopass); // piMsgId
        *n char(21) const options(*nopass); // piMsgFile
       end-pr;
       //=== End of Prototypes forSRV_MSG Routines ==================
