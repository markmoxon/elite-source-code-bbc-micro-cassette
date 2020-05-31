ORG &0400
L%=&1100
CODE%=P%

\ This data is loaded at .QQ18 by elite-loader.asm
\ It is loaded at &1100 (L%) and moved down to &0400 (ORG) at runtime

EQUB &4C, &32, &24                  ; Token:    0
EQUB &00                            ; Value:    "FUEL SCOOPS ON {beep}"
                                    ; Encoded:  "[111][17]{7}"

EQUB &03, &60, &6B, &A9, &77        ; Token:    1
EQUB &00                            ; Value:    " CHART"
                                    ; Encoded:  " CH<138>T"

EQUB &64, &6C, &B5, &71, &6D, &6E   ; Token:    2
EQUB &B1, &77                       ; Value:    "GOVERNMENT"
EQUB &00                            ; Encoded:  "GO<150>RNM<146>T"

EQUB &67, &B2, &62, &32, &20        ; Token:    3
EQUB &00                            ; Value:    "DATA ON {chosen system name}"
                                    ; Encoded:  "D<145>A[17]{3}"

EQUB &AF, &B5, &6D, &77, &BA, &7A   ; Token:    4
EQUB &2E                            ; Value:    "INVENTORY{crlf}"
EQUB &00                            ; Encoded:  "<140><150>NT<153>Y{13}"

EQUB &70, &7A, &70, &BF, &6E        ; Token:    5
EQUB &00                            ; Value:    "SYSTEM"
                                    ; Encoded:  "SYS<156>M"

EQUB &73, &BD, &A6                  ; Token:    6
EQUB &00                            ; Value:    "PRICE"
                                    ; Encoded:  "P<158><133>"

EQUB &21, &03, &A8, &71, &68, &66   ; Token:    7
EQUB &77, &03, &85, &70             ; Value:    "{current system name} MARKET PRICES"
EQUB &00                            ; Encoded:  "{2} <139>RKET [166]S"

EQUB &AF, &67, &AB, &77, &BD, &A3   ; Token:    8
EQUB &00                            ; Value:    "INDUSTRIAL"
                                    ; Encoded:  "<140>D<136>T<158><128>"

EQUB &62, &64, &BD, &60, &76, &6F   ; Token:    9
EQUB &77, &76, &B7, &6F             ; Value:    "AGRICULTURAL"
EQUB &00                            ; Encoded:  "AG<158>CULTU<148>L"

EQUB &BD, &60, &6B, &03             ; Token:    10
EQUB &00                            ; Value:    "RICH "
                                    ; Encoded:  "<158>CH "

EQUB &62, &B5, &B7, &A0, &03        ; Token:    11
EQUB &00                            ; Value:    "AVERAGE "
                                    ; Encoded:  "A<150><148><131> "

EQUB &73, &6C, &BA, &03             ; Token:    12
EQUB &00                            ; Value:    "POOR "
                                    ; Encoded:  "PO<153> "

EQUB &A8, &AF, &6F, &7A, &03        ; Token:    13
EQUB &00                            ; Value:    "MAINLY "
                                    ; Encoded:  "<139><140>LY "

EQUB &76, &6D, &6A, &77             ; Token:    14
EQUB &00                            ; Value:    "UNIT"
                                    ; Encoded:  "UNIT"

EQUB &75, &6A, &66, &74, &03        ; Token:    15
EQUB &00                            ; Value:    "VIEW "
                                    ; Encoded:  "VIEW "

EQUB &B9, &B8, &B4, &77, &7A        ; Token:    16
EQUB &00                            ; Value:    "QUANTITY"
                                    ; Encoded:  "<154><155><151>TY"

EQUB &B8, &A9, &60, &6B, &7A        ; Token:    17
EQUB &00                            ; Value:    "ANARCHY"
                                    ; Encoded:  "<155><138>CHY"

EQUB &65, &66, &76, &67, &A3        ; Token:    18
EQUB &00                            ; Value:    "FEUDAL"
                                    ; Encoded:  "FEUD<128>"

EQUB &6E, &76, &6F, &B4, &0E, &81   ; Token:    19
EQUB &00                            ; Value:    "MULTI-GOVERNMENT"
                                    ; Encoded:  "MUL<151>-[162]"

EQUB &AE, &60, &77, &B2, &BA, &9A   ; Token:    20
EQUB &00                            ; Value:    "DICTATORSHIP"
                                    ; Encoded:  "<141>CT<145><153>[185]"

EQUB &D8, &6E, &76, &6D, &BE, &77   ; Token:    21
EQUB &00                            ; Value:    "COMMUNIST"
                                    ; Encoded:  "[251]MUN<157>T"

EQUB &60, &BC, &65, &BB, &B3, &62   ; Token:    22
EQUB &60, &7A                       ; Value:    "CONFEDERACY"
EQUB &00                            ; Encoded:  "C<159>F<152><144>ACY"

EQUB &67, &66, &6E, &6C, &60, &B7   ; Token:    23
EQUB &60, &7A                       ; Value:    "DEMOCRACY"
EQUB &00                            ; Encoded:  "DEMOC<148>CY"

EQUB &60, &BA, &73, &BA, &B2, &66   ; Token:    24
EQUB &03, &E8, &B2, &66             ; Value:    "CORPORATE STATE"
EQUB &00                            ; Encoded:  "C<153>P<153><145>E [203]<145>E"

EQUB &70, &6B, &6A, &73             ; Token:    25
EQUB &00                            ; Value:    "SHIP"
                                    ; Encoded:  "SHIP"

EQUB &73, &71, &6C, &67, &76, &60   ; Token:    26
EQUB &77                            ; Value:    "PRODUCT"
EQUB &00                            ; Encoded:  "PRODUCT"

EQUB &03, &B6, &70, &B3             ; Token:    27
EQUB &00                            ; Value:    " LASER"
                                    ; Encoded:  " <149>S<144>"

EQUB &6B, &76, &6E, &B8, &03, &60   ; Token:    28
EQUB &6C, &6F, &BC, &6A, &A3        ; Value:    "HUMAN COLONIAL"
EQUB &00                            ; Encoded:  "HUM<155> COL<159>I<128>"

EQUB &6B, &7A, &73, &B3, &70, &73   ; Token:    29
EQUB &62, &A6, &03                  ; Value:    "HYPERSPACE "
EQUB &00                            ; Encoded:  "HYP<144>SPA<133> "

EQUB &70, &6B, &BA, &77, &03, &E9   ; Token:    30
EQUB &82                            ; Value:    "SHORT RANGE CHART"
EQUB &00                            ; Encoded:  "SH<153>T [202][161]"

EQUB &AE, &E8, &B8, &A6             ; Token:    31
EQUB &00                            ; Value:    "DISTANCE"
                                    ; Encoded:  "<141>[203]<155><133>"

EQUB &73, &6C, &73, &76, &6F, &B2   ; Token:    32
EQUB &6A, &BC                       ; Value:    "POPULATION"
EQUB &00                            ; Encoded:  "POPUL<145>I<159>"

EQUB &64, &71, &6C, &70, &70, &03   ; Token:    33
EQUB &99, &6A, &75, &6A, &77, &7A   ; Value:    "GROSS PRODUCTIVITY"
EQUB &00                            ; Encoded:  "GROSS [186]IVITY"

EQUB &66, &60, &BC, &6C, &6E, &7A   ; Token:    34
EQUB &00                            ; Value:    "ECONOMY"
                                    ; Encoded:  "EC<159>OMY"

EQUB &03, &6F, &6A, &64, &6B, &77   ; Token:    35
EQUB &03, &7A, &66, &A9, &70        ; Value:    " LIGHT YEARS"
EQUB &00                            ; Encoded:  " LIGHT YE<138>S"

EQUB &BF, &60, &6B, &0D, &A2, &B5   ; Token:    36
EQUB &6F                            ; Value:    "TECH.LEVEL"
EQUB &00                            ; Encoded:  "<156>CH.<129><150>L"

EQUB &60, &62, &70, &6B             ; Token:    37
EQUB &00                            ; Value:    "CASH"
                                    ; Encoded:  "CASH"

EQUB &03, &A5, &55, &6A, &BC        ; Token:    38
EQUB &00                            ; Value:    " BILLION"
                                    ; Encoded:  " <134>[118]I<159>"

EQUB &59, &82, &22                  ; Token:    39
EQUB &00                            ; Value:    "GALACTIC CHART{galaxy number padded to width 3}"
                                    ; Encoded:  "[122][161]{1}"

EQUB &77, &A9, &A0, &77, &03, &6F   ; Token:    40
EQUB &6C, &E8                       ; Value:    "TARGET LOST"
EQUB &00                            ; Encoded:  "T<138><131>T LO[203]"

EQUB &49, &03, &69, &62, &6E, &6E   ; Token:    41
EQUB &BB                            ; Value:    "MISSILE JAMMED"
EQUB &00                            ; Encoded:  "[106] JAMM<152>"

EQUB &71, &B8, &A0                  ; Token:    42
EQUB &00                            ; Value:    "RANGE"
                                    ; Encoded:  "R<155><131>"

EQUB &70, &77                       ; Token:    43
EQUB &00                            ; Value:    "ST"
                                    ; Encoded:  "ST"

EQUB &93, &03, &6C, &65, &03        ; Token:    44
EQUB &00                            ; Value:    "QUANTITY OF "
                                    ; Encoded:  "[176] OF "

EQUB &70, &66, &55                  ; Token:    45
EQUB &00                            ; Value:    "SELL"
                                    ; Encoded:  "SE[118]"

EQUB &03, &60, &A9, &64, &6C, &25   ; Token:    46
EQUB &00                            ; Value:    " CARGO{sentence case}"
                                    ; Encoded:  " C<138>GO{6}"

EQUB &66, &B9, &6A, &73             ; Token:    47
EQUB &00                            ; Value:    "EQUIP"
                                    ; Encoded:  "E<154>IP"

EQUB &65, &6C, &6C, &67             ; Token:    48
EQUB &00                            ; Value:    "FOOD"
                                    ; Encoded:  "FOOD"

EQUB &BF, &7B, &B4, &6F, &AA        ; Token:    49
EQUB &00                            ; Value:    "TEXTILES"
                                    ; Encoded:  "<156>X<151>L<137>"

EQUB &B7, &AE, &6C, &62, &60, &B4   ; Token:    50
EQUB &B5, &70                       ; Value:    "RADIOACTIVES"
EQUB &00                            ; Encoded:  "<148><141>OAC<151><150>S"

EQUB &70, &B6, &B5, &70             ; Token:    51
EQUB &00                            ; Value:    "SLAVES"
                                    ; Encoded:  "S<149><150>S"

EQUB &6F, &6A, &B9, &BA, &0C, &74   ; Token:    52
EQUB &AF, &AA                       ; Value:    "LIQUOR/WINES"
EQUB &00                            ; Encoded:  "LI<154><153>/W<140><137>"

EQUB &6F, &76, &7B, &76, &BD, &AA   ; Token:    53
EQUB &00                            ; Value:    "LUXURIES"
                                    ; Encoded:  "LUXU<158><137>"

EQUB &6D, &A9, &60, &6C, &B4, &60   ; Token:    54
EQUB &70                            ; Value:    "NARCOTICS"
EQUB &00                            ; Encoded:  "N<138>CO<151>CS"

EQUB &D8, &73, &76, &77, &B3, &70   ; Token:    55
EQUB &00                            ; Value:    "COMPUTERS"
                                    ; Encoded:  "[251]PUT<144>S"

EQUB &A8, &60, &6B, &AF, &B3, &7A   ; Token:    56
EQUB &00                            ; Value:    "MACHINERY"
                                    ; Encoded:  "<139>CH<140><144>Y"

EQUB &56, &6C, &7A, &70             ; Token:    57
EQUB &00                            ; Value:    "ALLOYS"
                                    ; Encoded:  "[117]OYS"

EQUB &65, &6A, &AD, &A9, &6E, &70   ; Token:    58
EQUB &00                            ; Value:    "FIREARMS"
                                    ; Encoded:  "FI<142><138>MS"

EQUB &65, &76, &71, &70             ; Token:    59
EQUB &00                            ; Value:    "FURS"
                                    ; Encoded:  "FURS"

EQUB &6E, &AF, &B3, &A3, &70        ; Token:    60
EQUB &00                            ; Value:    "MINERALS"
                                    ; Encoded:  "M<140><144><128>S"

EQUB &64, &6C, &6F, &67             ; Token:    61
EQUB &00                            ; Value:    "GOLD"
                                    ; Encoded:  "GOLD"

EQUB &73, &6F, &B2, &AF, &76, &6E   ; Token:    62
EQUB &00                            ; Value:    "PLATINUM"
                                    ; Encoded:  "PL<145><140>UM"

EQUB &A0, &6E, &0E, &E8, &BC, &AA   ; Token:    63
EQUB &00                            ; Value:    "GEM-STONES"
                                    ; Encoded:  "<131>M-[203]<159><137>"

EQUB &A3, &6A, &B1, &03, &5C, &70   ; Token:    64
EQUB &00                            ; Value:    "ALIEN ITEMS"
                                    ; Encoded:  "<128>I<146> [127]S"

EQUB &0B, &7A, &0C, &6D, &0A, &1C   ; Token:    65
EQUB &00                            ; Value:    "(Y/N)?"
                                    ; Encoded:  "(Y/N)?"

EQUB &03, &60, &71                  ; Token:    66
EQUB &00                            ; Value:    " CR"
                                    ; Encoded:  " CR"

EQUB &6F, &A9, &A0                  ; Token:    67
EQUB &00                            ; Value:    "LARGE"
                                    ; Encoded:  "L<138><131>"

EQUB &65, &6A, &B3, &A6             ; Token:    68
EQUB &00                            ; Value:    "FIERCE"
                                    ; Encoded:  "FI<144><133>"

EQUB &70, &A8, &55                  ; Token:    69
EQUB &00                            ; Value:    "SMALL"
                                    ; Encoded:  "S<139>[118]"

EQUB &64, &AD, &B1                  ; Token:    70
EQUB &00                            ; Value:    "GREEN"
                                    ; Encoded:  "G<142><146>"

EQUB &71, &BB                       ; Token:    71
EQUB &00                            ; Value:    "RED"
                                    ; Encoded:  "R<152>"

EQUB &7A, &66, &55, &6C, &74        ; Token:    72
EQUB &00                            ; Value:    "YELLOW"
                                    ; Encoded:  "YE[118]OW"

EQUB &61, &6F, &76, &66             ; Token:    73
EQUB &00                            ; Value:    "BLUE"
                                    ; Encoded:  "BLUE"

EQUB &61, &B6, &60, &68             ; Token:    74
EQUB &00                            ; Value:    "BLACK"
                                    ; Encoded:  "B<149>CK"

EQUB &35                            ; Token:    75
EQUB &00                            ; Value:    "HARMLESS"
                                    ; Encoded:  "[22]"

EQUB &70, &6F, &6A, &6E, &7A        ; Token:    76
EQUB &00                            ; Value:    "SLIMY"
                                    ; Encoded:  "SLIMY"

EQUB &61, &76, &64, &0E, &66, &7A   ; Token:    77
EQUB &BB                            ; Value:    "BUG-EYED"
EQUB &00                            ; Encoded:  "BUG-EY<152>"

EQUB &6B, &BA, &6D, &BB             ; Token:    78
EQUB &00                            ; Value:    "HORNED"
                                    ; Encoded:  "H<153>N<152>"

EQUB &61, &BC, &7A                  ; Token:    79
EQUB &00                            ; Value:    "BONY"
                                    ; Encoded:  "B<159>Y"

EQUB &65, &B2                       ; Token:    80
EQUB &00                            ; Value:    "FAT"
                                    ; Encoded:  "F<145>"

EQUB &65, &76, &71, &71, &7A        ; Token:    81
EQUB &00                            ; Value:    "FURRY"
                                    ; Encoded:  "FURRY"

EQUB &71, &6C, &67, &B1, &77        ; Token:    82
EQUB &00                            ; Value:    "RODENT"
                                    ; Encoded:  "ROD<146>T"

EQUB &65, &71, &6C, &64             ; Token:    83
EQUB &00                            ; Value:    "FROG"
                                    ; Encoded:  "FROG"

EQUB &6F, &6A, &A7, &71, &67        ; Token:    84
EQUB &00                            ; Value:    "LIZARD"
                                    ; Encoded:  "LI<132>RD"

EQUB &6F, &6C, &61, &E8, &B3        ; Token:    85
EQUB &00                            ; Value:    "LOBSTER"
                                    ; Encoded:  "LOB[203]<144>"

EQUB &A5, &71, &67                  ; Token:    86
EQUB &00                            ; Value:    "BIRD"
                                    ; Encoded:  "<134>RD"

EQUB &6B, &76, &6E, &B8, &6C, &6A   ; Token:    87
EQUB &67                            ; Value:    "HUMANOID"
EQUB &00                            ; Encoded:  "HUM<155>OID"

EQUB &65, &66, &6F, &AF, &66        ; Token:    88
EQUB &00                            ; Value:    "FELINE"
                                    ; Encoded:  "FEL<140>E"

EQUB &AF, &70, &66, &60, &77        ; Token:    89
EQUB &00                            ; Value:    "INSECT"
                                    ; Encoded:  "<140>SECT"

EQUB &88, &B7, &AE, &AB             ; Token:    90
EQUB &00                            ; Value:    "AVERAGE RADIUS"
                                    ; Encoded:  "[171]<148><141><136>"

EQUB &60, &6C, &6E                  ; Token:    91
EQUB &00                            ; Value:    "COM"
                                    ; Encoded:  "COM"

EQUB &D8, &6E, &B8, &67, &B3        ; Token:    92
EQUB &00                            ; Value:    "COMMANDER"
                                    ; Encoded:  "[251]M<155>D<144>"

EQUB &03, &67, &AA, &77, &71, &6C   ; Token:    93
EQUB &7A, &BB                       ; Value:    " DESTROYED"
EQUB &00                            ; Encoded:  " D<137>TROY<152>"

EQUB &61, &7A, &03, &67, &0D, &61   ; Token:    94
EQUB &B7, &B0, &6D, &03, &05, &03   ; Value:    "BY D.BRABEN & I.BELL"
EQUB &6A, &0D, &B0, &55             ; Value:    "BY D.B<148><147>N & I.<147>[118]"
EQUB &00

EQUB &8D, &03, &03, &93, &2E, &03   ; Token:    95
EQUB &99, &03, &03, &03, &8D, &03   ; Value:    "UNIT  QUANTITY{crlf} PRODUCT   UNIT PRICE FOR SALE{crlf}{lf}"
EQUB &85, &03, &65, &BA, &03, &70   ; Encoded:  "[174]  [176]{13} [186]   [174] [166] F<153> SA<129>{13}{10}"
EQUB &62, &A2, &2E, &29                                  
EQUB &00

EQUB &65, &71, &BC, &77             ; Token:    96
EQUB &00                            ; Value:    "FRONT"
                                    ; Encoded:  "FR<159>T"

EQUB &AD, &A9                       ; Token:    97
EQUB &00                            ; Value:    "REAR"
                                    ; Encoded:  "<142><138>"

EQUB &A2, &65, &77                  ; Token:    98
EQUB &00                            ; Value:    "LEFT"
                                    ; Encoded:  "<129>FT"

EQUB &BD, &64, &6B, &77             ; Token:    99
EQUB &00                            ; Value:    "RIGHT"
                                    ; Encoded:  "<158>GHT"

EQUB &5A, &6F, &6C, &74, &24        ; Token:    100
EQUB &00                            ; Value:    "ENERGY LOW{beep}"
                                    ; Encoded:  "[121]LOW{7}"

EQUB &40, &32, &DF, &02             ; Token:    101
EQUB &00                            ; Value:    "RIGHT ON COMMANDER!"
                                    ; Encoded:  "[99][17][252]!"

EQUB &66, &7B, &77, &B7, &03        ; Token:    102
EQUB &00                            ; Value:    "EXTRA "
                                    ; Encoded:  "EXT<148> "

EQUB &73, &76, &6F, &70, &66, &98   ; Token:    103
EQUB &00                            ; Value:    "PULSE LASER"
                                    ; Encoded:  "PULSE[187]"

EQUB &B0, &62, &6E, &98             ; Token:    104
EQUB &00                            ; Value:    "BEAM LASER"
                                    ; Encoded:  "<147>AM[187]"

EQUB &65, &76, &66, &6F             ; Token:    105
EQUB &00                            ; Value:    "FUEL"
                                    ; Encoded:  "FUEL"

EQUB &6E, &BE, &70, &6A, &A2        ; Token:    106
EQUB &00                            ; Value:    "MISSILE"
                                    ; Encoded:  "M<157>SI<129>"

EQUB &C0, &ED, &03, &61, &62, &7A   ; Token:    107
EQUB &00                            ; Value:    "LARGE CARGO{sentence case} BAY"
                                    ; Encoded:  "[227][206] BAY"

EQUB &66, &0D, &60, &0D, &6E, &0D   ; Token:    108
EQUB &86                            ; Value:    "E.C.M.SYSTEM"
EQUB &00                            ; Encoded:  "E.C.M.[165]"

EQUB &45, &44, &70                  ; Token:    109
EQUB &00                            ; Value:    "EXTRA PULSE LASERS"
                                    ; Encoded:  "[102][103]S"

EQUB &45, &4B, &70                  ; Token:    110
EQUB &00                            ; Value:    "EXTRA BEAM LASERS"
                                    ; Encoded:  "[102][104]S"

EQUB &4A, &03, &70, &60, &6C, &6C   ; Token:    111
EQUB &73, &70                       ; Value:    "FUEL SCOOPS"
EQUB &00                            ; Encoded:  "[105] SCOOPS"

EQUB &AA, &60, &62, &73, &66, &03   ; Token:    112
EQUB &73, &6C, &67                  ; Value:    "ESCAPE POD"
EQUB &00                            ; Encoded:  "<137>CAPE POD"

EQUB &5A, &61, &6C, &6E, &61        ; Token:    113
EQUB &00                            ; Value:    "ENERGY BOMB"
                                    ; Encoded:  "[121]BOMB"

EQUB &5A, &8D                       ; Token:    114
EQUB &00                            ; Value:    "ENERGY UNIT"
                                    ; Encoded:  "[121][174]"

EQUB &5F, &AF, &64, &03, &F4        ; Token:    115
EQUB &00                            ; Value:    "DOCKING COMPUTERS"
                                    ; Encoded:  "[124]<140>G [215]"

EQUB &59, &03, &9E                  ; Token:    116
EQUB &00                            ; Value:    "GALACTIC HYPERSPACE "
                                    ; Encoded:  "[122] [189]"

EQUB &62, &55                       ; Token:    117
EQUB &00                            ; Value:    "ALL"
                                    ; Encoded:  "A[118]"

EQUB &6F, &6F                       ; Token:    118
EQUB &00                            ; Value:    "LL"
                                    ; Encoded:  "LL"

EQUB &E6, &19, &23                  ; Token:    119
EQUB &00                            ; Value:    "CASH:{cash padded to width 11} CR"
                                    ; Encoded:  "[197]:{0}"

EQUB &AF, &D8, &AF, &64, &03, &49   ; Token:    120
EQUB &00                            ; Value:    "INCOMING MISSILE"
                                    ; Encoded:  "<140>[251]<140>G [106]"

EQUB &B1, &B3, &64, &7A, &03        ; Token:    121
EQUB &00                            ; Value:    "ENERGY "
                                    ; Encoded:  "<146><144>GY "

EQUB &64, &62, &B6, &60, &B4, &60   ; Token:    122
EQUB &00                            ; Value:    "GALACTIC"
                                    ; Encoded:  "GA<149>C<151>C"

EQUB &2E, &DF, &04, &70, &03, &6D   ; Token:    123
EQUB &62, &6E, &66, &1C, &03        ; Value:    "{crlf}COMMANDER'S NAME? "
EQUB &00                            ; Encoded:  "{13}[252]'S NAME? "

EQUB &67, &6C, &60, &68             ; Token:    124
EQUB &00                            ; Value:    "DOCK"
                                    ; Encoded:  "DOCK"

EQUB &26, &A2, &64, &A3, &03, &E8   ; Token:    125
EQUB &B2, &AB, &19                  ; Value:    "FUEL: {fuel as x.x} LIGHT YEARS{crlf}LEGAL STATUS:"
EQUB &00                            ; Encoded:  "{5}<129>G<128> [203]<145><136>:"

EQUB &DF, &03, &27, &2E, &2E, &2E   ; Token:    126
EQUB &25, &3C, &03, &86, &2A, &21   ; Value:    "COMMANDER {cmdr name}{crlf}{crlf}{crlf}{sentence case}PRESENT SYSTEM{tab to col 21}:{current system name}{crlf}HYPERSPACE SYSTEM{tab to col 21}:{chosen system name}{crlf}CONDITION{tab to col 21}:"
EQUB &2E, &9E, &86, &2A, &20, &2E   ; Encoded:  "[252] {4}{13}{13}{13}{6}[31] [165]{9}{2}{13}[189][165]{9}{3}{13}C<159><141><151><159>{9}"
EQUB &60, &BC, &AE, &B4, &BC, &2A
EQUB &00

EQUB &6A, &BF, &6E                  ; Token:    127
EQUB &00                            ; Value:    "ITEM"
                                    ; Encoded:  "I<156>M"

EQUB &03, &03, &6F, &6C, &62, &67   ; Token:    128
EQUB &03, &6D, &66, &74, &03, &DF   ; Value:    "  LOAD NEW COMMANDER (Y/N)?{crlf}{crlf}"
EQUB &03, &C2, &2E, &2E             ; Encoded:  "  LOAD NEW [252] [225]{13}{13}"
EQUB &00               

EQUB &25, &5F, &BB                  ; Token:    129
EQUB &00                            ; Value:    "{sentence case}DOCKED"
                                    ; Encoded:  "{6}[124]<152>"

EQUB &B7, &B4, &6D, &64, &19        ; Token:    130
EQUB &00                            ; Value:    "RATING:"
                                    ; Encoded:  "<148><151>NG:"

EQUB &03, &BC, &03                  ; Token:    131
EQUB &00                            ; Value:    " ON "
                                    ; Encoded:  " <159> "

EQUB &2E, &2B, &EC, &6E, &B1, &77   ; Token:    132
EQUB &19, &25                       ; Value:    "{crlf}{all caps}EQUIPMENT:{sentence case}"
EQUB &00                            ; Encoded:  "{13}{8}[207]M<146>T:{6}"

EQUB &60, &A2, &B8                  ; Token:    133
EQUB &00                            ; Value:    "CLEAN"
                                    ; Encoded:  "C<129><155>"

EQUB &6C, &65, &65, &B1, &67, &B3   ; Token:    134
EQUB &00                            ; Value:    "OFFENDER"
                                    ; Encoded:  "OFF<146>D<144>"

EQUB &65, &76, &64, &6A, &B4, &B5   ; Token:    135
EQUB &00                            ; Value:    "FUGITIVE"
                                    ; Encoded:  "FUGI<151><150>"

EQUB &6B, &A9, &6E, &A2, &70, &70   ; Token:    136
EQUB &00                            ; Value:    "HARMLESS"
                                    ; Encoded:  "H<138>M<129>SS"

EQUB &6E, &6C, &E8, &6F, &7A, &03   ; Token:    137
EQUB &35                            ; Value:    "MOSTLY HARMLESS"
EQUB &00                            ; Encoded:  "MO[203]LY [22]"

EQUB &8F                            ; Token:    138
EQUB &00                            ; Value:    "POOR "
                                    ; Encoded:  "[172]"

EQUB &88                            ; Token:    139
EQUB &00                            ; Value:    "AVERAGE "
                                    ; Encoded:  "[171]"

EQUB &62, &61, &6C, &B5, &03, &88   ; Token:    140
EQUB &00                            ; Value:    "ABOVE AVERAGE "
                                    ; Encoded:  "ABO<150> [171]"

EQUB &D8, &73, &66, &77, &B1, &77   ; Token:    141
EQUB &00                            ; Value:    "COMPETENT"
                                    ; Encoded:  "[251]PET<146>T"

EQUB &67, &B8, &A0, &71, &6C, &AB   ; Token:    142
EQUB &00                            ; Value:    "DANGEROUS"
                                    ; Encoded:  "D<155><131>RO<136>"

EQUB &67, &66, &62, &67, &6F, &7A   ; Token:    143
EQUB &00                            ; Value:    "DEADLY"
                                    ; Encoded:  "DEADLY"

EQUB &0E, &0E, &0E, &0E, &03, &66   ; Token:    144
EQUB &03, &6F, &03, &6A, &03, &77   ; Value:    "---- E L I T E ----"
EQUB &03, &66, &03, &0E, &0E, &0E   ; Encoded:  "---- E L I T E ----"
EQUB &0E
EQUB &00

EQUB &73, &AD, &70, &B1, &77        ; Token:    145
EQUB &00                            ; Value:    "PRESENT"
                                    ; Encoded:  "P<142>S<146>T"

EQUB &2B, &64, &62, &6E, &66, &03   ; Token:    146
EQUB &6C, &B5, &71                  ; Value:    "{all caps}GAME OVER"
EQUB &00                            ; Encoded:  "{8}GAME O<150>R"

EQUB &73, &71, &AA, &70, &03, &65   ; Token:    147
EQUB &6A, &AD, &03, &BA, &03, &70   ; Value:    "PRESS FIRE OR SPACE,COMMANDER.{crlf}{crlf}"
EQUB &73, &62, &A6, &0F, &DF, &0D   ; Encoded:  "PR<137>S FI<142> <153> SPA<133>,[252].{13}{13}"
EQUB &2E, &2E
EQUB &00

EQUB &0B, &60, &0A, &03, &62, &60   ; Token:    148
EQUB &BA, &6D, &A4, &65, &77, &03   ; Value:    "(C) ACORNSOFT 1984"
EQUB &12, &1A, &1B, &17             ; Encoded:  "(C) AC<153>N<135>FT 1984"
EQUB &00

PRINT "output/WORDS9.bin"
PRINT "ASSEMBLE AT", ~CODE%
PRINT "P%=",~P%
PRINT "CODE SIZE=", ~(P%-CODE%)
PRINT "RELOAD AT ", ~L%

PRINT "S.WORDS9 ",~CODE%," ",~P%," ",~L%," ",~L%

SAVE "output/WORDS9.bin", CODE%, P%, L%, L%
