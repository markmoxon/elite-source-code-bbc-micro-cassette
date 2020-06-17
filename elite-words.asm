\ *****************************************************************************
\ ELITE WORDS SOURCE
\ *****************************************************************************

\ This data is loaded at &1100 (LOAD%) as part of elite-loader.asm. It is then
\ moved down to &0400 (CODE%), which is at the location QQ18.

LOAD% = &1100
CODE% = &0400

ORG CODE%

\ *****************************************************************************
\ Tokens in Elite
\ *****************************************************************************
\ 
\ Elite uses a tokenisation system to store the text it displays during the
\ game. This enables the game to store strings more efficiently than would be
\ the case if they were simply inserted into the source code using EQUS, and it
\ also makes it possible to create things like system names using procedural
\ generation.
\ 
\ To support tokenisation, characters are printed to the screen using a special
\ subroutine (TT27), which not only supports the usual range of letters,
\ numbers and punctuation, but also three different types of token. When
\ printed, these tokens get expanded into longer strings, which enables the
\ game to squeeze a lot of text into a small amount of storage.
\ 
\ To print something, you pass a byte through to the printing routine at TT27.
\ The value of that byte determines what gets printed, as follows:
\ 
\     Value (n)   Type
\     ---------   -------------------------------------------------------
\     0-13        Control codes 0-13
\     14-31       Recursive tokens 128-145 (i.e. token number = n + 114)
\     32-95       Normal ASCII characters 32-95 (0-9, A-Z and most punctuation)
\     96-127      Recursive tokens 96-127 (i.e. token number = n)
\     128-159     Two-letter tokens 128-159
\     160-255     Recursive tokens 0-95 (i.e. token number = n - 160)
\ 
\ Characters with codes 32-95 represent the normal ASCII characters from ' ' to
\ '_', so a value of 65 in an Elite string represents the letter A (as 'A' has
\ character code 65 in the BBC Micro's character set).
\ 
\ All other character codes (0-31 and 96-255) represent tokens, and they can
\ print anything from single characters to entire sentences. In the case of
\ recursive tokens, the tokens can themselves contain other tokens, and in this
\ way long strings can be stored in very few bytes, at the expense of code
\ readability and speed.
\ 
\ To make things easier to follow in the discussion and comments below, let's
\ refer to the three token types like this, where n is the character code:
\ 
\     {n}    Control codes        n = 0 to 13
\     <n>    Two-letter token     n = 128 to 159
\     [n]    Recursive token      n = 0 to 148
\ 
\ So when we say {13} we're talking about control code 13 ("crlf"), while <141>
\ is the two-letter token 141 ("DI"), and [3] is the recursive token 3 ("DATA
\ ON {current system}"). The brackets are just there to make things easier to
\ understand when following the code, because the way these tokens are stored
\ in memory and passed to subroutines is confusing, to say the least.
\ 
\ We'll take a look at each of the three token types in more detail below, but
\ first a word about how characters get printed in Elite.
\ 
\ *****************************************************************************
\ The TT27 print subroutine
\ *****************************************************************************
\ 
\ Elite contains a subroutine at TT27 that prints out the character given in
\ the accumulator, and if that number refers to a token, then the token is
\ expanded before being printed. Whole strings can be printed by calling this
\ subroutine on one character at a time, and this is how almost all of the text
\ in the game gets put on screen. For example, the following code:
\ 
\     LDA #65
\     JSR TT27
\ 
\ prints a capital A, while this code:
\ 
\     LDA #163
\     JSR TT27
\ 
\ prints recursive token number 3 (see below for more on why we pass #163
\ instead of #3). This would produce the following if we were currently
\ visiting Tionisla:
\ 
\     DATA ON TIONISLA
\ 
\ This is because token 3 expands to the string "DATA ON {current system}". You
\ can see this very call being used in TT25, which displays data on the
\ selected system when F6 is pressed (this particular call is what prints the
\ title at the top of the screen).
\ 
\ *****************************************************************************
\ The ex print subroutine
\ *****************************************************************************
\ 
\ You may have noticed that in the table above, there are character codes for
\ all our ASCII characters and tokens, except for recursive tokens 146, 147 and
\ 148. How do we print these?
\ 
\ To print these tokens, there is another subroutine at ex that always prints
\ the recursive token number in the accumulator, so we can use that to print
\ these tokens.
\ 
\ (Incidentally, the ex subroutine is what TT27 calls when it has analysed the
\ character code, determined that it is a recursive token, and subtracted 160
\ or added 114 as appropriate to get the token number, so calling it directly
\ with 146-148 in the accumulator is acceptable.)
\ 
\ *****************************************************************************
\ Control codes: {n}
\ *****************************************************************************
\ 
\ Control codes are in the range 0 to 13, and expand to the following when
\ printed via TT27:
\ 
\     0   Current cash, right-aligned to width 9, then " CR", newline
\     1   Current galaxy number, right-aligned to width 3
\     2   Current system name
\     3   Selected system name (the cross-hairs in the short range chart)
\     4   Commander's name
\     5   "FUEL: ", fuel level, " LIGHT YEARS", newline, "CASH:", {0}, newline
\     6   Switch case to Sentence Case
\     7   Beep
\     8   Switch case to ALL CAPS
\     9   Tab to column 21, then print a colon
\     10  Line feed (i.e. move cursor down)
\     11  (not used, does the same as 13)
\     12  (not used, does the same as 13)
\     13  Newline (i.e. carriage return and line feed)
\ 
\ So a value of 4 in a tokenised string will be expanded to the current
\ commander's name, while a value of 5 will print the current fuel level in the
\ format "FUEL: 5.3 LIGHT YEARS", followed by a newline, followed by "CASH: ",
\ and then followed by control code 0, which shows the amount of cash to one
\ significant figure, right-aligned to a width of 9 characters, and finished
\ off with " CR" and another newline. The result is something like this, when
\ displayed in Sentence Case:
\ 
\     Fuel: 6.7 Light Years
\     Cash:    1234.5 Cr
\ 
\ If you press F8 to show the Status Mode screen, you can see control code 4
\ being used to show the commander's name in the title, while control code 5 is
\ responsible for displaying the fuel and cash lines.
\ 
\ When talking about encoded strings in the code comments below, control
\ characters are shown as {n}, so {4} expands to the commander's name and {5}
\ to the current fuel.
\ 
\ By default, Elite prints words using Sentence Case, where the first letter of
\ each word is capitalised. Control code {8} can be used to switch to ALL CAPS
\ (so it acts like Caps Lock), and {6} can be used to switch back to Sentence
\ Case. You can see this in action on the Status Mode screen, where the title
\ and equipment headers are in ALL CAPS, while everything else is in Sentence
\ Case. Tokens are stored in capital letters only, and each letter's case is
\ set by the logic in TT27.
\ 
\ *****************************************************************************
\ Two-letter tokens: <n>
\ *****************************************************************************
\ 
\ Two-letter tokens expand to the following:
\ 
\     128     AL
\     129     LE
\     130     XE
\     131     GE
\     132     ZA
\     133     CE
\     134     BI
\     135     SO
\     136     US
\     137     ES
\     138     AR
\     139     MA
\     140     IN
\     141     DI
\     142     RE
\     143     A?
\     144     ER
\     145     AT
\     146     EN
\     147     BE
\     148     RA
\     149     LA
\     150     VE
\     151     TI
\     152     ED
\     153     OR
\     154     QU
\     155     AN
\     156     TE
\     157     IS
\     158     RI
\     159     ON
\ 
\ So a value of 150 in the tokenised string would expand to VE, for example.
\ When talking about encoded strings in the code comments below, two-letter
\ tokens are shown as <n>, so <150> expands to VE.
\ 
\ The set of two-letter tokens is stored as one long string ("ALLEXEGE...") at
\ QQ16, in the main elite-source.asm. This string is also used to generate
\ planet names procedurally, but that's a story for another time.
\ 
\ Note that question marks are not printed, so token <143> expands to A. This
\ allows names with an odd number of characters to be generated from sequences
\ of two-letter tokens, though only if they contain the letter A.
\ 
\ *****************************************************************************
\ Recursive tokens: [n]
\ *****************************************************************************
\ 
\ The binary file that is assembled by this source file (WORDS9.bin) contains
\ 149 recursive tokens, numbered from 0 to 148, which are stored from &0400 to
\ &06FF in a tokenised form. These tokenised strings can include references to
\ other tokens, hence "recursive".
\ 
\ When talking about encoded strings in the code comments below, recursive
\ tokens are shown as [n], so [111] expands to "FUEL SCOOPS", for example, and
\ [110] expands to "[102][104]S", which in turn expands to "EXTRA BEAM LASERS"
\ (as [102] expands to "EXTRA " and [104] to "BEAM LASER").
\ 
\ The recursive tokens are numbered from 0 to 148, but because we've already
\ reserved codes 0-13 for control characters, 32-95 for ASCII characters and
\ 128-159 for two-letter tokens, we can't just send the token number straight
\ to TT27 to print it out (sending 65 to TT27 prints "A", for example, and not
\ recursive token 65). So instead, we use the table above to work out what to
\ send to TT27; here are the relevant lines:
\ 
\     Value (n)   Type
\     ---------   -------------------------------------------------------
\     14-31       Recursive tokens 128-145 (i.e. token number = n + 114)
\     96-127      Recursive tokens 96-127 (i.e. token number = n)
\     160-255     Recursive tokens 0-95 (i.e. token number = n - 160)
\ 
\ The first column is the number we need to send to TT27 to print the token
\ mentioned in the second column.
\ 
\ So, if we want to print recursive token 132, then according to the first row
\ in this table, we need to subtract 114 to get 18, and send that to TT27.
\ 
\ Meanwhile, if we want to print token 101, then according to the second row,
\ we can just pass that straight through to TT27.
\ 
\ Finally, if we want to print token 3, then according to the third row, we
\ need to add 160 to get 163.
\ 
\ Note that, as described in the section above, you can't use TT27 to print
\ recursive tokens 146-148, but instead you need to call the ex subroutine, so
\ the method described here only applies to recursive tokens 0-145.
\ 
\ *****************************************************************************
\ How recursive tokens are stored in memory
\ *****************************************************************************
\ 
\ The 149 recursive tokens are stored one after the other in memory, starting
\ at &0400, with each token being terminated by a null character (EQUB 0).
\ 
\ To complicate matters, the strings themselves are all EOR'd with 35 before
\ being stored, and this process is repeated when they are read from memory (as
\ EOR is reversible). This is done in the routine at TT50.
\ 
\ Note that if a recursive token contains another recursive token, then that
\ token's number is stored as the number that would be sent to TT27, rather
\ than the number of the token itself.
\ 
\ All of this makes it pretty challenging to work out how one would store a
\ specific token in memory, which is why this file uses a handful of macros to
\ make life easier. They are:
\ 
\     CHAR n      ; insert ASCII character n      n = 32 to 95
\     CTRL n      ; insert control code n         n = 0 to 13
\     TWOK n      ; insert two-letter token n     n = 128 to 159
\     RTOK n      ; insert recursive token n      n = 0 to 148
\ 
\ A side effect of all this obfuscation is that tokenised strings can't contain
\ ASCII 35 characters ("#"). This is because ASCII "#" EOR 35 is 0, and the
\ null character is already used to terminate our tokens in memory, so if you
\ did have a string containing the hash character, it wouldn't print the hash,
\ but would instead terminate at the character before.
\ 
\ Interestingly, there's no lookup table for each recursive token's starting
\ point im memory, as that would take up too much space, so to get hold of the
\ encoded string for a specific recursive token, the print routine runs through
\ the entire list of tokens, character by character, counting all the nulls
\ until it reaches the right spot. This might not be fast, but it is much more
\ space-efficient than a lookup table; you can see this loop in the subroutine
\ at ex, which is where recursive tokens are printed.
\ 
\ *****************************************************************************
\ An example
\ *****************************************************************************
\ 
\ Given all this, let's consider recursive token 3 again, which is printed
\ using the following code (remember, we have to add 160 to 3 to pass through
\ to TT27):
\ 
\     LDA #163
\     JSR TT27
\ 
\ Token 3 is stored in the tokenised form:
\ 
\     D<145>A[131]{3}
\ 
\ which we could store in memory using the following (adding in the null
\ terminator at the end):
\ 
\     CHAR 'D'
\     TWOK 145
\     CHAR 'A'
\     RTOK 131
\     CTRL 3
\     EQUB 0
\ 
\ As mentioned above, the values that are actually stored are EOR'd with 35,
\ and token [131] has to have 114 taken off it before it's ready for TT27, so
\ the bytes that are actually stored in memory for this token are:
\ 
\     EQUB 'D' EOR 35
\     EQUB 145 EOR 35
\     EQUB 'A' EOR 35
\     EQUB (131 - 114) EOR 35
\     EQUB 3 EOR 35
\     EQUB 0
\ 
\ or, as they would appear in the raw WORDS9.bin file, this:
\ 
\     EQUB &67, &B2, &62, &32, &20, &00
\ 
\ These all produce the same output, but the first version is rather easier to
\ understand.
\ 
\ Now that the token is stored in memory, we can call TT27 with the accumulator
\ set to 163, and the token will be printed as follows:
\ 
\     D       The letter D                        "D"
\     <145>   Two-letter token 145                "AT"
\     A       The letter A                        "A"
\     [131]   Recursive token 131                 " ON "
\     {3}     Control character 3                 The selected system name
\ 
\ So if the system under the cross-hairs in the short range chart is Tionisla,
\ this expands into "DATA ON TIONISLA".

\ *****************************************************************************
\ Macros for inserting tokens into memory
\ *****************************************************************************

MACRO CHAR x                        ; Insert ASCII character 'x'
  EQUB x EOR 35
ENDMACRO

MACRO TWOK n                        ; Insert two-letter token <n>
  EQUB n EOR 35
ENDMACRO

MACRO CTRL n                        ; Insert control code {n}
  EQUB n EOR 35
ENDMACRO

MACRO RTOK n                        ; Insert recursive token [n]
  IF n >= 0 AND n <= 95             ; Tokens 0-95 get stored as token number + 160
    EQUB (n + 160) EOR 35
  ELIF n >= 128
    EQUB (n - 114) EOR 35           ; Tokens 128-145 get stored as token number - 114
  ELSE
    EQUB n EOR 35                   ; Tokens 96-127 get stored as token number
  ENDIF
ENDMACRO

\ *****************************************************************************
\ Recursive tokens 0-148
\ *****************************************************************************

RTOK 111                            ; Token 0:      "FUEL SCOOPS ON {beep}"
RTOK 131                            ; Encoded as:   "[111][131]{7}"
CTRL 7
EQUB 0

CHAR ' '                            ; Token 1:      " CHART"
CHAR 'C'                            ; Encoded as:   " CH<138>T"
CHAR 'H'
TWOK 138
CHAR 'T'
EQUB 0

CHAR 'G'                            ; Token 2:      "GOVERNMENT"
CHAR 'O'                            ; Encoded as:   "GO<150>RNM<146>T"
TWOK 150
CHAR 'R'
CHAR 'N'
CHAR 'M'
TWOK 146
CHAR 'T'
EQUB 0

CHAR 'D'                            ; Token 3:      "DATA ON {selected system name}"
TWOK 145                            ; Encoded as:   "D<145>A[131]{3}"
CHAR 'A'
RTOK 131
CTRL 3
EQUB 0

TWOK 140                            ; Token 4:      "INVENTORY{crlf}"
TWOK 150                            ; Encoded as:   "<140><150>NT<153>Y{13}"
CHAR 'N'
CHAR 'T'
TWOK 153
CHAR 'Y'
CTRL 13
EQUB 0

CHAR 'S'                            ; Token 5:      "SYSTEM"
CHAR 'Y'                            ; Encoded as:   "SYS<156>M"
CHAR 'S'
TWOK 156
CHAR 'M'
EQUB 0

CHAR 'P'                            ; Token 6:      "PRICE"
TWOK 158                            ; Encoded as:   "P<158><133>"
TWOK 133
EQUB 0

CTRL 2                              ; Token 7:      "{current system name} MARKET PRICES"
CHAR ' '                            ; Encoded as:   "{2} <139>RKET [6]S"
TWOK 139
CHAR 'R'
CHAR 'K'
CHAR 'E'
CHAR 'T'
CHAR ' '
RTOK 6
CHAR 'S'
EQUB 0

TWOK 140                            ; Token 8:      "INDUSTRIAL"
CHAR 'D'                            ; Encoded as:   "<140>D<136>T<158><128>"
TWOK 136
CHAR 'T'
TWOK 158
TWOK 128
EQUB 0

CHAR 'A'                            ; Token 9:      "AGRICULTURAL"
CHAR 'G'                            ; Encoded as:   "AG<158>CULTU<148>L"
TWOK 158
CHAR 'C'
CHAR 'U'
CHAR 'L'
CHAR 'T'
CHAR 'U'
TWOK 148
CHAR 'L'
EQUB 0

TWOK 158                            ; Token 10:     "RICH "
CHAR 'C'                            ; Encoded as:   "<158>CH "
CHAR 'H'
CHAR ' '
EQUB 0

CHAR 'A'                            ; Token 11:     "AVERAGE "
TWOK 150                            ; Encoded as:   "A<150><148><131> "
TWOK 148
TWOK 131
CHAR ' '
EQUB 0

CHAR 'P'                            ; Token 12:     "POOR "
CHAR 'O'                            ; Encoded as:   "PO<153> "
TWOK 153
CHAR ' '
EQUB 0                              ; Encoded as:   "PO<153> "

TWOK 139                            ; Token 13:     "MAINLY "
TWOK 140                            ; Encoded as:   "<139><140>LY "
CHAR 'L'
CHAR 'Y'
CHAR ' '
EQUB 0

CHAR 'U'                            ; Token 14:     "UNIT"
CHAR 'N'                            ; Encoded as:   "UNIT"
CHAR 'I'
CHAR 'T'
EQUB 0

CHAR 'V'                            ; Token 15:     "VIEW "
CHAR 'I'                            ; Encoded as:   "VIEW "
CHAR 'E'
CHAR 'W'
CHAR ' '
EQUB 0

TWOK 154                            ; Token 16:     "QUANTITY"
TWOK 155                            ; Encoded as:   "<154><155><151>TY"
TWOK 151
CHAR 'T'
CHAR 'Y'
EQUB 0

TWOK 155                            ; Token 17:     "ANARCHY"
TWOK 138                            ; Encoded as:   "<155><138>CHY"
CHAR 'C'
CHAR 'H'
CHAR 'Y'
EQUB 0

CHAR 'F'                            ; Token 18:     "FEUDAL"
CHAR 'E'                            ; Encoded as:   "FEUD<128>"
CHAR 'U'
CHAR 'D'
TWOK 128
EQUB 0

CHAR 'M'                            ; Token 19:     "MULTI-GOVERNMENT"
CHAR 'U'                            ; Encoded as:   "MUL<151>-[2]"
CHAR 'L'
TWOK 151
CHAR '-'
RTOK 2
EQUB 0

TWOK 141                            ; Token 20:     "DICTATORSHIP"
CHAR 'C'                            ; Encoded as:   "<141>CT<145><153>[25]"
CHAR 'T'
TWOK 145
TWOK 153
RTOK 25
EQUB 0

RTOK 91                             ; Token 21:     "COMMUNIST"
CHAR 'M'                            ; Encoded as:   "[91]MUN<157>T"
CHAR 'U'
CHAR 'N'
TWOK 157
CHAR 'T'
EQUB 0

CHAR 'C'                            ; Token 22:     "CONFEDERACY"
TWOK 159                            ; Encoded as:   "C<159>F<152><144>ACY"
CHAR 'F'
TWOK 152
TWOK 144
CHAR 'A'
CHAR 'C'
CHAR 'Y'
EQUB 0

CHAR 'D'                            ; Token 23:     "DEMOCRACY"
CHAR 'E'                            ; Encoded as:   "DEMOC<148>CY"
CHAR 'M'
CHAR 'O'
CHAR 'C'
TWOK 148
CHAR 'C'
CHAR 'Y'
EQUB 0

CHAR 'C'                            ; Token 24:     "CORPORATE STATE"
TWOK 153                            ; Encoded as:   "C<153>P<153><145>E [43]<145>E"
CHAR 'P'
TWOK 153
TWOK 145
CHAR 'E'
CHAR ' '
RTOK 43
TWOK 145
CHAR 'E'
EQUB 0

CHAR 'S'                            ; Token 25:     "SHIP"
CHAR 'H'                            ; Encoded as:   "SHIP"
CHAR 'I'
CHAR 'P'
EQUB 0

CHAR 'P'                            ; Token 26:     "PRODUCT"
CHAR 'R'                            ; Encoded as:   "PRODUCT"
CHAR 'O'
CHAR 'D'
CHAR 'U'
CHAR 'C'
CHAR 'T'
EQUB 0

CHAR ' '                            ; Token 27:     " LASER"
TWOK 149                            ; Encoded as:   " <149>S<144>"
CHAR 'S'
TWOK 144
EQUB 0

CHAR 'H'                            ; Token 28:     "HUMAN COLONIAL"
CHAR 'U'                            ; Encoded as:   "HUM<155> COL<159>I<128>"
CHAR 'M'
TWOK 155
CHAR ' '
CHAR 'C'
CHAR 'O'
CHAR 'L'
TWOK 159
CHAR 'I'
TWOK 128
EQUB 0

CHAR 'H'                            ; Token 29:     "HYPERSPACE "
CHAR 'Y'                            ; Encoded as:   "HYP<144>SPA<133> "
CHAR 'P'
TWOK 144
CHAR 'S'
CHAR 'P'
CHAR 'A'
TWOK 133
CHAR ' '
EQUB 0

CHAR 'S'                            ; Token 30:     "SHORT RANGE CHART"
CHAR 'H'                            ; Encoded as:   "SH<153>T [42][1]"
TWOK 153
CHAR 'T'
CHAR ' '
RTOK 42
RTOK 1
EQUB 0

TWOK 141                            ; Token 31:     "DISTANCE"
RTOK 43                             ; Encoded as:   "<141>[43]<155><133>"
TWOK 155
TWOK 133
EQUB 0

CHAR 'P'                            ; Token 32:     "POPULATION"
CHAR 'O'                            ; Encoded as:   "POPUL<145>I<159>"
CHAR 'P'
CHAR 'U'
CHAR 'L'
TWOK 145
CHAR 'I'
TWOK 159
EQUB 0

CHAR 'G'                            ; Token 33:     "GROSS PRODUCTIVITY"
CHAR 'R'                            ; Encoded as:   "GROSS [26]IVITY"
CHAR 'O'
CHAR 'S'
CHAR 'S'
CHAR ' '
RTOK 26
CHAR 'I'
CHAR 'V'
CHAR 'I'
CHAR 'T'
CHAR 'Y'
EQUB 0

CHAR 'E'                            ; Token 34:     "ECONOMY"
CHAR 'C'                            ; Encoded as:   "EC<159>OMY"
TWOK 159
CHAR 'O'
CHAR 'M'
CHAR 'Y'
EQUB 0

CHAR ' '                            ; Token 35:     " LIGHT YEARS"
CHAR 'L'                            ; Encoded as:   " LIGHT YE<138>S"
CHAR 'I'
CHAR 'G'
CHAR 'H'
CHAR 'T'
CHAR ' '
CHAR 'Y'
CHAR 'E'
TWOK 138
CHAR 'S'
EQUB 0

TWOK 156                            ; Token 36:     "TECH.LEVEL"
CHAR 'C'                            ; Encoded as:   "<156>CH.<129><150>L"
CHAR 'H'
CHAR '.'
TWOK 129
TWOK 150
CHAR 'L'
EQUB 0

CHAR 'C'                            ; Token 37:     "CASH"
CHAR 'A'                            ; Encoded as:   "CASH"
CHAR 'S'
CHAR 'H'
EQUB 0

CHAR ' '                            ; Token 38:     " BILLION"
TWOK 134                            ; Encoded as:   " <134>[118]I<159>"
RTOK 118
CHAR 'I'
TWOK 159
EQUB 0

RTOK 122                            ; Token 39:     "GALACTIC CHART{galaxy number right-aligned to width 3}"
RTOK 1                              ; Encoded as:   "[122][1]{1}"
CTRL 1
EQUB 0

CHAR 'T'                            ; Token 40:     "TARGET LOST"
TWOK 138                            ; Encoded as:   "T<138><131>T LO[43]"
TWOK 131
CHAR 'T'
CHAR ' '
CHAR 'L'
CHAR 'O'
RTOK 43
EQUB 0

RTOK 106                            ; Token 41:     "MISSILE JAMMED"
CHAR ' '                            ; Encoded as:   "[106] JAMM<152>"
CHAR 'J'
CHAR 'A'
CHAR 'M'
CHAR 'M'
TWOK 152
EQUB 0

CHAR 'R'                            ; Token 42:     "RANGE"
TWOK 155                            ; Encoded as:   "R<155><131>"
TWOK 131
EQUB 0

CHAR 'S'                            ; Token 43:     "ST"
CHAR 'T'                            ; Encoded as:   "ST"
EQUB 0

RTOK 16                             ; Token 44:     "QUANTITY OF "
CHAR ' '                            ; Encoded as:   "[16] OF "
CHAR 'O'
CHAR 'F'
CHAR ' '
EQUB 0

CHAR 'S'                            ; Token 45:     "SELL"
CHAR 'E'                            ; Encoded as:   "SE[118]"
RTOK 118
EQUB 0

CHAR ' '                            ; Token 46:     " CARGO{switch to sentence case}"
CHAR 'C'                            ; Encoded as:   " C<138>GO{6}"
TWOK 138
CHAR 'G'
CHAR 'O'
CTRL 6
EQUB 0

CHAR 'E'                            ; Token 47:     "EQUIP"
TWOK 154                            ; Encoded as:   "E<154>IP"
CHAR 'I'
CHAR 'P'
EQUB 0

CHAR 'F'                            ; Token 48:     "FOOD"
CHAR 'O'                            ; Encoded as:   "FOOD"
CHAR 'O'
CHAR 'D'
EQUB 0

TWOK 156                            ; Token 49:     "TEXTILES"
CHAR 'X'                            ; Encoded as:   "<156>X<151>L<137>"
TWOK 151
CHAR 'L'
TWOK 137
EQUB 0

TWOK 148                            ; Token 50:     "RADIOACTIVES"
TWOK 141                            ; Encoded as:   "<148><141>OAC<151><150>S"
CHAR 'O'
CHAR 'A'
CHAR 'C'
TWOK 151
TWOK 150
CHAR 'S'
EQUB 0

CHAR 'S'                            ; Token 51:     "SLAVES"
TWOK 149                            ; Encoded as:   "S<149><150>S"
TWOK 150
CHAR 'S'
EQUB 0

CHAR 'L'                            ; Token 52:     "LIQUOR/WINES"
CHAR 'I'                            ; Encoded as:   "LI<154><153>/W<140><137>"
TWOK 154
TWOK 153
CHAR '/'
CHAR 'W'
TWOK 140
TWOK 137
EQUB 0

CHAR 'L'                            ; Token 53:     "LUXURIES"
CHAR 'U'                            ; Encoded as:   "LUXU<158><137>"
CHAR 'X'
CHAR 'U'
TWOK 158
TWOK 137
EQUB 0

CHAR 'N'                            ; Token 54:     "NARCOTICS"
TWOK 138                            ; Encoded as:   "N<138>CO<151>CS"
CHAR 'C'
CHAR 'O'
TWOK 151
CHAR 'C'
CHAR 'S'
EQUB 0

RTOK 91                             ; Token 55:     "COMPUTERS"
CHAR 'P'                            ; Encoded as:   "[91]PUT<144>S"
CHAR 'U'
CHAR 'T'
TWOK 144
CHAR 'S'
EQUB 0

TWOK 139                            ; Token 56:     "MACHINERY"
CHAR 'C'                            ; Encoded as:   "<139>CH<140><144>Y"
CHAR 'H'
TWOK 140
TWOK 144
CHAR 'Y'
EQUB 0

RTOK 117                            ; Token 57:     "ALLOYS"
CHAR 'O'                            ; Encoded as:   "[117]OYS"
CHAR 'Y'
CHAR 'S'
EQUB 0

CHAR 'F'                            ; Token 58:     "FIREARMS"
CHAR 'I'                            ; Encoded as:   "FI<142><138>MS"
TWOK 142
TWOK 138
CHAR 'M'
CHAR 'S'
EQUB 0

CHAR 'F'                            ; Token 59:     "FURS"
CHAR 'U'                            ; Encoded as:   "FURS"
CHAR 'R'
CHAR 'S'
EQUB 0

CHAR 'M'                            ; Token 60:     "MINERALS"
TWOK 140                            ; Encoded as:   "M<140><144><128>S"
TWOK 144
TWOK 128
CHAR 'S'
EQUB 0

CHAR 'G'                            ; Token 61:     "GOLD"
CHAR 'O'                            ; Encoded as:   "GOLD"
CHAR 'L'
CHAR 'D'
EQUB 0

CHAR 'P'                            ; Token 62:     "PLATINUM"
CHAR 'L'                            ; Encoded as:   "PL<145><140>UM"
TWOK 145
TWOK 140
CHAR 'U'
CHAR 'M'
EQUB 0

TWOK 131                            ; Token 63:     "GEM-STONES"
CHAR 'M'                            ; Encoded as:   "<131>M-[43]<159><137>"
CHAR '-'
RTOK 43
TWOK 159
TWOK 137
EQUB 0

TWOK 128                            ; Token 64:     "ALIEN ITEMS"
CHAR 'I'                            ; Encoded as:   "<128>I<146> [127]S"
TWOK 146
CHAR ' '
RTOK 127
CHAR 'S'
EQUB 0

CHAR '('                            ; Token 65:     "(Y/N)?"
CHAR 'Y'                            ; Encoded as:   "(Y/N)?"
CHAR '/'
CHAR 'N'
CHAR ')'
CHAR '?'
EQUB 0

CHAR ' '                            ; Token 66:     " CR"
CHAR 'C'                            ; Encoded as:   " CR"
CHAR 'R'
EQUB 0

CHAR 'L'                            ; Token 67:     "LARGE"
TWOK 138                            ; Encoded as:   "L<138><131>"
TWOK 131
EQUB 0

CHAR 'F'                            ; Token 68:     "FIERCE"
CHAR 'I'                            ; Encoded as:   "FI<144><133>"
TWOK 144
TWOK 133
EQUB 0

CHAR 'S'                            ; Token 69:     "SMALL"
TWOK 139                            ; Encoded as:   "S<139>[118]"
RTOK 118
EQUB 0

CHAR 'G'                            ; Token 70:     "GREEN"
TWOK 142                            ; Encoded as:   "G<142><146>"
TWOK 146
EQUB 0

CHAR 'R'                            ; Token 71:     "RED"
TWOK 152                            ; Encoded as:   "R<152>"
EQUB 0

CHAR 'Y'                            ; Token 72:     "YELLOW"
CHAR 'E'                            ; Encoded as:   "YE[118]OW"
RTOK 118
CHAR 'O'
CHAR 'W'
EQUB 0

CHAR 'B'                            ; Token 73:     "BLUE"
CHAR 'L'                            ; Encoded as:   "BLUE"
CHAR 'U'
CHAR 'E'
EQUB 0

CHAR 'B'                            ; Token 74:     "BLACK"
TWOK 149                            ; Encoded as:   "B<149>CK"
CHAR 'C'
CHAR 'K'
EQUB 0

RTOK 136                            ; Token 75:     "HARMLESS"
EQUB 0                              ; Encoded as:   "[136]"

CHAR 'S'                            ; Token 76:     "SLIMY"
CHAR 'L'                            ; Encoded as:   "SLIMY"
CHAR 'I'
CHAR 'M'
CHAR 'Y'
EQUB 0

CHAR 'B'                            ; Token 77:     "BUG-EYED"
CHAR 'U'                            ; Encoded as:   "BUG-EY<152>"
CHAR 'G'
CHAR '-'
CHAR 'E'
CHAR 'Y'
TWOK 152
EQUB 0

CHAR 'H'                            ; Token 78:     "HORNED"
TWOK 153                            ; Encoded as:   "H<153>N<152>"
CHAR 'N'
TWOK 152
EQUB 0

CHAR 'B'                            ; Token 79:     "BONY"
TWOK 159                            ; Encoded as:   "B<159>Y"
CHAR 'Y'
EQUB 0

CHAR 'F'                            ; Token 80:     "FAT"
TWOK 145                            ; Encoded as:   "F<145>"
EQUB 0

CHAR 'F'                            ; Token 81:     "FURRY"
CHAR 'U'                            ; Encoded as:   "FURRY"
CHAR 'R'
CHAR 'R'
CHAR 'Y'
EQUB 0

CHAR 'R'                            ; Token 82:     "RODENT"
CHAR 'O'                            ; Encoded as:   "ROD<146>T"
CHAR 'D'
TWOK 146
CHAR 'T'
EQUB 0

CHAR 'F'                            ; Token 83:     "FROG"
CHAR 'R'                            ; Encoded as:   "FROG"
CHAR 'O'
CHAR 'G'
EQUB 0

CHAR 'L'                            ; Token 84:     "LIZARD"
CHAR 'I'                            ; Encoded as:   "LI<132>RD"
TWOK 132
CHAR 'R'
CHAR 'D'
EQUB 0

CHAR 'L'                            ; Token 85:     "LOBSTER"
CHAR 'O'                            ; Encoded as:   "LOB[43]<144>"
CHAR 'B'
RTOK 43
TWOK 144
EQUB 0

TWOK 134                            ; Token 86:     "BIRD"
CHAR 'R'                            ; Encoded as:   "<134>RD"
CHAR 'D'
EQUB 0

CHAR 'H'                            ; Token 87:     "HUMANOID"
CHAR 'U'                            ; Encoded as:   "HUM<155>OID"
CHAR 'M'
TWOK 155
CHAR 'O'
CHAR 'I'
CHAR 'D'
EQUB 0

CHAR 'F'                            ; Token 88:     "FELINE"
CHAR 'E'                            ; Encoded as:   "FEL<140>E"
CHAR 'L'
TWOK 140
CHAR 'E'
EQUB 0

TWOK 140                            ; Token 89:     "INSECT"
CHAR 'S'                            ; Encoded as:   "<140>SECT"
CHAR 'E'
CHAR 'C'
CHAR 'T'
EQUB 0

RTOK 11                             ; Token 90:     "AVERAGE RADIUS"
TWOK 148                            ; Encoded as:   "[11]<148><141><136>"
TWOK 141
TWOK 136
EQUB 0

CHAR 'C'                            ; Token 91:     "COM"
CHAR 'O'                            ; Encoded as:   "COM"
CHAR 'M'
EQUB 0

RTOK 91                             ; Token 92:     "COMMANDER"
CHAR 'M'                            ; Encoded as:   "[91]M<155>D<144>"
TWOK 155
CHAR 'D'
TWOK 144
EQUB 0

CHAR ' '                            ; Token 93:     " DESTROYED"
CHAR 'D'                            ; Encoded as:   " D<137>TROY<152>"
TWOK 137
CHAR 'T'
CHAR 'R'
CHAR 'O'
CHAR 'Y'
TWOK 152
EQUB 0

CHAR 'B'                            ; Token 94:     "BY D.BRABEN & I.BELL"
CHAR 'Y'                            ; Encoded:      "BY D.B<148><147>N & I.<147>[118]"
CHAR ' '
CHAR 'D'
CHAR '.'
CHAR 'B'
TWOK 148
TWOK 147
CHAR 'N'
CHAR ' '
CHAR '&'
CHAR ' '
CHAR 'I'
CHAR '.'
TWOK 147
RTOK 118
EQUB 0

RTOK 14                            ; Token 95:     "UNIT  QUANTITY{crlf} PRODUCT   UNIT PRICE FOR SALE{crlf}{lf}"
CHAR ' '                           ; Encoded as:   "[14]  [16]{13} [26]   [14] [6] F<153> SA<129>{13}{10}"
CHAR ' '
RTOK 16
CTRL 13
CHAR ' '
RTOK 26
CHAR ' '
CHAR ' '
CHAR ' '
RTOK 14
CHAR ' '
RTOK 6
CHAR ' '
CHAR 'F'
TWOK 153
CHAR ' '
CHAR 'S'
CHAR 'A'
TWOK 129
CTRL 13
CTRL 10
EQUB 0

CHAR 'F'                            ; Token 96:     "FRONT"
CHAR 'R'                            ; Encoded as:   "FR<159>T"
TWOK 159
CHAR 'T'
EQUB 0

TWOK 142                            ; Token 97:     "REAR"
TWOK 138                            ; Encoded as:   "<142><138>"
EQUB 0

TWOK 129                            ; Token 98:     "LEFT"
CHAR 'F'                            ; Encoded as:   "<129>FT"
CHAR 'T'
EQUB 0

TWOK 158                            ; Token 99:     "RIGHT"
CHAR 'G'                            ; Encoded as:   "<158>GHT"
CHAR 'H'
CHAR 'T'
EQUB 0

RTOK 121                            ; Token 100:    "ENERGY LOW{beep}"
CHAR 'L'                            ; Encoded as:   "[121]LOW{7}"
CHAR 'O'
CHAR 'W'
CTRL 7
EQUB 0

RTOK 99                             ; Token 101:    "RIGHT ON COMMANDER!"
RTOK 131                            ; Encoded as:   "[99][131][92]!"
RTOK 92
CHAR '!'
EQUB 0

CHAR 'E'                            ; Token 102:    "EXTRA "
CHAR 'X'                            ; Encoded as:   "EXT<148> "
CHAR 'T'
TWOK 148
CHAR ' '
EQUB 0

CHAR 'P'                            ; Token 103:    "PULSE LASER"
CHAR 'U'                            ; Encoded as:   "PULSE[27]"
CHAR 'L'
CHAR 'S'
CHAR 'E'
RTOK 27
EQUB 0

TWOK 147                            ; Token 104:    "BEAM LASER"
CHAR 'A'                            ; Encoded as:   "<147>AM[27]"
CHAR 'M'
RTOK 27
EQUB 0

CHAR 'F'                            ; Token 105:    "FUEL"
CHAR 'U'                            ; Encoded as:   "FUEL"
CHAR 'E'
CHAR 'L'
EQUB 0

CHAR 'M'                            ; Token 106:    "MISSILE"
TWOK 157                            ; Encoded as:   "M<157>SI<129>"
CHAR 'S'
CHAR 'I'
TWOK 129
EQUB 0

RTOK 67                            ; Token 107:    "LARGE CARGO{switch to sentence case} BAY"
RTOK 46                            ; Encoded as:   "[67][46] BAY"
CHAR ' '
CHAR 'B'
CHAR 'A'
CHAR 'Y'
EQUB 0

CHAR 'E'                            ; Token 108:    "E.C.M.SYSTEM"
CHAR '.'                            ; Encoded as:   "E.C.M.[5]"
CHAR 'C'
CHAR '.'
CHAR 'M'
CHAR '.'
RTOK 5
EQUB 0

RTOK 102                            ; Token 109:    "EXTRA PULSE LASERS"
RTOK 103                            ; Encoded as:   "[102][103]S"
CHAR 'S'
EQUB 0

RTOK 102                            ; Token 110:    "EXTRA BEAM LASERS"
RTOK 104                            ; Encoded as:   "[102][104]S"
CHAR 'S'
EQUB 0

RTOK 105                            ; Token 111:    "FUEL SCOOPS"
CHAR ' '                            ; Encoded as:   "[105] SCOOPS"
CHAR 'S'
CHAR 'C'
CHAR 'O'
CHAR 'O'
CHAR 'P'
CHAR 'S'
EQUB 0

TWOK 137                            ; Token 112:    "ESCAPE POD"
CHAR 'C'                            ; Encoded as:   "<137>CAPE POD"
CHAR 'A'
CHAR 'P'
CHAR 'E'
CHAR ' '
CHAR 'P'
CHAR 'O'
CHAR 'D'
EQUB 0

RTOK 121                            ; Token 113:    "ENERGY BOMB"
CHAR 'B'                            ; Encoded as:   "[121]BOMB"
CHAR 'O'
CHAR 'M'
CHAR 'B'
EQUB 0

RTOK 121                            ; Token 114:    "ENERGY UNIT"
RTOK 14                             ; Encoded as:   "[121][14]"
EQUB 0

RTOK 124                            ; Token 115:    "DOCKING COMPUTERS"
TWOK 140                            ; Encoded as:   "[124]<140>G [55]"
CHAR 'G'
CHAR ' '
RTOK 55
EQUB 0

RTOK 122                            ; Token 116:    "GALACTIC HYPERSPACE "
CHAR ' '                            ; Encoded as:   "[122] [29]"
RTOK 29
EQUB 0

CHAR 'A'                            ; Token 117:    "ALL"
RTOK 118                            ; Encoded as:   "A[118]"
EQUB 0

CHAR 'L'                            ; Token 118:    "LL"
CHAR 'L'                            ; Encoded as:   "LL"
EQUB 0

RTOK 37                             ; Token 119:    "CASH:{cash right-aligned to width 9} CR{crlf}"
CHAR ':'                            ; Encoded as:   "[37]:{0}"
CTRL 0
EQUB 0

TWOK 140                            ; Token 120:    "INCOMING MISSILE"
RTOK 91                             ; Encoded as:   "<140>[91]<140>G [106]"
TWOK 140
CHAR 'G'
CHAR ' '
RTOK 106
EQUB 0

TWOK 146                            ; Token 121:    "ENERGY "
TWOK 144                            ; Encoded as:   "<146><144>GY "
CHAR 'G'
CHAR 'Y'
CHAR ' '
EQUB 0

CHAR 'G'                            ; Token 122:    "GALACTIC"
CHAR 'A'                            ; Encoded as:   "GA<149>C<151>C"
TWOK 149
CHAR 'C'
TWOK 151
CHAR 'C'
EQUB 0

CTRL 13                             ; Token 123:    "{crlf}COMMANDER'S NAME? "
RTOK 92                             ; Encoded as:   "{13}[92]'S NAME? "
CHAR 39                             ; CHAR 39 is the apostrophe, which we can't quote
CHAR 'S'
CHAR ' '
CHAR 'N'
CHAR 'A'
CHAR 'M'
CHAR 'E'
CHAR '?'
CHAR ' '
EQUB 0

CHAR 'D'                            ; Token 124:    "DOCK"
CHAR 'O'                            ; Encoded as:   "DOCK"
CHAR 'C'
CHAR 'K'
EQUB 0

CTRL 5                              ; Token 125:    "FUEL: {fuel level} LIGHT YEARS{crlf}CASH:{cash right-aligned to width 9} CR{crlf}LEGAL STATUS:"
TWOK 129                            ; Encoded as:   "{5}<129>G<128> [43]<145><136>:"
CHAR 'G'
TWOK 128
CHAR ' '
RTOK 43
TWOK 145
TWOK 136
CHAR ':'
EQUB 0

RTOK 92                             ; Token 126:    "COMMANDER {commander name}{crlf}{crlf}{crlf}{switch to sentence case}PRESENT SYSTEM{tab to column 21}:{current system name}{crlf}HYPERSPACE SYSTEM{tab to column 21}:{selected system name}{crlf}CONDITION{tab to column 21}:"
CHAR ' '                            ; Encoded as:   "[92] {4}{13}{13}{13}{6}[145] [5]{9}{2}{13}[29][5]{9}{3}{13}C<159><141><151><159>{9}"
CTRL 4
CTRL 13
CTRL 13
CTRL 13
CTRL 6
RTOK 145
CHAR ' '
RTOK 5
CTRL 9
CTRL 2
CTRL 13
RTOK 29
RTOK 5
CTRL 9
CTRL 3
CTRL 13
CHAR 'C'
TWOK 159
TWOK 141
TWOK 151
TWOK 159
CTRL 9
EQUB 0

CHAR 'I'                            ; Token 127:    "ITEM"
TWOK 156                            ; Encoded as:   "I<156>M"
CHAR 'M'
EQUB 0

CHAR ' '                            ; Token 128:    "  LOAD NEW COMMANDER (Y/N)?{crlf}{crlf}"
CHAR ' '                            ; Encoded as:   "  LOAD NEW [92] [65]{13}{13}"
CHAR 'L'
CHAR 'O'
CHAR 'A'
CHAR 'D'
CHAR ' '
CHAR 'N'
CHAR 'E'
CHAR 'W'
CHAR ' '
RTOK 92
CHAR ' '
RTOK 65
CTRL 13
CTRL 13
EQUB 0

CTRL 6                              ; Token 129:    "{switch to sentence case}DOCKED"
RTOK 124                            ; Encoded as:   "{6}[124]<152>"
TWOK 152
EQUB 0

TWOK 148                            ; Token 130:    "RATING:"
TWOK 151                            ; Encoded as:   "<148><151>NG:"
CHAR 'N'
CHAR 'G'
CHAR ':'
EQUB 0

CHAR ' '                            ; Token 131:    " ON "
TWOK 159                            ; Encoded as:   " <159> "
CHAR ' '
EQUB 0

CTRL 13                             ; Token 132:    "{crlf}{switch to all caps}EQUIPMENT:{switch to sentence case}"
CTRL 8                              ; Encoded as:   "{13}{8}[47]M<146>T:{6}"
RTOK 47
CHAR 'M'
TWOK 146
CHAR 'T'
CHAR ':'
CTRL 6
EQUB 0

CHAR 'C'                            ; Token 133:    "CLEAN"
TWOK 129                            ; Encoded as:   "C<129><155>"
TWOK 155
EQUB 0

CHAR 'O'                            ; Token 134:    "OFFENDER"
CHAR 'F'                            ; Encoded as:   "OFF<146>D<144>"
CHAR 'F'
TWOK 146
CHAR 'D'
TWOK 144
EQUB 0

CHAR 'F'                            ; Token 135:    "FUGITIVE"
CHAR 'U'                            ; Encoded as:   "FUGI<151><150>"
CHAR 'G'
CHAR 'I'
TWOK 151
TWOK 150
EQUB 0

CHAR 'H'                            ; Token 136:    "HARMLESS"
TWOK 138                            ; Encoded as:   "H<138>M<129>SS"
CHAR 'M'
TWOK 129
CHAR 'S'
CHAR 'S'
EQUB 0

CHAR 'M'                            ; Token 137:    "MOSTLY HARMLESS"
CHAR 'O'                            ; Encoded as:   "MO[43]LY [136]"
RTOK 43
CHAR 'L'
CHAR 'Y'
CHAR ' '
RTOK 136
EQUB 0

RTOK 12                             ; Token 138:    "POOR "
EQUB 0                              ; Encoded as:   "[12]"

RTOK 11                             ; Token 139:    "AVERAGE "
EQUB 0                              ; Encoded as:   "[11]"

CHAR 'A'                            ; Token 140:    "ABOVE AVERAGE "
CHAR 'B'                            ; Encoded as:   "ABO<150> [11]"
CHAR 'O'
TWOK 150
CHAR ' '
RTOK 11
EQUB 0

RTOK 91                             ; Token 141:    "COMPETENT"
CHAR 'P'                            ; Encoded as:   "[91]PET<146>T"
CHAR 'E'
CHAR 'T'
TWOK 146
CHAR 'T'
EQUB 0

CHAR 'D'                            ; Token 142:    "DANGEROUS"
TWOK 155                            ; Encoded as:   "D<155><131>RO<136>"
TWOK 131
CHAR 'R'
CHAR 'O'
TWOK 136
EQUB 0

CHAR 'D'                            ; Token 143:    "DEADLY"
CHAR 'E'                            ; Encoded as:   "DEADLY"
CHAR 'A'
CHAR 'D'
CHAR 'L'
CHAR 'Y'
EQUB 0

CHAR '-'                            ; Token 144:    "---- E L I T E ----"
CHAR '-'                            ; Encoded as:   "---- E L I T E ----"
CHAR '-'
CHAR '-'
CHAR ' '
CHAR 'E'
CHAR ' '
CHAR 'L'
CHAR ' '
CHAR 'I'
CHAR ' '
CHAR 'T'
CHAR ' '
CHAR 'E'
CHAR ' '
CHAR '-'
CHAR '-'
CHAR '-'
CHAR '-'
EQUB 0

CHAR 'P'                            ; Token 145:    "PRESENT"
TWOK 142                            ; Encoded as:   "P<142>S<146>T"
CHAR 'S'
TWOK 146
CHAR 'T'
EQUB 0

CTRL 8                              ; Token 146:    "{switch to all caps}GAME OVER"
CHAR 'G'                            ; Encoded as:   "{8}GAME O<150>R"
CHAR 'A'
CHAR 'M'
CHAR 'E'
CHAR ' '
CHAR 'O'
TWOK 150
CHAR 'R'
EQUB 0

CHAR 'P'                            ; Token 147:    "PRESS FIRE OR SPACE,COMMANDER.{crlf}{crlf}"
CHAR 'R'                            ; Encoded as:   "PR<137>S FI<142> <153> SPA<133>,[92].{13}{13}"
TWOK 137
CHAR 'S'
CHAR ' '
CHAR 'F'
CHAR 'I'
TWOK 142
CHAR ' '
TWOK 153
CHAR ' '
CHAR 'S'
CHAR 'P'
CHAR 'A'
TWOK 133
CHAR ','
RTOK 92
CHAR '.'
CTRL 13
CTRL 13
EQUB 0

CHAR '('                            ; Token 148:    "(C) ACORNSOFT 1984"
CHAR 'C'                            ; Encoded as:   "(C) AC<153>N<135>FT 1984"
CHAR ')'
CHAR ' '
CHAR 'A'
CHAR 'C'
TWOK 153
CHAR 'N'
TWOK 135
CHAR 'F'
CHAR 'T'
CHAR ' '
CHAR '1'
CHAR '9'
CHAR '8'
CHAR '4'
EQUB 0

\ *****************************************************************************
\ Save recursive tokens as output/WORDS9.bin
\ *****************************************************************************

PRINT "output/WORDS9.bin"
PRINT "ASSEMBLE AT", ~CODE%
PRINT "P%=",~P%
PRINT "CODE SIZE=", ~(P%-CODE%)
PRINT "RELOAD AT ", ~LOAD%

PRINT "S.WORDS9 ",~CODE%," ",~P%," ",~LOAD%," ",~LOAD%

SAVE "output/WORDS9.bin", CODE%, P%, LOAD%, LOAD%
