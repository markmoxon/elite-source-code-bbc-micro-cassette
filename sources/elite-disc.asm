\ ******************************************************************************
\
\ ELITE DISC IMAGE SCRIPT
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The code on this site is identical to the version released on Ian Bell's
\ personal website at http://www.elitehomepage.org/
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
