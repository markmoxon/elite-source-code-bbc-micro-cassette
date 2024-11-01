\ ******************************************************************************
\
\ ELITE DISC IMAGE SCRIPT
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The code on this site is identical to the source discs released on Ian Bell's
\ personal website at http://www.elitehomepage.org/ (it's just been reformatted
\ to be more readable)
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://elite.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://elite.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces one of the following SSD disc images, depending on
\ which release is being built:
\
\   * elite-cassette-sth.ssd
\   * elite-cassette-from-source-disc.ssd
\   * elite-cassette-from-text-sources.ssd
\
\ This can be loaded into an emulator or a real BBC Micro.
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 _SOURCE_DISC           = (_VARIANT = 1)
 _TEXT_SOURCES          = (_VARIANT = 2)
 _STH_CASSETTE          = (_VARIANT = 3)

IF _DISC

 PUTFILE "1-source-files/boot-files/$.!BOOT.bin", "!BOOT", &FFFFFF, &FFFFFF
 PUTFILE "1-source-files/basic-programs/$.ELITE.bin", "ELITE", &FF1900, &FF8023
 PUTFILE "3-assembled-output/ELITE.bin", "ELTdata", &FF1100, &FF2000
 PUTFILE "3-assembled-output/ELTcode.bin", "ELTcode", &FF1128, &FF1128

ELSE

 PUTFILE "1-source-files/boot-files/$.!BOOT.bin", "!BOOT", &FFFFFF, &FFFFFF
 PUTFILE "1-source-files/basic-programs/$.ELITEc.bin", "ELITE", &FF1900, &FF8023
\PUTFILE "3-assembled-output/ELITE.bin", "ELITEdata", &FF0E00, &FF1D00
\PUTFILE "3-assembled-output/ELTcode.bin", "ELITEcode", &000E00, &000132
 PUTFILE "3-assembled-output/ELITE.bin", "ELITEda", &FF0E00, &FF1D00
 PUTFILE "3-assembled-output/ELTcode.bin", "ELITEco", &000E00, &000132

ENDIF

 PUTFILE "3-assembled-output/README.txt", "README", &FFFFFF, &FFFFFF
