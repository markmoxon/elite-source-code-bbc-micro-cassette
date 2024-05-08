\ ******************************************************************************
\
\ ELITE README
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
\ https://www.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * README.txt
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 _SOURCE_DISC           = (_VARIANT = 1)
 _TEXT_SOURCES          = (_VARIANT = 2)
 _STH_CASSETTE          = (_VARIANT = 3)

.readme

 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13
 EQUS "Acornsoft Elite (flicker-free version)"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Version: BBC Micro cassette"
 EQUB 10, 13

IF _SOURCE_DISC

 EQUS "Variant: Ian Bell's source disc"
 EQUB 10, 13
 EQUS "Product: Acornsoft SBG38 (TBC)"
 EQUB 10, 13

ELIF _TEXT_SOURCES

 EQUS "Variant: Ian Bell's text sources"
 EQUB 10, 13

ELIF _STH_CASSETTE

 EQUS "Variant: Stairway to Hell cassette"
 EQUB 10, 13
 EQUS "Product: Acornsoft SBG38 (TBC)"
 EQUB 10, 13

ENDIF

 EQUB 10, 13
 EQUS "Contains the flicker-free ship drawing"
 EQUB 10, 13
 EQUS "routines from the BBC Master version,"
 EQUB 10, 13
 EQUS "backported by Mark Moxon"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "See www.bbcelite.com for details"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Build: ", TIME$("%F %T")
 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13

 SAVE "3-assembled-output/README.txt", readme, P%

