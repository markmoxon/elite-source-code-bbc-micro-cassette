\ ******************************************************************************
\
\ ELITE BIG CODE FILE SOURCE
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The code on this site is identical to the version released on Ian Bell's
\ personal website at http://www.iancgbell.clara.net/elite/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology used in this commentary is explained at the start of the
\ elite-loader.asm file
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary files:
\
\   * output/ELTcode.unprot.bin
\   * output/ELThead.bin
\
\ after reading in the following files:
\
\   * output/ELTA.bin
\   * output/ELTB.bin
\   * output/ELTC.bin
\   * output/ELTD.bin
\   * output/ELTE.bin
\   * output/ELTF.bin
\   * output/ELTG.bin
\   * output/SHIPS.bin
\
\ ******************************************************************************

CODE% = &0F40           \ CODE% is set to the location that the main game code
                        \ gets moved to after it is loaded

LOAD% = &1128           \ LOAD% points to the start of the actual game code,
                        \ after the &28 bytes of header code that are inserted
                        \ below

D% = &563A              \ D% is set to the size of the main game code

ZP = &70                \ ZP is a zero page variable used in the checksum
                        \ routine at LBL

ORG &1100               \ The load address of the main game code file ("ELTcode"
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
\ Other entry points:
\
\   LBL+2               Contains an RTS
\
\ ******************************************************************************

.LBL

 EQUB &6C               \ This is the opcode for an indirect JMP instruction,
                        \ and the opcode for LDX #&60 is &A2 &60, so together
                        \ the first three bytes are:
                        \
                        \   &6C &A2 &60 : JMP (&60A2)
                        \
                        \ Also, the third byte is &60, which is the opcode for
                        \ an RTS instruction, so jumping to LBL+2 (which we do
                        \ below) is the same as doing an RTS

 LDX #&60               \ Set X = &60 (this value of X isn't used, it's just a
                        \ set up for the JMP instruction and the RTS call below,
                        \ both of which are designed to confuse crackers

                        \ We now run a checksum on the block of memory from
                        \ &0B01 to &CFF, which is the UU% routine from the
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
                        \ loader code at elite-loader.asm. This values gets set
                        \ by elite-checksum.py

 BEQ LBL+2              \ If the checksums match, jump to LBL+2, which contains
                        \ an RTS

                        \ Otherwise the checksum just failed, so we reset the
                        \ machine

 LDA #%01111111         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bits 0-6 (i.e. disable all hardware
                        \ interrupts from the System VIA)

 JMP (&FFFC)            \ Jump to the address in &FFFC to reset the machine

\ ******************************************************************************
\
\ Load the compiled binaries to create the Big Code File
\
\ ******************************************************************************

.elitea

PRINT "elitea = ", ~P%
INCBIN "output/ELTA.bin"

.eliteb

PRINT "eliteb = ", ~P%
INCBIN "output/ELTB.bin"

.elitec

PRINT "elitec = ", ~P%
INCBIN "output/ELTC.bin"

.elited

PRINT "elited = ", ~P%
INCBIN "output/ELTD.bin"

.elitee

PRINT "elitee = ", ~P%
INCBIN "output/ELTE.bin"

.elitef

PRINT "elitef = ", ~P%
INCBIN "output/ELTF.bin"

.eliteg

PRINT "eliteg = ", ~P%
INCBIN "output/ELTG.bin"

.checksum0

PRINT "checksum0 = ", ~P%

 SKIP 1                 \ We skip this byte so we can insert the checksum later
                        \ in elite-checksum.py

.ships

PRINT "ships = ", ~P%
INCBIN "output/SHIPS.bin"

.end

\ ******************************************************************************
\
\ Save output/ELTcode.unprot.bin and output/ELThead.bin
\
\ ******************************************************************************

PRINT "P% = ", ~P%
PRINT "S.ELTcode 1100 ", ~(LOAD% + &6000 - CODE%), " ", ~LOAD%, ~LOAD%
SAVE "output/ELTcode.unprot.bin", &1100, (LOAD% + &6000 - CODE%), LOAD%
SAVE "output/ELThead.bin", &1100, elitea, &1100
