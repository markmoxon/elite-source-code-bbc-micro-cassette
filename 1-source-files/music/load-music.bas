MODE7
tstaddr = &8008
values = &90
unique = &80
RomSel = &FE30
romNumber = &8E : REM Set to address of .musicRomNumber
fromAddr = &80  : REM We can reuse unique block by this point

PRINT"BBC Micro Elite (Compendium version)"
PRINT"===================================="
PRINT'"Based on the Acornsoft SBG38 release"
PRINT"of Elite by Ian Bell and David Braben"
PRINT"Copyright (c) Acornsoft 1984"
PRINT'"Flicker-free routines, bug fixes and"
PRINT"music integration by Mark Moxon"
PRINT'"Sound routines by Kieran Connell and"
PRINT"Simon Morris"
PRINT'"Original music by Aidan Bell and Julie"
PRINT"Dunn (c) D. Braben and I. Bell 1985,"
PRINT"ported from the C64 by Negative Charge"
PRINT'"Sideways RAM detection and loading"
PRINT"routines by Tricky and J.G.Harston"

REM Find 16 values distinct from the 16 rom values and each other and save the original rom values
DIM CODE &100
FOR P = 0 TO 2 STEP 2
P%=CODE
[OPT P
SEI
LDA &F4                 \\ Store &F4 on stack
PHA
LDY #15                 \\ Unique values (-1) to find
TYA                     \\ A can start anywhere less than 256-64 as it just needs to allow for enough numbers not to clash with rom, tst and uninitialised tst values
.next_val
LDX #15                 \\ Sideways bank
ADC #1                  \\ Will inc mostly by 2, but doesn't matter
.next_slot
STX &F4
STX RomSel
CMP tstaddr
BEQ next_val
CMP unique,X            \\ Doesn't matter that we haven't checked these yet as it just excludes unnecessary values, but is safe
BEQ next_val
DEX
BPL next_slot
STA unique,Y
LDX tstaddr
STX values,Y
DEY
BPL next_val
LDX #0                  \\ Try to swap each rom value with a unique test value
.swap
STX &F4
STX RomSel              \\ Set RomSel as it will be needed to read, but is also sometimes used to select write
LDA unique,X
STA tstaddr
INX
CPX #16
BNE swap
LDY #16                 \\ Count matching values and restore old values - reverse order to swapping is safe
LDX #15
.tst_restore
STX &F4
STX RomSel
LDA tstaddr
CMP unique,X            \\ If it has changed, but is not this value, it will be picked up in a later bank
BNE not_swr
LDA values,X
STA tstaddr
DEY
STX values,Y
.not_swr
DEX
BPL tst_restore
STY values
PLA                     \\ Restore original value of &F4
STA &F4
STA RomSel              \\ Restore original ROM
CLI
RTS

.SRLOAD
LDA &F4
PHA
LDA romNumber
STA &F4
STA &FE30
.SR1
LDY #0
LDA (fromAddr),Y
STA toBlock+4
LDA #6
LDX #toBlock MOD256
LDY #toBlock DIV256
JSR &FFF1
INC fromAddr
INC toBlock
BNE SR1
INC fromAddr+1
INC toBlock+1
LDA toBlock+1
CMP #&C0
BNE SR1
PLA
STA &F4
STA &FE30
RTS

.toBlock
EQUD &8000
EQUD 0
]
NEXT
CALL CODE
N%=16-?&90
IF N%=0 THEN PRINT'"Can't run:";CHR$129;"no sideways RAM detected":END
PRINT'"Detected ";16-?&90;" sideways RAM bank";
IF N% > 1 THEN PRINT "s";
REM IF N% > 0 THEN FOR X% = ?&90 TO 15 : PRINT;" ";X%?&90; : NEXT
?romNumber=?(&90+?&90):REM STORE RAM BANK USED SOMEWHERE IN ZERO PAGE
PRINT'"Loading music into RAM bank ";?romNumber;"...";
*LOAD MUSICC 3F00
?&3F10=&09:?&3F11=&11:REM Update DNOIZ at &8010 to &1109 for Compendium
?&3F12=&31:?&3F13=&11:REM Update play1+1 at &8012 to &1130+1 for Compendium
?&3F16=&BD:?&3F17=&42:REM Update SFX at &8016 to &42BD for Compendium
!&80=&3F00 : CALL SRLOAD : REM Load ROM image into the correct bank
PRINT CHR$130;"OK"
PRINT'"Press any key to play Elite";
A$=GET$
*FX138,0,32
*RUN ELTdata
