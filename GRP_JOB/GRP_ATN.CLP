GR_ATN: +
  PGM
/*=== Attention program for programmer group job ============== */
/* Pops up an an ugly, but effective, IBM selection menu.       */
/* Called when Attn key is pressed in a group job.              */
/* Attn is Shift+Esc in most emulators.                         */
/*==============================================================*/

  TFRGRPJOB GRPJOB(*SELECT)

  ENDPGM
