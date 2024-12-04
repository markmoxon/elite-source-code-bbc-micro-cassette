\ ******************************************************************************
\
\ ELITE BIG CODE FILE SOURCE
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
\ This source file contains code to produce the Big Code File for BBC Micro
\ cassette Elite. The Big Code File comprises the game code and the ship
\ blueprints.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary files:
\
\   * ELTcode.unprot.bin
\   * ELThead.bin
\
\ after reading in the following files:
\
\   * ELTA.bin
\   * ELTB.bin
\   * ELTC.bin
\   * ELTD.bin
\   * ELTE.bin
\   * ELTF.bin
\   * ELTG.bin
\   * SHIPS.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 _SOURCE_DISC           = (_VARIANT = 1)
 _TEXT_SOURCES          = (_VARIANT = 2)
 _STH_CASSETTE          = (_VARIANT = 3)

 GUARD &8000            \ Guard against assembling over MOS memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &0F40          \ CODE% is set to the location that the main game code
                        \ gets moved to after it is loaded

 LOAD% = &1128          \ LOAD% points to the start of the actual game code,
                        \ after the &28 bytes of header code that are inserted
                        \ below

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0070 to &0071
\   Category: Workspaces
\    Summary: Important variables used by the loader
\
\ ******************************************************************************

 ORG &0070

.ZP

 SKIP 2                 \ Stores addresses used for moving content around

\ ******************************************************************************
\
\ Load the compiled binaries to create the Big Code File
\
\ ******************************************************************************

 ORG &1100              \ The load address of the main game code file ("ELTcode"
                        \ for loading from disc, "ELITEcode" for loading from
                        \ tape)

\ ******************************************************************************
\
\       Name: LBL
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Checksum the two pages of code that were copied from UU% to LE%
\
\ ------------------------------------------------------------------------------
\
\ This routine is called at LBL+1 from the CHECKER routine in the loader code in
\ elite-loader.asm. It calculates the checksum of the first two pages of the
\ loader code that was copied from UU% to LE% by part 3 of the loader, and
\ checks the result against the result in the first byte of the LE% block,
\ CHECKbyt, at address &0B00.
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   LBL+2               Contains an RTS
\
\ ******************************************************************************

.LBL

 EQUB &6C               \ This value is decremented by the tape loading routine
                        \ in the loader, in IRQ1. During loading this value gets
                        \ decremented down to &6C, and this new value is then
                        \ included in the checksum calculation for the MAINSUM
                        \ checksum in the CHECKER routine (the value is set to
                        \ &6C here as the tape protection is disabled)

 LDX #&60               \ Set X = &60. This value of X isn't used, it's just a
                        \ set up for the RTS call below, where we jump to LBL+2
                        \ to perform an RTS, as the opcode for RTS is &60

                        \ We now run a checksum on the block of memory from
                        \ &0B01 to &0CFF, which is the UU% routine from the
                        \ loader

 LDA #&B                \ Set ZP(1 0) = &0B00, to point to the start of the code
 STA ZP+1               \ we want to checksum

 LDY #0                 \ Set Y = 0 to count through each byte within each page
 STY ZP

 TYA                    \ Set A = 0 for building the checksum

 INY                    \ Increment Y to 1

.CHK3

 CLC                    \ Add the Y-th byte of the game code to A
 ADC (ZP),Y

 INY                    \ Increment the counter to point to the next byte

 BNE CHK3               \ Loop back for the next byte until we have finished
                        \ adding up this page

 INC ZP+1               \ Increment the high byte of ZP(1 0) to point to the
                        \ next page

.CHK4

 CLC                    \ Add the Y-th byte of this page to the checksum in A
 ADC (ZP),Y

 INY                    \ Increment the counter for this page

 BPL CHK4               \ Loop back for the next byte until we have finished
                        \ adding up this second page

 CMP &0B00              \ Compare the result to the contents of CHECKbyt in the
                        \ loader code at elite-loader.asm. This value gets set
                        \ by elite-checksum.py

 BEQ LBL+2              \ If the checksums match, jump to LBL+2, which contains
                        \ an RTS

                        \ Otherwise the checksum just failed, so we reset the
                        \ machine

 LDA #%01111111         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bits 0-6 (i.e. disable all hardware
                        \ interrupts from the System VIA)

 JMP (&FFFC)            \ Jump to the address in &FFFC to reset the machine

.elitea

 PRINT "elitea = ", ~P%
 INCBIN "3-assembled-output/ELTA.bin"

.eliteb

 PRINT "eliteb = ", ~P%
 INCBIN "3-assembled-output/ELTB.bin"

.elitec

 PRINT "elitec = ", ~P%
 INCBIN "3-assembled-output/ELTC.bin"

.elited

 PRINT "elited = ", ~P%
 INCBIN "3-assembled-output/ELTD.bin"

.elitee

 PRINT "elitee = ", ~P%
 INCBIN "3-assembled-output/ELTE.bin"

.elitef

 PRINT "elitef = ", ~P%
 INCBIN "3-assembled-output/ELTF.bin"

.eliteg

 PRINT "eliteg = ", ~P%
 INCBIN "3-assembled-output/ELTG.bin"

.checksum0

 PRINT "checksum0 = ", ~P%

IF _SOURCE_DISC OR _TEXT_SOURCES

 SKIP 1                 \ We skip this byte so we can insert the checksum later
                        \ in elite-checksum.py

ELIF _STH_CASSETTE

 EQUB &20               \ We skip this byte so we can insert the checksum later
                        \ in elite-checksum.py; it contains workspace noise in
                        \ the Stairway to Hell variant

ENDIF

.ships

 PRINT "ships = ", ~P%
 INCBIN "3-assembled-output/SHIPS.bin"

.end

\ ******************************************************************************
\
\ Save ELTcode.unprot.bin and ELThead.bin
\
\ ******************************************************************************

 PRINT "P% = ", ~P%
 PRINT "S.ELTcode 1100 ", ~(LOAD% + &6000 - CODE%), " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/ELTcode.unprot.bin", &1100, (LOAD% + &6000 - CODE%), LOAD%
 SAVE "3-assembled-output/ELThead.bin", &1100, elitea, &1100
