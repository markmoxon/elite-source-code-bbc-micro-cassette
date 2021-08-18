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
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * output/README.txt
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

_SOURCE_DISC            = (_RELEASE = 1)
_TEXT_SOURCES           = (_RELEASE = 2)

.readme

 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13
 EQUS "Acornsoft Elite"
 EQUB 10, 13
 EQUB 10, 13
 EQUS "Version: BBC Micro cassette"
 EQUB 10, 13
IF _SOURCE_DISC
 EQUS "Release: Ian Bell's source disc"
 EQUB 10, 13
 EQUS "         Acornsoft SBG38 v1.0"
 EQUB 10, 13
ELIF _TEXT_SOURCES
 EQUS "Release: Ian Bell's text sources"
 EQUB 10, 13
 EQUS "         Acornsoft SBG38 v1.1"
 EQUB 10, 13
ENDIF
 EQUB 10, 13
 EQUS "See www.bbcelite.com for details"
 EQUB 10, 13
 EQUS "---------------------------------------"
 EQUB 10, 13

SAVE "output/README.txt", readme, P%

