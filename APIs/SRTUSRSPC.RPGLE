      *******************************************************************
     * From "Sort Those API Lists," NEWS/400, May 1996.
     * Author: Greg LaForge
     * COPYRIGHT (c) 1996 Duke Communications International,
     * ALL RIGHTS RESERVED.
     *
     *
     * Program:     SRTUSRSPC
     * Description: This program sorts in a user space lists
     * created by system API commands.
     *
     **************************************************************************
     * Indicators used.
     *
     *   01 - Error on CALLs. Triggers abnormal termination of program and
     *   sets return parameter EXITER to *ON.
     *
     **************************************************************************
     * Arrays.
     *
     *      AD - Array of ascending/descending sequences (passed in).
     *      DT - Array of key fields' data types.
     *      KY - Array to pass info to the sort routine.
     *      LN - Array of key lengths (passed in).
     *      ST - Array of key starting positions (passed in).
     *
     D ad              s              1    dim(10)                              ascend/descend
     D dt              s              1    dim(10)                              data type
     D ln              s              5  0 dim(10)                              lengths
     D st              s              5  0 dim(10)                              start positions
     * ************************************************************************
     * Data structures.
     *
     *      BINALP - Converts binary to alpha field.
     *      ERROR  - Formats error fields for sort APIs.
     *      INDTA  - Creates a 9,000-byte field.
     *      MISC   - Defines some binary fields.
     *      OUTDTA - Creates a 9,000-byte field.
     *      RCVVAR - Defines some binary fields for user space lists.
     *      SORT   - Formats sort control block for QLGSORT API.
     *      SORTIN - Formats input fields for QLGSRTIO API.
     *      SORTOU - Formats output fields for QLGSRTIO API.
     *
     *-----------------------------------------------------------------------
     * Converts binary to alpha field.
     *
     D binalp          ds
     D alpha                          4
     D  binary                        9b 0 overlay(alpha)
     *-----------------------------------------------------------------------
     * Formats error fields for sort APIs.
     *
     D error           ds
     D errlen                         9b 0
     D erravl                         9b 0
     D errid                          7
     D errdta                 17    272
     *-----------------------------------------------------------------------
     * Creates a 9,000-byte field.
     *
     D indta           ds          9000
     D hold                 9000   9000
     *-----------------------------------------------------------------------
     * Defines some binary fields.
     *
     D misc            ds
     D lendta                         9b 0
     D strpos                         9b 0
     D lenspc                         9b 0
     D lenvar                         9b 0
     D parm3                          9b 0
     D parm4                          9b 0
     D outlen                         9b 0
     *-----------------------------------------------------------------------
     * Creates a 9,000-byte field.
     *
     D outdta          ds          9000
     D holda                9000   9000
     *-----------------------------------------------------------------------
     * Defines some binary fields for user space lists.
     *
     D rcvvar          ds
     D offset                         9b 0
     D nbrent                  9     12b 0
     D sizent                         9b 0
     *-----------------------------------------------------------------------
     * Formats sort control block for QLGSORT API.
     *
     D sort            ds
     D  blklen                 1      4b 0
     D  reqtyp                 5      8b 0
     D  fill01                 9     12b 0
     D  option                13     16b 0
     D  rcdlen                17     20b 0
     D  rcdcnt                21     24b 0
     D  keyoff                25     28b 0
     D  keys                  29     32b 0
     D  lanoff                33     36b 0
     D  inoff                 37     40b 0
     D  #infil                41     44b 0
     D  outoff                45     48b 0
     D  #outfi                49     52b 0
     D  fill02                53     56b 0
     D  ky                    57    216
     D                                     dim(40)                              key fields
     *-----------------------------------------------------------------------
     * Formats input fields for QLGSRTIO API.
     *
     D sortin          ds
     D intype                         9b 0
     D infil1                         9b 0
     D inlen                          9b 0
     D inrecs                         9b 0
     *-----------------------------------------------------------------------
     * Formats output fields for QLGSRTIO API.
     *
     D sortou          ds
     D ourprc                         9b 0
     D ouravl                         9b 0
     D oufil1                         9b 0
     D oufil2                         9b 0
     *---------------------------------------------------------------------
     * BEGIN of work fields added by CONNECTIONS 2000's CVTILERPG utility
     *---------------------------------------------------------------------
     D #keys           s                   like(dec003    )
     D #recs           s                   like(int       )
     D byte            s              1
     D chr032          s             32
     D dec003          s              3  0
     D exiter          s                   like(byte      )
     D force           s                   like(byte      )
     D i               s                   like(int       )
     D inbuff          s                   like(chr032    )
     D int             s              9  0
     D i1              s                   like(int       )
     D i2              s                   like(int       )
     D i3              s                   like(int       )
     D i4              s                   like(int       )
     D lib             s                   like(name      )
     D name            s             10
     D oubuff          s                   like(chr032    )
     D qname           s             20
     D spacer          s                   like(qname     )
     D tmp50           s                   like(int       )
     D totrec          s                   like(int       )
     D usrspc          s                   like(name      )
     *---------------------------------------------------------------------
     * END of work fields added by CONNECTIONS 2000's CVTILERPG utility
     *---------------------------------------------------------------------
     **************************************************************************
     *
     * Mainline.
     *
     C                   exsr      inzpgm
     C                   exsr      prcpgm
     C                   exsr      trmpgm
     *
     C                   return
     *-----------------------------------------------------------------------
     * CHK4ER: Look to see whether error has occurred; if so, exit.
     *
     C     chk4er        begsr
     *
B001 C                   if        *in01 = *on                                  error in call
 001 C                             or errid <> *blanks                          returned error
 001 C                   exsr      *pssr
E001 C                   endif
     *
     C                   endsr
     *-----------------------------------------------------------------------
     * DCLVAR:  Declare program variables.
     *          This subroutine is never executed.
     *
     C     dclvar        begsr
     * Declare data types.
     C                   eval      byte = *blank
     C                   eval      chr032 = *blank
     C                   eval      dec003 = 0
     C                   eval      int = 0
     C                   eval      name = *blank
     C                   eval      qname = *blank
     *
     * Declare variables based on data types.
     *
     C                   endsr
     *-----------------------------------------------------------------------
     * INZPGM:  Initialize program.
     *
     C     inzpgm        begsr
     *
     C     *entry        plist
     C                   parm                    usrspc                         user space
     C                   parm                    lib                            user space lib
     C                   parm                    #keys                          nbr of keys
     C                   parm                    st                             start positions
     C                   parm                    ln                             lengths
     C                   parm                    ad                             ascend/descend
     C                   parm                    dt                             data types
     C                   parm                    exiter                         *ON=error
     *
     * Clear error flag.
     C                   move      *off          exiter
     *
     * Get some info in the user space header.
     C                   movel     usrspc        spacer
     C                   move      lib           spacer
     *
     C                   call      'QUSRTVUS'                           01
     C                   parm                    spacer
     C                   parm      125           strpos
     C                   parm      16            lendta
     C                   parm                    rcvvar
     *
     C                   exsr      chk4er
     *
     * Determine starting position of list in the user space.
     C                   eval      strpos = offset
     C                   eval      strpos = strpos + 1
     *
     * Initialize the sort function.
     C                   eval      blklen = #keys                               length of
     C                   eval      blklen = blklen * 16                           sort control
     C                   eval      blklen = blklen + 56                           block
     C                   eval      reqtyp = 8                                   sort type
     C                   eval      fill01 = 0                                   filler
     C                   eval      option = 0                                   no options
     C                   eval      rcdlen = sizent                              rec size
     C                   eval      rcdcnt = 0                                   no rec count
     C                   eval      keyoff = 56                                  offset to keys
     C                   eval      keys = #keys                                 # of keys
     C                   eval      lanoff = 0                                   language offset
     C                   eval      inoff = 0                                    no input files
     C                   eval      #infil = 0                                   no input files
     C                   eval      outoff = 0                                   no out files
     C                   eval      #outfi = 0                                   no out files
     C                   eval      fill02 = 0
     *
     * Fill the key field area.
B001 C     1             do        #keys         i
 001 C                   eval      i1 = i - 1
 001 C                   eval      i1 = i1 * 4
 001 C                   eval      i1 = i1 + 1
 001 C                   eval      i2 = i1 + 1
 001 C                   eval      i3 = i2 + 1
 001 C                   eval      i4 = i3 + 1
 001 *
 001 * Convert start position to binary and place into array.
 001 C                   eval      binary = st(i)
 001 C                   movel     alpha         ky(i1)
 001 *
 001 * Convert key length to binary and place into array.
 001 C                   eval      binary = ln(i)
 001 C                   movel     alpha         ky(i2)
 001 *
 001 * Convert data type to binary and place into array.
B002 C                   select
 002 C                   when      dt(i) = 'Z'                                  zoned decimal
 002 C                   eval      binary = 2
 002 C                   when      dt(i) = 'B'                                  binary
 002 C                   eval      binary = 0
 002 C                   when      dt(i) = 'P'                                  packed decimal
 002 C                   eval      binary = 3
 002 C                   other                                                  all else
 002 C                   eval      binary = 6
E002 C                   endsl
 001 *
 001 C                   movel     alpha         ky(i3)
 001 *
 001 * Convert the sort order to binary and place into array.
B002 C                   if        ad(i) = 'D'                                  descend
 002 C                   eval      binary = 2
X002 C                   else
 002 C                   eval      binary = 1
E002 C                   endif
 001 *
 001 C                   movel     alpha         ky(i4)
E001 C                   enddo
     *
     C                   endsr
     *-----------------------------------------------------------------------
     * PRCPGM:  Process program.
     *
     C     prcpgm        begsr
     *
     * Now that the sort control block is built, initialize
     * the sort routine and get it ready to accept records.
     *
     C                   eval      errlen = 272                                 avail space
     *
     C                   call      'QLGSORT'                            01
     C                   parm                    sort                           control block
     C                   parm                    inbuff                         input buffer
     C                   parm                    oubuff                         output buffer
     C                   parm      0             parm3                          not used
     C                   parm      0             parm4                          not used
     C                   parm                    error                          error ds
     *
     C                   exsr      chk4er
     *
     * Pass a block of records to the sort routine. The block
     * can contain up to 9,000 bytes.
     *
     C                   eval      #recs = 9000 / rcdlen                        number of recs
     C                   eval      intype = 1                                   put records
     C                   eval      infil1 = 0                                   not used
     C                   eval      inlen = rcdlen                               rec len
     C                   eval      inrecs = #recs
     C                   eval      totrec = 0
     * Do for blocks of records:
B001 C                   dow       totrec < nbrent
 001 C                   eval      totrec = totrec + #recs
B002 C                   if        totrec > nbrent
 002 C                   eval      tmp50 = totrec - nbrent
 002 C                   eval      inrecs = inrecs - tmp50
E002 C                   endif
 001 C                   eval      lendta = rcdlen * inrecs
 001 * Retrieve a block of records.
 001 C                   call      'QUSRTVUS'                           01
 001 C                   parm                    spacer
 001 C                   parm                    strpos
 001 C                   parm                    lendta
 001 C                   parm                    indta
 001 *
 001 C                   exsr      chk4er
 001 * Send them to the sort routine.
 001 C                   call      'QLGSRTIO'                           01
 001 C                   parm                    sortin
 001 C                   parm                    indta
 001 C                   parm                    outdta
 001 C                   parm                    outlen
 001 C                   parm                    sortou
 001 C                   parm                    error
 001 *
 001 C                   exsr      chk4er
 001 *
 001 C                   eval      strpos = strpos + lendta
E001 C                   enddo
     *
     * Tell the sort routine we are all done.
     C                   eval      intype = 2                                   end put
     C                   call      'QLGSRTIO'                           01
     C                   parm                    sortin
     C                   parm                    indta
     C                   parm                    outdta
     C                   parm                    outlen
     C                   parm                    sortou
     C                   parm                    error
     *
     C                   exsr      chk4er
     *
     * Retrieve records from the sort and place back into user space.
     C                   eval      intype = 3                                   get records
     C                   eval      strpos = offset
     C                   eval      strpos = strpos + 1
     C                   eval      inrecs = #recs
     C                   eval      totrec = 0
     *
     * Do for blocks of records:
B001 C                   dow       totrec < nbrent
 001 C                   eval      totrec = totrec + #recs
B002 C                   if        totrec > nbrent
 002 C                   eval      tmp50 = totrec - nbrent
 002 C                   eval      inrecs = inrecs - tmp50
E002 C                   endif
 001 C                   eval      lendta = rcdlen * inrecs
 001 * Retrieve a block of records.
 001 C                   call      'QLGSRTIO'                           01
 001 C                   parm                    sortin
 001 C                   parm                    indta
 001 C                   parm                    outdta
 001 C                   parm                    outlen
 001 C                   parm                    sortou
 001 C                   parm                    error
 001 *
 001 C                   exsr      chk4er
 001 * Place them back into user space.
 001 C                   call      'QUSCHGUS'                           01
 001 C                   parm                    spacer
 001 C                   parm                    strpos
 001 C                   parm                    lendta
 001 C                   parm                    outdta
 001 C                   parm      '2'           force
 001 *
 001 C                   exsr      chk4er
 001 *
 001 C                   eval      strpos = strpos + lendta
E001 C                   enddo
     *
     C                   endsr
     *-----------------------------------------------------------------------
     * *PSSR:   Error handling subroutine.
     *
     C     *pssr         begsr
     C                   move      *on           exiter
     C                   move      *on           *inlr
     C                   return
     C                   endsr
     *-----------------------------------------------------------------------
     * TRMPGM:  Terminate program.
     *
     C     trmpgm        begsr
     * All done.
     C                   move      *on           *inlr
     *
     C                   endsr
