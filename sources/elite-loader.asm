\ ******************************************************************************
\
\ ELITE LOADER SOURCE
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The code on this site is identical to the version released on Ian Bell's
\ personal website at http://www.elitehomepage.org/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * output/ELITE.unprot.bin
\
\ after reading in the following files:
\
\   * binaries/DIALS.bin
\   * binaries/P.ELITE.bin
\   * binaries/P.A-SOFT.bin
\   * binaries/P.(C)ASFT.bin
\   * output/WORDS9.bin
\   * output/PYTHON.bin
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

DISC = TRUE             \ Set to TRUE to load the code above DFS and relocate
                        \ down, so we can load the cassette version from disc

PROT = FALSE            \ Set to TRUE to enable the tape protection code

LOAD% = &1100           \ LOAD% is the load address of the main game code file
                        \ ("ELTcode" for loading from disc, "ELITEcode" for
                        \ loading from tape)

C% = &0F40              \ C% is set to the location that the main game code gets
                        \ moved to after it is loaded

S% = C%                 \ S% points to the entry point for the main game code

L% = LOAD% + &28        \ L% points to the start of the actual game code from
                        \ elite-source.asm, after the &28 bytes of header code
                        \ that are inserted by elite-bcfs.asm

D% = &563A              \ D% is set to the size of the main game code

LC% = &6000 - C%        \ LC% is set to the maximum size of the main game code
                        \ (as the code starts at C% and screen memory starts
                        \ at &6000)

N% = 67                 \ N% is set to the number of bytes in the VDU table, so
                        \ we can loop through them in part 2 below

SVN = &7FFD             \ SVN is where we store the "saving in progress" flag,
                        \ and it matches the location in elite-source.asm

VEC = &7FFE             \ VEC is where we store the original value of the IRQ1
                        \ vector, and it matches the value in elite-source.asm

LEN1 = 15               \ Size of the BEGIN% routine that gets pushed onto the
                        \ stack and executed there

LEN2 = 18               \ Size of the MVDL routine that gets pushed onto the
                        \ stack and executed there

LEN = LEN1 + LEN2       \ Total number of bytes that get pushed on the stack for
                        \ execution there (33)

LE% = &0B00             \ LE% is the address to which the code from UU% onwards
                        \ is copied in part 3. It contains:
                        \
                        \   * ENTRY2, the entry point for the second block of
                        \     loader code
                        \
                        \   * IRQ1, the interrupt routine for the split-screen
                        \     mode
                        \
                        \   * BLOCK, which by this point has already been put
                        \     on the stack by this point
                        \
                        \   * The variables used by the above

IF DISC

 CODE% = &E00+&300      \ CODE% is set to the assembly address of the loader
                        \ code file that we assemble in this file ("ELITE"),
                        \ which is at the lowest DFS page value of &1100 for the
                        \ version that loads from disc

ELSE

 CODE% = &E00           \ CODE% is set to the assembly address of the loader
                        \ code file that we assemble in this file ("ELITE"),
                        \ which is at the standard &0E00 address for the version
                        \ that loads from cassette

ENDIF

NETV = &224             \ The NETV vector that we intercept as part of the copy
                        \ protection

IRQ1V = &204            \ The IRQ1V vector that we intercept to implement the
                        \ split-sceen mode

OSWRCH = &FFEE          \ The address for the OSWRCH routine
OSBYTE = &FFF4          \ The address for the OSBYTE routine
OSWORD = &FFF1          \ The address for the OSWORD routine
OSPRNT = &234           \ The address for the OSPRNT vector

VIA = &FE00             \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

VSCAN = 57-1            \ Defines the split position in the split-screen mode

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0004 to &0005 and &0070 to &0086
\   Category: Workspaces
\    Summary: Important variables used by the loader
\
\ ******************************************************************************

ORG &0004

.TRTB%

 SKIP 2                 \ TRTB%(1 0) points to the keyboard translation table

ORG &0070

.ZP

 SKIP 2                 \ Stores addresses used for moving content around

.P

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.YY

 SKIP 1                 \ Temporary storage, used in a number of places

.T

 SKIP 1                 \ Temporary storage, used in a number of places

.SC

 SKIP 1                 \ Screen address (low byte)
                        \
                        \ Elite draws on-screen by poking bytes directly into
                        \ screen memory, and SC(1 0) is typically set to the
                        \ address of the character block containing the pixel
                        \ we want to draw (see the deep dives on "Drawing
                        \ monochrome pixels in mode 4" and "Drawing colour
                        \ pixels in mode 5" for more details)

.SCH

 SKIP 1                 \ Screen address (high byte)

.BLPTR

 SKIP 2                 \ Gets set to &03CA as part of the obfuscation code

.V219

 SKIP 2                 \ Gets set to &0218 as part of the obfuscation code

 SKIP 4                 \ These bytes are unused

.K3

 SKIP 1                 \ Temporary storage, used in a number of places

.BLCNT

 SKIP 2                 \ Stores the tape loader block count as part of the copy
                        \ protection code in IRQ1

.BLN

 SKIP 2                 \ Gets set to &03C6 as part of the obfuscation code

.EXCN

 SKIP 2                 \ Gets set to &03C2 as part of the obfuscation code

\ ******************************************************************************
\
\ ELITE LOADER
\
\ ******************************************************************************

\ ******************************************************************************
\
\       Name: Elite loader (Part 1 of 6)
\       Type: Subroutine
\   Category: Loader
\    Summary: Include binaries for recursive tokens, Python blueprint and images
\
\ ------------------------------------------------------------------------------
\
\ The loader bundles a number of binary files in with the loader code, and moves
\ them to their correct memory locations in part 3 below.
\
\ There are two files containing code:
\
\   * WORDS9.bin contains the recursive token table, which is moved to &0400
\     before the main game is loaded
\
\   * PYTHON.bin contains the Python ship blueprint, which gets moved to &7F00
\     before the main game is loaded
\
\ and four files containing images, which are all moved into screen memory by
\ the loader:
\
\   * P.A-SOFT.bin contains the "ACORNSOFT" title across the top of the loading
\     screen, which gets moved to screen address &6100, on the second character
\     row of the monochrome mode 4 screen
\
\   * P.ELITE.bin contains the "ELITE" title across the top of the loading
\     screen, which gets moved to screen address &6300, on the fourth character
\     row of the monochrome mode 4 screen
\
\   * P.(C)ASFT.bin contains the "(C) Acornsoft 1984" title across the bottom
\     of the loading screen, which gets moved to screen address &7600, the
\     penultimate character row of the monochrome mode 4 screen, just above the
\     dashboard
\
\   * P.DIALS.bin contains the dashboard, which gets moved to screen address
\     &7800, which is the starting point of the four-colour mode 5 portion at
\     the bottom of the split screen
\
\ The routine ends with a jump to the start of the loader code at ENTRY.
\
\ ******************************************************************************

ORG CODE%
PRINT "WORDS9 = ",~P%
INCBIN "output/WORDS9.bin"

ORG CODE% + &400
PRINT "P.DIALS = ",~P%
INCBIN "binaries/P.DIALS.bin"

ORG CODE% + &B00
PRINT "PYTHON = ",~P%
INCBIN "output/PYTHON.bin"

ORG CODE% + &C00
PRINT "P.ELITE = ",~P%
INCBIN "binaries/P.ELITE.bin"

ORG CODE% + &D00
PRINT "P.A-SOFT = ",~P%
INCBIN "binaries/P.A-SOFT.bin"

ORG CODE% + &E00
PRINT "P.(C)ASFT = ",~P%
INCBIN "binaries/P.(C)ASFT.bin"

O% = CODE% + &400 + &800 + &300
ORG O%

.run

 JMP ENTRY              \ Jump to ENTRY to start the loading process

\ ******************************************************************************
\
\       Name: B%
\       Type: Variable
\   Category: Screen mode
\    Summary: VDU commands for setting the square mode 4 screen
\  Deep dive: The split-screen mode
\             Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ This block contains the bytes that get written by OSWRCH to set up the screen
\ mode (this is equivalent to using the VDU statement in BASIC).
\
\ It defines the whole screen using a square, monochrome mode 4 configuration;
\ the mode 5 part for the dashboard is implemented in the IRQ1 routine.
\
\ The top part of Elite's screen mode is based on mode 4 but with the following
\ differences:
\
\   * 32 columns, 31 rows (256 x 248 pixels) rather than 40, 32
\
\   * The horizontal sync position is at character 45 rather than 49, which
\     pushes the screen to the right (which centres it as it's not as wide as
\     the normal screen modes)
\
\   * Screen memory goes from &6000 to &7EFF, which leaves another whole page
\     for code (i.e. 256 bytes) after the end of the screen. This is where the
\     Python ship blueprint slots in
\
\   * The text window is 1 row high and 13 columns wide, and is at (2, 16)
\
\   * The cursor is disabled
\
\ This almost-square mode 4 variant makes life a lot easier when drawing to the
\ screen, as there are 256 pixels on each row (or, to put it in screen memory
\ terms, there's one page of memory per row of pixels). For more details of the
\ screen mode, see the deep dive on "Drawing monochrome pixels in mode 4".
\
\ There is also an interrupt-driven routine that switches the bytes-per-pixel
\ setting from that of mode 4 to that of mode 5, when the raster reaches the
\ split between the space view and the dashboard. See the deep dive on "The
\ split-screen mode" for details.
\
\ ******************************************************************************

.B%

 EQUB 22, 4             \ Switch to screen mode 4

 EQUB 28                \ Define a text window as follows:
 EQUB 2, 17, 15, 16     \
                        \   * Left = 2
                        \   * Right = 15
                        \   * Top = 16
                        \   * Bottom = 17
                        \
                        \ i.e. 1 row high, 13 columns wide at (2, 16)

 EQUB 23, 0, 6, 31      \ Set 6845 register R6 = 31
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "vertical displayed" register, and sets
                        \ the number of displayed character rows to 31. For
                        \ comparison, this value is 32 for standard modes 4 and
                        \ 5, but we claw back the last row for storing code just
                        \ above the end of screen memory

 EQUB 23, 0, 12, &0C    \ Set 6845 register R12 = &0C and R13 = &00
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This sets 6845 registers (R12 R13) = &0C00 to point
 EQUB 23, 0, 13, &00    \ to the start of screen memory in terms of character
 EQUB 0, 0, 0           \ rows. There are 8 pixel lines in each character row,
 EQUB 0, 0, 0           \ so to get the actual address of the start of screen
                        \ memory, we multiply by 8:
                        \
                        \   &0C00 * 8 = &6000
                        \
                        \ So this sets the start of screen memory to &6000

 EQUB 23, 0, 1, 32      \ Set 6845 register R1 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal displayed" register, which
                        \ defines the number of character blocks per horizontal
                        \ character row. For comparison, this value is 40 for
                        \ modes 4 and 5, but our custom screen is not as wide at
                        \ only 32 character blocks across

 EQUB 23, 0, 2, 45      \ Set 6845 register R2 = 45
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal sync position" register, which
                        \ defines the position of the horizontal sync pulse on
                        \ the horizontal line in terms of character widths from
                        \ the left-hand side of the screen. For comparison this
                        \ is 49 for modes 4 and 5, but needs to be adjusted for
                        \ our custom screen's width

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, so this sets the
                        \ cursor start line at 0, effectively disabling the
                        \ cursor

\ ******************************************************************************
\
\       Name: E%
\       Type: Variable
\   Category: Sound
\    Summary: Sound envelope definitions
\
\ ------------------------------------------------------------------------------
\
\ This table contains the sound envelope data, which is passed to OSWORD by the
\ FNE macro to create the four sound envelopes used in-game. Refer to chapter 30
\ of the BBC Micro User Guide for details of sound envelopes and what all the
\ parameters mean.
\
\ The envelopes are as follows:
\
\   * Envelope 1 is the sound of our own laser firing
\
\   * Envelope 2 is the sound of lasers hitting us, or hyperspace
\
\   * Envelope 3 is the first sound in the two-part sound of us dying, or the
\     second sound in the two-part sound of us making hitting or killing an
\     enemy ship
\
\   * Envelope 4 is the sound of E.C.M. firing
\
\ ******************************************************************************

.E%

 EQUB 1, 1, 0, 111, -8, 4, 1, 8, 8, -2, 0, -1, 112, 44
 EQUB 2, 1, 14, -18, -1, 44, 32, 50, 6, 1, 0, -2, 120, 126
 EQUB 3, 1, 1, -1, -3, 17, 32, 128, 1, 0, 0, -1, 1, 1
 EQUB 4, 1, 4, -8, 44, 4, 6, 8, 22, 0, 0, -127, 126, 0

\ ******************************************************************************
\
\       Name: swine
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Resets the machine if the copy protection detects a problem
\
\ ******************************************************************************

.swine

 LDA #%01111111         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bits 0-6 (i.e. disable all hardware
                        \ interrupts from the System VIA)

 JMP (&FFFC)            \ Jump to the address in &FFFC to reset the machine

\ ******************************************************************************
\
\       Name: OSB
\       Type: Subroutine
\   Category: Utility routines
\    Summary: A convenience routine for calling OSBYTE with Y = 0
\
\ ******************************************************************************

.OSB

 LDY #0                 \ Call OSBYTE with Y = 0, returning from the subroutine
 JMP OSBYTE             \ using a tail call (so we can call OSB to call OSBYTE
                        \ for when we know we want Y set to 0)

\ ******************************************************************************
\
\       Name: Authors' names
\       Type: Variable
\   Category: Copy protection
\    Summary: The authors' names, buried in the code
\
\ ------------------------------------------------------------------------------
\
\ Contains the authors' names, plus an unused OS command string that would
\ *RUN the main game code, which isn't what actually happens (so presumably
\ this is to throw the crackers off the scent).
\
\ ******************************************************************************

 EQUS "R.ELITEcode"
 EQUB 13
 EQUS "By D.Braben/I.Bell"
 EQUB 13
 EQUB &B0

\ ******************************************************************************
\
\       Name: oscliv
\       Type: Variable
\   Category: Utility routines
\    Summary: Contains the address of OSCLIV, for executing OS commands
\
\ ******************************************************************************

.oscliv

 EQUW &FFF7             \ Address of OSCLIV, for executing OS commands
                        \ (specifically the *LOAD that loads the main game code)

\ ******************************************************************************
\
\       Name: David9
\       Type: Variable
\   Category: Copy protection
\    Summary: Address used as part of the stack-based decryption loop
\
\ ------------------------------------------------------------------------------
\
\ This address is used in the decryption loop starting at David2 in part 4, and
\ is used to jump back into the loop at David5.
\
\ ******************************************************************************

.David9

 EQUW David5            \ The address of David5

 CLD                    \ This instruction is not used

\ ******************************************************************************
\
\       Name: David23
\       Type: Variable
\   Category: Copy protection
\    Summary: Address pointer to the start of the 6502 stack
\
\ ------------------------------------------------------------------------------
\
\ This two-byte address points to the start of the 6502 stack, which descends
\ from the end of page 2, less LEN bytes, which comes out as &01DF. So when we
\ push 33 bytes onto the stack (LEN being 33), this address will point to the
\ start of those bytes, which means we can push executable code onto the stack
\ and run it by calling this address with a JMP (David23) instruction. Sneaky
\ stuff!
\
\ ******************************************************************************

.David23

 EQUW (512-LEN)         \ The address of LEN bytes before the start of the stack

\ ******************************************************************************
\
\       Name: doPROT1
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Routine to self-modify the loader code
\
\ ------------------------------------------------------------------------------
\
\ This routine modifies various bits of code in-place as part of the copy
\ protection mechanism. It is called with A = &48 and X = 255.
\
\ ******************************************************************************

.doPROT1

 LDY #&DB               \ Store &EFDB in TRTB%(1 0) to point to the keyboard
 STY TRTB%              \ translation table for OS 0.1 (which we will overwrite
 LDY #&EF               \ with a call to OSBYTE later)
 STY TRTB%+1

 LDY #2                 \ Set the high byte of V219(1 0) to 2
 STY V219+1

 STA PROT1-255,X        \ Poke &48 into PROT1, which changes the instruction
                        \ there to a PHA

 LDY #&18
 STY V219+1,X           \ Set the low byte of V219(1 0) to &18 (as X = 255), so
                        \ V219(1 0) now contains &0218

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MHCA
\       Type: Variable
\   Category: Copy protection
\    Summary: Used to set one of the vectors in the copy protection code
\
\ ------------------------------------------------------------------------------
\
\ This value is used to set the low byte of BLPTR(1 0), when it's set in PLL1
\ as part of the copy protection.
\
\ ******************************************************************************

.MHCA

 EQUB &CA               \ The low byte of BLPTR(1 0)

\ ******************************************************************************
\
\       Name: David7
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Part of the multi-jump obfuscation code in PROT1
\
\ ------------------------------------------------------------------------------
\
\ This instruction is part of the multi-jump obfuscation in PROT1 (see part 2 of
\ the loader), which does the following jumps:
\
\   David8 -> FRED1 -> David7 -> Ian1 -> David3
\
\ ******************************************************************************

.David7

 BCC Ian1               \ This instruction is part of the multi-jump obfuscation
                        \ in PROT1

\ ******************************************************************************
\
\       Name: FNE
\       Type: Macro
\   Category: Sound
\    Summary: Macro definition for defining a sound envelope
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to define the four sound envelopes used in the
\ game. It uses OSWORD 8 to create an envelope using the 14 parameters in the
\ the I%-th block of 14 bytes at location E%. This OSWORD call is the same as
\ BBC BASIC's ENVELOPE command.
\
\ See variable E% for more details of the envelopes themselves.
\
\ ******************************************************************************

MACRO FNE I%

  LDX #LO(E%+I%*14)     \ Set (Y X) to point to the I%-th set of envelope data
  LDY #HI(E%+I%*14)     \ in E%

  LDA #8                \ Call OSWORD with A = 8 to set up sound envelope I%
  JSR OSWORD

ENDMACRO

\ ******************************************************************************
\
\       Name: Elite loader (Part 2 of 6)
\       Type: Subroutine
\   Category: Loader
\    Summary: Perform a number of OS calls, set up sound, push routines on stack
\
\ ------------------------------------------------------------------------------
\
\ This part of the loader does a number of calls to OS routines, sets up the
\ sound envelopes, pushes 33 bytes onto the stack that will be used later, and
\ sends us on a wild goose chase, just for kicks.
\
\ ******************************************************************************

.ENTRY

 SEI                    \ Disable all interrupts

 CLD                    \ Clear the decimal flag, so we're not in decimal mode

IF DISC = 0

 LDA #0                 \ Call OSBYTE with A = 0 and X = 255 to fetch the
 LDX #255               \ operating system version into X
 JSR OSBYTE

 TXA                    \ If X = 0 then this is OS 1.00, so jump down to OS100
 BEQ OS100              \ to skip the following

 LDY &FFB6              \ Otherwise this is OS 1.20, so set Y to the contents of
                        \ &FFB6, which contains the length of the default vector
                        \ table

 LDA &FFB7              \ Set ZP(1 0) to the location stored in &FFB7-&FFB8,
 STA ZP                 \ which contains the address of the default vector table
 LDA &FFB8
 STA ZP+1

 DEY                    \ Decrement Y so we can use it as an index for setting
                        \ all the vectors to their default states

.ABCDEFG

 LDA (ZP),Y             \ Copy the Y-th byte from the default vector table into
 STA &200,Y             \ the vector table in &0200

 DEY                    \ Decrement the loop counter

 BPL ABCDEFG            \ Loop back for the next vector until we have done them
                        \ all

.OS100

ENDIF

 LDA #%01111111         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bits 0-6 (i.e. disable all hardware
                        \ interrupts from the System VIA)

 STA &FE6E              \ Set 6522 User VIA interrupt enable register IER
                        \ (SHEILA &6E) bits 0-6 (i.e. disable all hardware
                        \ interrupts from the User VIA)

 LDA &FFFC              \ Fetch the low byte of the reset address in &FFFC,
                        \ which will reset the machine if called

 STA &200               \ Set the low bytes of USERV, BRKV, IRQ2V and EVENTV
 STA &202
 STA &206
 STA &220

 LDA &FFFD              \ Fetch the high byte of the reset address in &FFFD,
                        \ which will reset the machine if called

 STA &201               \ Set the high bytes of USERV, BRKV, IRQ2V and EVENTV
 STA &203
 STA &207
 STA &221

 LDX #&2F-2             \ We now step through all the vectors from &0204 to
                        \ &022F and OR their high bytes with &C0, so they all
                        \ point into the MOS ROM space (which is from &C000 and
                        \ upwards), so we set a counter in X to count through
                        \ them

.purge

 LDA &202,X             \ Set the high byte of the vector in &202+X so it points
 ORA #&C0               \ to the MOS ROM
 STA &202,X

 DEX                    \ Increment the counter to point to the next high byte
 DEX

 BPL purge              \ Loop back until we have done all the vectors

 LDA #&60               \ Store an RTS instruction in location &232
 STA &232

 LDA #&2                \ Point the NETV vector to &232, which we just filled
 STA NETV+1             \ with an RTS
 LDA #&32
 STA NETV

 LDA #&20               \ Set A to the op code for a JSR call with absolute
                        \ addressing

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &D0 &66, or BIT &66D0, which does nothing apart
                        \ from affect the flags

.Ian1

 BNE David3             \ This instruction is skipped if we came from above,
                        \ otherwise this is part of the multi-jump obfuscation
                        \ in PROT1

 STA David2             \ Store &20 in location David2, which modifies the
                        \ instruction there (see David2 for details)

 LSR A                  \ Set A = 16

 LDX #3                 \ Set the high bytes of BLPTR(1 0), BLN(1 0) and
 STX BLPTR+1            \ EXCN(1 0) to &3. We will fill in the high bytes in
 STX BLN+1              \ the PLL1 routine, and will then use these values in
 STX EXCN+1             \ the IRQ1 handler

 DEX                    \ Set X = 2

 JSR OSBYTE             \ Call OSBYTE with A = 16 and X = 2 to set the ADC to
                        \ sample 2 channels from the joystick

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &D0 &A1, or BIT &A1D0, which does nothing apart
                        \ from affect the flags

.FRED1

 BNE David7             \ This instruction is skipped if we came from above,
                        \ otherwise this is part of the multi-jump obfuscation
                        \ in PROT1

 LDX #255               \ Call doPROT1 to change an instruction in the PROT1
 LDA #&48               \ routine and set up another couple of variables
 JSR doPROT1

 LDA #144               \ Call OSBYTE with A = 144, X = 255 and Y = 0 to move
 JSR OSB                \ the screen down one line and turn screen interlace on

 LDA #247               \ Call OSBYTE with A = 247 and X = Y = 0 to disable the
 LDX #0                 \ BREAK intercept code by poking 0 into the first value
 JSR OSB

\LDA #129               \ These instructions are commented out in the original
\LDY #255               \ source, along with the comment "Damn 0.1", so
\LDX #1                 \ presumably MOS version 0.1 was a bit of a pain to
\JSR OSBYTE             \ support - which is probably why Elite doesn't bother
\TXA                    \ and only supports 1.0 and 1.2
\BPL OS01
\Damn 0.1

 LDA #190               \ Call OSBYTE with A = 190, X = 8 and Y = 0 to set the
 LDX #8                 \ ADC conversion type to 8 bits, for the joystick
 JSR OSB

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &D0 &E1, or BIT &E1D0, which does nothing apart
                        \ from affect the flags

.David8

 BNE FRED1              \ This instruction is skipped if we came from above,
                        \ otherwise this is part of the multi-jump obfuscation
                        \ in PROT1

 LDA #143               \ Call OSBYTE 143 to issue a paged ROM service call of
 LDX #&C                \ type &C with argument &FF, which is the "NMI claim"
 LDY #&FF               \ service call that asks the current user of the NMI
 JSR OSBYTE             \ space to clear it out

 LDA #13                \ Set A = 13 for the next OSBYTE call

.abrk

 LDX #0                 \ Call OSBYTE with A = 13, X = 0 and Y = 0 to disable
 JSR OSB                \ the "output buffer empty" event

 LDA #225               \ Call OSBYTE with A = 225, X = 128 and Y = 0 to set
 LDX #128               \ the function keys to return ASCII codes for SHIFT-fn
 JSR OSB                \ keys (i.e. add 128)

 LDA #172               \ Call OSBYTE 172 to read the address of the MOS
 LDX #0                 \ keyboard translation table into (Y X)
 LDY #255
 JSR OSBYTE

 STX TRTB%              \ Store the address of the keyboard translation table in
 STY TRTB%+1            \ TRTB%(1 0)

 LDA #200               \ Call OSBYTE with A = 200, X = 3 and Y = 0 to disable
 LDX #3                 \ the ESCAPE key and clear memory if the BREAK key is
 JSR OSB                \ pressed

IF PROT AND DISC = 0

 CPX #3                 \ If the previous value of X from the call to OSBYTE 200
 BNE abrk+1             \ was not 3 (ESCAPE disabled, clear memory), jump to
                        \ abrk+1, which contains a BRK instruction which will
                        \ reset the computer (as we set BRKV to point to the
                        \ reset address above)

ENDIF

 LDA #13                \ Call OSBYTE with A = 13, X = 2 and Y = 0 to disable
 LDX #2                 \ the "character entering keyboard buffer" event
 JSR OSB

.OS01                   \ Reset stack

 LDX #&FF               \ Set the stack pointer to &01FF, which is the standard
 TXS                    \ location for the 6502 stack, so this instruction
                        \ effectively resets the stack

 INX                    \ Set X = 0, to use as a counter in the following loop

.David3

 LDA BEGIN%,X           \ This routine pushes 33 bytes from BEGIN% onto the
                        \ stack, so fetch the X-th byte from BEGIN%

.PROT1

 INY                    \ This instruction gets changed to a PHA instruction by
                        \ the doPROT1 routine that's called above, so by the
                        \ time we get here, this instruction actually pushes the
                        \ X-th byte from BEGIN% onto the stack

 INX                    \ Increment the loop counter

 CPX #LEN               \ If X < #LEN (which is 33), loop back for the next one.
 BNE David8             \ This branch actually takes us on wold goose chase
                        \ through the following locations, where each BNE is
                        \ prefaced by an EQUB &2C that disables the branch
                        \ instruction during the normal instruction flow:
                        \
                        \   David8 -> FRED1 -> David7 -> Ian1 -> David3
                        \
                        \ so in the end this just loops back to push the next
                        \ byte onto the stack, but in a really sneaky way

 LDA #LO(B%)            \ Set the low byte of ZP(1 0) to point to the VDU code
 STA ZP                 \ table at B%

 LDA #&C8               \ Poke &C8 into PROT1 to change the instruction that we
 STA PROT1              \ modified back to an INY instruction, rather than a PHA

 LDA #HI(B%)            \ Set the high byte of ZP(1 0) to point to the VDU code
 STA ZP+1               \ table at B%

 LDY #0                 \ We are now going to send the N% VDU bytes in the table
                        \ at B% to OSWRCH to set up the special mode 4 screen
                        \ that forms the basis for the split-screen mode

.LOOP

 LDA (ZP),Y             \ Pass the Y-th byte of the B% table to OSWRCH
 JSR OSWRCH

 INY                    \ Increment the loop counter

 CPY #N%                \ Loop back for the next byte until we have done them
 BNE LOOP               \ all (the number of bytes was set in N% above)

 LDA #1                 \ In doPROT1 above we set V219(1 0) = &0218, so this
 TAX                    \ code sets the contents of &0219 (the high byte of
 TAY                    \ BPUTV) to 1. We will see why this later, at the start
 STA (V219),Y           \ of part 4

 LDA #4                 \ Call OSBYTE with A = 4, X = 1 and Y = 0 to disable
 JSR OSB                \ cursor editing, so the cursor keys return ASCII values
                        \ and can therefore be used in-game

 LDA #9                 \ Call OSBYTE with A = 9, X = 0 and Y = 0 to disable
 LDX #0                 \ flashing colours
 JSR OSB

 LDA #&6C               \ Poke &6C into crunchit after EOR'ing it first (which
 EOR crunchit           \ has no effect as crunchit contains a BRK instruction
 STA crunchit           \ with opcode 0), to change crunchit to an indirect JMP

 FNE 0                  \ Set up sound envelopes 0-3 using the FNE macro
 FNE 1
 FNE 2
 FNE 3

\ ******************************************************************************
\
\       Name: Elite loader (Part 3 of 6)
\       Type: Subroutine
\   Category: Loader
\    Summary: Move and decrypt recursive tokens, Python blueprint and images
\
\ ------------------------------------------------------------------------------
\
\ Move and decrypt the following memory blocks:
\
\   * WORDS9: move 4 pages (1024 bytes) from CODE% to &0400
\
\   * P.ELITE: move 1 page (256 bytes) from CODE% + &C00 to &6300
\
\   * P.A-SOFT: move 1 page (256 bytes) from CODE% + &D00 to &6100
\
\   * P.(C)ASFT: move 1 page (256 bytes) from CODE% + &E00 to &7600
\
\   * P.DIALS and PYTHON: move 8 pages (2048 bytes) from CODE% + &400 to &7800
\
\   * Move 2 pages (512 bytes) from UU% to &0B00-&0CFF
\
\ and call the routine to draw Saturn between P.(C)ASFT and P.DIALS.
\
\ See part 1 above for more details on the above files and the locations that
\ they are moved to.
\
\ The code at UU% (see below) forms part of the loader code and is moved before
\ being run, so it's tucked away safely while the main game code is loaded and
\ decrypted.
\
\ ******************************************************************************

 LDX #4                 \ Set the following:
 STX P+1                \
 LDA #HI(CODE%)         \   P(1 0) = &0400
 STA ZP+1               \   ZP(1 0) = CODE%
 LDY #0                 \   (X Y) = &400 = 1024
 LDA #256-LEN1          \
 STA (V219-4,X)         \ In doPROT1 above we set V219(1 0) = &0218, so this
 STY ZP                 \ also sets the contents of &0218 (the low byte of
 STY P                  \ BPUTV) to 256 - LEN1, or &F1. We set the low byte to
                        \ 1 above, so BPUTV now contains &01F1, which we will
                        \ use at the start of part 4

 JSR crunchit           \ Call crunchit, which has now been modified to call the
                        \ MVDL routine on the stack, to move and decrypt &400
                        \ bytes from CODE% to &0400. We loaded WORDS9.bin to
                        \ CODE% in part 1, so this moves WORDS9

 LDX #1                 \ Set the following:
 LDA #(HI(CODE%)+&C)    \
 STA ZP+1               \   P(1 0) = &6300
 LDA #&63               \   ZP(1 0) = CODE% + &C
 STA P+1                \   (X Y) = &100 = 256
 LDY #0

 JSR crunchit           \ Call crunchit to move and decrypt &100 bytes from
                        \ CODE% + &C to &6300, so this moves P.ELITE

 LDX #1                 \ Set the following:
 LDA #(HI(CODE%)+&D)    \
 STA ZP+1               \   P(1 0) = &6100
 LDA #&61               \   ZP(1 0) = CODE% + &D
 STA P+1                \   (X Y) = &100 = 256
 LDY #0

 JSR crunchit           \ Call crunchit to move and decrypt &100 bytes from
                        \ CODE% + &D to &6100, so this moves P.A-SOFT

 LDX #1                 \ Set the following:
 LDA #(HI(CODE%)+&E)    \
 STA ZP+1               \   P(1 0) = &7600
 LDA #&76               \   ZP(1 0) = CODE% + &E
 STA P+1                \   (X Y) = &100 = 256
 LDY #0

 JSR crunchit           \ Call crunchit to move and decrypt &100 bytes from
                        \ CODE% + &E to &7600, so this moves P.(C)ASFT

 JSR PLL1               \ Call PLL1 to draw Saturn

 LDX #8                 \ Set the following:
 LDA #(HI(CODE%)+4)     \
 STA ZP+1               \   P(1 0) = &7800
 LDA #&78               \   ZP(1 0) = CODE% + &4
 STA P+1                \   (X Y) = &800 = 2048
 LDY #0                 \
 STY ZP                 \ Also set BLCNT = 0
 STY BLCNT
 STY P

 JSR crunchit           \ Call crunchit to move and decrypt &800 bytes from
                        \ CODE% + &4 to &7800, so this moves P.DIALS and PYTHON

 LDX #(3-(DISC AND 1))  \ Set the following:
 LDA #HI(UU%)           \
 STA ZP+1               \   P(1 0) = LE%
 LDA #LO(UU%)           \   ZP(1 0) = UU%
 STA ZP                 \   (X Y) = &300 = 768 (if we are building for tape)
 LDA #HI(LE%)           \        or &200 = 512 (if we are building for disc)
 STA P+1
 LDY #0
 STY P

 JSR crunchit           \ Call crunchit to move and decrypt either &200 or &300
                        \ bytes from UU% to LE%, leaving X = 0

\ ******************************************************************************
\
\       Name: Elite loader (Part 4 of 6)
\       Type: Subroutine
\   Category: Loader
\    Summary: Copy more code onto stack, decrypt TUT block, set up IRQ1 handler
\
\ ------------------------------------------------------------------------------
\
\ This part copies more code onto the stack (from BLOCK to ENDBLOCK), decrypts
\ the code from TUT onwards, and sets up the IRQ1 handler for the split-screen
\ mode.
\
\ ******************************************************************************

 STY David3-2           \ Y was set to 0 above, so this modifies the OS01
                        \ routine above by changing the TXS instruction to BRK,
                        \ so calls to OS01 will now do this:
                        \
                        \   LDX #&FF
                        \   BRK
                        \
                        \ This is presumably just to confuse any cracker, as we
                        \ don't call OS01 again

                        \ We now enter a loop that starts with the counter in Y
                        \ (initially set to 0). It calls JSR &01F1 on the stack,
                        \ which pushes the Y-th byte of BLOCK on the stack
                        \ before encrypting the Y-th byte of BLOCK in-place. It
                        \ then jumps back to David5 below, where we increment Y
                        \ until it reaches a value of ENDBLOCK - BLOCK. So this
                        \ loop basically decrypts the code from TUT onwards, and
                        \ at the same time it pushes the code between BLOCK and
                        \ ENDBLOCK onto the stack, so it's there ready to be run
                        \ (at address &0163)

.David2

 EQUB &AC               \ This byte was changed to &20 by part 2, so by the time
 EQUW &FFD4             \ we get here, these three bytes together become JSR
                        \ &FFD4, or JSR OSBPUT. Amongst all the code above,
                        \ we've also managed to set BPUTV to &01F1, and as BPUTV
                        \ is the vector that OSBPUT goes through, these three
                        \ bytes are actually doing JSR &01F1
                        \
                        \ That address is in the stack, and is the address of
                        \ the first routine, that we pushed onto the stack in
                        \ the modified PROT1 routine. That routine doesn't
                        \ return with an RTS, but instead it removes the return
                        \ address from the stack and jumps to David5 below after
                        \ pushing the Y-th byte of BLOCK onto the stack and
                        \ EOR'ing the Y-th byte of TUT with the Y-th byte of
                        \ BLOCK
                        \
                        \ This obfuscation probably kept the crackers busy for a
                        \ while - it's difficult enough to work out when you
                        \ have the source code in front of you!

.LBLa

                        \ If, for some reason, the above JSR doesn't call the
                        \ routine on the stack and returns normally, which might
                        \ happen if crackers manage to unpick the BPUTV
                        \ redirection, then we end up here. We now obfuscate the
                        \ the first 255 bytes of the location where the main
                        \ game gets loaded (which is set in C%), just to make
                        \ things hard, and then we reset the machine... all in
                        \ a completely twisted manner, of course

 LDA C%,X               \ Obfuscate the X-th byte of C% by EOR'ing with &A5
 EOR #&A5
 STA C%,X

 DEX                    \ Decrement the loop counter

 BNE LBLa               \ Loop back until X wraps around, after EOR'ing a whole
                        \ page

 JMP (C%+&CF)           \ C%+&CF is &100F, which in the main game code contains
                        \ an LDA KY17 instruction (it's in the main loader in
                        \ the MA76 section). This has opcode &A5 &4E, and the
                        \ EOR above changes the first of these to &00, so this
                        \ jump goes to a BRK instruction, which in turn goes to
                        \ BRKV, which in turn resets the computer (as we set
                        \ BRKV to point to the reset address in part 2)

.swine2

 JMP swine              \ Jump to swine to reset the machine

 EQUW &4CFF             \ This data doesn't appear to be used

.crunchit

 BRK                    \ This instruction gets changed to an indirect JMP at
 EQUW David23           \ the end of part 2, so this does JMP (David23). David23
                        \ contains &01DF, so these bytes are actually doing JMP
                        \ &01DF. That address is in the stack, and is the
                        \ address of the MVDL routine, which we pushed onto the
                        \ stack in the modified PROT1 routine... so this
                        \ actually does the following:
                        \
                        \   JMP MVDL
                        \
                        \ meaning that this instruction:
                        \
                        \   JSR crunchit
                        \
                        \ actually does this, because it's a tail call:
                        \
                        \   JSR MVDL
                        \
                        \ It's yet another impressive bit of obfuscation and
                        \ misdirection

.RAND

 EQUD &6C785349         \ The random number seed used for drawing Saturn

.David5

 INY                    \ Increment the loop counter

 CPY #(ENDBLOCK-BLOCK)  \ Loop back to copy the next byte until we have copied
 BNE David2             \ all the bytes between BLOCK and ENDBLOCK

 SEI                    \ Disable interrupts while we set up our interrupt
                        \ handler to support the split-screen mode

 LDA #%11000010         \ Clear 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bits 1 and 7 (i.e. enable CA1 and TIMER1
                        \ interrupts from the System VIA, which enable vertical
                        \ sync and the 1 MHz timer, which we need enabled for
                        \ the split-screen interrupt code to work)

 LDA #%01111111         \ Set 6522 User VIA interrupt enable register IER
 STA &FE6E              \ (SHEILA &6E) bits 0-7 (i.e. disable all hardware
                        \ interrupts from the User VIA)

 LDA IRQ1V              \ Store the low byte of the current IRQ1V vector in VEC
 STA VEC

 LDA IRQ1V+1            \ If the current high byte of the IRQ1V vector is less
 BPL swine2             \ than &80, which means it points to user RAM rather
                        \ the MOS ROM, then something is probably afoot, so jump
                        \ to swine2 to reset the machine

 STA VEC+1              \ Otherwise all is well, so store the high byte of the
                        \ current IRQ1V vector in VEC+1, so VEC(1 0) now
                        \ contains the original address of the IRQ1 handler

 LDA #HI(IRQ1)          \ Set the IRQ1V vector to IRQ1, so IRQ1 is now the
 STA IRQ1V+1            \ interrupt handler
 LDA #LO(IRQ1)
 STA IRQ1V

 LDA #VSCAN             \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to VSCAN (56) to start the T1 counter
                        \ counting down from 14080 at a rate of 1 MHz (this is
                        \ a different value to the main game code)

 CLI                    \ Re-enable interrupts

IF DISC

 LDA #%10000001         \ Clear 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bit 1 (i.e. enable the CA2 interrupt,
                        \ which comes from the keyboard)

 LDY #20                \ Set Y = 20 for the following OSBYTE call

IF _REMOVE_CHECKSUMS

 NOP                    \ If we have disabled checksums, skip the OSBYTE call
 NOP
 NOP

ELSE

 JSR OSBYTE             \ A was set to 129 above, so this calls OSBYTE with
                        \ A = 129 and Y = 20, which reads the keyboard with a
                        \ time limit, in this case 20 centiseconds, or 0.2
                        \ seconds

ENDIF

 LDA #%00000001         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bit 1 (i.e. disable the CA2 interrupt,
                        \ which comes from the keyboard)

ENDIF

 RTS                    \ This RTS actually does a jump to ENTRY2, to the next
                        \ step of the loader in part 5. See the documentation
                        \ for the stack routine at BEGIN% for more details

\ ******************************************************************************
\
\       Name: PLL1
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen
\
\ ------------------------------------------------------------------------------
\
\ Part 1 (PLL1) x 1280 - planet
\
\   * Draw pixels at (x, y) where:
\
\     r1 = random number from 0 to 255
\     r2 = random number from 0 to 255
\     (r1^2 + r1^2) < 128^2
\
\     y = r2, squished into 64 to 191 by negation
\
\     x = SQRT(128^2 - (r1^2 + r1^2)) / 2
\
\ Part 2 (PLL2) x 477 - stars
\
\   * Draw pixels at (x, y) where:
\
\     y = random number from 0 to 255
\     y = random number from 0 to 255
\     (x^2 + y^2) div 256 > 17
\
\ Part 3 (PLL3) x 1280 - rings
\
\   * Draw pixels at (x, y) where:
\
\     r5 = random number from 0 to 255
\     r6 = random number from 0 to 255
\     r7 = r5, squashed into -32 to 31
\
\     32 <= (r5^2 + r6^2 + r7^2) / 256 <= 79
\     Draw 50% fewer pixels when (r6^2 + r7^2) / 256 <= 16
\
\     x = r5 + r7
\     y = r5
\
\ Draws pixels within the diagonal band of horizontal width 64, from top-left to
\ bottom-right of the screen.
\
\ ******************************************************************************

.PLL1

                        \ The following loop iterates CNT(1 0) times, i.e. &500
                        \ or 1280 times, and draws the planet part of the
                        \ loading screen's Saturn

 LDA VIA+&44            \ Read the 6522 System VIA T1C-L timer 1 low-order
 STA RAND+1             \ counter (SHEILA &44), which increments 1000 times a
                        \ second so this will be pretty random, and store it in
                        \ RAND+1 among the hard-coded random seeds in RAND

 JSR DORND              \ Set A and X to random numbers, say A = r1

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r1^2

 STA ZP+1               \ Set ZP(1 0) = (A P)
 LDA P                  \             = r1^2
 STA ZP

 JSR DORND              \ Set A and X to random numbers, say A = r2

 STA YY                 \ Set YY = A
                        \        = r2

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r2^2

 TAX                    \ Set (X P) = (A P)
                        \           = r2^2

 LDA P                  \ Set (A ZP) = (X P) + ZP(1 0)
 ADC ZP                 \
 STA ZP                 \ first adding the low bytes

 TXA                    \ And then adding the high bytes
 ADC ZP+1

 BCS PLC1               \ If the addition overflowed, jump down to PLC1 to skip
                        \ to the next pixel

 STA ZP+1               \ Set ZP(1 0) = (A ZP)
                        \             = r1^2 + r2^2

 LDA #1                 \ Set ZP(1 0) = &4001 - ZP(1 0) - (1 - C)
 SBC ZP                 \             = 128^2 - ZP(1 0)
 STA ZP                 \
                        \ (as the C flag is clear), first subtracting the low
                        \ bytes

 LDA #&40               \ And then subtracting the high bytes
 SBC ZP+1
 STA ZP+1

 BCC PLC1               \ If the subtraction underflowed, jump down to PLC1 to
                        \ skip to the next pixel

                        \ If we get here, then both calculations fitted into
                        \ 16 bits, and we have:
                        \
                        \   ZP(1 0) = 128^2 - (r1^2 + r2^2)
                        \
                        \ where ZP(1 0) >= 0

 JSR ROOT               \ Set ZP = SQRT(ZP(1 0))

 LDA ZP                 \ Set X = ZP >> 1
 LSR A                  \       = SQRT(128^2 - (a^2 + b^2)) / 2
 TAX

 LDA YY                 \ Set A = YY
                        \       = r2

 CMP #128               \ If YY >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same, i.e. A is a random number in
                        \ one of these ranges:
                        \
                        \   %00000000 - %00111111  = 0 to 63    (r2 = 0 - 127)
                        \   %11000000 - %11111111  = 192 to 255 (r2 = 128 - 255)
                        \
                        \ The PIX routine flips bit 7 of A before drawing, and
                        \ that makes -A in these ranges:
                        \
                        \   %10000000 - %10111111  = 128-191
                        \   %01000000 - %01111111  = 64-127
                        \
                        \ so that's in the range 64 to 191

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), i.e. at
                        \
                        \   (ZP / 2, -A)
                        \
                        \ where ZP = SQRT(128^2 - (r1^2 + r2^2))
                        \
                        \ So this is the same as plotting at (x, y) where:
                        \
                        \   r1 = random number from 0 to 255
                        \   r1 = random number from 0 to 255
                        \   (r1^2 + r1^2) < 128^2
                        \
                        \   y = r2, squished into 64 to 191 by negation
                        \
                        \   x = SQRT(128^2 - (r1^2 + r1^2)) / 2
                        \
                        \ which is what we want

.PLC1

 DEC CNT                \ Decrement the counter in CNT (the low byte)

 BNE PLL1               \ Loop back to PLL1 until CNT = 0

 DEC CNT+1              \ Decrement the counter in CNT+1 (the high byte)

 BNE PLL1               \ Loop back to PLL1 until CNT+1 = 0

 LDX #&C2               \ Set the low byte of EXCN(1 0) to &C2, so we now have
 STX EXCN               \ EXCN(1 0) = &03C2, which we will use in the IRQ1
                        \ handler (this has nothing to do with drawing Saturn,
                        \ it's all part of the copy protection)

                        \ The following loop iterates CNT2(1 0) times, i.e. &1DD
                        \ or 477 times, and draws the background stars on the
                        \ loading screen

.PLL2

 JSR DORND              \ Set A and X to random numbers, say A = r3

 TAX                    \ Set X = A
                        \       = r3

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r3^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r3^2 / 256

 JSR DORND              \ Set A and X to random numbers, say A = r4

 STA YY                 \ Set YY = r4

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r4^2

 ADC ZP+1               \ Set A = A + r3^2 / 256
                        \       = r4^2 / 256 + r3^2 / 256
                        \       = (r3^2 + r4^2) / 256

 CMP #&11               \ If A < 17, jump down to PLC2 to skip to the next pixel
 BCC PLC2

 LDA YY                 \ Set A = r4

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), i.e. at
                        \ (r3, -r4), where (r3^2 + r4^2) / 256 >= 17
                        \
                        \ Negating a random number from 0 to 255 still gives a
                        \ random number from 0 to 255, so this is the same as
                        \ plotting at (x, y) where:
                        \
                        \   x = random number from 0 to 255
                        \   y = random number from 0 to 255
                        \   (x^2 + y^2) div 256 >= 17
                        \
                        \ which is what we want

.PLC2

 DEC CNT2               \ Decrement the counter in CNT2 (the low byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2 = 0

 DEC CNT2+1             \ Decrement the counter in CNT2+1 (the high byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2+1 = 0

 LDX MHCA               \ Set the low byte of BLPTR(1 0) to the contents of MHCA
 STX BLPTR              \ (which is &CA), so we now have BLPTR(1 0) = &03CA,
                        \ which we will use in the IRQ1 handler (this has
                        \ nothing to do with drawing Saturn, it's all part of
                        \ the copy protection)

 LDX #&C6               \ Set the low byte of BLN(1 0) to &C6, so we now have
 STX BLN                \ BLN(1 0) = &03C6, which we will use in the IRQ1
                        \ handler (this has nothing to do with drawing Saturn,
                        \ it's all part of the copy protection)

                        \ The following loop iterates CNT3(1 0) times, i.e. &500
                        \ or 1280 times, and draws the rings around the loading
                        \ screen's Saturn

.PLL3

 JSR DORND              \ Set A and X to random numbers, say A = r5

 STA ZP                 \ Set ZP = r5

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r5^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r5^2 / 256

 JSR DORND              \ Set A and X to random numbers, say A = r6

 STA YY                 \ Set YY = r6

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r6^2

 STA T                  \ Set T = A
                        \       = r6^2 / 256

 ADC ZP+1               \ Set ZP+1 = A + r5^2 / 256
 STA ZP+1               \          = r6^2 / 256 + r5^2 / 256
                        \          = (r5^2 + r6^2) / 256

 LDA ZP                 \ Set A = ZP
                        \       = r5

 CMP #128               \ If A >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of ZP, i.e. bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same

 CMP #128               \ If A >= 128, set the C flag (so again, the C flag is
                        \ set to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 5-7 are now the same, i.e. A is a random number in one
                        \ of these ranges:
                        \
                        \   %00000000 - %00011111  = 0-31
                        \   %11100000 - %11111111  = 224-255
                        \
                        \ In terms of signed 8-bit integers, this is a random
                        \ number from -32 to 31. Let's call it r7

 ADC YY                 \ Set X = A + YY
 TAX                    \       = r7 + r6

 JSR SQUA2              \ Set (A P) = r7 * r7

 TAY                    \ Set Y = A
                        \       = r7 * r7 / 256

 ADC ZP+1               \ Set A = A + ZP+1
                        \       = r7^2 / 256 + (r5^2 + r6^2) / 256
                        \       = (r5^2 + r6^2 + r7^2) / 256

 BCS PLC3               \ If the addition overflowed, jump down to PLC3 to skip
                        \ to the next pixel

 CMP #80                \ If A >= 80, jump down to PLC3 to skip to the next
 BCS PLC3               \ pixel

 CMP #32                \ If A < 32, jump down to PLC3 to skip to the next pixel
 BCC PLC3

 TYA                    \ Set A = Y + T
 ADC T                  \       = r7^2 / 256 + r6^2 / 256
                        \       = (r6^2 + r7^2) / 256

 CMP #16                \ If A > 16, skip to PL1 to plot the pixel
 BCS PL1

 LDA ZP                 \ If ZP is positive (50% chance), jump down to PLC3 to
 BPL PLC3               \ skip to the next pixel

.PL1

 LDA YY                 \ Set A = YY
                        \       = r6

 JSR PIX                \ Draw a pixel at screen coordinate (X, -A), where:
                        \
                        \   X = (random -32 to 31) + r6
                        \   A = r6
                        \
                        \ Negating a random number from 0 to 255 still gives a
                        \ random number from 0 to 255, so this is the same as
                        \ plotting at (x, y) where:
                        \
                        \   r5 = random number from 0 to 255
                        \   r6 = random number from 0 to 255
                        \   r7 = r5, squashed into -32 to 31
                        \
                        \   x = r5 + r7
                        \   y = r5
                        \
                        \   32 <= (r5^2 + r6^2 + r7^2) / 256 <= 79
                        \   Draw 50% fewer pixels when (r6^2 + r7^2) / 256 <= 16
                        \
                        \ which is what we want

.PLC3

 DEC CNT3               \ Decrement the counter in CNT3 (the low byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3 = 0

 DEC CNT3+1             \ Decrement the counter in CNT3+1 (the high byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3+1 = 0

\ ******************************************************************************
\
\       Name: DORND
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Generate random numbers
\  Deep dive: Generating random numbers
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to random numbers. The C and V flags are also set randomly.
\
\ This is a simplified version of the DORND routine in the main game code. It
\ swaps the two calculations around and omits the ROL A instruction, but is
\ otherwise very similar. See the DORND routine in the main game code for more
\ details.
\
\ ******************************************************************************

.DORND

 LDA RAND+1             \ r1´ = r1 + r3 + C
 TAX                    \ r3´ = r1
 ADC RAND+3
 STA RAND+1
 STX RAND+3

 LDA RAND               \ X = r2´ = r0
 TAX                    \ A = r0´ = r0 + r2
 ADC RAND+2
 STA RAND
 STX RAND+2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SQUA2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = A * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = A * A
\
\ This uses the same approach as routine SQUA2 in the main game code, which
\ itself uses the MU11 routine to do the multiplication. See those routines for
\ more details.
\
\ ******************************************************************************

.SQUA2

 BPL SQUA               \ If A > 0, jump to SQUA

 EOR #&FF               \ Otherwise we need to negate A for the SQUA algorithm
 CLC                    \ to work, so we do this using two's complement, by
 ADC #1                 \ setting A = ~A + 1

.SQUA

 STA Q                  \ Set Q = A and P = A

 STA P                  \ Set P = A

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDY #8                 \ Set up a counter in Y to count the 8 bits in P

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

.SQL1

 BCC SQ1                \ If C (i.e. the next bit from P) is set, do the
 CLC                    \ addition for this bit of P:
 ADC Q                  \
                        \   A = A + Q

.SQ1

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 DEY                    \ Decrement the loop counter

 BNE SQL1               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PIX
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a single pixel at a specific coordinate
\
\ ------------------------------------------------------------------------------
\
\ Draw a pixel at screen coordinate (X, -A). The sign bit of A gets flipped
\ before drawing, and then the routine uses the same approach as the PIXEL
\ routine in the main game code, except it plots a single pixel from TWOS
\ instead of a two pixel dash from TWOS2. This applies to the top part of the
\ screen (the monochrome mode 4 space view).
\
\ See the PIXEL routine in the main game code for more details.
\
\ Arguments:
\
\   X                   The screen x-coordinate of the pixel to draw
\
\   A                   The screen y-coordinate of the pixel to draw, negated
\
\ ******************************************************************************

.PIX

 TAY                    \ Copy A into Y, for use later

 EOR #%10000000         \ Flip the sign of A

 LSR A                  \ Set ZP+1 = &60 + A >> 3
 LSR A
 LSR A
 ORA #&60
 STA ZP+1

 TXA                    \ Set ZP = (X >> 3) * 8
 EOR #%10000000
 AND #%11111000
 STA ZP

 TYA                    \ Set Y = Y AND %111
 AND #%00000111
 TAY

 TXA                    \ Set X = X AND %111
 AND #%00000111
 TAX

 LDA TWOS,X             \ Otherwise fetch a pixel from TWOS and OR it into ZP+Y
 ORA (ZP),Y
 STA (ZP),Y

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 4 (the top part of the
\ split screen). See the PIX routine for details.
\
\ ******************************************************************************

.TWOS

 EQUB %10000000
 EQUB %01000000
 EQUB %00100000
 EQUB %00010000
 EQUB %00001000
 EQUB %00000100
 EQUB %00000010
 EQUB %00000001

\ ******************************************************************************
\
\       Name: CNT
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's planetary body
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL1 loop, which draws the planet part
\ of the loading screen's Saturn.
\
\ ******************************************************************************

.CNT

 EQUW &0500             \ The number of iterations of the PLL1 loop (1280)

\ ******************************************************************************
\
\       Name: CNT2
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's background stars
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL2 loop, which draws the background
\ stars on the loading screen.
\
\ ******************************************************************************

.CNT2

 EQUW &01DD             \ The number of iterations of the PLL2 loop (477)

\ ******************************************************************************
\
\       Name: CNT3
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's rings
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL3 loop, which draws the rings
\ around the loading screen's Saturn.
\
\ ******************************************************************************

.CNT3

 EQUW &0500             \ The number of iterations of the PLL3 loop (1280)

\ ******************************************************************************
\
\       Name: ROOT
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate ZP = SQRT(ZP(1 0))
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following square root:
\
\   ZP = SQRT(ZP(1 0))
\
\ This routine is identical to LL5 in the main game code - it even has the same
\ label names. The only difference is that LL5 calculates Q = SQRT(R Q), but
\ apart from the variables used, the instructions are identical, so see the LL5
\ routine in the main game code for more details on the algorithm used here.
\
\ ******************************************************************************

.ROOT

 LDY ZP+1               \ Set (Y Q) = ZP(1 0)
 LDA ZP
 STA Q

                        \ So now to calculate ZP = SQRT(Y Q)

 LDX #0                 \ Set X = 0, to hold the remainder

 STX ZP                 \ Set ZP = 0, to hold the result

 LDA #8                 \ Set P = 8, to use as a loop counter
 STA P

.LL6

 CPX ZP                 \ If X < ZP, jump to LL7
 BCC LL7

 BNE LL8                \ If X > ZP, jump to LL8

 CPY #64                \ If Y < 64, jump to LL7 with the C flag clear,
 BCC LL7                \ otherwise fall through into LL8 with the C flag set

.LL8

 TYA                    \ Set Y = Y - 64
 SBC #64                \
 TAY                    \ This subtraction will work as we know C is set from
                        \ the BCC above, and the result will not underflow as we
                        \ already checked that Y >= 64, so the C flag is also
                        \ set for the next subtraction

 TXA                    \ Set X = X - ZP
 SBC ZP
 TAX

.LL7

 ROL ZP                 \ Shift the result in Q to the left, shifting the C flag
                        \ into bit 0 and bit 7 into the C flag

 ASL Q                  \ Shift the dividend in (Y S) to the left, inserting
 TYA                    \ bit 7 from above into bit 0
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 ASL Q                  \ Shift the dividend in (Y S) to the left
 TYA
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 DEC P                  \ Decrement the loop counter

 BNE LL6                \ Loop back to LL6 until we have done 8 loops

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: BEGIN%
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Single-byte decryption and copying routine, run on the stack
\
\ ------------------------------------------------------------------------------
\
\ This routine is copied to the stack at &01F1. It pushes BLOCK to ENDBLOCK onto
\ the stack, and decrypts the code from TUT onwards.
\
\ The 15 instructions for this routine are pushed onto the stack and executed
\ there. The instructions are pushed onto the stack in reverse (as the stack
\ grows downwards in memory), so first the JMP gets pushed, then the STA, and
\ so on.
\
\ This is the code that is pushed onto the stack. It gets run by a JMP call to
\ David2, which then calls the routine on the stack with JSR &01F1.
\
\    01F1 : PLA             \ Remove the return address from the stack that was
\    01F2 : PLA             \ put here by the JSR that called this routine
\
\    01F3 : LDA BLOCK,Y     \ Set A = the Y-th byte of BLOCK
\
\    01F6 : PHA             \ Push A onto the stack
\
\    01F7 : EOR TUT,Y       \ EOR the Y-th byte of TUT with A
\    01FA : STA TUT,Y
\
\    01FD : JMP (David9)    \ Jump to the address in David9
\
\ The routine is called inside a loop with Y as the counter. It counts from 0 to
\ ENDBLOCK - BLOCK, so the routine eventually pushes every byte between BLOCK
\ and ENDBLOCK onto the stack, as well as EOR'ing each byte from TUT onwards to
\ decrypt that section.
\
\ The elite-checksums.py script reverses the order of the bytes between BLOCK
\ and ENDBLOCK in the final file, so pushing them onto the stack (which is a
\ descending stack) realigns them in memory as assembled below. Not only that,
\ but the last two bytes pushed on the stack are the ones that are at the start
\ of the block at BLOCK, and these contain the address of ENTRY2. This is why
\ the RTS at the end of part 4 above actually jumps to ENTRY2 in part 5.
\
\ ******************************************************************************

.BEGIN%

 EQUB HI(David9)        \ JMP (David9)
 EQUB LO(David9)
 EQUB &6C

 EQUB HI(TUT)           \ STA TUT,Y
 EQUB LO(TUT)
 EQUB &99

IF _REMOVE_CHECKSUMS

 EQUB HI(TUT)           \ If we have disabled checksums, then just load the Y-th
 EQUB LO(TUT)           \ byte of TUT with LDA TUT,Y
 EQUB &B9

ELSE

 EQUB HI(TUT)           \ EOR TUT,Y
 EQUB LO(TUT)
 EQUB &59

ENDIF

 PHA                    \ PHA

 EQUB HI(BLOCK)         \ LDA BLOCK,Y
 EQUB LO(BLOCK)
 EQUB &B9

 PLA                    \ PLA

 PLA                    \ PLA

\ ******************************************************************************
\
\       Name: DOMOVE
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Multi-byte decryption and copying routine, run on the stack
\
\ ------------------------------------------------------------------------------
\
\ This routine is copied to the stack at &01DF. It moves and decrypts a block of
\ memory. The original source refers to the stack routine as MVDL.
\
\ The 18 instructions for this routine are pushed onto the stack and executed
\ there. The instructions are pushed onto the stack in reverse (as the stack
\ grows downwards in memory), so first the RTS gets pushed, then the BNE, and
\ so on.
\
\ This is the code that is pushed onto the stack. It gets run by a JMP call to
\ crunchit, which then calls the routine on the stack at MVDL, or &01DF. The
\ label MVDL comes from a comment in the original source file ELITES.
\
\    01DF : .MVDL
\
\    01DF : LDA (ZP),Y      \ Set A = the Y-th byte from the block whose address
\                           \ is in ZP(1 0)
\
\    01E1 : EOR OSB,Y       \ EOR A with the Y-th byte on from OSB
\
\    01E4 : STA (P),Y       \ Store A in the Y-th byte of the block whose
\                           \ address is in P(1 0)
\
\    01E6 : DEY             \ Decrement the loop counter
\
\    01E7 : BNE MVDL        \ Loop back to copy and EOR the next byte until we
\                           \ have copied an entire page (256 bytes)
\
\    01E9 : INC P+1         \ Increment the high byte of P(1 0) so it points to
\                           \ the next page of 256 bytes
\
\    01EB : INC ZP+1        \ Increment ZP(1 0) so it points to the next page of
\                           \ 256 bytes
\
\    01ED : DEX             \ Decrement X
\
\    01EE : BNE MVDL        \ Loop back to copy the next page
\
\    01F0 : RTS             \ Return from the subroutine, which takes us back
\                           \ to the caller of the crunchit routine using a
\                           \ tail call, as we called this with JMP crunchit
\
\ We call MVDL with the following arguments:
\
\   (X Y)               The number of bytes to copy
\
\   ZP(1 0)             The source address
\
\   P(1 0)              The destination address
\
\ The routine moves and decrypts a block of memory, and is used in part 3 to
\ move blocks of code and images that are embedded within the loader binary,
\ either into low memory locations below PAGE (for the recursive token table and
\ page at UU%), or into screen memory (for the loading screen and dashboard
\ images).
\
\ If checksums are disabled in the build, we don't do the EOR instruction, so
\ the routine just moves and doesn't decrypt.
\
\ ******************************************************************************

.DOMOVE

 RTS                    \ RTS

 EQUW &D0EF             \ BNE MVDL

 DEX                    \ DEX

 EQUB ZP+1              \ INC ZP+1
 INC P+1                \ INC P+1
 EQUB &E6

 EQUW &D0F6             \ BNE MVDL

 DEY                    \ DEY

 EQUB P                 \ STA(P),Y
 EQUB &91

IF _REMOVE_CHECKSUMS

 NOP                    \ If we have disabled checksums, skip the EOR so the
 NOP                    \ routine just does the copying part
 NOP

ELSE

 EQUB HI(OSB)           \ EOR OSB,Y
 EQUB LO(OSB)
 EQUB &59

ENDIF

 EQUB ZP                \ LDA(ZP),Y
 EQUB &B1

\ ******************************************************************************
\
\       Name: UU%
\       Type: Workspace
\    Address: &0B00
\   Category: Workspaces
\    Summary: Marker for a block that is moved as part of the obfuscation
\
\ ------------------------------------------------------------------------------
\
\ The code from here to the end of the file gets copied to &0B00 (LE%) by part
\ 3. It is called from the end of part 4, via ENTRY2 in part 5 below.
\
\ ******************************************************************************

.UU%

Q% = P% - LE%
ORG LE%

\ ******************************************************************************
\
\       Name: CHECKbyt
\       Type: Variable
\   Category: Copy protection
\    Summary: Checksum for the validity of the UU% workspace
\
\ ------------------------------------------------------------------------------
\
\ We calculate the value of the CHECKbyt checksum in elite-checksum.py, so this
\ just reserves a byte. It checks the validity of the first two pages of the UU%
\ workspace, which gets copied to LE%.
\
\ ******************************************************************************

.CHECKbyt

 BRK                    \ This could be an EQUB 0 directive instead of a BRK,
                        \ but this is what's in the source code

\ ******************************************************************************
\
\       Name: MAINSUM
\       Type: Variable
\   Category: Copy protection
\    Summary: Two checksums for the decryption header and text token table
\
\ ------------------------------------------------------------------------------
\
\ Contains two checksum values, one for the header code at LBL, and the other
\ for the recursive token table from &0400 to &07FF.
\
\ ******************************************************************************

.MAINSUM

 EQUB &CB               \ This is the checksum value of the decryption header
                        \ code (from LBL to elitea) that gets prepended to the
                        \ main game code by elite-bcfs.asm and saved as
                        \ ELThead.bin

 EQUB 0                 \ This is the checksum value for the recursive token
                        \ table from &0400 to &07FF. We calculate the value in
                        \ elite-checksum.py, so this just reserves a byte

\ ******************************************************************************
\
\       Name: FOOLV
\       Type: Variable
\   Category: Copy protection
\    Summary: Part of the AFOOL roundabout obfuscation routine
\
\ ------------------------------------------------------------------------------
\
\ FOOLV contains the address of FOOL. This is part of the JSR AFOOL obfuscation
\ routine, which calls AFOOL, which then jumps to the address in FOOLV, which
\ contains the address of FOOL, which contains an RTS instruction... so overall
\ it does nothing, but in a rather roundabout fashion.
\
\ ******************************************************************************

.FOOLV

 EQUW FOOL              \ The address of FOOL, which contains an RTS

\ ******************************************************************************
\
\       Name: CHECKV
\       Type: Variable
\   Category: Copy protection
\    Summary: The address of the LBL routine in the decryption header
\
\ ------------------------------------------------------------------------------
\
\ CHECKV contains the address of the LBL routine at the very start of the main
\ game code file, in the decryption header code that gets prepended to the main
\ game code by elite-bcfs.asm and saved as ELThead.bin
\
\ ******************************************************************************

.CHECKV

 EQUW LOAD%+1           \ The address of the LBL routine

\ ******************************************************************************
\
\       Name: block1
\       Type: Variable
\   Category: Screen mode
\    Summary: Palette data for the two dashboard colour scheme
\
\ ------------------------------------------------------------------------------
\
\ Palette bytes for use with the split-screen mode 5. See TVT1 in the main game
\ code for an explanation.
\
\ ******************************************************************************

.block1

 EQUB &F5, &E5
 EQUB &B5, &A5
 EQUB &76, &66
 EQUB &36, &26
 EQUB &D4, &C4
 EQUB &94, &84

\ ******************************************************************************
\
\       Name: block2
\       Type: Variable
\   Category: Screen mode
\    Summary: Palette data for the space part of the screen
\
\ ------------------------------------------------------------------------------
\
\ Palette bytes for use with the split-screen mode 4. See TVT1 in the main game
\ code for an explanation.
\
\ ******************************************************************************

.block2

 EQUB &D0, &C0
 EQUB &B0, &A0
 EQUB &F0, &E0
 EQUB &90, &80
 EQUB &77, &67
 EQUB &37, &27

\ ******************************************************************************
\
\       Name: TT26
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character at the text cursor (WRCHV points here)
\
\ ------------------------------------------------------------------------------
\
\ This routine prints a character at the text cursor (XC, YC). It is very
\ similar to the routine of the same name in the main game code, so refer to
\ that routine for a more detailed description.
\
\ This routine, however, only works within a small 14x14 character text window,
\ which we use for the tape loading messages, so there is extra code for fitting
\ the text into the window (and it also reverses the effect of line feeds and
\ carriage returns).
\
\ Arguments:
\
\   A                   The character to be printed
\
\   XC                  Contains the text column to print at (the x-coordinate)
\
\   YC                  Contains the line number to print on (the y-coordinate)
\
\ Returns:
\
\   A                   A is preserved
\
\   X                   X is preserved
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.TT26

 STA K3                 \ Store the A, X and Y registers (in K3 for A, and on
 TYA                    \ the stack for the others), so we can restore them at
 PHA                    \ the end (so they don't get changed by this routine)
 TXA
 PHA

.rr

 LDA K3                 \ Set A = the character to be printed

 CMP #7                 \ If this is a beep character (A = 7), jump to R5,
 BEQ R5                 \ which will emit the beep, restore the registers and
                        \ return from the subroutine

 CMP #32                \ If this is an ASCII character (A >= 32), jump to RR1
 BCS RR1                \ below, which will print the character, restore the
                        \ registers and return from the subroutine

 CMP #13                \ If this is control code 13 (carriage return) then jump
 BEQ RRX1               \ to RRX1, which will move along on character, restore
                        \ the registers and return from the subroutine (as we
                        \ don't have room in the text window for new lines)

 INC YC                 \ If we get here, then this is control code 10, a line
                        \ feed, so move down one line and fall through into RRX1
                        \ to move the cursor to the start of the line

.RRX1

 LDX #7                 \ Set the column number (x-coordinate) of the text
 STX XC                 \ to 7

 BNE RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine (this BNE is effectively a JMP as Y
                        \ will never be zero)

.RR1

 LDX #&BF               \ Set X to point to the first font page in ROM minus 1,
                        \ which is &C0 - 1, or &BF

 ASL A                  \ If bit 6 of the character is clear (A is 32-63)
 ASL A                  \ then skip the following instruction
 BCC P%+4

 LDX #&C1               \ A is 64-126, so set X to point to page &C1

 ASL A                  \ If bit 5 of the character is clear (A is 64-95)
 BCC P%+3               \ then skip the following instruction

 INX                    \ Increment X, so X now contains the high byte
                        \ (the page) of the address of the definition that we
                        \ want, while A contains the low byte (the offset into
                        \ the page) of the address

 STA P                  \ Store the address of this character's definition in
 STX P+1                \ P(1 0)

 LDA XC                 \ If the column number (x-coordinate) of the text is
 CMP #20                \ less than 20, skip to NOLF
 BCC NOLF

 LDA #7                 \ Otherwise we just reached the end of the line, so
 STA XC                 \ move the text cursor to column 7, and down onto the
 INC YC                 \ next line

.NOLF

 ASL A                  \ Multiply the x-coordinate (column) of the text by 8
 ASL A                  \ and store in ZP, to get the low byte of the screen
 ASL A                  \ address for the character we want to print
 STA ZP

 INC XC                 \ Once we print the character, we want to move the text
                        \ cursor to the right, so we do this by incrementing XC

 LDA YC                 \ If the row number (y-coordinate) of the text is less
 CMP #19                \ than 19, skip to RR3
 BCC RR3

                        \ Otherwise we just reached the bottom of the screen,
                        \ which is a small 14x14 character text window we use
                        \ for showing the tape loading messages, so now we need
                        \ to clear that window and move the cursor to the top

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 LDA #&65               \ Set the high byte of the SC(1 0) to &65, for character
 STA SC+1               \ row 5 of the screen

 LDY #7*8               \ Set Y = 7 * 8, for column 7 (as there are 8 bytes per
                        \ character block)

 LDX #14                \ Set X = 14, to count the number of character rows we
                        \ need to clear

 STY SC                 \ Set the low byte of SC(1 0) to 7*8, so SC(1 0) now
                        \ points to the character block at row 5, column 7, at
                        \ the top-left corner of the small text window

 LDA #0                 \ Set A = 0 for use in clearing the screen (which we do
                        \ by setting the screen memory to 0)

 TAY                    \ Set Y = 0

.David1

 STA (SC),Y             \ Clear the Y-th byte of the block pointed to by SC(1 0)

 INY                    \ Increment the counter in Y

 CPY #14*8              \ Loop back to clear the next byte until we have done 14
 BCC David1             \ lots of 8 bytes (i.e. 14 characters, the width of the
                        \ small text window)

 TAY                    \ Set Y = 0, ready for the next row

 INC SC+1               \ Point SC(1 0) to the next page in memory, i.e. the
                        \ next character row

 DEX                    \ Decrement the counter in X

 BPL David1             \ Loop back to David1 until we have done 14 character
                        \ rows (the height of the small text window)

 LDA #5                 \ Move the text cursor to row 5
 STA YC

 BNE rr                 \ Jump to rr to print the character we were about to
                        \ print when we ran out of space (this BNE is
                        \ effectively a JMP as A will never be zero)

.RR3

 ORA #&60               \ Add &60 to YC, giving us the page number that we want

 STA ZP+1               \ Store the page number of the destination screen
                        \ location in ZP+1, so ZP now points to the full screen
                        \ location where this character should go

 LDY #7                 \ We want to print the 8 bytes of character data to the
                        \ screen (one byte per row), so set up a counter in Y
                        \ to count these bytes

.RRL1

 LDA (P),Y              \ The character definition is at P(1 0) - we set this up
                        \ above -  so load the Y-th byte from P(1 0)

 STA (ZP),Y             \ Store the Y-th byte at the screen address for this
                        \ character location

 DEY                    \ Decrement the loop counter

 BPL RRL1               \ Loop back for the next byte to print to the screen

.RR4

 PLA                    \ We're done printing, so restore the values of the
 TAX                    \ A, X and Y registers that we saved above, loading them
 PLA                    \ from K3 (for A) and the stack (for X and Y)
 TAY
 LDA K3

.FOOL

 RTS                    \ Return from the subroutine

.R5

 LDA #7                 \ Control code 7 makes a beep, so load this into A

 JSR osprint            \ Call OSPRINT to "print" the beep character

 JMP RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: osprint
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Print a character
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to print
\
\ ******************************************************************************

.TUT

.osprint

 JMP (OSPRNT)           \ Jump to the address in OSPRNT and return using a
                        \ tail call

 EQUB &6C

\ ******************************************************************************
\
\       Name: command
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Execute an OS command
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (Y X)               The address of the OS command string to execute
\
\ ******************************************************************************

.command

 JMP (oscliv)           \ Jump to &FFF7 to execute the OS command pointed to
                        \ by (Y X) and return using a tail call

\ ******************************************************************************
\
\       Name: MESS1
\       Type: Variable
\   Category: Utility routines
\    Summary: Contains an OS command string for loading the main game code
\
\ ******************************************************************************

.MESS1

IF DISC

 EQUS "L.ELTcode 1100"

ELSE

 EQUS "L.ELITEcode F1F"

ENDIF

 EQUB 13

\ ******************************************************************************
\
\       Name: Elite loader (Part 5 of 6)
\       Type: Subroutine
\   Category: Loader
\    Summary: Load main game code, decrypt it, move it to the correct location
\
\ ------------------------------------------------------------------------------
\
\ This part loads the main game code, decrypts it and moves it to the correct
\ location for it to run.
\
\ The code in this part is encrypted by elite-checksum.py and is decrypted in
\ part 4 by the same routine that moves part 6 onto the stack.
\
\ ******************************************************************************

.ENTRY2

                        \ We start this part of the loader by setting the
                        \ following:
                        \
                        \   OSPRNT(1 0) = WRCHV
                        \   WRCHV(1 0) = TT26
                        \   (Y X) = MESS1(1 0)
                        \
                        \ so any character printing will use the TT26 routine

 LDA &20E               \ Copy the low byte of WRCHV to the low byte of OSPRNT
 STA OSPRNT

 LDA #LO(TT26)          \ Set the low byte of WRCHV to the low byte of TT26
 STA &20E

 LDX #LO(MESS1)         \ Set X to the low byte of MESS1

 LDA &20F               \ Copy the high byte of WRCHV to the high byte of OSPRNT
 STA OSPRNT+1

 LDA #HI(TT26)          \ Set the high byte of WRCHV to the high byte of TT26
 LDY #HI(MESS1)         \ and set Y to the high byte of MESS1
 STA &20F

 JSR AFOOL              \ This calls AFOOL, which jumps to the address in FOOLV,
                        \ which contains the address of FOOL, which contains an
                        \ RTS instruction... so overall this does nothing, but
                        \ in a rather roundabout fashion

 JSR command            \ Call command to execute the OSCLI command pointed to
                        \ by (Y X) in MESS1, which starts loading the main game
                        \ code

 JSR 512-LEN+CHECKER-ENDBLOCK \ Call the CHECKER routine in its new location on
                              \ the stack, to run a number of checksums on the
                              \ code (this routine, along with the whole of part
                              \ 6, was pushed onto the stack in part 4)

 JSR AFOOL              \ Another call to the round-the-houses routine to try
                        \ and distract the crackers, presumably

IF DISC

 LDA #140               \ Call OSBYTE with A = 140 and X = 12 to select the
 LDX #12                \ tape filing system (i.e. do a *TAPE command)
 JSR OSBYTE

ENDIF

 LDA #0                 \ Set SVN to 0, as the main game code checks the value
 STA SVN                \ of this location in its IRQ1 routine, so it needs to
                        \ be set to 0 so it can work properly once it takes over
                        \ when the game itself runs

                        \ We now decrypt and move the main game code from &1128
                        \ to &0F40

 LDX #HI(LC%)           \ Set X = high byte of LC%, the maximum size of the main
                        \ game code, so if we move this number of pages, we will
                        \ have definitely moved all the game code down

 LDA #LO(L%)            \ Set ZP(1 0) = L% (the start of the game code)
 STA ZP
 LDA #HI(L%)
 STA ZP+1

 LDA #LO(C%)            \ Set P(1 0) = C% = &0F40
 STA P
 LDA #HI(C%)
 STA P+1

 LDY #0                 \ Set Y as a counter for working our way through every
                        \ byte of the game code. We EOR the counter with the
                        \ current byte to decrypt it

.ML1

 TYA                    \ Copy the counter into A

IF _REMOVE_CHECKSUMS

 LDA (ZP),Y             \ If we have disabled checksums, just fetch the byte to
                        \ copy from the Y-th block pointed to by ZP(1 0)

ELSE

 EOR (ZP),Y             \ Fetch the byte and EOR it with the counter

ENDIF

 STA (P),Y              \ Store the copied (and decrypted) byte in the Y-th byte
                        \ of the block pointed to by P(1 0)

 INY                    \ Increment the loop counter

 BNE ML1                \ Loop back for the next byte until we have finished the
                        \ first 256 bytes

 INC ZP+1               \ Increment the high bytes of both ZP(1 0) and P(1 0) to
 INC P+1                \ point to the next 256 bytes

 DEX                    \ Decrement the number of pages we need to copy in X

 BPL ML1                \ Loop back to copy and decrypt the next page of bytes
                        \ until we have done them all

                        \ S% points to the entry point for the main game code,
                        \ so the following copies the addresses from the start
                        \ of the main code (see the S% label in the main game
                        \ code for the vector values)

 LDA S%+6               \ Set BRKV to point to the BR1 routine in the main game
 STA &202               \ code
 LDA S%+7
 STA &203

 LDA S%+2               \ Set WRCHV to point to the TT26 routine in the main
 STA &20E               \ game code
 LDA S%+3
 STA &20F

 RTS                    \ This RTS actually does a jump to the first instruction
                        \ in BLOCK, after the two EQUW operatives, which is now
                        \ on the stack. This takes us to the next and final
                        \ step of the loader in part 6. See the documentation
                        \ for the stack routine at BEGIN% for more details

.AFOOL

 JMP (FOOLV)            \ This jumps to the address in FOOLV as part of the
                        \ JSR AFOOL instruction above, which does nothing except
                        \ take us on wild goose chase

\ ******************************************************************************
\
\       Name: M2
\       Type: Variable
\   Category: Utility routines
\    Summary: Used for testing the 6522 System VIA status byte in IRQ1
\
\ ------------------------------------------------------------------------------
\
\ Used for testing bit 1 of the 6522 System VIA status byte in the IRQ1 routine,
\ as well as bit 1 of the block flag.
\
\ ******************************************************************************

.M2

 EQUB %00000010         \ Bit 1 is set

\ ******************************************************************************
\
\       Name: IRQ1
\       Type: Subroutine
\   Category: Screen mode
\    Summary: The loader's screen-mode interrupt handler (IRQ1V points here)
\  Deep dive: The split-screen mode
\
\ ------------------------------------------------------------------------------
\
\ The main interrupt handler, which implements Elite's split-screen mode.
\
\ This routine is similar to the main IRQ1 routine in the main game code, except
\ it's a bit simpler (it doesn't need to support the mode-flashing effect of
\ hyperspace, for example).
\
\ It also sets Timer 1 to a different value, 14386 instead of 14622. The split
\ in the split-screen mode does overlap more in the loader than in the game, so
\ it's interesting that they didn't fine-tune this version as much.
\
\ For more details on how the following works, see the IRQ1 routine in the main
\ game code.
\
\ ******************************************************************************

.VIA2

 LDA #%00000100         \ Set the Video ULA control register (SHEILA &20) to
 STA &FE20              \ %00000100, which is the same as switching to mode 5,
                        \ (i.e. the bottom part of the screen) but with no
                        \ cursor

 LDY #11                \ We now apply the palette bytes from block1 to the
                        \ mode 5 screen, so set a counter in Y for 12 bytes

.inlp1

 LDA block1,Y           \ Copy the Y-th palette byte from block1 to SHEILA &21
 STA &FE21              \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BPL inlp1              \ Loop back to the inlp1 until we have copied all the
                        \ palette bytes

 PLA                    \ Restore Y from the stack
 TAY

 JMP (VEC)              \ Jump to the address in VEC, which was set to the
                        \ original IRQ1V vector in part 4, so this instruction
                        \ passes control to the next interrupt handler

.IRQ1

 TYA                    \ Store Y on the stack
 PHA

IF PROT AND DISC = 0

                        \ By this point, we have set up the following in
                        \ various places throughout the loader code (such as
                        \ part 2 and PLL1):
                        \
                        \   BLPTR(1 0) = &03CA
                        \   BLN(1 0)   = &03C6
                        \   EXCN(1 0)  = &03C2
                        \
                        \ BLPTR (&03CA) is a byte in the MOS workspace that
                        \ stores the block flag of the most recent block loaded
                        \ from tape
                        \
                        \ BLN (&03C6) is the low byte of the number of the last
                        \ block loaded from tape
                        \
                        \ EXCN (&03C2) is the low byte of the execution address
                        \ of the file being loaded

 LDY #0                 \ Set A to the block flag of the most recent block
 LDA (BLPTR),Y          \ loaded from tape

 BIT M2                 \ If bit 1 of the block flag is set, jump to itdone
 BNE itdone

 EOR #%10000011         \ Otherwise flip bits 0, 1 and 7 of A. This has two
                        \ main effects:
                        \
                        \   * Bit 0 of the block flag gets cleared. Most
                        \     cassette versions of Acornsoft games are saved to
                        \     tape with locked blocks, so you can't just load
                        \     the game into memory (you'll get a "Locked" error
                        \     for each block). Locked blocks have bit 0 set, so
                        \     this clears the locked status, so when the MOS
                        \     gets round to checking whether the block is
                        \     locked, we've already cleared it and updated it in
                        \     memory (which we do below), so the block loads
                        \     without throwing an error
                        \
                        \   * Bit 1 of the block flag gets set, so we won't
                        \     increment BLCNT again until the next block starts
                        \     loading (so in this way we count the number of
                        \     blocks loaded in BLCNT)

 INC BLCNT              \ Increment BLCNT, which was initialised to 0 in part 3

 BNE ZQK                \ If BLCNT is non-zero, skip the next instruction

 DEC BLCNT              \ If incrementing BLCNT set it to zero, decrement it, so
                        \ this sets a maximum of 255 on BLCNT

.ZQK

 STA (BLPTR),Y          \ Store the updated value of A in the block flag, so the
                        \ block gets unlocked

 LDA #&23               \ If the block number in BLN is &23, skip the next
 CMP (BLN),Y            \ instruction
 BEQ P%+4

 EOR #17                \ EOR A with 17

 CMP (EXCN),Y           \ If A = the low byte of the execution address of the
 BEQ itdone             \ file we are loading, skip to itdone

 DEC LOAD%              \ Otherwise decrement LOAD%, which is the address of the
                        \ first byte of the main game code file (i.e. the load
                        \ address of "ELTcode"), so this decrements the first
                        \ byte of the file we are loading

.itdone

ENDIF

 LDA VIA+&4D            \ Read the 6522 System VIA status byte bit 1 (SHEILA
 BIT M2                 \ &4D), which is set if vertical sync has occurred on
                        \ the video system

 BNE LINSCN             \ If we are on the vertical sync pulse, jump to LINSCN
                        \ to set up the timers to enable us to switch the
                        \ screen mode between the space view and dashboard

 AND #%01000000         \ If the 6522 System VIA status byte bit 6 is set, which
 BNE VIA2               \ means timer 1 has timed out, jump to VIA2

 PLA                    \ Restore Y from the stack
 TAY

 JMP (VEC)              \ Jump to the address in VEC, which was set to the
                        \ original IRQ1V vector in part 4, so this instruction
                        \ passes control to the next interrupt handler

.LINSCN

 LDA #50                \ Set 6522 System VIA T1C-L timer 1 low-order counter
 STA VIA+&44            \ (SHEILA &44) to 50

 LDA #VSCAN             \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to VSCAN (56) to start the T1 counter
                        \ counting down from 14386 at a rate of 1 MHz

 LDA #8                 \ Set the Video ULA control register (SHEILA &20) to
 STA &FE20              \ %00001000, which is the same as switching to mode 4
                        \ (i.e. the top part of the screen) but with no cursor

 LDY #11                \ We now apply the palette bytes from block2 to the
                        \ mode 4 screen, so set a counter in Y for 12 bytes

.inlp2

 LDA block2,Y           \ Copy the Y-th palette byte from block2 to SHEILA &21
 STA &FE21              \ to map logical to actual colours for the top part of
                        \ the screen (i.e. the space view)

 DEY                    \ Decrement the palette byte counter

 BPL inlp2              \ Loop back to the inlp1 until we have copied all the
                        \ palette bytes

 PLA                    \ Restore Y from the stack
 TAY

 JMP (VEC)              \ Jump to the address in VEC, which was set to the
                        \ original IRQ1V vector in part 4, so this instruction
                        \ passes control to the next interrupt handler

\ ******************************************************************************
\
\       Name: BLOCK
\       Type: Variable
\   Category: Copy protection
\    Summary: Addresses for the obfuscated jumps that use RTS not JMP
\
\ ------------------------------------------------------------------------------
\
\ These two addresses get pushed onto the stack in part 4. The first EQUW is the
\ address of ENTRY2, while the second is the address of the first instruction in
\ part 6, after it is pushed onto the stack.
\
\ This entire section from BLOCK to ENDBLOCK gets copied into the stack at
\ location &015E by part 4, so by the time we call the routine at the second
\ EQUW address at the start, the entry point is on the stack at &0163.
\
\ This means that the RTS instructions at the end of parts 4 and 5 jump to
\ ENTRY2 and the start of part 6 respectively. See part 4 for details.
\
\ ******************************************************************************

.BLOCK

 EQUW ENTRY2-1

 EQUW 512-LEN+BLOCK-ENDBLOCK+3

\ ******************************************************************************
\
\       Name: Elite loader (Part 6 of 6)
\       Type: Subroutine
\   Category: Loader
\    Summary: Set up interrupt vectors, calculate checksums, run main game code
\
\ ------------------------------------------------------------------------------
\
\ This is the final part of the loader. It sets up some of the main game's
\ interrupt vectors and calculates various checksums, before finally handing
\ over to the main game.
\
\ ******************************************************************************

 LDA VIA+&44            \ Read the 6522 System VIA T1C-L timer 1 low-order
 STA 1                  \ counter (SHEILA &44) which increments 1000 times a
                        \ second so this will be pretty random, and store it in
                        \ location 1, which is among the main game code's random
                        \ seeds in RAND (so this seeds the random numbers for
                        \ the main game)

 SEI                    \ Disable all interrupts

 LDA #%00111001         \ Set 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bits 0 and 3-5 (i.e. disable the Timer1,
                        \ CB1, CB2 and CA2 interrupts from the System VIA)

\LDA #&7F               \ These instructions are commented out in the original
\STA &FE6E              \ source with the comment "already done", which they
\LDA IRQ1V              \ were, in part 4
\STA VEC
\LDA IRQ1V+1
\STA VEC+1

 LDA S%+4               \ S% points to the entry point for the main game code,
 STA IRQ1V              \ so this copies the address of the main game's IRQ1
 LDA S%+5               \ routine from the start of the main code into IRQ1V
 STA IRQ1V+1

 LDA #VSCAN             \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to VSCAN (56) to start the T1 counter
                        \ counting down from 14080 at a rate of 1 MHz (this is
                        \ a different value to the main game code)

 CLI                    \ Re-enable interrupts

\LDA #129               \ These instructions are commented out in the original
\LDY #&FF               \ source. They call OSBYTE with A = 129, X = 1 and
\LDX #1                 \ Y = &FF, which returns the machine type in X, so
\JSR OSBYTE             \ this code would detect the MOS version
\TXA
\EOR #&FF
\STA MOS
\BMI BLAST

 LDY #0                 \ Call OSBYTE with A = 200, X = 3 and Y = 0 to disable
 LDA #200               \ the ESCAPE key and clear memory if the BREAK key is
 LDX #3                 \ pressed
 JSR OSBYTE

                        \ The rest of the routine calculates various checksums
                        \ and makes sure they are correct before proceeding, to
                        \ prevent code tampering. We start by calculating the
                        \ checksum for the main game code from &0F40 to &5540,
                        \ which just adds up every byte and checks it against
                        \ the checksum stored at the end of the main game code

.BLAST

 LDA #HI(S%)            \ Set ZP(1 0) = S%
 STA ZP+1               \
 LDA #LO(S%)            \ so ZP(1 0) points to the start of the main game code
 STA ZP

 LDX #&45               \ We are going to checksum &45 pages from &0F40 to &5540
                        \ so set a page counter in X

 LDY #0                 \ Set Y to count through each byte within each page

 TYA                    \ Set A = 0 for building the checksum

.CHK

 CLC                    \ Add the Y-th byte of this page of the game code to A
 ADC (ZP),Y

 INY                    \ Increment the counter for this page

 BNE CHK                \ Loop back for the next byte until we have finished
                        \ adding up this page

 INC ZP+1               \ Increment the high byte of ZP(1 0) to point to the
                        \ next page

 DEX                    \ Decrement the page counter we set in X

 BPL CHK                \ Loop back to add up the next page until we have done
                        \ them all

IF _REMOVE_CHECKSUMS

 LDA #0                 \ If we have disabled checksums, just set A to 0 so the
 NOP                    \ BEQ below jumps to itsOK

ELSE

 CMP D%-1               \ D% is set to the size of the main game code, so this
                        \ compares the result to the last byte in the main game
                        \ code, at location checksum0

ENDIF

 BEQ itsOK              \ If the checksum we just calculated matches the value
                        \ in location checksum0, jump to itsOK

.nononono

 STA S%+1               \ If we get here then the checksum was wrong, so first
                        \ we store the incorrect checksum value in the low byte
                        \ of the address stored at the start of the main game
                        \ code, which contains the address of TT170, the entry
                        \ point for the main game (so this hides this address
                        \ from prying eyes)

 LDA #%01111111         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bits 0-6 (i.e. disable all hardware
                        \ interrupts from the System VIA)

 JMP (&FFFC)            \ Jump to the address in &FFFC to reset the machine

.itsOK

 JMP (S%)               \ The checksum was correct, so we call the address held
                        \ in the first two bytes of the main game code, which
                        \ point to TT170, the entry point for the main game
                        \ code, so this, finally, is where we hand over to the
                        \ game itself

\ ******************************************************************************
\
\       Name: CHECKER
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Run checksum checks on tokens, loader and tape block count
\
\ ------------------------------------------------------------------------------
\
\ This routine runs checksum checks on the recursive token table and the loader
\ code at the start of the main game code file, to prevent tampering with these
\ areas of memory. It also runs a check on the tape loading block count.
\
\ ******************************************************************************

.CHECKER

                        \ First we check the MAINSUM+1 checksum for the
                        \ recursive token table from &0400 to &07FF

 LDY #0                 \ Set Y = 0 to count through each byte within each page

 LDX #4                 \ We are going to checksum 4 pages from &0400 to &07FF
                        \ so set a page counter in X

 STX ZP+1               \ Set ZP(1 0) = &0400, to point to the start of the code
 STY ZP                 \ we want to checksum

 TYA                    \ Set A = 0 for building the checksum

.CHKq

 CLC                    \ Add the Y-th byte of this page of the token table to A
 ADC (ZP),Y

 INY                    \ Increment the counter for this page

 BNE CHKq               \ Loop back for the next byte until we have finished
                        \ adding up this page

 INC ZP+1               \ Increment the high byte of ZP(1 0) to point to the
                        \ next page

 DEX                    \ Decrement the page counter we set in X

 BNE CHKq               \ Loop back to add up the next page until we have done
                        \ them all

 CMP MAINSUM+1          \ Compare the result to the contents of MAINSUM+1, which
                        \ contains the checksum for the table (this gets set by
                        \ elite-checksum.py)

IF _REMOVE_CHECKSUMS

 NOP                    \ If we have disabled checksums, do nothing
 NOP

ELSE

 BNE nononono           \ If the checksum we just calculated does not match the
                        \ contents of MAINSUM+1, jump to nononono to reset the
                        \ machine

ENDIF

                        \ Next, we check the LBL routine in the header that's
                        \ appended to the main game code in elite-bcfs.asm, and
                        \ which is currently loaded at LOAD% (which contains the
                        \ load address of the main game code file)

 TYA                    \ Set A = 0 for building the checksum (as Y is still 0
                        \ from the above checksum loop)

.CHKb

 CLC                    \ Add the Y-th byte of LOAD% to A
 ADC LOAD%,Y

 INY                    \ Increment the counter

 CPY #&28               \ There are &28 bytes in the loader, so loop back until
 BNE CHKb               \ we have added them all

 CMP MAINSUM            \ Compare the result to the contents of MAINSUM, which
                        \ contains the checksum for loader code

IF _REMOVE_CHECKSUMS

 NOP                    \ If we have disabled checksums, do nothing
 NOP

ELSE

 BNE nononono           \ If the checksum we just calculated does not match the
                        \ contents of MAINSUM, jump to nononono to reset the
                        \ machine

ENDIF

                        \ Finally, we check the block count from the tape
                        \ loading code in the IRQ1 routine, which counts the
                        \ number of blocks in the main game code

IF PROT AND DISC = 0

 LDA BLCNT              \ If the tape protection is enabled and we are loading
 CMP #&4F               \ from tape (as opposed to disc), check that the block
 BCC nononono           \ count in BLCNT is &4F, and if it isn't, jump to
                        \ nononono to reset the machine

ENDIF

IF _REMOVE_CHECKSUMS

 RTS                    \ If we have disabled checksums, return from the
 NOP                    \ subroutine
 NOP

ELSE

 JMP (CHECKV)           \ Call the LBL routine in the header (whose address is
                        \ in CHECKV). This routine is inserted before the main
                        \ game code by elite-bcfs.asm, and it checks the
                        \ validity of the first two pages of the UU% routine,
                        \ which was copied to LE% above, and which contains a
                        \ checksum byte in CHECKbyt. We then return from the
                        \ subroutine using a tail call

ENDIF

.ENDBLOCK

\ ******************************************************************************
\
\       Name: XC
\       Type: Variable
\   Category: Text
\    Summary: The x-coordinate of the text cursor
\
\ ------------------------------------------------------------------------------
\
\ Contains the x-coordinate of the text cursor (i.e. the text column) with an
\ initial value of column 7, at the top-left corner of the 14x14 text window
\ where we show the tape loading messages (see TT26 for details).
\
\ ******************************************************************************

.XC

 EQUB 7

\ ******************************************************************************
\
\       Name: YC
\       Type: Variable
\   Category: Text
\    Summary: The y-coordinate of the text cursor
\
\ ------------------------------------------------------------------------------
\
\ Contains the y-coordinate of the text cursor (i.e. the text row) with an
\ initial value of row 6, at the top-left corner of the 14x14 text window where
\ we show the tape loading messages (see TT26 for details).
\
\ ******************************************************************************

.YC

 EQUB 6

\ ******************************************************************************
\
\ Save output/ELITE.unprot.bin
\
\ ******************************************************************************

COPYBLOCK LE%, P%, UU%  \ Copy the block that we assembled at LE% to UU%, which
                        \ is where it will actually run

PRINT "BLOCK offset = ", ~(BLOCK - LE%) + (UU% - CODE%)
PRINT "ENDBLOCK offset = ",~(ENDBLOCK - LE%) + (UU% - CODE%)
PRINT "MAINSUM offset = ",~(MAINSUM - LE%) + (UU% - CODE%)
PRINT "TUT offset = ",~(TUT - LE%) + (UU% - CODE%)
PRINT "UU% = ",~UU%," Q% = ",~Q%, " OSB = ",~OSB

PRINT "Memory usage: ", ~LE%, " - ",~P%
PRINT "Stack: ",LEN + ENDBLOCK - BLOCK

PRINT "S. ELITE ", ~CODE%, " ", ~UU% + (P% - LE%), " ", ~run, " ", ~CODE%
SAVE "output/ELITE.unprot.bin", CODE%, UU% + (P% - LE%), run, CODE%
