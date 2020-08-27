\ ******************************************************************************
\
\ ELITE LOADER SOURCE
\
\ The original 1984 source code is copyright Ian Bell and David Braben, and the
\ code on this site is identical to the version released by the authors on Ian
\ Bell's personal website at http://www.iancgbell.clara.net/elite/
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ ******************************************************************************
\
\ This source file produces the following binary file:
\
\   * output/ELITE.unprot.bin
\
\ after reading in the following files:
\
\   * images/DIALS.bin
\   * images/P.ELITE.bin
\   * images/P.A-SOFT.bin
\   * images/P.(C)ASFT.bin
\   * output/WORDS9.bin
\   * output/PYTHON.bin
\
\ ******************************************************************************

INCLUDE "elite-header.h.asm"

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

DISC = TRUE             \ Set to TRUE to load the code above DFS and relocate
                        \ down, so we can load the tape version from disc

PROT = FALSE            \ Set to TRUE to enable the tape protection code

LOAD% = &1100           \ LOAD% is the load address of the main game code file
                        \ ("ELTcode")

C% = &0F40              \ C% is set to the location that the main game code gets
                        \ moved to after it is loaded

S% = C%                 \ S% points to the entry point for the main game code

L% = LOAD% + &28        \ L% points to the start of the actual game code from
                        \ elite-source.asm, after the &28 bytes of header code
                        \ that are inserted by elite-bcfs.asm

D% = &563A              \ D% is set to the size of the main game code

LC% = &6000 - C%        \ LC% is set to the maximum size of the main game code

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

LE% = &B00              \ LE% is the address of the second stage loader (the one
                        \ containing ENTRY2)

IF DISC                 \ CODE% is set to the assembly address of the loader
 CODE% = &E00+&300      \ code file that we assemble in this file ("ELITE")
ELSE
 CODE% = &E00
ENDIF

NETV = &224             \ MOS vectors that we want to intercept
IRQ1V = &204

OSWRCH = &FFEE          \ The OS routines used in the loader
OSBYTE = &FFF4
OSWORD = &FFF1
OSPRNT = &234

VIA = &FE40             \ Memory-mapped space for accessing internal hardware,
USVIA = VIA             \ such as the video ULA, 6845 CRTC and 6522 VIAs

VSCAN = 57-1            \ Defines the split position in the split screen mode

TRTB% = &04             \ Zero page variables
ZP = &70
P = &72
Q = &73
YY = &74
T = &75
SC = &76
BLPTR = &78
V219 = &7A
K3 = &80
BLCNT = &81
BLN = &83
EXCN = &85

\ ******************************************************************************
\
\ Elite loader (Part 1 of )
\
\ The loader bundles a number of binary files in with the loader code, and moves
\ them to their correct memory locations in part 3 below.
\
\ There are two files containing code:
\
\   * WORDS9.bin contains the recursive token table, which moved to &0400 before
\     the main game is loaded
\
\   * PYTHON.bin contains the Python ship blueprint, which gets moved to &7F00
\     before the main game is loaded
\
\ And four files containing images, which are all moved into screen memory by
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
\     &7800, which is the starting point of the the four-colour mode 5 portion
\     at the bottom of the split screen
\
\  The routine ends with a jump to the start of the loader code at ENTRY.
\
\ ******************************************************************************

ORG CODE%
PRINT "WORDS9 = ",~P%
INCBIN "output/WORDS9.bin"

ORG CODE% + &400
PRINT "P.DIALS = ",~P%
INCBIN "images/P.DIALS.bin"

ORG CODE% + &B00
PRINT "PYTHON = ",~P%
INCBIN "output/PYTHON.bin"

ORG CODE% + &C00
PRINT "P.ELITE = ",~P%
INCBIN "images/P.ELITE.bin"

ORG CODE% + &D00
PRINT "P.A-SOFT = ",~P%
INCBIN "images/P.A-SOFT.bin"

ORG CODE% + &E00
PRINT "P.(C)ASFT = ",~P%
INCBIN "images/P.(C)ASFT.bin"

O% = CODE% + &400 + &800 + &300
ORG O%

.run

 JMP ENTRY              \ Jump to ENTRY to start the loading process

\ ******************************************************************************
\
\ Variable B%: VDU command data
\
\ This block containd the bytes that get passed to the VDU command (via OSWRCH)
\ in part 2 to set up the screen mode. This defines the whole screen using a
\ square, monochrome mode 4 configuration; the mode 5 part is implemented in the
\ IRQ1 routine.
\
\ Elite's monochrome screen mode is based on mode 4 but with the following
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
\   * The text window is 1 row high and 13 columns wide, and is at at (2, 16)
\
\   * There's a large, fast-blinking cursor
\
\ This almost-square mode 4 variant makes life a lot easier when drawing to the
\ screen, as there are 256 pixels on each row (or, to put it in screen memory
\ terms, there's one page of memory per row of pixels). For more details of the
\ screen mode, see the PIXEL subroutine in elite-source.asm.
\
\ There is also an interrupt-driven routine that switches the bytes-per-pixel
\ setting from that of mode 4 to that of mode 5, when the raster reaches the
\ split between the space view and the dashboard. This is described in the IRQ1
\ routine below, which does the switching.
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
 EQUB 0, 0, 0           \ This is the "cursor start" register, which sets the
                        \ cursor start line at 0 with a fast blink rate

\ ******************************************************************************
\
\ Variable E%: Sound envelope data
\
\ This table contains the sound envelope data, which is passed to OSWORD to set
\ up the sound envelopes in part 2 below. Refer to chapter 30 of the BBC Micro
\ User Guide for details of sound envelopes.
\
\ ******************************************************************************

.E%

 EQUB 1, 1, 0, 111, -8, 4, 1, 8, 8, -2, 0, -1, 112, 44
 EQUB 2, 1, 14, -18, -1, 44, 32, 50, 6, 1, 0, -2, 120, 126
 EQUB 3, 1, 1, -1, -3, 17, 32, 128, 1, 0, 0, -1, 1, 1
 EQUB 4, 1, 4, -8, 44, 4, 6, 8, 22, 0, 0, -127, 126, 0

\ ******************************************************************************
\
\ Elite loader (Part 2 of )
\
\ This part of the loader does a number of calls to OS calls, sets up the sound
\ envelopes, pushes 33 bytes onto the stack that will be used later, and sends
\ us on a wild goose chase, just for kicks.
\
\ ******************************************************************************

.swine 

 LDA #%01111111         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bits 0-6 (i.e. disable all hardware
                        \ interrupts from the System VIA)

 JMP (&FFFC)            \ Jump to the address in &FFFC to reset the machine

.OSB

 LDY #0                 \ Call OSBYTE with Y = 0, returning from the subroutine
 JMP OSBYTE             \ using a tail call (so we can call OSB to call OSBYTE
                        \ for when we know we want Y set to 0)

 EQUS "R.ELITEcode"     \ A message buried in the code from the authors
 EQUB 13
 EQUS "By D.Braben/I.Bell"
 EQUB 13
 EQUB &B0

.oscliv

 EQUW &FFF7             \ Addresses of various functions used by loader to
                        \ obfuscate

.David9

 EQUW David5            \ This address is used in the decryption loop starting
                        \ at David2 in part 4, and is used to jump back into the
                        \ loop at David5

 CLD

.David23

 EQUW (512-LEN)         \ This two-byte address points to the start of the
                        \ 6502 stack, which descends from the end of page 2,
                        \ less LEN bytes, which comes out as &01DF. So if we
                        \ push 33 bytes onto the stack (LEN being 33), this
                        \ address will point to the start of those bytes, which
                        \ means we can push executable code onto the stack and
                        \ run it by calling this address with a JMP (David23)
                        \ instruction. Sneaky stuff!

.doPROT1

                        \ This is called from below with A = &48 and X = 255

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

.MHCA

 EQUB &CA               \ This value is used to set the low byte of BLPTR(1 0)
                        \ when it's set in PLL1

.David7

 BCC Ian1               \ This instruction is part of the multi-jump obfuscation
                        \ in PROT1

.ENTRY

                        \ This is where the JMP at the start of the loader goes

 SEI                    \ Disable all interrupts

 CLD                    \ Clear the decimal flag, so we're not in decimal mode

IF DISC = FALSE

 LDA #0                 \ Call OSBYTE with A = 0 and X = 255 to fetch the
 LDX #255               \ operating sustem version into X
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

 LDA #&60               \ Store an RTS instruction in location &232 NETV
 STA &232

 LDA #&2                \ Point the NETV vector at &232, which we just filled
 STA NETV+1             \ with an RTS
 LDA #&32
 STA NETV

 LDA #&20               \ Set A to the op code for a JSR call with absolute
                        \ addressing

 EQUB &2C               \ Skip the next instruction by turning it into a BIT
                        \ instruction, which does nothing bar affecting the
                        \ flags

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

 EQUB &2C               \ Skip the next instruction by turning it into a BIT
                        \ instruction, which does nothing bar affecting the
                        \ flags

.FRED1

 BNE David7             \ This instruction is skipped if we came from above,
                        \ otherwise this is part of the multi-jump obfuscation
                        \ in PROT1

 LDX #255               \ Call doPROT1 to change an instruction in the PROT1
 LDA #&48               \ routine and set up another couple of variables
 JSR doPROT1

 LDA #144               \ Call OSBYTE with A = 144 and Y = 0 to turn the screen
 JSR OSB                \ interlace on (equivalent to a *TV 255,0 command)

 LDA #247               \ Call OSBYTE with A = 247 and X = Y = 0 to disable the
 LDX #0                 \ BREAK intercept code by poking 0 into the first value
 JSR OSB

\LDA #&81               \ These instructions are commented out in the original
\LDY #&FF               \ source, along with the comment "Damn 0.1", so
\LDX #1                 \ presumably MOS version 0.1 was a bit of a pain to
\JSR OSBYTE             \ support - which is probably why Elite doesn't bother
\TXA                    \ and only supports 1.0 and 1.2
\BPL OS01
\Damn 0.1

 LDA #190               \ Call OSBYTE with A = 190, X = 8 and Y = 0 to set the
 LDX #8                 \ ADC conversion type to 8 bits, for the joystick
 JSR OSB

 EQUB &2C               \ Skip the next instruction by turning it into a BIT
                        \ instruction, which does nothing bar affecting the
                        \ flags

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
 LDX #128               \ the function keys to return ASCII codes for Shift-fn
 JSR OSB                \ keys (i.e. add 128)

 LDA #172               \ Call OSBYTE 172 to read the address of the MOS
 LDX #0                 \ keyboard translation table into (Y X)
 LDY #255
 JSR OSBYTE
 
 STX TRTB%              \ Store the address of the keyboard translation table in
 STY TRTB%+1            \ TRTB%(1 0)

 LDA #200               \ Call OSBYTE with A = 200, X = 3 and Y = 0 to disable
 LDX #3                 \ the Escape key and clear memory if the Break key is
 JSR OSB                \ pressed

IF PROT AND DISC = 0
 CPX #3                 \ If the previous value of X from the call to OSBYTE 200
 BNE abrk+1             \ was not 3 (Escape disabled, clear memory), jump to
                        \ abrk+1, which contains a BRK instruction which will
                        \ reset the computer (as we set BRKV to point to the
                        \ reset address above)
ENDIF

 LDA #13                \ Call OSBYTE with A = 13, X = 2 and Y = 0 to disable
 LDX #2                 \ the "character entering keyboard buffer" event
 JSR OSB

.OS01                   \ Reset stack

 LDX #&FF               \ Set stack pointer to &01FF, as stack is in page 1
 TXS                    \ (this is the standard location for the 6502 stack,
                        \ so this instruction effectively resets the stack)

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

 LDY #0                 \ We are now going to send the 67 VDU bytes in the table
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
                        \ and can therfore be used in-game

 LDA #9                 \ Disable flashing colours (via OSBYTE 9)
 LDX #0
 JSR OSB

 LDA #&6C               \ Poke &6C into crunchit after EOR'ing it first (which
 EOR crunchit           \ has no effect as crunchit contains a BRK instruction
 STA crunchit           \ with opcode 0), to change crunchit to an indirect JMP

MACRO FNE I%
  LDX #LO(E%+I%*14)     \ Call OSWORD with A = 8 and (Y X) pointing to the
  LDY #HI(E%+I%*14)     \ I%-th set of envelope data in E%, to set up sound
  LDA #8                \ envelope I%
  JSR OSWORD
ENDMACRO

 FNE 0                  \ Set up sound envelopes 0-3 using the macro above
 FNE 1
 FNE 2
 FNE 3

\ ******************************************************************************
\
\ Elite loader (Part 3 of )
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
\ Elite loader (Part 4 of )
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
                        \ before decrypting the Y-th byte of BLOCK in-place. It
                        \ then jumps back to David5 below, where we increment Y
                        \ until it reaches a value of ENDBLOCK - BLOCK. So this
                        \ loop basically decrypts the code from TUT onwards, and
                        \ at the same time it pushed the code between BLOCK and
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

 LDA C%,X               \ Obfuscate the X-th byte of C% by EOR-ing with &A5
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

 EQUW &4CFF

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

 CPY #(ENDBLOCK-BLOCK)  \ Loop back to decrypt the next byte until we have
 BNE David2             \ decrypted all the bytes between BLOCK and ENDBLOCK

 SEI                    \ Disable interrupts while we set up our interrupt
                        \ handler to support the split-screen mode

 LDA #%11000010         \ Clear 6522 System VIA interrupt enable register IER
 STA VIA+&E             \ (SHEILA &4E) bits 1 and 7 (i.e. enable CA1 and TIMER1
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
 STA USVIA+5            \ (SHEILA &45) to VSCAN (56) to start the T1 counter
                        \ counting down from 14080 at a rate of 1 MHz (this is
                        \ a different value to the main game code)

 CLI                    \ Re-enable interrupts

IF DISC

 LDA #%10000001         \ Clear 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bit 1 (i.e. enable the CA2 interrupt,
                        \ which comes from the keyboard)

 LDY #20                \ Set Y = 20 for the following OSBYTE call

 IF _REMOVE_CHECKSUMS
 
  NOP                   \ Skip the OSBYTE call if checksums are disabled
  NOP
  NOP
 
 ELSE

  JSR OSBYTE            \ A was set to 129 above, so this calls OSBYTE with
                        \ A = 129 and Y = 20, which reads the keyboard with a
                        \ time limit, in this case 20 centiseconds, or 0.2
                        \ seconds
 
 ENDIF

 LDA #%00000001         \ Set 6522 System VIA interrupt enable register IER
 STA &FE4E              \ (SHEILA &4E) bit 1 (i.e. disable the CA2 interrupt,
                        \ which comes from the keyboard)

ENDIF

 RTS                    \ The address of ENTRY2-1 was pushed onto the stack by
                        \ the decryption loop above (as ENTRY2-1 is stored in
                        \ BLOCK, unencrypted), so this RTS actually does a jump
                        \ to ENTRY2, for the next step of the loader

\ ******************************************************************************
\
\ PLL1
\
\ Draw Saturn on the loading screen.
\
\ Part 1 (PLL1) x 1280 - planet
\ Draw pixels at (x, y) where:
\
\   x = SQRT(128^2 - (r1^2 + r2^2)) / 2
\
\   r1^2 + r2^2 fits into 16-bits
\
\   128^2 - (r1^2 + r2^2) fits into 16-bits
\
\   y = a random number in either 0-63 or 192-255
\
\ Part 2 (PLL2) x 477 - stars
\ Draw pixels at (r3, r4) where (r3^2 + r4^2) / 256 > 17
\
\ Part 3 (PLL3) x 1280 - rings
\
\ ******************************************************************************

.PLL1
{
                        \ The following loop iterates CNT(1 0) times, i.e. &500
                        \ or 1280 times

 LDA VIA+4              \ Read the 6522 System VIA T1C-L timer 1 low-order
 STA RAND+1             \ counter, which increments 1000 times a second so this
                        \ will be pretty random, and store it in RAND+1 among
                        \ the hard-coded random seeds in RAND

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

 LDA #1                 \ Set ZP(1 0) = &4000 - ZP(1 0)
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
                        \ where ZP > 0

 JSR ROOT               \ Set ZP = SQRT(ZP(1 0))
                        \
                        \ so ZP is now in the range 0-128

 LDA ZP                 \ Set X = ZP / 2
 LSR A
 TAX

 LDA YY                 \ Set A = YY
                        \       = r2

 CMP #128               \ If YY >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of YY, i.e. bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same, i.e. A is a random number in
                        \ one of these ranges:
                        \
                        \   %00000000 - %00111111  = 0-63
                        \   %11000000 - %11111111  = 192-255

 JSR PIX                \ Draw a pixel at screen coordinate (X, A), i.e. at
                        \
                        \ (ZP / 2, A)
                        \
                        \ where ZP = SQRT(128^2 - (r1^2 + r2^2)) and A is a
                        \ random number in either 0-63 or 192-255

.PLC1

 DEC CNT                \ Decrement the counter in CNT (the low byte)

 BNE PLL1               \ Loop back to PLL1 until CNT = 0

 DEC CNT+1              \ Decrement the counter in CNT+1 (the high byte)

 BNE PLL1               \ Loop back to PLL1 until CNT+1 = 0

 LDX #&C2               \ Set the low byte of EXCN(1 0) to &C2, so we now have
 STX EXCN               \ EXCN(1 0) = &03C2, which we will use in the IRQ1
                        \ handler (this has nothing to do with drawing Saturn,
                        \ it's all part of the copy protection)

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

 JSR PIX                \ Draw a pixel at screen coordinate (X, A), i.e. at
                        \ (r3, r4) where (r3^2 + r4^2) / 256 > 17

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
                        \ 5-7 are now the same, i.e. A is in one of these
                        \ ranges:
                        \
                        \   %00000000 - %00011111  = 0-31
                        \   %11100000 - %11111111  = 224-255
                        \
                        \ Call it r7

 ADC YY                 \ Set X = A + YY
 TAX                    \       = r7 + r6

 JSR SQUA2              \ Set (A P) = r7 * r7

 TAY                    \ Set Y = A
                        \       = r7 * r7 / 256

 ADC ZP+1               \ Set A = A + ZP+1
                        \       = r7^2 / 256 + (r5^2 + r6^2) / 256

 BCS PLC3               \ If the addition overflowed, jump down to PLC3 to skip
                        \ to the next pixel

 CMP #80                \ If A >= 80, jump down to PLC3 to skip to the next
 BCS PLC3               \ pixel


 CMP #32                \ If A < 32, jump down to PLC3 to skip to the next
 BCC PLC3               \ pixel

 TYA                    \ Set A = Y + T
 ADC T                  \       = r7 * r7 / 256 + r6^2 / 256

 CMP #16                \ If A > 16, skip to PL1 to plot the pixel
 BCS PL1

 LDA ZP                 \ If ZP is positive (50% chance), jump down to PLC3 to
 BPL PLC3               \ skip to the next pixel

.PL1

 LDA YY                 \ Set A = YY
                        \       = r6

 JSR PIX                \ Draw a pixel at screen coordinate (X, A)

.PLC3

 DEC CNT3               \ Decrement the counter in CNT3 (the low byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3 = 0

 DEC CNT3+1             \ Decrement the counter in CNT3+1 (the high byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3+1 = 0

\ ******************************************************************************
\
\ Subroutine: DORND
\
\ Set A and X to random numbers. Carry flag is also set randomly. Overflow flag
\ will be have a 50% probability of being 0 or 1.
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
\ Subroutine: SQUA2
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
                        \ and carry = bit 0 of P

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
\ Subroutine: PIX
\
\ Draw a pixel at screen coordinate (X, A). This uses the same approach as the
\ PIXEL routine in the main game code, except it plots a single pixel from TWOS
\ instead of a two pixel dash from TWOS2. This applies to the top part of the
\ screen (the monochrome mode 4 portion). See the PIXEL routine in the main game
\ code for more details.
\
\ Arguments:
\
\   X                   The screen x-coordinate of the pixel to draw
\
\   A                   The screen y-coordinate of the pixel to draw
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
\ Variables
\
\ This block contains various variables and tables used by the routines that
\ draw Saturn on the loading screen.
\
\ ******************************************************************************

.TWOS

 EQUB %10000000         \ Ready-made bytes for plotting one-pixel points in mode
 EQUB %01000000         \ 4 (the top part of the split screen). See the PIX
 EQUB %00100000         \ routine for details
 EQUB %00010000
 EQUB %00001000
 EQUB %00000100
 EQUB %00000010
 EQUB %00000001

.CNT

 EQUW &0500             \ The number of iterations of the PLL1 loop (1280)

.CNT2

 EQUW &01DD             \ The number of iterations of the PLL2 loop (477)

.CNT3

 EQUW &0500             \ The number of iterations of the PLL3 loop (1280)

\ ******************************************************************************
\
\ Subroutine: ROOT
\
\ Calculate the following square root:
\
\   ZP = SQRT(ZP(1 0))
\
\ This routine is identical to LL5 in the main game code - it even has the same
\ label names. The only difference is that LL5 calculates Q = SQRT(R Q), but
\ apart from the variables used, the instructions are identical, so see the LL5
\ routine in the main game code for more details.
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
}

\ ******************************************************************************
\
\ Subroutine: Copied from BEGIN% to the stack at &01F1
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
\ ENDBLOCK - BLOCK, so the routine eventually decrypts every byte between BLOCK
\ and ENDBLOCK, as well as pushing the unencrypted bytes onto the stack.
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

 EQUB HI(TUT)           \ LDA TUT,Y
 EQUB LO(TUT)
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
\ Subroutine: MVDL, copied from DOMOVE to the stack at &01DF
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
\    01E1 : EOR OSB,Y       \ EOR A with the Y-th byte on from from OSB
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
\ either into low memory locations below PAGE (for the the recursive token table
\ and page at UU%), or into screen memory (for the loading screen and dashboard
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

 NOP                    \ Skip the EOR if checksums are disabled
 NOP
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
\ Variables
\
\ This code all located at &B00 onwards
\
\ ******************************************************************************

.UU%

Q% = P% - LE%
ORG LE%

.CHECKbyt

 BRK                    \ CHECKbyt checksum value calcuated in elite-checksum.py

.MAINSUM

 EQUB &CB               \ hard-coded checksum value of &28 bytes at LBL in elite-bcfs.asm (ELThead)
 EQUB 0                 \ MAINSUM checksum value calculated in elite-checksum.py

.FOOLV

 EQUW FOOL              \ address of fn with just RTS

.CHECKV

 EQUW LOAD%+1           \ address of LBL fn in elite-bcfs.asm (ELThead)

.block1

 EQUD &A5B5E5F5         \ ULA Palette colours for MODE 5 portion of screen
 EQUD &26366676
 EQUD &8494C4D4

.block2

 EQUD &A0B0C0D0         \ ULA Palette colours for MODE 4 portion of screen
 EQUD &8090E0F0
 EQUD &27376777         \ Colours for interrupts

\ ******************************************************************************
\
\ Subroutine: TT26
\
\ PRINT fn for OSPRNT
\
\ ******************************************************************************

.TT26                   \ PRINT  Please tidy this up!
{
 STA K3
 TYA
 PHA
 TXA
 PHA

.rr

 LDA K3
 CMP #7
 BEQ R5
 CMP #32
 BCS RR1
 CMP #13
 BEQ RRX1
 INC YC

.RRX1

 LDX#7
 STX XC
 BNE RR4

.RR1

 LDX #&BF
 ASL A
 ASL A
 BCC P%+4
 LDX #&C1
 ASL A
 BCC P%+3
 INX 
 STA P
 STX P+1

 LDA XC
 CMP #20
 BCC NOLF
 LDA #7
 STA XC
 INC YC

.NOLF

 ASL A
 ASL A
 ASL A
 STA ZP
 INC XC
 LDA YC
 CMP #19
 BCC RR3
 LDA #7
 STA XC
 LDA #&65
 STA SC+1
 LDY #7*8
 LDX #14
 STY SC
 LDA #0
 TAY

.David1

 STA (SC),Y
 INY 
 CPY #14*8
 BCC David1
 TAY
 INC SC+1
 DEX
 BPL David1
 LDA #5
 STA YC

 BNE rr

.RR3

 ORA #&60
 STA ZP+1
 LDY #7

.RRL1

 LDA (P),Y
 STA (ZP),Y
 DEY
 BPL RRL1

.RR4
 PLA
 TAX
 PLA
 TAY
 LDA K3

.^FOOL
 RTS

.R5
 LDA #7
 JSR osprint
 JMP RR4
}

\ ******************************************************************************
\
\ Elite loader (Part 5 of )
\
\ Following code all encrypted in elite-checksum.py
\
\ ******************************************************************************

.TUT                    \ EOR here onward

.osprint

 JMP (OSPRNT)
 EQUB &6C

.command

 JMP (oscliv)

.MESS1

IF DISC
 EQUS "L.ELTcode 1100"
ELSE
 EQUS "L.ELITEcode F1F"
ENDIF

 EQUB 13                \ *LOAD ELITEcode

.ENTRY2                 \ Second entry point for loader after screen & irq set up

 LDA &20E               \ Set OSPRNT vector to TT26 fn
 STA OSPRNT
 LDA #(TT26 MOD256)
 STA &20E
 LDX #(MESS1 MOD256)
 LDA &20F
 STA OSPRNT+1
 LDA #(TT26 DIV256)
 LDY #(MESS1 DIV256)
 STA &20F               \ OSWRCH for loading messages

 JSR AFOOL

 JSR command            \ Issue OSCLI command in MESS1 "*L.ELTcode 1100"

                        \ Execute CHECKER fn but in stack

 JSR 512-LEN+CHECKER-ENDBLOCK 
 JSR AFOOL
                        \ (Gratuitous JSRs)- LOAD Mcode and checksum it.

IF DISC
 LDA #140               \ Issue *TAPE command (via OSBYTE 140)
 LDX #12
 JSR OSBYTE             \*TAPE 
ENDIF

 LDA #0                 \ Set SVN to 0, as the main game code checks the value
 STA SVN                \ of this location in its IRQ1 routine, so it needs to
                        \ be set to 0 so it can work properly


 LDX #(LC% DIV256)      \ Decrypt and copy down all ELITE game code from &1128 to &F40
 LDA #(L% MOD256)
 STA ZP
 LDA #(L% DIV256)
 STA ZP+1
 LDA #(C% MOD256)
 STA P
 LDA #(C% DIV256)
 STA P+1
 LDY #0

.ML1

 TYA

IF _REMOVE_CHECKSUMS
 LDA (ZP),Y
ELSE
 EOR (ZP),Y
ENDIF

 STA (P),Y
 INY 
 BNE ML1
 INC ZP+1
 INC P+1
 DEX
 BPL ML1                \ Move code down (d)

 LDA S%+6               \ Set BRKV and WRCHV to point at BR1 and TT26 fns in elite-source.asm

 STA &202
 LDA S%+7
 STA &203
 LDA S%+2
 STA &20E
 LDA S%+3
 STA &20F               \ BRK,OSWRCH     

                        \ Calls final boot code from value copied to stack

 RTS                    \- ON STACK 

.AFOOL

 JMP(FOOLV)

.M2

 EQUB 2

\ ******************************************************************************
\
\ Subroutine: IRQ1
\
\ IRQ1V handler for Timer 1 interrupt
\
\ ******************************************************************************

{
.VIA2

 LDA #4                 \ Set ULA Control Register to 20 characters per line (MODE 5)
 STA &FE20

 LDY #11                \ Set ULA Palette Registers for MODE 5 colour scheme

.inlp1

 LDA block1,Y
 STA &FE21
 DEY
 BPL inlp1
 PLA
 TAY
 JMP (VEC)

.^IRQ1

 TYA                    \ IRQ1V handler
 PHA

IF PROT AND DISC = 0
 LDY #0                 \ TAPE protection

 LDA (BLPTR),Y
 BIT M2
 BNE itdone
 EOR#128+3
 INC BLCNT
 BNE ZQK
 DEC BLCNT

.ZQK

 STA (BLPTR),Y
 LDA #&23
 CMP (BLN),Y
 BEQ P%+4
 EOR #17
 CMP (EXCN),Y
 BEQ itdone
 DEC LOAD%

.itdone

ENDIF

 LDA VIA+&D             \ Test which interrupt has occurred
 BIT M2
 BNE LINSCN
 AND #64
 BNE VIA2
 PLA
 TAY
 JMP (VEC)

.LINSCN

                        \ IRQ1V handler for Vsync interrupt

 LDA #50                \ Reset Timer 1 counter value Hi and Low bytes
 STA USVIA+4
 LDA #VSCAN
 STA USVIA+5

 LDA #8                 \ Set ULA Control Register to 40 characters per line (MODE 4)
 STA &FE20
 LDY #11

.inlp2

 LDA block2,Y           \ Set ULA Palette Registers for MODE 4 black & white
 STA &FE21
 DEY
 BPL inlp2
 PLA
 TAY
 JMP (VEC)
}

\ ******************************************************************************
\
\ Subroutine: Copied from BLOCK to the stack
\
\ Obfuscated code
\
\ Entire BLOCK to ENDBLOCK copied into stack at location &15E
\
\ ******************************************************************************

.BLOCK                  \ Pushed onto stack for execution

 EQUW ENTRY2-1                  \ return address for ENTRY2
 EQUW 512-LEN+BLOCK-ENDBLOCK+3  \ return address for final boot code (below)

\ ******************************************************************************
\
\ Elite loader (Part 6 of )
\
\ Final boot code starts at &163
\
\ ******************************************************************************

 LDA VIA+4              \ Disable SYSVIA interrupts Timer2, CB1, CB2, CA2
 STA 1
 SEI
 LDA #&39
 STA VIA+&E
\LDA#&7F
\STA&FE6E
\LDAIRQ1V
\STAVEC
\LDAIRQ1V+1
\STAVEC+1  Already done

 LDA S%+4               \ Set IRQ1V to IRQ1 fn in elite-source.asm & set Timer 1 Counter Hi value
 STA IRQ1V
 LDA S%+5
 STA IRQ1V+1
 LDA #VSCAN
 STA USVIA+5
 CLI \Interrupt vectors

\LDA#&81LDY#FFLDX#1JSROSBYTETXAEOR#FFSTAMOS \FF if MOS0.1 else 0
\BMIBLAST

 LDY #0                 \ Disable ESCAPE, memory cleared on BREAK (via OSBYTE 200)
 LDA #200
 LDX #3
 JSR OSBYTE

.BLAST

                        \ break,escape

 LDA #(S% DIV256)       \ Calculate Checksum0 = 70x pages of all Elite code from &F40 to &5540
 STA ZP+1
 LDA #(S% MOD256)
 STA ZP
 LDX #&45
 LDY #0
 TYA

.CHK

 CLC
 ADC (ZP),Y
 INY 
 BNE CHK
 INC ZP+1
 DEX
 BPL CHK

IF _REMOVE_CHECKSUMS
 LDA #0:NOP
ELSE
 CMP D%-1
ENDIF

 BEQ itsOK

.nononono

 STA S%+1               \ Checksum wrong - disable all interrupts and reset machine
 LDA #&7F
 STA &FE4E
 JMP (&FFFC)

.itsOK

 JMP(S%)

.CHECKER

 LDY #0                  \ CHECKER fn verifies checksum values
 LDX #4
 STX ZP+1
 STY ZP
 TYA

.CHKq

 CLC                    \ Verify MAINSUM of WORDS9 = 4 pages from &400 to &800
 ADC (ZP),Y
 INY 
 BNE CHKq
 INC ZP+1
 DEX
 BNE CHKq
 CMP MAINSUM+1

IF _REMOVE_CHECKSUMS
 NOP:NOP
ELSE
 BNE nononono
ENDIF

 TYA                    \ Verify (hard coded) checksum of LBL in elite-bcfs.asm (ELThead)

.CHKb

 CLC
 ADC LOAD%,Y
 INY 
 CPY #&28
 BNE CHKb
 CMP MAINSUM

IF _REMOVE_CHECKSUMS
 NOP:NOP
ELSE
 BNE nononono
ENDIF

IF PROT AND DISC = 0
 LDA BLCNT
 CMP #&4F
 BCC nononono
ENDIF

IF _REMOVE_CHECKSUMS
 RTS:NOP:NOP
ELSE
 JMP (CHECKV)           \ Call LBL in elite-bcfs.sm (ELThead) to verify CHECKbyt checksum
ENDIF

.ENDBLOCK               \ no more on to stack

\ ******************************************************************************
\
\ Variables: XC, YC
\
\ ******************************************************************************

.XC

 EQUB 7                 \ Variables used by PRINT function

.YC

 EQUB 6

\ ******************************************************************************
\
\ Save output/ELITE.unprot.bin
\
\ We assembled a block of code at &B00
\ Need to copy this up to end of main code
\ Further processing completed by elite-checksum.py script
\
\ ******************************************************************************

COPYBLOCK LE%, P%, UU%

PRINT "BLOCK offset = ", ~(BLOCK - LE%) + (UU% - CODE%)
PRINT "ENDBLOCK offset = ",~(ENDBLOCK - LE%) + (UU% - CODE%)
PRINT "MAINSUM offset = ",~(MAINSUM - LE%) + (UU% - CODE%)
PRINT "TUT offset = ",~(TUT - LE%) + (UU% - CODE%)
PRINT "UU% = ",~UU%," Q% = ",~Q%, " OSB = ",~OSB

PRINT "Memory usage: ", ~LE%, " - ",~P%
PRINT "Stack: ",LEN + ENDBLOCK - BLOCK

PRINT "S. ELITE ", ~CODE%, " ", ~UU% + (P% - LE%), " ", ~run, " ", ~CODE%
SAVE "output/ELITE.unprot.bin", CODE%, UU% + (P% - LE%), run, CODE%
