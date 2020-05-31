\ *****************************************************************************
\* Source Code for ELITE  (the loader)
\ *****************************************************************************

INCLUDE "elite-header.h.asm"

DISC = TRUE     ; load above DFS and relocate down
PROT = FALSE    ; TAPE protection

HIMEM=&4000
;DIMTEMP%256
LOD%=&1100      ; load address of ELTcode (elite-bcfs.asm)

C%=&F40         ; assembly address of Elite game code (elite-source.asm)
S%=C%
L%=LOD%+&28     ; load address Elite game code (elite-bcfs.asm)
D%=&563A        ; hardcoded size of Elite game code (elite-source.asm)
LC%=&6000-C%    ; maximum size of Elite game code

svn=&7FFD
len1=15
len2=18
len=len1+len2

LE%=&B00        ; address of second stage loader (containing ENTRY2)

;REM  Move Mover to here while CODE loading

IF DISC
LL%=&E00+&300   ; load address of loader
ELSE
LL%=&E00
ENDIF

;CODE=&4000
CODE=LL%        ; we can assemble in place

;REM Where this loader loads

\ *****************************************************************************
\ MOS definitions
\ *****************************************************************************

MOS=S%+8        ; unused - was part of OS version test
TRTB%=4         ; MOS key translation table
NETV=&224

OSWRCH=&FFEE
OSBYTE=&FFF4
OSWORD=&FFF1
SCLI=&FFF7
IRQ1V=&204
osprnt=&234

\ *****************************************************************************
\ ZERO PAGE variables
\ *****************************************************************************

ZP=&70
P=&72
Q=&73
YY=&74
T=&75
sc=&76
BLPTR=&78
V219=&7A
K3=&80
BLCNT=&81
BLN=&83
EXCN=&85

FF=&FF

\ *****************************************************************************
\ SYSVIA definitions
\ *****************************************************************************

VIA=&FE40
USVIA=VIA
VSCAN=57-1
VEC=&7FFE

\ *****************************************************************************
\ Concatenate data files used by loader
\ *****************************************************************************

;OSCLI("L.:0.WORDS9 "+STR$~CODE)
ORG CODE
PRINT "WORDS9=",~P%
INCBIN "output/WORDS9.bin"

;OSCLI("L.:0.DIALSHP "+STR$~(CODE+&400))
ORG CODE+&400
PRINT "DIALSHP=",~P%
INCBIN "data/DIALSHP.bin"

;OSCLI("L.:2.P.ELITE "+STR$~(CODE+&C00))
ORG CODE+&C00
PRINT "P.ELITE=",~P%
INCBIN "data/P.ELITE.bin"

;OSCLI("L.:2.P.A-SOFT "+STR$~(CODE+&D00))
ORG CODE+&D00
PRINT "P.A-SOFT=",~P%
INCBIN "data/P.A-SOFT.bin"

;OSCLI("L.:2.P.(C)ASFT "+STR$~(CODE+&E00))
ORG CODE+&E00
PRINT "P.(C)ASFT=",~P%
INCBIN "data/P.(C)ASFT.bin"

;REMOSCLI("L.:2.P.NAME$ "+STR$~(CODE+&E00))

ORG LL%+&400+&800+&300
O%=CODE+&400+&800+&300

\ *****************************************************************************
\ LOADER CODE START
\ *****************************************************************************

.run
 JMP ENTRY

\ *****************************************************************************
\ VDU command data
\ *****************************************************************************

B%=P%
N%=67       ; DATA 67:READ N%

EQUB 22,4,28,2,17,15,16
EQUB 23,0, 6,31,0,0,0,0,0,0
EQUB 23,0,12,12,0,0,0,0,0,0
EQUB 23,0,13, 0,0,0,0,0,0,0
EQUB 23,0, 1,32,0,0,0,0,0,0
EQUB 23,0, 2,45,0,0,0,0,0,0
EQUB 23,0,10,32,0,0,0,0,0,0

\ *****************************************************************************
\ Sound envelope data
\ *****************************************************************************

E%=P%

EQUB 1,1,0,111,-8,4,1,8, 8,-2,0,-1,112,44
EQUB 2,1,14,-18,-1,44,32,50, 6,1,0,-2,120,126
EQUB 3,1,1,-1,-3,17,32,128,1,0,0,-1,1,1
EQUB 4,1,4,-8,44,4,6,8,22,0,0,-127,126,0

MACRO FNE I%
    LDX #((E%+I%*14)MOD256)
    LDY #((E%+I%*14)DIV256)
    LDA #8
    JSR OSWORD
ENDMACRO

\ *****************************************************************************
\ Machine reset
\ *****************************************************************************

.swine 
 LDA #&7F
 STA &FE4E
 JMP (&FFFC)

\ This bit runs where it loads

\ *****************************************************************************
\ OSBYTE call with Y=0
\ *****************************************************************************

.OSB
 LDY #0
 JMP OSBYTE

 EQUS "R.ELITEcode"
 EQUB 13
 EQUS "By D.Braben/I.Bell"
 EQUB 13
 EQUB &B0

\ *****************************************************************************
\ Addresses of various functions used by loader to obfuscate
\ *****************************************************************************

.oscliv
 EQUW &FFF7

.David9
 EQUW David5        ; used to direct decyrypt fn in stack to end of loop
 CLD

.David23
 EQUW (512-len)     ; start of DOMOVE fn pushed onto stack (&1DF)

\ *****************************************************************************
\ Set up PROT1 fn to work correctly and set V219 to OSBPUT vector address
\ *****************************************************************************

.doPROT1            ; enters with A=&48;X=255
 LDY#&DB
 STY TRTB%
 LDY #&EF \0.1 look-up keys
 STY TRTB%+1
 LDY #2
 STY V219+1
 STA PROT1-255,X    ; self-mod PHA -> PROT1
 LDY #&18
 STY V219+1,X       ; set V219 to &0218
 RTS

.MHCA
 EQUB &CA

.David7
 BCC Ian1

\ *****************************************************************************
\ Boot code
\ *****************************************************************************

.ENTRY
 SEI
 CLD

\ *****************************************************************************
\ TAPE protection
\ *****************************************************************************

IF DISC=FALSE
    LDA #0
    LDX #FF
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

\ *****************************************************************************
\ Disable all interupts
\ *****************************************************************************

 LDA #&7F
 STA &FE4E
 STA &FE6E

\ *****************************************************************************
\ Set USERV, BRKV, IRQ2V and EVENTV to point to machine reset (&FFFC)
\ *****************************************************************************

 LDA &FFFC
 STA &200
 STA &202
 STA &206
 STA &220
 LDA &FFFD
 STA &201
 STA &203
 STA &207
 STA &221 \ Cold reset (Power on) on BRK,USER,& unrecog IRQ

\ *****************************************************************************
\ Ensure all vectors are pointing into MOS (&C000 and upwards)
\ *****************************************************************************

 LDX #&2F-2
.purge
 LDA &202,X
 ORA #&C0
 STA &202,X
 DEX
 DEX
 BPL purge

\ *****************************************************************************
\ Make NETV an RTS
\ *****************************************************************************

 LDA #&60
 STA &232
 LDA #2
 STA NETV+1
 LDA #&32
 STA NETV \Knock out NETVEC

\ *****************************************************************************
\ Poke JSR into David2 fn and set ADC to sample 2 channels
\ *****************************************************************************

 LDA #32        ; JSR absolute
 EQUB &2C       ; BIT absolute (skip next 2 bytes)

.Ian1
 BNE David3
 STA David2     ; self-mod code -> JSR at David2
 LSR A
 LDX #3
 STX BLPTR+1
 STX BLN+1
 STX EXCN+1
 DEX
 JSR OSBYTE \ADC

 EQUB &2C       ; BIT absolute (skip next 2 bytes)

.FRED1
 BNE David7

\ *****************************************************************************
\ Poke PHA into PROT1 fn
\ *****************************************************************************

 LDX #255
 LDA #&48
 JSR doPROT1

\ *****************************************************************************
\ Issue *TV 255,0 command (via OSBYTE 144)
\ *****************************************************************************

 LDA #144
 JSR OSB \TV

\ *****************************************************************************
\ Remove BREAK intercept (via OSBYTE 247)
\ *****************************************************************************

 LDA #247
 LDX #0
 JSR OSB \BREAK vec

\LDA#&81\LDY#FF\LDX#1\JSROSBYTE\TXA\BPLOS01 \Damn 0.1

\ *****************************************************************************
\ Set ADC to 8-bit conversion (via OSBYTE 190)
\ *****************************************************************************

 LDA #190
 LDX #8
 JSR OSB \8bitADC

 EQUB &2C       ; BIT absolute (skip next 2 bytes)
.David8
 BNE FRED1

\ *****************************************************************************
\ Issue paged ROM service call (via OSBYTE &8F)
\ *****************************************************************************

 LDA #&8F
 LDX #&C
 LDY #FF
 JSR OSBYTE \ claim NMIs

\ *****************************************************************************
\ Disable output buffer empty event (via OSBYTE 13)
\ *****************************************************************************

 LDA #13
.abrk
 LDX #0
 JSR OSB \otput bffer

\ *****************************************************************************
\ Set character status flag (via OSBYTE 225)
\ *****************************************************************************

 LDA #225
 LDX #128
 JSR OSB \fn keys

\ *****************************************************************************
\ Get address of MOS key translation table (via OSBYTE 172)
\ *****************************************************************************

 LDA #172
 LDX #0
 LDY #255
 JSR OSBYTE
 STX TRTB%
 STY TRTB%+1 \int-ascii table

\ *****************************************************************************
\ Disable ESCAPE, memory cleared on BREAK (via OSBYTE 200)
\ *****************************************************************************

 LDA #200
 LDX #3
 JSR OSB

IF PROT AND DISC=0
 CPX #3
 BNE abrk+1 \Clear memory on BREAK 
ENDIF

\ *****************************************************************************
\ Disable character entering keyboard buffer event (via OSBYTE 13)
\ *****************************************************************************

 LDA #13
 LDX #2
 JSR OSB \kybrd buffer

\ *****************************************************************************
\ Reset stack
\ *****************************************************************************

.OS01
 LDX #FF
 TXS 
 INX 

\ *****************************************************************************
\ Push 33 bytes from BEGIN% onto the stack
\ NB. loops by indirecting through 5 branches!
\ *****************************************************************************

.David3
 LDA BEGIN%,X

.PROT1
 INY \PHA
 INX 
 CPX #len
 BNE David8 \^stack

\ *****************************************************************************
\ Issue 67 VDU commands to set up square MODE4 screen at &6000
\ *****************************************************************************

 LDA #(B% MOD256)
 STA ZP
 LDA #&C8           ; self-mod INY -> PROT1
 STA PROT1
 LDA #(B% DIV256)
 STA ZP+1

 LDY #0
.LOOP
 LDA (ZP),Y
 JSR OSWRCH
 INY 
 CPY #N%
 BNE LOOP \set up pokey-mode-4

\ *****************************************************************************
\ Disable cursor editing, keys give ASCII values (via OSBYTE 4)
\ *****************************************************************************

 LDA #1
 TAX
 TAY
 STA (V219),Y
 LDA #4
 JSR OSB \cursor

\ *****************************************************************************
\ Disable flashing colours (via OSBYTE 9)
\ *****************************************************************************

 LDA #9
 LDX #0
 JSR OSB \flashing

\ *****************************************************************************
\ Poke JSR indirect into crunchit fn
\ *****************************************************************************

 LDA #&6C           ; JMP indirect
 EOR crunchit
 STA crunchit

\ *****************************************************************************
\ Define 4x sound envelopes (via OSWORD 8)
\ *****************************************************************************

    FNE 0
    FNE 1
    FNE 2
    FNE 3 \envelopes

\ *****************************************************************************
\ Move & decrypt WORDS9 to language workspace (4x pages from &1100 to &0400)
\ *****************************************************************************

 LDX #4
 STX P+1
 LDA #(LL%DIV256)
 STA ZP+1
 LDY #0
 LDA #256-len1
 STA (V219-4,X)
 STY ZP
 STY P
 JSR crunchit \Move WORDS9 to &400

\ *****************************************************************************
\ Move & decypt P.ELITE to screen (1x pages from &1D00 to &6300)
\ *****************************************************************************

 LDX #1
 LDA #((LL%DIV256)+&C)
 STA ZP+1
 LDA #&63
 STA P+1
 LDY #0
 JSR crunchit

\ *****************************************************************************
\ Move & decypt P.A-SOFT to screen (1x pages from &1E00 to &6100)
\ *****************************************************************************

 LDX #1
 LDA #((LL%DIV256)+&D)
 STA ZP+1
 LDA #&61
 STA P+1
 LDY #0
 JSR crunchit

\ *****************************************************************************
\ Move & decypt P.A-SOFT to screen (1x pages from &1F00 to &7600)
\ *****************************************************************************

 LDX #1
 LDA #((LL%DIV256)+&E)
 STA ZP+1
 LDA #&76
 STA P+1
 LDY #0
 JSR crunchit

\ *****************************************************************************
\ Draw Saturn
\ *****************************************************************************

 JSR PLL1 \draw Saturn

\ *****************************************************************************
\ Move & decypt DIALSHP to screen (1x pages from &1500 to &7800)
\ *****************************************************************************

 LDX #8
 LDA #((LL%DIV256)+4)
 STA ZP+1
 LDA #&78
 STA P+1
 LDY #0
 STY ZP
 STY BLCNT
 STY P
 JSR crunchit \Move DIALSHP to &7800

\ *****************************************************************************
\ Move & decypt 2x pages of code from UU% down to &0B00
\ *****************************************************************************

 LDX #(3-(DISC AND1))
 LDA #(UU%DIV256)
 STA ZP+1
 LDA #(UU%MOD256)
 STA ZP
 LDA #(LE%DIV256)
 STA P+1
 LDY #0
 STY P
 JSR crunchit \Move Part of this program to LE%

\ *****************************************************************************
\ Poke BRK into OS01 fn and call OSBPUT with file handle Y=0...
\ By now the address &01F1 has been sneakily placed into BPUTV (&218)
\ So this call to OSBPUT actually calls the second function placed in stack
\ *****************************************************************************

 STY David3-2
\LDY#0
.David2
 EQUB &AC   ; self moded to JSR &FFD4
 EQUW &FFD4 \JSR&FFD4

\ *****************************************************************************
\ Code should never reach here if decryption is successful!!
\ *****************************************************************************

.LBLa
 LDA C%,X
 EOR #&A5
 STA C%,X
 DEX
 BNE LBLa
 JMP (C%+&CF)

.swine2
 JMP swine
 EQUW &4CFF

\ *****************************************************************************
\ Call DOMOVE fn but inside the stack
\ *****************************************************************************

.crunchit
 BRK            ; JSR (David23)
 EQUW David23

.RAND
 EQUD &6C785349

\ *****************************************************************************
\ End of our decrypt fn inside the stack
\ *****************************************************************************

.David5
 INY
 CPY #(ENDBLOCK-BLOCK)
 BNE David2

\ *****************************************************************************
\ Enable interupts and set IRQ1V to IRQ1 fn
\ *****************************************************************************

 SEI
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
 CLI \ INTERRUPTS NOW OK

\ *****************************************************************************
\ Read key with time limit (via OSBYTE &81)
\ *****************************************************************************

IF DISC 
 LDA #&81
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

\ *****************************************************************************
\ ENTRY2 already pushed onto stack at start of BLOCK code
\ *****************************************************************************

 RTS  \ENTRY2 on stack already

\ *****************************************************************************
\ Draw Saturn
\ *****************************************************************************

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
 EOR #FF
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

\ *****************************************************************************
\ Copy BLOCK fn to stack and decrypt TUT fn
\ *****************************************************************************

.BEGIN%
 EQUB (David9 DIV256)
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

\ *****************************************************************************
\ Copy BLOCK fn to stack and decrypt TUT fn
\
\    01F1 : PLA
\    01F2 : PLA
\    01F3 : LDA 0C7C,Y      ; BLOCK
\    01F6 : PHA
\    01F7 : EOR 0BAD,Y      ; TUT
\    01FA : STA 0BAD,Y
\    01FD : JMP (20AD)
\
\ *****************************************************************************

\ *****************************************************************************
\ Move memory fn with EOR against loader code from OSB onwards
\ *****************************************************************************

.DOMOVE
 RTS
 EQUW &D0EF \BNEMVDL
 DEX
 EQUB ZP+1
 INC P+1
 EQUB &E6 \INCP+1 INCZP+1
 EQUW &D0F6 \BNEMVDL
 DEY
 EQUB P
 EQUB &91 \STA(),Y
IF _REMOVE_CHECKSUMS
 NOP:NOP:NOP
ELSE
 EQUB (OSB DIV256)
 EQUB (OSB MOD256)
 EQUB &59 \EOR
ENDIF
 EQUB ZP
 EQUB &B1 \LDA(),Y        \ 18 Bytes ^ Stack
 
\ *****************************************************************************
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
\
\ *****************************************************************************

\ *****************************************************************************
\ This code all located at &B00
\ *****************************************************************************

.UU%

Q%=P%-LE%
ORG LE%                 ;P%=LE%

.CHECKbyt
 BRK        ; CHECKbyt checksum value calcuated in elite-checksum.py

.MAINSUM
 EQUB &CB   ; hard-coded checksum value of &28 bytes at LBL in elite-bcfs.asm (ELThead)
 EQUB 0     ; MAINSUM checksum value calculated in elite-checksum.py

.FOOLV
 EQUW FOOL  ; address of fn with just RTS

.CHECKV
 EQUW LOD%+1    ; address of LBL fn in elite-bcfs.asm (ELThead)

\ *****************************************************************************
\ ULA Palette colours for MODE 5 portion of screen
\ *****************************************************************************

.block1
 EQUD &A5B5E5F5
 EQUD &26366676
 EQUD &8494C4D4

\ *****************************************************************************
\ ULA Palette colours for MODE 4 portion of screen
\ *****************************************************************************

.block2
 EQUD &A0B0C0D0
 EQUD &8090E0F0
 EQUD &27376777 \ Colours for interrupts

\ *****************************************************************************
\ PRINT fn for OSPRNT
\ *****************************************************************************

.TT26\ PRINT  Please tidy this up!
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
 STA sc+1
 LDY #7*8
 LDX #14
 STY sc
 LDA #0
 TAY

.David1
 sta (sc),Y
 INY 
 CPY #14*8
 BCC David1
 TAY
 inc sc+1
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
 lda #7
 JSR osprint
 JMP RR4

\ *****************************************************************************
\ Following code all encrypted in elite-checksum.py
\ *****************************************************************************

.TUT  \EOR here onward

.osprint
 jmp (osprnt)
 EQUB &6C

.command
 jmp(oscliv)

.MESS1
IF DISC
 EQUS "L.ELTcode 1100"
ELSE
 EQUS "L.ELITEcode F1F"
ENDIF
 EQUB13 \*LOAD ELITEcode

\ *****************************************************************************
\ Second entry point for loader after screen & irq set up
\ *****************************************************************************

.ENTRY2

\ *****************************************************************************
\ Set OSPRNT vector to TT26 fn
\ *****************************************************************************

 lda &20E
 STA osprnt
 LDA #(TT26 MOD256)
 STA &20E
 LDX #(MESS1 MOD256)
 LDA &20F
 STA osprnt+1
 LDA #(TT26 DIV256)
 LDY #(MESS1 DIV256)
 STA &20F \OSWRCH for loading messages

 JSR AFOOL

\ *****************************************************************************
\ Issue OSCLI command in MESS1 "*L.ELTcode 1100"
\ *****************************************************************************

 JSR command
 
\ *****************************************************************************
\ Execute CHECKER fn but in stack
\ *****************************************************************************

 JSR 512-len+CHECKER-ENDBLOCK 
 JSR AFOOL
 \ (Gratuitous JSRs)- LOAD Mcode and checksum it.

\ *****************************************************************************
\ Issue *TAPE command (via OSBYTE 140)
\ *****************************************************************************

IF DISC
 LDA #140
 LDX #12
 JSR OSBYTE \*TAPE 
ENDIF

 LDA #0
 STA svn

\ *****************************************************************************
\ Decrypt and copy down all ELITE game code from &1128 to &F40
\ *****************************************************************************

 LDX #(LC% DIV256)
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
 BPL ML1  \Move code down (d)

\ *****************************************************************************
\ Set BRKV and WRCHV to point at BR1 and TT26 fns in elite-source.asm
\ *****************************************************************************

 LDA S%+6
 STA &202
 LDA S%+7
 STA &203
 LDA S%+2
 STA &20E
 LDA S%+3
 STA &20F \BRK,OSWRCH     

\ *****************************************************************************
\ Calls final boot code from value copied to stack
\ *****************************************************************************

 RTS \- ON STACK 

.AFOOL
 JMP(FOOLV)

.M2
 EQUB 2

\ *****************************************************************************
\ IRQ1V handler for Timer 1 interrupt
\ *****************************************************************************

.VIA2

\ *****************************************************************************
\ Set ULA Control Register to 20 characters per line (MODE 5)
\ *****************************************************************************

 LDA #4
 STA &FE20

\ *****************************************************************************
\ Set ULA Palette Registers for MODE 5 colour scheme
\ *****************************************************************************

 LDY #11

.inlp1
 LDA block1,Y
 STA &FE21
 DEY
 BPL inlp1
 PLA
 TAY
 JMP (VEC)

\ *****************************************************************************
\ IRQ1V handler
\ *****************************************************************************

.IRQ1
 TYA
 PHA

\ *****************************************************************************
\ TAPE protection
\ *****************************************************************************

IF PROT AND DISC=0
 LDY #0
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
 DEC LOD%
.itdone
ENDIF

\ *****************************************************************************
\ Test which interrupt has occurred
\ *****************************************************************************

 LDA VIA+&D
 BIT M2
 BNE LINSCN
 AND #64
 BNE VIA2
 PLA
 TAY
 JMP (VEC)

\ *****************************************************************************
\ IRQ1V handler for Vsync interrupt
\ *****************************************************************************

.LINSCN

\ *****************************************************************************
\ Reset Timer 1 counter value Hi and Low bytes
\ *****************************************************************************

 LDA #50
 STA USVIA+4
 LDA #VSCAN
 STA USVIA+5

\ *****************************************************************************
\ Set ULA Control Register to 40 characters per line (MODE 4)
\ *****************************************************************************

 LDA #8
 STA &FE20
 LDY #11

\ *****************************************************************************
\ Set ULA Palette Registers for MODE 4 black & white
\ *****************************************************************************

.inlp2
 LDA block2,Y
 STA &FE21
 DEY
 BPL inlp2
 PLA
 TAY
 JMP (VEC)

\ *****************************************************************************
\ Entire BLOCK to ENDBLOCK copied into stack at location &15E
\ *****************************************************************************

.BLOCK \ Pushed onto stack for execution   
 EQUW ENTRY2-1                  ; return address for ENTRY2
 EQUW 512-len+BLOCK-ENDBLOCK+3  ; return address for final boot code (below)

\ *****************************************************************************
\ Final boot code starts at &163
\ *****************************************************************************

\ *****************************************************************************
\ Disable SYSVIA interrupts Timer2, CB1, CB2, CA2
\ *****************************************************************************

 LDA VIA+4
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

\ *****************************************************************************
\ Set IRQ1V to IRQ1 fn in elite-source.asm & set Timer 1 Counter Hi value
\ *****************************************************************************

 LDA S%+4
 STA IRQ1V
 LDA S%+5
 STA IRQ1V+1
 LDA #VSCAN
 STA USVIA+5
 CLI \Interrupt vectors

\LDA#&81LDY#FFLDX#1JSROSBYTETXAEOR#FFSTAMOS \FF if MOS0.1 else 0
\BMIBLAST

\ *****************************************************************************
\ Disable ESCAPE, memory cleared on BREAK (via OSBYTE 200)
\ *****************************************************************************

 LDY #0
 LDA #200
 LDX #3
 JSR OSBYTE

\ *****************************************************************************
\ Calculate Checksum0 = 70x pages of all Elite code from &F40 to &5540
\ *****************************************************************************

.BLAST \break,escape
 LDA #(S% DIV256)
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

\ *****************************************************************************
\ Checksum wrong - disable all interrupts and reset machine
\ *****************************************************************************

.nononono
 STA S%+1
 LDA #&7F
 STA &FE4E
 JMP (&FFFC)

.itsOK
 JMP(S%)

\ *****************************************************************************
\ CHECKER fn verifies checksum values
\ *****************************************************************************

.CHECKER
 LDY#0
 LDX #4
 STX ZP+1
 STY ZP
 TYA

\ *****************************************************************************
\ Verify MAINSUM of WORDS9 = 4 pages from &400 to &800
\ *****************************************************************************

.CHKq
 CLC
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

\ *****************************************************************************
\ Verify (hard coded) checksum of LBL in elite-bcfs.asm (ELThead)
\ *****************************************************************************

 TYA
.CHKb
 CLC
 ADC LOD%,Y
 INY 
 CPY #&28
 BNE CHKb
 CMP MAINSUM
IF _REMOVE_CHECKSUMS
 NOP:NOP
ELSE
 BNE nononono
ENDIF

IF PROT AND DISC=0
 LDA BLCNT
 CMP #&4F
 BCC nononono
ENDIF

\ *****************************************************************************
\ Call LBL in elite-bcfs.sm (ELThead) to verify CHECKbyt checksum
\ *****************************************************************************

IF _REMOVE_CHECKSUMS
 RTS:NOP:NOP
ELSE
 JMP (CHECKV)
ENDIF

.ENDBLOCK \ no more on to stack

\ *****************************************************************************
\ Variables used by PRINT function
\ *****************************************************************************

.XC
 EQUB 7

.YC
 EQUB 6

\ *****************************************************************************
\ LOADER END
\ *****************************************************************************

\\ We assembled a block of code at &B00
\\ Need to copy this up to end of main code

COPYBLOCK LE%, P%, UU%

PRINT "BLOCK_offset =", ~(BLOCK - LE%) + (UU% - CODE)
PRINT "ENDBLOCK_offset =",~(ENDBLOCK - LE%) + (UU% - CODE)
PRINT "MAINSUM_offset =",~(MAINSUM - LE%) + (UU% - CODE)
PRINT "TUT_ofset =",~(TUT - LE%) + (UU% - CODE)
PRINT "UU%=",~UU%," Q%=",~Q%, " OSB=",~OSB

\\ Further processing completed by elite-checksum.py script

PRINT "Memory usage: ", ~LE%, " - ",~P%
PRINT "Stack: ",len+ENDBLOCK-BLOCK

;OSCLI("S.:0.ELITE "+STR$~CODE +" "+STR$~O% +" "+STR$~run +" "+STR$~LL%)

\ *****************************************************************************
\ Save ELITE loader
\ *****************************************************************************

PRINT "S. ELITE ",~CODE," ",~UU%+(P%-LE%)," ",~run," ",~LL%
SAVE "output/ELITE.unprot.bin", CODE, UU%+(P%-LE%), run, LL%
