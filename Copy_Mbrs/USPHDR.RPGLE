
      //=== USPHDR Description =============================================
      // The list APIs which return data in a user space put a standard
      // header at the start of the user space.  This descibes the header.
      //=== Basing Pointer for Header ======================================
     D UspPtr          s               *   inz(*Null)
      //=== User Space Header Layout =======================================
     D UspHdr          ds                  based(UspPtr)
     D UspH                         192a
     D  UspUser                      64a   overlay(UspH:1)
     D  UspSize                      10i 0 overlay(UspH:65)
     D  UspInfSts                     1a   overlay(UspH:104)
     D   UspICmpl      c                   const('C')
     D   UspIPrtl      c                   const('P')
     D   UspIIncp      c                   const('I')
     D  UspSpSize                    10i 0 overlay(UspH:105)
     D  UspInOff                     10i 0 overlay(UspH:109)
     D  UspInSize                    10i 0 overlay(UspH:113)
     D  UspHdrOfs                    10i 0 overlay(UspH:117)
     D  UspHdrSize                   10i 0 overlay(UspH:121)
     D  UspLstOfs                    10i 0 overlay(UspH:125)
     D  UspLstSize                   10i 0 overlay(UspH:129)
     D  UspLst#Ent                   10i 0 overlay(UspH:133)
     D  UspLstEntSz                  10i 0 overlay(UspH:137)

