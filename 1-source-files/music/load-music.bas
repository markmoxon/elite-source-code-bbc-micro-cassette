DIM CODE% &100
bank=&70
temp=&71
orig=&72
addrBlock=&73
fromAddr=&80
romNumber=&8E : REM Address of .musicRomNumber
master%=FALSE
copro%=FALSE
:
VDU 22,7
PROCtitle
PROCfindSRAM
PROCloadROM
PROCpatch
PROCloadSRAM
*RUN ELTdata
END
:
DEF PROCpatch
?&3C10=&09:?&3C11=&11:REM Update DNOIZ at &8010 to &1109 for Compendium
?&3C12=&31:?&3C13=&11:REM Update play1+1 at &8012 to &1130+1 for Compendium
?&3C16=&BD:?&3C17=&42:REM Update SFX at &8016 to &42BD for Compendium
ENDPROC
:
DEF PROCtitle
PRINT"BBC Micro Elite (Compendium version)"
PRINT"===================================="
PRINT
PRINT"The updated BBC Micro cassette version"
PRINT"for the BBC Micro with 16K sideways RAM"
PRINT
PRINT"Based on the Acornsoft SBG38 release"
PRINT"of Elite by Ian Bell and David Braben"
PRINT"Copyright (c) Acornsoft 1984"
PRINT
PRINT"Flicker-free routines, bug fixes and"
PRINT"music integration by Mark Moxon"
PRINT
PRINT"Sound routines by Kieran Connell and"
PRINT"Simon Morris"
PRINT
PRINT"Original music by Aidan Bell and Julie"
PRINT"Dunn (c) D. Braben and I. Bell 1985,"
PRINT"ported from the C64 by Negative Charge"
ENDPROC
:
DEF PROCloadROM
IF ?bank>15 THEN PRINT'"Can't run:";CHR$129;"no sideways RAM detected":END
PRINT'"Loading music into RAM bank ";?bank;"...";
*LOAD MUSICC 3C00
ENDPROC
:
DEF PROCloadSRAM
!fromAddr=&3C00
CALL SRLoad
PRINT CHR$130;"OK"
PRINT'"Press any key to play Elite";
A$=GET$
*FX138,0,32
ENDPROC
:
DEF PROCfindSRAM
FOR pass%=0 TO 2 STEP 2
P%=CODE%
[OPT pass%

 SEI                \ Disable interrupts

 LDX #&00           \ Set A = ?&00F4
 LDY #&F4
 JSR GetByteXY

 PHA                \ Store A on stack

 LDA #0             \ Try each ROM, starting from bank 0
 STA bank

.mloop

 JSR PageBankA      \ Page in bank A

 LDX #&80           \ Set A = ?&8007 (copyright offset)
 LDY #&07           \
 JSR GetByteXY      \ Also sets addrBlock+1 = &80

 STA addrBlock      \ Set addrBlock(1 0) to copyright address

 LDA #0             \ Set temp = index into copyright string
 STA temp

.cloop

 JSR GetByte        \ Fetch next copyright byte from ROM

 LDY temp           \ If no copyright match, go to emptyBank
 CMP copyright,Y
 BNE emptyBank

 INC temp           \ Move adresses to next character
 INC addrBlock

 INY                \ Loop through all four characters
 CPY #4
 BNE cloop

 BEQ nextBank       \ Bank is occupied so move on to next bank (JMP)

.emptyBank

 LDX #&80           \ Set A = ?&8008 (the byte to use for RAM test)
 LDY #&08
 JSR GetByteXY

 STA orig           \ Store original value in orig

 EOR #&FF           \ Set temp = ~A
 STA temp

 JSR SetByte        \ Set ?&8008 = ~A

 JSR GetByte        \ Set A = ?&8008

 CMP temp           \ If set <> get, move on to next bank
 BNE nextBank

 LDA orig           \ Set ?&8008 = orig to restore &8008
 JSR SetByte

 JMP done           \ Return the bank number in A

.nextBank

 INC bank           \ Move on to next bank

 LDA bank           \ Fetch next bank number to check

 OPT FNmaster       \ Skip bank 6 if this is a Master

 CMP #16            \ Loop back to check next bank until all done
 BCC mloop

.done

 PLA                \ Page in original bank
 JSR PageBankA

 LDA bank           \ Set ?romNumber = bank
 LDX #0
 LDY #romNumber
 JSR SetByteXY

 CLI                \ Enable interrupts

 RTS                \ Return

.SRLoad

 LDX #&00           \ Set A = ?&00F4
 LDY #&F4
 JSR GetByteXY

 PHA                \ Store A on stack

 LDA bank           \ Page in SRAM bank
 JSR PageBankA

 LDX #&80           \ Set addrBlock(1 0) = &8000
 LDY #&00
 STX addrBlock+1
 STY addrBlock

.sloop

 LDY #0             \ Set ?addrBlock(1 0) = ?fromAddr(1 0)
 LDA (fromAddr),Y
 JSR SetByte

 INC fromAddr       \ Loop back to copy one page
 INC addrBlock
 BNE sloop

 INC fromAddr+1     \ Loop back to copy next page until &C000
 INC addrBlock+1
 LDA addrBlock+1
 CMP #&C0
 BNE sloop

 BEQ done           \ Restore original bank (JMP)

.copyright

 EQUB 0
 EQUS "(C)"

.PageBankA

 PHA                \ Set ?&00F4 = A
 LDX #&00
 LDY #&F4
 JSR SetByteXY

 PLA                \ Set ?&FE30 = A
 LDX #&FE
 LDY #&30
 JMP SetByteXY

.SetByteXY

 STX addrBlock+1    \ Set Address
 STY addrBlock

.SetByte

 OPT FNset          \ Set across Tube
 RTS

.GetByteXY

 STX addrBlock+1    \ Set Address
 STY addrBlock

.GetByte

 OPT FNget          \ Get across Tube
 RTS
]
NEXT
CALL CODE%
ENDPROC
:
DEF FNmaster
IF master% PROCnotBank6
=pass%
:
DEF PROCnotBank6
[OPT pass%
 CMP #6             \ Do not use bank 6 (Elite uses it)
 BEQ nextBank
]
ENDPROC
:
DEF FNget
IF copro% PROCgetTube ELSE PROCgetLDA
=pass%
:
DEF PROCgetTube
[OPT pass%
 LDA #5
 LDX #addrBlock MOD256
 LDY #addrBlock DIV256
 JSR &FFF1
 LDA addrBlock+4
]
ENDPROC
:
DEF PROCgetLDA
[OPT pass%
 LDY #0
 LDA (addrBlock),Y
]
ENDPROC
:
DEF FNset
IF copro% PROCsetTube ELSE PROCsetSTA
=pass%
:
DEF PROCsetTube
[OPT pass%
 STA addrBlock+4
 LDA #6
 LDX #addrBlock MOD256
 LDY #addrBlock DIV256
 JSR &FFF1
]
ENDPROC
:
DEF PROCsetSTA
[OPT pass%
 LDY #0
 STA (addrBlock),Y
]
ENDPROC
