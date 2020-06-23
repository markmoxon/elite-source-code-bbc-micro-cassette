\ *****************************************************************************
\ ELITE GAME SOURCE
\ *****************************************************************************

INCLUDE "elite-header.h.asm"

_REMOVE_COMMANDER_CHECK = TRUE AND _REMOVE_CHECKSUMS
_ENABLE_MAX_COMMANDER   = TRUE AND _REMOVE_CHECKSUMS

\ *****************************************************************************
\ Workspace pointers
\ *****************************************************************************

ZP = 0                  ; &0000 to &00B0 - Zero page variables, see below for
                        ; details of what is stored here

XX3 = &0100             ; &0100 to &01FF - Used as heap space for storing
                        ; temporary data during calculations; shared with the
                        ; descending 6502 stack, which works down from &01FF

T% = &0300              ; &0300 to &035F - Workspace T%, contains the current
                        ; commander data and the stardust data block

QQ18 = &0400            ; &0400 to &07FF - The recursive token table is loaded
CODE_WORDS% = QQ18      ; at &1100 and is moved down to &0400 as part of
LOAD_WORDS% = &1100     ; elite-loader.asm

K% = &0900              ; &0900 to &0CFF - Workspace K%, pointed to by the
                        ; lookup table at location UNIV, the first 468 bytes
                        ; of which holds data on 13 ships, 36 (NI%) bytes each

WP = &0D40              ; &0D40 to &0F34 - Workspace WP, see below for details
                        ; of what is stored here

CODE% = &0F40           ; &0F40 to &6000 - The main game code is loaded at
LOAD% = &1128           ; &1128 and is moved down to &0F40 as part of
                        ; elite-loader.asm

GUARD &6000             ; Screen buffer starts here

\ *****************************************************************************
\ Configuration variables
\ *****************************************************************************

NOST = 18               ; Maximum number of stardust particles

NOSH = 12               ; Maximum number of ships at any one time

COPS = 2                ; Viper
MAM = 3                 ; Mamba
THG = 6                 ; Thargoid
CYL = 7                 ; Cobra Mk III
SST = 8                 ; Space station
MSL = 9                 ; Missile
AST = 10                ; Asteroid
OIL = 11                ; Container
TGL = 12                ; Thargon
ESC = 13                ; Escape Pod

POW = 15                ; Pulse laser power

NI% = 36                ; Number of bytes for each object in our universe (as
                        ; stored in INWK and pointed to by UNIV)

\ *****************************************************************************
\ MOS definitions
\ *****************************************************************************

OSBYTE = &FFF4
OSWORD = &FFF1
OSFILE = &FFDD
SHEILA = &FE00
VSCAN  = 57
VEC    = &7FFE
SVN    = &7FFD

X = 128                 ; Screen centre
Y = 96

\ *****************************************************************************
\ Function key numbers
\ *****************************************************************************

f0 = &20
f1 = &71
f2 = &72
f3 = &73
f4 = &14
f5 = &74
f6 = &75
f7 = &16
f8 = &76
f9 = &77

\ *****************************************************************************
\ Zero page workspace at &0000 - &00B0
\ *****************************************************************************

ORG ZP

.RAND                   ; 
 SKIP 4

.TRTB%                  ; Set by elite-loader.asm to point to the MOS key
 SKIP 2                 ; translation table, used to translate internal key
                        ; values to ASCII

.T1                     ; Temporary storage, used quite a lot
 SKIP 1

.SC                     ; Screen address (low byte)
 SKIP 1

.SCH                    ; Screen address (high byte)
 SKIP 1

.XX16                   ; 
 SKIP 18

.P                      ; Temporary storage for a memory pointer (e.g. used in
 SKIP 3                 ; TT26 to store the address of character definitions)

.XX0                    ; Stores address of ship definition in NWSHP
 SKIP 2

.INF                    ; Stores address of new ship data block when adding a
 SKIP 2                 ; new ship

.V                      ; 
 SKIP 2

.XX                     ; 
 SKIP 2

.YY                     ; 
 SKIP 2

.SUNX                   ; 
 SKIP 2

.BETA                   ; 
 SKIP 1

.BET1                   ; 
 SKIP 1

.XC                     ; Contains the x-coordinate of the text cursor (i.e.
 SKIP 1                 ; the text column). A value of 0 denotes the leftmost
                        ; column.

.YC                     ; Contains the y-coordinate of the text cursor (i.e.
 SKIP 1                 ; the text row). A value of 0 denotes the top row.

.QQ22                   ; Hyperspace countdown
 SKIP 2

.ECMA                   ; E.C.M. status flag; 0 is off, non-zero is on
 SKIP 1

.XX15                   ; Shares location with X1, Y1, X2, Y2

.X1
 SKIP 1

.Y1
 SKIP 1

.X2
 SKIP 1

.Y2
 SKIP 1

 SKIP 2                 ; Last 2 bytes of XX15

.XX12                   ; 
 SKIP 6

.K                      ; 
 SKIP 4

.KL                     ; If a key is being pressed that is not in the keyboard
 SKIP 1                 ; table at KYTB, it can be stored here (as seen in
                        ; routine DK4, for example)

                        ; The following bytes implement a key logger that
                        ; enables Elite to scan for concurrent key presses of
                        ; all the flight keys (so this effectively implements
                        ; a 15-key rollover for the flight keys listed in the
                        ; keyboard table at KYTB, enabling players to roll,
                        ; pitch, change speed and fire lasers at the same, all
                        ; while targeting missiles and setting off their E.C.M.
                        ; and energy bomb, without the keyboard ignoring them).
                        ; The various keyboard canning routines, such as the one
                        ; at DKS1, can set the relevant byte in this table to
                        ; &FF to denote that that particular key is being
                        ; pressed. The logger is cleared to zero (no keys are
                        ; being pressed) by the U% routine.

.KY1                    ; ? key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY2                    ; Space key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY3                    ; < key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY4                    ; > key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY5                    ; X key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY6                    ; S key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY7                    ; A key pressed (0 = no, non-zero = yes)
 SKIP 1                 ; Also, joystick fire button pressed

.KY12                   ; Tab key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY13                   ; Escape key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY14                   ; T key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY15                   ; U key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY16                   ; M key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY17                   ; E key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY18                   ; J key pressed (0 = no, non-zero = yes)
 SKIP 1

.KY19                   ; C key pressed (0 = no, non-zero = yes)
 SKIP 1

.LAS                    ; 
 SKIP 1

.MSTG                   ; Missile target (&FF = no target)
 SKIP 1

.XX1
 
.INWK                   ; Shares memory with XX1, XX19
 SKIP NI%               ; Workspace for a ship

                        ; x-coordinate = (INWK+1 INWK+0), sign in INWK+2
                        ; y-coordinate = (INWK+4 INWK+3), sign in INWK+5
                        ; y-coordinate = (INWK+7 INWK+6), sign in INWK+8
                        ;
                        ;                   (rotmat0x rotmat0y rotmat0z)
                        ; Rotation matrix = (rotmat1x rotmat1y rotmat1z)
                        ;                   (rotmat2x rotmat2y rotmat2z)
                        ;
                        ;                   (INWK+10,9  INWK+12,11 INWK+14,13)
                        ;                 = (INWK+16,15 INWK+18,17 INWK+20,19)
                        ;                   (INWK+22,21 INWK+24,23 INWK+26,25)
                        ;
                        ;                   (0    0  &E0)   (0  0 -1)
                        ; Zero'd in ZINF to (0   &60   0) = (0  1  0)
                        ;                   (&60  0    0)   (1  0  0)
                        ;
                        ; &60 (96) is the figure we use to represent 1 in the
                        ; rotation matrix, while &E0 9224) is -1

                        ; INWK    = x_lo
                        ; INWK+1  = x_hi
                        ; INWK+2  = x_sign
                        ; INWK+3  = y_lo
                        ; INWK+4  = y_hi
                        ; INWK+5  = y_sign
                        ; INWK+6  = z_lo
                        ; INWK+7  = z_hi
                        ; INWK+8  = z_sign
                        ; INWK+9  = rotmat0x_lo
                        ; INWK+10 = rotmat0x_hi     xincrot_hi
                        ; INWK+11 = rotmat0y_lo
                        ; INWK+12 = rotmat0y_hi     yincrot_hi
                        ; INWK+13 = rotmat0z_lo
                        ; INWK+14 = rotmat0z_hi     zincrot_hi
                        ; INWK+15 = rotmat1x_lo
                        ; INWK+16 = rotmat1x_hi
                        ; INWK+17 = rotmat1y_lo
                        ; INWK+18 = rotmat1y_hi
                        ; INWK+19 = rotmat1z_lo
                        ; INWK+20 = rotmat1z_hi
                        ; INWK+21 = rotmat2x_lo
                        ; INWK+22 = rotmat2x_hi
                        ; INWK+23 = rotmat2y_lo
                        ; INWK+24 = rotmat2y_hi
                        ; INWK+25 = rotmat2z_lo
                        ; INWK+26 = rotmat2z_hi
                        ; INWK+27 = speed (32 = quite fast)
                        ; INWK+28 = acceleration
                        ; INWK+29 = rotx counter, 127 = no damping, damps roll
                        ; INWK+30 = rotz counter, 127 = no damping, damps pitch
                        ; INWK+31 = exploding/display state, or missile count
                        ; INWK+32 = ai counter, ai_attack_univ_ecm
                        ;           bit6 set = missile attacking player
                        ;           &FF = ai attack everyone, has ecm
                        ;           1 = ai and ecm
                        ; INWK+33 = ship lines heap space pointer lo
                        ; INWK+34 = ship lines heap space pointer hi
                        ; INWK+35 = ship energy

XX19 = INWK + 33        ; Shares memory with INWK+33

.LSP                    ; 
 SKIP 1

.QQ15                   ; Contains the three 16-bit seeds (6 bytes) for the
 SKIP 6                 ; selected system, i.e. the one in the cross-hairs in
                        ; the short range chart.
                        ;
                        ; The seeds are stored as little-endian 16-bit numbers,
                        ; so the low (least significant) byte is first followed
                        ; by the high (most significant) byte. That means if
                        ; the seeds are w0, w1 and w2, they are stored like
                        ; this:
                        ;
                        ;       low byte  high byte
                        ;   w0  QQ15      QQ15+1
                        ;   w1  QQ15+2    QQ15+3
                        ;   w2  QQ15+4    QQ15+5
                        ;
                        ; In this documentation, we denote the low byte of w0
                        ; as w0_lo and the high byte as w0_hi, and so on for
                        ; w1_lo, w1_hi, w2_lo and w2_hi.

.XX18                   ; Shares memory with QQ17, QQ19
 SKIP 9

QQ17 = XX18             ; Shares memory with XX18, K5
                        ;
                        ; QQ17 stores flags that affect how text tokens are
                        ; printed, including the capitalisation setting
                        ;
                        ; Setting QQ17 = &FF disables text printing entirely
                        ;
                        ; Otherwise:
                        ;
                        ; Bit 7 = 0 means ALL CAPS
                        ; Bit 7 = 1 means Sentence Case, bit 6 determines case
                        ;           of next letter to print
                        ;
                        ; Bit 6 = 0 means print the next letter in upper case
                        ; Bit 6 = 1 means print the next letter in lower case
                        ;
                        ; So:
                        ;
                        ; QQ17 = 0   (%0000 0000) means case is set to ALL CAPS
                        ; QQ17 = 128 (%1000 0000) means Sentence Case,
                        ;                         currently printing upper case
                        ; QQ17 = 192 (%1100 0000) means Sentence Case,
                        ;                         currently printing lower case
                        ;
                        ; If any of bits 0-5 are set and QQ17 is not &FF, we
                        ; print in lower case

QQ19 = QQ17 + 1         ; Shares memory with XX18+1, K5
                        ;
                        ; Temporary storage for seed pairs (e.g. used in cpl
                        ; as a temporary backup when twisting three 16-bit
                        ; seeds)

K5 = XX18               ; Shares memory with XX18, QQ17, QQ19

K6 = K5 + 4             ; Shares memory with XX18+4

.ALP1                   ; Roll?
 SKIP 1

.ALP2                   ; Roll sign?
 SKIP 2

.BET2                   ; Pitch sign?
 SKIP 2

.DELTA                  ; Current speed
 SKIP 1

.DELT4                  ; 
 SKIP 2

.U                      ; Temporary storage (e.g. used in BPRNT to store the
 SKIP 1                 ; last position at which we must start printing digits)

.Q                      ; 
 SKIP 1

.R                      ; 
 SKIP 1

.S                      ; Temporary storage (e.g. used in BPRNT)
 SKIP 1

.XSAV                   ; Temporary storage for X
 SKIP 1

.YSAV                   ; Temporary storage for Y (e.g. used in TT27)
 SKIP 1

.XX17                   ; Temporary storage (e.g. used in BPRNT to store the
 SKIP 1                 ; number of characters to print)

.QQ11                   ; Current view (0 = space view)
 SKIP 1

.ZZ                     ; 
 SKIP 1

.XX13                   ; 
 SKIP 1

.MCNT                   ; Move counter
 SKIP 1

.DL                     ; Line scan counter. This is updated
 SKIP 1

.TYPE                   ; 
 SKIP 1

.JSTX                   ; Current rate of roll being applied by the controls
 SKIP 1                 ; (as shown in the dashboard's RL indicator), ranging
                        ; from 1 to 255 with 128 as the centre point (so 1
                        ; means roll is decreasing at the maximum rate, 128
                        ; means roll is not changing, and 255 means roll is
                        ; increasing at the maximum rate)

.JSTY                   ; Current rate of pitch being applied by the controls
 SKIP 1                 ; (as shown in the dashboard's DC indicator), ranging
                        ; from 1 to 255 with 128 as the centre point (so 1
                        ; means pitch is decreasing at the maximum rate, 128
                        ; means pitch is not changing, and 255 means pitch is
                        ; increasing at the maximum rate)

.ALPHA                  ; 
 SKIP 1

.QQ12                   ; Docked flag, &FF = docked
 SKIP 1

.TGT                    ; 
 SKIP 1

.SWAP                   ; 
 SKIP 1

.COL                    ; 
 SKIP 1

.FLAG                   ; 
 SKIP 1

.CNT                    ; 
 SKIP 1

.CNT2                   ; 
 SKIP 1

.STP                    ; 
 SKIP 1

.XX4                    ; 
 SKIP 1

.XX20                   ; 
 SKIP 1

.XX14                   ; 
 SKIP 1

.RAT                    ; 
 SKIP 1

.RAT2                   ; 
 SKIP 1

.K2                     ; 
 SKIP 4

T = &D1                 ; Used as temporary storage (e.g. used in cpl for the
                        ; loop counter)

XX2 = &D2               ; Shares memory with K3, K4

K3 = XX2                ; Shares memory with XX2
                        ;
                        ; Used as temporary storage (e.g. used in TT27 for the
                        ; character to print)

K4 = K3 + 14            ; Shares memory with XX2+14
                        ;
                        ; Used as temporary storage (e.g. used in TT27 for the
                        ; character to print)

PRINT "Zero page variables from ", ~ZP, " to ", ~P%

\ *****************************************************************************
\ Workspace at T% = &300 - &035F
\
\ Contains the current commander data (NT% bytes at location TP), and the
\ stardust data block (NOST bytes at location SX)
\ *****************************************************************************

ORG T%                  ; Start of the commander block

.TP                     ; Mission status, always 0 for tape version
 SKIP 1

.QQ0                    ; Current system X-coordinate
 SKIP 1

.QQ1                    ; Current system Y-coordinate
 SKIP 1

.QQ21                   ; Three 16-bit seeds for current system
 SKIP 6

.CASH                   ; Cash as a 32-bit unsigned integer
 SKIP 4

.QQ14                   ; Contains the current fuel level * 10 (so a 1 in QQ14
 SKIP 1                 ; represents 0.1 light years)

.COK                    ; Competition code flags
 SKIP 1                 ;
                        ; Bit 7 is set on start-up if CHK and CHK2 do not match,
                        ; which presumably indicates that there may have been
                        ; some cheatimg going on
                        ;
                        ; Bit 1 is set on start-up
                        ;
                        ; Bit 0 is set in routine ptg if player holds X during
                        ; hyperspace to force a mis-jump (having first paused
                        ; the game and toggled on the author credits with X)

.GCNT                   ; Contains the current galaxy number, 0-7. When this is
 SKIP 1                 ; displayed in-game, 1 is added to the number (so we
                        ; start in galaxy 1 in-game, but it's stored as galaxy
                        ; 0 internally)

.LASER                  ; Laser power, 0 means no laser
 SKIP 4                 ; (byte 0 = front, 1 = rear, 2 = left, 3 = right)

 SKIP 2                 ; Not used (reserved for up/down lasers, maybe?)
 
.CRGO                   ; Cargo capacity
 SKIP 1

.QQ20                   ; Contents of cargo hold
 SKIP 17

.ECM                    ; E.C.M.
 SKIP 1

.BST                    ; Fuel scoops ("barrel status")
 SKIP 1

.BOMB                   ; Energy bomb
 SKIP 1

.ENGY                   ; Energy/shield level
 SKIP 1

.DKCMP                  ; Docking computer
 SKIP 1

.GHYP                   ; Galactic hyperdrive
 SKIP 1

.ESCP                   ; Escape pod
 SKIP 1

 SKIP 4                 ; Not used

.NOMSL                  ; Number of missiles
 SKIP 1

.FIST                   ; Legal status ("fugitive/innocent status")
 SKIP 1

.AVL                    ; Market availability
 SKIP 17

.QQ26                   ; Random byte that changes for each visit to a system,
 SKIP 1                 ; for randomising market prices

.TALLY                  ; Number of kills
 SKIP 2

.SVC                    ; Save count, gets halved with each save
 SKIP 1

 SKIP 2                 ; Reserve two bytes for commander checksum, so when
                        ; current commander block is copied to the last saved
                        ; commnder block at NA%, CHK and CHK2 get overwritten

NT% = SVC + 2 - TP      ; Set to the size of the commander block, which starts
                        ; at T% (&300) and goes to SVC+3

SX = P%                 ; SX points to the stardust data block, which is NOST
                        ; bytes (NOST = "number of stars")

SXL = SX + NOST + 1     ; SXL points to the end of the stardust data block

PRINT "T% workspace from  ", ~T%, " to ", ~SXL

\ *****************************************************************************
\ ELITE WORDS SOURCE
\ *****************************************************************************

ORG CODE_WORDS%

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
\   Value (n)     Type
\   ---------     -------------------------------------------------------
\   0-13          Control codes 0-13
\   14-31         Recursive tokens 128-145 (i.e. token number = n + 114)
\   32-95         Normal ASCII characters 32-95 (0-9, A-Z and most punctuation)
\   96-127        Recursive tokens 96-127 (i.e. token number = n)
\   128-159       Two-letter tokens 128-159
\   160-255       Recursive tokens 0-95 (i.e. token number = n - 160)
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
\   {n}           Control codes             n = 0 to 13
\   <n>           Two-letter token          n = 128 to 159
\   [n]           Recursive token           n = 0 to 148
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
\   LDA #65
\   JSR TT27
\ 
\ prints a capital A, while this code:
\ 
\   LDA #163
\   JSR TT27
\ 
\ prints recursive token number 3 (see below for more on why we pass #163
\ instead of #3). This would produce the following if we were currently
\ visiting Tionisla:
\ 
\   DATA ON TIONISLA
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
\   0   Current cash, right-aligned to width 9, then " CR", newline
\   1   Current galaxy number, right-aligned to width 3
\   2   Current system name
\   3   Selected system name (the cross-hairs in the short range chart)
\   4   Commander's name
\   5   "FUEL: ", fuel level, " LIGHT YEARS", newline, "CASH:", {0}, newline
\   6   Switch case to Sentence Case
\   7   Beep
\   8   Switch case to ALL CAPS
\   9   Tab to column 21, then print a colon
\   10  Line feed (i.e. move cursor down)
\   11  (not used, does the same as 13)
\   12  (not used, does the same as 13)
\   13  Newline (i.e. carriage return and line feed)
\ 
\ So a value of 4 in a tokenised string will be expanded to the current
\ commander's name, while a value of 5 will print the current fuel level in the
\ format "FUEL: 5.3 LIGHT YEARS", followed by a newline, followed by "CASH: ",
\ and then followed by control code 0, which shows the amount of cash to one
\ significant figure, right-aligned to a width of 9 characters, and finished
\ off with " CR" and another newline. The result is something like this, when
\ displayed in Sentence Case:
\ 
\   Fuel: 6.7 Light Years
\   Cash:    1234.5 Cr
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
\   128     AL
\   129     LE
\   130     XE
\   131     GE
\   132     ZA
\   133     CE
\   134     BI
\   135     SO
\   136     US
\   137     ES
\   138     AR
\   139     MA
\   140     IN
\   141     DI
\   142     RE
\   143     A?
\   144     ER
\   145     AT
\   146     EN
\   147     BE
\   148     RA
\   149     LA
\   150     VE
\   151     TI
\   152     ED
\   153     OR
\   154     QU
\   155     AN
\   156     TE
\   157     IS
\   158     RI
\   159     ON
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
\   Value (n)     Type
\   ---------     -------------------------------------------------------
\   14-31         Recursive tokens 128-145 (i.e. token number = n + 114)
\   96-127        Recursive tokens 96-127 (i.e. token number = n)
\   160-255       Recursive tokens 0-95 (i.e. token number = n - 160)
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
\   CHAR n        ; insert ASCII character n        n = 32 to 95
\   CTRL n        ; insert control code n           n = 0 to 13
\   TWOK n        ; insert two-letter token n       n = 128 to 159
\   RTOK n        ; insert recursive token n        n = 0 to 148
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
\   LDA #163
\   JSR TT27
\ 
\ Token 3 is stored in the tokenised form:
\ 
\   D<145>A[131]{3}
\ 
\ which we could store in memory using the following (adding in the null
\ terminator at the end):
\ 
\   CHAR 'D'
\   TWOK 145
\   CHAR 'A'
\   RTOK 131
\   CTRL 3
\   EQUB 0
\ 
\ As mentioned above, the values that are actually stored are EOR'd with 35,
\ and token [131] has to have 114 taken off it before it's ready for TT27, so
\ the bytes that are actually stored in memory for this token are:
\ 
\   EQUB 'D' EOR 35
\   EQUB 145 EOR 35
\   EQUB 'A' EOR 35
\   EQUB (131 - 114) EOR 35
\   EQUB 3 EOR 35
\   EQUB 0
\ 
\ or, as they would appear in the raw WORDS9.bin file, this:
\ 
\   EQUB &67, &B2, &62, &32, &20, &00
\ 
\ These all produce the same output, but the first version is rather easier to
\ understand.
\ 
\ Now that the token is stored in memory, we can call TT27 with the accumulator
\ set to 163, and the token will be printed as follows:
\ 
\   D             The letter D                      "D"
\   <145>         Two-letter token 145              "AT"
\   A             The letter A                      "A"
\   [131]         Recursive token 131               " ON "
\   {3}           Control character 3               The selected system name
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
\ Save output/WORDS9.bin
\ *****************************************************************************

PRINT "WORDS9"
PRINT "Assembled at ", ~CODE_WORDS%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_WORDS%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_WORDS%

PRINT "S.WORDS9 ",~CODE%," ",~P%," ",~LOAD%," ",~LOAD_WORDS%
SAVE "output/WORDS9.bin", CODE_WORDS%, P%, LOAD%

\ *****************************************************************************
\ Workspace at WP = &0D40 - &0F34
\ *****************************************************************************

ORG WP

.FRIN                   ; Contains the ship type for each of the ships in UNIV
 SKIP NOSH + 1          ; (0 means that slot is empty)

.MANY                   ; Shares memory with CABTMP, SSPR
 SKIP 14                ; Contains a count of the number of ships of type X at
                        ; offset X, so the current number of Sidewinders in our
                        ; bubble of universe is at MANY+1, the number of Mambas
                        ; is at MANY+2, and so on

CABTMP = MANY           ; Shares memory with MANY

SSPR = MANY + SST       ; Shares memory with MANY
                        ;
                        ; "Space station present" flag
                        ;
                        ; Non-zero if we are inside the space station safe zone
                        ;
                        ; 0 if we aren't (in which case we can show the sun)

.ECMP                   ; 
 SKIP 1

.MJ                     ; 
 SKIP 1

.LAS2                   ; 
 SKIP 1

.MSAR                   ; 
 SKIP 1

.VIEW                   ; 
 SKIP 1

.LASCT                  ; 
 SKIP 1

.GNTMP                  ; 
 SKIP 1

.HFX                    ; 
 SKIP 1

.EV                     ; 
 SKIP 1

.DLY                    ; 
 SKIP 1

.de                     ; 
 SKIP 1

.LSO                    ; Shares memory with LSX
 SKIP 192

LSX = LSO               ; Shares memory with LSO

.LSX2                   ; 
 SKIP 78

.LSY2                   ; 
 SKIP 78

.SY                     ; 
 SKIP NOST + 1

.SYL                    ; 
 SKIP NOST + 1

.SZ                     ; 
 SKIP NOST + 1

.SZL                    ; 
 SKIP NOST + 1

.XSAV2                  ; Temporary storage for the X register (e.g. used in
 SKIP 1                 ; TT27 to store X while printing is performed)

.YSAV2                  ; Temporary storage for the Y register (e.g. used in
 SKIP 1                 ; TT27 to store X while printing is performed)

.MCH                    ; 
 SKIP 1

.FSH                    ; Forward shields
 SKIP 1

.ASH                    ; Aft shields
 SKIP 1

.ENERGY                 ; Energy banks
 SKIP 1

.LASX                   ; 
 SKIP 1

.LASY                   ; 
 SKIP 1

.COMX                   ; 
 SKIP 1

.COMY                   ; 
 SKIP 1

.QQ24                   ; 
 SKIP 1

.QQ25                   ; 
 SKIP 1

.QQ28                   ; 
 SKIP 1

.QQ29                   ; 
 SKIP 1

.gov                    ; 
 SKIP 1

.tek                    ; 
 SKIP 1

.SLSP                   ; Points to the start of the ship lines heap space,
 SKIP 2                 ; which is a block that starts at SLSP and ends at
                        ; WP, and which can be extended downwards by lowering
                        ; SLSP if more heap space is required

.XX24                   ; 
 SKIP 1

.ALTIT                  ; 
 SKIP 1

.QQ2                    ; Contains the three 16-bit seeds (6 bytes) for the
 SKIP 6                 ; current system. See QQ15 above for details of how the
                        ; three seeds are stored in memory

.QQ3                    ; Selected system's economy (0-7)
 SKIP 1

.QQ4                    ; Selected system's government (0-7)
 SKIP 1

.QQ5                    ; Selected system's tech level (1-14)
 SKIP 1

.QQ6                    ; Selected system's population * 10 in billions (1-71)
 SKIP 2

.QQ7                    ; Selected system's productivity in M CR (96-62480)
 SKIP 2

.QQ8                    ; Distance to the selected system (0 if this is the
 SKIP 2                 ; current system)

.QQ9                    ; Selected system's X-coordinate
 SKIP 1

.QQ10                   ; Selected system's Y-coordinate
 SKIP 1

.NOSTM                  ; Number of stardust particles
 SKIP 1

PRINT "WP workspace from  ", ~WP," to ", ~P%

\ *****************************************************************************
\ ELITE A
\ *****************************************************************************

ORG CODE%
LOAD_A% = LOAD%

.S%
 EQUW TT170             ; Entry point for Elite game; once the main code has
                        ; been loaded, decrypted and moved to the right place
                        ; by elite-loader.asm, the game is started by a
                        ; JMP (S%) instruction, which jumps to the main entry
                        ; point TT170 via this location

 EQUW TT26              ; WRCHV is set to point here by elite-loader.asm

 EQUW IRQ1              ; IRQ1V is set to point here by elite-loader.asm

 EQUW BR1               ; BRKV is set to point here by elite-loader.asm

.COMC                   ; Compass colour, &F0 = in front, &FF = behind
 EQUB 0

.DNOIZ                  ; Sound on/off, 0 = on, non-zero = off
 EQUB 0                 ; Toggled by S when paused, see DK4

.DAMP                   ; Keyboard damping, 0 = no, &FF = yes
 EQUB 0                 ; Toggled by Caps Lock when paused, see DKS3

.DJD                    ; Keyboard auto-recentre, 0 = no, &FF = yes
 EQUB 0                 ; Toggled by A when paused, see DKS3

.PATG                   ; Display authors on start-up screen, 0 = no, &FF = yes
 EQUB 0                 ;
                        ; Toggled by X when paused, see DKS3
                        ;
                        ; This needs to be set to &FF for manual mis-jumps to
                        ; be possible; to do a manual mis-jump, first toggle
                        ; the author display by pausing the game (Copy) and
                        ; pressing X, and then hold down CTRL during the next
                        ; hyperspace to force a mis-jump; see routine ee5 for
                        ; the "AND PATG" instruction that implements this

.FLH                    ; Flashing console bars, 0 = no, &FF = yes
 EQUB 0                 ; Toggled by F when paused, see DKS3

.JSTGY                  ; Reverse joystick Y channel, 0 = no, &FF = yes
 EQUB 0                 ; Toggled by Y when paused, see DKS3

.JSTE                   ; Reverse both joystick channels, 0 = no, &FF = yes
 EQUB 0                 ; Toggled by J when paused, see DKS3

.JSTK                   ; Keyboard or joystick, 0 = keyboard, &FF = joystick
 EQUB 0                 ; Toggled by K when paused, see DKS3

\ *****************************************************************************
\ Subroutine: M%
\
\ Read keyboard for flight controls
\ *****************************************************************************

.M%
{
 LDA K%
 STA RAND
 LDX JSTX
 JSR cntr
 JSR cntr
 TXA
 EOR #128
 TAY
 AND #128
 STA ALP2
 STX JSTX
 EOR #128
 STA ALP2+1
 TYA
 BPL P%+7
 EOR #&FF
 CLC
 ADC #1
 LSR A
 LSR A
 CMP #8
 BCS P%+4
 LSR A
 CLC
 STA ALP1
 ORA ALP2
 STA ALPHA

 LDX JSTY
 JSR cntr
 TXA
 EOR #128
 TAY
 AND #128
 STX JSTY
 STA BET2+1
 EOR #128
 STA BET2
 TYA
 BPL P%+4
 EOR #&FF
 ADC #4
 LSR A
 LSR A
 LSR A
 LSR A
 CMP #3
 BCS P%+3
 LSR A
 STA BET1
 ORA BET2
 STA BETA

 LDA KY2                ; Is Space key being pressed?
 BEQ MA17               ; If not, jump to MA17
 LDA DELTA              ; Speed-up key is being pressed, so speed up
 CMP #40
 BCS MA17
 INC DELTA

.MA17
 LDA KY1                ; Is ? key being pressed?
 BEQ MA4                ; If not, jump to MA4
 DEC DELTA              ; Slow-down key is being pressed, so slow down
 BNE MA4                ; speed done
 INC DELTA              ; speed back to 1

.MA4                    ; speed done
 LDA KY15               ; key 'U' unarm missile
 AND NOMSL              ; number of missiles
 BEQ MA20               ; check target a missile
 LDY #&EE               ; Green
 JSR ABORT              ; draw missile block
 LDA #40                ; warning
 JSR NOISE

.MA31                   ; disarm missile
 LDA #0                 ; missile disarmed
 STA MSAR               ; missiles are armed

.MA20                   ; check target a missile
 LDA MSTG               ; = #&FF if missile NOT targeted
 BPL MA25               ; missile has target, can fire
 LDA KY14               ; key 'T' target missile
 BEQ MA25               ; ignore, can fire
 LDX NOMSL              ; number of missiles
 BEQ MA25               ; ignore, can fire
 STA MSAR               ; #&FF to arm missile and allow possile hitch
 LDY #&E0               ; Yellow
 JSR MSBAR              ; draw missile bar

.MA25                   ; ignore T being hit, can fire missile
 LDA KY16               ; key 'M' for launch missile
 BEQ MA24               ; missile not fired
 LDA MSTG               ; #&FF if missile NOT targeted
 BMI MA64               ; no target, skip a few key tests to check dock C key
 JSR FRMIS              ; Fire missile

.MA24                   ; missile not fired
 LDA KY12               ; tab key
 BEQ MA76               ; none, onto docking
 ASL BOMB               ; *=2  &7F => &FE

.MA76                   ; docking
 LDA KY13               ; auto docking
 AND ESCP
 BEQ P%+5
 JMP ESCAPE
 LDA KY18
 BEQ P%+5
 JSR WARP
 LDA KY17
 AND ECM
 BEQ MA64
 LDA ECMA
 BNE MA64
 DEC ECMP
 JSR ECBLB2

.MA64                   ; check dock C key
 LDA KY19               ; key 'C' docking computer
 AND DKCMP              ; have a docking computer?
 AND SSPR
 BEQ MA68
 LDA K%+NI%+32
 BMI MA68
 JMP GOIN

.MA68                   ; onto Laser
 LDA #0                 ; Laser power per pulse
 STA LAS
 STA DELT4              ; dust speed lo
 LDA DELTA              ; speed
 LSR A                  ; speed/2
 ROR DELT4
 LSR A
 ROR DELT4
 STA DELT4+1            ; hi, speed/4

 LDA LASCT              ; laser count =9 for pulse, cooled off?
 BNE MA3                ; skip laser
 LDA KY7                ; key 'A' fire laser
 BEQ MA3                ; skip laser
 LDA GNTMP              ; gun temperature
 CMP #242               ; overheated
 BCS MA3                ; skip laser
 LDX VIEW               ; index for laser mount
 LDA LASER,X
 BEQ MA3                ; skip as no laser
 PHA                    ; store laser info
 AND #127               ; laser power
 STA LAS
 STA LAS2
 LDA #0                 ; laser fire
 JSR NOISE
 JSR LASLI              ; laser lines
 PLA                    ; restore laser sign
 BPL ma1
 LDA #0                 ; military or beam reset quick

.ma1
 AND #&FA               ; gives 9 for pulse, 0 for beam
 STA LASCT              ; laser count =9 for pulse

.MA3                    ; skip laser
 LDX #0
}

\ *****************************************************************************
\ Subroutine: MAL1
\
\ Moving things?
\ *****************************************************************************

.MAL1                   ; Counter X slot for each nearby ship
{
 STX XSAV               ; save nearby slot
 LDA FRIN,X             ; nearby ship type
 BNE P%+5               ; skip exit
 JMP MA18               ; exit, onto check Your ship
 STA TYPE               ; nearby ship type
 JSR GINF               ; get INF pointer for ship X from UNIV.

 LDY #(NI%-1)           ; counter, last byte of inwk for ship

.MAL2                   ; counter Y
 LDA (INF),Y            ; load ship's univ data into inwk
 STA INWK,Y             ; inner workspace
 DEY                    ; next byte
 BPL MAL2               ; loop Y
 LDA TYPE
 BMI MA21               ; planet or sun, move it
 ASL A                  ; build hull pointer
 TAY                    ; type*2
 LDA XX21-2,Y           ; get ship file entry into
 STA XX0                ; hull pointer lo
 LDA XX21-1,Y           ; hi
 STA XX0+1              ; hull pointer hi

 LDA BOMB
 BPL MA21               ; it didn't go off, planet sun move it.
 CPY #2*SST             ; is type space station
 BEQ MA21               ; bomb going off had no effect, move it.
 LDA INWK+31            ; display|missiles explosion state
 AND #32                ; bit5 is already exploding
 BNE MA21               ; bomb had no effect, move it.
 LDA INWK+31
 ORA #128               ; set bit7 to Kill ship with debris
 STA INWK+31
 JSR EXNO2              ; faint death noise, player killed ship.

.MA21                   ; planet or sun, move it
 JSR MVEIT              ; move it
 LDY #(NI%-1)

.MAL3                   ; counter Y
 LDA INWK,Y             ; store inwk back to ship's univ data
 STA (INF),Y
 DEY                    ; next byte
 BPL MAL3               ; loop Y

 LDA INWK+31            ; display|missiles explosion state
 AND #&A0               ; kill with debris or already exploding
 JSR MAS4               ; all hi or'd
 BNE MA65               ; ignore as far away, or already killed, exploding.
 LDA INWK               ; x coordinate lo
 ORA INWK+3             ; z coordinate lo
 ORA INWK+6             ; z coordinate lo
 BMI MA65               ; ignore as far away, Try targetting missile
 LDX TYPE               ; nearby ship type
 BMI MA65               ; ignore as sun/planet
 CPX #SST               ; is #SST space station
 BEQ ISDK               ; is docking
 AND #&C0               ; else Back to INWK lo bit6 for scooping
 BNE MA65               ; ignore as far away, Try targetting missile
 CPX #MSL               ; missile
 BEQ MA65               ; ignore as missile

 CPX #OIL
 BCS P%+5
 JMP MA58
 LDA BST                ; fuel scoops Barrel status
 AND INWK+5             ; y coordinate sign +ve?
 BPL MA58               ; Big collision, down, as cargo is above
 LDA #3
 CPX #TGL
 BCC oily               ; scoop canister below
 BNE slvy2
 LDA #16
 BNE slvy2              ; guaranteed to hop to pieces to scoop

.oily                   ; scoop cannister
 JSR DORND              ; do random, new A, X.
 AND #7                 ; 7 choices to scoop, computers max.

.slvy2                  ; pieces to scoop
 STA QQ29
 LDA #1
 JSR tnpr               ; ton count, Acc = item becomes Acc = 1
 LDY #78                ; noise, not used
 BCS MA59               ; Scooping failed, below
 LDY QQ29               ; cargo item
 ADC QQ20,Y             ; cargo counts
 STA QQ20,Y
 TYA                    ; scooped item
 ADC #208               ; token = FOOD .. GEM-STONES
 JSR MESS               ; message

 JMP MA60

.MA65                   ; ignored as far away
 JMP MA26               ; Try targeting missile, down.
}

\ *****************************************************************************
\ Subroutine: ISDK
\
\ Process docking with space station
\ *****************************************************************************

.ISDK                   ; is docking to SST nearby
{
 LDA K%+NI%+32          ; UNIV #SST last byte NEWB,  K%+NI%+36
 BMI MA62               ; Failed dock
 LDA INWK+14            ; rotmat0z hi, face normal
 CMP #&D6               ; z_unit  -ve &56 to -ve &60, 26 degrees.
 BCC MA62               ; Failed dock
 JSR SPS4               ; XX15 vector to planet
 LDA XX15+2             ; z_unit away from planet
 BMI MA62               ; Failed dock
 CMP #89                ; < #&60 ?
 BCC MA62               ; Failed dock
 LDA INWK+16            ; rotmat1x hi, slit roll
 AND #&7F               ; clear sign
 CMP #80                ; < #&60 ?
 BCC MA62               ; Failed dock
}

.GOIN                   ; do Dock entry, escape pod arrives
{
 LDA #0
 STA QQ22+1
 LDA #8                 ; octagon rings
 JSR LAUN               ; Launch rings from space station
 JSR RES4               ; Restore forward, aft shields, and energy
 JMP BAY                ; In Docking Bay
}

.MA62                   ; Failed dock
{
 LDA DELTA              ; speed
 CMP #5                 ; < 5?
 BCC MA67               ; slow enough, only damage to player.
 JMP DEATH              ; else death
}

\ *****************************************************************************
\ Subroutine: MA59
\
\ Scooping failed
\ *****************************************************************************

.MA59                   ; Scooping failed
{
 JSR EXNO3              ; ominous noises
}

.MA60                   ; kill it
{
 ASL INWK+31            ; display|missiles explosion state
 SEC                    ; set bit7 to kill it with debris
 ROR INWK+31

.MA61
 BNE MA26               ; guaranteed, onto Try targeting missile.
}

.MA67                   ; slow enough, damage to player
{
 LDA #1                 ; slow speed
 STA DELTA
 LDA #5                 ; small dent
 BNE MA63               ; guaranteed, little Oops.
}

.MA58                   ; Big Collision, cargo destroyed.
{
 ASL INWK+31            ; display|missiles explosion state
 SEC                    ; set bit to kill it with debris
 ROR INWK+31
 LDA INWK+35            ; Energy of nearby ship
 SEC                    ; damage to player is
 ROR A                  ; dent = 128+energy/2
}

.MA63                   ; little Oops
{
 JSR OOPS               ; Lose some shield strength, cargo, could die.
 JSR EXNO3              ; ominous noises
}

.MA26                   ; Try targeting missile, several arrive to continue.
{
 LDA QQ11               ; NEWB bit 7 remove ship?
 BNE MA15               ; no skip scan
 JSR PLUT               ; inwk not forward view

 JSR HITCH              ; Carry set if ship collides or missile locks.
 BCC MA8                ; else just Draw object
 LDA MSAR               ; hitched, is missile already armed?
 BEQ MA47               ; onto laser lock
 JSR BEEP               ; missile found a target
 LDX XSAV               ; nearby ship slot id becomes missile target
 LDY #&E                ; missile red
 JSR ABORT2             ; missile found a target
}

\ *****************************************************************************
\ Subroutine: MA47
\
\ Laser lock, fighting, altitude checks, fuel scooping
\ *****************************************************************************

.MA47                   ; onto laser lock
{
 LDA LAS                ; Laser power
 BEQ MA8                ; no laser, just draw object
 LDX #15                ; distance far
 JSR EXNO               ; explosion noise distance X
 LDA INWK+35
 SEC
 SBC LAS
 BCS MA14

 LDA TYPE               ; ship type hit
 CMP #SST               ; is Space Station?
 BEQ MA14+2             ; visit angry
 LDA INWK+31
 ORA #128
 STA INWK+31
 BCS MA8
 JSR DORND
 BPL oh
 LDY #0
 AND (XX0),Y
 STA CNT

.um
 BEQ oh
 LDX #OIL
 LDA #0
 JSR SFS1
 DEC CNT
 BPL um

.oh
 JSR EXNO2

.MA14                   ; also Survived
 STA INWK+35            ; update ship energy
 LDA TYPE               ; ship type
 JSR ANGRY
}

.MA8                    ; else just Draw object
{
 JSR LL9                ; object ENTRY
}

.MA15                   ; maybe Remove ship, legal affect
{
 LDY #35                ; hull byte#35
 LDA INWK+35            ; ship energy
 STA (INF),Y            ; update

 LDA INWK+31            ; display|missiles explosion state
 BPL MAC1               ; maybe far away, else bit7 set, kill with debris
 AND #&20               ; is bit5 set, explosion finished?
 BEQ NBOUN              ; maybe far away. Else #&A0, explosion done, you killed it.
 LDA TYPE       
 CMP #COPS              ; was victim a cop? 
 BNE q2         
 LDA FIST
 ORA #64                ; fugitative/innocent status
 STA FIST

.q2
 LDA DLY                ; delay printing as cash updating will scramble text
 ORA MJ                 ; mis-jump
 BNE KS1S               ; just Kill ship, else display bounty.
 LDY #10                ; hull byte#10 bounty lo
 LDA (XX0),Y
 BEQ KS1S               ; just Kill ship1 if multiple of 25.6 Cr
 TAX                    ; cash lo
 INY                    ; hull byte#11 bounty hi
 LDA (XX0),Y
 TAY                    ; cash hi
 JSR MCASH              ; more cash, add Xlo.Yhi to cash
 LDA #0                 ; token =0, print player cash
 JSR MESS               ; message

.KS1S                   ; Kill ship1
 JMP KS1                ; Kill ship1

.NBOUN

.MAC1                   ; maybe far away
 LDA TYPE               ; ship type
 BMI MA27               ; planet
 JSR FAROF              ; carry cleared
 BCC KS1S               ; up, kill ship1 as far away.

.MA27                   ; ship is near, or planet.
 LDY #31                ; (INF)#31 state|missiles explosion state
 LDA INWK+31            ; display|missiles explosion state
 STA (INF),Y            ; allwk state updated
 LDX XSAV               ; nearby ship slot count
 INX                    ; next nearby ship
 JMP MAL1               ; loop X
}

.MA18                   ; check Your ship
{
 LDA BOMB
 BPL MA77               ; no working bomb
 ASL BOMB               ; else &FE -> & FC still on.
 JSR WSCAN              ; Wait for line scan, ie whole frame completed.
 LDA #&30               ; colour, logical 0(011) set to actual 0000. white vertical bars
 STA SHEILA+&21         ; Sheila+&21

.MA77                   ; no working bomb
 LDA MCNT               ; move count
 AND #7
 BNE MA22               ; skip updates
 LDX ENERGY             ; players energy
 BPL b                  ; recharge energy only if <50%
 LDX ASH                ; else recharge aft shield
 JSR SHD                ; shield recover
 STX ASH
 LDX FSH                ; forward shield
 JSR SHD                ; shield recover
 STX FSH

.b                      ; recharge energy
 SEC
 LDA ENGY               ; energy unit recharge rate
 ADC ENERGY             ; player's energy
 BCS P%+5               ; overflowed
 STA ENERGY

 LDA MJ                 ; witchspace mis-jump
 BNE MA23S              ; skip to big distance, else regular space
 LDA MCNT               ; move count
 AND #31
 BNE MA93               ; skip space station check at #31
 LDA SSPR               ; space station present
 BNE MA23S              ; if true, skip to big distance
 TAY                    ; = 0 outside S-range
 JSR MAS2               ; or'd x,y,z coordinate of &902+Y to Acc, Y=planet.
 BNE MA23S              ; skip to planet big distance, else build space station as planet is close.

 LDX #28                ; planet 0 up to 28, dont need rot counters or state.

.MAL4                   ; counter X
 LDA K%,X               ; planet coordinates
 STA INWK,X             ; template for space station
 DEX
 BPL MAL4               ; loop X
 INX                    ; Xreg =0
 LDY #9                 ; offset x coord with x inc
 JSR MAS1               ; add 2*INWK(Y+0to1) to INWK(0to2+X)
 BNE MA23S              ; Acc = xsg7, too big, skip to big distance
 LDX #3
 LDY #11                ; offset y coord with y inc
 JSR MAS1               ; add 2*INWK(Y+0to1) to INWK(0to2+X)
 BNE MA23S              ; Acc = ysg7, too big, skip to big distance
 LDX #6
 LDY #13                ; offset z coord with z inc
 JSR MAS1               ; add 2*INWK(Y+0to1) to INWK(0to2+X)
 BNE MA23S              ; Acc = zsg7, too big, skip to big distance

 LDA #&C0
 JSR FAROF2             ; carry clear if hi > #&C0
 BCC MA23S              ; skip to big distance, else close enough to planet to

 LDA QQ11
 BNE P%+5
 JSR WPLS               ; wipe sun
 JSR NWSPS              ; New space station at INWK, S bulb appears.

.MA23S                  ; jmp MA23 as big distance or mis-jump
 JMP MA23               ; big distance

.MA22                   ; arrived from above when checking own ship and skipped updates.
 LDA MJ                 ; mis-jump
 BNE MA23               ; to MA23 big distance or mis-jump
 LDA MCNT               ; move count
 AND #31

.MA93                   ; skipped space station check arrives here
 CMP #10                ; every MCNT tenth
 BNE MA29               ; skip altitude checks
 LDA #50                ; player's energy low?
 CMP ENERGY
 BCC P%+6               ; skip message
 ASL A                  ; #&64 token =  ENERGY LOW
 JSR MESS               ; message
 LDY #&FF               ; Altimeter set to max
 STY ALTIT
 INY                    ; Y = 0 is planet info
 JSR m                  ; max of x,y,z of Yreg=0 planet
 BNE MA23               ; skip to big distance
 JSR MAS3               ; get hsb distance squared of &900+Y = planet
 BCS MA23               ; skip to big distance
 SBC #&24               ; 6^2 = planet radius^2
 BCC MA28               ; death, Crashed into planet.
 STA R                  ; else update altimeter
 JSR LL5                ; Q = SQR(Qlo.Rhi)
 LDA Q
 STA ALTIT
 BNE MA23               ; big distance, else

.MA28                   ; death, Crashed into planet
 JMP DEATH

.MA29                   ; skipped altitude checks earlier
 CMP #20                ; every MCNT=20
 BNE MA23               ; skip to big distance, else check on Sun
 LDA #30                ; default cabin temperature
 STA CABTMP
 LDA SSPR               ; space station present
 BNE MA23               ; skip to big distance, as sun not present.
 LDY #NI%               ; #NI% is offset to Sun info
 JSR MAS2               ; find max of &902 x,y,z coordinate, Sun.
 BNE MA23               ; skip to big distance
 JSR MAS3               ; get hsb distance squared of &900+Y to Sun
 EOR #&FF               ; flip
 ADC #30
 STA CABTMP
 BCS MA28               ; up to Death, too hot.

 CMP #&E0               ; close enough to sun?
 BCC MA23               ; skip to big distance
 LDA BST                ; fuel scoops Barrel status
 BEQ MA23               ; skip to big distance
 LDA DELT4+1            ; hi, speed/4, 10 max
 LSR A                  ; speed/8 is fuel scooped
 ADC QQ14               ; ship fuel
 CMP #70                ; max fuel allowed #70 = #&46
 BCC P%+4               ; not full
 LDA #70                ; max fuel allowed #70 = #&46
 STA QQ14
 LDA #160               ; token = FUEL SCOOPS ON
 JSR MESS               ; message

.MA23                   ; big distance, many arrive here to continue.
 LDA LAS2
 BEQ MA16               ; already switched laser Off
 LDA LASCT              ; laser count
 CMP #8                 ; reached 8 for pulse laser
 BCS MA16               ; laser off
 JSR LASLI2             ; stops drawing laser lines early for pulse laser
 LDA #0                 ; counter reached 8
 STA LAS2               ; so pulse laser doesn't restart

.MA16                   ; already switched laser Off
 LDA ECMP               ; ECM on is player's?
 BEQ MA69               ; ecm finished
 JSR DENGY              ; else drain energy by 1 for active ECM pulse
 BEQ MA70               ; no energy, ecm off.

.MA69                   ; ecm finished
 LDA ECMA               ; someone's ECM active?
 BEQ MA66               ; skip ecm off
 DEC ECMA               ; ECM on counter was started at #32
 BNE MA66               ; skip ecm off

.MA70                   ; ecm off
 JSR ECMOF

.MA66                   ; skipped ecm off
 LDA QQ11               ; menu i.d.
 BNE MA9                ; not a space view, rts
 JMP STARS              ; Dust Field
}

\ *****************************************************************************
\ Subroutine: MAS1
\
\ Add 2*INWK(0to1+Y) to INWK(0to2+X), add x inc to x coord etc.
\ *****************************************************************************

.MAS1                   ; Add 2*INWK(0to1+Y) to INWK(0to2+X), add x inc to x coord etc.
{
 LDA INWK,Y             ; lo
 ASL A                  ; 2*lo
 STA K+1
 LDA INWK+1,Y           ; hi
 ROL A                  ; 2*hi
 STA K+2
 LDA #0
 ROR A                  ; carry into bit7 is
 STA K+3                ; sign of inc
 JSR MVT3               ; add INWK(0to2+X) to K(1to3) X = 0, 3, 6
 STA INWK+2,X           ; sg
 LDY K+1                ; coord lo
 STY INWK,X             ; INWK+0,X
 LDY K+2                ; coord hi
 STY INWK+1,X
 AND #127               ; Acc = big distance sg lower7
}

.MA9
{
 RTS
}

\ *****************************************************************************
\ Subroutine: m
\
\ Max of x,y,z of &902+Y
\ *****************************************************************************

.m                      ; max of x,y,z of &902+Y
{
 LDA #0
}

.MAS2                   ; or'd x,y,z coordinate of &902+Y
{
 ORA K%+2,Y             ; xsg
 ORA K%+5,Y             ; ysg
 ORA K%+8,Y             ; zsg
 AND #127               ; Acc is sg7 distance
 RTS
}

\ *****************************************************************************
\ Subroutine: MAS3
\
\ Find hsb squared of &901+Y
\ *****************************************************************************

.MAS3                   ; find hsb squared of &901+Y
{
 LDA K%+1,Y             ; xhi
 JSR SQUA2              ; P.A =A*A unsigned
 STA R
 LDA K%+4,Y             ; yhi
 JSR SQUA2              ; P.A =A*A unsigned
 ADC R
 BCS MA30               ; sat #&FF
 STA R
 LDA K%+7,Y             ; zhi
 JSR SQUA2              ; P.A =A*A unsigned
 ADC R                  ; Acc = z^2 + y^2 + x^2
 BCC P%+4

.MA30                   ; sat #&FF
 LDA #&FF
 RTS
}

\ *****************************************************************************
\ Subroutine: MVEIT
\
\ Move ship/planet/object
\ *****************************************************************************

.MVEIT                  ; Move It, data in INWK and hull XXX0
{
 LDA INWK+31            ; exploding/display state|missiles
 AND #&A0               ; kill or in explosion?
 BNE MV30               ; Dumb ship or exploding

 LDA MCNT               ; move count
 EOR XSAV               ; nearby ship slot
 AND #15                ; only tidy ship if slot survives
 BNE MV3                ; else skip tidy
 JSR TIDY               ; re-orthogonalize rotation matrix

.MV3                    ; skipped tidy
 LDX TYPE               ; ship type
 BPL P%+5               ; not planet
 JMP MV40               ; else, move Planet.
 LDA INWK+32            ; ai_attack_univ_ecm
 BPL MV30               ; Dumb ship
 CPX #MSL
 BEQ MV26               ; missile done every mcnt

 LDA MCNT               ; move count
 EOR XSAV               ; nearby ship slot
 AND #7                 ; else tactics only needed every 8
 BNE MV30               ; Dumb ship

.MV26                   ; missile done every mcnt
 JSR TACTICS

.MV30                   ; Dumb ship or exploding
 JSR SCAN               ; erase inwk ship on scanner

 LDA INWK+27            ; speed
 ASL A
 ASL A                  ; *=4 speed
 STA Q
 LDA INWK+10
 AND #127               ; x_inc/2 hi
 JSR FMLTU              ; x_inc*speed/256unsg
 STA R
 LDA INWK+10
 LDX #0                 ; x_inc/2 hi
 JSR MVT1-2             ; use Abit7 for x+=R

 LDA INWK+12
 AND #127               ; y_inc/2 hi
 JSR FMLTU              ; y_inc*speed/256unsg
 STA R
 LDA INWK+12
 LDX #3                 ; y_inc/2 hi
 JSR MVT1-2             ; use Abit7 for y+=R
 LDA INWK+14
 AND #127               ; z_inc/2 hi
 JSR FMLTU              ; z_inc*speed/256unsg
 STA R
 LDA INWK+14
 LDX #6                 ; z_inc/2 hi
 JSR MVT1-2             ; use Abit7 for z+=R

 LDA INWK+27
 CLC                    ; update speed with
 ADC INWK+28            ; accel used for 1 frame
 BPL P%+4               ; keep speed +ve
 LDA #0                 ; cant go -ve
 LDY #15                ; hull byte#15 is max speed
 CMP (XX0),Y
 BCC P%+4               ; else clamp speed to hull max
 LDA (XX0),Y
 STA INWK+27            ; speed

 LDA #0                 ; accel was used for 1 frame
 STA INWK+28

 LDX ALP1               ; roll mag lower7 bits
 LDA INWK
 EOR #&FF               ; flip xlo
 STA P
 LDA INWK+1             ; xhi
 JSR MLTU2-2            ; AP(2)= AP* alp1_unsg(EOR P)
 STA P+2
 LDA ALP2+1             ; flipped roll sign
 EOR INWK+2             ; xsg
 LDX #3                 ; y_shift
 JSR MVT6               ; P(1,2) += inwk,x (A is protected but with new sign)

 STA K2+3               ; sg for Y-aX
 LDA P+1
 STA K2+1
 EOR #&FF               ; flip
 STA P
 LDA P+2
 STA K2+2;              ; K2=Y-aX \ their comment \ Yinwk corrected for alpha roll

 LDX BET1               ; pitch mag lower7 bits
 JSR MLTU2-2            ; AP(2)= AP* bet1_unsg(EOR P)
 STA P+2
 LDA K2+3
 EOR BET2               ; pitch sign
 LDX #6                 ; z_shift
 JSR MVT6               ; P(1,2) += inwk,x (A is protected but with new sign)
 STA INWK+8             ; zsg
 LDA P+1
 STA INWK+6             ; zlo
 EOR #&FF               ; flip
 STA P
 LDA P+2
 STA INWK+7             ; zhi \ Z=Z+bK2 \ their comment

 JSR MLTU2              ; AP(2)= AP* Qunsg(EOR P) \ Q = speed
 STA P+2
 LDA K2+3
 STA INWK+5             ; ysg
 EOR BET2               ; pitch sign
 EOR INWK+8             ; zsg
 BPL MV43               ; +ve zsg
 LDA P+1
 ADC K2+1
 STA INWK+3             ; ylo
 LDA P+2
 ADC K2+2
 STA INWK+4             ; yhi
 JMP MV44               ; roll&pitch continue

.MV43                   ; +ve ysg zsg
 LDA K2+1
 SBC P+1
 STA INWK+3             ; ylo
 LDA K2+2
 SBC P+2
 STA INWK+4             ; yhi
 BCS MV44               ; roll&pitch continue
 LDA #1                 ; ylo flipped
 SBC INWK+3
 STA INWK+3
 LDA #0                 ; any carry into yhi
 SBC INWK+4
 STA INWK+4
 LDA INWK+5
 EOR #128               ; flip ysg
 STA INWK+5             ; ysg \ Y=K2-bZ \ their comment

.MV44                   ; roll&pitch continue
 LDX ALP1               ; roll mag lower7 bits
 LDA INWK+3
 EOR #&FF               ; flip ylo
 STA P
 LDA INWK+4             ; yhi
 JSR MLTU2-2            ; AP(2)= AP* alp1_unsg(EOR P)
 STA P+2
 LDA ALP2               ; roll sign
 EOR INWK+5             ; ysg
 LDX #0                 ; x_shift
 JSR MVT6               ; P(1,2) += inwk,x (A is protected but with new sign)
 STA INWK+2             ; xsg
 LDA P+2
 STA INWK+1             ; xhi
 LDA P+1
 STA INWK               ; X=X+aY \ their comment
}

.MV45                   ; move inwk by speed
{
 LDA DELTA              ; speed
 STA R
 LDA #128               ; force inc sign to be -ve
 LDX #6                 ; z_shift
 JSR MVT1               ; Add R|sgnA to inwk,x+0to2
 LDA TYPE               ; ship type
 AND #&81               ; sun bits
 CMP #&81               ; is sun?
 BNE P%+3
 RTS                    ; Z=Z-d \ their comment

.notsun                 ; All except Suns
 LDY #9                 ; select row
 JSR MVS4               ; pitch&roll update to rotmat
 LDY #15
 JSR MVS4               ; pitch&roll update to rotmat
 LDY #21
 JSR MVS4               ; pitch&roll update to rotmat
 LDA INWK+30            ; rotz counter
 AND #128               ; rotz sign
 STA RAT2
 LDA INWK+30
 AND #127               ; pitch mag lower 7bits
 BEQ MV8                ; rotz=0, Other rotation.
 CMP #127               ; C set if equal, no damping of pitch
 SBC #0                 ; reduce z pitch, rotz
 ORA RAT2               ; reinclude rotz sign
 STA INWK+30            ; rotz counter

 LDX #15                ; select column
 LDY #9                 ; select row
 JSR MVS5               ; moveship5, small rotation in matrix
 LDX #17
 LDY #11
 JSR MVS5
 LDX #19
 LDY #13
 JSR MVS5

.MV8                    ; Other rotation, roll.
 LDA INWK+29            ; rotx counter
 AND #128               ; rotx sign
 STA RAT2
 LDA INWK+29            ; rotx counter
 AND #127               ; roll mag lower 7 bits
 BEQ MV5                ; rotations Done
 CMP #127               ; C set if equal, no damping of x roll
 SBC #0                 ; reduce x roll
 ORA RAT2               ; reinclude sign
 STA INWK+29            ; rotx counter

 LDX #15                ; select column
 LDY #21                ; select row
 JSR MVS5               ; moveship5, small rotation in matrix
 LDX #17
 LDY #23
 JSR MVS5
 LDX #19
 LDY #25
 JSR MVS5

.MV5                    ; rotations Done
 LDA INWK+31            ; display explosion state|missiles
 AND #&A0               ; do kill at end of explosion
 BNE MVD1               ; end explosion
 LDA INWK+31
 ORA #16                ; else keep visible on scanner, set bit4.
 STA INWK+31
 JMP SCAN               ; ships inwk on scanner

.MVD1                   ; end explosion
 LDA INWK+31
 AND #&EF               ; clear bit4, now invisible.
 STA INWK+31
 RTS

 AND #128               ; use Abit7 for x+=R
}

.MVT1                   ; Add Rlo.Ahi.sg to inwk,x+0to2 ship translation
{
 ASL A                  ; bit7 into carry
 STA S                  ; A6to0
 LDA #0
 ROR A                  ; sign bit from Acc
 STA T
 LSR S                  ; A6to0
 EOR INWK+2,X
 BMI MV10               ; -ve sg eor T
 LDA R                  ; lo
 ADC INWK,X
 STA INWK,X
 LDA S                  ; hi
 ADC INWK+1,X
 STA INWK+1,X
 LDA INWK+2,X
 ADC #0                 ; sign bit from Acc
 ORA T
 STA INWK+2,X
 RTS

.MV10                   ; -ve sg eor T
 LDA INWK,X             ; INWK+0,X
 SEC                    ; lo sub
 SBC R
 STA INWK,X
 LDA INWK+1,X
 SBC S                  ; hi
 STA INWK+1,X
 LDA INWK+2,X
 AND #127               ; keep far
 SBC #0                 ; any carry
 ORA #128               ; sign
 EOR T
 STA INWK+2,X
 BCS MV11               ; rts

 LDA #1                 ; else need to flip sign
 SBC INWK,X
 STA INWK,X
 LDA #0                 ; hi
 SBC INWK+1,X
 STA INWK+1,X
 LDA #0                 ; sg
 SBC INWK+2,X
 AND #127               ; keep far
 ORA T
 STA INWK+2,X

.MV11
 RTS                    ; MVT1 done
}

.MVT3                   ; add INWK(0to2+X) to K(1to3) X = 0, 3, 6
{
 LDA K+3
 STA S
 AND #128               ; sign only
 STA T
 EOR INWK+2,X
 BMI MV13               ; sg -ve
 LDA K+1
 CLC                    ; add lo
 ADC INWK,X
 STA K+1
 LDA K+2                ; hi
 ADC INWK+1,X
 STA K+2
 LDA K+3                ; sg
 ADC INWK+2,X
 AND #127
 ORA T                  ; sign only
 STA K+3
 RTS

.MV13                   ; sg -ve
 LDA S
 AND #127               ; keep 7 bits
 STA S
 LDA INWK,X
 SEC                    ; sub lo
 SBC K+1
 STA K+1
 LDA INWK+1,X
 SBC K+2                ; hi
 STA K+2
 LDA INWK+2,X
 AND #127
 SBC S
 ORA #128               ; set bit7
 EOR T                  ; sign only
 STA K+3                ; sg
 BCS MV14               ; rts

 LDA #1                 ; else need to flip sign
 SBC K+1                ; lo
 STA K+1
 LDA #0                 ; hi
 SBC K+2
 STA K+2
 LDA #0                 ; sg
 SBC K+3
 AND #127
 ORA T                  ; sign only
 STA K+3

.MV14                   ; rts
 RTS                    ; MVT3 done
}

\ *****************************************************************************
\ Subroutine: MVS4
\
\ Moveship4, pitch and roll calculation
\ *****************************************************************************

\ roll alpha=a pitch beta=b, z in direction of travel, y is vertical. 
\ [    ca    sa   0  ]    [ 1 a   0]      [x]    [x + ay       ]
\ [ -sa.cb ca.cb -sb ] -> [- a 1 -b]   so [y] -> [y - ax  -bz  ]
\ [ -sa.sb ca.sb  cb ]    [-ab b  1]      [z]    [z + b(y - ax)]

.MVS4                   ; Moveship4, Y is matrix row, pitch&roll update to coordinates
 LDA ALPHA
 STA Q                  ; player ship's roll
 LDX INWK+2,Y
 STX R                  ; lo
 LDX INWK+3,Y
 STX S                  ; hi
 LDX INWK,Y
 STX P                  ; over-written
 LDA INWK+1,Y
 EOR #128               ; flip sign
 JSR MAD                ; X.A = alpha*INWK+1,Y + INWK+2to3,Y
 STA INWK+3,Y           ; hi
 STX INWK+2,Y           ; Y=Y-aX \ their comment
 STX P

 LDX INWK,Y
 STX R                  ; lo
 LDX INWK+1,Y
 STX S                  ; hi
 LDA INWK+3,Y
 JSR MAD                ; X.A = alpha*INWK+3,Y + INWK+0to1,Y
 STA INWK+1,Y           ; hi
 STX INWK,Y             ; X=X+aY \ their comment
 STX P

 LDA BETA
 STA Q                  ; player ship's pitch
 LDX INWK+2,Y
 STX R                  ; lo
 LDX INWK+3,Y
 STX S                  ; lo
 LDX INWK+4,Y
 STX P                  ; hi
 LDA INWK+5,Y
 EOR #128               ; flip sign hi
 JSR MAD                ; X.A =-beta*INWK+5,Y + INWK+2to3,Y
 STA INWK+3,Y           ; hi
 STX INWK+2,Y           ; Y=Y-bZ \ their comment
 STX P

 LDX INWK+4,Y
 STX R                  ; lo
 LDX INWK+5,Y
 STX S                  ; hi
 LDA INWK+3,Y
 JSR MAD                ; X.A = beta*INWK+3,Y + INWK+4,5,Y
 STA INWK+5,Y           ; hi
 STX INWK+4,Y           ; Z=Z+bY \ their comment
 RTS                    ; MVS4 done

\ *****************************************************************************
\ Subroutine: MVS5
\
\ Moveship5, small rotation in matrix (1-1/2/256 = cos  1/16 = sine)
\ *****************************************************************************

.MVS5                   ; Moveship5, small rotation in matrix (1-1/2/256 = cos  1/16 = sine)
{
 LDA INWK+1,X
 AND #127               ; hi7
 LSR A                  ; hi7/2
 STA T
 LDA INWK,X
 SEC                    ; lo
 SBC T
 STA R                  ; Xindex one is 1-1/512
 LDA INWK+1,X
 SBC #0                 ; hi
 STA S
 LDA INWK,Y
 STA P                  ; Prepare to divide Yindex one by 16
 LDA INWK+1,Y
 AND #128               ; sign bit
 STA T
 LDA INWK+1,Y
 AND #127               ; hi7
 LSR A                  ; hi7/2
 ROR P                  ; lo
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P                  ; divided by 16
 ORA T                  ; sign bit
 EOR RAT2               ; rot sign
 STX Q                  ; protect Xindex
 JSR ADD                ; (A X) = (A P) + (S R)
 STA K+1                ; hi
 STX K                  ; lo, save for later

 LDX Q                  ; restore Xindex
 LDA INWK+1,Y
 AND #127               ; hi7
 LSR A                  ; hi7/2
 STA T
 LDA INWK,Y
 SEC                    ; sub lo
 SBC T
 STA R                  ; Yindex one is 1-1/512
 LDA INWK+1,Y
 SBC #0                 ; sub hi
 STA S
 LDA INWK,X
 STA P                  ; Prepare to divide Xindex one by 16
 LDA INWK+1,X
 AND #128               ; sign bit
 STA T
 LDA INWK+1,X
 AND #127               ; hi7
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P                  ; divided by 16
 ORA T                  ; sign bit
 EOR #128               ; flip sign
 EOR RAT2               ; rot sign

 STX Q                  ; protect Xindex
 JSR ADD                ; (A X) = (A P) + (S R)
 STA INWK+1,Y
 STX INWK,Y             ; Yindex one now updated by 1/16th of a radian rotation
 LDX Q                  ; restore Xindex
 LDA K                  ; restore Xindex one lo
 STA INWK,X
 LDA K+1                ; Xindex one now updated by 1/16th of a radian rotation
 STA INWK+1,X
 RTS                    ; MVS5 done
}

\ *****************************************************************************
\ Subroutine: MVT6
\
\ P(1,2) += inwk,x (A is protected but with new sign)
\ *****************************************************************************

.MVT6                   ; Planet P(1,2) += inwk,x for planet (Asg is protected but with new sign)
{
 TAY                    ; Yreg = sg
 EOR INWK+2,X
 BMI MV50               ; sg -ve
 LDA P+1
 CLC                    ; add lo
 ADC INWK,X
 STA P+1
 LDA P+2                ; add hi
 ADC INWK+1,X
 STA P+2
 TYA                    ; restore old sg ok
 RTS

.MV50                   ; sg -ve
 LDA INWK,X
 SEC                    ; sub lo
 SBC P+1
 STA P+1
 LDA INWK+1,X
 SBC P+2                ; sub hi
 STA P+2
 BCC MV51               ; fix -ve
 TYA                    ; restore Asg
 EOR #128               ; but flip sign
 RTS

.MV51                   ; fix -ve
 LDA #1                 ; carry was clear
 SBC P+1
 STA P+1
 LDA #0                 ; sub hi
 SBC P+2
 STA P+2
 TYA                    ; old Asg ok
 RTS                    ; MVT6 done.
}

\ *****************************************************************************
\ Subroutine: MV40
\
\ Move Planet
\ *****************************************************************************

.MV40                   ; move Planet
{
 LDA ALPHA
 EOR #128               ; flip roll
 STA Q
 LDA INWK
 STA P                  ; xlo
 LDA INWK+1
 STA P+1                ; xhi
 LDA INWK+2             ; xsg
 JSR MULT3              ; K(4)= -AP(2)*alpha
 LDX #3                 ; Y coords
 JSR MVT3               ; add INWK(0to2+X) to K(1to3)  \ K=Y-a*X \ their comment

 LDA K+1
 STA K2+1
 STA P                  ; lo
 LDA K+2
 STA K2+2
 STA P+1                ; hi
 LDA BETA
 STA Q
 LDA K+3
 STA K2+3               ; sg
 JSR MULT3              ; K(4)= AP(2)*beta
 LDX #6                 ; Z coords
 JSR MVT3               ; add INWK(0to2+X) to K(1to3) \ K = Z+b*K2
 LDA K+1
 STA P                  ; zlo
 STA INWK+6
 LDA K+2
 STA P+1                ; zhi
 STA INWK+7
 LDA K+3
 STA INWK+8             ; zsg \Z=Z+b*K2 \ their comment

 EOR #128               ; -Z sgn
 JSR MULT3              ; K(4)= -Z*beta
 LDA K+3
 AND #128               ; sign
 STA T
 EOR K2+3
 BMI MV1                ; planet y = -Z*beta-K2

 LDA K
\CLC                    ; else y = -Z*beta+K2
 ADC K2
 LDA K+1
 ADC K2+1
 STA INWK+3
 LDA K+2
 ADC K2+2
 STA INWK+4             ; ylo
 LDA K+3
 ADC K2+3
 JMP MV2

.MV1                    ; planet y = -Z*beta-K2
 LDA K
 SEC                    ; yre
 SBC K2
 LDA K+1
 SBC K2+1
 STA INWK+3             ; ylo
 LDA K+2
 SBC K2+2
 STA INWK+4             ; yhi
 LDA K2+3
 AND #127               ; mag of K2+3
 STA P
 LDA K+3
 AND #127               ; mag of K+3
 SBC P
 STA P
 BCS MV2                ; continue pitch Planet

 LDA #1                 ; carry clear, fix ylo
 SBC INWK+3
 STA INWK+3
 LDA #0                 ; yhi
 SBC INWK+4
 STA INWK+4
 LDA #0                 ; mag of K2+3
 SBC P
 ORA #128               ; set bit7

.MV2                    ; continue pitch planet
 EOR T
 STA INWK+5             ; ysg \ Y=K2-bZ \ their comment

 LDA ALPHA
 STA Q
 LDA INWK+3
 STA P                  ; ylo
 LDA INWK+4
 STA P+1                ; yhi
 LDA INWK+5             ; ysg
 JSR MULT3              ; K(4)=AP(2)*alpha
 LDX #0                 ; X coords
 JSR MVT3               ; add INWK(0to2+X) to K(1to3) \ K = X+Ya
 LDA K+1
 STA INWK               ; xlo
 LDA K+2
 STA INWK+1             ; xhi
 LDA K+3
 STA INWK+2             ; xsg \ X=X+aY \ their comment

 JMP MV45               ; move inwk by speed, end of MV40 move planet.
}

\ *****************************************************************************
\ Save output/ELTA.bin
\ *****************************************************************************

PRINT "ELITE A"
PRINT "Assembled at ", ~CODE%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_A%

PRINT "S.ELTA ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_A%
SAVE "output/ELTA.bin", CODE%, P%, LOAD%

\ *****************************************************************************
\ ELITE B
\ *****************************************************************************

CODE_B% = P%
LOAD_B% = LOAD% + P% - CODE%
Q% = _ENABLE_MAX_COMMANDER

\ *****************************************************************************
\ Variable: NA%
\
\ Exposed labels: CHK, CHK2
\
\ Contains the last saved commander data, with the name at NA% and the data at
\ NA%+8 onwards. The size of the data block is given in NT%. This block is
\ initially set up with the default commander, which can be maxed out for
\ testing purposes by setting Q% to TRUE.
\
\ The commander's name is stored at NA%, and can be up to 7 characters long
\ (the DFS filename limit). It is terminated with a carriage return character,
\ ASCII 13.
\ *****************************************************************************

.NA%
{
 EQUS "JAMESON"         ; Default commander name
 EQUB 13                ; Terminated by a carriage return; commander name can
                        ; be up to 7 characters (the DFS limit for file names)
 
                        ; NA%+8 - the start of the commander data block
                        ;
                        ; This block contains the last saved commander data
                        ; block. As the game is played it uses an identical
                        ; block at location TP to store the current commander
                        ; state, and that block is copied here when the game is
                        ; saved. Conversely, when the game starts up, the block
                        ; here is copied to TP, which restores the last saved
                        ; commander when the player dies.
                        ;
                        ; The intial state of this block defines the default
                        ; commander. Q% can be set to TRUE to give the default
                        ; commander lots of credits and equipment.

 EQUB 0                 ; Mission status. The disk version of the game has two
                        ; missions, and this byte contains the status of those
                        ; missions (the possible values are 0, 1, 2, &A, &E). As
                        ; the tape version doesn't have missions, this byte will
                        ; always be zero, which means no missions have been
                        ; started.
                        ;
                        ; Note that this byte must not have bit 7 set, or
                        ; loading this commander will cause the game to restart

 EQUB 20                ; QQ0 = current system X-coordinate (Lave)
 EQUB 173               ; QQ1 = current system Y-coordinate (Lave)

 EQUW &5A4A             ; QQ21 = Seed w0 for system 0 in galaxy 0 (Tibedied)
 EQUW &0248             ; QQ21 = Seed w1 for system 0 in galaxy 0 (Tibedied)
 EQUW &B753             ; QQ21 = Seed w2 for system 0 in galaxy 0 (Tibedied)

IF Q%
 EQUD &00CA9A3B         ; CASH = Amount of cash (100,000,000 Cr)
ELSE
 EQUD &E8030000         ; CASH = Amount of cash (100 Cr)
ENDIF

 EQUB 70                ; QQ14 = Fuel level

 EQUB 0                 ; COK = Competition code

 EQUB 0                 ; GCNT = Galaxy number, 0-7

 EQUB POW+(128 AND Q%)  ; LASER = Front laser

IF Q% OR _FIX_REAR_LASER
 EQUB (POW+128) AND Q%  ; LASER+1 = Rear laser, as in ELITEB source
ELSE
 EQUB POW               ; LASER+1 = Rear laser, as in extracted ELTB binary
ENDIF

 EQUB 0                 ; LASER+2 = Left laser

 EQUB 0                 ; LASER+3 = Right laser

 EQUW 0                 ; Not used (reserved for up/down lasers, maybe?)

 EQUB 22+(15 AND Q%)    ; CRGO = Cargo capacity

 EQUD 0                 ; QQ20 = Contents of cargo hold (17 bytes)
 EQUD 0
 EQUD 0
 EQUD 0
 EQUB 0

 EQUB Q%                ; ECM = E.C.M.

 EQUB Q%                ; BST = Fuel scoops ("barrel status")

 EQUB Q% AND 127        ; BOMB = Energy bomb

 EQUB Q% AND 1          ; ENGY = Energy/shield level

 EQUB Q%                ; DKCMP = Docking computer

 EQUB Q%                ; GHYP = Galactic hyperdrive

 EQUB Q%                ; ESCP = Escape pod

 EQUD FALSE             ; Not used

 EQUB 3+(Q% AND 1)      ; NOMSL = Number of missiles

 EQUB FALSE             ; FIST = Legal status ("fugitive/innocent status")

 EQUB 16                ; AVL = Market availability (17 bytes)
 EQUB 15
 EQUB 17
 EQUB 0
 EQUB 3
 EQUB 28
 EQUB 14
 EQUB 0
 EQUB 0
 EQUB 10
 EQUB 0
 EQUB 17
 EQUB 58
 EQUB 7
 EQUB 9
 EQUB 8
 EQUB 0

 EQUB 0                 ; QQ26 = Random byte that changes for each visit to a
                        ; system, for randomising market prices

 EQUW 0                 ; TALLY = Number of kills

 EQUB 128               ; SVC = Save count

IF _FIX_REAR_LASER
 CH% = &3
ELSE
 CH% = &92
ENDIF

PRINT "CH% = ", ~CH%

.^CHK2                  ; Commander checksum byte, EOR'd with &A9 to make it
 EQUB CH% EOR &A9       ; harder to tamper with the checksum byte

.^CHK                   ; Commander checksum byte, see elite-checksum.py for
 EQUB CH%               ; more details
}

\ *****************************************************************************
\ Variable: UNIV
\
\ The little bubble of the universe that we simulate in Elite can contain up to
\ 13 ships. Each of those ships has its own block of 36 (NI%) bytes that
\ contains information such as the ship's position in space, speed, rotation,
\ energy and so on, as well as a pointer to the line data for plotting it on
\ screen. These 13 blocks of ship data live in the first 468 bytes of the
\ workspace at K% (&0900 to &0AD4).
\
\ In order to update the ship data, the whole block is copied to the INWK ship
\ workspace in zero page, as it's easier and quicker to work with zero page
\ locations. See the INWK documentation for details of the 36 bytes and the
\ information that they contain.
\
\ UNIV contains a table of address pointers to these data blocks, one for each
\ of the 13 ships. So if we want to read the data for ship number 3 in our
\ little bubble of the universe, we would look at the address held in UNIV+3
\ (ship numbers start at 0).
\ *****************************************************************************

.UNIV
{
FOR I%, 0, 12
 EQUW K% + I% * NI%     ; Address of block no. I%, of size NI%, in workspace K%
NEXT
}

\ *****************************************************************************
\ Variable: TWOS
\
\ Mode 4 single pixel.
\ *****************************************************************************

.TWOS                   ; Mode 4 single pixel
{
 EQUD &10204080
 EQUD &01020408
}

\ *****************************************************************************
\ Variable: TWOS2
\
\ Mode 4 double-width pixel approx as contained in 1 column.
\ *****************************************************************************

.TWOS2                  ; Mode 4 double-width pixel approx as contained in 1 column
{
 EQUD &183060C0
 EQUD &0303060C
}

\ *****************************************************************************
\ Variable: CTWOS
\
\ Mode 5 coloured pixel.
\ *****************************************************************************

.CTWOS                  ; Mode 5 coloured pixel
{
 EQUD &11224488
 EQUB &88               ; need extra for compass
}

\ *****************************************************************************
\ Subroutine: LL30, LOIN
\
\ Draw Line using (X1,Y1) , (X2,Y2).
\ *****************************************************************************

.LL30                   ; draw Line using (X1,Y1) , (X2,Y2)
.LOIN
{
 STY YSAV               ; will be restored at the end

 LDA #128               ; set bit7
 STA S
 ASL A                  ; = 0
 STA SWAP
 LDA X2
 SBC X1
 BCS LI1                ; deltaX
 EOR #&FF               ; else negate
 ADC #1
 SEC

.LI1                    ; deltaX
 STA P                  ; delta-X

 LDA Y2
 SBC Y1
 BCS LI2                ; deltaY
 EOR #&FF               ; else negate
 ADC #1

.LI2                    ; deltaY
 STA Q                  ; delta-Y
 CMP P                  ; is Q < P ?
 BCC STPX               ; if yes will Step along x
 JMP STPY               ; else will step along y

.STPX                   ; Step along x for line
 LDX X1
 CPX X2
 BCC LI3                ; is X1 < X2 ? hop down, order correct
 DEC SWAP               ; set flag
 LDA X2
 STA X1
 STX X2
 TAX
 LDA Y2
 LDY Y1
 STA Y1
 STY Y2

.LI3                    ; order correct    Xreg = X1
 LDA Y1
 LSR A                  ; build screen index
 LSR A
 LSR A
 ORA #&60               ; high byte of screen memory set to page &60+ Y1/8
 STA SCH
 LDA Y1
 AND #7                 ; build lo
 TAY                    ; row in char
 TXA                    ; X1
 AND #&F8               ; keep upper 5 bits
 STA SC                 ; screen lo

 TXA                    ; X1
 AND #7                 ; keep lower 3 bits
 TAX                    ; index mask
 LDA TWOS,X             ; Mode 4 single pixel
 STA R                  ; mask byte

 LDA Q                  ; delta-Y
 LDX #254               ; roll counter
 STX Q

.LIL1                   ; roll Q
 ASL A                  ; highest bit of delta-Y
 BCS LI4                ; steep
 CMP P                  ; delta-X
 BCC LI5                ; shallow

.LI4                    ; steep
 SBC P
 SEC

.LI5                    ; shallow
 ROL Q
 BCS LIL1               ; loop Q, end with some low bits in Q

 LDX P
 INX                    ; Xreg is width
 LDA Y2
 SBC Y1
 BCS DOWN               ; draw line to the right and down

 LDA SWAP
 BNE LI6                ; else Xreg was correct after all, no need to update R
 DEX

.LIL2                   ; counter X width
 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI6                    ; Xreg correct
 LSR R                  ; mask byte
 BCC LI7                ; else moving to next column to right. Bring carry in back
 ROR R
 LDA SC
 ADC #8                 ; next column
 STA SC

.LI7                    ; S += Q. this is like an overflow monitor to update Y
 LDA S
 ADC Q                  ; some low bits
 STA S
 BCC LIC2               ; skip Y adjustment
 DEY
 BPL LIC2               ; skip Y adjustment
 DEC SCH
 LDY #7

.LIC2                   ; skip Y adjustment
 DEX
 BNE LIL2               ; loop X width
 LDY YSAV               ; restore Yreg
 RTS

.DOWN                   ; Line is going to the right and down
 LDA SWAP
 BEQ LI9                ; no swap
 DEX

.LIL3                   ; counter X width
 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI9                    ; no swap
 LSR R
 BCC LI10               ; still in correct column, hop
 ROR R
 LDA SC
 ADC #8                 ; next column
 STA SC

.LI10                   ; this is like an overflow monitor to update Y
 LDA S
 ADC Q
 STA S
 BCC LIC3               ; skip Y adjustment
 INY
 CPY #8
 BNE LIC3               ; have not reached bottom byte of char, hop
 INC SCH
 LDY #0

.LIC3                   ; skipped Y adjustment
 DEX
 BNE LIL3               ; loop X width
 LDY YSAV               ; restore Yreg
 RTS

.STPY                   ; Step along y for line, goes down and to right
 LDY Y1
 TYA
 LDX X1
 CPY Y2
 BCS LI15               ; skip swap if Y1 >= Y2
 DEC SWAP
 LDA X2
 STA X1
 STX X2
 TAX
 LDA Y2
 STA Y1
 STY Y2
 TAY

.LI15                   ; Y1 Y2 order is now correct
 LSR A
 LSR A
 LSR A
 ORA #&60
 STA SCH                ; screen hi
 TXA                    ; X1
 AND #&F8
 STA SC                 ; screen lo

 TXA
 AND #7                 ; mask index
 TAX
 LDA TWOS,X             ; Mode4 single pixel
 STA R                  ; mask
 LDA Y1
 AND #7
 TAY

 LDA P                  ; delta-X
 LDX #1                 ; roll counter
 STX P

.LIL4                   ; roll P
 ASL A
 BCS LI13               ; do subtraction
 CMP Q                  ; delta-Y
 BCC LI14               ; less than Q

.LI13                   ; do subtraction
 SBC Q
 SEC

.LI14                   ; less than Q
 ROL P
 BCC LIL4               ; loop P, end with some low bits in P
 LDX Q
 INX                    ; adjust height
 LDA X2
 SBC X1
 BCC LFT                ; if C cleared then line moving to the left - hop down

 CLC
 LDA SWAP
 BEQ LI17               ; skip first point
 DEX

.LIL5                   ; skipped first point, counter X
 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI17                   ; skipped first point
 DEY
 BPL LI16               ; skip hi adjust
 DEC SCH
 LDY #7                 ; new char

.LI16                   ; skipped hi adjust
 LDA S
 ADC P
 STA S
 BCC LIC5               ; skip, still in same column
 LSR R                  ; mask
 BCC LIC5               ; no mask bit hop
 ROR R                  ; else moved over to next column, reset mask
 LDA SC                 ; screen lo
 ADC #8                 ; next char below
 STA SC

.LIC5                   ; same column
 DEX
 BNE LIL5               ; loop X height
 LDY YSAV               ; restore Yreg
 RTS

.LFT                    ; going left
 LDA SWAP
 BEQ LI18               ; skip first point
 DEX                    ; reduce height

.LIL6                   ; counter X height
 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI18
 DEY
 BPL LI19               ; skip hi adjust
 DEC SCH
 LDY #7                 ; rest char row

.LI19                   ; skipped hi adjust
 LDA S
 ADC P                  ; some low bits
 STA S
 BCC LIC6               ; no overflow

 ASL R                  ; else move byte mask to the left
 BCC LIC6               ; no overflow
 ROL R
 LDA SC
 SBC #7                 ; down 1 char
 STA SC
 CLC

.LIC6                   ; no overflow
 DEX                    ; height
 BNE LIL6               ; loop X
 LDY YSAV               ; restore Yreg
}

.HL6
{
 RTS                    ; end Line drawing
}

\ *****************************************************************************
\ Subroutine: NLIN3
\
\ Print title string and draw line underneath
\ *****************************************************************************

.NLIN3                  ; Title string and draw line underneath
{
 JSR TT27               ; process flight token
}

.NLIN4                  ; draw Line at Y = #19
{
 LDA #19
 BNE NLIN2              ; guaranteed, next horizontal line drawn at Y1=19.
}

\ *****************************************************************************
\ Subroutine: NLIN
\
\ Draw a horizontal line at text row 23
\ *****************************************************************************

.NLIN                   ; Horizontal line
{
 LDA #23                ; at Y1 = 23.
 INC YC                 ; Y text cursor
}

.NLIN2                  ; Horizontal line at height Acc
{
 STA Y1
 LDX #2                 ; left edge
 STX X1
 LDX #254               ; right edge
 STX X2
 BNE HLOIN              ; guaranteed, horizontal line only uses X1,Y1,X2.
}

\ *****************************************************************************
\ Subroutine: HLOIN2
\
\ Horizontal line X1,X2 using YY as mid-point, Acc is half-wdith.
\ *****************************************************************************

.HLOIN2                 ; Horizontal line X1,X2 using YY as mid-point, Acc is half-wdith.
{
 JSR EDGES              ; Clips Horizontal lines
 STY Y1
 LDA #0                 ; flag in line buffer solar at height Y1
 STA LSO,Y
}

\ *****************************************************************************
\ Subroutine: HLOIN
\
\ Draw a horizontal lines that only needs X1,Y1,X2
\ *****************************************************************************

.HLOIN                  ; Draw a horizontal lines that only needs X1,Y1,X2
{
 STY YSAV               ; protect Yreg
 LDX X1
 CPX X2
 BEQ HL6                ; no line rts
 BCC HL5                ; no swap needed
 LDA X2
 STA X1
 STX X2
 TAX                    ; Xreg=X1

.HL5                    ; no swap needed
 DEC X2

 LDA Y1
 LSR A                  ; build screen hi
 LSR A
 LSR A
 ORA #&60
 STA SCH
 LDA Y1
 AND #7
 STA SC                 ; screen lo
 TXA                    ; X1
 AND #&F8
 TAY                    ; upper 5 bits of X1

.HL1
 TXA                    ; X1
 AND #&F8
 STA T
 LDA X2
 AND #&F8
 SEC
 SBC T
 BEQ HL2                ; within one column
 LSR A
 LSR A
 LSR A
 STA R                  ; wide count

 LDA X1
 AND #7
 TAX                    ; mask index
 LDA TWFR,X             ; right
 EOR (SC),Y
 STA (SC),Y
 TYA
 ADC #8
 TAY                    ; next column
 LDX R                  ; wide count
 DEX
 BEQ HL3                ; approaching end

 CLC

.HLL1                   ; counter X wide count
 LDA #&FF               ; mask full line
 EOR (SC),Y
 STA (SC),Y
 TYA
 ADC #8                 ; next column
 TAY
 DEX
 BNE HLL1               ; loop X wide

.HL3                    ; approaching end R =1 in HL1
 LDA X2
 AND #7
 TAX                    ; mask index
 LDA TWFL,X             ; left
 EOR (SC),Y
 STA (SC),Y
 LDY YSAV               ; restore Yreg
 RTS

.HL2                    ; wide done, X1 and X2 within 1 column
 LDA X1
 AND #7
 TAX                    ; mask index
 LDA TWFR,X             ; right
 STA T                  ; temp mask
 LDA X2
 AND #7
 TAX                    ; mask index
 LDA TWFL,X             ; left
 AND T                  ; temp mask
 EOR (SC),Y
 STA (SC),Y
 LDY YSAV               ; restore Y reg 
 RTS                    ; end horizontal line
}

\ *****************************************************************************
\ Variable: TWFL
\
\ Mask left of horizontal line.
\ *****************************************************************************

.TWFL                   ; mask left of horizontal line.
{
 EQUD &F0E0C080
 EQUW &FCF8
 EQUB &FE
}

\ *****************************************************************************
\ Variable: TWFR
\
\ Mask right of horizontal line.
\ *****************************************************************************

.TWFR                   ; mask right of horizontal line.
{
 EQUD &1F3F7FFF
 EQUD &0103070F
}

\ *****************************************************************************
\ Subroutine: PX3
\
\ Draw 1 pixel for the case ZZ >= &90
\ *****************************************************************************

.PX3                    ; Draw 1 pixel for the case ZZ >= &90
{
 LDA TWOS,X             ; Mode 4 single pixel
 EOR (SC),Y
 STA (SC),Y
 LDY T1                 ; restore Yreg
 RTS
}

\ *****************************************************************************
\ Subroutine: PIX1
\
\ Draw dust Pixel, Acc has ALPHA or BETA in it
\ *****************************************************************************

.PIX1                   ; dust Pixel, Acc has ALPHA or BETA in it
{
 JSR ADD                ; (A X) = (A P) + (S R)
 STA YY+1               ; hi
 TXA                    ; lo
 STA SYL,Y              ; dust ylo
}

\ *****************************************************************************
\ Subroutine: PIXEL2
\
\ Draw dust (X1,Y1) from middle
\ *****************************************************************************

.PIXEL2                 ; dust (X1,Y1) from middle
{
 LDA X1                 ; xscreen
 BPL PX1                ; +ve X dust
 EOR #&7F               ; else negate
 CLC
 ADC #1

.PX1                    ; +ve X dust
 EOR #128               ; flip bit7 of X1
 TAX                    ; xscreen
 LDA Y1
 AND #127
 CMP #96                ; #Y screen half height
 BCS PX4                ; too high, rts
 LDA Y1
 BPL PX2                ; +ve Y dust
 EOR #&7F               ; else negate
 ADC #1

.PX2                    ; +ve Y dust
 STA T                  ; temp y dust
 LDA #97                ; #Y+1 above mid-point
 SBC T
}

\ *****************************************************************************
\ Subroutine: PIXEL
\
\ at (X,A) ZZ away. Yreg protected
\ *****************************************************************************

.PIXEL                  ; at (X,A) ZZ away. Yreg protected
{
 STY T1                 ; save Yreg
 TAY                    ; copy of ycoord
 LSR A
 LSR A
 LSR A
 ORA #&60
 STA SCH                ; screen hi
 TXA                    ; xscreen
 AND #&F8               ; column given by upper 5 bits of X
 STA SC                 ; screen lo
 TYA                    ; copy of ycoord
 AND #7                 ; char row is lower 3 bits of Yreg
 TAY
 TXA
 AND #7
 TAX                    ; mask index is lower 3 bits of Xreg

 LDA ZZ                 ; distance
 CMP #&90               ; Bigger number is further away
 BCS PX3                ; for the case ZZ >= &90. Draw 1 pixel
 LDA TWOS2,X            ; Mode 4 double-width pixel
 EOR (SC),Y
 STA (SC),Y
 LDA ZZ
 CMP #&50
 BCS PX13               ; middle distance pixel ended
 DEY                    ; char row below
 BPL PX14               ; double-size
 LDY #1                 ; add row above not below

.PX14                   ; double size
 LDA TWOS2,X            ; double-width pixel
 EOR (SC),Y
 STA (SC),Y

.PX13                   ; middle distance pixel ended
 LDY T1                 ; restore Yreg
}

.PX4                    ; rts
{
 RTS                    ; end Pixel
}

\ *****************************************************************************
\ Subroutine: BLINE
\
\ Ball line for Circle2 uses (X.T) as next y offset for arc
\ *****************************************************************************

.BLINE                  ; Ball line for Circle2 uses (X.T) as next y offset for arc
{
 TXA
 ADC K4                 ; y0 offset from circle2 is (X,T)
 STA K6+2               ; y2 lo = X + K4 lo
 LDA K4+1
 ADC T
 STA K6+3               ; y2 hi = T + K4 hi

 LDA FLAG               ; set to #&FF at beginning of CIRCLE2
 BEQ BL1                ; flag 0
 INC FLAG

.BL5                    ; counter LSP supplied and updated
 LDY LSP
 LDA #&FF
 CMP LSY2-1,Y
 BEQ BL7                ; end, move K6 to K5
 STA LSY2,Y
 INC LSP
 BNE BL7                ; end, move K6 to K5

.BL1                    ; flag 0 \ Prepare to clip
 LDA K5
 STA XX15               ; x1 lo
 LDA K5+1
 STA XX15+1             ; x1 hi

 LDA K5+2
 STA XX15+2             ; y1 lo
 LDA K5+3
 STA XX15+3             ; y1 hi

 LDA K6
 STA XX15+4             ; x2 lo
 LDA K6+1
 STA XX15+5             ; x2 hi

 LDA K6+2
 STA XX12               ; y2 lo
 LDA K6+3
 STA XX12+1             ; y2 hi

 JSR LL145              ; Clip XX15 XX12 vector
 BCS BL5                ; no line visible, loop LSP
 LDA SWAP
 BEQ BL9                ; skip swap
 LDA X1
 LDY X2
 STA X2
 STY X1
 LDA Y1
 LDY Y2
 STA Y2
 STY Y1

.BL9                    ; swap done
 LDY LSP
 LDA LSY2-1,Y
 CMP #&FF
 BNE BL8                ; skip stores to line buffers
 LDA X1
 STA LSX2,Y
 LDA Y1
 STA LSY2,Y
 INY                    ; LSP+1 other end of line segment

.BL8                    ; skipped stores
 LDA X2
 STA LSX2,Y
 LDA Y2
 STA LSY2,Y
 INY                    ; next LSP
 STY LSP
 JSR LOIN               ; draw line using (X1,Y1), (X2,Y2)

 LDA XX13               ; flag from clip
 BNE BL5                ; loop LSP as XX13 clip

.BL7                    ; end, move K6 to K5, cnt+=stp
 LDA K6
 STA K5
 LDA K6+1
 STA K5+1
 LDA K6+2
 STA K5+2
 LDA K6+3
 STA K5+3
 LDA CNT                ; count
 CLC                    ; cnt += step
 ADC STP                ; step for ring
 STA CNT
 RTS                    ; ball line done.
}

\ *****************************************************************************
\ Subroutine: FLIP
\
\ Switch dusty and dustx
\ *****************************************************************************

.FLIP                   ; switch dusty and dustx
{
\LDA MJ
\BNE FLIP-1
 LDY NOSTM              ; number of dust particles

.FLL1                   ; counter Y
 LDX SY,Y               ; dusty
 LDA SX,Y               ; dustx
 STA Y1
 STA SY,Y               ; dusty
 TXA                    ; old dusty
 STA X1
 STA SX,Y
 LDA SZ,Y
 STA ZZ                 ; dust distance
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next buffer entry
 BNE FLL1               ; loop Y
 RTS
}

\ *****************************************************************************
\ Subroutine: STARS
\
\ Dust Field Enter
\ *****************************************************************************

.STARS                  ; Dust Field Enter
{
\LDA #&FF
\STA COL
 LDX VIEW               ; laser mount
 BEQ STARS1             ; Forward Dust
 DEX
 BNE ST11               ; Left or Right dust
 JMP STARS6             ; Rear dust

.ST11                   ; Left or Right dust
 JMP STARS2             ; Left or Right dust

.STARS1                 ; Forward Dust
 LDY NOSTM              ; number of dust particles
}

.STL1                   ; counter Y
{
 JSR DV42               ; P.R = speed/SZ(Y) \ travel step of dust particle front/rear
 LDA R                  ; remainder
 LSR P                  ; hi
 ROR A
 LSR P                  ; hi is now emptied out.
 ROR A                  ; remainder
 ORA #1
 STA Q                  ; upper 2 bits above remainder

 LDA SZL,Y              ; dust zlo
 SBC DELT4              ; upper 2 bits are lowest 2 of speed
 STA SZL,Y              ; dust zlo
 LDA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 SBC DELT4+1            ; hi, speed/4, 10 max
 STA SZ,Y               ; dustz

 JSR MLU1               ; Y1 = SY,Y and P.A = Y1 7bit * Q
 STA YY+1
 LDA P                  ; lo
 ADC SYL,Y              ; dust ylo
 STA YY
 STA R                  ; offsetY lo
 LDA Y1                 ; old SY,Y
 ADC YY+1
 STA YY+1
 STA S

 LDA SX,Y               ; dustx
 STA X1
 JSR MLU2               ; P.A = A7bit*Q
 STA XX+1
 LDA P
 ADC SXL,Y              ; dust xlo
 STA XX
 LDA X1
 ADC XX+1
 STA XX+1

 EOR ALP2+1             ; roll sign
 JSR MLS1               ; P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA YY+1
 STX YY

 EOR ALP2               ; roll sign
 JSR MLS2               ; R.S = XX(0to1) and P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 STX XX

 LDX BET1               ; pitch lower7 bits
 LDA YY+1
 EOR BET2+1             ; flipped pitch sign
 JSR MULTS-2            ; AP=A*bet1 (bet1+<32)
 STA Q
 JSR MUT2               ; S = XX+1, R = XX, A.P=Q*A
 ASL P
 ROL A
 STA T
 LDA #0
 ROR A
 ORA T
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 TXA
 STA SXL,Y              ; dust xlo

 LDA YY
 STA R
 LDA YY+1
\JSR MAD
\STA S
\STX R
 STA S                  ; offset for pix1
 LDA #0
 STA P
 LDA BETA
 EOR #128

 JSR PIX1               ; dust, X1 has xscreen. yscreen = R.S+P.A
 LDA XX+1
 STA X1
 STA SX,Y               ; dustx
 AND #127               ; drop sign
 CMP #120
 BCS KILL1              ; kill the forward dust
 LDA YY+1
 STA SY,Y               ; dusty
 STA Y1
 AND #127               ; drop sign
 CMP #120
 BCS KILL1              ; kill the forward dust

 LDA SZ,Y               ; dustz
 CMP #16
 BCC KILL1              ; kill the forward dust
 STA ZZ                 ; old distance
}

.STC1                   ; Re-enter after kill
{
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next dust particle
 BEQ P%+5               ; rts
 JMP STL1               ; loop Y forward dust
 RTS
}

\ *****************************************************************************
\ Subroutine: KILL1
\
\ Kill the forward dust
\ *****************************************************************************

.KILL1                  ; kill the forward dust
{
 JSR DORND              ; do random, new A, X.
 ORA #4                 ; flick up/down
 STA Y1                 ; ydistance from middle
 STA SY,Y               ; dusty
 JSR DORND              ; do random, new A, X.
 ORA #8                 ; flick left/right
 STA X1
 STA SX,Y               ; dustx
 JSR DORND              ; do random, new A, X.
 ORA #&90               ; flick distance
 STA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 LDA Y1                 ; ydistance from middle
 JMP STC1               ; guaranteed, Re-enter forward dust loop
}

\ *****************************************************************************
\ Subroutine: STARS6
\
\ Rear dust
\ *****************************************************************************

.STARS6                 ; Rear dust
{
 LDY NOSTM              ; number of dust particles
}

.STL6                   ; counter Y
{
 JSR DV42               ; travel step of dust particle front/rear
 LDA R                  ; remainder
 LSR P                  ; hi
 ROR A
 LSR P                  ; hi is now emptied out
 ROR A
 ORA #1
 STA Q                  ; upper 2 bits above remainder

 LDA SX,Y               ; dustx
 STA X1
 JSR MLU2               ; P.A = A7bit*Q
 STA XX+1
 LDA SXL,Y              ; dust xlo
 SBC P
 STA XX
 LDA X1
 SBC XX+1
 STA XX+1

 JSR MLU1               ; Y1 = SY,Y and P.A = Y1 7bit * Q
 STA YY+1
 LDA SYL,Y              ; dust ylo
 SBC P
 STA YY
 STA R
 LDA Y1
 SBC YY+1
 STA YY+1
 STA S

 LDA SZL,Y              ; dust zlo
 ADC DELT4              ; upper 2 bits are lowest 2 of speed
 STA SZL,Y              ; dust zlo
 LDA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 ADC DELT4+1            ; hi, speed/4, 10 max
 STA SZ,Y               ; dustz

 LDA XX+1
 EOR ALP2               ; roll sign
 JSR MLS1               ; P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA YY+1
 STX YY

 EOR ALP2+1             ; flipped roll sign
 JSR MLS2               ; R.S = XX(0to1) and P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 STX XX

 LDA YY+1
 EOR BET2+1             ; flipped pitch sign
 LDX BET1               ; pitch lower7 bits
 JSR MULTS-2            ; AP=A*bet1 (bet1+<32)
 STA Q
 LDA XX+1
 STA S
 EOR #128
 JSR MUT1               ; R = XX, A.P=Q*A
 ASL P
 ROL A
 STA T
 LDA #0
 ROR A
 ORA T
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 TXA
 STA SXL,Y              ; dust xlo

 LDA YY
 STA R
 LDA YY+1
 STA S                  ; offset for pix1
\EOR #128
\JSR MAD
\STA S
\STX R
 LDA #0
 STA P
 LDA BETA

 JSR PIX1               ; dust, X1 has xscreen. yscreen = R.S+P.A
 LDA XX+1
 STA X1
 STA SX,Y               ; dustx
 LDA YY+1
 STA SY,Y               ; dusty
 STA Y1
 AND #127               ; ignore sign
 CMP #110
 BCS KILL6              ; rear dust kill

 LDA SZ,Y               ; dustz
 CMP #160
 BCS KILL6              ; rear dust kill
 STA ZZ                 ; old distance
}
.STC6                   ; Re-enter after kill
{
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY
 BEQ ST3                ; rts
 JMP STL6               ; loop Y rear dust

.ST3                    ; rts
 RTS
}

\ *****************************************************************************
\ Subroutine: KILL6
\
\ Rear dust kill
\ *****************************************************************************

.KILL6                  ; rear dust kill
{
 JSR DORND              ; do random, new A, X.
 AND #127
 ADC #10
 STA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 LSR A                  ; get carry
 BCS ST4                ; half of the new dust
 LSR A
 LDA #&FC               ; new dustx at edges
 ROR A                  ; may get a carry
 STA X1
 STA SX,Y               ; dustx
 JSR DORND              ; do random, new A, X.
 STA Y1
 STA SY,Y               ; dusty
 JMP STC6               ; Re-enter rear dust loop

.ST4                    ; half of the new dust
 JSR DORND              ; do random, new A, X.
 STA X1
 STA SX,Y               ; dustx
 LSR A                  ; get carry
 LDA #230               ; new dusty at edges
 ROR A
 STA Y1
 STA SY,Y               ; dusty
 BNE STC6               ; guaranteed, Re-enter rear loop
}

\ *****************************************************************************
\ Variable: PRXS
\
\ Equipment prices.
\ *****************************************************************************

.PRXS                   ; Equipment prices
{
 EQUW 1                 ; PRXS(0) used for 2*fuel_needed, max 140
 EQUW 300               ; Missile                     30.0 Cr
 EQUW 4000              ; Large Cargo Bay            400.0 Cr
 EQUW 6000              ; E.C.M. System (item 4)     600.0 Cr
 EQUW 4000              ; Extra Pulse Lasers         400.0 Cr
 EQUW 10000             ; Extra Beam Lasers         1000.0 Cr
 EQUW 5250              ; Fuel Scoops  (item 7)      525.0 Cr
 EQUW 10000             ; Escape Pod                1000.0 Cr
 EQUW 9000              ; Energy Bomb                900.0 Cr
 EQUW 15000             ; Energy Unit               1500.0 Cr
 EQUW 10000             ; Docking Computer          1000.0 Cr
 EQUW 50000             ; Galactic Hyperspace       5000.0 Cr
}

\ *****************************************************************************
\ Subroutine: st4
\
\ Tally high of Status code
\ *****************************************************************************

.st4                    ; tally high of Status code
{
 LDX #9                 ; Elite 9
 CMP #25                ; 256*25=6400 kills
 BCS st3                ; Xreg = 9 Elite
 DEX                    ; Deadly 8
 CMP #10                ; 256*10=2560 kills
 BCS st3                ; Xreg = 8 Deadly
 DEX                    ; Dangerous 7
 CMP #2                 ; 256*2= 512 kills
 BCS st3                ; Xreg = 7 Dangerous
 DEX                    ; else Xreg = 6 Competent
 BNE st3                ; guaranteed down, tally continue
}

\ *****************************************************************************
\ Subroutine: STATUS
\
\ Status screen Start #f8 red key
\ *****************************************************************************

.STATUS                 ; Status screen Start #f8 red key
{
 LDA #8                 ; menu i.d.
 JSR TT66               ; box border with QQ11 set to Acc
 JSR TT111              ; closest to QQ9,10 target system
 LDA #7                 ; indent
 STA XC                 ; X text cursor
 LDA #126               ; token = COMMANDER .....PRESENT SYSTEM...HYPERSPACE SYSTEM...CONDITION
 JSR NLIN3              ; Title string and draw line underneath
 LDA #15
 LDY QQ12
 BNE st6
 LDA #230               ; token = GREEN
 LDY MANY+AST           ; JUNK \ not ships, get offset to others nearby
 LDX FRIN+2,Y           ; any other ship types nearby?
 BEQ st6                ; only junk, so have message = GREEN
 LDY ENERGY             ; players energy
 CPY #128               ; (token E7 is red, E8 is yellow)
 ADC #1                 ; 1 or 2

.st6                    ; have message
 JSR plf                ; TT27 process flight token followed by rtn
 LDA #125               ; token = LEGAL STATUS:
 JSR spc                ; Acc to TT27 process flight token, followed by white space
 LDA #19                ; token = CLEAN
 LDY FIST               ; Fugitive/Innocent legal status
 BEQ st5                ; clean
 CPY #50                ; if Y >=  #50 then C is set
 ADC #1                 ; token OFFENDER or FUGITIVE

.st5                    ; clean
 JSR plf                ; TT27 process flight token followed by rtn
 LDA #16                ; token = RATING:

 JSR spc                ; Acc to TT27 process flight token, followed by white space
 LDA TALLY+1
 BNE st4                ; tally high, >= Competent, up
 TAX                    ; else less than 256 kills, set Xreg = 0
 LDA TALLY              ; the number of kills lo byte
 LSR A
 LSR A                  ; /=4 so keep upper 6 bits

.st5L                   ; roll kills lo/4 highest bit 54321
 INX
 LSR A                  ; roll out tally lo bits
 BNE st5L               ; loop, max Xreg =5
}

.st3                    ; tally continue, also arrive from st4 tally hi
{
 TXA                    ; tally status Xreg = 0 to 9
 CLC
 ADC #21                ; Acc = 30 is Elite
 JSR plf                ; TT27 process flight token followed by rtn

 LDA #18                ; token = 0x0c SHIP :
 JSR plf2               ; process flight token then rts then tab
 LDA CRGO               ; cargo bay size
 CMP #26                ; < 25 tonnes?
 BCC P%+7               ; onto fuel scoop
 LDA #&6B               ; token = Large Cargo Bay
 JSR plf2               ; process flight token then rts then tab
 LDA BST                ; Barrel status, fuel scoops
 BEQ P%+7               ; not present, onto e.c.m.
 LDA #111               ; token = FUEL SCOOPS
 JSR plf2               ; process flight token then rts then tab
 LDA ECM                ; have an ecm?
 BEQ P%+7               ; not present, onto other equipment
 LDA #&6C               ; token = E.C.M.SYSTEM
 JSR plf2               ; process flight token then rts then tab
 LDA #113               ; start other equipment
 STA XX4                ; equip start token

.stqv                   ; counter XX4
 TAY                    ; equipment token
 LDX BOMB-113,Y         ; equipstart =#&382-#&71,Y
 BEQ P%+5               ; equip not present, skip item
 JSR plf2               ; process flight token then rts then tab
 INC XX4
 LDA XX4
 CMP #117               ; end equip list
 BCC stqv               ; loop XX4

 LDX #0                 ; onto listing lasers

.st                     ; counter X
 STX CNT                ; laser view counter
 LDY LASER,X
 BEQ st1                ; hop as no laser
 TXA                    ; laser view
 CLC
 ADC #96                ; token = FRONT ..
 JSR spc                ; Acc to TT27 process flight token, followed by white space
 LDA #103               ; token = PULSE LASER
 LDX CNT
 LDY LASER,X            ; laser type
 BPL P%+4               ; skip token update
 LDA #104               ; token = BEAM LASER
 JSR plf2               ; process flight token then rts then tab

.st1                    ; hopped as no laser
 LDX CNT
 INX                    ; next laser view
 CPX #4                 ; 4 views max for lasers
 BCC st                 ; loop X
 RTS

.plf2                   ; process flight text token then rts then tab
 JSR plf                ; TT27 flight token followed by rtn
 LDX #6                 ; indent for next item
 STX XC
 RTS
}

\ *****************************************************************************
\ Variable: TENS
\
\ Contains the four low bytes of the value 100,000,000,000 (100 billion).
\
\ The maximum number of digits that we can print with the the BPRNT routine
\ below is 11, so the biggest number we can print is 99,999,999,999. This
\ maximum number plus 1 is 100,000,000,000, which in hexadecimal is:
\
\   & 17 48 76 E8 00
\
\ The TENS variable contains the lowest four bytes in this number, with the
\ least significant byte first, i.e. 00 E8 76 48. This value is used in the
\ BPRNT routine when working out which decimal digits to print when printing a
\ number.
\ *****************************************************************************

.TENS
{
 EQUD &00E87648
}

\ *****************************************************************************
\ Subroutine: pr2
\
\ Print the 8-bit number in X to 3 digits, left-padding with spaces for numbers
\ with fewer than 3 digits (so numbers < 100 are right-aligned). Optionally
\ include a decimal point.
\
\ Arguments:
\
\   X           The number to print
\
\   C flag      If set, include a decimal point
\ *****************************************************************************

.pr2
{
 LDA #3                 ; Set A to the number of digits (3)

 LDY #0                 ; Zero the Y register, so we can fall through into TT11
                        ; to print the 16-bit number (Y X) to 3 digits, which
                        ; effectively prints X to 3 digits as the high byte is
                        ; zero
}

\ *****************************************************************************
\ Subroutine: TT11
\
\ Print the 16-bit number in (Y X) to a specific number of digits, left-padding
\ with spaces for numbers with fewer digits (so lower numbers are right-aligned).
\ Optionally include a decimal point.
\
\ Arguments:
\
\   X           The low byte of the number to print
\
\   Y           The high byte of the number to print
\
\   A           The number of digits
\
\   C flag      If set, include a decimal point
\ *****************************************************************************

.TT11
{
 STA U                  ; We are going to use the BPRNT routine (below) to
                        ; print this number, so we store the number of digits
                        ; in U, as that's what BPRNT takes as an argument
 
 LDA #0                 ; BPRNT takes a 32-bit number in K to K+3, with the
 STA K                  ; most significant byte first (big-endian), so we set
 STA K+1                ; the two most significant bytes to zero (K and K+1)
 STY K+2                ; and store (Y X) in the least two significant bytes
 STX K+3                ; (K+2 and K+3), so we are going to print the 32-bit
                        ; number (0 0 Y X)

                        ; Finally we fall through into BPRNT to print out the
                        ; number in K to K+3, which now contains (Y X), to 3
                        ; digits (as U = 3), using the same carry flag as when
                        ; pr2 was called to control the decimal point
}

\ *****************************************************************************
\ Subroutine: BPRNT
\
\ Print the 32-bit number stored in K to K+3 to a specific number of digits,
\ left-padding with spaces for numbers with fewer digits (so lower numbers are
\ right-aligned). Optionally include a decimal point.
\
\ Arguments:
\
\   K...K+3     The number to print, stored with the most significant byte in K
\               and the least significant in K+3 (big-endian, which is not the
\               same way that 6502 assembler stores addresses)
\
\   U           The maximum number of digits to print, including the decimal
\               point (spaces will be used on the left to pad out the result to
\               this width, so the number is right-aligned to this width). The
\               maximum number of characters including any decimal point must
\               be 11 or less.
\
\   C flag      If set, include a decimal point followed by one fractional
\               digit (i.e. show the number to 1 decimal place). In this case,
\               the number in K to K+3 contains 10 * the number we end up
\               printing, so to print 123.4, we would pass 1234 in K to K+3 and
\               would set the C flag.
\
\ *****************************************************************************
\
\ The algorithm is relatively simple, but it looks fairly complicated because
\ we're dealing with 32-bit numbers.
\ 
\ To see how it works, let's first consider a simple example with fewer digits.
\ Let's say we want to print out the following number to three digits:
\ 
\   567
\ 
\ First we subtract 100 repeatedly until we can't do it any more, counting how
\ many times we can do this:
\ 
\   567 - 100 - 100 - 100 - 100 - 100 = 67
\ 
\ Not surprisingly, we can subtract it 5 times, so our first digit is 5. Now we
\ multiply the remaining number by 10 to get 670, and repeat the process:
\ 
\   670 - 100 - 100 - 100 - 100 - 100 - 100 = 70
\ 
\ We subtracted 100 6 times, so the second digit is 6. Now to multiply by 10
\ again to get 700 and repeat the process:
\ 
\   700 - 100 - 100 - 100 - 100 - 100 - 100 - 100 = 0
\ 
\ So the third digit is 7 and we are done.
\ 
\ The BPRNT subroutine code does exactly this in its main loop at TT36, except
\ instead of having a three-digit number and subtracting 100, we have up to an
\ 11-digit number and subtract 10 billion each time (as 10 billion has 11
\ digits), using 32-bit arithmetic and an overflow byte, and that's where
\ the complexity comes in.
\ 
\ Given this, let's use some terminology to make it easier to talk about
\ multi-byte numbers, and specifically the big-endian numbers that Elite uses
\ to store large numbers like the current cash amount (big-endian numbers store
\ their most significant byte first, then the lowest significant bytes, which
\ is different to how 6502 assembly stores it's 16-bit numbers; Elite's large
\ numbers are stored in the same way that we write numbers, with the largest
\ digits first, while 6502 does it the other way round, where &30 &FE
\ represents &FE30, for example).
\ 
\ If K is made up of four bytes, then we may talk about K(0 1 2 3) as the
\ 32-bit number that is stored in memory at K thorough K+3, with the most
\ significant byte in K and the least significant in K+3. If we want to add
\ another significant byte to make this a five-byte number - an overflow byte
\ in a memory location called S, say - then we might talk about K(S 0 1 2 3).
\ Similarly, XX15(4 0 1 2 3) is a five-byte number stored with the highest byte
\ in XX15+4, then the next most significant in XX15, then XX15+1 and XX15+2,
\ through to the lowest byte in XX15+3 (yes, the following code does store one
\ of its numbers like this). It might help to think of the digits listed in
\ the brackets as being written down in the same order that we would write them
\ down as humans.
\ 
\ Now that we have some terminology, let's look at the above algorithm. We need
\ multi-byte subtraction, which we can do byte-by-byte using the carry flag,
\ but we also need to be able to multiply a multi-byte number by 10, which is
\ slightly trickier. Multiplying by 10 isn't directly supported the 6502, but
\ multiplying by 2 is, in the guise of shifting and rotating left, so we can do
\ this to multiply K by 10:
\ 
\   K * 10 = K * (2 + 8)
\          = (K * 2) + (K * 8)
\          = (K * 2) + (K * 2 * 2 * 2)
\ 
\ And that's what we do in the TT35 subroutine below, just with 32-bit
\ numbers with an 8-bit overflow. This doubling process is used quite a few
\ times in the following, so let's look an an example, in which we double the
\ number in K(S 0 1 2 3):
\ 
\   ASL K+3
\   ROL K+2
\   ROL K+1
\   ROL K
\   ROL S
\ 
\ First we use ASL K+3 to shift the least significant byte left (so bit 7 goes
\ to the carry flag). Then we rotate the next most significant byte with ROL
\ K+2 (so the carry flag goes into bit 0 and bit 7 goes into the carry), and we
\ repeat this with each byte in turn, until we get to the overflow byte S. This
\ has the effect of shifting the entire five-byte number one place to the left,
\ which doubles it in-place.
\ 
\ Finally, there are three variables that are used as counters in the above
\ loop, each of which gets decremented as we go work our way through the
\ digits. Their starting values are:
\ 
\   XX17   The maximum number of characters to print in total (this is
\          hard-coded to 11)
\ 
\   T      The maximum number of digits that we might end up printing (11 if
\          there's no decimal point, 10 otherwise)
\ 
\   U      The loop number at which we should start printing digits or spaces
\          (calculated from the U argument to BPRNT)
\ 
\ We do the loop XX11 times, once for each character that we might print. We
\ start printing characters once we reach loop number U (at which point we
\ print a space if there isn't a digit at that point, otherwise we print the
\ calculated digit). As soon as we have printed our first digit we set T to 0
\ to indicate that we should print characters for all subsequent loops, so T is
\ effectively a flag for denoting that we're switching from spaces to zeroes
\ for zero values, and decrementing T ensures that we always have at least one
\ digit in the number, even if it's a zero.
\ *****************************************************************************

.BPRNT
{
 LDX #11                ; Set T to the maximum number of digits allowed (11
 STX T                  ; characters, which is the number of digits in 10
                        ; billion); we will use this as a flag when printing
                        ; characters in TT37 below

 PHP                    ; Make a copy of the status register (in particular
                        ; the carry flag) so we can retrieve it later

 BCC TT30               ; If the carry flag is clear, we do not want to print a
                        ; decimal point, so skip the next two instructions

 DEC T                  ; As we are going to show a decimal point, decrement
 DEC U                  ; both the number of characters and the number of
                        ; digits (as one of them is now a decimal point)

.TT30
 LDA #11                ; Set A to 11, the maximum number of digits allowed

 SEC                    ; Set the carry flag so we can do subtraction without
                        ; the carry flag affecting the result

 STA XX17               ; Store the maximum number of digits allowed (11) in
                        ; XX17

 SBC U                  ; Set U = 11 - U + 1, so U now contains the maximum 
 STA U                  ; number of digits minus the number of digits we want
 INC U                  ; to display, plus 1 (so this is the number of digits
                        ; we should skip before starting to print the number
                        ; itself, and the plus 1 is there to ensure we at least
                        ; print one digit)

 LDY #0                 ; In the main loop below, we use Y to count the number
                        ; of times we subtract 10 billion to get the left-most
                        ; digit, so set this to zero (see below TT36 for an
                        ; of how this algorithm works)

 STY S                  ; In the main loop below, we use location S as an
                        ; 8-bit overflow for the 32-bit calculations, so
                        ; we need to set this to 0 before joining the loop

 JMP TT36               ; Jump to TT36 to start the process of printing this
                        ; number's digits

.TT35                   ; This subroutine multiplies K(S 0 1 2 3) by 10 and
                        ; stores the result back in K(S 0 1 2 3), using the
                        ; (K * 2) + (K * 2 * 2 * 2) approach described above

 ASL K+3                ; Set K(S 0 1 2 3) = K(S 0 1 2 3) * 2 by rotating bits.
 ROL K+2                ; See above for an explanation.
 ROL K+1
 ROL K
 ROL S

 LDX #3                 ; Now we want to make a copy of the newly doubled K in
                        ; XX15, so we can use it for the first (K * 2) in the
                        ; equation above, so set up a counter in X for copying
                        ; four bytes, starting with the last byte in memory
                        ; (i.e. the least significant)

.tt35
 LDA K,X                ; Copy the X-th byte of K(0 1 2 3) to the X-th byte of
 STA XX15,X             ; XX15(0 1 2 3), so that XX15 will contain a copy of
                        ; K(0 1 2 3) once we've copied all four bytes

 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)
 
 BPL tt35               ; Loop back to copy the next byte
 
 LDA S                  ; Store the value of location S, our overflow byte, in
 STA XX15+4             ; XX15+4, so now XX15(4 0 1 2 3) contains a copy of
                        ; K(S 0 1 2 3), which is the value of (K * 2) that we
                        ; want

 ASL K+3                ; Now to calculate the (K * 2 * 2 * 2) part. We still
 ROL K+2                ; have (K * 2) in K(S 0 1 2 3), so we just need to
 ROL K+1                ; it twice. This is the first one, so we do
 ROL K                  ; K(S 0 1 2 3) = K(S 0 1 2 3) * 2 (i.e. K * 4)
 ROL S

 ASL K+3                ; And then we do it again, so that means
 ROL K+2                ; K(S 0 1 2 3) = K(S 0 1 2 3) * 2 (i.e. K * 8)
 ROL K+1
 ROL K
 ROL S

 CLC                    ; Clear the carry flag so we can do addition without
                        ; the carry flag affecting the result
 
 LDX #3                 ; By now we've got (K * 2) in XX15(4 0 1 2 3) and
                        ; (K * 8) in K(S 0 1 2 3), so the final step is to add
                        ; these two 32-bit numbers together to get K * 10.
                        ; So we set a counter in X for four bytes, starting
                        ; with the last byte in memory (i.e. the least
                        ; significant)

.tt36
 LDA K,X                ; Fetch the X-th byte of K into A

 ADC XX15,X             ; Add the X-th byte of XX15 to A, with carry

 STA K,X                ; Store the result in the X-th byte of K
 
 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)
 
 BPL tt36               ; Loop back to add the next byte

 LDA XX15+4             ; Finally, fetch the overflow byte from XX15(4 0 1 2 3)

 ADC S                  ; And add it to the overflow byte from K(S 0 1 2 3),
                        ; with carry

 STA S                  ; And store the result in the overflow byte from
                        ; K(S 0 1 2 3), so now we have our desired result that
                        ; K(S 0 1 2 3) is now K(S 0 1 2 3) * 10

 LDY #0                 ; In the main loop below, we use Y to count the number
                        ; of times we subtract 10 billion to get the left-most
                        ; digit, so set this to zero

.TT36                   ; This is the main loop of our digit-printing routine.
                        ; In the following loop, we are going to count the
                        ; number of times that we can subtract 10 million in Y,
                        ; which we have already set to 0
                        
 LDX #3                 ; Our first calculation concerns 32-bit numbers, so
                        ; set up a counter for a four-byte loop

 SEC                    ; Set the carry flag so we can do subtraction without
                        ; the carry flag affecting the result
                        
.tt37                   ; Now we loop thorough each byte in turn to do this:
                        ;
                        ; XX15(4 0 1 2 3) = K(S 0 1 2 3) - 100,000,000,000

 LDA K,X                ; Subtract the X-th byte of TENS (i.e. 10 billion) from
 SBC TENS,X             ; the X-th byte of K

 STA XX15,X             ; Store the result in the X-th byte of XX15

 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)

 BPL tt37               ; Loop back to subtract from the next byte

 LDA S                  ; Subtract the fifth byte of 10 billion (i.e. &17) from
 SBC #&17               ; the fifth (overflow) byte of K, which is S
 
 STA XX15+4             ; Store the result in the overflow byte of XX15

 BCC TT37               ; If subtracting 10 billion took us below zero, jump to
                        ; TT37 to print out this digit, which is now in Y

 LDX #3                 ; We now want to copy XX15(4 0 1 2 3) back to
                        ; K(S 0 1 2 3), so we can loop back up to do the next
                        ; subtraction, so set up a counter for a four-byte loop

.tt38
 LDA XX15,X             ; Copy the X-th byte of XX15(0 1 2 3) to the X-th byte
 STA K,X                ; of K(0 1 2 3), so that K will contain a copy of
                        ; XX15(0 1 2 3) once we've copied all four bytes
 
 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)
 
 BPL tt38               ; Loop back to copy the next byte

 LDA XX15+4             ; Store the value of location XX15+4, our overflow
 STA S                  ; byte in S, so now K(S 0 1 2 3) contains a copy of
                        ; XX15(4 0 1 2 3)
 
 INY                    ; We have now managed to subtract 10 billion from our
                        ; number, so increment Y, which is where we are keeping
                        ; count of the number of subtractions so far
 
 JMP TT36               ; Jump back to TT36 to subtract the next 10 billion

.TT37
 TYA                    ; If we get here then Y contains the digit that we want
                        ; to print (as Y has now counted the total number of
                        ; subtractions of 10 billion), so transfer Y into A

 BNE TT32               ; If the digit is non-zero, jump to TT32 to print it

 LDA T                  ; Otherwise the digit is zero. If we are already
                        ; printing the number then we will want to print a 0,
                        ; but if we haven't started printing the number yet,
                        ; then we probbaly don't, as we don't want to print
                        ; leading zeroes unless this is the only digit before
                        ; the decimal point
                        ; 
                        ; To help with this, we are going to use T as a flag
                        ; that tells us whether we have already started
                        ; printing digits:
                        ;
                        ;   If T <> 0 we haven't printed anything yet
                        ;   If T = 0 then we have started printing digits
                        ;
                        ; We initially set T to the maximum number of
                        ; characters allowed at, less 1 if we are printing a
                        ; decimal point, so the first time we enter the digit
                        ; printing routine at TT37, it is definitely non-zero
 
 BEQ TT32               ; If T = 0, jump straight to the print routine at TT32,
                        ; as we have already started printing the number, so we
                        ; definitely want to print this digit too

 DEC U                  ; We initially set U to the number of digits we want to
 BPL TT34               ; skip before starting to print the number. If we get
                        ; here then we haven't printed any digits yet, so
                        ; decrement U to see if we have reached the point where
                        ; we should start printing the number, and if not, jump
                        ; to TT34 to set up things for the next digit

 LDA #' '               ; We haven't started printing any digits yet, but we
 BNE tt34               ; have reached the point where we should start printing
                        ; our number, so call TT26 (via tt34) to print a space
                        ; so that the number is left-padded with spaces (this
                        ; BNE is effectively a JMP as A will never be zero)

.TT32
 LDY #0                 ; We are printing an actual digit, so first set T to 0,
 STY T                  ; to denote that we have now started printing digits as
                        ; opposed to spaces

 CLC                    ; The digit value is in A, so add ASCII '0' to get the
 ADC #'0'               ; ASCII character number to print

.tt34
 JSR TT26               ; Print the character in A and fall through into TT34
                        ; to get things ready for the next digit

.TT34
 DEC T                  ; Decrement T but keep T >= 0 (by incrementing it
 BPL P%+4               ; again if the above decrement made T negative)
 INC T

 DEC XX17               ; Decrement the total number of characters to print in
                        ; XX17

 BMI RR3+1              ; If it is negative, we have printed all the characters
                        ; so return from the subroutine (as RR3 contains an
                        ; ORA #&60 instruction, so RR3+1 is &60, which is the
                        ; opcode for an RTS)

 BNE P%+10              ; If it is positive (> 0) loop back to TT35 (via the
                        ; last instruction in this subroutine) to print the
                        ; next digit

 PLP                    ; If we get here then we have printed the exact number
                        ; of digits that we wanted to, so restore the carry
                        ; flag that we stored at the start of BPRNT

 BCC P%+7               ; If carry is clear, we don't want a decimal point, so
                        ; look back to TT35 (via the last instruction in this
                        ; subroutine) to print the next digit

 LDA #'.'               ; Print the decimal point
 JSR TT26

 JMP TT35               ; Loop back to TT35 to print the next digit
}

\ *****************************************************************************
\ Subroutine: BELL
\
\ Make a beep sound.
\ *****************************************************************************

.BELL
{
 LDA #7                 ; Control code 7 makes a beep, so load this into A so
                        ; we can fall through into the TT27 print routine to
                        ; actually make the sound
}

\ *****************************************************************************
\ Subroutine: TT26
\
\ Exposed labels: RR3, RREN, RR4, rT9, R5
\
\ Print a character at the text cursor (XC, YC), do a beep, print a newline,
\ or delete left (backspace).
\
\ WRCHV is set to point here by elite-loader.asm.
\
\ Entry conditions:
\
\   * XC contains the text column to print at (the x-coordinate)
\
\   * YC contains the line number to print on (the y-coordinate)
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\
\                 * 127 (delete the character to the left of the text cursor
\                   and move the cursor to the left)
\ *****************************************************************************

.TT26
{
 STA K3                 ; Store the A, X and Y registers, so we can restore
 STY YSAV2              ; them at the end (so they don't get changed by this
 STX XSAV2              ; routine)

 LDY QQ17               ; Load the QQ17 flag, which contains the text printing
                        ; flags

 CPY #&FF               ; If QQ17 = #&FF, then jump to RR4, which doesn't print
 BEQ RR4                ; anything, it just restore of the registers and
                        ; returns from the subroutine

 CMP #7                 ; If this is a beep character (A = 7), jump to R5,
 BEQ R5                 ; which will emit the beep, restore the registers and
                        ; return from the subroutine

 CMP #32                ; If this is an ASCII character (A >= 32), jump to RR1
 BCS RR1                ; below, which will print the character, restore the
                        ; registers and return from the subroutine

 CMP #10                ; If this is control code 10 (line feed) then jump to
 BEQ RRX1               ; RRX1, which will move down a line, restore the
                        ; registers and return from the subroutine

 LDX #1                 ; If we get here, then this is control code 11-13, of
 STX XC                 ; which only 13 is used. This code prints a newline,
                        ; which we can achieve by moving the text cursor
                        ; to the start of the line (carriage return) and down
                        ; one line (line feed). These two lines do the first
                        ; bit by setting XC = 1, and we then fall through into
                        ; the line feed routine that's used by control code 10

.RRX1
 INC YC                 ; Print a line feed, simply by incrementing the row
                        ; number (y-coordinate) of the text cursor, which is
                        ; stored in YC

 BNE RR4                ; Jump to RR4 to restore the registers and return from
                        ; the subroutine (this BNE is effectively a JMP as Y
                        ; will never be zero)

.RR1                    ; If we get here, then the character to print is an
                        ; ASCII character in the range 32-95. The quickest way
                        ; to display text on screen is to poke the character
                        ; pixel by pixel, directly into screen memory, so
                        ; that's what the rest of this routine does.
                        ; 
                        ; The first step, then, is to get hold of the bitmap
                        ; definition for the character we want to draw on the
                        ; screen (i.e. we need the pixel shape of this
                        ; character). The OS ROM contains bitmap definitions
                        ; of the BBC's ASCII characters, starting from &C000
                        ; for space (ASCII 32) and ending with the £ symbol
                        ; (ASCII 126).
                        ;
                        ; There are 32 characters definitions in each page of
                        ; memory, as each definition takes up 8 bytes (8 rows
                        ; of 8 pixels) and 32 * 8 = 256 bytes = 1 page. So:
                        ;
                        ;   ASCII 32-63  are defined in &C000-&C0FF (page &C0)
                        ;   ASCII 64-95  are defined in &C100-&C1FF (page &C1)
                        ;   ASCII 96-126 are defined in &C200-&C2F0 (page &C2)
                        ;
                        ; The following code reads the relevant character
                        ; bitmap from the above locations in ROM and pokes
                        ; those values into the correct position in screen
                        ; memory, thus printing the character on screen
                        ;
                        ; It's a long way from 10 PRINT "Hello world!":GOTO 10

\LDX #LO(K3)            ; These instructions are commented out in the original
\INX                    ; source, but they call OSWORD &A, which reads the
\STX P+1                ; character bitmap for the character number in K3 and
\DEX                    ; stores it in the block at K3+1, while also setting
\LDY #HI(K3)            ; P+1 to point to the character definition. This is
\STY P+2                ; exactly what the following uncommented code does,
\LDA #10                ; just without calling OSWORD. Presumably the code
\JSR OSWORD             ; below is faster than using the system call, as this
                        ; version takes up 15 bytes, while the version below
                        ; (which ends with STA P+1 and SYX P+2) is 17 bytes.
                        ; Every efficiency saving helps, especially as this
                        ; routine is run each time the game prints a character.
                        ;
                        ; If you want to switch this code back on, uncomment
                        ; the above block, and comment out the code below from
                        ; TAY to STX P+2. You will also need to uncomment the
                        ; LDA YC instruction a few lines down (in RR2), just to
                        ; make sure the rest of the code doesn't shift in
                        ; memory. To be honest I can't see a massive difference
                        ; in speed, but there you go.

 TAY                    ; Copy the character number from A to Y, as we are
                        ; about to pull A apart to work out where this
                        ; character definition lives in the ROM

                        ; Now we want to set X to point to the revevant page
                        ; number for this character - i.e. &C0, &C1 or &C2.
                        ; The following logic is easier to follow if we look
                        ; at the three character number ranges in binary:
                        ;
                        ;   Bit # 7654 3210
                        ; 
                        ;   32  = 0010 0000     Page &C0
                        ;   63  = 0011 1111
                        ;
                        ;   64  = 0100 0000     Page &C1
                        ;   95  = 0101 1111
                        ;
                        ;   96  = 0110 0000     Page &C2
                        ;   125 = 0111 1101
                        ;
                        ; We'll refer to this below.

 LDX #&BF               ; Set X to point to the first font page in ROM minus 1,
                        ; which is &C0 - 1, or &BF

 ASL A                  ; If bit 6 of the character is clear (A is 32-63)
 ASL A                  ; then skip the following instruction
 BCC P%+4

 LDX #&C1               ; A is 64-126, so set X to point to page &C1

 ASL A                  ; If bit 5 of the character is clear (A is 64-95)
 BCC P%+3               ; then skip the following instruction

 INX                    ; Increment X
                        ;
                        ; By this point, we started with X = &BF, and then
                        ; we did the following:
                        ;
                        ;   If A = 32-63:   skip    then INX  so X = &C0
                        ;   If A = 64-95:   X = &C1 then skip so X = &C1
                        ;   If A = 96-126:  X = &C1 then INX  so X = &C2
                        ;
                        ; In other words, X points to the relevant page. But
                        ; what about the value of A? That gets shifted to the
                        ; left three times during the above code, which
                        ; multiplies the number by 8 but also drops bits 7, 6
                        ; and 5 in the process. Look at the above binary
                        ; figures and you can see that if we cleared bits 5-7,
                        ; then that would change 32-53 to 0-31... but it would
                        ; do exactly the same to 64-95 and 96-125. And because
                        ; we also multiply this figure by 8, A now points to
                        ; the start of the character's definition within its
                        ; page (because there are 8 bytes per character
                        ; definition).
                        ;
                        ; Or, to put it another way, X contains the high byte
                        ; (the page) of the address of the definition that we
                        ; want, while A contains the low byte (the offset into
                        ; the page) of the address.
 
 STA P+1                ; Store the address of this character's definition in
 STX P+2                ; P+1 (low byte) and P+2 (high byte)

 LDA XC                 ; Fetch XC, the x-coordinate (column) of the text
 ASL A                  ; cursor, multiply by 8, and store in SC. As each
 ASL A                  ; character is 8 bits wide, and the special screen mode
 ASL A                  ; Elite uses for the top part of the screen is 256
 STA SC                 ; bits across with one bit per pixel, this value is 
                        ; not only the screen address offest of the text cursor
                        ; from the left side of the screen, it's also the least
                        ; significant byte of the screen address where we want
                        ; to print this character, as each row of on-screen
                        ; pixels corresponds to one page. To put this more
                        ; explicitly, the screen starts at &6000, so the
                        ; text rows are stored in screen memory like this:
                        ;
                        ;   Row 1: &6000 - &60FF    YC = 1, XC = 0 to 31
                        ;   Row 2: &6100 - &61FF    YC = 2, XC = 0 to 31
                        ;   Row 3: &6200 - &62FF    YC = 3, XC = 0 to 31
                        ;
                        ; and so on.
 
 LDA YC                 ; Fetch YC, the y-coordinate (row) of the text cursor

 CPY #127               ; If the character number (which is in Y) <> 127, then
 BNE RR2                ; skip to RR2 to print that character, otherwise this is
                        ; the delete character, so continue on

 DEC XC                 ; We want to delete the character to the left of the
                        ; text cursor and move the cursor back one, so let's
                        ; do that by decrementing YC. Note that this doesn't
                        ; have anything to do with the actual deletion below,
                        ; we're just updating the cursor so it's in the right
                        ; position following the deletion.

 ADC #&5E               ; A contains YC (from above) and the carry flag is set
 TAX                    ; (from the CPY #127 above), so these instructions do
                        ; this: X = YC + &5E + 1 = YC + &5F
                        ;
                        ; Because YC starts at 1 for the first text row, this
                        ; means that X will be &60 for row 1, &61 for row 2
                        ; and so on. In other words, X is now set to the page
                        ; number for the relevant row in screen memory (see
                        ; the comment above).

 LDY #&F8               ; Set Y = -8

 JSR ZES2               ; Call ZES2, which zero-fills the page pointed to by X,
                        ; from position SC + Y to SC - so that's the 8 bytes
                        ; before SC. We set SC above to point to the current
                        ; character, so this zero-fills the character before
                        ; that, effectively deleting the character to the left

 BEQ RR4                ; We are done deleting, so restore the registers and
                        ; return from the subroutine (this BNE is effectively
                        ; a JMP as ZES2 always returns with the zero flag set)

.RR2                    ; Now to actually print the character

 INC XC                 ; Once we print the character, we want to move the text
                        ; cursor to the right, so we do this by incrementing
                        ; XC. Note that this doesn't have anything to do
                        ; with the actual printing below, we're just updating
                        ; the cursor so it's in the right position following
                        ; the print.

\LDA YC                 ; This instruction is commented out in the original
                        ; source. It isn't required because we only just did a
                        ; LDA YC before jumping to RR2, so this is presumably
                        ; an example of the authors squeezing the code to save
                        ; 2 bytes and 3 cycles.
                        ;
                        ; If you want to re-enable the commented block near the
                        ; start of this routine, you should uncomment this
                        ; instruction as well

 CMP #24                ; If the text cursor is on the screen (i.e. YC < 24, so
 BCC RR3                ; we are on rows 1-23), then jump to RR3 to print the
                        ; character

 JSR TTX66              ; Otherwise we are off the bottom of the screen, so
                        ; clear the screen and draw a box border

 JMP RR4                ; And restore the registers and return from the
                        ; subroutine

.^RR3
 ORA #&60               ; A contains the value of YC - the screen row where we
                        ; want to print this character - so now we need to
                        ; convert this into a screen address, so we can poke
                        ; the character data to the right place in screen
                        ; memory. We already stored the least significant byte
                        ; of this screen address in SC above (see the STA SC
                        ; instruction above), so all we need is the most
                        ; significant byte. As mentioned above, in Elite's
                        ; square mode 4 screen, each row of text on screen
                        ; takes up exactly one page, so the first row is page
                        ; &60xx, the second row is page &61xx, so we can get
                        ; the page for character (XC, YC) by OR-ing with &60.
                        ; To see this in action, consider that our two values
                        ; are, in binary:
                        ;
                        ;   YC is between:  %0000 0000
                        ;             and:  %0001 0111
                        ;          &60 is:  %0110 0000
                        ;
                        ; so YC OR &60 effectively adds &60 to YV, giving us
                        ; the page number that we want

.^RREN
 STA SC+1               ; Store the page number of the destination screen
                        ; location in SC+1, so SC now points to the full screen
                        ; location where this character should go

 LDY #7                 ; We want to print the 8 bytes of character data to the
                        ; screen (one byte per row), so set up a counter in Y
                        ; to count these bytes

.RRL1
 LDA (P+1),Y            ; The character definition is at P+1 (low byte) and P+2
                        ; (high byte) - we set this up above -  so load the
                        ; Y-th byte from P+1

 EOR (SC),Y             ; If we EOR this value with the existing screen
                        ; contents, then it's reversible (so reprinting the
                        ; same character in the same place will revert the
                        ; screen to what it looked like before we printed
                        ; anything); this means that printing a white pixel on
                        ; onto a white background results in a black pixel, but
                        ; that's a small price to pay for easily erasable text

 STA (SC),Y             ; Store the Y-th byte at the screen address for this
                        ; character location

 DEY                    ; Decrement the loop counter

 BPL RRL1               ; Loop back for the next byte to print to the screen=

.^RR4
 LDY YSAV2              ; We're done printing, so restore the values of the
 LDX XSAV2              ; A, X and Y registers that we saved above and clear
 LDA K3                 ; the carry flag, so everything is back to how it was
 CLC

.^rT9
 RTS                    ; Return from the subroutine

.^R5
 JSR BEEP               ; Call the BEEP subroutine, which uses the SOUND
                        ; command to emit a beep

 JMP RR4                ; Jump to RR4 to restore the registers and return from
                        ; the subroutine
}

\ *****************************************************************************
\ Subroutine: DIALS
\
\ Update displayed Dials
\ *****************************************************************************

.DIALS                  ; update displayed Dials
{
 LDA #&D0               ; screen lo
 STA SC                 ; bottom console (SC) = &78D0
 LDA #&78               ; screen hi
 STA SC+1
 JSR PZW                ; flashing X.A = F0.0F or F0.0?
 STX K+1
 STA K
 LDA #14                ; threshold to change colour
 STA T1
 LDA DELTA              ; player ship's speed
\LSR A
 JSR DIL-1              ; only /2

 LDA #0
 STA R                  ; lo
 STA P                  ; lo
 LDA #8                 ; center indicator
 STA S                  ; = 8 hi
 LDA ALP1               ; roll magnitude
 LSR A
 LSR A
 ORA ALP2               ; roll sign
 EOR #128               ; flipped
 JSR ADD                ; (A X) = (A P) + (S R)
 JSR DIL2               ; roll/pitch indicator takes X.A
 LDA BETA               ; pitch
 LDX BET1               ; pitch sign
 BEQ P%+4               ; skip sbc #1
 SBC #1                 ; will add S=8 to Acc to center
 JSR ADD                ; (A X) = (A P) + (S R)
 JSR DIL2               ; roll/pitch indicator takes X.A

 LDA MCNT               ; movecount
 AND #3                 ; only 1in4 times
 BNE rT9                ; continue, else rts
 LDY #0
 JSR PZW                ; flashing X.A = F0.0F or F0.0
 STX K
 STA K+1
 LDX #3                 ; 4 energy banks
 STX T1                 ; threshold

.DLL23                  ; counter X
 STY XX12,X
 DEX                    ; energy bank
 BPL DLL23              ; loop X
 LDX #3                 ; player's energy
 LDA ENERGY
 LSR A
 LSR A                  ; = ENERGY/4
 STA Q

.DLL24                  ; counter X
 SEC
 SBC #16                ; each bank
 BCC DLL26              ; exit subtraction with valid Q, X
 STA Q                  ; bank fraction
 LDA #16                ; full bank
 STA XX12,X
 LDA Q
 DEX                    ; next energy bank, 0 will be top one.
 BPL DLL24              ; loop X
 BMI DLL9               ; guaranteed hop, all full.

.DLL26                  ; exit subtraction with valid Q, X
 LDA Q                  ; bank fraction
 STA XX12,X

.DLL9                   ; all full, counter Y
 LDA XX12,Y
 STY P                  ; store Y
 JSR DIL                ; energy bank
 LDY P                  ; restore Y
 INY
 CPY #4                 ; reached last energy bank?
 BNE DLL9               ; loop Y

 LDA #&78               ; move to top left row
 STA SC+1
 LDA #16                ; some comment about in range 0to80, shield range
 STA SC
 LDA FSH                ; forward shield
 JSR DILX               ; shield bar
 LDA ASH                ; aft shield
 JSR DILX               ; shield bar
 LDA QQ14               ; ship fuel #70 = #&46
 JSR DILX+2             ; /8 not /16 bar

 JSR PZW                ; flashing X.A = F0.0F or F0.0
 STX K+1
 STA K
 LDX #11                ; ambient cabin temperature
 STX T1                 ; threshold to change bar colour
 LDA CABTMP             ; cabin temperature
 JSR DILX               ; shield bar
 LDA GNTMP              ; laser temperature
 JSR DILX               ; shield bar

 LDA #&F0               ; high altitude
 STA T1                 ; threshold to change bar colour
 STA K+1
 LDA ALTIT              ; Altimeter
 JSR DILX               ; shield bar
 JMP COMPAS             ; space compass.

.PZW                    ; Flashing X.A = F0.0F or F0.0?
 LDX #&F0               ; yellow
 LDA MCNT               ; movecount
 AND #8
 AND FLH                ; flash toggle
 BEQ P%+4               ; if zero default to lda #&0F
 TXA                    ; else return A = X
 EQUB &2C               ; bit2 skip load
 LDA #15                ; red
 RTS
}

\ *****************************************************************************
\ Subroutine: DILX
\
\ Show speed, shield bar, fuel
\ *****************************************************************************

.DILX                   ; shield bar
{
 LSR A                  ; /=  2
 LSR A                  ; fuel bar starts here
 LSR A                  ; DILX+2
 LSR A                  ; DIL-1
}

.DIL                    ; energy bank
{
 STA Q                  ; bar value 0to15
 LDX #&FF               ; mask
 STX R
 CMP T1                 ; threshold to change bar colour
 BCS DL30               ; Acc >= threshold colour will be K
 LDA K+1                ; other colour
 BNE DL31               ; skip lda K

.DL30                   ; threshold colour will be K
 LDA K

.DL31
 STA COL                ; the colour
 LDY #2                 ; height offset
 LDX #3                 ; height of bar-1

.DL1                    ; counter X height
 LDA Q                  ; bar value 0to15
 CMP #4
 BCC DL2                ; exit, Q < 4
 SBC #4
 STA Q
 LDA R                  ; mask

.DL5                    ; loop Mask
 AND COL
 STA (SC),Y
 INY
 STA (SC),Y
 INY
 STA (SC),Y
 TYA                    ; step to next char
 CLC
 ADC #6                 ; +=6
 TAY
 DEX                    ; reduce height
 BMI DL6                ; ended, next bar.
 BPL DL1                ; else guaranteed loop X height

.DL2                    ; exited, Q < 4
 EOR #3                 ; counter
 STA Q
 LDA R                  ; load up mask colour byte = &FF

.DL3                    ; counter small Q
 ASL A                  ; empty out mask
 AND #239
 DEC Q
 BPL DL3                ; loop Q
 PHA                    ; store mask
 LDA #0                 ; black
 STA R
 LDA #99                ; into Q
 STA Q
 PLA                    ; restore mask
 JMP DL5                ; up, loop mask

.DL6                    ; next bar
 INC SC+1

.DL9
 RTS
}

\ *****************************************************************************
\ Subroutine: DIL2
\
\ Show roll/pitch indicator
\ *****************************************************************************

.DIL2                   ; roll/pitch indicator takes X.A
{
 LDY #1                 ; counter Y = 1
 STA Q                  ; xpos

.DLL10                  ; counter Y til #30
 SEC
 LDA Q                  ; xpos
 SBC #4                 ; xpos-4
 BCS DLL11              ; blank
 LDA #&FF               ; else indicator
 LDX Q                  ; palette index
 STA Q                  ; = #&FF
 LDA CTWOS,X
 AND #&F0               ; Mode5 colour yellow
 BNE DLL12              ; fill

.DLL11                  ; blank
 STA Q                  ; new xpos
 LDA #0

.DLL12                  ; fill
 STA (SC),Y
 INY
 STA (SC),Y
 INY
 STA (SC),Y
 INY
 STA (SC),Y
 TYA                    ; step to next char
 CLC
 ADC #5
 TAY                    ; Y updated to next char
 CPY #30
 BCC DLL10              ; loop Y
 INC SC+1               ; next row, at end.
 RTS
}

\ *****************************************************************************
\ Variable: TVT1
\
\ Screen mode?
\ *****************************************************************************


.TVT1
 EQUD &8494C4D4
\TVT2
 EQUD &A5B5E5F5
 EQUD &26366676
 EQUD &A1B1F1E1
\TVT3
 EQUD &A0B0E0F0
 EQUD &8090C0D0
 EQUD &27376777

\ *****************************************************************************
\ Subroutine: LINSCN
\
\ Something to do with line scan, screen mode etc.
\ *****************************************************************************

.LINSCN
{
 LDA #30
 STA DL
 STA SHEILA+&44
 LDA #VSCAN
 STA SHEILA+&45
 LDA HFX
 BNE VNT1
 LDA #8
 STA SHEILA+&20
.VNT3
 LDA TVT1+16,Y
 STA SHEILA+&21
 DEY
 BPL VNT3
 LDA LASCT
 BEQ P%+5
 DEC LASCT
\VNT4
 LDA SVN
 BNE jvec
 PLA
 TAY
 LDA SHEILA+&41
 LDA &FC
 RTI
}

\ *****************************************************************************
\ Subroutine: IRQ1
\
\ Interrupt handler, might be a screen mode thing?
\
\ IRQ1V is set to point here by elite-loader.asm.
\ *****************************************************************************

.IRQ1
{
 TYA
 PHA
 LDY #11
 LDA #2
 BIT SHEILA+&4D
 BNE LINSCN
 BVC jvec
 ASL A\4
 STA SHEILA+&20
 LDA ESCP
 BNE VNT1
\VNT2
 LDA TVT1,Y
 STA SHEILA+&21
 DEY
 BPL P%-7

.^jvec
 PLA
 TAY
 JMP (VEC)

.^VNT1
 LDY #7
 LDA TVT1+8,Y
 STA SHEILA+&21
 DEY
 BPL VNT1+2
 BMI jvec
}

\ *****************************************************************************
\ Subroutine: ESCAPE
\
\ Escape pod launch
\ *****************************************************************************

.ESCAPE                 ; your Escape pod launch
{
 LDA MJ
 PHA
 JSR RES2               ; reset2
 LDX #CYL               ; Cobra Mk3
 STX TYPE
 JSR FRS1               ; escape pod launch, missile launch.
 LDA #8                 ; modest speed 
 STA INWK+27
 LDA #&C2               ; rotz, pitch counter
 STA INWK+30
 LSR A                  ; #&61 = ai dumb but has ecm, also counter.
 STA INWK+32

.ESL1                   ; ai counter INWK+32, ship flys out of view.
 JSR MVEIT
 JSR LL9                ; object ENTRY
 DEC INWK+32
 BNE ESL1               ; loop ai counter
 JSR SCAN               ; ships on scanner
 JSR RESET
 PLA
 BEQ P%+5
 JMP DEATH
 LDX #16

.ESL2                   ; counter X
 STA QQ20,X             ; cargo
 DEX
 BPL ESL2               ; loop X
 STA FIST               ; fugitative/innocent status, make clean
 STA ESCP               ; no escape pod
 LDA #70                ; max fuel allowed #70 = #&46
 STA QQ14
 JMP BAY                ; dock code
}

\ *****************************************************************************
\ Save output/ELTB.bin
\ *****************************************************************************

PRINT "ELITE B"
PRINT "Assembled at ", ~CODE_B%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_B%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_B%

PRINT "S.ELTB ", ~CODE_B%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_B%
SAVE "output/ELTB.bin", CODE_B%, P%, LOAD%

\ *****************************************************************************
\ ELITE C
\ *****************************************************************************

CODE_C% = P%
LOAD_C% = LOAD% +P% - CODE%

\ *****************************************************************************
\ Subroutine: TA34
\
\ Tactics, missile attacking player, from TA18
\ *****************************************************************************

.TA34                   ; Tactics, missile attacking player, from TA18
{
 LDA #0                 ; all hi or'd
 JSR MAS4
 BEQ P%+5               ; this ship is nearby
 JMP TA21               ; else rest of tactics, thargons can die.
 JSR TA87+3             ; set bit7 of INWK+31, kill missile with debris
 JSR EXNO3              ; ominous noises
 LDA #250               ; Huge dent in player's shield.
 JMP OOPS               ; Lose some shield strength, cargo, could die.
}

\ *****************************************************************************
\ Subroutine: TA18
\
\ Missile tactics
\ *****************************************************************************

.TA18                   ; msl \ their comment \ Missile tactics
{
 LDA ECMA               ; any ECM on ?
 BNE TA35               ; kill this missile
 LDA INWK+32            ; ai_attack_univ_ecm
 ASL A                  ; is bit6 set, player under attack?
 BMI TA34               ; yes, missile attacking player, up.
 LSR A                  ; else bits 7 and 6 are now clear, can use as an index.

 TAX                    ; missile's target in univ.
 LDA UNIV,X
 STA V                  ; is pointer to target info.
 LDA UNIV+1,X
 STA V+1                ; pointer hi
 LDY #2                 ; xsg
 JSR TAS1               ; below, K3(0to8) = inwk(0to8)-V_coords(0to8)
 LDY #5                 ; ysg
 JSR TAS1               ; K3(0to8) = inwk(0to8) -V_coords(0to8)
 LDY #8                 ; zsg
 JSR TAS1               ; K3(0to8) = inwk(0to8) -V_coords(0to8)

 LDA K3+2               ; xsubhi
 ORA K3+5               ; ysubhi
 ORA K3+8               ; zsubhi
 AND #127               ; ignore signs
 ORA K3+1               ; xsublo
 ORA K3+4               ; ysublo
 ORA K3+7               ; zsublo
 BNE TA64               ; missile far away, maybe ecm, then K3 heading.

 LDA INWK+32            ; ai_attack_univ_ecm, else missile close to hitting target
 CMP #&82               ; are only ai bit 7 and bit 1 set
 BEQ TA35               ; if attacking target 1 = #SST, kill missile.
 LDY #31                ; display state|missiles state of target ship V.
 LDA (V),Y
 BIT M32+1              ; used as mask #&20 = bit5 of V, target already exploding?
 BNE TA35               ; kill this missile
 ORA #128               ; else set bit7 display state of V, kill target ship V with debris.
 STA (V),Y

.TA35                   ; kill this missile
 LDA INWK               ; xlo
 ORA INWK+3             ; ylo
 ORA INWK+6             ; zlo
 BNE TA87               ; far away, down, set bit7 of INWK+31, kill this missile with debris
 LDA #80                ; else near player so large dent
 JSR OOPS               ; Lose some shield strength, cargo, could die.
}

.TA87                   ; kill inwk with noise
{
 JSR EXNO2              ; faint death noise, player killed inwk.
 ASL INWK+31            ; display explosion state|missiles
 SEC                    ; set bit7 to kill inwk with debris
 ROR INWK+31

.TA1
 RTS
}

\ *****************************************************************************
\ Subroutine: TA64
\
\ Missile far away, maybe ecm, then K3 heading.
\ *****************************************************************************

.TA64                   ; missile far away, maybe ecm, then K3 heading.
{
 JSR DORND              ; do random, new A, X.
 CMP #16                ; rnd >= #16 most likely
 BCS TA19               ; down, Attack K3.
}

.M32                    ; else ship V activates its ecm
{
 LDY #32                ; #&20 used as mask in bit5 test of TA18
 LDA (V),Y              ; ai_attack_univ_ecm for ship V
 LSR A                  ; does ship V has ecm in bit0 of ai?
 BCC TA19               ; down, Attack K3.
 JMP ECBLB2             ; ecm on, bulb2.
}

\ *****************************************************************************
\ Subroutine: TACTICS
\
\ Main tactic routine, Xreg is ship type, called by mveit if ai inwk+32 has
\ bit7 set, slot in XSAV.
\ *****************************************************************************

.TACTICS                ; Xreg is ship type, called by mveit if ai inwk+32 has bit7 set, slot in XSAV.
{
 CPX #MSL               ; is missile?
 BEQ TA18               ; up, Missile tactics

 CPX #ESC               ; is sscape pod?
 BNE P%+8               ; not sscape pod, down to space station
 JSR SPS1               ; XX15 vector to planet
 JMP TA15               ; fly towards XX15

 CPX #SST               ; is space station?
 BNE TA13               ; not space station, Other craft.

 JSR DORND              ; do random, new A, X.
 CMP #140               ; medium chance to launch
 BCC TA14-1             ; rts
 LDA MANY+COPS          ; MANY+COPS any so far?
 CMP #4                 ; no more than 4 cops max 
 BCS TA14-1             ; rts
 LDX #COPS
 LDA #&F1               ; ai_attack_univ_ecm, has ai, fairly aggressive, has ecm.
 JMP SFS1               ; spawn ship from parent ship, Acc is ai, Xreg is type created.

.TA13                   ; not space station, Other craft.
 CPX #TGL
 BNE TA14               ; not thargon
 LDA MANY+THG           ; number of thargoids #THG so far?
 BNE TA14               ; mother ship(s) still present, skip to not thargon
 LSR INWK+32            ; thargon ai
 ASL INWK+32            ; cleared bit0, thargon now have no ecm system.
 LSR INWK+27            ; speed halved
 RTS

.TA14                   ; not thargon
 CPX #CYL               ; is Cobra Mk III?
 BCS TA62
 CPX #COPS              ; is cop?
 BEQ TA62
 LDA SSPR               ; in space station range?
 BEQ TA62               ; no, pirate attacks player
 LDA INWK+32            ; ai_attack_univ_ecm
 AND #129               ; only keep bit0 and bit7, else pirate ai set to no attack, fly away,
 STA INWK+32            ; because pirate in space station range.

.TA62
 LDY #14                ; Hull byte#14 energy
 LDA INWK+35            ; ship energy
 CMP (XX0),Y
 BCS TA21
 INC INWK+35            ; ship energy
}

.TA21                   ; also not Pirate attacking player
{
 LDX #8                 ; Build local XX15

.TAL1                   ; counter X
 LDA INWK,X
 STA K3,X               ; K3(0to8) loaded with INWK(0to8) coords
 DEX
 BPL TAL1               ; loop X
}

.TA19                   ; Attack K3, spawn worms, others arrive.
{
 JSR TAS2               ; XX15=r~96  \ their comment \ build XX15 max 0x60 from K3
 LDY #10
 JSR TAS3               ; Y = 10, for TAS3 XX15.inwk,y dot product. max Acc 0x24 = 36.
 STA CNT                ; dot product. max Acc 0x24 = 36.
 LDA TYPE               ; ship type
 CMP #MSL               ; missile
 BNE P%+5               ; not missile
 JMP TA20               ; missile heading XX15 and CNT has dot product
 JSR DORND              ; do random, new A, X.
 CMP #250               ; very likely
 BCC TA7                ; Vrol
 JSR DORND              ; do random, new A, X.
 ORA #&68               ; large roll
 STA INWK+29            ; rotx counter

.TA7                    ; VRol  \ their comment \ likely
 LDY #14                ; Hull byte#14 energy
 LDA (XX0),Y
 LSR A                  ; Acc = max_energy/2
 CMP INWK+35            ; ship energy
 BCC TA3                ; Good energy
 LSR A
 LSR A                  ; Acc = max_energy/8
 CMP INWK+35    
 BCC ta3                ; not Low energy, else ship in trouble ..
 JSR DORND              ; do random, new A, X.
 CMP #230               ; likely
 BCC ta3                ; not Low energy, else respond to crisis ..
 LDA TYPE               ; restore ship type
 CMP #THG               ; Thargoid?
 BEQ ta3                ; is Thargoid, skip following
 LDA #0                 ; ship ai goes dumb.
 STA INWK+32
 JMP SESCP              ; ships launch Escape pod.

.ta3                    ; not Low energy, try to fire missiles.
 LDA INWK+31            ; display explosion state|missiles
 AND #7                 ; number of missiles
 BEQ TA3                ; none, continue to Good energy
 STA T                  ; number of missiles
 JSR DORND              ; do random, new A, X.
 AND #31                ; likely exceed
 CMP T                  ; number of missiles
 BCS TA3                ; continue to Good energy
 LDA ECMA               ; any ECM on?
 BNE TA3                ; continue to Good energy
 DEC INWK+31            ; reduce by 1 missile
 LDA TYPE               ; ship type
 CMP #THG               ; Thargoid?
 BNE TA16               ; not Thargoid, launch missile.
 LDX #TGL               ; thargon launch
 LDA INWK+32            ; Acc = Thargoid mother ai
 JMP SFS1               ; spawn ship from parent ship, Acc is ai, Xreg is type created.

.TA16                   ; not Thargoid, launch missile.
 JMP SFRMIS             ; Sound fire missile

.TA3                    ; Good energy > max/2
 LDA #0
 JSR MAS4               ; all hi or'd
 AND #&E0               ; keep big distance bits
 BNE TA4                ; just Manoeuvre
 LDX CNT                ; has a dot product to player
 CPX #160               ; -ve &20 vs max &24
 BCC TA4                ; not lined up, Manoeuvre
 LDA INWK+31            ; display explosion state|missiles
 ORA #64                ; set bit6, laser Firing at player.
 STA INWK+31
 CPX #163               ; dot product -ve &23 vs max &24
 BCC TA4                ; missed, onto Manoeuvre.

.HIT                    ; laser Hitting player
 LDY #19
 LDA (XX0),Y
 LSR A                  ; laser power/2 = size of dent on player
 JSR OOPS               ; Lose some shield strength, cargo, could die.
 DEC INWK+28            ; accel, attacking ship slows down.
 LDA ECMA               ; ECM on
 BNE TA10               ; rts, sound of ECM already.
 LDA #8                 ; frLs	\ their comment, sound of laser strike
 JMP NOISE

.TA4                    ; Manoeuvre
 LDA INWK+7             ; zhi
 CMP #3
 BCS TA5                ; Far z
 LDA INWK+1             ; xhi
 ORA INWK+4             ; yhi
 AND #&FE               ; > hi1
 BEQ TA15               ; Near

.TA5                    ; Far z
 JSR DORND              ; do random, new A, X.
 ORA #128               ; set bit 7 as ai active.
 CMP INWK+32            ; compare to actual ai_attack_univ_ecm
 BCS TA15               ; weak (non-missile) ai head away, Near.

.TA20                   ; Also arrive here if missile, heading XX15 and CNT has dot product
 LDA XX15
 EOR #128
 STA XX15
 LDA XX15+1
 EOR #128
 STA XX15+1
 LDA XX15+2
 EOR #128
 STA XX15+2
 LDA CNT
 EOR #128
 STA CNT
}

.TA15                   ; Near \^XX15, both towards and away from player
{
 LDY #16                ; XX15.inwk,16 dot product
 JSR TAS3
 EOR #128
 AND #128
 ORA #3
 STA INWK+30            ; new rotz counter pitch

 LDA INWK+29            ; rotx counter roll
 AND #127
 CMP #16                ; #16 magnitude
 BCS TA6                ; big pitch leave roll, onto Far away.

 LDY #22                ; XX15.inwk,22 dot product
 JSR TAS3
 EOR INWK+30            ; rotz counter, affects roll.
 AND #128
 EOR #&85
 STA INWK+29            ; new rotx counter roll 

.TA6                    ; default, Far away.
 LDA CNT                ; dot product
 BMI TA9                ; target is far behind, maybe Slow down.
 CMP #22                ; angle in front not too large
 BCC TA9                ; maybe Slow down
 LDA #3                 ; speed up a lot
 STA INWK+28            ; accel
 RTS                    ; TA9-1

.TA9                    ; maybe Slow down
 AND #127               ; drop dot product sign
 CMP #18                ; angle to axis not too large
 BCC TA10               ; slow enough, rts
 LDA #&FF               ; slow
 LDX TYPE               ; ship type
 CPX #MSL               ; missile
 BNE P%+3               ; skip asl if not missile
 ASL A                  ; #&FE = -2 for missile
 STA INWK+28            ; accel, #&FF=-1 if not missile.
}

.TA10
{
 RTS
}

\ *****************************************************************************
\ Subroutine: TAS1
\
\ K3(0to8) = inwk(0to8) -V_coords(0to8)
\ *****************************************************************************

.TAS1                   ; K3(0to8) = inwk(0to8) -V_coords(0to8)
{
 LDA (V),Y
 EOR #128               ; flip sg
 STA K+3
 DEY                    ; hi
 LDA (V),Y
 STA K+2                ; hi V_coord
 DEY                    ; lo
 LDA (V),Y
 STA K+1                ; K(1to3) gets V_coord(Y)
 STY U                  ; index = lo
 LDX U
 JSR MVT3               ; add INWK(0to2+X) to K(1to3) X = 0, 3, 6
 LDY U                  ; restore Yreg

 STA K3+2,X             ; sg
 LDA K+2
 STA K3+1,X             ; hi
 LDA K+1
 STA K3,X               ; lo
 RTS
}

\ *****************************************************************************
\ Subroutine: HITCH
\
\ Carry set if ship collides or missile locks.
\ *****************************************************************************

.HITCH                  ; Carry set if ship collides or missile locks.
{
 CLC
 LDA INWK+8             ; zsg
 BNE HI1                ; rts with C clear as -ve or big zg
 LDA TYPE               ; ship type
 BMI HI1                ; rts with C clear as planet or sun
 LDA INWK+31            ; display explosion state|missiles
 AND #32                ; keep bit5, is target exploding?
 ORA INWK+1             ; xhi
 ORA INWK+4             ; yhi
 BNE HI1                ; rts with C clear as too far away

 LDA INWK               ; xlo
 JSR SQUA2              ; P.A = xlo^2
 STA S                  ; x2 hi
 LDA P                  ; x2 lo
 STA R

 LDA INWK+3             ; ylo
 JSR SQUA2              ; P.A = ylo^2
 TAX                    ; y^2 hi
 LDA P                  ; y^2 lo
 ADC R                  ; x^2 lo
 STA R                  ; = x^2 +y^2 lo
 TXA                    ; y^2 hi
 ADC S                  ; x^2 hi
 BCS FR1-2              ; too far off, clc rts
 STA S                  ; x^2 + y^2 hi
 LDY #2                 ; Hull byte#2 area hi of ship type
 LDA (XX0),Y
 CMP S                  ; area hi
 BNE HI1                ; carry set if Hull hi > area
 DEY                    ; else hi equal, look at area lo, Hull byte#1
 LDA (XX0),Y
 CMP R                  ; carry set if Hull lo > area
}

.HI1                    ; rts
{
 RTS
}

\ *****************************************************************************
\ Subroutine: FRS1
\
\ Escape pod Launched, see Cobra Mk3 ahead, or player missile launch.
\ *****************************************************************************

.FRS1                   ; escape pod Launched, see Cobra Mk3 ahead, or player missile launch.
{
 JSR ZINF               ; zero info
 LDA #28                ; ylo distance
 STA INWK+3
 LSR A                  ; #14 = zlo
 STA INWK+6
 LDA #128               ; ysg -ve is below
 STA INWK+5
 LDA MSTG               ; = #&FF if missile NOT targeted
 ASL A                  ; convert to univ index, no ecm.
 ORA #128               ; set bit7, ai_active
 STA INWK+32
}

.fq1                    ; type Xreg cargo/alloys in explosion arrives here
{
 LDA #96                ; unit +1
 STA INWK+14            ; rotmat0z hi
 ORA #128               ; unit -1
 STA INWK+22            ; rotmat2x hi
 LDA DELTA              ; speed
 ROL A                  ; missile speed is double
 STA INWK+27            ; speed
 TXA                    ; ship type
 JMP NWSHP              ; New ship type X
}

\ *****************************************************************************
\ Subroutine: FRMIS
\
\ Player fires missile
\ *****************************************************************************

.FRMIS                  ; Player fires missile
{
 LDX #MSL               ; Missile
 JSR FRS1               ; player missile launch attempt, up.
 BCC FR1                ; no room, missile jammed message, down.
 LDX MSTG               ; nearby id for missile target
 JSR GINF               ; get address, INF, for ship X nearby from UNIV.
 LDA FRIN,X             ; get nearby ship type
 JSR ANGRY              ; for ship type Acc., visit down.
 LDY #0                 ; black missile block as gone
 JSR ABORT              ; draw missile block
 DEC NOMSL              ; reduce number of player's missles
 LDA #48                ; their comment
 JMP NOISE              ; for sound of missile launching
}

\ *****************************************************************************
\ Subroutine: ANGRY
\
\ Space station (or pirate?) angry
\ *****************************************************************************

.ANGRY                  ; Acc already loaded with ship type
{
 CMP #SST               ; #SST, space station.
 BEQ AN2                ; space station Angry
 BCS HI1
 CMP #CYL               ; #CYL cobra
 BNE P%+5               ; transport or below rts, else trader ship or higher.
 JSR AN2                ; space station Angry in support of police only
 LDY #32                ; Byte#32 = ai_attack_univ_ecm from info
 LDA (INF),Y
 BEQ HI1                ; rts if dumb
 ORA #128               ; else some ai bits exist. So set bit7, enable ai for tactics.
 STA (INF),Y
 LDY #28                ; accel
 LDA #2                 ; speed up
 STA (INF),Y
 ASL A                  ; #4 pitch
 LDY #30                ; rotz counter
 STA (INF),Y
 RTS

.AN2                    ; space station Angry
 ASL K%+NI%+32
 SEC
 ROR K%+NI%+32
 CLC
 RTS
}

\ *****************************************************************************
\ Subroutine: FR1
\
\ Missile jammed message
\ *****************************************************************************

.FR1                    ; missile jammed message.
{
 LDA #201               ; token = missile jammed
 JMP MESS               ; message
}

\ *****************************************************************************
\ Subroutine: SESCP
\
\ Ships launch Escape pod
\ *****************************************************************************

.SESCP                  ; from tactics, ships launch Escape pod
{
 LDX #ESC               ; #ESC type escape pod. On next line missiles.
 LDA #&FE               ; SFRMIS arrives \ SFS1-2 \ ai has bit6 set, attack player. No ecm.
}

\ *****************************************************************************
\ Subroutine: SFS1
\
\ Spawn ship from parent ship, Acc is ai, Xreg is type created.
\ *****************************************************************************

.SFS1                   ; spawn ship from parent ship, Acc is ai, Xreg is type created.
{
 STA T1                 ; daughter ai_attack_univ_ecm
 LDA XX0
 PHA                    ; pointer lo to Hull data
 LDA XX0+1
 PHA                    ; pointer hi to Hull data
 LDA INF
 PHA
 LDA INF+1
 PHA                    ; parent INF pointer
 LDY #NI%-1             ; whole workspace

.FRL2                   ; counter Y
 LDA INWK,Y
 STA XX3,Y              ; move inwk to heap
 LDA (INF),Y
 STA INWK,Y             ; get parent info
 DEY                    ; next bytes
 BPL FRL2               ; loop Y

 LDA TYPE               ; ship type of parent
 CMP #SST               ; space station
 BNE rx                 ; skip as space station not parent
 TXA                    ; else ship launched by space station
 PHA                    ; second copy of new type pushed
 LDA #32                ; speed quite fast
 STA INWK+27
 LDX #0                 ; xcoord
 LDA INWK+10
 JSR SFS2               ; xincrot added to inwk coord, below
 LDX #3                 ; ycoord
 LDA INWK+12
 JSR SFS2               ; yincrot added to inwk coord
 LDX #6                 ; zcoord
 LDA INWK+14
 JSR SFS2               ; zincrot added to inwk coord
 PLA
 TAX                    ; second copy of type restored

.rx                     ; skipped space station not parent
 LDA T1                 ; daughter ai_attack_univ_ecm.
 STA INWK+32            ; ai_attack_univ_ecm
 LSR INWK+29            ; rotx counter
 ASL INWK+29            ; clear bit0 to start damping roll.
 TXA                    ; second copy of daughter type restored
 CMP #OIL
 BNE NOIL               ; type is not cargo
 JSR DORND              ; do random, new A, X.
 ASL A                  ; pitch damped, and need rnd carry later.
 STA INWK+30            ; rotz counter
 TXA                    ; Xrnd
 AND #15                ; keep lower 4 bits as
 STA INWK+27            ; speed
 LDA #&FF               ; no damping
 ROR A                  ; rnd carry gives sign
 STA INWK+29            ; rotx counter roll has no damping
 LDA #OIL

.NOIL                   ; not cargo, launched missile or escape pod.
 JSR NWSHP              ; New ship type Acc

 PLA                    ; restore parent info pointer
 STA INF+1
 PLA
 STA INF
 LDX #NI%-1             ; #(NI%-1) whole workspace

.FRL3                   ; counter X
 LDA XX3,X              ; heap
 STA INWK,X             ; restore initial inwk.
 DEX                    ; next byte
 BPL FRL3               ; loop X
 PLA                    ; restore Hull data pointer
 STA XX0+1
 PLA                    ; lo
 STA XX0
 RTS
}

\ *****************************************************************************
\ Subroutine: SFS2
\
\ X=0,3,6 for Acc = inc added to x,y,z coords
\ *****************************************************************************

.SFS2                   ; X=0,3,6 for Acc = inc added to x,y,z coords
{
 ASL A                  ; sign into carry
 STA R                  ; inc
 LDA #0
 ROR A                  ; bring any carry back into bit 7
 JMP MVT1               ; Add R|sgnA to inwk,x+0to2
}

\ *****************************************************************************
\ Subroutine: LL164
\
\ Hyperspace noise and Tunnel inc. misjump
\ *****************************************************************************

.LL164                  ; hyperspace noise and Tunnel inc. misjump
{
 LDA #56                ; Hyperspace
 JSR NOISE
 LDA #1                 ; toggle Mode 4 to 5 colours for Hyperspace effects
 STA HFX
 LDA #4                 ; finer circles for launch code tunnel
 JSR HFS2
 DEC HFX                ; = 0
 RTS
}

\ *****************************************************************************
\ Subroutine: LAUN
\
\ Launch rings from space station
\ *****************************************************************************

.LAUN                   ; Launch rings from space station
{
 LDA #48                ; noisfr
 JSR NOISE
 LDA #8                 ; crude octagon rings
}

.HFS2                   ; Rings for tunnel
{
 STA STP                ; step for ring
 JSR TTX66              ; new box
 JSR HFS1

.HFS1                   ; Rings of STP
 LDA #128               ; half of xcreen
 STA K3
 LDX #Y                 ; #Y half of yscreen
 STX K4
 ASL A
 STA XX4                ; ring counter
 STA K3+1               ; x hi
 STA K4+1               ; y hi

.HFL5                   ; counter XX4 0..7
 JSR HFL1               ; One ring
 INC XX4
 LDX XX4
 CPX #8                 ; 8 rings
 BNE HFL5               ; loop X, next ring.
 RTS

.HFL1                   ; One ring
 LDA XX4                ; ring counter
 AND #7
 CLC
 ADC #8                 ; ring radius 8..15
 STA K

.HFL2                   ; roll K radius
 LDA #1                 ; arc step
 STA LSP
 JSR CIRCLE2
 ASL K
 BCS HF8                ; big ring, exit rts
 LDA K                  ; radius*=2
 CMP #160               ; radius max
 BCC HFL2               ; loop K

.HF8                    ; exit
 RTS
}

\ *****************************************************************************
\ Subroutine: STARS2
\
\ Left view has Xreg=1, Right has Xreg=2.
\ *****************************************************************************

.STARS2                 ; Left view has Xreg=1, Right has Xreg=2.
{
 LDA #0
 CPX #2                 ; if X >=2 then C is set
 ROR A                  ; if left view, RAT=0, if right view, RAT=128
 STA RAT
 EOR #128               ; flip other rat sign
 STA RAT2               ; if left view, RAT2=128, if right view, RAT2=0
 JSR ST2                ; flip alpha, bet2

 LDY NOSTM              ; number of stars
}

.STL2                   ; counter Y
{
 LDA SZ,Y               ; dustz
 STA ZZ                 ; distance away of dust particles
 LSR A
 LSR A
 LSR A                  ; /=8
 JSR DV41               ; P.R = speed/ (ZZ/8)
 LDA P
 EOR RAT2               ; view sign
 STA S                  ; delta hi
 LDA SXL,Y              ; dust xlo
 STA P
 LDA SX,Y               ; dustx
 STA X1                 ; x middle
 JSR ADD                ; (A X) = (A P) + (S R) = dustx+delta/z_distance

 STA S                  ; new x hi
 STX R                  ; new x lo
 LDA SY,Y               ; dusty
 STA Y1                 ; yhi old
 EOR BET2               ; pitch sign
 LDX BET1               ; lower7 bits
 JSR MULTS-2            ; AP=A*bet1 (bet1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STX XX
 STA XX+1

 LDX SYL,Y              ; dust ylo
 STX R
 LDX Y1                 ; yhi old
 STX S
 LDX BET1               ; lower7 bits
 EOR BET2+1             ; flipped pitch sign
 JSR MULTS-2            ; AP=A*~bet1 (~bet1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STX YY                 ; ylo
 STA YY+1               ; yhi

 LDX ALP1               ; lower7 bits of roll
 EOR ALP2               ; roll sign
 JSR MULTS-2            ; AP=A*~alp1(~alp1+<32)
 STA Q                  ; roll step
 LDA XX
 STA R
 LDA XX+1
 STA S
 EOR #128               ; flip sign
 JSR MAD                ; X.A = Q*A -XX
 STA XX+1
 TXA                    ; dust xlo
 STA SXL,Y

 LDA YY                 ; ylo
 STA R
 LDA YY+1               ; yhi
 STA S
 JSR MAD                ; offset for pix1
 STA S                  ; yhi a
 STX R                  ; ylo a
 LDA #0                 ; add yinc due to roll
 STA P                  ; ylo b
 LDA ALPHA              ; yhi b

 JSR PIX1               ; dust, X1 has xscreen. yscreen = R.S+P.A
 LDA XX+1
 STA SX,Y               ; dustx
 STA X1                 ; X from middle

 AND #127               ; Acc left with bottom 7 bits of X hi
 CMP #116               ; approaching left or right edge of screen.  deltatX=11
 BCS KILL2              ; left or right edge
 LDA YY+1
 STA SY,Y               ; dusty
 STA Y1                 ; Y from middle
 AND #127               ; Acc left with bottom 7 bits of Y hi
 CMP #116               ; approaching top or bottom of screen
 BCS ST5                ; ydust kill
}

.STC2                   ; Back in
{
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next dust
 BEQ ST2                ; all dust done, exit loop
 JMP STL2               ; loop Y
}

.ST2                    ; exited dust loop, flip alpha, bet2
{
 LDA ALPHA
 EOR RAT                ; view sign
 STA ALPHA
 LDA ALP2               ; roll sign
 EOR RAT
 STA ALP2               ; roll sign
 EOR #128               ; flip
 STA ALP2+1             ; flipped roll sign
 LDA BET2               ; pitch sign2
 EOR RAT                ; view sign
 STA BET2               ; pitch sign
 EOR #128               ; flip
 STA BET2+1             ; flipped pitch sign
 RTS
}

\ *****************************************************************************
\ Subroutine: KILL2
\
\ Kill dust, left or right edge.
\ *****************************************************************************

.KILL2                  ; kill dust, left or right edge.
{
 JSR DORND              ; do random, new A, X.
 STA Y1
 STA SY,Y               ; dusty rnd
 LDA #115               ; new xstart
 ORA RAT                ; view sign
 STA X1
 STA SX,Y               ; dustx
 BNE STF1               ; guaranteed, Set new distance
}

.ST5                    ; ydust kill
{
 JSR DORND              ; do random, new A, X.
 STA X1
 STA SX,Y               ; dustx rnd
 LDA #110               ; new ystart
 ORA ALP2+1             ; flipped roll sign
 STA Y1
 STA SY,Y               ; dusty
}

.STF1                   ; Set new distance
{
 JSR DORND              ; do random, new A, X.
 ORA #8                 ; not too close
 STA ZZ
 STA SZ,Y               ; dustz
 BNE STC2               ; guaranteed Back in for left/right dust
}

\ *****************************************************************************
\ Variable: SNE
\
\ Sine table.
\ *****************************************************************************

.SNE
{
FOR I%,0,31
N=ABS(SIN(I%/64*2*PI))
IF N>=1
    EQUB &FF
ELSE
    EQUB INT(256*N+.5)
ENDIF
NEXT

;O%=O%+32
;P%=P%+32
}

\ *****************************************************************************
\ Subroutine: MU5
\
\ Load Acc into K(0to3)
\ *****************************************************************************

.MU5                    ; load Acc into K(0to3)
{
 STA K
 STA K+1                ; MU5+2 does K1to3
 STA K+2
 STA K+3
 CLC
 RTS
}

\ *****************************************************************************
\ Subroutine: MULT3
\
\ K(4)=AP(2)*Q   Move planet
\ *****************************************************************************

.MULT3                  ; K(4)=AP(2)*Q   Move planet
{
 STA R                  ; sg
 AND #127
 STA K+2                ; hi
 LDA Q
 AND #127               ; Q7
 BEQ MU5                ; set K to zero
 SEC
 SBC #1
 STA T                  ; Q7-1 as carry will be set
 LDA P+1                ; mid
 LSR K+2
 ROR A
 STA K+1                ; mid
 LDA P
 ROR A
 STA K                  ; lo
 LDA #0
 LDX #24                ; 3 bytes

.MUL2                   ; counter X for 3 bytes
 BCC P%+4
 ADC T
 ROR A
 ROR K+2
 ROR K+1
 ROR K
 DEX
 BNE MUL2               ; loop X
 STA T                  ; sg7
 LDA R                  ; sg
 EOR Q
 AND #128               ; sign bit
 ORA T                  ; sg7
 STA K+3
 RTS
}

\ *****************************************************************************
\ Subroutine: MLS2
\
\ Assign from stars R.S = XX(0to1), and P.A = A*alp1 (alp1+<32)
\ *****************************************************************************

.MLS2                   ; assign from stars R.S = XX(0to1), and P.A = A*alp1 (alp1+<32)
{
 LDX XX
 STX R                  ; lo
 LDX XX+1
 STX S                  ; hi
}

\ *****************************************************************************
\ Subroutine: MLS1
\
\ P.A = A*alp1 (alp1+<32)
\ *****************************************************************************

.MLS1                   ; P.A = A*alp1 (alp1+<32)
{
 LDX ALP1               ; roll magnitude
 STX P
}

.MULTS                  ; P.A =A*P(P+<32)
{
 TAX                    ; Acc in
 AND #128
 STA T                  ; sign
 TXA
 AND #127
 BEQ MU6                ; set Plo.Phi = Acc = 0
 TAX                    ; Acc in
 DEX
 STX T1                 ; A7-1 as carry will be set
 LDA #0

 LSR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P

 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 ORA T
 RTS
}

\ *****************************************************************************
\ Subroutine: SQUA
\
\ AP=A*ApresQ \ P.A =A7*A7
\ *****************************************************************************

.SQUA                   ; AP=A*ApresQ \ P.A =A7*A7
{
 AND #127
}

\ *****************************************************************************
\ Subroutine: SQUA2
\
\ AP=A*A unsigned, also P.A = ylo^2
\ *****************************************************************************

.SQUA2                  ; AP=A*A unsigned
{
 STA P
 TAX                    ; is 0?
 BNE MU11               ; X*A will be done
}

\ *****************************************************************************
\ Subroutine: MU1
\
\ P = Acc = Xreg
\ *****************************************************************************

.MU1                    ; else P = Acc = Xreg
{
 CLC
 STX P
 TXA                    ; Acc = Xreg
 RTS
}

\ *****************************************************************************
\ Subroutine: MLU1
\
\ Y1 = SY,Y and P.A = Y1 7bit * Q
\ *****************************************************************************

.MLU1                   ; Y1 = SY,Y and P.A = Y1 7bit * Q
{
 LDA SY,Y
 STA Y1                 ; dusty
}

\ *****************************************************************************
\ Subroutine: MLU2
\
\ P.A = A7*Q
\ *****************************************************************************

.MLU2                   ; P.A = A7*Q
{
 AND #127
 STA P
}

\ *****************************************************************************
\ Subroutine: MULTU
\
\ AP=P*Qunsg
\ *****************************************************************************

.MULTU                  ; AP=P*Qunsg
{
 LDX Q
 BEQ MU1                ; up, P = Acc = Xreg = 0
}

\ *****************************************************************************
\ Subroutine: MU11
\
\ P*X will be done
\ *****************************************************************************

.MU11                   ; P*X will be done
{
 DEX                    ; Q-1 as carry will be set for addition
 STX T
 LDA #0
 LDX #8                 ; counter unwind?
 LSR P
{
.MUL6                   ; counter X
 BCC P%+4               ; low bit of P lo clear
 ADC T                  ; +=Q as carry set
 ROR A                  ; hi
 ROR P
 DEX
 BNE MUL6               ; loop X unwind?
 RTS                    ; Xreg = 0
}
}

\ *****************************************************************************
\ Subroutine: MU6
\
\ Set Plo.Phi = Acc
\ *****************************************************************************

.MU6                    ; set Plo.Phi = Acc
{
 STA P+1
 STA P
 RTS
}

\ *****************************************************************************
\ Subroutine: FMLTU2
\
\ For CIRCLE2,  A=K*sin(X)/256unsg
\ *****************************************************************************

.FMLTU2                 ; for CIRCLE2,  A=K*sin(X)/256unsg
{
 AND #31                ; table max #31
 TAX                    ; sine table index
 LDA SNE,X
 STA Q                  ; 0to255 for sine(0to pi)
 LDA K                  ; the radius
}

\ *****************************************************************************
\ Subroutine: FMLTU
\
\ A=A*Q/256unsg  Fast multiply
\ *****************************************************************************

.FMLTU                  ; A=A*Q/256unsg  Fast multiply
{
 EOR #&FF
 SEC
 ROR A                  ; bring a carry into bit7
 STA P                  ; slide counter
 LDA #0

.MUL3                   ; roll P
 BCS MU7                ; carry set, don't add Q
 ADC Q                  ; maybe a carry
 ROR A
 LSR P
 BNE MUL3               ; loop P
 RTS

.MU7                    ; carry set, don't add Q
 LSR A                  ; not ROR A
 LSR P
 BNE MUL3               ; loop P
 RTS
}

\ *****************************************************************************
\ Subroutine: MULTU6
\
\ AP=P*Qunsg \ Repeat of multu not needed?
\ *****************************************************************************

.MULTU6                 ; AP=P*Qunsg \ Repeat of multu not needed?
{
 LDX Q
 BEQ MU1                ; up, P = Acc = Xreg = 0
 
.MU116	                ; P*X will be done
 DEX
 STX T                  ; = Q-1 as carry will be set for addition
 LDA #0
 LDX #8                 ; counter
 LSR P
{
.MUL6                   ; counter X
 BCC P%+4               ; low bit of P lo clear
 ADC T                  ; +=Q as carry set
 ROR A                  ; hi
 ROR P
 DEX
 BNE MUL6               ; loop X
 RTS                    ; Repeat of mul6 not needed ?
}
}

\ *****************************************************************************
\ Subroutine: MLTU2-2
\
\ AP(2)= AP* Xunsg(EOR P)
\ *****************************************************************************

 STX Q                  ; AP(2)= AP* Xunsg(EOR P)

\ *****************************************************************************
\ Subroutine: MLTU2
\
\ AP(2)= AP* Qunsg(EOR P)
\ *****************************************************************************

.MLTU2                  ; AP(2)= AP* Qunsg(EOR P)
{
 EOR #&FF               ; use 2 bytes of P and A for result
 LSR A                  ; hi
 STA P+1
 LDA #0
 LDX #16                ; 2 bytes
 ROR P                  ; lo

.MUL7                   ; counter X
 BCS MU21               ; carry set, don't add Q
 ADC Q
 ROR A                  ; 3 byte result
 ROR P+1
 ROR P
 DEX
 BNE MUL7               ; loop X
 RTS

.MU21                   ; carry set, don't add Q
 LSR A                  ; not ROR A
 ROR P+1
 ROR P
 DEX
 BNE MUL7               ; loop X
 RTS
}

\ *****************************************************************************
\ Subroutine: MUT3
\
\ R.S = XX(2), A.P=A*Q
\ Not called?
\ *****************************************************************************

.MUT3                   ; R.S = XX(2), A.P=A*Q
{
 LDX ALP1               ; roll magnitude
 STX P                  ; over-written
}

\ *****************************************************************************
\ Subroutine: MUT2
\
\ R.S = XX(2), A.P=A*Q
\ *****************************************************************************

.MUT2                   ; R.S = XX(2), A.P=A*Q
{
 LDX XX+1
 STX S                  ; hi
}

\ *****************************************************************************
\ Subroutine: MUT1
\
\ Rlo = XX(1), A.P=A*Q
\ *****************************************************************************

.MUT1                   ; Rlo = XX(1), A.P=A*Q
{
 LDX XX
 STX R                  ; lo
}

\ *****************************************************************************
\ Subroutine: MULT1
\
\ A.P=Q*A first part of MAD, multiply and add. Visited Quite often.
\ *****************************************************************************

.MULT1                  ; A.P=Q*A first part of MAD, multiply and add. Visited Quite often.
{
 TAX                    ; Acc in
 AND #127
 LSR A
 STA P
 TXA                    ; Acc in
 EOR Q
 AND #128               ; extract sign
 STA T
 LDA Q
 AND #127
 BEQ mu10               ; zero down
 TAX                    ; Q7
 DEX                    ; Q7-1  as carry will be set for addition
 STX T1
 LDA #0
 LDX #7                 ; counter X

.MUL4                   ; Could unroll this loop
 BCC P%+4               ; skip add
 ADC T1                 ; Q7-1 as carry set
 ROR A                  ; both arrive
 ROR P
 DEX
 BNE MUL4               ; loop X
 LSR A                  ; hi
 ROR P
 ORA T                  ; sign
 RTS

.mu10                   ; zero down
 STA P
 RTS
}

\ *****************************************************************************
\ Subroutine: MULT12
\
\ R.S = Q * A \ visited quite often
\ *****************************************************************************

.MULT12                 ; R.S = Q * A \ visited quite often
{
 JSR MULT1              ; visit above,  (P,A)= Q * A
 STA S                  ; hi
 LDA P
 STA R                  ; lo
 RTS
}

\ *****************************************************************************
\ Subroutine: TAS3
\
\ Returns XX15.inwk,y  Dot product
\ *****************************************************************************

.TAS3                   ; returns XX15.inwk,y  Dot product
{
 LDX INWK,Y
 STX Q
 LDA XX15               ; xunit
 JSR MULT12             ; R.S = inwk*xx15
 LDX INWK+2,Y
 STX Q
 LDA XX15+1             ; yunit
 JSR MAD                ; X.A = inwk*xx15 + R.S
 STA S
 STX R

 LDX INWK+4,Y
 STX Q
 LDA XX15+2             ; zunit
}

\ *****************************************************************************
\ Subroutine: MAD
\
\ Multiply and Add   X.A = Q*A + R.S
\ *****************************************************************************

.MAD                    ; Multiply and Add   X.A = Q*A + R.S
{
 JSR MULT1              ; AP=Q * A, protects Y.
}

\ *****************************************************************************
\ Subroutine: ADD
\
\ Add two signed 16-bit numbers together, making sure the result has the
\ correct sign. Specifically:
\
\   (A X) = (A P) + (S R)
\
\ *****************************************************************************
\
\ When adding two signed numbers using two's complement, the result can have
\ the wrong sign when an overflow occurs. The classic example in 8-bit signed
\ arithmetic is 127 + 1, which doesn't give the expected 128, but instead gives
\ -128. In binary the sum looks like this:
\ 
\   0111 1111 + 0000 0001 = 1000 0000
\ 
\ The result has bit 7 set, so it is a negative number, 127 + 1 gives -128.
\ This is where the overflow flag V comes in - V would be set by the above sum
\ - but this means that every time you do a sum, you have to check the overflow
\ flag and deal with the overflow.
\ 
\ Elite doesn't want to have to bother with this overhead, so the ADD
\ subroutine, which adds two signed 16-bit numbers, instead ensures that the
\ result always had the correct sign, even in the event of an overflow, though
\ if the addition does overflow, the result still won't be correct. It will
\ have the right sign, though.
\ 
\ To implement this, the algorithm goes as follows. We want to add A and S, so:
\ 
\   * If both A and S are positive, just add them as normal
\ 
\   * If both A and S are negative, then add them and make sure the result is
\     negative
\ 
\   * If A and S have different signs, then we can use the absolute values of A
\     and S to work out the sum, as follows:
\ 
\     * Subtract the smaller absolute value from the larger absolute value
\ 
\     * Give the answer the same sign as the argument with the larger absolute
\       value
\ 
\ To see why this works, try visualising a number line containing the two
\ numbers A and S, with one to the left of zero and one to the right. Adding
\ the numbers is a bit like moving the number with the larger absolute value
\ towards zero on the number line, moving it by the amount of the smaller
\ absolute number; so it's like subtracting the smaller absolute value from the
\ larger one. You can also see that the sum of the two numbers will be on the
\ same side of zero as the number that is furthest from zero, so that's why the
\ answer should have the same sign as the argument with the larger absolute
\ value.
\ 
\ We can implement these steps like this:
\   
\   * If |A| = |S|, then the result is 0
\ 
\   * If |A| > |S|, then the result is |A| - |S|, with the sign set to the same
\     sign as A
\ 
\   * If |S| > |A|, then the result is |S| - |A|, with the sign set to the same
\     sign as S
\  
\ So that's what we do below to implement 16-bit signed addition that produces
\ results with the correct sign.
\ *****************************************************************************

.ADD
{
 STA T1                 ; Store argument A in T1

 AND #128               ; Extract the sign (bit 7) of A and store it in T
 STA T

 EOR S                  ; EOR bit 7 of A with S. If they have different bit 7s
 BMI MU8                ; (i.e. they have different signs) then bit 7 in the
                        ; EOR result will be 1, which means the EOR result is
                        ; negative. So the AND, EOR and BMI together mean "jump
                        ; to MU8 if A and S have different signs".
 
                        ; If we reach here, then A and S have the same sign, so
                        ; we can add them and set the sign to get the result

 LDA R                  ; Add the least significant bytes together into X, so
 CLC                    ;
 ADC P                  ;   X = P + R
 TAX
 
 LDA S                  ; Add the most significant bytes together into A. We
 ADC T1                 ; stored the original argument A in T1 earlier, so we
                        ; can do this with:
                        ;
                        ;   A = A  + S + carry
                        ;     = T1 + S + carry

 ORA T                  ; If argument A was negative (and therefore S was also
                        ; negative) then make sure result A is negative by
                        ; OR-ing the result with the sign bit from argument A
                        ; (which we stored in T)

 RTS                    ; Return from subroutine

.MU8                    ; If we reach here, then A and S have different signs,
                        ; so we can subtract their absolute values and set the
                        ; sign to get the result

 LDA S                  ; Clear the sign (bit 7) in S and store the result in
 AND #127               ; U, so U now contains |S|
 STA U

 LDA P                  ; Subtract the least significant bytes into X, so
 SEC                    ;   X = P - R
 SBC R
 TAX

 LDA T1                 ; Restore the A of the argument (A P) from T1 and
 AND #127               ; clear the sign (bit 7), so A now contains |A|

 SBC U                  ; Set A = |A| - |S|

                        ; At this point we have |A P| - |S R| in (A X), so we
                        ; need to check whether the subtraction above was the
                        ; the right way round (i.e. that we subtracted the
                        ; smaller absolute value from the larger absolute
                        ; value)

 BCS MU9                ; If |A| >= |S|, our subtraction was the right way
                        ; round, so jump to MU9 to set the sign

                        ; If we get here, then |A| < |S|, so our subtraction
                        ; above was the wrong way round (we actually subtracted
                        ; the larger absolute value from the smaller absolute
                        ; value. So let's subtract the result we have in (A X)
                        ; from zero, so that the subtraction is the right way
                        ; round

 STA U                  ; Store A in U

 TXA                    ; Set X = 0 - X using two's complement (to negate a
 EOR #&FF               ; number in two's complement, you can invert the bits
 ADC #1                 ; and add one - and we know carry is clear as we didn't
 TAX                    ; take the BCS branch above, so ADC will do the job)

 LDA #0                 ; Set A = 0 - A, which we can do this time using a
 SBC U                  ; a subtraction with carry clear
 
 ORA #128               ; We now set the sign bit of A, so that the EOR on the
                        ; next line wil give the result the opposite sign to
                        ; argument A (as T contains the sign bit of argument
                        ; A). This is the same as giving the result the same
                        ; sign as argument S (as A and S have different signs),
                        ; which is what we want, as S has the larger absolute
                        ; value.

.MU9
 EOR T                  ; If we get here from the BCS above, then |A| >= |S|,
                        ; so we want to give the result the same sign as
                        ; argument A, so if argument A was negative, we flip
                        ; the sign of the result with an EOR (to make it
                        ; negative)

 RTS                    ; Return from subroutine
}

\ *****************************************************************************
\ Subroutine: TIS1
\
\ Tidy subroutine 1  X.A =  (-X*A  + (R.S))/96
\ *****************************************************************************

.TIS1                   ; Tidy subroutine 1  X.A =  (-X*A  + (R.S))/96
{
 STX Q
 EOR #128               ; flip sign of Acc
 JSR MAD                ; multiply and add (X,A) =  -X*A  + (R,S)

.DVID96                 ; Their comment A=A/96: answer is A*255/96
 TAX
 AND #128               ; hi sign
 STA T
 TXA
 AND #127               ; hi A7
 LDX #254               ; slide counter
 STX T1

.DVL3                   ; roll T1  clamp Acc to #96 for rotation matrix unity
 ASL A
 CMP #96                ; max 96
 BCC DV4                ; skip subtraction
 SBC #96

.DV4                    ; skip subtraction
 ROL T1
 BCS DVL3               ; loop T1
 LDA T1
 ORA T                  ; hi sign
 RTS
}

\ *****************************************************************************
\ Subroutine: DV42
\
\ Travel step of dust particle front/rear
\ *****************************************************************************

.DV42                   ; travel step of dust particle front/rear
{
 LDA SZ,Y               ; dustz
}

\ *****************************************************************************
\ Subroutine: DV41
\
\ P.R = speed/ (ZZ/8) Called by STARS2 left/right
\ *****************************************************************************

.DV41                   ; P.R = speed/ (ZZ/8) Called by STARS2 left/right
{
 STA Q
 LDA DELTA              ; speed, how far has dust moved based on its z-coord
}

\ *****************************************************************************
\ Subroutine: DVID4
\
\ P-R=A/Qunsg \ P.R = A/Q unsigned  called by compass in Block E
\ *****************************************************************************

.DVID4                  ; P-R=A/Qunsg \ P.R = A/Q unsigned  called by compass in Block E
{
 LDX #8                 ; counter
 ASL A
 STA P
 LDA #0

.DVL4                   ; counter X
 ROL A
 BCS DV8                ; Acc carried
 CMP Q
 BCC DV5                ; skip subtraction

.DV8                    ; Acc carried
 SBC Q
 SEC                    ; carry gets set

.DV5                    ; skip subtraction
 ROL P                  ; hi
 DEX
 BNE DVL4               ; loop X, hi left in P.
 JMP LL28+4             ; Block G remainder R for A*256/Q
}

\ *****************************************************************************
\ Subroutine: DVID3B2
\
\ Divide 3 bytes by 2 bytes, K = P.A/INWK_z for planet, Xreg protected.
\ *****************************************************************************

.DVID3B2                ; Divide 3 bytes by 2 bytes, K = P.A/INWK_z for planet, Xreg protected.
{
 STA P+2                ; num sg
 LDA INWK+6             ; z coord lo
 STA Q
 LDA INWK+7             ; z coord hi
 STA R
 LDA INWK+8             ; z coord sg
 STA S

.DVID3B                 ; K (3bytes)=P(3bytes)/S.R.Q. aprx  Acc equiv K(0)
 LDA P                  ; num lo
 ORA #1                 ; avoid 0
 STA P
 LDA P+2                ; num sg
 EOR S                  ; zsg
 AND #128               ; extract sign
 STA T
 LDY #0                 ; counter
 LDA P+2                ; num sg
 AND #127               ; will look at lower 7 bits of Acc in.

.DVL9                   ; counter Y up
 CMP #&40               ; object very far away?
 BCS DV14               ; scaled, exit Ycount
 ASL P
 ROL P+1
 ROL A                  ; 3 bytes
 INY
 BNE DVL9               ; loop Y

.DV14                   ; scaled, exited Ycount
 STA P+2                ; big numerator
 LDA S                  ; zsg
 AND #127               ; denom sg7
 BMI DV9                ; can't happen

.DVL6                   ; counter Y back down, roll S.
 DEY                    ; scale Y back
 ASL Q                  ; denom lo
 ROL R
 ROL A                  ; hi S
 BPL DVL6               ; loop roll S until Abit7 set.

.DV9                    ; bmi cant happen?
 STA Q                  ; mostly empty so now reuse as hi denom
 LDA #254               ; Xreg protected so can't LL28+4
 STA R
 LDA P+2                ; big numerator
 JSR LL31               ; R now =A*256/Q

 LDA #0                 ; K1to3 = 0
 STA K+1
 STA K+2
 STA K+3
 TYA                    ; Y counter for scale
 BPL DV12               ; Ycount +ve
 LDA R                  ; else Y count is -ve, Acc = remainder.

.DVL8                   ; counter Y up
 ASL A                  ; boost up
 ROL K+1
 ROL K+2
 ROL K+3
 INY
 BNE DVL8               ; loop Y up
 STA K                  ; lo
 LDA K+3                ; sign
 ORA T
 STA K+3
 RTS

.DV13                   ; Ycount zero \ K(1to2) already = 0
 LDA R                  ; already correct
 STA K                  ; lo
 LDA T                  ; sign
 STA K+3
 RTS

.DV12                   ; Ycount +ve
 BEQ DV13               ; Ycount zero, up.
 LDA R                  ; else reduce remainder

.DVL10                  ; counter Y reduce
 LSR A
 DEY
 BNE DVL10              ; loop Y reduce
 STA K                  ; lo
 LDA T                  ; sign
 STA K+3
 RTS
}

\ *****************************************************************************
\ Subroutine: cntr
\
\ Center ship indicators
\ *****************************************************************************

.cntr                   ; Center ship indicators
{
 LDA DAMP               ; damping toggle
 BNE RE1                ; rts
 TXA
 BPL BUMP               ; nudge up
 DEX
 BMI RE1                ; rts

.BUMP                   ; counter X  nudge up
 INX
 BNE RE1                ; rts

.REDU                   ; reduce, nudge down.
 DEX
 BEQ BUMP               ; nudge up

.RE1                    ; rts
 RTS
}

\ *****************************************************************************
\ Subroutine: BUMP2
\
\ Exposed labels: RE2
\
\ Increase ("bump up") X by A, where X is either the current rate of pitch or
\ the current rate of roll.
\
\ The rate of pitch or roll ranges from 1 to 255 with 128 as the centre point.
\ This is the amount by which the pitch or roll is currently changing, so 1
\ means it is decreasing at the maximum rate, 128 means it is not changing,
\ and 255 means it is increasing at the maximum rate. These values correspond
\ to the line on the DC or RL indicators on the dashboard, with 1 meaning full
\ left, 128 meaning the middle, and 255 meaning full right.
\
\ If bumping up X would push it past 255, then X is set to 255.
\
\ If keyboard auto-recentre is configured and the result is less than 128, we
\ bump X up to the mid-point, 128. This is the equivalent of having a roll or
\ pitch in the left half of the indicator, when increasing the roll or pitch
\ should jump us straight to the mid-point.
\ *****************************************************************************

.BUMP2
{
 STA T                  ; Store argument A in T so we can restore it later

 TXA                    ; Copy argument X into A

 CLC                    ; Clear the carry flag so we can do addition without
                        ; the carry flag affecting the result
                    
 ADC T                  ; Set X = A = argument X + argument A
 TAX

 BCC RE2                ; If carry is clear, then we didn't overflow, so jump
                        ; to RE2 to auto-recentre and return the result

 LDX #255               ; We have an overflow, so set X to the maximum possible
                        ; value, 255

.^RE2
 BPL RE3+2              ; If X has bit 7 clear (i.e. the result < 128), then
                        ; jump to RE3+2 below to do an auto-recentre, if
                        ; configured, because the result is on the left side of
                        ; the centre point of 128

                        ; Jumps to RE2+2 end up here

 LDA T                  ; Restore the original argument A into A

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: REDU2
\
\ Exposed labels: RE3
\
\ Reduce X by A, where X is either the current rate of pitch or the current
\ rate of roll.
\
\ The rate of pitch or roll ranges from 1 to 255 with 128 as the centre point.
\ This is the amount by which the pitch or roll is currently changing, so 1
\ means it is decreasing at the maximum rate, 128 means it is not changing,
\ and 255 means it is increasing at the maximum rate. These values correspond
\ to the line on the DC or RL indicators on the dashboard, with 1 meaning full
\ left, 128 meaning the middle, and 255 meaning full right.
\
\ If reducing X would bring it below 1, then X is set to 1.
\
\ If keyboard auto-recentre is configured and the result is greater than 128, we
\ reduce X down to the mid-point, 128. This is the equivalent of having a roll or
\ pitch in the right half of the indicator, when decreasing the roll or pitch
\ should jump us straight to the mid-point.
\ *****************************************************************************

.REDU2
{
 STA T                  ; Store argument A in T so we can restore it later

 TXA                    ; Copy argument X into A

 SEC                    ; Set the carry flag so we can do subtraction without
                        ; the carry flag affecting the result

 SBC T                  ; Set X = A = argument X - argument A
 TAX

 BCS RE3                ; If carry is set, then we didn't underflow, so jump
                        ; to RE3 to auto-recentre and return the result

 LDX #1                 ; We have an underflow, so set X to the minimum possible
                        ; value, 1

.^RE3
 BPL RE2+2              ; If X has bit 7 clear (i.e. the result < 128), then
                        ; jump to RE2+2 above to return the result as is,
                        ; because the result is on the left side of the centre
                        ; point of 128, so we don't need to auto-centre

                        ; Jumps to RE3+2 end up here

                        ; If we get here, then we need to apply auto-recentre, if
                        ; it is configured

 LDA DJD                ; If keyboard auto-recentre is not configured, then
 BNE RE2+2              ; jump to RE2+2 to restore A and return

 LDX #128               ; If keyboard auto-recentre is configured, set X to 128
 BMI RE2+2              ; (the middle of our range) and jump to RE2+2 to
                        ; restore A and return
}

\ *****************************************************************************
\ Subroutine: ARCTAN
\
\ A=TAN-1(P/Q) \ A=arctan (P/Q)  called from block E
\ *****************************************************************************

.ARCTAN                 ; A=TAN-1(P/Q) \ A=arctan (P/Q)  called from block E
{
 LDA P
 EOR Q
 STA T1                 ; quadrant info
 LDA Q
 BEQ AR2                ; Q=0 so set angle to 63, pi/2
 ASL A                  ; drop sign
 STA Q
 LDA P
 ASL A                  ; drop sign
 CMP Q
 BCS AR1                ; swop A and Q as A >= Q
 JSR ARS1               ; get Angle for A*32/Q from table.
 SEC

.AR4                    ; sub o.k
 LDX T1
 BMI AR3                ; -ve quadrant
 RTS

.AR1                    ; swop A and Q
 LDX Q
 STA Q
 STX P
 TXA
 JSR ARS1               ; get Angle for A*32/Q from table.
 STA T                  ; angle
 LDA #64                ; next range of angle, pi/4 to pi/2
 SBC T
 BCS AR4                ; sub o.k

.AR2                    ; set angle to 90 degrees
 LDA #63
 RTS

.AR3                    ; -ve quadrant
 STA T                  ; angle
 LDA #128               ; pi
\SEC
 SBC T                  ; A = 128-T, so now covering range pi/2 to pi correctly
 RTS

.ARS1                   ; get Angle for A*32/Q from table.
 JSR LL28               ; BFRDIV R=A*256/Q
 LDA R
 LSR A
 LSR A
 LSR A                  ; 31 max.
 TAX                    ; index into table at end of words data
 LDA ACT,X
 RTS
}

\ *****************************************************************************
\ Variable: ACT
\
\ Arctan table.
\ *****************************************************************************

.ACT
{
FOR I%,0,31
;I%?O%=INT(128/PI*ATN(I%/32)+.5)
 EQUB  INT(128/PI*ATN(I%/32)+.5)
NEXT
;P%=P%+32
;O%=O%+32
}

\ *****************************************************************************
\ Subroutine: WARP
\
\ Jump J key was hit. Esc, cargo, asteroid, transporter dragged with you.
\ *****************************************************************************

.WARP                   ; Jump J key was hit. Esc, cargo, asteroid, transporter dragged with you.
{
 LDA MANY+AST
 CLC
 ADC MANY+ESC
 CLC                    ; Not in ELITEC.TXT, but in ELTC source image

 ADC MANY+OIL
 TAX
 LDA FRIN+2,X           ; more entries than just junk?
 ORA SSPR               ; space station present
 ORA MJ                 ; mis-jump
 BNE WA1                ; Warning noise #40 jump failed
 LDY K%+8               ; planet zsg
 BMI WA3                ; planet behind
 TAY                    ; A = Y = 0 for planet
 JSR MAS2               ; or'd x,y,z coordinate of &902+Y to A.
\LSR A                  ; ignore lowest bit of sg
\BEQ WA1                ; Warning, as planet too close
 CMP #2
 BCC WA1                ; Not in ELITEC.TXT, but in ELTC source image

.WA3                    ; planet behind
 LDY K%+NI%+8           ; Sun zsg
 BMI WA2                ; sun behind
 LDY #NI%               ; NI% for Sun
 JSR m                  ; max of x,y,z at &902+Y to A.
\LSR A                  ; ignore lowest bit of sg
\BEQ WA1                ; Warning, as Sun too close
 CMP #2
 BCC WA1                ; Not in ELITEC.TXT, but in ELTC source image

.WA2                    ; sun behind, Shift.
 LDA #&81               ; shift sun and planet zsg
 STA S                  ; hi
 STA R                  ; lo
 STA P                  ; lo
 LDA K%+8               ; planet zsg
 JSR ADD                ; (A X) = (A P) + (S R) = &81.zsg + &81.&81
 STA K%+8               ; allwk+8
 LDA K%+NI%+8           ; Sun zsg
 JSR ADD                ; (A X) = (A P) + (S R)
 STA K%+NI%+8           ; allwk+37+8

 LDA #1                 ; menu id
 STA QQ11
 STA MCNT               ; move count
 LSR A                  ; #0
 STA EV                 ; extra vessels
 LDX VIEW               ; forward
 JMP LOOK1              ; start view X

.WA1                    ; Warning sound
 LDA #40                ; noise #40
 JMP NOISE
}

\ *****************************************************************************
\ Subroutine: LASLI
\
\ Laser lines
\ *****************************************************************************

.LASLI                  ; laser lines
{
 JSR DORND              ; do random, new A, X.
 AND #7
 ADC #Y-4               ; below center of screen
 STA LASY
 JSR DORND              ; do random, new A, X.
 AND #7
 ADC #X-4               ; left of center
 STA LASX
 LDA GNTMP              ; gun temperature
 ADC #8                 ; heat up laser temperature
 STA GNTMP
 JSR DENGY              ; drain energy by 1 for active ECM pulse
}

\ *****************************************************************************
\ Subroutine: LASLI2
\
\ Stops drawing laser lines early for pulse laser
\ *****************************************************************************

.LASLI2
{
 LDA QQ11               ; If not zero then not a space view
 BNE PU1-1              ; rts
 LDA #32                ; xleft
 LDY #224               ; xright
 JSR las                ; (a few lines below) twice
 LDA #48                ; new xleft
 LDY #208               ; new xright

.las
 STA X2
 LDA LASX               ; center-X
 STA X1
 LDA LASY               ; center-Y
 STA Y1
 LDA #2*Y-1             ; bottom of screen
 STA Y2
 JSR LOIN               ; from center (X1,Y1) to bottom left (X2,Y2)
 LDA LASX
 STA X1
 LDA LASY
 STA Y1
 STY X2
 LDA #2*Y-1
 STA Y2
 JMP LOIN
}

\ *****************************************************************************
\ Subroutine: PLUT
\
\ inwk not forward view, called from MA26
\ *****************************************************************************

.PLUT
{
 LDX VIEW
 BNE PU1
 RTS
}

.PU1                    ; INWK not forward view, X >0
{
 DEX                    ; view--
 BNE PU2                ; view was 2,3 not rear which needs x and z flipped

 LDA INWK+2
 EOR #128               ; flip xsg
 STA INWK+2
 LDA INWK+8
 EOR #128               ; flip zsg
 STA INWK+8
 LDA INWK+10
 EOR #128               ; flip rotmat0x hi
 STA INWK+10
 LDA INWK+14
 EOR #128               ; flip rotmat0z hi
 STA INWK+14
 LDA INWK+16
 EOR #128               ; rotmat1x hi
 STA INWK+16

 LDA INWK+20
 EOR #128               ; rotmat1z hi
 STA INWK+20
 LDA INWK+22
 EOR #128               ; rotmat2x hi
 STA INWK+22
 LDA INWK+26
 EOR #128               ; rotmat2z hi
 STA INWK+26
 RTS

.PU2                    ; other views  2,3
 LDA #0
 CPX #2                 ; if X >= 2 then C set. Right View.
 ROR A                  ; any carry
 STA RAT2               ; 0 for view 3, 128 for view 4
 EOR #128               ; flip
 STA RAT                ; 128 for view 3, 0 for view 4

 LDA INWK               ; xlo
 LDX INWK+6             ; zlo
 STA INWK+6
 STX INWK               ; xlo and zlo swopped
 LDA INWK+1             ; xhi
 LDX INWK+7             ; zhi
 STA INWK+7
 STX INWK+1             ; xhi and zhi swopped
 LDA INWK+2             ; xsg
 EOR RAT
 TAX                    ; xsg flipped
 LDA INWK+8             ; zsg
 EOR RAT2
 STA INWK+2             ; xsg
 STX INWK+8             ; zsg swopped with xsg flipped

 LDY #9                 ; rotmat0x lo
 JSR PUS1               ; swop rotmat x and z

 LDY #15                ; rotmat1x lo
 JSR PUS1               ; swop rotmat x and z

 LDY #21                ; rotmat2x lo

.PUS1                   ; swop rotmat x and z
 LDA INWK,Y
 LDX INWK+4,Y
 STA INWK+4,Y
 STX INWK,Y             ; lo swopped
 LDA INWK+1,Y
 EOR RAT                ; 128 for view 3, 0 for view 4
 TAX                    ; flipped inwk+1,y
 LDA INWK+5,Y
 EOR RAT2               ; 0 for view 3, 128 for view 4
 STA INWK+1,Y
 STX INWK+5,Y
}

.LO2
{
 RTS
}

\ *****************************************************************************
\ Subroutine: LQ
\
\ new view X, Acc = 0
\ *****************************************************************************

.LQ                     ; new view X, Acc = 0
{
 STX VIEW               ; laser mount
 JSR TT66               ; box border with menu id QQ11 set to Acc
 JSR SIGHT              ; laser cross-hairs
 JMP NWSTARS            ; new dust field
}

\ *****************************************************************************
\ Subroutine: LOOK1
\
\ Start view X
\ *****************************************************************************

.LOOK1                  ; Start view X
{
 LDA #0                 ; menu id is space view
 LDY QQ11
 BNE LQ                 ; new view X, Acc = 0.
 CPX VIEW
 BEQ LO2                ; rts as view unchanged
 STX VIEW               ; else new view
 JSR TT66               ; box border with QQ11 set to Acc
 JSR FLIP               ; switch dusty and dustx
 JSR WPSHPS             ; wipe ships on scanner
}

\ *****************************************************************************
\ Subroutine: SIGHT
\
\ Laser cross-hairs
\ *****************************************************************************

.SIGHT                  ; Laser cross-hairs
{
 LDY VIEW
 LDA LASER,Y
 BEQ LO2                ; no laser cross-hairs, rts
 LDA #128               ; xscreen mid
 STA QQ19
 LDA #Y-24              ; #Y-24 = #72 yscreen mid
 STA QQ19+1
 LDA #20                ; size of cross hair
 STA QQ19+2
 JSR TT15               ; the cross hair using QQ19(0to2)
 LDA #10                ; negate out small cross-hairs
 STA QQ19+2
 JMP TT15               ; again, negate out small cross-hairs.
}

\ *****************************************************************************
\ Subroutine: TT66-2
\
\ Box border with QQ11 set to Acc = 1
\ *****************************************************************************
 LDA #1

\ *****************************************************************************
\ Subroutine: TT66
\
\ Box border with QQ11 set to Acc
\ *****************************************************************************

.TT66                   ; Box border with QQ11 set to Acc
{
 STA QQ11               ; menu id, zero is a titled space view.
}

\ *****************************************************************************
\ Subroutine: TTX66
\
\ Clear the top part of the screen (mode 4) and draw a box border
\ *****************************************************************************

.TTX66                  ; New box
{
 LDA #128               ; set bit7 One uppercase letter
 STA QQ17               ; flag for flight tokens
 ASL A
 STA LASCT              ; Acc =0, is LAS2 in ELITEC.TXT
 STA DLY                ; delay printing
 STA de                 ; clear flag for item + destroyed
 LDX #&60               ; screen hi page start

.BOL1                   ; box loop 1, counter X
 JSR ZES1               ; zero page X
 INX                    ; next page
 CPX #&78               ; last screen page
 BNE BOL1               ; loop X

 LDX QQ22+1
 BEQ BOX                ; skip if no outer hyperspace countdown
 JSR ee3                ; else reprint hyperspace countdown in X
}

.BOX                    ; front view box but no title if menu id > 0
{
 LDY #1                 ; Y text cursor to top
 STY YC
 LDA QQ11               ; menu id
 BNE tt66
 LDY #11                ; X text cursor indent
 STY XC
 LDA VIEW
 ORA #&60               ; build token = front rear
 JSR TT27               ; process flight text token
 JSR TT162              ; white space
 LDA #175               ; token = VIEW
 JSR TT27

.tt66                   ; no view title
 LDX #0                 ; top horizontal line
 STX X1
 STX Y1
 STX QQ17               ; printing flag all Upper case
 DEX                    ; #255
 STX X2
 JSR HLOIN              ; horizontal line  X1,X2,Y1. Yreg protected.

 LDA #2                 ; 2 then 1, 0, 255, 254
 STA X1
 STA X2
 JSR BOS2               ; do twice

.BOS2
 JSR BOS1               ; do twice

.BOS1
 LDA #0                 ; bottom of screen
 STA Y1
 LDA #2*Y-1             ; #(2*Y-1) is top of screen
 STA Y2
 DEC X1
 DEC X2
 JMP LOIN               ; line using (X1,Y1), (X2,Y2) Yreg protected.
}

\ *****************************************************************************
\ Subroutine: DELAY-5
\
\ Short delay
\ *****************************************************************************

 LDY #2
 EQUB &2C               ; Skips next instruction by turning it into &2C &A0 &08
                        ; or BIT &08A0, which does nothing bar affecting the
                        ; flags

\ *****************************************************************************
\ Subroutine: DEL8
\
\ Delay counter = 8
\ *****************************************************************************

.DEL8
{
 LDY #8                 ; Delay counter = 8
}

\ *****************************************************************************
\ Subroutine: DELAY
\
\ Yreg loaded with length of delay counter
\ *****************************************************************************

.DELAY                  ; Yreg loaded with length of delay counter
{
 JSR WSCAN              ; Wait for line scan, ie whole frame completed.
 DEY
 BNE DELAY              ; loop Y
 RTS
}

\ *****************************************************************************
\ Subroutine: hm
\
\ Move hyperspace cross-hairs
\ *****************************************************************************

.hm                     ; move hyperspace cross-hairs
{
 JSR TT103              ; erase small cross hairs at target hyperspace system
 JSR TT111              ; closest to QQ9,10, then Sys Data.
 JSR TT103              ; draw small cross hairs at target hyperspace system
 LDA QQ11
 BEQ SC5
}

\ *****************************************************************************
\ Subroutine: CLYNS
\
\ Clear screen rows, Yreg set to 0.
\ *****************************************************************************

.CLYNS                  ; Clear screen rows, Yreg set to 0.
{
 LDA #20                ; Y text cursor set few lines from bottom
 STA YC
 LDA #&75               ; page near bottom of screen
 STA SC+1
 LDA #7                 ; screen lo
 STA SC
 JSR TT67               ; Next row ; Call TT67, which prints a newline
 LDA #0                 ; most of bytes on Row set to Acc
 JSR LYN                ; Row 1
 INC SC+1
 JSR LYN
 INC SC+1
 INY                    ; X text cursor = 1
 STY XC
}

\ *****************************************************************************
\ Subroutine: LYN
\
\ Exposed labels: SC5
\
\ Most of bytes on Row (2) set to Acc.
\ *****************************************************************************

.LYN                    ; most of bytes on Row (2) set to Acc.
{
 LDY #233               ; near far right

.EE2                    ; counter Y  233to0
 STA (SC),Y
 DEY                    ; next column to left
 BNE EE2                ; loop Y

.^SC5
 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: SCAN
\
\ Ships on Scanner - last code written
\ *****************************************************************************

.SCAN                   ; ships on Scanner - last code written
{
 LDA INWK+31            ; display explosion state|missiles
 AND #16                ; dont show on scanner if bit4 clear, invisible.
 BEQ SC5                ; rts
 LDA TYPE               ; ship type
 BMI SC5                ; dont show planet, rts
 LDX #&FF               ; default scanner colour Yellow
\CMP #TGL
\BEQ SC49
 CMP #MSL               ; missile
 BNE P%+4               ; not missile
 LDX #&F0               ; scanner colour updated for missile to Red
\CMP #AST
\BCC P%+4
\LDX #&F
\.SC49
 STX COL                ; the colour for stick
 LDA INWK+1             ; xhi
 ORA INWK+4             ; yhi
 ORA INWK+7             ; zhi
 AND #&C0               ; too far away?
 BNE SC5                ; rts

 LDA INWK+1             ; xhi
 CLC                    ; build stick xcoord
 LDX INWK+2             ; xsg
 BPL SC2                ; xsg +ve
 EOR #&FF               ; else flip
 ADC #1

.SC2                    ; xsg +ve
 ADC #123               ; xhi+#123
 STA X1                 ; Xscreen for stick

 LDA INWK+7
 LSR A                  ; zhi
 LSR A                  ; Acc = zhi /4
 CLC                    ; onto zsg
 LDX INWK+8
 BPL SC3                ; z +ve
 EOR #&FF               ; else
 SEC                    ; flip zhi/4

.SC3                    ; z +ve
 ADC #35                ; zhi/4+ #35
 EOR #&FF               ; flip to screen lo
 STA SC                 ; store Z component of stick base

 LDA INWK+4             ; yhi
 LSR A                  ; Acc = yhi/2
 CLC                    ; onto ysg
 LDX INWK+5
 BMI SCD6               ; y +ve
 EOR #&FF               ; else flip yhi/2
 SEC

.SCD6                   ; y +ve , now add to z-component
 ADC SC                 ; add Z component of stick base
 BPL ld246              ; stick goes up
 CMP #194               ; >= #194 ?
 BCS P%+4               ; skip min at #194
 LDA #194               ; clamp y min
 CMP #247               ; < #247 ?
 BCC P%+4               ; skip max at #246

.ld246                  ; stick goes up
 LDA #246               ; clamp y max
 STA Y1                 ; Yscreen for stick head
 SEC                    ; sub z-component to leave y length
 SBC SC
 PHP                    ; push sign
\BCS SC48
\EOR #&FF
\ADC #1
.SC48
 PHA                    ; sub result used as counter
 JSR CPIX4              ; big flag on stick, at (X1,Y1)
 LDA CTWOS+1,X          ; recall mask
 AND COL                ; the colour
 STA X1                 ; colour temp
 PLA                    ; sub result used as counter
 PLP                    ; sign info
 TAX                    ; sub result used as counter
 BEQ RTS                ; no stick height, rts
 BCC RTS+1              ; -ve stick length

.VLL1                   ; positive stick counter X.
 DEY                    ; Y was running through byte char in CPIX4
 BPL VL1                ; else reset Y to 7 for
 LDY #7                 ; next row
 DEC SC+1               ; screen hi
.VL1                    ; Y reset done
 LDA X1                 ; colour temp for stick
 EOR (SC),Y
 STA (SC),Y
 DEX                    ; next dot of stick up
 BNE VLL1               ; loop X
.RTS
 RTS
\.SCRTS+1               ; -ve stick length
 INY                    ; Y was running through byte char in CPIX4
 CPY #8                 ; hop reset
 BNE P%+6               ; Y continue
 LDY #0                 ; else reset for next row
 INC SC+1               ; screen hi

.VLL2                   ; Y continue, counter X
 INY                    ; Y was running through byte char in CPIX4
 CPY #8                 ; hop reset
 BNE VL2                ; same row
 LDY #0                 ; else reset for next row
 INC SC+1               ; screen hi

.VL2                    ; same row
 LDA X1                 ; colour temp for stick
 EOR (SC),Y
 STA (SC),Y
 INX                    ; next dot of stick down
 BNE VLL2               ; loop X
 RTS
}

\ *****************************************************************************
\ Subroutine: WSCAN
\
\ Wait for line scan
\ *****************************************************************************

.WSCAN                  ; Wait for line scan
{
 LDA #0                 ; updated by interrupt routine
 STA DL
 LDA DL
 BEQ P%-2               ; loop DL
 RTS
}

\ *****************************************************************************
\ Save output/ELTC.bin
\ *****************************************************************************

PRINT "ELITE C"
PRINT "Assembled at ", ~CODE_C%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_C%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_C%

PRINT "S.ELTC ", ~CODE_C%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_C%
SAVE "output/ELTC.bin", CODE_C%, P%, LOAD%

\ *****************************************************************************
\ ELITE D
\ *****************************************************************************

CODE_D% = P%
LOAD_D% = LOAD% + P% - CODE%

\ *****************************************************************************
\ Subroutine: tnpr
\
\ Ton/kg count, Acc = item. Exits with Acc = 1
\ *****************************************************************************

.tnpr                   ; ton count, Acc = item. Exits with Acc = 1
{
 PHA                    ; store #1
 LDX #12                ; above minerals
 CPX QQ29
 BCC kg                 ; treated as kg

.Tml                    ; Count tonnes, counter X start at 12
 ADC QQ20,X             ; tonnes added to Acc initial =1
 DEX
 BPL Tml                ; loop X
 CMP CRGO               ; max cargo, carry set is too much.
 PLA                    ; scooping added one item
 RTS

.kg                     ; scooped item QQ29 > 12
 LDY QQ29               ; market item, 0to16
 ADC QQ20,Y
 CMP #200               ; 199 kg max, carry set is too much.
 PLA                    ; scooping added one item
 RTS
}

\ *****************************************************************************
\ Subroutine: TT20
\
\ Twist the three 16-bit seeds in QQ15 (selected system) four times, to
\ generate the next system.
\ *****************************************************************************

.TT20
{
 JSR P%+3               ; This line calls the line below as a subroutine, which
                        ; does two twists before returning here, and then we
                        ; fall through to the line below for another two
                        ; twists, so the net effect of these two consecutive
                        ; JSR calls is four twists, not counting the ones
                        ; inside your head as you try to follow this process

 JSR P%+3               ; This line calls TT54 as a subroutine to do a twist,
                        ; and then falls through into TT54 to do another twist
                        ; before returning from the subroutine
}

\ *****************************************************************************
\ Subroutine: TT54
\
\ This routine twists the three 16-bit seeds in QQ15 once.
\
\ *****************************************************************************
\
\ Famously, the universe in Elite is generated procedurally, and the core of
\ this process is the set of three 16-bit seeds that describe each system in
\ the universe. Each of the eight galaxies in the game is generated in the same
\ way, by taking an initial set of seeds and "twisting" them to generate 256
\ systems, one after the other (the actual twisting process is described
\ below).

\ Specifically, given the initial set of seeds, we can generate the next system
\ in the sequence by twisting that system's seeds four times. As we do these
\ twists, we can extract the system's data from the seed values - including the
\ system name, which is generated by the subroutine cpl, where you can read
\ about how this aspect works.
\
\ It is therefore no exaggeration that the twisting process implemented below
\ is the fundamental building block of Elite's "universe in a bottle" approach,
\ which enabled the authors to squeeze eight galaxies of 256 planets out of
\ nothing more then three initial numbers and a short twisting routine (and
\ they could have had far larger galaxies and many more of them, if they had
\ wanted, but they made the wise decision to limit the number). Let's look at
\ how this twisting proces works.
\
\ The three seeds that describe a system represent three consecutive numbers in
\ a Tribonacci sequence, where each number is equal to the sum of the preceding
\ three numbers (the name is a play on Fibonacci sequence, in which each number
\ is equal to the sum of the preceding two numbers). Twisting is the process of
\ moving along the sequence by one place. So, say our seeds currently point to
\ these numbers in the sequence:
\
\   0   0   1   1   2   4   7   13   24   44   ...
\                       ^   ^    ^
\
\ so they are 4, 7 and 13, then twisting would move them all along by one
\ place, like this:
\
\   0   0   1   1   2   4   7   13   24   44   ...
\                           ^    ^    ^
\
\ giving us 7, 13 and 24. To generalise this, if we start with seeds w0, w1
\ and w2 and we want to work out their new values after we perform a twist
\ (let's call the new values x0, x1 and x2), then:
\
\   x0 = w1
\   x1 = w2
\   x2 = w0 + w1 + w2
\ 
\ So given an existing set of seeds in w0, w1 and w2, we can get the new values
\ x0, x1 and x2 simply by doing the above sums. And if we want to do the above
\ in-place without creating three new x variables, then we can do the
\ following:
\
\   tmp = w0 + w1
\   w0 = w1
\   w1 = w2
\   w2 = tmp + w1
\
\ In Elite, the numbers we're dealing with are two-byte, 16-bit numbers, and
\ because these 16-bit numbers can only hold values up to 65535, the sequence
\ wraps around at the end. But the maths is the same, it just has to be done
\ on 16-bit numbers, one byte at a time.
\
\ The seeds are stored as little-endian 16-bit numbers, so the low (least
\ significant) byte is first, followed by the high (most significant) byte.
\ Taking the case of the currently selected system, whose seeds are stored
\ in the six bytes from QQ15, that means our seed values are stored like this:
\
\       low byte  high byte
\   w0  QQ15      QQ15+1
\   w1  QQ15+2    QQ15+3
\   w2  QQ15+4    QQ15+5
\
\ If we denote the low byte of w0 as w0_lo and the high byte as w0_hi, then
\ the twist operation above can be rewritten for 16-bit values like this,
\ assuming the additions include the carry flag:
\ 
\   tmp_lo = w0_lo + w1_lo          ; tmp = w0 + w1
\   tmp_hi = w0_hi + w1_hi
\   w0_lo  = w1_lo                  ; w0 = w1
\   w0_hi  = w1_hi
\   w1_lo  = w2_lo                  ; w1 = w2
\   w1_hi  = w2_hi
\   w2_lo  = tmp_lo + w1_lo         ; w2 = tmp + w1
\   w2_hi  = tmp_hi + w1_hi
\
\ And that's exactly what this subroutine does to twist our three 16-bit
\ seeds to the next values in the sequence, using X to store tmp_lo and Y to
\ store tmp_hi.
\ *****************************************************************************

.TT54
{
 LDA QQ15               ; X = tmp_lo = w0_lo + w1_lo
 CLC
 ADC QQ15+2
 TAX

 LDA QQ15+1             ; Y = tmp_hi = w1_hi + w1_hi + carry
 ADC QQ15+3
 TAY

 LDA QQ15+2             ; w0_lo = w1_lo
 STA QQ15
 
 LDA QQ15+3             ; w0_hi = w1_hi
 STA QQ15+1
 
 LDA QQ15+5             ; w1_hi = w2_hi
 STA QQ15+3
 
 LDA QQ15+4             ; w1_lo = w2_lo
 STA QQ15+2
 
 CLC                    ; w2_lo = X + w1_lo
 TXA       
 ADC QQ15+2
 STA QQ15+4

 TYA                    ; w2_hi = Y + w1_hi + carry
 ADC QQ15+3
 STA QQ15+5

 RTS                    ; The twist is complete so return from the subroutine
}

\ *****************************************************************************
\ Subroutine: TT146
\
\ Print the distance to the selected system in light years, if non-zero. If
\ zero, just move the text cursor down a line.
\
\ Specifically, if the distance in QQ8 is non-zero, print token 31 ("DISTANCE"),
\ then a colon, then the distance to one decimal place, then token 35 ("LIGHT
\ YEARS"). If the distance is zero, move the cursor down one
\ line.
\ *****************************************************************************


.TT146                  ; Distance in Light years
 LDA QQ8                ; distance in 0.1 LY units
 ORA QQ8+1
 BNE TT63               ; if not zero, Distance in Light years
 INC YC                 ; else just new text line
 RTS

.TT63                   ; Distance in Light years
 LDA #191               ; token = DISTANCE
 JSR TT68               ; process token followed by colon

 LDX QQ8
 LDY QQ8+1
 SEC                    ; with decimal point
 JSR pr5                ; print 4 digits of XloYhi
 LDA #195               ; token = LIGHT YEARS

\ *****************************************************************************
\ Subroutine: TT60
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). Then print a paragraph break (a blank line between
\ paragraphs) by moving the cursor down a line, setting Sentence Case, and then
\ printing a newline.
\
\ Arguments:
\
\   A           The text token to be printed
\ *****************************************************************************

.TT60
{
 JSR TT27               ; Print the text token in A and fall through into TTX69
                        ; to print the paragraph break
}

\ *****************************************************************************
\ Subroutine: TTX69
\
\ Print a paragraph break (a blank line between paragraphs) by moving the cursor
\ down a line, setting Sentence Case, and then printing a newline.
\ *****************************************************************************

.TTX69
{
 INC YC                 ; Move the text cursor down a line and then fall
                        ; through into TT69 to set Sentence Case and print a
                        ; newline
}

\ *****************************************************************************
\ Subroutine: TT69
\
\ Set Sentence Case and print a newline.
\ *****************************************************************************

.TT69
{
 LDA #128               ; Set QQ17 to 128, which denotes Sentence Case, and
 STA QQ17               ; fall througn into TT67 to print a newline
}

\ *****************************************************************************
\ Subroutine: TT67
\
\ Print a newline
\ *****************************************************************************

.TT67
{
 LDA #13                ; Load a newline character into A

 JMP TT27               ; Print the text token in A and return from the
                        ; subroutine using a tail call
}

\ *****************************************************************************
\ Subroutine: TT70
\
\ Display "MAINLY " and jump to TT72. This subroutine is called by TT25 when
\ displaying a system's economy.
\
\ *****************************************************************************

.TT70
{
 LDA #173               ; Print recursive token 13 ("MAINLY ")
 JSR TT27

 JMP TT72               ; Jump to TT72 to continue printing system data as part
                        ; of routine TT25
}

\ *****************************************************************************
\ Subroutine: spc
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token) followed by a space.
\
\ Arguments:
\
\   A           The text token to be printed
\ *****************************************************************************

.spc
{
 JSR TT27               ; Print the text token in A

 JMP TT162              ; Print a space and return from the subroutine using a
                        ; tail call
}

\ *****************************************************************************
\ Subroutine: TT25
\
\ Exposed labels: TT72
\
\ Display Data on System (red key f6).
\
\ *****************************************************************************
\
\ Although most system data is calculated in TT24 below and stored in locations
\ QQ3 to QQ7, the species type and average radius are not. Here's how they are
\ calculated.
\
\ Species type
\ ------------
\ The species type is either Human Colonials, or it's an alien species that
\ consists of up to three adjectives and a species name (so you can get
\ anything from "Rodents" and "Fierce Frogs" to "Black Fat Felines" and "Small
\ Yellow Bony Lobsters").
\ 
\ As with the rest of the system data, the species is built from various bits
\ in the seeds. Specifically, all the bits in w2_hi are used, along with bits
\ 0-2 of w0_hi and w1_hi, and bit 7 of w2_lo.
\ 
\ First, we check bit 7 of w2_lo. It it is clear, print "Human Colonials" and
\ stop, otherwise this is an alien species, so we move onto the following
\ steps. (In the following steps, the potential range of the calculated value
\ of A is 0-7, and if a match isn't made, nothing is printed for that step.)
\ 
\   1. Set A = bits 2-4 of w2_hi
\   
\     * If A = 0,  print "Large "
\     * If A = 1,  print "Fierce "
\     * If A = 2,  print "Small "
\   
\   2. Set A = bits 5-7 of w2_hi
\   
\     * If A = 0,  print "Green "
\     * If A = 1,  print "Red "
\     * If A = 2,  print "Yellow "
\     * If A = 3,  print "Blue "
\     * If A = 4,  print "Black "
\     * If A = 5,  print "Harmless "
\   
\   3. Set A = bits 0-2 of (w0_hi EOR w1_hi)
\   
\     * If A = 0,  print "Slimy "
\     * If A = 1,  print "Bug-Eyed "
\     * If A = 2,  print "Horned "
\     * If A = 3,  print "Bony "
\     * If A = 4,  print "Fat "
\     * If A = 5,  print "Furry "
\   
\   4. Add bits 0-1 of w2_hi to A from step 3, and take bits 0-2 of the result
\   
\     * If A = 0,  print "Rodents"
\     * If A = 1,  print "Frogs"
\     * If A = 2,  print "Lizards"
\     * If A = 3,  print "Lobsters"
\     * If A = 4,  print "Birds"
\     * If A = 5,  print "Humanoids"
\     * If A = 6,  print "Felines"
\     * If A = 7,  print "Insects"
\ 
\ So if we print an adjective at step 3, then the only options for the species
\ name are from A to A + 3 (because we add a 2-bit number) in step 4. So only
\ certain combinations are possible:
\ 
\   * Only rodents, frogs, lizards and lobsters can be slimy
\   * Only frogs, lizards, lobsters and birds can be bug-eyed
\   * Only lizards, lobsters, birds and humanoids can be horned
\   * Only lobsters, birds, humanoids and felines can be bony
\   * Only birds, humanoids, felines and insects can be fat
\   * Only humanoids, felines, insects and rodents can be furry
\ 
\ So however hard you look, you will never find slimy humanoids, bony insects,
\ fat rodents or furry frogs, which is probably for the best.
\
\ Average radius
\ --------------
\ The average radius is calculated as follows:
\ 
\   ((w2_hi AND %1111) + 11) * 256 + w1_hi
\ 
\ The highest average radius is (15 + 11) * 256 + 255 = 6911 km, and the lowest
\ is 11 * 256 = 2816 km.
\ *****************************************************************************

.TT25
{
 JSR TT66-2             ; Clear the top part of the screen and draw a box
                        ; border, with QQ11 set to 1 (so TT66 does not show the
                        ; name of the space view at the bottom)

 LDA #9                 ; Set the text cursor XC to column 9
 STA XC

 LDA #163               ; Print recursive token 3 as a title in capitals at
 JSR TT27               ; the top ("DATA ON {selected system name}")

 JSR NLIN               ; Draw a horizontal line underneath the title

 JSR TTX69              ; Print a paragraph break and set Sentence Case

 INC YC                 ; Move the text cursor down one more line

 JSR TT146              ; If the distance to this system is non-zero, print
                        ; "DISTANCE", then the distance, "LIGHT YEARS" and a
                        ; paragraph break, otherwise just move the cursor down
                        ; a line

 LDA #194               ; Print recursive token 34 ("ECONOMY") followed by
 JSR TT68               ; a colon

 LDA QQ3                ; The system economy is determined by the value in QQ3,
                        ; so fetch it into A. First we work out the system's
                        ; prosperity as follows:
                        ;
                        ;   QQ3 = 0 or 5 = %000 or %101 = Rich
                        ;   QQ3 = 1 or 6 = %001 or %110 = Average
                        ;   QQ3 = 2 or 7 = %010 or %111 = Poor
                        ;   QQ3 = 3 or 4 = %011 or %100 = Mainly
        
 CLC                    ; If (QQ3 + 1) >> 1 = %10, i.e. if QQ3 = %011 or %100
 ADC #1                 ; (3 or 4), then call TT70, which prints "MAINLY " and
 LSR A                  ; jumps down to TT72 to print the type of economy
 CMP #2
 BEQ TT70
 
 LDA QQ3                ; The LSR A above shifted bit 0 of QQ3 into the carry
 BCC TT71               ; flag, so this jumps to TT71 if bit 0 of QQ3 is 0,
                        ; i.e. if QQ3 = %000, %001 or %010 (0, 1 or 2)

 SBC #5                 ; Here QQ3 = %101, %110 or %111 (5, 6 or 7), so
 CLC                    ; subtract 5 to bring it down to 0, 1 or 2 (the carry
                        ; flag is already set so the SBC will be correct)

.TT71
 ADC #170               ; A is now 0, 1 or 2, so print recursive token 10 + A.
 JSR TT27               ; This means that:
                        ;
                        ;   QQ3 = 0 or 5 prints token 10 ("RICH ")
                        ;   QQ3 = 1 or 6 prints token 11 ("AVERAGE ")
                        ;   QQ3 = 2 or 7 prints token 12 ("POOR ")

.^TT72
 LDA QQ3                ; Now to work out the type of economy, which is
 LSR A                  ; determined by bit 2 of QQ3, as follows:
 LSR A                  ;
                        ;   QQ3 bit 2 = 0 = Industrial
                        ;   QQ3 bit 2 = 1 = Agricultural
                        ;
                        ; So we fetch QQ3 into A and set A = bit 2 of QQ3 using
                        ; two right shifts (which will work as QQ3 is only a
                        ; 3-bit number)

 CLC                    ; Print recursive token 8 + A, followed by a paragraph
 ADC #168               ; break and Sentence Case, so:
 JSR TT60               ;
                        ;   QQ3 bit 2 = 0 prints token 8 ("INDUSTRIAL")
                        ;   QQ3 bit 2 = 1 prints token 9 ("AGRICULTURAL")

 LDA #162               ; Print recursive token 2 ("GOVERNMENT") followed by
 JSR TT68               ; a colon

 LDA QQ4                ; The system economy is determined by the value in QQ4,
                        ; so fetch it into A

 CLC                    ; Print recursive token 17 + A, followed by a paragraph
 ADC #177               ; break and Sentence Case, so:
 JSR TT60               ;
                        ;   QQ4 = 0 prints token 17 ("ANARCHY")
                        ;   QQ4 = 1 prints token 18 ("FEUDAL")
                        ;   QQ4 = 2 prints token 19 ("MULTI-GOVERNMENT")
                        ;   QQ4 = 3 prints token 20 ("DICTATORSHIP")
                        ;   QQ4 = 4 prints token 21 ("COMMUNIST")
                        ;   QQ4 = 5 prints token 22 ("CONFEDERACY")
                        ;   QQ4 = 6 prints token 23 ("DEMOCRACY")
                        ;   QQ4 = 7 prints token 24 ("CORPORATE STATE")

 LDA #196               ; Print recursive token 36 ("TECH.LEVEL") followed by a
 JSR TT68               ; colon

 LDX QQ5                ; Fetch the tech level from QQ5 and increment it, as it
 INX                    ; is stored in the range 0-14 but the displayed range
                        ; should be 1-15

 CLC                    ; Call pr2 to print the technology level as a 3-digit
 JSR pr2                ; number without a decimal point (by clearing the carry
                        ; flag)

 JSR TTX69              ; Print a paragraph break and set Sentence Case

 LDA #192               ; Print recursive token 32 ("POPULATION") followed by a
 JSR TT68               ; colon

 SEC                    ; Call pr2 to print the population as a 3-digit number
 LDX QQ6                ; with a decimal point (by setting the carry flag), so
 JSR pr2                ; the number printed will be population / 10

 LDA #198               ; Print recursive token 38 (" BILLION"), followed by a
 JSR TT60               ; paragraph break and Sentence Case

 LDA #'('               ; Print an opening bracket
 JSR TT27

 LDA QQ15+4             ; Now to calculate the species, so first check bit 7 of
 BMI TT75               ; w2_lo, and if it is set, jump to TT75 as this is an
                        ; alien species

 LDA #188               ; Bit 7 of w2_lo is clear, so print recursive token 28
 JSR TT27               ; ("HUMAN COLONIAL")

 JMP TT76               ; Jump to TT76 to print "S)" and a paragraph break, so
                        ; the whole species string is "(HUMAN COLONIALS)"

.TT75
 LDA QQ15+5             ; This is an alien species, and we start with the first
 LSR A                  ; adjective, so fetch bits 2-7 of w2_hi into A and push
 LSR A                  ; onto the stack so we can use this later
 PHA

 AND #7                 ; Set A = bits 0-2 of A (so that's bits 2-4 of w2_hi)

 CMP #3                 ; If A >= 3, jump to TT205 to skip the first adjective,
 BCS TT205

 ADC #227               ; Otherwise A = 0, 1 or 2, so print recursive token
 JSR spc                ; 67 + A, followed by a space, so:
                        ;
                        ;   A = 0 prints token 67 ("LARGE") and a space
                        ;   A = 1 prints token 67 ("FIERCE") and a space
                        ;   A = 2 prints token 67 ("SMALL") and a space

.TT205
 PLA                    ; Now for the second adjective, so restore A to bits
 LSR A                  ; 2-7 of w2_hi, and throw away bits 2-4 to leave
 LSR A                  ; A = bits 5-7 of w2_hi
 LSR A

 CMP #6                 ; If A >= 6, jump to TT206 to skip the second adjective
 BCS TT206

 ADC #230               ; Otherwise A = 0 to 5, so print recursive token
 JSR spc                ; 70 + A, followed by a space, so:
                        ;
                        ;   A = 0 prints token 70 ("GREEN") and a space
                        ;   A = 1 prints token 71 ("RED") and a space
                        ;   A = 2 prints token 72 ("YELLOW") and a space
                        ;   A = 3 prints token 73 ("BLUE") and a space
                        ;   A = 4 prints token 74 ("BLACK") and a space
                        ;   A = 5 prints token 75 ("HARMLESS") and a space

.TT206
 LDA QQ15+3             ; Now for the third adjective, so EOR the high bytes of
 EOR QQ15+1             ; w0 and w1 and extract bits 0-2 of the result:
 AND #7                 ;
 STA QQ19               ;   A = (w0_hi EOR w1_hi) AND %111
                        ;
                        ; storing the result in QQ19 so we can use it later

 CMP #6                 ; If A >= 6, jump to TT207 to skip the third adjective
 BCS TT207

 ADC #236               ; Otherwise A = 0 to 5, so print recursive token
 JSR spc                ; 76 + A, followed by a space, so:
                        ;
                        ;   A = 0 prints token 76 ("SLIMY") and a space
                        ;   A = 1 prints token 77 ("BUG-EYED") and a space
                        ;   A = 2 prints token 78 ("HORNED") and a space
                        ;   A = 3 prints token 79 ("BONY") and a space
                        ;   A = 4 prints token 80 ("FAT") and a space
                        ;   A = 5 prints token 81 ("FURRY") and a space

.TT207
 LDA QQ15+5             ; Now for the actual species, so take bits 0-1 of
 AND #3                 ; w2_hi, add this to the value of A that we used for
 CLC                    ; the third adjective, and take bits 0-2 of the result
 ADC QQ19
 AND #7

 ADC #242               ; A = 0 to 7, so print recursive token 82 + A, so:
 JSR TT27               ;
                        ;   A = 0 prints token 76 ("RODENT")
                        ;   A = 1 prints token 76 ("FROG")
                        ;   A = 2 prints token 76 ("LIZARD")
                        ;   A = 3 prints token 76 ("LOBSTER")
                        ;   A = 4 prints token 76 ("BIRD")
                        ;   A = 5 prints token 76 ("HUMANOID")
                        ;   A = 6 prints token 76 ("FELINE")
                        ;   A = 7 prints token 76 ("INSECT")

.TT76
 LDA #'S'               ; Print an 'S' to pluralise the species
 JSR TT27

 LDA #')'               ; And finally, print a closing bracket, followed by a
 JSR TT60               ; paragraph break and Sentence Case, to end the species
                        ; section

 LDA #193               ; Print recursive token 33 ("GROSS PRODUCTIVITY"),
 JSR TT68               ; followed by colon

 LDX QQ7                ; Fetch the 16-bit productivity value from QQ7 into
 LDY QQ7+1              ; (Y X)

 JSR pr6                ; Print (Y X) to 5 digits with no decimal point

 JSR TT162              ; Print a space

 LDA #0                 ; Set QQ17 = 0 for ALL CAPS
 STA QQ17

 LDA #'M'               ; Print 'M'
 JSR TT27

 LDA #226               ; Print recursive token 66 (" CR"), followed by a
 JSR TT60               ; paragraph break and Sentence Case

 LDA #250               ; Print recursive token 90 ("AVERAGE RADIUS"), followed
 JSR TT68               ; by a colon

                        ; The average radius is calculated like this:
                        ;
                        ;   ((w2_hi AND %1111) + 11) * 256 + w1_hi
                        ;
                        ; or, in terms of memory locations:
                        ;
                        ;   ((QQ15+5 AND %1111) + 11) * 256 + QQ15+3
                        ;
                        ; Because the multiplication is by 256, this is the
                        ; same as saying a 16-bit number, with high byte:
                        ;
                        ;   (QQ15+5 AND %1111) + 11
                        ;
                        ; and low byte:
                        ;
                        ;   QQ15+3
                        ;
                        ; so we can set this up in (Y X) and call the pr5
                        ; routine to print it out.

 LDA QQ15+5             ; Set A = QQ15+5
 LDX QQ15+3             ; Set X = QQ15+3

 AND #15                ; Set Y = (A AND %1111) + 11
 CLC
 ADC #11
 TAY

 JSR pr5                ; Print (Y X) to 5 digits, including a decimal point
                        ; if the carry flag is set

 JSR TT162              ; Print a space

 LDA #'k'               ; Print 'km', returning from the subroutine using a
 JSR TT26               ; tail call
 LDA #'m'
 JMP TT26
}

\ *****************************************************************************
\ Subroutine: TT24
\
\ Calculate system data from the seeds in QQ15 and store them in the relevant
\ locations. Specifically, this routine calculates the following from the three
\ 16-bit seeds in QQ15 (using only w0_hi, w1_hi and w1_lo):
\
\   QQ3 = economy (0-7)
\   QQ4 = government (0-7)
\   QQ5 = technology level (0-14)
\   QQ6 = population * 10 (1-71)
\   QQ7 = productivity (96-62480)
\
\ The ranges of the various values are shown in brackets. Note that the radius
\ and type of inhabitant are calculated on-the-fly in the TT25 routine when
\ the system data gets displayed, so they aren't calculated here.
\
\ *****************************************************************************
\
\ The above system statistics are generated from the system seeds, specifically
\ from parts of w0_hi, w1_hi and w1_lo. Here's how it all works.
\ 
\ Government
\ ----------
\ The government is given by a 3-bit value, taken from bits 3-5 of w1_lo. This
\ value determine the type of government as follows:
\ 
\   0 = Anarchy
\   1 = Feudal
\   2 = Multi-government
\   3 = Dictatorship
\   4 = Communist
\   5 = Confederacy
\   6 = Democracy
\   7 = Corporate State
\ 
\ The highest government value is 7 and the lowest is 0.
\
\ Economy
\ -------
\ The economy is given by a 3-bit value, taken from bits 0-2 of w0_hi. This
\ value determine the prosperity of the economy:
\ 
\   0 or 5 = %000 or %101 = Rich
\   1 or 6 = %001 or %110 = Average
\   2 or 7 = %010 or %111 = Poor
\   3 or 4 = %011 or %100 = Mainly
\ 
\ while bit 2 determines the type of economy:
\ 
\   bit 2 = %0 = Industrial
\   bit 2 = %1 = Agricultural
\ 
\ If the government is an anarchy or feudal state, we need to fix the economy
\ so it can't be rich (as that wouldn't make sense). We do this by setting bit
\ 1 of the economy value, giving possible values of %010, %011, %110, %111.
\ Looking at the prosperity list above, we can see this forces the economy to
\ be poor, mainly, average, or poor respectively, so there's now a 50% chance
\ of the system being poor, a 25% chance of it being average, and a 25% chance
\ of it being "Mainly Agricultural" or "Mainly Industrial".
\ 
\ The highest economy value is 7 and the lowest is 0.
\ 
\ Technology level
\ ----------------
\ The tech level is calculated as follows:
\ 
\   flipped economy + (w1_hi AND %11) + (government / 2)
\ 
\ where "flipped economy" is the economy value with its bits inverted (keeping
\ it as a 3-bit value, so if the economy is %001, the flipped economy is %110).
\ The division is done using LSR and the addition uses ADC, so this rounds up
\ the division for odd-numbered government types.
\ 
\ Flipping the three economy bits gives the following spread of numbers:
\ 
\   7 or 2 = %111 or %010 = Rich
\   6 or 1 = %110 or %001 = Average
\   5 or 0 = %101 or %000 = Poor
\   4 or 3 = %100 or %011 = Mainly
\ 
\ This, on average, gives a higher number to rich states compared with poor
\ states, as well as giving higher values to industrial economies compared to
\ agricultural, all of which makes a reasonable basis for a measurement of
\ technology level.
\ 
\ The highest tech level is 7 + 3 + (7 / 2) = 14 (when rounded up) and the
\ lowest is 0.
\ 
\ Population
\ ----------
\ The population is calculated as follows:
\ 
\   (tech level * 4) + economy + government + 1
\ 
\ This means that systems with higher tech levels, better economies and more
\ stable governments have higher populations, with the tech level having the
\ most influence. The number stored is actually the population * 10 (in
\ billions), so we can display it to one decimal place by calling the pr2
\ subroutine (so if the population value is 52, it means 5.2 billion).
\ 
\ The highest population is 14 * 4 + 7 + 7 + 1 = 71 (7.1 billion) and the
\ lowest is 1 (0.1 billion).
\ 
\ Productivity
\ ------------
\ The productivity is calculated as follows:
\ 
\   (flipped economy + 3) * (government + 4) * population * 8
\ 
\ Productivity is measured in millions of credits, so a productivity of 23740
\ would be displayed as "23740 M CR".
\ 
\ The highest productivity is 10 * 11 * 71 * 8 = 62480, while the lowest is 3 *
\ 4 * 1 * 8 = 96 (so the range is between 96 and 62480 million credits).
\ *****************************************************************************

.TT24
{
 LDA QQ15+1             ; Fetch w0_hi and extract bits 0-2 to determine the
 AND #7                 ; system's economy, and store in QQ3
 STA QQ3
 
 LDA QQ15+2             ; Fetch w1_lo and extract bits 3-5 to determine the
 LSR A                  ; system's government, and store in QQ4
 LSR A
 LSR A
 AND #7
 STA QQ4
 
 LSR A                  ; If government isn't anarchy or feudal, skip to TT77,
 BNE TT77               ; as we need to fix the economy of anarchy and feudal
                        ; systems so they can't be rich

 LDA QQ3                ; Set bit 1 of the economy in QQ3 to fix the economy
 ORA #2                 ; for anarchy and feudal governments
 STA QQ3

.TT77
 LDA QQ3                ; Now to work out the tech level, which we do like this:
 EOR #7                 ; 
 CLC                    ;   flipped economy + (w1_hi AND %11) + (government / 2)
 STA QQ5                ;
                        ; or, in terms of memory locations:
                        ;
                        ;   QQ5 = (QQ3 EOR %111) + (QQ15+3 AND %11) + (QQ4 / 2)
                        ;
                        ; We start by setting QQ5 = QQ3 EOR %111

 LDA QQ15+3             ; We then take the first 2 bits of w1_hi (QQ15+3) and
 AND #3                 ; add it into QQ5
 ADC QQ5
 STA QQ5

 LDA QQ4                ; And finally we add QQ4 / 2 and store the result in
 LSR A                  ; QQ5, using LSR then ADC to divide by 2, which rounds
 ADC QQ5                ; up the result for odd-numbered government types
 STA QQ5 
 
 ASL A                  ; Now to work out the population, like so:
 ASL A                  ;
 ADC QQ3                ;   (tech level * 4) + economy + government + 1
 ADC QQ4                ;
 ADC #1                 ; or, in terms of memory locations:
 STA QQ6                ;
                        ;   QQ6 = (QQ5 * 4) + QQ3 + QQ4 + 1


 LDA QQ3                ; Finally, we work out productivity, like this:
 EOR #7                 ;
 ADC #3                 ;  (flipped economy + 3) * (government + 4)
 STA P                  ;                        * population
 LDA QQ4                ;                        * 8
 ADC #4                 ;
 STA Q                  ; or, in terms of memory locations:
 JSR MULTU              ;
                        ;   QQ7 = (QQ3 EOR %111 + 3) * (QQ4 + 4) * QQ6 * 8
                        ;
                        ; We do the first step by setting P to the first
                        ; expression in brackets and Q to the second, and
                        ; calling MULTU, so now (A P) = P * Q. The highest this
                        ; can be is 10 * 11 (as the maximum values of economy
                        ; and government are 7), so the high byte of the result
                        ; will always be 0, so we actually have:
                        ;
                        ;   P = P * Q
                        ;     = (flipped economy + 3) * (government + 4)

 LDA QQ6                ; We now take the result in P and multiply by the
 STA Q                  ; population to get the productivity, by setting Q to
 JSR MULTU              ; the population from QQ6 and calling MULTU again, so
                        ; now we have:
                        ;
                        ;   (A P) = P * population

 ASL P                  ; Next we multiply the result by 8, as a 16-bit number,
 ROL A                  ; so we shift both bytes to the left three times,
 ASL P                  ; using the carry flag to carry bits from bit 7 of the
 ROL A                  ; low byte into bit 0 of the high byte
 ASL P
 ROL A

 STA QQ7+1              ; Finally, we store the productivity in two bytes, with
 LDA P                  ; the low byte in QQ7 and the high byte in QQ7+1
 STA QQ7

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: TT22
\
\ Long range galactic chart
\ *****************************************************************************

.TT22                   ; Lng Sc \ their comment \ Long range galactic chart.
{
 LDA #64                ; bit6 set for menu i.d.
 JSR TT66               ; box border with QQ11 set to A
 LDA #7                 ; indent
 STA XC
 JSR TT81               ; QQ15 loaded with rolled planet seed.
 LDA #199               ; token = GALACTIC CHART.
 JSR TT27               ; process text token
 JSR NLIN               ; no token just horizontal line at 23
 LDA #152               ; second horizontal line
 JSR NLIN2              ; horizontal line drawn at A =  #152
 JSR TT14               ; Circle with a cross hair

 LDX #0
.TT83                   ; counter X   256 systems
 STX XSAV               ; store counter
 LDX QQ15+3             ; seed w1_h is Xcoord of star
 LDY QQ15+4             ; seed w2_l is star size
 TYA
 ORA #&50               ; minimum distance away
 STA ZZ                 ; pixel distance sets star size

 LDA QQ15+1             ; seed w0_h is Ycoord*2
 LSR A                  ; /2=Ycoord
 CLC                    ; add offset to
 ADC #24                ; Ycoord of star
 STA XX15+1             ; Y1
 JSR PIXEL              ; at (X,Y) ZZ away, Yreg protected.
 JSR TT20               ; TWIST operation on QQ15(0to5)
 LDX XSAV               ; restore counter
 INX                    ; next system
 BNE TT83               ; loop X, 256 stars
 LDA QQ9                ; target planet X
 STA QQ19               ; xorg for cross-hair
 LDA QQ10               ; target planet Y
 LSR A                  ; /= 2 org for cross-hair
 STA QQ19+1             ; Y1 calculated again with this
 LDA #4                 ; target cross-hair size
 STA QQ19+2
}

\ *****************************************************************************
\ Subroutine: TT15
\
\ Cross hair using QQ19(0to2) for laser or chart
\ *****************************************************************************

.TT15                   ; cross hair using QQ19(0to2) for laser or chart
{
 LDA #24                ; default cross size
 LDX QQ11               ; menu i.d.
 BPL P%+4               ; if bit7 clear hop over lda #0
 LDA #0                 ; else Short range chart
 STA QQ19+5             ; Ycross could be #24
 LDA QQ19               ; Xorg
 SEC
 SBC QQ19+2             ; cross-hair size
 BCS TT84               ; Xorg-cross-hair ok
 LDA #0

.TT84                   ; Xorg-cross-hair ok
 STA XX15               ; left
 LDA QQ19               ; Xorg
 CLC                    ; Xorg+cross-hair size
 ADC QQ19+2
 BCC P%+4               ; no X overflow
 LDA #&FF               ; else right edge
 STA XX15+2

 LDA QQ19+1
 CLC                    ; Yorg + Ycross
 ADC QQ19+5             ; could be #24
 STA XX15+1             ; Yorg + Ycross
 JSR HLOIN              ; horizontal line  X1,Y1,X2  Yreg protected.
 LDA QQ19+1
 SEC                    ; Yorg - cross-hair size
 SBC QQ19+2
 BCS TT86               ; Yorg-cross-hair ok
 LDA #0

.TT86                   ; Yorg-cross-hair ok
 CLC
 ADC QQ19+5             ; could be #24
 STA XX15+1             ; the top-most extent
 LDA QQ19+1             ; Yorg
 CLC
 ADC QQ19+2             ; cross-hair size
 ADC QQ19+5             ; could be #24
 CMP #152               ; Ytop
 BCC TT87               ; Yscreen sum ok

 LDX QQ11               ; menu id = short range chart?
 BMI TT87               ; Yscreen sum ok
 LDA #151               ; else ymax

.TT87                   ; Yscreen sum ok
 STA XX15+3             ; Y cross top
 LDA QQ19               ; Xorg
 STA XX15               ; X1
 STA XX15+2             ; X2
 JMP LL30               ; draw vertical line using (X1,Y1), (X2,Y2)
}

.TT126                  ; default  Circle with a cross-hair
{
 LDA #104               ; Xorg
 STA QQ19
 LDA #90                ; Yorg
 STA QQ19+1
 LDA #16                ; cross-hair size
 STA QQ19+2
 JSR TT15               ; the cross hair using QQ19(0to2)
 LDA QQ14               ; ship fuel #70 = #&46
 STA K                  ; radius
 JMP TT128              ; below. QQ19(0,1) and K for Circle
}

\ *****************************************************************************
\ Subroutine: TT14
\
\ Circle with a cross hair
\ *****************************************************************************

.TT14                   ; Crcl/+ \ their comment \ Circle with a cross hair
{
 LDA QQ11               ; menu i.d.
 BMI TT126              ; if bit7 set up, Short range chart default.
 LDA QQ14               ; else ship fuel #70 = #&46
 LSR A                  ; Long range chart uses
 LSR A                  ; /=4
 STA K                  ; radius
 LDA QQ0                ; present X
 STA QQ19               ; Xorg
 LDA QQ1                ; present Y
 LSR A                  ; Y /=2
 STA QQ19+1             ; Yorg
 LDA #7                 ; cross-hair size
 STA QQ19+2
 JSR TT15               ; present cross hair using QQ19
 LDA QQ19+1             ; Yorg
 CLC
 ADC #24
 STA QQ19+1             ; Ytop
}

\ *****************************************************************************
\ Subroutine: TT128
\
\ QQ19(0,1) and K for circle
\ *****************************************************************************

.TT128                  ; QQ19(0,1) and K for circle
{
 LDA QQ19
 STA K3                 ; Xorg
 LDA QQ19+1
 STA K4                 ; Yorg
 LDX #0                 ; hi
 STX K4+1
 STX K3+1
\STX
\LSX
 INX                    ; step size for circle = 1
 STX LSP
 LDX #2                 ; load step =2, fairly big circle with small step size.
 STX STP

 JSR CIRCLE2
\LDA #&FF
\STA
\LSX
 RTS                    ; could have used jmp
}

\ *****************************************************************************
\ Subroutine: TT219
\
\ Buy cargo (#f1)
\ *****************************************************************************

.TT219                  ; Buy \ their comment \ Buy cargo (#f1)
{
\LDA#2                  ; set menu i.d.
 JSR TT66-2             ; box border with QQ11 set to Acc
 JSR TT163              ; headings for market place
 LDA #128               ; bit7 set for Capital letter
 STA QQ17
\JSR FLKB               ; flush keyboard
 LDA #0                 ; item of interest
 STA QQ29

.TT220                  ; List items, counter QQ29
 JSR TT151              ; Pmk-A  display the line for one market item
 LDA QQ25
 BNE TT224              ; Quantity of item not zero
 JMP TT222              ; else skip item

.TQ4                    ; try Quantity again
 LDY #176               ; token = QUANTITY

.Tc                     ; white space, Y token then question mark
 JSR TT162              ; white space
 TYA                    ; Y token
 JSR prq                ; print Yreg then question mark.

.TTX224
 JSR dn2                ; beep, delay.

.TT224                  ; also Quantity not zero
 JSR CLYNS              ; clear some rows
 LDA #204               ; token = QUANTITY OF
 JSR TT27               ; process flight token
 LDA QQ29               ; item of interest
 CLC
 ADC #208               ; token = FOOD .. GEM-STONES
 JSR TT27
 LDA #&2F               ; ascii '/'
 JSR TT27
 JSR TT152              ; t kg g from QQ19+1
 LDA #&3F               ; ascii '?'
 JSR TT27
 JSR TT67               ; next Row ; Call TT67, which prints a newline
 LDX #0                 ; input result returned (also done by gnum)
 STX R
 LDX #12                ; counter max
 STX T1

\.TT223                 ; DUPLICATE LABEL?

 JSR gnum               ; get number for purchase, max quantity QQ25
 BCS TQ4                ; error up, try Quantity again
 STA P                  ; else valid quantity
 JSR tnpr               ; ton purchase check
 LDY #206               ; token = CARGO
 BCS Tc                 ; no space, cargo?
 LDA QQ24               ; price
 STA Q
 JSR GCASH              ; cargo * price
 JSR LCASH              ; less cash, XloYhi = P*Q*4
 LDY #197               ; token = CASH
 BCC Tc                 ; not enough cash?

 LDY QQ29               ; cargo item of interest as index
 LDA R                  ; number of items purchased
 PHA                    ; copy number of items purchased
 CLC                    ; add to cargo of that kind in ship count
 ADC QQ20,Y
 STA QQ20,Y
 LDA AVL,Y
 SEC                    ; Market availability updated
 SBC R                  ; number of items purchased
 STA AVL,Y
 PLA                    ; number of items purchased
 BEQ TT222              ; if none skip item, else
 JSR dn                 ; else display remaining cash

.TT222                  ; skipped item
 LDA QQ29               ; cargo item of interest
 CLC                    ; Y text cursor
 ADC #5                 ; move to correct row
 STA YC
 LDA #0                 ; X text cursor
 STA XC
 INC QQ29               ; next item
 LDA QQ29
 CMP #17                ; max+1 items can purchase
 BCS BAY2               ; exit, all items done
 JMP TT220              ; loop up next item QQ29
}

.BAY2                   ; all items done, Back to
{
 LDA #f9                ; red key #f9 Inventory page
 JMP FRCE               ; forced to enter Main loop
}

.gnum                   ; get number R for purchase, max quantity QQ25
{
 LDX #0                 ; result returned
 STX R
 LDX #12                ; counter max
 STX T1

.TT223                  ; counter T1
 JSR TT217              ; get ascii from keyboard, store in X and A
 STA Q                  ; ascii accepted
 SEC                    ; was hit key a digit
 SBC #&30               ; below ascii '0' ?
 BCC OUT                ; exit, take R.
 CMP #10                ; digit >= 10 ?
 BCS BAY2               ; above valid digit, inventory screen.
 STA S                  ; new digit 0to9
 LDA R                  ; partial result
 CMP #26                ; >= 26 will *10 then exceeds 256.
 BCS OUT                ; exit, take R.
 ASL A                  ; *=2
 STA T
 ASL A
 ASL A                  ; *=8
 ADC T                  ; Acc  = 2*R + 8*R
 ADC S                  ; new digit 0to9
 STA R                  ; new partial result = 10*R + S
 CMP QQ25               ; max quantity allowed
 BEQ TT226              ; accept key Q
 BCS OUT                ; if R > QQ25, exit

.TT226                  ; accept key Q
 LDA Q                  ; ascii accepted
 JSR TT26               ; print character
 DEC T1                 ; loop T1
 BNE TT223              ; 12 times max.

.OUT                    ; exit
 LDA R                  ; return result R
 RTS
}

\ *****************************************************************************
\ Subroutine: TT208
\
\ Sell cargo (#f2)
\ *****************************************************************************

.TT208                  ; Sel \ their comment \ Sell cargo (#f2)
{
 LDA #4                 ; menu i.d. = 4
 JSR TT66               ; box border with QQ11 set to Acc
 LDA #4                 ; indent
 STA YC 
 STA XC
\JSR FLKB               ; flush keyboard
 LDA #205               ; token = SELL
 JSR TT27               ; process text token
 LDA #206               ; token = CARGO
 JSR TT68               ; finish title string and draw line underneath
}

\ *****************************************************************************
\ Subroutine: TT210
\
\ Cargo list Inventory (no sell)
\ *****************************************************************************

.TT210                  ; Crgo \ their comment \ Cargo list Inventory (no sell)
{
 LDY #0

.TT211                  ; counter Y = QQ29 for item
 STY QQ29               ; in sell list, Yreg = QQ29 is item index
 LDX QQ20,Y             ; ship cargo count
 BEQ TT212              ; skip cargo item

 TYA                    ; build index base
 ASL A
 ASL A                  ; Y*4
 TAY                    ; build index base Y*4
 LDA QQ23+1,Y           ; Prxs
 STA QQ19+1             ; byte1 of Market Prxs info

 TXA                    ; ship cargo count
 PHA                    ; store
 JSR TT69               ; next Row with QQ17 set
 CLC                    ; item index used to build token
 LDA QQ29
 ADC #208               ; token = FOOD .. GEM-STONES

 JSR TT27               ; process flight text token
 LDA #14                ; indent
 STA XC
 PLA                    ; restore
 TAX                    ; ship cargo count
 CLC                    ; no decimal point
 JSR pr2                ; number X to printable characters
 JSR TT152              ; t kg g from QQ19+1 byte1

 LDA QQ11               ; menu i.d.
 CMP #4                 ; are we selling or just listing cargo?
 BNE TT212              ; skip sell item
 LDA #205               ; token = SELL
 JSR TT214

 BCC TT212              ; if 0 skip sell item
 LDA QQ29               ; item index
 LDX #255               ; partial print
 STX QQ17
 JSR TT151              ; Pmk-A  display the line for one market item

 LDY QQ29               ; item index
 LDA QQ20,Y             ; ship cargo count
 STA P                  ; amount
 LDA QQ24               ; price
 STA Q
 JSR GCASH              ; amount * price \ XloYhi = P*Q*4
 JSR MCASH              ; add Xlo.Yhi to cash 

 LDA #0                 ; All upper case
 LDY QQ29               ; item index
 STA QQ20,Y             ; ship cargo count
 STA QQ17

.TT212                  ; skipped (sell) item
 LDY QQ29               ; market item index
 INY                    ; next market item
 CPY #17                ; last cargo type?
 BCS P%+5
 JMP TT211              ; loop, next QQ29
 LDA QQ11               ; menu i.d.
 CMP #4                 ; are we selling or just listing cargo?
 BNE P%+8               ; rts else
 JSR dn2                ; All sells done - beep, delay.
 JMP BAY2               ; Inventory screen.
 RTS                    ; needed TT213-1
}

\ *****************************************************************************
\ Subroutine: TT213
\
\ Inventory
\ *****************************************************************************

.TT213                  ; Invntry \ their comment \ Inventory
{
 LDA #8                 ; menu i.d.
 JSR TT66               ; box border with QQ11 set to A
 LDA #11                ; indent
 STA XC
 LDA #164               ; token = INVENTORY
 JSR TT60               ; TT27 token then next row
 JSR NLIN4              ; draw line at Y = #19
 JSR fwl                ; fuel and cash

 LDA CRGO
 CMP #26                ; size of cargo bay?
 BCC P%+7               ; jmp TT214 list Cargo
 LDA #&6B               ; token = Large cargo bay
 JSR TT27               ; process text token
 JMP TT210              ; List Cargo, up.
}

\ *****************************************************************************
\ Subroutine: TT214
\
\ List cargo
\ *****************************************************************************

.TT214
{
 PHA
 JSR TT162
 PLA

.TT221                  ; called by anyone?  token Acc Y/N ?
 JSR TT27               ; process flight text Token in Acc
 LDA #225               ; token = x01 (Y/N)?
 JSR TT27               ; process flight text Token in Acc

 JSR TT217              ; get ascii from keyboard, store in X and A
 ORA #32                ; to lower  case
 CMP #&79               ; ascii 'y'
 BEQ TT218              ; yes, set carry
 LDA #&6E               ; ascii 'n'
 JMP TT26               ; print character

.TT218                  ; yes, set carry
 JSR TT26               ; print character
 SEC                    ; set carry
 RTS
}

\ *****************************************************************************
\ Subroutine: TT16
\
\ Arrive with X and Y values values to shift cross-hairs on charts by
\ *****************************************************************************

.TT16                   ; Arrive with X and Y values values to shift cross-hairs on charts by
{
 TXA
 PHA                    ; Xinc
 DEY                    ; negate Yinc
 TYA
 EOR #255
 PHA                    ; negate Yinc
 JSR WSCAN              ; wait for line scan, ie whole frame completed.
 JSR TT103              ; erase small cross hairs at target hyperspace
 PLA                    ; negated Yinc
 STA QQ19+3             ; inc

 LDA QQ10               ; target y
 JSR TT123              ; coordinate update, fix overflow
 LDA QQ19+4             ; result
 STA QQ10               ; target y
 STA QQ19+1             ; new Y
 PLA                    ; Xinc

 STA QQ19+3             ; inc
 LDA QQ9                ; target x
 JSR TT123              ; coordinate update, fix overflow
 LDA QQ19+4             ; result
 STA QQ9                ; target x
 STA QQ19               ; new X
}

\ *****************************************************************************
\ Subroutine: TT103
\
\ Draw small cross hairs at target hyperspace system.
\ *****************************************************************************

.TT103                  ; Draw small cross hairs at target hyperspace system.
{
 LDA QQ11               ; menu i.d.
 BEQ TT180
 BMI TT105              ; bit7 set is Short range chart cross-hair clip
 LDA QQ9                ; target x
 STA QQ19
 LDA QQ10               ; target y
 LSR A                  ; Y /=2
 STA QQ19+1
 LDA #4                 ; small cross hair
 STA QQ19+2
 JMP TT15               ; cross hairs for laser or chart
}

\ *****************************************************************************
\ Subroutine: TT123
\
\ Coordinate update, fix overflow
\ *****************************************************************************

.TT123                  ; coordinate update, fix overflow
{
 STA QQ19+4             ; coordinate to update
 CLC                    ; add inc
 ADC QQ19+3
 LDX QQ19+3
 BMI TT124              ; shift was -ve
 BCC TT125              ; else addition went o.k.
 RTS

.TT124                  ; shift was -ve
 BCC TT180              ; shift was -ve,  RTS.

.TT125                  ; update ok
 STA QQ19+4             ; updated coordinate
}

.TT180                  ; rts
{
 RTS
}

\ *****************************************************************************
\ Subroutine: TT105
\
\ Short range chart cross-hair clip
\ *****************************************************************************

.TT105                  ; Short range chart cross-hair clip
{
 LDA QQ9                ; target X
 SEC
 SBC QQ0                ; present X
 CMP #38
 BCC TT179              ; targetX-presentX, X is close
 CMP #230
 BCC TT180              ; rts

.TT179                  ; X is close
 ASL A
 ASL A                  ; X*4
 CLC
 ADC #104               ; cross X
 STA QQ19

 LDA QQ10               ; target Y
 SEC
 SBC QQ1                ; present Y
 CMP #38
 BCC P%+6               ; targetY-presentY, Y is close
 CMP #220
 BCC TT180              ; rts

 ASL A                  ; Y*2
 CLC
 ADC #90                ; cross Y
 STA QQ19+1
 LDA #8                 ; big cross
 STA QQ19+2
 JMP TT15               ; the cross hair using QQ19(0to2)
}

\ *****************************************************************************
\ Subroutine: TT23
\
\ Short range chart
\ *****************************************************************************

.TT23                   ; ShrtSc \ their comment \ Short range chart
{
 LDA #128               ; Set bit7 of menu i.d.
 JSR TT66               ; box border with QQ11 set to A
 LDA #7                 ; indent
 STA XC
 LDA #190               ; token = SHORT RANGE CHART
 JSR NLIN3              ; title string and draw line underneath
 JSR TT14               ; Circle+cross hair, small cross at target
 JSR TT103              ; draw small cross hairs at target hyperspace system
 JSR TT81               ; QQ15 loaded with rolled planet seed

 LDA #0                 ; future counter
 STA XX20
 LDX #24                ; Clear 24 row to label stars

.EE3                    ; counter X
 STA INWK,X
 DEX
 BPL EE3                ; loop X

.TT182                  ; Counter XX20 through 256 stars
 LDA QQ15+3
 SEC                    ; Xcoord of star
 SBC QQ0
 BCS TT184              ; xsubtracted
 EOR #&FF               ; else negate
 ADC #1

.TT184                  ; xsubtracted
 CMP #20                ; x distance close?
 BCS TT187              ; skip star plotting
 LDA QQ15+1
 SEC                    ; Ycoord of star
 SBC QQ1                ; Ypresent
 BCS TT186              ; ysubtracted
 EOR #&FF               ; else negate
 ADC #1

.TT186                  ; ysubstracted
 CMP #38                ; y distance close?
 BCS TT187              ; skip star plotting

 LDA QQ15+3
 SEC                    ; X coord of star
 SBC QQ0
 ASL A                  ; X present
 ASL A                  ; *=4
 ADC #104               ; xplot
 STA XX12
 LSR A
 LSR A                  ; x text cursor
 LSR A
 STA XC
 INC XC
 LDA QQ15+1
 SEC                    ; Y coord of star
 SBC QQ1
 ASL A                  ; Y present
 ADC #90                ; yplot
 STA K4
 LSR A
 LSR A
 LSR A

 TAY                    ; y text cursor
 LDX INWK,Y
 BEQ EE4                ; empty label row
 INY                    ; else try row above
 LDX INWK,Y
 BEQ EE4                ; empty label row
 DEY                    ; else try row below
 DEY
 LDX INWK,Y
 BNE ee1

.EE4                    ; found empty label row
 STY YC
 CPY #3                 ; < 3rd row?
 BCC TT187              ; skip star plotting
 DEX
 STX INWK,Y

 LDA #128               ; First label letter capital
 STA QQ17
 JSR cpl

.ee1                    ; bigstars \ their comment \ no label, just the star.
 LDA #0                 ; hi = 0
 STA K3+1
 STA K4+1
 STA K+1
 LDA XX12               ; xplot for star
 STA K3
 LDA QQ15+5             ; seed w2_h
 AND #1                 ; use lowest bit of w2_h for star size, lowest 4 did planet radius
 ADC #2                 ; sun radius
 STA K
 JSR FLFLLS             ; clear array  
 JSR SUN                ; clear lines
 JSR FLFLLS

.TT187                  ; skipped star plotting
 JSR TT20               ; Twist galaxy seed
 INC XX20
 BEQ TT111-1            ; all 256 done, rts 
 JMP TT182              ; loop XX20 next star
}

.TT81                   ; QQ15 loaded with galaxy seeds
{
 LDX #5                 ; Galaxy root seeds, counter X.
 LDA QQ21,X
 STA QQ15,X
 DEX                    ; to planet seeds to twist
 BPL TT81+2
 RTS
}

\ *****************************************************************************
\ Subroutine: TT111
\
\ Rectangle Closest to QQ9,10. Could be arriving in new galaxy with initial
\ (96,96)
\ *****************************************************************************

.TT111                  ; rectangle Closest to QQ9,10. Could be arriving in new galaxy with initial (96,96)
{
 JSR TT81               ; QQ15 loaded with galaxy seeds
 LDY #127               ; distance tracker, starts at half of screen width.
 STY T
 LDA #0                 ; trial system id starts at 0
 STA U

.TT130                  ; counter U, visit each trial system.
 LDA QQ15+3
 SEC                    ; Xsystem
 SBC QQ9
 BCS TT132              ; skip xnegate
 EOR #&FF
 ADC #1

.TT132                  ; skip xnegate
 LSR A                  ; halve this x-distance
 STA S
 LDA QQ15+1
 SEC                    ; Ysystem
 SBC QQ10
 BCS TT134              ; skip ynegate
 EOR #&FF
 ADC #1

.TT134                  ; skip ynegate
 LSR A                  ; halve y distance,
 CLC                    ; so total mag will fit in 1 byte
 ADC S                  ; sum of abs(delta_x/2) + abs(delta_y/4)
 CMP T                  ; distance tracker
 BCS TT135              ; not close, else update distance tracker

 STA T
 LDX #5                 ; and new best seeds update

.TT136                  ; counter X
 LDA QQ15,X
 STA QQ19,X
 DEX                    ; present best system seed values
 BPL TT136              ; loop X for 6 bytes.

.TT135                  ; not close
 JSR TT20               ; Twist galaxy seed
 INC U
 BNE TT130              ; loop U next sys id, not 256 yet.
 LDX #5                 ; finished

.TT137                  ; counter X, copy out present best seeds
 LDA QQ19,X
 STA QQ15,X
 DEX
 BPL TT137              ; loop X

                        ; use QQ15 to QQ9,10 to set distance QQ8
 LDA QQ15+1
 STA QQ10               ; target y-coordinate updated to closest system
 LDA QQ15+3
 STA QQ9                ; target x-coordinate updated to closest system

 SEC                    ; present X
 SBC QQ0
 BCS TT139              ; x dist-org
 EOR #&FF               ; else negate
 ADC #1

.TT139                  ; x dist-org
 JSR SQUA2              ; (P,A) = A*A
 STA K+1
 LDA P                  ; xlo
 STA K
 LDA QQ10

 SEC                    ; Y subtracted
 SBC QQ1
 BCS TT141              ; y dist-org
 EOR #&FF               ; else negate
 ADC #1

.TT141                  ; y dist-org
 LSR A                  ; Acc = abs(delta_y)/2
 JSR SQUA2              ; (P,A) = A*A
 PHA                    ; highest bytes for delta_y ^2
 LDA P
 CLC                    ; y lo
 ADC K

 STA Q                  ; r^2 lo
 PLA                    ; highest bytes for delta_y ^2
 ADC K+1
 STA R                  ; r^2 hi
 JSR LL5                ; SQRT  Q = SQR(Q,R)
 LDA Q
 ASL A                  ; distance lo *=2
 LDX #0                 ; distance hi
 STX QQ8+1
 ROL QQ8+1
 ASL A
 ROL QQ8+1
 STA QQ8                ; QQ8(0,1) is 4*distance in x-units
 JMP TT24               ; Calculate System Data from QQ15(0to5).
}

\ *****************************************************************************
\ Subroutine: hy6
\
\ Clear some screen rows
\ *****************************************************************************

.hy6
{
 JSR CLYNS              ; Clear some screen rows
 LDA #15
 STA XC
 JMP TT27               ; process flight text token
}

\ *****************************************************************************
\ Subroutine: hyp
\
\ hyperspace start, key H hit.
\ *****************************************************************************

.hyp                    ; hyperspace start, key H hit.
{
 LDA QQ12               ; hyp countdown hi
 BNE hy6
 LDA QQ22+1             ; hyp countdown lo
 BNE zZ+1               ; rts! as countdown already going on
 JSR CTRL               ; scan from ctrl key upwards on keyboard
 BMI Ghy                ; Galactic hyperdrive for ctrl-H
 JSR hm                 ; move hyperspace cross on chart

                        ; check range, all.
 LDA QQ8                ; distance in 0.1 LY units
 ORA QQ8+1              ; zero?
 BEQ zZ+1               ; rts!
 LDA #7                 ; indent
 STA XC
 LDA #23                ; near bottom row for hyperspace message
 STA YC
 LDA #0                 ; All upper case
 STA QQ17
 LDA #189               ; token = HYPERSPACE
 JSR TT27               ; process flight text token
 LDA QQ8+1              ; distance hi
 BNE TT147              ; hyperspace range too far
 LDA QQ14               ; ship fuel #70 = #&46
 CMP QQ8                ; distance lo
 BCC TT147              ; hyperspace too far

 LDA #&2D               ; ascii '-' in  "HYPERSPACE -ISINOR"
 JSR TT27
 JSR cpl                ; Planet name for seed QQ15
}

.wW                     ; Also Galactic hyperdrive countdown starting
{
 LDA #15                ; counter for outer and inner hyperspace countdown loops
 STA QQ22+1
 STA QQ22               ; inner hyperspace countdown
 TAX                    ; starts at 15
 JMP ee3                ; digit in top left hand corner, using Xreg.

\hy5 RTS
}

\ *****************************************************************************
\ Subroutine: Ghy
\
\ Galactic hyperdrive for ctrl-H
\ *****************************************************************************

.Ghy                    ; Galactic hyperdrive for ctrl-H
{
\JSR TT111              ; is in ELITED.TXT but not in ELITE SOURCE IMAGE
 LDX GHYP               ; possess galactic hyperdrive?
 BEQ hy5                ; rts
 INX                    ; Xreg = 0
 STX QQ8
 STX QQ8+1
 STX GHYP               ; works once
 STX FIST               ; clean Fugitive/Innocent status
 JSR wW                 ; start countdown
 LDX #5                 ; 6 seeds
 INC GCNT               ; next galaxy
 LDA GCNT
 AND #7                 ; round count to just 8
 STA GCNT

.G1                     ; counter X  ROLL galaxy seeds
 LDA QQ21,X             ; Galaxy seeds, 6 bytes
 ASL A                  ; to get carry to load back into bit 0
 ROL QQ21,X             ; rolled galaxy seeds
 DEX
 BPL G1                 ; loop X
\JSR DORND
}

.zZ                     ; Arrive closest to (96,96)
{
 LDA #&60               ; zZ+1 is an rts !
 STA QQ9
 STA QQ10
 JSR TT110              ; Launch ship decision
 LDA #116               ; token = Galactic Hyperspace
 JSR MESS               ; message
}

.jmp                    ; move target coordinates to become new present
{
 LDA QQ9
 STA QQ0
 LDA QQ10
 STA QQ1
}

.hy5
{
 RTS                    ; ee3-1
}

\ *****************************************************************************
\ Subroutine: ee3
\
\ Print the 8-bit number in X at text location (0, 1). Print the number to
\ 5 digits, left-padding with spaces for numbers with fewer than 3 digits (so
\ numbers < 10000 are right-aligned), with no decimal point.
\
\ Arguments:
\
\   X           The number to print
\ *****************************************************************************

.ee3
{
 LDY #1                 ; Set YC = 1 (first row)
 STY YC

 DEY                    ; Set XC = 0 (first character)
 STY XC

                        ; Fall through into pr6 to print X to 5 digits
}

\ *****************************************************************************
\ Subroutine: pr6
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned),
\ with no decimal point.
\
\ Arguments:
\
\   X           The low byte of the number to print
\
\   Y           The high byte of the number to print
\ *****************************************************************************

.pr6
{
 CLC                    ; Do not display a decimal point when printing

                        ; Fall through into pr5 to print X to 5 digits
}

\ *****************************************************************************
\ Subroutine: pr5
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned).
\ Optionally include a decimal point.
\
\ Arguments:
\
\   X           The low byte of the number to print
\
\   Y           The high byte of the number to print
\
\   C flag      If set, include a decimal point
\ *****************************************************************************

.pr5
{
 LDA #5                 ; Set the number of digits to print to 5

 JMP TT11               ; Call TT11 to print (Y X) to 5 digits and return from
                        ; the subroutine using a tail call
}

\ *****************************************************************************
\ Subroutine: TT147
\
\ Hyperspace too far, display 'RANGE' (?)
\ *****************************************************************************

.TT147                  ; hyperspace too far
{
 LDA #202               ; token = (HYPERSPACE) 'RANGE' (?)
}

\ *****************************************************************************
\ Subroutine: prq
\
\ Print Acc then question mark
\ *****************************************************************************

.prq                    ; print Acc then question mark
{
 JSR TT27               ; process text token
 LDA #&3F               ; ascii '?'
 JMP TT27
}

\ *****************************************************************************
\ Subroutine: TT151
\
\ Market prices on one item
\ *****************************************************************************

.TT151                  ; Pmk-A \ their comment \ Market prices on one item
{
 PHA                    ; index for item
 STA QQ19+4
 ASL A                  ; build index for QQ23 table
 ASL A                  ; item*4
 STA QQ19
 LDA #1                 ; left
 STA XC
 PLA                    ; restore item
 ADC #208               ; token = FOOD..GEM-STONES

 JSR TT27               ; process flight text token
 LDA #14                ; next column
 STA XC
 LDX QQ19               ; item*4 index for QQ23 table
 LDA QQ23+1,X           ; Prxs  Market prices info
 STA QQ19+1             ; byte 1
 LDA QQ26               ; random byte each system visit
 AND QQ23+3,X           ; byte3 Market mask
 CLC
 ADC QQ23,X             ; byte0 Market base
 STA QQ24               ; price
 JSR TT152              ; t kg g from QQ19+1

 JSR var                ; slope QQ19+3  = economy * gradient
 LDA QQ19+1             ; byte1
 BMI TT155              ; subtract QQ19,3 from QQ24
 LDA QQ24               ; price, else add
 ADC QQ19+3             ; economy * gradient
 JMP TT156              ; both prices

.TT155                  ; subtract QQ19,3 from QQ24
 LDA QQ24               ; price
 SEC
 SBC QQ19+3             ; economy * gradient

.TT156                  ; both price cases
 STA QQ24               ; price
 STA P                  ; price_lo
 LDA #0
 JSR GC2                ; get cash Xlo.Yhi = P.A *=4  max 1024

 SEC                    ; decimal point in max 102.4
 JSR pr5                ; 4 digits of XloYhi
 LDY QQ19+4             ; index for item
 LDA #5                 ; 5 digits
 LDX AVL,Y              ; availability
 STX QQ25               ; max available

 CLC
 BEQ TT172              ; tab '-' as none available
 JSR pr2+2              ; else print available Xreg to 5 places
 JMP TT152              ; t kg g from QQ19+1

.TT172                  ; tab '-' as none available
 LDA XC
 ADC #4                 ; move by 4
 STA XC
 LDA #&2D               ; ascii '-'
 BNE TT162+2            ; guaranteed jmp TT27
}

.TT152                  ; t kg g from QQ19+1
{
 LDA QQ19+1             ; byte1
 AND #96                ; mask info, no bits set?
 BEQ TT160              ; 't' for tonne
 CMP #32                ; mask info, bit5 set?
 BEQ TT161              ; 'kg'

 JSR TT16a              ; else 'g' for gram
}

\ *****************************************************************************
\ Subroutine: TT162
\
\ Print a space.
\ *****************************************************************************

.TT162
{
 LDA #' '               ; Load a space character into A

 JMP TT27               ; Print the character in A and return from the
                        ; subroutine using a tail call
}

\ *****************************************************************************
\ Subroutine: TT160
\
\ 't' for tonne
\ *****************************************************************************

.TT160                  ; 't' for tonne
{
 LDA #&74               ; ascii 't' for tonne
 JSR TT26               ; print character
 BCC TT162              ; guaranteed, trailing space.
}

\ *****************************************************************************
\ Subroutine: TT161
\
\ 'kg'
\ *****************************************************************************

.TT161                  ; 'kg'
{
 LDA #&6B               ; ascii 'k'
 JSR TT26               ; print character lower case
}

\ *****************************************************************************
\ Subroutine: TT16a
\
\ 'g'
\ *****************************************************************************

.TT16a
{
 LDA #&67               ; ascii 'g'
 JMP TT26               ; print character lower case
}

\ *****************************************************************************
\ Subroutine: TT163
\
\ Table Headings for market place
\ *****************************************************************************

.TT163                  ; table Headings for market place
{
 LDA #17                ; indent
 STA XC
 LDA #&FF               ; token = unit  quantity product unit    price   for   sale
 BNE TT162+2
}

\ *****************************************************************************
\ Subroutine: TT167
\
\ Market place menu screen
\ *****************************************************************************

.TT167                  ; MktP \ their comment \ Market place menu screen
{
 LDA #16                ; menu i.d. bit4 set
 JSR TT66               ; box border with QQ11 set to A
 LDA #5                 ; indent
 STA XC
 LDA #167               ; token = MARKET PRICES
 JSR NLIN3              ; title and draw line underneath
 LDA #3                 ; few lines down
 STA YC
 JSR TT163              ; table headings for market place, up
 LDA #0                 ; counter
 STA QQ29

.TT168                  ; counter QQ29 market items
 LDX #128               ; set bit7, first letter Upper case.
 STX QQ17
 JSR TT151              ; Pmk-A  display the line for one market item
 INC YC

 INC QQ29
 LDA QQ29
 CMP #17                ; still <17 items?
 BCC TT168              ; loop QQ29
 RTS
}

\ *****************************************************************************
\ Subroutine: var
\
\ Market price slope QQ19+3  = economy * gradient
\ *****************************************************************************

.var                    ; market price slope QQ19+3  = economy * gradient
{
 LDA QQ19+1             ; byte1 gradient info bits.
 AND #31                ; gradient 0to31.
 LDY QQ28               ; the economy byte of present system (0 is Rich Ind.)
 STA QQ19+2             ; gradient 0to31.
 CLC                    ; build product
 LDA #0                 ; availability of Alien items
 STA AVL+16

.TT153                  ; counter Y, eco
 DEY                    ; Take economy byte down by 1
 BMI TT154              ; exit product
 ADC QQ19+2             ; gradient 0to31
 JMP TT153              ; guaranteed loop Y to build product

.TT154                  ; exit product
 STA QQ19+3             ; economy * gradient
 RTS
}

\ *****************************************************************************
\ Subroutine: hyp1
\
\ Arrive in the system closest to (QQ9, QQ10)
\ *****************************************************************************

.hyp1
{
 JSR TT111              ; Calculate closest system to (QQ9, QQ10) and then fall
                        ; through into arrival routine below
}

\ *****************************************************************************
\ Subroutine: hyp1+3
\
\ Arrive in the system at (QQ9, QQ10)
\ *****************************************************************************

{
 JSR jmp                ; move target coordinates to present
 LDX #5                 ; 6 bytes

.TT112                  ; counter X
 LDA QQ15,X             ; safehouse,X  target seeds
 STA QQ2,X              ; copied over to home seeds
 DEX                    ; next seed
 BPL TT112              ; loop X
 INX                    ; X = 0
 STX EV                 ; 0 extra vessels
 LDA QQ3                ; economy of target system
 STA QQ28               ; economy of present system
 LDA QQ5                ; Tech
 STA tek                ; techlevel-1 of present system 
 LDA QQ4                ; Government, 0 is Anarchy
 STA gov                ; gov of present system
 RTS
}

\ *****************************************************************************
\ Subroutine: GVL
\
\ Set up system market on arrival?
\ *****************************************************************************

.GVL
{
 JSR DORND              ; do random, new A, X.
 STA QQ26               ; random byte for each system vist (for market)
 LDX #0                 ; set up availability
 STX XX4

.hy9                    ; counter XX4  availability table
 LDA QQ23+1,X
 STA QQ19+1
 JSR var                ; slope QQ19+3  = economy * gradient
 LDA QQ23+3,X           ; byte3 of Market Prxs info
 AND QQ26               ; random byte for system market
 CLC                    ; masked by market byte3
 ADC QQ23+2,X           ; base price byte2 of Market Prxs info
 LDY QQ19+1
 BMI TT157              ; -ve byte1
 SEC                    ; else subtract
 SBC QQ19+3             ; slope
 JMP TT158              ; hop over to both avail

.TT157                  ; -ve byte1
 CLC                    ; add slope
 ADC QQ19+3

.TT158                  ; both avail
 BPL TT159
 LDA #0                 ; else negative avail, set to zero.

.TT159                  ; both options arrive here
 LDY XX4                ; counter as index
 AND #63                ; take lower 6 bits as quantity available
 STA AVL,Y              ; availability
 INY                    ; next item
 TYA                    ; counter
 STA XX4
 ASL A                  ; build index
 ASL A                  ; *=4
 TAX                    ; X = Y*4 to index table
 CMP #63                ; XX4 < 63?
 BCC hy9                ; loop XX4 availability
}

.hyR
{
 RTS
}

\ *****************************************************************************
\ Subroutine: GTHG
\
\ Get Thargoid ship
\ *****************************************************************************

.GTHG                   ; get Thargoid ship
{
 JSR Ze                 ; Zero for new ship, new inwk coords, ends with dornd and T1 = rnd too.
 LDA #&FF               ; ai attack everyone, has ecm.
 STA INWK+32
 LDA #THG               ; thargoid ship
 JSR NWSHP              ; new ship type Acc
 LDA #TGL               ; accompanying thargon
 JMP NWSHP              ; new ship type Acc
}

.ptg                    ; shift forced hyperspace misjump
{
 LSR COK                ; Set bit 0 of COK, the competition code
 SEC
 ROL COK
}

\ *****************************************************************************
\ Subroutine: MJP
\
\ Miss-jump to Thargoids in witchspace
\ *****************************************************************************

.MJP                    ; miss jump
{
\LDA #1                 ; not required as this is present at TT66-2
 JSR TT66-2             ; box border with QQ11 set to A = 1
 JSR LL164              ; hyperspace noise and tunnel
 JSR RES2               ; reset2
 STY MJ                 ; mis-jump flag set #&FF

.MJP1                   ; counter MANY + #29 thargoids
 JSR GTHG               ; get Thargoid ship
 LDA #3                 ; 3 Thargoid ships
 CMP MANY+THG           ; thargoids
 BCS MJP1               ; loop if thargoids < 3
 STA NOSTM              ; number of stars, dust = 3
 LDX #0                 ; forward view
 JSR LOOK1
 LDA QQ1                ; present Y
 EOR #31                ; flip lower y coord bits
 STA QQ1
 RTS
}

\ *****************************************************************************
\ Subroutine: TT18
\
\ Countdown finished, (try) go through Hyperspace
\ *****************************************************************************

.TT18                   ; HSPC \ their comment \ Countdown finished, (try) go through Hyperspace
{
 LDA QQ14               ; ship fuel #70 = #&46
 SEC                    ; Subtract distance in 0.1 LY units
 SBC QQ8
 STA QQ14
 LDA QQ11
 BNE ee5                ; menu i.d. not a space view
 JSR TT66               ; else box border with QQ11 set to Acc
 JSR LL164              ; hyperspace noise and tunnel

.ee5                    ; not a space view
 JSR CTRL               ; scan from ctrl on keyboard
 AND PATG               ; PATG = &FF if credits have been enabled
 BMI ptg                ; shift key forced misjump, up.
 JSR DORND              ; do random, new A, X.
 CMP #253               ; also small chance that
 BCS MJP                ; miss-jump to Thargoids in witchspace
 \JSR TT111
 JSR hyp1+3             ; else don't move to QQ9,10 but do Arrive in system.
 JSR GVL
 JSR RES2               ; reset2, MJ flag cleared.
 JSR SOLAR              ; Set up planet and sun

 LDA QQ11
 AND #63                ; menu i.d. not space views, but maybe charts.
 BNE hyR                ; rts
 JSR TTX66              ; else new box for space view or new chart.
 LDA QQ11
 BNE TT114              ; menu i.d. not space view, a new chart.
 INC QQ11               ; else space, menu id = 1 for new dust view.
}

\ *****************************************************************************
\ Subroutine: TT110
\
\ Launch ship decision. Also arrive here after galactic hyperdrive jump, and
\ after f0 hit.
\ *****************************************************************************

.TT110                  ; Launch ship decision. Also arrive here after galactic hyperdrive jump, and after f0 hit.
{
 LDX QQ12               ; Docked flag
 BEQ NLUNCH             ; not launched
 JSR LAUN               ; launched from space station
 JSR RES2               ; reset2, small reset.
 JSR TT111              ; Closest to QQ9,10 then Sys Data
 INC INWK+8             ; zsg, push away planet in front.
 JSR SOS1               ; set up planet
 LDA #128               ; space station behind you
 STA INWK+8
 INC INWK+7             ; zhi=1
 JSR NWSPS              ; New space station at INWK, S bulb appears.
 LDA #12                ; launch speed
 STA DELTA
 JSR BAD                ; scan for QQ20(3,6,10), 32 tons of Slaves, Narcotics
 ORA FIST               ; fugitive/innocent status
 STA FIST

.NLUNCH                 ; also not launched
 LDX #0                 ; forward
 STX QQ12               ; check messages
 JMP LOOK1              ; start view Xreg = 0
}

.TT114                  ; not space view, a chart.
{
 BMI TT115              ; menu i.d. bit7 Short range chart
 JMP TT22               ; else Long range galactic chart

.TT115                  ; Short range chart
 JMP TT23               ; Short range chart
}

\ *****************************************************************************
\ Subroutine: LCASH
\
\ Less X.Y cash
\ *****************************************************************************

.LCASH                  ; Less X.Y cash
{
 STX T1
 LDA CASH+3
 SEC                    ; subtract Xlo from CASH(3)
 SBC T1
 STA CASH+3
 STY T1
 LDA CASH+2
 SBC T1
 STA CASH+2
 LDA CASH+1
 SBC #0                 ; subtracted Yhi from CASH(2)
 STA CASH+1
 LDA CASH
 SBC #0                 ; (big-endian)
 STA CASH
 BCS TT113              ; rts if no debt with carry set

                        ; else roll on to carry clear and restore cash
}

\ *****************************************************************************
\ Subroutine: MCASH
\
\ More cash, add Xlo.Yhi
\ *****************************************************************************

.MCASH                  ; More cash, add Xlo.Yhi
{
 TXA                    ; lo
 CLC                    ; add Xlo to CASH(3)
 ADC CASH+3
 STA CASH+3
 TYA                    ; hi
 ADC CASH+2
 STA CASH+2
 LDA CASH+1
 ADC #0                 ; added Yhi to CASH(2)
 STA CASH+1
 LDA CASH
 ADC #0                 ; (big-endian)
 STA CASH
 CLC                    ; carry clear also means LCASH failed
}

.TT113
{
 RTS
}

\ *****************************************************************************
\ Subroutine: GCASH
\
\ cargo * price Xlo.Yhi = P*Q*4
\ *****************************************************************************

.GCASH                  ; Xlo.Yhi = P*Q*4
{
 JSR MULTU              ; P.A = P*Q,  lsb in P.
}

\ *****************************************************************************
\ Subroutine: GC2
\
\ Xlo.Yhi = P.A *=4
\ *****************************************************************************

.GC2                    ; Xlo.Yhi = P.A *=4
{
 ASL P
 ROL A                  ; hi
 ASL P
 ROL A
                        ; X.Y = P.A
 TAY                    ; Y hi
 LDX P                  ; X lo
 RTS
}

\ *****************************************************************************
\ Subroutine: bay
\
\ error, back to Bay
\ *****************************************************************************

.bay                    ; error, back to Bay
{
 JMP BAY                ; Start in Docking Bay
}

\ *****************************************************************************
\ Subroutine: EQSHP
\
\ (#f3) Equip Ship
\ *****************************************************************************

.EQSHP                  ; (#f3) Equip Ship
{
 JSR DIALS
 LDA #32
 JSR TT66               ; flush keyboard
 LDA #12                ; indent
 STA XC
 LDA #207               ; token = EQUIP
 JSR spc                ; Acc to TT27 followed by white space
 LDA #185               ; token =  SHIP
 JSR NLIN3              ; finish title and draw line underneath
 LDA #128               ; First letter capital
 STA QQ17
 INC YC
 LDA tek                ; techlevel of present system
 CLC                    ; build max equipment
 ADC #3
 CMP #12
 BCC P%+4               ; is TechLevel+3 < 12
 LDA #12                ; else max list is 12
 STA Q
 STA QQ25               ; max gnum range
 INC Q                  ; count max
 LDA #70                ; 7.0 LYr. of fuel max
 SEC                    ; subtract present ship fuel
 SBC QQ14
 ASL A                  ; *=2 is the fuel price, 14.0 Cr max.
 STA PRXS               ; first entry in prices list

 LDX #1                 ; equip counter

.EQL1                   ; counter X
 STX XX13
 JSR TT67               ; next Row with QQ17 set ; Call TT67, which prints a newline
 LDX XX13
 CLC                    ; no decimal point
 JSR pr2                ; number X
 JSR TT162              ; white space
 LDA XX13               ; equip counter
 CLC                    ; build equip token
 ADC #&68               ; token = fuel..
 JSR TT27               ; process text token
 LDA XX13               ; equip counter
 JSR prx-3              ; return price in (X,Y) for item Acc-1
 SEC                    ; with decimal point
 LDA #25                ; right column
 STA XC
 LDA #6                 ; 6 digits
 JSR TT11               ; print Xlo.Yhi, carry set will make decimal point.
 LDX XX13               ; equip counter
 INX                    ; next equipment item
 CPX Q                  ; count max
 BCC EQL1               ; loop X

 JSR CLYNS              ; clear screen lines
 LDA #127               ; token = ITEM
 JSR prq                ; print Acc then question mark
 JSR gnum               ; get number
 BEQ bay                ; none, back to Bay
 BCS bay                ; exceeded QQ25 max
 SBC #0                 ; Acc = equipment chosen -1
 LDX #2                 ; small indent, next row.
 STX XC
 INC YC
 PHA                    ; store equipment chosen -1
 JSR eq                 ; reduce cash for item chosen Acc if enough
 PLA                    ; equipment chosen -1
 BNE et0                ; not fuel, onto Missile
 STA MCNT
 LDX #70                ; refuel max
 STX QQ14               ; ship fuel. Acc=0 so rattle through ..

.et0                    ; Missile
 CMP #1                 ; item missile?
 BNE et1                ; else Large cargo bay
 LDX NOMSL              ; number of missiles
 INX                    ; increased
 LDY #&75               ; token =  ALL (missiles) PRESENT
 CPX #5                 ; max number of missiles allowed +1
 BCS pres               ; error, Token in Y is already 'present' on ship

 STX NOMSL              ; update number of missiles
 JSR msblob             ; draw all missile blocks

.et1                    ; Large cargo bay
 LDY #&6B               ; token = Large cargo bay
 CMP #2                 ; item Large cargo bay? 
 BNE et2                ; else E.C.M.
 LDX #37                ; already large cargo bay?
 CPX CRGO
 BEQ pres               ; error, Token in Y is already 'present' on ship
 STX CRGO

.et2                    ; E.C.M.
 CMP #3                 ; item E.C.M.
 BNE et3                ; else extra Pulse
 INY                    ; token = E.C.C.system
 LDX ECM                ; already have ?
 BNE pres               ; Token in Y is already 'present' on ship
 DEC ECM                ; #&FF = ECM now present

.et3                    ; extra Pulse
 CMP #4                 ; item extra pulse laser
 BNE et4                ; else extra Beam
 JSR qv                 ; query view, new mount in X
 LDA #4
 LDY LASER,X
 BEQ ed4

.ed7
 LDY #187               ; beam laser power
 BNE pres               ; Token in Y is already 'present' on ship

.ed4
 LDA #POW               ; pulse laser power
 STA LASER,X
 LDA #4                 ; to allow rattle through

.et4                    ; extra Beam
 CMP #5                 ; item extra beam laser
 BNE et5                ; else Fuel scoop
 JSR qv                 ; query view, new mount in X
 STX T1
 LDA #5
 LDY LASER,X
 BEQ ed5
\BPL P%+4
 BMI ed7
 LDA #4
 JSR prx                ; return price in (X,Y) for item Acc
 JSR MCASH              ; add XloYhi to cash

.ed5
 LDA #POW+128
 LDX T1
 STA LASER,X

.et5                    ; Fuel scoop
 LDY #&6F               ; token = FUEL SCOOPS
 CMP #6                 ; item fuel scoop
 BNE et6                ; else Escape pod
 LDX BST                ; barrel status, fuel scoops present
 BEQ ed9                ; empty so Fuel scoop awarded
}

.pres                   ; error, Token in Yreg is already 'present' on ship
{
 STY K                  ; store equipment already present token
 JSR prx                ; return price in (X,Y) for item Acc
 JSR MCASH              ; add XloYhi to cash
 LDA K                  ; equipment present token
 JSR spc                ; Acc to TT27 followed by white space
 LDA #31                ; token = PRESENT
 JSR TT27               ; process text token
}

.err                    ; Also other errors
{
 JSR dn2                ; beep and wait
 JMP BAY                ; start in Docking Bay
}

.ed9                    ; Fuel scoop awarded
{
 DEC BST                ; #&FF = fuel scoops awarded
}

.et6                    ; Escape pod
{
 INY                    ; token = escape pod
 CMP #7                 ; item Escape pod
 BNE et7                ; else Energy bomb
 LDX ESCP               ; escape pod
 BNE pres               ; error, Token in Y is already 'present' on ship
 DEC ESCP               ; #&FF = escape pod awarded

.et7                    ; Energy bomb
 INY                    ; token = energy bomb
 CMP #8                 ; item Energy bomb
 BNE et8                ; Energy recharge unit
 LDX BOMB               ; random hyperspace unit in Elite-A
 BNE pres               ; error, Token in Y is already 'present' on ship
 LDX #&7F               ; #&7F Unused energy bomb awarded
 STX BOMB               ; random hyperspace unit in Elite-A

.et8                    ; Energy recharge unit
 INY                    ; token = energy unit
 CMP #9                 ; item Energy unit
 BNE etA                ; else Docking computer
 LDX ENGY               ; extra energy unit/ recharge rate
 BNE pres               ; error, Token in Y is already 'present' on ship
 INC ENGY               ; increase extra energy unit/ recharge rate

.etA                    ; Docking computer
 INY                    ; token = docking computer
 CMP #10                ; item docking computer
 BNE etB                ; else Galactic hyperdrive
 LDX DKCMP              ; docking computer
 BNE pres               ; error, Token in Y is already 'present' on ship
 DEC DKCMP              ; #&FF = docking computer awarded

.etB                    ; Galactic hyperdrive
 INY                    ; token = galactic hyperdrive
 CMP #11                ; item galactic hyperdrive
 BNE et9                ; else Military laser
 LDX GHYP               ; galactic hyperdrive
 BNE pres               ; error, Token in Y is already 'present' on ship
 DEC GHYP               ; #&FF = galactic hyperdrive awarded

.et9                    ; display cash and Loop
 JSR dn                 ; display cash
 JMP EQSHP              ; equip ship, new menu screen
}

.dn                     ; display cash
{
 JSR TT162              ; white space
 LDA #119               ; token = CASH 0x00
 JSR spc                ; Acc to TT27 followed by white space
}

.dn2                    ; beep, delay. 
{
 JSR BEEP
 LDY #50                ; moderate delay
 JMP DELAY              ; Yreg is length of delay counter
}

\ *****************************************************************************
\ Subroutine: eq
\
\ reduce cash for item Acc if enough
\ *****************************************************************************

.eq                     ; reduce cash for item Acc if enough
{
 JSR prx                ; return price in (X,Y) for item Acc
 JSR LCASH              ; less cash
 BCS c                  ; rts if ok, else not enough
 LDA #197               ; token = CASH
                        ; err msg A then question mark
 JSR prq                ; print Acc then question mark
 JMP err                ; err msg for eqshp
                        ; return price in (X,Y) for item Acc-1
 SEC
 SBC #1
}

\ *****************************************************************************
\ Subroutine: prx
\
\ return price in (X,Y) for item Acc
\ *****************************************************************************

.prx                    ; return price in (X,Y) for item Acc
{
 ASL A
 TAY                    ; build index
 LDX PRXS,Y             ; equipment price lo
 LDA PRXS+1,Y           ; equipment price hi
 TAY
}

.c
{
 RTS
}

\ *****************************************************************************
\ Subroutine: qv
\
\ query which view for laser mount, returned in Xreg.
\ *****************************************************************************

.qv                     ; query which view for laser mount, returned in Xreg.
{
 LDY #16                ; view options listed mid screen 
 STY YC

.qv1
 LDX #12                ; indent
 STX XC
 TYA                    ; view counter based on YC
 CLC
 ADC #&30-16            ; start at ascii '0'
 JSR spc                ; Acc to TT27 followed by white space
 LDA YC
 CLC                    ; token based on YC
 ADC #&50               ; start at token #&60 = FRONT
 JSR TT27               ; process text token
 INC YC
 LDY YC
 CPY #20                ; 4th view done
 BCC qv1                ; loop Y

.qv3
 JSR CLYNS              ; clear screen lines

.qv2                    ; repeat until valid
 LDA #175               ; token = VIEW
 JSR prq                ; print Acc then question mark
 JSR TT217              ; get ascii from keyboard, store in X and A
 SEC
 SBC #&30               ; convert to number
 CMP #4                 ; max laser mounts
 BCS qv3                ; exit valid input < max view
 TAX                    ; Xreg has valid mount
 RTS
}

\ *****************************************************************************
\ Save output/ELTD.bin
\ *****************************************************************************

PRINT "ELITE D"
PRINT "Assembled at ", ~CODE_D%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_D%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_D%

PRINT "S.ELTD ", ~CODE_D%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_D%
SAVE "output/ELTD.bin", CODE_D%, P%, LOAD%

\ *****************************************************************************
\ ELITE E
\ *****************************************************************************

CODE_E% = P%
LOAD_E% = LOAD% + P% - CODE%

MAPCHAR '(', '('EOR&A4
MAPCHAR 'C', 'C'EOR&A4
MAPCHAR ')', ')'EOR&A4
MAPCHAR 'B', 'B'EOR&A4
MAPCHAR 'e', 'e'EOR&A4
MAPCHAR 'l', 'l'EOR&A4
MAPCHAR '/', '/'EOR&A4
MAPCHAR 'r', 'r'EOR&A4
MAPCHAR 'a', 'a'EOR&A4
MAPCHAR 'b', 'b'EOR&A4
MAPCHAR 'n', 'n'EOR&A4
MAPCHAR '1', '1'EOR&A4
MAPCHAR '9', '9'EOR&A4
MAPCHAR '8', '8'EOR&A4
MAPCHAR '4', '4'EOR&A4

.BDOLLAR
 EQUS  "(C)Bell/Braben1984"

MAPCHAR '(', '('
MAPCHAR 'C', 'C'
MAPCHAR ')', ')'
MAPCHAR 'B', 'B'
MAPCHAR 'e', 'e'
MAPCHAR 'l', 'l'
MAPCHAR '/', '/'
MAPCHAR 'r', 'r'
MAPCHAR 'a', 'a'
MAPCHAR 'b', 'b'
MAPCHAR 'n', 'n'
MAPCHAR '1', '1'
MAPCHAR '9', '9'
MAPCHAR '8', '8'
MAPCHAR '4', '4'

\ *****************************************************************************
\ Subroutine: cpl
\
\ Print control code 3 (the selected system name, i.e. the one in the
\ cross-hairs in the short range chart).
\
\ *****************************************************************************
\
\ System names are generated from the three 16-bit seeds for that system. In
\ the case of the selected system, those seeds live at QQ15. The process works
\ as follows, where w0, w1, w2 are the seeds for the system in question 
\
\   1. Check bit 6 of w0_lo. If it is set then we will generate four two-letter
\      pairs for the name (8 characters in total), otherwise we will generate
\      three pairs (6 characters).
\
\   2. Generate the first two letters by taking bits 0-4 of w2_hi. If this is
\      zero, jump to the next step, otherwise we have a number in the range
\      1-31. Add 128 to get a number in the range 129-159, and convert this to
\      a two-letter token (see elite-words.asm for more on two-letter tokens).
\
\   3. Twist the seeds by calling TT54 and repeat the previous step, until we
\      have processed three or four pairs, depending on step 1.
\
\ One final note. As the process above involves twisting the seeds three or
\ four times, they will be changed, so we also need to back up the original
\ seeds before starting the above process, and restore them afterwards.
\ *****************************************************************************

.cpl
{
 LDX #5                 ; First we need to backup the seeds in QQ15, so set up
                        ; a counter in X to cover three 16-bit seeds (i.e.
                        ; 6 bytes)

.TT53
 LDA QQ15,X             ; Copy byte X from QQ15 to QQ19
 STA QQ19,X

 DEX                    ; Decrement the loop counter

 BPL TT53               ; Loop back for the next byte to backup

 LDY #3                 ; Step 1: Now that the seeds are backed up, we can
                        ; start the name-generation process. We will either
                        ; need to loop three or four times, so for now set
                        ; up a counter in Y to loop four times

 BIT QQ15               ; Check bit 6 of w0_lo, which is stored in QQ15

 BVS P%+3               ; If bit 6 is set then skip over the next instruction

 DEY                    ; Bit 6 is clear, so we only want to loop three times,
                        ; so decrement the loop counter in Y

 STY T                  ; Store the loop counter in T

.TT55
 LDA QQ15+5             ; Step 2: Load w2_hi, which is stored in QQ15+5, and
 AND #31                ; extract bits 0-4 by AND-ing with %0001 1111 (31)

 BEQ P%+7               ; If all those bits are zero, then skip the following
                        ; 2 instructions to go to step 3

 ORA #128               ; We now have a number in the range 1-31, which we can
 JSR TT27               ; easily convert into a two-letter token, but first we
                        ; need to add 128 to get a range of 129-159

 JSR TT54               ; Step 3: twist the seeds in QQ15

 DEC T                  ; Decrement the loop counter

 BPL TT55               ; Loop back for the next two letters

 LDX #5                 ; We have printed the system name, so we can now
                        ; restore the seeds we backed up earlier. Set up a
                        ; counter in X to cover three 16-bit seeds (i.e. 6
                        ; bytes)

.TT56
 LDA QQ19,X             ; Copy byte X from QQ19 to QQ15
 STA QQ15,X

 DEX                    ; Decrement the loop counter

 BPL TT56               ; Loop back for the next byte to restore

 RTS                    ; Once all the seeds are restored, return from the
                        ; subroutine
}

\ *****************************************************************************
\ Subroutine: cmn
\
\ Print control code 4 (the commander's name).
\ *****************************************************************************

.cmn
{
 LDY #0                 ; Set up a counter in Y, starting from 0

.QUL4
 LDA NA%,Y              ; The commander's name is stored at NA%, so load the
                        ; Y-th character from NA%
 
 CMP #13                ; If we have reached the end of the name, return from
 BEQ ypl-1              ; the subroutine (ypl-1 points to the RTS below)
 
 JSR TT26               ; Print the character we just loaded
 
 INY                    ; Increment the loop counter
 
 BNE QUL4               ; Loop back for the next character
 
 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: ypl
\
\ Print control code 2 (the current system name).
\ *****************************************************************************

.ypl
{
 LDA MJ                 ; Check the mis-jump flag at MJ, and if it is non-zero
 BNE cmn-1              ; then return from the subroutine, as we are in
                        ; witchspace, and witchspace doesn't have a system name
 
 JSR TT62               ; Call TT62 below to swap the three 16-bit seeds in
                        ; QQ2 and QQ15 (before the swap, QQ2 contains the seeds
                        ; for the current system, while QQ15 contains the seeds
                        ; for the selected system)
 
 JSR cpl                ; Call cpl to print out the system name for the seeds
                        ; in QQ15 (which now contains the seeds for the current
                        ; system)
                        
                        ; Now we fall through into the TT62 subroutine, which
                        ; will swap QQ2 and QQ15 once again, so everything goes
                        ; back into the right place, and the RTS at the end of
                        ; TT62 will return from the subroutine

.TT62
 LDX #5                 ; Set up a counter in X for the three 16-bit seeds we
                        ; want to swap (i.e. 6 bytes)

.TT78
 LDA QQ15,X             ; Swap byte X between QQ2 and QQ15
 LDY QQ2,X
 STA QQ2,X
 STY QQ15,X
 
 DEX                    ; Decrement the loop counter
 
 BPL TT78               ; Loop back for the next byte to swap
 
 RTS                    ; Once all bytes are swapped, return from the
                        ; subroutine
}

\ *****************************************************************************
\ Subroutine: tal
\
\ Print control code 1 (the current galaxy number, right-aligned to width 3).
\ *****************************************************************************

.tal
{
 CLC                    ; We don't want to print the galaxy number with a
                        ; decimal point, so clear the carry flag for pr2 to
                        ; take as an argument
 
 LDX GCNT               ; Load the current galaxy number from GCNT into X
 
 INX                    ; Add 1 to the galaxy number, as the galaxy numbers
                        ; are 0-7 internally, but we want to display them as
                        ; galaxy 1 through 8
 
 JMP pr2                ; Jump to pr2, which prints the number in X to a width
                        ; of 3 figures, left-padding with spaces to a width of
                        ; 3, and once done, return from the subroutine (as pr2
                        ; ends with an RTS)
}

\ *****************************************************************************
\ Subroutine: fwl
\
\ Print control code 5 ("FUEL: ", fuel level, " LIGHT YEARS", newline, "CASH:",
\ control code 0).
\ *****************************************************************************

.fwl
{
 LDA #105               ; Print recursive token 105 ("FUEL") followed by a
 JSR TT68               ; colon
 
 LDX QQ14               ; Load the current fuel level from QQ14

 SEC                    ; We want to print the fuel level with a decimal point,
                        ; so set the carry flag for pr2 to take as an argument

 JSR pr2                ; Call pr2, which prints the number in X to a width of
                        ; 3 figures (i.e. in the format x.x, which will always
                        ; be exactly 3 characters as the maximum fuel is 7.0)

 LDA #195               ; Print recursive token 35 ("LIGHT YEARS") followed by
 JSR plf                ; a newline

.PCASH                  ; This label is not used but is in the original source

 LDA #119               ; Print recursive token 119 ("CASH:" then control code
 BNE TT27               ; 0, which prints cash levels, then " CR" and newline)
}

\ *****************************************************************************
\ Subroutine: csh
\
\ Print control code 0 (the current amount of cash, right-aligned to width 9,
\ followed by " CR" and a newline).
\ *****************************************************************************

.csh
{
 LDX #3                 ; We are going to use the BPRNT routine to print out
                        ; the current amount of cash, which is stored as a
                        ; 32-bit number at location CASH. BPRNT prints out
                        ; the 32-bit number stored in K, so before we call
                        ; BPRNT, we need to copy the four bytes from CASH into
                        ; K, so first we set up a counter in X for the 4 bytes

.pc1
 LDA CASH,X             ; Copy byte X from CASH to K
 STA K,X

 DEX                    ; Decrement the loop counter
 
 BPL pc1                ; Loop back for the next byte to copy

 LDA #9                 ; We want to print the cash using up to 9 digits
 STA U                  ; (including the decimal point), so store this in U
                        ; for BRPNT to take as an argument
 
 SEC                    ; We want to print the fuel level with a decimal point,
                        ; so set the carry flag for BRPNT to take as an
                        ; argument

 JSR BPRNT              ; Print the amount of cash to 9 digits with a decimal
                        ; point

 LDA #226               ; Print recursive token 66 (" CR") followed by a
                        ; newline by falling through into plf
}

\ *****************************************************************************
\ Subroutine: plf
\
\ Print a text token followed by a newline.
\
\ Arguments:
\
\   A           The text token to be printed
\ *****************************************************************************

.plf
{
 JSR TT27               ; Print the text token in A

 JMP TT67               ; Jump to TT67, which prints a newline
}

\ *****************************************************************************
\ Subroutine: TT68
\
\ Print a text token followed by a colon.
\
\ Arguments:
\
\   A           The text token to be printed
\ *****************************************************************************

.TT68
{
 JSR TT27               ; Print the text token in A and fall through into TT73
                        ; to print a colon
}

\ *****************************************************************************
\ Subroutine: TT73
\
\ Print a colon.
\ *****************************************************************************

.TT73
{
 LDA #':'               ; Set A to ASCII ':' and fall through into TT27 to
                        ; actually print the colon
}

\ *****************************************************************************
\ Subroutine: TT27
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). See elite-words.asm for a discussion of the token system
\ used in Elite.
\
\ Arguments:
\
\   A           The text token to be printed
\ *****************************************************************************

.TT27
{
 TAX                    ; Copy the token number from A to X. We can then keep
                        ; decrementing X and testing it against zero, while
                        ; keeping the original token number intact in A; this
                        ; effectively implements a switch statement on the
                        ; value of the token

 BEQ csh                ; If token = 0, this is control code 0 (current amount
                        ; of cash and newline), so jump to csh

 BMI TT43               ; If token > 127, this is either a two-letter token
                        ; (128-159) or a recursive token (160-255), so jump
                        ; to .TT43 to process tokens

 DEX                    ; If token = 1, this is control code 1 (current
 BEQ tal                ; galaxy number), so jump to tal
 
 DEX                    ; If token = 2, this is control code 2 (current system
 BEQ ypl                ; name), so jump to ypl

 DEX                    ; If token > 3, skip the following instruction
 BNE P%+5
 
 JMP cpl                ; This token is control code 3 (selected system name)
                        ; so jump to cpl

 DEX                    ; If token = 4, this is control code 4 (commander
 BEQ cmn                ; name), so jump to cmm

 DEX                    ; If token = 5, this is control code 5 (fuel, newline,
 BEQ fwl                ; cash, newline), so jump to fwl

 DEX                    ; If token > 6, skip the following 3 instructions
 BNE P%+7

 LDA #128               ; This token is control code 6 (switch to sentence
 STA QQ17               ; case), so store 128 (bit 7 set, bit 6 clear) in QQ17,
 RTS                    ; which controls letter case, and return from the
                        ; subroutine as we are done

 DEX                    ; If token > 8, skip the following 2 instructions
 DEX
 BNE P%+5
 
 STX QQ17               ; This token is control code 8 (switch to ALL CAPS)
 RTS                    ; so store 0 in QQ17, which controls letter case, and
                        ; return from the subroutine as we are done

 DEX                    ; If token = 9, this is control code 9 (tab to column
 BEQ crlf               ; 21 and print a colon), so jump to crlf
 
 CMP #96                ; By this point, token is either 7, or in 10-127.
 BCS ex                 ; Check token number in A and if token >= 96, then the
                        ; token is in 96-127, which is a recursive token, so
                        ; jump to ex, which prints recursive tokens in this
                        ; range (i.e. where the recursive token number is
                        ; correct and doesn't need correcting)
 
 CMP #14                ; If token < 14, skip the following 2 instructions
 BCC P%+6
 
 CMP #32                ; If token < 32, then this means token is in 14-31, so
 BCC qw                 ; this is a recursive token that needs 114 adding to it
                        ; to get the recursive token number, so jump to qw
                        ; which will do this

                        ; By this point, token is either 7 (beep) or in 10-13
                        ; (line feeds and carriage returns), or in 32-95
                        ; (ASCII letters, numbers and punctuation)

 LDX QQ17               ; Fetch QQ17, which controls letter case, into X
 
 BEQ TT74               ; If QQ17 = 0, then ALL CAPS is set, so jump to TT27
                        ; to print this character as is (i.e. as a capital)
                        
 BMI TT41               ; If QQ17 has bit 7 set, then we are using Sentence
                        ; Case, so jump to TT41, which will print the
                        ; character in upper or lower case, depending on
                        ; whether this is the first letter in a word
  
 BIT QQ17               ; If we get here, QQ17 is not 0 and bit 7 is clear, so
 BVS TT46               ; either it is bit 6 that is set, or some other flag in
                        ; QQ17 is set (bits 0-5). So check whether bit 6 is set.
                        ; If it is, then ALL CAPS has been set (as bit 7 is
                        ; clear) but bit 6 is still indicating that the next
                        ; character should be printed in lower case, so we need
                        ; to fix this. We do this with a jump to TT46, which
                        ; will print this character in upper case and clear bit
                        ; 6, so the flags are consistent with ALL CAPS going
                        ; forward.

                        ; If we get here, some other flag is set in QQ17 (one
                        ; of bits 0-5 is set), which shouldn't happen in this
                        ; version of Elite. If this were the case, then we
                        ; would fall through into TT42 to print in lower case,
                        ; which is how printing all words in lower case could
                        ; be supported (by setting QQ17 to 1, say).
}

\ *****************************************************************************
\ Subroutine: TT42
\
\ Exposed labels: TT44
\
\ Print a letter in lower case.
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\ *****************************************************************************

.TT42
{
 CMP #'A'               ; If A < ASCII 'A', then this is punctuation, so jump
 BCC TT44               ; to TT26 (via TT44) to print the character as is, as
                        ; we don't care about the character's case

 CMP #'Z' + 1           ; If A >= (ASCII 'Z' + 1), then this is also
 BCS TT44               ; punctuation, so jump to TT26 (via TT44) to print the
                        ; character as is, as we don't care about the
                        ; character's case
                        
 ADC #32                ; Add 32 to the character, to convert it from upper to
                        ; to lower case

.^TT44
 JMP TT26               ; Print the character in A
}

\ *****************************************************************************
\ Subroutine: TT41
\
\ Print a letter according to Sentence Case. The rules are as follows:
\
\   * If QQ17 bit 6 is set, print lower case (via TT45)
\
\   * If QQ17 bit 6 clear, then:
\
\       * If character is punctuation, just print it
\
\       * If character is a letter, set QQ17 bit 6 and print letter as a capital
\
\ Entry conditions:
\
\   * QQ17 bit 7 is set
\
\   * X contains the value of QQ17
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\ *****************************************************************************

.TT41                   ; If we get here, then QQ17 has bit 7 set, so we are in
{
                        ; Sentence Case
 
 BIT QQ17               ; If QQ17 also has bit 6 set, jump to TT45 to print
 BVS TT45               ; this character in lower case

                        ; If we get here, then QQ17 has bit 6 clear and bit 7
                        ; set, so we are in Sentence Case and we need to print
                        ; the next letter in upper case

 CMP #'A'               ; If A < ASCII 'A', then this is punctuation, so jump
 BCC TT74               ; to TT26 (via TT44) to print the character as is, as
                        ; we don't care about the character's case

 PHA                    ; Otherwise this is a letter, so store the token number
 
 TXA                    ; Set bit 6 in QQ17 (X contains the current QQ17)
 ORA #64                ; so the next letter after this one is printed in lower
 STA QQ17               ; case
 
 PLA                    ; Restore the token number into A
 
 BNE TT44               ; Jump to TT26 (via TT44) to print the character in A
                        ; (this BNE is effectively a JMP as A will never be
                        ; zero)
}

\ *****************************************************************************
\ Subroutine: qw
\
\ Print a recursive token where the token number is in 128-145 (so the value
\ passed to TT27 is in the range 14-31).
\
\ Arguments:
\
\   A           A value from 128-145, which refers to a recursive token in the
\               range 14-31
\ *****************************************************************************

.qw
{
 ADC #114               ; This is a recursive token in the range 0-95, so add
 BNE ex                 ; 114 to the argument to get the token number 128-145
                        ; and jump to ex to print it
}

\ *****************************************************************************
\ Subroutine: crlf
\
\ Print control code 9 (tab to column 21 and print a colon). The subroutine
\ name is pretty misleading, as it doesn't have anything to do with carriage
\ returns or line feeds.
\ *****************************************************************************

.crlf
{
 LDA #21                ; Set the X-column in XC to 21
 STA XC

 BNE TT73               ; Jump to TT73, which prints a colon (this BNE is
                        ; effectively a JMP as A is always non-zero)
}

\ *****************************************************************************
\ Subroutine: TT45
\
\ Print a letter in lower case. Specifically:
\
\   * If QQ17 = &FF, abort printing this character
\
\   * If a letter then print in lower case
\
\   * Otherwise this is punctuation, so clear bit 6 in QQ17 and print
\
\ Entry conditions:
\
\   * QQ17 bit 6 is set
\
\   * QQ17 bit 7 is set
\
\   * X contains the value of QQ17
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\ *****************************************************************************

.TT45                   ; If we get here, then QQ17 has bit 6 and 7 set, so we
{
                        ; are in Sentence Case and we need to print the next
                        ; letter in lower case

 CPX #&FF               ; If QQ17 = #&FF then return from the subroutine (as)
 BEQ TT48               ; TT48 contains an RTS)

 CMP #'A'               ; If A >= ASCII 'A', then jump to TT42, which will
 BCS TT42               ; print the letter in lowercase
 
                        ; Otherwise this is not a letter, it's punctuation, so
                        ; this is effectively a word break. We therefore fall
                        ; through to TT46 to print the character and set QQ17
                        ; to ensure the next word starts with a capital letter
}

\ *****************************************************************************
\ Subroutine: TT46
\
\ Print character and clear bit 6 in QQ17, so that the next letter that gets
\ printed after this will start with a capital letter.
\
\ Entry conditions:
\
\   * QQ17 bit 6 is set
\
\   * QQ17 bit 7 is set
\
\   * X contains the value of QQ17
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\ *****************************************************************************

.TT46
{
 PHA                    ; Store the token number
 
 TXA                    ; Clear bit 6 in QQ17 (X contains the current QQ17)
 AND #191               ; so the next letter after this one is printed in upper
 STA QQ17               ; case
 
 PLA                    ; Restore the token number into A

                        ; Now fall through into TT74 to print the character
}

\ *****************************************************************************
\ Subroutine: TT74
\
\ Print a character.
\
\ Arguments:
\
\   A           The character to be printed
\ *****************************************************************************

.TT74
{
 JMP TT26               ; Print the character in A
}

\ *****************************************************************************
\ Subroutine: TT43
\
\ Print a two-letter token, or a recursive token where the token number is in
\ 0-95 (so the value passed to TT27 is in the range 160-255).
\
\ Arguments:
\
\   A           One of the following:
\                 * 128-159 (two-letter token)
\                 * 160-255 (the argument to TT27 that refers to a recursive
\                   token in the range 0-95)
\ *****************************************************************************

.TT43
{
 CMP #160               ; If token >= 160, then this is a recursive token, so
 BCS TT47               ; jump to TT47 below to process it

 AND #127               ; This is a two-letter token with number 128-159. The
 ASL A                  ; set of two-letter tokens is stored as one long string
                        ; ("ALLEXEGE...") at QQ16, so to convert this into the
                        ; token's position in this string, we subtract 128 (or
                        ; just clear bit 7) and multiply by 2 (or shift left)

 TAY                    ; Transfer the token's position into Y so we can look
                        ; up the token using absolute indexed mode

 LDA QQ16,Y             ; Get the first letter of the token and print it
 JSR TT27

 LDA QQ16+1,Y           ; Get the second letter of the token

 CMP #'?'               ; If the second letter of the token is a question mark
 BEQ TT48               ; then just return from the subroutine without
                        ; printing, as this is a one-letter token (TT48
                        ; contains an RTS)

 JMP TT27               ; Print the second letter and return from the
                        ; subroutine

.TT47
 SBC #160               ; This is a recursive token in the range 160-255, so
                        ; subtract 160 from the argument to get the token
                        ; number 0-95 and fall through into ex to print it
}

\ *****************************************************************************
\ Subroutine: ex
\
\ Exposed labels: TT48
\
\ Print a recursive token.
\
\ Arguments:
\
\   A           The recursive token to be printed, in the range 0-148
\
\ *****************************************************************************
\
\ This routine works its way through the recursive tokens that are stored in
\ tokenised form in memory at &0400 - &06FF, and when it finds token number A,
\ it prints it. Tokens are null-terminated in memory and fill three pages,
\ but there is no lookup table as that would consume too much memory, so the
\ only way to find the correct token is to start at the beginning and look
\ through the table byte by byte, counting tokens as we go until we are in the
\ right place. This approach might not be terribly speed efficient, but it is
\ certainly memory-efficient.
\
\ The variable QQ18 points to the token table at &0400.
\
\ For details of the tokenisation system, see elite-words.asm.
\ *****************************************************************************

.ex
{
 TAX                    ; Copy the token number into X

 LDA #LO(QQ18)          ; Set V, V+1 to point to the recursive token table at
 STA V                  ; QQ18, which is assembled in elite-words.asm
 LDA #HI(QQ18)
 STA V+1

 LDY #0                 ; Set a counter Y to point to the character offset
                        ; as we scan through the table

 TXA                    ; Copy the token number back into A, so both A and X
                        ; now contain the token number we want to print

 BEQ TT50               ; If the token number we want is 0, then we have
                        ; already found the token we are looking for, so jump
                        ; to TT50, otherwise start working our way through the
                        ; null-terminated token table until we find the X-th
                        ; token

.TT51
 LDA (V),Y              ; Fetch the Y-th character from the token table page
                        ; we are currently scanning

 BEQ TT49               ; If the character is null, we've reached the end of
                        ; this token, so jump to TT49

 INY                    ; Increment character pointer and loop back round for
 BNE TT51               ; the next character in this token, assuming Y hasn't
                        ; yet wrapped around to 0

 INC V+1                ; If it has wrapped round to 0, we have just crossed
 BNE TT51               ; into a new page, so increment V+1 so that V points
                        ; to the start of the new page

.TT49
 INY                    ; Increment the character pointer

 BNE TT59               ; If Y hasn't just wrapped around to 0, skip the next
                        ; instruction

 INC V+1                ; We have just crossed into a new page, so increment
                        ; V+1 so that V points to the start of the new page

.TT59
 DEX                    ; We have just reached a new token, so decrement the
                        ; token number we are looking for

 BNE TT51               ; Assuming we haven't yet reached the token number in
                        ; X, look back up to keep fetching characters

.TT50                   ; We have now reached the correct token in the token
                        ; table, with Y pointing to the start of the token as
                        ; an offset within the page pointed to by V, so let's
                        ; print the recursive token. Because recursive tokens
                        ; can contain other recursive tokens, we need to store
                        ; our current state on the stack, so we can retrieve
                        ; it after printing each character in this token.

 TYA                    ; Store the offset in Y on the stack
 PHA

 LDA V+1                ; Store the high byte of V (the page containing the
 PHA                    ; token we have found) on the stack, so the stack now
                        ; contains the address of the start of this token

 LDA (V),Y              ; Load the character at offset Y in the token table,
                        ; which is the next character of this token that we
                        ; want to print

 EOR #35                ; Tokens are stored in memory having been EOR'd with 35
                        ; (see elite-words.asm for details), so we repeat the
                        ; EOR to get the actual character to print

 JSR TT27               ; Print the text token in A, which could be a letter,
                        ; number, control code, two-letter token or another
                        ; recursive token

 PLA                    ; Restore the high byte of V (the page containing the
 STA V+1                ; token we have found) into V+1

 PLA                    ; Restore the offset into Y
 TAY

 INY                    ; Increment Y to point to the next character in the
                        ; token we are printing

 BNE P%+4               ; If Y is zero then we have just crossed into a new
 INC V+1                ; page, so increment V+1 so that V points to the start
                        ; of the new page

 LDA (V),Y              ; Load the next character we want to print into A

 BNE TT50               ; If this is not the null character at the end of the
                        ; token, jump back up to TT50 to print the next
                        ; character, otherwise we are done printing

.^TT48
 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: EX2
\
\ ready to remove - Explosion Code
\ *****************************************************************************


.EX2                    ; ready to remove - Explosion Code
{
 LDA INWK+31            ; exploding/display state|missiles
 ORA #&A0               ; bit7 to kill it, bit5 finished exploding.
 STA INWK+31
 RTS
}

\ *****************************************************************************
\ Subroutine: DOEXP
\
\ Do Explosion as bit5 set by LL9
\ *****************************************************************************

.DOEXP                  ; Do Explosion as bit5 set by LL9
{
 LDA INWK+31
 AND #64                ; display state keep bit6
 BEQ P%+5               ; exploding not started, skip ptcls
 JSR PTCLS              ; else exploding has started, remove old plot Cloud.
 LDA INWK+6             ; zlo. All do a round of cloud counter.
 STA T
 LDA INWK+7
 CMP #&20               ; zhi < 32,  boost*8
 BCC P%+6               ; skip default
 LDA #&FE               ; furthest cloud distance
 BNE yy                 ; guaranteed Cloud
 ASL T                  ; else use zlo
 ROL A                  ; *=2
 ASL T
 ROL A                  ; z lo.hi*=4
 SEC                    ; ensure cloud distance not 0
 ROL A

.yy                     ; Cloud
 STA Q                  ; cloud distance
 LDY #1                 ; get ship heap byte1, which started at #18
 LDA (XX19),Y
 ADC #4                 ; +=4 Cloud counter 
 BCS EX2                ; until overflow and ready to removed, up.

 STA (XX19),Y           ; else update Cloud counter
 JSR DVID4              ; P.R = cloud counter/cloud distance
 LDA P
 CMP #&1C               ; hi < #28 ?
 BCC P%+6               ; cloud radius < 28 skip max
 LDA #&FE               ; else max radius
 BNE LABEL_1            ; guaranteed  Acc = Cloud radius
 ASL R
 ROL A                  ; *=2
 ASL R
 ROL A                  ; *=4
 ASL R
 ROL A                  ; *=8

.LABEL_1                ; Acc = Cloud radius
 DEY                    ; Y = 0, save ship heap byte0 = Cloud radius
 STA (XX19),Y
 LDA INWK+31            ; display explosion state|missiles
 AND #&BF               ; clear bit6 in case can't start
 STA INWK+31
 AND #8                 ; keep bit3 of display state, something to erase?
 BEQ TT48               ; rts, up.

 LDY #2                 ; else ship heap byte2 = hull byte#7 dust
 LDA (XX19),Y
 TAY                    ; Y counter multiples of 4, greater than 6.

.EXL1                   ; counter Y
 LDA XX3-7,Y            ; from (all visible) vertex heap
 STA (XX19),Y           ; to ship heap
 DEY                    ; next vertex
 CPY #6                 ; until down to 7
 BNE EXL1               ; loop Y
 LDA INWK+31
 ORA #64                ; set bit6 so this dust will be erased
 STA INWK+31

.PTCLS                  ; plot Cloud
 LDY #0                 ; ship heap byte0 = Cloud radius
 LDA (XX19),Y
 STA Q                  ; Cloud radius
 INY                    ; ship byte1 = Cloud counter
 LDA (XX19),Y
 BPL P%+4               ; Cloud counter not half way, skip flip
 EOR #&FF               ; else more than half way through cloud counter
 LSR A
 LSR A
 LSR A                  ; cloud counter/8 max = 15 pixels
                        ; pixel count set
 ORA #1                 ; 1 min
 STA U                  ; number of pixels per vertex
 INY                    ; ship byte2 = dust = counter target
 LDA (XX19),Y
 STA TGT                ; = hull byte#7 dust = counter target
 LDA RAND+1
 PHA                    ; restrict random

 LDY #6                 ; ship heap index at vertex-1
.EXL5                   ; counter Y=CNT Outer loop +=4 for each vertex on ship heap
 LDX #3

.EXL3                   ; counter X, K3 loaded with reversed vertex from heap.
 INY                    ; Y++ = 7 start is a vertex on ship heap
 LDA (XX19),Y
 STA K3,X               ; Yorg hi,lo, Xorg hi,lo
 DEX                    ; next coord
 BPL EXL3               ; loop X
 STY CNT                ; store index for vertex on ship heap
 LDY #2

.EXL2                   ; inner counter Y to set rnd for each vertex
 INY                    ; Y++ = 3 start, the 4 randoms on ship heap.
 LDA (XX19),Y
 EOR CNT                ; rnd seeded for each vertex CNT
 STA &FFFD,Y            ; using bytes 3,4,5,6.
 CPY #6                 ; 6 is last one
 BNE EXL2               ; loop next inner Y rnd seed
 LDY U                  ; number of pixels per vertex

.EXL4                   ; counter Y for pixels at each (reversed) vertex in K3
 JSR DORND2             ; leave bit0 of RAND+2 at 0
 STA ZZ                 ; restricted pixel depth
 LDA K3+1               ; Yorg lo
 STA R
 LDA K3                 ; Yorg hi
 JSR EXS1               ; Xlo.Ahi = Ylo+/-rnd*Cloud radius
 BNE EX11               ; Ahi too big, skip but new rnd
 CPX #2*Y-1             ; #2*Y-1 = Y screen range
 BCS EX11               ; too big, skip but new rnd.
 STX Y1                 ; Y coord
 LDA K3+3               ; Xorg lo
 STA R
 LDA K3+2               ; Xorg hi
 JSR EXS1               ; Xlo.Ahi = Xlo+/-rnd*Cloud radius
 BNE EX4                ; skip pixel
 LDA Y1                 ; reload Y coord
 JSR PIXEL              ; at (X,Y1) ZZ away

.EX4                    ; skipped pixel
 DEY                    ; loop Y
 BPL EXL4               ; next pixel at vertex
 LDY CNT                ; reload index for vertex on ship heap
 CPY TGT                ; counter target
 BCC EXL5               ; Outer loop, next vertex on ship heap

 PLA                    ; restore random
 STA RAND+1
 LDA K%+6               ; planet zlo seed
 STA RAND+3
 RTS

.EX11                   ; skipped pixel as Y too big, but new rnd
 JSR DORND2             ; new restricted rnd
 JMP EX4                ; skipped pixel, up.

.EXS1                   ; Xlo.Ahi = Rlo.Ahi+/-rnd*Q
 STA S                  ; store origin hi
 JSR DORND2             ; restricted rnd, carry.
 ROL A                  ; rnd hi
 BCS EX5                ; negative
 JSR FMLTU              ; Xlo = Arnd*Q=Cloud radius/256
 ADC R
 TAX                    ; Xlo = R+Arnd*Cloud radius/256
 LDA S
 ADC #0                 ; Ahi = S
 RTS

.EX5                    ; rnd hi negative
 JSR FMLTU              ; A=A*Q/256unsg
 STA T
 LDA R
 SBC T                  ; Arnd*Q=Cloud radius/256
 TAX                    ; Xlo = Rlo-T
 LDA S
 SBC #0                 ; Ahi = S
 RTS                    ; end of explosion code
}

\ *****************************************************************************
\ Subroutine: SOS1
\
\ Set up planet
\ *****************************************************************************

.SOS1                   ; Set up planet
{
 JSR msblob             ; draw all missile blocks
 LDA #127               ; no damping of rotation
 STA INWK+29            ; rotx counter
 STA INWK+30            ; roty counter
 LDA tek                ; techlevel of present system
 AND #2                 ; bit1 determines planet type 80..82
 ORA #128               ; type is planet
 JMP NWSHP              ; new ship type Acc
}

\ *****************************************************************************
\ Subroutine: SOLAR
\
\ Set up planet and sun
\ *****************************************************************************

.SOLAR                  ; Set up planet and sun
{
 LSR FIST               ; reduce Fugitative/Innocent legal status
 JSR ZINF               ; zero info
 LDA QQ15+1             ; w0_h is Economy
 AND #7                 ; disk version has AND 3
 ADC #6                 ; disk version has ADC 3
 LSR A                  ; not in disk version
 STA INWK+8             ; zsg is planet distance
 ROR A                  ; planet off to top right
 STA INWK+2             ; xsg
 STA INWK+5             ; ysg

 JSR SOS1               ; set up planet,up.
 LDA QQ15+3             ; w1_h
 AND #7
 ORA #129               ; sun behind you
 STA INWK+8             ; zsg
 LDA QQ15+5             ; w2_h
 AND #3
 STA INWK+2             ; xsg
 STA INWK+1             ; xhi
 LDA #0                 ; no rotation for sun
 STA INWK+29            ; rotx counter
 STA INWK+30            ; rotz counter
 LDA #&81               ; type is Sun
 JSR NWSHP              ; new ship type Acc
}

\ *****************************************************************************
\ Subroutine: NWSTARS
\
\ New dust field
\ *****************************************************************************

.NWSTARS                ; New dust field
{
 LDA QQ11               ; menu i.d. QQ11 == 0 is space view
\ORA MJ
 BNE WPSHPS             ; if not space view skip over to Wipe Ships
}

\ *****************************************************************************
\ Subroutine: nWq
\
\ New dust
\ *****************************************************************************

.nWq
{
 LDY NOSTM              ; number of dust particles

.SAL4                   ; counter Y
 JSR DORND              ; do random, new A, X.
 ORA #8                 ; flick out in z
 STA SZ,Y               ; dustz
 STA ZZ                 ; distance
 JSR DORND              ; do random, new A, X.
 STA SX,Y               ; dustx
 STA X1
 JSR DORND              ; do random, new A, X.
 STA SY,Y               ; dusty
 STA Y1
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next dust
 BNE SAL4               ; loop Y
}

\ *****************************************************************************
\ Subroutine: WPSHPS
\
\ Wipe Ships on scanner
\ *****************************************************************************

.WPSHPS                 ; Wipe Ships on scanner
{
 LDX #0

.WSL1                   ; outer counter X
 LDA FRIN,X             ; the Type for each of the 12 ships allowed
 BEQ WS2                ; exit as Nothing
 BMI WS1                ; loop as Planet or Sun
 STA TYPE               ; ship type
 JSR GINF               ; Get info on ship X, update INF pointer
 LDY #31                ; load some INWK from (INF)

.WSL2                   ; inner counter Y
 LDA (INF),Y
 STA INWK,Y
 DEY                    ; next byte of univ inf to inwk
 BPL WSL2               ; inner loop Y
 STX XSAV               ; store nearby ship count outer
 JSR SCAN               ; ships on scanner
 LDX XSAV               ; restore
 LDY #31                ; need to adjust INF display state
 LDA (INF),Y
 AND #&A7               ; clear bits 6,4,3 (explode,invisible,dot)
 STA (INF),Y            ; keep bits 7,5,2,1,0 (kill,exploding,missiles)

.WS1                    ; loop as Planet or Sun
 INX                    ; next nearby slot
 BNE WSL1               ; outer loop X

.WS2                    ; exit as Nothing
 LDX #&FF               ; clear line buffers
 STX LSX2               ; lines X2
 STX LSY2               ; lines Y2
}

\ *****************************************************************************
\ Subroutine: FLFLLS
\
\ New Flood-filled Sun, ends with Acc=0
\ *****************************************************************************

.FLFLLS                 ; New Flood-filled Sun, ends with Acc=0
{
 LDY #2*Y-1             ; #2*Y-1 is top of Yscreen
 LDA #0                 ; clear each line

.SAL6                   ; counter Y
 STA LSO,Y              ; line buffer solar
 DEY                    ; fill next line with zeros
 BNE SAL6               ; loop Y
 DEY                    ; Yreg = #&FF
 STY LSX                ; overlaps with LSO vector
 RTS
}

\ *****************************************************************************
\ Subroutine: DET1
\
\ Death with X = 24 text rows
\ *****************************************************************************

.DET1                   ; Death with X = 24 text rows
{
 LDA #6                 ; R6 number of displayed Character rows
 SEI                    ; disable other interrupts
 STA SHEILA+&00         ; 6845 register
 STX SHEILA+&01         ; 6845 data
 CLI                    ; enable interrupts
 RTS
}

\ *****************************************************************************
\ Subroutine: SHD-2
\
\ cap Shield = #&FF \ SHD-2
\ *****************************************************************************

{
 DEX                    ; cap Shield = #&FF \ SHD-2
 RTS                    ; Shield = #&FF
}

\ *****************************************************************************
\ Subroutine: SHD
\
\ let Shield X recharge
\ *****************************************************************************

.SHD                    ; let Shield X recharge
{
 INX
 BEQ SHD-2              ; cap Shield up = #&FF if too big else
}

\ *****************************************************************************
\ Subroutine: DENGY
\
\ Drain player's Energy
\ *****************************************************************************

.DENGY                  ; Drain player's Energy
{
 DEC ENERGY
 PHP                    ; push dec flag
 BNE P%+5               ; skip inc, else underflowing
 INC ENERGY             ; energy set back to 1
 PLP                    ; pull dec flag
 RTS
}

\ *****************************************************************************
\ Subroutine: COMPAS
\
\ space Compass
\ *****************************************************************************

.COMPAS                 ; space Compass
{
 JSR DOT                ; compass dot remove
 LDA SSPR               ; space station present? 0 is SUN.
 BNE SP1                ; compass point to space station, down.
 JSR SPS1               ; XX15 vector to planet
 JMP SP2                ; compass point to XX15
}

\ *****************************************************************************
\ Subroutine: SPS2
\
\ X.Y = A/10 for space compass display
\ *****************************************************************************

.SPS2                   ; X.Y = A/10 for space compass display
{
 ASL A                  ; A is signed unit vector
 TAX                    ; X = 7bits
 LDA #0                 ; Acc gets sign in bit7
 ROR A                  ; from any carry
 TAY                    ; Yreg = bit7 sign
 LDA #20                ; denominator
 STA Q
 TXA                    ; 7bits
 JSR DVID4              ; Phi.Rlo=A/20
 LDX P

 TYA                    ; sign bit
 BMI LL163              ; flip sign of X
 LDY #0                 ; hi +ve
 RTS

.LL163                  ; flip sign of X
 LDY #&FF               ; hi -ve
 TXA                    ; 7bits
 EOR #&FF
 TAX                    ; flipped
 INX                    ; -ve P
 RTS                    ; X -> -X, Y = #&FF.
}

\ *****************************************************************************
\ Subroutine: SPS4
\
\ XX15 vector to #SST
\ *****************************************************************************

.SPS4                   ; XX15 vector to #SST
{
 LDX #8                 ; 9 coords

.SPL1                   ; counter X
 LDA K%+NI%,X           ; allwk+37,X
 STA K3,X
 DEX                    ; next coord
 BPL SPL1               ; loop X
 JMP TAS2               ; build XX15 from K3
}

\ *****************************************************************************
\ Subroutine: SP1
\
\ compass point to space station
\ *****************************************************************************

.SP1                    ; compass point to space station
{
 JSR SPS4               ; XX15 vector to #SST, up.
}

\ *****************************************************************************
\ Subroutine: SP2
\
\ compass point to XX15
\ *****************************************************************************

.SP2                    ; compass point to XX15
{
 LDA XX15               ; xunit
 JSR SPS2               ; X.Y = xunit/10 for space compass display
 TXA                    ; left edge of compass
 ADC #195               ; X-1 \ their comment
 STA COMX               ; compass-x
 LDA XX15+1             ; yunit
 JSR SPS2               ; X.Y = yunit/10 for space compass display
 STX T
 LDA #204               ; needs to be flipped around
 SBC T
 STA COMY               ; compass-y

 LDA #&F0               ; default compass colour yellow
 LDX XX15+2             ; zunit
 BPL P%+4               ; its in front
 LDA #&FF               ; else behind colour is green
 STA COMC               ; compass colour
}

\ *****************************************************************************
\ Subroutine: DOT
\
\ Compass dot
\ *****************************************************************************

.DOT                    ; Compass dot
{
 LDA COMY               ; compass-y
 STA Y1
 LDA COMX               ; compass-x
 STA X1
 LDA COMC               ; compass colour
 STA COL                ; the colour
 CMP #&F0               ; yellow is in front?
 BNE CPIX2              ; hop ahead 4 lines if behind you, narrower bar
}

\ *****************************************************************************
\ Subroutine: CPIX4
\
\ stick head on scanner at height Y1
\ *****************************************************************************

.CPIX4                  ; stick head on scanner at height Y1
{
 JSR CPIX2              ; two visits, Y1 then Y1-1 to make twice as thick.
 DEC Y1                 ; next bar
}

\ *****************************************************************************
\ Subroutine: CPIX2
\
\ narrower bar
\ *****************************************************************************

.CPIX2                  ; Colour Pixel Mode 5
{
 LDA Y1                 ; yscreen

\.CPIX
 TAY                    ; build screen page
 LSR A
 LSR A                  ; upper 5 bits
 LSR A                  ; Y1/8
 ORA #&60               ; screen hi
 STA SCH                ; SC+1
 LDA X1                 ; xscreen
 AND #&F8               ; upper 5 bits
 STA SC
 TYA                    ; yscreen
 AND #7                 ; lower 3 bits
 TAY                    ; byte row set
 LDA X1
 AND #6                 ; build mask index bits 2,1
 LSR A                  ; /=2, carry cleared.
 TAX                    ; color mask index for Mode 5, coloured.
 LDA CTWOS,X
 AND COL                ; the colour
 EOR (SC),Y
 STA (SC),Y

 LDA CTWOS+1,X
 BPL CP1                ; same column
 LDA SC
 ADC #8                 ; next screen column
 STA SC
 LDA CTWOS+1,X

.CP1                    ; same column
 AND COL                ; the colour
 EOR (SC),Y
 STA (SC),Y
 RTS
}

\ *****************************************************************************
\ Subroutine: OOPS
\
\ Lose some shield strength, cargo, could die.
\ *****************************************************************************

.OOPS                   ; Lose some shield strength, cargo, could die.
{
 STA T                  ; dent was in Acc
 LDY #8                 ; get zsg of ship hit
 LDX #0                 ; min
 LDA (INF),Y
 BMI OO1                ; aft shield hit
 LDA FSH                ; forward shield
 SBC T                  ; dent
 BCC OO2                ; clamp forward at 0
 STA FSH                ; forward shield
 RTS

.OO2                    ; clamp forward at 0
\LDX #0
 STX FSH                ; forward shield = 0
 BCC OO3                ; guaranteed, Shield gone

.OO1                    ; Aft shield hit
 LDA ASH                ; aft shield = 0
 SBC T                  ; dent
 BCC OO5                ; clamp aft at 0
 STA ASH                ; aft shield
 RTS

.OO5                    ; clamp aft at 0
\LDX #0
 STX ASH                ; aft shield

.OO3                    ; Shield gone
 ADC ENERGY             ; some energy added, wraps as small dent.
 STA ENERGY
 BEQ P%+4               ; if 0, DEATH
 BCS P%+5               ; overflow just noise EXNO3, OUCH
 JMP DEATH
 JSR EXNO3              ; ominous noises
 JMP OUCH               ; lose cargo/equipment
}

\ *****************************************************************************
\ Subroutine: SPS3
\
\ planet if Xreg=0 for space compass into K3(0to8)
\ *****************************************************************************

.SPS3                   ; planet if Xreg=0 for space compass into K3(0to8)
{
 LDA K%+1,X             ; allwk+1,X
 STA K3,X               ; hi
 LDA K%+2,X             ; allwk+2,X
 TAY                    ; sg
 AND #127               ; sg far7
 STA K3+1,X
 TYA                    ; sg
 AND #128               ; bit7 sign
 STA K3+2,X
 RTS
}

\ *****************************************************************************
\ Subroutine: GINF
\
\ Get the address of the data block for ship number X and store it in INF. This
\ address is fetched from the UNIV table, which stores the addresses of the 13
\ ship data blocks in workspace K%.
\
\ Arguments:
\
\   X           The ship number for which we want the data block address
\ *****************************************************************************

.GINF
{
 TXA                    ; Set Y = X * 2
 ASL A
 TAY

 LDA UNIV,Y             ; Get the high byte of the address of the X-th ship
 STA INF                ; from UNIV and store it in INF

 LDA UNIV+1,Y           ; Get the low byte of the address of the X-th ship
 STA INF+1              ; from UNIV and store it in INF

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: NWSPS
\
\ New Space Station
\ *****************************************************************************

.NWSPS                  ; New Space Station
{
 JSR SPBLB              ; space station bulb
 LDX #1                 ; has ai and ecm
 STX INWK+32
 DEX                    ; rotz counter, no pitch.
 STX INWK+30
\STX INWK+31
 STX FRIN+1             ; use sun slot
 DEX                    ; X = #&FF, rotx counter roll with no damping
 STX INWK+29
 LDX #10                ; 10, 12, 14 for x,y,z inc hi
 JSR NwS1               ; Flip sign of INWK(10)
 JSR NwS1               ; Flip sign of INWK(12)
 JSR NwS1               ; Flip sign of INWK(14)

 LDA #LO(LSO)           ; solar line buffer
 STA INWK+33            ; SST pointer lo
 LDA #HI(LSO)
 STA INWK+34            ; pointer hi
 LDA #SST               ; Type is space station
}

\ *****************************************************************************
\ Subroutine: NWSHP
\
\ Add a new ship to the universe. This creates a block of ship data in the
\ workspace at K% (where we store the ships in our current bubble of universe),
\ and we also add the ship type into the slot index table at FRIN. We can
\ retrieve this block of ship data later using the lookup table at UNIV.
\
\ Arguments:
\
\   A           The type of the ship to add (see variable XX21 for a list of
\               ship types)
\
\ Returns:
\
\   C flag      Set if the ship was successfully added, clear if it wasn't
\               (as there wasn't enough free memory)
\ *****************************************************************************

.NWSHP
{
 STA T                  ; Store the ship type in location T

 LDX #0                 ; Before we can add a new ship, we need to check
                        ; whether we have an empty slot we can put it in. To do
                        ; this, we need to loop through all the slots to look
                        ; for an empty one, so set a counter in X that starts
                        ; from the first slot at 0. When ships are killed, then
                        ; the slots are shuffled down by the KILLSHP routine, so
                        ; the first empty slot will always come after the last
                        ; filled slot. This allows us to tack the new ship's
                        ; data block and ship lines heap onto the end of the
                        ; existing ship data and heap, as shown in the memory
                        ; map below.

.NWL1
 LDA FRIN,X             ; Load the ship type for the X-th slot

 BEQ NW1                ; If it is zero, then this slot is empty and we can use
                        ; it for our new ship, so jump down to NW1

 INX                    ; Otherwise increment X to point to the next slot

 CPX #NOSH              ; If we haven't reached the last slot yet, loop back up
 BCC NWL1               ; to NWL1 to check the next slot

.NW3                    ; Otherwise we don't have an empty slot, so we can't
 CLC                    ; add a new ship, so clear the carry flag to indicate
 RTS                    ; that we have not managed to create the new ship, and
                        ; return from the subroutine

.NW1                    ; If we get here, then we have found an empty slot at
                        ; index X, so we can go ahead and create our new ship.
                        ; We do that by creating a ship data block at INWK and,
                        ; when we are done, copying the block from INWK into
                        ; the workspace at K% (specifically, to INF).

 JSR GINF               ; Get the address of the data block for ship X (which
                        ; is in workspace K%) and store it in INF

 LDA T                  ; If the type of ship that we want to create is
 BMI NW2                ; negative, then this indicates a planet or sun, so
                        ; jump down to NW2, as the next section sets up a ship
                        ; data block, which doesn't apply to planets and suns,
                        ; as they don't have things like shields, missiles,
                        ; vertices and edges.

                        ; This is a ship, so first we need to set up various
                        ; pointers to the ship data we will need. Ship data is
                        ; assembled in a table at location XX21, so refer to
                        ; that variable below for more details on the data
                        ; we're about to access.

 ASL A                  ; Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           ; The ship definitions at XX21 start with a lookup
 STA XX0                ; table that points to the individual ship definitions,
                        ; so this fetches the low byte of this particular ship
                        ; type's definition and stores it in XX0

 LDA XX21-1,Y           ; Fetch the high byte of this particular ship type's 
 STA XX0+1              ; definition and store it in XX0+1

 CPY #2*SST             ; If the ship type is a space station (SST), then jump
 BEQ NW6                ; to NW6, skipping the heap space steps below

                        ; We now want to allocate a heap space that we can use
                        ; while drawing our new ship - the ship lines heap
                        ; space. SLSP points to the start of the current
                        ; heap space, and we can extend it downwards with the
                        ; heap for our new ship (as the heap space always ends
                        ; just before the workspace at WP).

 LDY #5                 ; Fetch ship definition byte #5, which contains the
 LDA (XX0),Y            ; maximum heap size required for plotting the new ship,
 STA T1                 ; and store it in T1

 LDA SLSP               ; Take the 16-bit address in SLSP and subtract T1,
 SEC                    ; storing the 16-bit result in (INWK+34 INWK+33),
 SBC T1                 ; so this now points to the start of the heap space
 STA INWK+33            ; for our new ship
 LDA SLSP+1
 SBC #0
 STA INWK+34

                        ; We now need to check that there is enough free space
                        ; for both this new heap space and the new data block
                        ; for our ship. In memory, this is the layout of the
                        ; ship data and heap space:
                        ;
                        ;   High address
                        ;
                        ;   +-----------------------------------+   &0F34
                        ;   |                                   |
                        ;   | WP workspace                      |
                        ;   |                                   |
                        ;   +-----------------------------------+   &0D40 = WP
                        ;   |                                   |
                        ;   | Current ship lines heap           |
                        ;   |                                   |
                        ;   +-----------------------------------+   SLSP
                        ;   |                                   |
                        ;   | Proposed heap for new ship        |
                        ;   |                                   |
                        ;   +-----------------------------------+   INWK+33
                        ;   |                                   |
                        ;   .                                   .
                        ;   .                                   .
                        ;   .                                   .
                        ;   .                                   .
                        ;   .                                   .
                        ;   |                                   |
                        ;   +-----------------------------------+   INF+NI%
                        ;   |                                   |
                        ;   | Proposed data block for new ship  |
                        ;   |                                   |
                        ;   +-----------------------------------+   INF
                        ;   |                                   |
                        ;   | Existing ship data blocks         |
                        ;   |                                   |
                        ;   +-----------------------------------+   &0900 = K%
                        ;
                        ;   Low address
                        ;
                        ; So, to work out if we have enough space, we have to
                        ; make sure there is room between the end of our new
                        ; ship data block at INF+NI%, and the start of the
                        ; proposed heap for our new ship at INWK+33. Or, to
                        ; put it another way, we need to make sure that:
                        ;
                        ;   INWK+33 > INF+NI%
                        ;
                        ; which is the same as saying:
                        ;
                        ;   INWK+33 - INF > NI%


 LDA INWK+33            ; Calculate INWK+33 - INF, again using 16-bit
\SEC                    ; arithmetic, and put the result in (A Y), so the high
 SBC INF                ; byte is in A and the low byte in Y. The SEC
 TAY                    ; instruction is commented out in the original source;
 LDA INWK+34            ; as the previous subtraction will never underflow, it
 SBC INF+1              ; is superfluous.

 BCC NW3+1              ; If we have an underflow from the subtraction, then
                        ; INF > INWK+33 and we definitely don't have enough
                        ; room for this ship, so jump to NW3+1, which clears
                        ; the carry flag and returns from the subroutine

 BNE NW4                ; If the subtraction of the high bytes in A is not
                        ; zero, and we don't have underflow, then we definitely
                        ; have enough space, so jump to NW4 to continue setting
                        ; up the new ship

 CPY #NI%               ; Otherwise the high bytes are the same in our
 BCC NW3+1              ; subtraction, so now we compare the low byte of the
                        ; result (which is in Y) with NI%. This is the same as
                        ; doing INWK+33 - INF > NI% (see above). If this isn't
                        ; true, the carry flag will be clear and we don't have
                        ; enough space, so we jump to NW3+1, which clears the
                        ; carry flag and returns from the subroutine.

.NW4
 LDA INWK+33            ; If we get here then we do have enough space for our
 STA SLSP               ; new ship, so store the new bottom of the ship lines
 LDA INWK+34            ; heap space (i.e. INWK+33) in SLSP, doing both the
 STA SLSP+1             ; high and low bytes

.NW6
 LDY #14                ; Fetch ship definition byte #14, which contains the
 LDA (XX0),Y            ; ship's energy, and store it in INWK+35
 STA INWK+35

 LDY #19                ; Fetch ship definition byte #19, which contains the
 LDA (XX0),Y            ; number of missiles and laser power, and AND with %111
 AND #7                 ; to extract the number of missiles before storing in
 STA INWK+31            ; INWK+31

 LDA T                  ; Restore the ship type we stored above

.NW2
 STA FRIN,X             ; Store the ship type in the X-th byte of FRIN, so the
                        ; this slot is now shown as occupied in the index table
 
 TAX                    ; Copy the ship type into X

 BMI P%+5               ; If the ship type is negative (planet or sun), then
                        ; skip the following instruction

 INC MANY,X             ; Increment the total number of ships of type X

 LDY #(NI%-1)           ; The final step is to copy the new ship's data block
                        ; from INWK to INF, so set up a counter for NI% bytes
                        ; in Y

.NWL3
 LDA INWK,Y             ; Load the Y-th byte of INWK and store in the Y-th byte
 STA (INF),Y            ; of the workspace pointed to by INF
 
 DEY                    ; Decrement the loop counter
 
 BPL NWL3               ; Loop back for the next byte until we have copied them
                        ; all over

 SEC                    ; We have successfuly created our new ship, so set the
                        ; carry flag to indicate success

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: NwS1
\
\ flip signs and X+=2 needed by new space station
\ *****************************************************************************

.NwS1                   ; flip signs and X+=2 needed by new space station
{
 LDA INWK,X
 EOR #128               ; flip sg coordinate
 STA INWK,X
 INX
 INX                    ; X+=2
 RTS
}

\ *****************************************************************************
\ Subroutine: ABORT
\
\ draw Missile block, Unarm missile
\ *****************************************************************************

.ABORT                  ; draw Missile block, Unarm missile
{
 LDX #&FF
}

\ *****************************************************************************
\ Subroutine: ABORT2
\
\ missile found a target
\ *****************************************************************************

.ABORT2                 ; Xreg stored as Missile target
{
 STX MSTG               ; missile targeted 12 choices
 LDX NOMSL              ; number of missiles
 JSR MSBAR              ; draw missile bar, returns with Y = 0.
 STY MSAR               ; missiles armed status
 RTS
}

\ *****************************************************************************
\ Subroutine: ECBLB2
\
\ set ECM bulb
\ *****************************************************************************

.ECBLB2                 ; set ECM bulb
{
 LDA #32
 STA ECMA               ; ECM on
 ASL A                  ; #64
 JSR NOISE
}

\ *****************************************************************************
\ Subroutine: ECBLB
\
\ ECM bulb switch
\ *****************************************************************************

.ECBLB                  ; ECM bulb switch
{
 LDA #7*8               ; SC lo for E on left of row
 LDX #LO(ECBT)
 LDY #HI(ECBT)
 BNE BULB-2             ; guaranteed, but assume same Y page
}

\ *****************************************************************************
\ Subroutine: SPBLB
\
\ Space Station bulb
\ *****************************************************************************

.SPBLB                  ; Space Station bulb
{
 LDA #24*8              ; Screen lo destination SC on right of row
 LDX #LO(SPBT)          ; font source
}

\ *****************************************************************************
\ Subroutine: BULB-2
\
\ Bulb
\ *****************************************************************************

{
 LDY #HI(SPBT)
}

\ *****************************************************************************
\ Subroutine: BULB
\
\ Bulb
\ *****************************************************************************

.BULB
{
 STA SC                 ; screen lo
 STX P+1                ; font pointer lo
 STY P+2                ; font pointer hi
 LDA #&7D               ; screen hi SC+1 destination (SC) = &7DC0
 JMP RREN               ; Acc has screen hi for 8 bytes from (P+1)
}

\ *****************************************************************************
\ Variable: ECBT
\
\ 'E' displayed in lower console.
\ *****************************************************************************

.ECBT
{
 EQUW &E0E0             ; 'E' displayed in lower console
 EQUB &80
}

\ *****************************************************************************
\ Variable: SPBT
\
\ 'S' displayed in lower console.
\ *****************************************************************************

.SPBT                   ; make sure same page !
{
 EQUD &E080E0E0         ; 'S' displayed in lower console
 EQUD &E0E020E0
}

\ *****************************************************************************
\ Subroutine: MSBAR
\
\ draw Missile bar. X is number of missiles. Y is strip design.
\ *****************************************************************************

.MSBAR                  ; draw Missile bar. X is number of missiles. Y is strip design.
{
 TXA                    ; missile i.d.
 ASL A
 ASL A
 ASL A                  ; X*8 move over to missile block of interest
 STA T
 LDA #49                ; far right
 SBC T
 STA SC                 ; screen low byte in console
 LDA #&7E               ; bottom row of visible console
 STA SCH
 TYA                    ; strip mask
 LDY #5                 ; 5 strips

.MBL1                   ; counter Y to build block
 STA (SC),Y
 DEY                    ; next strip
 BNE MBL1               ; loop Y
 RTS
}

\ *****************************************************************************
\ Subroutine: PROJ
\
\ Project K+INWK(x,y)/z to K3,K4 for center to screen
\ *****************************************************************************

.PROJ                   ; Project K+INWK(x,y)/z to K3,K4 for center to screen
{
 LDA INWK               ; xlo
 STA P
 LDA INWK+1             ; xhi
 STA P+1
 LDA INWK+2             ; xsg
 JSR PLS6               ; Klo.Xhi = P.A/INWK_z, C set if big
 BCS PL2-1              ; rts as x big
 LDA K
 ADC #X                 ; add xcenter
 STA K3
 TXA                    ; xhi
 ADC #0                 ; K3 is xcenter of planet
 STA K3+1

 LDA INWK+3             ; ylo
 STA P
 LDA INWK+4             ; yhi
 STA P+1
 LDA INWK+5             ; ysg
 EOR #128               ; flip yscreen
 JSR PLS6               ; Klo.Xhi = P.A/INWK_z, C set if big
 BCS PL2-1              ; rts as y big
 LDA K
 ADC #Y                 ; #Y for add ycenter
 STA K4
 TXA                    ; y hi
 ADC #0                 ; K4 is ycenter of planet
 STA K4+1
 CLC                    ; carry clear is center is on screen
 RTS                    ; PL2-1
}

\ *****************************************************************************
\ Subroutine: PL2
\
\ Wipe planet/sun
\ *****************************************************************************

.PL2                    ; planet/sun behind
{
 LDA TYPE               ; ship type
 LSR A                  ; bit0
 BCS P%+5               ; sun has bit0 set
 JMP WPLS2              ; bit0 clear Wipe Planet
 JMP WPLS               ; Wipe Sun
}

\ *****************************************************************************
\ Subroutine: PLANET
\
\ Planet or Sun type to screen
\ *****************************************************************************

.PLANET                 ; Planet or Sun type to screen
{
 LDA INWK+8             ; zsg if behind
 BMI PL2                ; wipe planet/sun
 CMP #48                ; very far away?
 BCS PL2                ; wipe planet/sun
 ORA INWK+7             ; zhi
 BEQ PL2                ; else too close, wipe planet/sun
 JSR PROJ               ; Project K+INWK(x,y)/z to K3,K4 for center to screen
 BCS PL2                ; if center large offset wipe planet/sun

 LDA #96                ; default radius hi
 STA P+1
 LDA #0                 ; radius lo
 STA P
 JSR DVID3B2            ; divide 3bytes by 2, K = P(2).A/INWK_z
 LDA K+1                ; radius hi
 BEQ PL82               ; radius hi fits
 LDA #&F8               ; else too big
 STA K                  ; radius

.PL82                   ; radius fits
 LDA TYPE               ; ship type
 LSR A                  ; sun has bit0 set
 BCC PL9                ; planet radius K
 JMP SUN                ; else Sun #&81 #&83 .. with radius Ks

.PL9                    ; Planet radius K
 JSR WPLS2              ; wipe planet
 JSR CIRCLE             ; for planet
 BCS PL20               ; rts, else circle done
 LDA K+1
 BEQ PL25               ; planet on screen

.PL20
 RTS

.PL25                   ; Planet on screen
 LDA TYPE               ; ship type
 CMP #&80               ; Lave 2-rings is #&80
 BNE PL26               ; Other planet #&82 is crater
 LDA K
 CMP #6                 ; very small radius ?
 BCC PL20               ; rts
 LDA INWK+14            ; rotmat0z hi. Start first  meridian
 EOR #128               ; flipped rotmat0z hi
 STA P                  ; meridian width
 LDA INWK+20            ; rotmat1z hi, for meridian1
 JSR PLS4               ; CNT2 = angle of P_opp/A_adj for Lave
 LDX #9                 ; rotmat0.x for both meridians
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2                 ; mag  0.x   used in final x of arc
 STY XX16               ; sign 0.x
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2+1               ; mag  0.y   used in final y of arc
 STY XX16+1             ; sign 0.y
 LDX #15                ; rotmat1.x for first meridian
 JSR PLS5               ; mag K2+2,3 sign XX16+2,3 = NWK(X+=2)/INWK_z

 JSR PLS2               ; Lave half ring, phase offset CNT2.
 LDA INWK+14            ; rotmat0z hi. Start second meridian
 EOR #128               ; flipped rotmat0z hi
 STA P                  ; meridian width again
 LDA INWK+26            ; rotmat2z hi, for meridian2 at 90 degrees.
 JSR PLS4               ; CNT2 = angle of P_opp/A_adj for Lave

 LDX #21                ; rotmat2.x for second meridian
 JSR PLS5               ; mag K2+2,3 sign XX16+2,3 = NWK(X+=2)/INWK_z
 JMP PLS2               ; Lave half ring, phase offset CNT2.

.PL26                   ; crtr \ their comment \ Other planet e.g. #&82 has One crater.
 LDA INWK+20            ; rotmat1z hi
 BMI PL20               ; rts, crater on far side

 LDX #15                ; rotmat1.x (same as meridian1)
 JSR PLS3               ; A.Y = 222* INWK(X+=2)/INWK_z. 222 is xoffset of crater
 CLC                    ; add xorg lo
 ADC K3
 STA K3
 TYA                    ; xoffset hi of crater center updated
 ADC K3+1
 STA K3+1
 JSR PLS3               ; A.Y = 222* INWK(X+=2)/INWK_z. 222 is yoffset of crater
 STA P
 LDA K4
 SEC                    ; sub Plo from yorg lo
 SBC P
 STA K4
 STY P                  ; yoffset hi temp
 LDA K4+1               ; yorg hi
 SBC P                  ; yoffset hi temp
 STA K4+1               ; y of crater center updated

 LDX #9                 ; rotmat0.x  (same as both meridians)
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final x of ring
 STA K2                 ; mag 0.x/2
 STY XX16               ; sign 0.x
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final y of ring
 STA K2+1               ; mag 0.y/2
 STY XX16+1             ; sign 0.y

 LDX #21                ; rotmat2.x (same as second meridian)
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final x of ring
 STA K2+2               ; mag 2.x/2
 STY XX16+2             ; sign 2.x
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final y of ring
 STA K2+3               ; mag 2.y/2
 STY XX16+3             ; sign 2.y

 LDA #64                ; full circle
 STA TGT                ; count target
 LDA #0                 ; no phase offset for crater ring
 STA CNT2
 JMP PLS22              ; guaranteed crater with TGT = #64
}

\ *****************************************************************************
\ Subroutine: PLS1
\
\ X = 9 etc. A.Y = INWK(X+=2)/INWK_z
\ *****************************************************************************

.PLS1                   ; X = 9 etc. A.Y = INWK(X+=2)/INWK_z
{
 LDA INWK,X
 STA P
 LDA INWK+1,X
 AND #127               ; 7bits of hi
 STA P+1
 LDA INWK+1,X           ; again, get sign for 3rd byte
 AND #128               ; sign only

 JSR DVID3B2            ; divide 3bytes by 2, K = P(2).A/INWK_z
 LDA K                  ; lo
 LDY K+1                ; hi
 BEQ P%+4
 LDA #&FE               ; else sat Acc and keep Y = K+1 non-zero
 LDY K+3                ; sign
 INX                    ; X+=2
 INX
 RTS
}

\ *****************************************************************************
\ Subroutine: PLS2
\
\ Lave half ring, mags K2+0to3, signs XX16+0to3, xy(0)xy(1), phase offset CNT2
\ *****************************************************************************

.PLS2                   ; Lave half ring, mags K2+0to3, signs XX16+0to3, xy(0)xy(1), phase offset CNT2
{
 LDA #31                ; half-circle
 STA TGT                ; count target
}

\ *****************************************************************************
\ Subroutine: PLS22
\
\ Also crater with TGT = #64
\ *****************************************************************************

.PLS22                  ; also crater with TGT = #64
{
 LDX #0
 STX CNT                ; count
 DEX                    ; X = #&FF
 STX FLAG

.PLL4                   ; counter CNT+= STP > TGT planet ring
 LDA CNT2               ; for arc
 AND #31                ; angle index
 TAX                    ; sine table
 LDA SNE,X
 STA Q                  ; sine
 LDA K2+2               ; mag x1
 JSR FMLTU              ; A=A*Q/256unsg
 STA R                  ; part2 lo x = mag x1 * sin
 LDA K2+3               ; mag y1
 JSR FMLTU              ; A=A*Q/256unsg
 STA K                  ; part2 lo y =  mag y1 * sin
 LDX CNT2
 CPX #33                ; for arc
 LDA #0                 ; any sign
 ROR A                  ; into 7th bit
 STA XX16+5             ; ysign

 LDA CNT2
 CLC                    ; for arc
 ADC #16                ; cosine
 AND #31                ; index
 TAX                    ; sinetable
 LDA SNE,X
 STA Q                  ; cosine
 LDA K2+1               ; mag y0
 JSR FMLTU              ; A=A*Q/256unsg
 STA K+2                ; part1 lo y = mag y0 * cos
 LDA K2                 ; mag x0
 JSR FMLTU              ; A=A*Q/256unsg
 STA P                  ; part1 lo x  = mag x0 * cos
 LDA CNT2
 ADC #15                ; for arc
 AND #63                ; 63 max
 CMP #33                ; > 32 ?
 LDA #0                 ; any carry is sign
 ROR A                  ; into 7th bit
 STA XX16+4             ; xsign

 LDA XX16+5             ; ysign
 EOR XX16+2             ; x1 sign
 STA S                  ; S = part2 hi x
 LDA XX16+4             ; xsign
 EOR XX16               ; A = part1 hi x
 JSR ADD                ; lo x = mag x0 * cos + mag x1 * sin
 STA T                  ; sum hi
 BPL PL42               ; hop xplus
 TXA                    ; else minus, sum lo
 EOR #&FF
 CLC
 ADC #1
 TAX                    ; flipped lo
 LDA T                  ; sum hi
 EOR #&7F
 ADC #0
 STA T                  ; flip sum hi and continue

.PL42                   ; hop xplus
 TXA                    ; sum x lo
 ADC K3                 ; xcenter lo
 STA K6                 ; xfinal lo
 LDA T                  ; sum x hi
 ADC K3+1               ; xcenter hi
 STA K6+1               ; xfinal hi

 LDA K                  ; part2 lo y
 STA R                  ; part2 lo y
 LDA XX16+5             ; ysign
 EOR XX16+3             ; y1 sign
 STA S                  ; part2 hi y
 LDA K+2                ; part1 lo y
 STA P                  ; part1 lo y
 LDA XX16+4             ; xsign
 EOR XX16+1             ; A = part1 hi y
 JSR ADD                ; lo y = mag y0 * cos +  mag y1 * sin
 EOR #128               ; flip
 STA T                  ; yfinal hi
 BPL PL43               ; hop yplus
 TXA                    ; else minus, sum lo
 EOR #&FF
 CLC
 ADC #1
 TAX                    ; flipped lo, yfinal lo
 LDA T                  ; yfinal hi
 EOR #&7F
 ADC #0
 STA T                  ; flipped sum hi and continue, yfinal hi

.PL43                   ; hop yplus
 JSR BLINE              ; ball line uses (X.T) as next y offset for arc
 CMP TGT                ; CNT+= STP > TGT
 BEQ P%+4               ; = TGT, next.
 BCS PL40               ; > TGT exit arc rts
 LDA CNT2               ; next, CNT2
 CLC                    ; +step for ring
 ADC STP
 AND #63                ; round
 STA CNT2
 JMP PLL4               ; loop planet ring

.PL40
 RTS                    ; end Crater ring
}

\ *****************************************************************************
\ Subroutine: PLF3-3
\
\ Wipe Sun
\ *****************************************************************************

{
 JMP WPLS               ; Wipe Sun
}

\ *****************************************************************************
\ Subroutine: PLF3
\
\ Flip height for planet/sun fill
\ *****************************************************************************

.PLF3                   ; flip height for planet/sun fill
{
 TXA                    ; Yscreen height lo
 EOR #&FF               ; flip
 CLC
 ADC #1
 TAX                    ; height flipped
}

\ *****************************************************************************
\ Subroutine: PLF17
\
\ up A = #&FF as Xlo =0
\ *****************************************************************************

.PLF17                  ; up A = #&FF as Xlo =0
{
 LDA #&FF               ; fringe flag will run up
 JMP PLF5               ; guaranteed, Xreg = height ready
}

\ *****************************************************************************
\ Subroutine: SUN
\
\ Sun with radius K
\ *****************************************************************************

.SUN                    ; Sun with radius K
{
 LDA #1
 STA LSX                ; overlaps with LSO vector
 JSR CHKON              ; P+1 set to maxY
 BCS PLF3-3             ; jmp wpls Wipe Sun
 LDA #0                 ; fill up Acc bits based on size
 LDX K                  ; radius
 CPX #&60               ; any carry becomes low bit
 ROL A
 CPX #&28               ; 4 if K >= 40
 ROL A
 CPX #&10               ; 2 if K >= 16
 ROL A                  ; extent of fringes set

.PLF18
 STA CNT                ; bits are extent of fringes
 LDA #2*Y-1             ; 2*#Y-1 is Yscreen
 LDX P+2
 BNE PLF2               ; big height
 CMP P+1                ; is Y screen < P+1
 BCC PLF2               ; big height
 LDA P+1                ; now Acc loaded
 BNE PLF2               ; big height
 LDA #1                 ; else Acc=1 is bottom end of Yscreen

.PLF2                   ; big height
 STA TGT                ; top of screen for Y height
 LDA #2*Y-1             ; #2*Y-1 is Yscreen
 SEC                    ; subtract
 SBC K4                 ; Yorg
 TAX                    ; lo Yscreen lo
 LDA #0                 ; hi
 SBC K4+1
 BMI PLF3               ; flip height then ready to run up
 BNE PLF4               ; if Yscreen hi not zero then height is full radius
 INX
 DEX                    ; ysub lo
 BEQ PLF17              ; if ylo = 0 then ready to run up with A = #&FF
 CPX K                  ; Yscreen lo < radius ?
 BCC PLF5               ; if ylo < radius then ready to run down

.PLF4                   ; height is full radius
 LDX K                  ; counter V height is radius
 LDA #0                 ; fringe flag will run down
}

\ *****************************************************************************
\ Subroutine: PLF5
\
\ Xreg = height ready, Acc is flag for run direction
\ *****************************************************************************

.PLF5                   ; Xreg = height ready, Acc is flag for run direction
{
 STX V                  ; counter height
 STA V+1                ; flag 0 (up) or FF (down)

 LDA K
 JSR SQUA2              ; P.A =A*A unsigned
 STA K2+1               ; squared 16-bit radius hi
 LDA P                  ; lo
 STA K2                 ; squared 16-bit stored in K2
 LDY #2*Y-1             ; 2*#Y-1 is Yscreen is counter start
 LDA SUNX
 STA YY                 ; old mid-point of horizontal line
 LDA SUNX+1
 STA YY+1               ; hi

.PLFL2                  ; counter Y down erase top Disc
 CPY TGT                ; Yheight top reached?
 BEQ PLFL               ; exit to Start, Y height = TGT top.
 LDA LSO,Y
 BEQ PLF13              ; if half width zero skip line drawing
 JSR HLOIN2             ; line X1,X2 using YY as mid-point, Acc is half-width

.PLF13                  ; skipped line drawing
 DEY                    ; erase top Disc
 BNE PLFL2              ; loop Y

.PLFL                   ; exited as reached Start. Y = TGT, counter V height. Work out extent.
 LDA V                  ; counter height
 JSR SQUA2              ; P.A =A*A unsigned
 STA T                  ; squared height hi
 LDA K2                 ; squared 16-bit radius lo
 SEC
 SBC P                  ; height squared lo
 STA Q                  ; radius^2-height^2 lo
 LDA K2+1               ; radius^2 hi
 SBC T                  ; height squared hi
 STA R                  ; extent^2 hi
 STY Y1                 ; Y store line height
 JSR LL5                ; SQRT Q = SQR(Q,R) = sqrt(sub)
 LDY Y1                 ; restore line counter
 JSR DORND              ; do random number
 AND CNT                ; trim fringe
 CLC
 ADC Q                  ; new extent
 BCC PLF44              ; not saturated
 LDA #&FF               ; fringe max extent

.PLF44                  ; fringes not saturated
 LDX LSO,Y
 STA LSO,Y
 BEQ PLF11              ; updated extent, if zero No previous old line
 LDA SUNX
 STA YY                 ; Old mid-point of line
 LDA SUNX+1
 STA YY+1               ; hi
 TXA                    ; old lso,y half-width extent
 JSR EDGES              ; horizontal line old extent clip
 LDA X1
 STA XX                 ; old left
 LDA X2
 STA XX+1               ; old right

 LDA K3                 ; Xcenter
 STA YY                 ; new mid-point
 LDA K3+1
 STA YY+1               ; hi
 LDA LSO,Y
 JSR EDGES              ; horizontal line new extent clip
 BCS PLF23              ; No new line
 LDA X2
 LDX XX                 ; old left
 STX X2
 STA XX                 ; swopped old left and new X2 right
 JSR HLOIN              ; horizontal line X1,Y1,X2  Left fringe

.PLF23                  ; also No new line
 LDA XX                 ; old left or new right
 STA X1
 LDA XX+1               ; old right
 STA X2

.PLF16                  ; Draw New line, also from PLF11
 JSR HLOIN              ; horizontal line X1,Y1,X2  Whole old, or new Right fringe.

.PLF6                   ; tail Next line
 DEY                    ; next height Y
 BEQ PLF8               ; Exit Sun fill
 LDA V+1                ; if flag already set
 BNE PLF10              ; take height counter V back up to radius K
 DEC V                  ; else counter height down
 BNE PLFL               ; loop V, Work out extent
 DEC V+1                ; finished down, set flag to go other way.

.PLFLS                  ; loop back to Work out extent
 JMP PLFL               ; loop V back, Work out extent.

.PLF11                  ; No previous old line at Y1 screen
 LDX K3                 ; Xcenter
 STX YY                 ; new mid-point
 LDX K3+1
 STX YY+1               ; hi
 JSR EDGES              ; horizontal line X1,Y1,X2
 BCC PLF16              ; Draw New line, up.
 LDA #0                 ; else no line at height Y
 STA LSO,Y
 BEQ PLF6               ; guaranteed, tail Next line up

.PLF10                  ; V flag set to take height back up to radius K
 LDX V                  ; counter height
 INX                    ; next
 STX V
 CPX K                  ; if height < radius
 BCC PLFLS              ; loop V, Work out extent
 BEQ PLFLS              ; if height = radius, loop V, Work out extent
 LDA SUNX
 STA YY                 ; Onto remaining erase. Old mid-point of line
 LDA SUNX+1
 STA YY+1               ; hi

.PLFL3                  ; rest of counter Y screen line
 LDA LSO,Y
 BEQ PLF9               ; no fringe, skip draw line
 JSR HLOIN2             ; line X1,X2 using YY as mid-point, Acc is half-width

.PLF9                   ; skipped erase line
 DEY                    ; rest of screen
 BNE PLFL3              ; loop Y erase bottom Disc

.PLF8                   ; Exit Planet fill
 CLC                    ; update mid-point of line
 LDA K3
 STA SUNX
 LDA K3+1
 STA SUNX+1
}

\ *****************************************************************************
\ Subroutine: RTS2
\
\ RTS
\ *****************************************************************************

.RTS2
{
 RTS                    ; End of Sun fill
}

\ *****************************************************************************
\ Subroutine: CIRCLE
\
\ Circle for planet
\ *****************************************************************************

.CIRCLE                 ; Circle for planet
{
 JSR CHKON              ; P+1 set to maxY
 BCS RTS2               ; rts

 LDA #0
 STA LSX2

 LDX K                  ; radius
 LDA #8                 ; set up STP size based on radius
 CPX #8                 ; is radius X < 8 ?
 BCC PL89               ; small
 LSR A                  ; STP #4
 CPX #60
 BCC PL89               ; small
 LSR A                  ; bigger circles get smaller step

.PL89                   ; small
 STA STP                ; step for ring
}

\ *****************************************************************************
\ Subroutine: CIRCLE2
\
\ also on chart at origin (K3,K4) STP already set
\ *****************************************************************************

.CIRCLE2                ; also on chart at origin (K3,K4) STP already set
{
 LDX #&FF
 STX FLAG
 INX                    ; X = 0
 STX CNT

.PLL3                   ; counter CNT  until = 64
 LDA CNT
 JSR FMLTU2             ; Get K*sin(CNT) in Acc
 LDX #0                 ; hi
 STX T
 LDX CNT                ; the count around the circle
 CPX #33                ; <= #32 ?
 BCC PL37               ; right-half of circle
 EOR #&FF               ; else Xreg = A lo flipped
 ADC #0
 TAX                    ; lo
 LDA #&FF               ; hi flipped
 ADC #0                 ; any carry
 STA T
 TXA                    ; lo flipped, later moved into K6(0,1) for BLINE x offset
 CLC

.PL37                   ; right-half of circle, Acc = xlo
 ADC K3                 ; Xorg
 STA K6                 ; K3(0) + Acc  = lsb of X for bline
 LDA K3+1               ; hi
 ADC T                  ; hi
 STA K6+1               ; K3(1) + T + C = hsb of X for bline

 LDA CNT
 CLC                    ; onto Y
 ADC #16                ; Go ahead a quarter of a quadrant for cosine index
 JSR FMLTU2             ; Get K*sin(CNT) into A
 TAX                    ; y lo =  K*sin(CNT)
 LDA #0                 ; y hi = 0
 STA T
 LDA CNT
 ADC #15                ; count +=15
 AND #63                ; round within 64
 CMP #33                ; <= 32 ?
 BCC PL38               ; if true skip y flip
 TXA                    ; Ylo
 EOR #&FF               ; flip
 ADC #0
 TAX                    ; Ylo flipped
 LDA #&FF               ; hi flipped
 ADC #0                 ; any carry
 STA T
 CLC

.PL38                   ; skipped Y flip
 JSR BLINE              ; ball line uses (X.T) as next y
 CMP #65                ; > #64?
 BCS P%+5               ; hop to exit
 JMP PLL3               ; loop CNT back
 CLC
 RTS                    ; End Circle
}

\ *****************************************************************************
\ Subroutine: WPLS2
\
\ Wipe Planet
\ *****************************************************************************

.WPLS2                  ; Wipe Planet
{
 LDY LSX2               ; 78 bytes used by bline Xcoords
 BNE WP1                ; Avoid lines down

.WPL1                   ; counter Y starts at 0
 CPY LSP
 BCS WP1                ; arc step reached, exit to Avoid lines.
 LDA LSY2,Y             ; buffer Ycoords
 CMP #&FF               ; flag
 BEQ WP2                ; move into X1,Y1
 STA Y2                 ; else move into X2,Y2
 LDA LSX2,Y             ; buffer Xcoords
 STA X2
 JSR LOIN               ; draw line using (X1,Y1), (X2,Y2)
 INY                    ; next vertex
 LDA SWAP
 BNE WPL1               ; loop Y through buffer

 LDA X2                 ; else swap (X2,Y2) -> (X1,Y1)
 STA X1
 LDA Y2
 STA Y1
 JMP WPL1               ; loop Y through buffer

.WP2                    ; flagged move into X1,Y1
 INY                    ; next vertex
 LDA LSX2,Y
 STA X1
 LDA LSY2,Y
 STA Y1
 INY                    ; next vertex
 JMP WPL1               ; loop Y through buffer

.WP1                    ; Avoid lines, used by wipe planet code
 LDA #1
 STA LSP                ; arc step
 LDA #&FF
 STA LSX2
 RTS                    ; WPLS-1
}

\ *****************************************************************************
\ Subroutine: WPLS
\
\ Wipe Sun
\ *****************************************************************************

.WPLS                   ; Wipe Sun
{
 LDA LSX                ; LSO
 BMI WPLS-1             ; rts
 LDA SUNX
 STA YY                 ; mid-point of line lo
 LDA SUNX+1
 STA YY+1               ; hi
 LDY #2*Y-1             ; #2*Y-1 = Yscreen top

.WPL2                   ; counter Y
 LDA LSO,Y
 BEQ P%+5               ; skip hline2
 JSR HLOIN2             ; line using YY as mid-point, A is half-width.
 DEY
 BNE WPL2               ; loop Y
 DEY                    ; Yreg = #&FF, solar empty.
 STY LSX                ; LSO
 RTS
}

\ *****************************************************************************
\ Subroutine: EDGES
\
\ Clip Horizontal line centered on YY to X1 X2
\ *****************************************************************************

.EDGES                  ; Clip Horizontal line centered on YY to X1 X2
{
 STA T
 CLC                    ; trial halfwidth
 ADC YY                 ; add center of line X mid-point
 STA X2                 ; right
 LDA YY+1               ; hi
 ADC #0                 ; any carry
 BMI ED1                ; right overflow
 BEQ P%+6               ; no hsb present, hop to LDA YY
 LDA #254               ; else saturate right
 STA X2

 LDA YY                 ; center of line X mid-point
 SEC                    ; subtract trial halfwidth
 SBC T
 STA X1                 ; left
 LDA YY+1               ; hi
 SBC #0                 ; any carry
 BNE ED3                ; left underflow
 CLC                    ; else, ok draw line
 RTS                    ; X1 and X2 now known

.ED3                    ; left underflow
 BPL ED1                ; X1 left under flow, dont draw.
 LDA #2                 ; else saturate left
 STA X1
 CLC                    ; ok draw line
 RTS

.ED1                    ; right overflow, also left dont draw
 LDA #0                 ; clear line buffer solar
 STA LSO,Y
 SEC                    ; dont draw
 RTS                    ; end of Clipped edges
}

\ *****************************************************************************
\ Subroutine: CHKON
\
\ Check extent of circles, P+1 set to maxY, Y protected.
\ *****************************************************************************

.CHKON                  ; check extent of circles, P+1 set to maxY, Y protected.
{
 LDA K3                 ; Xorg
 CLC
 ADC K                  ; radius
 LDA K3+1               ; hi
 ADC #0
 BMI PL21               ; overflow to right, sec rts
 LDA K3                 ; Xorg
 SEC
 SBC K                  ; radius
 LDA K3+1               ; hi
 SBC #0
 BMI PL31               ; Xrange ok
 BNE PL21               ; underflow to left, sec rts

.PL31                   ; Xrange ok
 LDA K4                 ; Yorg
 CLC
 ADC K                  ; radius
 STA P+1                ; maxY = Yorg+radius
 LDA K4+1               ; hi
 ADC #0
 BMI PL21               ; overflow top, sec rts
 STA P+2                ; maxY hi
 LDA K4                 ; Yorg
 SEC
 SBC K                  ; radius
 TAX                    ; bottom lo
 LDA K4+1               ; hi
 SBC #0
 BMI PL44               ; ok to draw, clc
 BNE PL21               ; bottom underflowed, sec rts
 CPX #2*Y-1             ; #2*Y-1, bottom Ylo >= screen Ytop?
 RTS
}

\ *****************************************************************************
\ Subroutine: PL21
\
\ dont draw
\ *****************************************************************************

.PL21                   ; dont draw
{
 SEC
 RTS
}

\ *****************************************************************************
\ Subroutine: PLS3
\
\ Only Crater uses this, A.Y = 222* INWK(X+=2)/INWK_z
\ *****************************************************************************

.PLS3                   ; only Crater uses this, A.Y = 222* INWK(X+=2)/INWK_z
{
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA P
 LDA #222               ; offset to crater, divide/256 * unit to offset crater center
 STA Q
 STX U                  ; store index
 JSR MULTU              ; P.A = P*Q = 222* INWK(X+=2)/INWK_z
 LDX U                  ; restore index
 LDY K+3                ; sign
 BPL PL12               ; +ve
 EOR #&FF               ; else flip A hi
 CLC
 ADC #1
 BEQ PL12               ; +ve
 LDY #&FF               ; else A flipped
 RTS

.PL12                   ; +ve
 LDY #0
 RTS
}

\ *****************************************************************************
\ Subroutine: PLS4
\
\ CNT2 = angle of P_opp/A_adj for Lave
\ *****************************************************************************

.PLS4                   ; CNT2 = angle of P_opp/A_adj for Lave
{
 STA Q
 JSR ARCTAN             ; A=arctan (P/Q)
 LDX INWK+14            ; rotmat0z hi
 BMI P%+4               ; -ve rotmat0z hi keeps arctan +ve
 EOR #128               ; else arctan -ve
 LSR A
 LSR A                  ; /4
 STA CNT2               ; phase offset
 RTS
}

\ *****************************************************************************
\ Subroutine: PLS5
\
\ Mag K2+2,3 sign XX16+2,3  = NWK(X+=2)/INWK_z for Lave
\ *****************************************************************************

.PLS5                   ; mag K2+2,3 sign XX16+2,3  = NWK(X+=2)/INWK_z for Lave
{
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2+2               ; mag
 STY XX16+2             ; sign
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2+3               ; mag
 STY XX16+3             ; sign
 RTS
}

\ *****************************************************************************
\ Subroutine: PLS6
\
\ Visited from PROJ \ Klo.Xhi = P.A/INWK_z, C set if big
\ *****************************************************************************

.PLS6                   ; visited from PROJ \ Klo.Xhi = P.A/INWK_z, C set if big
{
 JSR DVID3B2            ; divide 3bytes by 2, K = P(2).A/INWK_z
 LDA K+3
 AND #127               ; sg 7bits
 ORA K+2
 BNE PL21               ; sec rts as too far off
 LDX K+1
 CPX #4                 ; hi >= 4 ? ie >= 1024
 BCS PL6                ; rts as too far off
 LDA K+3                ; sign
\CLC
 BPL PL6                ; rts C clear ok
 LDA K                  ; else flip K lo
 EOR #&FF
 ADC #1                 ; flipped lo
 STA K
 TXA                    ; K+1
 EOR #&FF               ; flip hi
 ADC #0
 TAX                    ; X = K+1 hi flipped
}

\ *****************************************************************************
\ Subroutine: PL44
\
\ ok to draw
\ *****************************************************************************

.PL44                   ; ok to draw
{
 CLC
}

\ *****************************************************************************
\ Subroutine: PL6
\
\ End of Planet, onto keyboard block E ---
\ *****************************************************************************

.PL6
{
 RTS                    ; end of Planet, onto keyboard block E ---
}

\ *****************************************************************************
\ Subroutine: TT17
\
\ Returns with X,Y from arrow keys or joystick used
\ *****************************************************************************

.TT17                   ; returns with X,Y from arrow keys or joystick used
{
 JSR DOKEY              ; KL has force key
 LDA JSTK               ; or joystick used
 BEQ TJ1                ; hop down, Arrows from keyboard, else joystick
 LDA JSTX
 EOR #&FF               ; flip sign
 JSR TJS1               ; Yreg = -2 to +2 for -JSTX
 TYA                    ; Acc  = -2 to +2 for -JSTX
 TAX                    ; Xreg = -2 to +2 for -JSTX

 LDA JSTY

.TJS1                   ; Acc scaled to -2 to +2 for 0 to FF
 TAY                    ; JST X Y
 LDA #0
 CPY #&10               ; set C if Y>= #&10
 SBC #0
\CPY #&20
\SBC #0
 CPY #&40
 SBC #0
 CPY #&C0
 ADC #0
 CPY #&E0
 ADC #0
\CPY #&F0
\ADC #0
 TAY                    ; Yreg = -2 to +2
 LDA KL                 ; Acc = keyboard logger
 RTS

.TJ1                    ; Arrows from keyboard
 LDA KL                 ; keyboard logger
 LDX #0
 LDY #0
 CMP #&19               ; left cursor
 BNE P%+3               ; skip dex
 DEX
 CMP #&79               ; right cursor
 BNE P%+3               ; skip inx
 INX
 CMP #&39               ; up cursor
 BNE P%+3               ; skip iny
 INY
 CMP #&29               ; down cursor
 BNE P%+3               ; skip dey
 DEY
 RTS                    ; no shift boost in Flight code
}

\ *****************************************************************************
\ Subroutine: ping
\
\ Set the target system to the current system.
\ *****************************************************************************

.ping
{
 LDX #1                 ; We want to copy the X- and Y-coordinates of the
                        ; current system in (QQ0, QQ1) to the target system's
                        ; coordinates in (QQ9, QQ10), so set up a counter to
                        ; copy two bytes

.pl1
 LDA QQ0,X              ; Load byte X from the current system in QQ0/QQ1

 STA QQ9,X              ; Store byte X in the target system in QQ9/QQ10
 
 DEX                    ; Decrement the loop counter

 BPL pl1                ; Loop back for the next byte to copy

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Save output/ELTE.bin
\ *****************************************************************************

PRINT "ELITE E"
PRINT "Assembled at ", ~CODE_E%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_E%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_E%

PRINT "S.ELTE ", ~CODE_E%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_E%
SAVE "output/ELTE.bin", CODE_E%, P%, LOAD%

\ *****************************************************************************
\ ELITE F
\ *****************************************************************************

CODE_F% = P%
LOAD_F% = LOAD% + P% - CODE%

\ *****************************************************************************
\ Subroutine: KS3
\
\ exit as end found, temp P correct.
\ *****************************************************************************

.KS3                    ; exit as end found, temp P correct.
{
 LDA P                  ; temp pointer lo
 STA SLSP               ; last ship lines stack pointer
 LDA P+1                ; temp pointer hi
 STA SLSP+1
 RTS
}

\ *****************************************************************************
\ Subroutine: KS1
\
\ Kill ships from Block A loop Enters here
\ *****************************************************************************

.KS1                    ; Kill ships from Block A loop Enters here
{
 LDX XSAV               ; nearby ship index
 JSR KILLSHP            ; Kill target X, down.
 LDX XSAV               ; reload ship index
 JMP MAL1               ; rejoin loop in Block A
}

\ *****************************************************************************
\ Subroutine: KS4
\
\ Removing Space Station to make new Sun
\ *****************************************************************************

.KS4                    ; removing Space Station to make new Sun
{
 JSR ZINF               ; zero info, ends with A = #&C0.
 JSR FLFLLS             ; ends with A=0
 STA FRIN+1             ; #SST slot emptied
 STA SSPR               ; space station present, 0 is SUN.
 JSR SPBLB              ; erase space station bulb 'S' symbol
 LDA #6                 ; sun location up in the sky
 STA INWK+5             ; ysg
 LDA #&81               ; new Sun
 JMP NWSHP              ; new ship type Acc
}

\ *****************************************************************************
\ Subroutine: KS2
\
\ frin shuffled, update Missiles
\ *****************************************************************************

.KS2                    ; frin shuffled, update Missiles
{
 LDX #&FF

.KSL4                   ; counter X
 INX                    ; starts at X=0
 LDA FRIN,X             ; nearby ship types
 BEQ KS3                ; exit as end found, up temp P correct.
 CMP #MSL               ; else this slot is a missile?
 BNE KSL4               ; not missile, loop X
 TXA                    ; else, missile
 ASL A                  ; slot*2
 TAY                    ; build index Y into
 LDA UNIV,Y
 STA SC                 ; missile info lo
 LDA UNIV+1,Y
 STA SC+1               ; missile info hi

 LDY #32                ; info byte#32 is ai_attack_univ_ecm
 LDA (SC),Y
 BPL KSL4               ; ai dumb, loop X
 AND #&7F               ; else, drop ai active bit
 LSR A                  ; bit6, attack you, can be ignored here
 CMP XX4                ; kill target id
 BCC KSL4               ; loop if missile doesn't have target XX4
 BEQ KS6                ; else found missile X with kill target XX4
 SBC #1                 ; else update target -=1
 ASL A                  ; update missile ai
 ORA #128               ; set bit7, ai is active.
 STA (SC),Y
 BNE KSL4               ; guaranteed loop X

.KS6                    ; found missile X with kill target XX4
 LDA #0                 ; missile dumb, no attack target.
 STA (SC),Y
 BEQ KSL4               ; guaranteed loop X
}

\ *****************************************************************************
\ Subroutine: KILLSHP
\
\ Kill target X Entry
\ *****************************************************************************

.KILLSHP                ; Kill target X Entry
{
 STX XX4                ; store kill target slot id
\CPX MSTG
 LDA MSTG               ; NOT IN ELITEF.TXT but is in ELITE SOURCE IMAGE
 CMP XX4                ; was targeted by player's missile? NOT IN ELITEF.TXT but is in ELITE SOURCE IMAGE
 BNE KS5                ; dstar, else no target for player's missile
 LDY #&EE               ; colour strip green for missile block
 JSR ABORT              ; draw missile block
 LDA #200               ; token = target lost
 JSR MESS               ; message and rejoin

.KS5                    ; dstar
 LDY XX4                ; kill target slot id
 LDX FRIN,Y             ; target ship type
 CPX #SST               ; #SST space station?
 BEQ KS4                ; removing Space Station, up
 DEC MANY,X             ; remove from sums of each type 
 LDX XX4                ; reload kill target id, lost type.

 LDY #5                 ; target Hull byte#5 maxlines
 LDA (XX0),Y
 LDY #33                ; info byte#33 is XX19, the ship heap pointer lo
 CLC                    ; unwind lines pointer
 ADC (INF),Y
 STA P                  ; new pointer lo
 INY                    ; info byte#34 is XX19 hi
 LDA (INF),Y
 ADC #0                 ; new pointer hi 
 STA P+1

.KSL1                   ; counter X shuffle higher ships down
 INX                    ; above target id
 LDA FRIN,X             ; nearby ship types
 STA FRIN-1,X           ; down one
 BEQ KS2                ; else exit as frin shuffled, update Missiles up
 ASL A                  ; build index
 TAY                    ; for hull type
 LDA XX21-2,Y
 STA SC                 ; hull data lo
 LDA XX21-1,Y
 STA SC+1               ; hull data hi
 LDY #5                 ; higher Hull byte#5 maxlines
 LDA (SC),Y
 STA T                  ; maxlines for ship heap after XX4
 LDA P                  ; pointer temp lo
 SEC
 SBC T                  ; maxlines for ship heap after XX4
 STA P                  ; pointer temp lo -= maxlines
 LDA P+1
 SBC #0                 ; any carry
 STA P+1
 TXA                    ; slot above target
 ASL A                  ; build index
 TAY                    ; for ship info
 LDA UNIV,Y
 STA SC                 ; inf pointer of higher ship
 LDA UNIV+1,Y
 STA SC+1               ; hi
 LDY #35                ; NEWB of higher ship
 LDA (SC),Y
 STA (INF),Y
 DEY                    ; info#byte35 = energy
 LDA (SC),Y
 STA K+1                ; heap pointer temp hi
 LDA P+1                ; pointer temp hi - maxlines
 STA (INF),Y            ; new XX19 hi
 DEY                    ; info byte#33 = XX19 ship heap pointer lo
 LDA (SC),Y
 STA K                  ; heap pointer temp lo
 LDA P                  ; pointer temp lo - maxlines
 STA (INF),Y            ; new XX19 lo
 DEY                    ; #32 = rest of inwk, ai downwards.

.KSL2                   ; counter Y
 LDA (SC),Y
 STA (INF),Y
 DEY                    ; next inwk byte
 BPL KSL2               ; loop Y
 LDA SC                 ; pointer for inf in slot above
 STA INF
 LDA SC+1               ; hi
 STA INF+1
 LDY T                  ; maxlines for ship heap after XX4 counter

.KSL3                   ; counter Y
 DEY                    ; move entries
 LDA (K),Y              ; on old heap to
 STA (P),Y              ; new temp heap
 TYA
 BNE KSL3               ; loop Y
 BEQ KSL1               ; guaranteed up, shuffle higher slots remaining
}

\ *****************************************************************************
\ Variable: SFX
\
\ Sound data.
\ *****************************************************************************

.SFX                    ; block F1 Sound data
{
 EQUS  &12,&01,&00,&10  ; FNS("12010010") Laser you fired  Flush2 uses Envelope #1  Acc= 0
 EQUS  &12,&02,&2C,&08  ; FNS("12022C08") Laset hit you    Flush2 uses Envelope #2  Acc= 4
 EQUS  &11,&03,&F0,&18  ; FNS("1103F018") Death_initial    Flush1 uses Envelope #3  Acc= 8
 EQUS  &10,&F1,&07,&1A  ; FNS("10F1071A") Death_later or   Kill Flush07		        Acc=12

 EQUS  &03,&F1,&BC,&01  ; FNS("03F1BC01") Beep, high short NoFlush3		            Acc=16
 EQUS  &13,&F4,&0C,&08  ; FNS("13F40C08") Beep, low long   Flush3		            Acc=20
 EQUS  &10,&F1,&06,&0C  ; FNS("10F1060C") Missile/Launch   Flush06		            Acc=24
 EQUS  &10,&02,&60,&10  ; FNS("10026010") Hyperspace       Flush0 uses Envelope #2  Acc=28
 EQUS  &13,&04,&C2,&FF  ; FNS("1304C2FF") ECM_ON           Flush3 uses Envelope #4  Acc=32
 EQUS  &13,&00,&00,&00  ; FNS("13000000") ECM_OFF				                    Acc=36
}

\ *****************************************************************************
\ Subroutine: RESET
\
\ Reset the player ship and various controls, then fall through into RES4 to
\ restore shields and energy, and reset the stardust and the ship workspace at
\ INWK.
\
\ In this subroutine, this means zero-filling the following locations:
\
\   * Pages &9, &A, &B, &C and &D
\
\   * BETA to BETA+6, which covers the following:
\
\     * BETA, BET1 - Set pitch to 0
\
\     * XC, YC - Set text cursor to (0, 0)
\
\     * QQ22 - Stop hyperspace countdown
\
\     * ECMA - Turn E.C.M. off
\
\ It also sets QQ12 to &FF, to indicate we are docked, and then falls through
\ into RES4.
\ *****************************************************************************

.RESET
{
 JSR ZERO               ; Zero-fill pages &9, &A, &B, &C and &D

 LDX #6                 ; Set up a counter for zeroing BETA through BETA+6

.SAL3
 STA BETA,X             ; Zero the X-th byte after BETA         

 DEX                    ; Decrement the loop counter

 BPL SAL3               ; Loop back for the next byte to zero

 STX QQ12               ; X is now negative - i.e. &FF - so this sets QQ12 to
                        ; &FF to indicate we are docked

                        ; Fall through into RES4 to restore shields and energy,
                        ; and reset the stardust and ship workspace at INWK
}

\ *****************************************************************************
\ Subroutine: RES4
\
\ Reset the shields and energy banks, then fall through into RES2 to reset the
\ stardust and the ship workspace at INWK.
\ *****************************************************************************

.RES4
{
 LDA #&FF               ; Set A to &FF so we can fill up the shields and energy
                        ; bars with a full charge

 LDX #2                 ; The two shields and energy bank levels are stored in
                        ; three consecutive bytes, at FSH through FSH+2, so set
                        ; up a counter in X to index these three bytes

.REL5
 STA FSH,X              ; Set the X-th byte in the FSH block to &FF

 DEX                    ; Decrement the loop counter

 BPL REL5               ; Loop back to do the next byte, until we have done
                        ; all three

                        ; Fall through into RES2 to reset stardust and INWK
}

\ *****************************************************************************
\ Subroutine: RES2
\
\ Reset a number of flight variables and workspaces.
\
\ This is called after we launch from a space station, arrive in a new system
\ after hyperspace, launch an escape pod, or die a cold, lonely death in the
\ depths of space.
\ *****************************************************************************

.RES2
{
 LDA #NOST              ; Reset NOSTM, the number of stardust particles, to the
 STA NOSTM              ; maximum allowed (18)

 LDX #&FF               ; Reset LSX2 and LSY2, the buffers used by the BLINE
 STX LSX2               ; routine for drawing the planet's ball line, to &FF
 STX LSY2

 STX MSTG               ; Reset MSTG, the missile target, to &FF (no target)

 LDA #128               ; Set the current pitch rate to the mid-point, 128
 STA JSTY

 STA ALP2               ; Reset the roll and pitch signs to (&00 &FF)
 STA BET2
 ASL A                  ; This sets A to 0
 STA ALP2+1
 STA BET2+1

 STA MCNT               ; Reset MCNT, the move count, to 0

 LDA #3                 ; Reset DELTA (speed), ALPHA and ALP1 to 3
 STA DELTA
 STA ALPHA
 STA ALP1

 LDA SSPR               ; Fetch the "space station present" flag, and if we are
 BEQ P%+5               ; not inside the safe zone, skip the next instruction

 JSR SPBLB              ; Light up the space station bulb on the dashboard

 LDA ECMA               ; Fetch the E.C.M. status flag, and if E.C.M. is off,
 BEQ yu                 ; skip the next instruction

 JSR ECMOF              ; Turn off the E.C.M. sound

.yu
 JSR WPSHPS             ; Wipe all ships from the scanner

 JSR ZERO               ; Zero-fill pages &9, &A, &B, &C and &D.

 LDA #LO(WP-1)          ; Reset the ship lines pointer to be empty, so point
 STA SLSP               ; SLSP to the byte before the WP workspace
 LDA #HI(WP-1)
 STA SLSP+1

 JSR DIALS              ; Update the dashboard

                        ; Finally, fall through into ZINF to reset the INWK
                        ; ship workspace
}

\ *****************************************************************************
\ Subroutine: ZINF
\
\ Zero-fill the INWK ship workspace and reset the rotation matrix.
\ *****************************************************************************

.ZINF
{
 LDY #NI%-1             ; There are NI% bytes in the INWK workspace, so set a
                        ; counter in Y so we can loop through them

 LDA #0                 ; Set A to 0 so we can zero-fill the workspace

.ZI1
 STA INWK,Y             ; Zero the Y-th byte of the INWK workspace

 DEY                    ; Decrement the loop counter

 BPL ZI1                ; Loop back for the next byte, ending when we have
                        ; zero-filled the last byte at INWK

                        ; Finally, we reset the rotation matrix to unity,
                        ; as follows:
                        ;
                        ;                   (rotmat0x rotmat0y rotmat0z)
                        ; Rotation matrix = (rotmat1x rotmat1y rotmat1z)
                        ;                   (rotmat2x rotmat2y rotmat2z)
                        ;
                        ;                   (INWK+10,9  INWK+12,11 INWK+14,13)
                        ;                 = (INWK+16,15 INWK+18,17 INWK+20,19)
                        ;                   (INWK+22,21 INWK+24,23 INWK+26,25)
                        ;
                        ;                   (0    0  &E0)   (0  0 -1)
                        ;                 = (0   &60   0) = (0  1  0)
                        ;                   (&60  0    0)   (1  0  0)
                        ;
                        ; &60 represents 1 in the rotation matrix, while &E0
                        ; represents -1
                        ;
                        ; We already set the whole matrix to zero above, so
                        ; we just need to set up the diagonal values and we're
                        ; done.

 LDA #&60               ; Set A to represent a 1 in the matrix

 STA INWK+18            ; Set INWK+18 = rotmat1y_hi = &60 = 1 in the matrix
 STA INWK+22            ; Set INWK+22 = rotmat2x_hi = &60 = 1 in the matrix

 ORA #128               ; Flip the sign of A to represent a -1 in the matrix

 STA INWK+14            ; Set INWK+14 = rotmat0z_hi = &E0 = -1 in the matrix

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: msblob
\
\ Update the dashboard's missile indicators
\ *****************************************************************************

.msblob                 ; update Missile blocks on console
{
 LDX #4                 ; number of missile blocks

.ss                     ; counter X
 CPX NOMSL              ; compare Xreg to number of missiles
 BEQ SAL8               ; remaining missiles are green
 LDY #0                 ; else black bar
 JSR MSBAR              ; draw missile block Xreg
 DEX                    ; next missile
 BNE ss                 ; loop X
 RTS

.SAL8                   ; remaining missiles are green, counter X
 LDY #&EE               ; green
 JSR MSBAR              ; draw missile block Xreg
 DEX                    ; next missile
 BNE SAL8               ; loop X
 RTS
}

\ *****************************************************************************
\ Subroutine: me2
\
\ Erase message from TT100
\ *****************************************************************************

.me2                    ; erase message from TT100
{
 LDA MCH                ; message id
 JSR MESS               ; message
 LDA #0
 STA DLY                ; delay printing = 0
 JMP me3                ; back to TT100
}

\ *****************************************************************************
\ Subroutine: Ze
\
\ Zero ship and set coordinates, ends with dornd.
\ *****************************************************************************

.Ze                     ; Zero ship and set coordinates, ends with dornd.
{
 JSR ZINF               ; zero information
 JSR DORND              ; do random, new A, X.
 STA T1
 AND #128               ; keep bit7 sign
 STA INWK+2             ; xsg left/right
 TXA                    ; Xrnd = old rnd
 AND #128               ; keep bit7 sign
 STA INWK+5             ; ysg up/down
 LDA #32                ; distance away
 STA INWK+1             ; xhi
 STA INWK+4             ; yhi
 STA INWK+7             ; zhi
 TXA
 CMP #245               ; carry set rarely
 ROL A                  ; and goes into bit0, has ecm.
 ORA #&C0               ; set AI active and turn to attack 50% probability
 STA INWK+32            ; ai_attack_univ_ecm
}

\ *****************************************************************************
\ Subroutine: DORND2
\
\ Restricted for explosion dust.
\ *****************************************************************************

.DORND2                 ; Restricted for explosion dust.
{
 CLC                    ; leave bit0 of RAND+2 at 0.
}

\ *****************************************************************************
\ Subroutine: DORND
\
\ Do random, new A, X.
\ *****************************************************************************

.DORND                  ; do random, new A, X.
{
 LDA RAND               ; seed 0
 ROL A
 TAX                    ; double lo
 ADC RAND+2
 STA RAND
 STX RAND+2             ; dornd2 would leave bit0 of RAND+2 at 0.
 LDA RAND+1
 TAX                    ; store hi
 ADC RAND+3             ; bvs will see bit6 set here
 STA RAND+1             ; A rnd
 STX RAND+3             ; Xrnd = old A rnd
 RTS
}

\ *****************************************************************************
\ Subroutine: MTT4
\
\ Spawn freighters
\ *****************************************************************************

.MTT4                   ; Spawn freighters
{
 LSR A                  ; clear bit7, dumb ship, 50% prob has ecm.
 STA INWK+32            ; ai_attack_univ_ecm
 STA INWK+29            ; rotx counter, roll right usually damped
 ROL INWK+31            ; display exploding state|missiles = Arnd
 AND #31                ; max #15
 ORA #16                ; #16 min, #31 max.
 STA INWK+27            ; speed
 LDA #CYL               ; Cobra Mk III
 JSR NWSHP              ; new ship type Acc 
}

\ *****************************************************************************
\ Subroutine: TT100
\
\ Start MAIN LOOP Spawnings
\ *****************************************************************************

.TT100                  ; Start MAIN LOOP Spawnings
{
 JSR M%                 ; M% in Block A has some flight controls
 DEC DLY                ; reduce delay
 BEQ me2                ; if 0 erase messages, up
 BPL me3                ; Spawnings
 INC DLY                ; else undershot, set to 0.
}

\ *****************************************************************************
\ Subroutine: me3
\
\ Spawnings
\ *****************************************************************************

.me3                    ; Spawnings
{
 DEC MCNT               ; move count
 BEQ P%+5               ; rarely do spawning, test misjump

.ytq                    ; jmp mloop, yet to quit.
 JMP MLOOP              ; usually down to clear stack, look at keys, up TT100.
 LDA MJ                 ; mis-jump
 BNE ytq                ; if stuck in witchspace, jmp mloop
 JSR DORND              ; do random, new A, X.
 CMP #35                ; >= usually
 BCS MTT1               ; down 80% of the time
 LDA MANY+AST           ; not ships
 CMP #3                 ; else junk rarely
 BCS MTT1               ; already >= 3 enough junk
 JSR ZINF               ; zero info
 LDA #38                ; coordinates of new junk spawn
 STA INWK+7             ; zhi far away
 JSR DORND              ; do random, new A, X.
 STA INWK               ; xlo Arnd
 STX INWK+3             ; ylo Xrnd
 AND #128               ; bit7 of A rnd
 STA INWK+2             ; xsg left or right
 TXA                    ; old rnd
 AND #128               ; bit7 of X rnd
 STA INWK+5             ; ysg
 ROL INWK+1             ; xhi rnd Carry
 ROL INWK+1             ; xhi not far off center
 JSR DORND              ; do random, new A, X.
 BVS MTT4               ; 50% prob up, Spawn freighters.
 ORA #&6F               ; set bits 6,5 3to0
 STA INWK+29            ; rotx counter, max roll with 50% prob no damping
 LDA SSPR               ; in space station present range? 0 is SUN.
 BNE MTT1               ; down, else rocks exist.
 TXA                    ; X rnd
 BCS MTT2               ; 50% prob no speed max spin
 AND #31                ; speed max 31
 ORA #16                ; min 16 max 31
 STA INWK+27
 BCC MTT3               ; guaranteed, speed done for junk

.MTT2                   ; 50% prob no speed, max spin
 ORA #127               ; max rotation, no damping, only sign clock/anti random.
 STA INWK+30            ; rotz counter pitch

.MTT3                   ; speed done for junk
 JSR DORND              ; do random, new A, X.
 CMP #5                 ; likely carry set 95% of time.
 LDA #AST               ; Asteroid
 BCS P%+4
 LDA #OIL               ; Container
 JSR NWSHP              ; new ship type Acc

.MTT1                   ; 80% of the time or junk >= 3, or in SS range.
 LDA SSPR
 BNE MLOOP              ; main loop if not in deep space
                        ; In deep space
 JSR BAD                ; affected by QQ20(3,6,10), 32 tons of Slaves, Narcotics
 ASL A                  ; boost to possible FIST.
 LDX MANY+COPS          ; number of COPS
 BEQ P%+5               ; if no cops present no change to legal status
 ORA FIST               ; else Fugitative/Innocent status or'd to Acc of BAD
 STA T                  ; new legal
 JSR Ze                 ; Zero for new ship, new inwk coords, ends with dornd and T1 = rnd too.
 CMP T                  ; if rnd >= new legal
 BCS P%+7               ; if mild unlikely to make Cop
 LDA #COPS              ; else make COPS
 JSR NWSHP              ; new ship type Acc
 LDA MANY+COPS          ; number of COPS
 BNE MLOOP              ; jump to main loop if cops now present
 DEC EV                 ; else reduce extra vessels spawning delay
 BPL MLOOP              ; jump to main loop if +ve
 INC EV                 ; else undershot, set extra vessels = 0
 JSR DORND              ; do random, new A, X.
 LDY gov                ; government of present system
 BEQ LABEL_2            ; branch if anarchy
 CMP #90                ; else safer systems
 BCS MLOOP              ; likely to main loop
 AND #7                 ; rnd7
 CMP gov
 BCC MLOOP              ; main loop likely for large governments

.LABEL_2
 JSR Ze                 ; Zero for new ship, new inwk coords, ends with dornd and T1 = rnd too.
 CMP #200               ; Arnd >= 200 ?
 BCS mt1                ; likely Pirates
 INC EV                 ; else extra vessels delayed
 AND #3                 ; rnd3 for bounty hunter
 ADC #3
 TAY                    ; store type hunter
 TXA            
 CMP #200
 ROL A
 ORA #&C0
 CPY #6
 BEQ tha
 STA INWK+32
 TYA
 JSR NWSHP              ; New Ship type Acc

.mj1                    ; main loop jump
 JMP MLOOP              ; Main Loop

.mt1                    ; Pirates
 AND #3                 ; rnd 0to3
 STA EV                 ; extra vessels, delay further spawnings.
 STA XX13               ; pirate counter

.mt3                    ; counter XX13 ships needed
 JSR DORND              ; do random, new A, X.
 AND #3
 ORA #1                 ; Sidewinder or Mamba
 JSR NWSHP              ; New Ship type Acc

 DEC XX13               ; next ship needed
 BPL mt3                ; loop XX13
}

\ *****************************************************************************
\ Subroutine: MLOOP
\
\ MAIN loop ending
\ *****************************************************************************

.MLOOP                  ; MAIN loop ending
{
 LDA #1
 STA SHEILA+&4E
 LDX #&FF               ; Clear Stack
 TXS                    ; to Stack
 LDX GNTMP              ; gun temperature
 BEQ EE20               ; cold laser
 DEC GNTMP

.EE20                   ; cold laser
 JSR DIALS              ; update flight console
 LDA QQ11               ; menu i.d.
 BEQ P%+11              ; if space view skip small delay and visit TT17
 AND PATG               ; PATG = &FF if credits have been enabled
 LSR A                  ; carry loaded?
 BCS P%+5               ; skip delay
 JSR DELAY-5            ; small length of delay counter

 JSR TT17               ; returns with X,Y from arrow keys or joystick used
}

\ *****************************************************************************
\ Subroutine: FRCE
\
\ Join the main game loop with a key already "pressed". This lets us jump into
\ the loop with a specific action to perform, as defined by the value of the
\ fake key press. In practice, this is used when we enter the docking bay in
\ BAY to display Status Mode (red key F8), and when we finish buying or selling
\ cargo in BAY2 to jump to the Inventory (red key F9). This subroutine also
\ forms the end of the main game loop.
\
\ Arguments:
\
\   A           The internal key number of the key we want to "press"
\ *****************************************************************************

.FRCE
{
 JSR TT102              ; Call TT102 to process the keypress in A

 LDA QQ12               ; Fetch the docked flag from QQ12 into A

 BNE MLOOP              ; If we are docked, loop back up to MLOOP just above
                        ; to join the main loop

 JMP TT100              ; Otherwise jump to TT100 to start spawning ships
}

\ *****************************************************************************
\ Subroutine: tha
\
\ ?
\ *****************************************************************************

.tha
{
 JSR DORND
 CMP #200
 BCC P%+5
 JSR GTHG
 JMP MLOOP
}

\ *****************************************************************************
\ Subroutine: TT102
\
\ Switchyard for Red keys
\
\ Arguments:
\
\   A           The internal key number of the key pressed
\ *****************************************************************************

.TT102                  ; Switchyard for Red keys
{
 CMP #f8                ; red key #f8
 BNE P%+5
 JMP STATUS             ; commander
 CMP #f4                ; red key #f4
 BNE P%+5
 JMP TT22               ; Long range galactic chart
 CMP #f5                ; red key #f5
 BNE P%+5
 JMP TT23               ; Short range chart
 CMP #f6                ; red key #f6
 BNE TT92               ; switchyard continue
 JSR TT111              ; closest to QQ9,10
 JMP TT25               ; DATA on system

.TT92                   ; switchyard continue
 CMP #f9                ; red key #f9
 BNE P%+5
 JMP TT213              ; Inventory
 CMP #f7                ; red key #f7
 BNE P%+5
 JMP TT167              ; Market place menu screen
 CMP #f0                ; red key #f0
 BNE fvw                ; forward view not
 JMP TT110              ; else Launch ship decision

.fvw                    ; forward view not
 BIT QQ12
 BPL INSP
 CMP #f3                ; red key #f3
 BNE P%+5
 JMP EQSHP              ; equip ship
 CMP #f1                ; red key #f1
 BNE P%+5
 JMP TT219              ; Buy cargo
                        ; not red key
 CMP #&47               ; key '@'
 BNE P%+5               ; not H else
 JMP SVE                ; Start hyperspace code

 CMP #f2                ; red key #f2
 BNE LABEL_3
 JMP TT208              ; Sell cargo

.INSP
 CMP #&71               ; red key #f1
 BCC LABEL_3
 CMP #&74               ; red key #f5
 BCS LABEL_3
 AND #3
 TAX
 JMP LOOK1              ; Start view X

.LABEL_3
 CMP #&54               ; key 'H'
 BNE P%+5               ; not H else can't hyperspace whilst docked
 JMP hyp                ; hyperspace start, key H hit.
 CMP #&32               ; key 'D'
 BEQ T95                ; Distance to system
 STA T1                 ; protect Acc key
 LDA QQ11
 AND #192               ; short or long range chart
 BEQ TT107              ; no, run Countdown
 LDA QQ22+1             ; hyperspace outer countdown 
 BNE TT107              ; if running, run Countdown
 LDA T1                 ; restore Acc key
 CMP #&36               ; key 'O'
 BNE ee2                ; not O, else recenter cursor
 JSR TT103              ; erase small cross hairs at target hyperspace system
 JSR ping               ; move to home coordinates
 JSR TT103              ; draw small cross hairs at target hyperspace system

.ee2                    ; not O
 JSR TT16               ; Xreg and Yreg values used to shift cross-hairs on charts by

.TT107                  ; run Countdown
 LDA QQ22+1             ; outer hyperspace countdown
 BEQ t95                ; rts
 DEC QQ22               ; inner-countdown
 BNE t95                ; rts
 LDX QQ22+1
 DEX                    ; decrease outer hyperspace countdown
 JSR ee3                ; print hyperspace countdown in X
 LDA #5                 ; reset inner countdown
 STA QQ22               ; inner-countdown
 LDX QQ22+1             ; old outer hyperspace countdown
 JSR ee3                ; erase old hyperspace countdown
 DEC QQ22+1             ; decrease old outer hyperspace countdown
 BNE t95                ; rts
 JMP TT18               ; else HSPC Countdown finished, (try) go through Hyperspace.

.t95                    ; rts
 RTS

.T95                    ; 'D' pressed, Distance to system
 LDA QQ11
 AND #192               ; short or long range chart?
 BEQ t95                ; no, rts
 JSR hm                 ; move hyperspace cross-hairs to QQ9,10 target
                        ; hm always returns with A=0
 STA QQ17               ; All letters Uppercase
 JSR cpl                ; print Planet name for seed QQ15
 LDA #128               ; Only first letter Uppercase
 STA QQ17
 LDA #1                 ; left
 STA XC
 INC YC                 ; next row
 JMP TT146              ; Non-zero distance in Light years
}

\ *****************************************************************************
\ Subroutine: BAD
\
\ Legal status from Cargo scan
\ *****************************************************************************

.BAD                    ; Legal status from Cargo scan
{
 LDA QQ20+3             ; cargo slaves
 CLC
 ADC QQ20+6             ; narcotics
 ASL A                  ; slaves and narcotics penalty doubled
 ADC QQ20+10            ; add firearms
 RTS                    ; FIST = 64 is cop-killer. Same as 32 tons of Slave or Narcotics.
}

\ *****************************************************************************
\ Subroutine: FAROF
\
\ For docking computer, Carry is clear if hi >= #&E0
\ *****************************************************************************

.FAROF                  ; for docking computer, Carry is clear if hi >= #&E0
{
 LDA #&E0               ; distance hi far enough away
}

\ *****************************************************************************
\ Subroutine: FAROF2
\
\ Carry set if Acc >= hi
\ *****************************************************************************

.FAROF2                 ; carry set if Acc >= hi
{
 CMP INWK+1             ; xhi
 BCC MA34               ; rts
 CMP INWK+4             ; yhi
 BCC MA34               ; rts
 CMP INWK+7             ; zhi

.MA34                   ; rts
 RTS
}

\ *****************************************************************************
\ Subroutine: MAS4
\
\ All hi coord or'd
\ *****************************************************************************

.MAS4                   ; All hi coord or'd
{
 ORA INWK+1             ; xhi
 ORA INWK+4             ; yhi
 ORA INWK+7             ; zhi
 RTS
}

\ *****************************************************************************
\ Subroutine: DEATH
\
\ Player killed in Flight
\ *****************************************************************************

.DEATH                  ; Player killed in Flight
{
 JSR EXNO3              ; ominous noises
 JSR RES2               ; reset2
 ASL DELTA              ; speed
 ASL DELTA              ; *=4
 LDX #24                ; 24 text rows
 JSR DET1
 JSR TT66               ; box border with QQ11 menu id set to Acc = 6
 JSR BOX                ; border removed
 JSR nWq                ; new dust
 LDA #12                ; middle
 STA YC
 STA XC
 LDA #146               ; Token = Game Over
 JSR ex                 ; extra tokens

.D1                     ; counter  FRIN+4 empty
 JSR Ze                 ; Zero for new ship, new inwk coords
 LSR A                  ; ends with dornd and T1 = rnd too. /=2
 LSR A                  ; Arnd 63 max
 STA INWK               ; xlo reduced
 LDY #0                 ; set below to 0
 STY QQ11               ; menu id now space view.
 STY INWK+1             ; xhi
 STY INWK+4             ; yhi
 STY INWK+7             ; zhi
 STY INWK+32            ; ai dumb, no ecm.
 DEY                    ; #&FF
 STY MCNT               ; move count
 STY LASCT              ; laser count
 EOR #42                ; flip every other bit below 64 0010 1010
 STA INWK+3             ; ylo
 ORA #80                ; flick away
 STA INWK+6             ; zlo
 TXA                    ; rnd X
 AND #&8F               ; keep sign, but max 15
 STA INWK+29            ; rotx counter roll
 ROR A                  ; might set carry
 AND #&87               ; keep sign, but max 7
 STA INWK+30            ; rotz counter pitch
 PHP
 LDX #OIL               ; Type #OIL cargo default
 JSR fq1                ; type X cargo/alloys in explosion
 PLP
 LDA #0
 ROR A
 LDY #31                ; display explosion state|missiles
 STA (INF),Y            ; Prob 50% to kill
 LDA FRIN+3             ; 4th slot for nearby craft
 BEQ D1                 ; loop next debris
 JSR U%                 ; clear keyboard logger
 STA DELTA              ; speed

.D2                     ; counter LASCT laser count
 JSR M%                 ; M% block A. Some flight controls
 LDA LASCT              ; laser count was reduced in M%
 BNE D2                 ; loop
 LDX #31                ; restore all 31
 JSR DET1               ; text rows
}

\ *****************************************************************************
\ Subroutine: DEATH2
\
\ Reset2, onto Docked code
\ *****************************************************************************

.DEATH2                 ; reset2, onto Docked code.
{
 JSR RES2               ; reset2
}

\ *****************************************************************************
\ Subroutine: TT170
\
\ Exposed labels: BR1
\
\ Entry point for Elite game code. Also called following death or quitting a
\ game (by pressing Escape when paused).
\
\ BRKV is set to point to BR1 by elite-loader.asm.
\ *****************************************************************************

.TT170
{
 LDX #&FF               ; Set stack pointer to &01FF, so stack is in page 1
 TXS                    ; (this is the standard location for the 6502 stack)

.^BR1                   ; BRKV is set to point here by elite-loader.asm

 LDX #3                 ; Set XC = 3 (set text cursor to column 3)
 STX XC

 JSR FX200              ; Disable Escape key and clear memory if Break key is
                        ; pressed (*FX 200, 3)

 LDX #CYL               ; Call the TITLE subroutine to show the rotating ship
 LDA #128               ; and load prompt. The arguments sent to TITLE are:
 JSR TITLE              ; 
                        ;   X = type of ship to show, CYL is Cobra Mk III
                        ;   A = text token to show below the rotating ship, 128
                        ;       is "  LOAD NEW COMMANDER (Y/N)?{crlf}{crlf}"
                        ;
                        ; The TITLE subroutine returns with the internal number
                        ; of the key pressed in A (see p.142 of the Advanced
                        ; User Guide for a list of internal key number)

 CMP #&44               ; Did the player press 'Y'?

 BNE QU5                ; If they didn't press 'Y', jump to QU5

\BR1                    ; These instructions are commented out in the original
\LDX #3                 ; source. This block starts with the same *FX call as
\STX XC                 ; above, then clears the screen, calls a routine to
\JSR FX200              ; flush the keyboard buffer (FLKB) that isn't present
\LDA #1                 ; in the tape version but is in the disk version, and 
\JSR TT66               ; then it displays "LOAD NEW COMMANDER (Y/N)?" and
\JSR FLKB               ; lists the current cargo, before falling straight into
\LDA #14                ; the load routine below, whether or not the player has
\JSR TT214              ; pressed Y. This may be a testing loop for testing the
\BCC QU5                ; cargo aspect of loading commander files.

 JSR GTNME              ; The player wants to load a new commander, so first we
                        ; ask them for the commander name to load

 JSR LOD                ; We then call the LOD subroutine to load the commander
                        ; file to address NA%+8, which is where we store the
                        ; commander save file

 JSR TRNME              ; Once loaded, we copy the commander name to NA%

 JSR TTX66              ; And we clear the top part of the screen and draw a
                        ; box border

.QU5                    ; By the time we get here, the correct commander name
                        ; is at NA% and the correct commander data is at NA%+8.
                        ; Specifically:
                        ;
                        ; If the player loaded a commander file, then the name
                        ; and data from that file will be at NA% and NA%+8.
                        ;
                        ; If this is a brand new game, then NA% will contain
                        ; the default starting commander name ("JAMESON") and
                        ; NA%+8 will contain the default commander data.
                        ;
                        ; If this is not a new game (because they died or quit)
                        ; and the player didn't want to load a commander file,
                        ; then NA% will contain the last saved commander name,
                        ; and NA%+8 the last saved commander data. If the game
                        ; has never been saved, this will still be the default
                        ; commander.

\JSR TTX66              ; This instruction is commented out in the original
                        ; source; it clears the screen and draws a border

 LDX #NT%               ; The size of the commander data block is NT% bytes,
                        ; and it starts at NA%+8, so we need to copy the data
                        ; from the 'last saved' buffer at NA%+8 to the current
                        ; commander workspace at TP. So we set up a counter in X
                        ; for the NT% bytes that we want to copy.

.QUL1
 LDA NA%+7,X            ; Copy the X-th byte of NA%+7 to the X-th byte of TP-1,
 STA TP-1,X             ; (the -1 is because X is counting down from NT% to 1)

 DEX                    ; Decrement the loop counter

 BNE QUL1               ; Loop back for the next byte of the commander file

 STX QQ11               ; X is 0 by the end of the above loop, so this sets QQ11
                        ; to 0, which means we will be showing a view without a
                        ; boxed title at the top (i.e. we're going to use the
                        ; screen layout of a space view in the following)
 
                        ; If the commander check below fails, we keep jumping
                        ; back to here to crash the game with an infinite loop

 JSR CHECK              ; Call the CHECK subroutine to calculate the checksum
                        ; for the current commander block at NA%+8 and put it
                        ; in A

 CMP CHK                ; Test the calculated checksum against CHK

IF _REMOVE_COMMANDER_CHECK

 NOP                    ; If we have disabled the commander check, then ignore
 NOP                    ; the checksum and fall through into the next part

ELSE

 BNE P%-6               ; If commander check is enabled and the calculated
                        ; checksum does not match CHK, then loop back to repeat
                        ; the check - in other words, we enter an infinite loop
                        ; here, as the checksum routine will keep returning the
                        ; same incorrect value

ENDIF

                        ; The checksum CHK is correct, so now we check whether
                        ; CHK2 = CHK EOR A9, and if this check fails, bit 7 of
                        ; the competition code COK gets set, presumably to
                        ; indicate to Acornsoft that there may have been some
                        ; hacking going on with this competition entry

 EOR #&A9               ; X = checksum EOR &A9
 TAX

 LDA COK                ; Set A = competition code in COK

 CPX CHK2               ; If X = CHK2, then skip the next instruction
 BEQ tZ

 ORA #128               ; Set bit 7 of A

.tZ
 ORA #2                 ; Set bit 1 of A

 STA COK                ; Store the competition code A in COK

 JSR msblob             ; Update the dashboard's missile indicators

 LDA #147               ; Call the TITLE subroutine to show the rotating ship
 LDX #MAM               ; and fire/space prompt. The arguments sent to TITLE
 JSR TITLE              ; are:
                        ; 
                        ;   X = type of ship to show, MAM is Mamba
                        ;   A = text token to show below the rotating ship, 147
                        ;       is "PRESS FIRE OR SPACE,COMMANDER.{crlf}{crlf}"
 
 JSR ping               ; Set the target system coordinates (QQ9, QQ10) to the
                        ; current system coordinates (QQ0, QQ1) we just loaded

 JSR hyp1               ; Arrive in the system closest to (QQ9, QQ10) and then
                        ; and then fall through into the docking bay routine
                        ; below
}

\ *****************************************************************************
\ Subroutine: BAY
\
\ Go to the docking bay (i.e. show Status Mode).
\
\ We end up here after the startup process (load commander etc.), as well as
\ after a successful save, an escape pod launch, a successful docking, the end
\ of a cargo sell, and various errors (such as not having enough cash, entering
\ too many items when buying, trying to fit an item to your ship when you
\ already have it, running out of cargo space, and so on).
\ *****************************************************************************

.BAY
{
 LDA #&FF               ; Set QQ12 = &FF (the docked flag) to indicate that we
 STA QQ12               ; are docked

 LDA #f8                ; Jump into the main loop at FRCE, setting the key
 JMP FRCE               ; "pressed" to red key F8 (so we show Status Mode)
}

\ *****************************************************************************
\ Subroutine: TITLE
\
\ Display the title screen, with a rotating ship and a recursive text token at
\ the bottom of the screen.
\
\ Arguments:
\
\   A           The number of the recursive token to show below the rotating
\               ship (see elite-words.asm for details of recursive tokens)
\
\   X           The type of the ship to show (see variable XX21 for a list of
\               ship types)
\ *****************************************************************************

.TITLE
{
 PHA                    ; Store the token number on the stack for later

 STX TYPE               ; Store the ship type in location TYPE

 JSR RESET              ; Reset the player ship so we can use it for our
                        ; rotating title ship

 LDA #1                 ; Clear the top part of the screen and draw a box
 JSR TT66               ; border, with QQ11 set to 1 (so TT66 does not show the
                        ; name of the space view at the bottom)

 DEC QQ11               ; Decrement QQ11 to 0, so from here on we are using a
                        ; space view

 LDA #96                ; Set rotmat0z hi = 96 (96 is the value of unity in the
 STA INWK+14            ; rotation vector)

\LSR A                  ; This instruction is commented out in the original
                        ; source. It would halve the value of zhi to 48, so the
                        ; ship would start off closer to the viewer.

 STA INWK+7             ; Set z_hi, the high byte of the ship's z-coordinate,
                        ; to 96, which is the distance at which the rotating
                        ; ship starts out before coming towards us

 LDX #127
 STX INWK+29            ; Set rotx counter = 127, so don't dampen the roll
 STX INWK+30            ; Set rotz counter = 127, so don't dampen the pitch

 INX                    ; Set QQ17 = 128, which sets Sentence Case, with the
 STX QQ17               ; next letter printing in upper case

 LDA TYPE               ; Set up a new ship, using the ship type in TYPE
 JSR NWSHP

 LDY #6                 ; Set the text cursor to column 6
 STY XC

 JSR DELAY              ; Delay for Y line scans (i.e. 6 line scans)
 
 LDA #30                ; Print recursive token 144 ("---- E L I T E ----")
 JSR plf                ; followed by a newline

 LDY #6                 ; Set the text cursor to column 6 again
 STY XC
 
 INC YC                 ; Move the text cursor down a row

 LDA PATG               ; If PATG = 0, skip the following two lines, which
 BEQ awe                ; print the author credits (PATG can be toggled by the
                        ; player pausing the game and pressing X)

 LDA #254               ; Print recursive token 94, "BY D.BRABEN & I.BELL"
 JSR TT27

.awe
 JSR CLYNS              ; Clear some screen rows, exists with Y = 0

 STY DELTA              ; Set DELTA = 0 (i.e. ship speed = 0)

 STY JSTK               ; Set KSTK = 0 (i.e. keyboard, not joystick)

 PLA                    ; Restore the recursive token number we stored on the
 JSR ex                 ; stack at the start of this subroutine, and print that
                        ; token

 LDA #148               ; Move the text cursor to column 7 and print recursive
 LDX #7                 ; token 148 ("(C) ACORNSOFT 1984")
 STX XC
 JSR ex

.TLL2
 LDA INWK+7             ; If z_hi (the ship's distance) is 1, jump to TL1 to
 CMP #1                 ; skip the following decrement
 BEQ TL1

 DEC INWK+7             ; Decrement the ship's distance, to bring the ship
                        ; a bit closer to us

.TL1
 JSR MVEIT              ; Move the ship in space according to the rotation
                        ; matrix and the new value in z_hi

 LDA #128               ; Set z_lo = 128 (so the closest the ship gets to us is
 STA INWK+6             ; z_hi = 1, z_lo = 128, or 256 + 128 = 384

 ASL A                  ; Set A = 0

 STA INWK               ; Set x_lo = 0, so ship remains in the screen centre

 STA INWK+3             ; Set y_lo = 0, so ship remains in the screen centre

 JSR LL9                ; Call LL9 to display the ship

 DEC MCNT               ; Decrement the move counter

 LDA SHEILA+&40         ; Read 6522 System VIA input register IRB (SHEILA &40)

 AND #16                ; Bit 4 of IRB (PB4) is clear if joystick 1's fire
                        ; button is pressed, otherwise it is set, so AND'ing
                        ; the value of IRB with 16 (%10000) extracts this bit

\TAX                    ; This instruction is commented out in the original
                        ; source

 BEQ TL2                ; If the joystick fire button is pressed, jump to BL2

 JSR RDKEY              ; Scan the keyboard for a keypress

 BEQ TLL2               ; If no key was pressed, loop back up to move/rotate
                        ; the ship and check again for a key press

 RTS                    ; Return from the subroutine

.TL2
 DEC JSTK               ; Joystick fire button was pressed, so set JSTK to &FF
                        ; (it was set to 0 above), to disable keyboard and
                        ; enable joysticks

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: CHECK
\
\ Calculate the checksum for the last saved commander data block, to protect
\ against corruption and tampering. The checksum is returned in A.
\
\ This algorithm is also implemented in elite-checksum.py.
\ *****************************************************************************

.CHECK
{
 LDX #NT%-2             ; Set X to the size of the commander data block, less
                        ; 2 (as there are two checksum bytes)

 CLC                    ; Clear the carry flag so we can do addition without
                        ; the carry flag affecting the result

 TXA                    ; Seed the checksum calculation by setting A to the
                        ; size of the commander data block, less 2

                        ; We now loop through the commander data block,
                        ; starting at the end and looping down to the start
                        ; (so at the start of this loop, the X-th byte is the
                        ; last byte of the commander data block, i.e. the save
                        ; count)

.QUL2
 ADC NA%+7,X            ; Add the X-1-th byte of the data block to A, plus
                        ; carry

 EOR NA%+8,X            ; EOR A with the X-th byte of the data block

 DEX                    ; Decrement the loop counter

 BNE QUL2               ; Loop back for the next byte in the data block

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: TRNME
\
\ Transfer commander name to page &11 and &3
\ *****************************************************************************

.TRNME                  ; Transfer commander name to page &11 and &3
{
 LDX #7                 ; 8 chars max

.GTL1                   ; counter X
 LDA INWK,X             ; INWK+5,X
 STA NA%,X
 DEX                    ; next char
 BPL GTL1               ; loop X
}

\ *****************************************************************************
\ Subroutine: TR1
\
\ Reset name from NA% to INWK+5 but not flight's page &3
\ *****************************************************************************

.TR1                    ; reset name from NA% to INWK+5 but not flight's page &3
{
 LDX #7                 ; 8 chars max

.GTL2                   ; counter X
 LDA NA%,X
 STA INWK,X
 DEX
 BPL GTL2               ; loop X
 RTS
}

\ *****************************************************************************
\ Subroutine: GTNME
\
\ Get Commander Name
\ *****************************************************************************

.GTNME                  ; Get Commander Name
{
 LDA #1
 JSR TT66
 LDA #123
 JSR TT27
 JSR DEL8
 LDA #&81
 STA SHEILA+&4E
 LDA #15
 TAX
 JSR OSBYTE
 LDX #LO(RLINE)
 LDY #HI(RLINE)
 LDA #0                 ; RLINE at &39E9 for OSWORD = 0
 JSR OSWORD             ; read input string
 \LDA #1
 \STA SHEILA+&4E
 BCS TR1                ; else carry set if escape hit
 TYA                    ; accepted string length
 BEQ TR1                ; if 0 reset name from NA% to INWK+5
 JMP TT67               ; Jump to TT67, which prints a newline
}

\ *****************************************************************************
\ Variable: RLINE
\
\ OSWORD block for gtnme.
\ *****************************************************************************

.RLINE                  ; OSWORD block for gtnme
{
 EQUW INWK
 EQUB 7                 ; +3 min ascii
 EQUB 33                ; +4 max ascii
 EQUB &7A
}

\ *****************************************************************************
\ Subroutine: ZERO
\
\ Zero-fill pages &9, &A, &B, &C and &D.
\ *****************************************************************************

.ZERO
{
 LDX #&D                ; Point X to page &D

.ZEL
 JSR ZES1               ; Call ZES1 below to zero-fill the page in X

 DEX                    ; Decrement X to point to the next page

 CPX #9                 ; If X is > 9 (i.e. is &A, &B or &C), then loop back
 BNE ZEL                ; up to clear the next page

                        ; Then fall through into ZES1 with X set to 9, so we
                        ; clear page &9 too
}

\ *****************************************************************************
\ Subroutine: ZES1
\
\ Zero-fill the page whose number is in X.
\
\ Arguments:
\
\   X           The page we want to zero-fill
\ *****************************************************************************

.ZES1
{
 LDY #0                 ; If we set Y = SC = 0 and fall through into ZES2
 STY SC                 ; below, then we will zero-fill 255 bytes starting from
                        ; SC - in other words, we will zero-fill the whole of
                        ; page X
}

\ *****************************************************************************
\ Subroutine: ZES2
\
\ Zero-fill the page whose number is in X, from position SC to SC + Y.
\
\ If Y is 0, this will zero-fill 255 bytes starting from SC
\
\ If Y is negative, this will zero-fill from SC + Y to SC - 1, i.e. the Y bytes
\ before SC
\
\ Arguments:
\
\   X           The page where we want to zero-fill
\
\   Y           A negative value denoting how many bytes before SC we want
\               to start zeroing
\
\   SC          The position in the page where we should zero fill up to
\ *****************************************************************************

.ZES2
{
 LDA #0                 ; Load X with the byte we want to fill the memory block
                        ; with - i.e. zero

 STX SC+1               ; We want to zero-fill page X, so store this in the
                        ; high byte of SC, so the 16-bit address in SC and
                        ; SC+1 is now pointing to the SC-th byte of page X

.ZEL1
 STA (SC),Y             ; Zero the Y-th byte of the block pointed to by SC,
                        ; so that's effectively the Y-th byte before SC

 INY                    ; Increment the loop counter

 BNE ZEL1               ; Loop back to zero the next byte
 
 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: SVE
\
\ Save commander
\ *****************************************************************************

.SVE                    ; Disc service entry as key @ hit
{
 JSR GTNME              ; zero pages &9,&A,&B,&C,&D
 JSR TRNME              ; Transfer commander name to Page &11
 JSR ZERO
 LSR SVC
 LDX #NT%

.SVL1                   ; counter X
 LDA TP,X               ; TP,X from Page &3 to
 STA &B00,X             ; Page &0B
 STA NA%+8,X            ; Page &11
 DEX
 BPL SVL1               ; loop X
 JSR CHECK              ; Acc gets check byte
 STA CHK
 PHA                    ; push check byte
 ORA #128               ; build competition info for bbc disk
 STA K
 EOR COK                ; file check competition
 STA K+2
 EOR CASH+2
 STA K+1
 EOR #&5A               ; 'Z'
 EOR TALLY+1            ; kills/256
 STA K+3
 JSR BPRNT              ; Buffer print ( 4 bytes of K)
 JSR TT67               ; next Row ; Call TT67, which prints a newline
 JSR TT67               ; next Row ; Call TT67, which prints a newline
 PLA                    ; pull check byte
 STA &B00+NT%
 EOR #&A9               ; check code2

 STA CHK2
 STA &AFF+NT%
 LDY #&B
 STY &C0B               ; &0B00 is start address of data to save
 INY                    ; #&0C
 STY &C0F               ; &0C00 is end address of data to save

 LDA #&81
 STA SHEILA+&4E
 INC SVN
 LDA #0
 JSR QUS1
 LDX #0
 \STX SHEILA+&4E
 \DEX
 STX SVN
 JMP BAY
}

\ *****************************************************************************
\ Subroutine: QUS1
\
\ File Ops,  Acc=OSFILE in, valid drive is carry clear.
\ *****************************************************************************

.QUS1                   ; File Ops,  Acc=OSFILE in, valid drive is carry clear.
{
 LDX #INWK
 STX &C00               ; pointer to filename string
 LDX #0                 ; lo
 JMP OSFILE             ; block &0C00
}

\ *****************************************************************************
\ Subroutine: LOD
\
\ Load new Commander
\ *****************************************************************************

.LOD                    ; Load commander file then Page &B to Page &11, else carry set if invalid drive
{
 LDX #2                 ; Enable Escape key and clear memory if Break key is
 JSR FX200              ; pressed (*FX 200, 2)

 JSR ZERO               ; Zero Pages &9,&A,&B,&C,&D
 LDY #&B
 STY &C03               ; load address is &0B00
 INC &C0B               ; length of file incremented
 INY
 LDA #&FF
 JSR QUS1               ; File Ops
 LDA &B00               ; look at data, first byte is TP mission bits
 BMI SPS1+1             ; bit7 set is Not ELITE II file
 LDX #NT%

.LOL1                   ; counter X \ copy &B00 onwards to NA%+8 onwards
 LDA &B00,X             ; page &B
 STA NA%+8,X
 DEX
 BPL LOL1               ; loop X
 LDX #3
}

\ *****************************************************************************
\ Subroutine: FX200
\
\ Performs a *FX 200, X command, which controls the behaviour of the Escape
\ and Break keys.
\ *****************************************************************************

.FX200
{
 LDY #0                 ; Call OSBYTE &C8 (200) with Y = 0, so new value is
 LDA #200               ; set to X
 JMP OSBYTE

 RTS                    ; Return from subroutine
}

\ *****************************************************************************
\ Subroutine: SPS1
\
\ XX15 vector to planet
\ *****************************************************************************

.SPS1                   ; XX15 vector to planet
{
 LDX #0                 ; xcoord planet
 JSR SPS3               ; planet for space compass into K3(0to8)
 LDX #3                 ; ycoord
 JSR SPS3
 LDX #6                 ; zcoord
 JSR SPS3
}

\ *****************************************************************************
\ Subroutine: TAS2
\
\ XX15=r~96 \ their comment \ build XX15 from K3
\ *****************************************************************************

.TAS2                   ; XX15=r~96 \ their comment \ build XX15 from K3
{
 LDA K3
 ORA K3+3
 ORA K3+6
 ORA #1                 ; not zero
 STA K3+9               ; lo or'd max
 LDA K3+1               ; x hi
 ORA K3+4               ; y hi
 ORA K3+7               ; z hi

.TAL2                   ; roll Acc = xyz  hi
 ASL K3+9               ; all lo max
 ROL A                  ; all hi max
 BCS TA2                ; exit when xyz hi*=2 overflows
 ASL K3                 ; xlo
 ROL K3+1               ; xhi*=2
 ASL K3+3               ; ylo
 ROL K3+4               ; yhi*=2
 ASL K3+6               ; zlo
 ROL K3+7               ; zhi*=2
 BCC TAL2               ; loop roll Acc xyz hi

.TA2                    ; exited, Build XX15(0to2) from (raw) K3(1to8)
 LDA K3+1               ; xhi
 LSR A                  ; clear bit7 for sign
 ORA K3+2               ; xsg
 STA XX15               ; xunit, bit7 is xsign
 LDA K3+4               ; yhi
 LSR A
 ORA K3+5               ; ysg
 STA XX15+1             ; yunit, bit7 is ysign
 LDA K3+7               ; zhi
 LSR A
 ORA K3+8               ; zsg
 STA XX15+2             ; zunit, bit7 is zsign
}

\ *****************************************************************************
\ Subroutine: NORM
\
\ Normalize 3-vector length of XX15
\ *****************************************************************************

.NORM                   ; Normalize 3-vector length of XX15
{
 LDA XX15
 JSR SQUA               ; P.A =A7*A7  x^2
 STA R                  ; hi sum
 LDA P                  ; lo
 STA Q                  ; lo sum
 LDA XX15+1
 JSR SQUA               ; P.A =A7*A7 y^2
 STA T                  ; temp hi
 LDA P                  ; lo
 ADC Q
 STA Q
 LDA T                  ; hi
 ADC R
 STA R
 LDA XX15+2
 JSR SQUA               ; P.A =A7*A7 z^2
 STA T
 LDA P                  ; lo
 ADC Q
 STA Q                  ; xlo2 + ylo2 + zlo2
 LDA T                  ; temp hi
 ADC R
 STA R

 JSR LL5                ; Q = SQR(Qlo.Rhi), Q <~127

 LDA XX15
 JSR TIS2               ; *96/Q
 STA XX15               ; xunit

 LDA XX15+1
 JSR TIS2
 STA XX15+1             ; yunit

 LDA XX15+2
 JSR TIS2
 STA XX15+2             ; zunit
}

.NO1
{
 RTS                    ; end of norm
}

\ *****************************************************************************
\ Subroutine: RDKEY
\
\ Scan the keyboard, starting with internal key number 16 (Q) and working
\ through the set of internal key numbers (see p.142 of the Advanced User Guide
\ for a list of internal key values).
\
\ This routine is effectively the same as OSBYTE &7A, though the OSBYTE call
\ preserves A, unlike this routine.
\
\ Returns:
\
\   X           If a key is being pressed, X contains the internal key number,
\               otherwise it contains 0
\
\   A           Contains the same as X
\ *****************************************************************************

.RDKEY
{
 LDX #16                ; Start the scan with internal key number 16 (Q)

.Rd1
 JSR DKS4               ; Scan the keyboard to see if the key in X is currently
                        ; being pressed

 BMI Rd2                ; Jump to Rd2 if this key is being pressed (in which
                        ; case DKS4 will have returned a negative value,
                        ; specifically 128 + X)

 INX                    ; Increment the key number

 BPL Rd1                ; Loop back to test the next key, ending the loop when
                        ; X is negative (i.e. 128)

 TXA                    ; If we get here, nothing is being pressed, so copy X
                        ; into A so that X = A = 128

.Rd2
 EOR #128               ; EOR A with 128, to switch off bit 7, so A now
                        ; contains 0 if no key has been pressed, or the
                        ; internal key number if it has been pressed

 TAX                    ; Copy A into X

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: ECMOF
\
\ Sound of ECM system off
\ *****************************************************************************

.ECMOF                  ; Sound of ECM system off
{
 LDA #0                 ; not active
 STA ECMA
 STA ECMP               ; player's not on
 JSR ECBLB              ; ecm bulb switch
 LDA #72                ; becomes noise Yindex = 39
 BNE NOISE              ; guaranteed hop
}

\ *****************************************************************************
\ Subroutine: EXNO3
\
\ Called when DEATH occurs. Ominous noises, two noises, A=16,24
\ *****************************************************************************

.EXNO3                  ; called when DEATH occurs. Ominous noises, two noises, A=16,24
{
 LDA #16                ; becomes Yindex = 11
 JSR NOISE
 LDA #24                ; becomes Yindex = 15 rumble
 BNE NOISE              ; guaranteed hop
}

\ *****************************************************************************
\ Subroutine: SFRMIS
\
\ Sound fire missile
\ *****************************************************************************

.SFRMIS                 ; Sound fire missile
{
 LDX #MSL               ; #MSL missile
 JSR SFS1-2             ; spawn missile with ai=#&FE max but no ecm
 BCC NO1                ; rts as failed to launch
 LDA #&78               ; token = incoming missile
 JSR MESS               ; message
 LDA #48                ; becomes Y = 27
 BNE NOISE              ; guaranteed hop
}

\ *****************************************************************************
\ Subroutine: EXNO2
\
\ Faint death noise, player killed ship.
\ *****************************************************************************

.EXNO2                  ; faint death noise, player killed ship.
{
 INC TALLY              ; kills lo
 BNE EXNO-2             ; no carry hop to ldx #7
 INC TALLY+1            ; kills hi
 LDA #101               ; token = right on commander !
 JSR MESS               ; message
 LDX #7                 ; mask for sound distance
}

\ *****************************************************************************
\ Subroutine: EXNO
\
\ Explosion noise distance X
\ *****************************************************************************

.EXNO                   ; Explosion noise distance X
{
 STX T                  ; distance
 LDA #24                ; Rumble later becomes Yindex = 15
 JSR NOS1               ; build sound y index
 LDA INWK+7             ; zhi
 LSR A                  ; /=2
 LSR A                  ; #&3F max
 AND T                  ; could be #7
 ORA #&F1               ; adjust sound amplitude by distance away
 STA XX16+2
 JSR NO3                ; Sound block ready
 LDA #16                ; becomes Yindex = 11

 EQUB &2C
}

\ *****************************************************************************
\ Subroutine: BEEP
\
\ Missile lock target
\ *****************************************************************************

.BEEP                   ; Missile lock target
{
 LDA #32                ; becomes Y= 19
}

\ *****************************************************************************
\ Subroutine: NOISE
\
\ Sound based on Acc
\ *****************************************************************************

.NOISE                  ; Sound based on Acc
{
 JSR NOS1               ; build sound y index
}

\ *****************************************************************************
\ Subroutine: NO3
\
\ Sound block ready
\ *****************************************************************************

.NO3                    ; Sound block ready
{
 LDX DNOIZ              ; sound toggle
 BNE NO1                ; rts
 LDX #LO(XX16)
 LDY #HI(XX16)
 LDA #7                 ; SOUND
 JMP OSWORD
}

\ *****************************************************************************
\ Subroutine: NOS1
\
\ Build sound y index
\ *****************************************************************************

.NOS1                   ; build sound y index
{
 LSR A                  ; /=2 and carry cleared
 ADC #3                 ; +=3 top of block
 TAY                    ; Yindex = last byte needed from group of
 LDX #7                 ; 4 words

.NOL1                   ; counters X,Y
 LDA #0                 ; upper byte
 STA XX16,X
 DEX                    ; Sound parameter block
 LDA SFX,Y              ; lower byte
 STA XX16,X
 DEY                    ; next lo
 DEX                    ; next byte
 BPL NOL1               ; loop Y,X
 RTS
}

\ *****************************************************************************
\ Variable: KYTB
\
\ Keyboard table for in-flight controls. This table contains the internal key
\ codes for the flight keys (see p.142 of the Advanced User Guide for a list of
\ internal key values).
\
\ The pitch, roll, speed and laser keys (i.e. the seven primary flight
\ control keys) have bit 7 set, so they have 128 added to their internal
\ values. This doesn't appear to be used anywhere.
\
\ Note that KYTB actually points to the byte before the start of the table, so
\ the offset of the first key value is 1 (i.e. KYTB+1), not 0.
\ *****************************************************************************

KYTB = P% - 1           ; Point KYTB to the byte before the start of the table
{
                        ; These are the primary flight controls (pitch, roll,
                        ; speed and lasers)

 EQUB &68 + 128         ; ?         KYTB+1      Slow down
 EQUB &62 + 128         ; Space     KYTB+2      Speed up
 EQUB &66 + 128         ; <         KYTB+3      Roll left
 EQUB &67 + 128         ; >         KYTB+4      Roll right
 EQUB &42 + 128         ; X         KYTB+5      Pitch up
 EQUB &51 + 128         ; S         KYTB+6      Pitch down
 EQUB &41 + 128         ; A         KYTB+7      Fire lasers

                        ; These are the secondary flight controls

 EQUB &60               ; Tab       KYTB+8      Energy bomb
 EQUB &70               ; Escape    KYTB+9      Launch escape pod
 EQUB &23               ; T         KYTB+10     Arm missile
 EQUB &35               ; U         KYTB+11     Unarm missile
 EQUB &65               ; M         KYTB+12     Fire missile
 EQUB &22               ; E         KYTB+13     E.C.M.
 EQUB &45               ; J         KYTB+14     In-system jump
 EQUB &52               ; C         KYTB+15     Docking computer
}

\ *****************************************************************************
\ Subroutine: DKS1
\
\ Scan the keyboard for the flight key given in register Y, where Y is the
\ offset into the KYTB table above (so we can scan for Space by setting Y to
\ 2, for example). If the key is pressed, set the corresponding byte in the
\ key logger at KL to &FF.
\
\ Arguments:
\
\   Y           The offset into the KYTB table above of the key that we want to
\               scan on the keyboard
\ *****************************************************************************

.DKS1
{
 LDX KYTB,Y             ; Get the internal key number from the Y-th byte of the
                        ; KYTB table above

 JSR DKS4               ; Call DKS4, which will set A and X to a negative value
                        ; if the key is being pressed

 BPL DKS2-1             ; The key is not being pressed, so return from the
                        ; subroutine (as DKS2-1 contains an RTS instruction)

 LDX #&FF               ; Store &FF in the Y-th byte of the key logger at KL
 STX KL,Y

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: CTRL
\
\ Scan the keyboard to see if CTRL is currently pressed.
\ *****************************************************************************

.CTRL
{
 LDX #1                 ; Set X to the internal key number for CTRL and fall
                        ; through to DSK4 to scan the keyboard
}

\ *****************************************************************************
\ Subroutine: DKS4
\
\ Scan the keyboard to see if the key specified in X is currently being
\ pressed.
\
\ Arguments:
\
\   X           The internal number of the key to check (see p.142 of the
\               Advanced User Guide for a list of internal key values)
\
\ Returns:
\
\   X           If the key in X is being pressed, X contains the original
\               argument X, but with bit 7 set (i.e. X + 128). If the key in
\               X is not being pressed, the value in X is unchanged.
\
\   A           Contains the same as X
\ *****************************************************************************

.DKS4
{
 LDA #3                 ; Set A to 3, so it's ready to send to SHEILA once
                        ; interrupts have been disabled

 SEI                    ; Disable interrupts so we can scan the keyboard
                        ; without being hijacked

 STA SHEILA+&40         ; Set 6522 System VIA output register ORB (SHEILA &40)
                        ; to %0011 to stop auto scan of keyboard

 LDA #&7F               ; Set 6522 System VIA data direction register DDRA
 STA SHEILA+&43         ; (SHEILA &43) to %0111 1111. This sets the A registers
                        ; (IRA and ORA) so that 
                        ;
                        ; Bits 0-6 of ORA will sent to the keyboard
                        ;
                        ; Bit 7 of IRA will be read from the keyboard

 STX SHEILA+&4F         ; Set 6522 System VIA output register ORA (SHEILA &4F)
                        ; to X, the key we want to scan for; bits 0-6 will be
                        ; sent to the keyboard, of which bits 0-3 determine the
                        ; keyboard column, and bits 4-6 the keyboard row

 LDX SHEILA+&4F         ; Read 6522 System VIA output register IRA (SHEILA &4F)
                        ; into X; bit 7 is the only bit that will have changed.
                        ; If the key is pressed, then bit 7 will be set (so X
                        ; will contain 128 + X), otherwise it will be clear (so
                        ; X will be unchanged).
 
 LDA #&B                ; Set 6522 System VIA output register ORB (SHEILA &40)
 STA SHEILA+&40         ; to %1011 to restart auto scan of keyboard

 CLI                    ; Allow interrupts again

 TXA                    ; Transfer X into A

 RTS
}

\ *****************************************************************************
\ Subroutine: DKS2
\
\ Return the value of ADC channel in X (used to read the joystick). The value
\ will be inverted if the game has been configured to reverse both joystick
\ channels (which can be done by pausing the game and pressing J).
\
\ Arguments:
\
\   X           The ADC channel to read (1 = joystick X, 2 = joystick Y)
\
\ Returns:
\
\   (A X)       The 16-bit value read from channel X, with the value inverted
\               if the game has been configured to reverse the joystick
\ *****************************************************************************

.DKS2
{
 LDA #&80               ; Call OSBYTE &80 to fetch the 16-bit value from ADC
 JSR OSBYTE             ; channel X, returning (Y X), i.e. the high byte in Y
                        ; and the low byte in X

 TYA                    ; Copy Y to A, so the result is now in (A X)

 EOR JSTE               ; The high byte A is now EOR'd with the value in
                        ; location JSTE, which contains &FF if both joystick
                        ; channels are reversed and 0 otherwise (so A now 
                        ; contains the high byte but inverted, if that's what
                        ; the current settings say)

 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: DKS3
\
\ Toggle a configuration setting and emit a beep. This is called when the game
\ is paused and a key is pressed that changes the games's configuration.
\ Specifically, this routine toggles the configuration settings for the
\ following keys:
\
\   * Caps Lock toggles keyboard flight damping (&40)
\   * A toggles keyboard auto-recentre (&41)
\   * X toggles author names on start-up screen (&42)
\   * F toggles flashing console bars (&43)
\   * Y toggles reverse joystick Y channel (&44)
\   * J toggles reverse both joystick channels (&45)
\   * K toggles keyboard and joystick (&46)
\
\ The numbers in brackets are the internal key numbers (see p.142 of the
\ Advanced User Guide for a list of internal key values). We pass the key that
\ has been pressed in X, and the configuration option to check it against in Y,
\ so this routine is typically called in a loop that loops through the various
\ configuration options.
\
\ Arguments:
\
\   X           The internal number of the key that's been pressed
\
\   Y           The internal number of the configuration key to check against,
\               from the list above (i.e. Y must be from &40 to &46)
\ *****************************************************************************

.DKS3
{
 STY T                  ; Store the configuration key argument in T

 CPX T                  ; If X <> Y, jump to Dk3 to return from the subroutine
 BNE Dk3

                        ; We have a match between X and Y, so now to toggle
                        ; the relevant configuration byte. Caps Lock has a key
                        ; value of &40 and has its configuration byte at
                        ; location DAMP, A has a value of &41 and has its byte
                        ; at location DJD, which is DAMP+1, and so on. So we
                        ; can toggle the configuration byte by changing the
                        ; byte at DAMP + (X - &40), or to put it in indexing
                        ; terms, DAMP-&40,X. It's no coincidence that the
                        ; game's configuration bytes are set up in this order
                        ; and with these keys (and this is also why the sound
                        ; on/off keys are dealt with elsewhere, as the internal
                        ; key for S and Q are &51 and &10, which don't fit
                        ; nicely into this approach).

 LDA DAMP-&40,X         ; Fetch the byte from DAMP + (X - &40), invert it and
 EOR #&FF               ; put it back (0 means no and &FF means yes in the
 STA DAMP-&40,X         ; configuration bytes, so this toggles the setting)

 JSR BELL               ; Make a beep sound so the player knows something has
                        ; happened

 JSR DELAY              ; Wait for Y line scans (Y is between 64 and 70, so
                        ; this is always a bit longer than a second)

 LDY T                  ; Restore the configuration key argument into Y

.Dk3
 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: DKJ1
\
\ Read joystick flight controls. Specifically, scan the keyboard for the speed
\ up and slow down keys, and read the joystick's fire button and X and Y axes,
\ storing the results in the key logger and the joystick position variables.
\
\ This routine is only called if joysticks are enabled (JSTK = &FF).
\ *****************************************************************************

.DKJ1
{
 LDY #1                 ; Update the key logger for key 1 in the KYTB table, so
 JSR DKS1               ; KY1 will be &FF if ? (slow down) is being pressed

 INY                    ; Update the key logger for key 2 in the KYTB table, so
 JSR DKS1               ; KY2 will be &FF if Space (speed up) is being pressed

 LDA SHEILA+&40         ; Read 6522 System VIA input register IRB (SHEILA &40)

 TAX                    ; This instruction doesn't seem to have any effect, as
                        ; X is overwritten in a few instructions. When the
                        ; joystick is checked in a similar way in the TITLE
                        ; subroutine for the "Press Fire Or Space,Commander."
                        ; stage of the start-up screen, there's another
                        ; unnecessary TAX instruction present, but there it's
                        ; commented out.

 AND #16                ; Bit 4 of IRB (PB4) is clear if joystick 1's fire
                        ; button is pressed, otherwise it is set, so AND'ing
                        ; the value of IRB with 16 (%10000) extracts this bit

 EOR #16                ; Flip bit 4 so that it's set if the fire button has
 STA KY7                ; been pressed, and store the result in the keyboard
                        ; logger at location KY7, which is also where the A key
                        ; (fire lasers) key is logged

 LDX #1                 ; Call DKS2 to fetch the value of ADC channel 1 (the
 JSR DKS2               ; joystick X value) into (A X), and OR A with 1. This
 ORA #1                 ; ensures that the high byte is at least 1, and then we
 STA JSTX               ; store the result in JSTX.

 LDX #2                 ; Call DKS2 to fetch the value of ADC channel 2 (the
 JSR DKS2               ; joystick Y value) into (A X), and EOR A with JSTGY.
 EOR JSTGY              ; JSTGY will be &FF if the game is configured to
 STA JSTY               ; reverse the joystick Y channel, so this EOR does
                        ; exactly that, and then we store the result in JSTY.

 JMP DK4                ; We are done scanning the joystick flight controls,
                        ; so jump to DK4 to scan for other keys, using a tail
                        ; call so we can return from the subroutine there.
}

\ *****************************************************************************
\ Subroutine: U%
\
\ Clear the key logger (from KY1 through KY19).
\ *****************************************************************************

.U%
{
 LDA #0                 ; Set A to 0, as this means "key not pressed" in the
                        ; key logger at KL

 LDY #15                ; We want to clear the 15 key logger locations from
                        ; KY1 to KY19, so set a counter in Y. We don't want to
                        ; clear the first key logger location, at KL, as the
                        ; keyboard table at KYTB starts with offset 1, not 0,
                        ; so KL is not technically part of the key logger
                        ; (it's actually used for logging keys that don't
                        ; appear in the keyboard table, and which therefore
                        ; don't use the key logger)

.DKL3
 STA KL,Y               ; Store 0 in the Y-th byte of the key logger

 DEY                    ; Decrement the counter

 BNE DKL3               ; And loop back for the next key

 RTS
}

\ *****************************************************************************
\ Subroutine: DOKEY
\
\ Scan for the seven primary flight controls (or the equivalent on joystick).
\ Specifically:
\
\   * If we are on keyboard configuration, clear the key logger and update it
\     for the seven primary flight controls, and update the roll and pitch
\     rates accordingly.
\
\   * If we are on joystick configuration, clear the key logger and jump to
\     DKJ1, which reads the joystick equivalents of the primary flight
\     controls.
\
\ Both options end up at DK4 to scan for other keys, beyond the seven primary
\ flight controls.
\ *****************************************************************************

.DOKEY
{
 JSR U%                 ; Call U% to clear the key logger

 LDA JSTK               ; If JSTK is non-zero, then we are configured to use
 BNE DKJ1               ; the joystick rather than keyboard, so jump to DKJ1
                        ; to read the joystick flight controls, before jumping
                        ; to DK4 below

 LDY #7                 ; We're going to work our way through the primary flight
                        ; control keys (pitch, roll, speed and laser), so set a
                        ; counter in Y so we can loop through all 7

.DKL2
 JSR DKS1               ; Call DKS1 to see if the KYTB key at offset Y is being
                        ; pressed, and set the key logger accordingly

 DEY                    ; Decrement the loop counter

 BNE DKL2               ; Loop back for the next key, working our way from A at
                        ; KYTB+7 down to ? at KYTB+1

 LDX JSTX               ; Set X = JSTX, the current roll rate (as shown in the
                        ; RL indicator on the dashboard)

 LDA #7                 ; Set A to 7, which is the amount we want to alter the
                        ; roll rate by if the roll keys are being pressed

 LDY KL+3               ; If the < key is being pressed, then call the BUMP2
 BEQ P%+5               ; routine to increase the roll rate in X by A
 JSR BUMP2

 LDY KL+4               ; If the > key is being pressed, then call the REDU2
 BEQ P%+5               ; routine to decrease the roll rate in X by A, taking
 JSR REDU2              ; the keyboard auto re-centre setting into account

 STX JSTX               ; Store the updated roll rate in JSTX

 ASL A                  ; Double the value of A, to 14

 LDX JSTY               ; Set X = JSTY, the current pitch rate (as shown in the
                        ; DC indicator on the dashboard)

 LDY KL+5               ; If the > key is being pressed, then call the REDU2
 BEQ P%+5               ; routine to decrease the pitch rate in X by A, taking
 JSR REDU2              ; the keyboard auto re-centre setting into account

 LDY KL+6               ; If the S key is being pressed, then call the BUMP2
 BEQ P%+5               ; routine to increase the pitch rate in X by A
 JSR BUMP2

 STX JSTY               ; Store the updated roll rate in JSTY

                        ; Fall through into DK4 to scan for other keys
}

\ *****************************************************************************
\ Subroutine: DK4
\
\ Scan for pause and configuration keys, and if this is a space view, also scan
\ for secondary flight controls.
\
\ Specifically:
\
\   * Scan for the pause button (COPY) and if it's pressed, pause the game and
\     process any configuration key presses until the game is unpaused (DELETE)
\
\   * If this is a space view, scan for secondary flight keys and update the
\     relevant bytes in the key logger
\ *****************************************************************************

.DK4
{
 JSR RDKEY              ; Scan the keyboard from Q upwards and fetch any key
                        ; press into X

 STX KL                 ; Store X in KL, byte 0 of the key logger

 CPX #&69               ; If COPY is not being pressed, jump to DK2 below,
 BNE DK2                ; otherwise let's process the configuration keys

.FREEZE                 ; COPY is being pressed, so we enter a loop that
                        ; listens for configuration keys, and we keep looping
                        ; until we detect a DELETE keypress. This effectively
                        ; pauses the game when COPY is pressed, and unpauses
                        ; it when DELETE is pressed.

 JSR WSCAN              ; Wait for line scan, so the whole frame is completed

 JSR RDKEY              ; Scan the keyboard from Q upwards and fetch any key
                        ; press into X

 CPX #&51               ; If S is not being pressed, skip to DK6
 BNE DK6

 LDA #0                 ; S is being pressed, so set DNOIZ to 0 to turn the
 STA DNOIZ              ; sound on

.DK6
 LDY #&40               ; We now want to loop through the keys that toggle
                        ; various settings. These have internal key numbers
                        ; between &40 (Caps Lock) and &46 (K), so we set up the
                        ; first key number in Y to act as a loop counter. See
                        ; subroutine DKS3 for more details on this.

.DKL4
 JSR DKS3               ; Call DKS3 to scan for the key given in Y, and toggle
                        ; the relevant setting if it is pressed

 INY                    ; Increment Y to point to the next toggle key

 CPY #&47               ; The last toggle key is &46 (K), so check whether we
                        ; have just done that one

 BNE DKL4               ; If not, loop back to check for the next toggle key

.DK55
 CPX #&10               ; If Q is not being pressed, skip to DK7
 BNE DK7

 STX DNOIZ              ; S is being pressed, so set DNOIZ to X, which is
                        ; non-zero (&10), so this will turn the sound off

.DK7
 CPX #&70               ; If Escape is not being pressed, skip over the next
 BNE P%+5               ; instruction

 JMP DEATH2             ; Escape is being pressed, so jump to DEATH2 to end
                        ; the game

 CPX #&59               ; If DELETE is not being pressed, we are still paused,
 BNE FREEZE             ; so loop back up to keep listening for configuration
                        ; keys, otherwise fall through into the rest of the
                        ; key detection code, which unpauses the game

.DK2
 LDA QQ11               ; If the current view is non-zero (i.e. not a space
 BNE DK5                ; view), return from the subroutine (via DK5, which
                        ; contains an RTS)

 LDY #15                ; This is a space view, so now we want to check for all
                        ; the secondary flight keys. The internal key numbers
                        ; are in the keyboard table KYTB from KYTB+8 to
                        ; KYTB+15, and their key logger locations are from KL+8
                        ; to KL+15. So set a decreasing counter in Y for the
                        ; index, starting at 15, so we can loop through them.

 LDA #&FF               ; Set A to &FF so we can store this in the keyboard
                        ; logger for keys that are being pressed

.DKL1
 LDX KYTB,Y             ; Get the internal key value of the Y-th flight key
                        ; the KYTB keyboard table

 CPX KL                 ; We stored the key that's being pressed in Kl above,
                        ; so check to see if the Y-th flight key is being
                        ; pressed

 BNE DK1                ; If it is not being pressed, skip to DK1 below

 STA KL,Y               ; The Y-th flight key is being pressed, so set that
                        ; key's location in the key logger to &FF

.DK1
 DEY                    ; Decrement the loop counter

 CPY #7                 ; Have we just done the last key?

 BNE DKL1               ; If not, loop back to process the next key

.DK5
 RTS                    ; Return from subroutine
}

\ *****************************************************************************
\ Subroutine: TT217
\
\ Exposed labels: out
\
\ Scan the keyboard until a key is pressed, and return the key's ASCII code.
\ If, om entry, a key is already being held down, then wait until that key is
\ released first (so this routine detects the first key down event following
\ the subroutine call).
\
\ Returns:
\
\   X           The ASCII code of the key that was pressed
\
\   A           Contains the same as X
\
\   Y           Y is preserved
\ *****************************************************************************

.TT217
{
 STY YSAV               ; Store Y in temporary storage, so we can restore it
                        ; later

.t
 JSR DELAY-5            ; Delay for 8 line scans, so we don't take up too much
                        ; CPU time while looping round

 JSR RDKEY              ; Scan the keyboard, starting from Q

 BNE t                  ; If a key was already being held down when we entered
                        ; this routine, keep looping back up to t, until the
                        ; key is released

.t2
 JSR RDKEY              ; Any pre-existing key press is now gone, so we can
                        ; start scanning the keyboard again, starting from Q

 BEQ t2                 ; Keep looping up to t2 until a key is pressed

 TAY                    ; Copy A to Y, so Y contains the internal key number
                        ; of the key pressed

 LDA (TRTB%),Y          ; The address in TRTB% points to the MOS key
                        ; translation table, which is used to translate
                        ; internal key values to ASCII, so this fetches the
                        ; key's ASCII code into A
 
 LDY YSAV               ; Restore the original value of Y we stored above

 TAX                    ; Copy A into X

.^out
 RTS                    ; Return from the subroutine
}

\ *****************************************************************************
\ Subroutine: me1
\
\ Onto new message
\ *****************************************************************************

.me1                    ; onto new message
{
 STX DLY                ; delay set to 0
 PHA                    ; store new token
 LDA MCH                ; old message to erase
 JSR mes9               ; message output now
 PLA                    ; restore new token
 EQUB &2C
}

.ou2                    ; equipment lost is ecm
{
 LDA #108               ; token =  ecm
 EQUB &2C               ; bit2 skip lda
}

.ou3                    ; equipment lost is fuel scoops
{
 LDA #111               ; token = fuel_scoops
}

\ *****************************************************************************
\ Subroutine: MESS
\
\ Message start
\ *****************************************************************************

.MESS                   ; Message start
{
 LDX #0                 ; all capital letters
 STX QQ17
 LDY #9                 ; indent
 STY XC
 LDY #22                ; near bottom row
 STY YC
 CPX DLY                ; is delay printing zero?
 BNE me1
 STY DLY                ; new delay set to 22
 STA MCH                ; copy of token to erase
}

.mes9                   ; also message to erase
{
 JSR TT27               ; process text token
 LSR de                 ; message flag for item + destroyed
 BCC out                ; rts, else append
 LDA #253               ; token = ' DESTROYED'
 JMP TT27
}

\ *****************************************************************************
\ Subroutine: OUCH
\
\ Shield depleted and taking hits to energy, lose cargo/equipment.
\ *****************************************************************************

.OUCH                   ; Shield depleted and taking hits to energy, lose cargo/equipment.
{
 JSR DORND              ; do random, new A, X.
 BMI out                ; rts, 50% prob
 CPX #22                ; max equipment
 BCS out                ; item too high
 LDA QQ20,X             ; cargo or equipment
 BEQ out                ; dont have, rts.
 LDA DLY                ; delay printing already going on
 BNE out                ; rts
 LDY #3                 ; also Acc now 0
 STY de                 ; message flag for item + destroyed
 STA QQ20,X             ; = 0
 CPX #17                ; max cargo
 BCS ou1                ; if yes, equipment Lost, down.
 TXA                    ; else cargo lost, carry is clear.
 ADC #208               ; add to token = food
 BNE MESS               ; guaranteed up, Message start.

.ou1                    ; equipment Lost
 BEQ ou2                ; equipment lost is X=17 ecm, up.
 CPX #18                ; equipment item is 
 BEQ ou3                ; fuel scoops, up.
 TXA                    ; else carry set probably
 ADC #113-20            ; #113-20, token = Bomb, energy unit, docking computer
 BNE MESS               ; guaranteed up, Message start.
}

\ *****************************************************************************
\ Variable: QQ16
\
\ Two-letter token lookup string for tokens 128-159. See elite-words.asm for
\ details of how the two-letter token system works.
\ *****************************************************************************

.QQ16
{
 EQUS "ALLEXEGEZACEBISOUSESARMAINDIREA?ERATENBERALAVETIEDORQUANTEISRION"
}

\ *****************************************************************************
\ Variable: QQ23
\
\ Market prices info.
\ *****************************************************************************

.QQ23                   ; Prxs -> &4619 \ Market prices info
{
                        ; base_price, gradient sign+5bits, base_quantity, mask, units 2bits
 EQUD &01068213         ; Food
 EQUD &030A8114         ; Textiles
 EQUD &07028341         ; Radioactives
 EQUD &1FE28528         ; Slaves
 EQUD &0FFB8553         ; Liquor/Wines
 EQUD &033608C4         ; Luxuries
 EQUD &78081DEB         ; Narcotics
 EQUD &03380E9A         ; Computers
 EQUD &07280675         ; Machinery
 EQUD &1F11014E         ; Alloys
 EQUD &071D0D7C         ; Firearms
 EQUD &3FDC89B0         ; Furs
 EQUD &03358120         ; Minerals
 EQUD &0742A161         ; Gold
 EQUD &1F37A2AB         ; Platinum
 EQUD &0FFAC12D         ; Gem-Stones
 EQUD &07C00F35         ; Alien Items
}

\ *****************************************************************************
\ Subroutine: TI2
\
\ Tidy2 \ yunit small, used to renormalize rotation matrix Xreg = index1 = 0
\ *****************************************************************************

.TI2                    ; Tidy2 \ yunit small, used to renormalize rotation matrix Xreg = index1 = 0
{
 TYA                    ; Acc  index3 = 4
 LDY #2                 ; Yreg index2 = 2
 JSR TIS3               ; below, denom is z
 STA INWK+20            ; Uz=-(FxUx+FyUy)/Fz \ their comment \ rotmat1z hi
 JMP TI3                ; Tidy3
}

\ *****************************************************************************
\ Subroutine: TI1
\
\ Tidy1 \ xunit small, with Y = 4
\ *****************************************************************************

.TI1                    ; Tidy1 \ xunit small, with Y = 4
{
 TAX                    ; Xreg = index1 = 0
 LDA XX15+1
 AND #&60               ; is yunit vector small
 BEQ TI2                ; up, Tidy2  Y = 4
 LDA #2                 ; else index2 = 4, index3 = 2
 JSR TIS3               ; below, denom is y
 STA INWK+18            ; rotmat1 hi
 JMP TI3                ; Tidy3
}

\ *****************************************************************************
\ Subroutine: TIDY
\
\ Orthogonalize rotation matrix that uses 0x60 as unity
\ returns INWK(16,18,20) = INWK(12*18+14*20, 10*16+14*20, 10*16+12*18) / INWK(10,12,14)
\ Ux,Uy,Uz = -(FyUy+FzUz, FxUx+FzUz, FxUx+FyUy)/ Fx,Fy,Fz
\ *****************************************************************************

.TIDY                   ; Orthogonalize rotation matrix that uses 0x60 as unity
{
 LDA INWK+10            ; rotmat0x hi
 STA XX15               ; XX15(0,1,2) = Fx,Fy,Fz
 LDA INWK+12            ; rotmat0y hi
 STA XX15+1
 LDA INWK+14            ; rotmat0z hi
 STA XX15+2
 JSR NORM               ; normalize  F= Rotmat0
 LDA XX15               ; XX15+0
 STA INWK+10            ; rotmat0x hi
 LDA XX15+1
 STA INWK+12            ; rotmat0y hi
 LDA XX15+2
 STA INWK+14            ; rotmat0z hi

 LDY #4                 ; Y=#4
 LDA XX15
 AND #&60               ; is xunit small?
 BEQ TI1                ; up to Tidy1 with Y = 4
 LDX #2                 ; index1 = 2
 LDA #0                 ; index3 = 0
 JSR TIS3               ; below with Yreg = index2 = 4, denom = x
 STA INWK+16            ; rotmat1x hi
}

.TI3                    ; Tidy3  \ All 3 choices continue with rotmat1? updated
{
 LDA INWK+16            ; rotmat1x hi
 STA XX15
 LDA INWK+18            ; rotmat1y hi
 STA XX15+1
 LDA INWK+20            ; rotmat1z hi
 STA XX15+2             ; XX15(0,1,2) = Ux,Uy,Uz
 JSR NORM               ; normalize Rotmat1
 LDA XX15
 STA INWK+16            ; rotmat1x hi
 LDA XX15+1
 STA INWK+18            ; rotmat1y hi
 LDA XX15+2
 STA INWK+20            ; rotmat1z hi
 LDA INWK+12            ; rotmat0y hi
 STA Q                  ; = Fy
 LDA INWK+20            ; = Uz   \ rotmat1z hi
 JSR MULT12             ; R.S = P.A = Q * A = FyUz
 LDX INWK+14            ; = Fz	\ rotmat0z hi
 LDA INWK+18            ; = Uy	\ rotmat1y hi
 JSR TIS1               ; X.A =  -X*A  + (R.S)/96
 EOR #128               ; flip
 STA INWK+22            ; hsb(FzUy-FyUz)/96*255 \ rotmat2x hi
 LDA INWK+16            ; = Ux \ rotmat1x hi
 JSR MULT12             ; R.S = Q * A = FyUx
 LDX INWK+10            ; = Fx \ rotmat0x hi
 LDA INWK+20            ; = Uz \ rotmat1z hi
 JSR TIS1               ; X.A =  -X*A  + (R.S)/96
 EOR #128               ; flip
 STA INWK+24            ; rotmat2y hi
 LDA INWK+18            ; = Uy \ rotmat1y hi
 JSR MULT12             ; R.S = Q * A = FyUy
 LDX INWK+12            ; = Fy \ rotmat0y hi
 LDA INWK+16            ; = Ux \ rotmat1x hi
 JSR TIS1               ; X.A =  -X*A  + (R.S)/96
 EOR #128               ; flip
 STA INWK+26            ; rotmat2z hi
 LDA #0                 ; clear matrix lo's
 LDX #14                ; except 2z's

.TIL1                   ; counter X
 STA INWK+9,X
 DEX                    ; +23 and down
 DEX                    ; skip hi's
 BPL TIL1               ; loop X
 RTS
}

.TIS2                   ; Reduce Acc in NORM routine i.e. *96/Q
{
 TAY                    ; copy of Acc
 AND #127               ; ignore sign
 CMP Q
 BCS TI4                ; clean to +/- unity
 LDX #254               ; division roll
 STX T

.TIL2                   ; roll T
 ASL A
 CMP Q
 BCC P%+4               ; skip sbc
 SBC Q
 ROL T
 BCS TIL2               ; loop T
 LDA T

 LSR A
 LSR A                  ; result/4
 STA T
 LSR A                  ; result/8
 ADC T
 STA T                  ; T = 3/8*Acc (max = 96)
 TYA                    ; copy of Acc
 AND #128               ; sign
 ORA T
 RTS

.TI4                    ; clean to +/- unity
 TYA                    ; copy of Acc
 AND #128               ; sign
 ORA #96                ; +/- unity
 RTS
}

\ *****************************************************************************
\ Subroutine: TIS3
\
\ A = INWK(12*18+14*20, 10*16+14*20, 10*16+12*18) / INWK(10,12,14)
\ Ux,Uy,Uz = -(FyUy+FzUz, FxUx+FzUz, FxUx+FyUy)/ Fx,Fy,Fz
\ Xreg = index1, Yreg = index2, Acc = index3
\ *****************************************************************************

.TIS3                   ; visited by TI1,TI2
{
 STA P+2                ; store index3
 LDA INWK+10,X          ; rotmat0x,X hi
 STA Q
 LDA INWK+16,X          ; rotmat1x,X hi
 JSR MULT12             ; R.S = Q * rotmat1x
 LDX INWK+10,Y          ; rotmat0x,Y hi
 STX Q
 LDA INWK+16,Y          ; rotmat1x,Y hi
 JSR MAD                ; X.A = rotmat0x*rotmat1y + R.S

 STX P                  ; num lo
 LDY P+2                ; index3
 LDX INWK+10,Y          ; rotmat0x,A hi
 STX Q                  ; is denominator
 EOR #128               ; num -hi
}

\ *****************************************************************************
\ Subroutine: DVIDT
\
\ A=AP/Q \ their comment.  A = (P,A)/Q
\ *****************************************************************************

.DVIDT                  ; A=AP/Q \ their comment.  A = (P,A)/Q
{
 STA P+1                ; num hi
 EOR Q
 AND #128               ; sign bit
 STA T
 LDA #0
 LDX #16                ; counter 2 bytes
 ASL P                  ; num lo
 ROL P+1                ; num hi
 ASL Q                  ; denom
 LSR Q                  ; lose sign bit, clear carry

.DVL2                   ; counter X
 ROL A
 CMP Q
 BCC P%+4               ; skip sbc
 SBC Q
 ROL P                  ; result
 ROL P+1
 DEX
 BNE DVL2               ; loop X
 LDA P
 ORA T                  ; sign bit
 RTS                    ; -- end of TIDY 

}

\ *****************************************************************************
\ Save output/ELTF.bin
\ *****************************************************************************

PRINT "ELITE F"
PRINT "Assembled at ", ~CODE_F%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_F%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_F%

PRINT "S.ELTF ", ~CODE_F%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_F%
SAVE "output/ELTF.bin", CODE_F%, P%, LOAD%

\ *****************************************************************************
\ ELITE G
\ *****************************************************************************

CODE_G% = P%
LOAD_G% = LOAD% + P% - CODE%

\ *****************************************************************************
\ Subroutine: SHPPT
\
\ Ship plot as point from LL10
\ *****************************************************************************

.SHPPT                  ; ship plot as point from LL10
{
 JSR EE51               ; if bit3 set draw to erase lines in XX19 heap
 JSR PROJ               ; Project K+INWK(x,y)/z to K3,K4 for craft center
 ORA K3+1
 BNE nono
 LDA K4                 ; #Y Ymiddle not K4 when docked
 CMP #Y*2-2             ; #Y*2-2  96*2-2 screen height
 BCS nono               ; off top of screen
 LDY #2                 ; index for edge heap
 JSR Shpt               ; Ship is point, could end if nono-2
 LDY #6                 ; index for edge heap
 LDA K4                 ; #Y
 ADC #1                 ; 1 pixel uo
 JSR Shpt               ; Ship is point, could end if nono-2
 LDA #8                 ; set bit3 (to erase later) and plot as Dot
 ORA XX1+31             ; display/exploding state|missiles
 STA XX1+31
 LDA #8                 ; Dot uses #8 not U
 JMP LL81+2             ; skip first two edges on XX19 heap
 PLA                    ; nono-2 \ Changing return address
 PLA                    ; ending routine early
}

\ *****************************************************************************
\ Subroutine: nono
\
\ Clear bit3 nothing to erase in next round, no draw.
\ *****************************************************************************

.nono                   ; clear bit3 nothing to erase in next round, no draw.
{
 LDA #&F7               ; clear bit3
 AND XX1+31             ; display/exploding state|missiles
 STA XX1+31
 RTS
}

\ *****************************************************************************
\ Subroutine: Shpt
\
\ Ship is point at screen center
\ *****************************************************************************

.Shpt                   ; ship is point at screen center
{
 STA (XX19),Y
 INY
 INY                    ; next Y coord
 STA (XX19),Y
 LDA K3                 ; Xscreen-mid, not K3 when docked
 DEY                    ; 2nd X coord
 STA (XX19),Y
 ADC #3                 ; 1st X coord
 BCS nono-2             ; overflowed to right, remove 2 from stack and clear bit 3
 DEY
 DEY                    ; first entry in group of 4 added to ship line heap
 STA (XX19),Y
 RTS
}

\ *****************************************************************************
\ Subroutine: LL5
\
\ 2BSQRT Q=SQR(RQ) \ two-byte square root, R is hi, Q is lo.
\ *****************************************************************************

.LL5                    ; 2BSQRT Q=SQR(RQ) \ two-byte square root, R is hi, Q is lo.
{
 LDY R                  ; hi
 LDA Q
 STA S                  ; lo
 LDX #0                 ; result
 STX Q
 LDA #8                 ; counter
 STA T

.LL6                    ; counter T
 CPX Q
 BCC LL7                ; no carry
 BNE LL8                ; hop ne
 CPY #&40               ; hi
 BCC LL7                ; no carry

.LL8                    ; hop ne
 TYA
 SBC #&40
 TAY                    ; new hi
 TXA
 SBC Q
 TAX                    ; maybe carry into

.LL7                    ; no carry
 ROL Q                  ; result
 ASL S                  ; maybe carry into Yreg
 TYA
 ROL A
 TAY                    ; Yhi *2
 TXA
 ROL A
 TAX                    ; Xlo *2
 ASL S                  ; maybe carry into Yreg
 TYA
 ROL A
 TAY                    ; Yhi *2
 TXA
 ROL A
 TAX                    ; Xlo *2
 DEC T
 BNE LL6                ; loop T
 RTS                    ; Q left with root
}

\ *****************************************************************************
\ Subroutine: LL28
\
\ BFRDIV R=A*256/Q \ byte from remainder of division
\ *****************************************************************************

.LL28                   ; BFRDIV R=A*256/Q \ byte from remainder of division
{
 CMP Q                  ; is A >=  Q ?
 BCS LL2                ; if yes, answer too big for 1 byte, R=#&FF
 LDX #254               ; remainder R for AofQ *256/Q
 STX R                  ; div roll counter
}

.LL31                   ; roll R
{
 ASL A
 BCS LL29               ; hop to Reduce
 CMP Q
 BCC P%+4               ; skip sbc
 SBC Q
 ROL R
 BCS LL31               ; loop R
 RTS                    ; R left with remainder of division

.LL29                   ; Reduce
 SBC Q
 SEC
 ROL R
 BCS LL31               ; loop R
 RTS                    ; R left with remainder of division
}

.LL2                    ; answer too big for 1 byte, R=#&FF
{
 LDA #&FF
 STA R
 RTS
}

\ *****************************************************************************
\ Subroutine: LL38
\
\ BADD(S)A=R+Q(SA) \ byte add (subtract)   (Sign S)A = R + Q*(Sign from A^S)
\ *****************************************************************************

.LL38                   ; BADD(S)A=R+Q(SA) \ byte add (subtract)   (Sign S)A = R + Q*(Sign from A^S)
{
 EOR S                  ; sign of operator is A xor S
 BMI LL39               ; 1 byte subtraction
 LDA Q                  ; else addition, S already correct
 CLC
 ADC R
 RTS

.LL39                   ; 1 byte subtraction (S)A = R-Q
 LDA R
 SEC
 SBC Q
 BCC P%+4               ; sign of S needs correcting, hop over rts
 CLC
 RTS
 PHA                    ; store subtraction result
 LDA S
 EOR #128               ; flip
 STA S
 PLA                    ; restore subtraction result
 EOR #255
 ADC #1                 ; negate
 RTS
}

\ *****************************************************************************
\ Subroutine: LL51
\
\ XX12=XX15.XX16  each vector is 16-bit x,y,z
\ XX16_hsb[   1  3  5    highest XX16 done below is 5, then X taken up by 6, Y taken up by 2.
\             7  9 11
\	         13 15 17=0 ?]
\ *****************************************************************************

.LL51                   ; XX12=XX15.XX16  each vector is 16-bit x,y,z
{
 LDX #0
 LDY #0

.ll51                   ; counter X+=6 < 17  Y+=2
 LDA XX15               ; xmag
 STA Q
 LDA XX16,X
 JSR FMLTU              ; Acc= XX15 *XX16 /256 assume unsigned
 STA T
 LDA XX15+1
 EOR XX16+1,X
 STA S                  ; xsign
 LDA XX15+2             ; ymag
 STA Q
 LDA XX16+2,X
 JSR FMLTU              ; Acc= XX15 *XX16 /256 assume unsigned
 STA Q
 LDA T
 STA R                  ; move T to R
 LDA XX15+3             ; ysign
 EOR XX16+3,X
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 STA T
 LDA XX15+4             ; zmag
 STA Q
 LDA XX16+4,X
 JSR FMLTU              ; Acc= XX15 *XX16 /256 assume unsigned
 STA Q
 LDA T
 STA R                  ; move T to R
 LDA XX15+5             ; zsign
 EOR XX16+5,X
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 STA XX12,Y
 LDA S                  ; result sign
 STA XX12+1,Y
 INY
 INY                    ; Y +=2
 TXA
 CLC
 ADC #6
 TAX                    ; X +=6
 CMP #17                ; X finished?
 BCC ll51               ; loop for second half of matrix
 RTS
}

\ *****************************************************************************
\ Subroutine: LL25
\
\ Planet
\ *****************************************************************************

.LL25                   ; planet
{
 JMP PLANET
}

\ *****************************************************************************
\ Subroutine: LL9
\
\ Object ENTRY for displaying, including debris.
\ *****************************************************************************

.LL9                    ; object ENTRY for displaying, including debris.
{
 LDA TYPE               ; ship type
 BMI LL25               ; planet as bit7 set
 LDA #31                ; max visibility
 STA XX4
 LDA #32                ; mask for bit 5, exploding
 BIT XX1+31             ; display explosion state|missiles
 BNE EE28               ; bit5 set, explosion ongoing
 BPL EE28               ; bit7 clear, else Start blowing up!
 ORA XX1+31
 AND #&3F               ; clear bit7,6
 STA XX1+31
 LDA #0                 ; acceleration & pitch zeroed.
 LDY #28                ; byte #28 accel
 STA (INF),Y
 LDY #30                ; byte #30 rotz counter
 STA (INF),Y
 JSR EE51               ; if bit3 set erase old lines in XX19 heap
 LDY #1                 ; edge heap byte1
 LDA #18                ; counter for explosion radius
 STA (XX19),Y
 LDY #7                 ; Hull byte#7 explosion of ship type e.g. &2A
 LDA (XX0),Y
 LDY #2                 ; edge heap byte2
 STA (XX19),Y

\LDA XX1+32
\AND #&7F
\STA XX1+32

.EE55                   ; counter Y, 4 rnd bytes to edge heap
 INY                    ; #3 start
 JSR DORND
 STA (XX19),Y
 CPY #6                 ; bytes 3to6 = random bytes for seed
 BNE EE55               ; loop Y

.EE28                   ; bit5 set do explosion, or bit7 clear, dont kill.
 LDA XX1+8              ; sign of Z coord

.EE49                   ; In view?
 BPL LL10               ; hop over as object in front
}

.LL14                   ; Test to remove object
{
 LDA XX1+31             ; display explosion state|missiles
 AND #32                ; bit5 ongoing explosion?
 BEQ EE51               ; if no then if bit3 set erase old lines in XX19 heap
 LDA XX1+31             ; else exploding
 AND #&F7               ; clear bit3
 STA XX1+31
 JMP DOEXP              ; Explosion
}

.EE51                   ; if bit3 set draw lines in XX19 heap
{
 LDA #8                 ; mask for bit 3
 BIT XX1+31             ; exploding/display state|missiles
 BEQ LL10-1             ; if bit3 clear, just rts
 EOR XX1+31             ; else toggle bit3 to allow lines
 STA XX1+31
 JMP LL155              ; clear LINEstr. Draw lines in XX19 heap.

\LL24
 RTS                    ; needed by beq \ LL10-1 
}

.LL10                   ; object in front of you
{
 LDA XX1+7              ; zhi
 CMP #&C0               ; far in front
 BCS LL14               ; test to remove object
 LDA XX1                ; xlo
 CMP XX1+6              ; zlo
 LDA XX1+1              ; xhi
 SBC XX1+7              ; zhi, gives angle to object
 BCS LL14               ; test to remove object
 LDA XX1+3              ; ylo
 CMP XX1+6              ; zlo
 LDA XX1+4              ; yhi
 SBC XX1+7              ; zhi
 BCS LL14               ; test to remove object
 LDY #6                 ; Hull byte6, node gun*4
 LDA (XX0),Y
 TAX                    ; node heap index
 LDA #255               ; flag on node heap at gun
 STA XX3,X
 STA XX3+1,X
 LDA XX1+6              ; zlo
 STA T
 LDA XX1+7              ; zhi
 LSR A
 ROR T
 LSR A
 ROR T
 LSR A
 ROR T
 LSR A
 BNE LL13               ; hop as far
 LDA T
 ROR A                  ; bring in hi bit0
 LSR A
 LSR A                  ; small zlo
 LSR A                  ; updated visibility
 STA XX4
 BPL LL17               ; guaranteed hop to Draw wireframe

.LL13                   ; hopped to as far
 LDY #13                ; Hull byte#13, distance point at which ship becomes a dot
 LDA (XX0),Y
 CMP XX1+7              ; dot_distance >= z_hi will leave carry set
 BCS LL17               ; hop over to draw Wireframe
 LDA #32                ; mask bit5 exploding
 AND XX1+31             ; exploding/display state|missiles
 BNE LL17               ; hop over to Draw wireframe or exploding
 JMP SHPPT              ; else ship plot point, up.

.LL17                   ; draw Wireframe (including nodes exploding)
 LDX #5                 ; load rotmat into XX16

.LL15                   ; counter X
 LDA XX1+21,X
 STA XX16,X
 LDA XX1+15,X
 STA XX16+6,X
 LDA XX1+9,X
 STA XX16+12,X
 DEX
 BPL LL15               ; loop X
 LDA #197               ; comment here about NORM
 STA Q
 LDY #16

.LL21                   ; counter Y -=2
 LDA XX16,Y             ; XX16+0,Y
 ASL A                  ; get carry, only once.
 LDA XX16+1,Y
 ROL A
 JSR LL28               ; BFRDIV R=A*256/197
 LDX R
 STX XX16,Y
 DEY
 DEY                    ; Y -=2
 BPL LL21               ; loop Y
 LDX #8                 ; load craft coords into XX18

.ll91                   ; counter X
 LDA XX1,X
 STA XX18,X
 DEX
 BPL ll91               ; loop X

 LDA #255               ; last normal is always visible
 STA XX2+15
 LDY #12                ; Hull byte 12 =  normals*4
 LDA XX1+31
 AND #32                ; mask bit5 exploding
 BEQ EE29               ; no, only Some visible
 LDA (XX0),Y
 LSR A                  ; else do explosion needs all vertices
 LSR A                  ; /=4
 TAX                    ; Xreg = number of normals, faces
 LDA #&FF               ; all faces visible

.EE30                   ; counter X  for each face
 STA XX2,X
 DEX
 BPL EE30               ; loop X
 INX                    ; X = 0
 STX XX4                ; visibility = 0

.LL41                   ; visibilities now set in XX2,X Transpose matrix.
 JMP LL42               ; jump to transpose matrix

.EE29                   ; only Some visible  Yreg =Hull byte12, normals*4
 LDA (XX0),Y
 BEQ LL41               ; if no normals, visibilities now set in XX2,X Transpose matrix.
 STA XX20               ; normals*4
 LDY #18                ; Hull byte #18  normals scaled by 2^Q%
                        ; DtProd^XX2 \ their comment \ Dot product gives  normals' visibility in XX2
 LDA (XX0),Y
 TAX                    ; normals scaled by 2^X plus
 LDA XX18+7             ; z_hi

.LL90                   ; scaling object distance
 TAY                    ; z_hi
 BEQ LL91               ; object close/small, hop
 INX                    ; repeat INWK z brought closer, take X up
 LSR XX18+4             ; yhi
 ROR XX18+3             ; ylo
 LSR XX18+1             ; xhi
 ROR XX18               ; xlo
 LSR A                  ; zhi /=2
 ROR XX18+6             ; z_lo
 TAY                    ; zhi
 BNE LL90+3             ; again as z_hi too big

.LL91                   ; object close/small
 STX XX17               ; keep Scale required
 LDA XX18+8             ; last member of INWK copied over
 STA XX15+5             ; zsign 6 members
 LDA XX18
 STA XX15               ; xscaled
 LDA XX18+2
 STA XX15+1             ; xsign
 LDA XX18+3
 STA XX15+2             ; yscaled
 LDA XX18+5
 STA XX15+3             ; ysign
 LDA XX18+6
 STA XX15+4             ; zscaled
 JSR LL51               ; XX12=XX15.XX16  each vector is 16-bit x,y,z
 LDA XX12
 STA XX18               ; load result back in
 LDA XX12+1
 STA XX18+2             ; xsg
 LDA XX12+2
 STA XX18+3
 LDA XX12+3
 STA XX18+5             ; ysg
 LDA XX12+4
 STA XX18+6
 LDA XX12+5
 STA XX18+8             ; zsg

 LDY #4                 ; Hull byte#4 = lsb of offset to normals
 LDA (XX0),Y
 CLC                    ; lo
 ADC XX0
 STA V                  ; will point to start of normals
 LDY #17                ; Hull byte#17 = hsb of offset to normals
 LDA (XX0),Y
 ADC XX0+1
 STA V+1                ; hi of pointer to normals data
 LDY #0                 ; byte#0 of normal

.LL86                   ; counter Y/4 go through all normals
 LDA (V),Y
 STA XX12+1             ; byte#0
 AND #31                ; lower 5 bits are face visibility
 CMP XX4
 BCS LL87               ; >= XX4 visibility, skip over jump LL88
 TYA                    ; face*4 count
 LSR A                  ; else visible
 LSR A                  ; counter/4
 TAX                    ; Xreg is normal count
 LDA #255               ; visible face
 STA XX2,X
 TYA                    ; next face*4
 ADC #4                 ; +=4
 TAY                    ; Yreg +=4 is next normal
 JMP LL88               ; to near end of normal's visibility loop

.LL87                   ; normal visibility>= XX4
 LDA XX12+1             ; byte#0 of normal
 ASL A                  ; get sign y
 STA XX12+3
 ASL A                  ; get sign z
 STA XX12+5
 INY                    ; byte#1 of normal
 LDA (V),Y
 STA XX12               ; xnormal lo
 INY                    ; byte#2 of normal
 LDA (V),Y
 STA XX12+2             ; ynormal lo
 INY                    ; byte#3 of normal
 LDA (V),Y
 STA XX12+4             ; znormal lo
 LDX XX17               ; kept Scale required
 CPX #4                 ; is XX17 < 4 ?
 BCC LL92               ; scale required is Quite close

.LL143                  ; Face offset<<PV \ their comment \ far enough away, use XX18.
 LDA XX18               ; xlo
 STA XX15
 LDA XX18+2             ; xsg
 STA XX15+1
 LDA XX18+3             ; ylo
 STA XX15+2
 LDA XX18+5             ; ysg
 STA XX15+3
 LDA XX18+6             ; zlo
 STA XX15+4
 LDA XX18+8             ; zsg
 STA XX15+5
 JMP LL89               ; XX15(6) ready, down to START.

.ovflw                  ; overflow from below, reduce xx18+0,3,6
 LSR XX18               ; x_lo/2
 LSR XX18+6             ; z_lo/2
 LSR XX18+3             ; y_lo/2
 LDX #1                 ; scale finished

.LL92                   ; arrive if Quite close, with scale in Xreg.  Normals translate.
 LDA XX12               ; xnormal lo
 STA XX15
 LDA XX12+2             ; ynormal lo
 STA XX15+2
 LDA XX12+4             ; znormal lo

.LL93
 DEX                    ; scale--
 BMI LL94               ; exit, Scale done.
 LSR XX15               ; counter X
 LSR XX15+2             ; ynormal lo/2
 LSR A                  ; znormal lo/2
 DEX                    ; reduce scale
 BPL LL93+3             ; loop to lsr xx15

.LL94                   ; Scale done.
 STA R                  ; znormal  XX15+4
 LDA XX12+5             ; zsg
 STA S                  ; z_hi to translate
 LDA XX18+6             ; z_lo
 STA Q
 LDA XX18+8             ; zsg
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 BCS ovflw              ; up to overflow, reduce xx18+0,3,6

 STA XX15+4             ; new z
 LDA S                  ; maybe new sign
 STA XX15+5             ; zsg

 LDA XX15
 STA R                  ; xnormal
 LDA XX12+1             ; xsg
 STA S                  ; x_hi to translate

 LDA XX18               ; x_lo
 STA Q
 LDA XX18+2             ; xsg
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 BCS ovflw              ; up to overflow, reduce xx18+0,3,6
 STA XX15               ; new x
 LDA S                  ; maybe new sign
 STA XX15+1             ; xsg
 LDA XX15+2
 STA R                  ; ynormal
 LDA XX12+3             ; ysg
 STA S                  ; y_hi to translate
 LDA XX18+3             ; y_lo
 STA Q
 LDA XX18+5             ; ysg
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 BCS ovflw              ; up to overflow, reduce xx18+0,3,6
 STA XX15+2             ; new y
 LDA S                  ; maybe new sign
 STA XX15+3             ; ysg

.LL89                   ; START also arrive from LL143  Face offset<<PV  XX15(6) ready
                        ; Calculate 3D dot product  XX12 . XX15 for (x,y,z) 
 LDA XX12               ; xnormal lo
 STA Q
 LDA XX15
 JSR FMLTU              ; A=A*Q/256unsg
 STA T                  ; x-dot
 LDA XX12+1
 EOR XX15+1
 STA S                  ; x-sign
 LDA XX12+2             ; ynormal lo
 STA Q
 LDA XX15+2
 JSR FMLTU              ; A=A*Q/256unsg
 STA Q                  ; y-dot
 LDA T                  ; x-dot
 STA R
 LDA XX12+3             ; ysg
 EOR XX15+3
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 STA T                  ; xdot+ydot
 LDA XX12+4             ; znormal lo
 STA Q
 LDA XX15+4
 JSR FMLTU              ; A=A*Q/256unsg
 STA Q                  ; zdot
 LDA T
 STA R                  ; xdot+ydot
 LDA XX15+5
 EOR XX12+5             ; hi sign
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 PHA                    ; push xdot+ydot+zdot
 TYA                    ; normal_count *4 so far
 LSR A
 LSR A                  ; /=4
 TAX                    ; normal index
 PLA                    ; xdot+ydot+zdot
 BIT S                  ; maybe new sign
 BMI P%+4               ; if -ve then keep Acc
 LDA #0                 ; else face not visible
 STA XX2,X              ; face visibility
 INY                    ; Y now taken up by a total of 4

.LL88                   ; near end of normals visibility loop
 CPY XX20               ; number of normals*4
 BCS LL42               ; If Y >= XX20 all normals' visibilities set, onto Transpose.
 JMP LL86               ; loop normals visibility Y

                        ; -- All normals' visibilities now set in XX2,X
.LL42                   ; DO nodeX-Ycoords \ their comment  \  TrnspMat
 LDY XX16+2             ; Transpose Matrix
 LDX XX16+3
 LDA XX16+6
 STA XX16+2
 LDA XX16+7
 STA XX16+3
 STY XX16+6
 STX XX16+7
 LDY XX16+4
 LDX XX16+5
 LDA XX16+12
 STA XX16+4
 LDA XX16+13
 STA XX16+5
 STY XX16+12
 STX XX16+13
 LDY XX16+10
 LDX XX16+11
 LDA XX16+14
 STA XX16+10
 LDA XX16+15
 STA XX16+11
 STY XX16+14
 STX XX16+15

\XX16 got INWK 9..21..26 up at LL15  . The ROTMAT has 18 bytes, for 3x3 matrix
\XX16_lsb[   0  2  4    highest XX16 done below is 5, then X taken up by 6, Y taken up by 2.
\            6  8 10    
\	    12 14 16=0 ?]

 LDY #8                 ; Hull byte#8 = number of vertices *6
 LDA (XX0),Y
 STA XX20
 LDA XX0                ; pointer to ship type data
 CLC                    ; build
 ADC #20                ; vertex data fixed offset 
 STA V                  ; pointer to start of hull vertices
 LDA XX0+1
 ADC #0                 ; any carry
 STA V+1
 LDY #0                 ; index for XX3 heap
 STY CNT
}

.LL48                   ; Start loop on Nodes for visibility, each node has 4 faces associated with it.
{
 STY XX17               ; vertex*6 counter
 LDA (V),Y
 STA XX15               ; xlo
 INY                    ; vertex byte#1
 LDA (V),Y
 STA XX15+2
 INY                    ; vertex byte#2
 LDA (V),Y
 STA XX15+4
 INY                    ; vertex byte#3
 LDA (V),Y
 STA T                  ; sign bits of vertex
 AND #31                ; visibility
 CMP XX4
 BCC LL49-3             ; if yes jmp LL50, next vertex.
 INY                    ; vertex byte#4, first 2 faces
 LDA (V),Y
 STA P                  ; two 4-bit indices 0:15 into XX2 for 2 of the 4 normals
 AND #15                ; face 1
 TAX                    ; face visibility index
 LDA XX2,X
 BNE LL49               ; vertex is visible
 LDA P                  ; restore
 LSR A
 LSR A
 LSR A
 LSR A                  ; hi nibble
 TAX                    ; face 2
 LDA XX2,X
 BNE LL49               ; vertex is visible
 INY                    ; vertex byte#5, other 2 faces
 LDA (V),Y
 STA P                  ; two 4-bit indices 0:15 into XX2
 AND #15                ; face 3
 TAX                    ; face visibility index
 LDA XX2,X
 BNE LL49               ; vertex is visible
 LDA P                  ; restore
 LSR A
 LSR A
 LSR A
 LSR A                  ; hi nibble
 TAX                    ; face 4
 LDA XX2,X
 BNE LL49               ; vertex is visible
 JMP LL50               ; both arrive here \ LL49-3 \ next vertex.

                        ; This jump can only happen if got 4 zeros from XX2 normals visibility.
.LL49                   ; Else vertex is visible, update info on XX3 node heap.
 LDA T                  ; 4th byte read for vertex, sign bits.
 STA XX15+1
 ASL A                  ; y sgn
 STA XX15+3
 ASL A                  ; z sgn
 STA XX15+5
 JSR LL51               ; XX12=XX15.XX16   Rotated.
 LDA XX1+2              ; x-sign
 STA XX15+2
 EOR XX12+1             ; rotated xnode hi
 BMI LL52               ; hop as -ve x sign
 CLC                    ; else x +ve
 LDA XX12               ; rotated xnode lo
 ADC XX1                ; xorg lo
 STA XX15               ; new x
 LDA XX1+1              ; INWK+1
 ADC #0                 ; hi x
 STA XX15+1
 JMP LL53               ; Onto y

.LL52                   ; -ve x sign
 LDA XX1                ; xorg lo
 SEC
 SBC XX12               ; rotated xnode lo
 STA XX15               ; new x
 LDA XX1+1              ; INWK+1
 SBC #0                 ; hi x
 STA XX15+1
 BCS LL53               ; usually ok Onto y
 EOR #&FF               ; else fix x negative
 STA XX15+1
 LDA #1                 ; negate
 SBC XX15
 STA XX15
 BCC P%+4               ; skip x hi
 INC XX15+1
 LDA XX15+2
 EOR #128               ; flip xsg
 STA XX15+2

.LL53                   ; Both x signs arrive here, Onto y
 LDA XX1+5              ; y-sign
 STA XX15+5
 EOR XX12+3             ; rotated ynode hi
 BMI LL54               ; hop as -ve y sign
 CLC                    ; else y +ve
 LDA XX12+2             ; rotated ynode lo
 ADC XX1+3              ; yorg lo
 STA XX15+3             ; new y
 LDA XX1+4
 ADC #0                 ; hi y
 STA XX15+4
 JMP LL55               ; Onto z

.LL54                   ; -ve y sign
 LDA XX1+3              ; yorg lo
 SEC
 SBC XX12+2             ; rotated ynode lo
 STA XX15+3             ; new ylo
 LDA XX1+4
 SBC #0                 ; hi y

 STA XX15+4
 BCS LL55               ; usually ok Onto z
 EOR #255               ; else fix y negative
 STA XX15+4
 LDA XX15+3
 EOR #255               ; negate y lo
 ADC #1
 STA XX15+3
 LDA XX15+5
 EOR #128               ; flip ysg
 STA XX15+5
 BCC LL55               ; Onto z
 INC XX15+4

.LL55                   ; Both y signs arrive here, Onto z
 LDA XX12+5             ; rotated znode hi
 BMI LL56               ; -ve Z node
 LDA XX12+4             ; rotated znode lo
 CLC
 ADC XX1+6              ; zorg lo
 STA T                  ; z new lo
 LDA XX1+7
 ADC #0                 ; hi
 STA U                  ; z new hi
 JMP LL57               ; Node additions done, z = U.T case
}

\ *****************************************************************************
\ Subroutine: LL61
\
\ Doing additions and scalings for each visible node around here
\ *****************************************************************************

                        ; Doing additions and scalings for each visible node around here
.LL61                   ; Handling division R=A/Q for case further down
 LDX Q
 BEQ LL84               ; div by zero div error
 LDX #0

.LL63                   ; roll Acc count Xreg
 LSR A
 INX                    ; counts required will be stored in S
 CMP Q
 BCS LL63               ; loop back if Acc >= Q
 STX S
 JSR LL28               ; BFRDIV R=A*256/Q byte from remainder of division
 LDX S                  ; restore Xcount
 LDA R                  ; remainder

.LL64                   ; counter Xreg
 ASL A                  ; lo boost
 ROL U                  ; hi
 BMI LL84               ; bit7 set, overflowed, div error
 DEX                    ; bring X back down
 BNE LL64               ; loop X
 STA R                  ; remainder
 RTS

.LL84                   ; div error  R=U=#50
 LDA #50
 STA R
 STA U
 RTS

.LL62                   ; Arrive from LL65 just below, screen for -ve RU onto XX3 heap, index X=CNT
 LDA #128               ; x-screen mid-point
 SEC                    ; xcoord lo
 SBC R
 STA XX3,X
 INX                    ; hi
 LDA #0                 ; xcoord hi
 SBC U
 STA XX3,X
 JMP LL66               ; xccord shoved, go back down

.LL56                   ; Enter XX12+5 -ve Z node case  from above
 LDA XX1+6              ; z org lo
 SEC
 SBC XX12+4             ; rotated z node lo
 STA T
 LDA XX1+7              ; zhi
 SBC #0
 STA U
 BCC LL140              ; underflow, make node close
 BNE LL57               ; Enter Node additions done, UT=z
 LDA T                  ; restore z lo
 CMP #4                 ; >= 4 ?
 BCS LL57               ; zlo big enough, Enter Node additions done.

.LL140                  ; else make node close
 LDA #0                 ; hi
 STA U
 LDA #4                 ; lo
 STA T

.LL57                   ; Enter Node additions done, z=T.U set up from LL55
 LDA U                  ; z hi
 ORA XX15+1             ; x hi
 ORA XX15+4             ; y hi
 BEQ LL60               ; exit loop down once hi U rolled to 0
 LSR XX15+1
 ROR XX15
 LSR XX15+4
 ROR XX15+3
 LSR U                  ; z hi
 ROR T                  ; z lo
 JMP LL57               ; loop U

.LL60                   ; hi U rolled to 0, exited loop above.
 LDA T
 STA Q                  ; zdist lo
 LDA XX15               ; rolled x lo
 CMP Q
 BCC LL69               ; if xdist < zdist hop over jmp to small x angle
 JSR LL61               ; visit up  R = A/Q = x/z
 JMP LL65               ; hop over small xangle

.LL69                   ; small x angle
 JSR LL28               ; BFRDIV R=A*256/Q byte for remainder of division

.LL65                   ; both continue for scaling based on z
 LDX CNT                ; index for XX3 heap
 LDA XX15+2             ; sign of X dist
 BMI LL62               ; up, -ve Xdist, RU screen onto XX3 heap
 LDA R                  ; xscaled
 CLC                    ; xcoord lo to XX3 heap
 ADC #128               ; x screen mid-point
 STA XX3,X
 INX                    ; x hi onto node heap
 LDA U
 ADC #0                 ; any carry to hi
 STA XX3,X

.LL66                   ; also from LL62, XX3 node heap has xscreen node so far.
 TXA                    ; Onto y coord
 PHA                    ; push XX3 heap pointer
 LDA #0                 ; y hi = 0
 STA U
 LDA T
 STA Q                  ; zdist lo
 LDA XX15+3             ; rolled y low
 CMP Q
 BCC LL67               ; if ydist < zdist hop to small yangle

 JSR LL61               ; else visit up R = A/Q = y/z
 JMP LL68               ; hop over small y yangle

.LL70                   ; arrive from below, Yscreen for -ve RU onto XX3 node heap, index X=CNT
 LDA #Y                 ; #Y = #96 mid Yscreen \ also rts at LL70+1
 CLC                    ; ycoord lo to XX3 node heap
 ADC R                  ; yscaled
 STA XX3,X
 INX                    ; y hi to node heap
 LDA #0                 ; any carry to y hi
 ADC U
 STA XX3,X
 JMP LL50               ; down XX3 heap has yscreen node

.LL67                   ; Arrive from LL66 above if XX15+3 < Q \ small yangle
 JSR LL28               ; BFRDIV R=A*256/Q byte from remainder of division

.LL68                   ; -> &4CF5 both carry on, also arrive from LL66, yscaled based on z
 PLA                    ; restore
 TAX                    ; XX3 heap index
 INX                    ; take XX3 heap index up
 LDA XX15+5             ; rolled Ydist sign
 BMI LL70               ; up, -ve RU onto XX3 heap
 LDA #Y                 ; #Y = #96 Yscreen
 SEC                    ; subtracted yscaled and store on heap
 SBC R
 STA XX3,X
 INX                    ; y screen hi
 LDA #0                 ; any carry
 SBC U
 STA XX3,X

.LL50                   ; also from LL70, Also from  LL49-3. XX3 heap has yscreen, Next vertex.
 CLC                    ; reload XX3 heap index base
 LDA CNT
 ADC #4                 ; +=4, next 16bit xcoord,ycoord pair on XX3 heap
 STA CNT
 LDA XX17               ; vertex*6 count
 ADC #6                 ; +=6
 TAY                    ; Y taken up to next vertex
 BCS LL72               ; down Loaded if maxed out number of vertices (42)
 CMP XX20               ; number of vertices*6
 BCS LL72               ; done Loaded if all vertices done, exit loop
 JMP LL48               ; loop Y back to next vertex at transpose matrix

.LL72                   ; XX3 node heap already loaded with 16bit xy screen
 LDA XX1+31             ; display/exploding state|missiles
 AND #32                ; bit5 of mask
 BEQ EE31               ; if zero no explosion
 LDA XX1+31
 ORA #8                 ; else set bit3 to erase old line
 STA XX1+31
 JMP DOEXP              ; explosion

.EE31                   ; no explosion
 LDA #8                 ; mask bit 3 set of
 BIT XX1+31             ; exploding/display state|missiles
 BEQ LL74               ; clear is hop to do New lines
 JSR LL155              ; else erase lines in XX19 heap at LINEstr down
 LDA #8                 ; set bit3, as new lines

.LL74                   ; do New lines
 ORA XX1+31
 STA XX1+31
 LDY #9                 ; Hull byte#9, number of edges
 LDA (XX0),Y
 STA XX20               ; number of edges
 LDY #0                 ; ship lines heap offset to 0 for XX19
 STY U
 STY XX17               ; edge counter
 INC U                  ; ship lines heap offset = 1
 BIT XX1+31
 BVC LL170              ; bit6 of display state clear (laser not firing) \ Calculate new lines
 LDA XX1+31
 AND #&BF               ; else laser is firing, clear bit6.
 STA XX1+31
 LDY #6                 ; Hull byte#6, gun vertex*4
 LDA (XX0),Y
 TAY                    ; index to gun on XX3 heap
 LDX XX3,Y
 STX XX15               ;  x1 lo
 INX                    ; was heap entry updated from #255?
 BEQ LL170              ; skip the rest (laser node not visible)
 LDX XX3+1,Y
 STX XX15+1             ;  x1 hi
 INX                    ; was heap entry updated from #255?
 BEQ LL170              ; skip the rest (laser node not visible)
 LDX XX3+2,Y
 STX XX15+2             ; y1 lo
 LDX XX3+3,Y
 STX XX15+3             ; y1 hi
 LDA #0                 ; x2 lo.hi = 0
 STA XX15+4
 STA XX15+5
 STA XX12+1             ; y2 high = 0
 LDA XX1+6              ; z ship lo
 STA XX12               ; y2 low = z-lo
 LDA XX1+2              ; xship-sgn
 BPL P%+4               ; skip dec
 DEC XX15+4             ; else x2 lo =#255 to right across screen
 JSR LL145              ; clip test on XX15 XX12 vector
 BCS LL170              ; if carry set skip the rest (laser not firing)
 LDY U                  ; ship lines heap offset
 LDA XX15               ; push (now clipped) to clipped lines ship heap
 STA (XX19),Y
 INY
 LDA XX15+1             ; Y1
 STA (XX19),Y
 INY
 LDA XX15+2             ; X2
 STA (XX19),Y
 INY
 LDA XX15+3             ; Y2
 STA (XX19),Y
 INY
 STY U                  ; ship lines heap offset updated

.LL170                  ; (laser not firing) \ Calculate new lines	\ their comment
 LDY #3                 ; Hull byte#3 edges lo
 CLC                    ; build base pointer
 LDA (XX0),Y
 ADC XX0
 STA V                  ; is pointer to where edges data start
 LDY #16                ; Hull byte #16 edges hi
 LDA (XX0),Y
 ADC XX0+1
 STA V+1
 LDY #5                 ; Hull byte#5 is 4*MAXLI + 1, for ship lines stack
 LDA (XX0),Y
 STA T1                 ; 4*MAXLI + 1, edge counter limit.
 LDY XX17               ; edge counter

.LL75                   ; count Visible edges
 LDA (V),Y              ; edge data byte#0
 CMP XX4                ; visibility
 BCC LL78               ; edge not visible
 INY
 LDA (V),Y              ; edge data byte#1
 INY                    ; Y = 2
 STA P                  ; store byte#1
 AND #15
 TAX                    ; lower 4 bits are face1
 LDA XX2,X              ; face visibility
 BNE LL79               ; hop down to Visible edge
 LDA P                  ; restore byte#1
 LSR A
 LSR A
 LSR A
 LSR A                  ; /=16 upper nibble
 TAX                    ; upper 4 bits are face2
 LDA XX2,X              ; face visibility
 BEQ LL78               ; edge not visible

.LL79                   ; Visible edge
 LDA (V),Y              ; edge data byte#2
 TAX                    ; index into node heap for first node of edge
 INY                    ; Y = 3
 LDA (V),Y              ; edge data byte#3
 STA Q                  ; index into node heap for other node of edge
 LDA XX3+1,X
 STA XX15+1             ; x1 hi
 LDA XX3,X
 STA XX15               ; x1 lo
 LDA XX3+2,X
 STA XX15+2             ; y1 lo
 LDA XX3+3,X
 STA XX15+3             ; y1 hi
 LDX Q                  ; other index into node heap for second node
 LDA XX3,X
 STA XX15+4             ; x2 lo
 LDA XX3+3,X
 STA XX12+1             ; y2 hi
 LDA XX3+2,X
 STA XX12               ; y2 lo
 LDA XX3+1,X
 STA XX15+5             ; x2 hi
 JSR LL147              ; CLIP2, take care of swop and clips
 BCS LL78               ; jmp LL78 edge not visible

.LL80                   ; Shove visible edge onto XX19 ship lines heap counter U
 LDY U                  ; clipped edges heap index
 LDA XX15               ; X1
 STA (XX19),Y
 INY
 LDA XX15+1             ; Y1
 STA (XX19),Y
 INY
 LDA XX15+2             ; X2
 STA (XX19),Y
 INY
 LDA XX15+3             ; Y2
 STA (XX19),Y
 INY
 STY U                  ; clipped ship lines heap index
 CPY T1                 ; >=  4*MAXLI + 1 counter limit
 BCS LL81               ; hop over jmp to Exit edge data loop

.LL78                   ; also arrive here if Edge not visible, loop next data edge.
 INC XX17               ; edge counter
 LDY XX17
 CPY XX20               ; number of edges
 BCS LL81               ; hop over jmp to Exit edge data loop
 LDY #0                 ; else next edge
 LDA V
 ADC #4                 ; take edge data pointer up to next edge
 STA V
 BCC ll81               ; skip inc hi
 INC V+1

.ll81                   ; skip inc hi
 JMP LL75               ; Loop Next Edge

.LL81                   ; Exited edge data loop
 LDA U                  ; clipped ship lines heap index for (XX19),Y
 LDY #0                 ; first entry in ship edges heap is number of bytes
 STA (XX19),Y

.LL155                  ; CLEAR LINEstr visited by EE31 when XX3 heap ready to draw/erase lines in XX19 heap.
 LDY #0                 ; number of bytes
 LDA (XX19),Y
 STA XX20               ; valid length of heap XX19
 CMP #4                 ; if < 4 then
 BCC LL118-1            ; rts
 INY                    ; #1

.LL27                   ; counter Y, Draw clipped lines in XX19 ship lines heap
 LDA (XX19),Y
 STA XX15               ; X1
 INY
 LDA (XX19),Y
 STA XX15+1             ; Y1
 INY
 LDA (XX19),Y
 STA XX15+2             ; X2
 INY
 LDA (XX19),Y
 STA XX15+3             ; Y2
 JSR LL30               ; draw line using (X1,Y1), (X2,Y2)
 INY                    ; +=4
 CPY XX20               ; valid number of edges in heap XX19
 BCC LL27               ; loop Y
\LL82
 RTS                    ; --- Wireframe end  \ LL118-1

\ *****************************************************************************
\ Subroutine: LL118
\
\ Trim XX15,XX15+2 to screen grad=XX12+2 for CLIP
\ *****************************************************************************

.LL118                  ; Trim XX15,XX15+2 to screen grad=XX12+2 for CLIP
{
 LDA XX15+1             ; x1 hi
 BPL LL119              ; x1 hi+ve skip down
 STA S                  ; else x1 hi -ve
 JSR LL120              ; X1<0 \ their comment \ X.Y = x1_lo.S *  M/256
 TXA                    ; step Y1 lo
 CLC
 ADC XX15+2             ; Y1 lo 
 STA XX15+2
 TYA                    ; step Y1 hi
 ADC XX15+3             ; Y1 hi
 STA XX15+3
 LDA #0                 ; xleft min
 STA XX15               ; X1 lo 
 STA XX15+1             ; X1 = 0
 TAX                    ; Xreg = 0, will skip to Ytrim

.LL119                  ; x1 hi +ve from LL118
 BEQ LL134              ; if x1 hi = 0 skip to Ytrim
 STA S                  ; else x1 hi > 0
 DEC S                  ; x1 hi-1
 JSR LL120              ; X1>255 \ their comment \ X.Y = x1lo.S *  M/256
 TXA                    ; step Y1 lo
 CLC
 ADC XX15+2             ; Y1 lo 
 STA XX15+2
 TYA                    ; step Y1 hi
 ADC XX15+3             ; Y1 hi
 STA XX15+3
 LDX #&FF               ; xright max
 STX XX15               ; X1 lo = 255
 INX                    ; = 0
 STX XX15+1             ; X1 hi

.LL134                  ; Ytrim
 LDA XX15+3             ; y1 hi
 BPL LL135              ; y1 hi +ve
 STA S                  ; else y1 hi -ve
 LDA XX15+2             ; y1 lo
 STA R                  ; Y1<0 their comment
 JSR LL123              ; X.Y=R.S*256/M (M=grad.)   \where 256/M is gradient
 TXA                    ; step X1 lo
 CLC
 ADC XX15               ; X1 lo
 STA XX15
 TYA                    ; step X1 hi
 ADC XX15+1             ; X1 hi
 STA XX15+1
 LDA #0                 ; Y bottom min
 STA XX15+2             ; Y1 lo
 STA XX15+3             ; Y1 hi = 0

.LL135                  ; y1 hi +ve from LL134
\BNE LL139
 LDA XX15+2             ; Y1 lo
 SEC
 SBC #Y*2               ; #Y*2  screen y height
 STA R                  ; Y1>191 their comment
 LDA XX15+3             ; Y1 hi
 SBC #0
 STA S
 BCC LL136              ; failed, rts

.LL139
 JSR LL123              ; X.Y=R.S*256/M (M=grad.)   \where 256/M is gradient
 TXA                    ; step X1 lo
 CLC
 ADC XX15               ; X1 lo
 STA XX15
 TYA                    ; step X1 hi
 ADC XX15+1             ; X1 hi
 STA XX15+1
 LDA #Y*2-1             ; #Y*2-1 = y top max
 STA XX15+2             ; Y1 lo
 LDA #0                 ; Y1 hi = 0
 STA XX15+3             ; Y1 = 191

.LL136                  ; rts
 RTS                    ; -- trim for CLIP done
}

\ *****************************************************************************
\ Subroutine: LL120
\
\ X.Y=x1lo.S*M/256  	\ where M/256 is gradient
\ *****************************************************************************

.LL120                  ; X.Y=x1lo.S*M/256  	\ where M/256 is gradient
{
 LDA XX15               ; x1 lo
 STA R

\.LL120
 JSR LL129              ; RS = abs(x1=RS) and return with
 PHA                    ; store Acc = hsb x1 EOR quadrant_info, Q = (1/)gradient
 LDX T                  ; steep toggle = 0 or FF for steep/shallow down
 BNE LL121              ; down Steep
}

.LL122                  ; else Shallow return step, also arrive from LL123 for steep stepX
{
 LDA #0
 TAX
 TAY                    ; all = 0 at start
 LSR S                  ; hi /=2
 ROR R                  ; lo /=2
 ASL Q                  ; double 1/gradient
 BCC LL126              ; hop first half of loop

.LL125                  ; roll Q up
 TXA                    ; increase step
 CLC
 ADC R
 TAX                    ; lo
 TYA                    ; hi
 ADC S
 TAY                    ; hi

.LL126                  ; first half of loop done
 LSR S                  ; hi /=2
 ROR R                  ; lo /=2
 ASL Q                  ; double 1/gradient
 BCS LL125              ; if gradient not too small, loop Q
 BNE LL126              ; half loop as Q not emptied yet.
 PLA                    ; restore quadrant info
 BPL LL133              ; flip XY sign
 RTS
}

\ *****************************************************************************
\ Subroutine: LL123
\
\ X.Y=R.S*256/M (M=grad.)	\ where 256/M is gradient
\ *****************************************************************************

.LL123                  ; X.Y=R.S*256/M (M=grad.)	\ where 256/M is gradient
{
 JSR LL129              ; RS = abs(y1=RS) and return with
 PHA                    ; store  Acc = hsb x1 EOR hi, Q = (1/)gradient
 LDX T                  ; steep toggle = 0 or FF for steep/shallow up
 BNE LL122              ; up Shallow
}

.LL121                  ; T = #&FF for Steep return stepY, shallow stepX
{
 LDA #255
 TAY
 ASL A                  ; #&FE
 TAX                    ; Step X.Y= &FFFE at start

.LL130                  ; roll Y
 ASL R                  ; lo *=2
 ROL S                  ; hi *=2
 LDA S
 BCS LL131              ; if S overflowed skip Q test and do subtractions
 CMP Q
 BCC LL132              ; if S <  Q = 256/gradient skip subtractions

.LL131                  ; skipped Q test
 SBC Q
 STA S                  ; lo
 LDA R
 SBC #0                 ; hi
 STA R
 SEC

.LL132                  ; skipped subtractions
 TXA                    ; increase step
 ROL A
 TAX                    ; stepX lo
 TYA
 ROL A
 TAY                    ; stepX hi
 BCS LL130              ; loop Y if bit fell out of Y
 PLA                    ; restore quadrant info
 BMI LL128              ; down rts
}

.LL133                  ; flip XY sign, quadrant info +ve in LL120 arrives here too
{
 TXA
 EOR #&FF
\CLC
 ADC #1
 TAX                    ; flip sign of x
 TYA
 EOR #&FF
 ADC #0
 TAY                    ; flip sign of y
}

.LL128
{
 RTS
}

\ *****************************************************************************
\ Subroutine: LL129
\
\ RS = abs(RS) and return Acc = hsb x1 EOR hi, Q = (1/)gradient
\ *****************************************************************************

.LL129                  ; RS = abs(RS) and return Acc = hsb x1 EOR hi, Q = (1/)gradient
{
 LDX XX12+2             ; gradient
 STX Q
 LDA S                  ; hi
 BPL LL127              ; hop to eor
 LDA #0                 ; else flip sign of R
 SEC
 SBC R
 STA R
 LDA S
 PHA                    ; push old S
 EOR #255               ; flip S
 ADC #0
 STA S
 PLA                    ; pull old S for eor

.LL127
 EOR XX12+3             ; Acc ^= quadrant info
 RTS                    ; -- CLIP, bounding box is now done,
}

\ *****************************************************************************
\ Subroutine: LL145
\
\ CLIP  XX15 XX12 line
\ *****************************************************************************

.LL145                  ; -> &4E19  CLIP  XX15 XX12 line
{
                        ; also called by BLINE, waiting for (X1,Y1), (X2,Y2) to draw a line.
                        ; Before clipping,  XX15(0,1) was x1.  XX15(2,3) was y1. XX15(4,5) was x2. XX12(0,1) was y2.
 LDA #0
 STA SWAP
 LDA XX15+5             ; x2 hi
}

.LL147                  ; CLIP2 arrives from LL79 to do swop and clip
{
 LDX #Y*2-1             ; #Y*2-1 yClip = screen height
 ORA XX12+1             ; y2 hi
 BNE LL107              ; skip yClip
 CPX XX12               ; is screen hight < y2 lo ?
 BCC LL107              ; if yes, skip yClip
 LDX #0                 ; else yClip = 0

.LL107                  ; skipped yClip
 STX XX13               ; yClip
 LDA XX15+1             ; x1 hi
 ORA XX15+3             ; y1 hi
 BNE LL83               ; no hi bits in coord 1 present
 LDA #Y*2-1             ; #Y*2-1  screen height
 CMP XX15+2             ; y1 lo
 BCC LL83               ; if screen height < y1 lo skip A top
 LDA XX13               ; yClip
 BNE LL108              ; hop down, yClip not zero

.LL146                  ; Finished clipping, Shuffle XX15 down to (X1,Y1) (X2,Y2)
 LDA XX15+2             ; y1 lo
 STA XX15+1             ; new Y1
 LDA XX15+4             ; x2 lo
 STA XX15+2             ; new X2
 LDA XX12               ; y2 lo
 STA XX15+3             ; new Y2
 CLC                    ; valid to plot is in XX15(0to3)
 RTS                    ; 2nd pro different, it swops based on swop flag around here.

.LL109                  ; clipped line Not visible
 SEC
 RTS

.LL108                  ; arrived as yClip not zero in LL107 clipping
 LSR XX13               ; yClip = Ymid

.LL83                   ; also arrive from LL107 if bits in hi present or y1_lo > screen height, A top
 LDA XX13               ; yClip
 BPL LL115              ; yClip < 128
 LDA XX15+1             ; x1 hi
 AND XX15+5             ; x2 hi
 BMI LL109              ; clipped line Not visible
 LDA XX15+3             ; y1 hi
 AND XX12+1             ; y2 hi
 BMI LL109              ; clipped line Not visible
 LDX XX15+1             ; x1 hi
 DEX
 TXA                    ; Acc = x1 hi -1
 LDX XX15+5             ; x2 hi
 DEX
 STX XX12+2             ; x2 hi --
 ORA XX12+2             ; (x1 hi -1) or (x2 hi -1)
 BPL LL109              ; clipped line not visible
 LDA XX15+2             ; y1 lo
 CMP #Y*2               ; #Y*2  screen height, maybe carry set
 LDA XX15+3             ; y1 hi
 SBC #0                 ; any carry
 STA XX12+2             ; y1 hi--
 LDA XX12               ; y2 lo
 CMP #Y*2               ; #Y*2 screen height, maybe carry set
 LDA XX12+1             ; y2 hi
 SBC #0                 ; any carry
 ORA XX12+2             ; (y1 hi -1) or (y2 hi -1)
 BPL LL109              ; clipped line Not visible

.LL115                  ; also arrive from LL83 with yClip < 128 need to trim.
 TYA                    ; index for edge data
 PHA                    ; protect offset
 LDA XX15+4             ; x2 lo
 SEC
 SBC XX15               ; x1 lo
 STA XX12+2             ; delta_x lo
 LDA XX15+5             ; x2 hi
 SBC XX15+1             ; x1 hi
 STA XX12+3             ; delta_x hi
 LDA XX12               ; y2 lo
 SEC
 SBC XX15+2             ; y1 lo
 STA XX12+4             ; delta_y lo
 LDA XX12+1             ; y2 hi
 SBC XX15+3             ; y1 hi
 STA XX12+5             ; delta_y hi
 EOR XX12+3             ; delta_x hi
 STA S                  ; quadrant relationship for gradient
 LDA XX12+5             ; delta_y hi
 BPL LL110              ; hop down if delta_y positive
 LDA #0                 ; else flip sign of delta_y
 SEC                    ; delta_y lo
 SBC XX12+4
 STA XX12+4
 LDA #0                 ; delta_y hi
 SBC XX12+5
 STA XX12+5

.LL110                  ; delta_y positive
 LDA XX12+3             ; delta_x hi
 BPL LL111              ; hop down if positive to GETgrad
 SEC                    ; else flip sign of delta_x
 LDA #0                 ; delta_x lo
 SBC XX12+2
 STA XX12+2
 LDA #0                 ; Acc will have delta_x hi +ve
 SBC XX12+3

                        ; GETgrad get Gradient for trimming
.LL111                  ; roll Acc  delta_x hi
 TAX                    ; delta_x hi
 BNE LL112              ; skip if delta_x hi not zero
 LDX XX12+5             ; delta_y hi
 BEQ LL113              ; Exit when both delta hi zero

.LL112                  ; skipped as delta_x hi not zero
 LSR A                  ; delta_x hi/=2
 ROR XX12+2             ; delta_x lo/=2

 LSR XX12+5             ; delta_y hi/=2
 ROR XX12+4             ; delta_y lo/=2
 JMP LL111              ; loop GETgrad

.LL113                  ; Exited as both delta hi zero for trimming
 STX T                  ; delta_y hi = 0
 LDA XX12+2             ; delta_x lo
 CMP XX12+4             ; delta_y lo
 BCC LL114              ; hop to STEEP as x < y
 STA Q                  ; else shallow, Q = delta_x lo
 LDA XX12+4             ; delta_y lo
 JSR LL28               ; BFRDIV R=A*256/Q = delta_y / delta_x

                        ; Use Y/X grad. \ as not steep
 JMP LL116              ; gradient now known, go a few lines down

.LL114                  ; else STEEP
 LDA XX12+4             ; delta_y lo
 STA Q
 LDA XX12+2             ; delta_x lo
 JSR LL28               ; BFRDIV R=A*256/Q = delta_x / delta_y

                        ; Use X/Y grad.
 DEC T                  ; steep toggle updated T = #&FF

.LL116                  ; arrive here for both options with known gradient
 LDA R                  ; gradient
 STA XX12+2
 LDA S                  ; quadrant info
 STA XX12+3
 LDA XX13
 BEQ LL138              ; yClip = 0 or 191?, skip bpl
 BPL LLX117             ; yClip+ve, swop nodes

.LL138                  ; yClip = 0 or or >127   need to fit x1,y1 into bounding box
 JSR LL118              ; Trim XX15,XX15+2 to screen grad=XX12+2
 LDA XX13
 BPL LL124              ; yClip+ve, finish clip

.LL117                  ; yClip > 127
 LDA XX15+1             ; x1 hi
 ORA XX15+3             ; y1 hi
 BNE LL137              ; some hi bits present, no line.
 LDA XX15+2             ; y1 lo
 CMP #Y*2               ; #Y*2  Yscreen full height
 BCS LL137              ; if y1 lo >= Yscreen,  no line.

.LLX117                 ; yClip+ve from LL116, swop nodes then trim nodes, XX12+2 = gradient, XX12+3 = quadrant info.
 LDX XX15               ; x1 lo
 LDA XX15+4             ; x2 lo
 STA XX15
 STX XX15+4
 LDA XX15+5             ; x2 hi
 LDX XX15+1             ; x1 hi
 STX XX15+5
 STA XX15+1
 LDX XX15+2             ; Onto swopping y
 LDA XX12               ; y2 lo
 STA XX15+2
 STX XX12
 LDA XX12+1             ; y2 hi
 LDX XX15+3             ; y1 hi
 STX XX12+1
 STA XX15+3             ; finished swop of (x1 y1) and (x2 y2)
 JSR LL118              ; Trim XX15,XX15+2 to screen grad=XX12+2
 DEC SWAP

.LL124                  ; also yClip+ve from LL138, finish clip
 PLA                    ; restore ship edge index
 TAY
 JMP LL146              ; up, Finished clipping, Shuffle XX15 down to (x1,y1) (x2,y2)

.LL137                  ; no line
 PLA                    ; restore ship edge index
 TAY
 SEC                    ; not visible
 RTS                    ; -- Finished clipping

F% = P%
}

\ *****************************************************************************
\ Save output/ELTG.bin
\ *****************************************************************************

PRINT "ELITE G"
PRINT "Assembled at ", ~CODE_G%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_G%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_G%

PRINT "S.ELTG ", ~CODE_G%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_G%
SAVE "output/ELTG.bin", CODE_G%, P%, LOAD%

\ *****************************************************************************
\ Variable: checksum0
\
\ 
\ *****************************************************************************

.checksum0
{
SKIP 1
}

\ *****************************************************************************
\ ELITE SHIPS SOURCE
\ *****************************************************************************

CODE_SHIPS% = P%
LOAD_SHIPS% = LOAD% + P% - CODE%

\ *****************************************************************************
\ Variable: XX21
\
\ Ships lookup table.
\ *****************************************************************************

\ The following lookup table points to the individual ship definitions below.

.XX21
 EQUW SHIP1                         ;         1 = Sidewinder
 EQUW SHIP2                         ; COPS =  2 = Viper
 EQUW SHIP3                         ; MAM  =  3 = Mamba
 EQUW &7F00                         ;         4 = &7F00
 EQUW SHIP5                         ;         5 = Points to Cobra Mk III
 EQUW SHIP6                         ; THG  =  6 = Thargoid
 EQUW SHIP5                         ; CYL  =  7 = Cobra Mk III
 EQUW SHIP8                         ; SST  =  8 = Coriolis space station
 EQUW SHIP9                         ; MSL  =  9 = Missile
 EQUW SHIP10                        ; AST  = 10 = Asteroid
 EQUW SHIP11                        ; OIL  = 11 = Cargo
 EQUW SHIP12                        ; TGL  = 12 = Thargon
 EQUW SHIP13                        ; ESC  = 13 = Escape pod

\ *****************************************************************************
\ Ships in Elite
\ *****************************************************************************
\
\ For each ship definition below, the first 20 bytes define the following:
\
\ Byte #0       High nibble determines cargo type if scooped, 0 = not scoopable
\               Lower nibble determines maximum number of bits of debris shown
\               when destroyed
\ Byte #1-2     Area of ship that can be locked onto by a missle (lo, hi)
\ Byte #3       Edges data offset lo (offset is from byte #0)
\ Byte #4       Faces data offset lo (offset is from byte #0)
\ Byte #5       Maximum heap size for plotting ship = 1 + 4 * max. no of
\               visible edges
\ Byte #6       Number * 4 of the vertex used for gun spike, if applicable
\ Byte #7       Explosion count = 4 * n + 6, where n = number of vertices used
\               as origins for explosion dust
\ Byte #8       Number of vertices * 6
\ Byte #10-11   Bounty awarded in Cr * 10 (lo, hi)
\ Byte #12      Number of faces * 4
\ Byte #13      Beyond this distance, show this ship as a dot
\ Byte #14      Maximum energy/shields
\ Byte #15      Maximum speed
\ Byte #16      Edges data offset hi (if this is negative (&FF) it points to
\               another ship's edge net)
\ Byte #17      Faces data offset hi
\ Byte #18      Q%: Normals are scaled by 2^Q% to make large objects' normals
\               flare out further away (see EE29)
\ Byte #19      %00 lll mmm, where bits 0-2 = number of missiles,
\               bits 3-5 = laser power

\ *****************************************************************************
\ Variable: SHIP1
\
\ Sidewinder ship definition
\ *****************************************************************************

.SHIP1
 EQUB &00
 EQUB &81, &10
 EQUB &50
 EQUB &8C
 EQUB &3D
 EQUB &00                           ; gun vertex = 0
 EQUB &1E
 EQUB &3C                           ; number of vertices = &3C / 6 = 10
 EQUB &0F                           ; number of edges = &0F = 15
 EQUB &32, &00                      ; bounty = &0032 = 50
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &14
 EQUB &46
 EQUB &25
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB &10                           ; %10000, laser = 2, missiles = 0

 EQUB &20, &00, &24, &9F, &10, &54  ; vertices data (10*6)
 EQUB &20, &00, &24, &1F, &20, &65
 EQUB &40, &00, &1C, &3F, &32, &66
 EQUB &40, &00, &1C, &BF, &31, &44
 EQUB &00, &10, &1C, &3F, &10, &32

 EQUB &00, &10, &1C, &7F, &43, &65
 EQUB &0C, &06, &1C, &AF, &33, &33
 EQUB &0C, &06, &1C, &2F, &33, &33
 EQUB &0C, &06, &1C, &6C, &33, &33
 EQUB &0C, &06, &1C, &EC, &33, &33

 EQUB &1F, &50, &00, &04            ; edges data (15*4)
 EQUB &1F, &62, &04, &08
 EQUB &1F, &20, &04, &10
 EQUB &1F, &10, &00, &10
 EQUB &1F, &41, &00, &0C

 EQUB &1F, &31, &0C, &10
 EQUB &1F, &32, &08, &10
 EQUB &1F, &43, &0C, &14
 EQUB &1F, &63, &08, &14
 EQUB &1F, &65, &04, &14

 EQUB &1F, &54, &00, &14
 EQUB &0F, &33, &18, &1C
 EQUB &0C, &33, &1C, &20
 EQUB &0C, &33, &18, &24
 EQUB &0C, &33, &20, &24

 EQUB &1F, &00, &20, &08            ; faces data (7*4)
 EQUB &9F, &0C, &2F, &06
 EQUB &1F, &0C, &2F, &06
 EQUB &3F, &00, &00, &70
 EQUB &DF, &0C, &2F, &06

 EQUB &5F, &00, &20, &08
 EQUB &5F, &0C, &2F, &06

\ *****************************************************************************
\ Variable: SHIP2
\
\ Viper ship definition
\ *****************************************************************************

.SHIP2
 EQUB &00
 EQUB &F9, &15
 EQUB &6E
 EQUB &BE
 EQUB &4D
 EQUB &00                           ; gun vertex = 0
 EQUB &2A
 EQUB &5A                           ; number of vertices = &5A / 6 = 15
 EQUB &14                           ; number of edges = &14 = 20
 EQUB &00, &00                      ; bounty = 0
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &17
 EQUB &78
 EQUB &20
 EQUB &00
 EQUB &00
 EQUB &01
 EQUB &11                           ; %10001, laser = 2, missiles = 1

 EQUB &00, &00, &48, &1F, &21, &43  ; vertices data (15*6)
 EQUB &00, &10, &18, &1E, &10, &22
 EQUB &00, &10, &18, &5E, &43, &55
 EQUB &30, &00, &18, &3F, &42, &66
 EQUB &30, &00, &18, &BF, &31, &66

 EQUB &18, &10, &18, &7E, &54, &66
 EQUB &18, &10, &18, &FE, &35, &66
 EQUB &18, &10, &18, &3F, &20, &66
 EQUB &18, &10, &18, &BF, &10, &66
 EQUB &20, &00, &18, &B3, &66, &66

 EQUB &20, &00, &18, &33, &66, &66
 EQUB &08, &08, &18, &33, &66, &66
 EQUB &08, &08, &18, &B3, &66, &66
 EQUB &08, &08, &18, &F2, &66, &66
 EQUB &08, &08, &18, &72, &66, &66

 EQUB &1F, &42, &00, &0C            ; edges data (20*4)
 EQUB &1E, &21, &00, &04
 EQUB &1E, &43, &00, &08
 EQUB &1F, &31, &00, &10
 EQUB &1E, &20, &04, &1C

 EQUB &1E, &10, &04, &20
 EQUB &1E, &54, &08, &14
 EQUB &1E, &53, &08, &18
 EQUB &1F, &60, &1C, &20
 EQUB &1E, &65, &14, &18

 EQUB &1F, &61, &10, &20
 EQUB &1E, &63, &10, &18
 EQUB &1F, &62, &0C, &1C
 EQUB &1E, &46, &0C, &14
 EQUB &13, &66, &24, &30

 EQUB &12, &66, &24, &34
 EQUB &13, &66, &28, &2C
 EQUB &12, &66, &28, &38
 EQUB &10, &66, &2C, &38
 EQUB &10, &66, &30, &34

 EQUB &1F, &00, &20, &00            ; faces data (7*4)
 EQUB &9F, &16, &21, &0B
 EQUB &1F, &16, &21, &0B
 EQUB &DF, &16, &21, &0B
 EQUB &5F, &16, &21, &0B

 EQUB &5F, &00, &20, &00
 EQUB &3F, &00, &00, &30

\ *****************************************************************************
\ Variable: SHIP3
\
\ Mamba ship definition
\ *****************************************************************************

.SHIP3
 EQUB &01                           ; scoopable = 0, debris shown = 1
 EQUB &24, &13
 EQUB &AA
 EQUB &1A
 EQUB &5D
 EQUB &00                           ; gun vertex = 0
 EQUB &22
 EQUB &96                           ; number of vertices = &96 / 6 = 25
 EQUB &1C                           ; number of edges = &1C = 28
 EQUB &96, &00                      ; bounty = &0096 = 150
 EQUB &14                           ; number of faces = &14 / 4 = 5
 EQUB &19
 EQUB &5A
 EQUB &1E
 EQUB &00
 EQUB &01
 EQUB &02
 EQUB &12                           ; %00 0010 010, laser = 2, missiles = 2

 EQUB &00, &00, &40, &1F, &10, &32  ; vertices data (25*6)
 EQUB &40, &08, &20, &FF, &20, &44
 EQUB &20, &08, &20, &BE, &21, &44
 EQUB &20, &08, &20, &3E, &31, &44
 EQUB &40, &08, &20, &7F, &30, &44

 EQUB &04, &04, &10, &8E, &11, &11
 EQUB &04, &04, &10, &0E, &11, &11
 EQUB &08, &03, &1C, &0D, &11, &11
 EQUB &08, &03, &1C, &8D, &11, &11
 EQUB &14, &04, &10, &D4, &00, &00

 EQUB &14, &04, &10, &54, &00, &00
 EQUB &18, &07, &14, &F4, &00, &00
 EQUB &10, &07, &14, &F0, &00, &00
 EQUB &10, &07, &14, &70, &00, &00
 EQUB &18, &07, &14, &74, &00, &00

 EQUB &08, &04, &20, &AD, &44, &44
 EQUB &08, &04, &20, &2D, &44, &44
 EQUB &08, &04, &20, &6E, &44, &44
 EQUB &08, &04, &20, &EE, &44, &44
 EQUB &20, &04, &20, &A7, &44, &44

 EQUB &20, &04, &20, &27, &44, &44
 EQUB &24, &04, &20, &67, &44, &44
 EQUB &24, &04, &20, &E7, &44, &44
 EQUB &26, &00, &20, &A5, &44, &44
 EQUB &26, &00, &20, &25, &44, &44

 EQUB &1F, &20, &00, &04            ; edges data (28*4)
 EQUB &1F, &30, &00, &10
 EQUB &1F, &40, &04, &10
 EQUB &1E, &42, &04, &08
 EQUB &1E, &41, &08, &0C

 EQUB &1E, &43, &0C, &10
 EQUB &0E, &11, &14, &18
 EQUB &0C, &11, &18, &1C
 EQUB &0D, &11, &1C, &20
 EQUB &0C, &11, &14, &20

 EQUB &14, &00, &24, &2C
 EQUB &10, &00, &24, &30
 EQUB &10, &00, &28, &34
 EQUB &14, &00, &28, &38
 EQUB &0E, &00, &34, &38

 EQUB &0E, &00, &2C, &30
 EQUB &0D, &44, &3C, &40
 EQUB &0E, &44, &44, &48
 EQUB &0C, &44, &3C, &48
 EQUB &0C, &44, &40, &44

 EQUB &07, &44, &50, &54
 EQUB &05, &44, &50, &60
 EQUB &05, &44, &54, &60
 EQUB &07, &44, &4C, &58
 EQUB &05, &44, &4C, &5C

 EQUB &05, &44, &58, &5C
 EQUB &1E, &21, &00, &08
 EQUB &1E, &31, &00, &0C

 EQUB &5E, &00, &18, &02            ; faces data (5*4)
 EQUB &1E, &00, &18, &02
 EQUB &9E, &20, &40, &10
 EQUB &1E, &20, &40, &10
 EQUB &3E, &00, &00, &7F

\ *****************************************************************************
\ Variable: SHIP5
\
\ Cobra Mk III ship definition
\ *****************************************************************************

.SHIP5
 EQUB &03                           ; scoopable = 0, debris shown = 3
 EQUB &41, &23                      ; area for missile lock = &2331
 EQUB &BC                           ; edges data offset = &00BC
 EQUB &54                           ; faces data offset = &0154
 EQUB &99                           ; max. edge count for heap = (&99 - 1) / 4 = 38
 EQUB &54                           ; gun vertex = &54 / 4 = 21
 EQUB &2A                           ; explosion count = (4 * n) + 6 = &2A, n = 9
 EQUB &A8                           ; number of vertices = &A8 / 6 = 28
 EQUB &26                           ; number of edges = &26 = 38
 EQUB &00, &00                      ; bounty = 0
 EQUB &34                           ; number of faces = &34 / 4 = 13
 EQUB &32                           ; show as a dot past a distance of 50
 EQUB &96                           ; maximum energy/shields = 150
 EQUB &1C                           ; maximum speed = 28
 EQUB &00                           ; edges data offset = &00BC
 EQUB &01                           ; faces data offset = &0154
 EQUB &01                           ; normals are scaled by 2^1 = 2
 EQUB &13                           ; &13 = %00 010 011, missiles = 3, laser power = 2

 EQUB &20, &00, &4C, &1F, &FF, &FF  ; vertices data (28*6)
 EQUB &20, &00, &4C, &9F, &FF, &FF
 EQUB &00, &1A, &18, &1F, &FF, &FF
 EQUB &78, &03, &08, &FF, &73, &AA
 EQUB &78, &03, &08, &7F, &84, &CC

 EQUB &58, &10, &28, &BF, &FF, &FF
 EQUB &58, &10, &28, &3F, &FF, &FF
 EQUB &80, &08, &28, &7F, &98, &CC
 EQUB &80, &08, &28, &FF, &97, &AA
 EQUB &00, &1A, &28, &3F, &65, &99

 EQUB &20, &18, &28, &FF, &A9, &BB
 EQUB &20, &18, &28, &7F, &B9, &CC
 EQUB &24, &08, &28, &B4, &99, &99
 EQUB &08, &0C, &28, &B4, &99, &99
 EQUB &08, &0C, &28, &34, &99, &99

 EQUB &24, &08, &28, &34, &99, &99
 EQUB &24, &0C, &28, &74, &99, &99
 EQUB &08, &10, &28, &74, &99, &99
 EQUB &08, &10, &28, &F4, &99, &99
 EQUB &24, &0C, &28, &F4, &99, &99

 EQUB &00, &00, &4C, &06, &B0, &BB
 EQUB &00, &00, &5A, &1F, &B0, &BB
 EQUB &50, &06, &28, &E8, &99, &99
 EQUB &50, &06, &28, &A8, &99, &99
 EQUB &58, &00, &28, &A6, &99, &99

 EQUB &50, &06, &28, &28, &99, &99
 EQUB &58, &00, &28, &26, &99, &99
 EQUB &50, &06, &28, &68, &99, &99

 EQUB &1F, &B0, &00, &04            ; edges data (38*4)
 EQUB &1F, &C4, &00, &10
 EQUB &1F, &A3, &04, &0C
 EQUB &1F, &A7, &0C, &20
 EQUB &1F, &C8, &10, &1C

 EQUB &1F, &98, &18, &1C
 EQUB &1F, &96, &18, &24
 EQUB &1F, &95, &14, &24
 EQUB &1F, &97, &14, &20
 EQUB &1F, &51, &08, &14

 EQUB &1F, &62, &08, &18
 EQUB &1F, &73, &0C, &14
 EQUB &1F, &84, &10, &18
 EQUB &1F, &10, &04, &08
 EQUB &1F, &20, &00, &08

 EQUB &1F, &A9, &20, &28
 EQUB &1F, &B9, &28, &2C
 EQUB &1F, &C9, &1C, &2C
 EQUB &1F, &BA, &04, &28
 EQUB &1F, &CB, &00, &2C

 EQUB &1D, &31, &04, &14
 EQUB &1D, &42, &00, &18
 EQUB &06, &B0, &50, &54
 EQUB &14, &99, &30, &34
 EQUB &14, &99, &48, &4C

 EQUB &14, &99, &38, &3C
 EQUB &14, &99, &40, &44
 EQUB &13, &99, &3C, &40
 EQUB &11, &99, &38, &44
 EQUB &13, &99, &34, &48

 EQUB &13, &99, &30, &4C
 EQUB &1E, &65, &08, &24
 EQUB &06, &99, &58, &60
 EQUB &06, &99, &5C, &60
 EQUB &08, &99, &58, &5C

 EQUB &06, &99, &64, &68
 EQUB &06, &99, &68, &6C
 EQUB &08, &99, &64, &6C

 EQUB &1F, &00, &3E, &1F            ; faces data (13*4)
 EQUB &9F, &12, &37, &10            ; start normals #0 = top front plate of, &Cobra Mk III
 EQUB &1F, &12, &37, &10
 EQUB &9F, &10, &34, &0E
 EQUB &1F, &10, &34, &0E

 EQUB &9F, &0E, &2F, &00
 EQUB &1F, &0E, &2F, &00
 EQUB &9F, &3D, &66, &00
 EQUB &1F, &3D, &66, &00
 EQUB &3F, &00, &00, &50

 EQUB &DF, &07, &2A, &09
 EQUB &5F, &00, &1E, &06
 EQUB &5F, &07, &2A, &09

\ *****************************************************************************
\ Variable: SHIP6
\
\ Thargoid ship definition
\ *****************************************************************************

.SHIP6
 EQUB &00
 EQUB &49, &26
 EQUB &8C
 EQUB &F4
 EQUB &65
 EQUB &3C                           ; gun vertex = &3C / 4 = 15
 EQUB &26
 EQUB &78                           ; number of vertices = &78 / 6 = 20
 EQUB &1A                           ; number of edges = &1A = 26
 EQUB &F4, &01                      ; bounty = &01F4 = 500
 EQUB &28                           ; number of faces = &28 / 4 = 10
 EQUB &37
 EQUB &F0
 EQUB &27
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB &16                           ; %10110, laser = 2, missiles = 6

 EQUB &20, &30, &30, &5F, &40, &88  ; vertices data (20)
 EQUB &20, &44, &00, &5F, &10, &44
 EQUB &20, &30, &30, &7F, &21, &44
 EQUB &20, &00, &44, &3F, &32, &44
 EQUB &20, &30, &30, &3F, &43, &55

 EQUB &20, &44, &00, &1F, &54, &66
 EQUB &20, &30, &30, &1F, &64, &77
 EQUB &20, &00, &44, &1F, &74, &88
 EQUB &18, &74, &74, &DF, &80, &99
 EQUB &18, &A4, &00, &DF, &10, &99

 EQUB &18, &74, &74, &FF, &21, &99
 EQUB &18, &00, &A4, &BF, &32, &99
 EQUB &18, &74, &74, &BF, &53, &99
 EQUB &18, &A4, &00, &9F, &65, &99
 EQUB &18, &74, &74, &9F, &76, &99

 EQUB &18, &00, &A4, &9F, &87, &99
 EQUB &18, &40, &50, &9E, &99, &99
 EQUB &18, &40, &50, &BE, &99, &99
 EQUB &18, &40, &50, &FE, &99, &99
 EQUB &18, &40, &50, &DE, &99, &99

 EQUB &1F, &84, &00, &1C            ; edges data (26*4)
 EQUB &1F, &40, &00, &04
 EQUB &1F, &41, &04, &08
 EQUB &1F, &42, &08, &0C
 EQUB &1F, &43, &0C, &10

 EQUB &1F, &54, &10, &14
 EQUB &1F, &64, &14, &18
 EQUB &1F, &74, &18, &1C
 EQUB &1F, &80, &00, &20
 EQUB &1F, &10, &04, &24

 EQUB &1F, &21, &08, &28
 EQUB &1F, &32, &0C, &2C
 EQUB &1F, &53, &10, &30
 EQUB &1F, &65, &14, &34
 EQUB &1F, &76, &18, &38

 EQUB &1F, &87, &1C, &3C
 EQUB &1F, &98, &20, &3C
 EQUB &1F, &90, &20, &24
 EQUB &1F, &91, &24, &28
 EQUB &1F, &92, &28, &2C

 EQUB &1F, &93, &2C, &30
 EQUB &1F, &95, &30, &34
 EQUB &1F, &96, &34, &38
 EQUB &1F, &97, &38, &3C
 EQUB &1E, &99, &40, &44

 EQUB &1E, &99, &48, &4C

 EQUB &5F, &67, &3C, &19            ; faces data (10*4)
 EQUB &7F, &67, &3C, &19
 EQUB &7F, &67, &19, &3C
 EQUB &3F, &67, &19, &3C
 EQUB &1F, &40, &00, &00

 EQUB &3F, &67, &3C, &19
 EQUB &1F, &67, &3C, &19
 EQUB &1F, &67, &19, &3C
 EQUB &5F, &67, &19, &3C
 EQUB &9F, &30, &00, &00

\ *****************************************************************************
\ Variable: SHIP8
\
\ Coriolis space station definition
\ *****************************************************************************

.SHIP8
 EQUB &00
 EQUB &00, &64
 EQUB &74
 EQUB &E4
 EQUB &55
 EQUB &00                           ; gun vertex = 0
 EQUB &36
 EQUB &60                           ; number of vertices = &60 / 6 = 16
 EQUB &1C                           ; number of edges = &1C = 28
 EQUB &00, &00                      ; bounty = 0
 EQUB &38                           ; number of faces = &38 / 4 = 14
 EQUB &78
 EQUB &F0
 EQUB &00
 EQUB &00
 EQUB &00
 EQUB &00
 EQUB &06

 EQUB &A0, &00, &A0, &1F, &10, &62  ; vertices data (16*6)
 EQUB &00, &A0, &A0, &1F, &20, &83
 EQUB &A0, &00, &A0, &9F, &30, &74
 EQUB &00, &A0, &A0, &5F, &10, &54
 EQUB &A0, &A0, &00, &5F, &51, &A6

 EQUB &A0, &A0, &00, &1F, &62, &B8
 EQUB &A0, &A0, &00, &9F, &73, &C8
 EQUB &A0, &A0, &00, &DF, &54, &97
 EQUB &A0, &00, &A0, &3F, &A6, &DB
 EQUB &00, &A0, &A0, &3F, &B8, &DC

 EQUB &A0, &00, &A0, &BF, &97, &DC
 EQUB &00, &A0, &A0, &7F, &95, &DA
 EQUB &0A, &1E, &A0, &5E, &00, &00
 EQUB &0A, &1E, &A0, &1E, &00, &00
 EQUB &0A, &1E, &A0, &9E, &00, &00

 EQUB &0A, &1E, &A0, &DE, &00, &00

 EQUB &1F, &10, &00, &0C            ; edges data (28*4)
 EQUB &1F, &20, &00, &04
 EQUB &1F, &30, &04, &08
 EQUB &1F, &40, &08, &0C
 EQUB &1F, &51, &0C, &10

 EQUB &1F, &61, &00, &10
 EQUB &1F, &62, &00, &14
 EQUB &1F, &82, &14, &04
 EQUB &1F, &83, &04, &18
 EQUB &1F, &73, &08, &18

 EQUB &1F, &74, &08, &1C
 EQUB &1F, &54, &0C, &1C
 EQUB &1F, &DA, &20, &2C
 EQUB &1F, &DB, &20, &24
 EQUB &1F, &DC, &24, &28

 EQUB &1F, &D9, &28, &2C
 EQUB &1F, &A5, &10, &2C
 EQUB &1F, &A6, &10, &20
 EQUB &1F, &B6, &14, &20
 EQUB &1F, &B8, &14, &24

 EQUB &1F, &C8, &18, &24
 EQUB &1F, &C7, &18, &28
 EQUB &1F, &97, &1C, &28
 EQUB &1F, &95, &1C, &2C
 EQUB &1E, &00, &30, &34

 EQUB &1E, &00, &34, &38
 EQUB &1E, &00, &38, &3C
 EQUB &1E, &00, &3C, &30

 EQUB &1F, &00, &00, &A0            ; faces data (14*4)
 EQUB &5F, &6B, &6B, &6B
 EQUB &1F, &6B, &6B, &6B
 EQUB &9F, &6B, &6B, &6B
 EQUB &DF, &6B, &6B, &6B

 EQUB &5F, &00, &A0, &00
 EQUB &1F, &A0, &00, &00
 EQUB &9F, &A0, &00, &00
 EQUB &1F, &00, &A0, &00
 EQUB &FF, &6B, &6B, &6B

 EQUB &7F, &6B, &6B, &6B
 EQUB &3F, &6B, &6B, &6B
 EQUB &BF, &6B, &6B, &6B
 EQUB &3F, &00, &00, &A0

\ *****************************************************************************
\ Variable: SHIP9
\
\ Missile definition
\ *****************************************************************************

.SHIP9
 EQUB &00
 EQUB &40, &06
 EQUB &7A
 EQUB &DA
 EQUB &51
 EQUB &00                           ; gun vertex = 0
 EQUB &0A
 EQUB &66                           ; number of vertices = &66 / 6 = 17
 EQUB &18                           ; number of edges = &18 = 24
 EQUB &00, &00                      ; bounty = 0
 EQUB &24                           ; number of faces = &24 / 4 = 9
 EQUB &0E
 EQUB &02
 EQUB &2C
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB &00                           ; %00000, laser = 0, missiles = 0

 EQUB &00, &00, &44, &1F, &10, &32  ; vertices data (17*6)
 EQUB &08, &08, &24, &5F, &21, &54
 EQUB &08, &08, &24, &1F, &32, &74
 EQUB &08, &08, &24, &9F, &30, &76
 EQUB &08, &08, &24, &DF, &10, &65

 EQUB &08, &08, &2C, &3F, &74, &88
 EQUB &08, &08, &2C, &7F, &54, &88
 EQUB &08, &08, &2C, &FF, &65, &88
 EQUB &08, &08, &2C, &BF, &76, &88
 EQUB &0C, &0C, &2C, &28, &74, &88

 EQUB &0C, &0C, &2C, &68, &54, &88
 EQUB &0C, &0C, &2C, &E8, &65, &88
 EQUB &0C, &0C, &2C, &A8, &76, &88
 EQUB &08, &08, &0C, &A8, &76, &77
 EQUB &08, &08, &0C, &E8, &65, &66

 EQUB &08, &08, &0C, &28, &74, &77
 EQUB &08, &08, &0C, &68, &54, &55

 EQUB &1F, &21, &00, &04            ; edges data (24*4)
 EQUB &1F, &32, &00, &08
 EQUB &1F, &30, &00, &0C
 EQUB &1F, &10, &00, &10
 EQUB &1F, &24, &04, &08

 EQUB &1F, &51, &04, &10
 EQUB &1F, &60, &0C, &10
 EQUB &1F, &73, &08, &0C
 EQUB &1F, &74, &08, &14
 EQUB &1F, &54, &04, &18

 EQUB &1F, &65, &10, &1C
 EQUB &1F, &76, &0C, &20
 EQUB &1F, &86, &1C, &20
 EQUB &1F, &87, &14, &20
 EQUB &1F, &84, &14, &18

 EQUB &1F, &85, &18, &1C
 EQUB &08, &85, &18, &28
 EQUB &08, &87, &14, &24
 EQUB &08, &87, &20, &30
 EQUB &08, &85, &1C, &2C

 EQUB &08, &74, &24, &3C
 EQUB &08, &54, &28, &40
 EQUB &08, &76, &30, &34
 EQUB &08, &65, &2C, &38

 EQUB &9F, &40, &00, &10             ; faces data (9*4)
 EQUB &5F, &00, &40, &10
 EQUB &1F, &40, &00, &10
 EQUB &1F, &00, &40, &10
 EQUB &1F, &20, &00, &00

 EQUB &5F, &00, &20, &00
 EQUB &9F, &20, &00, &00
 EQUB &1F, &00, &20, &00
 EQUB &3F, &00, &00, &B0

\ *****************************************************************************
\ Variable: SHIP10
\
\ Asteroid definition
\ *****************************************************************************

.SHIP10
 EQUB &00
 EQUB &00, &19
 EQUB &4A
 EQUB &9E
 EQUB &41
 EQUB &00                           ; gun vertex = 0
 EQUB &22
 EQUB &36                           ; number of vertices = &36 / 6 = 9
 EQUB &15                           ; number of edges = &15 = 21
 EQUB &05, &00                      ; bounty = &0005 = 5
 EQUB &38                           ; number of faces = &38 / 4 = 14
 EQUB &32
 EQUB &3C
 EQUB &1E
 EQUB &00
 EQUB &00
 EQUB &01
 EQUB &00                           ; %00000, laser = 0, missiles = 0

 EQUB &00, &50, &00, &1F, &FF, &FF  ; vertices data (25*9)
 EQUB &50, &0A, &00, &DF, &FF, &FF
 EQUB &00, &50, &00, &5F, &FF, &FF
 EQUB &46, &28, &00, &5F, &FF, &FF
 EQUB &3C, &32, &00, &1F, &65, &DC

 EQUB &32, &00, &3C, &1F, &FF, &FF
 EQUB &28, &00, &46, &9F, &10, &32
 EQUB &00, &1E, &4B, &3F, &FF, &FF
 EQUB &00, &32, &3C, &7F, &98, &BA

 EQUB &1F, &72, &00, &04            ; edges data (21*4)
 EQUB &1F, &D6, &00, &10
 EQUB &1F, &C5, &0C, &10
 EQUB &1F, &B4, &08, &0C
 EQUB &1F, &A3, &04, &08

 EQUB &1F, &32, &04, &18
 EQUB &1F, &31, &08, &18
 EQUB &1F, &41, &08, &14
 EQUB &1F, &10, &14, &18
 EQUB &1F, &60, &00, &14

 EQUB &1F, &54, &0C, &14
 EQUB &1F, &20, &00, &18
 EQUB &1F, &65, &10, &14
 EQUB &1F, &A8, &04, &20
 EQUB &1F, &87, &04, &1C

 EQUB &1F, &D7, &00, &1C
 EQUB &1F, &DC, &10, &1C
 EQUB &1F, &C9, &0C, &1C
 EQUB &1F, &B9, &0C, &20
 EQUB &1F, &BA, &08, &20

 EQUB &1F, &98, &1C, &20

 EQUB &1F, &09, &42, &51            ; faces data (14*4)
 EQUB &5F, &09, &42, &51
 EQUB &9F, &48, &40, &1F
 EQUB &DF, &40, &49, &2F
 EQUB &5F, &2D, &4F, &41

 EQUB &1F, &87, &0F, &23
 EQUB &1F, &26, &4C, &46
 EQUB &BF, &42, &3B, &27
 EQUB &FF, &43, &0F, &50
 EQUB &7F, &42, &0E, &4B

 EQUB &FF, &46, &50, &28
 EQUB &7F, &3A, &66, &33
 EQUB &3F, &51, &09, &43
 EQUB &3F, &2F, &5E, &3F

\ *****************************************************************************
\ Variable: SHIP11
\
\ Cargo cannister definition
\ *****************************************************************************

.SHIP11
 EQUB &00
 EQUB &90, &01
 EQUB &50
 EQUB &8C
 EQUB &31
 EQUB &00                           ; gun vertex = 0
 EQUB &12
 EQUB &3C                           ; number of vertices = &3C / 6 = 10
 EQUB &0F                           ; number of edges = &0F = 15
 EQUB &00, &00                      ; bounty = 0
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &0C
 EQUB &11
 EQUB &0F
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB &00                           ; %00000, laser = 0, missiles = 0

 EQUB &18, &10, &00, &1F, &10, &55  ; vertices data (10*6)
 EQUB &18, &05, &0F, &1F, &10, &22
 EQUB &18, &0D, &09, &5F, &20, &33
 EQUB &18, &0D, &09, &7F, &30, &44
 EQUB &18, &05, &0F, &3F, &40, &55

 EQUB &18, &10, &00, &9F, &51, &66
 EQUB &18, &05, &0F, &9F, &21, &66
 EQUB &18, &0D, &09, &DF, &32, &66
 EQUB &18, &0D, &09, &FF, &43, &66
 EQUB &18, &05, &0F, &BF, &54, &66

 EQUB &1F, &10, &00, &04            ; edges data (15*4)
 EQUB &1F, &20, &04, &08
 EQUB &1F, &30, &08, &0C
 EQUB &1F, &40, &0C, &10
 EQUB &1F, &50, &00, &10

 EQUB &1F, &51, &00, &14
 EQUB &1F, &21, &04, &18
 EQUB &1F, &32, &08, &1C
 EQUB &1F, &43, &0C, &20
 EQUB &1F, &54, &10, &24

 EQUB &1F, &61, &14, &18
 EQUB &1F, &62, &18, &1C
 EQUB &1F, &63, &1C, &20
 EQUB &1F, &64, &20, &24
 EQUB &1F, &65, &24, &14

 EQUB &1F, &60, &00, &00            ; faces data (7*4)
 EQUB &1F, &00, &29, &1E
 EQUB &5F, &00, &12, &30
 EQUB &5F, &00, &33, &00
 EQUB &7F, &00, &12, &30

 EQUB &3F, &00, &29, &1E
 EQUB &9F, &60, &00, &00

\ *****************************************************************************
\ Variable: SHIP12
\
\ Thargon ship definition
\ *****************************************************************************

.SHIP12
 EQUB &00
 EQUB &40, &06
 EQUB &A8                           ; use edge data from Thargoid at offset &FFA8 = -88
 EQUB &50
 EQUB &41
 EQUB &00                           ; gun vertex = 0
 EQUB &12
 EQUB &3C                           ; number of vertices = &3C / 6 = 10
 EQUB &0F                           ; number of edges = &0F = 15
 EQUB &32, &00                      ; bounty = &0032 = 50
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &14
 EQUB &14
 EQUB &1E
 EQUB &FF                           ; use edge data from Thargoid at offset &FFA8 = -88
 EQUB &00
 EQUB &02
 EQUB &10

 EQUB &09, &00, &28, &9F, &01, &55  ; vertices data (10*6)
 EQUB &09, &26, &0C, &DF, &01, &22
 EQUB &09, &18, &20, &FF, &02, &33
 EQUB &09, &18, &20, &BF, &03, &44
 EQUB &09, &26, &0C, &9F, &04, &55

 EQUB &09, &00, &08, &3F, &15, &66
 EQUB &09, &0A, &0F, &7F, &12, &66
 EQUB &09, &06, &1A, &7F, &23, &66
 EQUB &09, &06, &1A, &3F, &34, &66
 EQUB &09, &0A, &0F, &3F, &45, &66

 EQUB &9F, &24, &00, &00            ; faces data (7*4)
 EQUB &5F, &14, &05, &07
 EQUB &7F, &2E, &2A, &0E
 EQUB &3F, &24, &00, &68
 EQUB &3F, &2E, &2A, &0E

 EQUB &1F, &14, &05, &07
 EQUB &1F, &24, &00, &00

\ *****************************************************************************
\ Variable: SHIP13
\
\ Escape pod definition
\ *****************************************************************************

.SHIP13
 EQUB &00
 EQUB &00, &01
 EQUB &2C
 EQUB &44
 EQUB &19
 EQUB &00                           ; gun vertex = 0
 EQUB &16
 EQUB &18                           ; number of vertices = &18 / 6 = 4
 EQUB &06                           ; number of edges = &06 = 6
 EQUB &00, &00                      ; bounty = 0
 EQUB &10                           ; number of faces = &10 / 4 = 4
 EQUB &08
 EQUB &11
 EQUB &08
 EQUB &00
 EQUB &00
 EQUB &03
 EQUB &00

 EQUB &07, &00, &24, &9F, &12, &33  ; vertices data (4*6)
 EQUB &07, &0E, &0C, &FF, &02, &33
 EQUB &07, &0E, &0C, &BF, &01, &33
 EQUB &15, &00, &00, &1F, &01, &22

 EQUB &1F, &23, &00, &04            ; edges data (6*4)
 EQUB &1F, &03, &04, &08
 EQUB &1F, &01, &08, &0C
 EQUB &1F, &12, &0C, &00
 EQUB &1F, &13, &00, &08

 EQUB &1F, &02, &0C, &04

 EQUB &3F, &1A, &00, &3D            ; faces data (4*4)
 EQUB &1F, &13, &33, &0F
 EQUB &5F, &13, &33, &0F
 EQUB &9F, &38, &00, &00

\ *****************************************************************************
\ Save output/SHIPS.bin
\ *****************************************************************************

PRINT "SHIPS"
PRINT "Assembled at ", ~CODE_SHIPS%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_SHIPS%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_SHIPS%

PRINT "S.SHIPS ", ~CODE_B%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_SHIPS%
SAVE "output/SHIPS.bin", CODE_SHIPS%, P%, LOAD%

\ *****************************************************************************
\ Show free space
\ *****************************************************************************

PRINT "ELITE game code ", ~(&6000-P%), " bytes free"
PRINT "Ends at ", ~P%
