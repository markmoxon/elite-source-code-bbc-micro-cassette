\ ******************************************************************************
\
\ ELITE DISC IMAGE SCRIPT
\
\ The original 1984 source code is copyright Ian Bell and David Braben, and the
\ code on this site is identical to the version released by the authors on Ian
\ Bell's personal website at http://www.iancgbell.clara.net/elite/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology used in this commentary is explained at the start of the
\ elite-loader.asm file
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following SSD disc image:
\
\   * elite.ssd
\
\ This can be loaded into an emulator or a real BBC Micro.
\
\ ******************************************************************************

PUTFILE "output/ELITE.bin", "ELITE", &1100, &2000

PUTFILE "output/ELTcode.bin", "ELTcode", &1128, &1128
