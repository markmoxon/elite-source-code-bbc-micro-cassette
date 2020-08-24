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

DISC = TRUE             \ load above DFS and relocate down
PROT = FALSE            \ TAPE protection

LOAD% = &1100           \ load address of ELTcode (elite-bcfs.asm)

C% = &F40               \ assembly address of Elite game code (elite-source.asm)
S% = C%
L% = LOAD% + &28        \ load address Elite game code (elite-bcfs.asm)
D% = &563A              \ hardcoded size of Elite game code (elite-source.asm)
LC% = &6000 - C%        \ maximum size of Elite game code

SVN = &7FFD
LEN1 = 15
LEN2 = 18
LEN = LEN1 + LEN2

LE% = &B00              \ address of second stage loader (containing ENTRY2)

IF DISC
 LL% = &E00+&300        \ load address of loader
ELSE
 LL% = &E00
ENDIF

CODE% = LL%             \ we can assemble in place

TRTB% = 4               \ MOS key translation table

NETV = &224             \ MOS vectors we want to intercept
IRQ1V = &204

OSWRCH = &FFEE          \ The OS routines used in the loader
OSBYTE = &FFF4
OSWORD = &FFF1
OSPRNT = &234

VIA = &FE40             \ Memory-mapped space for accessing internal hardware,
USVIA = VIA             \ such as the video ULA, 6845 CRTC and 6522 VIAs

VSCAN = 57-1            \ Defines the split position in the split screen mode
VEC = &7FFE

ZP = &70                \ Zero page variables
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
\
\ Include the binary files that the loader loads into memory
\
\ ******************************************************************************

ORG CODE%
PRINT "WORDS9 = ",~P%
INCBIN "output/WORDS9.bin"

ORG CODE% + &400
PRINT "DIALS = ",~P%
INCBIN "images/DIALS.bin"

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

ORG LL% + &400 + &800 + &300
O% = CODE% + &400 + &800 + &300

\ ******************************************************************************
\
\ Elite loader (Part 2 of )
\
\ Produces the binary file ELITE.unprot.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

.run
 JMP ENTRY

\ ******************************************************************************
\
\ Variable B%: VDU command data
\
\ Elite uses its own screen mode, based on mode 4 but with the following
\ differences:
\
\   * 32 columns, 31 rows (256 x 248 pixels) rather than 40, 32
\
\   * Horizontal sync position at character 45 rather than 49, which pushes the
\     screen to the right
\
\   * Screen memory starts at &6000
\
\   * Text window and large, fast blinking cursor
\
\ This almost square mode 4 variant makes life a lot easier when drawing to the
\ screen, as there are 256 pixels on each row (or, to put it in screen memory
\ terms, there's one page of memory per row of pixels).
\
\ There is also an interrupt-driven routine that switches the bytes-per-pixel
\ setting from that of mode 4 to that of mode 5, when the raster reaches the
\ split between the space view and the dashboard. This is described in the IRQ1
\ routine, which does the switching.
\
\ ******************************************************************************

B% = P%
N% = 67

 EQUB 22, 4             \ Screen mode 4

 EQUB 28, 2, 17, 15, 16 \ Define text window left = 2, right = 15
                        \ top = 16, bottom = 17
                        \ i.e. 1 row high, 13 wide at (2, 16)

 EQUB 23, 0, 6, 31      \ 6845 register R6 = 31 (vertical displayed
 EQUB 0, 0, 0, 0, 0, 0  \ register, number of displayed character rows, 
                        \ 32 for modes 4 and 5)

 EQUB 23, 0, 12, 12     \ 6845 register R12 = 12 = &0C
 EQUB 0, 0, 0, 0, 0, 0

 EQUB 23, 0, 13, 0      \ 6845 register R13 = 0 = &00
 EQUB 0, 0, 0, 0, 0, 0
                        \ (R12 R13) = &0C00 points to the start of
                        \ screen memory in character lines, so we
                        \ multiply by 8 lines per character to get
                        \ the start address of screen memory
                        \ = &0C00 * 8 = &6000

 EQUB 23, 0, 1, 32      \ 6845 register R1 = 32 (horizontal displayed
 EQUB 0, 0, 0, 0, 0, 0  \ register, number of displayed characters per
                        \ horizontal line, 40 for modes 4 and 5)

 EQUB 23, 0, 2, 45      \ 6845 register R2 = 45 (horizontal sync
 EQUB 0, 0, 0, 0, 0, 0  \ position register, the position of the  
                        \ horizontal sync pulse on the horizontal line
                        \ in terms of character widths from the left
                        \ hand side of the screen, 49 for modes 4 and 5)

 EQUB 23, 0, 10, 32     \ 6845 register R10 = 32 (cursor start, 
 EQUB 0, 0, 0, 0, 0, 0  \ set start line 0 with fast blink rate)

\ ******************************************************************************
\
\ Variable E%: Sound envelope data
\
\ ******************************************************************************

E% = P%

EQUB 1, 1, 0, 111, -8, 4, 1, 8, 8, -2, 0, -1, 112, 44
EQUB 2, 1, 14, -18, -1, 44, 32, 50, 6, 1, 0, -2, 120, 126
EQUB 3, 1, 1, -1, -3, 17, 32, 128, 1, 0, 0, -1, 1, 1
EQUB 4, 1, 4, -8, 44, 4, 6, 8, 22, 0, 0, -127, 126, 0

MACRO FNE I%
  LDX #((E%+I%*14)MOD256)
  LDY #((E%+I%*14)DIV256)
  LDA #8
  JSR OSWORD
ENDMACRO

\ ******************************************************************************
\
\ Elite loader (Part 3 of )
\
\
\
\ ******************************************************************************

.swine 

 LDA #&7F               \ Machine reset
 STA &FE4E
 JMP (&FFFC)

\ This bit runs where it loads

.OSB

 LDY #0                 \ OSBYTE call with Y = 0
 JMP OSBYTE

 EQUS "R.ELITEcode"
 EQUB 13
 EQUS "By D.Braben/I.Bell"
 EQUB 13
 EQUB &B0

                        \ Addresses of various functions used by loader to
                        \ obfuscate

.oscliv

 EQUW &FFF7

.David9

 EQUW David5            \ used to direct decyrypt fn in stack to end of loop
 CLD

.David23

 EQUW (512-LEN)         \ start of DOMOVE fn pushed onto stack (&1DF)

                        \ Set up PROT1 fn to work correctly and set V219 to
                        \ OSBPUT vector address

.doPROT1

                        \ enters with A = &48;X = 255

 LDY#&DB
 STY TRTB%
 LDY #&EF               \ 0.1 look-up keys
 STY TRTB%+1
 LDY #2
 STY V219+1
 STA PROT1-255,X        \ self-mod PHA -> PROT1
 LDY #&18
 STY V219+1,X           \ set V219 to &0218
 RTS

.MHCA

 EQUB &CA

.David7

 BCC Ian1

.ENTRY

 SEI                    \ Boot code
 CLD

IF DISC = FALSE
 LDA #0              \ TAPE protection
 LDX #&FF
 JSR OSBYTE
 TXA
 BEQ OS100
 LDY &FFB6
 LDA &FFB7
 STA ZP
 LDA &FFB8
 STA ZP+1
 DEY

.ABCDEFG

 LDA (ZP),Y
 STA &200,Y
 DEY
 BPL ABCDEFG

.OS100
ENDIF

 LDA #&7F               \ Disable all interupts
 STA &FE4E
 STA &FE6E

 LDA &FFFC              \ Set USERV, BRKV, IRQ2V and EVENTV to point to machine reset (&FFFC)
 STA &200
 STA &202
 STA &206
 STA &220
 LDA &FFFD
 STA &201
 STA &203
 STA &207
 STA &221               \ Cold reset (Power on) on BRK,USER,& unrecog IRQ

 LDX #&2F-2             \ Ensure all vectors are pointing into MOS (&C000 and upwards)

.purge

 LDA &202,X
 ORA #&C0
 STA &202,X
 DEX
 DEX
 BPL purge

 LDA #&60               \ Make NETV an RTS
 STA &232
 LDA #2
 STA NETV+1
 LDA #&32
 STA NETV               \ Knock out NETVEC

                        \ Poke JSR into David2 fn and set ADC to sample 2 channels

 LDA #32                \ JSR absolute
 EQUB &2C               \ BIT absolute (skip next 2 bytes)

.Ian1

 BNE David3
 STA David2             \ self-mod code -> JSR at David2
 LSR A
 LDX #3
 STX BLPTR+1
 STX BLN+1
 STX EXCN+1
 DEX
 JSR OSBYTE             \ ADC

 EQUB &2C               \ BIT absolute (skip next 2 bytes)

.FRED1

 BNE David7

 LDX #255               \ Poke PHA into PROT1 fn
 LDA #&48
 JSR doPROT1

 LDA #144               \ Issue *TV 255,0 command (via OSBYTE 144)
 JSR OSB

 LDA #247               \ Remove BREAK intercept (via OSBYTE 247)
 LDX #0
 JSR OSB

\LDA#&81\LDY#&FF\LDX#1\JSROSBYTE\TXA\BPLOS01 \Damn 0.1

 LDA #190               \ Set ADC to 8-bit conversion (via OSBYTE 190)
 LDX #8
 JSR OSB

 EQUB &2C               \ BIT absolute (skip next 2 bytes)

.David8

 BNE FRED1

 LDA #&8F               \ Issue paged ROM service call (via OSBYTE &8F)
 LDX #&C
 LDY #&FF
 JSR OSBYTE

 LDA #13                \ Disable output buffer empty event (via OSBYTE 13)

.abrk

 LDX #0
 JSR OSB

 LDA #225               \ Set character status flag (via OSBYTE 225)
 LDX #128
 JSR OSB

 LDA #172               \ Get address of MOS key translation table (via OSBYTE 172)
 LDX #0
 LDY #255
 JSR OSBYTE
 STX TRTB%
 STY TRTB%+1

 LDA #200               \ Disable ESCAPE, memory cleared on BREAK (via OSBYTE 200)
 LDX #3
 JSR OSB

IF PROT AND DISC = 0
 CPX #3
 BNE abrk+1             \ Clear memory on BREAK 
ENDIF

 LDA #13                \ Disable character entering keyboard buffer event (via OSBYTE 13)
 LDX #2
 JSR OSB

.OS01                   \ Reset stack

 LDX #&FF
 TXS 
 INX 

.David3

                        \ Push 33 bytes from BEGIN% onto the stack
                        \ NB. loops by indirecting through 5 branches!

 LDA BEGIN%,X

.PROT1

 INY
\PHA
 INX 
 CPX #LEN
 BNE David8

 LDA #(B% MOD256)       \ Issue 67 VDU commands to set up square MODE4 screen at &6000
 STA ZP
 LDA #&C8               \ self-mod INY -> PROT1
 STA PROT1
 LDA #(B% DIV256)
 STA ZP+1

 LDY #0

.LOOP

 LDA (ZP),Y
 JSR OSWRCH
 INY 
 CPY #N%
 BNE LOOP               \ set up pokey-mode-4

 LDA #1                 \ Disable cursor editing, keys give ASCII values (via OSBYTE 4)
 TAX
 TAY
 STA (V219),Y
 LDA #4
 JSR OSB

 LDA #9                 \ Disable flashing colours (via OSBYTE 9)
 LDX #0
 JSR OSB

 LDA #&6C               \ Poke JSR indirect into crunchit fn
 EOR crunchit           \ JMP indirect
 STA crunchit

  FNE 0                 \ Define 4x sound envelopes (via OSWORD 8)
  FNE 1
  FNE 2
  FNE 3

\ ******************************************************************************
\
\ Elite loader (Part 4 of )
\
\ Move & decrypt WORDS9 to language workspace (4x pages from &1100 to &0400)
\ Move & decypt P.ELITE to screen (1x pages from &1D00 to &6300)
\ Move & decypt P.A-SOFT to screen (1x pages from &1E00 to &6100)
\ Move & decypt P.A-SOFT to screen (1x pages from &1F00 to &7600)
\ Draw saturn
\ Move & decypt DIALSHP to screen (1x pages from &1500 to &7800)
\ Move & decypt 2x pages of code from UU% down to &0B00
\
\ ******************************************************************************

 LDX #4                 \ Move & decrypt WORDS9 to language workspace (4x pages from &1100 to &0400)
 STX P+1
 LDA #(LL%DIV256)
 STA ZP+1
 LDY #0
 LDA #256-LEN1
 STA (V219-4,X)
 STY ZP
 STY P
 JSR crunchit

 LDX #1                 \ Move & decypt P.ELITE to screen (1x pages from &1D00 to &6300)
 LDA #((LL%DIV256)+&C)
 STA ZP+1
 LDA #&63
 STA P+1
 LDY #0
 JSR crunchit

 LDX #1                 \ Move & decypt P.A-SOFT to screen (1x pages from &1E00 to &6100)
 LDA #((LL%DIV256)+&D)
 STA ZP+1
 LDA #&61
 STA P+1
 LDY #0
 JSR crunchit

 LDX #1                 \ Move & decypt P.A-SOFT to screen (1x pages from &1F00 to &7600)

 LDA #((LL%DIV256)+&E)
 STA ZP+1
 LDA #&76
 STA P+1
 LDY #0
 JSR crunchit

 JSR PLL1               \ Draw Saturn

 LDX #8                 \ Move & decypt DIALSHP to screen (1x pages from &1500 to &7800)
 LDA #((LL%DIV256)+4)
 STA ZP+1
 LDA #&78
 STA P+1
 LDY #0
 STY ZP
 STY BLCNT
 STY P
 JSR crunchit           \ Move DIALSHP to &7800

 LDX #(3-(DISC AND1))   \ Move & decypt 2x pages of code from UU% down to &0B00
 LDA #(UU%DIV256)
 STA ZP+1
 LDA #(UU%MOD256)
 STA ZP
 LDA #(LE%DIV256)
 STA P+1
 LDY #0
 STY P
 JSR crunchit           \ Move Part of this program to LE%

\ ******************************************************************************
\
\ Elite loader (Part 5 of )
\
\
\ ******************************************************************************

                    \ Poke BRK into OS01 fn and call OSBPUT with file handle Y = 0...
                    \ By now the address &01F1 has been sneakily placed into BPUTV (&218)
                    \ So this call to OSBPUT actually calls the second function placed in stack

 STY David3-2
\LDY#0

.David2

 EQUB &AC               \ self moded to JSR &FFD4
 EQUW &FFD4
\JSR&FFD4

.LBLa

 LDA C%,X               \ Code should never reach here if decryption is successful!!
 EOR #&A5
 STA C%,X
 DEX
 BNE LBLa
 JMP (C%+&CF)

.swine2

 JMP swine
 EQUW &4CFF

.crunchit

                        \ Call DOMOVE fn but inside the stack

 BRK                    \ JSR (David23)
 EQUW David23

.RAND

 EQUD &6C785349

                        \ End of our decrypt fn inside the stack

.David5

 INY
 CPY #(ENDBLOCK-BLOCK)
 BNE David2

 SEI                    \ Enable interupts and set IRQ1V to IRQ1 fn
 LDA #&C2
 STA VIA+&E
 LDA #&7F
 STA &FE6E
 LDA IRQ1V
 STA VEC
 LDA IRQ1V+1
 BPL swine2
 STA VEC+1
 LDA #(IRQ1 DIV256)
 STA IRQ1V+1
 LDA #(IRQ1 MOD256)
 STA IRQ1V
 LDA #VSCAN
 STA USVIA+5
 CLI                    \ INTERRUPTS NOW OK

IF DISC 
 LDA #&81               \ Read key with time limit (via OSBYTE &81)
 STA &FE4E
 LDY #20

 IF _REMOVE_CHECKSUMS
  NOP:NOP:NOP
 ELSE
  JSR OSBYTE
 ENDIF

 LDA #1
 STA &FE4E
ENDIF

 RTS                    \ ENTRY2 already pushed onto stack at start of BLOCK code

\ ******************************************************************************
\
\ Elite loader (Part 6 of )
\
\ Draw Saturn
\
\ ******************************************************************************

.PLL1
{
 LDA VIA+4
 STA RAND+1
 JSR DORND
 JSR SQUA2
 STA ZP+1
 LDA P
 STA ZP
 JSR DORND
 STA YY
 JSR SQUA2
 TAX
 LDA P
 ADC ZP
 STA ZP
 TXA
 ADC ZP+1
 BCS PLC1

 STA ZP+1
 LDA #1
 SBC ZP
 STA ZP
 LDA #&40
 SBC ZP+1
 STA ZP+1
 BCC PLC1
 JSR ROOT
 LDA ZP
 LSR A
 TAX
 LDA YY
 CMP #128
 ROR A
 JSR PIX

.PLC1
 DEC CNT
 BNE PLL1
 DEC CNT+1
 BNE PLL1
 LDX #&C2
 STX EXCN

.PLL2
 JSR DORND
 TAX
 JSR SQUA2
 STA ZP+1
 JSR DORND
 STA YY
 JSR SQUA2
 ADC ZP+1
 CMP #&11
 BCC PLC2
 LDA YY
 JSR PIX

.PLC2
 DEC CNT2
 BNE PLL2
 DEC CNT2+1
 BNE PLL2
 LDX MHCA
 STX BLPTR
 LDX #&C6
 STX BLN

.PLL3
 JSR DORND
 STA ZP
 JSR SQUA2
 STA ZP+1
 JSR DORND
 STA YY
 JSR SQUA2
 STA T

 ADC ZP+1
 STA ZP+1
 LDA ZP
 CMP #128
 ROR A
 CMP #128
 ROR A
 ADC YY
 TAX
 JSR SQUA2
 TAY
 ADC ZP+1

 BCS PLC3
 CMP #&50
 BCS PLC3
 CMP #&20
 BCC PLC3
 TYA
 ADC T
 CMP #&10
 BCS PL1
 LDA ZP
 BPL PLC3

.PL1
 LDA YY
 JSR PIX

.PLC3
 DEC CNT3
 BNE PLL3
 DEC CNT3+1
 BNE PLL3

.DORND
 LDA RAND+1
 TAX
 ADC RAND+3
 STA RAND+1
 STX RAND+3
 LDA RAND
 TAX
 ADC RAND+2
 STA RAND
 STX RAND+2
 RTS

.SQUA2
 BPL SQUA
 EOR #&FF
 CLC
 ADC #1

.SQUA
 STA Q
 STA P
 LDA #0
 LDY #8
 LSR P

.SQL1
 BCC SQ1
 CLC
 ADC Q

.SQ1
 ROR A
 ROR P
 DEY
 BNE SQL1
 RTS

.PIX
 TAY
 EOR #128
 LSR A
 LSR A
 LSR A
 ORA #&60
 STA ZP+1
 TXA
 EOR #128
 AND #&F8
 STA ZP
 TYA
 AND #7
 TAY
 TXA
 AND #7
 TAX

 LDA TWOS,X
 ORA (ZP),Y
 STA (ZP),Y
 RTS

.TWOS
 EQUD &10204080
 EQUD &01020408

.CNT
 EQUW &500
.CNT2
 EQUW &1DD
.CNT3
 EQUW &500

.ROOT
 LDY ZP+1
 LDA ZP
 STA Q
 LDX #0
 STX ZP
 LDA #8
 STA P

.LL6
 CPX ZP
 BCC LL7
 BNE LL8
 CPY #&40
 BCC LL7

.LL8
 TYA
 SBC #&40
 TAY
 TXA
 SBC ZP
 TAX

.LL7
 ROL ZP
 ASL Q
 TYA
 ROL A
 TAY
 TXA
 ROL A
 TAX
 ASL Q
 TYA
 ROL A
 TAY
 TXA
 ROL A
 TAX
 DEC P
 BNE LL6
 RTS
}

\ ******************************************************************************
\
\ Elite loader (Part 7 of )
\
\ Obfuscated code
\
\ Copy BLOCK fn to stack and decrypt TUT fn
\
\    01F1 : PLA
\    01F2 : PLA
\    01F3 : LDA 0C7C,Y      \ BLOCK
\    01F6 : PHA
\    01F7 : EOR 0BAD,Y      \ TUT
\    01FA : STA 0BAD,Y
\    01FD : JMP (20AD)
\
\ ******************************************************************************

.BEGIN%

 EQUB (David9 DIV256)   \ Copy BLOCK fn to stack and decrypt TUT fn
 EQUB (David9 MOD256)
 EQUB &6C \JMP
 EQUB (TUT DIV256)
 EQUB (TUT MOD256)
 EQUB &99 \STA,Y
 EQUB (TUT DIV256)
 EQUB (TUT MOD256)

IF _REMOVE_CHECKSUMS
 EQUB &B9 \LDA,Y
ELSE
 EQUB &59 \EOR,Y
ENDIF

 PHA
 EQUB ((BLOCK)DIV256)
 EQUB ((BLOCK)MOD256)
 EQUB &B9 \LDA,Y
 PLA
 PLA

\ ******************************************************************************
\
\ Elite loader (Part 8 of )
\
\ Obfuscated code
\
\ DOMOVE fn as running on the stack
\
\    01DF : LDA (70),Y
\    01E1 : EOR 2086,Y
\    01E4 : STA (72),Y
\    01E6 : DEY
\    01E7 : BNE 01DF
\    01E9 : INC 73
\    01EB : INC 71
\    01ED : DEX
\    01EE : BNE 01DF
\    01F0 : RTS

\ ******************************************************************************

.DOMOVE

 RTS                    \ Move memory fn with EOR against loader code from OSB onwards

 EQUW &D0EF             \BNEMVDL
 DEX
 EQUB ZP+1
 INC P+1
 EQUB &E6               \INCP+1 INCZP+1
 EQUW &D0F6             \BNEMVDL
 DEY
 EQUB P
 EQUB &91               \STA(),Y

IF _REMOVE_CHECKSUMS
 NOP:NOP:NOP
ELSE
 EQUB (OSB DIV256)
 EQUB (OSB MOD256)
 EQUB &59               \EOR
ENDIF

 EQUB ZP
 EQUB &B1               \LDA(),Y        \ 18 Bytes ^ Stack
 
\ ******************************************************************************
\
\ Elite loader (Part 9 of )
\
\ This code all located at &B00
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

\ ******************************************************************************
\
\ Variable: block1
\
\ ******************************************************************************

.block1

 EQUD &A5B5E5F5       \ ULA Palette colours for MODE 5 portion of screen
 EQUD &26366676
 EQUD &8494C4D4

\ ******************************************************************************
\
\ Variable: block2
\
\ ******************************************************************************

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
}

.RR4
 PLA
 TAX
 PLA
 TAY
 LDA K3

.FOOL
 RTS

.R5
 LDA #7
 JSR osprint
 JMP RR4

\ ******************************************************************************
\
\ Elite loader (Part 10 of )
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

 EQUB 13                 \ *LOAD ELITEcode

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

 LDA #0
 STA SVN

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
\ Elite loader (Part 11 of )
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
\ Elite loader (Part 12 of )
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
\ Variable XC, YC
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

\ ******************************************************************************

COPYBLOCK LE%, P%, UU%

PRINT "BLOCK offset = ", ~(BLOCK - LE%) + (UU% - CODE%)
PRINT "ENDBLOCK offset = ",~(ENDBLOCK - LE%) + (UU% - CODE%)
PRINT "MAINSUM offset = ",~(MAINSUM - LE%) + (UU% - CODE%)
PRINT "TUT offset = ",~(TUT - LE%) + (UU% - CODE%)
PRINT "UU% = ",~UU%," Q% = ",~Q%, " OSB = ",~OSB

PRINT "Memory usage: ", ~LE%, " - ",~P%
PRINT "Stack: ",LEN + ENDBLOCK - BLOCK

PRINT "S. ELITE ", ~CODE%, " ", ~UU% + (P% - LE%), " ", ~run, " ", ~LL%
SAVE "output/ELITE.unprot.bin", CODE%, UU% + (P% - LE%), run, LL%
