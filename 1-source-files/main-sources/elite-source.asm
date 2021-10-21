\ ******************************************************************************
\
\ ELITE GAME SOURCE
\
\ Elite was written by Ian Bell and David Braben and is copyright Acornsoft 1984
\
\ The code on this site is identical to the source discs released on Ian Bell's
\ personal website at http://www.elitehomepage.org/ (it's just been reformatted
\ to be more readable)
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary files:
\
\   * ELTA.bin
\   * ELTB.bin
\   * ELTC.bin
\   * ELTD.bin
\   * ELTE.bin
\   * ELTF.bin
\   * ELTG.bin
\   * PYTHON.bin
\   * SHIPS.bin
\   * WORDS9.bin
\
\ ******************************************************************************

INCLUDE "1-source-files/main-sources/elite-header.h.asm"

_SOURCE_DISC            = (_RELEASE = 1)
_TEXT_SOURCES           = (_RELEASE = 2)

GUARD &6000             \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

Q% = _REMOVE_CHECKSUMS  \ Set Q% to TRUE to max out the default commander, FALSE
                        \ for the standard default commander (this is set to
                        \ TRUE if checksums are disabled, just for convenience)

NOST = 18               \ The number of stardust particles in normal space (this
                        \ goes down to 3 in witchspace)

NOSH = 12               \ The maximum number of ships in our local bubble of
                        \ universe

NTY = 13                \ The number of different ship types

COPS = 2                \ Ship type for a Viper
THG = 6                 \ Ship type for a Thargoid
CYL = 7                 \ Ship type for a Cobra Mk III (trader)
SST = 8                 \ Ship type for the space station
MSL = 9                 \ Ship type for a missile
AST = 10                \ Ship type for an asteroid
OIL = 11                \ Ship type for a cargo canister
TGL = 12                \ Ship type for a Thargon
ESC = 13                \ Ship type for an escape pod

POW = 15                \ Pulse laser power

NI% = 36                \ The number of bytes in each ship's data block (as
                        \ stored in INWK and K%)

VSCAN = 57              \ Defines the split position in the split-screen mode

X = 128                 \ The centre x-coordinate of the 256 x 192 space view
Y = 96                  \ The centre y-coordinate of the 256 x 192 space view

f0 = &20                \ Internal key number for red key f0 (Launch, Front)
f1 = &71                \ Internal key number for red key f1 (Buy Cargo, Rear)
f2 = &72                \ Internal key number for red key f2 (Sell Cargo, Left)
f3 = &73                \ Internal key number for red key f3 (Equip Ship, Right)
f4 = &14                \ Internal key number for red key f4 (Long-range Chart)
f5 = &74                \ Internal key number for red key f5 (Short-range Chart)
f6 = &75                \ Internal key number for red key f6 (Data on System)
f7 = &16                \ Internal key number for red key f7 (Market Price)
f8 = &76                \ Internal key number for red key f8 (Status Mode)
f9 = &77                \ Internal key number for red key f9 (Inventory)

VIA = &FE00             \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

OSBYTE = &FFF4          \ The address for the OSBYTE routine, which is used
                        \ three times in the main game code

OSWORD = &FFF1          \ The address for the OSWORD routine, which is used
                        \ twice in the main game code

OSFILE = &FFDD          \ The address for the OSFILE routine, which is used
                        \ once in the main game code

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0000 to &00B0
\   Category: Workspaces
\    Summary: Lots of important variables are stored in the zero page workspace
\             as it is quicker and more space-efficient to access memory here
\
\ ******************************************************************************

ORG &0000

.ZP

 SKIP 0                 \ The start of the zero page workspace

.RAND

 SKIP 4                 \ Four 8-bit seeds for the random number generation
                        \ system implemented in the DORND routine

.TRTB%

 SKIP 2                 \ Contains the address of the keyboard translation
                        \ table, which is used to translate internal key
                        \ numbers to ASCII

.T1

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

.XX16

 SKIP 18                \ Temporary storage for a block of values, used in a
                        \ number of places

.P

 SKIP 3                 \ Temporary storage, used in a number of places

.XX0

 SKIP 2                 \ Temporary storage, used to store the address of a ship
                        \ blueprint. For example, it is used when we add a new
                        \ ship to the local bubble in routine NWSHP, and it
                        \ contains the address of the current ship's blueprint
                        \ as we loop through all the nearby ships in the main
                        \ flight loop

.INF

 SKIP 2                 \ Temporary storage, typically used for storing the
                        \ address of a ship's data block, so it can be copied
                        \ to and from the internal workspace at INWK

.V

 SKIP 2                 \ Temporary storage, typically used for storing an
                        \ address pointer

.XX

 SKIP 2                 \ Temporary storage, typically used for storing a 16-bit
                        \ x-coordinate

.YY

 SKIP 2                 \ Temporary storage, typically used for storing a 16-bit
                        \ y-coordinate

.SUNX

 SKIP 2                 \ The 16-bit x-coordinate of the vertical centre axis
                        \ of the sun (which might be off-screen)

.BETA

 SKIP 1                 \ The current pitch angle beta, which is reduced from
                        \ JSTY to a sign-magnitude value between -8 and +8
                        \
                        \ This describes how fast we are pitching our ship, and
                        \ determines how fast the universe pitches around us
                        \
                        \ The sign bit is also stored in BET2, while the
                        \ opposite sign is stored in BET2+1

.BET1

 SKIP 1                 \ The magnitude of the pitch angle beta, i.e. |beta|,
                        \ which is a positive value between 0 and 8

.XC

 SKIP 1                 \ The x-coordinate of the text cursor (i.e. the text
                        \ column), which can be from 0 to 32
                        \
                        \ A value of 0 denotes the leftmost column and 32 the
                        \ rightmost column, but because the top part of the
                        \ screen (the space view) has a white border that
                        \ clashes with columns 0 and 32, text is only shown
                        \ in columns 1-31

.YC

 SKIP 1                 \ The y-coordinate of the text cursor (i.e. the text
                        \ row), which can be from 0 to 23
                        \
                        \ The screen actually has 31 character rows if you
                        \ include the dashboard, but the text printing routines
                        \ only work on the top part (the space view), so the
                        \ text cursor only goes up to a maximum of 23, the row
                        \ just before the screen splits
                        \
                        \ A value of 0 denotes the top row, but because the
                        \ top part of the screen has a white border that clashes
                        \ with row 0, text is always shown at row 1 or greater

.QQ22

 SKIP 2                 \ The two hyperspace countdown counters
                        \
                        \ Before a hyperspace jump, both QQ22 and QQ22+1 are
                        \ set to 15
                        \
                        \ QQ22 is an internal counter that counts down by 1
                        \ each time TT102 is called, which happens every
                        \ iteration of the main game loop. When it reaches
                        \ zero, the on-screen counter in QQ22+1 gets
                        \ decremented, and QQ22 gets set to 5 and the countdown
                        \ continues (so the first tick of the hyperspace counter
                        \ takes 15 iterations to happen, but subsequent ticks
                        \ take 5 iterations each)
                        \
                        \ QQ22+1 contains the number that's shown on-screen
                        \ during the countdown. It counts down from 15 to 1, and
                        \ when it hits 0, the hyperspace engines kick in

.ECMA

 SKIP 1                 \ The E.C.M. countdown timer, which determines whether
                        \ an E.C.M. system is currently operating:
                        \
                        \   * 0 = E.C.M. is off
                        \
                        \   * Non-zero = E.C.M. is on and is counting down
                        \
                        \ The counter starts at 32 when an E.C.M. is activated,
                        \ either by us or by an opponent, and it decreases by 1
                        \ in each iteration of the main flight loop until it
                        \ reaches zero, at which point the E.C.M. switches off.
                        \ Only one E.C.M. can be active at any one time, so
                        \ there is only one counter

.XX15

 SKIP 0                 \ Temporary storage, typically used for storing screen
                        \ coordinates in line-drawing routines
                        \
                        \ There are six bytes of storage, from XX15 TO XX15+5.
                        \ The first four bytes have the following aliases:
                        \
                        \   X1 = XX15
                        \   Y1 = XX15+1
                        \   X2 = XX15+2
                        \   Y2 = XX15+3
                        \
                        \ These are typically used for describing lines in terms
                        \ of screen coordinates, i.e. (X1, Y1) to (X2, Y2)
                        \
                        \ The last two bytes of XX15 do not have aliases

.X1

 SKIP 1                 \ Temporary storage, typically used for x-coordinates in
                        \ line-drawing routines

.Y1

 SKIP 1                 \ Temporary storage, typically used for y-coordinates in
                        \ line-drawing routines

.X2

 SKIP 1                 \ Temporary storage, typically used for x-coordinates in
                        \ line-drawing routines

.Y2

 SKIP 1                 \ Temporary storage, typically used for y-coordinates in
                        \ line-drawing routines

 SKIP 2                 \ The last two bytes of the XX15 block

.XX12

 SKIP 6                 \ Temporary storage for a block of values, used in a
                        \ number of places

.K

 SKIP 4                 \ Temporary storage, used in a number of places

.KL

 SKIP 1                 \ The following bytes implement a key logger that
                        \ enables Elite to scan for concurrent key presses of
                        \ the primary flight keys, plus a secondary flight key
                        \
                        \ See the deep dive on "The key logger" for more details
                        \
                        \ If a key is being pressed that is not in the keyboard
                        \ table at KYTB, it can be stored here (as seen in
                        \ routine DK4, for example)

.KY1

 SKIP 1                 \ "?" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY2

 SKIP 1                 \ Space is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY3

 SKIP 1                 \ "<" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY4

 SKIP 1                 \ ">" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY5

 SKIP 1                 \ "X" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY6

 SKIP 1                 \ "S" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY7

 SKIP 1                 \ "A" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes
                        \
                        \ This is also set when the joystick fire button has
                        \ been pressed

.KY12

 SKIP 1                 \ TAB is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY13

 SKIP 1                 \ ESCAPE is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY14

 SKIP 1                 \ "T" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY15

 SKIP 1                 \ "U" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY16

 SKIP 1                 \ "M" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY17

 SKIP 1                 \ "E" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY18

 SKIP 1                 \ "J" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY19

 SKIP 1                 \ "C" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.LAS

 SKIP 1                 \ Contains the laser power of the laser fitted to the
                        \ current space view (or 0 if there is no laser fitted
                        \ to the current view)
                        \
                        \ This gets set to bits 0-6 of the laser power byte from
                        \ the commander data block, which contains the laser's
                        \ power (bit 7 doesn't denote laser power, just whether
                        \ or not the laser pulses, so that is not stored here)

.MSTG

 SKIP 1                 \ The current missile lock target
                        \
                        \   * &FF = no target
                        \
                        \   * 1-13 = the slot number of the ship that our
                        \            missile is locked onto

.XX1

 SKIP 0                 \ This is an alias for INWK that is used in the main
                        \ ship-drawing routine at LL9

.INWK

 SKIP 33                \ The zero-page internal workspace for the current ship
                        \ data block
                        \
                        \ As operations on zero page locations are faster and
                        \ have smaller opcodes than operations on the rest of
                        \ the addressable memory, Elite tends to store oft-used
                        \ data here. A lot of the routines in Elite need to
                        \ access and manipulate ship data, so to make this an
                        \ efficient exercise, the ship data is first copied from
                        \ the ship data blocks at K% into INWK (or, when new
                        \ ships are spawned, from the blueprints at XX21). See
                        \ the deep dive on "Ship data blocks" for details of
                        \ what each of the bytes in the INWK data block
                        \ represents

.XX19

 SKIP NI% - 33          \ XX19(1 0) shares its location with INWK(34 33), which
                        \ contains the address of the ship line heap

.LSP

 SKIP 1                 \ The ball line heap pointer, which contains the number
                        \ of the first free byte after the end of the LSX2 and
                        \ LSY2 heaps (see the deep dive on "The ball line heap"
                        \ for details)

.QQ15

 SKIP 6                 \ The three 16-bit seeds for the selected system, i.e.
                        \ the one in the crosshairs in the Short-range Chart
                        \
                        \ See the deep dives on "Galaxy and system seeds" and
                        \ "Twisting the system seeds" for more details

.K5

 SKIP 0                 \ Temporary storage used to store segment coordinates
                        \ across successive calls to BLINE, the ball line
                        \ routine

.XX18

 SKIP 0                 \ Temporary storage used to store coordinates in the
                        \ LL9 ship-drawing routine

.QQ17

 SKIP 1                 \ Contains a number of flags that affect how text tokens
                        \ are printed, particularly capitalisation:
                        \
                        \   * If all bits are set (255) then text printing is
                        \     disabled
                        \
                        \   * Bit 7: 0 = ALL CAPS
                        \            1 = Sentence Case, bit 6 determines the
                        \                case of the next letter to print
                        \
                        \   * Bit 6: 0 = print the next letter in upper case
                        \            1 = print the next letter in lower case
                        \
                        \   * Bits 0-5: If any of bits 0-5 are set, print in
                        \               lower case
                        \
                        \ So:
                        \
                        \   * QQ17 = 0 means case is set to ALL CAPS
                        \
                        \   * QQ17 = %10000000 means Sentence Case, currently
                        \            printing upper case
                        \
                        \   * QQ17 = %11000000 means Sentence Case, currently
                        \            printing lower case
                        \
                        \   * QQ17 = %11111111 means printing is disabled

.QQ19

 SKIP 3                 \ Temporary storage, used in a number of places

.K6

 SKIP 5                 \ Temporary storage, typically used for storing
                        \ coordinates during vector calculations

.ALP1

 SKIP 1                 \ Magnitude of the roll angle alpha, i.e. |alpha|,
                        \ which is a positive value between 0 and 31

.ALP2

 SKIP 2                 \ Bit 7 of ALP2 = sign of the roll angle in ALPHA
                        \
                        \ Bit 7 of ALP2+1 = opposite sign to ALP2 and ALPHA

.BET2

 SKIP 2                 \ Bit 7 of BET2 = sign of the pitch angle in BETA
                        \
                        \ Bit 7 of BET2+1 = opposite sign to BET2 and BETA

.DELTA

 SKIP 1                 \ Our current speed, in the range 1-40

.DELT4

 SKIP 2                 \ Our current speed * 64 as a 16-bit value
                        \
                        \ This is stored as DELT4(1 0), so the high byte in
                        \ DELT4+1 therefore contains our current speed / 4

.U

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.R

 SKIP 1                 \ Temporary storage, used in a number of places

.S

 SKIP 1                 \ Temporary storage, used in a number of places

.XSAV

 SKIP 1                 \ Temporary storage for saving the value of the X
                        \ register, used in a number of places

.YSAV

 SKIP 1                 \ Temporary storage for saving the value of the Y
                        \ register, used in a number of places

.XX17

 SKIP 1                 \ Temporary storage, used in BPRNT to store the number
                        \ of characters to print, and as the edge counter in the
                        \ main ship-drawing routine

.QQ11

 SKIP 1                 \ The number of the current view:
                        \
                        \   0   = Space view
                        \   1   = Title screen
                        \         Get commander name ("@", save/load commander)
                        \         In-system jump just arrived ("J")
                        \         Data on System screen (red key f6)
                        \         Buy Cargo screen (red key f1)
                        \         Mis-jump just arrived (witchspace)
                        \   4   = Sell Cargo screen (red key f2)
                        \   6   = Death screen
                        \   8   = Status Mode screen (red key f8)
                        \         Inventory screen (red key f9)
                        \   16  = Market Price screen (red key f7)
                        \   32  = Equip Ship screen (red key f3)
                        \   64  = Long-range Chart (red key f4)
                        \   128 = Short-range Chart (red key f5)
                        \
                        \ This value is typically set by calling routine TT66

.ZZ

 SKIP 1                 \ Temporary storage, typically used for distance values

.XX13

 SKIP 1                 \ Temporary storage, typically used in the line-drawing
                        \ routines

.MCNT

 SKIP 1                 \ The main loop counter
                        \
                        \ This counter determines how often certain actions are
                        \ performed within the main loop. See the deep dive on
                        \ "Scheduling tasks with the main loop counter" for more
                        \ details

.DL

 SKIP 1                 \ Vertical sync flag
                        \
                        \ DL gets set to 30 every time we reach vertical sync on
                        \ the video system, which happens 50 times a second
                        \ (50Hz). The WSCAN routine uses this to pause until the
                        \ vertical sync, by setting DL to 0 and then monitoring
                        \ its value until it changes to 30

.TYPE

 SKIP 1                 \ The current ship type
                        \
                        \ This is where we store the current ship type for when
                        \ we are iterating through the ships in the local bubble
                        \ as part of the main flight loop. See the table at XX21
                        \ for information about ship types

.JSTX

 SKIP 1                 \ Our current roll rate
                        \
                        \ This value is shown in the dashboard's RL indicator,
                        \ and determines the rate at which we are rolling
                        \
                        \ The value ranges from from 1 to 255 with 128 as the
                        \ centre point, so 1 means roll is decreasing at the
                        \ maximum rate, 128 means roll is not changing, and
                        \ 255 means roll is increasing at the maximum rate
                        \
                        \ This value is updated by "<" and ">" key presses, or
                        \ if joysticks are enabled, from the joystick. If
                        \ keyboard damping is enabled (which it is by default),
                        \ the value is slowly moved towards the centre value of
                        \ 128 (no roll) if there are no key presses or joystick
                        \ movement

.JSTY

 SKIP 1                 \ Our current pitch rate
                        \
                        \ This value is shown in the dashboard's DC indicator,
                        \ and determines the rate at which we are pitching
                        \
                        \ The value ranges from from 1 to 255 with 128 as the
                        \ centre point, so 1 means pitch is decreasing at the
                        \ maximum rate, 128 means pitch is not changing, and
                        \ 255 means pitch is increasing at the maximum rate
                        \
                        \ This value is updated by "S" and "X" key presses, or
                        \ if joysticks are enabled, from the joystick. If
                        \ keyboard damping is enabled (which it is by default),
                        \ the value is slowly moved towards the centre value of
                        \ 128 (no pitch) if there are no key presses or joystick
                        \ movement

.ALPHA

 SKIP 1                 \ The current roll angle alpha, which is reduced from
                        \ JSTX to a sign-magnitude value between -31 and +31
                        \
                        \ This describes how fast we are rolling our ship, and
                        \ determines how fast the universe rolls around us
                        \
                        \ The sign bit is also stored in ALP2, while the
                        \ opposite sign is stored in ALP2+1

.QQ12

 SKIP 1                 \ Our "docked" status
                        \
                        \   * 0 = we are not docked
                        \
                        \   * &FF = we are docked

.TGT

 SKIP 1                 \ Temporary storage, typically used as a target value
                        \ for counters when drawing explosion clouds and partial
                        \ circles

.SWAP

 SKIP 1                 \ Temporary storage, used to store a flag that records
                        \ whether or not we had to swap a line's start and end
                        \ coordinates around when clipping the line in routine
                        \ LL145 (the flag is used in places like BLINE to swap
                        \ them back)

.COL

 SKIP 1                 \ Temporary storage, used to store colour information
                        \ when drawing pixels in the dashboard

.FLAG

 SKIP 1                 \ A flag that's used to define whether this is the first
                        \ call to the ball line routine in BLINE, so it knows
                        \ whether to wait for the second call before storing
                        \ segment data in the ball line heap

.CNT

 SKIP 1                 \ Temporary storage, typically used for storing the
                        \ number of iterations required when looping

.CNT2

 SKIP 1                 \ Temporary storage, used in the planet-drawing routine
                        \ to store the segment number where the arc of a partial
                        \ circle should start

.STP

 SKIP 1                 \ The step size for drawing circles
                        \
                        \ Circles in Elite are split up into 64 points, and the
                        \ step size determines how many points to skip with each
                        \ straight-line segment, so the smaller the step size,
                        \ the smoother the circle. The values used are:
                        \
                        \   * 2 for big planets and the circles on the charts
                        \   * 4 for medium planets and the launch tunnel
                        \   * 8 for small planets and the hyperspace tunnel
                        \
                        \ As the step size increases we move from smoother
                        \ circles at the top to more polygonal at the bottom.
                        \ See the CIRCLE2 routine for more details

.XX4

 SKIP 1                 \ Temporary storage, used in a number of places

.XX20

 SKIP 1                 \ Temporary storage, used in a number of places

.XX14

 SKIP 1                 \ This byte appears to be unused

.RAT

 SKIP 1                 \ Used to store different signs depending on the current
                        \ space view, for use in calculating stardust movement

.RAT2

 SKIP 1                 \ Temporary storage, used to store the pitch and roll
                        \ signs when moving objects and stardust

.K2

 SKIP 4                 \ Temporary storage, used in a number of places

ORG &00D1

.T

 SKIP 1                 \ Temporary storage, used in a number of places

.K3

 SKIP 0                 \ Temporary storage, used in a number of places

.XX2

 SKIP 14                \ Temporary storage, used to store the visibility of the
                        \ ship's faces during the ship-drawing routine at LL9

.K4

 SKIP 2                 \ Temporary storage, used in a number of places

PRINT "Zero page variables from ", ~ZP, " to ", ~P%

\ ******************************************************************************
\
\       Name: XX3
\       Type: Workspace
\    Address: &0100 to the top of the descending stack
\   Category: Workspaces
\    Summary: Temporary storage space for complex calculations
\
\ ------------------------------------------------------------------------------
\
\ Used as heap space for storing temporary data during calculations. Shared with
\ the descending 6502 stack, which works down from &01FF.
\
\ ******************************************************************************

ORG &0100

.XX3

 SKIP 0                 \ Temporary storage, typically used for storing tables
                        \ of values such as screen coordinates or ship data

\ ******************************************************************************
\
\       Name: T%
\       Type: Workspace
\    Address: &0300 to &035F
\   Category: Workspaces
\    Summary: Current commander data and stardust data blocks
\
\ ------------------------------------------------------------------------------
\
\ Contains the current commander data (NT% bytes at location TP), and the
\ stardust data blocks (NOST bytes at location SX)
\
\ ******************************************************************************

ORG &0300

.T%

 SKIP 0                 \ The start of the T% workspace

.TP

 SKIP 1                 \ The current mission status, which is always 0 for the
                        \ cassette version of Elite as there are no missions

.QQ0

 SKIP 1                 \ The current system's galactic x-coordinate (0-256)

.QQ1

 SKIP 1                 \ The current system's galactic y-coordinate (0-256)

.QQ21

 SKIP 6                 \ The three 16-bit seeds for the current galaxy
                        \
                        \ These seeds define system 0 in the current galaxy, so
                        \ they can be used as a starting point to generate all
                        \ 256 systems in the galaxy
                        \
                        \ Using a galactic hyperdrive rotates each byte to the
                        \ left (rolling each byte within itself) to get the
                        \ seeds for the next galaxy, so after eight galactic
                        \ jumps, the seeds roll around to the first galaxy again
                        \
                        \ See the deep dives on "Galaxy and system seeds" and
                        \ "Twisting the system seeds" for more details
.CASH

 SKIP 4                 \ Our current cash pot
                        \
                        \ The cash stash is stored as a 32-bit unsigned integer,
                        \ with the most significant byte in CASH and the least
                        \ significant in CASH+3. This is big-endian, which is
                        \ the opposite way round to most of the numbers used in
                        \ Elite - to use our notation for multi-byte numbers,
                        \ the amount of cash is CASH(0 1 2 3)

.QQ14

 SKIP 1                 \ Our current fuel level (0-70)
                        \
                        \ The fuel level is stored as the number of light years
                        \ multiplied by 10, so QQ14 = 1 represents 0.1 light
                        \ years, and the maximum possible value is 70, for 7.0
                        \ light years

.COK

 SKIP 1                 \ Flags used to generate the competition code
                        \
                        \ See the deep dive on "The competition code" for
                        \ details of these flags and how they are used in
                        \ generating and decoding the competition code

.GCNT

 SKIP 1                 \ The number of the current galaxy (0-7)
                        \
                        \ When this is displayed in-game, 1 is added to the
                        \ number, so we start in galaxy 1 in-game, but it's
                        \ stored as galaxy 0 internally
                        \
                        \ The galaxy number increases by one every time a
                        \ galactic hyperdrive is used, and wraps back round to
                        \ the start after eight galaxies

.LASER

 SKIP 4                 \ The specifications of the lasers fitted to each of the
                        \ four space views:
                        \
                        \   * Byte #0 = front view (red key f0)
                        \   * Byte #1 = rear view (red key f1)
                        \   * Byte #2 = left view (red key f2)
                        \   * Byte #3 = right view (red key f3)
                        \
                        \ For each of the views:
                        \
                        \   * 0 = no laser is fitted to this view
                        \
                        \   * Non-zero = a laser is fitted to this view, with
                        \     the following specification:
                        \
                        \     * Bits 0-6 contain the laser's power
                        \
                        \     * Bit 7 determines whether or not the laser pulses
                        \       (0 = pulse laser) or is always on (1 = beam
                        \       laser)

 SKIP 2                 \ These bytes appear to be unused (they were originally
                        \ used for up/down lasers, but they were dropped)

.CRGO

 SKIP 1                 \ Our ship's cargo capacity
                        \
                        \   * 22 = standard cargo bay of 20 tonnes
                        \
                        \   * 37 = large cargo bay of 35 tonnes
                        \
                        \ The value is two greater than the actual capacity to
                        \ make the maths in tnpr slightly more efficient

.QQ20

 SKIP 17                \ The contents of our cargo hold
                        \
                        \ The amount of market item X that we have in our hold
                        \ can be found in the X-th byte of QQ20. For example:
                        \
                        \   * QQ20 contains the amount of food (item 0)
                        \
                        \   * QQ20+7 contains the amount of computers (item 7)
                        \
                        \ See QQ23 for a list of market item numbers and their
                        \ storage units

.ECM

 SKIP 1                 \ E.C.M. system
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.BST

 SKIP 1                 \ Fuel scoops (BST stands for "barrel status")
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.BOMB

 SKIP 1                 \ Energy bomb
                        \
                        \   * 0 = not fitted
                        \
                        \   * &7F = fitted

.ENGY

 SKIP 1                 \ Energy unit
                        \
                        \   * 0 = not fitted
                        \
                        \   * Non-zero = fitted
                        \
                        \ The actual value determines the refresh rate of our
                        \ energy banks, as they refresh by ENGY+1 each time (so
                        \ our ship's energy level goes up by 2 each time if we
                        \ have an energy unit fitted, otherwise it goes up by 1)

.DKCMP

 SKIP 1                 \ Docking computer
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.GHYP

 SKIP 1                 \ Galactic hyperdrive
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.ESCP

 SKIP 1                 \ Escape pod
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

 SKIP 4                 \ These bytes appear to be unused

.NOMSL

 SKIP 1                 \ The number of missiles we have fitted (0-4)

.FIST

 SKIP 1                 \ Our legal status (FIST stands for "fugitive/innocent
                        \ status"):
                        \
                        \   * 0 = Clean
                        \
                        \   * 1-49 = Offender
                        \
                        \   * 50+ = Fugitive
                        \
                        \ You get 64 points if you kill a cop, so that's a fast
                        \ ticket to fugitive status

.AVL

 SKIP 17                \ Market availability in the current system
                        \
                        \ The available amount of market item X is stored in
                        \ the X-th byte of AVL, so for example:
                        \
                        \   * AVL contains the amount of food (item 0)
                        \
                        \   * AVL+7 contains the amount of computers (item 7)
                        \
                        \ See QQ23 for a list of market item numbers and their
                        \ storage units, and the deep dive on "Market item
                        \ prices and availability" for details of the algorithm
                        \ used for calculating each item's availability

.QQ26

 SKIP 1                 \ A random value used to randomise market data
                        \
                        \ This value is set to a new random number for each
                        \ change of system, so we can add a random factor into
                        \ the calculations for market prices (for details of how
                        \ this is used, see the deep dive on "Market prices")

.TALLY

 SKIP 2                 \ Our combat rank
                        \
                        \ The combat rank is stored as the number of kills, in a
                        \ 16-bit number TALLY(1 0) - so the high byte is in
                        \ TALLY+1 and the low byte in TALLY
                        \
                        \ If the high byte in TALLY+1 is 0 then we have between
                        \ 0 and 255 kills, so our rank is Harmless, Mostly
                        \ Harmless, Poor, Average or Above Average, according to
                        \ the value of the low byte in TALLY:
                        \
                        \   Harmless        = %00000000 to %00000011 = 0 to 3
                        \   Mostly Harmless = %00000100 to %00000111 = 4 to 7
                        \   Poor            = %00001000 to %00001111 = 8 to 15
                        \   Average         = %00010000 to %00011111 = 16 to 31
                        \   Above Average   = %00100000 to %11111111 = 32 to 255
                        \
                        \ If the high byte in TALLY+1 is non-zero then we are
                        \ Competent, Dangerous, Deadly or Elite, according to
                        \ the high byte in TALLY+1:
                        \
                        \   Competent       = 1           = 256 to 511 kills
                        \   Dangerous       = 2 to 9      = 512 to 2559 kills
                        \   Deadly          = 10 to 24    = 2560 to 6399 kills
                        \   Elite           = 25 and up   = 6400 kills and up
                        \
                        \ You can see the rating calculation in STATUS

.SVC

 SKIP 1                 \ The save count
                        \
                        \ When a new commander is created, the save count gets
                        \ set to 128. This value gets halved each time the
                        \ commander file is saved, but it is otherwise unused.
                        \ It is presumably part of the security system for the
                        \ competition, possibly another flag to catch out
                        \ entries with manually altered commander files

 SKIP 2                 \ The commander file checksum
                        \
                        \ These two bytes are reserved for the commander file
                        \ checksum, so when the current commander block is
                        \ copied from here to the last saved commander block at
                        \ NA%, CHK and CHK2 get overwritten

NT% = SVC + 2 - TP      \ This sets the variable NT% to the size of the current
                        \ commander data block, which starts at TP and ends at
                        \ SVC+2 (inclusive)

.SX

 SKIP NOST + 1          \ This is where we store the x_hi coordinates for all
                        \ the stardust particles

.SXL

 SKIP NOST + 1          \ This is where we store the x_lo coordinates for all
                        \ the stardust particles

PRINT "T% workspace from  ", ~T%, " to ", ~P%

\ ******************************************************************************
\
\ ELITE RECURSIVE TEXT TOKEN FILE
\
\ Produces the binary file WORDS9.bin that gets loaded by elite-loader.asm.
\
\ The recursive token table is loaded at &1100 and is moved down to &0400 as
\ part of elite-loader.asm, so it ends up at &0400 to &07FF.
\
\ ******************************************************************************

CODE_WORDS% = &0400
LOAD_WORDS% = &1100

ORG CODE_WORDS%

\ ******************************************************************************
\
\       Name: CHAR
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for characters in the recursive token table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the recursive token table:
\
\   CHAR 'x'            Insert ASCII character "x"
\
\ To include an apostrophe, use a backtick character, as in CHAR '`'.
\
\ See the deep dive on "Printing text tokens" for details on how characters are
\ stored in the recursive token table.
\
\ Arguments:
\
\   'x'                 The character to insert into the table
\
\ ******************************************************************************

MACRO CHAR x

  IF x = '`'
    EQUB 39 EOR 35
  ELSE
    EQUB x EOR 35
  ENDIF

ENDMACRO

\ ******************************************************************************
\
\       Name: TWOK
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for two-letter tokens in the token table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the recursive token table:
\
\   TWOK 'x', 'y'       Insert two-letter token "xy"
\
\ See the deep dive on "Printing text tokens" for details on how two-letter
\ tokens are stored in the recursive token table.
\
\ Arguments:
\
\   'x'                 The first letter of the two-letter token to insert into
\                       the table
\
\   'y'                 The second letter of the two-letter token to insert into
\                       the table
\
\ ******************************************************************************

MACRO TWOK t, k

  IF t = 'A' AND k = 'L' : EQUB 128 EOR 35 : ENDIF
  IF t = 'L' AND k = 'E' : EQUB 129 EOR 35 : ENDIF
  IF t = 'X' AND k = 'E' : EQUB 130 EOR 35 : ENDIF
  IF t = 'G' AND k = 'E' : EQUB 131 EOR 35 : ENDIF
  IF t = 'Z' AND k = 'A' : EQUB 132 EOR 35 : ENDIF
  IF t = 'C' AND k = 'E' : EQUB 133 EOR 35 : ENDIF
  IF t = 'B' AND k = 'I' : EQUB 134 EOR 35 : ENDIF
  IF t = 'S' AND k = 'O' : EQUB 135 EOR 35 : ENDIF
  IF t = 'U' AND k = 'S' : EQUB 136 EOR 35 : ENDIF
  IF t = 'E' AND k = 'S' : EQUB 137 EOR 35 : ENDIF
  IF t = 'A' AND k = 'R' : EQUB 138 EOR 35 : ENDIF
  IF t = 'M' AND k = 'A' : EQUB 139 EOR 35 : ENDIF
  IF t = 'I' AND k = 'N' : EQUB 140 EOR 35 : ENDIF
  IF t = 'D' AND k = 'I' : EQUB 141 EOR 35 : ENDIF
  IF t = 'R' AND k = 'E' : EQUB 142 EOR 35 : ENDIF
  IF t = 'A' AND k = '?' : EQUB 143 EOR 35 : ENDIF
  IF t = 'E' AND k = 'R' : EQUB 144 EOR 35 : ENDIF
  IF t = 'A' AND k = 'T' : EQUB 145 EOR 35 : ENDIF
  IF t = 'E' AND k = 'N' : EQUB 146 EOR 35 : ENDIF
  IF t = 'B' AND k = 'E' : EQUB 147 EOR 35 : ENDIF
  IF t = 'R' AND k = 'A' : EQUB 148 EOR 35 : ENDIF
  IF t = 'L' AND k = 'A' : EQUB 149 EOR 35 : ENDIF
  IF t = 'V' AND k = 'E' : EQUB 150 EOR 35 : ENDIF
  IF t = 'T' AND k = 'I' : EQUB 151 EOR 35 : ENDIF
  IF t = 'E' AND k = 'D' : EQUB 152 EOR 35 : ENDIF
  IF t = 'O' AND k = 'R' : EQUB 153 EOR 35 : ENDIF
  IF t = 'Q' AND k = 'U' : EQUB 154 EOR 35 : ENDIF
  IF t = 'A' AND k = 'N' : EQUB 155 EOR 35 : ENDIF
  IF t = 'T' AND k = 'E' : EQUB 156 EOR 35 : ENDIF
  IF t = 'I' AND k = 'S' : EQUB 157 EOR 35 : ENDIF
  IF t = 'R' AND k = 'I' : EQUB 158 EOR 35 : ENDIF
  IF t = 'O' AND k = 'N' : EQUB 159 EOR 35 : ENDIF

ENDMACRO

\ ******************************************************************************
\
\       Name: CONT
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for control codes in the recursive token table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the recursive token table:
\
\   CONT n              Insert control code token {n}
\
\ See the deep dive on "Printing text tokens" for details on how characters are
\ stored in the recursive token table.
\
\ Arguments:
\
\   n                   The control code to insert into the table
\
\ ******************************************************************************

MACRO CONT n

  EQUB n EOR 35

ENDMACRO

\ ******************************************************************************
\
\       Name: RTOK
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for recursive tokens in the recursive token table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the recursive token table:
\
\   RTOK n              Insert recursive token [n]
\
\                         * Tokens 0-95 get stored as n + 160
\
\                         * Tokens 128-145 get stored as n - 114
\
\                         * Tokens 96-127 get stored as n
\
\ See the deep dive on "Printing text tokens" for details on how recursive
\ tokens are stored in the recursive token table.
\
\ Arguments:
\
\   n                   The number of the recursive token to insert into the
\                       table, in the range 0 to 145
\
\ ******************************************************************************

MACRO RTOK n

  IF n >= 0 AND n <= 95
    t = n + 160
  ELIF n >= 128
    t = n - 114
  ELSE
    t = n
  ENDIF

  EQUB t EOR 35

ENDMACRO

\ ******************************************************************************
\
\       Name: QQ18
\       Type: Variable
\   Category: Text
\    Summary: The recursive token table for tokens 0-148
\  Deep dive: Printing text tokens
\
\ ******************************************************************************

.QQ18

 RTOK 111               \ Token 0:      "FUEL SCOOPS ON {beep}"
 RTOK 131               \
 CONT 7                 \ Encoded as:   "[111][131]{7}"
 EQUB 0

 CHAR ' '               \ Token 1:      " CHART"
 CHAR 'C'               \
 CHAR 'H'               \ Encoded as:   " CH<138>T"
 TWOK 'A', 'R'
 CHAR 'T'
 EQUB 0

 CHAR 'G'               \ Token 2:      "GOVERNMENT"
 CHAR 'O'               \
 TWOK 'V', 'E'          \ Encoded as:   "GO<150>RNM<146>T"
 CHAR 'R'
 CHAR 'N'
 CHAR 'M'
 TWOK 'E', 'N'
 CHAR 'T'
 EQUB 0

 CHAR 'D'               \ Token 3:      "DATA ON {selected system name}"
 TWOK 'A', 'T'          \
 CHAR 'A'               \ Encoded as:   "D<145>A[131]{3}"
 RTOK 131
 CONT 3
 EQUB 0

 TWOK 'I', 'N'          \ Token 4:      "INVENTORY{crlf}
 TWOK 'V', 'E'          \               "
 CHAR 'N'               \
 CHAR 'T'               \ Encoded as:   "<140><150>NT<153>Y{13}"
 TWOK 'O', 'R'
 CHAR 'Y'
 CONT 13
 EQUB 0

 CHAR 'S'               \ Token 5:      "SYSTEM"
 CHAR 'Y'               \
 CHAR 'S'               \ Encoded as:   "SYS<156>M"
 TWOK 'T', 'E'
 CHAR 'M'
 EQUB 0

 CHAR 'P'               \ Token 6:      "PRICE"
 TWOK 'R', 'I'          \
 TWOK 'C', 'E'          \ Encoded as:   "P<158><133>"
 EQUB 0

 CONT 2                 \ Token 7:      "{current system name} MARKET PRICES"
 CHAR ' '               \
 TWOK 'M', 'A'          \ Encoded as:   "{2} <139>RKET [6]S"
 CHAR 'R'
 CHAR 'K'
 CHAR 'E'
 CHAR 'T'
 CHAR ' '
 RTOK 6
 CHAR 'S'
 EQUB 0

 TWOK 'I', 'N'          \ Token 8:      "INDUSTRIAL"
 CHAR 'D'               \
 TWOK 'U', 'S'          \ Encoded as:   "<140>D<136>T<158><128>"
 CHAR 'T'
 TWOK 'R', 'I'
 TWOK 'A', 'L'
 EQUB 0

 CHAR 'A'               \ Token 9:      "AGRICULTURAL"
 CHAR 'G'               \
 TWOK 'R', 'I'          \ Encoded as:   "AG<158>CULTU<148>L"
 CHAR 'C'
 CHAR 'U'
 CHAR 'L'
 CHAR 'T'
 CHAR 'U'
 TWOK 'R', 'A'
 CHAR 'L'
 EQUB 0

 TWOK 'R', 'I'          \ Token 10:     "RICH "
 CHAR 'C'               \
 CHAR 'H'               \ Encoded as:   "<158>CH "
 CHAR ' '
 EQUB 0

 CHAR 'A'               \ Token 11:     "AVERAGE "
 TWOK 'V', 'E'          \
 TWOK 'R', 'A'          \ Encoded as:   "A<150><148><131> "
 TWOK 'G', 'E'
 CHAR ' '
 EQUB 0

 CHAR 'P'               \ Token 12:     "POOR "
 CHAR 'O'               \
 TWOK 'O', 'R'          \ Encoded as:   "PO<153> "
 CHAR ' '
 EQUB 0

 TWOK 'M', 'A'          \ Token 13:     "MAINLY "
 TWOK 'I', 'N'          \
 CHAR 'L'               \ Encoded as:   "<139><140>LY "
 CHAR 'Y'
 CHAR ' '
 EQUB 0

 CHAR 'U'               \ Token 14:     "UNIT"
 CHAR 'N'               \
 CHAR 'I'               \ Encoded as:   "UNIT"
 CHAR 'T'
 EQUB 0

 CHAR 'V'               \ Token 15:     "VIEW "
 CHAR 'I'               \
 CHAR 'E'               \ Encoded as:   "VIEW "
 CHAR 'W'
 CHAR ' '
 EQUB 0

 TWOK 'Q', 'U'          \ Token 16:     "QUANTITY"
 TWOK 'A', 'N'          \
 TWOK 'T', 'I'          \ Encoded as:   "<154><155><151>TY"
 CHAR 'T'
 CHAR 'Y'
 EQUB 0

 TWOK 'A', 'N'          \ Token 17:     "ANARCHY"
 TWOK 'A', 'R'          \
 CHAR 'C'               \ Encoded as:   "<155><138>CHY"
 CHAR 'H'
 CHAR 'Y'
 EQUB 0

 CHAR 'F'               \ Token 18:     "FEUDAL"
 CHAR 'E'               \
 CHAR 'U'               \ Encoded as:   "FEUD<128>"
 CHAR 'D'
 TWOK 'A', 'L'
 EQUB 0

 CHAR 'M'               \ Token 19:     "MULTI-GOVERNMENT"
 CHAR 'U'               \
 CHAR 'L'               \ Encoded as:   "MUL<151>-[2]"
 TWOK 'T', 'I'
 CHAR '-'
 RTOK 2
 EQUB 0

 TWOK 'D', 'I'          \ Token 20:     "DICTATORSHIP"
 CHAR 'C'               \
 CHAR 'T'               \ Encoded as:   "<141>CT<145><153>[25]"
 TWOK 'A', 'T'
 TWOK 'O', 'R'
 RTOK 25
 EQUB 0

 RTOK 91                \ Token 21:     "COMMUNIST"
 CHAR 'M'               \
 CHAR 'U'               \ Encoded as:   "[91]MUN<157>T"
 CHAR 'N'
 TWOK 'I', 'S'
 CHAR 'T'
 EQUB 0

 CHAR 'C'               \ Token 22:     "CONFEDERACY"
 TWOK 'O', 'N'          \
 CHAR 'F'               \ Encoded as:   "C<159>F<152><144>ACY"
 TWOK 'E', 'D'
 TWOK 'E', 'R'
 CHAR 'A'
 CHAR 'C'
 CHAR 'Y'
 EQUB 0

 CHAR 'D'               \ Token 23:     "DEMOCRACY"
 CHAR 'E'               \
 CHAR 'M'               \ Encoded as:   "DEMOC<148>CY"
 CHAR 'O'
 CHAR 'C'
 TWOK 'R', 'A'
 CHAR 'C'
 CHAR 'Y'
 EQUB 0

 CHAR 'C'               \ Token 24:     "CORPORATE STATE"
 TWOK 'O', 'R'          \
 CHAR 'P'               \ Encoded as:   "C<153>P<153><145>E [43]<145>E"
 TWOK 'O', 'R'
 TWOK 'A', 'T'
 CHAR 'E'
 CHAR ' '
 RTOK 43
 TWOK 'A', 'T'
 CHAR 'E'
 EQUB 0

 CHAR 'S'               \ Token 25:     "SHIP"
 CHAR 'H'               \
 CHAR 'I'               \ Encoded as:   "SHIP"
 CHAR 'P'
 EQUB 0

 CHAR 'P'               \ Token 26:     "PRODUCT"
 CHAR 'R'               \
 CHAR 'O'               \ Encoded as:   "PRODUCT"
 CHAR 'D'
 CHAR 'U'
 CHAR 'C'
 CHAR 'T'
 EQUB 0

 CHAR ' '               \ Token 27:     " LASER"
 TWOK 'L', 'A'          \
 CHAR 'S'               \ Encoded as:   " <149>S<144>"
 TWOK 'E', 'R'
 EQUB 0

 CHAR 'H'               \ Token 28:     "HUMAN COLONIAL"
 CHAR 'U'               \
 CHAR 'M'               \ Encoded as:   "HUM<155> COL<159>I<128>"
 TWOK 'A', 'N'
 CHAR ' '
 CHAR 'C'
 CHAR 'O'
 CHAR 'L'
 TWOK 'O', 'N'
 CHAR 'I'
 TWOK 'A', 'L'
 EQUB 0

 CHAR 'H'               \ Token 29:     "HYPERSPACE "
 CHAR 'Y'               \
 CHAR 'P'               \ Encoded as:   "HYP<144>SPA<133> "
 TWOK 'E', 'R'
 CHAR 'S'
 CHAR 'P'
 CHAR 'A'
 TWOK 'C', 'E'
 CHAR ' '
 EQUB 0

 CHAR 'S'               \ Token 30:     "SHORT RANGE CHART"
 CHAR 'H'               \
 TWOK 'O', 'R'          \ Encoded as:   "SH<153>T [42][1]"
 CHAR 'T'
 CHAR ' '
 RTOK 42
 RTOK 1
 EQUB 0

 TWOK 'D', 'I'          \ Token 31:     "DISTANCE"
 RTOK 43                \
 TWOK 'A', 'N'          \ Encoded as:   "<141>[43]<155><133>"
 TWOK 'C', 'E'
 EQUB 0

 CHAR 'P'               \ Token 32:     "POPULATION"
 CHAR 'O'               \
 CHAR 'P'               \ Encoded as:   "POPUL<145>I<159>"
 CHAR 'U'
 CHAR 'L'
 TWOK 'A', 'T'
 CHAR 'I'
 TWOK 'O', 'N'
 EQUB 0

 CHAR 'G'               \ Token 33:     "GROSS PRODUCTIVITY"
 CHAR 'R'               \
 CHAR 'O'               \ Encoded as:   "GROSS [26]IVITY"
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

 CHAR 'E'               \ Token 34:     "ECONOMY"
 CHAR 'C'               \
 TWOK 'O', 'N'          \ Encoded as:   "EC<159>OMY"
 CHAR 'O'
 CHAR 'M'
 CHAR 'Y'
 EQUB 0

 CHAR ' '               \ Token 35:     " LIGHT YEARS"
 CHAR 'L'               \
 CHAR 'I'               \ Encoded as:   " LIGHT YE<138>S"
 CHAR 'G'
 CHAR 'H'
 CHAR 'T'
 CHAR ' '
 CHAR 'Y'
 CHAR 'E'
 TWOK 'A', 'R'
 CHAR 'S'
 EQUB 0

 TWOK 'T', 'E'          \ Token 36:     "TECH.LEVEL"
 CHAR 'C'               \
 CHAR 'H'               \ Encoded as:   "<156>CH.<129><150>L"
 CHAR '.'
 TWOK 'L', 'E'
 TWOK 'V', 'E'
 CHAR 'L'
 EQUB 0

 CHAR 'C'               \ Token 37:     "CASH"
 CHAR 'A'               \
 CHAR 'S'               \ Encoded as:   "CASH"
 CHAR 'H'
 EQUB 0

 CHAR ' '               \ Token 38:     " BILLION"
 TWOK 'B', 'I'          \
 RTOK 118               \ Encoded as:   " <134>[118]I<159>"
 CHAR 'I'
 TWOK 'O', 'N'
 EQUB 0

 RTOK 122               \ Token 39:     "GALACTIC CHART{galaxy number}"
 RTOK 1                 \
 CONT 1                 \ Encoded as:   "[122][1]{1}"
 EQUB 0

 CHAR 'T'               \ Token 40:     "TARGET LOST"
 TWOK 'A', 'R'          \
 TWOK 'G', 'E'          \ Encoded as:   "T<138><131>T LO[43]"
 CHAR 'T'
 CHAR ' '
 CHAR 'L'
 CHAR 'O'
 RTOK 43
 EQUB 0

 RTOK 106               \ Token 41:     "MISSILE JAMMED"
 CHAR ' '               \
 CHAR 'J'               \ Encoded as:   "[106] JAMM<152>"
 CHAR 'A'
 CHAR 'M'
 CHAR 'M'
 TWOK 'E', 'D'
 EQUB 0

 CHAR 'R'               \ Token 42:     "RANGE"
 TWOK 'A', 'N'          \
 TWOK 'G', 'E'          \ Encoded as:   "R<155><131>"
 EQUB 0

 CHAR 'S'               \ Token 43:     "ST"
 CHAR 'T'               \
 EQUB 0                 \ Encoded as:   "ST"

 RTOK 16                \ Token 44:     "QUANTITY OF "
 CHAR ' '               \
 CHAR 'O'               \ Encoded as:   "[16] OF "
 CHAR 'F'
 CHAR ' '
 EQUB 0

 CHAR 'S'               \ Token 45:     "SELL"
 CHAR 'E'               \
 RTOK 118               \ Encoded as:   "SE[118]"
 EQUB 0

 CHAR ' '               \ Token 46:     " CARGO{sentence case}"
 CHAR 'C'               \
 TWOK 'A', 'R'          \ Encoded as:   " C<138>GO{6}"
 CHAR 'G'
 CHAR 'O'
 CONT 6
 EQUB 0

 CHAR 'E'               \ Token 47:     "EQUIP"
 TWOK 'Q', 'U'          \
 CHAR 'I'               \ Encoded as:   "E<154>IP"
 CHAR 'P'
 EQUB 0

 CHAR 'F'               \ Token 48:     "FOOD"
 CHAR 'O'               \
 CHAR 'O'               \ Encoded as:   "FOOD"
 CHAR 'D'
 EQUB 0

 TWOK 'T', 'E'          \ Token 49:     "TEXTILES"
 CHAR 'X'               \
 TWOK 'T', 'I'          \ Encoded as:   "<156>X<151>L<137>"
 CHAR 'L'
 TWOK 'E', 'S'
 EQUB 0

 TWOK 'R', 'A'          \ Token 50:     "RADIOACTIVES"
 TWOK 'D', 'I'          \
 CHAR 'O'               \ Encoded as:   "<148><141>OAC<151><150>S"
 CHAR 'A'
 CHAR 'C'
 TWOK 'T', 'I'
 TWOK 'V', 'E'
 CHAR 'S'
 EQUB 0

 CHAR 'S'               \ Token 51:     "SLAVES"
 TWOK 'L', 'A'          \
 TWOK 'V', 'E'          \ Encoded as:   "S<149><150>S"
 CHAR 'S'
 EQUB 0

 CHAR 'L'               \ Token 52:     "LIQUOR/WINES"
 CHAR 'I'               \
 TWOK 'Q', 'U'          \ Encoded as:   "LI<154><153>/W<140><137>"
 TWOK 'O', 'R'
 CHAR '/'
 CHAR 'W'
 TWOK 'I', 'N'
 TWOK 'E', 'S'
 EQUB 0

 CHAR 'L'               \ Token 53:     "LUXURIES"
 CHAR 'U'               \
 CHAR 'X'               \ Encoded as:   "LUXU<158><137>"
 CHAR 'U'
 TWOK 'R', 'I'
 TWOK 'E', 'S'
 EQUB 0

 CHAR 'N'               \ Token 54:     "NARCOTICS"
 TWOK 'A', 'R'          \
 CHAR 'C'               \ Encoded as:   "N<138>CO<151>CS"
 CHAR 'O'
 TWOK 'T', 'I'
 CHAR 'C'
 CHAR 'S'
 EQUB 0

 RTOK 91                \ Token 55:     "COMPUTERS"
 CHAR 'P'               \
 CHAR 'U'               \ Encoded as:   "[91]PUT<144>S"
 CHAR 'T'
 TWOK 'E', 'R'
 CHAR 'S'
 EQUB 0

 TWOK 'M', 'A'          \ Token 56:     "MACHINERY"
 CHAR 'C'               \
 CHAR 'H'               \ Encoded as:   "<139>CH<140><144>Y"
 TWOK 'I', 'N'
 TWOK 'E', 'R'
 CHAR 'Y'
 EQUB 0

 RTOK 117               \ Token 57:     "ALLOYS"
 CHAR 'O'               \
 CHAR 'Y'               \ Encoded as:   "[117]OYS"
 CHAR 'S'
 EQUB 0

 CHAR 'F'               \ Token 58:     "FIREARMS"
 CHAR 'I'               \
 TWOK 'R', 'E'          \ Encoded as:   "FI<142><138>MS"
 TWOK 'A', 'R'
 CHAR 'M'
 CHAR 'S'
 EQUB 0

 CHAR 'F'               \ Token 59:     "FURS"
 CHAR 'U'               \
 CHAR 'R'               \ Encoded as:   "FURS"
 CHAR 'S'
 EQUB 0

 CHAR 'M'               \ Token 60:     "MINERALS"
 TWOK 'I', 'N'          \
 TWOK 'E', 'R'          \ Encoded as:   "M<140><144><128>S"
 TWOK 'A', 'L'
 CHAR 'S'
 EQUB 0

 CHAR 'G'               \ Token 61:     "GOLD"
 CHAR 'O'               \
 CHAR 'L'               \ Encoded as:   "GOLD"
 CHAR 'D'
 EQUB 0

 CHAR 'P'               \ Token 62:     "PLATINUM"
 CHAR 'L'               \
 TWOK 'A', 'T'          \ Encoded as:   "PL<145><140>UM"
 TWOK 'I', 'N'
 CHAR 'U'
 CHAR 'M'
 EQUB 0

 TWOK 'G', 'E'          \ Token 63:     "GEM-STONES"
 CHAR 'M'               \
 CHAR '-'               \ Encoded as:   "<131>M-[43]<159><137>"
 RTOK 43
 TWOK 'O', 'N'
 TWOK 'E', 'S'
 EQUB 0

 TWOK 'A', 'L'          \ Token 64:     "ALIEN ITEMS"
 CHAR 'I'               \
 TWOK 'E', 'N'          \ Encoded as:   "<128>I<146> [127]S"
 CHAR ' '
 RTOK 127
 CHAR 'S'
 EQUB 0

 CHAR '('               \ Token 65:     "(Y/N)?"
 CHAR 'Y'               \
 CHAR '/'               \ Encoded as:   "(Y/N)?"
 CHAR 'N'
 CHAR ')'
 CHAR '?'
 EQUB 0

 CHAR ' '               \ Token 66:     " CR"
 CHAR 'C'               \
 CHAR 'R'               \ Encoded as:   " CR"
 EQUB 0

 CHAR 'L'               \ Token 67:     "LARGE"
 TWOK 'A', 'R'          \
 TWOK 'G', 'E'          \ Encoded as:   "L<138><131>"
 EQUB 0

 CHAR 'F'               \ Token 68:     "FIERCE"
 CHAR 'I'               \
 TWOK 'E', 'R'          \ Encoded as:   "FI<144><133>"
 TWOK 'C', 'E'
 EQUB 0

 CHAR 'S'               \ Token 69:     "SMALL"
 TWOK 'M', 'A'          \
 RTOK 118               \ Encoded as:   "S<139>[118]"
 EQUB 0

 CHAR 'G'               \ Token 70:     "GREEN"
 TWOK 'R', 'E'          \
 TWOK 'E', 'N'          \ Encoded as:   "G<142><146>"
 EQUB 0

 CHAR 'R'               \ Token 71:     "RED"
 TWOK 'E', 'D'          \
 EQUB 0                 \ Encoded as:   "R<152>"

 CHAR 'Y'               \ Token 72:     "YELLOW"
 CHAR 'E'               \
 RTOK 118               \ Encoded as:   "YE[118]OW"
 CHAR 'O'
 CHAR 'W'
 EQUB 0

 CHAR 'B'               \ Token 73:     "BLUE"
 CHAR 'L'               \
 CHAR 'U'               \ Encoded as:   "BLUE"
 CHAR 'E'
 EQUB 0

 CHAR 'B'               \ Token 74:     "BLACK"
 TWOK 'L', 'A'          \
 CHAR 'C'               \ Encoded as:   "B<149>CK"
 CHAR 'K'
 EQUB 0

 RTOK 136               \ Token 75:     "HARMLESS"
 EQUB 0                 \
                        \ Encoded as:   "[136]"

 CHAR 'S'               \ Token 76:     "SLIMY"
 CHAR 'L'               \
 CHAR 'I'               \ Encoded as:   "SLIMY"
 CHAR 'M'
 CHAR 'Y'
 EQUB 0

 CHAR 'B'               \ Token 77:     "BUG-EYED"
 CHAR 'U'               \
 CHAR 'G'               \ Encoded as:   "BUG-EY<152>"
 CHAR '-'
 CHAR 'E'
 CHAR 'Y'
 TWOK 'E', 'D'
 EQUB 0

 CHAR 'H'               \ Token 78:     "HORNED"
 TWOK 'O', 'R'          \
 CHAR 'N'               \ Encoded as:   "H<153>N<152>"
 TWOK 'E', 'D'
 EQUB 0

 CHAR 'B'               \ Token 79:     "BONY"
 TWOK 'O', 'N'          \
 CHAR 'Y'               \ Encoded as:   "B<159>Y"
 EQUB 0

 CHAR 'F'               \ Token 80:     "FAT"
 TWOK 'A', 'T'          \
 EQUB 0                 \ Encoded as:   "F<145>"

 CHAR 'F'               \ Token 81:     "FURRY"
 CHAR 'U'               \
 CHAR 'R'               \ Encoded as:   "FURRY"
 CHAR 'R'
 CHAR 'Y'
 EQUB 0

 CHAR 'R'               \ Token 82:     "RODENT"
 CHAR 'O'               \
 CHAR 'D'               \ Encoded as:   "ROD<146>T"
 TWOK 'E', 'N'
 CHAR 'T'
 EQUB 0

 CHAR 'F'               \ Token 83:     "FROG"
 CHAR 'R'               \
 CHAR 'O'               \ Encoded as:   "FROG"
 CHAR 'G'
 EQUB 0

 CHAR 'L'               \ Token 84:     "LIZARD"
 CHAR 'I'               \
 TWOK 'Z', 'A'          \ Encoded as:   "LI<132>RD"
 CHAR 'R'
 CHAR 'D'
 EQUB 0

 CHAR 'L'               \ Token 85:     "LOBSTER"
 CHAR 'O'               \
 CHAR 'B'               \ Encoded as:   "LOB[43]<144>"
 RTOK 43
 TWOK 'E', 'R'
 EQUB 0

 TWOK 'B', 'I'          \ Token 86:     "BIRD"
 CHAR 'R'               \
 CHAR 'D'               \ Encoded as:   "<134>RD"
 EQUB 0

 CHAR 'H'               \ Token 87:     "HUMANOID"
 CHAR 'U'               \
 CHAR 'M'               \ Encoded as:   "HUM<155>OID"
 TWOK 'A', 'N'
 CHAR 'O'
 CHAR 'I'
 CHAR 'D'
 EQUB 0

 CHAR 'F'               \ Token 88:     "FELINE"
 CHAR 'E'               \
 CHAR 'L'               \ Encoded as:   "FEL<140>E"
 TWOK 'I', 'N'
 CHAR 'E'
 EQUB 0

 TWOK 'I', 'N'          \ Token 89:     "INSECT"
 CHAR 'S'               \
 CHAR 'E'               \ Encoded as:   "<140>SECT"
 CHAR 'C'
 CHAR 'T'
 EQUB 0

 RTOK 11                \ Token 90:     "AVERAGE RADIUS"
 TWOK 'R', 'A'          \
 TWOK 'D', 'I'          \ Encoded as:   "[11]<148><141><136>"
 TWOK 'U', 'S'
 EQUB 0

 CHAR 'C'               \ Token 91:     "COM"
 CHAR 'O'               \
 CHAR 'M'               \ Encoded as:   "COM"
 EQUB 0

 RTOK 91                \ Token 92:     "COMMANDER"
 CHAR 'M'               \
 TWOK 'A', 'N'          \ Encoded as:   "[91]M<155>D<144>"
 CHAR 'D'
 TWOK 'E', 'R'
 EQUB 0

 CHAR ' '               \ Token 93:     " DESTROYED"
 CHAR 'D'               \
 TWOK 'E', 'S'          \ Encoded as:   " D<137>TROY<152>"
 CHAR 'T'
 CHAR 'R'
 CHAR 'O'
 CHAR 'Y'
 TWOK 'E', 'D'
 EQUB 0

 CHAR 'B'               \ Token 94:     "BY D.BRABEN & I.BELL"
 CHAR 'Y'               \
 CHAR ' '               \ Encoded as:   "BY D.B<148><147>N & I.<147>[118]"
 CHAR 'D'
 CHAR '.'
 CHAR 'B'
 TWOK 'R', 'A'
 TWOK 'B', 'E'
 CHAR 'N'
 CHAR ' '
 CHAR '&'
 CHAR ' '
 CHAR 'I'
 CHAR '.'
 TWOK 'B', 'E'
 RTOK 118
 EQUB 0

 RTOK 14                \ Token 95:     "UNIT  QUANTITY{crlf}
 CHAR ' '               \                 PRODUCT   UNIT PRICE FOR SALE{crlf}
 CHAR ' '               \                                              {lf}"
 RTOK 16                \
 CONT 13                \ Encoded as:   "[14]  [16]{13} [26]   [14] [6] F<153>
 CHAR ' '               \                 SA<129>{13}{10}"
 RTOK 26
 CHAR ' '
 CHAR ' '
 CHAR ' '
 RTOK 14
 CHAR ' '
 RTOK 6
 CHAR ' '
 CHAR 'F'
 TWOK 'O', 'R'
 CHAR ' '
 CHAR 'S'
 CHAR 'A'
 TWOK 'L', 'E'
 CONT 13
 CONT 10
 EQUB 0

 CHAR 'F'               \ Token 96:     "FRONT"
 CHAR 'R'               \
 TWOK 'O', 'N'          \ Encoded as:   "FR<159>T"
 CHAR 'T'
 EQUB 0

 TWOK 'R', 'E'          \ Token 97:     "REAR"
 TWOK 'A', 'R'          \
 EQUB 0                 \ Encoded as:   "<142><138>"

 TWOK 'L', 'E'          \ Token 98:     "LEFT"
 CHAR 'F'               \
 CHAR 'T'               \ Encoded as:   "<129>FT"
 EQUB 0

 TWOK 'R', 'I'          \ Token 99:     "RIGHT"
 CHAR 'G'               \
 CHAR 'H'               \ Encoded as:   "<158>GHT"
 CHAR 'T'
 EQUB 0

 RTOK 121               \ Token 100:    "ENERGY LOW{beep}"
 CHAR 'L'               \
 CHAR 'O'               \ Encoded as:   "[121]LOW{7}"
 CHAR 'W'
 CONT 7
 EQUB 0

 RTOK 99                \ Token 101:    "RIGHT ON COMMANDER!"
 RTOK 131               \
 RTOK 92                \ Encoded as:   "[99][131][92]!"
 CHAR '!'
 EQUB 0

 CHAR 'E'               \ Token 102:    "EXTRA "
 CHAR 'X'               \
 CHAR 'T'               \ Encoded as:   "EXT<148> "
 TWOK 'R', 'A'
 CHAR ' '
 EQUB 0

 CHAR 'P'               \ Token 103:    "PULSE LASER"
 CHAR 'U'               \
 CHAR 'L'               \ Encoded as:   "PULSE[27]"
 CHAR 'S'
 CHAR 'E'
 RTOK 27
 EQUB 0

 TWOK 'B', 'E'          \ Token 104:    "BEAM LASER"
 CHAR 'A'               \
 CHAR 'M'               \ Encoded as:   "<147>AM[27]"
 RTOK 27
 EQUB 0

 CHAR 'F'               \ Token 105:    "FUEL"
 CHAR 'U'               \
 CHAR 'E'               \ Encoded as:   "FUEL"
 CHAR 'L'
 EQUB 0

 CHAR 'M'               \ Token 106:    "MISSILE"
 TWOK 'I', 'S'          \
 CHAR 'S'               \ Encoded as:   "M<157>SI<129>"
 CHAR 'I'
 TWOK 'L', 'E'
 EQUB 0

 RTOK 67                \ Token 107:    "LARGE CARGO{sentence case} BAY"
 RTOK 46                \
 CHAR ' '               \ Encoded as:   "[67][46] BAY"
 CHAR 'B'
 CHAR 'A'
 CHAR 'Y'
 EQUB 0

 CHAR 'E'               \ Token 108:    "E.C.M.SYSTEM"
 CHAR '.'               \
 CHAR 'C'               \ Encoded as:   "E.C.M.[5]"
 CHAR '.'
 CHAR 'M'
 CHAR '.'
 RTOK 5
 EQUB 0

 RTOK 102               \ Token 109:    "EXTRA PULSE LASERS"
 RTOK 103               \
 CHAR 'S'               \ Encoded as:   "[102][103]S"
 EQUB 0

 RTOK 102               \ Token 110:    "EXTRA BEAM LASERS"
 RTOK 104               \
 CHAR 'S'               \ Encoded as:   "[102][104]S"
 EQUB 0

 RTOK 105               \ Token 111:    "FUEL SCOOPS"
 CHAR ' '               \
 CHAR 'S'               \ Encoded as:   "[105] SCOOPS"
 CHAR 'C'
 CHAR 'O'
 CHAR 'O'
 CHAR 'P'
 CHAR 'S'
 EQUB 0

 TWOK 'E', 'S'          \ Token 112:    "ESCAPE POD"
 CHAR 'C'               \
 CHAR 'A'               \ Encoded as:   "<137>CAPE POD"
 CHAR 'P'
 CHAR 'E'
 CHAR ' '
 CHAR 'P'
 CHAR 'O'
 CHAR 'D'
 EQUB 0

 RTOK 121               \ Token 113:    "ENERGY BOMB"
 CHAR 'B'               \
 CHAR 'O'               \ Encoded as:   "[121]BOMB"
 CHAR 'M'
 CHAR 'B'
 EQUB 0

 RTOK 121               \ Token 114:    "ENERGY UNIT"
 RTOK 14                \
 EQUB 0                 \ Encoded as:   "[121][14]"

 RTOK 124               \ Token 115:    "DOCKING COMPUTERS"
 TWOK 'I', 'N'          \
 CHAR 'G'               \ Encoded as:   "[124]<140>G [55]"
 CHAR ' '
 RTOK 55
 EQUB 0

 RTOK 122               \ Token 116:    "GALACTIC HYPERSPACE "
 CHAR ' '               \
 RTOK 29                \ Encoded as:   "[122] [29]"
 EQUB 0

 CHAR 'A'               \ Token 117:    "ALL"
 RTOK 118               \
 EQUB 0                 \ Encoded as:   "A[118]"

 CHAR 'L'               \ Token 118:    "LL"
 CHAR 'L'               \
 EQUB 0                 \ Encoded as:   "LL"

 RTOK 37                \ Token 119:    "CASH:{cash} CR{crlf}
 CHAR ':'               \               "
 CONT 0                 \
 EQUB 0                 \ Encoded as:   "[37]:{0}"

 TWOK 'I', 'N'          \ Token 120:    "INCOMING MISSILE"
 RTOK 91                \
 TWOK 'I', 'N'          \ Encoded as:   "<140>[91]<140>G [106]"
 CHAR 'G'
 CHAR ' '
 RTOK 106
 EQUB 0

 TWOK 'E', 'N'          \ Token 121:    "ENERGY "
 TWOK 'E', 'R'          \
 CHAR 'G'               \ Encoded as:   "<146><144>GY "
 CHAR 'Y'
 CHAR ' '
 EQUB 0

 CHAR 'G'               \ Token 122:    "GALACTIC"
 CHAR 'A'               \
 TWOK 'L', 'A'          \ Encoded as:   "GA<149>C<151>C"
 CHAR 'C'
 TWOK 'T', 'I'
 CHAR 'C'
 EQUB 0

 CONT 13                \ Token 123:    "{crlf}
 RTOK 92                \                COMMANDER'S NAME? "
 CHAR '`'               \
 CHAR 'S'               \ Encoded as:   "{13}[92]'S NAME? "
 CHAR ' '
 CHAR 'N'
 CHAR 'A'
 CHAR 'M'
 CHAR 'E'
 CHAR '?'
 CHAR ' '
 EQUB 0

 CHAR 'D'               \ Token 124:    "DOCK"
 CHAR 'O'               \
 CHAR 'C'               \ Encoded as:   "DOCK"
 CHAR 'K'
 EQUB 0

 CONT 5                 \ Token 125:    "FUEL: {fuel level} LIGHT YEARS{crlf}
 TWOK 'L', 'E'          \                CASH:{cash} CR{crlf}
 CHAR 'G'               \                LEGAL STATUS:"
 TWOK 'A', 'L'          \
 CHAR ' '               \ Encoded as:   "{5}<129>G<128> [43]<145><136>:"
 RTOK 43
 TWOK 'A', 'T'
 TWOK 'U', 'S'
 CHAR ':'
 EQUB 0

 RTOK 92                \ Token 126:    "COMMANDER {commander name}{crlf}
 CHAR ' '               \                {crlf}
 CONT 4                 \                {crlf}
 CONT 13                \                {sentence case}PRESENT SYSTEM{tab to
 CONT 13                \                column 21}:{current system name}{crlf}
 CONT 13                \                HYPERSPACE SYSTEM{tab to column 21}:
 CONT 6                 \                {selected system name}{crlf}
 RTOK 145               \                CONDITION{tab to column 21}:"
 CHAR ' '               \
 RTOK 5                 \ Encoded as:   "[92] {4}{13}{13}{13}{6}[145] [5]{9}{2}
 CONT 9                 \                {13}[29][5]{9}{3}{13}C<159><141><151>
 CONT 2                 \                <159>{9}"
 CONT 13
 RTOK 29
 RTOK 5
 CONT 9
 CONT 3
 CONT 13
 CHAR 'C'
 TWOK 'O', 'N'
 TWOK 'D', 'I'
 TWOK 'T', 'I'
 TWOK 'O', 'N'
 CONT 9
 EQUB 0

 CHAR 'I'               \ Token 127:    "ITEM"
 TWOK 'T', 'E'          \
 CHAR 'M'               \ Encoded as:   "I<156>M"
 EQUB 0

 CHAR ' '               \ Token 128:    "  LOAD NEW COMMANDER (Y/N)?{crlf}
 CHAR ' '               \                {crlf}
 CHAR 'L'               \               "
 CHAR 'O'               \
 CHAR 'A'               \ Encoded as:   "  LOAD NEW [92] [65]{13}{13}"
 CHAR 'D'
 CHAR ' '
 CHAR 'N'
 CHAR 'E'
 CHAR 'W'
 CHAR ' '
 RTOK 92
 CHAR ' '
 RTOK 65
 CONT 13
 CONT 13
 EQUB 0

 CONT 6                 \ Token 129:    "{sentence case}DOCKED"
 RTOK 124               \
 TWOK 'E', 'D'          \ Encoded as:   "{6}[124]<152>"
 EQUB 0

 TWOK 'R', 'A'          \ Token 130:    "RATING:"
 TWOK 'T', 'I'          \
 CHAR 'N'               \ Encoded as:   "<148><151>NG:"
 CHAR 'G'
 CHAR ':'
 EQUB 0

 CHAR ' '               \ Token 131:    " ON "
 TWOK 'O', 'N'          \
 CHAR ' '               \ Encoded as:   " <159> "
 EQUB 0

 CONT 13                \ Token 132:    "{crlf}
 CONT 8                 \                {all caps}EQUIPMENT: {sentence case}"
 RTOK 47                \
 CHAR 'M'               \ Encoded as:   "{13}{8}[47]M<146>T:{6}"
 TWOK 'E', 'N'
 CHAR 'T'
 CHAR ':'
 CONT 6
 EQUB 0

 CHAR 'C'               \ Token 133:    "CLEAN"
 TWOK 'L', 'E'          \
 TWOK 'A', 'N'          \ Encoded as:   "C<129><155>"
 EQUB 0

 CHAR 'O'               \ Token 134:    "OFFENDER"
 CHAR 'F'               \
 CHAR 'F'               \ Encoded as:   "OFF<146>D<144>"
 TWOK 'E', 'N'
 CHAR 'D'
 TWOK 'E', 'R'
 EQUB 0

 CHAR 'F'               \ Token 135:    "FUGITIVE"
 CHAR 'U'               \
 CHAR 'G'               \ Encoded as:   "FUGI<151><150>"
 CHAR 'I'
 TWOK 'T', 'I'
 TWOK 'V', 'E'
 EQUB 0

 CHAR 'H'               \ Token 136:    "HARMLESS"
 TWOK 'A', 'R'          \
 CHAR 'M'               \ Encoded as:   "H<138>M<129>SS"
 TWOK 'L', 'E'
 CHAR 'S'
 CHAR 'S'
 EQUB 0

 CHAR 'M'               \ Token 137:    "MOSTLY HARMLESS"
 CHAR 'O'               \
 RTOK 43                \ Encoded as:   "MO[43]LY [136]"
 CHAR 'L'
 CHAR 'Y'
 CHAR ' '
 RTOK 136
 EQUB 0

 RTOK 12                \ Token 138:    "POOR "
 EQUB 0                 \
                        \ Encoded as:   "[12]"

 RTOK 11                \ Token 139:    "AVERAGE "
 EQUB 0                 \
                        \ Encoded as:   "[11]"

 CHAR 'A'               \ Token 140:    "ABOVE AVERAGE "
 CHAR 'B'               \
 CHAR 'O'               \ Encoded as:   "ABO<150> [11]"
 TWOK 'V', 'E'
 CHAR ' '
 RTOK 11
 EQUB 0

 RTOK 91                \ Token 141:    "COMPETENT"
 CHAR 'P'               \
 CHAR 'E'               \ Encoded as:   "[91]PET<146>T"
 CHAR 'T'
 TWOK 'E', 'N'
 CHAR 'T'
 EQUB 0

 CHAR 'D'               \ Token 142:    "DANGEROUS"
 TWOK 'A', 'N'          \
 TWOK 'G', 'E'          \ Encoded as:   "D<155><131>RO<136>"
 CHAR 'R'
 CHAR 'O'
 TWOK 'U', 'S'
 EQUB 0

 CHAR 'D'               \ Token 143:    "DEADLY"
 CHAR 'E'               \
 CHAR 'A'               \ Encoded as:   "DEADLY"
 CHAR 'D'
 CHAR 'L'
 CHAR 'Y'
 EQUB 0

 CHAR '-'               \ Token 144:    "---- E L I T E ----"
 CHAR '-'               \
 CHAR '-'               \ Encoded as:   "---- E L I T E ----"
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

 CHAR 'P'               \ Token 145:    "PRESENT"
 TWOK 'R', 'E'          \
 CHAR 'S'               \ Encoded as:   "P<142>S<146>T"
 TWOK 'E', 'N'
 CHAR 'T'
 EQUB 0

 CONT 8                 \ Token 146:    "{all caps}GAME OVER"
 CHAR 'G'               \
 CHAR 'A'               \ Encoded as:   "{8}GAME O<150>R"
 CHAR 'M'
 CHAR 'E'
 CHAR ' '
 CHAR 'O'
 TWOK 'V', 'E'
 CHAR 'R'
 EQUB 0

 CHAR 'P'               \ Token 147:    "PRESS FIRE OR SPACE,COMMANDER.{crlf}
 CHAR 'R'               \                {crlf}
 TWOK 'E', 'S'          \               "
 CHAR 'S'               \
 CHAR ' '               \ Encoded as:   "PR<137>S FI<142> <153> SPA<133>,[92].
 CHAR 'F'               \                {13}{13}"
 CHAR 'I'
 TWOK 'R', 'E'
 CHAR ' '
 TWOK 'O', 'R'
 CHAR ' '
 CHAR 'S'
 CHAR 'P'
 CHAR 'A'
 TWOK 'C', 'E'
 CHAR ','
 RTOK 92
 CHAR '.'
 CONT 13
 CONT 13
 EQUB 0

 CHAR '('               \ Token 148:    "(C) ACORNSOFT 1984"
 CHAR 'C'               \
 CHAR ')'               \ Encoded as:   "(C) AC<153>N<135>FT 1984"
 CHAR ' '
 CHAR 'A'
 CHAR 'C'
 TWOK 'O', 'R'
 CHAR 'N'
 TWOK 'S', 'O'
 CHAR 'F'
 CHAR 'T'
 CHAR ' '
 CHAR '1'
 CHAR '9'
 CHAR '8'
 CHAR '4'
 EQUB 0

\ ******************************************************************************
\
\ Save WORDS9.bin
\
\ ******************************************************************************

PRINT "WORDS9"
PRINT "Assembled at ", ~CODE_WORDS%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_WORDS%)
PRINT "Execute at ", ~LOAD_WORDS%
PRINT "Reload at ", ~LOAD_WORDS%

PRINT "S.WORDS9 ",~CODE_WORDS%," ",~P%," ",~LOAD_WORDS%," ",~LOAD_WORDS%
SAVE "3-assembled-output/WORDS9.bin", CODE_WORDS%, P%, LOAD_WORDS%

\ ******************************************************************************
\
\       Name: K%
\       Type: Workspace
\    Address: &0900 to &0D3F
\   Category: Workspaces
\    Summary: Ship data blocks and ship line heaps
\  Deep dive: Ship data blocks
\             The local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ Contains ship data for all the ships, planets, suns and space stations in our
\ local bubble of universe, along with their corresponding ship line heaps.
\
\ The blocks are pointed to by the lookup table at location UNIV. The first 432
\ bytes of the K% workspace hold ship data on up to 12 ships, with 36 (NI%)
\ bytes per ship, and the ship line heap grows downwards from WP at the end of
\ the K% workspace.
\
\ See the deep dive on "Ship data blocks" for details on ship data blocks, and
\ the deep dive on "The local bubble of universe" for details of how Elite
\ stores the local universe in K%, FRIN and UNIV.
\
\ ******************************************************************************

ORG &0900

.K%

 SKIP 0                 \ Ship data blocks and ship line heap

\ ******************************************************************************
\
\       Name: WP
\       Type: Workspace
\    Address: &0D40 to &0F33
\   Category: Workspaces
\    Summary: Ship slots, variables
\
\ ******************************************************************************

ORG &0D40

.WP

 SKIP 0                 \ The start of the WP workspace

.FRIN

 SKIP NOSH + 1          \ Slots for the ships in the local bubble of universe
                        \
                        \ There are #NOSH + 1 slots, but the ship-spawning
                        \ routine at NWSHP only populates #NOSH of them, so
                        \ there are 13 slots but only 12 are used for ships
                        \ (the last slot is effectively used as a null
                        \ terminator when shuffling the slots down in the
                        \ KILLSHP routine)
                        \
                        \ See the deep dive on "The local bubble of universe"
                        \ for details of how Elite stores the local universe in
                        \ FRIN, UNIV and K%

.CABTMP

 SKIP 0                 \ Cabin temperature
                        \
                        \ The ambient cabin temperature in deep space is 30,
                        \ which is displayed as one notch on the dashboard bar
                        \
                        \ We get higher temperatures closer to the sun
                        \
                        \ CABTMP shares a location with MANY, but that's OK as
                        \ MANY+0 would contain the number of ships of type 0,
                        \ and as there is no ship type 0 (they start at 1), the
                        \ byte at MANY+0 is not used for storing a ship type
                        \ and can be used for the cabin temperature instead

.MANY

 SKIP SST               \ The number of ships of each type in the local bubble
                        \ of universe
                        \
                        \ The number of ships of type X in the local bubble is
                        \ stored at MANY+X, so the number of Sidewinders is at
                        \ MANY+1, the number of Mambas is at MANY+2, and so on
                        \
                        \ See the deep dive on "Ship blueprints" for a list of
                        \ ship types

.SSPR

 SKIP NTY + 1 - SST     \ "Space station present" flag
                        \
                        \   * Non-zero if we are inside the space station's safe
                        \     zone
                        \
                        \   * 0 if we aren't (in which case we can show the sun)
                        \
                        \ This flag is at MANY+SST, which is no coincidence, as
                        \ MANY+SST is a count of how many space stations there
                        \ are in our local bubble, which is the same as saying
                        \ "space station present"

.ECMP

 SKIP 1                 \ Our E.C.M. status
                        \
                        \   * 0 = E.C.M. is off
                        \
                        \   * Non-zero = E.C.M. is on

.MJ

 SKIP 1                 \ Are we in witchspace (i.e. have we mis-jumped)?
                        \
                        \   * 0 = no, we are in normal space
                        \
                        \   * &FF = yes, we are in witchspace

.LAS2

 SKIP 1                 \ Laser power for the current laser
                        \
                        \   * Bits 0-6 contain the laser power of the current
                        \     space view
                        \
                        \   * Bit 7 denotes whether or not the laser pulses:
                        \
                        \     * 0 = pulsing laser
                        \
                        \     * 1 = beam laser (i.e. always on)

.MSAR

 SKIP 1                 \ The targeting state of our leftmost missile
                        \
                        \   * 0 = missile is not looking for a target, or it
                        \     already has a target lock (indicator is not
                        \     yellow/white)
                        \
                        \   * Non-zero = missile is currently looking for a
                        \     target (indicator is yellow/white)

.VIEW

 SKIP 1                 \ The number of the current space view
                        \
                        \   * 0 = front
                        \   * 1 = rear
                        \   * 2 = left
                        \   * 3 = right

.LASCT

 SKIP 1                 \ The laser pulse count for the current laser
                        \
                        \ This is a counter that defines the gap between the
                        \ pulses of a pulse laser. It is set as follows:
                        \
                        \   * 0 for a beam laser
                        \
                        \   * 10 for a pulse laser
                        \
                        \ It gets decremented every vertical sync (in the LINSCN
                        \ routine, which is called 50 times a second) and is set
                        \ to a non-zero value for pulse lasers only
                        \
                        \ The laser only fires when the value of LASCT hits
                        \ zero, so for pulse lasers with a value of 10, that
                        \ means the laser fires once every 10 vertical syncs (or
                        \ 5 times a second)
                        \
                        \ In comparison, beam lasers fire continuously as the
                        \ value of LASCT is always 0

.GNTMP

 SKIP 1                 \ Laser temperature (or "gun temperature")
                        \
                        \ If the laser temperature exceeds 242 then the laser
                        \ overheats and cannot be fired again until it has
                        \ cooled down

.HFX

 SKIP 1                 \ A flag that toggles the hyperspace colour effect
                        \
                        \   * 0 = no colour effect
                        \
                        \   * Non-zero = hyperspace colour effect enabled
                        \
                        \ When HFX is set to 1, the mode 4 screen that makes
                        \ up the top part of the display is temporarily switched
                        \ to mode 5 (the same screen mode as the dashboard),
                        \ which has the effect of blurring and colouring the
                        \ hyperspace rings in the top part of the screen. The
                        \ code to do this is in the LINSCN routine, which is
                        \ called as part of the screen mode routine at IRQ1.
                        \ It's in LINSCN that HFX is checked, and if it is
                        \ non-zero, the top part of the screen is not switched
                        \ to mode 4, thus leaving the top part of the screen in
                        \ the more colourful mode 5

.EV

 SKIP 1                 \ The "extra vessels" spawning counter
                        \
                        \ This counter is set to 0 on arrival in a system and
                        \ following an in-system jump, and is bumped up when we
                        \ spawn bounty hunters or pirates (i.e. "extra vessels")
                        \
                        \ It decreases by 1 each time we consider spawning more
                        \ "extra vessels" in part 4 of the main game loop, so
                        \ increasing the value of EV has the effect of delaying
                        \ the spawning of more vessels
                        \
                        \ In other words, this counter stops bounty hunters and
                        \ pirates from continually appearing, and ensures that
                        \ there's a delay between spawnings

.DLY

 SKIP 1                 \ In-flight message delay
                        \
                        \ This counter is used to keep an in-flight message up
                        \ for a specified time before it gets removed. The value
                        \ in DLY is decremented each time we start another
                        \ iteration of the main game loop at TT100

.de

 SKIP 1                 \ Equipment destruction flag
                        \
                        \   * Bit 1 denotes whether or not the in-flight message
                        \     about to be shown by the MESS routine is about
                        \     destroyed equipment:
                        \
                        \     * 0 = the message is shown normally
                        \
                        \     * 1 = the string " DESTROYED" gets added to the
                        \       end of the message

.LSX

 SKIP 0                 \ LSX is an alias that points to the first byte of the
                        \ sun line heap at LSO
                        \
                        \   * &FF indicates the sun line heap is empty
                        \
                        \   * Otherwise the LSO heap contains the line data for
                        \     the sun

.LSO

 SKIP 192               \ The ship line heap for the space station (see NWSPS)
                        \ and the sun line heap (see SUN)
                        \
                        \ The spaces can be shared as our local bubble of
                        \ universe can support either the sun or a space
                        \ station, but not both

.LSX2

 SKIP 78                \ The ball line heap for storing x-coordinates (see the
                        \ deep dive on "The ball line heap" for details)

.LSY2

 SKIP 78                \ The ball line heap for storing y-coordinates (see the
                        \ deep dive on "The ball line heap" for details)

.SY

 SKIP NOST + 1          \ This is where we store the y_hi coordinates for all
                        \ the stardust particles

.SYL

 SKIP NOST + 1          \ This is where we store the y_lo coordinates for all
                        \ the stardust particles

.SZ

 SKIP NOST + 1          \ This is where we store the z_hi coordinates for all
                        \ the stardust particles

.SZL

 SKIP NOST + 1          \ This is where we store the z_lo coordinates for all
                        \ the stardust particles

.XSAV2

 SKIP 1                 \ Temporary storage, used for storing the value of the X
                        \ register in the TT26 routine

.YSAV2

 SKIP 1                 \ Temporary storage, used for storing the value of the Y
                        \ register in the TT26 routine

.MCH

 SKIP 1                 \ The text token number of the in-flight message that is
                        \ currently being shown, and which will be removed by
                        \ the me2 routine when the counter in DLY reaches zero

.FSH

 SKIP 1                 \ Forward shield status
                        \
                        \   * 0 = empty
                        \
                        \   * &FF = full

.ASH

 SKIP 1                 \ Aft shield status
                        \
                        \   * 0 = empty
                        \
                        \   * &FF = full

.ENERGY

 SKIP 1                 \ Energy bank status
                        \
                        \   * 0 = empty
                        \
                        \   * &FF = full

.LASX

 SKIP 1                 \ The x-coordinate of the tip of the laser line

.LASY

 SKIP 1                 \ The y-coordinate of the tip of the laser line

.COMX

 SKIP 1                 \ The x-coordinate of the compass dot

.COMY

 SKIP 1                 \ The y-coordinate of the compass dot

.QQ24

 SKIP 1                 \ Temporary storage, used to store the current market
                        \ item's price in routine TT151

.QQ25

 SKIP 1                 \ Temporary storage, used to store the current market
                        \ item's availability in routine TT151

.QQ28

 SKIP 1                 \ The current system's economy (0-7)
                        \
                        \   * 0 = Rich Industrial
                        \   * 1 = Average Industrial
                        \   * 2 = Poor Industrial
                        \   * 3 = Mainly Industrial
                        \   * 4 = Mainly Agricultural
                        \   * 5 = Rich Agricultural
                        \   * 6 = Average Agricultural
                        \   * 7 = Poor Agricultural
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ information on economies

.QQ29

 SKIP 1                 \ Temporary storage, used in a number of places

.gov

 SKIP 1                 \ The current system's government type (0-7)
                        \
                        \ See the deep dive on "Generating system data" for
                        \ details of the various government types

.tek

 SKIP 1                 \ The current system's tech level (0-14)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ information on tech levels

.SLSP

 SKIP 2                 \ The address of the bottom of the ship line heap
                        \
                        \ The ship line heap is a descending block of memory
                        \ that starts at WP and descends down to SLSP. It can be
                        \ extended downwards by the NWSHP routine when adding
                        \ new ships (and their associated ship line heaps), in
                        \ which case SLSP is lowered to provide more heap space,
                        \ assuming there is enough free memory to do so

.XX24

 SKIP 1                 \ This byte appears to be unused

.ALTIT

 SKIP 1                 \ Our altitude above the surface of the planet or sun
                        \
                        \   * 255 = we are a long way above the surface
                        \
                        \   * 1-254 = our altitude as the square root of:
                        \
                        \       x_hi^2 + y_hi^2 + z_hi^2 - 6^2
                        \
                        \     where our ship is at the origin, the centre of the
                        \     planet/sun is at (x_hi, y_hi, z_hi), and the
                        \     radius of the planet/sun is 6
                        \
                        \   * 0 = we have crashed into the surface

.QQ2

 SKIP 6                 \ The three 16-bit seeds for the current system, i.e.
                        \ the one we are currently in
                        \
                        \ See the deep dives on "Galaxy and system seeds" and
                        \ "Twisting the system seeds" for more details

.QQ3

 SKIP 1                 \ The selected system's economy (0-7)
                        \
                        \   * 0 = Rich Industrial
                        \   * 1 = Average Industrial
                        \   * 2 = Poor Industrial
                        \   * 3 = Mainly Industrial
                        \   * 4 = Mainly Agricultural
                        \   * 5 = Rich Agricultural
                        \   * 6 = Average Agricultural
                        \   * 7 = Poor Agricultural
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ information on economies

.QQ4

 SKIP 1                 \ The selected system's government (0-7)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ details of the various government types

.QQ5

 SKIP 1                 \ The selected system's tech level (0-14)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ information on tech levels

.QQ6

 SKIP 2                 \ The selected system's population in billions * 10
                        \ (1-71), so the maximum population is 7.1 billion
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ details on population levels

.QQ7

 SKIP 2                 \ The selected system's productivity in M CR (96-62480)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ details about productivity levels

.QQ8

 SKIP 2                 \ The distance from the current system to the selected
                        \ system in light years * 10, stored as a 16-bit number
                        \
                        \ The distance will be 0 if the selected sysyem is the
                        \ current system
                        \
                        \ The galaxy chart is 102.4 light years wide and 51.2
                        \ light years tall (see the intra-system distance
                        \ calculations in routine TT111 for details), which
                        \ equates to 1024 x 512 in terms of QQ8

.QQ9

 SKIP 1                 \ The galactic x-coordinate of the crosshairs in the
                        \ galaxy chart (and, most of the time, the selected
                        \ system's galactic x-coordinate)

.QQ10

 SKIP 1                 \ The galactic y-coordinate of the crosshairs in the
                        \ galaxy chart (and, most of the time, the selected
                        \ system's galactic y-coordinate)

.NOSTM

 SKIP 1                 \ The number of stardust particles shown on screen,
                        \ which is 18 (#NOST) for normal space, and 3 for
                        \ witchspace

PRINT "WP workspace from  ", ~WP," to ", ~P%

\ ******************************************************************************
\
\ ELITE A FILE
\
\ Produces the binary file ELTA.bin that gets loaded by elite-bcfs.asm.
\
\ The main game code (ELITE A through G, plus the ship data) is loaded at &1128
\ and is moved down to &0F40 as part of elite-loader.asm.
\
\ ******************************************************************************

CODE% = &0F40
LOAD% = &1128

ORG CODE%

LOAD_A% = LOAD%

\ ******************************************************************************
\
\       Name: S%
\       Type: Workspace
\    Address: &0F40 to &0F50
\   Category: Workspaces
\    Summary: Vector addresses, compass colour and configuration settings
\
\ ------------------------------------------------------------------------------
\
\ Contains addresses that are used by the loader to set up vectors, the current
\ compass colour, and the game's configuration settings.
\
\ ******************************************************************************

.S%

 EQUW TT170             \ The entry point for the main game; once the main code
                        \ has been loaded, decrypted and moved to the right
                        \ place by elite-loader.asm, the game is started by a
                        \ JMP (S%) instruction, which jumps to the main entry
                        \ point at TT170 via this location

 EQUW TT26              \ WRCHV is set to point here by elite-loader.asm

 EQUW IRQ1              \ IRQ1V is set to point here by elite-loader.asm

 EQUW BR1               \ BRKV is set to point here by elite-loader.asm

.COMC

 SKIP 1                 \ The colour of the dot on the compass
                        \
                        \   * &F0 = the object in the compass is in front of us,
                        \     so the dot is yellow/white
                        \
                        \   * &FF = the object in the compass is behind us, so
                        \     the dot is green/cyan

.DNOIZ

 SKIP 1                 \ Sound on/off configuration setting
                        \
                        \   * 0 = sound is on (default)
                        \
                        \   * Non-zero = sound is off
                        \
                        \ Toggled by pressing "S" when paused, see the DK4
                        \ routine for details

.DAMP

 SKIP 1                 \ Keyboard damping configuration setting
                        \
                        \   * 0 = damping is enabled (default)
                        \
                        \   * &FF = damping is disabled
                        \
                        \ Toggled by pressing CAPS LOCK when paused, see the
                        \ DKS3 routine for details

.DJD

 SKIP 1                 \ Keyboard auto-recentre configuration setting
                        \
                        \   * 0 = auto-recentre is enabled (default)
                        \
                        \   * &FF = auto-recentre is disabled
                        \
                        \ Toggled by pressing "A" when paused, see the DKS3
                        \ routine for details

.PATG

 SKIP 1                 \ Configuration setting to show the author names on the
                        \ start-up screen and enable manual hyperspace mis-jumps
                        \
                        \   * 0 = no author names or manual mis-jumps (default)
                        \
                        \   * &FF = show author names and allow manual mis-jumps
                        \
                        \ Toggled by pressing "X" when paused, see the DKS3
                        \ routine for details
                        \
                        \ This needs to be turned on for manual mis-jumps to be
                        \ possible. To do a manual mis-jump, first toggle the
                        \ author display by pausing the game (COPY) and pressing
                        \ "X", and during the next hyperspace, hold down CTRL to
                        \ force a mis-jump. See routine ee5 for the "AND PATG"
                        \ instruction that implements this logic

.FLH

 SKIP 1                 \ Flashing console bars configuration setting
                        \
                        \   * 0 = static bars (default)
                        \
                        \   * &FF = flashing bars
                        \
                        \ Toggled by pressing "F" when paused, see the DKS3
                        \ routine for details

.JSTGY

 SKIP 1                 \ Reverse joystick Y-channel configuration setting
                        \
                        \   * 0 = standard Y-channel (default)
                        \
                        \   * &FF = reversed Y-channel
                        \
                        \ Toggled by pressing "Y" when paused, see the DKS3
                        \ routine for details

.JSTE

 SKIP 1                 \ Reverse both joystick channels configuration setting
                        \
                        \   * 0 = standard channels (default)
                        \
                        \   * &FF = reversed channels
                        \
                        \ Toggled by pressing "J" when paused, see the DKS3
                        \ routine for details

.JSTK

 SKIP 1                 \ Keyboard or joystick configuration setting
                        \
                        \   * 0 = keyboard (default)
                        \
                        \   * &FF = joystick
                        \
                        \ Toggled by pressing "K" when paused, see the DKS3
                        \ routine for details

\ ******************************************************************************
\
\       Name: Main flight loop (Part 1 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Seed the random number generator
\  Deep dive: Program flow of the main game loop
\             Generating random numbers
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Seed the random number generator
\
\ Other entry points:
\
\   M%                  The entry point for the main flight loop
\
\ ******************************************************************************

.M%

 LDA K%                 \ We want to seed the random number generator with a
                        \ pretty random number, so fetch the contents of K%,
                        \ which is the x_lo coordinate of the planet. This value
                        \ will be fairly unpredictable, so it's a pretty good
                        \ candidate

 STA RAND               \ Store the seed in the first byte of the four-byte
                        \ random number seed that's stored in RAND

\ ******************************************************************************
\
\       Name: Main flight loop (Part 2 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Calculate the alpha and beta angles from the current pitch and
\             roll of our ship
\  Deep dive: Program flow of the main game loop
\             Pitching and rolling
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Calculate the alpha and beta angles from the current pitch and roll
\
\ Here we take the current rate of pitch and roll, as set by the joystick or
\ keyboard, and convert them into alpha and beta angles that we can use in the
\ matrix functions to rotate space around our ship. The alpha angle covers
\ roll, while the beta angle covers pitch (there is no yaw in this version of
\ Elite). The angles are in radians, which allows us to use the small angle
\ approximation when moving objects in the sky (see the MVEIT routine for more
\ on this). Also, the signs of the two angles are stored separately, in both
\ the sign and the flipped sign, as this makes calculations easier.
\
\ ******************************************************************************

 LDX JSTX               \ Set X to the current rate of roll in JSTX

 JSR cntr               \ Apply keyboard damping twice (if enabled) so the roll
 JSR cntr               \ rate in X creeps towards the centre by 2

                        \ The roll rate in JSTX increases if we press ">" (and
                        \ the RL indicator on the dashboard goes to the right).
                        \ This rolls our ship to the right (clockwise), but we
                        \ actually implement this by rolling everything else
                        \ to the left (anticlockwise), so a positive roll rate
                        \ in JSTX translates to a negative roll angle alpha

 TXA                    \ Set A and Y to the roll rate but with the sign bit
 EOR #%10000000         \ flipped (i.e. set them to the sign we want for alpha)
 TAY

 AND #%10000000         \ Extract the flipped sign of the roll rate and store
 STA ALP2               \ in ALP2 (so ALP2 contains the sign of the roll angle
                        \ alpha)

 STX JSTX               \ Update JSTX with the damped value that's still in X

 EOR #%10000000         \ Extract the correct sign of the roll rate and store
 STA ALP2+1             \ in ALP2+1 (so ALP2+1 contains the flipped sign of the
                        \ roll angle alpha)

 TYA                    \ Set A to the roll rate but with the sign bit flipped

 BPL P%+7               \ If the value of A is positive, skip the following
                        \ three instructions

 EOR #%11111111         \ A is negative, so change the sign of A using two's
 CLC                    \ complement so that A is now positive and contains
 ADC #1                 \ the absolute value of the roll rate, i.e. |JSTX|

 LSR A                  \ Divide the (positive) roll rate in A by 4
 LSR A

 CMP #8                 \ If A >= 8, skip the following two instructions
 BCS P%+4

 LSR A                  \ A < 8, so halve A again

 CLC                    \ This instruction has no effect, as we only get here
                        \ if the C flag is clear (if it is set, we skip this
                        \ instruction)

 STA ALP1               \ Store A in ALP1, so we now have:
                        \
                        \   ALP1 = |JSTX| / 8    if |JSTX| < 32
                        \
                        \   ALP1 = |JSTX| / 4    if |JSTX| >= 32
                        \
                        \ This means that at lower roll rates, the roll angle is
                        \ reduced closer to zero than at higher roll rates,
                        \ which gives us finer control over the ship's roll at
                        \ lower roll rates
                        \
                        \ Because JSTX is in the range -127 to +127, ALP1 is
                        \ in the range 0 to 31

 ORA ALP2               \ Store A in ALPHA, but with the sign set to ALP2 (so
 STA ALPHA              \ ALPHA has a different sign to the actual roll rate)

 LDX JSTY               \ Set X to the current rate of pitch in JSTY

 JSR cntr               \ Apply keyboard damping so the pitch rate in X creeps
                        \ towards the centre by 1

 TXA                    \ Set A and Y to the pitch rate but with the sign bit
 EOR #%10000000         \ flipped
 TAY

 AND #%10000000         \ Extract the flipped sign of the pitch rate into A

 STX JSTY               \ Update JSTY with the damped value that's still in X

 STA BET2+1             \ Store the flipped sign of the pitch rate in BET2+1

 EOR #%10000000         \ Extract the correct sign of the pitch rate and store
 STA BET2               \ it in BET2

 TYA                    \ Set A to the pitch rate but with the sign bit flipped

 BPL P%+4               \ If the value of A is positive, skip the following
                        \ instruction

 EOR #%11111111         \ A is negative, so flip the bits

 ADC #4                 \ Add 4 to the (positive) pitch rate, so the maximum
                        \ value is now up to 131 (rather than 127)

 LSR A                  \ Divide the (positive) pitch rate in A by 16
 LSR A
 LSR A
 LSR A

 CMP #3                 \ If A >= 3, skip the following instruction
 BCS P%+3

 LSR A                  \ A < 3, so halve A again

 STA BET1               \ Store A in BET1, so we now have:
                        \
                        \   BET1 = |JSTY| / 32    if |JSTY| < 48
                        \
                        \   BET1 = |JSTY| / 16    if |JSTY| >= 48
                        \
                        \ This means that at lower pitch rates, the pitch angle
                        \ is reduced closer to zero than at higher pitch rates,
                        \ which gives us finer control over the ship's pitch at
                        \ lower pitch rates
                        \
                        \ Because JSTY is in the range -131 to +131, BET1 is in
                        \ the range 0 to 8

 ORA BET2               \ Store A in BETA, but with the sign set to BET2 (so
 STA BETA               \ BETA has the same sign as the actual pitch rate)

\ ******************************************************************************
\
\       Name: Main flight loop (Part 3 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Scan for flight keys and process the results
\  Deep dive: Program flow of the main game loop
\             The key logger
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Scan for flight keys and process the results
\
\ Flight keys are logged in the key logger at location KY1 onwards, with a
\ non-zero value in the relevant location indicating a key press. See the deep
\ dive on "The key logger" for more details.
\
\ The key presses that are processed are as follows:
\
\   * Space and "?" to speed up and slow down
\   * "U", "T" and "M" to disarm, arm and fire missiles
\   * TAB to fire an energy bomb
\   * ESCAPE to launch an escape pod
\   * "J" to initiate an in-system jump
\   * "E" to deploy E.C.M. anti-missile countermeasures
\   * "C" to use the docking computer
\   * "A" to fire lasers
\
\ ******************************************************************************

 LDA KY2                \ If Space is being pressed, keep going, otherwise jump
 BEQ MA17               \ down to MA17 to skip the following

 LDA DELTA              \ The "go faster" key is being pressed, so first we
 CMP #40                \ fetch the current speed from DELTA into A, and if
 BCS MA17               \ A >= 40, we are already going at full pelt, so jump
                        \ down to MA17 to skip the following

 INC DELTA              \ We can go a bit faster, so increment the speed in
                        \ location DELTA

.MA17

 LDA KY1                \ If "?" is being pressed, keep going, otherwise jump
 BEQ MA4                \ down to MA4 to skip the following

 DEC DELTA              \ The "slow down" key is being pressed, so we decrement
                        \ the current ship speed in DELTA

 BNE MA4                \ If the speed is still greater than zero, jump to MA4

 INC DELTA              \ Otherwise we just braked a little too hard, so bump
                        \ the speed back up to the minimum value of 1

.MA4

 LDA KY15               \ If "U" is being pressed and the number of missiles
 AND NOMSL              \ in NOMSL is non-zero, keep going, otherwise jump down
 BEQ MA20               \ to MA20 to skip the following

 LDY #&EE               \ The "disarm missiles" key is being pressed, so call
 JSR ABORT              \ ABORT to disarm the missile and update the missile
                        \ indicators on the dashboard to green/cyan (Y = &EE)

 LDA #40                \ Call the NOISE routine with A = 40 to make a low,
 JSR NOISE              \ long beep to indicate the missile is now disarmed

.MA31

 LDA #0                 \ Set MSAR to 0 to indicate that no missiles are
 STA MSAR               \ currently armed

.MA20

 LDA MSTG               \ If MSTG is positive (i.e. it does not have bit 7 set),
 BPL MA25               \ then it indicates we already have a missile locked on
                        \ a target (in which case MSTG contains the ship number
                        \ of the target), so jump to MA25 to skip targeting. Or
                        \ to put it another way, if MSTG = &FF, which means
                        \ there is no current target lock, keep going

 LDA KY14               \ If "T" is being pressed, keep going, otherwise jump
 BEQ MA25               \ down to MA25 to skip the following

 LDX NOMSL              \ If the number of missiles in NOMSL is zero, jump down
 BEQ MA25               \ to MA25 to skip the following

 STA MSAR               \ The "target missile" key is being pressed and we have
                        \ at least one missile, so set MSAR = &FF to denote that
                        \ our missile is currently armed (we know A has the
                        \ value &FF, as we just loaded it from MSTG and checked
                        \ that it was negative)

 LDY #&E0               \ Change the leftmost missile indicator to yellow/white
 JSR MSBAR              \ on the missile bar (this call changes the leftmost
                        \ indicator because we set X to the number of missiles
                        \ in NOMSL above, and the indicators are numbered from
                        \ right to left, so X is the number of the leftmost
                        \ indicator)

.MA25

 LDA KY16               \ If "M" is being pressed, keep going, otherwise jump
 BEQ MA24               \ down to MA24 to skip the following

 LDA MSTG               \ If MSTG = &FF then there is no target lock, so jump to
 BMI MA64               \ MA64 to skip the following (also skipping the checks
                        \ for TAB, ESCAPE, "J" and "E")

 JSR FRMIS              \ The "fire missile" key is being pressed and we have
                        \ a missile lock, so call the FRMIS routine to fire
                        \ the missile

.MA24

 LDA KY12               \ If TAB is being pressed, keep going, otherwise jump
 BEQ MA76               \ jump down to MA76 to skip the following

 ASL BOMB               \ The "energy bomb" key is being pressed, so double
                        \ the value in BOMB. If we have an energy bomb fitted,
                        \ BOMB will contain &7F (%01111111) before this shift
                        \ and will contain &FE (%11111110) after the shift; if
                        \ we don't have an energy bomb fitted, BOMB will still
                        \ contain 0. The bomb explosion is dealt with in the
                        \ MAL1 routine below - this just registers the fact that
                        \ we've set the bomb ticking

.MA76

 LDA KY13               \ If ESCAPE is being pressed and we have an escape pod
 AND ESCP               \ fitted, keep going, otherwise skip the next
 BEQ P%+5               \ instruction

 JMP ESCAPE             \ The "launch escape pod" button is being pressed and
                        \ we have an escape pod fitted, so jump to ESCAPE to
                        \ launch it, and exit the main flight loop using a tail
                        \ call

 LDA KY18               \ If "J" is being pressed, keep going, otherwise skip
 BEQ P%+5               \ the next instruction

 JSR WARP               \ Call the WARP routine to do an in-system jump

 LDA KY17               \ If "E" is being pressed and we have an E.C.M. fitted,
 AND ECM                \ keep going, otherwise jump down to MA64 to skip the
 BEQ MA64               \ following

 LDA ECMA               \ If ECMA is non-zero, that means an E.C.M. is already
 BNE MA64               \ operating and is counting down (this can be either
                        \ our E.C.M. or an opponent's), so jump down to MA64 to
                        \ skip the following (as we can't have two E.C.M.
                        \ systems operating at the same time)

 DEC ECMP               \ The "E.C.M." button is being pressed and nobody else
                        \ is operating their E.C.M., so decrease the value of
                        \ ECMP to make it non-zero, to denote that our E.C.M.
                        \ is now on

 JSR ECBLB2             \ Call ECBLB2 to light up the E.C.M. indicator bulb on
                        \ the dashboard, set the E.C.M. countdown timer to 32,
                        \ and start making the E.C.M. sound

.MA64

 LDA KY19               \ If "C" is being pressed, and we have a docking
 AND DKCMP              \ computer fitted, and we are inside the space station's
 AND SSPR               \ safe zone, keep going, otherwise jump down to MA68 to
 BEQ MA68               \ skip the following

 LDA K%+NI%+32          \ Fetch the AI counter (byte #32) of the second ship
 BMI MA68               \ from the ship data workspace at K%, which is reserved
                        \ for the sun or the space station (in this case it's
                        \ the latter as we are in the safe zone). If byte #32 is
                        \ negative, meaning the station is hostile, then jump
                        \ down to MA68 to skip the following (so we can't use
                        \ the docking computer to dock at a station that has
                        \ turned against us)

 JMP GOIN               \ The "docking computer" button has been pressed and
                        \ we are allowed to dock at the station, so jump to
                        \ GOIN to dock (or "go in"), and exit the main flight
                        \ loop using a tail call

.MA68

 LDA #0                 \ Set LAS = 0, to switch the laser off while we do the
 STA LAS                \ following logic

 STA DELT4              \ Take the 16-bit value (DELTA 0) - i.e. a two-byte
 LDA DELTA              \ number with DELTA as the high byte and 0 as the low
 LSR A                  \ byte - and divide it by 4, storing the 16-bit result
 ROR DELT4              \ in DELT4(1 0). This has the effect of storing the
 LSR A                  \ current speed * 64 in the 16-bit location DELT4(1 0)
 ROR DELT4
 STA DELT4+1

 LDA LASCT              \ If LASCT is zero, keep going, otherwise the laser is
 BNE MA3                \ a pulse laser that is between pulses, so jump down to
                        \ MA3 to skip the following

 LDA KY7                \ If "A" is being pressed, keep going, otherwise jump
 BEQ MA3                \ down to MA3 to skip the following

 LDA GNTMP              \ If the laser temperature >= 242 then the laser has
 CMP #242               \ overheated, so jump down to MA3 to skip the following
 BCS MA3

 LDX VIEW               \ If the current space view has a laser fitted (i.e. the
 LDA LASER,X            \ laser power for this view is greater than zero), then
 BEQ MA3                \ keep going, otherwise jump down to MA3 to skip the
                        \ following

                        \ If we get here, then the "fire" button is being
                        \ pressed, our laser hasn't overheated and isn't already
                        \ being fired, and we actually have a laser fitted to
                        \ the current space view, so it's time to hit me with
                        \ those laser beams

 PHA                    \ Store the current view's laser power on the stack

 AND #%01111111         \ Set LAS and LAS2 to bits 0-6 of the laser power
 STA LAS
 STA LAS2

 LDA #0                 \ Call the NOISE routine with A = 0 to make the sound
 JSR NOISE              \ of our laser firing

 JSR LASLI              \ Call LASLI to draw the laser lines

 PLA                    \ Restore the current view's laser power into A

 BPL ma1                \ If the laser power has bit 7 set, then it's an "always
                        \ on" laser rather than a pulsing laser, so keep going,
                        \ otherwise jump down to ma1 to skip the following
                        \ instruction

 LDA #0                 \ This is an "always on" laser (i.e. a beam laser,
                        \ as the cassette version of Elite doesn't have military
                        \ lasers), so set A = 0, which will be stored in LASCT
                        \ to denote that this is not a pulsing laser

.ma1

 AND #%11111010         \ LASCT will be set to 0 for beam lasers, and to the
 STA LASCT              \ laser power AND %11111010 for pulse lasers, which
                        \ comes to 10 (as pulse lasers have a power of 15). See
                        \ MA23 below for more on laser pulsing and LASCT

\ ******************************************************************************
\
\       Name: Main flight loop (Part 4 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Copy the ship's data block from K% to the
\             zero-page workspace at INWK
\  Deep dive: Program flow of the main game loop
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Start looping through all the ships in the local bubble, and for each
\     one:
\
\     * Copy the ship's data block from K% to INWK
\
\     * Set XX0 to point to the ship's blueprint (if this is a ship)
\
\ Other entry points:
\
\   MAL1                Marks the beginning of the ship analysis loop, so we
\                       can jump back here from part 12 of the main flight loop
\                       to work our way through each ship in the local bubble.
\                       We also jump back here when a ship is removed from the
\                       bubble, so we can continue processing from the next ship
\
\ ******************************************************************************

.MA3

 LDX #0                 \ We're about to work our way through all the ships in
                        \ our local bubble of universe, so set a counter in X,
                        \ starting from 0, to refer to each ship slot in turn

.MAL1

 STX XSAV               \ Store the current slot number in XSAV

 LDA FRIN,X             \ Fetch the contents of this slot into A. If it is 0
 BNE P%+5               \ then this slot is empty and we have no more ships to
 JMP MA18               \ process, so jump to MA18 below, otherwise A contains
                        \ the type of ship that's in this slot, so skip over the
                        \ JMP MA18 instruction and keep going

 STA TYPE               \ Store the ship type in TYPE

 JSR GINF               \ Call GINF to fetch the address of the ship data block
                        \ for the ship in slot X and store it in INF. The data
                        \ block is in the K% workspace, which is where all the
                        \ ship data blocks are stored

                        \ Next we want to copy the ship data block from INF to
                        \ the zero-page workspace at INWK, so we can process it
                        \ more efficiently

 LDY #NI%-1             \ There are NI% bytes in each ship data block (and in
                        \ the INWK workspace, so we set a counter in Y so we can
                        \ loop through them

.MAL2

 LDA (INF),Y            \ Load the Y-th byte of INF and store it in the Y-th
 STA INWK,Y             \ byte of INWK

 DEY                    \ Decrement the loop counter

 BPL MAL2               \ Loop back for the next byte until we have copied the
                        \ last byte from INF to INWK

 LDA TYPE               \ If the ship type is negative then this indicates a
 BMI MA21               \ planet or sun, so jump down to MA21, as the next bit
                        \ sets up a pointer to the ship blueprint, and then
                        \ checks for energy bomb damage, and neither of these
                        \ apply to planets and suns

 ASL A                  \ Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           \ The ship blueprints at XX21 start with a lookup
 STA XX0                \ table that points to the individual ship blueprints,
                        \ so this fetches the low byte of this particular ship
                        \ type's blueprint and stores it in XX0

 LDA XX21-1,Y           \ Fetch the high byte of this particular ship type's
 STA XX0+1              \ blueprint and store it in XX0+1

\ ******************************************************************************
\
\       Name: Main flight loop (Part 5 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: If an energy bomb has been set off,
\             potentially kill this ship
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * If an energy bomb has been set off and this ship can be killed, kill it
\       and increase the kill tally
\
\ ******************************************************************************

 LDA BOMB               \ If we set off our energy bomb (see MA24 above), then
 BPL MA21               \ BOMB is now negative, so this skips to MA21 if our
                        \ energy bomb is not going off

 CPY #2*SST             \ If the ship in Y is the space station, jump to BA21
 BEQ MA21               \ as energy bombs are useless against space stations

 LDA INWK+31            \ If the ship we are checking has bit 5 set in its ship
 AND #%00100000         \ byte #31, then it is already exploding, so jump to
 BNE MA21               \ BA21 as ships can't explode more than once

 LDA INWK+31            \ The energy bomb is killing this ship, so set bit 7 of
 ORA #%10000000         \ the ship byte #31 to indicate that it has now been
 STA INWK+31            \ killed

 JSR EXNO2              \ Call EXNO2 to process the fact that we have killed a
                        \ ship (so increase the kill tally, make an explosion
                        \ sound and possibly display "RIGHT ON COMMANDER!")

\ ******************************************************************************
\
\       Name: Main flight loop (Part 6 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Move the ship in space and copy the updated
\             INWK data block back to K%
\  Deep dive: Program flow of the main game loop
\             Program flow of the ship-moving routine
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Move the ship in space
\
\     * Copy the updated ship's data block from INWK back to K%
\
\ ******************************************************************************

.MA21

 JSR MVEIT              \ Call MVEIT to move the ship we are processing in space

                        \ Now that we are done processing this ship, we need to
                        \ copy the ship data back from INWK to the correct place
                        \ in the K% workspace. We already set INF in part 4 to
                        \ point to the ship's data block in K%, so we can simply
                        \ do the reverse of the copy we did before, this time
                        \ copying from INWK to INF

 LDY #(NI%-1)           \ Set a counter in Y so we can loop through the NI%
                        \ bytes in the ship data block

.MAL3

 LDA INWK,Y             \ Load the Y-th byte of INWK and store it in the Y-th
 STA (INF),Y            \ byte of INF

 DEY                    \ Decrement the loop counter

 BPL MAL3               \ Loop back for the next byte, until we have copied the
                        \ last byte from INWK back to INF

\ ******************************************************************************
\
\       Name: Main flight loop (Part 7 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Check whether we are docking, scooping or
\             colliding with it
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Check how close we are to this ship and work out if we are docking,
\       scooping or colliding with it
\
\ ******************************************************************************

 LDA INWK+31            \ Fetch the status of this ship from bits 5 (is ship
 AND #%10100000         \ exploding?) and bit 7 (has ship been killed?) from
                        \ ship byte #31 into A

 JSR MAS4               \ Or this value with x_hi, y_hi and z_hi

 BNE MA65               \ If this value is non-zero, then either the ship is
                        \ far away (i.e. has a non-zero high byte in at least
                        \ one of the three axes), or it is already exploding,
                        \ or has been flagged as being killed - in which case
                        \ jump to MA65 to skip the following, as we can't dock
                        \ scoop or collide with it

 LDA INWK               \ Set A = (x_lo OR y_lo OR z_lo), and if bit 7 of the
 ORA INWK+3             \ result is set, the ship is still a fair distance
 ORA INWK+6             \ away (further than 127 in at least one axis), so jump
 BMI MA65               \ to MA65 to skip the following, as it's too far away to
                        \ dock, scoop or collide with

 LDX TYPE               \ If the current ship type is negative then it's either
 BMI MA65               \ a planet or a sun, so jump down to MA65 to skip the
                        \ following, as we can't dock with it or scoop it

 CPX #SST               \ If this ship is the space station, jump to ISDK to
 BEQ ISDK               \ check whether we are docking with it

 AND #%11000000         \ If bit 6 of (x_lo OR y_lo OR z_lo) is set, then the
 BNE MA65               \ ship is still a reasonable distance away (further than
                        \ 63 in at least one axis), so jump to MA65 to skip the
                        \ following, as it's too far away to dock, scoop or
                        \ collide with

 CPX #MSL               \ If this ship is a missile, jump down to MA65 to skip
 BEQ MA65               \ the following, as we can't scoop or dock with a
                        \ missile, and it has its own dedicated collision
                        \ checks in the TACTICS routine

 CPX #OIL               \ If ship type >= OIL (i.e. it's a cargo canister,
 BCS P%+5               \ Thargon or escape pod), skip the JMP instruction and
 JMP MA58               \ continue on, otherwise jump to MA58 to process a
                        \ potential collision

 LDA BST                \ If we have fuel scoops fitted then BST will be &FF,
                        \ otherwise it will be 0

 AND INWK+5             \ Ship byte #5 contains the y_sign of this ship, so a
                        \ negative value here means the canister is below us,
                        \ which means the result of the AND will be negative if
                        \ the canister is below us and we have a fuel scoop
                        \ fitted

 BPL MA58               \ If the result is positive, then we either have no
                        \ scoop or the canister is above us, and in both cases
                        \ this means we can't scoop the item, so jump to MA58
                        \ to process a collision

\ ******************************************************************************
\
\       Name: Main flight loop (Part 8 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Process us potentially scooping this item
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Process us potentially scooping this item
\
\ ******************************************************************************

 LDA #3                 \ Set A to 3 to denote we may be scooping an escape pod

 CPX #TGL               \ If ship type < Thargon, i.e. it's a canister, jump
 BCC oily               \ to oily to randomly decide the canister's contents

 BNE slvy2              \ If ship type <> Thargon, i.e. it's an escape pod,
                        \ jump to slvy2 with A set to 3, so we scoop up the
                        \ escape pod as slaves

 LDA #16                \ Otherwise this is a Thargon, so jump to slvy2 with
 BNE slvy2              \ A set to 16, so we scoop up the Thargon as alien items
                        \ (this BNE is effectively a JMP as A will never be
                        \ zero)

.oily

 JSR DORND              \ Set A and X to random numbers and reduce A to a
 AND #7                 \ random number in the range 0-7

.slvy2

                        \ By the time we get here, we are scooping, and A
                        \ contains the type of item we are scooping (a random
                        \ number 0-7 if we are scooping a cargo canister, 3 if
                        \ we are scooping an escape pod, or 16 if we are
                        \ scooping a Thargon). These numbers correspond to the
                        \ relevant market items (see QQ23 for a list), so a
                        \ cargo canister can contain anything from food to
                        \ computers, while escape pods contain slaves, and
                        \ Thargons become alien items when scooped

 STA QQ29               \ Call tnpr with the scooped cargo type stored in QQ29
 LDA #1                 \ and A set to 1, to work out whether we have room in
 JSR tnpr               \ the hold for the scooped item (A is preserved by this
                        \ call, and the C flag contains the result)

 LDY #78                \ This instruction has no effect, so presumably it used
                        \ to do something, but didn't get removed

 BCS MA59               \ If the C flag is set then we have no room in the hold
                        \ for the scooped item, so jump down to MA59 make a
                        \ sound to indicate failure, before destroying the
                        \ canister

 LDY QQ29               \ Scooping was successful, so set Y to the type of
                        \ item we just scooped, which we stored in QQ29 above

 ADC QQ20,Y             \ Add A (which we set to 1 above) to the number of items
 STA QQ20,Y             \ of type Y in the cargo hold, as we just successfully
                        \ scooped one canister of type Y

 TYA                    \ Print recursive token 48 + Y as an in-flight token,
 ADC #208               \ which will be in the range 48 ("FOOD") to 64 ("ALIEN
 JSR MESS               \ ITEMS"), so this prints the scooped item's name

 JMP MA60               \ We are done scooping, so jump down to MA60 to set the
                        \ kill flag on the canister, as it no longer exists in
                        \ the local bubble

.MA65

 JMP MA26               \ If we get here, then the ship we are processing was
                        \ too far away to be scooped, docked or collided with,
                        \ so jump to MA26 to skip over the collision routines
                        \ and move on to missile targeting

\ ******************************************************************************
\
\       Name: Main flight loop (Part 9 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: If it is a space station, check whether we
\             are successfully docking with it
\  Deep dive: Program flow of the main game loop
\             Docking checks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Process docking with a space station
\
\ For details on the various docking checks in this routine, see the deep dive
\ on "Docking checks".
\
\ Other entry points:
\
\   GOIN                We jump here from part 3 of the main flight loop if the
\                       docking computer is activated by pressing "C"
\
\ ******************************************************************************

.ISDK

 LDA K%+NI%+32          \ 1. Fetch the AI counter (byte #32) of the second ship
 BMI MA62               \ in the ship data workspace at K%, which is reserved
                        \ for the sun or the space station (in this case it's
                        \ the latter), and if it's negative, i.e. bit 7 is set,
                        \ meaning the station is hostile, jump down to MA62 to
                        \ fail docking (so trying to dock at a station that we
                        \ have annoyed does not end well)

 LDA INWK+14            \ 2. If nosev_z_hi < 214, jump down to MA62 to fail
 CMP #214               \ docking, as the angle of approach is greater than 26
 BCC MA62               \ degrees

 JSR SPS4               \ Call SPS4 to get the vector to the space station
                        \ into XX15

 LDA XX15+2             \ 3. Check the sign of the z-axis (bit 7 of XX15+2) and
 BMI MA62               \ if it is negative, we are facing away from the
                        \ station, so jump to MA62 to fail docking

 CMP #89                \ 4. If z-axis < 89, jump to MA62 to fail docking, as
 BCC MA62               \ we are not in the 22.0 degree safe cone of approach

 LDA INWK+16            \ 5. If |roofv_x_hi| < 80, jump to MA62 to fail docking,
 AND #%01111111         \ as the slot is more than 36.6 degrees from horizontal
 CMP #80
 BCC MA62

.GOIN

                        \ If we arrive here, either the docking computer has
                        \ been activated, or we just docked successfully

 LDA #0                 \ Set the on-screen hyperspace counter to 0
 STA QQ22+1

 LDA #8                 \ This instruction has no effect, so presumably it used
                        \ to do something, and didn't get removed

 JSR LAUN               \ Show the space station launch tunnel

 JSR RES4               \ Reset the shields and energy banks, stardust and INWK
                        \ workspace

 JMP BAY                \ Go to the docking bay (i.e. show the Status Mode
                        \ screen)

.MA62

                        \ If we arrive here, docking has just failed

 LDA DELTA              \ If the ship's speed is < 5, jump to MA67 to register
 CMP #5                 \ some damage, but not a huge amount
 BCC MA67

 JMP DEATH              \ Otherwise we have just crashed into the station, so
                        \ process our death

\ ******************************************************************************
\
\       Name: Main flight loop (Part 10 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Remove if scooped, or process collisions
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Remove scooped item after both successful and failed scoopings
\
\     * Process collisions
\
\ ******************************************************************************

.MA59

                        \ If we get here then scooping failed

 JSR EXNO3              \ Make the sound of the cargo canister being destroyed
                        \ and fall through into MA60 to remove the canister
                        \ from our local bubble

.MA60

                        \ If we get here then scooping was successful

 ASL INWK+31            \ Set bit 7 of the scooped or destroyed item, to denote
 SEC                    \ that it has been killed and should be removed from
 ROR INWK+31            \ the local bubble

.MA61

 BNE MA26               \ Jump to MA26 to skip over the collision routines and
                        \ to move on to missile targeting (this BNE is
                        \ effectively a JMP as A will never be zero)

.MA67

                        \ If we get here then we have collided with something,
                        \ but not fatally

 LDA #1                 \ Set the speed in DELTA to 1 (i.e. a sudden stop)
 STA DELTA

 LDA #5                 \ Set the amount of damage in A to 5 (a small dent) and
 BNE MA63               \ jump down to MA63 to process the damage (this BNE is
                        \ effectively a JMP as A will never be zero)

.MA58

                        \ If we get here, we have collided with something in a
                        \ potentially fatal way

 ASL INWK+31            \ Set bit 7 of the ship we just collided with, to
 SEC                    \ denote that it has been killed and should be removed
 ROR INWK+31            \ from the local bubble

 LDA INWK+35            \ Load A with the energy level of the ship we just hit

 SEC                    \ Set the amount of damage in A to 128 + A / 2, so
 ROR A                  \ this is quite a big dent, and colliding with higher
                        \ energy ships will cause more damage

.MA63

 JSR OOPS               \ The amount of damage is in A, so call OOPS to reduce
                        \ our shields, and if the shields are gone, there's a
                        \ a chance of cargo loss or even death

 JSR EXNO3              \ Make the sound of colliding with the other ship and
                        \ fall through into MA26 to try targeting a missile

\ ******************************************************************************
\
\       Name: Main flight loop (Part 11 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Process missile lock and firing our laser
\  Deep dive: Program flow of the main game loop
\             Flipping axes between space views
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * If this is not the front space view, flip the axes of the ship's
\        coordinates in INWK
\
\     * Process missile lock
\
\     * Process our laser firing
\
\ ******************************************************************************

.MA26

 LDA QQ11               \ If this is not a space view, jump to MA15 to skip
 BNE MA15               \ missile and laser locking

 JSR PLUT               \ Call PLUT to update the geometric axes in INWK to
                        \ match the view (front, rear, left, right)

 JSR HITCH              \ Call HITCH to see if this ship is in the crosshairs,
 BCC MA8                \ in which case the C flag will be set (so if there is
                        \ no missile or laser lock, we jump to MA8 to skip the
                        \ following)

 LDA MSAR               \ We have missile lock, so check whether the leftmost
 BEQ MA47               \ missile is currently armed, and if not, jump to MA47
                        \ to process laser fire, as we can't lock an unarmed
                        \ missile

 JSR BEEP               \ We have missile lock and an armed missile, so call
                        \ the BEEP subroutine to make a short, high beep

 LDX XSAV               \ Call ABORT2 to store the details of this missile
 LDY #&0E               \ lock, with the targeted ship's slot number in X
 JSR ABORT2             \ (which we stored in XSAV at the start of this ship's
                        \ loop at MAL1), and set the colour of the missile
                        \ indicator to the colour in Y (red = &0E)

.MA47

                        \ If we get here then the ship is in our sights, but
                        \ we didn't lock a missile, so let's see if we're
                        \ firing the laser

 LDA LAS                \ If we are firing the laser then LAS will contain the
 BEQ MA8                \ laser power (which we set in MA68 above), so if this
                        \ is zero, jump down to MA8 to skip the following

 LDX #15                \ We are firing our laser and the ship in INWK is in
 JSR EXNO               \ the crosshairs, so call EXNO to make the sound of
                        \ us making a laser strike on another ship

 LDA INWK+35            \ Fetch the hit ship's energy from byte #35 and subtract
 SEC                    \ our current laser power, and if the result is greater
 SBC LAS                \ than zero, the other ship has survived the hit, so
 BCS MA14               \ jump down to MA14 to make it angry

 LDA TYPE               \ Did we just hit the space station? If so, jump to
 CMP #SST               \ MA14+2 to make the station hostile, skipping the
 BEQ MA14+2             \ following as we can't destroy a space station

 LDA INWK+31            \ Set bit 7 of the enemy ship's byte #31, to indicate
 ORA #%10000000         \ that it has been killed
 STA INWK+31

 BCS MA8                \ If the enemy ship type is >= SST (i.e. missile,
                        \ asteroid, canister, Thargon or escape pod) then
                        \ jump down to MA8

 JSR DORND              \ Fetch a random number, and jump to oh if it is
 BPL oh                 \ positive (50% chance)

 LDY #0                 \ Fetch the first byte of the hit ship's blueprint,
 AND (XX0),Y            \ which determines the maximum number of bits of
                        \ debris shown when the ship is destroyed, and AND
                        \ with the random number we just fetched

 STA CNT                \ Store the result in CNT, so CNT contains a random
                        \ number between 0 and the maximum number of bits of
                        \ debris that this ship will release when destroyed

.um

 BEQ oh                 \ We're going to go round a loop using CNT as a counter
                        \ so this checks whether the counter is zero and jumps
                        \ to oh when it gets there (which might be straight
                        \ away)

 LDX #OIL               \ Call SFS1 to spawn a cargo canister from the now
 LDA #0                 \ deceased parent ship, giving the spawned canister an
 JSR SFS1               \ AI flag of 0 (no AI, no E.C.M., non-hostile)

 DEC CNT                \ Decrease the loop counter

 BPL um                 \ Jump back up to um (this BPL is effectively a JMP as
                        \ CNT will never be negative)

.oh

 JSR EXNO2              \ Call EXNO2 to process the fact that we have killed a
                        \ ship (so increase the kill tally, make an explosion
                        \ sound and so on)

.MA14

 STA INWK+35            \ Store the hit ship's updated energy in ship byte #35

 LDA TYPE               \ Call ANGRY to make this ship hostile, now that we
 JSR ANGRY              \ have hit it

\ ******************************************************************************
\
\       Name: Main flight loop (Part 12 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: For each nearby ship: Draw the ship, remove if killed, loop back
\  Deep dive: Program flow of the main game loop
\             Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Draw the ship
\
\     * Process removal of killed ships
\
\   * Loop back up to MAL1 to move onto the next ship in the local bubble
\
\ ******************************************************************************

.MA8

 JSR LL9                \ Call LL9 to draw the ship we're processing on-screen

.MA15

 LDY #35                \ Fetch the ship's energy from byte #35 and copy it to
 LDA INWK+35            \ byte #35 in INF (so the ship's data in K% gets
 STA (INF),Y            \ updated)

 LDA INWK+31            \ If bit 7 of the ship's byte #31 is clear, then the
 BPL MAC1               \ ship hasn't been killed by energy bomb, collision or
                        \ laser fire, so jump to MAC1 to skip the following

 AND #%00100000         \ If bit 5 of the ship's byte #31 is clear then the
 BEQ NBOUN              \ ship is no longer exploding, so jump to NBOUN to skip
                        \ the following

 LDA TYPE               \ If the ship we just destroyed was a cop, keep going,
 CMP #COPS              \ otherwise jump to q2 to skip the following
 BNE q2

 LDA FIST               \ We shot the sheriff, so update our FIST flag
 ORA #64                \ ("fugitive/innocent status") to at least 64, which
 STA FIST               \ will instantly make us a fugitive

.q2

 LDA DLY                \ If we already have an in-flight message on-screen (in
 ORA MJ                 \ which case DLY > 0), or we are in witchspace (in
 BNE KS1S               \ which case MJ > 0), jump to KS1S to skip showing an
                        \ on-screen bounty for this kill

 LDY #10                \ Fetch byte #10 of the ship's blueprint, which is the
 LDA (XX0),Y            \ low byte of the bounty awarded when this ship is
 BEQ KS1S               \ killed (in Cr * 10), and if it's zero jump to KS1S as
                        \ there is no on-screen bounty to display

 TAX                    \ Put the low byte of the bounty into X

 INY                    \ Fetch byte #11 of the ship's blueprint, which is the
 LDA (XX0),Y            \ high byte of the bounty awarded (in Cr * 10), and put
 TAY                    \ it into Y

 JSR MCASH              \ Call MCASH to add (Y X) to the cash pot

 LDA #0                 \ Print control code 0 (current cash, right-aligned to
 JSR MESS               \ width 9, then " CR", newline) as an in-flight message

.KS1S

 JMP KS1                \ Process the killing of this ship (which removes this
                        \ ship from its slot and shuffles all the other ships
                        \ down to close up the gap)

.NBOUN

.MAC1

 LDA TYPE               \ If the ship we are processing is a planet or sun,
 BMI MA27               \ jump to MA27 to skip the following two instructions

 JSR FAROF              \ If the ship we are processing is a long way away (its
 BCC KS1S               \ distance in any one direction is > 224, jump to KS1S
                        \ to remove the ship from our local bubble, as it's just
                        \ left the building

.MA27

 LDY #31                \ Fetch the ship's explosion/killed state from byte #31
 LDA INWK+31            \ and copy it to byte #31 in INF (so the ship's data in
 STA (INF),Y            \ K% gets updated)

 LDX XSAV               \ We're done processing this ship, so fetch the ship's
                        \ slot number, which we saved in XSAV back at the start
                        \ of the loop

 INX                    \ Increment the slot number to move on to the next slot

 JMP MAL1               \ And jump back up to the beginning of the loop to get
                        \ the next ship in the local bubble for processing

\ ******************************************************************************
\
\       Name: Main flight loop (Part 13 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Show energy bomb effect, charge shields and energy banks
\  Deep dive: Program flow of the main game loop
\             Scheduling tasks with the main loop counter
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Show energy bomb effect (if applicable)
\
\   * Charge shields and energy banks (every 7 iterations of the main loop)
\
\ ******************************************************************************

.MA18

 LDA BOMB               \ If we set off our energy bomb (see MA24 above), then
 BPL MA77               \ BOMB is now negative, so this skips to MA21 if our
                        \ energy bomb is not going off

 ASL BOMB               \ We set off our energy bomb, so rotate BOMB to the
                        \ left by one place. BOMB was rotated left once already
                        \ during this iteration of the main loop, back at MA24,
                        \ so if this is the first pass it will already be
                        \ %11111110, and this will shift it to %11111100 - so
                        \ if we set off an energy bomb, it stays activated
                        \ (BOMB > 0) for four iterations of the main loop

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn and the following palette change
                        \ won't kick in while the screen is still refreshing

 LDA #%00110000         \ Set the palette byte at SHEILA &21 to map logical
 STA VIA+&21            \ colour 0 to physical colour 7 (white), but with only
                        \ one mapping (rather than the 7 mappings required to
                        \ do the mapping properly). This makes the space screen
                        \ flash with black and white stripes. See p.382 of the
                        \ Advanced User Guide for details of why this single
                        \ palette change creates a special effect

.MA77

 LDA MCNT               \ Fetch the main loop counter and calculate MCNT mod 7,
 AND #7                 \ jumping to MA22 if it is non-zero (so the following
 BNE MA22               \ code only runs every 8 iterations of the main loop)

 LDX ENERGY             \ Fetch our ship's energy levels and skip to b if bit 7
 BPL b                  \ is not set, i.e. only charge the shields from the
                        \ energy banks if they are at more than 50% charge

 LDX ASH                \ Call SHD to recharge our aft shield and update the
 JSR SHD                \ shield status in ASH
 STX ASH

 LDX FSH                \ Call SHD to recharge our forward shield and update
 JSR SHD                \ the shield status in FSH
 STX FSH

.b

 SEC                    \ Set A = ENERGY + ENGY + 1, so our ship's energy
 LDA ENGY               \ level goes up by 2 if we have an energy unit fitted,
 ADC ENERGY             \ otherwise it goes up by 1

 BCS P%+5               \ If the value of A did not overflow (the maximum
 STA ENERGY             \ energy level is &FF), then store A in ENERGY

\ ******************************************************************************
\
\       Name: Main flight loop (Part 14 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Spawn a space station if we are close enough to the planet
\  Deep dive: Program flow of the main game loop
\             Scheduling tasks with the main loop counter
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Spawn a space station if we are close enough to the planet (every 32
\     iterations of the main loop)
\
\ ******************************************************************************

 LDA MJ                 \ If we are in witchspace, jump down to MA23S to skip
 BNE MA23S              \ the following, as there are no space stations in
                        \ witchspace

 LDA MCNT               \ Fetch the main loop counter and calculate MCNT mod 32,
 AND #31                \ jumping to MA93 if it is on-zero (so the following
 BNE MA93               \ code only runs every 32 iterations of the main loop

 LDA SSPR               \ If we are inside the space station safe zone, jump to
 BNE MA23S              \ MA23S to skip the following, as we already have a
                        \ space station and don't need another

 TAY                    \ Set Y = A = 0 (A is 0 as we didn't branch with the
                        \ previous BNE instruction)

 JSR MAS2               \ Call MAS2 to calculate the largest distance to the
 BNE MA23S              \ planet in any of the three axes, and if it's
                        \ non-zero, jump to MA23S to skip the following, as we
                        \ are too far from the planet to bump into a space
                        \ station

                        \ We now want to spawn a space station, so first we
                        \ need to set up a ship data block for the station in
                        \ INWK that we can then pass to NWSPS to add a new
                        \ station to our bubble of universe. We do this by
                        \ copying the planet data block from K% to INWK so we
                        \ can work on it, but we only need the first 29 bytes,
                        \ as we don't need to worry about bytes #29 to #35
                        \ for planets (as they don't have rotation counters,
                        \ AI, explosions, missiles, a ship line heap or energy
                        \ levels)

 LDX #28                \ So we set a counter in X to copy 29 bytes from K%+0
                        \ to K%+28

.MAL4

 LDA K%,X               \ Load the X-th byte of K% and store in the X-th byte
 STA INWK,X             \ of the INWK workspace

 DEX                    \ Decrement the loop counter

 BPL MAL4               \ Loop back for the next byte until we have copied the
                        \ first 28 bytes of K% to INWK

                        \ We now check the distance from our ship (at the
                        \ origin) towards the planet's surface, by adding the
                        \ planet's nosev vector to the planet's centre at
                        \ (x, y, z) and checking our distance to the end
                        \ point along the relevant axis

 INX                    \ Set X = 0 (as we ended the above loop with X as &FF)

 LDY #9                 \ Call MAS1 with X = 0, Y = 9 to do the following:
 JSR MAS1               \
                        \   (x_sign x_hi x_lo) += (nosev_x_hi nosev_x_lo) * 2
                        \
                        \   A = |x_hi|

 BNE MA23S              \ If A > 0, jump to MA23S to skip the following, as we
                        \ are too far from the planet in the x-direction to
                        \ bump into a space station

 LDX #3                 \ Call MAS1 with X = 3, Y = 11 to do the following:
 LDY #11                \
 JSR MAS1               \   (y_sign y_hi y_lo) += (nosev_y_hi nosev_y_lo) * 2
                        \
                        \   A = |y_hi|

 BNE MA23S              \ If A > 0, jump to MA23S to skip the following, as we
                        \ are too far from the planet in the y-direction to
                        \ bump into a space station

 LDX #6                 \ Call MAS1 with X = 6, Y = 13 to do the following:
 LDY #13                \
 JSR MAS1               \   (z_sign z_hi z_lo) += (nosev_z_hi nosev_z_lo) * 2
                        \
                        \   A = |z_hi|

 BNE MA23S              \ If A > 0, jump to MA23S to skip the following, as we
                        \ are too far from the planet in the z-direction to
                        \ bump into a space station

 LDA #192               \ Call FAROF2 to compare x_hi, y_hi and z_hi with 192,
 JSR FAROF2             \ which will set the C flag if all three are < 192, or
                        \ clear the C flag if any of them are >= 192

 BCC MA23S              \ Jump to MA23S if any one of x_hi, y_hi or z_hi are
                        \ >= 192 (i.e. they must all be < 192 for us to be near
                        \ enough to the planet to bump into a space station)

 LDA QQ11               \ If the current view is not a space view, skip the
 BNE P%+5               \ following instruction (so we only remove the sun from
                        \ the screen if we are potentially looking at it)

 JSR WPLS               \ Call WPLS to remove the sun from the screen, as we
                        \ can't have both the sun and the space station at the
                        \ same time

 JSR NWSPS              \ Add a new space station to our local bubble of
                        \ universe

.MA23S

 JMP MA23               \ Jump to MA23 to skip the following planet and sun
                        \ altitude checks

\ ******************************************************************************
\
\       Name: Main flight loop (Part 15 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Perform altitude checks with the planet and sun and process fuel
\             scooping if appropriate
\  Deep dive: Program flow of the main game loop
\             Scheduling tasks with the main loop counter
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Perform an altitude check with the planet (every 32 iterations of the main
\     loop, on iteration 10 of each 32)
\
\   * Perform an an altitude check with the sun and process fuel scooping (every
\     32 iterations of the main loop, on iteration 20 of each 32)
\
\ ******************************************************************************

.MA22

 LDA MJ                 \ If we are in witchspace, jump down to MA23 to skip
 BNE MA23               \ the following, as there are no planets or suns to
                        \ bump into in witchspace

 LDA MCNT               \ Fetch the main loop counter and calculate MCNT mod 32,
 AND #31                \ which tells us the position of this loop in each block
                        \ of 32 iterations

.MA93

 CMP #10                \ If this is the tenth iteration in this block of 32,
 BNE MA29               \ do the following, otherwise jump to MA29 to skip the
                        \ planet altitude check and move on to the sun distance
                        \ check

 LDA #50                \ If our energy bank status in ENERGY is >= 50, skip
 CMP ENERGY             \ printing the following message (so the message is
 BCC P%+6               \ only shown if our energy is low)

 ASL A                  \ Print recursive token 100 ("ENERGY LOW{beep}") as an
 JSR MESS               \ in-flight message

 LDY #&FF               \ Set our altitude in ALTIT to &FF, the maximum
 STY ALTIT

 INY                    \ Set Y = 0

 JSR m                  \ Call m to calculate the maximum distance to the
                        \ planet in any of the three axes, returned in A

 BNE MA23               \ If A > 0 then we are a fair distance away from the
                        \ planet in at least one axis, so jump to MA23 to skip
                        \ the rest of the altitude check

 JSR MAS3               \ Set A = x_hi^2 + y_hi^2 + z_hi^2, so using Pythagoras
                        \ we now know that A now contains the square of the
                        \ distance between our ship (at the origin) and the
                        \ centre of the planet at (x_hi, y_hi, z_hi)

 BCS MA23               \ If the C flag was set by MAS3, then the result
                        \ overflowed (was greater than &FF) and we are still a
                        \ fair distance from the planet, so jump to MA23 as we
                        \ haven't crashed into the planet

 SBC #36                \ Subtract 36 from x_hi^2 + y_hi^2 + z_hi^2. The radius
                        \ of the planet is defined as 6 units and 6^2 = 36, so
                        \ A now contains the high byte of our altitude above
                        \ the planet surface, squared

 BCC MA28               \ If A < 0 then jump to MA28 as we have crashed into
                        \ the planet

 STA R                  \ We are getting close to the planet, so we need to
 JSR LL5                \ work out how close. We know from the above that A
                        \ contains our altitude squared, so we store A in R
                        \ and call LL5 to calculate:
                        \
                        \   Q = SQRT(R Q) = SQRT(A Q)
                        \
                        \ Interestingly, Q doesn't appear to be set to 0 for
                        \ this calculation, so presumably this doesn't make a
                        \ difference

 LDA Q                  \ Store the result in ALTIT, our altitude
 STA ALTIT

 BNE MA23               \ If our altitude is non-zero then we haven't crashed,
                        \ so jump to MA23 to skip to the next section

.MA28

 JMP DEATH              \ If we get here then we just crashed into the planet
                        \ or got too close to the sun, so jump to DEATH to start
                        \ the funeral preparations and return from the main
                        \ flight loop using a tail call

.MA29

 CMP #20                \ If this is the 20th iteration in this block of 32,
 BNE MA23               \ do the following, otherwise jump to MA23 to skip the
                        \ sun altitude check

 LDA #30                \ Set CABTMP to 30, the cabin temperature in deep space
 STA CABTMP             \ (i.e. one notch on the dashboard bar)

 LDA SSPR               \ If we are inside the space station safe zone, jump to
 BNE MA23               \ MA23 to skip the following, as we can't have both the
                        \ sun and space station at the same time, so we clearly
                        \ can't be flying near the sun

 LDY #NI%               \ Set Y to NI%, which is the offset in K% for the sun's
                        \ data block, as the second block at K% is reserved for
                        \ the sun (or space station)

 JSR MAS2               \ Call MAS2 to calculate the largest distance to the
 BNE MA23               \ sun in any of the three axes, and if it's non-zero,
                        \ jump to MA23 to skip the following, as we are too far
                        \ from the sun for scooping or temperature changes

 JSR MAS3               \ Set A = x_hi^2 + y_hi^2 + z_hi^2, so using Pythagoras
                        \ we now know that A now contains the square of the
                        \ distance between our ship (at the origin) and the
                        \ heart of the sun at (x_hi, y_hi, z_hi)

 EOR #%11111111         \ Invert A, so A is now small if we are far from the
                        \ sun and large if we are close to the sun, in the
                        \ range 0 = far away to &FF = extremely close, ouch,
                        \ hot, hot, hot!

 ADC #30                \ Add the minimum cabin temperature of 30, so we get
                        \ one of the following:
                        \
                        \   * If the C flag is clear, A contains the cabin
                        \     temperature, ranging from 30 to 255, that's hotter
                        \     the closer we are to the sun
                        \
                        \   * If the C flag is set, the addition has rolled over
                        \     and the cabin temperature is over 255

 STA CABTMP             \ Store the updated cabin temperature

 BCS MA28               \ If the C flag is set then jump to MA28 to die, as
                        \ our temperature is off the scale

 CMP #&E0               \ If the cabin temperature < 224 then jump to MA23 to
 BCC MA23               \ to skip fuel scooping, as we aren't close enough

 LDA BST                \ If we don't have fuel scoops fitted, jump to BA23 to
 BEQ MA23               \ skip fuel scooping, as we can't scoop without fuel
                        \ scoops

 LDA DELT4+1            \ We are now successfully fuel scooping, so it's time
 LSR A                  \ to work out how much fuel we're scooping. Fetch the
                        \ high byte of DELT4, which contains our current speed
                        \ divided by 4, and halve it to get our current speed
                        \ divided by 8 (so it's now a value between 1 and 5, as
                        \ our speed is normally between 1 and 40). This gives
                        \ us the amount of fuel that's being scooped in A, so
                        \ the faster we go, the more fuel we scoop, and because
                        \ the fuel levels are stored as 10 * the fuel in light
                        \ years, that means we just scooped between 0.1 and 0.5
                        \ light years of free fuel

 ADC QQ14               \ Set A = A + the current fuel level * 10 (from QQ14)

 CMP #70                \ If A > 70 then set A = 70 (as 70 is the maximum fuel
 BCC P%+4               \ level, or 7.0 light years)
 LDA #70

 STA QQ14               \ Store the updated fuel level in QQ14

 LDA #160               \ Print recursive token 0 ("FUEL SCOOPS ON") as an
 JSR MESS               \ in-flight message

\ ******************************************************************************
\
\       Name: Main flight loop (Part 16 of 16)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Process laser pulsing, E.C.M. energy drain, call stardust routine
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ The main flight loop covers most of the flight-specific aspects of Elite. This
\ section covers the following:
\
\   * Process laser pulsing
\
\   * Process E.C.M. energy drain
\
\   * Jump to the stardust routine if we are in a space view
\
\   * Return from the main flight loop
\
\ ******************************************************************************

.MA23

 LDA LAS2               \ If the current view has no laser, jump to MA16 to skip
 BEQ MA16               \ the following

 LDA LASCT              \ If LASCT >= 8, jump to MA16 to skip the following, so
 CMP #8                 \ for a pulse laser with a LASCT between 8 and 10, the
 BCS MA16               \ the laser stays on, but for a LASCT of 7 or less it
                        \ gets turned off and stays off until LASCT reaches zero
                        \ and the next pulse can start (if the fire button is
                        \ still being pressed)
                        \
                        \ For pulse lasers, LASCT gets set to 10 in ma1 above,
                        \ and it decrements every vertical sync (50 times a
                        \ second), so this means it pulses five times a second,
                        \ with the laser being on for the first 3/10 of each
                        \ pulse and off for the rest of the pulse
                        \
                        \ If this is a beam laser, LASCT is 0 so we always keep
                        \ going here. This means the laser doesn't pulse, but it
                        \ does get drawn and removed every cycle, in a slightly
                        \ different place each time, so the beams still flicker
                        \ around the screen

 JSR LASLI2             \ Redraw the existing laser lines, which has the effect
                        \ of removing them from the screen

 LDA #0                 \ Set LAS2 to 0 so if this is a pulse laser, it will
 STA LAS2               \ skip over the above until the next pulse (this has no
                        \ effect if this is a beam laser)

.MA16

 LDA ECMP               \ If our E.C.M is not on, skip to MA69, otherwise keep
 BEQ MA69               \ going to drain some energy

 JSR DENGY              \ Call DENGY to deplete our energy banks by 1

 BEQ MA70               \ If we have no energy left, jump to MA70 to turn our
                        \ E.C.M. off

.MA69

 LDA ECMA               \ If an E.C.M is going off (our's or an opponent's) then
 BEQ MA66               \ keep going, otherwise skip to MA66

 DEC ECMA               \ Decrement the E.C.M. countdown timer, and if it has
 BNE MA66               \ reached zero, keep going, otherwise skip to MA66

.MA70

 JSR ECMOF              \ If we get here then either we have either run out of
                        \ energy, or the E.C.M. timer has run down, so switch
                        \ off the E.C.M.

.MA66

 LDA QQ11               \ If this is not a space view (i.e. QQ11 is non-zero)
 BNE MA9                \ then jump to MA9 to return from the main flight loop
                        \ (as MA9 is an RTS)

 JMP STARS              \ This is a space view, so jump to the STARS routine to
                        \ process the stardust, and return from the main flight
                        \ loop using a tail call

\ ******************************************************************************
\
\       Name: MAS1
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Add an orientation vector coordinate to an INWK coordinate
\
\ ------------------------------------------------------------------------------
\
\ Add a doubled nosev vector coordinate, e.g. (nosev_y_hi nosev_y_lo) * 2, to
\ an INWK coordinate, e.g. (x_sign x_hi x_lo), storing the result in the INWK
\ coordinate. The axes used in each side of the addition are specified by the
\ arguments X and Y.
\
\ In the comments below, we document the routine as if we are doing the
\ following, i.e. if X = 0 and Y = 11:
\
\   (x_sign x_hi x_lo) = (x_sign x_hi x_lo) + (nosev_y_hi nosev_y_lo) * 2
\
\ as that way the variable names in the comments contain "x" and "y" to match
\ the registers that specify the vector axis to use.
\
\ Arguments:
\
\   X                   The coordinate to add, as follows:
\
\                         * If X = 0, add (x_sign x_hi x_lo)
\                         * If X = 3, add (y_sign y_hi y_lo)
\                         * If X = 6, add (z_sign z_hi z_lo)
\
\   Y                   The vector to add, as follows:
\
\                         * If Y = 9,  add (nosev_x_hi nosev_x_lo)
\                         * If Y = 11, add (nosev_y_hi nosev_y_lo)
\                         * If Y = 13, add (nosev_z_hi nosev_z_lo)
\
\ Returns:
\
\   A                   The high byte of the result with the sign cleared (e.g.
\                       |x_hi| if X = 0, etc.)
\
\ Other entry points:
\
\   MA9                 Contains an RTS
\
\ ******************************************************************************

.MAS1

 LDA INWK,Y             \ Set K(2 1) = (nosev_y_hi nosev_y_lo) * 2
 ASL A
 STA K+1
 LDA INWK+1,Y
 ROL A
 STA K+2

 LDA #0                 \ Set K+3 bit 7 to the C flag, so the sign bit of the
 ROR A                  \ above result goes into K+3
 STA K+3

 JSR MVT3               \ Add (x_sign x_hi x_lo) to K(3 2 1)

 STA INWK+2,X           \ Store the sign of the result in x_sign

 LDY K+1                \ Store K(2 1) in (x_hi x_lo)
 STY INWK,X
 LDY K+2
 STY INWK+1,X

 AND #%01111111         \ Set A to the sign byte with the sign cleared

.MA9

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MAS2
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate a cap on the maximum distance to the planet or sun
\
\ ------------------------------------------------------------------------------
\
\ Given a value in Y that points to the start of a ship data block as an offset
\ from K%, calculate the following:
\
\   A = A OR x_sign OR y_sign OR z_sign
\
\ and clear the sign bit of the result. The K% workspace contains the ship data
\ blocks, so the offset in Y must be 0 or a multiple of NI% (as each block in
\ K% contains NI% bytes).
\
\ The result effectively contains a maximum cap of the three values (though it
\ might not be one of the three input values - it's just guaranteed to be
\ larger than all of them).
\
\ If Y = 0 and A = 0, then this calculates the maximum cap of the highest byte
\ containing the distance to the planet, as K%+2 = x_sign, K%+5 = y_sign and
\ K%+8 = z_sign (the first slot in the K% workspace represents the planet).
\
\ Arguments:
\
\   Y                   The offset from K% for the start of the ship data block
\                       to use
\
\ Returns:
\
\   A                   A OR K%+2+Y OR K%+5+Y OR K%+8+Y, with bit 7 cleared
\
\ Other entry points:
\
\   m                   Do not include A in the calculation
\
\ ******************************************************************************

.m

 LDA #0                 \ Set A = 0 and fall through into MAS2 to calculate the
                        \ OR of the three bytes at K%+2+Y, K%+5+Y and K%+8+Y

.MAS2

 ORA K%+2,Y             \ Set A = A OR x_sign OR y_sign OR z_sign
 ORA K%+5,Y
 ORA K%+8,Y

 AND #%01111111         \ Clear bit 7 in A

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MAS3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = x_hi^2 + y_hi^2 + z_hi^2 in the K% block
\
\ ------------------------------------------------------------------------------
\
\ Given a value in Y that points to the start of a ship data block as an offset
\ from K%, calculate the following:
\
\   A = x_hi^2 + y_hi^2 + z_hi^2
\
\ returning A = &FF if the calculation overflows a one-byte result. The K%
\ workspace contains the ship data blocks, so the offset in Y must be 0 or a
\ multiple of NI% (as each block in K% contains NI% bytes).
\
\ Arguments:
\
\   Y                   The offset from K% for the start of the ship data block
\                       to use
\
\ Returns
\
\   A                   A = x_hi^2 + y_hi^2 + z_hi^2
\
\                       A = &FF if the calculation overflows a one-byte result
\
\ ******************************************************************************

.MAS3

 LDA K%+1,Y             \ Set (A P) = x_hi * x_hi
 JSR SQUA2

 STA R                  \ Store A (high byte of result) in R

 LDA K%+4,Y             \ Set (A P) = y_hi * y_hi
 JSR SQUA2

 ADC R                  \ Add A (high byte of second result) to R

 BCS MA30               \ If the addition of the two high bytes caused a carry
                        \ (i.e. they overflowed), jump to MA30 to return A = &FF

 STA R                  \ Store A (sum of the two high bytes) in R

 LDA K%+7,Y             \ Set (A P) = z_hi * z_hi
 JSR SQUA2

 ADC R                  \ Add A (high byte of third result) to R, so R now
                        \ contains the sum of x_hi^2 + y_hi^2 + z_hi^2

 BCC P%+4               \ If there is no carry, skip the following instruction
                        \ to return straight from the subroutine

.MA30

 LDA #&FF               \ The calculation has overflowed, so set A = &FF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVEIT (Part 1 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Tidy the orientation vectors
\  Deep dive: Program flow of the ship-moving routine
\             Scheduling tasks with the main loop counter
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Tidy the orientation vectors for one of the ship slots
\
\ Arguments:
\
\   INWK                The current ship/planet/sun's data block
\
\   XSAV                The slot number of the current ship/planet/sun
\
\   TYPE                The type of the current ship/planet/sun
\
\ ******************************************************************************

.MVEIT

 LDA INWK+31            \ If bits 5 or 7 of ship byte #31 are set, jump to MV30
 AND #%10100000         \ as the ship is either exploding or has been killed, so
 BNE MV30               \ we don't need to tidy its orientation vectors or apply
                        \ tactics

 LDA MCNT               \ Fetch the main loop counter

 EOR XSAV               \ Fetch the slot number of the ship we are moving, EOR
 AND #15                \ with the loop counter and apply mod 15 to the result.
 BNE MV3                \ The result will be zero when "counter mod 15" matches
                        \ the slot number, so this makes sure we call TIDY 12
                        \ times every 16 main loop iterations, like this:
                        \
                        \   Iteration 0, tidy the ship in slot 0
                        \   Iteration 1, tidy the ship in slot 1
                        \   Iteration 2, tidy the ship in slot 2
                        \     ...
                        \   Iteration 11, tidy the ship in slot 11
                        \   Iteration 12, do nothing
                        \   Iteration 13, do nothing
                        \   Iteration 14, do nothing
                        \   Iteration 15, do nothing
                        \   Iteration 16, tidy the ship in slot 0
                        \     ...
                        \
                        \ and so on

 JSR TIDY               \ Call TIDY to tidy up the orientation vectors, to
                        \ prevent the ship from getting elongated and out of
                        \ shape due to the imprecise nature of trigonometry
                        \ in assembly language

\ ******************************************************************************
\
\       Name: MVEIT (Part 2 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Call tactics routine, remove ship from scanner
\  Deep dive: Scheduling tasks with the main loop counter
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Apply tactics to ships with AI enabled (by calling the TACTICS routine)
\
\   * Remove the ship from the scanner, so we can move it
\
\ ******************************************************************************

.MV3

 LDX TYPE               \ If the type of the ship we are moving is positive,
 BPL P%+5               \ i.e. it is not a planet (types 128 and 130) or sun
                        \ (type 129), then skip the following instruction

 JMP MV40               \ This item is the planet or sun, so jump to MV40 to
                        \ move it, which ends by jumping back into this routine
                        \ at MV45 (after all the rotation, tactics and scanner
                        \ code, which we don't need to apply to planets or suns)

 LDA INWK+32            \ Fetch the ship's byte #32 (AI flag) into A

 BPL MV30               \ If bit 7 of the AI flag is clear, then if this is a
                        \ ship or missile it is dumb and has no AI, and if this
                        \ is the space station it is not hostile, so in both
                        \ cases skip the following as it has no tactics

 CPX #MSL               \ If the ship is a missile, skip straight to MV26 to
 BEQ MV26               \ call the TACTICS routine, as we do this every
                        \ iteration of the main loop for missiles only

 LDA MCNT               \ Fetch the main loop counter

 EOR XSAV               \ Fetch the slot number of the ship we are moving, EOR
 AND #7                 \ with the loop counter and apply mod 8 to the result.
 BNE MV30               \ The result will be zero when "counter mod 8" matches
                        \ the slot number mod 8, so this makes sure we call
                        \ TACTICS 12 times every 8 main loop iterations, like
                        \ this:
                        \
                        \   Iteration 0, apply tactics to slots 0 and 8
                        \   Iteration 1, apply tactics to slots 1 and 9
                        \   Iteration 2, apply tactics to slots 2 and 10
                        \   Iteration 3, apply tactics to slots 3 and 11
                        \   Iteration 4, apply tactics to slot 4
                        \   Iteration 5, apply tactics to slot 5
                        \   Iteration 6, apply tactics to slot 6
                        \   Iteration 7, apply tactics to slot 7
                        \   Iteration 8, apply tactics to slots 0 and 8
                        \     ...
                        \
                        \ and so on

.MV26

 JSR TACTICS            \ Call TACTICS to apply AI tactics to this ship

.MV30

 JSR SCAN               \ Draw the ship on the scanner, which has the effect of
                        \ removing it, as it's already at this point and hasn't
                        \ yet moved

\ ******************************************************************************
\
\       Name: MVEIT (Part 3 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Move ship forward according to its speed
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Move the ship forward (along the vector pointing in the direction of
\     travel) according to its speed:
\
\     (x, y, z) += nosev_hi * speed / 64
\
\ ******************************************************************************

 LDA INWK+27            \ Set Q = the ship's speed byte #27 * 4
 ASL A
 ASL A
 STA Q

 LDA INWK+10            \ Set A = |nosev_x_hi|
 AND #%01111111

 JSR FMLTU              \ Set R = A * Q / 256
 STA R                  \       = |nosev_x_hi| * speed / 64

 LDA INWK+10            \ If nosev_x_hi is positive, then:
 LDX #0                 \
 JSR MVT1-2             \   (x_sign x_hi x_lo) = (x_sign x_hi x_lo) + R
                        \
                        \ If nosev_x_hi is negative, then:
                        \
                        \   (x_sign x_hi x_lo) = (x_sign x_hi x_lo) - R
                        \
                        \ So in effect, this does:
                        \
                        \   (x_sign x_hi x_lo) += nosev_x_hi * speed / 64

 LDA INWK+12            \ Set A = |nosev_y_hi|
 AND #%01111111

 JSR FMLTU              \ Set R = A * Q / 256
 STA R                  \       = |nosev_y_hi| * speed / 64

 LDA INWK+12            \ If nosev_y_hi is positive, then:
 LDX #3                 \
 JSR MVT1-2             \   (y_sign y_hi y_lo) = (y_sign y_hi y_lo) + R
                        \
                        \ If nosev_y_hi is negative, then:
                        \
                        \   (y_sign y_hi y_lo) = (y_sign y_hi y_lo) - R
                        \
                        \ So in effect, this does:
                        \
                        \   (y_sign y_hi y_lo) += nosev_y_hi * speed / 64

 LDA INWK+14            \ Set A = |nosev_z_hi|
 AND #%01111111

 JSR FMLTU              \ Set R = A * Q / 256
 STA R                  \       = |nosev_z_hi| * speed / 64

 LDA INWK+14            \ If nosev_y_hi is positive, then:
 LDX #6                 \
 JSR MVT1-2             \   (z_sign z_hi z_lo) = (z_sign z_hi z_lo) + R
                        \
                        \ If nosev_z_hi is negative, then:
                        \
                        \   (z_sign z_hi z_lo) = (z_sign z_hi z_lo) - R
                        \
                        \ So in effect, this does:
                        \
                        \   (z_sign z_hi z_lo) += nosev_z_hi * speed / 64

\ ******************************************************************************
\
\       Name: MVEIT (Part 4 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Apply acceleration to ship's speed as a one-off
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Apply acceleration to the ship's speed (if acceleration is non-zero),
\     and then zero the acceleration as it's a one-off change
\
\ ******************************************************************************

 LDA INWK+27            \ Set A = the ship's speed in byte #24 + the ship's
 CLC                    \ acceleration in byte #28
 ADC INWK+28

 BPL P%+4               \ If the result is positive, skip the following
                        \ instruction

 LDA #0                 \ Set A to 0 to stop the speed from going negative

 LDY #15                \ Fetch byte #15 from the ship's blueprint, which
                        \ contains the ship's maximum speed

 CMP (XX0),Y            \ If A < the ship's maximum speed, skip the following
 BCC P%+4               \ instruction

 LDA (XX0),Y            \ Set A to the ship's maximum speed

 STA INWK+27            \ We have now calculated the new ship's speed after
                        \ accelerating and keeping the speed within the ship's
                        \ limits, so store the updated speed in byte #27

 LDA #0                 \ We have added the ship's acceleration, so we now set
 STA INWK+28            \ it back to 0 in byte #28, as it's a one-off change

\ ******************************************************************************
\
\       Name: MVEIT (Part 5 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Rotate ship's location by our pitch and roll
\  Deep dive: Rotating the universe
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Rotate the ship's location in space by the amount of pitch and roll of
\     our ship. See below for a deeper explanation of this routine
\
\ ******************************************************************************

 LDX ALP1               \ Fetch the magnitude of the current roll into X, so
                        \ if the roll angle is alpha, X contains |alpha|

 LDA INWK               \ Set P = ~x_lo (i.e. with all its bits flipped) so that
 EOR #%11111111         \ we can pass x_lo to MLTU2 below)
 STA P

 LDA INWK+1             \ Set A = x_hi

 JSR MLTU2-2            \ Set (A P+1 P) = (A ~P) * X
                        \               = (x_hi x_lo) * alpha

 STA P+2                \ Store the high byte of the result in P+2, so we now
                        \ have:
                        \
                        \ P(2 1 0) = (x_hi x_lo) * alpha

 LDA ALP2+1             \ Fetch the flipped sign of the current roll angle alpha
 EOR INWK+2             \ from ALP2+1 and EOR with byte #2 (x_sign), so if the
                        \ flipped roll angle and x_sign have the same sign, A
                        \ will be positive, else it will be negative. So A will
                        \ contain the sign bit of x_sign * flipped alpha sign,
                        \ which is the opposite to the sign of the above result,
                        \ so we now have:
                        \
                        \ (A P+2 P+1) = - (x_sign x_hi x_lo) * alpha / 256

 LDX #3                 \ Set (A P+2 P+1) = (y_sign y_hi y_lo) + (A P+2 P+1)
 JSR MVT6               \                 = y - x * alpha / 256

 STA K2+3               \ Set K2(3) = A = the sign of the result

 LDA P+1                \ Set K2(1) = P+1, the low byte of the result
 STA K2+1

 EOR #%11111111         \ Set P = ~K2+1 (i.e. with all its bits flipped) so
 STA P                  \ that we can pass K2+1 to MLTU2 below)

 LDA P+2                \ Set K2(2) = A = P+2
 STA K2+2

                        \ So we now have result 1 above:
                        \
                        \ K2(3 2 1) = (A P+2 P+1)
                        \           = y - x * alpha / 256

 LDX BET1               \ Fetch the magnitude of the current pitch into X, so
                        \ if the pitch angle is beta, X contains |beta|

 JSR MLTU2-2            \ Set (A P+1 P) = (A ~P) * X
                        \               = K2(2 1) * beta

 STA P+2                \ Store the high byte of the result in P+2, so we now
                        \ have:
                        \
                        \ P(2 1 0) = K2(2 1) * beta

 LDA K2+3               \ Fetch the sign of the above result in K(3 2 1) from
 EOR BET2               \ K2+3 and EOR with BET2, the sign of the current pitch
                        \ rate, so if the pitch and K(3 2 1) have the same sign,
                        \ A will be positive, else it will be negative. So A
                        \ will contain the sign bit of K(3 2 1) * beta, which is
                        \ the same as the sign of the above result, so we now
                        \ have:
                        \
                        \ (A P+2 P+1) = K2(3 2 1) * beta / 256

 LDX #6                 \ Set (A P+2 P+1) = (z_sign z_hi z_lo) + (A P+2 P+1)
 JSR MVT6               \                 = z + K2 * beta / 256

 STA INWK+8             \ Set z_sign = A = the sign of the result

 LDA P+1                \ Set z_lo = P+1, the low byte of the result
 STA INWK+6

 EOR #%11111111         \ Set P = ~z_lo (i.e. with all its bits flipped) so that
 STA P                  \ we can pass z_lo to MLTU2 below)

 LDA P+2                \ Set z_hi = P+2
 STA INWK+7

                        \ So we now have result 2 above:
                        \
                        \ (z_sign z_hi z_lo) = (A P+2 P+1)
                        \                    = z + K2 * beta / 256

 JSR MLTU2              \ MLTU2 doesn't change Q, and Q was set to beta in
                        \ the previous call to MLTU2, so this call does:
                        \
                        \ (A P+1 P) = (A ~P) * Q
                        \           = (z_hi z_lo) * beta

 STA P+2                \ Set P+2 = A = the high byte of the result, so we
                        \ now have:
                        \
                        \ P(2 1 0) = (z_hi z_lo) * beta

 LDA K2+3               \ Set y_sign = K2+3
 STA INWK+5

 EOR BET2               \ EOR y_sign with BET2, the sign of the current pitch
 EOR INWK+8             \ rate, and z_sign. If the result is positive jump to
 BPL MV43               \ MV43, otherwise this means beta * z and y have
                        \ different signs, i.e. P(2 1) and K2(3 2 1) have
                        \ different signs, so we need to add them in order to
                        \ calculate K2(2 1) - P(2 1)

 LDA P+1                \ Set (y_hi y_lo) = K2(2 1) + P(2 1)
 ADC K2+1
 STA INWK+3
 LDA P+2
 ADC K2+2
 STA INWK+4

 JMP MV44               \ Jump to MV44 to continue the calculation

.MV43

 LDA K2+1               \ Reversing the logic above, we need to subtract P(2 1)
 SBC P+1                \ and K2(3 2 1) to calculate K2(2 1) - P(2 1), so this
 STA INWK+3             \ sets (y_hi y_lo) = K2(2 1) - P(2 1)
 LDA K2+2
 SBC P+2
 STA INWK+4

 BCS MV44               \ If the above subtraction did not underflow, then
                        \ jump to MV44, otherwise we need to negate the result

 LDA #1                 \ Negate (y_sign y_hi y_lo) using two's complement,
 SBC INWK+3             \ first doing the low bytes:
 STA INWK+3             \
                        \ y_lo = 1 - y_lo

 LDA #0                 \ Then the high bytes:
 SBC INWK+4             \
 STA INWK+4             \ y_hi = 0 - y_hi

 LDA INWK+5             \ And finally flip the sign in y_sign
 EOR #%10000000
 STA INWK+5

.MV44

                        \ So we now have result 3 above:
                        \
                        \ (y_sign y_hi y_lo) = K2(2 1) - P(2 1)
                        \                    = K2 - beta * z

 LDX ALP1               \ Fetch the magnitude of the current roll into X, so
                        \ if the roll angle is alpha, X contains |alpha|

 LDA INWK+3             \ Set P = ~y_lo (i.e. with all its bits flipped) so that
 EOR #&FF               \ we can pass y_lo to MLTU2 below)
 STA P

 LDA INWK+4             \ Set A = y_hi

 JSR MLTU2-2            \ Set (A P+1 P) = (A ~P) * X
                        \               = (y_hi y_lo) * alpha

 STA P+2                \ Store the high byte of the result in P+2, so we now
                        \ have:
                        \
                        \ P(2 1 0) = (y_hi y_lo) * alpha

 LDA ALP2               \ Fetch the correct sign of the current roll angle alpha
 EOR INWK+5             \ from ALP2 and EOR with byte #5 (y_sign), so if the
                        \ correct roll angle and y_sign have the same sign, A
                        \ will be positive, else it will be negative. So A will
                        \ contain the sign bit of x_sign * correct alpha sign,
                        \ which is the same as the sign of the above result,
                        \ so we now have:
                        \
                        \ (A P+2 P+1) = (y_sign y_hi y_lo) * alpha / 256

 LDX #0                 \ Set (A P+2 P+1) = (x_sign x_hi x_lo) + (A P+2 P+1)
 JSR MVT6               \                 = x + y * alpha / 256

 STA INWK+2             \ Set x_sign = A = the sign of the result

 LDA P+2                \ Set x_hi = P+2, the high byte of the result
 STA INWK+1

 LDA P+1                \ Set x_lo = P+1, the low byte of the result
 STA INWK

                        \ So we now have result 4 above:
                        \
                        \ x = x + alpha * y
                        \
                        \ and the rotation of (x, y, z) is done

\ ******************************************************************************
\
\       Name: MVEIT (Part 6 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Move the ship in space according to our speed
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Move the ship in space according to our speed (we already moved it
\     according to its own speed in part 3).
\
\ We do this by subtracting our speed (i.e. the distance we travel in this
\ iteration of the loop) from the other ship's z-coordinate. We subtract because
\ they appear to be "moving" in the opposite direction to us, and the whole
\ MVEIT routine is about moving the other ships rather than us (even though we
\ are the one doing the moving).
\
\ Other entry points:
\
\   MV45                Rejoin the MVEIT routine after the rotation, tactics and
\                       scanner code
\
\ ******************************************************************************

.MV45

 LDA DELTA              \ Set R to our speed in DELTA
 STA R

 LDA #%10000000         \ Set A to zeroes but with bit 7 set, so that (A R) is
                        \ a 16-bit number containing -R, or -speed

 LDX #6                 \ Set X to the z-axis so the call to MVT1 does this:
 JSR MVT1               \
                        \ (z_sign z_hi z_lo) = (z_sign z_hi z_lo) + (A R)
                        \                    = (z_sign z_hi z_lo) - speed

 LDA TYPE               \ If the ship type is not the sun (129) then skip the
 AND #%10000001         \ next instruction, otherwise return from the subroutine
 CMP #129               \ as we don't need to rotate the sun around its origin.
 BNE P%+3               \ Having both the AND and the CMP is a little odd, as
                        \ the sun is the only ship type with bits 0 and 7 set,
                        \ so the AND has no effect and could be removed

 RTS                    \ Return from the subroutine, as the ship we are moving
                        \ is the sun and doesn't need any of the following

\ ******************************************************************************
\
\       Name: MVEIT (Part 7 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Rotate ship's orientation vectors by pitch/roll
\  Deep dive: Orientation vectors
\             Pitching and rolling
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Rotate the ship's orientation vectors according to our pitch and roll
\
\ As with the previous step, this is all about moving the other ships rather
\ than us (even though we are the one doing the moving). So we rotate the
\ current ship's orientation vectors (which defines its orientation in space),
\ by the angles we are "moving" the rest of the sky through (alpha and beta, our
\ roll and pitch), so the ship appears to us to be stationary while we rotate.
\
\ ******************************************************************************

 LDY #9                 \ Apply our pitch and roll rotations to the current
 JSR MVS4               \ ship's nosev vector

 LDY #15                \ Apply our pitch and roll rotations to the current
 JSR MVS4               \ ship's roofv vector

 LDY #21                \ Apply our pitch and roll rotations to the current
 JSR MVS4               \ ship's sidev vector

\ ******************************************************************************
\
\       Name: MVEIT (Part 8 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Rotate ship about itself by its own pitch/roll
\  Deep dive: Orientation vectors
\             Pitching and rolling by a fixed angle
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * If the ship we are processing is rolling or pitching itself, rotate it and
\     apply damping if required
\
\ ******************************************************************************

 LDA INWK+30            \ Fetch the ship's pitch counter and extract the sign
 AND #%10000000         \ into RAT2
 STA RAT2

 LDA INWK+30            \ Fetch the ship's pitch counter and extract the value
 AND #%01111111         \ without the sign bit into A

 BEQ MV8                \ If the pitch counter is 0, then jump to MV8 to skip
                        \ the following, as the ship is not pitching

 CMP #%01111111         \ If bits 0-6 are set in the pitch counter (i.e. the
                        \ ship's pitch is not damping down), then the C flag
                        \ will be set by this instruction

 SBC #0                 \ Set A = A - 0 - (1 - C), so if we are damping then we
                        \ reduce A by 1, otherwise it is unchanged

 ORA RAT2               \ Change bit 7 of A to the sign we saved in RAT2, so
                        \ the updated pitch counter in A retains its sign

 STA INWK+30            \ Store the updated pitch counter in byte #30

 LDX #15                \ Rotate (roofv_x, nosev_x) by a small angle (pitch)
 LDY #9
 JSR MVS5

 LDX #17                \ Rotate (roofv_y, nosev_y) by a small angle (pitch)
 LDY #11
 JSR MVS5

 LDX #19                \ Rotate (roofv_z, nosev_z) by a small angle (pitch)
 LDY #13
 JSR MVS5

.MV8

 LDA INWK+29            \ Fetch the ship's roll counter and extract the sign
 AND #%10000000         \ into RAT2
 STA RAT2

 LDA INWK+29            \ Fetch the ship's roll counter and extract the value
 AND #%01111111         \ without the sign bit into A

 BEQ MV5                \ If the roll counter is 0, then jump to MV5 to skip the
                        \ following, as the ship is not rolling

 CMP #%01111111         \ If bits 0-6 are set in the roll counter (i.e. the
                        \ ship's roll is not damping down), then the C flag
                        \ will be set by this instruction

 SBC #0                 \ Set A = A - 0 - (1 - C), so if we are damping then we
                        \ reduce A by 1, otherwise it is unchanged

 ORA RAT2               \ Change bit 7 of A to the sign we saved in RAT2, so
                        \ the updated roll counter in A retains its sign

 STA INWK+29            \ Store the updated pitch counter in byte #29

 LDX #15                \ Rotate (roofv_x, sidev_x) by a small angle (roll)
 LDY #21
 JSR MVS5

 LDX #17                \ Rotate (roofv_y, sidev_y) by a small angle (roll)
 LDY #23
 JSR MVS5

 LDX #19                \ Rotate (roofv_z, sidev_z) by a small angle (roll)
 LDY #25
 JSR MVS5

\ ******************************************************************************
\
\       Name: MVEIT (Part 9 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Redraw on scanner, if it hasn't been destroyed
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * If the ship is exploding or being removed, hide it on the scanner
\
\   * Otherwise redraw the ship on the scanner, now that it's been moved
\
\ ******************************************************************************

.MV5

 LDA INWK+31            \ Fetch the ship's exploding/killed state from byte #31

 AND #%10100000         \ If we are exploding or removing this ship then jump to
 BNE MVD1               \ MVD1 to remove it from the scanner permanently

 LDA INWK+31            \ Set bit 4 to keep the ship visible on the scanner
 ORA #%00010000
 STA INWK+31

 JMP SCAN               \ Display the ship on the scanner, returning from the
                        \ subroutine using a tail call

.MVD1

 LDA INWK+31            \ Clear bit 4 to hide the ship on the scanner
 AND #%11101111
 STA INWK+31

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVT1
\       Type: Subroutine
\   Category: Moving
\    Summary: Calculate (x_sign x_hi x_lo) = (x_sign x_hi x_lo) + (A R)
\
\ ------------------------------------------------------------------------------
\
\ Add the signed delta (A R) to a ship's coordinate, along the axis given in X.
\ Mathematically speaking, this routine translates the ship along a single axis
\ by a signed delta. Taking the example of X = 0, the x-axis, it does the
\ following:
\
\   (x_sign x_hi x_lo) = (x_sign x_hi x_lo) + (A R)
\
\ (In practice, MVT1 is only ever called directly with A = 0 or 128, otherwise
\ it is always called via MVT-2, which clears A apart from the sign bit. The
\ routine is written to cope with a non-zero delta_hi, so it supports a full
\ 16-bit delta, but it appears that delta_hi is only ever used to hold the
\ sign of the delta.)
\
\ The comments below assume we are adding delta to the x-axis, though the axis
\ is determined by the value of X.
\
\ Arguments:
\
\   (A R)               The signed delta, so A = delta_hi and R = delta_lo
\
\   X                   Determines which coordinate axis of INWK to change:
\
\                         * X = 0 adds the delta to (x_lo, x_hi, x_sign)
\
\                         * X = 3 adds the delta to (y_lo, y_hi, y_sign)
\
\                         * X = 6 adds the delta to (z_lo, z_hi, z_sign)
\
\ Other entry points:
\
\   MVT1-2              Clear bits 0-6 of A before entering MVT1
\
\ ******************************************************************************

 AND #%10000000         \ Clear bits 0-6 of A

.MVT1

 ASL A                  \ Set the C flag to the sign bit of the delta, leaving
                        \ delta_hi << 1 in A

 STA S                  \ Set S = delta_hi << 1
                        \
                        \ This also clears bit 0 of S

 LDA #0                 \ Set T = just the sign bit of delta (in bit 7)
 ROR A
 STA T

 LSR S                  \ Set S = delta_hi >> 1
                        \       = |delta_hi|
                        \
                        \ This also clear the C flag, as we know that bit 0 of
                        \ S was clear before the LSR

 EOR INWK+2,X           \ If T EOR x_sign has bit 7 set, then x_sign and delta
 BMI MV10               \ have different signs, so jump to MV10

                        \ At this point, we know x_sign and delta have the same
                        \ sign, that sign is in T, and S contains |delta_hi|,
                        \ so now we want to do:
                        \
                        \   (x_sign x_hi x_lo) = (x_sign x_hi x_lo) + (S R)
                        \
                        \ and then set the sign of the result to the same sign
                        \ as x_sign and delta

 LDA R                  \ First we add the low bytes, so:
 ADC INWK,X             \
 STA INWK,X             \   x_lo = x_lo + R

 LDA S                  \ Then we add the high bytes:
 ADC INWK+1,X           \
 STA INWK+1,X           \   x_hi = x_hi + S

 LDA INWK+2,X           \ And finally we add any carry into x_sign, and if the
 ADC #0                 \ sign of x_sign and delta in T is negative, make sure
 ORA T                  \ the result is negative (by OR'ing with T)
 STA INWK+2,X

 RTS                    \ Return from the subroutine

.MV10

                        \ If we get here, we know x_sign and delta have
                        \ different signs, with delta's sign in T, and
                        \ |delta_hi| in S, so now we want to do:
                        \
                        \   (x_sign x_hi x_lo) = (x_sign x_hi x_lo) - (S R)
                        \
                        \ and then set the sign of the result according to
                        \ the signs of x_sign and delta

 LDA INWK,X             \ First we subtract the low bytes, so:
 SEC                    \
 SBC R                  \   x_lo = x_lo - R
 STA INWK,X

 LDA INWK+1,X           \ Then we subtract the high bytes:
 SBC S                  \
 STA INWK+1,X           \   x_hi = x_hi - S

 LDA INWK+2,X           \ And finally we subtract any borrow from bits 0-6 of
 AND #%01111111         \ x_sign, and give the result the opposite sign bit to T
 SBC #0                 \ (i.e. give it the sign of the original x_sign)
 ORA #%10000000
 EOR T
 STA INWK+2,X

 BCS MV11               \ If the C flag is set by the above SBC, then our sum
                        \ above didn't underflow and is correct - to put it
                        \ another way, (x_sign x_hi x_lo) >= (S R) so the result
                        \ should indeed have the same sign as x_sign, so jump to
                        \ MV11 to return from the subroutine

                        \ Otherwise our subtraction underflowed because
                        \ (x_sign x_hi x_lo) < (S R), so we now need to flip the
                        \ subtraction around by using two's complement to this:
                        \
                        \   (S R) - (x_sign x_hi x_lo)
                        \
                        \ and then we need to give the result the same sign as
                        \ (S R), the delta, as that's the dominant figure in the
                        \ sum

 LDA #1                 \ First we subtract the low bytes, so:
 SBC INWK,X             \
 STA INWK,X             \   x_lo = 1 - x_lo

 LDA #0                 \ Then we subtract the high bytes:
 SBC INWK+1,X           \
 STA INWK+1,X           \   x_hi = 0 - x_hi

 LDA #0                 \ And then we subtract the sign bytes:
 SBC INWK+2,X           \
                        \   x_sign = 0 - x_sign

 AND #%01111111         \ Finally, we set the sign bit to the sign in T, the
 ORA T                  \ sign of the original delta, as the delta is the
 STA INWK+2,X           \ dominant figure in the sum

.MV11

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVT3
\       Type: Subroutine
\   Category: Moving
\    Summary: Calculate K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)
\
\ ------------------------------------------------------------------------------
\
\ Add an INWK position coordinate - i.e. x, y or z - to K(3 2 1), like this:
\
\   K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)
\
\ The INWK coordinate to add to K(3 2 1) is specified by X.
\
\ Arguments:
\
\   X                   The coordinate to add to K(3 2 1), as follows:
\
\                         * If X = 0, add (x_sign x_hi x_lo)
\
\                         * If X = 3, add (y_sign y_hi y_lo)
\
\                         * If X = 6, add (z_sign z_hi z_lo)
\
\ Returns:
\
\   A                   Contains a copy of the high byte of the result, K+3
\
\   X                   X is preserved
\
\ ******************************************************************************

.MVT3

 LDA K+3                \ Set S = K+3
 STA S

 AND #%10000000         \ Set T = sign bit of K(3 2 1)
 STA T

 EOR INWK+2,X           \ If x_sign has a different sign to K(3 2 1), jump to
 BMI MV13               \ MV13 to process the addition as a subtraction

 LDA K+1                \ Set K(3 2 1) = K(3 2 1) + (x_sign x_hi x_lo)
 CLC                    \ starting with the low bytes
 ADC INWK,X
 STA K+1

 LDA K+2                \ Then the middle bytes
 ADC INWK+1,X
 STA K+2

 LDA K+3                \ And finally the high bytes
 ADC INWK+2,X

 AND #%01111111         \ Setting the sign bit of K+3 to T, the original sign
 ORA T                  \ of K(3 2 1)
 STA K+3

 RTS                    \ Return from the subroutine

.MV13

 LDA S                  \ Set S = |K+3| (i.e. K+3 with the sign bit cleared)
 AND #%01111111
 STA S

 LDA INWK,X             \ Set K(3 2 1) = (x_sign x_hi x_lo) - K(3 2 1)
 SEC                    \ starting with the low bytes
 SBC K+1
 STA K+1

 LDA INWK+1,X           \ Then the middle bytes
 SBC K+2
 STA K+2

 LDA INWK+2,X           \ And finally the high bytes, doing A = |x_sign| - |K+3|
 AND #%01111111         \ and setting the C flag for testing below
 SBC S

 ORA #%10000000         \ Set the sign bit of K+3 to the opposite sign of T,
 EOR T                  \ i.e. the opposite sign to the original K(3 2 1)
 STA K+3

 BCS MV14               \ If the C flag is set, i.e. |x_sign| >= |K+3|, then
                        \ the sign of K(3 2 1). In this case, we want the
                        \ result to have the same sign as the largest argument,
                        \ which is (x_sign x_hi x_lo), which we know has the
                        \ opposite sign to K(3 2 1), and that's what we just set
                        \ the sign of K(3 2 1) to... so we can jump to MV14 to
                        \ return from the subroutine

 LDA #1                 \ We need to swap the sign of the result in K(3 2 1),
 SBC K+1                \ which we do by calculating 0 - K(3 2 1), which we can
 STA K+1                \ do with 1 - C - K(3 2 1), as we know the C flag is
                        \ clear. We start with the low bytes

 LDA #0                 \ Then the middle bytes
 SBC K+2
 STA K+2

 LDA #0                 \ And finally the high bytes
 SBC K+3

 AND #%01111111         \ Set the sign bit of K+3 to the same sign as T,
 ORA T                  \ i.e. the same sign as the original K(3 2 1), as
 STA K+3                \ that's the largest argument

.MV14

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVS4
\       Type: Subroutine
\   Category: Moving
\    Summary: Apply pitch and roll to an orientation vector
\  Deep dive: Orientation vectors
\             Pitching and rolling
\
\ ------------------------------------------------------------------------------
\
\ Apply pitch and roll angles alpha and beta to the orientation vector in Y.
\
\ Specifically, this routine rotates a point (x, y, z) around the origin by
\ pitch alpha and roll beta, using the small angle approximation to make the
\ maths easier, and incorporating the Minsky circle algorithm to make the
\ rotation more stable (though more elliptic).
\
\ If that paragraph makes sense to you, then you should probably be writing
\ this commentary! For the rest of us, there's a detailed explanation of all
\ this in the deep dive on "Pitching and rolling".
\
\ Arguments:
\
\   Y                   Determines which of the INWK orientation vectors to
\                       transform:
\
\                         * Y = 9 rotates nosev: (nosev_x, nosev_y, nosev_z)
\
\                         * Y = 15 rotates roofv: (roofv_x, roofv_y, roofv_z)
\
\                         * Y = 21 rotates sidev: (sidev_x, sidev_y, sidev_z)
\
\ ******************************************************************************

.MVS4

 LDA ALPHA              \ Set Q = alpha (the roll angle to rotate through)
 STA Q

 LDX INWK+2,Y           \ Set (S R) = nosev_y
 STX R
 LDX INWK+3,Y
 STX S

 LDX INWK,Y             \ These instructions have no effect as MAD overwrites
 STX P                  \ X and P when called, but they set X = P = nosev_x_lo

 LDA INWK+1,Y           \ Set A = -nosev_x_hi
 EOR #%10000000

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+3,Y           \           = alpha * -nosev_x_hi + nosev_y
 STX INWK+2,Y           \
                        \ and store (A X) in nosev_y, so this does:
                        \
                        \ nosev_y = nosev_y - alpha * nosev_x_hi

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_y_lo

 LDX INWK,Y             \ Set (S R) = nosev_x
 STX R
 LDX INWK+1,Y
 STX S

 LDA INWK+3,Y           \ Set A = nosev_y_hi

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+1,Y           \           = alpha * nosev_y_hi + nosev_x
 STX INWK,Y             \
                        \ and store (A X) in nosev_x, so this does:
                        \
                        \ nosev_x = nosev_x + alpha * nosev_y_hi

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_x_lo

 LDA BETA               \ Set Q = beta (the pitch angle to rotate through)
 STA Q

 LDX INWK+2,Y           \ Set (S R) = nosev_y
 STX R
 LDX INWK+3,Y
 STX S
 LDX INWK+4,Y

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_y

 LDA INWK+5,Y           \ Set A = -nosev_z_hi
 EOR #%10000000

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+3,Y           \           = beta * -nosev_z_hi + nosev_y
 STX INWK+2,Y           \
                        \ and store (A X) in nosev_y, so this does:
                        \
                        \ nosev_y = nosev_y - beta * nosev_z_hi

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_y_lo

 LDX INWK+4,Y           \ Set (S R) = nosev_z
 STX R
 LDX INWK+5,Y
 STX S

 LDA INWK+3,Y           \ Set A = nosev_y_hi

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+5,Y           \           = beta * nosev_y_hi + nosev_z
 STX INWK+4,Y           \
                        \ and store (A X) in nosev_z, so this does:
                        \
                        \ nosev_z = nosev_z + beta * nosev_y_hi

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVS5
\       Type: Subroutine
\   Category: Moving
\    Summary: Apply a 3.6 degree pitch or roll to an orientation vector
\  Deep dive: Orientation vectors
\             Pitching and rolling by a fixed angle
\
\ ------------------------------------------------------------------------------
\
\ Pitch or roll a ship by a small, fixed amount (1/16 radians, or 3.6 degrees),
\ in a specified direction, by rotating the orientation vectors. The vectors to
\ rotate are given in X and Y, and the direction of the rotation is given in
\ RAT2. The calculation is as follows:
\
\   * If the direction is positive:
\
\     X = X * (1 - 1/512) + Y / 16
\     Y = Y * (1 - 1/512) - X / 16
\
\   * If the direction is negative:
\
\     X = X * (1 - 1/512) - Y / 16
\     Y = Y * (1 - 1/512) + X / 16
\
\ So if X = 15 (roofv_x), Y = 21 (sidev_x) and RAT2 is positive, it does this:
\
\   roofv_x = roofv_x * (1 - 1/512)  + sidev_x / 16
\   sidev_x = sidev_x * (1 - 1/512)  - roofv_x / 16
\
\ Arguments:
\
\   X                   The first vector to rotate:
\
\                         * If X = 15, rotate roofv_x
\
\                         * If X = 17, rotate roofv_y
\
\                         * If X = 19, rotate roofv_z
\
\                         * If X = 21, rotate sidev_x
\
\                         * If X = 23, rotate sidev_y
\
\                         * If X = 25, rotate sidev_z
\
\   Y                   The second vector to rotate:
\
\                         * If Y = 9,  rotate nosev_x
\
\                         * If Y = 11, rotate nosev_y
\
\                         * If Y = 13, rotate nosev_z
\
\                         * If Y = 21, rotate sidev_x
\
\                         * If Y = 23, rotate sidev_y
\
\                         * If Y = 25, rotate sidev_z
\
\   RAT2                The direction of the pitch or roll to perform, positive
\                       or negative (i.e. the sign of the roll or pitch counter
\                       in bit 7)
\
\ ******************************************************************************

.MVS5

 LDA INWK+1,X           \ Fetch roofv_x_hi, clear the sign bit, divide by 2 and
 AND #%01111111         \ store in T, so:
 LSR A                  \
 STA T                  \ T = |roofv_x_hi| / 2
                        \   = |roofv_x| / 512
                        \
                        \ The above is true because:
                        \
                        \ |roofv_x| = |roofv_x_hi| * 256 + roofv_x_lo
                        \
                        \ so:
                        \
                        \ |roofv_x| / 512 = |roofv_x_hi| * 256 / 512
                        \                    + roofv_x_lo / 512
                        \                  = |roofv_x_hi| / 2

 LDA INWK,X             \ Now we do the following subtraction:
 SEC                    \
 SBC T                  \ (S R) = (roofv_x_hi roofv_x_lo) - |roofv_x| / 512
 STA R                  \       = (1 - 1/512) * roofv_x
                        \
                        \ by doing the low bytes first

 LDA INWK+1,X           \ And then the high bytes (the high byte of the right
 SBC #0                 \ side of the subtraction being 0)
 STA S

 LDA INWK,Y             \ Set P = nosev_x_lo
 STA P

 LDA INWK+1,Y           \ Fetch the sign of nosev_x_hi (bit 7) and store in T
 AND #%10000000
 STA T

 LDA INWK+1,Y           \ Fetch nosev_x_hi into A and clear the sign bit, so
 AND #%01111111         \ A = |nosev_x_hi|

 LSR A                  \ Set (A P) = (A P) / 16
 ROR P                  \           = |nosev_x_hi nosev_x_lo| / 16
 LSR A                  \           = |nosev_x| / 16
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P

 ORA T                  \ Set the sign of A to the sign in T (i.e. the sign of
                        \ the original nosev_x), so now:
                        \
                        \ (A P) = nosev_x / 16

 EOR RAT2               \ Give it the sign as if we multiplied by the direction
                        \ by the pitch or roll direction

 STX Q                  \ Store the value of X so it can be restored after the
                        \ call to ADD

 JSR ADD                \ (A X) = (A P) + (S R)
                        \       = +/-nosev_x / 16 + (1 - 1/512) * roofv_x

 STA K+1                \ Set K(1 0) = (1 - 1/512) * roofv_x +/- nosev_x / 16
 STX K

 LDX Q                  \ Restore the value of X from before the call to ADD

 LDA INWK+1,Y           \ Fetch nosev_x_hi, clear the sign bit, divide by 2 and
 AND #%01111111         \ store in T, so:
 LSR A                  \
 STA T                  \ T = |nosev_x_hi| / 2
                        \   = |nosev_x| / 512

 LDA INWK,Y             \ Now we do the following subtraction:
 SEC                    \
 SBC T                  \ (S R) = (nosev_x_hi nosev_x_lo) - |nosev_x| / 512
 STA R                  \       = (1 - 1/512) * nosev_x
                        \
                        \ by doing the low bytes first

 LDA INWK+1,Y           \ And then the high bytes (the high byte of the right
 SBC #0                 \ side of the subtraction being 0)
 STA S

 LDA INWK,X             \ Set P = roofv_x_lo
 STA P

 LDA INWK+1,X           \ Fetch the sign of roofv_x_hi (bit 7) and store in T
 AND #%10000000
 STA T

 LDA INWK+1,X           \ Fetch roofv_x_hi into A and clear the sign bit, so
 AND #%01111111         \ A = |roofv_x_hi|

 LSR A                  \ Set (A P) = (A P) / 16
 ROR P                  \           = |roofv_x_hi roofv_x_lo| / 16
 LSR A                  \           = |roofv_x| / 16
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P

 ORA T                  \ Set the sign of A to the opposite sign to T (i.e. the
 EOR #%10000000         \ sign of the original -roofv_x), so now:
                        \
                        \ (A P) = -roofv_x / 16

 EOR RAT2               \ Give it the sign as if we multiplied by the direction
                        \ by the pitch or roll direction

 STX Q                  \ Store the value of X so it can be restored after the
                        \ call to ADD

 JSR ADD                \ (A X) = (A P) + (S R)
                        \       = -/+roofv_x / 16 + (1 - 1/512) * nosev_x

 STA INWK+1,Y           \ Set nosev_x = (1-1/512) * nosev_x -/+ roofv_x / 16
 STX INWK,Y

 LDX Q                  \ Restore the value of X from before the call to ADD

 LDA K                  \ Set roofv_x = K(1 0)
 STA INWK,X             \              = (1-1/512) * roofv_x +/- nosev_x / 16
 LDA K+1
 STA INWK+1,X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVT6
\       Type: Subroutine
\   Category: Moving
\    Summary: Calculate (A P+2 P+1) = (x_sign x_hi x_lo) + (A P+2 P+1)
\
\ ------------------------------------------------------------------------------
\
\ Do the following calculation, for the coordinate given by X (so this is what
\ it does for the x-coordinate):
\
\   (A P+2 P+1) = (x_sign x_hi x_lo) + (A P+2 P+1)
\
\ A is a sign bit and is not included in the calculation, but bits 0-6 of A are
\ preserved. Bit 7 is set to the sign of the result.
\
\ Arguments:
\
\   A                   The sign of P(2 1) in bit 7
\
\   P(2 1)              The 16-bit value we want to add the coordinate to
\
\   X                   The coordinate to add, as follows:
\
\                         * If X = 0, add to (x_sign x_hi x_lo)
\
\                         * If X = 3, add to (y_sign y_hi y_lo)
\
\                         * If X = 6, add to (z_sign z_hi z_lo)
\
\ Returns:
\
\   A                   The sign of the result (in bit 7)
\
\ ******************************************************************************

.MVT6

 TAY                    \ Store argument A into Y, for later use

 EOR INWK+2,X           \ Set A = A EOR x_sign

 BMI MV50               \ If the sign is negative, i.e. A and x_sign have
                        \ different signs, jump to MV50

                        \ The signs are the same, so we can add the two
                        \ arguments and keep the sign to get the result

 LDA P+1                \ First we add the low bytes:
 CLC                    \
 ADC INWK,X             \   P+1 = P+1 + x_lo
 STA P+1

 LDA P+2                \ And then the high bytes:
 ADC INWK+1,X           \
 STA P+2                \   P+2 = P+2 + x_hi

 TYA                    \ Restore the original A argument that we stored earlier
                        \ so that we keep the original sign

 RTS                    \ Return from the subroutine

.MV50

 LDA INWK,X             \ First we subtract the low bytes:
 SEC                    \
 SBC P+1                \   P+1 = x_lo - P+1
 STA P+1

 LDA INWK+1,X           \ And then the high bytes:
 SBC P+2                \
 STA P+2                \   P+2 = x_hi - P+2

 BCC MV51               \ If the last subtraction underflowed, then the C flag
                        \ will be clear and x_hi < P+2, so jump to MV51 to
                        \ negate the result

 TYA                    \ Restore the original A argument that we stored earlier
 EOR #%10000000         \ but flip bit 7, which flips the sign. We do this
                        \ because x_hi >= P+2 so we want the result to have the
                        \ same sign as x_hi (as it's the dominant side in this
                        \ calculation). The sign of x_hi is x_sign, and x_sign
                        \ has the opposite sign to A, so we flip the sign in A
                        \ to return the correct result

 RTS                    \ Return from the subroutine

.MV51

 LDA #1                 \ Our subtraction underflowed, so we negate the result
 SBC P+1                \ using two's complement, first with the low byte:
 STA P+1                \
                        \   P+1 = 1 - P+1

 LDA #0                 \ And then the high byte:
 SBC P+2                \
 STA P+2                \   P+2 = 0 - P+2

 TYA                    \ Restore the original A argument that we stored earlier
                        \ as this is the correct sign for the result. This is
                        \ because x_hi < P+2, so we want to return the same sign
                        \ as P+2, the dominant side

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MV40
\       Type: Subroutine
\   Category: Moving
\    Summary: Rotate the planet or sun's location in space by the amount of
\             pitch and roll of our ship
\
\ ------------------------------------------------------------------------------
\
\ We implement this using the same equations as in part 5 of MVEIT, where we
\ rotated the current ship's location by our pitch and roll. Specifically, the
\ calculation is as follows:
\
\   1. K2 = y - alpha * x
\   2. z = z + beta * K2
\   3. y = K2 - beta * z
\   4. x = x + alpha * y
\
\ See the deep dive on "Rotating the universe" for more details on the above.
\
\ ******************************************************************************

.MV40

 LDA ALPHA              \ Set Q = -ALPHA, so Q contains the angle we want to
 EOR #%10000000         \ roll the planet through (i.e. in the opposite
 STA Q                  \ direction to our ship's roll angle alpha)

 LDA INWK               \ Set P(1 0) = (x_hi x_lo)
 STA P
 LDA INWK+1
 STA P+1

 LDA INWK+2             \ Set A = x_sign

 JSR MULT3              \ Set K(3 2 1 0) = (A P+1 P) * Q
                        \
                        \ which also means:
                        \
                        \   K(3 2 1) = (A P+1 P) * Q / 256
                        \            = x * -alpha / 256
                        \            = - alpha * x / 256

 LDX #3                 \ Set K(3 2 1) = (y_sign y_hi y_lo) + K(3 2 1)
 JSR MVT3               \              = y - alpha * x / 256

 LDA K+1                \ Set K2(2 1) = P(1 0) = K(2 1)
 STA K2+1
 STA P

 LDA K+2                \ Set K2+2 = K+2
 STA K2+2

 STA P+1                \ Set P+1 = K+2

 LDA BETA               \ Set Q = beta, the pitch angle of our ship
 STA Q

 LDA K+3                \ Set K+3 to K2+3, so now we have result 1 above:
 STA K2+3               \
                        \   K2(3 2 1) = K(3 2 1)
                        \             = y - alpha * x / 256

                        \ We also have:
                        \
                        \   A = K+3
                        \
                        \   P(1 0) = K(2 1)
                        \
                        \ so combined, these mean:
                        \
                        \   (A P+1 P) = K(3 2 1)
                        \             = K2(3 2 1)

 JSR MULT3              \ Set K(3 2 1 0) = (A P+1 P) * Q
                        \
                        \ which also means:
                        \
                        \   K(3 2 1) = (A P+1 P) * Q / 256
                        \            = K2(3 2 1) * beta / 256
                        \            = beta * K2 / 256

 LDX #6                 \ K(3 2 1) = (z_sign z_hi z_lo) + K(3 2 1)
 JSR MVT3               \          = z + beta * K2 / 256

 LDA K+1                \ Set P = K+1
 STA P

 STA INWK+6             \ Set z_lo = K+1

 LDA K+2                \ Set P+1 = K+2
 STA P+1

 STA INWK+7             \ Set z_hi = K+2

 LDA K+3                \ Set A = z_sign = K+3, so now we have:
 STA INWK+8             \
                        \   (z_sign z_hi z_lo) = K(3 2 1)
                        \                      = z + beta * K2 / 256

                        \ So we now have result 2 above:
                        \
                        \   z = z + beta * K2

 EOR #%10000000         \ Flip the sign bit of A to give A = -z_sign

 JSR MULT3              \ Set K(3 2 1 0) = (A P+1 P) * Q
                        \                = (-z_sign z_hi z_lo) * beta
                        \                = -z * beta

 LDA K+3                \ Set T to the sign bit of K(3 2 1 0), i.e. to the sign
 AND #%10000000         \ bit of -z * beta
 STA T

 EOR K2+3               \ If K2(3 2 1 0) has a different sign to K(3 2 1 0),
 BMI MV1                \ then EOR'ing them will produce a 1 in bit 7, so jump
                        \ to MV1 to take this into account

                        \ If we get here, K and K2 have the same sign, so we can
                        \ add them together to get the result we're after, and
                        \ then set the sign afterwards

 LDA K                  \ We now do the following sum:
\CLC                    \
 ADC K2                 \   (A y_hi y_lo -) = K(3 2 1 0) + K2(3 2 1 0)
                        \
                        \ starting with the low bytes (which we don't keep)
                        \
                        \ The CLC instruction is commented out in the original
                        \ source. It isn't needed because MULT3 clears the C
                        \ flag, so this is an example of the authors finding
                        \ one more precious byte to save

 LDA K+1                \ We then do the middle bytes, which go into y_lo
 ADC K2+1
 STA INWK+3

 LDA K+2                \ And then the high bytes, which go into y_hi
 ADC K2+2
 STA INWK+4

 LDA K+3                \ And then the sign bytes into A, so overall we have the
 ADC K2+3               \ following, if we drop the low bytes from the result:
                        \
                        \   (A y_hi y_lo) = (K + K2) / 256

 JMP MV2                \ Jump to MV2 to skip the calculation for when K and K2
                        \ have different signs

.MV1

 LDA K                  \ If we get here then K2 and K have different signs, so
 SEC                    \ instead of adding, we need to subtract to get the
 SBC K2                 \ result we want, like this:
                        \
                        \   (A y_hi y_lo -) = K(3 2 1 0) - K2(3 2 1 0)
                        \
                        \ starting with the low bytes (which we don't keep)

 LDA K+1                \ We then do the middle bytes, which go into y_lo
 SBC K2+1
 STA INWK+3

 LDA K+2                \ And then the high bytes, which go into y_hi
 SBC K2+2
 STA INWK+4

 LDA K2+3               \ Now for the sign bytes, so first we extract the sign
 AND #%01111111         \ byte from K2 without the sign bit, so P = |K2+3|
 STA P

 LDA K+3                \ And then we extract the sign byte from K without the
 AND #%01111111         \ sign bit, so A = |K+3|

 SBC P                  \ And finally we subtract the sign bytes, so P = A - P
 STA P

                        \ By now we have the following, if we drop the low bytes
                        \ from the result:
                        \
                        \   (A y_hi y_lo) = (K - K2) / 256
                        \
                        \ so now we just need to make sure the sign of the
                        \ result is correct

 BCS MV2                \ If the C flag is set, then the last subtraction above
                        \ didn't underflow and the result is correct, so jump to
                        \ MV2 as we are done with this particular stage

 LDA #1                 \ Otherwise the subtraction above underflowed, as K2 is
 SBC INWK+3             \ the dominant part of the subtraction, so we need to
 STA INWK+3             \ negate the result using two's complement, starting
                        \ with the low bytes:
                        \
                        \   y_lo = 1 - y_lo

 LDA #0                 \ And then the high bytes:
 SBC INWK+4             \
 STA INWK+4             \   y_hi = 0 - y_hi

 LDA #0                 \ And finally the sign bytes:
 SBC P                  \
                        \   A = 0 - P

 ORA #%10000000         \ We now force the sign bit to be negative, so that the
                        \ final result below gets the opposite sign to K, which
                        \ we want as K2 is the dominant part of the sum

.MV2

 EOR T                  \ T contains the sign bit of K, so if K is negative,
                        \ this flips the sign of A

 STA INWK+5             \ Store A in y_sign

                        \ So we now have result 3 above:
                        \
                        \   y = K2 + K
                        \     = K2 - beta * z

 LDA ALPHA              \ Set A = alpha
 STA Q

 LDA INWK+3             \ Set P(1 0) = (y_hi y_lo)
 STA P
 LDA INWK+4
 STA P+1

 LDA INWK+5             \ Set A = y_sign

 JSR MULT3              \ Set K(3 2 1 0) = (A P+1 P) * Q
                        \                = (y_sign y_hi y_lo) * alpha
                        \                = y * alpha

 LDX #0                 \ Set K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)
 JSR MVT3               \              = x + y * alpha / 256

 LDA K+1                \ Set (x_sign x_hi x_lo) = K(3 2 1)
 STA INWK               \                        = x + y * alpha / 256
 LDA K+2
 STA INWK+1
 LDA K+3
 STA INWK+2

                        \ So we now have result 4 above:
                        \
                        \   x = x + y * alpha

 JMP MV45               \ We have now finished rotating the planet or sun by
                        \ our pitch and roll, so jump back into the MVEIT
                        \ routine at MV45 to apply all the other movements

\ ******************************************************************************
\
\ Save ELTA.bin
\
\ ******************************************************************************

PRINT "ELITE A"
PRINT "Assembled at ", ~CODE%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_A%

PRINT "S.ELTA ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_A%
SAVE "3-assembled-output/ELTA.bin", CODE%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE B FILE
\
\ Produces the binary file ELTB.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CODE_B% = P%
LOAD_B% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: NA%
\       Type: Variable
\   Category: Save and load
\    Summary: The data block for the last saved commander
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Contains the last saved commander data, with the name at NA% and the data at
\ NA%+8 onwards. The size of the data block is given in NT% (which also includes
\ the two checksum bytes that follow this block). This block is initially set up
\ with the default commander, which can be maxed out for testing purposes by
\ setting Q% to TRUE.
\
\ The commander's name is stored at NA%, and can be up to 7 characters long
\ (the DFS filename limit). It is terminated with a carriage return character,
\ ASCII 13.
\
\ The offset of each byte within a saved commander file is also shown as #0, #1
\ and so on, so the kill tally, for example, is in bytes #71 and #72 of the
\ saved file. The related variable name from the current commander block is
\ also shown.
\
\ ******************************************************************************

.NA%

 EQUS "JAMESON"         \ The current commander name, which defaults to JAMESON
 EQUB 13                \
                        \ The commander name can be up to 7 characters (the DFS
                        \ limit for filenames), and is terminated by a carriage
                        \ return

                        \ NA%+8 is the start of the commander data block
                        \
                        \ This block contains the last saved commander data
                        \ block. As the game is played it uses an identical
                        \ block at location TP to store the current commander
                        \ state, and that block is copied here when the game is
                        \ saved. Conversely, when the game starts up, the block
                        \ here is copied to TP, which restores the last saved
                        \ commander when we die
                        \
                        \ The initial state of this block defines the default
                        \ commander. Q% can be set to TRUE to give the default
                        \ commander lots of credits and equipment

 EQUB 0                 \ TP = Mission status, #0

 EQUB 20                \ QQ0 = Current system X-coordinate (Lave), #1
 EQUB 173               \ QQ1 = Current system Y-coordinate (Lave), #2

 EQUW &5A4A             \ QQ21 = Seed s0 for system 0, galaxy 0 (Tibedied), #3-4
 EQUW &0248             \ QQ21 = Seed s1 for system 0, galaxy 0 (Tibedied), #5-6
 EQUW &B753             \ QQ21 = Seed s2 for system 0, galaxy 0 (Tibedied), #7-8

IF Q%
 EQUD &00CA9A3B         \ CASH = Amount of cash (100,000,000 Cr), #9-12
ELSE
 EQUD &E8030000         \ CASH = Amount of cash (100 Cr), #9-12
ENDIF

 EQUB 70                \ QQ14 = Fuel level, #13

 EQUB 0                 \ COK = Competition flags, #14

 EQUB 0                 \ GCNT = Galaxy number, 0-7, #15

 EQUB POW+(128 AND Q%)  \ LASER = Front laser, #16

 EQUB (POW+128) AND Q%  \ LASER+1 = Rear laser, #17

 EQUB 0                 \ LASER+2 = Left laser, #18

 EQUB 0                 \ LASER+3 = Right laser, #19

 EQUW 0                 \ These bytes appear to be unused (they were originally
                        \ used for up/down lasers, but they were dropped),
                        \ #20-21

 EQUB 22+(15 AND Q%)    \ CRGO = Cargo capacity, #22

 EQUB 0                 \ QQ20+0  = Amount of food in cargo hold, #23
 EQUB 0                 \ QQ20+1  = Amount of textiles in cargo hold, #24
 EQUB 0                 \ QQ20+2  = Amount of radioactives in cargo hold, #25
 EQUB 0                 \ QQ20+3  = Amount of slaves in cargo hold, #26
 EQUB 0                 \ QQ20+4  = Amount of liquor/Wines in cargo hold, #27
 EQUB 0                 \ QQ20+5  = Amount of luxuries in cargo hold, #28
 EQUB 0                 \ QQ20+6  = Amount of narcotics in cargo hold, #29
 EQUB 0                 \ QQ20+7  = Amount of computers in cargo hold, #30
 EQUB 0                 \ QQ20+8  = Amount of machinery in cargo hold, #31
 EQUB 0                 \ QQ20+9  = Amount of alloys in cargo hold, #32
 EQUB 0                 \ QQ20+10 = Amount of firearms in cargo hold, #33
 EQUB 0                 \ QQ20+11 = Amount of furs in cargo hold, #34
 EQUB 0                 \ QQ20+12 = Amount of minerals in cargo hold, #35
 EQUB 0                 \ QQ20+13 = Amount of gold in cargo hold, #36
 EQUB 0                 \ QQ20+14 = Amount of platinum in cargo hold, #37
 EQUB 0                 \ QQ20+15 = Amount of gem-stones in cargo hold, #38
 EQUB 0                 \ QQ20+16 = Amount of alien items in cargo hold, #39

 EQUB Q%                \ ECM = E.C.M. system, #40

 EQUB Q%                \ BST = Fuel scoops ("barrel status"), #41

 EQUB Q% AND 127        \ BOMB = Energy bomb, #42

 EQUB Q% AND 1          \ ENGY = Energy/shield level, #43

 EQUB Q%                \ DKCMP = Docking computer, #44

 EQUB Q%                \ GHYP = Galactic hyperdrive, #45

 EQUB Q%                \ ESCP = Escape pod, #46

 EQUD 0                 \ These four bytes appear to be unused, #47-50

 EQUB 3+(Q% AND 1)      \ NOMSL = Number of missiles, #51

 EQUB 0                 \ FIST = Legal status ("fugitive/innocent status"), #52

 EQUB 16                \ AVL+0  = Market availability of food, #53
 EQUB 15                \ AVL+1  = Market availability of textiles, #54
 EQUB 17                \ AVL+2  = Market availability of radioactives, #55
 EQUB 0                 \ AVL+3  = Market availability of slaves, #56
 EQUB 3                 \ AVL+4  = Market availability of liquor/Wines, #57
 EQUB 28                \ AVL+5  = Market availability of luxuries, #58
 EQUB 14                \ AVL+6  = Market availability of narcotics, #59
 EQUB 0                 \ AVL+7  = Market availability of computers, #60
 EQUB 0                 \ AVL+8  = Market availability of machinery, #61
 EQUB 10                \ AVL+9  = Market availability of alloys, #62
 EQUB 0                 \ AVL+10 = Market availability of firearms, #63
 EQUB 17                \ AVL+11 = Market availability of furs, #64
 EQUB 58                \ AVL+12 = Market availability of minerals, #65
 EQUB 7                 \ AVL+13 = Market availability of gold, #66
 EQUB 9                 \ AVL+14 = Market availability of platinum, #67
 EQUB 8                 \ AVL+15 = Market availability of gem-stones, #68
 EQUB 0                 \ AVL+16 = Market availability of alien items, #69

 EQUB 0                 \ QQ26 = Random byte that changes for each visit to a
                        \ system, for randomising market prices, #70

 EQUW 0                 \ TALLY = Number of kills, #71-72

 EQUB 128               \ SVC = Save count, #73

\ ******************************************************************************
\
\       Name: CHK2
\       Type: Variable
\   Category: Save and load
\    Summary: Second checksum byte for the saved commander data file
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Second commander checksum byte. If the default commander is changed, a new
\ checksum will be calculated and inserted by the elite-checksum.py script.
\
\ The offset of this byte within a saved commander file is also shown (it's at
\ byte #74).
\
\ ******************************************************************************

.CHK2

 EQUB &03 EOR &A9       \ The checksum value for the default commander, EOR'd
                        \ with &A9 to make it harder to tamper with the checksum
                        \ byte, #74

\ ******************************************************************************
\
\       Name: CHK
\       Type: Variable
\   Category: Save and load
\    Summary: First checksum byte for the saved commander data file
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Commander checksum byte. If the default commander is changed, a new checksum
\ will be calculated and inserted by the elite-checksum.py script.
\
\ The offset of this byte within a saved commander file is also shown (it's at
\ byte #75).
\
\ ******************************************************************************

.CHK

 EQUB &03               \ The checksum value for the default commander, #75

\ ******************************************************************************
\
\       Name: UNIV
\       Type: Variable
\   Category: Universe
\    Summary: Table of pointers to the local universe's ship data blocks
\  Deep dive: The local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ See the deep dive on "Ship data blocks" for details on ship data blocks, and
\ the deep dive on "The local bubble of universe" for details of how Elite
\ stores the local universe in K%, FRIN and UNIV.
\
\ ******************************************************************************

.UNIV

FOR I%, 0, NOSH

 EQUW K% + I% * NI%     \ Address of block no. I%, of size NI%, in workspace K%

NEXT

\ ******************************************************************************
\
\       Name: TWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 4
\  Deep dive: Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 4 (the top part of the
\ split screen). See the PIXEL routine for details.
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
\       Name: TWOS2
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made double-pixel character row bytes for mode 4
\  Deep dive: Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting two-pixel dashes in mode 4 (the top part of the
\ split screen). See the PIXEL routine for details.
\
\ ******************************************************************************

.TWOS2

 EQUB %11000000
 EQUB %01100000
 EQUB %00110000
 EQUB %00011000
 EQUB %00001100
 EQUB %00000110
 EQUB %00000011
 EQUB %00000011

\ ******************************************************************************
\
\       Name: CTWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 5
\  Deep dive: Drawing colour pixels in mode 5
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 5 (the bottom part of
\ the split screen). See the dashboard routines SCAN, DIL2 and CPIX2 for
\ details.
\
\ There is one extra row to support the use of CTWOS+1,X indexing in the CPIX2
\ routine. The extra row is a repeat of the first row, and saves us from having
\ to work out whether CTWOS+1+X needs to be wrapped around when drawing a
\ two-pixel dash that crosses from one character block into another. See CPIX2
\ for more details.
\
\ ******************************************************************************

.CTWOS

 EQUB %10001000
 EQUB %01000100
 EQUB %00100010
 EQUB %00010001
 EQUB %10001000

\ ******************************************************************************
\
\       Name: LOIN (Part 1 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Calculate the line gradient in the form of deltas
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ This stage calculates the line deltas.
\
\ Arguments:
\
\   X1                  The screen x-coordinate of the start of the line
\
\   Y1                  The screen y-coordinate of the start of the line
\
\   X2                  The screen x-coordinate of the end of the line
\
\   Y2                  The screen y-coordinate of the end of the line
\
\ Returns:
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   LL30                LL30 is a synonym for LOIN and draws a line from
\                       (X1, Y1) to (X2, Y2)
\
\ ******************************************************************************

.LL30

 SKIP 0                 \ LL30 is a synomym for LOIN
                        \
                        \ In the cassette and disc versions of Elite, LL30 and
                        \ LOIN are synonyms for the same routine, presumably
                        \ because the two developers each had their own line
                        \ routines to start with, and then chose one of them for
                        \ the final game

.LOIN

 STY YSAV               \ Store Y into YSAV, so we can preserve it across the
                        \ call to this subroutine

 LDA #128               \ Set S = 128, which is the starting point for the
 STA S                  \ slope error (representing half a pixel)

 ASL A                  \ Set SWAP = 0, as %10000000 << 1 = 0
 STA SWAP

 LDA X2                 \ Set A = X2 - X1
 SBC X1                 \       = delta_x
                        \
                        \ This subtraction works as the ASL A above sets the C
                        \ flag

 BCS LI1                \ If X2 > X1 then A is already positive and we can skip
                        \ the next three instructions

 EOR #%11111111         \ Negate the result in A by flipping all the bits and
 ADC #1                 \ adding 1, i.e. using two's complement to make it
                        \ positive

 SEC                    \ Set the C flag, ready for the subtraction below

.LI1

 STA P                  \ Store A in P, so P = |X2 - X1|, or |delta_x|

 LDA Y2                 \ Set A = Y2 - Y1
 SBC Y1                 \       = delta_y
                        \
                        \ This subtraction works as we either set the C flag
                        \ above, or we skipped that SEC instruction with a BCS

 BCS LI2                \ If Y2 > Y1 then A is already positive and we can skip
                        \ the next two instructions

 EOR #%11111111         \ Negate the result in A by flipping all the bits and
 ADC #1                 \ adding 1, i.e. using two's complement to make it
                        \ positive

.LI2

 STA Q                  \ Store A in Q, so Q = |Y2 - Y1|, or |delta_y|

 CMP P                  \ If Q < P, jump to STPX to step along the x-axis, as
 BCC STPX               \ the line is closer to being horizontal than vertical

 JMP STPY               \ Otherwise Q >= P so jump to STPY to step along the
                        \ y-axis, as the line is closer to being vertical than
                        \ horizontal

\ ******************************************************************************
\
\       Name: LOIN (Part 2 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Line has a shallow gradient, step right along x-axis
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * |delta_y| < |delta_x|
\
\   * The line is closer to being horizontal than vertical
\
\   * We are going to step right along the x-axis
\
\   * We potentially swap coordinates to make sure X1 < X2
\
\ ******************************************************************************

.STPX

 LDX X1                 \ Set X = X1

 CPX X2                 \ If X1 < X2, jump down to LI3, as the coordinates are
 BCC LI3                \ already in the order that we want

 DEC SWAP               \ Otherwise decrement SWAP from 0 to &FF, to denote that
                        \ we are swapping the coordinates around

 LDA X2                 \ Swap the values of X1 and X2
 STA X1
 STX X2

 TAX                    \ Set X = X1

 LDA Y2                 \ Swap the values of Y1 and Y2
 LDY Y1
 STA Y1
 STY Y2

.LI3

                        \ By this point we know the line is horizontal-ish and
                        \ X1 < X2, so we're going from left to right as we go
                        \ from X1 to X2

 LDA Y1                 \ Set A = Y1 / 8, so A now contains the character row
 LSR A                  \ that will contain our horizontal line
 LSR A
 LSR A

 ORA #&60               \ As A < 32, this effectively adds &60 to A, which gives
                        \ us the screen address of the character row (as each
                        \ character row takes up 256 bytes, and the first
                        \ character row is at screen address &6000, or page &60)

 STA SCH                \ Store the page number of the character row in SCH, so
                        \ the high byte of SC is set correctly for drawing the
                        \ start of our line

 LDA Y1                 \ Set Y = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw the start of
 TAY                    \ our line (as each character block has 8 rows)

 TXA                    \ Set A = bits 3-7 of X1
 AND #%11111000

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw the
                        \ start of our line on

 TXA                    \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWOS,X             \ Fetch a 1-pixel byte from TWOS where pixel X is set,
 STA R                  \ and store it in R

                        \ The following calculates:
                        \
                        \   Q = Q / P
                        \     = |delta_y| / |delta_x|
                        \
                        \ using the same shift-and-subtract algorithm that's
                        \ documented in TIS2

 LDA Q                  \ Set A = |delta_y|

 LDX #%11111110         \ Set Q to have bits 1-7 set, so we can rotate through 7
 STX Q                  \ loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use Q to catch our result bits into bit 0 each time

.LIL1

 ASL A                  \ Shift A to the left

 BCS LI4                \ If bit 7 of A was set, then jump straight to the
                        \ subtraction

 CMP P                  \ If A < P, skip the following subtraction
 BCC LI5

.LI4

 SBC P                  \ A >= P, so set A = A - P

 SEC                    \ Set the C flag to rotate into the result in Q

.LI5

 ROL Q                  \ Rotate the counter in Q to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS LIL1               \ If we still have set bits in Q, loop back to TIL2 to
                        \ do the next iteration of 7

                        \ We now have:
                        \
                        \   Q = A / P
                        \     = |delta_y| / |delta_x|
                        \
                        \ and the C flag is clear

 LDX P                  \ Set X = P + 1
 INX                    \       = |delta_x| + 1
                        \
                        \ We add 1 so we can skip the first pixel plot if the
                        \ line is being drawn with swapped coordinates

 LDA Y2                 \ Set A = Y2 - Y1 - 1 (as the C flag is clear following
 SBC Y1                 \ the above division)

 BCS DOWN               \ If Y2 >= Y1 - 1 then jump to DOWN, as we need to draw
                        \ the line to the right and down

\ ******************************************************************************
\
\       Name: LOIN (Part 3 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a shallow line going right and up or left and down
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going right and up (no swap) or left and down (swap)
\
\   * X1 < X2 and Y1-1 > Y2
\
\   * Draw from (X1, Y1) at bottom left to (X2, Y2) at top right
\
\ ******************************************************************************

 LDA SWAP               \ If SWAP > 0 then we swapped the coordinates above, so
 BNE LI6                \ jump down to LI6 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL2

                        \ We now loop along the line from left to right, using X
                        \ as a decreasing counter, and at each count we plot a
                        \ single pixel using the pixel mask in R

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI6

 LSR R                  \ Shift the single pixel in R to the right to step along
                        \ the x-axis, so the next pixel we plot will be at the
                        \ next x-coordinate along

 BCC LI7                \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI7

 ROR R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R right so the set C flag goes
                        \ back into the left end, giving %10000000

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

.LI7

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LIC2               \ If the addition didn't overflow, jump to LIC2

 DEY                    \ Otherwise we just overflowed, so decrement Y to move
                        \ to the pixel line above

 BPL LIC2               \ If Y is positive we are still within the same
                        \ character block, so skip to LIC2

 DEC SCH                \ Otherwise we need to move up into the character block
 LDY #7                 \ above, so decrement the high byte of the screen
                        \ address and set the pixel line to the last line in
                        \ that character block

.LIC2

 DEX                    \ Decrement the counter in X

 BNE LIL2               \ If we haven't yet reached the right end of the line,
                        \ loop back to LIL2 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 4 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a shallow line going right and down or left and up
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going right and down (no swap) or left and up (swap)
\
\   * X1 < X2 and Y1-1 <= Y2
\
\   * Draw from (X1, Y1) at top left to (X2, Y2) at bottom right
\
\ ******************************************************************************

.DOWN

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI9                \ so jump down to LI9 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL3

                        \ We now loop along the line from left to right, using X
                        \ as a decreasing counter, and at each count we plot a
                        \ single pixel using the pixel mask in R

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI9

 LSR R                  \ Shift the single pixel in R to the right to step along
                        \ the x-axis, so the next pixel we plot will be at the
                        \ next x-coordinate along

 BCC LI10               \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI10

 ROR R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R right so the set C flag goes
                        \ back into the left end, giving %10000000

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

.LI10

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LIC3               \ If the addition didn't overflow, jump to LIC3

 INY                    \ Otherwise we just overflowed, so increment Y to move
                        \ to the pixel line below

 CPY #8                 \ If Y < 8 we are still within the same character block,
 BNE LIC3               \ so skip to LIC3

 INC SCH                \ Otherwise we need to move down into the character
 LDY #0                 \ block below, so increment the high byte of the screen
                        \ address and set the pixel line to the first line in
                        \ that character block

.LIC3

 DEX                    \ Decrement the counter in X

 BNE LIL3               \ If we haven't yet reached the right end of the line,
                        \ loop back to LIL3 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 5 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Line has a steep gradient, step up along y-axis
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * |delta_y| >= |delta_x|
\
\   * The line is closer to being vertical than horizontal
\
\   * We are going to step up along the y-axis
\
\   * We potentially swap coordinates to make sure Y1 >= Y2
\
\ ******************************************************************************

.STPY

 LDY Y1                 \ Set A = Y = Y1
 TYA

 LDX X1                 \ Set X = X1

 CPY Y2                 \ If Y1 >= Y2, jump down to LI15, as the coordinates are
 BCS LI15               \ already in the order that we want

 DEC SWAP               \ Otherwise decrement SWAP from 0 to &FF, to denote that
                        \ we are swapping the coordinates around

 LDA X2                 \ Swap the values of X1 and X2
 STA X1
 STX X2

 TAX                    \ Set X = X1

 LDA Y2                 \ Swap the values of Y1 and Y2
 STA Y1
 STY Y2

 TAY                    \ Set Y = A = Y1

.LI15

                        \ By this point we know the line is vertical-ish and
                        \ Y1 >= Y2, so we're going from top to bottom as we go
                        \ from Y1 to Y2

 LSR A                  \ Set A = Y1 / 8, so A now contains the character row
 LSR A                  \ that will contain our horizontal line
 LSR A

 ORA #&60               \ As A < 32, this effectively adds &60 to A, which gives
                        \ us the screen address of the character row (as each
                        \ character row takes up 256 bytes, and the first
                        \ character row is at screen address &6000, or page &60)

 STA SCH                \ Store the page number of the character row in SCH, so
                        \ the high byte of SC is set correctly for drawing the
                        \ start of our line

 TXA                    \ Set A = bits 3-7 of X1
 AND #%11111000

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw the
                        \ start of our line on

 TXA                    \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWOS,X             \ Fetch a 1-pixel byte from TWOS where pixel X is set,
 STA R                  \ and store it in R

 LDA Y1                 \ Set Y = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw the start of
 TAY                    \ our line (as each character block has 8 rows)

                        \ The following calculates:
                        \
                        \   P = P / Q
                        \     = |delta_x| / |delta_y|
                        \
                        \ using the same shift-and-subtract algorithm
                        \ documented in TIS2

 LDA P                  \ Set A = |delta_x|

 LDX #1                 \ Set Q to have bits 1-7 clear, so we can rotate through
 STX P                  \ 7 loop iterations, getting a 1 each time, and then
                        \ getting a 1 on the 8th iteration... and we can also
                        \ use P to catch our result bits into bit 0 each time

.LIL4

 ASL A                  \ Shift A to the left

 BCS LI13               \ If bit 7 of A was set, then jump straight to the
                        \ subtraction

 CMP Q                  \ If A < Q, skip the following subtraction
 BCC LI14

.LI13

 SBC Q                  \ A >= Q, so set A = A - Q

 SEC                    \ Set the C flag to rotate into the result in Q

.LI14

 ROL P                  \ Rotate the counter in P to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCC LIL4               \ If we still have set bits in P, loop back to TIL2 to
                        \ do the next iteration of 7

                        \ We now have:
                        \
                        \   P = A / Q
                        \     = |delta_x| / |delta_y|
                        \
                        \ and the C flag is set

 LDX Q                  \ Set X = Q + 1
 INX                    \       = |delta_y| + 1
                        \
                        \ We add 1 so we can skip the first pixel plot if the
                        \ line is being drawn with swapped coordinates

 LDA X2                 \ Set A = X2 - X1 (the C flag is set as we didn't take
 SBC X1                 \ the above BCC)

 BCC LFT                \ If X2 < X1 then jump to LFT, as we need to draw the
                        \ line to the left and down

\ ******************************************************************************
\
\       Name: LOIN (Part 6 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a steep line going up and left or down and right
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going up and left (no swap) or down and right (swap)
\
\   * X1 < X2 and Y1 >= Y2
\
\   * Draw from (X1, Y1) at top left to (X2, Y2) at bottom right
\
\ ******************************************************************************

 CLC                    \ Clear the C flag

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI17               \ so jump down to LI17 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL5

                        \ We now loop along the line from left to right, using X
                        \ as a decreasing counter, and at each count we plot a
                        \ single pixel using the pixel mask in R

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI17

 DEY                    \ Decrement Y to step up along the y-axis

 BPL LI16               \ If Y is positive we are still within the same
                        \ character block, so skip to LI16

 DEC SCH                \ Otherwise we need to move up into the character block
 LDY #7                 \ above, so decrement the high byte of the screen
                        \ address and set the pixel line to the last line in
                        \ that character block

.LI16

 LDA S                  \ Set S = S + Q to update the slope error
 ADC P
 STA S

 BCC LIC5               \ If the addition didn't overflow, jump to LIC5

 LSR R                  \ Otherwise we just overflowed, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LIC5               \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LIC5

 ROR R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R right so the set C flag goes
                        \ back into the left end, giving %10000000

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

.LIC5

 DEX                    \ Decrement the counter in X

 BNE LIL5               \ If we haven't yet reached the right end of the line,
                        \ loop back to LIL5 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 7 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a steep line going up and right or down and left
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going up and right (no swap) or down and left (swap)
\
\   * X1 >= X2 and Y1 >= Y2
\
\   * Draw from (X1, Y1) at bottom left to (X2, Y2) at top right
\
\ Other entry points:
\
\   HL6                 Contains an RTS
\
\ ******************************************************************************

.LFT

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI18               \ jump down to LI18 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL6

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI18

 DEY                    \ Decrement Y to step up along the y-axis

 BPL LI19               \ If Y is positive we are still within the same
                        \ character block, so skip to LI19

 DEC SCH                \ Otherwise we need to move up into the character block
 LDY #7                 \ above, so decrement the high byte of the screen
                        \ address and set the pixel line to the last line in
                        \ that character block

.LI19

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCC LIC6               \ If the addition didn't overflow, jump to LIC6

 ASL R                  \ Otherwise we just overflowed, so shift the single
                        \ pixel in R to the left, so the next pixel we plot
                        \ will be at the previous x-coordinate

 BCC LIC6               \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LIC6

 ROL R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R left so the set C flag goes
                        \ back into the right end, giving %0000001

 LDA SC                 \ Subtract 7 from SC, so SC(1 0) now points to the
 SBC #7                 \ previous character along to the left
 STA SC

 CLC                    \ Clear the C flag so it doesn't affect the additions
                        \ below

.LIC6

 DEX                    \ Decrement the counter in X

 BNE LIL6               \ If we haven't yet reached the left end of the line,
                        \ loop back to LIL6 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

.HL6

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: NLIN3
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Print a title and a horizontal line at row 19 to box it in
\
\ ------------------------------------------------------------------------------
\
\ This routine print a text token at the cursor position and draws a horizontal
\ line at pixel row 19. It is used for the Status Mode screen, the Short-range
\ Chart, the Market Price screen and the Equip Ship screen.
\
\ ******************************************************************************

.NLIN3

 JSR TT27               \ Print the text token in A

                        \ Fall through into NLIN4 to draw a horizontal line at
                        \ pixel row 19

\ ******************************************************************************
\
\       Name: NLIN4
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line at pixel row 19 to box in a title
\
\ ------------------------------------------------------------------------------
\
\ This routine is used on the Inventory screen to draw a horizontal line at
\ pixel row 19 to box in the title.
\
\ ******************************************************************************

.NLIN4

 LDA #19                \ Jump to NLIN2 to draw a horizontal line at pixel row
 BNE NLIN2              \ 19, returning from the subroutine with using a tail
                        \ call (this BNE is effectively a JMP as A will never
                        \ be zero)

\ ******************************************************************************
\
\       Name: NLIN
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line at pixel row 23 to box in a title
\
\ ------------------------------------------------------------------------------
\
\ Draw a horizontal line at pixel row 23 and move the text cursor down one
\ line.
\
\ ******************************************************************************

.NLIN

 LDA #23                \ Set A = 23 so NLIN2 below draws a horizontal line at
                        \ pixel row 23

 INC YC                 \ Move the text cursor down one line

                        \ Fall through into NLIN2 to draw the horizontal line
                        \ at row 23

\ ******************************************************************************
\
\       Name: NLIN2
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a screen-wide horizontal line at the pixel row in A
\
\ ------------------------------------------------------------------------------
\
\ This draws a line from (2, A) to (254, A), which is almost screen-wide and
\ fits in nicely between the white borders without clashing with it.
\
\ Arguments:
\
\   A                   The pixel row on which to draw the horizontal line
\
\ ******************************************************************************

.NLIN2

 STA Y1                 \ Set Y1 = A

 LDX #2                 \ Set X1 = 2, so (X1, Y1) = (2, A)
 STX X1

 LDX #254               \ Set X2 = 254, so (X2, Y2) = (254, A)
 STX X2

 BNE HLOIN              \ Call HLOIN to draw a horizontal line from (2, A) to
                        \ (254, A) and return from the subroutine (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: HLOIN2
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Remove a line from the sun line heap and draw it on-screen
\
\ ------------------------------------------------------------------------------
\
\ Specifically, this does the following:
\
\   * Set X1 and X2 to the x-coordinates of the ends of the horizontal line with
\     centre YY(1 0) and length A to the left and right
\
\   * Set the Y-th byte of the LSO block to 0 (i.e. remove this line from the
\     sun line heap)
\
\   * Draw a horizontal line from (X1, Y) to (X2, Y)
\
\ Arguments:
\
\   YY(1 0)             The x-coordinate of the centre point of the line
\
\   A                   The half-width of the line, i.e. the contents of the
\                       Y-th byte of the sun line heap
\
\   Y                   The number of the entry in the sun line heap (which is
\                       also the y-coordinate of the line)
\
\ Returns:
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.HLOIN2

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A

 STY Y1                 \ Set Y1 = Y

 LDA #0                 \ Set the Y-th byte of the LSO block to 0
 STA LSO,Y

                        \ Fall through into HLOIN to draw a horizontal line from
                        \ (X1, Y) to (X2, Y)

\ ******************************************************************************
\
\       Name: HLOIN
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line from (X1, Y1) to (X2, Y1)
\
\ ------------------------------------------------------------------------------
\
\ We do not draw a pixel at the end point (X2, X1).
\
\ To understand how this routine works, you might find it helpful to read the
\ deep dive on "Drawing monochrome pixels in mode 4".
\
\ Returns:
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.HLOIN

 STY YSAV               \ Store Y into YSAV, so we can preserve it across the
                        \ call to this subroutine

 LDX X1                 \ Set X = X1

 CPX X2                 \ If X1 = X2 then the start and end points are the same,
 BEQ HL6                \ so return from the subroutine (as HL6 contains an RTS)

 BCC HL5                \ If X1 < X2, jump to HL5 to skip the following code, as
                        \ (X1, Y1) is already the left point

 LDA X2                 \ Swap the values of X1 and X2, so we know that (X1, Y1)
 STA X1                 \ is on the left and (X2, Y1) is on the right
 STX X2

 TAX                    \ Set X = X1

.HL5

 DEC X2                 \ Decrement X2 so we do not draw a pixel at the end
                        \ point

 LDA Y1                 \ Set A = Y1 / 8, so A now contains the character row
 LSR A                  \ that will contain our horizontal line
 LSR A
 LSR A

 ORA #&60               \ As A < 32, this effectively adds &60 to A, which gives
                        \ us the screen address of the character row (as each
                        \ character row takes up 256 bytes, and the first
                        \ character row is at screen address &6000, or page &60)

 STA SCH                \ Store the page number of the character row in SCH, so
                        \ the high byte of SC is set correctly for drawing our
                        \ line

 LDA Y1                 \ Set A = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw our line (as
                        \ each character block has 8 rows)

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw our
                        \ horizontal line on

 TXA                    \ Set Y = bits 3-7 of X1
 AND #%11111000
 TAY

.HL1

 TXA                    \ Set T = bits 3-7 of X1, which will contain the
 AND #%11111000         \ the character number of the start of the line * 8
 STA T

 LDA X2                 \ Set A = bits 3-7 of X2, which will contain the
 AND #%11111000         \ the character number of the end of the line * 8

 SEC                    \ Set A = A - T, which will contain the number of
 SBC T                  \ character blocks we need to fill - 1 * 8

 BEQ HL2                \ If A = 0 then the start and end character blocks are
                        \ the same, so the whole line fits within one block, so
                        \ jump down to HL2 to draw the line

                        \ Otherwise the line spans multiple characters, so we
                        \ start with the left character, then do any characters
                        \ in the middle, and finish with the right character

 LSR A                  \ Set R = A / 8, so R now contains the number of
 LSR A                  \ character blocks we need to fill - 1
 LSR A
 STA R

 LDA X1                 \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWFR,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ right end of the byte (so the filled pixels start at
                        \ point X and go all the way to the end of the byte),
                        \ which is the shape we want for the left end of the
                        \ line

 EOR (SC),Y             \ Store this into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen,
                        \ so we have now drawn the line's left cap

 TYA                    \ Set Y = Y + 8 so (SC),Y points to the next character
 ADC #8                 \ block along, on the same pixel row as before
 TAY

 LDX R                  \ Fetch the number of character blocks we need to fill
                        \ from R

 DEX                    \ Decrement the number of character blocks in X

 BEQ HL3                \ If X = 0 then we only have the last block to do (i.e.
                        \ the right cap), so jump down to HL3 to draw it

 CLC                    \ Otherwise clear the C flag so we can do some additions
                        \ while we draw the character blocks with full-width
                        \ lines in them

.HLL1

 LDA #%11111111         \ Store a full-width 8-pixel horizontal line in SC(1 0)
 EOR (SC),Y             \ so that it draws the line on-screen, using EOR logic
 STA (SC),Y             \ so it merges with whatever is already on-screen

 TYA                    \ Set Y = Y + 8 so (SC),Y points to the next character
 ADC #8                 \ block along, on the same pixel row as before
 TAY

 DEX                    \ Decrement the number of character blocks in X

 BNE HLL1               \ Loop back to draw more full-width lines, if we have
                        \ any more to draw

.HL3

 LDA X2                 \ Now to draw the last character block at the right end
 AND #7                 \ of the line, so set X = X2 mod 8, which is the
 TAX                    \ horizontal pixel number where the line ends

 LDA TWFL,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ left end of the byte (so the filled pixels start at
                        \ the left edge and go up to point X), which is the
                        \ shape we want for the right end of the line

 EOR (SC),Y             \ Store this into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen,
                        \ so we have now drawn the line's right cap

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved across the
                        \ call to this subroutine

 RTS                    \ Return from the subroutine

.HL2

                        \ If we get here then the entire horizontal line fits
                        \ into one character block

 LDA X1                 \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWFR,X             \ Fetch a ready-made byte with X pixels filled in at the
 STA T                  \ right end of the byte (so the filled pixels start at
                        \ point X and go all the way to the end of the byte)

 LDA X2                 \ Set X = X2 mod 8, which is the horizontal pixel number
 AND #7                 \ where the line ends
 TAX

 LDA TWFL,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ left end of the byte (so the filled pixels start at
                        \ the left edge and go up to point X)

 AND T                  \ We now have two bytes, one (T) containing pixels from
                        \ the starting point X1 onwards, and the other (A)
                        \ containing pixels up to the end point at X2, so we can
                        \ get the actual line we want to draw by AND'ing them
                        \ together. For example, if we want to draw a line from
                        \ point 2 to point 5 (within the row of 8 pixels
                        \ numbered from 0 to 7), we would have this:
                        \
                        \   T       = %00111111
                        \   A       = %11111100
                        \   T AND A = %00111100
                        \
                        \ so if we stick T AND A in screen memory, that's what
                        \ we do here, setting A = A AND T

 EOR (SC),Y             \ Store our horizontal line byte into screen memory at
 STA (SC),Y             \ SC(1 0), using EOR logic so it merges with whatever is
                        \ already on-screen

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TWFL
\       Type: Variable
\   Category: Drawing lines
\    Summary: Ready-made character rows for the left end of a horizontal line in
\             mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting horizontal line end caps in mode 4 (the top part
\ of the split screen). This table provides a byte with pixels at the left end,
\ which is used for the right end of the line.
\
\ See the HLOIN routine for details.
\
\ ******************************************************************************

.TWFL

 EQUB %10000000
 EQUB %11000000
 EQUB %11100000
 EQUB %11110000
 EQUB %11111000
 EQUB %11111100
 EQUB %11111110

\ ******************************************************************************
\
\       Name: TWFR
\       Type: Variable
\   Category: Drawing lines
\    Summary: Ready-made character rows for the right end of a horizontal line
\             in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting horizontal line end caps in mode 4 (the top part
\ of the split screen). This table provides a byte with pixels at the right end,
\ which is used for the left end of the line.
\
\ See the HLOIN routine for details.
\
\ ******************************************************************************

.TWFR

 EQUB %11111111
 EQUB %01111111
 EQUB %00111111
 EQUB %00011111
 EQUB %00001111
 EQUB %00000111
 EQUB %00000011
 EQUB %00000001

\ ******************************************************************************
\
\       Name: PX3
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Plot a single pixel at (X, Y) within a character block
\
\ ------------------------------------------------------------------------------
\
\ This routine is called from PIXEL to set 1 pixel within a character block for
\ a distant point (i.e. where the distance ZZ >= &90). See the PIXEL routine for
\ details, as this routine is effectively part of PIXEL.
\
\ Arguments:
\
\   X                   The x-coordinate of the pixel within the character block
\
\   Y                   The y-coordinate of the pixel within the character block
\
\   SC(1 0)             The screen address of the character block
\
\   T1                  The value of Y to restore on exit, so Y is preserved by
\                       the call to PIXEL
\
\ ******************************************************************************

.PX3

 LDA TWOS,X             \ Fetch a 1-pixel byte from TWOS and EOR it into SC+Y
 EOR (SC),Y
 STA (SC),Y

 LDY T1                 \ Restore Y from T1, so Y is preserved by the routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PIX1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (YY+1 SYL+Y) = (A P) + (S R) and draw stardust particle
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   (YY+1 SYL+Y) = (A P) + (S R)
\
\ and draw a stardust particle at (X1,Y1) with distance ZZ.
\
\ Arguments:
\
\   (A P)               A is the angle ALPHA or BETA, P is always 0
\
\   (S R)               YY(1 0) or YY(1 0) + Q * A
\
\   Y                   Stardust particle number
\
\   X1                  The x-coordinate offset
\
\   Y1                  The y-coordinate offset
\
\   ZZ                  The distance of the point (further away = smaller point)
\
\ ******************************************************************************

.PIX1

 JSR ADD                \ Set (A X) = (A P) + (S R)

 STA YY+1               \ Set YY+1 to A, the high byte of the result

 TXA                    \ Set SYL+Y to X, the low byte of the result
 STA SYL,Y

                        \ Fall through into PIX1 to draw the stardust particle
                        \ at (X1,Y1)

\ ******************************************************************************
\
\       Name: PIXEL2
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a stardust particle relative to the screen centre
\
\ ------------------------------------------------------------------------------
\
\ Draw a point (X1, Y1) from the middle of the screen with a size determined by
\ a distance value. Used to draw stardust particles.
\
\ Arguments:
\
\   X1                  The x-coordinate offset
\
\   Y1                  The y-coordinate offset (positive means up the screen
\                       from the centre, negative means down the screen)
\
\   ZZ                  The distance of the point (further away = smaller point)
\
\ ******************************************************************************

.PIXEL2

 LDA X1                 \ Fetch the x-coordinate offset into A

 BPL PX1                \ If the x-coordinate offset is positive, jump to PX1
                        \ to skip the following negation

 EOR #%01111111         \ The x-coordinate offset is negative, so flip all the
 CLC                    \ bits apart from the sign bit and add 1, to negate
 ADC #1                 \ it to a positive number, i.e. A is now |X1|

.PX1

 EOR #%10000000         \ Set X = -|A|
 TAX                    \       = -|X1|

 LDA Y1                 \ Fetch the y-coordinate offset into A and clear the
 AND #%01111111         \ sign bit, so A = |Y1|

 CMP #96                \ If |Y1| >= 96 then it's off the screen (as 96 is half
 BCS PX4                \ the screen height), so return from the subroutine (as
                        \ PX4 contains an RTS)

 LDA Y1                 \ Fetch the y-coordinate offset into A

 BPL PX2                \ If the y-coordinate offset is positive, jump to PX2
                        \ to skip the following negation

 EOR #%01111111         \ The y-coordinate offset is negative, so flip all the
 ADC #1                 \ bits apart from the sign bit and subtract 1, to negate
                        \ it to a positive number, i.e. A is now |Y1|

.PX2

 STA T                  \ Set A = 97 - A
 LDA #97                \       = 97 - |Y1|
 SBC T                  \
                        \ so if Y is positive we display the point up from the
                        \ centre, while a negative Y means down from the centre

                        \ Fall through into PIXEL to draw the stardust at the
                        \ screen coordinates in (X, A)

\ ******************************************************************************
\
\       Name: PIXEL
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a 1-pixel dot, 2-pixel dash or 4-pixel square
\  Deep dive: Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Draw a point at screen coordinate (X, A) with the point size determined by the
\ distance in ZZ. This applies to the top part of the screen (the monochrome
\ mode 4 portion).
\
\ Arguments:
\
\   X                   The screen x-coordinate of the point to draw
\
\   A                   The screen y-coordinate of the point to draw
\
\   ZZ                  The distance of the point (further away = smaller point)
\
\ Returns:
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   PX4                 Contains an RTS
\
\ ******************************************************************************

.PIXEL

 STY T1                 \ Store Y in T1

 TAY                    \ Copy A into Y, for use later

 LSR A                  \ Set SCH = &60 + A >> 3
 LSR A
 LSR A
 ORA #&60
 STA SCH

 TXA                    \ Set SC = (X >> 3) * 8
 AND #%11111000
 STA SC

 TYA                    \ Set Y = Y AND %111
 AND #%00000111
 TAY

 TXA                    \ Set X = X AND %111
 AND #%00000111
 TAX

 LDA ZZ                 \ If distance in ZZ >= 144, then this point is a very
 CMP #144               \ long way away, so jump to PX3 to fetch a 1-pixel point
 BCS PX3                \ from TWOS and EOR it into SC+Y

 LDA TWOS2,X            \ Otherwise fetch a 2-pixel dash from TWOS2 and EOR it
 EOR (SC),Y             \ into SC+Y
 STA (SC),Y

 LDA ZZ                 \ If distance in ZZ >= 80, then this point is a medium
 CMP #80                \ distance away, so jump to PX13 to stop drawing, as a
 BCS PX13               \ 2-pixel dash is enough

                        \ Otherwise we keep going to draw another 2 pixel point
                        \ either above or below the one we just drew, to make a
                        \ 4-pixel square

 DEY                    \ Reduce Y by 1 to point to the pixel row above the one
 BPL PX14               \ we just plotted, and if it is still positive, jump to
                        \ PX14 to draw our second 2-pixel dash

 LDY #1                 \ Reducing Y by 1 made it negative, which means Y was
                        \ 0 before we did the DEY above, so set Y to 1 to point
                        \ to the pixel row after the one we just plotted

.PX14

 LDA TWOS2,X            \ Fetch a 2-pixel dash from TWOS2 and EOR it into this
 EOR (SC),Y             \ second row to make a 4-pixel square
 STA (SC),Y

.PX13

 LDY T1                 \ Restore Y from T1, so Y is preserved by the routine

.PX4

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: BLINE
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle segment and add it to the ball line heap
\  Deep dive: The ball line heap
\             Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a single segment of a circle, adding the point to the ball line heap.
\
\ Arguments:
\
\   CNT                 The number of this segment
\
\   STP                 The step size for the circle
\
\   K6(1 0)             The x-coordinate of the new point on the circle, as
\                       a screen coordinate
\
\   (T X)               The y-coordinate of the new point on the circle, as
\                       an offset from the centre of the circle
\
\   FLAG                Set to &FF for the first call, so it sets up the first
\                       point in the heap but waits until the second call before
\                       drawing anything (as we need two points, i.e. two calls,
\                       before we can draw a line)
\
\   K                   The circle's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the circle
\
\   K4(1 0)             Pixel y-coordinate of the centre of the circle
\
\   SWAP                If non-zero, we swap (X1, Y1) and (X2, Y2)
\
\ Returns:
\
\   CNT                 CNT is updated to CNT + STP
\
\   A                   The new value of CNT
\
\   FLAG                Set to 0
\
\ ******************************************************************************

.BLINE

 TXA                    \ Set K6(3 2) = (T X) + K4(1 0)
 ADC K4                 \             = y-coord of centre + y-coord of new point
 STA K6+2               \
 LDA K4+1               \ so K6(3 2) now contains the y-coordinate of the new
 ADC T                  \ point on the circle but as a screen coordinate, to go
 STA K6+3               \ along with the screen y-coordinate in K6(1 0)

 LDA FLAG               \ If FLAG = 0, jump down to BL1
 BEQ BL1

 INC FLAG               \ Flag is &FF so this is the first call to BLINE, so
                        \ increment FLAG to set it to 0, as then the next time
                        \ we call BLINE it can draw the first line, from this
                        \ point to the next

.BL5

                        \ The following inserts a &FF marker into the LSY2 line
                        \ heap to indicate that the next call to BLINE should
                        \ store both the (X1, Y1) and (X2, Y2) points. We do
                        \ this on the very first call to BLINE (when FLAG is
                        \ &FF), and on subsequent calls if the segment does not
                        \ fit on-screen, in which case we don't draw or store
                        \ that segment, and we start a new segment with the next
                        \ call to BLINE that does fit on-screen

 LDY LSP                \ If byte LSP-1 of LSY2 = &FF, jump to BL7 to tidy up
 LDA #&FF               \ and return from the subroutine, as the point that has
 CMP LSY2-1,Y           \ been passed to BLINE is the start of a segment, so all
 BEQ BL7                \ we need to do is save the coordinate in K5, without
                        \ moving the pointer in LSP

 STA LSY2,Y             \ Otherwise we just tried to plot a segment but it
                        \ didn't fit on-screen, so put the &FF marker into the
                        \ heap for this point, so the next call to BLINE starts
                        \ a new segment

 INC LSP                \ Increment LSP to point to the next point in the heap

 BNE BL7                \ Jump to BL7 to tidy up and return from the subroutine
                        \ (this BNE is effectively a JMP, as LSP will never be
                        \ zero)

.BL1

 LDA K5                 \ Set XX15 = K5 = x_lo of previous point
 STA XX15

 LDA K5+1               \ Set XX15+1 = K5+1 = x_hi of previous point
 STA XX15+1

 LDA K5+2               \ Set XX15+2 = K5+2 = y_lo of previous point
 STA XX15+2

 LDA K5+3               \ Set XX15+3 = K5+3 = y_hi of previous point
 STA XX15+3

 LDA K6                 \ Set XX15+4 = x_lo of new point
 STA XX15+4

 LDA K6+1               \ Set XX15+5 = x_hi of new point
 STA XX15+5

 LDA K6+2               \ Set XX12 = y_lo of new point
 STA XX12

 LDA K6+3               \ Set XX12+1 = y_hi of new point
 STA XX12+1

 JSR LL145              \ Call LL145 to see if the new line segment needs to be
                        \ clipped to fit on-screen, returning the clipped line's
                        \ end-points in (X1, Y1) and (X2, Y2)

 BCS BL5                \ If the C flag is set then the line is not visible on
                        \ screen anyway, so jump to BL5, to avoid drawing and
                        \ storing this line

 LDA SWAP               \ If SWAP = 0, then we didn't have to swap the line
 BEQ BL9                \ coordinates around during the clipping process, so
                        \ jump to BL9 to skip the following swap

 LDA X1                 \ Otherwise the coordinates were swapped by the call to
 LDY X2                 \ LL145 above, so we swap (X1, Y1) and (X2, Y2) back
 STA X2                 \ again
 STY X1
 LDA Y1
 LDY Y2
 STA Y2
 STY Y1

.BL9

 LDY LSP                \ Set Y = LSP

 LDA LSY2-1,Y           \ If byte LSP-1 of LSY2 is not &FF, jump down to BL8
 CMP #&FF               \ to skip the following (X1, Y1) code
 BNE BL8

                        \ Byte LSP-1 of LSY2 is &FF, which indicates that we
                        \ need to store (X1, Y1) in the heap

 LDA X1                 \ Store X1 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y1                 \ Store Y1 in the LSP-th byte of LSY2
 STA LSY2,Y

 INY                    \ Increment Y to point to the next byte in LSX2/LSY2

.BL8

 LDA X2                 \ Store X2 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y2                 \ Store Y2 in the LSP-th byte of LSX2
 STA LSY2,Y

 INY                    \ Increment Y to point to the next byte in LSX2/LSY2

 STY LSP                \ Update LSP to point to the same as Y

 JSR LOIN               \ Draw a line from (X1, Y1) to (X2, Y2)

 LDA XX13               \ If XX13 is non-zero, jump up to BL5 to add a &FF
 BNE BL5                \ marker to the end of the line heap. XX13 is non-zero
                        \ after the call to the clipping routine LL145 above if
                        \ the end of the line was clipped, meaning the next line
                        \ sent to BLINE can't join onto the end but has to start
                        \ a new segment, and that's what inserting the &FF
                        \ marker does

.BL7

 LDA K6                 \ Copy the data for this step point from K6(3 2 1 0)
 STA K5                 \ into K5(3 2 1 0), for use in the next call to BLINE:
 LDA K6+1               \
 STA K5+1               \   * K5(1 0) = screen x-coordinate of this point
 LDA K6+2               \
 STA K5+2               \   * K5(3 2) = screen y-coordinate of this point
 LDA K6+3               \
 STA K5+3               \ They now become the "previous point" in the next call

 LDA CNT                \ Set CNT = CNT + STP
 CLC
 ADC STP
 STA CNT

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FLIP
\       Type: Subroutine
\   Category: Stardust
\    Summary: Reflect the stardust particles in the screen diagonal
\
\ ------------------------------------------------------------------------------
\
\ Swap the x- and y-coordinates of all the stardust particles and draw the new
\ set of particles. Called by LOOK1 when we switch views.
\
\ This is a quick way of making the stardust field in the new view feel
\ different without having to generate a whole new field. If you look carefully
\ at the stardust field when you switch views, you can just about see that the
\ new field is a reflection of the previous field in the screen diagonal, i.e.
\ in the line from bottom left to top right. This is the line where x = y when
\ the origin is in the middle of the screen, and positive x and y are right and
\ up, which is the coordinate system we use for stardust).
\
\ ******************************************************************************

.FLIP

\LDA MJ                 \ These instructions are commented out in the original
\BNE FLIP-1             \ source. They would have the effect of not swapping the
                        \ stardust if we had mis-jumped into witchspace

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

.FLL1

 LDX SY,Y               \ Copy the Y-th particle's y-coordinate from SY+Y into X

 LDA SX,Y               \ Copy the Y-th particle's x-coordinate from SX+Y into
 STA Y1                 \ both Y1 and the particle's y-coordinate
 STA SY,Y

 TXA                    \ Copy the Y-th particle's original y-coordinate into
 STA X1                 \ both X1 and the particle's x-coordinate, so the x- and
 STA SX,Y               \ y-coordinates are now swapped and (X1, Y1) contains
                        \ the particle's new coordinates

 LDA SZ,Y               \ Fetch the Y-th particle's distance from SZ+Y into ZZ
 STA ZZ

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ

 DEY                    \ Decrement the counter to point to the next particle of
                        \ stardust

 BNE FLL1               \ Loop back to FLL1 until we have moved all the stardust
                        \ particles

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: STARS
\       Type: Subroutine
\   Category: Stardust
\    Summary: The main routine for processing the stardust
\
\ ------------------------------------------------------------------------------
\
\ Called at the very end of the main flight loop.
\
\ ******************************************************************************

.STARS

\LDA #&FF               \ These instructions are commented out in the original
\STA COL                \ source, but they would set the stardust colour to
                        \ white. That said, COL is only used when updating the
                        \ dashboard, so this would have no effect - perhaps it's
                        \ left over from experiments with a colour top part of
                        \ the screen? Who knows...

 LDX VIEW               \ Load the current view into X:
                        \
                        \   0 = front
                        \   1 = rear
                        \   2 = left
                        \   3 = right

 BEQ STARS1             \ If this 0, jump to STARS1 to process the stardust for
                        \ the front view

 DEX                    \ If this is view 2 or 3, jump to STARS2 (via ST11) to
 BNE ST11               \ process the stardust for the left or right views

 JMP STARS6             \ Otherwise this is the rear view, so jump to STARS6 to
                        \ process the stardust for the rear view

.ST11

 JMP STARS2             \ Jump to STARS2 for the left or right views, as it's
                        \ too far for the branch instruction above

\ ******************************************************************************
\
\       Name: STARS1
\       Type: Subroutine
\   Category: Stardust
\    Summary: Process the stardust for the front view
\  Deep dive: Stardust in the front view
\
\ ------------------------------------------------------------------------------
\
\ This moves the stardust towards us according to our speed (so the dust rushes
\ past us), and applies our current pitch and roll to each particle of dust, so
\ the stardust moves correctly when we steer our ship.
\
\ When a stardust particle rushes past us and falls off the side of the screen,
\ its memory is recycled as a new particle that's positioned randomly on-screen.
\
\ ******************************************************************************

.STARS1

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

                        \ In the following, we're going to refer to the 16-bit
                        \ space coordinates of the current particle of stardust
                        \ (i.e. the Y-th particle) like this:
                        \
                        \   x = (x_hi x_lo)
                        \   y = (y_hi y_lo)
                        \   z = (z_hi z_lo)
                        \
                        \ These values are stored in (SX+Y SXL+Y), (SY+Y SYL+Y)
                        \ and (SZ+Y SZL+Y) respectively

.STL1

 JSR DV42               \ Call DV42 to set the following:
                        \
                        \   (P R) = 256 * DELTA / z_hi
                        \         = 256 * speed / z_hi
                        \
                        \ The maximum value returned is P = 2 and R = 128 (see
                        \ DV42 for an explanation)

 LDA R                  \ Set A = R, so now:
                        \
                        \   (P A) = 256 * speed / z_hi

 LSR P                  \ Rotate (P A) right by 2 places, which sets P = 0 (as P
 ROR A                  \ has a maximum value of 2) and leaves:
 LSR P                  \
 ROR A                  \   A = 64 * speed / z_hi

 ORA #1                 \ Make sure A is at least 1, and store it in Q, so we
 STA Q                  \ now have result 1 above:
                        \
                        \   Q = 64 * speed / z_hi

 LDA SZL,Y              \ We now calculate the following:
 SBC DELT4              \
 STA SZL,Y              \  (z_hi z_lo) = (z_hi z_lo) - DELT4(1 0)
                        \
                        \ starting with the low bytes

 LDA SZ,Y               \ And then we do the high bytes
 STA ZZ                 \
 SBC DELT4+1            \ We also set ZZ to the original value of z_hi, which we
 STA SZ,Y               \ use below to remove the existing particle
                        \
                        \ So now we have result 2 above:
                        \
                        \   z = z - DELT4(1 0)
                        \     = z - speed * 64

 JSR MLU1               \ Call MLU1 to set:
                        \
                        \   Y1 = y_hi
                        \
                        \   (A P) = |y_hi| * Q
                        \
                        \ So Y1 contains the original value of y_hi, which we
                        \ use below to remove the existing particle

                        \ We now calculate:
                        \
                        \   (S R) = YY(1 0) = (A P) + y

 STA YY+1               \ First we do the low bytes with:
 LDA P                  \
 ADC SYL,Y              \   YY+1 = A
 STA YY                 \   R = YY = P + y_lo
 STA R                  \
                        \ so we get this:
                        \
                        \   (? R) = YY(1 0) = (A P) + y_lo

 LDA Y1                 \ And then we do the high bytes with:
 ADC YY+1               \
 STA YY+1               \   S = YY+1 = y_hi + YY+1
 STA S                  \
                        \ so we get our result:
                        \
                        \   (S R) = YY(1 0) = (A P) + (y_hi y_lo)
                        \                   = |y_hi| * Q + y
                        \
                        \ which is result 3 above, and (S R) is set to the new
                        \ value of y

 LDA SX,Y               \ Set X1 = A = x_hi
 STA X1                 \
                        \ So X1 contains the original value of x_hi, which we
                        \ use below to remove the existing particle

 JSR MLU2               \ Set (A P) = |x_hi| * Q

                        \ We now calculate:
                        \
                        \   XX(1 0) = (A P) + x

 STA XX+1               \ First we do the low bytes:
 LDA P                  \
 ADC SXL,Y              \   XX(1 0) = (A P) + x_lo
 STA XX

 LDA X1                 \ And then we do the high bytes:
 ADC XX+1               \
 STA XX+1               \   XX(1 0) = XX(1 0) + (x_hi 0)
                        \
                        \ so we get our result:
                        \
                        \   XX(1 0) = (A P) + x
                        \           = |x_hi| * Q + x
                        \
                        \ which is result 4 above, and we also have:
                        \
                        \   A = XX+1 = (|x_hi| * Q + x) / 256
                        \
                        \ i.e. A is the new value of x, divided by 256

 EOR ALP2+1             \ EOR with the flipped sign of the roll angle alpha, so
                        \ A has the opposite sign to the flipped roll angle
                        \ alpha, i.e. it gets the same sign as alpha

 JSR MLS1               \ Call MLS1 to calculate:
                        \
                        \   (A P) = A * ALP1
                        \         = (x / 256) * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = (x / 256) * alpha + y
                        \         = y + alpha * x / 256

 STA YY+1               \ Set YY(1 0) = (A X) to give:
 STX YY                 \
                        \   YY(1 0) = y + alpha * x / 256
                        \
                        \ which is result 5 above, and we also have:
                        \
                        \   A = YY+1 = y + alpha * x / 256
                        \
                        \ i.e. A is the new value of y, divided by 256

 EOR ALP2               \ EOR A with the correct sign of the roll angle alpha,
                        \ so A has the opposite sign to the roll angle alpha

 JSR MLS2               \ Call MLS2 to calculate:
                        \
                        \   (S R) = XX(1 0)
                        \         = x
                        \
                        \   (A P) = A * ALP1
                        \         = -y / 256 * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = -y / 256 * alpha + x

 STA XX+1               \ Set XX(1 0) = (A X), which gives us result 6 above:
 STX XX                 \
                        \   x = x - alpha * y / 256

 LDX BET1               \ Fetch the pitch magnitude into X

 LDA YY+1               \ Set A to y_hi and set it to the flipped sign of beta
 EOR BET2+1

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = -beta * y_hi

 STA Q                  \ Store the high byte of the result in Q, so:
                        \
                        \   Q = -beta * y_hi / 256

 JSR MUT2               \ Call MUT2 to calculate:
                        \
                        \   (S R) = XX(1 0) = x
                        \
                        \   (A P) = Q * A
                        \         = (-beta * y_hi / 256) * (-beta * y_hi / 256)
                        \         = (beta * y / 256) ^ 2

 ASL P                  \ Double (A P), store the top byte in A and set the C
 ROL A                  \ flag to bit 7 of the original A, so this does:
 STA T                  \
                        \   (T P) = (A P) << 1
                        \         = 2 * (beta * y / 256) ^ 2

 LDA #0                 \ Set bit 7 in A to the sign bit from the A in the
 ROR A                  \ calculation above and apply it to T, so we now have:
 ORA T                  \
                        \   (A P) = (A P) * 2
                        \         = 2 * (beta * y / 256) ^ 2
                        \
                        \ with the doubling retaining the sign of (A P)

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = 2 * (beta * y / 256) ^ 2 + x

 STA XX+1               \ Store the high byte A in XX+1

 TXA
 STA SXL,Y              \ Store the low byte X in x_lo

                        \ So (XX+1 x_lo) now contains:
                        \
                        \   x = x + 2 * (beta * y / 256) ^ 2
                        \
                        \ which is result 7 above

 LDA YY                 \ Set (S R) = YY(1 0) = y
 STA R
 LDA YY+1
\JSR MAD                \ These instructions are commented out in the original
\STA S                  \ source
\STX R
 STA S

 LDA #0                 \ Set P = 0
 STA P

 LDA BETA               \ Set A = -beta, so:
 EOR #%10000000         \
                        \   (A P) = (-beta 0)
                        \         = -beta * 256

 JSR PIX1               \ Call PIX1 to calculate the following:
                        \
                        \   (YY+1 y_lo) = (A P) + (S R)
                        \               = -beta * 256 + y
                        \
                        \ i.e. y = y - beta * 256, which is result 8 above
                        \
                        \ PIX1 also draws a particle at (X1, Y1) with distance
                        \ ZZ, which will remove the old stardust particle, as we
                        \ set X1, Y1 and ZZ to the original values for this
                        \ particle during the calculations above

                        \ We now have our newly moved stardust particle at
                        \ x-coordinate (XX+1 x_lo) and y-coordinate (YY+1 y_lo)
                        \ and distance z_hi, so we draw it if it's still on
                        \ screen, otherwise we recycle it as a new bit of
                        \ stardust and draw that

 LDA XX+1               \ Set X1 and x_hi to the high byte of XX in XX+1, so
 STA X1                 \ the new x-coordinate is in (x_hi x_lo) and the high
 STA SX,Y               \ byte is in X1

 AND #%01111111         \ If |x_hi| >= 120 then jump to KILL1 to recycle this
 CMP #120               \ particle, as it's gone off the side of the screen,
 BCS KILL1              \ and re-join at STC1 with the new particle

 LDA YY+1               \ Set Y1 and y_hi to the high byte of YY in YY+1, so
 STA SY,Y               \ the new x-coordinate is in (y_hi y_lo) and the high
 STA Y1                 \ byte is in Y1

 AND #%01111111         \ If |y_hi| >= 120 then jump to KILL1 to recycle this
 CMP #120               \ particle, as it's gone off the top or bottom of the
 BCS KILL1              \ screen, and re-join at STC1 with the new particle

 LDA SZ,Y               \ If z_hi < 16 then jump to KILL1 to recycle this
 CMP #16                \ particle, as it's so close that it's effectively gone
 BCC KILL1              \ past us, and re-join at STC1 with the new particle

 STA ZZ                 \ Set ZZ to the z-coordinate in z_hi

.STC1

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ,
                        \ i.e. draw the newly moved particle at (x_hi, y_hi)
                        \ with distance z_hi

 DEY                    \ Decrement the loop counter to point to the next
                        \ stardust particle

 BEQ P%+5               \ If we have just done the last particle, skip the next
                        \ instruction to return from the subroutine

 JMP STL1               \ We have more stardust to process, so jump back up to
                        \ STL1 for the next particle

 RTS                    \ Return from the subroutine

.KILL1

                        \ Our particle of stardust just flew past us, so let's
                        \ recycle that particle, starting it at a random
                        \ position that isn't too close to the centre point

 JSR DORND              \ Set A and X to random numbers

 ORA #4                 \ Make sure A is at least 4 and store it in Y1 and y_hi,
 STA Y1                 \ so the new particle starts at least 4 pixels above or
 STA SY,Y               \ below the centre of the screen

 JSR DORND              \ Set A and X to random numbers

 ORA #8                 \ Make sure A is at least 8 and store it in X1 and x_hi,
 STA X1                 \ so the new particle starts at least 8 pixels either
 STA SX,Y               \ side of the centre of the screen

 JSR DORND              \ Set A and X to random numbers

 ORA #144               \ Make sure A is at least 144 and store it in ZZ and
 STA SZ,Y               \ z_hi so the new particle starts in the far distance
 STA ZZ

 LDA Y1                 \ Set A to the new value of y_hi. This has no effect as
                        \ STC1 starts with a jump to PIXEL2, which starts with a
                        \ LDA instruction

 JMP STC1               \ Jump up to STC1 to draw this new particle

\ ******************************************************************************
\
\       Name: STARS6
\       Type: Subroutine
\   Category: Stardust
\    Summary: Process the stardust for the rear view
\
\ ------------------------------------------------------------------------------
\
\ This routine is very similar to STARS1, which processes stardust for the front
\ view. The main difference is that the direction of travel is reversed, so the
\ signs in the calculations are different, as well as the order of the first
\ batch of calculations.
\
\ When a stardust particle falls away into the far distance, it is removed from
\ the screen and its memory is recycled as a new particle, positioned randomly
\ along one of the four edges of the screen.
\
\ See STARS1 for an explanation of the maths used in this routine. The
\ calculations are as follows:
\
\   1. q = 64 * speed / z_hi
\   2. x = x - |x_hi| * q
\   3. y = y - |y_hi| * q
\   4. z = z + speed * 64
\
\   5. y = y - alpha * x / 256
\   6. x = x + alpha * y / 256
\
\   7. x = x - 2 * (beta * y / 256) ^ 2
\   8. y = y + beta * 256
\
\ ******************************************************************************

.STARS6

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

.STL6

 JSR DV42               \ Call DV42 to set the following:
                        \
                        \   (P R) = 256 * DELTA / z_hi
                        \         = 256 * speed / z_hi
                        \
                        \ The maximum value returned is P = 2 and R = 128 (see
                        \ DV42 for an explanation)

 LDA R                  \ Set A = R, so now:
                        \
                        \   (P A) = 256 * speed / z_hi

 LSR P                  \ Rotate (P A) right by 2 places, which sets P = 0 (as P
 ROR A                  \ has a maximum value of 2) and leaves:
 LSR P                  \
 ROR A                  \   A = 64 * speed / z_hi

 ORA #1                 \ Make sure A is at least 1, and store it in Q, so we
 STA Q                  \ now have result 1 above:
                        \
                        \   Q = 64 * speed / z_hi

 LDA SX,Y               \ Set X1 = A = x_hi
 STA X1                 \
                        \ So X1 contains the original value of x_hi, which we
                        \ use below to remove the existing particle

 JSR MLU2               \ Set (A P) = |x_hi| * Q

                        \ We now calculate:
                        \
                        \   XX(1 0) = x - (A P)

 STA XX+1               \ First we do the low bytes:
 LDA SXL,Y              \
 SBC P                  \   XX(1 0) = x_lo - (A P)
 STA XX

 LDA X1                 \ And then we do the high bytes:
 SBC XX+1               \
 STA XX+1               \   XX(1 0) = (x_hi 0) - XX(1 0)
                        \
                        \ so we get our result:
                        \
                        \   XX(1 0) = x - (A P)
                        \           = x - |x_hi| * Q
                        \
                        \ which is result 2 above, and we also have:

 JSR MLU1               \ Call MLU1 to set:
                        \
                        \   Y1 = y_hi
                        \
                        \   (A P) = |y_hi| * Q
                        \
                        \ So Y1 contains the original value of y_hi, which we
                        \ use below to remove the existing particle

                        \ We now calculate:
                        \
                        \   (S R) = YY(1 0) = y - (A P)

 STA YY+1               \ First we do the low bytes with:
 LDA SYL,Y              \
 SBC P                  \   YY+1 = A
 STA YY                 \   R = YY = y_lo - P
 STA R                  \
                        \ so we get this:
                        \
                        \   (? R) = YY(1 0) = y_lo - (A P)

 LDA Y1                 \ And then we do the high bytes with:
 SBC YY+1               \
 STA YY+1               \   S = YY+1 = y_hi - YY+1
 STA S                  \
                        \ so we get our result:
                        \
                        \   (S R) = YY(1 0) = (y_hi y_lo) - (A P)
                        \                   = y - |y_hi| * Q
                        \
                        \ which is result 3 above, and (S R) is set to the new
                        \ value of y

 LDA SZL,Y              \ We now calculate the following:
 ADC DELT4              \
 STA SZL,Y              \  (z_hi z_lo) = (z_hi z_lo) + DELT4(1 0)
                        \
                        \ starting with the low bytes

 LDA SZ,Y               \ And then we do the high bytes
 STA ZZ                 \
 ADC DELT4+1            \ We also set ZZ to the original value of z_hi, which we
 STA SZ,Y               \ use below to remove the existing particle
                        \
                        \ So now we have result 4 above:
                        \
                        \   z = z + DELT4(1 0)
                        \     = z + speed * 64

 LDA XX+1               \ EOR x with the correct sign of the roll angle alpha,
 EOR ALP2               \ so A has the opposite sign to the roll angle alpha

 JSR MLS1               \ Call MLS1 to calculate:
                        \
                        \   (A P) = A * ALP1
                        \         = (-x / 256) * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = (-x / 256) * alpha + y
                        \         = y - alpha * x / 256

 STA YY+1               \ Set YY(1 0) = (A X) to give:
 STX YY                 \
                        \   YY(1 0) = y - alpha * x / 256
                        \
                        \ which is result 5 above, and we also have:
                        \
                        \   A = YY+1 = y - alpha * x / 256
                        \
                        \ i.e. A is the new value of y, divided by 256

 EOR ALP2+1             \ EOR with the flipped sign of the roll angle alpha, so
                        \ A has the opposite sign to the flipped roll angle
                        \ alpha, i.e. it gets the same sign as alpha

 JSR MLS2               \ Call MLS2 to calculate:
                        \
                        \   (S R) = XX(1 0)
                        \         = x
                        \
                        \   (A P) = A * ALP1
                        \         = y / 256 * alpha

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = y / 256 * alpha + x

 STA XX+1               \ Set XX(1 0) = (A X), which gives us result 6 above:
 STX XX                 \
                        \   x = x + alpha * y / 256

 LDA YY+1               \ Set A to y_hi and set it to the flipped sign of beta
 EOR BET2+1

 LDX BET1               \ Fetch the pitch magnitude into X

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = beta * y_hi

 STA Q                  \ Store the high byte of the result in Q, so:
                        \
                        \   Q = beta * y_hi / 256

 LDA XX+1               \ Set S = x_hi
 STA S

 EOR #%10000000         \ Flip the sign of A, so A now contains -x

 JSR MUT1               \ Call MUT1 to calculate:
                        \
                        \   R = XX = x_lo
                        \
                        \   (A P) = Q * A
                        \         = (beta * y_hi / 256) * (-beta * y_hi / 256)
                        \         = (-beta * y / 256) ^ 2

 ASL P                  \ Double (A P), store the top byte in A and set the C
 ROL A                  \ flag to bit 7 of the original A, so this does:
 STA T                  \
                        \   (T P) = (A P) << 1
                        \         = 2 * (-beta * y / 256) ^ 2

 LDA #0                 \ Set bit 7 in A to the sign bit from the A in the
 ROR A                  \ calculation above and apply it to T, so we now have:
 ORA T                  \
                        \   (A P) = -2 * (beta * y / 256) ^ 2
                        \
                        \ with the doubling retaining the sign of (A P)

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = -2 * (beta * y / 256) ^ 2 + x

 STA XX+1               \ Store the high byte A in XX+1

 TXA
 STA SXL,Y              \ Store the low byte X in x_lo

                        \ So (XX+1 x_lo) now contains:
                        \
                        \   x = x - 2 * (beta * y / 256) ^ 2
                        \
                        \ which is result 7 above

 LDA YY                 \ Set (S R) = YY(1 0) = y
 STA R
 LDA YY+1
 STA S

\EOR #128               \ These instructions are commented out in the original
\JSR MAD                \ source
\STA S
\STX R

 LDA #0                 \ Set P = 0
 STA P

 LDA BETA               \ Set A = beta, so (A P) = (beta 0) = beta * 256

 JSR PIX1               \ Call PIX1 to calculate the following:
                        \
                        \   (YY+1 y_lo) = (A P) + (S R)
                        \               = beta * 256 + y
                        \
                        \ i.e. y = y + beta * 256, which is result 8 above
                        \
                        \ PIX1 also draws a particle at (X1, Y1) with distance
                        \ ZZ, which will remove the old stardust particle, as we
                        \ set X1, Y1 and ZZ to the original values for this
                        \ particle during the calculations above

                        \ We now have our newly moved stardust particle at
                        \ x-coordinate (XX+1 x_lo) and y-coordinate (YY+1 y_lo)
                        \ and distance z_hi, so we draw it if it's still on
                        \ screen, otherwise we recycle it as a new bit of
                        \ stardust and draw that

 LDA XX+1               \ Set X1 and x_hi to the high byte of XX in XX+1, so
 STA X1                 \ the new x-coordinate is in (x_hi x_lo) and the high
 STA SX,Y               \ byte is in X1

 LDA YY+1               \ Set Y1 and y_hi to the high byte of YY in YY+1, so
 STA SY,Y               \ the new x-coordinate is in (y_hi y_lo) and the high
 STA Y1                 \ byte is in Y1

 AND #%01111111         \ If |y_hi| >= 110 then jump to KILL6 to recycle this
 CMP #110               \ particle, as it's gone off the top or bottom of the
 BCS KILL6              \ screen, and re-join at STC6 with the new particle

 LDA SZ,Y               \ If z_hi >= 160 then jump to KILL6 to recycle this
 CMP #160               \ particle, as it's so far away that it's too far to
 BCS KILL6              \ see, and re-join at STC1 with the new particle

 STA ZZ                 \ Set ZZ to the z-coordinate in z_hi

.STC6

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ,
                        \ i.e. draw the newly moved particle at (x_hi, y_hi)
                        \ with distance z_hi

 DEY                    \ Decrement the loop counter to point to the next
                        \ stardust particle

 BEQ ST3                \ If we have just done the last particle, skip the next
                        \ instruction to return from the subroutine

 JMP STL6               \ We have more stardust to process, so jump back up to
                        \ STL6 for the next particle

.ST3

 RTS                    \ Return from the subroutine

.KILL6

 JSR DORND              \ Set A and X to random numbers

 AND #%01111111         \ Clear the sign bit of A to get |A|

 ADC #10                \ Make sure A is at least 10 and store it in z_hi and
 STA SZ,Y               \ ZZ, so the new particle starts close to us
 STA ZZ

 LSR A                  \ Divide A by 2 and randomly set the C flag

 BCS ST4                \ Jump to ST4 half the time

 LSR A                  \ Randomly set the C flag again

 LDA #252               \ Set A to either +126 or -126 (252 >> 1) depending on
 ROR A                  \ the C flag, as this is a sign-magnitude number with
                        \ the C flag rotated into its sign bit

 STA X1                 \ Set x_hi and X1 to A, so this particle starts on
 STA SX,Y               \ either the left or right edge of the screen

 JSR DORND              \ Set A and X to random numbers

 STA Y1                 \ Set y_hi and Y1 to random numbers, so the particle
 STA SY,Y               \ starts anywhere along either the left or right edge

 JMP STC6               \ Jump up to STC6 to draw this new particle

.ST4

 JSR DORND              \ Set A and X to random numbers

 STA X1                 \ Set x_hi and X1 to random numbers, so the particle
 STA SX,Y               \ starts anywhere along the x-axis

 LSR A                  \ Randomly set the C flag

 LDA #230               \ Set A to either +115 or -115 (230 >> 1) depending on
 ROR A                  \ the C flag, as this is a sign-magnitude number with
                        \ the C flag rotated into its sign bit

 STA Y1                 \ Set y_hi and Y1 to A, so the particle starts anywhere
 STA SY,Y               \ along either the top or bottom edge of the screen

 BNE STC6               \ Jump up to STC6 to draw this new particle (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: PRXS
\       Type: Variable
\   Category: Equipment
\    Summary: Equipment prices
\
\ ------------------------------------------------------------------------------
\
\ Equipment prices are stored as 10 * the actual value, so we can support prices
\ with fractions of credits (0.1 Cr). This is used for the price of fuel only.
\
\ ******************************************************************************

.PRXS

 EQUW 1                 \ 0  Fuel, calculated in EQSHP  140.0 Cr (full tank)
 EQUW 300               \ 1  Missile                     30.0 Cr
 EQUW 4000              \ 2  Large Cargo Bay            400.0 Cr
 EQUW 6000              \ 3  E.C.M. System              600.0 Cr
 EQUW 4000              \ 4  Extra Pulse Lasers         400.0 Cr
 EQUW 10000             \ 5  Extra Beam Lasers         1000.0 Cr
 EQUW 5250              \ 6  Fuel Scoops                525.0 Cr
 EQUW 10000             \ 7  Escape Pod                1000.0 Cr
 EQUW 9000              \ 8  Energy Bomb                900.0 Cr
 EQUW 15000             \ 9  Energy Unit               1500.0 Cr
 EQUW 10000             \ 10 Docking Computer          1000.0 Cr
 EQUW 50000             \ 11 Galactic Hyperspace       5000.0 Cr

\ ******************************************************************************
\
\       Name: STATUS
\       Type: Subroutine
\   Category: Status
\    Summary: Show the Status Mode screen (red key f8)
\  Deep dive: Combat rank
\
\ ******************************************************************************

.st4

                        \ We call this from st5 below with the high byte of the
                        \ kill tally in A, which is non-zero, and want to return
                        \ with the following in X, depending on our rating:
                        \
                        \   Competent = 6
                        \   Dangerous = 7
                        \   Deadly    = 8
                        \   Elite     = 9
                        \
                        \ The high bytes of the top tier ratings are as follows,
                        \ so this a relatively simple calculation:
                        \
                        \   Competent       = 1 to 2
                        \   Dangerous       = 2 to 9
                        \   Deadly          = 10 to 24
                        \   Elite           = 25 and up

 LDX #9                 \ Set X to 9 for an Elite rating

 CMP #25                \ If A >= 25, jump to st3 to print out our rating, as we
 BCS st3                \ are Elite

 DEX                    \ Decrement X to 8 for a Deadly rating

 CMP #10                \ If A >= 10, jump to st3 to print out our rating, as we
 BCS st3                \ are Deadly

 DEX                    \ Decrement X to 7 for a Dangerous rating

 CMP #2                 \ If A >= 2, jump to st3 to print out our rating, as we
 BCS st3                \ are Dangerous

 DEX                    \ Decrement X to 6 for a Competent rating

 BNE st3                \ Jump to st3 to print out our rating, as we are
                        \ Competent (this BNE is effectively a JMP as A will
                        \ never be zero)

.STATUS

 LDA #8                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 8 (Status
                        \ Mode screen)

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 LDA #126               \ Print recursive token 126, which prints the top
 JSR NLIN3              \ four lines of the Status Mode screen:
                        \
                        \         COMMANDER {commander name}
                        \
                        \
                        \   Present System      : {current system name}
                        \   Hyperspace System   : {selected system name}
                        \   Condition           :
                        \
                        \ and draw a horizontal line at pixel row 19 to box
                        \ in the title

 LDA #15                \ Set A to token 129 ("{sentence case}DOCKED")

 LDY QQ12               \ Fetch the docked status from QQ12, and if we are
 BNE st6                \ docked, jump to st6 to print "Docked" for our
                        \ ship's condition

 LDA #230               \ Otherwise we are in space, so start off by setting A
                        \ to token 70 ("GREEN")

 LDY MANY+AST           \ Set Y to the number of asteroids in our local bubble
                        \ of universe

 LDX FRIN+2,Y           \ The ship slots at FRIN are ordered with the first two
                        \ slots reserved for the planet and sun/space station,
                        \ and then any ships, so if the slot at FRIN+2+Y is not
                        \ empty (i.e is non-zero), then that means the number of
                        \ non-asteroids in the vicinity is at least 1

 BEQ st6                \ So if X = 0, there are no ships in the vicinity, so
                        \ jump to st6 to print "Green" for our ship's condition

 LDY ENERGY             \ Otherwise we have ships in the vicinity, so we load
                        \ our energy levels into Y

 CPY #128               \ Set the C flag if Y >= 128, so C is set if we have
                        \ more than half of our energy banks charged

 ADC #1                 \ Add 1 + C to A, so if C is not set (i.e. we have low
                        \ energy levels) then A is set to token 231 ("RED"),
                        \ and if C is set (i.e. we have healthy energy levels)
                        \ then A is set to token 232 ("YELLOW")

.st6

 JSR plf                \ Print the text token in A (which contains our ship's
                        \ condition) followed by a newline

 LDA #125               \ Print recursive token 125, which prints the next
 JSR spc                \ three lines of the Status Mode screen:
                        \
                        \   Fuel: {fuel level} Light Years
                        \   Cash: {cash} Cr
                        \   Legal Status:
                        \
                        \ followed by a space

 LDA #19                \ Set A to token 133 ("CLEAN")

 LDY FIST               \ Fetch our legal status, and if it is 0, we are clean,
 BEQ st5                \ so jump to st5 to print "Clean"

 CPY #50                \ Set the C flag if Y >= 50, so C is set if we have
                        \ a legal status of 50+ (i.e. we are a fugitive)

 ADC #1                 \ Add 1 + C to A, so if C is not set (i.e. we have a
                        \ legal status between 1 and 49) then A is set to token
                        \ 134 ("OFFENDER"), and if C is set (i.e. we have a
                        \ legal status of 50+) then A is set to token 135
                        \ ("FUGITIVE")

.st5

 JSR plf                \ Print the text token in A (which contains our legal
                        \ status) followed by a newline

 LDA #16                \ Print recursive token 130 ("RATING:")
 JSR spc

 LDA TALLY+1            \ Fetch the high byte of the kill tally, and if it is
 BNE st4                \ not zero, then we have more than 256 kills, so jump
                        \ to st4 to work out whether we are Competent,
                        \ Dangerous, Deadly or Elite

                        \ Otherwise we have fewer than 256 kills, so we are one
                        \ of Harmless, Mostly Harmless, Poor, Average or Above
                        \ Average

 TAX                    \ Set X to 0 (as A is 0)

 LDA TALLY              \ Set A = lower byte of tally / 4
 LSR A
 LSR A

.st5L

                        \ We now loop through bits 2 to 7, shifting each of them
                        \ off the end of A until there are no set bits left, and
                        \ incrementing X for each shift, so at the end of the
                        \ process, X contains the position of the leftmost 1 in
                        \ A. Looking at the rank values in TALLY:
                        \
                        \   Harmless        = %00000000 to %00000011
                        \   Mostly Harmless = %00000100 to %00000111
                        \   Poor            = %00001000 to %00001111
                        \   Average         = %00010000 to %00011111
                        \   Above Average   = %00100000 to %11111111
                        \
                        \ we can see that the values returned by this process
                        \ are:
                        \
                        \   Harmless        = 1
                        \   Mostly Harmless = 2
                        \   Poor            = 3
                        \   Average         = 4
                        \   Above Average   = 5

 INX                    \ Increment X for each shift

 LSR A                  \ Shift A to the right

 BNE st5L               \ Keep looping around until A = 0, which means there are
                        \ no set bits left in A

.st3

 TXA                    \ A now contains our rating as a value of 1 to 9, so
                        \ transfer X to A, so we can print it out

 CLC                    \ Print recursive token 135 + A, which will be in the
 ADC #21                \ range 136 ("HARMLESS") to 144 ("---- E L I T E ----")
 JSR plf                \ followed by a newline

 LDA #18                \ Print recursive token 132, which prints the next bit
 JSR plf2               \ of the Status Mode screen:
                        \
                        \   EQUIPMENT:
                        \
                        \ followed by a newline and an indent of 6 characters

 LDA CRGO               \ If our ship's cargo capacity is < 26 (i.e. we do not
 CMP #26                \ have a cargo bay extension), skip the following two
 BCC P%+7               \ instructions

 LDA #107               \ We do have a cargo bay extension, so print recursive
 JSR plf2               \ token 107 ("LARGE CARGO{sentence case} BAY"), followed
                        \ by a newline and an indent of 6 characters

 LDA BST                \ If we don't have fuel scoops fitted, skip the
 BEQ P%+7               \ following two instructions

 LDA #111               \ We do have a fuel scoops fitted, so print recursive
 JSR plf2               \ token 111 ("FUEL SCOOPS"), followed by a newline and
                        \ an indent of 6 characters

 LDA ECM                \ If we don't have an E.C.M. fitted, skip the following
 BEQ P%+7               \ two instructions

 LDA #108               \ We do have an E.C.M. fitted, so print recursive token
 JSR plf2               \ 108 ("E.C.M.SYSTEM"), followed by a newline and an
                        \ indent of 6 characters

 LDA #113               \ We now cover the four pieces of equipment whose flags
 STA XX4                \ are stored in BOMB through BOMB+3, and whose names
                        \ correspond with text tokens 113 through 116:
                        \
                        \   BOMB+0 = BOMB  = token 113 = Energy bomb
                        \   BOMB+1 = ENGY  = token 114 = Energy unit
                        \   BOMB+2 = DKCMP = token 115 = Docking computer
                        \   BOMB+3 = GHYP  = token 116 = Galactic hyperdrive
                        \
                        \ We can print these out using a loop, so we set XX4 to
                        \ 113 as a counter (and we also set A as well, to pass
                        \ through to plf2)

.stqv

 TAY                    \ Fetch byte BOMB+0 through BOMB+4 for values of XX4
 LDX BOMB-113,Y         \ from 113 through 117

 BEQ P%+5               \ If it is zero then we do not own that piece of
                        \ equipment, so skip the next instruction

 JSR plf2               \ Print the recursive token in A from 113 ("ENERGY
                        \ BOMB") through 116 ("GALACTIC HYPERSPACE "), followed
                        \ by a newline and an indent of 6 characters

 INC XX4                \ Increment the counter (and A as well)
 LDA XX4

 CMP #117               \ If A < 117, loop back up to stqv to print the next
 BCC stqv               \ piece of equipment

 LDX #0                 \ Now to print our ship's lasers, so set a counter in X
                        \ to count through the four views (0 = front, 1 = rear,
                        \ 2 = left, 3 = right)

.st

 STX CNT                \ Store the view number in CNT

 LDY LASER,X            \ Fetch the laser power for view X, and if we do not
 BEQ st1                \ have a laser fitted to that view, jump to st1 to move
                        \ on to the next one

 TXA                    \ Print recursive token 96 + X, which will print from 96
 CLC                    \ ("FRONT") through to 99 ("RIGHT"), followed by a space
 ADC #96
 JSR spc

 LDA #103               \ Set A to token 103 ("PULSE LASER")

 LDX CNT                \ If the laser power for view X has bit 7 clear, then it
 LDY LASER,X            \ is a pulse laser, so skip the following instruction
 BPL P%+4

 LDA #104               \ Set A to token 104 ("BEAM LASER")

 JSR plf2               \ Print the text token in A (which contains our legal
                        \ status) followed by a newline and an indent of 6
                        \ characters

.st1

 LDX CNT                \ Increment the counter in X and CNT to point to the
 INX                    \ next view

 CPX #4                 \ If this isn't the last of the four views, jump back up
 BCC st                 \ to st to print out the next one

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: plf2
\       Type: Subroutine
\   Category: Text
\    Summary: Print text followed by a newline and indent of 6 characters
\
\ ------------------------------------------------------------------------------
\
\ Print a text token followed by a newline, and indent the next line to text
\ column 6.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.plf2

 JSR plf                \ Print the text token in A followed by a newline

 LDX #6                 \ Move the text cursor to column 6
 STX XC

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TENS
\       Type: Variable
\   Category: Text
\    Summary: A constant used when printing large numbers in BPRNT
\  Deep dive: Printing decimal numbers
\
\ ------------------------------------------------------------------------------
\
\ Contains the four low bytes of the value 100,000,000,000 (100 billion).
\
\ The maximum number of digits that we can print with the BPRNT routine is 11,
\ so the biggest number we can print is 99,999,999,999. This maximum number
\ plus 1 is 100,000,000,000, which in hexadecimal is:
\
\   & 17 48 76 E8 00
\
\ The TENS variable contains the lowest four bytes in this number, with the
\ most significant byte first, i.e. 48 76 E8 00. This value is used in the
\ BPRNT routine when working out which decimal digits to print when printing a
\ number.
\
\ ******************************************************************************

.TENS

 EQUD &00E87648

\ ******************************************************************************
\
\       Name: pr2
\       Type: Subroutine
\   Category: Text
\    Summary: Print an 8-bit number, left-padded to 3 digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 8-bit number in X to 3 digits, left-padding with spaces for numbers
\ with fewer than 3 digits (so numbers < 100 are right-aligned). Optionally
\ include a decimal point.
\
\ Arguments:
\
\   X                   The number to print
\
\   C flag              If set, include a decimal point
\
\ Other entry points:
\
\   pr2+2               Print the 8-bit number in X to the number of digits in A
\
\ ******************************************************************************

.pr2

 LDA #3                 \ Set A to the number of digits (3)

 LDY #0                 \ Zero the Y register, so we can fall through into TT11
                        \ to print the 16-bit number (Y X) to 3 digits, which
                        \ effectively prints X to 3 digits as the high byte is
                        \ zero

\ ******************************************************************************
\
\       Name: TT11
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 16-bit number, left-padded to n digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to a specific number of digits, left-padding
\ with spaces for numbers with fewer digits (so lower numbers will be right-
\ aligned). Optionally include a decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\   A                   The number of digits
\
\   C flag              If set, include a decimal point
\
\ ******************************************************************************

.TT11

 STA U                  \ We are going to use the BPRNT routine (below) to
                        \ print this number, so we store the number of digits
                        \ in U, as that's what BPRNT takes as an argument

 LDA #0                 \ BPRNT takes a 32-bit number in K to K+3, with the
 STA K                  \ most significant byte first (big-endian), so we set
 STA K+1                \ the two most significant bytes to zero (K and K+1)
 STY K+2                \ and store (Y X) in the least two significant bytes
 STX K+3                \ (K+2 and K+3), so we are going to print the 32-bit
                        \ number (0 0 Y X)

                        \ Finally we fall through into BPRNT to print out the
                        \ number in K to K+3, which now contains (Y X), to 3
                        \ digits (as U = 3), using the same C flag as when pr2
                        \ was called to control the decimal point

\ ******************************************************************************
\
\       Name: BPRNT
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 32-bit number, left-padded to a specific number of digits,
\             with an optional decimal point
\  Deep dive: Printing decimal numbers
\
\ ------------------------------------------------------------------------------
\
\ Print the 32-bit number stored in K(0 1 2 3) to a specific number of digits,
\ left-padding with spaces for numbers with fewer digits (so lower numbers are
\ right-aligned). Optionally include a decimal point.
\
\ See the deep dive on "Printing decimal numbers" for details of the algorithm
\ used in this routine.
\
\ Arguments:
\
\   K(0 1 2 3)          The number to print, stored with the most significant
\                       byte in K and the least significant in K+3 (i.e. as a
\                       big-endian number, which is the opposite way to how the
\                       6502 assembler stores addresses, for example)
\
\   U                   The maximum number of digits to print, including the
\                       decimal point (spaces will be used on the left to pad
\                       out the result to this width, so the number is right-
\                       aligned to this width). U must be 11 or less
\
\   C flag              If set, include a decimal point followed by one
\                       fractional digit (i.e. show the number to 1 decimal
\                       place). In this case, the number in K(0 1 2 3) contains
\                       10 * the number we end up printing, so to print 123.4,
\                       we would pass 1234 in K(0 1 2 3) and would set the C
\                       flag to include the decimal point
\
\ ******************************************************************************

.BPRNT

 LDX #11                \ Set T to the maximum number of digits allowed (11
 STX T                  \ characters, which is the number of digits in 10
                        \ billion). We will use this as a flag when printing
                        \ characters in TT37 below

 PHP                    \ Make a copy of the status register (in particular
                        \ the C flag) so we can retrieve it later

 BCC TT30               \ If the C flag is clear, we do not want to print a
                        \ decimal point, so skip the next two instructions

 DEC T                  \ As we are going to show a decimal point, decrement
 DEC U                  \ both the number of characters and the number of
                        \ digits (as one of them is now a decimal point)

.TT30

 LDA #11                \ Set A to 11, the maximum number of digits allowed

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

 STA XX17               \ Store the maximum number of digits allowed (11) in
                        \ XX17

 SBC U                  \ Set U = 11 - U + 1, so U now contains the maximum
 STA U                  \ number of digits minus the number of digits we want
 INC U                  \ to display, plus 1 (so this is the number of digits
                        \ we should skip before starting to print the number
                        \ itself, and the plus 1 is there to ensure we print at
                        \ least one digit)

 LDY #0                 \ In the main loop below, we use Y to count the number
                        \ of times we subtract 10 billion to get the leftmost
                        \ digit, so set this to zero

 STY S                  \ In the main loop below, we use location S as an
                        \ 8-bit overflow for the 32-bit calculations, so
                        \ we need to set this to 0 before joining the loop

 JMP TT36               \ Jump to TT36 to start the process of printing this
                        \ number's digits

.TT35

                        \ This subroutine multiplies K(S 0 1 2 3) by 10 and
                        \ stores the result back in K(S 0 1 2 3), using the fact
                        \ that K * 10 = (K * 2) + (K * 2 * 2 * 2)

 ASL K+3                \ Set K(S 0 1 2 3) = K(S 0 1 2 3) * 2 by rotating left
 ROL K+2
 ROL K+1
 ROL K
 ROL S

 LDX #3                 \ Now we want to make a copy of the newly doubled K in
                        \ XX15, so we can use it for the first (K * 2) in the
                        \ equation above, so set up a counter in X for copying
                        \ four bytes, starting with the last byte in memory
                        \ (i.e. the least significant)

.tt35

 LDA K,X                \ Copy the X-th byte of K(0 1 2 3) to the X-th byte of
 STA XX15,X             \ XX15(0 1 2 3), so that XX15 will contain a copy of
                        \ K(0 1 2 3) once we've copied all four bytes

 DEX                    \ Decrement the loop counter

 BPL tt35               \ Loop back to copy the next byte until we have copied
                        \ all four

 LDA S                  \ Store the value of location S, our overflow byte, in
 STA XX15+4             \ XX15+4, so now XX15(4 0 1 2 3) contains a copy of
                        \ K(S 0 1 2 3), which is the value of (K * 2) that we
                        \ want to use in our calculation

 ASL K+3                \ Now to calculate the (K * 2 * 2 * 2) part. We still
 ROL K+2                \ have (K * 2) in K(S 0 1 2 3), so we just need to shift
 ROL K+1                \ it twice. This is the first one, so we do this:
 ROL K                  \
 ROL S                  \   K(S 0 1 2 3) = K(S 0 1 2 3) * 2 = K * 4

 ASL K+3                \ And then we do it again, so that means:
 ROL K+2                \
 ROL K+1                \   K(S 0 1 2 3) = K(S 0 1 2 3) * 2 = K * 8
 ROL K
 ROL S

 CLC                    \ Clear the C flag so we can do addition without the
                        \ C flag affecting the result

 LDX #3                 \ By now we've got (K * 2) in XX15(4 0 1 2 3) and
                        \ (K * 8) in K(S 0 1 2 3), so the final step is to add
                        \ these two 32-bit numbers together to get K * 10.
                        \ So we set a counter in X for four bytes, starting
                        \ with the last byte in memory (i.e. the least
                        \ significant)

.tt36

 LDA K,X                \ Fetch the X-th byte of K into A

 ADC XX15,X             \ Add the X-th byte of XX15 to A, with carry

 STA K,X                \ Store the result in the X-th byte of K

 DEX                    \ Decrement the loop counter

 BPL tt36               \ Loop back to add the next byte, moving from the least
                        \ significant byte to the most significant, until we
                        \ have added all four

 LDA XX15+4             \ Finally, fetch the overflow byte from XX15(4 0 1 2 3)

 ADC S                  \ And add it to the overflow byte from K(S 0 1 2 3),
                        \ with carry

 STA S                  \ And store the result in the overflow byte from
                        \ K(S 0 1 2 3), so now we have our desired result, i.e.
                        \
                        \   K(S 0 1 2 3) = K(S 0 1 2 3) * 10

 LDY #0                 \ In the main loop below, we use Y to count the number
                        \ of times we subtract 10 billion to get the leftmost
                        \ digit, so set this to zero so we can rejoin the main
                        \ loop for another subtraction process

.TT36

                        \ This is the main loop of our digit-printing routine.
                        \ In the following loop, we are going to count the
                        \ number of times that we can subtract 10 million and
                        \ store that count in Y, which we have already set to 0

 LDX #3                 \ Our first calculation concerns 32-bit numbers, so
                        \ set up a counter for a four-byte loop

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

.tt37

                        \ We now loop through each byte in turn to do this:
                        \
                        \   XX15(4 0 1 2 3) = K(S 0 1 2 3) - 100,000,000,000

 LDA K,X                \ Subtract the X-th byte of TENS (i.e. 10 billion) from
 SBC TENS,X             \ the X-th byte of K

 STA XX15,X             \ Store the result in the X-th byte of XX15

 DEX                    \ Decrement the loop counter

 BPL tt37               \ Loop back to subtract the next byte, moving from the
                        \ least significant byte to the most significant, until
                        \ we have subtracted all four

 LDA S                  \ Subtract the fifth byte of 10 billion (i.e. &17) from
 SBC #&17               \ the fifth (overflow) byte of K, which is S

 STA XX15+4             \ Store the result in the overflow byte of XX15

 BCC TT37               \ If subtracting 10 billion took us below zero, jump to
                        \ TT37 to print out this digit, which is now in Y

 LDX #3                 \ We now want to copy XX15(4 0 1 2 3) back into
                        \ K(S 0 1 2 3), so we can loop back up to do the next
                        \ subtraction, so set up a counter for a four-byte loop

.tt38

 LDA XX15,X             \ Copy the X-th byte of XX15(0 1 2 3) to the X-th byte
 STA K,X                \ of K(0 1 2 3), so that K(0 1 2 3) will contain a copy
                        \ of XX15(0 1 2 3) once we've copied all four bytes

 DEX                    \ Decrement the loop counter

 BPL tt38               \ Loop back to copy the next byte, until we have copied
                        \ all four

 LDA XX15+4             \ Store the value of location XX15+4, our overflow
 STA S                  \ byte in S, so now K(S 0 1 2 3) contains a copy of
                        \ XX15(4 0 1 2 3)

 INY                    \ We have now managed to subtract 10 billion from our
                        \ number, so increment Y, which is where we are keeping
                        \ a count of the number of subtractions so far

 JMP TT36               \ Jump back to TT36 to subtract the next 10 billion

.TT37

 TYA                    \ If we get here then Y contains the digit that we want
                        \ to print (as Y has now counted the total number of
                        \ subtractions of 10 billion), so transfer Y into A

 BNE TT32               \ If the digit is non-zero, jump to TT32 to print it

 LDA T                  \ Otherwise the digit is zero. If we are already
                        \ printing the number then we will want to print a 0,
                        \ but if we haven't started printing the number yet,
                        \ then we probably don't, as we don't want to print
                        \ leading zeroes unless this is the only digit before
                        \ the decimal point
                        \
                        \ To help with this, we are going to use T as a flag
                        \ that tells us whether we have already started
                        \ printing digits:
                        \
                        \   * If T <> 0 we haven't printed anything yet
                        \
                        \   * If T = 0 then we have started printing digits
                        \
                        \ We initially set T above to the maximum number of
                        \ characters allowed, less 1 if we are printing a
                        \ decimal point, so the first time we enter the digit
                        \ printing routine at TT37, it is definitely non-zero

 BEQ TT32               \ If T = 0, jump straight to the print routine at TT32,
                        \ as we have already started printing the number, so we
                        \ definitely want to print this digit too

 DEC U                  \ We initially set U to the number of digits we want to
 BPL TT34               \ skip before starting to print the number. If we get
                        \ here then we haven't printed any digits yet, so
                        \ decrement U to see if we have reached the point where
                        \ we should start printing the number, and if not, jump
                        \ to TT34 to set up things for the next digit

 LDA #' '               \ We haven't started printing any digits yet, but we
 BNE tt34               \ have reached the point where we should start printing
                        \ our number, so call TT26 (via tt34) to print a space
                        \ so that the number is left-padded with spaces (this
                        \ BNE is effectively a JMP as A will never be zero)

.TT32

 LDY #0                 \ We are printing an actual digit, so first set T to 0,
 STY T                  \ to denote that we have now started printing digits as
                        \ opposed to spaces

 CLC                    \ The digit value is in A, so add ASCII "0" to get the
 ADC #'0'               \ ASCII character number to print

.tt34

 JSR TT26               \ Call TT26 to print the character in A and fall through
                        \ into TT34 to get things ready for the next digit

.TT34

 DEC T                  \ Decrement T but keep T >= 0 (by incrementing it
 BPL P%+4               \ again if the above decrement made T negative)
 INC T

 DEC XX17               \ Decrement the total number of characters left to
                        \ print, which we stored in XX17

 BMI RR3+1              \ If the result is negative, we have printed all the
                        \ characters, so return from the subroutine (as RR3
                        \ contains an ORA #&60 instruction, so RR3+1 is &60,
                        \ which is the opcode for an RTS)

 BNE P%+10              \ If the result is positive (> 0) then we still have
                        \ characters left to print, so loop back to TT35 (via
                        \ the JMP TT35 instruction below) to print the next
                        \ digit

 PLP                    \ If we get here then we have printed the exact number
                        \ of digits that we wanted to, so restore the C flag
                        \ that we stored at the start of the routine

 BCC P%+7               \ If the C flag is clear, we don't want a decimal point,
                        \ so loop back to TT35 (via the JMP TT35 instruction
                        \ below) to print the next digit

 LDA #'.'               \ Otherwise the C flag is set, so print the decimal
 JSR TT26               \ point

 JMP TT35               \ Loop back to TT35 to print the next digit

\ ******************************************************************************
\
\       Name: BELL
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a standard system beep
\
\ ------------------------------------------------------------------------------
\
\ This is the standard system beep as made by the VDU 7 statement in BBC BASIC.
\
\ ******************************************************************************

.BELL

 LDA #7                 \ Control code 7 makes a beep, so load this into A

                        \ Fall through into the TT26 print routine to
                        \ actually make the sound

\ ******************************************************************************
\
\       Name: TT26
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character at the text cursor by poking into screen memory
\  Deep dive: Drawing text
\
\ ------------------------------------------------------------------------------
\
\ Print a character at the text cursor (XC, YC), do a beep, print a newline,
\ or delete left (backspace).
\
\ WRCHV is set to point here by the loading process.
\
\ Arguments:
\
\   A                   The character to be printed. Can be one of the
\                       following:
\
\                         * 7 (beep)
\
\                         * 10-13 (line feeds and carriage returns)
\
\                         * 32-95 (ASCII capital letters, numbers and
\                           punctuation)
\
\                         * 127 (delete the character to the left of the text
\                           cursor and move the cursor to the left)
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
\   C flag              The C flag is cleared
\
\ Other entry points:
\
\   RR3+1               Contains an RTS
\
\   RREN                Prints the character definition pointed to by P(2 1) at
\                       the screen address pointed to by (A SC). Used by the
\                       BULB routine
\
\   rT9                 Contains an RTS
\
\ ******************************************************************************

.TT26

 STA K3                 \ Store the A, X and Y registers, so we can restore
 STY YSAV2              \ them at the end (so they don't get changed by this
 STX XSAV2              \ routine)

 LDY QQ17               \ Load the QQ17 flag, which contains the text printing
                        \ flags

 CPY #255               \ If QQ17 = 255 then printing is disabled, so jump to
 BEQ RR4                \ RR4, which doesn't print anything, it just restores
                        \ the registers and returns from the subroutine

 CMP #7                 \ If this is a beep character (A = 7), jump to R5,
 BEQ R5                 \ which will emit the beep, restore the registers and
                        \ return from the subroutine

 CMP #32                \ If this is an ASCII character (A >= 32), jump to RR1
 BCS RR1                \ below, which will print the character, restore the
                        \ registers and return from the subroutine

 CMP #10                \ If this is control code 10 (line feed) then jump to
 BEQ RRX1               \ RRX1, which will move down a line, restore the
                        \ registers and return from the subroutine

 LDX #1                 \ If we get here, then this is control code 11-13, of
 STX XC                 \ which only 13 is used. This code prints a newline,
                        \ which we can achieve by moving the text cursor
                        \ to the start of the line (carriage return) and down
                        \ one line (line feed). These two lines do the first
                        \ bit by setting XC = 1, and we then fall through into
                        \ the line feed routine that's used by control code 10

.RRX1

 INC YC                 \ Print a line feed, simply by incrementing the row
                        \ number (y-coordinate) of the text cursor, which is
                        \ stored in YC

 BNE RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine (this BNE is effectively a JMP as Y
                        \ will never be zero)

.RR1

                        \ If we get here, then the character to print is an
                        \ ASCII character in the range 32-95. The quickest way
                        \ to display text on-screen is to poke the character
                        \ pixel by pixel, directly into screen memory, so
                        \ that's what the rest of this routine does
                        \
                        \ The first step, then, is to get hold of the bitmap
                        \ definition for the character we want to draw on the
                        \ screen (i.e. we need the pixel shape of this
                        \ character). The MOS ROM contains bitmap definitions
                        \ of the system's ASCII characters, starting from &C000
                        \ for space (ASCII 32) and ending with the £ symbol
                        \ (ASCII 126)
                        \
                        \ There are definitions for 32 characters in each of the
                        \ three pages of MOS memory, as each definition takes up
                        \ 8 bytes (8 rows of 8 pixels) and 32 * 8 = 256 bytes =
                        \ 1 page. So:
                        \
                        \   ASCII 32-63  are defined in &C000-&C0FF (page 0)
                        \   ASCII 64-95  are defined in &C100-&C1FF (page 1)
                        \   ASCII 96-126 are defined in &C200-&C2F0 (page 2)
                        \
                        \ The following code reads the relevant character
                        \ bitmap from the above locations in ROM and pokes
                        \ those values into the correct position in screen
                        \ memory, thus printing the character on-screen
                        \
                        \ It's a long way from 10 PRINT "Hello world!":GOTO 10

\LDX #LO(K3)            \ These instructions are commented out in the original
\INX                    \ source, but they call OSWORD 10, which reads the
\STX P+1                \ character bitmap for the character number in K3 and
\DEX                    \ stores it in the block at K3+1, while also setting
\LDY #HI(K3)            \ P+1 to point to the character definition. This is
\STY P+2                \ exactly what the following uncommented code does,
\LDA #10                \ just without calling OSWORD. Presumably the code
\JSR OSWORD             \ below is faster than using the system call, as this
                        \ version takes up 15 bytes, while the version below
                        \ (which ends with STA P+1 and SYX P+2) is 17 bytes.
                        \ Every efficiency saving helps, especially as this
                        \ routine is run each time the game prints a character
                        \
                        \ If you want to switch this code back on, uncomment
                        \ the above block, and comment out the code below from
                        \ TAY to STX P+2. You will also need to uncomment the
                        \ LDA YC instruction a few lines down (in RR2), just to
                        \ make sure the rest of the code doesn't shift in
                        \ memory. To be honest I can't see a massive difference
                        \ in speed, but there you go

 TAY                    \ Copy the character number from A to Y, as we are
                        \ about to pull A apart to work out where this
                        \ character definition lives in memory

                        \ Now we want to set X to point to the relevant page
                        \ number for this character - i.e. &C0, &C1 or &C2.

                        \ The following logic is easier to follow if we look
                        \ at the three character number ranges in binary:
                        \
                        \   Bit #  76543210
                        \
                        \   32  = %00100000     Page 0 of bitmap definitions
                        \   63  = %00111111
                        \
                        \   64  = %01000000     Page 1 of bitmap definitions
                        \   95  = %01011111
                        \
                        \   96  = %01100000     Page 2 of bitmap definitions
                        \   125 = %01111101
                        \
                        \ We'll refer to this below

 LDX #&BF               \ Set X to point to the first font page in ROM minus 1,
                        \ which is &C0 - 1, or &BF

 ASL A                  \ If bit 6 of the character is clear (A is 32-63)
 ASL A                  \ then skip the following instruction
 BCC P%+4

 LDX #&C1               \ A is 64-126, so set X to point to page &C1

 ASL A                  \ If bit 5 of the character is clear (A is 64-95)
 BCC P%+3               \ then skip the following instruction

 INX                    \ Increment X
                        \
                        \ By this point, we started with X = &BF, and then
                        \ we did the following:
                        \
                        \   If A = 32-63:   skip    then INX  so X = &C0
                        \   If A = 64-95:   X = &C1 then skip so X = &C1
                        \   If A = 96-126:  X = &C1 then INX  so X = &C2
                        \
                        \ In other words, X points to the relevant page. But
                        \ what about the value of A? That gets shifted to the
                        \ left three times during the above code, which
                        \ multiplies the number by 8 but also drops bits 7, 6
                        \ and 5 in the process. Look at the above binary
                        \ figures and you can see that if we cleared bits 5-7,
                        \ then that would change 32-53 to 0-31... but it would
                        \ do exactly the same to 64-95 and 96-125. And because
                        \ we also multiply this figure by 8, A now points to
                        \ the start of the character's definition within its
                        \ page (because there are 8 bytes per character
                        \ definition)
                        \
                        \ Or, to put it another way, X contains the high byte
                        \ (the page) of the address of the definition that we
                        \ want, while A contains the low byte (the offset into
                        \ the page) of the address

 STA P+1                \ Store the address of this character's definition in
 STX P+2                \ P(2 1)

 LDA XC                 \ Fetch XC, the x-coordinate (column) of the text cursor
                        \ into A

 ASL A                  \ Multiply A by 8, and store in SC. As each character is
 ASL A                  \ 8 pixels wide, and the special screen mode Elite uses
 ASL A                  \ for the top part of the screen is 256 pixels across
 STA SC                 \ with one bit per pixel, this value is not only the
                        \ screen address offset of the text cursor from the left
                        \ side of the screen, it's also the least significant
                        \ byte of the screen address where we want to print this
                        \ character, as each row of on-screen pixels corresponds
                        \ to one page. To put this more explicitly, the screen
                        \ starts at &6000, so the text rows are stored in screen
                        \ memory like this:
                        \
                        \   Row 1: &6000 - &60FF    YC = 1, XC = 0 to 31
                        \   Row 2: &6100 - &61FF    YC = 2, XC = 0 to 31
                        \   Row 3: &6200 - &62FF    YC = 3, XC = 0 to 31
                        \
                        \ and so on

 LDA YC                 \ Fetch YC, the y-coordinate (row) of the text cursor

 CPY #127               \ If the character number (which is in Y) <> 127, then
 BNE RR2                \ skip to RR2 to print that character, otherwise this is
                        \ the delete character, so continue on

 DEC XC                 \ We want to delete the character to the left of the
                        \ text cursor and move the cursor back one, so let's
                        \ do that by decrementing YC. Note that this doesn't
                        \ have anything to do with the actual deletion below,
                        \ we're just updating the cursor so it's in the right
                        \ position following the deletion

 ADC #&5E               \ A contains YC (from above) and the C flag is set (from
 TAX                    \ the CPY #127 above), so these instructions do this:
                        \
                        \   X = YC + &5E + 1
                        \     = YC + &5F

                        \ Because YC starts at 0 for the first text row, this
                        \ means that X will be &5F for row 0, &60 for row 1 and
                        \ so on. In other words, X is now set to the page number
                        \ for the row before the one containing the text cursor,
                        \ and given that we set SC above to point to the offset
                        \ in memory of the text cursor within the row's page,
                        \ this means that (X SC) now points to the character
                        \ above the text cursor

 LDY #&F8               \ Set Y = &F8, so the following call to ZES2 will count
                        \ Y upwards from &F8 to &FF

 JSR ZES2               \ Call ZES2, which zero-fills from address (X SC) + Y to
                        \ (X SC) + &FF. (X SC) points to the character above the
                        \ text cursor, and adding &FF to this would point to the
                        \ cursor, so adding &F8 points to the character before
                        \ the cursor, which is the one we want to delete. So
                        \ this call zero-fills the character to the left of the
                        \ cursor, which erases it from the screen

 BEQ RR4                \ We are done deleting, so restore the registers and
                        \ return from the subroutine (this BNE is effectively
                        \ a JMP as ZES2 always returns with the Z flag set)

.RR2

                        \ Now to actually print the character

 INC XC                 \ Once we print the character, we want to move the text
                        \ cursor to the right, so we do this by incrementing
                        \ XC. Note that this doesn't have anything to do
                        \ with the actual printing below, we're just updating
                        \ the cursor so it's in the right position following
                        \ the print

\LDA YC                 \ This instruction is commented out in the original
                        \ source. It isn't required because we only just did a
                        \ LDA YC before jumping to RR2, so this is presumably
                        \ an example of the authors squeezing the code to save
                        \ 2 bytes and 3 cycles
                        \
                        \ If you want to re-enable the commented block near the
                        \ start of this routine, you should uncomment this
                        \ instruction as well

 CMP #24                \ If the text cursor is on the screen (i.e. YC < 24, so
 BCC RR3                \ we are on rows 1-23), then jump to RR3 to print the
                        \ character

 JSR TTX66              \ Otherwise we are off the bottom of the screen, so
                        \ clear the screen and draw a white border

 JMP RR4                \ And restore the registers and return from the
                        \ subroutine

.RR3

                        \ A contains the value of YC - the screen row where we
                        \ want to print this character - so now we need to
                        \ convert this into a screen address, so we can poke
                        \ the character data to the right place in screen
                        \ memory

 ORA #&60               \ We already stored the least significant byte
                        \ of this screen address in SC above (see the STA SC
                        \ instruction above), so all we need is the most
                        \ significant byte. As mentioned above, in Elite's
                        \ square mode 4 screen, each row of text on-screen
                        \ takes up exactly one page, so the first row is page
                        \ &60xx, the second row is page &61xx, so we can get
                        \ the page for character (XC, YC) by OR'ing with &60.
                        \ To see this in action, consider that our two values
                        \ are, in binary:
                        \
                        \   YC is between:  %00000000
                        \             and:  %00010111
                        \          &60 is:  %01100000
                        \
                        \ so YC OR &60 effectively adds &60 to YC, giving us
                        \ the page number that we want

.RREN

 STA SC+1               \ Store the page number of the destination screen
                        \ location in SC+1, so SC now points to the full screen
                        \ location where this character should go

 LDY #7                 \ We want to print the 8 bytes of character data to the
                        \ screen (one byte per row), so set up a counter in Y
                        \ to count these bytes

.RRL1

 LDA (P+1),Y            \ The character definition is at P(2 1) - we set this up
                        \ above - so load the Y-th byte from P(2 1), which will
                        \ contain the bitmap for the Y-th row of the character

 EOR (SC),Y             \ If we EOR this value with the existing screen
                        \ contents, then it's reversible (so reprinting the
                        \ same character in the same place will revert the
                        \ screen to what it looked like before we printed
                        \ anything); this means that printing a white pixel on
                        \ onto a white background results in a black pixel, but
                        \ that's a small price to pay for easily erasable text

 STA (SC),Y             \ Store the Y-th byte at the screen address for this
                        \ character location

 DEY                    \ Decrement the loop counter

 BPL RRL1               \ Loop back for the next byte to print to the screen

.RR4

 LDY YSAV2              \ We're done printing, so restore the values of the
 LDX XSAV2              \ A, X and Y registers that we saved above and clear
 LDA K3                 \ the C flag, so everything is back to how it was
 CLC

.rT9

 RTS                    \ Return from the subroutine

.R5

 JSR BEEP               \ Call the BEEP subroutine to make a short, high beep

 JMP RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: DIALS (Part 1 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: speed indicator
\  Deep dive: The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ This routine updates the dashboard. First we draw all the indicators in the
\ right part of the dashboard, from top (speed) to bottom (energy banks), and
\ then we move on to the left part, again drawing from top (forward shield) to
\ bottom (altitude).
\
\ This first section starts us off with the speedometer in the top right.
\
\ ******************************************************************************

.DIALS

 LDA #&D0               \ Set SC(1 0) = &78D0, which is the screen address for
 STA SC                 \ the character block containing the left end of the
 LDA #&78               \ top indicator in the right part of the dashboard, the
 STA SC+1               \ one showing our speed

 JSR PZW                \ Call PZW to set A to the colour for dangerous values
                        \ and X to the colour for safe values

 STX K+1                \ Set K+1 (the colour we should show for low values) to
                        \ X (the colour to use for safe values)

 STA K                  \ Set K (the colour we should show for high values) to
                        \ A (the colour to use for dangerous values)

                        \ The above sets the following indicators to show red
                        \ for high values and yellow/white for low values

 LDA #14                \ Set T1 to 14, the threshold at which we change the
 STA T1                 \ indicator's colour

 LDA DELTA              \ Fetch our ship's speed into A, in the range 0-40

\LSR A                  \ Draw the speed indicator using a range of 0-31, and
 JSR DIL-1              \ increment SC to point to the next indicator (the roll
                        \ indicator). The LSR is commented out as it isn't
                        \ required with a call to DIL-1, so perhaps this was
                        \ originally a call to DIL that got optimised

\ ******************************************************************************
\
\       Name: DIALS (Part 2 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: pitch and roll indicators
\  Deep dive: The dashboard indicators
\
\ ******************************************************************************

 LDA #0                 \ Set R = P = 0 for the low bytes in the call to the ADD
 STA R                  \ routine below
 STA P

 LDA #8                 \ Set S = 8, which is the value of the centre of the
 STA S                  \ roll indicator

 LDA ALP1               \ Fetch the roll angle alpha as a value between 0 and
 LSR A                  \ 31, and divide by 4 to get a value of 0 to 7
 LSR A

 ORA ALP2               \ Apply the roll sign to the value, and flip the sign,
 EOR #%10000000         \ so it's now in the range -7 to +7, with a positive
                        \ roll angle alpha giving a negative value in A

 JSR ADD                \ We now add A to S to give us a value in the range 1 to
                        \ 15, which we can pass to DIL2 to draw the vertical
                        \ bar on the indicator at this position. We use the ADD
                        \ routine like this:
                        \
                        \ (A X) = (A 0) + (S 0)
                        \
                        \ and just take the high byte of the result. We use ADD
                        \ rather than a normal ADC because ADD separates out the
                        \ sign bit and does the arithmetic using absolute values
                        \ and separate sign bits, which we want here rather than
                        \ the two's complement that ADC uses

 JSR DIL2               \ Draw a vertical bar on the roll indicator at offset A
                        \ and increment SC to point to the next indicator (the
                        \ pitch indicator)

 LDA BETA               \ Fetch the pitch angle beta as a value between -8 and
                        \ +8

 LDX BET1               \ Fetch the magnitude of the pitch angle beta, and if it
 BEQ P%+4               \ is 0 (i.e. we are not pitching), skip the next
                        \ instruction

 SBC #1                 \ The pitch angle beta is non-zero, so set A = A - 1
                        \ (the C flag is set by the call to DIL2 above, so we
                        \ don't need to do a SEC). This gives us a value of A
                        \ from -7 to +7 because these are magnitude-based
                        \ numbers with sign bits, rather than two's complement
                        \ numbers

 JSR ADD                \ We now add A to S to give us a value in the range 1 to
                        \ 15, which we can pass to DIL2 to draw the vertical
                        \ bar on the indicator at this position (see the JSR ADD
                        \ above for more on this)

 JSR DIL2               \ Draw a vertical bar on the pitch indicator at offset A
                        \ and increment SC to point to the next indicator (the
                        \ four energy banks)

\ ******************************************************************************
\
\       Name: DIALS (Part 3 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: four energy banks
\  Deep dive: The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ This and the next section only run once every four iterations of the main
\ loop, so while the speed, pitch and roll indicators update every iteration,
\ the other indicators update less often.
\
\ ******************************************************************************

 LDA MCNT               \ Fetch the main loop counter and calculate MCNT mod 4,
 AND #3                 \ jumping to rT9 if it is non-zero. rT9 contains an RTS,
 BNE rT9                \ so the following code only runs every 4 iterations of
                        \ the main loop, otherwise we return from the subroutine

 LDY #0                 \ Set Y = 0, for use in various places below

 JSR PZW                \ Call PZW to set A to the colour for dangerous values
                        \ and X to the colour for safe values

 STX K                  \ Set K (the colour we should show for high values) to X
                        \ (the colour to use for safe values)

 STA K+1                \ Set K+1 (the colour we should show for low values) to
                        \ A (the colour to use for dangerous values)

                        \ The above sets the following indicators to show red
                        \ for low values and yellow/white for high values, which
                        \ we use not only for the energy banks, but also for the
                        \ shield levels and current fuel

 LDX #3                 \ Set up a counter in X so we can zero the four bytes at
                        \ XX12, so we can then calculate each of the four energy
                        \ banks' values before drawing them later

 STX T1                 \ Set T1 to 3, the threshold at which we change the
                        \ indicator's colour

.DLL23

 STY XX12,X             \ Set the X-th byte of XX12 to 0

 DEX                    \ Decrement the counter

 BPL DLL23              \ Loop back for the next byte until the four bytes at
                        \ XX12 are all zeroed

 LDX #3                 \ Set up a counter in X to loop through the 4 energy
                        \ bank indicators, so we can calculate each of the four
                        \ energy banks' values and store them in XX12

 LDA ENERGY             \ Set A = Q = ENERGY / 4, so they are both now in the
 LSR A                  \ range 0-63 (so that's a maximum of 16 in each of the
 LSR A                  \ banks, and a maximum of 15 in the top bank)

 STA Q                  \ Set Q to A, so we can use Q to hold the remaining
                        \ energy as we work our way through each bank, from the
                        \ full ones at the bottom to the empty ones at the top

.DLL24

 SEC                    \ Set A = A - 16 to reduce the energy count by a full
 SBC #16                \ bank

 BCC DLL26              \ If the C flag is clear then A < 16, so this bank is
                        \ not full to the brim, and is therefore the last one
                        \ with any energy in it, so jump to DLL26

 STA Q                  \ This bank is full, so update Q with the energy of the
                        \ remaining banks

 LDA #16                \ Store this bank's level in XX12 as 16, as it is full,
 STA XX12,X             \ with XX12+3 for the bottom bank and XX12+0 for the top

 LDA Q                  \ Set A to the remaining energy level again

 DEX                    \ Decrement X to point to the next bank, i.e. the one
                        \ above the bank we just processed

 BPL DLL24              \ Loop back to DLL24 until we have either processed all
                        \ four banks, or jumped out early to DLL26 if the top
                        \ banks have no charge

 BMI DLL9               \ Jump to DLL9 as we have processed all four banks (this
                        \ BMI is effectively a JMP as A will never be positive)

.DLL26

 LDA Q                  \ If we get here then the bank we just checked is not
 STA XX12,X             \ fully charged, so store its value in XX12 (using Q,
                        \ which contains the energy of the remaining banks -
                        \ i.e. this one)

                        \ Now that we have the four energy bank values in XX12,
                        \ we can draw them, starting with the top bank in XX12
                        \ and looping down to the bottom bank in XX12+3, using Y
                        \ as a loop counter, which was set to 0 above

.DLL9

 LDA XX12,Y             \ Fetch the value of the Y-th indicator, starting from
                        \ the top

 STY P                  \ Store the indicator number in P for retrieval later

 JSR DIL                \ Draw the energy bank using a range of 0-15, and
                        \ increment SC to point to the next indicator (the
                        \ next energy bank down)

 LDY P                  \ Restore the indicator number into Y

 INY                    \ Increment the indicator number

 CPY #4                 \ Check to see if we have drawn the last energy bank

 BNE DLL9               \ Loop back to DLL9 if we have more banks to draw,
                        \ otherwise we are done

\ ******************************************************************************
\
\       Name: DIALS (Part 4 of 4)
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the dashboard: shields, fuel, laser & cabin temp, altitude
\  Deep dive: The dashboard indicators
\
\ ******************************************************************************

 LDA #&78               \ Set SC(1 0) = &7810, which is the screen address for
 STA SC+1               \ the character block containing the left end of the
 LDA #&10               \ top indicator in the left part of the dashboard, the
 STA SC                 \ one showing the forward shield

 LDA FSH                \ Draw the forward shield indicator using a range of
 JSR DILX               \ 0-255, and increment SC to point to the next indicator
                        \ (the aft shield)

 LDA ASH                \ Draw the aft shield indicator using a range of 0-255,
 JSR DILX               \ and increment SC to point to the next indicator (the
                        \ fuel level)

 LDA QQ14               \ Draw the fuel level indicator using a range of 0-63,
 JSR DILX+2             \ and increment SC to point to the next indicator (the
                        \ cabin temperature)

 JSR PZW                \ Call PZW to set A to the colour for dangerous values
                        \ and X to the colour for safe values

 STX K+1                \ Set K+1 (the colour we should show for low values) to
                        \ X (the colour to use for safe values)

 STA K                  \ Set K (the colour we should show for high values) to
                        \ A (the colour to use for dangerous values)

                        \ The above sets the following indicators to show red
                        \ for high values and yellow/white for low values, which
                        \ we use for the cabin and laser temperature bars

 LDX #11                \ Set T1 to 11, the threshold at which we change the
 STX T1                 \ cabin and laser temperature indicators' colours

 LDA CABTMP             \ Draw the cabin temperature indicator using a range of
 JSR DILX               \ 0-255, and increment SC to point to the next indicator
                        \ (the laser temperature)

 LDA GNTMP              \ Draw the laser temperature indicator using a range of
 JSR DILX               \ 0-255, and increment SC to point to the next indicator
                        \ (the altitude)

 LDA #240               \ Set T1 to 240, the threshold at which we change the
 STA T1                 \ altitude indicator's colour. As the altitude has a
                        \ range of 0-255, pixel 16 will not be filled in, and
                        \ 240 would change the colour when moving between pixels
                        \ 15 and 16, so this effectively switches off the colour
                        \ change for the altitude indicator

 STA K+1                \ Set K+1 (the colour we should show for low values) to
                        \ 240, or &F0 (dashboard colour 2, yellow/white), so the
                        \ altitude indicator always shows in this colour

 LDA ALTIT              \ Draw the altitude indicator using a range of 0-255
 JSR DILX

 JMP COMPAS             \ We have now drawn all the indicators, so jump to
                        \ COMPAS to draw the compass, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: PZW
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Fetch the current dashboard colours, to support flashing
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to the colours we should use for indicators showing dangerous and
\ safe values respectively. This enables us to implement flashing indicators,
\ which is one of the game's configurable options.
\
\ If flashing is enabled, the colour returned in A (dangerous values) will be
\ red for 8 iterations of the main loop, and yellow/white for the next 8, before
\ going back to red. If we always use PZW to decide which colours we should use
\ when updating indicators, flashing colours will be automatically taken care of
\ for us.
\
\ The values returned are &F0 for yellow/white and &0F for red. These are mode 5
\ bytes that contain 4 pixels, with the colour of each pixel given in two bits,
\ the high bit from the first nibble (bits 4-7) and the low bit from the second
\ nibble (bits 0-3). So in &F0 each pixel is %10, or colour 2 (yellow or white,
\ depending on the dashboard palette), while in &0F each pixel is %01, or colour
\ 1 (red).
\
\ Returns:
\
\   A                   The colour to use for indicators with dangerous values
\
\   X                   The colour to use for indicators with safe values
\
\ ******************************************************************************

.PZW

 LDX #&F0               \ Set X to dashboard colour 2 (yellow/white)

 LDA MCNT               \ A will be non-zero for 8 out of every 16 main loop
 AND #%00001000         \ counts, when bit 4 is set, so this is what we use to
                        \ flash the "danger" colour

 AND FLH                \ A will be zeroed if flashing colours are disabled

 BEQ P%+4               \ If A is zero, skip to the LDA instruction below

 TXA                    \ Otherwise flashing colours are enabled and it's the
                        \ main loop iteration where we flash them, so set A to
                        \ colour 2 (yellow/white) and use the BIT trick below to
                        \ return from the subroutine

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &0F, or BIT &0FA9, which does nothing apart
                        \ from affect the flags

 LDA #&0F               \ Set A to dashboard colour 1 (red)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DILX
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update a bar-based indicator on the dashboard
\  Deep dive: The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ The range of values shown on the indicator depends on which entry point is
\ called. For the default entry point of DILX, the range is 0-255 (as the value
\ passed in A is one byte). The other entry points are shown below.
\
\ Arguments:
\
\   A                   The value to be shown on the indicator (so the larger
\                       the value, the longer the bar)
\
\   T1                  The threshold at which we change the indicator's colour
\                       from the low value colour to the high value colour. The
\                       threshold is in pixels, so it should have a value from
\                       0-16, as each bar indicator is 16 pixels wide
\
\   K                   The colour to use when A is a high value, as a 4-pixel
\                       mode 5 character row byte
\
\   K+1                 The colour to use when A is a low value, as a 4-pixel
\                       mode 5 character row byte
\
\   SC(1 0)             The screen address of the first character block in the
\                       indicator
\
\ Other entry points:
\
\   DILX+2              The range of the indicator is 0-64 (for the fuel
\                       indicator)
\
\   DIL-1               The range of the indicator is 0-32 (for the speed
\                       indicator)
\
\   DIL                 The range of the indicator is 0-16 (for the energy
\                       banks)
\
\ ******************************************************************************

.DILX

 LSR A                  \ If we call DILX, we set A = A / 16, so A is 0-15
 LSR A

 LSR A                  \ If we call DILX+2, we set A = A / 4, so A is 0-15

 LSR A                  \ If we call DIL-1, we set A = A / 2, so A is 0-15

.DIL

                        \ If we call DIL, we leave A alone, so A is 0-15

 STA Q                  \ Store the indicator value in Q, now reduced to 0-15,
                        \ which is the length of the indicator to draw in pixels

 LDX #&FF               \ Set R = &FF, to use as a mask for drawing each row of
 STX R                  \ each character block of the bar, starting with a full
                        \ character's width of 4 pixels

 CMP T1                 \ If A >= T1 then we have passed the threshold where we
 BCS DL30               \ change bar colour, so jump to DL30 to set A to the
                        \ "high value" colour

 LDA K+1                \ Set A to K+1, the "low value" colour to use

 BNE DL31               \ Jump down to DL31 (this BNE is effectively a JMP as A
                        \ will never be zero)

.DL30

 LDA K                  \ Set A to K, the "high value" colour to use

.DL31

 STA COL                \ Store the colour of the indicator in COL

 LDY #2                 \ We want to start drawing the indicator on the third
                        \ line in this character row, so set Y to point to that
                        \ row's offset

 LDX #3                 \ Set up a counter in X for the width of the indicator,
                        \ which is 4 characters (each of which is 4 pixels wide,
                        \ to give a total width of 16 pixels)

.DL1

 LDA Q                  \ Fetch the indicator value (0-15) from Q into A

 CMP #4                 \ If Q < 4, then we need to draw the end cap of the
 BCC DL2                \ indicator, which is less than a full character's
                        \ width, so jump down to DL2 to do this

 SBC #4                 \ Otherwise we can draw a 4-pixel wide block, so
 STA Q                  \ subtract 4 from Q so it contains the amount of the
                        \ indicator that's left to draw after this character

 LDA R                  \ Fetch the shape of the indicator row that we need to
                        \ display from R, so we can use it as a mask when
                        \ painting the indicator. It will be &FF at this point
                        \ (i.e. a full 4-pixel row)

.DL5

 AND COL                \ Fetch the 4-pixel mode 5 colour byte from COL, and
                        \ only keep pixels that have their equivalent bits set
                        \ in the mask byte in A

 STA (SC),Y             \ Draw the shape of the mask on pixel row Y of the
                        \ character block we are processing

 INY                    \ Draw the next pixel row, incrementing Y
 STA (SC),Y

 INY                    \ And draw the third pixel row, incrementing Y
 STA (SC),Y

 TYA                    \ Add 6 to Y, so Y is now 8 more than when we started
 CLC                    \ this loop iteration, so Y now points to the address
 ADC #6                 \ of the first line of the indicator bar in the next
 TAY                    \ character block (as each character is 8 bytes of
                        \ screen memory)

 DEX                    \ Decrement the loop counter for the next character
                        \ block along in the indicator

 BMI DL6                \ If we just drew the last character block then we are
                        \ done drawing, so jump down to DL6 to finish off

 BPL DL1                \ Loop back to DL1 to draw the next character block of
                        \ the indicator (this BPL is effectively a JMP as A will
                        \ never be negative following the previous BMI)

.DL2

 EOR #3                 \ If we get here then we are drawing the indicator's
 STA Q                  \ end cap, so Q is < 4, and this EOR flips the bits, so
                        \ instead of containing the number of indicator columns
                        \ we need to fill in on the left side of the cap's
                        \ character block, Q now contains the number of blank
                        \ columns there should be on the right side of the cap's
                        \ character block

 LDA R                  \ Fetch the current mask from R, which will be &FF at
                        \ this point, so we need to turn Q of the columns on the
                        \ right side of the mask to black to get the correct end
                        \ cap shape for the indicator

.DL3

 ASL A                  \ Shift the mask left so bit 0 is cleared, and then
 AND #%11101111         \ clear bit 4, which has the effect of shifting zeroes
                        \ from the left into each nibble (i.e. xxxx xxxx becomes
                        \ xxx0 xxx0, which blanks out the last column in the
                        \ 4-pixel mode 5 character block)

 DEC Q                  \ Decrement the counter for the number of columns to
                        \ blank out

 BPL DL3                \ If we still have columns to blank out in the mask,
                        \ loop back to DL3 until the mask is correct for the
                        \ end cap

 PHA                    \ Store the mask byte on the stack while we use the
                        \ accumulator for a bit

 LDA #0                 \ Change the mask so no bits are set, so the characters
 STA R                  \ after the one we're about to draw will be all blank

 LDA #99                \ Set Q to a high number (99, why not) so we will keep
 STA Q                  \ drawing blank characters until we reach the end of
                        \ the indicator row

 PLA                    \ Restore the mask byte from the stack so we can use it
                        \ to draw the end cap of the indicator

 JMP DL5                \ Jump back up to DL5 to draw the mask byte on-screen

.DL6

 INC SC+1               \ Increment the high byte of SC to point to the next
                        \ character row on-screen (as each row takes up exactly
                        \ one page of 256 bytes) - so this sets up SC to point
                        \ to the next indicator, i.e. the one below the one we
                        \ just drew

.DL9

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DIL2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the roll or pitch indicator on the dashboard
\  Deep dive: The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ The indicator can show a vertical bar in 16 positions, with a value of 8
\ showing the bar in the middle of the indicator.
\
\ In practice this routine is only ever called with A in the range 1 to 15, so
\ the vertical bar never appears in the leftmost position (though it does appear
\ in the rightmost).
\
\ Arguments:
\
\   A                   The offset of the vertical bar to show in the indicator,
\                       from 0 at the far left, to 8 in the middle, and 15 at
\                       the far right
\
\ Returns:
\
\   C flag              The C flag is set
\
\ ******************************************************************************

.DIL2

 LDY #1                 \ We want to start drawing the vertical indicator bar on
                        \ the second line in the indicator's character block, so
                        \ set Y to point to that row's offset

 STA Q                  \ Store the offset of the vertical bar to draw in Q

                        \ We are now going to work our way along the indicator
                        \ on the dashboard, from left to right, working our way
                        \ along one character block at a time. Y will be used as
                        \ a pixel row counter to work our way through the
                        \ character blocks, so each time we draw a character
                        \ block, we will increment Y by 8 to move on to the next
                        \ block (as each character block contains 8 rows)

.DLL10

 SEC                    \ Set A = Q - 4, so that A contains the offset of the
 LDA Q                  \ vertical bar from the start of this character block
 SBC #4

 BCS DLL11              \ If Q >= 4 then the character block we are drawing does
                        \ not contain the vertical indicator bar, so jump to
                        \ DLL11 to draw a blank character block

 LDA #&FF               \ Set A to a high number (and &FF is as high as they go)

 LDX Q                  \ Set X to the offset of the vertical bar, which we know
                        \ is within this character block

 STA Q                  \ Set Q to a high number (&FF, why not) so we will keep
                        \ drawing blank characters after this one until we reach
                        \ the end of the indicator row

 LDA CTWOS,X            \ CTWOS is a table of ready-made 1-pixel mode 5 bytes,
                        \ just like the TWOS and TWOS2 tables for mode 4 (see
                        \ the PIXEL routine for details of how they work). This
                        \ fetches a mode 5 1-pixel byte with the pixel position
                        \ at X, so the pixel is at the offset that we want for
                        \ our vertical bar

 AND #&F0               \ The 4-pixel mode 5 colour byte &F0 represents four
                        \ pixels of colour %10 (3), which is yellow in the
                        \ normal dashboard palette and white if we have an
                        \ escape pod fitted. We AND this with A so that we only
                        \ keep the pixel that matches the position of the
                        \ vertical bar (i.e. A is acting as a mask on the
                        \ 4-pixel colour byte)

 BNE DLL12              \ Jump to DLL12 to skip the code for drawing a blank,
                        \ and move on to drawing the indicator (this BNE is
                        \ effectively a JMP as A is always non-zero)

.DLL11

                        \ If we get here then we want to draw a blank for this
                        \ character block

 STA Q                  \ Update Q with the new offset of the vertical bar, so
                        \ it becomes the offset after the character block we
                        \ are about to draw

 LDA #0                 \ Change the mask so no bits are set, so all of the
                        \ character blocks we display from now on will be blank
.DLL12

 STA (SC),Y             \ Draw the shape of the mask on pixel row Y of the
                        \ character block we are processing

 INY                    \ Draw the next pixel row, incrementing Y
 STA (SC),Y

 INY                    \ And draw the third pixel row, incrementing Y
 STA (SC),Y

 INY                    \ And draw the fourth pixel row, incrementing Y
 STA (SC),Y

 TYA                    \ Add 5 to Y, so Y is now 8 more than when we started
 CLC                    \ this loop iteration, so Y now points to the address
 ADC #5                 \ of the first line of the indicator bar in the next
 TAY                    \ character block (as each character is 8 bytes of
                        \ screen memory)

 CPY #30                \ If Y < 30 then we still have some more character
 BCC DLL10              \ blocks to draw, so loop back to DLL10 to display the
                        \ next one along

 INC SC+1               \ Increment the high byte of SC to point to the next
                        \ character row on-screen (as each row takes up exactly
                        \ one page of 256 bytes) - so this sets up SC to point
                        \ to the next indicator, i.e. the one below the one we
                        \ just drew

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TVT1
\       Type: Variable
\   Category: Screen mode
\    Summary: Palette data for space and the two dashboard colour schemes
\
\ ------------------------------------------------------------------------------
\
\ Palette bytes for use with the split-screen mode (see IRQ1 below for more
\ details).
\
\ Palette data is given as a set of bytes, with each byte mapping a logical
\ colour to a physical one. In each byte, the logical colour is given in bits
\ 4-7 and the physical colour in bits 0-3. See p.379 of the Advanced User Guide
\ for details of how palette mapping works, as in modes 4 and 5 we have to do
\ multiple palette commands to change the colours correctly, and the physical
\ colour value is EOR'd with 7, just to make things even more confusing.
\
\ Similarly, the palette at TVT1+16 is for the monochrome space view, where
\ logical colour 1 is mapped to physical colour 0 EOR 7 = 7 (white), and
\ logical colour 0 is mapped to physical colour 7 EOR 7 = 0 (black). Each of
\ these mappings requires six calls to SHEILA &21 - see p.379 of the Advanced
\ User Guide for an explanation.
\
\ The mode 5 palette table has two blocks which overlap. The block used depends
\ on whether or not we have an escape pod fitted. The block at TVT1 is used for
\ the standard dashboard colours, while TVT1+8 is used for the dashboard when an
\ escape pod is fitted. The colours are as follows:
\
\                 Normal (TVT1)     Escape pod (TVT1+8)
\
\   Colour 0      Black             Black
\   Colour 1      Red               Red
\   Colour 2      Yellow            White
\   Colour 3      Green             Cyan
\
\ ******************************************************************************

.TVT1

 EQUB &D4, &C4          \ This block of palette data is used to create two
 EQUB &94, &84          \ palettes used in three different places, all of them
 EQUB &F5, &E5          \ redefining four colours in mode 5:
 EQUB &B5, &A5          \
                        \ 12 bytes from TVT1 (i.e. the first 6 rows): applied
 EQUB &76, &66          \ when the T1 timer runs down at the switch from the
 EQUB &36, &26          \ space view to the dashboard, so this is the standard
                        \ dashboard palette
 EQUB &E1, &F1          \
 EQUB &B1, &A1          \ 8 bytes from TVT1+8 (i.e. the last 4 rows): applied
                        \ when the T1 timer runs down at the switch from the
                        \ space view to the dashboard, and we have an escape
                        \ pod fitted, so this is the escape pod dashboard
                        \ palette
                        \
                        \ 8 bytes from TVT1+8 (i.e. the last 4 rows): applied
                        \ at vertical sync in LINSCN when HFX is non-zero, to
                        \ create the hyperspace effect in LINSCN (where the
                        \ whole screen is switched to mode 5 at vertical sync)

 EQUB &F0, &E0          \ 12 bytes of palette data at TVT1+16, used to set the
 EQUB &B0, &A0          \ mode 4 palette in LINSCN when we hit vertical sync,
 EQUB &D0, &C0          \ so the palette is set to monochrome when we start to
 EQUB &90, &80          \ draw the first row of the screen
 EQUB &77, &67
 EQUB &37, &27

\ ******************************************************************************
\
\       Name: IRQ1
\       Type: Subroutine
\   Category: Screen mode
\    Summary: The main screen-mode interrupt handler (IRQ1V points here)
\  Deep dive: The split-screen mode
\
\ ------------------------------------------------------------------------------
\
\ The main interrupt handler, which implements Elite's split-screen mode (see
\ the deep dive on "The split-screen mode" for details).
\
\ IRQ1V is set to point to IRQ1 by the loading process.
\
\ ******************************************************************************

.LINSCN

                        \ This is called from the interrupt handler below, at
                        \ the start of each vertical sync (i.e. when the screen
                        \ refresh starts)

 LDA #30                \ Set the line scan counter to a non-zero value, so
 STA DL                 \ routines like WSCAN can set DL to 0 and then wait for
                        \ it to change to non-zero to catch the vertical sync

 STA VIA+&44            \ Set 6522 System VIA T1C-L timer 1 low-order counter
                        \ (SHEILA &44) to 30

 LDA #VSCAN             \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to VSCAN (57) to start the T1 counter
                        \ counting down from 14622 at a rate of 1 MHz

 LDA HFX                \ If HFX is non-zero, jump to VNT1 to set the mode 5
 BNE VNT1               \ palette instead of switching to mode 4, which will
                        \ have the effect of blurring and colouring the top
                        \ screen. This is how the white hyperspace rings turn
                        \ to colour when we do a hyperspace jump, and is
                        \ triggered by setting HFX to 1 in routine LL164

 LDA #%00001000         \ Set the Video ULA control register (SHEILA &20) to
 STA VIA+&20            \ %00001000, which is the same as switching to mode 4
                        \ (i.e. the top part of the screen) but with no cursor

.VNT3

 LDA TVT1+16,Y          \ Copy the Y-th palette byte from TVT1+16 to SHEILA &21
 STA VIA+&21            \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BPL VNT3               \ Loop back to VNT3 until we have copied all the
                        \ palette bytes

 LDA LASCT              \ Decrement the value of LASCT, but if we go too far
 BEQ P%+5               \ and it becomes negative, bump it back up again (this
 DEC LASCT              \ controls the pulsing of pulse lasers)

 LDA SVN                \ If SVN is non-zero, we are in the process of saving
 BNE jvec               \ the commander file, so jump to jvec to pass control
                        \ to the next interrupt handler, so we don't break file
                        \ saving by blocking the interrupt chain

 PLA                    \ Otherwise restore Y from the stack
 TAY

 LDA VIA+&41            \ Read 6522 System VIA input register IRA (SHEILA &41)

 LDA &FC                \ Set A to the interrupt accumulator save register,
                        \ which restores A to the value it had on entering the
                        \ interrupt

 RTI                    \ Return from interrupts, so this interrupt is not
                        \ passed on to the next interrupt handler, but instead
                        \ the interrupt terminates here

.IRQ1

 TYA                    \ Store Y on the stack
 PHA

 LDY #11                \ Set Y as a counter for 12 bytes, to use when setting
                        \ the dashboard palette below

 LDA #%00000010         \ Read the 6522 System VIA status byte bit 1 (SHEILA
 BIT VIA+&4D            \ &4D), which is set if vertical sync has occurred on
                        \ the video system

 BNE LINSCN             \ If we are on the vertical sync pulse, jump to LINSCN
                        \ to set up the timers to enable us to switch the
                        \ screen mode between the space view and dashboard

 BVC jvec               \ Read the 6522 System VIA status byte bit 6, which is
                        \ set if timer 1 has timed out. We set the timer in
                        \ LINSCN above, so this means we only run the next bit
                        \ if the screen redraw has reached the boundary between
                        \ the space view and the dashboard. Otherwise bit 6 is
                        \ clear and we aren't at the boundary, so we jump to
                        \ jvec to pass control to the next interrupt handler

 ASL A                  \ Double the value in A to 4

 STA VIA+&20            \ Set the Video ULA control register (SHEILA &20) to
                        \ %00000100, which is the same as switching to mode 5,
                        \ (i.e. the bottom part of the screen) but with no
                        \ cursor

 LDA ESCP               \ If an escape pod is fitted, jump to VNT1 to set the
 BNE VNT1               \ mode 5 palette differently (so the dashboard is a
                        \ different colour if we have an escape pod)

 LDA TVT1,Y             \ Copy the Y-th palette byte from TVT1 to SHEILA &21
 STA VIA+&21            \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BPL P%-7               \ Loop back to the LDA TVT1,Y instruction until we have
                        \ copied all the palette bytes

.jvec

 PLA                    \ Restore Y from the stack
 TAY

 JMP (VEC)              \ Jump to the address in VEC, which was set to the
                        \ original IRQ1V vector by the loading process, so this
                        \ instruction passes control to the next interrupt
                        \ handler

.VNT1

 LDY #7                 \ Set Y as a counter for 8 bytes

 LDA TVT1+8,Y           \ Copy the Y-th palette byte from TVT1+8 to SHEILA &21
 STA VIA+&21            \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BPL VNT1+2             \ Loop back to the LDA TVT1+8,Y instruction until we
                        \ have copied all the palette bytes

 BMI jvec               \ Jump up to jvec to pass control to the next interrupt
                        \ handler (this BMI is effectively a JMP as we didn't
                        \ loop back with the BPL above, so BMI is always true)

\ ******************************************************************************
\
\       Name: ESCAPE
\       Type: Subroutine
\   Category: Flight
\    Summary: Launch our escape pod
\
\ ------------------------------------------------------------------------------
\
\ This routine displays our doomed Cobra Mk III disappearing off into the ether
\ before arranging our replacement ship. Called when we press ESCAPE during
\ flight and have an escape pod fitted.
\
\ ******************************************************************************

.ESCAPE

 LDA MJ                 \ Store the value of MJ on the stack (the "are we in
 PHA                    \ witchspace?" flag)

 JSR RES2               \ Reset a number of flight variables and workspaces

 LDX #CYL               \ Set the current ship type to a Cobra Mk III, so we
 STX TYPE               \ can show our ship disappear into the distance when we
                        \ eject in our pod

 JSR FRS1               \ Call FRS1 to launch the Cobra Mk III straight ahead,
                        \ like a missile launch, but with our ship instead

 LDA #8                 \ Set the Cobra's byte #27 (speed) to 8
 STA INWK+27

 LDA #194               \ Set the Cobra's byte #30 (pitch counter) to 194, so it
 STA INWK+30            \ pitches as we pull away

 LSR A                  \ Set the Cobra's byte #32 (AI flag) to %01100001, so it
 STA INWK+32            \ has no AI, and we can use this value as a counter to
                        \ do the following loop 97 times

.ESL1

 JSR MVEIT              \ Call MVEIT to move the Cobra in space

 JSR LL9                \ Call LL9 to draw the Cobra on-screen

 DEC INWK+32            \ Decrement the counter in byte #32

 BNE ESL1               \ Loop back to keep moving the Cobra until the AI flag
                        \ is 0, which gives it time to drift away from our pod

 JSR SCAN               \ Call SCAN to remove the Cobra from the scanner (by
                        \ redrawing it)

 JSR RESET              \ Call RESET to reset our ship and various controls

 PLA                    \ Restore the witchspace flag from before the escape pod
 BEQ P%+5               \ launch, and if we were in normal space, skip the
                        \ following instruction

 JMP DEATH              \ Launching an escape pod in witchspace is fatal, so
                        \ jump to DEATH to begin the funeral and return from the
                        \ subroutine using a tail call

 LDX #16                \ We lose all our cargo when using our escape pod, so
                        \ up a counter in X so we can zero the 17 cargo slots
                        \ in QQ20

.ESL2

 STA QQ20,X             \ Set the X-th byte of QQ20 to zero (as we know A = 0
                        \ from the BEQ above), so we no longer have any of item
                        \ type X in the cargo hold

 DEX                    \ Decrement the counter

 BPL ESL2               \ Loop back to ESL2 until we have emptied the entire
                        \ cargo hold

 STA FIST               \ Launching an escape pod also clears our criminal
                        \ record, so set our legal status in FIST to 0 ("clean")

 STA ESCP               \ The escape pod is a one-use item, so set ESCP to 0 so
                        \ we no longer have one fitted

 LDA #70                \ Our replacement ship is delivered with a full tank of
 STA QQ14               \ fuel, so set the current fuel level in QQ14 to 70, or
                        \ 7.0 light years

 JMP BAY                \ Go to the docking bay (i.e. show the Status Mode
                        \ screen) and return from the subroutine with a tail
                        \ call

\ ******************************************************************************
\
\ Save ELTB.bin
\
\ ******************************************************************************

PRINT "ELITE B"
PRINT "Assembled at ", ~CODE_B%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_B%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_B%

PRINT "S.ELTB ", ~CODE_B%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_B%
SAVE "3-assembled-output/ELTB.bin", CODE_B%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE C FILE
\
\ Produces the binary file ELTC.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CODE_C% = P%
LOAD_C% = LOAD% +P% - CODE%

\ ******************************************************************************
\
\       Name: TACTICS (Part 1 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Process missiles, both enemy missiles and our own
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section implements missile tactics and is entered at TA18 from the main
\ entry point below, if the current ship is a missile. Specifically:
\
\   * If E.C.M. is active, destroy the missile
\
\   * If the missile is hostile towards us, then check how close it is. If it
\     hasn't reached us, jump to part 3 so it can streak towards us, otherwise
\     we've been hit, so process a large amount of damage to our ship
\
\   * Otherwise see how close the missile is to its target. If it has not yet
\     reached its target, give the target a chance to activate its E.C.M. if it
\     has one, otherwise jump to TA19 with K3 set to the vector from the target
\     to the missile
\
\   * If it has reached its target and the target is the space station, destroy
\     the missile, potentially damaging us if we are nearby
\
\   * If it has reached its target and the target is a ship, destroy the missile
\     and the ship, potentially damaging us if we are nearby
\
\ ******************************************************************************

.TA34

                        \ If we get here, the missile is hostile

 LDA #0                 \ Set A to x_hi OR y_hi OR z_hi
 JSR MAS4

 BEQ P%+5               \ If A = 0 then the missile is very close to our ship,
                        \ so skip the following instruction

 JMP TA21               \ Jump down to part 3 to set up the vectors and skip
                        \ straight to aggressive manoeuvring

 JSR TA87+3             \ The missile has hit our ship, so call TA87+3 to set
                        \ bit 7 of the missile's byte #31, which marks the
                        \ missile as being killed

 JSR EXNO3              \ Make the sound of the missile exploding

 LDA #250               \ Call OOPS to damage the ship by 250, which is a pretty
 JMP OOPS               \ big hit, and return from the subroutine using a tail
                        \ call

.TA18

                        \ This is the entry point for missile tactics and is
                        \ called from the main TACTICS routine below

 LDA ECMA               \ If an E.C.M. is currently active (either our's or an
 BNE TA35               \ opponent's), jump to TA35 to destroy this missile

 LDA INWK+32            \ Fetch the AI flag from byte #32 and if bit 6 is set
 ASL A                  \ (i.e. missile is hostile), jump up to TA34 to check
 BMI TA34               \ whether the missile has hit us

 LSR A                  \ Otherwise shift A right again. We know bits 6 and 7
                        \ are now clear, so this leaves bits 0-5. Bits 1-5
                        \ contain the target's slot number, and bit 0 is cleared
                        \ in FRMIS when a missile is launched, so A contains
                        \ the slot number shifted left by 1 (i.e. doubled) so we
                        \ can use it as an index for the two-byte address table
                        \ at UNIV

 TAX                    \ Copy the address of the target ship's data block from
 LDA UNIV,X             \ UNIV(X+1 X) to V(1 0)
 STA V
 LDA UNIV+1,X
 STA V+1

 LDY #2                 \ K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate of
 JSR TAS1               \ target ship

 LDY #5                 \ K3(5 4 3) = (y_sign y_hi z_lo) - y-coordinate of
 JSR TAS1               \ target ship

 LDY #8                 \ K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate of
 JSR TAS1               \ target ship

                        \ So K3 now contains the vector from the target ship to
                        \ the missile

 LDA K3+2               \ Set A = OR of all the sign and high bytes of the
 ORA K3+5               \ above, clearing bit 7 (i.e. ignore the signs)
 ORA K3+8
 AND #%01111111
 ORA K3+1
 ORA K3+4
 ORA K3+7

 BNE TA64               \ If the result is non-zero, then the missile is some
                        \ distance from the target, so jump down to TA64 see if
                        \ the target activates its E.C.M.

 LDA INWK+32            \ Fetch the AI flag from byte #32 and if only bits 7 and
 CMP #%10000010         \ 1 are set (AI is enabled and the target is slot 1, the
 BEQ TA35               \ space station), jump to TA35 to destroy this missile,
                        \ as the space station ain't kidding around

 LDY #31                \ Fetch byte #31 (the exploding flag) of the target ship
 LDA (V),Y              \ into A

 BIT M32+1              \ M32 contains an LDY #32 instruction, so M32+1 contains
                        \ 32, so this instruction tests A with %00100000, which
                        \ checks bit 5 of A (the "already exploding?" bit)

 BNE TA35               \ If the target ship is already exploding, jump to TA35
                        \ to destroy this missile

 ORA #%10000000         \ Otherwise set bit 7 of the target's byte #31 to mark
 STA (V),Y              \ the ship as having been killed, so it explodes

.TA35

 LDA INWK               \ Set A = x_lo OR y_lo OR z_lo of the missile
 ORA INWK+3
 ORA INWK+6

 BNE TA87               \ If A is non-zero then the missile is not near our
                        \ ship, so jump to TA87 to skip damaging our ship

 LDA #80                \ Otherwise the missile just got destroyed near us, so
 JSR OOPS               \ call OOPS to damage the ship by 80, which is nowhere
                        \ near as bad as the 250 damage from a missile slamming
                        \ straight into us, but it's still pretty nasty

.TA87

 JSR EXNO2              \ Call EXNO2 to process the fact that we have killed a
                        \ missile (so increase the kill tally, make an explosion
                        \ sound and so on)

 ASL INWK+31            \ Set bit 7 of the missile's byte #31 flag to mark it as
 SEC                    \ having been killed, so it explodes
 ROR INWK+31

.TA1

 RTS                    \ Return from the subroutine

.TA64

                        \ If we get here then the missile has not reached the
                        \ target

 JSR DORND              \ Set A and X to random numbers

 CMP #16                \ If A >= 16 (94% chance), jump down to TA19 with the
 BCS TA19               \ vector from the target to the missile in K3

.M32

 LDY #32                \ Fetch byte #32 for the target and shift bit 0 (E.C.M.)
 LDA (V),Y              \ into the C flag
 LSR A

 BCC TA19               \ If the C flag is clear then the target does not have
                        \ E.C.M. fitted, so jump down to TA19 with the vector
                        \ from the target to the missile in K3

 JMP ECBLB2             \ The target has E.C.M., so jump to ECBLB2 to set it
                        \ off, returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TACTICS (Part 2 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Escape pod, station, lone Thargon, safe-zone pirate
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section contains the main entry point at TACTICS, which is called from
\ part 2 of MVEIT for ships that have the AI flag set (i.e. bit 7 of byte #32).
\ This part does the following:
\
\   * If this is a missile, jump up to the missile code in part 1
\
\   * If this is an escape pod, point it at the planet and jump to the
\     manoeuvring code in part 7
\
\   * If this is the space station and it is hostile, consider spawning a cop
\     (45% chance, up to a maximum of four) and we're done
\
\   * If this is a lone Thargon without a mothership, set it adrift aimlessly
\     and we're done
\
\   * If this is a pirate and we are within the space station safe zone, stop
\     the pirate from attacking by removing all its aggression
\
\   * Recharge the ship's energy banks by 1
\
\ Arguments:
\
\   X                   The ship type
\
\ ******************************************************************************

.TACTICS

 CPX #MSL               \ If this is a missile, jump up to TA18 to implement
 BEQ TA18               \ missile tactics

 CPX #ESC               \ If this is not an escape pod, skip the following two
 BNE P%+8               \ instructions

 JSR SPS1               \ This is an escape pod, so call SPS1 to calculate the
                        \ vector to the planet and store it in XX15

 JMP TA15               \ Jump down to TA15

 CPX #SST               \ If this is not the space station, jump down to TA13
 BNE TA13

                        \ We only call the tactics routine for the space station
                        \ when it is hostile, so if we get here then this is the
                        \ station, and we already know it's hostile, so we need
                        \ to spawn some cops

 JSR DORND              \ Set A and X to random numbers

 CMP #140               \ If A < 140 (55% chance) then return from the
 BCC TA14-1             \ subroutine (as TA14-1 contains an RTS)

 LDA MANY+COPS          \ We only call the tactics routine for the space station
 CMP #4                 \ when it is hostile, so first check the number of cops
 BCS TA14-1             \ in the vicinity, and if we already have 4 or more, we
                        \ don't need to spawn any more, so return from the
                        \ subroutine (as TA14-1 contains an RTS)

 LDX #COPS              \ Set X to the ship type for a cop

 LDA #%11110001         \ Set the AI flag to give the ship E.C.M., enable AI and
                        \ make it very aggressive (60 out of 63)

 JMP SFS1               \ Jump to SFS1 to spawn the ship, returning from the
                        \ subroutine using a tail call

.TA13

 CPX #TGL               \ If this is not a Thargon, jump down to TA14
 BNE TA14

 LDA MANY+THG           \ If there is at least one Thargoid in the vicinity,
 BNE TA14               \ jump down to TA14

 LSR INWK+32            \ This is a Thargon but there is no Thargoid mothership,
 ASL INWK+32            \ so clear bit 0 of the AI flag to disable its E.C.M.

 LSR INWK+27            \ And halve the Thargon's speed

 RTS                    \ Return from the subroutine

.TA14

 CPX #CYL               \ If A >= #CYL, i.e. this is a Cobra Mk III trader (as
 BCS TA62               \ asteroids and cargo canisters never have AI), jump
                        \ down to TA62

 CPX #COPS              \ If this is a cop, jump down to TA62
 BEQ TA62

 LDA SSPR               \ If we aren't within range of the space station, jump
 BEQ TA62               \ down to TA62

 LDA INWK+32            \ This is a pirate or bounty hunter, but we are inside
 AND #%10000001         \ the space station's safe zone, so clear bits 1-6 of
 STA INWK+32            \ the AI flag to stop it being hostile, because even
                        \ pirates aren't crazy enough to breach the station's
                        \ no-fire zone

.TA62

 LDY #14                \ If the ship's energy is greater or equal to the
 LDA INWK+35            \ maximum value from the ship's blueprint pointed to by
 CMP (XX0),Y            \ XX0, then skip the next instruction
 BCS TA21

 INC INWK+35            \ The ship's energy is not at maximum, so recharge the
                        \ energy banks by 1

\ ******************************************************************************
\
\       Name: TACTICS (Part 3 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Calculate dot product to determine ship's aim
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section sets up some vectors and calculates dot products. Specifically:
\
\   * Calculate the dot product of the ship's nose vector (i.e. the direction it
\     is pointing) with the vector between us and the ship. This value will help
\     us work out later on whether the enemy ship is pointing towards us, and
\     therefore whether it can hit us with its lasers.
\
\ ******************************************************************************

.TA21

 LDX #8                 \ We now want to copy the ship's x, y and z coordinates
                        \ from INWK to K3, so set up a counter for 9 bytes

.TAL1

 LDA INWK,X             \ Copy the X-th byte from INWK to the X-th byte of K3
 STA K3,X

 DEX                    \ Decrement the counter

 BPL TAL1               \ Loop back until we have copied all 9 bytes

.TA19

                        \ If this is a missile that's heading for its target
                        \ (not us, one of the other ships), then the missile
                        \ routine at TA18 above jumps here after setting K3 to
                        \ the vector from the target to the missile

 JSR TAS2               \ Normalise the vector in K3 and store the normalised
                        \ version in XX15, so XX15 contains the normalised
                        \ vector from our ship to the ship we are applying AI
                        \ tactics to (or the normalised vector from the target
                        \ to the missile - in both cases it's the vector from
                        \ the potential victim to the attacker)

 LDY #10                \ Set (A X) = nosev . XX15
 JSR TAS3

 STA CNT                \ Store the high byte of the dot product in CNT. The
                        \ bigger the value, the more aligned the two ships are,
                        \ with a maximum magnitude of 36 (96 * 96 >> 8). If CNT
                        \ is positive, the ships are facing in a similar
                        \ direction, if it's negative they are facing in
                        \ opposite directions

\ ******************************************************************************
\
\       Name: TACTICS (Part 4 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Check energy levels, maybe launch escape pod if low
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section works out what kind of condition the ship is in. Specifically:
\
\   * Rarely (2.5% chance) roll the ship by a noticeable amount
\
\   * If the ship has at least half its energy banks full, jump to part 6 to
\     consider firing the lasers
\
\   * If the ship is not into the last 1/8th of its energy, jump to part 5 to
\     consider firing a missile
\
\   * If the ship is into the last 1/8th of its energy, then rarely (10% chance)
\     the ship launches an escape pod and is left drifting in space
\
\ ******************************************************************************

 LDA TYPE               \ If this is not a missile, skip the following
 CMP #MSL               \ instruction
 BNE P%+5

 JMP TA20               \ This is a missile, so jump down to TA20 to get
                        \ straight into some aggressive manoeuvring

 JSR DORND              \ Set A and X to random numbers

 CMP #250               \ If A < 250 (97.5% chance), jump down to TA7 to skip
 BCC TA7                \ the following

 JSR DORND              \ Set A and X to random numbers

 ORA #104               \ Bump A up to at least 104 and store in the roll
 STA INWK+29            \ counter, to gives the ship a noticeable roll

.TA7

 LDY #14                \ Set A = the ship's maximum energy / 2
 LDA (XX0),Y
 LSR A

 CMP INWK+35            \ If the ship's current energy in byte #35 > A, i.e. the
 BCC TA3                \ ship has at least half of its energy banks charged,
                        \ jump down to TA3

 LSR A                  \ If the ship's current energy in byte #35 > A / 4, i.e.
 LSR A                  \ the ship is not into the last 1/8th of its energy,
 CMP INWK+35            \ jump down to ta3 to consider firing a missile
 BCC ta3

 JSR DORND              \ Set A and X to random numbers

 CMP #230               \ If A < 230 (90% chance), jump down to ta3 to consider
 BCC ta3                \ firing a missile

 LDA TYPE               \ If this is a Thargoid, jump down to ta3 to consider
 CMP #THG               \ launching a Thargon
 BEQ ta3

                        \ By this point, the ship has run out of both energy and
                        \ luck, so it's time to bail

 LDA #0                 \ Set the AI flag to 0 to disable AI, hostility and
 STA INWK+32            \ E.C.M., so the ship's a sitting duck

 JMP SESCP              \ Jump to SESCP to spawn an escape pod from the ship,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TACTICS (Part 5 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Consider whether to launch a missile at us
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section considers whether to launch a missile. Specifically:
\
\   * If the ship doesn't have any missiles, skip to the next part
\
\   * If an E.C.M. is firing, skip to the next part
\
\   * Randomly decide whether to fire a missile (or, in the case of Thargoids,
\     release a Thargon), and if we do, we're done
\
\ ******************************************************************************

.ta3

                        \ If we get here then the ship has less than half energy
                        \ so there may not be enough juice for lasers, but let's
                        \ see if we can fire a missile

 LDA INWK+31            \ Set A = bits 0-2 of byte #31, the number of missiles
 AND #%00000111         \ the ship has left

 BEQ TA3                \ If it doesn't have any missiles, jump to TA3

 STA T                  \ Store the number of missiles in T

 JSR DORND              \ Set A and X to random numbers

 AND #31                \ Restrict A to a random number in the range 0-31

 CMP T                  \ If A >= T, which is quite likely, though less likely
 BCS TA3                \ with higher numbers of missiles, jump to TA3 to skip
                        \ firing a missile

 LDA ECMA               \ If an E.C.M. is currently active (either our's or an
 BNE TA3                \ opponent's), jump to TA3 to skip firing a missile

 DEC INWK+31            \ We're done with the checks, so it's time to fire off a
                        \ missile, so reduce the missile count in byte #31 by 1

 LDA TYPE               \ Fetch the ship type into A

 CMP #THG               \ If this is not a Thargoid, jump down to TA16 to launch
 BNE TA16               \ a missile

 LDX #TGL               \ This is a Thargoid, so instead of launching a missile,
 LDA INWK+32            \ the mothership launches a Thargon, so call SFS1 to
 JMP SFS1               \ spawn a Thargon from the parent ship, and return from
                        \ the subroutine using a tail call

.TA16

 JMP SFRMIS             \ Jump to SFRMIS to spawn a missile as a child of the
                        \ current ship, make a noise and print a message warning
                        \ of incoming missiles, and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TACTICS (Part 6 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Consider firing a laser at us, if aim is true
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section looks at potentially firing the ship's laser at us. Specifically:
\
\   * If the ship is not pointing at us, skip to the next part
\
\   * If the ship is pointing at us but not accurately, fire its laser at us and
\     skip to the next part
\
\   * If we are in the ship's crosshairs, register some damage to our ship, slow
\     down the attacking ship, make the noise of us being hit by laser fire, and
\     we're done
\
\ ******************************************************************************

.TA3

                        \ If we get here then the ship either has plenty of
                        \ energy, or levels are low but it couldn't manage to
                        \ launch a missile, so maybe we can fire the laser?

 LDA #0                 \ Set A to x_hi OR y_hi OR z_hi
 JSR MAS4

 AND #%11100000         \ If any of the hi bytes have any of bits 5-7 set, then
 BNE TA4                \ jump to TA4 to skip the laser checks, as the ship is
                        \ too far away from us to hit us with a laser

 LDX CNT                \ Set X = the dot product set above in CNT. If this is
                        \ positive, this ship and our ship are facing in similar
                        \ directions, but if it's negative then we are facing
                        \ each other, so for us to be in the enemy ship's line
                        \ of fire, X needs to be negative. The value in X can
                        \ have a maximum magnitude of 36, which would mean we
                        \ were facing each other square on, so in the following
                        \ code we check X like this:
                        \
                        \   X = 0 to -31, we are not in the enemy ship's line
                        \       of fire, so they can't shoot at us
                        \
                        \   X = -32 to -34, we are in the enemy ship's line
                        \       of fire, so they can shoot at us, but they can't
                        \       hit us as we're not dead in their crosshairs
                        \
                        \   X = -35 to -36, we are bang in the middle of the
                        \       enemy ship's crosshairs, so they can not only
                        \       shoot us, they can hit us

 CPX #160               \ If X < 160, i.e. X > -32, then we are not in the enemy
 BCC TA4                \ ship's line of fire, so jump to TA4 to skip the laser
                        \ checks

 LDA INWK+31            \ Set bit 6 in byte #31 to denote that the ship is
 ORA #%01000000         \ firing its laser at us
 STA INWK+31

 CPX #163               \ If X < 163, i.e. X > -35, then we are not in the enemy
 BCC TA4                \ ship's crosshairs, so jump to TA4 to skip the laser

.HIT

 LDY #19                \ We are being hit by enemy laser fire, so fetch the
 LDA (XX0),Y            \ enemy ship's byte #19 from their ship's blueprint
                        \ into A

 LSR A                  \ Halve the enemy ship's byte #19 (which contains both
                        \ the laser power and number of missiles) to get the
                        \ amount of damage we should take

 JSR OOPS               \ Call OOPS to take some damage, which could do anything
                        \ from reducing the shields and energy, all the way to
                        \ losing cargo or dying (if the latter, we don't come
                        \ back from this subroutine)

 DEC INWK+28            \ Halve the attacking ship's acceleration in byte #28

 LDA ECMA               \ If an E.C.M. is currently active (either our's or an
 BNE TA10               \ opponent's), return from the subroutine without making
                        \ the laser-strike sound (as TA10 contains an RTS)

 LDA #8                 \ Call the NOISE routine with A = 8 to make the sound
 JMP NOISE              \ of us being hit by lasers, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TACTICS (Part 7 of 7)
\       Type: Subroutine
\   Category: Tactics
\    Summary: Apply tactics: Set pitch, roll, and acceleration
\  Deep dive: Program flow of the tactics routine
\
\ ------------------------------------------------------------------------------
\
\ This section looks at manoeuvring the ship. Specifically:
\
\   * Work out which direction the ship should be moving, depending on whether
\     it's an escape pod, where it is, which direction it is pointing, and how
\     aggressive it is
\
\   * Set the pitch and roll counters to head in that direction
\
\   * Speed up or slow down, depending on where the ship is in relation to us
\
\ ******************************************************************************

.TA4

 LDA INWK+7             \ If z_hi >= 3 then the ship is quite far away, so jump
 CMP #3                 \ down to TA5
 BCS TA5

 LDA INWK+1             \ Otherwise set A = x_hi OR y_hi and extract bits 1-7
 ORA INWK+4
 AND #%11111110

 BEQ TA15               \ If A = 0 then the ship is pretty close to us, so jump
                        \ to TA15 so it heads away from us

.TA5

                        \ If we get here then the ship is quite far away

 JSR DORND              \ Set A and X to random numbers

 ORA #%10000000         \ Set bit 7 of A

 CMP INWK+32            \ If A >= byte #32 (the ship's AI flag) then jump down
 BCS TA15               \ to TA15 so it heads away from us

                        \ We get here if A < byte #32, and the chances of this
                        \ being true are greater with high values of byte #32.
                        \ In other words, higher byte #32 values increase the
                        \ chances of a ship changing direction to head towards
                        \ us - or, to put it another way, ships with higher
                        \ byte #32 values are spoiling for a fight. Thargoids
                        \ have byte #32 set to 255, which explains an awful lot

.TA20

                        \ If this is a missile we will have jumped straight
                        \ here, but we also get here if the ship is either far
                        \ away and aggressive, or not too close

 LDA XX15               \ Reverse the signs of XX15 and the dot product in CNT,
 EOR #%10000000         \ starting with the x-coordinate
 STA XX15

 LDA XX15+1             \ Then reverse the sign of the y-coordinate
 EOR #%10000000
 STA XX15+1

 LDA XX15+2             \ And then the z-coordinate, so now the XX15 vector goes
 EOR #%10000000         \ from the enemy ship to our ship (it was previously the
 STA XX15+2             \ other way round)

 LDA CNT                \ And finally change the sign of the dot product in CNT,
 EOR #%10000000         \ so now it's positive if the ships are facing each
 STA CNT                \ other, and negative if they are facing the same way

.TA15

                        \ If we get here, then one of the following is true:
                        \
                        \   * This is an escape pod and XX15 is pointing towards
                        \     the planet
                        \
                        \   * The ship is pretty close to us, or it's just not
                        \     very aggressive (though there is a random factor
                        \     at play here too). XX15 is still pointing from our
                        \     ship towards the enemy ship
                        \
                        \   * The ship is aggressive (though again, there's an
                        \     element of randomness here). XX15 is pointing from
                        \     the enemy ship towards our ship
                        \
                        \   * This is a missile heading for a target. XX15 is
                        \     pointing from the missile towards the target
                        \
                        \ We now want to move the ship in the direction of XX15,
                        \ which will make aggressive ships head towards us, and
                        \ ships that are too close turn away. Escape pods,
                        \ meanwhile, head off towards the planet in search of a
                        \ space station, and missiles home in on their targets

 LDY #16                \ Set (A X) = roofv . XX15
 JSR TAS3               \
                        \ This will be positive if XX15 is pointing in the same
                        \ direction as an arrow out of the top of the ship, in
                        \ other words if the ship should pull up to head in the
                        \ direction of XX15

 EOR #%10000000         \ Set the ship's pitch counter to 3, with the opposite
 AND #%10000000         \ sign to the dot product result, which gently pitches
 ORA #%00000011         \ the ship towards the direction of the XX15 vector
 STA INWK+30

 LDA INWK+29            \ Fetch the roll counter from byte #29 into A and clear
 AND #%01111111         \ the sign bit

 CMP #16                \ If A >= 16 then jump to TA6, as the ship is already
 BCS TA6                \ in the process of rolling

 LDY #22                \ Set (A X) = sidev . XX15
 JSR TAS3               \
                        \ This will be positive if XX15 is pointing in the same
                        \ direction as an arrow out of the right side of the
                        \ ship, in other words if the ship should roll right to
                        \ head in the direction of XX15

 EOR INWK+30            \ Set the ship's roll counter to 5, with the sign set to
 AND #%10000000         \ positive if the pitch counter and dot product have
 EOR #%10000101         \ different signs, negative if they have the same sign
 STA INWK+29

.TA6

 LDA CNT                \ Fetch the dot product, and if it's negative jump to
 BMI TA9                \ TA9, as the ships are facing away from each other and
                        \ the ship might want to slow down to take another shot

 CMP #22                \ The dot product is positive, so the ships are facing
 BCC TA9                \ each other. If A < 22 then the ships are not heading
                        \ directly towards each other, so jump to TA9 to slow
                        \ down

 LDA #3                 \ Otherwise set the acceleration in byte #28 to 3
 STA INWK+28

 RTS                    \ Return from the subroutine

.TA9

 AND #%01111111         \ Clear the sign bit of the dot product in A

 CMP #18                \ If A < 18 then the ship is way off the XX15 vector, so
 BCC TA10               \ return from the subroutine (TA10 contains an RTS)
                        \ without slowing down, as it still has quite a bit of
                        \ turning to do to get on course

 LDA #&FF               \ Otherwise set A = -1

 LDX TYPE               \ If this is not a missile then skip the ASL instruction
 CPX #MSL
 BNE P%+3

 ASL A                  \ This is a missile, so set A = -2, as missiles are more
                        \ nimble and can brake more quickly

 STA INWK+28            \ Set the ship's acceleration to A

.TA10

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TAS1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate K3 = (x_sign x_hi x_lo) - V(1 0)
\
\ ------------------------------------------------------------------------------
\
\ Calculate one of the following, depending on the value in Y:
\
\   K3(2 1 0) = (x_sign x_hi x_lo) - x-coordinate in V(1 0)
\
\   K3(5 4 3) = (y_sign y_hi z_lo) - y-coordinate in V(1 0)
\
\   K3(8 7 6) = (z_sign z_hi z_lo) - z-coordinate in V(1 0)
\
\ where the first coordinate is from the ship data block in INWK, and the second
\ coordinate is from the ship data block pointed to by V(1 0).
\
\ Arguments:
\
\   V(1 0)              The address of the ship data block to subtract
\
\   Y                   The coordinate in the V(1 0) block to subtract:
\
\                         * If Y = 2, subtract the x-coordinate and store the
\                           result in K3(2 1 0)
\
\                         * If Y = 5, subtract the y-coordinate and store the
\                           result in K3(5 4 3)
\
\                         * If Y = 8, subtract the z-coordinate and store the
\                           result in K3(8 7 6)
\
\ ******************************************************************************

.TAS1

 LDA (V),Y              \ Copy the sign byte of the V(1 0) coordinate into K+3,
 EOR #%10000000         \ flipping it in the process
 STA K+3

 DEY                    \ Copy the high byte of the V(1 0) coordinate into K+2
 LDA (V),Y
 STA K+2

 DEY                    \ Copy the high byte of the V(1 0) coordinate into K+1,
 LDA (V),Y              \ so now:
 STA K+1                \
                        \   K(3 2 1) = - coordinate in V(1 0)

 STY U                  \ Copy the index (now 0, 3 or 6) into U and X
 LDX U

 JSR MVT3               \ Call MVT3 to add the same coordinates, but this time
                        \ from INWK, so this would look like this for the
                        \ x-axis:
                        \
                        \   K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)
                        \            = (x_sign x_hi x_lo) - coordinate in V(1 0)

 LDY U                  \ Restore the index into Y, though this instruction has
                        \ no effect, as Y is not used again, either here or
                        \ following calls to this routine

 STA K3+2,X             \ Store K(3 2 1) in K3+X(2 1 0), starting with the sign
                        \ byte

 LDA K+2                \ And then doing the high byte
 STA K3+1,X

 LDA K+1                \ And finally the low byte
 STA K3,X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: HITCH
\       Type: Subroutine
\   Category: Tactics
\    Summary: Work out if the ship in INWK is in our crosshairs
\  Deep dive: In the crosshairs
\
\ ------------------------------------------------------------------------------
\
\ This is called by the main flight loop to see if we have laser or missile lock
\ on an enemy ship.
\
\ Returns:
\
\   C flag              Set if the ship is in our crosshairs, clear if it isn't
\
\ Other entry points:
\
\   HI1                 Contains an RTS
\
\ ******************************************************************************

.HITCH

 CLC                    \ Clear the C flag so we can return with it cleared if
                        \ our checks fail

 LDA INWK+8             \ Set A = z_sign

 BNE HI1                \ If A is non-zero then the ship is behind us and can't
                        \ be in our crosshairs, so return from the subroutine
                        \ with the C flag clear (as HI1 contains an RTS)

 LDA TYPE               \ If the ship type has bit 7 set then it is the planet
 BMI HI1                \ or sun, which we can't target or hit with lasers, so
                        \ return from the subroutine with the C flag clear (as
                        \ HI1 contains an RTS)

 LDA INWK+31            \ Fetch bit 5 of byte #31 (the exploding flag) and OR
 AND #%00100000         \ with x_hi and y_hi
 ORA INWK+1
 ORA INWK+4

 BNE HI1                \ If this value is non-zero then either the ship is
                        \ exploding (so we can't target it), or the ship is too
                        \ far away from our line of fire to be targeted, so
                        \ return from the subroutine with the C flag clear (as
                        \ HI1 contains an RTS)

 LDA INWK               \ Set A = x_lo

 JSR SQUA2              \ Set (A P) = A * A = x_lo^2

 STA S                  \ Set (S R) = (A P) = x_lo^2
 LDA P
 STA R

 LDA INWK+3             \ Set A = y_lo

 JSR SQUA2              \ Set (A P) = A * A = y_lo^2

 TAX                    \ Store the high byte in X

 LDA P                  \ Add the two low bytes, so:
 ADC R                  \
 STA R                  \   R = P + R

 TXA                    \ Restore the high byte into A and add S to give the
 ADC S                  \ following:
                        \
                        \   (A R) = (S R) + (A P) = x_lo^2 + y_lo^2

 BCS FR1-2              \ If the addition just overflowed then there is no way
                        \ our crosshairs are within the ship's targetable area,
                        \ so return from the subroutine with the C flag clear
                        \ (as FR1-2 contains a CLC then an RTS)

 STA S                  \ Set (S R) = (A P) = x_lo^2 + y_lo^2

 LDY #2                 \ Fetch the ship's blueprint and set A to the high byte
 LDA (XX0),Y            \ of the targetable area of the ship

 CMP S                  \ We now compare the high bytes of the targetable area
                        \ and the calculation in (S R):
                        \
                        \   * If A >= S then then the C flag will be set
                        \
                        \   * If A < S then the C flag will be C clear

 BNE HI1                \ If A <> S we have just set the C flag correctly, so
                        \ return from the subroutine (as HI1 contains an RTS)

 DEY                    \ The high bytes were identical, so now we fetch the
 LDA (XX0),Y            \ low byte of the targetable area into A

 CMP R                  \ We now compare the low bytes of the targetable area
                        \ and the calculation in (S R):
                        \
                        \   * If A >= R then the C flag will be set
                        \
                        \   * If A < R then the C flag will be C clear

.HI1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FRS1
\       Type: Subroutine
\   Category: Tactics
\    Summary: Launch a ship straight ahead of us, below the laser sights
\
\ ------------------------------------------------------------------------------
\
\ This is used in two places:
\
\   * When we launch a missile, in which case the missile is the ship that is
\     launched ahead of us
\
\   * When we launch our escape pod, in which case it's our abandoned Cobra Mk
\     III that is launched ahead of us
\
\   * The fq1 entry point is used to launch a bunch of cargo canisters ahead of
\     us as part of the death screen
\
\ Arguments:
\
\   X                   The type of ship to launch ahead of us
\
\ Returns:
\
\   C flag              Set if the ship was successfully launched, clear if it
\                       wasn't (as there wasn't enough free memory)
\
\ Other entry points:
\
\   fq1                 Used to add a cargo canister to the universe
\
\ ******************************************************************************

.FRS1

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

 LDA #28                \ Set y_lo = 28
 STA INWK+3

 LSR A                  \ Set z_lo = 14, so the launched ship starts out
 STA INWK+6             \ ahead of us

 LDA #%10000000         \ Set y_sign to be negative, so the launched ship is
 STA INWK+5             \ launched just below our line of sight

 LDA MSTG               \ Set A to the missile lock target, shifted left so the
 ASL A                  \ slot number is in bits 1-4

 ORA #%10000000         \ Set bit 7 and store the result in byte #32, the AI
 STA INWK+32            \ flag launched ship for the launched ship. For missiles
                        \ this enables AI (bit 7), makes it friendly towards us
                        \ (bit 6), sets the target to the value of MSTG (bits
                        \ 1-4), and sets its lock status as launched (bit 0).
                        \ It doesn't matter what it does for our abandoned
                        \ Cobra, as the AI flag gets overwritten once we return
                        \ from the subroutine back to the ESCAPE routine that
                        \ called FRS1 in the first place

.fq1

 LDA #&60               \ Set byte #14 (nosev_z_hi) to 1 (&60), so the launched
 STA INWK+14            \ ship is pointing away from us

 ORA #128               \ Set byte #22 (sidev_x_hi) to -1 (&D0), so the launched
 STA INWK+22            \ ship has the same orientation as spawned ships, just
                        \ pointing away from us (if we set sidev to +1 instead,
                        \ this ship would be a mirror image of all the other
                        \ ships, which are spawned with -1 in nosev and +1 in
                        \ sidev)

 LDA DELTA              \ Set byte #27 (speed) to 2 * DELTA, so the launched
 ROL A                  \ ship flies off at twice our speed
 STA INWK+27

 TXA                    \ Add a new ship of type X to our local bubble of
 JMP NWSHP              \ universe and return from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: FRMIS
\       Type: Subroutine
\   Category: Tactics
\    Summary: Fire a missile from our ship
\
\ ------------------------------------------------------------------------------
\
\ We fired a missile, so send it streaking away from us to unleash mayhem and
\ destruction on our sworn enemies.
\
\ ******************************************************************************

.FRMIS

 LDX #MSL               \ Call FRS1 to launch a missile straight ahead of us
 JSR FRS1

 BCC FR1                \ If FRS1 returns with the C flag clear, then there
                        \ isn't room in the universe for our missile, so jump
                        \ down to FR1 to display a "missile jammed" message

 LDX MSTG               \ Fetch the slot number of the missile's target

 JSR GINF               \ Get the address of the data block for the target ship
                        \ and store it in INF

 LDA FRIN,X             \ Fetch the ship type of the missile's target into A

 JSR ANGRY              \ Call ANGRY to make the target ship hostile

 LDY #0                 \ We have just launched a missile, so we need to remove
 JSR ABORT              \ missile lock and hide the leftmost indicator on the
                        \ dashboard by setting it to black (Y = 0)

 DEC NOMSL              \ Reduce the number of missiles we have by 1

 LDA #48                \ Call the NOISE routine with A = 48 to make the sound
 JMP NOISE              \ of a missile launch, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: ANGRY
\       Type: Subroutine
\   Category: Tactics
\    Summary: Make a ship hostile
\
\ ------------------------------------------------------------------------------
\
\ All this routine does is set the ship's hostile flag, start it turning and
\ give it a kick of acceleration - later calls to TACTICS will make the ship
\ start to attack us.
\
\ Arguments:
\
\   A                   The type of ship we're going to irritate
\
\   INF                 The address of the data block for the ship we're going
\                       to infuriate
\
\ ******************************************************************************

.ANGRY

 CMP #SST               \ If this is the space station, jump to AN2 to make the
 BEQ AN2                \ space station hostile

 BCS HI1                \ If A >= #SST then this is a missile, asteroid, cargo
                        \ canister, Thargon or escape pod, and they can't get
                        \ hostile, so return from the subroutine (as HI1
                        \ contains an RTS)

 CMP #CYL               \ If this is not a Cobra Mk III trader, skip the
 BNE P%+5               \ following instruction

 JSR AN2                \ Call AN2 to make the space station hostile

 LDY #32                \ Fetch the ship's byte #32 (AI flag)
 LDA (INF),Y

 BEQ HI1                \ If the AI flag is zero then this ship has no AI and
                        \ it can't get hostile, so return from the subroutine
                        \ (as HI1 contains an RTS)

 ORA #%10000000         \ Otherwise set bit 7 (AI enabled) to ensure AI is
 STA (INF),Y            \ definitely enabled

 LDY #28                \ Set the ship's byte #28 (acceleration) to 2, so it
 LDA #2                 \ speeds up
 STA (INF),Y

 ASL A                  \ Set the ship's byte #30 (pitch counter) to 4, so it
 LDY #30                \ starts pitching
 STA (INF),Y

 RTS                    \ Return from the subroutine

.AN2

 ASL K%+NI%+32          \ Fetch the AI counter (byte #32) of the second ship
 SEC                    \ in the ship data workspace at K%, which is reserved
 ROR K%+NI%+32          \ for the sun or the space station (in this case it's
                        \ the latter), and set bit 7 to make it hostile

 CLC                    \ Clear the C flag, which isn't used by calls to this
                        \ routine, but it does set up the entry point FR1-2
                        \ so that it clears the C flag and does an RTS

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FR1
\       Type: Subroutine
\   Category: Tactics
\    Summary: Display the "missile jammed" message
\
\ ------------------------------------------------------------------------------
\
\ This is shown if there isn't room in the local bubble of universe for a new
\ missile.
\
\ Other entry points:
\
\   FR1-2               Clear the C flag and return from the subroutine
\
\ ******************************************************************************

.FR1

 LDA #201               \ Print recursive token 41 ("MISSILE JAMMED") as an
 JMP MESS               \ in-flight message and return from the subroutine using
                        \ a tail call

\ ******************************************************************************
\
\       Name: SESCP
\       Type: Subroutine
\   Category: Flight
\    Summary: Spawn an escape pod from the current (parent) ship
\
\ ------------------------------------------------------------------------------
\
\ This is called when an enemy ship has run out of both energy and luck, so it's
\ time to bail.
\
\ ******************************************************************************

.SESCP

 LDX #ESC               \ Set X to the ship type for an escape pod

 LDA #%11111110         \ Set A to an AI flag that has AI enabled, is hostile,
                        \ but has no E.C.M.

                        \ Fall through into SFS1 to spawn the escape pod

\ ******************************************************************************
\
\       Name: SFS1
\       Type: Subroutine
\   Category: Universe
\    Summary: Spawn a child ship from the current (parent) ship
\
\ ------------------------------------------------------------------------------
\
\ If the parent is a space station then the child ship is spawned coming out of
\ the slot, and if the child is a cargo canister, it is sent tumbling through
\ space. Otherwise the child ship is spawned with the same ship data as the
\ parent, just with damping disabled and the ship type and AI flag that are
\ passed in A and X.
\
\ Arguments:
\
\   A                   AI flag for the new ship (see the documentation on ship
\                       data byte #32 for details)
\
\   X                   The ship type of the child to spawn
\
\   INF                 Address of the parent's ship data block
\
\   TYPE                The type of the parent ship
\
\ Returns:
\
\   C flag              Set if ship successfully added, clear if it failed
\
\   INF                 INF is preserved
\
\   XX0                 XX0 is preserved
\
\   INWK                The whole INWK workspace is preserved
\
\ Other entry points:
\
\   SFS1-2              Add a missile to the local bubble that has AI enabled,
\                       is hostile, but has no E.C.M.
\
\ ******************************************************************************

.SFS1

 STA T1                 \ Store the child ship's AI flag in T1

                        \ Before spawning our child ship, we need to save the
                        \ INF and XX00 variables and the whole INWK workspace,
                        \ so we can restore them later when returning from the
                        \ subroutine

 LDA XX0                \ Store XX0(1 0) on the stack, so we can restore it
 PHA                    \ later when returning from the subroutine
 LDA XX0+1
 PHA

 LDA INF                \ Store INF(1 0) on the stack, so we can restore it
 PHA                    \ later when returning from the subroutine
 LDA INF+1
 PHA

 LDY #NI%-1             \ Now we want to store the current INWK data block in
                        \ temporary memory so we can restore it when we are
                        \ done, and we also want to copy the parent's ship data
                        \ into INWK, which we can do at the same time, so set up
                        \ a counter in Y for NI% bytes

.FRL2

 LDA INWK,Y             \ Copy the Y-th byte of INWK to the Y-th byte of
 STA XX3,Y              \ temporary memory in XX3, so we can restore it later
                        \ when returning from the subroutine

 LDA (INF),Y            \ Copy the Y-th byte of the parent ship's data block to
 STA INWK,Y             \ the Y-th byte of INWK

 DEY                    \ Decrement the loop counter

 BPL FRL2               \ Loop back to copy the next byte until we have done
                        \ them all

                        \ INWK now contains the ship data for the parent ship,
                        \ so now we need to tweak the data before creating the
                        \ new child ship (in this way, the child inherits things
                        \ like location from the parent)

 LDA TYPE               \ Fetch the ship type of the parent into A

 CMP #SST               \ If the parent is not a space station, jump to rx to
 BNE rx                 \ skip the following

                        \ The parent is a space station, so the child needs to
                        \ launch out of the space station's slot. The space
                        \ station's nosev vector points out of the station's
                        \ slot, so we want to move the ship along this vector.
                        \ We do this by taking the unit vector in nosev and
                        \ doubling it, so we spawn our ship 2 units along the
                        \ vector from the space station's centre

 TXA                    \ Store the child's ship type in X on the stack
 PHA

 LDA #32                \ Set the child's byte #27 (speed) to 32
 STA INWK+27

 LDX #0                 \ Add 2 * nosev_x_hi to (x_lo, x_hi, x_sign) to get the
 LDA INWK+10            \ child's x-coordinate
 JSR SFS2

 LDX #3                 \ Add 2 * nosev_y_hi to (y_lo, y_hi, y_sign) to get the
 LDA INWK+12            \ child's y-coordinate
 JSR SFS2

 LDX #6                 \ Add 2 * nosev_z_hi to (z_lo, z_hi, z_sign) to get the
 LDA INWK+14            \ child's z-coordinate
 JSR SFS2

 PLA                    \ Restore the child's ship type from the stack into X
 TAX

.rx

 LDA T1                 \ Restore the child ship's AI flag from T1 and store it
 STA INWK+32            \ in the child's byte #32 (AI)

 LSR INWK+29            \ Clear bit 0 of the child's byte #29 (roll counter) so
 ASL INWK+29            \ that its roll dampens (so if we are spawning from a
                        \ space station, for example, the spawned ship won't
                        \ keep rolling forever)

 TXA                    \ Copy the child's ship type from X into A

 CMP #OIL               \ If the child we are spawning is not a cargo canister,
 BNE NOIL               \ jump to NOIL to skip us setting up the pitch and roll
                        \ for the canister

 JSR DORND              \ Set A and X to random numbers

 ASL A                  \ Set the child's byte #30 (pitch counter) to a random
 STA INWK+30            \ value, and at the same time set the C flag randomly

 TXA                    \ Set the child's byte #27 (speed) to a random value
 AND #%00001111         \ between 0 and 15
 STA INWK+27

 LDA #&FF               \ Set the child's byte #29 (roll counter) to a full
 ROR A                  \ roll, so the canister tumbles through space, with
 STA INWK+29            \ damping randomly enabled or disabled, depending on the
                        \ C flag from above

 LDA #OIL               \ Set A to the ship type of a cargo canister

.NOIL

 JSR NWSHP              \ Add a new ship of type A to the local bubble

                        \ We have now created our child ship, so we need to
                        \ restore all the variables we saved at the start of
                        \ the routine, so they are preserved when we return
                        \ from the subroutine

 PLA                    \ Restore INF(1 0) from the stack
 STA INF+1
 PLA
 STA INF

 LDX #NI%-1             \ Now to restore the INWK workspace that we saved into
                        \ XX3 above, so set a counter in X for NI% bytes

.FRL3

 LDA XX3,X              \ Copy the Y-th byte of XX3 to the Y-th byte of INWK
 STA INWK,X

 DEX                    \ Decrement the loop counter

 BPL FRL3               \ Loop back to copy the next byte until we have done
                        \ them all

 PLA                    \ Restore XX0(1 0) from the stack
 STA XX0+1
 PLA
 STA XX0

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SFS2
\       Type: Subroutine
\   Category: Moving
\    Summary: Move a ship in space along one of the coordinate axes
\
\ ------------------------------------------------------------------------------
\
\ Move a ship's coordinates by a certain amount in the direction of one of the
\ axes, where X determines the axis. Mathematically speaking, this routine
\ translates the ship along a single axis by a signed delta.
\
\ Arguments:
\
\   A                   The amount of movement, i.e. the signed delta
\
\   X                   Determines which coordinate axis of INWK to move:
\
\                         * X = 0 moves the ship along the x-axis
\
\                         * X = 3 moves the ship along the y-axis
\
\                         * X = 6 moves the ship along the z-axis
\
\ ******************************************************************************

.SFS2

 ASL A                  \ Set R = |A * 2|, with the C flag set to bit 7 of A
 STA R

 LDA #0                 \ Set bit 7 of A to the C flag, i.e. the sign bit from
 ROR A                  \ the original argument in A

 JMP MVT1               \ Add the delta R with sign A to (x_lo, x_hi, x_sign)
                        \ (or y or z, depending on the value in X) and return
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: LL164
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Make the hyperspace sound and draw the hyperspace tunnel
\
\ ------------------------------------------------------------------------------
\
\ See the IRQ1 routine for details on the multi-coloured effect that's used.
\
\ ******************************************************************************

.LL164

 LDA #56                \ Call the NOISE routine with A = 56 to make the sound
 JSR NOISE              \ of the hyperspace drive being engaged

 LDA #1                 \ Set HFX to 1, which switches the screen mode to a full
 STA HFX                \ mode 5 screen, therefore making the hyperspace rings
                        \ multi-coloured and all zig-zaggy (see the IRQ1 routine
                        \ for details)

 LDA #4                 \ Set the step size for the hyperspace rings to 4, so
                        \ there are more sections in the rings and they are
                        \ quite round (compared to the step size of 8 used in
                        \ the much more polygonal launch rings)

 JSR HFS2               \ Call HFS2 to draw the hyperspace tunnel rings

 DEC HFX                \ Set HFX back to 0, so we switch back to the normal
                        \ split-screen mode

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LAUN
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Make the launch sound and draw the launch tunnel
\
\ ------------------------------------------------------------------------------
\
\ This is shown when launching from or docking with the space station.
\
\ ******************************************************************************

.LAUN

 LDA #48                \ Call the NOISE routine with A = 48 to make the sound
 JSR NOISE              \ of the ship launching from the station

 LDA #8                 \ Set the step size for the launch tunnel rings to 8, so
                        \ there are fewer sections in the rings and they are
                        \ quite polygonal (compared to the step size of 4 used
                        \ in the much rounder hyperspace rings)

                        \ Fall through into HFS2 to draw the launch tunnel rings

\ ******************************************************************************
\
\       Name: HFS2
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw the launch or hyperspace tunnel
\
\ ------------------------------------------------------------------------------
\
\ The animation gets drawn like this. First, we draw a circle of radius 8 at the
\ centre, and then double the radius, draw another circle, double the radius
\ again and draw a circle, and we keep doing this until the radius is bigger
\ than 160 (which goes beyond the edge of the screen, which is 256 pixels wide,
\ equivalent to a radius of 128). We then repeat this whole process for an
\ initial circle of radius 9, then radius 10, all the way up to radius 15.
\
\ This has the effect of making the tunnel appear to be racing towards us as we
\ hurtle out into hyperspace or through the space station's docking tunnel.
\
\ The hyperspace effect is done in a full mode 5 screen, which makes the rings
\ all coloured and zig-zaggy, while the launch screen is in the normal
\ monochrome mode 4 screen.
\
\ Arguments:
\
\   A                   The step size of the straight lines making up the rings
\                       (4 for launch, 8 for hyperspace)
\
\ ******************************************************************************

.HFS2

 STA STP                \ Store the step size in A

 JSR TTX66              \ Clear the screen and draw a white border

 JSR HFS1               \ Call HFS1 below and then fall through into the same
                        \ routine, so this effectively runs HFS1 twice, and as
                        \ HFS1 draws 8 concentric rings, this means we draw 16
                        \ of them in all

.HFS1

 LDA #128               \ Set K3 = 128 (the x-coordinate of the centre of the
 STA K3                 \ screen)

 LDX #Y                 \ Set K4 = #Y (the y-coordinate of the centre of the
 STX K4                 \ screen)

 ASL A                  \ Set A = 0

 STA XX4                \ Set XX4 = 0, which we will use as a counter for
                        \ drawing eight concentric rings

 STA K3+1               \ Set the high bytes of K3(1 0) and K4(1 0) to 0
 STA K4+1

.HFL5

 JSR HFL1               \ Call HFL1 below to draw a set of rings, with each one
                        \ twice the radius of the previous one, until they won't
                        \ fit on-screen

 INC XX4                \ Increment the counter and fetch it into X
 LDX XX4

 CPX #8                 \ If we haven't drawn 8 sets of rings yet, loop back to
 BNE HFL5               \ HFL5 to draw the next ring

 RTS                    \ Return from the subroutine

.HFL1

 LDA XX4                \ Set K to the ring number in XX4 (0-7) + 8, so K has
 AND #7                 \ a value of 8 to 15, which we will use as the starting
 CLC                    \ radius for our next set of rings
 ADC #8
 STA K

.HFL2

 LDA #1                 \ Set LSP = 1 to reset the ball line heap
 STA LSP

 JSR CIRCLE2            \ Call CIRCLE2 to draw a circle with the centre at
                        \ (K3(1 0), K4(1 0)) and radius K

 ASL K                  \ Double the radius in K

 BCS HF8                \ If the radius had a 1 in bit 7 before the above shift,
                        \ then doubling K will means the circle will no longer
                        \ fit on the screen (which is width 256), so jump to
                        \ HF8 to stop drawing circles

 LDA K                  \ If the radius in K <= 160, loop back to HFL2 to draw
 CMP #160               \ another one
 BCC HFL2

.HF8

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: STARS2
\       Type: Subroutine
\   Category: Stardust
\    Summary: Process the stardust for the left or right view
\  Deep dive: Stardust in the side views
\
\ ------------------------------------------------------------------------------
\
\ This moves the stardust sideways according to our speed and which side we are
\ looking out of, and applies our current pitch and roll to each particle of
\ dust, so the stardust moves correctly when we steer our ship.
\
\ Arguments:
\
\   X                   The view to process:
\
\                         * X = 1 for left view
\
\                         * X = 2 for right view
\
\ ******************************************************************************

.STARS2

 LDA #0                 \ Set A to 0 so we can use it to capture a sign bit

 CPX #2                 \ If X >= 2 then the C flag is set

 ROR A                  \ Roll the C flag into the sign bit of A and store in
 STA RAT                \ RAT, so:
                        \
                        \   * Left view, C is clear so RAT = 0 (positive)
                        \
                        \   * Right view, C is set so RAT = 128 (negative)
                        \
                        \ RAT represents the end of the x-axis where we want new
                        \ stardust particles to come from: positive for the left
                        \ view where new particles come in from the right,
                        \ negative for the right view where new particles come
                        \ in from the left

 EOR #%10000000         \ Set RAT2 to the opposite sign, so:
 STA RAT2               \
                        \   * Left view, RAT2 = 128 (negative)
                        \
                        \   * Right view, RAT2 = 0 (positive)
                        \
                        \ RAT2 represents the direction in which stardust
                        \ particles should move along the x-axis: negative for
                        \ the left view where particles go from right to left,
                        \ positive for the right view where particles go from
                        \ left to right

 JSR ST2                \ Call ST2 to flip the signs of the following if this is
                        \ the right view: ALPHA, ALP2, ALP2+1, BET2 and BET2+1

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

.STL2

 LDA SZ,Y               \ Set A = ZZ = z_hi

 STA ZZ                 \ We also set ZZ to the original value of z_hi, which we
                        \ use below to remove the existing particle

 LSR A                  \ Set A = z_hi / 8
 LSR A
 LSR A

 JSR DV41               \ Call DV41 to set the following:
                        \
                        \   (P R) = 256 * DELTA / A
                        \         = 256 * speed / (z_hi / 8)
                        \         = 8 * 256 * speed / z_hi
                        \
                        \ This represents the distance we should move this
                        \ particle along the x-axis, let's call it delta_x

 LDA P                  \ Set S = P but with the sign from RAT2, so we now have
 EOR RAT2               \ the distance delta_x with the correct sign in (S R):
 STA S                  \
                        \   (S R) = delta_x
                        \         = 8 * 256 * speed / z_hi
                        \
                        \ So (S R) is the delta, signed to match the direction
                        \ the stardust should move in, which is result 1 above

 LDA SXL,Y              \ Set (A P) = (x_hi x_lo)
 STA P                  \           = x
 LDA SX,Y

 STA X1                 \ Set X1 = A, so X1 contains the original value of x_hi,
                        \ which we use below to remove the existing particle

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = x + delta_x

 STA S                  \ Set (S R) = (A X)
 STX R                  \           = x + delta_x

 LDA SY,Y               \ Set A = y_hi

 STA Y1                 \ Set Y1 = A, so Y1 contains the original value of y_hi,
                        \ which we use below to remove the existing particle

 EOR BET2               \ Give A the correct sign of A * beta, i.e. y_hi * beta

 LDX BET1               \ Fetch |beta| from BET1, the pitch angle

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = beta * y_hi

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = beta * y + x + delta_x

 STX XX                 \ Set XX(1 0) = (A X), which gives us results 2 and 3
 STA XX+1               \ above, done at the same time:
                        \
                        \   x = x + delta_x + beta * y

 LDX SYL,Y              \ Set (S R) = (y_hi y_lo)
 STX R                  \           = y
 LDX Y1
 STX S

 LDX BET1               \ Fetch |beta| from BET1, the pitch angle

 EOR BET2+1             \ Give A the opposite sign to x * beta

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = -beta * x

 JSR ADD                \ Call ADD to calculate:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = -beta * x + y

 STX YY                 \ Set YY(1 0) = (A X), which gives us result 4 above:
 STA YY+1               \
                        \   y = y - beta * x

 LDX ALP1               \ Set X = |alpha| from ALP2, the roll angle

 EOR ALP2               \ Give A the correct sign of A * alpha, i.e. y_hi *
                        \ alpha

 JSR MULTS-2            \ Call MULTS-2 to calculate:
                        \
                        \   (A P) = X * A
                        \         = alpha * y

 STA Q                  \ Set Q = high byte of alpha * y

 LDA XX                 \ Set (S R) = XX(1 0)
 STA R                  \           = x
 LDA XX+1               \
 STA S                  \ and set A = y_hi at the same time

 EOR #%10000000         \ Flip the sign of A = -x_hi

 JSR MAD                \ Call MAD to calculate:
                        \
                        \   (A X) = Q * A + (S R)
                        \         = alpha * y * -x + x

 STA XX+1               \ Store the high byte A in XX+1

 TXA
 STA SXL,Y              \ Store the low byte X in x_lo

                        \ So (XX+1 x_lo) now contains result 5 above:
                        \
                        \   x = x - alpha * x * y

 LDA YY                 \ Set (S R) = YY(1 0)
 STA R                  \           = y
 LDA YY+1               \
 STA S                  \ and set A = y_hi at the same time

 JSR MAD                \ Call MAD to calculate:
                        \
                        \   (A X) = Q * A + (S R)
                        \         = alpha * y * y_hi + y

 STA S                  \ Set (S R) = (A X)
 STX R                  \           = y + alpha * y * y

 LDA #0                 \ Set P = 0
 STA P

 LDA ALPHA              \ Set A = alpha, so:
                        \
                        \   (A P) = (alpha 0)
                        \         = alpha / 256

 JSR PIX1               \ Call PIX1 to calculate the following:
                        \
                        \   (YY+1 y_lo) = (A P) + (S R)
                        \               = alpha * 256 + y + alpha * y * y
                        \
                        \ i.e. y = y + alpha / 256 + alpha * y^2, which is
                        \ result 6 above
                        \
                        \ PIX1 also draws a particle at (X1, Y1) with distance
                        \ ZZ, which will remove the old stardust particle, as we
                        \ set X1, Y1 and ZZ to the original values for this
                        \ particle during the calculations above

                        \ We now have our newly moved stardust particle at
                        \ x-coordinate (XX+1 x_lo) and y-coordinate (YY+1 y_lo)
                        \ and distance z_hi, so we draw it if it's still on
                        \ screen, otherwise we recycle it as a new bit of
                        \ stardust and draw that

 LDA XX+1               \ Set X1 and x_hi to the high byte of XX in XX+1, so
 STA SX,Y               \ the new x-coordinate is in (x_hi x_lo) and the high
 STA X1                 \ byte is in X1

 AND #%01111111         \ If |x_hi| >= 116 then jump to KILL2 to recycle this
 CMP #116               \ particle, as it's gone off the side of the screen,
 BCS KILL2              \ and re-join at STC2 with the new particle

 LDA YY+1               \ Set Y1 and y_hi to the high byte of YY in YY+1, so
 STA SY,Y               \ the new x-coordinate is in (y_hi y_lo) and the high
 STA Y1                 \ byte is in Y1

 AND #%01111111         \ If |y_hi| >= 116 then jump to ST5 to recycle this
 CMP #116               \ particle, as it's gone off the top or bottom of the
 BCS ST5                \ screen, and re-join at STC2 with the new particle

.STC2

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ,
                        \ i.e. draw the newly moved particle at (x_hi, y_hi)
                        \ with distance z_hi

 DEY                    \ Decrement the loop counter to point to the next
                        \ stardust particle

 BEQ ST2                \ If we have just done the last particle, skip the next
                        \ instruction to return from the subroutine

 JMP STL2               \ We have more stardust to process, so jump back up to
                        \ STL2 for the next particle

                        \ Fall through into ST2 to restore the signs of the
                        \ following if this is the right view: ALPHA, ALP2,
                        \ ALP2+1, BET2 and BET2+1

.ST2

 LDA ALPHA              \ If this is the right view, flip the sign of ALPHA
 EOR RAT
 STA ALPHA

 LDA ALP2               \ If this is the right view, flip the sign of ALP2
 EOR RAT
 STA ALP2

 EOR #%10000000         \ If this is the right view, flip the sign of ALP2+1
 STA ALP2+1

 LDA BET2               \ If this is the right view, flip the sign of BET2
 EOR RAT
 STA BET2

 EOR #%10000000         \ If this is the right view, flip the sign of BET2+1
 STA BET2+1

 RTS                    \ Return from the subroutine

.KILL2

 JSR DORND              \ Set A and X to random numbers

 STA Y1                 \ Set y_hi and Y1 to random numbers, so the particle
 STA SY,Y               \ starts anywhere along the y-axis

 LDA #115               \ Make sure A is at least 115 and has the sign in RAT
 ORA RAT

 STA X1                 \ Set x_hi and X1 to A, so this particle starts on the
 STA SX,Y               \ correct edge of the screen for new particles

 BNE STF1               \ Jump down to STF1 to set the z-coordinate (this BNE is
                        \ effectively a JMP as A will never be zero)

.ST5

 JSR DORND              \ Set A and X to random numbers

 STA X1                 \ Set x_hi and X1 to random numbers, so the particle
 STA SX,Y               \ starts anywhere along the x-axis

 LDA #110               \ Make sure A is at least 110 and has the sign in AL2+1,
 ORA ALP2+1             \ the flipped sign of the roll angle alpha

 STA Y1                 \ Set y_hi and Y1 to A, so the particle starts at the
 STA SY,Y               \ top or bottom edge, depending on the current roll
                        \ angle alpha

.STF1

 JSR DORND              \ Set A and X to random numbers

 ORA #8                 \ Make sure A is at least 8 and store it in z_hi and
 STA ZZ                 \ ZZ, so the new particle starts at any distance from
 STA SZ,Y               \ us, but not too close

 BNE STC2               \ Jump up to STC2 to draw this new particle (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: SNE
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Sine/cosine table
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ To calculate the following:
\
\   sin(theta) * 256
\
\ where theta is in radians, look up the value in:
\
\   SNE + (theta * 10)
\
\ To calculate the following:
\
\   cos(theta) * 256
\
\ where theta is in radians, look up the value in:
\
\   SNE + ((theta * 10) + 16) mod 32
\
\ Theta must be between 0 and 3.1 radians, so theta * 10 is between 0 and 31.
\
\ ******************************************************************************

.SNE

FOR I%, 0, 31

 N = ABS(SIN((I% / 64) * 2 * PI))

 IF N >= 1
  EQUB 255
 ELSE
  EQUB INT(256 * N + 0.5)
 ENDIF

NEXT

\ ******************************************************************************
\
\       Name: MU5
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set K(3 2 1 0) = (A A A A) and clear the C flGag
\
\ ------------------------------------------------------------------------------
\
\ In practice this is only called via a BEQ following an AND instruction, in
\ which case A = 0, so this routine effectively does this:
\
\   K(3 2 1 0) = 0
\
\ ******************************************************************************

.MU5

 STA K                  \ Set K(3 2 1 0) to (A A A A)
 STA K+1
 STA K+2
 STA K+3

 CLC                    \ Clear the C flag

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MULT3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate K(3 2 1 0) = (A P+1 P) * Q
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following multiplication between a signed 24-bit number and a
\ signed 8-bit number, returning the result as a signed 32-bit number:
\
\   K(3 2 1 0) = (A P+1 P) * Q
\
\ The algorithm is the same shift-and-add algorithm as in routine MULT1, but
\ extended to cope with more bits.
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.MULT3

 STA R                  \ Store the high byte of (A P+1 P) in R

 AND #%01111111         \ Set K+2 to |A|, the high byte of K(2 1 0)
 STA K+2

 LDA Q                  \ Set A to bits 0-6 of Q, so A = |Q|
 AND #%01111111

 BEQ MU5                \ If |Q| = 0, jump to MU5 to set K(3 2 1 0) to 0,
                        \ returning from the subroutine using a tail call

 SEC                    \ Set T = |Q| - 1
 SBC #1
 STA T

                        \ We now use the same shift-and-add algorithm as MULT1
                        \ to calculate the following:
                        \
                        \ K(2 1 0) = K(2 1 0) * |Q|
                        \
                        \ so we start with the first shift right, in which we
                        \ take (K+2 P+1 P) and shift it right, storing the
                        \ result in K(2 1 0), ready for the multiplication loop
                        \ (so the multiplication loop actually calculates
                        \ (|A| P+1 P) * |Q|, as the following sets K(2 1 0) to
                        \ (|A| P+1 P) shifted right)

 LDA P+1                \ Set A = P+1

 LSR K+2                \ Shift the high byte in K+2 to the right

 ROR A                  \ Shift the middle byte in A to the right and store in
 STA K+1                \ K+1 (so K+1 contains P+1 shifted right)

 LDA P                  \ Shift the middle byte in P to the right and store in
 ROR A                  \ K, so K(2 1 0) now contains (|A| P+1 P) shifted right
 STA K

                        \ We now use the same shift-and-add algorithm as MULT1
                        \ to calculate the following:
                        \
                        \ K(2 1 0) = K(2 1 0) * |Q|

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #24                \ Set up a counter in X to count the 24 bits in K(2 1 0)

.MUL2

 BCC P%+4               \ If C (i.e. the next bit from K) is set, do the
 ADC T                  \ addition for this bit of K:
                        \
                        \   A = A + T + C
                        \     = A + |Q| - 1 + 1
                        \     = A + |Q|

 ROR A                  \ Shift A right by one place to catch the next digit
 ROR K+2                \ next digit of our result in the left end of K(2 1 0),
 ROR K+1                \ while also shifting K(2 1 0) right to fetch the next
 ROR K                  \ bit for the calculation into the C flag
                        \
                        \ On the last iteration of this loop, the bit falling
                        \ off the end of K will be bit 0 of the original A, as
                        \ we did one shift before the loop and we are doing 24
                        \ iterations. We set A to 0 before looping, so this
                        \ means the loop exits with the C flag clear

 DEX                    \ Decrement the loop counter

 BNE MUL2               \ Loop back for the next bit until K(2 1 0) has been
                        \ rotated all the way

                        \ The result (|A| P+1 P) * |Q| is now in (A K+2 K+1 K),
                        \ but it is positive and doesn't have the correct sign
                        \ of the final result yet

 STA T                  \ Save the high byte of the result into T

 LDA R                  \ Fetch the sign byte from the original (A P+1 P)
                        \ argument that we stored in R

 EOR Q                  \ EOR with Q so the sign bit is the same as that of
                        \ (A P+1 P) * Q

 AND #%10000000         \ Extract the sign bit

 ORA T                  \ Apply this to the high byte of the result in T, so
                        \ that A now has the correct sign for the result, and
                        \ (A K+2 K+1 K) therefore contains the correctly signed
                        \ result

 STA K+3                \ Store A in K+3, so K(3 2 1 0) now contains the result

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MLS2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S R) = XX(1 0) and (A P) = A * ALP1
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   (S R) = XX(1 0)
\
\   (A P) = A * ALP1
\
\ where ALP1 is the magnitude of the current roll angle alpha, in the range
\ 0-31.
\
\ ******************************************************************************

.MLS2

 LDX XX                 \ Set (S R) = XX(1 0), starting with the low bytes
 STX R

 LDX XX+1               \ And then doing the high bytes
 STX S

                        \ Fall through into MLS1 to calculate (A P) = A * ALP1

\ ******************************************************************************
\
\       Name: MLS1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = ALP1 * A
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   (A P) = ALP1 * A
\
\ where ALP1 is the magnitude of the current roll angle alpha, in the range
\ 0-31.
\
\ This routine uses an unrolled version of MU11. MU11 calculates P * X, so we
\ use the same algorithm but with P set to ALP1 and X set to A. The unrolled
\ version here can skip the bit tests for bits 5-7 of P as we know P < 32, so
\ only 5 shifts with bit tests are needed (for bits 0-4), while the other 3
\ shifts can be done without a test (for bits 5-7).
\
\ Other entry points:
\
\   MULTS-2             Calculate (A P) = X * A
\
\ ******************************************************************************

.MLS1

 LDX ALP1               \ Set P to the roll angle alpha magnitude in ALP1
 STX P                  \ (0-31), so now we calculate P * A

.MULTS

 TAX                    \ Set X = A, so now we can calculate P * X instead of
                        \ P * A to get our result, and we can use the algorithm
                        \ from MU11 to do that, just unrolled (as MU11 returns
                        \ P * X)

 AND #%10000000         \ Set T to the sign bit of A
 STA T

 TXA                    \ Set A = |A|
 AND #127

 BEQ MU6                \ If A = 0, jump to MU6 to set P(1 0) = 0 and return
                        \ from the subroutine using a tail call

 TAX                    \ Set T1 = X - 1
 DEX                    \
 STX T1                 \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

                        \ We are now going to work our way through the bits of
                        \ P, and do a shift-add for any bits that are set,
                        \ keeping the running total in A, but instead of using a
                        \ loop like MU11, we just unroll it, starting with bit 0

 BCC P%+4               \ If C (i.e. the next bit from P) is set, do the
 ADC T1                 \ addition for this bit of P:
                        \
                        \   A = A + T1 + C
                        \     = A + X - 1 + 1
                        \     = A + X

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 BCC P%+4               \ Repeat the shift-and-add loop for bit 1
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat the shift-and-add loop for bit 2
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat the shift-and-add loop for bit 3
 ADC T1
 ROR A
 ROR P

 BCC P%+4               \ Repeat the shift-and-add loop for bit 4
 ADC T1
 ROR A
 ROR P

 LSR A                  \ Just do the "shift" part for bit 5
 ROR P

 LSR A                  \ Just do the "shift" part for bit 6
 ROR P

 LSR A                  \ Just do the "shift" part for bit 7
 ROR P

 ORA T                  \ Give A the sign bit of the original argument A that
                        \ we put into T above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SQUA
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Clear bit 7 of A and calculate (A P) = A * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers, after first
\ clearing bit 7 of A:
\
\   (A P) = A * A
\
\ ******************************************************************************

.SQUA

 AND #%01111111         \ Clear bit 7 of A and fall through into SQUA2 to set
                        \ (A P) = A * A

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
\ ******************************************************************************

.SQUA2

 STA P                  \ Copy A into P and X
 TAX

 BNE MU11               \ If X = 0 fall through into MU1 to return a 0,
                        \ otherwise jump to MU11 to return P * X

\ ******************************************************************************
\
\       Name: MU1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Copy X into P and A, and clear the C flag
\
\ ------------------------------------------------------------------------------
\
\ Used to return a 0 result quickly from MULTU below.
\
\ ******************************************************************************

.MU1

 CLC                    \ Clear the C flag

 STX P                  \ Copy X into P and A
 TXA

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MLU1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate Y1 = y_hi and (A P) = |y_hi| * Q for Y-th stardust
\
\ ------------------------------------------------------------------------------
\
\ Do the following assignment, and multiply the Y-th stardust particle's
\ y-coordinate with an unsigned number Q:
\
\   Y1 = y_hi
\
\   (A P) = |y_hi| * Q
\
\ ******************************************************************************

.MLU1

 LDA SY,Y               \ Set Y1 the Y-th byte of SY
 STA Y1

                        \ Fall through into MLU2 to calculate:
                        \
                        \   (A P) = |A| * Q

\ ******************************************************************************
\
\       Name: MLU2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = |A| * Q
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of a sign-magnitude 8-bit number P with an
\ unsigned number Q:
\
\   (A P) = |A| * Q
\
\ ******************************************************************************

.MLU2

 AND #%01111111         \ Clear the sign bit in P, so P = |A|
 STA P

                        \ Fall through into MULTU to calculate:
                        \
                        \   (A P) = P * Q
                        \         = |A| * Q

\ ******************************************************************************
\
\       Name: MULTU
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = P * Q
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = P * Q
\
\ ******************************************************************************

.MULTU

 LDX Q                  \ Set X = Q

 BEQ MU1                \ If X = Q = 0, jump to MU1 to copy X into P and A,
                        \ clear the C flag and return from the subroutine using
                        \ a tail call

                        \ Otherwise fall through into MU11 to set (A P) = P * X

\ ******************************************************************************
\
\       Name: MU11
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = P * X
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned 8-bit numbers:
\
\   (A P) = P * X
\
\ This uses the same shift-and-add approach as MULT1, but it's simpler as we
\ are dealing with unsigned numbers in P and X. See the deep dive on
\ "Shift-and-add multiplication" for a discussion of how this algorithm works.
\
\ ******************************************************************************

.MU11

 DEX                    \ Set T = X - 1
 STX T                  \
                        \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #8                 \ Set up a counter in X to count the 8 bits in P

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

                        \ We are now going to work our way through the bits of
                        \ P, and do a shift-add for any bits that are set,
                        \ keeping the running total in A. We just did the first
                        \ shift right, so we now need to do the first add and
                        \ loop through the other bits in P

.MUL6

 BCC P%+4               \ If C (i.e. the next bit from P) is set, do the
 ADC T                  \ addition for this bit of P:
                        \
                        \   A = A + T + C
                        \     = A + X - 1 + 1
                        \     = A + X

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 DEX                    \ Decrement the loop counter

 BNE MUL6               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MU6
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set P(1 0) = (A A)
\
\ ------------------------------------------------------------------------------
\
\ In practice this is only called via a BEQ following an AND instruction, in
\ which case A = 0, so this routine effectively does this:
\
\   P(1 0) = 0
\
\ ******************************************************************************

.MU6

 STA P+1                \ Set P(1 0) = (A A)
 STA P

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FMLTU2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = K * sin(A)
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   A = K * sin(A)
\
\ Because this routine uses the sine lookup table SNE, we can also call this
\ routine to calculate cosine multiplication. To calculate the following:
\
\   A = K * cos(B)
\
\ call this routine with B + 16 in the accumulator, as sin(B + 16) = cos(B).
\
\ ******************************************************************************

.FMLTU2

 AND #%00011111         \ Restrict A to bits 0-5 (so it's in the range 0-31)

 TAX                    \ Set Q = sin(A) * 256
 LDA SNE,X
 STA Q

 LDA K                  \ Set A to the radius in K

                        \ Fall through into FMLTU to do the following:
                        \
                        \   (A ?) = A * Q
                        \         = K * sin(A) * 256
                        \
                        \ which is equivalent to:
                        \
                        \   A = K * sin(A)

\ ******************************************************************************
\
\       Name: FMLTU
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = A * Q / 256
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned 8-bit numbers, returning only
\ the high byte of the result:
\
\   (A ?) = A * Q
\
\ or, to put it another way:
\
\   A = A * Q / 256
\
\ ******************************************************************************

.FMLTU

 EOR #%11111111         \ Flip the bits in A, set the C flag and rotate right,
 SEC                    \ so the C flag now contains bit 0 of A inverted, and P
 ROR A                  \ contains A inverted and shifted right by one, with bit
 STA P                  \ 7 set to a 1. We can now use P as our source of bits
                        \ to shift right, just as in MU11, just with the logic
                        \ reversed

 LDA #0                 \ Set A = 0 so we can start building the answer in A

.MUL3

 BCS MU7                \ If C (i.e. the next bit from P) is set, do not do the
                        \ addition for this bit of P, and instead skip to MU7
                        \ to just do the shifts

 ADC Q                  \ Do the addition for this bit of P:
                        \
                        \   A = A + Q + C
                        \     = A + Q

 ROR A                  \ Shift A right to catch the next digit of our result.
                        \ If we were interested in the low byte of the result we
                        \ would want to save the bit that falls off the end, but
                        \ we aren't, so we can ignore it

 LSR P                  \ Shift P right to fetch the next bit for the
                        \ calculation into the C flag

 BNE MUL3               \ Loop back to MUL3 if P still contains some set bits
                        \ (so we loop through the bits of P until we get to the
                        \ 1 we inserted before the loop, and then we stop)

 RTS                    \ Return from the subroutine

.MU7

 LSR A                  \ Shift A right to catch the next digit of our result,
                        \ pushing a 0 into bit 7 as we aren't adding anything
                        \ here (we can't use a ROR here as the C flag is set, so
                        \ a ROR would push a 1 into bit 7)

 LSR P                  \ Fetch the next bit from P into the C flag

 BNE MUL3               \ Loop back to MUL3 if P still contains some set bits
                        \ (so we loop through the bits of P until we get to the
                        \ 1 we inserted before the loop, and then we stop)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: Unused duplicate of MULTU
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Unused duplicate of the MULTU routine
\
\ ------------------------------------------------------------------------------
\
\ This is a duplicate of the MULTU routine, but with no entry label, so it can't
\ be called by name. It is unused, and could have been culled to save a few
\ bytes (24 to be precise), but it's still here, unnamed, unloved and unvisited,
\ through no fault of its own.
\
\ ******************************************************************************

{
 LDX Q
 BEQ MU1
 DEX
 STX T
 LDA #0
 LDX #8
 LSR P

.MUL6

 BCC P%+4
 ADC T
 ROR A
 ROR P
 DEX
 BNE MUL6
 RTS
}

\ ******************************************************************************
\
\       Name: MLTU2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P+1 P) = (A ~P) * Q
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of an unsigned 16-bit number and an unsigned
\ 8-bit number:
\
\   (A P+1 P) = (A ~P) * Q
\
\ where ~P means P EOR %11111111 (i.e. P with all its bits flipped). In other
\ words, if you wanted to calculate &1234 * &56, you would:
\
\   * Set A to &12
\   * Set P to &34 EOR %11111111 = &CB
\   * Set Q to &56
\
\ before calling MLTU2.
\
\ This routine is like a mash-up of MU11 and FMLTU. It uses part of FMLTU's
\ inverted argument trick to work out whether or not to do an addition, and like
\ MU11 it sets up a counter in X to extract bits from (P+1 P). But this time we
\ extract 16 bits from (P+1 P), so the result is a 24-bit number. The core of
\ the algorithm is still the shift-and-add approach explained in MULT1, just
\ with more bits.
\
\ Returns:
\
\   Q                   Q is preserved
\
\ Other entry points:
\
\   MLTU2-2             Set Q to X, so this calculates (A P+1 P) = (A ~P) * X
\
\ ******************************************************************************

 STX Q                  \ Store X in Q

.MLTU2

 EOR #%11111111         \ Flip the bits in A and rotate right, storing the
 LSR A                  \ result in P+1, so we now calculate (P+1 P) * Q
 STA P+1

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #16                \ Set up a counter in X to count the 16 bits in (P+1 P)

 ROR P                  \ Set P = P >> 1 with bit 7 = bit 0 of A
                        \ and C flag = bit 0 of P

.MUL7

 BCS MU21               \ If C (i.e. the next bit from P) is set, do not do the
                        \ addition for this bit of P, and instead skip to MU21
                        \ to just do the shifts

 ADC Q                  \ Do the addition for this bit of P:
                        \
                        \   A = A + Q + C
                        \     = A + Q

 ROR A                  \ Rotate (A P+1 P) to the right, so we capture the next
 ROR P+1                \ digit of the result in P+1, and extract the next digit
 ROR P                  \ of (P+1 P) in the C flag

 DEX                    \ Decrement the loop counter

 BNE MUL7               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

.MU21

 LSR A                  \ Shift (A P+1 P) to the right, so we capture the next
 ROR P+1                \ digit of the result in P+1, and extract the next digit
 ROR P                  \ of (P+1 P) in the C flag

 DEX                    \ Decrement the loop counter

 BNE MUL7               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MUT3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Unused routine that does the same as MUT2
\
\ ------------------------------------------------------------------------------
\
\ This routine is never actually called, but it is identical to MUT2, as the
\ extra instructions have no effect.
\
\ ******************************************************************************

.MUT3

 LDX ALP1               \ Set P = ALP1, though this gets overwritten by the
 STX P                  \ following, so this has no effect

                        \ Fall through into MUT2 to do the following:
                        \
                        \   (S R) = XX(1 0)
                        \   (A P) = Q * A

\ ******************************************************************************
\
\       Name: MUT2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S R) = XX(1 0) and (A P) = Q * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following assignment, and multiplication of two signed 8-bit numbers:
\
\   (S R) = XX(1 0)
\   (A P) = Q * A
\
\ ******************************************************************************

.MUT2

 LDX XX+1               \ Set S = XX+1
 STX S

                        \ Fall through into MUT1 to do the following:
                        \
                        \   R = XX
                        \   (A P) = Q * A

\ ******************************************************************************
\
\       Name: MUT1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate R = XX and (A P) = Q * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following assignment, and multiplication of two signed 8-bit numbers:
\
\   R = XX
\   (A P) = Q * A
\
\ ******************************************************************************

.MUT1

 LDX XX                 \ Set R = XX
 STX R

                        \ Fall through into MULT1 to do the following:
                        \
                        \   (A P) = Q * A

\ ******************************************************************************
\
\       Name: MULT1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = Q * A
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two 8-bit sign-magnitude numbers:
\
\   (A P) = Q * A
\
\ ******************************************************************************

.MULT1

 TAX                    \ Store A in X

 AND #%01111111         \ Set P = |A| >> 1
 LSR A                  \ and C flag = bit 0 of A
 STA P

 TXA                    \ Restore argument A

 EOR Q                  \ Set bit 7 of A and T if Q and A have different signs,
 AND #%10000000         \ clear bit 7 if they have the same signs, 0 all other
 STA T                  \ bits, i.e. T contains the sign bit of Q * A

 LDA Q                  \ Set A = |Q|
 AND #%01111111

 BEQ mu10               \ If |Q| = 0 jump to mu10 (with A set to 0)

 TAX                    \ Set T1 = |Q| - 1
 DEX                    \
 STX T1                 \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

                        \ We are now going to work our way through the bits of
                        \ P, and do a shift-add for any bits that are set,
                        \ keeping the running total in A. We already set up
                        \ the first shift at the start of this routine, as
                        \ P = |A| >> 1 and C = bit 0 of A, so we now need to set
                        \ up a loop to sift through the other 7 bits in P

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #7                 \ Set up a counter in X to count the 7 bits remaining
                        \ in P

.MUL4

 BCC P%+4               \ If C (i.e. the next bit from P) is set, do the
 ADC T1                 \ addition for this bit of P:
                        \
                        \   A = A + T1 + C
                        \     = A + |Q| - 1 + 1
                        \     = A + |Q|

 ROR A                  \ As mentioned above, this ROR shifts A right and
                        \ catches bit 0 in C - giving another digit for our
                        \ result - and the next ROR sticks that bit into the
                        \ left end of P while also extracting the next bit of P
                        \ for the next addition

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation

 DEX                    \ Decrement the loop counter

 BNE MUL4               \ Loop back for the next bit until P has been rotated
                        \ all the way

 LSR A                  \ Rotate (A P) once more to get the final result, as
 ROR P                  \ we only pushed 7 bits through the above process

 ORA T                  \ Set the sign bit of the result that we stored in T

 RTS                    \ Return from the subroutine

.mu10

 STA P                  \ If we get here, the result is 0 and A = 0, so set
                        \ P = 0 so (A P) = 0

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MULT12
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S R) = Q * A
\
\ ------------------------------------------------------------------------------
\
\ Calculate:
\
\   (S R) = Q * A
\
\ ******************************************************************************

.MULT12

 JSR MULT1              \ Set (A P) = Q * A

 STA S                  \ Set (S R) = (A P)
 LDA P
 STA R

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TAS3
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the dot product of XX15 and an orientation vector
\
\ ------------------------------------------------------------------------------
\
\ Calculate the dot product of the vector in XX15 and one of the orientation
\ vectors, as determined by the value of Y. If vect is the orientation vector,
\ we calculate this:
\
\   (A X) = vect . XX15
\         = vect_x * XX15 + vect_y * XX15+1 + vect_z * XX15+2
\
\ Arguments:
\
\   Y                   The orientation vector:
\
\                         * If Y = 10, calculate nosev . XX15
\
\                         * If Y = 16, calculate roofv . XX15
\
\                         * If Y = 22, calculate sidev . XX15
\
\ Returns:
\
\   (A X)               The result of the dot product
\
\ ******************************************************************************

.TAS3

 LDX INWK,Y             \ Set Q = the Y-th byte of INWK, i.e. vect_x
 STX Q

 LDA XX15               \ Set A = XX15

 JSR MULT12             \ Set (S R) = Q * A
                        \           = vect_x * XX15

 LDX INWK+2,Y           \ Set Q = the Y+2-th byte of INWK, i.e. vect_y
 STX Q

 LDA XX15+1             \ Set A = XX15+1

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = vect_y * XX15+1 + vect_x * XX15

 STA S                  \ Set (S R) = (A X)
 STX R

 LDX INWK+4,Y           \ Set Q = the Y+2-th byte of INWK, i.e. vect_z
 STX Q

 LDA XX15+2             \ Set A = XX15+2

                        \ Fall through into MAD to set:
                        \
                        \   (A X) = Q * A + (S R)
                        \           = vect_z * XX15+2 + vect_y * XX15+1 +
                        \             vect_x * XX15

\ ******************************************************************************
\
\       Name: MAD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A X) = Q * A + (S R)
\
\ ------------------------------------------------------------------------------
\
\ Calculate
\
\   (A X) = Q * A + (S R)
\
\ ******************************************************************************

.MAD

 JSR MULT1              \ Call MULT1 to set (A P) = Q * A

                        \ Fall through into ADD to do:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = Q * A + (S R)

\ ******************************************************************************
\
\       Name: ADD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A X) = (A P) + (S R)
\  Deep dive: Adding sign-magnitude numbers
\
\ ------------------------------------------------------------------------------
\
\ Add two 16-bit sign-magnitude numbers together, calculating:
\
\   (A X) = (A P) + (S R)
\
\ ******************************************************************************

.ADD

 STA T1                 \ Store argument A in T1

 AND #%10000000         \ Extract the sign (bit 7) of A and store it in T
 STA T

 EOR S                  \ EOR bit 7 of A with S. If they have different bit 7s
 BMI MU8                \ (i.e. they have different signs) then bit 7 in the
                        \ EOR result will be 1, which means the EOR result is
                        \ negative. So the AND, EOR and BMI together mean "jump
                        \ to MU8 if A and S have different signs"

                        \ If we reach here, then A and S have the same sign, so
                        \ we can add them and set the sign to get the result

 LDA R                  \ Add the least significant bytes together into X:
 CLC                    \
 ADC P                  \   X = P + R
 TAX

 LDA S                  \ Add the most significant bytes together into A. We
 ADC T1                 \ stored the original argument A in T1 earlier, so we
                        \ can do this with:
                        \
                        \   A = A  + S + C
                        \     = T1 + S + C

 ORA T                  \ If argument A was negative (and therefore S was also
                        \ negative) then make sure result A is negative by
                        \ OR-ing the result with the sign bit from argument A
                        \ (which we stored in T)

 RTS                    \ Return from the subroutine

.MU8

                        \ If we reach here, then A and S have different signs,
                        \ so we can subtract their absolute values and set the
                        \ sign to get the result

 LDA S                  \ Clear the sign (bit 7) in S and store the result in
 AND #%01111111         \ U, so U now contains |S|
 STA U

 LDA P                  \ Subtract the least significant bytes into X:
 SEC                    \
 SBC R                  \   X = P - R
 TAX

 LDA T1                 \ Restore the A of the argument (A P) from T1 and
 AND #%01111111         \ clear the sign (bit 7), so A now contains |A|

 SBC U                  \ Set A = |A| - |S|

                        \ At this point we have |A P| - |S R| in (A X), so we
                        \ need to check whether the subtraction above was the
                        \ the right way round (i.e. that we subtracted the
                        \ smaller absolute value from the larger absolute
                        \ value)

 BCS MU9                \ If |A| >= |S|, our subtraction was the right way
                        \ round, so jump to MU9 to set the sign

                        \ If we get here, then |A| < |S|, so our subtraction
                        \ above was the wrong way round (we actually subtracted
                        \ the larger absolute value from the smaller absolute
                        \ value). So let's subtract the result we have in (A X)
                        \ from zero, so that the subtraction is the right way
                        \ round

 STA U                  \ Store A in U

 TXA                    \ Set X = 0 - X using two's complement (to negate a
 EOR #&FF               \ number in two's complement, you can invert the bits
 ADC #1                 \ and add one - and we know the C flag is clear as we
 TAX                    \ didn't take the BCS branch above, so the ADC will do
                        \ the correct addition)

 LDA #0                 \ Set A = 0 - A, which we can do this time using a
 SBC U                  \ a subtraction with the C flag clear

 ORA #%10000000         \ We now set the sign bit of A, so that the EOR on the
                        \ next line will give the result the opposite sign to
                        \ argument A (as T contains the sign bit of argument
                        \ A). This is the same as giving the result the same
                        \ sign as argument S (as A and S have different signs),
                        \ which is what we want, as S has the larger absolute
                        \ value

.MU9

 EOR T                  \ If we get here from the BCS above, then |A| >= |S|,
                        \ so we want to give the result the same sign as
                        \ argument A, so if argument A was negative, we flip
                        \ the sign of the result with an EOR (to make it
                        \ negative)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TIS1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A ?) = (-X * A + (S R)) / 96
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following expression between sign-magnitude numbers, ignoring
\ the low byte of the result:
\
\   (A ?) = (-X * A + (S R)) / 96
\
\ This uses the same shift-and-subtract algorithm as TIS2, just with the
\ quotient A hard-coded to 96.
\
\ Returns:
\
\   Q                   Gets set to the value of argument X
\
\ ******************************************************************************

.TIS1

 STX Q                  \ Set Q = X

 EOR #%10000000         \ Flip the sign bit in A

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = X * -A + (S R)

.DVID96

 TAX                    \ Set T to the sign bit of the result
 AND #%10000000
 STA T

 TXA                    \ Set A to the high byte of the result with the sign bit
 AND #%01111111         \ cleared, so (A ?) = |X * A + (S R)|

                        \ The following is identical to TIS2, except Q is
                        \ hard-coded to 96, so this does A = A / 96

 LDX #254               \ Set T1 to have bits 1-7 set, so we can rotate through
 STX T1                 \ 7 loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use T1 to catch our result bits into bit 0 each time

.DVL3

 ASL A                  \ Shift A to the left

 CMP #96                \ If A < 96 skip the following subtraction
 BCC DV4

 SBC #96                \ Set A = A - 96
                        \
                        \ Going into this subtraction we know the C flag is
                        \ set as we passed through the BCC above, and we also
                        \ know that A >= 96, so the C flag will still be set
                        \ once we are done

.DV4

 ROL T1                 \ Rotate the counter in T1 to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS DVL3               \ If we still have set bits in T1, loop back to DVL3 to
                        \ do the next iteration of 7

 LDA T1                 \ Fetch the result from T1 into A

 ORA T                  \ Give A the sign of the result that we stored above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DV42
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P R) = 256 * DELTA / z_hi
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division and remainder:
\
\   P = DELTA / (the Y-th stardust particle's z_hi coordinate)
\
\   R = remainder as a fraction of A, where 1.0 = 255
\
\ Another way of saying the above is this:
\
\   (P R) = 256 * DELTA / z_hi
\
\ DELTA is a value between 1 and 40, and the minimum z_hi is 16 (dust particles
\ are removed at lower values than this), so this means P is between 0 and 2
\ (as 40 / 16 = 2.5, so the maximum result is P = 2 and R = 128.
\
\ This uses the same shift-and-subtract algorithm as TIS2, but this time we
\ keep the remainder.
\
\ Arguments:
\
\   Y                   The number of the stardust particle to process
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.DV42

 LDA SZ,Y               \ Fetch the Y-th dust particle's z_hi coordinate into A

                        \ Fall through into DV41 to do:
                        \
                        \   (P R) = 256 * DELTA / A
                        \         = 256 * DELTA / Y-th stardust particle's z_hi

\ ******************************************************************************
\
\       Name: DV41
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P R) = 256 * DELTA / A
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division and remainder:
\
\   P = DELTA / A
\
\   R = remainder as a fraction of A, where 1.0 = 255
\
\ Another way of saying the above is this:
\
\   (P R) = 256 * DELTA / A
\
\ This uses the same shift-and-subtract algorithm as TIS2, but this time we
\ keep the remainder.
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.DV41

 STA Q                  \ Store A in Q

 LDA DELTA              \ Fetch the speed from DELTA into A

                        \ Fall through into DVID4 to do:
                        \
                        \   (P R) = 256 * A / Q
                        \         = 256 * DELTA / A

\ ******************************************************************************
\
\       Name: DVID4
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P R) = 256 * A / Q
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division and remainder:
\
\   P = A / Q
\
\   R = remainder as a fraction of Q, where 1.0 = 255
\
\ Another way of saying the above is this:
\
\   (P R) = 256 * A / Q
\
\ This uses the same shift-and-subtract algorithm as TIS2, but this time we
\ keep the remainder.
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.DVID4

 LDX #8                 \ Set a counter in X to count the 8 bits in A

 ASL A                  \ Shift A left and store in P (we will build the result
 STA P                  \ in P)

 LDA #0                 \ Set A = 0 for us to build a remainder

.DVL4

 ROL A                  \ Shift A to the left

 BCS DV8                \ If the C flag is set (i.e. bit 7 of A was set) then
                        \ skip straight to the subtraction

 CMP Q                  \ If A < Q skip the following subtraction
 BCC DV5

.DV8

 SBC Q                  \ A >= Q, so set A = A - Q

 SEC                    \ Set the C flag, so that P gets a 1 shifted into bit 0

.DV5

 ROL P                  \ Shift P to the left, pulling the C flag into bit 0

 DEX                    \ Decrement the loop counter

 BNE DVL4               \ Loop back for the next bit until we have done all 8
                        \ bits of P

 JMP LL28+4             \ Jump to LL28+4 to convert the remainder in A into an
                        \ integer representation of the fractional value A / Q,
                        \ in R, where 1.0 = 255. LL28+4 always returns with the
                        \ C flag cleared, and we return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: DVID3B2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate K(3 2 1 0) = (A P+1 P) / (z_sign z_hi z_lo)
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   K(3 2 1 0) = (A P+1 P) / (z_sign z_hi z_lo)
\
\ The actual division here is done as an 8-bit calculation using LL31, but this
\ routine shifts both the numerator (the top part of the division) and the
\ denominator (the bottom part of the division) around to get the multi-byte
\ result we want.
\
\ Specifically, it shifts both of them to the left as far as possible, keeping a
\ tally of how many shifts get done in each one - and specifically, the
\ difference in the number of shifts between the top and bottom (as shifting
\ both of them once in the same direction won't change the result). It then
\ divides the two highest bytes with the simple 8-bit routine in LL31, and
\ shifts the result by the difference in the number of shifts, which acts as a
\ scale factor to get the correct result.
\
\ Returns:
\
\   K(3 2 1 0)          The result of the division
\
\   X                   X is preserved
\
\ ******************************************************************************

.DVID3B2

 STA P+2                \ Set P+2 = A

 LDA INWK+6             \ Set Q = z_lo
 STA Q

 LDA INWK+7             \ Set R = z_hi
 STA R

 LDA INWK+8             \ Set S = z_sign
 STA S

.DVID3B

                        \ Given the above assignments, we now want to calculate
                        \ the following to get the result we want:
                        \
                        \   K(3 2 1 0) = P(2 1 0) / (S R Q)

 LDA P                  \ Make sure P(2 1 0) is at least 1
 ORA #1
 STA P

 LDA P+2                \ Set T to the sign of P+2 * S (i.e. the sign of the
 EOR S                  \ result) and store it in T
 AND #%10000000
 STA T

 LDY #0                 \ Set Y = 0 to store the scale factor

 LDA P+2                \ Clear the sign bit of P+2, so the division can be done
 AND #%01111111         \ with positive numbers and we'll set the correct sign
                        \ below, once all the maths is done
                        \
                        \ This also leaves A = P+2, which we use below

.DVL9

                        \ We now shift (A P+1 P) left until A >= 64, counting
                        \ the number of shifts in Y. This makes the top part of
                        \ the division as large as possible, thus retaining as
                        \ much accuracy as we can.  When we come to return the
                        \ final result, we shift the result by the number of
                        \ places in Y, and in the correct direction

 CMP #64                \ If A >= 64, jump down to DV14
 BCS DV14

 ASL P                  \ Shift (A P+1 P) to the left
 ROL P+1
 ROL A

 INY                    \ Increment the scale factor in Y

 BNE DVL9               \ Loop up to DVL9 (this BNE is effectively a JMP, as Y
                        \ will never be zero)

.DV14

                        \ If we get here, A >= 64 and contains the highest byte
                        \ of the numerator, scaled up by the number of left
                        \ shifts in Y

 STA P+2                \ Store A in P+2, so we now have the scaled value of
                        \ the numerator in P(2 1 0)

 LDA S                  \ Set A = |S|
 AND #%01111111

 BMI DV9                \ If bit 7 of A is set, jump down to DV9 to skip the
                        \ left-shifting of the denominator (though this branch
                        \ instruction has no effect as bit 7 of the above AND
                        \ can never be set, which is why this instruction was
                        \ removed from later versions)

.DVL6

                        \ We now shift (S R Q) left until bit 7 of S is set,
                        \ reducing Y by the number of shifts. This makes the
                        \ bottom part of the division as large as possible, thus
                        \ retaining as much accuracy as we can. When we come to
                        \ return the final result, we shift the result by the
                        \ total number of places in Y, and in the correct
                        \ direction, to give us the correct result
                        \
                        \ We set A to |S| above, so the following actually
                        \ shifts (A R Q)

 DEY                    \ Decrement the scale factor in Y

 ASL Q                  \ Shift (A R Q) to the left
 ROL R
 ROL A

 BPL DVL6               \ Loop up to DVL6 to do another shift, until bit 7 of A
                        \ is set and we can't shift left any further

.DV9

                        \ We have now shifted both the numerator and denominator
                        \ left as far as they will go, keeping a tally of the
                        \ overall scale factor of the various shifts in Y. We
                        \ can now divide just the two highest bytes to get our
                        \ result

 STA Q                  \ Set Q = A, the highest byte of the denominator

 LDA #254               \ Set R to have bits 1-7 set, so we can pass this to
 STA R                  \ LL31 to act as the bit counter in the division

 LDA P+2                \ Set A to the highest byte of the numerator

 JSR LL31               \ Call LL31 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * numerator / denominator

                        \ The result of our division is now in R, so we just
                        \ need to shift it back by the scale factor in Y

 LDA #0                 \ Set K(3 2 1) = 0 to hold the result (we populate K
 STA K+1                \ next)
 STA K+2
 STA K+3

 TYA                    \ If Y is positive, jump to DV12
 BPL DV12

                        \ If we get here then Y is negative, so we need to shift
                        \ the result R to the left by Y places, and then set the
                        \ correct sign for the result

 LDA R                  \ Set A = R

.DVL8

 ASL A                  \ Shift (K+3 K+2 K+1 A) left
 ROL K+1
 ROL K+2
 ROL K+3

 INY                    \ Increment the scale factor in Y

 BNE DVL8               \ Loop back to DVL8 until we have shifted left by Y
                        \ places

 STA K                  \ Store A in K so the result is now in K(3 2 1 0)

 LDA K+3                \ Set K+3 to the sign in T, which we set above to the
 ORA T                  \ correct sign for the result
 STA K+3

 RTS                    \ Return from the subroutine

.DV13

                        \ If we get here then Y is zero, so we don't need to
                        \ shift the result R, we just need to set the correct
                        \ sign for the result

 LDA R                  \ Store R in K so the result is now in K(3 2 1 0)
 STA K

 LDA T                  \ Set K+3 to the sign in T, which we set above to the
 STA K+3                \ correct sign for the result

 RTS                    \ Return from the subroutine

.DV12

 BEQ DV13               \ We jumped here having set A to the scale factor in Y,
                        \ so this jumps up to DV13 if Y = 0

                        \ If we get here then Y is positive and non-zero, so we
                        \ need to shift the result R to the right by Y places
                        \ and then set the correct sign for the result. We also
                        \ know that K(3 2 1) will stay 0, as we are shifting the
                        \ lowest byte to the right, so no set bits will make
                        \ their way into the top three bytes

 LDA R                  \ Set A = R

.DVL10

 LSR A                  \ Shift A right

 DEY                    \ Decrement the scale factor in Y

 BNE DVL10              \ Loop back to DVL10 until we have shifted right by Y
                        \ places

 STA K                  \ Store the shifted A in K so the result is now in
                        \ K(3 2 1 0)

 LDA T                  \ Set K+3 to the sign in T, which we set above to the
 STA K+3                \ correct sign for the result

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: cntr
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Apply damping to the pitch or roll dashboard indicator
\
\ ------------------------------------------------------------------------------
\
\ Apply damping to the value in X, where X ranges from 1 to 255 with 128 as the
\ centre point (so X represents a position on a centre-based dashboard slider,
\ such as pitch or roll). If the value is in the left-hand side of the slider
\ (1-127) then it bumps the value up by 1 so it moves towards the centre, and
\ if it's in the right-hand side, it reduces it by 1, also moving it towards the
\ centre.
\
\ ******************************************************************************

.cntr

 LDA DAMP               \ If DAMP is non-zero, then keyboard damping is not
 BNE RE1                \ enabled, so jump to RE1 to return from the subroutine

 TXA                    \ If X < 128, then it's in the left-hand side of the
 BPL BUMP               \ dashboard slider, so jump to BUMP to bump it up by 1,
                        \ to move it closer to the centre

 DEX                    \ Otherwise X >= 128, so it's in the right-hand side
 BMI RE1                \ of the dashboard slider, so decrement X by 1, and if
                        \ it's still >= 128, jump to RE1 to return from the
                        \ subroutine, otherwise fall through to BUMP to undo
                        \ the bump and then return

.BUMP

 INX                    \ Bump X up by 1, and if it hasn't overshot the end of
 BNE RE1                \ the dashboard slider, jump to RE1 to return from the
                        \ subroutine, otherwise fall through to REDU to drop
                        \ it down by 1 again

.REDU

 DEX                    \ Reduce X by 1, and if we have reached 0 jump up to
 BEQ BUMP               \ BUMP to add 1, because we need the value to be in the
                        \ range 1 to 255

.RE1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: BUMP2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Bump up the value of the pitch or roll dashboard indicator
\
\ ------------------------------------------------------------------------------
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
\
\ Other entry points:
\
\   RE2+2               Restore A from T and return from the subroutine
\
\ ******************************************************************************

.BUMP2

 STA T                  \ Store argument A in T so we can restore it later

 TXA                    \ Copy argument X into A

 CLC                    \ Clear the C flag so we can do addition without the
                        \ C flag affecting the result

 ADC T                  \ Set X = A = argument X + argument A
 TAX

 BCC RE2                \ If the C flag is clear, then we didn't overflow, so
                        \ jump to RE2 to auto-recentre and return the result

 LDX #255               \ We have an overflow, so set X to the maximum possible
                        \ value of 255

.RE2

 BPL RE3+2              \ If X has bit 7 clear (i.e. the result < 128), then
                        \ jump to RE3+2 in routine REDU2 to do an auto-recentre,
                        \ if configured, because the result is on the left side
                        \ of the centre point of 128

                        \ Jumps to RE2+2 end up here

 LDA T                  \ Restore the original argument A from T into A

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: REDU2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Reduce the value of the pitch or roll dashboard indicator
\
\ ------------------------------------------------------------------------------
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
\ reduce X down to the mid-point, 128. This is the equivalent of having a roll
\ or pitch in the right half of the indicator, when decreasing the roll or pitch
\ should jump us straight to the mid-point.
\
\ Other entry points:
\
\   RE3+2               Auto-recentre the value in X, if keyboard auto-recentre
\                       is configured
\
\ ******************************************************************************

.REDU2

 STA T                  \ Store argument A in T so we can restore it later

 TXA                    \ Copy argument X into A

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

 SBC T                  \ Set X = A = argument X - argument A
 TAX

 BCS RE3                \ If the C flag is set, then we didn't underflow, so
                        \ jump to RE3 to auto-recentre and return the result

 LDX #1                 \ We have an underflow, so set X to the minimum possible
                        \ value, 1

.RE3

 BPL RE2+2              \ If X has bit 7 clear (i.e. the result < 128), then
                        \ jump to RE2+2 above to return the result as is,
                        \ because the result is on the left side of the centre
                        \ point of 128, so we don't need to auto-centre

                        \ Jumps to RE3+2 end up here

                        \ If we get here, then we need to apply auto-recentre,
                        \ if it is configured

 LDA DJD                \ If keyboard auto-recentre is disabled, then
 BNE RE2+2              \ jump to RE2+2 to restore A and return

 LDX #128               \ If keyboard auto-recentre is enabled, set X to 128
 BMI RE2+2              \ (the middle of our range) and jump to RE2+2 to
                        \ restore A and return

\ ******************************************************************************
\
\       Name: ARCTAN
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate A = arctan(P / Q)
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   A = arctan(P / Q)
\
\ In other words, this finds the angle in the right-angled triangle where the
\ opposite side to angle A is length P and the adjacent side to angle A has
\ length Q, so:
\
\   tan(A) = P / Q
\
\ ******************************************************************************

.ARCTAN

 LDA P                  \ Set T1 = P EOR Q, which will have the sign of P * Q
 EOR Q
 STA T1

 LDA Q                  \ If Q = 0, jump to AR2 to return a right angle
 BEQ AR2

 ASL A                  \ Set Q = |Q| * 2 (this is a quick way of clearing the
 STA Q                  \ sign bit, and we don't need to shift right again as we
                        \ only ever use this value in the division with |P| * 2,
                        \ which we set next)

 LDA P                  \ Set A = |P| * 2
 ASL A

 CMP Q                  \ If A >= Q, i.e. |P| > |Q|, jump to AR1 to swap P
 BCS AR1                \ and Q around, so we can still use the lookup table

 JSR ARS1               \ Call ARS1 to set the following from the lookup table:
                        \
                        \   A = arctan(A / Q)
                        \     = arctan(|P / Q|)

 SEC                    \ Set the C flag so the SBC instruction in AR3 will be
                        \ correct, should we jump there

.AR4

 LDX T1                 \ If T1 is negative, i.e. P and Q have different signs,
 BMI AR3                \ jump down to AR3 to return arctan(-|P / Q|)

 RTS                    \ Otherwise P and Q have the same sign, so our result is
                        \ correct and we can return from the subroutine

.AR1

                        \ We want to calculate arctan(t) where |t| > 1, so we
                        \ can use the calculation described in the documentation
                        \ for the ACT table, i.e. 64 - arctan(1 / t)

 LDX Q                  \ Swap the values in Q and P, using the fact that we
 STA Q                  \ called AR1 with A = P
 STX P                  \
 TXA                    \ This also sets A = P (which now contains the original
                        \ argument |Q|)

 JSR ARS1               \ Call ARS1 to set the following from the lookup table:
                        \
                        \   A = arctan(A / Q)
                        \     = arctan(|Q / P|)
                        \     = arctan(1 / |P / Q|)

 STA T                  \ Set T = 64 - T
 LDA #64
 SBC T

 BCS AR4                \ Jump to AR4 to continue the calculation (this BCS is
                        \ effectively a JMP as the subtraction will never
                        \ underflow, as ARS1 returns values in the range 0-31)

.AR2

                        \ If we get here then Q = 0, so tan(A) = infinity and
                        \ A is a right angle, or 0.25 of a circle. We allocate
                        \ 255 to a full circle, so we should return 63 for a
                        \ right angle

 LDA #63                \ Set A to 63, to represent a right angle

 RTS                    \ Return from the subroutine

.AR3

                        \ A contains arctan(|P / Q|) but P and Q have different
                        \ signs, so we need to return arctan(-|P / Q|), using
                        \ the calculation described in the documentation for the
                        \ ACT table, i.e. 128 - A

 STA T                  \ Set A = 128 - A
 LDA #128               \
\SEC                    \ The SEC instruction is commented out in the original
 SBC T                  \ source, and isn't required as we did a SEC before
                        \ calling AR3

 RTS                    \ Return from the subroutine

.ARS1

                        \ This routine fetches arctan(A / Q) from the ACT table

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q

 LDA R                  \ Set X = R / 8
 LSR A                  \       = 32 * A / Q
 LSR A                  \
 LSR A                  \ so X has the value t * 32 where t = A / Q, which is
 TAX                    \ what we need to look up values in the ACT table

 LDA ACT,X              \ Fetch ACT+X from the ACT table into A, so now:
                        \
                        \   A = value in ACT + X
                        \     = value in ACT + (32 * A / Q)
                        \     = arctan(A / Q)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ACT
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Arctan table
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ To calculate the following:
\
\   theta = arctan(t)
\
\ where 0 <= t < 1, look up the value in:
\
\   ACT + (t * 32)
\
\ The result will be an integer representing the angle in radians, with 256
\ representing a full circle of 2 * PI radians.
\
\ The table does not support values of t >= 1 or t < 0 directly, but we can use
\ the following calculations instead:
\
\   * For t > 1, arctan(t) = 64 - arctan(1 / t)
\
\   * For t < 0, arctan(-t) = 128 - arctan(t)
\
\ If t < -1, we can do the first one to get arctan(|t|), then the second to get
\ arctan(-|t|).
\
\ ******************************************************************************

.ACT

FOR I%, 0, 31

 EQUB INT((128 / PI) * ATN(I% / 32) + 0.5)

NEXT

\ ******************************************************************************
\
\       Name: WARP
\       Type: Subroutine
\   Category: Flight
\    Summary: Perform an in-system jump
\
\ ------------------------------------------------------------------------------
\
\ This is called when we press "J" during flight. The following checks are
\ performed:
\
\   * Make sure we don't have any ships or space stations in the vicinity
\
\   * Make sure we are not in witchspace
\
\   * If we are facing the planet, make sure we aren't too close
\
\   * If we are facing the sun, make sure we aren't too close
\
\ If the above checks are passed, then we perform an in-system jump by moving
\ the sun and planet in the opposite direction to travel, so we appear to jump
\ in space. This means that any asteroids, cargo canisters or escape pods get
\ dragged along for the ride.
\
\ ******************************************************************************

.WARP

IF _SOURCE_DISC

 LDA MANY+AST           \ Set X to the total number of asteroids, escape pods
 CLC                    \ and cargo canisters in the vicinity
 ADC MANY+ESC
 CLC                    \ The second CLC instruction has no effect, as there is
 ADC MANY+OIL           \ is no way that adding the number of asteroids and the
 TAX                    \ number escape pods will cause a carry

ELIF _TEXT_SOURCES

 LDA MANY+AST           \ Set X to the total number of asteroids, escape pods
 CLC                    \ and cargo canisters in the vicinity
 ADC MANY+ESC           \
 ADC MANY+OIL           \ This code saves one byte of memory over the code in
 TAX                    \ the source disc version. The second CLC is not needed
                        \ as there is no way that adding the number of asteroids
                        \ and the number of escape pods will cause a carry

ENDIF

 LDA FRIN+2,X           \ If the slot at FRIN+2+X is non-zero, then we have
                        \ something else in the vicinity besides asteroids,
                        \ escape pods and cargo canisters, so to check whether
                        \ we can jump, we first grab the slot contents into A

 ORA SSPR               \ If there is a space station nearby, then SSPR will
                        \ be non-zero, so OR'ing with SSPR will produce a
                        \ a non-zero result if either A or SSPR are non-zero

 ORA MJ                 \ If we are in witchspace, then MJ will be non-zero, so
                        \ OR'ing with MJ will produce a non-zero result if
                        \ either A or SSPR or MJ are non-zero

 BNE WA1                \ A is non-zero if we have either a ship or a space
                        \ station in the vicinity, or we are in witchspace, in
                        \ which case jump to WA1 to make a low beep to show that
                        \ we can't do an in-system jump

 LDY K%+8               \ Otherwise we can do an in-system jump, so now we fetch
                        \ the byte at K%+8, which contains the z_sign for the
                        \ first ship slot, i.e. the distance of the planet

 BMI WA3                \ If the planet's z_sign is negative, then the planet
                        \ is behind us, so jump to WA3 to skip the following

 TAY                    \ Set A = Y = 0 (as we didn't BNE above) so the call
                        \ to MAS2 measures the distance to the planet

 JSR MAS2               \ Call MAS2 to set A to the largest distance to the
                        \ planet in any of the three axes (we could also call
                        \ routine m to do the same thing, as A = 0)

IF _SOURCE_DISC

 CMP #2                 \ If A < 2 then jump to WA1 to abort the in-system jump
 BCC WA1                \ with a low beep, as we are facing the planet and are
                        \ too close to jump in that direction

ELIF _TEXT_SOURCES

 LSR A                  \ If A < 2 then jump to WA1 to abort the in-system jump
 BEQ WA1                \ with a low beep, as we are facing the planet and are
                        \ too close to jump in that direction
                        \
                        \ These instructions between them save one byte of
                        \ memory over the CMP-based code in the source disc
                        \ version, as LSR A is a one-byte opcode, while CMP #2
                        \ takes up two bytes (though the code does exactly the
                        \ same thing)

ENDIF

.WA3

 LDY K%+NI%+8           \ Fetch the z_sign (byte #8) of the second ship in the
                        \ ship data workspace at K%, which is reserved for the
                        \ sun or the space station (in this case it's the
                        \ former, as we already confirmed there isn't a space
                        \ station in the vicinity)

 BMI WA2                \ If the sun's z_sign is negative, then the sun is
                        \ behind us, so jump to WA2 to skip the following

 LDY #NI%               \ Set Y to point to the offset of the ship data block
                        \ for the sun, which is NI% (as each block is NI% bytes
                        \ long, and the sun is the second block)

 JSR m                  \ Call m to set A to the largest distance to the sun
                        \ in any of the three axes

IF _SOURCE_DISC

 CMP #2                 \ If A < 2 then jump to WA1 to abort the in-system jump
 BCC WA1                \ with a low beep, as we are facing the planet and are
                        \ too close to jump in that direction

ELIF _TEXT_SOURCES

 LSR A                  \ If A < 2 then jump to WA1 to abort the in-system jump
 BEQ WA1                \ with a low beep, as we are facing the planet and are
                        \ too close to jump in that direction
                        \
                        \ These instructions between them save one byte of
                        \ memory over the CMP-based code in the source disc
                        \ version, as LSR A is a one-byte opcode, while CMP #2
                        \ takes up two bytes (though the code does exactly the
                        \ same thing)

ENDIF

.WA2

                        \ If we get here, then we can do an in-system jump, as
                        \ we don't have any ships or space stations in the
                        \ vicinity, we are not in witchspace, and if we are
                        \ facing the planet or the sun, we aren't too close to
                        \ jump towards it
                        \
                        \ We do an in-system jump by moving the sun and planet,
                        \ rather than moving our own local bubble (this is why
                        \ in-system jumps drag asteroids, cargo canisters and
                        \ escape pods along for the ride). Specifically, we move
                        \ them in the z-axis by a fixed amount in the opposite
                        \ direction to travel, thus performing a jump towards
                        \ our destination

 LDA #&81               \ Set R = R = P = &81
 STA S
 STA R
 STA P

 LDA K%+8               \ Set A = z_sign for the planet

 JSR ADD                \ Set (A X) = (A P) + (S R)
                        \           = (z_sign &81) + &8181
                        \           = (z_sign &81) - &0181
                        \
                        \ This moves the planet against the direction of travel
                        \ by reducing z_sign by 1, as the above maths is:
                        \
                        \         z_sign 00000000
                        \   +   00000000 10000001
                        \   -   00000001 10000001
                        \
                        \ or:
                        \
                        \         z_sign 00000000
                        \   +   00000000 00000000
                        \   -   00000001 00000000
                        \
                        \ i.e. the high byte is z_sign - 1, making sure the sign
                        \ is preserved

 STA K%+8               \ Set the planet's z_sign to the high byte of the result

 LDA K%+NI%+8           \ Set A = z_sign for the sun

 JSR ADD                \ Set (A X) = (A P) + (S R)
                        \           = (z_sign &81) + &8181
                        \           = (z_sign &81) - &0181
                        \
                        \ which moves the sun against the direction of travel
                        \ by reducing z_sign by 1

 STA K%+NI%+8           \ Set the planet's z_sign to the high byte of the result

 LDA #1                 \ These instructions have no effect, as the call to
 STA QQ11               \ LOOK1 below starts by setting QQ11 to 0; instead they
                        \ just set the current view type in QQ11 to 1 for the
                        \ duration of the next three instructions

 STA MCNT               \ Set the main loop counter to 1, so the next iteration
                        \ through the main loop will potentially spawn ships
                        \ (see part 2 of the main game loop at me3)

 LSR A                  \ Set EV, the extra vessels spawning counter, to 0
 STA EV                 \ (the LSR produces a 0 as A was previously 1)

 LDX VIEW               \ Set X to the current view (front, rear, left or right)
 JMP LOOK1              \ and jump to LOOK1 to initialise that view, returning
                        \ from the subroutine using a tail call

.WA1

 LDA #40                \ If we get here then we can't do an in-system jump, so
 JMP NOISE              \ call the NOISE routine with A = 40 to make a long, low
                        \ beep and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: LASLI
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw the laser lines for when we fire our lasers
\
\ ------------------------------------------------------------------------------
\
\ Draw the laser lines, aiming them to slightly different place each time so
\ they appear to flicker and dance. Also heat up the laser temperature and drain
\ some energy.
\
\ Other entry points:
\
\   LASLI2              Just draw the current laser lines without moving the
\                       centre point, draining energy or heating up. This has
\                       the effect of removing the lines from the screen
\
\   LASLI-1             Contains an RTS
\
\ ******************************************************************************

.LASLI

 JSR DORND              \ Set A and X to random numbers

 AND #7                 \ Restrict A to a random value in the range 0 to 7

 ADC #Y-4               \ Set LASY to four pixels above the centre of the
 STA LASY               \ screen (#Y), plus our random number, so the laser
                        \ dances above and below the centre point

 JSR DORND              \ Set A and X to random numbers

 AND #7                 \ Restrict A to a random value in the range 0 to 7

 ADC #X-4               \ Set LASX to four pixels left of the centre of the
 STA LASX               \ screen (#X), plus our random number, so the laser
                        \ dances to the left and right of the centre point

 LDA GNTMP              \ Add 8 to the laser temperature in GNTMP
 ADC #8
 STA GNTMP

 JSR DENGY              \ Call DENGY to deplete our energy banks by 1

.LASLI2

 LDA QQ11               \ If this is not a space view (i.e. QQ11 is non-zero)
 BNE PU1-1              \ then jump to MA9 to return from the main flight loop
                        \ (as PU1-1 is an RTS)

 LDA #32                \ Set A = 32 and Y = 224 for the first set of laser
 LDY #224               \ lines (the wider pair of lines)

 JSR las                \ Call las below to draw the first set of laser lines

 LDA #48                \ Fall through into las with A = 48 and Y = 208 to draw
 LDY #208               \ a second set of lines (the narrower pair)

                        \ The following routine draws two laser lines, one from
                        \ the centre point down to point A on the bottom row,
                        \ and the other from the centre point down to point Y
                        \ on the bottom row. We therefore get lines from the
                        \ centre point to points 32, 48, 208 and 224 along the
                        \ bottom row, giving us the triangular laser effect
                        \ we're after

.las

 STA X2                 \ Set X2 = A

 LDA LASX               \ Set (X1, Y1) to the random centre point we set above
 STA X1
 LDA LASY
 STA Y1

 LDA #2*Y-1             \ Set Y2 = 2 * #Y - 1. The constant #Y is 96, the
 STA Y2                 \ y-coordinate of the mid-point of the space view, so
                        \ this sets Y2 to 191, the y-coordinate of the bottom
                        \ pixel row of the space view

 JSR LOIN               \ Draw a line from (X1, Y1) to (X2, Y2), so that's from
                        \ the centre point to (A, 191)

 LDA LASX               \ Set (X1, Y1) to the random centre point we set above
 STA X1
 LDA LASY
 STA Y1

 STY X2                 \ Set X2 = Y

 LDA #2*Y-1             \ Set Y2 = 2 * #Y - 1, the y-coordinate of the bottom
 STA Y2                 \ pixel row of the space view (as before)

 JMP LOIN               \ Draw a line from (X1, Y1) to (X2, Y2), so that's from
                        \ the centre point to (Y, 191), and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PLUT
\       Type: Subroutine
\   Category: Flight
\    Summary: Flip the coordinate axes for the four different views
\  Deep dive: Flipping axes between space views
\
\ ------------------------------------------------------------------------------
\
\ This routine flips the relevant geometric axes in INWK depending on which
\ view we are looking through (front, rear, left, right).
\
\ Other entry points:
\
\   PU1-1               Contains an RTS
\
\ ******************************************************************************

.PLUT

 LDX VIEW               \ Load the current view into X:
                        \
                        \   0 = front
                        \   1 = rear
                        \   2 = left
                        \   3 = right

 BNE PU1                \ If the current view is the front view, return from the
 RTS                    \ subroutine, as the geometry in INWK is already correct

.PU1

 DEX                    \ Decrement the view, so now:
                        \
                        \   0 = rear
                        \   1 = left
                        \   2 = right

 BNE PU2                \ If the current view is left or right, jump to PU2,
                        \ otherwise this is the rear view, so continue on

 LDA INWK+2             \ Flip the sign of x_sign
 EOR #%10000000
 STA INWK+2

 LDA INWK+8             \ Flip the sign of z_sign
 EOR #%10000000
 STA INWK+8

 LDA INWK+10            \ Flip the sign of nosev_x_hi
 EOR #%10000000
 STA INWK+10

 LDA INWK+14            \ Flip the sign of nosev_z_hi
 EOR #%10000000
 STA INWK+14

 LDA INWK+16            \ Flip the sign of roofv_x_hi
 EOR #%10000000
 STA INWK+16

 LDA INWK+20            \ Flip the sign of roofv_z_hi
 EOR #%10000000
 STA INWK+20

 LDA INWK+22            \ Flip the sign of sidev_x_hi
 EOR #%10000000
 STA INWK+22

 LDA INWK+26            \ Flip the sign of roofv_z_hi
 EOR #%10000000
 STA INWK+26

 RTS                    \ Return from the subroutine

.PU2

                        \ We enter this with X set to the view, as follows:
                        \
                        \   1 = left
                        \   2 = right

 LDA #0                 \ Set RAT2 = 0 (left view) or -1 (right view)
 CPX #2
 ROR A
 STA RAT2

 EOR #%10000000         \ Set RAT = -1 (left view) or 0 (right view)
 STA RAT

 LDA INWK               \ Swap x_lo and z_lo
 LDX INWK+6
 STA INWK+6
 STX INWK

 LDA INWK+1             \ Swap x_hi and z_hi
 LDX INWK+7
 STA INWK+7
 STX INWK+1

 LDA INWK+2             \ Swap x_sign and z_sign
 EOR RAT                \ If left view, flip sign of new z_sign
 TAX                    \ If right view, flip sign of new x_sign
 LDA INWK+8
 EOR RAT2
 STA INWK+2
 STX INWK+8

 LDY #9                 \ Swap nosev_x_lo and nosev_z_lo
 JSR PUS1               \ Swap nosev_x_hi and nosev_z_hi
                        \ If left view, flip sign of new nosev_z_hi
                        \ If right view, flip sign of new nosev_x_hi

 LDY #15                \ Swap roofv_x_lo and roofv_z_lo
 JSR PUS1               \ Swap roofv_x_hi and roofv_z_hi
                        \ If left view, flip sign of new roofv_z_hi
                        \ If right view, flip sign of new roofv_x_hi

 LDY #21                \ Swap sidev_x_lo and sidev_z_lo
                        \ Swap sidev_x_hi and sidev_z_hi
                        \ If left view, flip sign of new sidev_z_hi
                        \ If right view, flip sign of new sidev_x_hi

.PUS1

 LDA INWK,Y             \ Swap the low x and z bytes for the vector in Y:
 LDX INWK+4,Y           \
 STA INWK+4,Y           \   * For Y =  9 swap nosev_x_lo and nosev_z_lo
 STX INWK,Y             \   * For Y = 15 swap roofv_x_lo and roofv_z_lo
                        \   * For Y = 21 swap sidev_x_lo and sidev_z_lo

 LDA INWK+1,Y           \ Swap the high x and z bytes for the offset in Y:
 EOR RAT                \
 TAX                    \   * If left view, flip sign of new z-coordinate
 LDA INWK+5,Y           \   * If right view, flip sign of new x-coordinate
 EOR RAT2
 STA INWK+1,Y
 STX INWK+5,Y

                        \ Fall through into LOOK1 to return from the subroutine

\ ******************************************************************************
\
\       Name: LOOK1
\       Type: Subroutine
\   Category: Flight
\    Summary: Initialise the space view
\
\ ------------------------------------------------------------------------------
\
\ Initialise the space view, with the direction of view given in X. This clears
\ the upper screen and draws the laser crosshairs, if the view in X has lasers
\ fitted. It also wipes all the ships from the scanner, so we can recalculate
\ ship positions for the new view (they get put back in the main flight loop).
\
\ Arguments:
\
\   X                   The space view to set:
\
\                         * 0 = front
\
\                         * 1 = rear
\
\                         * 2 = left
\
\                         * 3 = right
\
\ Other entry points:
\
\   LO2                 Contains an RTS
\
\ ******************************************************************************

.LO2

 RTS                    \ Return from the subroutine

.LQ

 STX VIEW               \ Set the current space view to X

 JSR TT66               \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 0 (space
                        \ view)

 JSR SIGHT              \ Draw the laser crosshairs

 JMP NWSTARS            \ Set up a new stardust field and return from the
                        \ subroutine using a tail call

.LOOK1

 LDA #0                 \ Set A = 0, the type number of a space view

 LDY QQ11               \ If the current view is not a space view, jump up to LQ
 BNE LQ                 \ to set up a new space view

 CPX VIEW               \ If the current view is already of type X, jump to LO2
 BEQ LO2                \ to return from the subroutine (as LO2 contains an RTS)

 STX VIEW               \ Change the current space view to X

 JSR TT66               \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 0 (space
                        \ view)

 JSR FLIP               \ Swap the x- and y-coordinates of all the stardust
                        \ particles

 JSR WPSHPS             \ Wipe all the ships from the scanner

                        \ And fall through into SIGHT to draw the laser
                        \ crosshairs

\ ******************************************************************************
\
\       Name: SIGHT
\       Type: Subroutine
\   Category: Flight
\    Summary: Draw the laser crosshairs
\
\ ******************************************************************************

.SIGHT

 LDY VIEW               \ Fetch the laser power for our new view
 LDA LASER,Y

 BEQ LO2                \ If it is zero (i.e. there is no laser fitted to this
                        \ view), jump to LO2 to return from the subroutine (as
                        \ LO2 contains an RTS)

 LDA #128               \ Set QQ19 to the x-coordinate of the centre of the
 STA QQ19               \ screen

 LDA #Y-24              \ Set QQ19+1 to the y-coordinate of the centre of the
 STA QQ19+1             \ screen, minus 24 (because TT15 will add 24 to the
                        \ coordinate when it draws the crosshairs)

 LDA #20                \ Set QQ19+2 to size 20 for the crosshairs size
 STA QQ19+2

 JSR TT15               \ Call TT15 to draw crosshairs of size 20 just to the
                        \ left of the middle of the screen

 LDA #10                \ Set QQ19+2 to size 10 for the crosshairs size
 STA QQ19+2

 JMP TT15               \ Call TT15 to draw crosshairs of size 10 at the same
                        \ location, which will remove the centre part from the
                        \ laser crosshairs, leaving a gap in the middle, and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT66
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the screen and set the current view type
\
\ ------------------------------------------------------------------------------
\
\ Clear the top part of the screen, draw a white border, and set the current
\ view type in QQ11 to A.
\
\ Arguments:
\
\   A                   The type of the new current view (see QQ11 for a list of
\                       view types)
\
\ Other entry points:
\
\   TT66-2              Call TT66 with A = 1
\
\ ******************************************************************************

 LDA #1                 \ Set the view type to 1 when this is called via the
                        \ TT66-2 entry point

.TT66

 STA QQ11               \ Set the current view type in QQ11 to A

                        \ Fall through into TTX66 to clear the screen and draw a
                        \ white border

\ ******************************************************************************
\
\       Name: TTX66
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the top part of the screen and draw a white border
\
\ ------------------------------------------------------------------------------
\
\ Clear the top part of the screen (the space view) and draw a white border
\ along the top and sides.
\
\ Other entry points:
\
\   BOX                 Just draw the border and (if this is a space view) the
\                       view name. This can be used to remove the border and
\                       view name, as it is drawn using EOR logic
\
\ ******************************************************************************

.TTX66

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

IF _SOURCE_DISC

 ASL A                  \ Set LASCT to 0, as 128 << 1 = %10000000 << 1 = 0. This
 STA LASCT              \ stops any laser pulsing

ELIF _TEXT_SOURCES

 ASL A                  \ Set LAS2 to 0, as 128 << 1 = %10000000 << 1 = 0. This
 STA LAS2               \ stops any laser pulsing

ENDIF

 STA DLY                \ Set the delay in DLY to 0, to indicate that we are
                        \ no longer showing an in-flight message, so any new
                        \ in-flight messages will be shown instantly

 STA de                 \ Clear de, the flag that appends " DESTROYED" to the
                        \ end of the next text token, so that it doesn't

 LDX #&60               \ Set X to the screen memory page for the top row of the
                        \ screen (as screen memory starts at &6000)

.BOL1

 JSR ZES1               \ Call ZES1 to zero-fill the page in X, which clears
                        \ that character row on the screen

 INX                    \ Increment X to point to the next page, i.e. the next
                        \ character row

 CPX #&78               \ Loop back to BOL1 until we have cleared page &7700,
 BNE BOL1               \ the last character row in the space view part of the
                        \ screen (the top part)

 LDX QQ22+1             \ Fetch into X the number that's shown on-screen during
                        \ the hyperspace countdown

 BEQ BOX                \ If the counter is zero then we are not counting down
                        \ to hyperspace, so jump to BOX to skip the next
                        \ instruction

 JSR ee3                \ Print the 8-bit number in X at text location (0, 1),
                        \ i.e. print the hyperspace countdown in the top-left
                        \ corner

.BOX

 LDY #1                 \ Move the text cursor to row 1
 STY YC

 LDA QQ11               \ If this is not a space view, jump to tt66 to skip
 BNE tt66               \ displaying the view name

 LDY #11                \ Move the text cursor to row 11
 STY XC

 LDA VIEW               \ Load the current view into A:
                        \
                        \   0 = front
                        \   1 = rear
                        \   2 = left
                        \   3 = right

 ORA #&60               \ OR with &60 so we get a value of &60 to &63 (96 to 99)

 JSR TT27               \ Print recursive token 96 to 99, which will be in the
                        \ range "FRONT" to "RIGHT"

 JSR TT162              \ Print a space

 LDA #175               \ Print recursive token 15 ("VIEW ")
 JSR TT27

.tt66

 LDX #0                 \ Set (X1, Y1) to (0, 0)
 STX X1
 STX Y1

 STX QQ17               \ Set QQ17 = 0 to switch to ALL CAPS

 DEX                    \ Set X2 = 255
 STX X2

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1), so
                        \ that's (0, 0) to (255, 0), along the very top of the
                        \ screen

 LDA #2                 \ Set X1 = X2 = 2
 STA X1
 STA X2

 JSR BOS2               \ Call BOS2 below, which will call BOS1 twice, and then
                        \ fall through into BOS2 again, so we effectively do
                        \ BOS1 four times, decrementing X1 and X2 each time
                        \ before calling LOIN, so this whole loop-within-a-loop
                        \ mind-bender ends up drawing these four lines:
                        \
                        \   (1, 0)   to (1, 191)
                        \   (0, 0)   to (0, 191)
                        \   (255, 0) to (255, 191)
                        \   (254, 0) to (254, 191)
                        \
                        \ So that's a 2-pixel wide vertical border along the
                        \ left edge of the upper part of the screen, and a
                        \ 2-pixel wide vertical border along the right edge

.BOS2

 JSR BOS1               \ Call BOS1 below and then fall through into it, which
                        \ ends up running BOS1 twice. This is all part of the
                        \ loop-the-loop border-drawing mind-bender explained
                        \ above

.BOS1

 LDA #0                 \ Set Y1 = 0
 STA Y1

 LDA #2*Y-1             \ Set Y2 = 2 * #Y - 1. The constant #Y is 96, the
 STA Y2                 \ y-coordinate of the mid-point of the space view, so
                        \ this sets Y2 to 191, the y-coordinate of the bottom
                        \ pixel row of the space view

 DEC X1                 \ Decrement X1 and X2
 DEC X2

 JMP LOIN               \ Draw a line from (X1, Y1) to (X2, Y2), and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: DELAY
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Wait for a specified time, in 1/50s of a second
\
\ ------------------------------------------------------------------------------
\
\ Wait for the number of vertical syncs given in Y, so this effectively waits
\ for Y/50 of a second (as the vertical sync occurs 50 times a second).
\
\ Arguments:
\
\   Y                   The number of vertical sync events to wait for
\
\ Other entry points:
\
\   DEL8                Wait for 8/50 of a second (0.16 seconds)
\
\   DELAY-5             Wait for 2/50 of a second (0.04 seconds)
\
\ ******************************************************************************

 LDY #2                 \ Set Y to 2 vertical syncs

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A0 &08, or BIT &08A0, which does nothing apart
                        \ from affect the flags

.DEL8

 LDY #8                 \ Set Y to 8 vertical syncs and fall through into DELAY
                        \ to wait for this long

.DELAY

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn

 DEY                    \ Decrement the counter in Y

 BNE DELAY              \ If Y isn't yet at zero, jump back to DELAY to wait
                        \ for another vertical sync

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: hm
\       Type: Subroutine
\   Category: Charts
\    Summary: Select the closest system and redraw the chart crosshairs
\
\ ------------------------------------------------------------------------------
\
\ Set the system closest to galactic coordinates (QQ9, QQ10) as the selected
\ system, redraw the crosshairs on the chart accordingly (if they are being
\ shown), and, if this is not a space view, clear the bottom three text rows of
\ the screen.
\
\ ******************************************************************************

.hm

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will draw the crosshairs at our current home
                        \ system

 LDA QQ11               \ If this is a space view, return from the subroutine
 BEQ SC5                \ (as SC5 contains an RTS)

                        \ Otherwise fall through into CLYNS to clear space at
                        \ the bottom of the screen

\ ******************************************************************************
\
\       Name: CLYNS
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the bottom three text rows of the mode 4 screen
\
\ ------------------------------------------------------------------------------
\
\ This routine clears some space at the bottom of the screen and moves the text
\ cursor to column 1, row 21. 
\
\ Specifically, it zeroes the following screen locations:
\
\   &7507 to &75F0
\   &7607 to &76F0
\   &7707 to &77F0
\
\ which clears the three bottom text rows of the mode 4 screen (rows 21 to 23),
\ clearing each row from text column 1 to 30 (so it doesn't overwrite the box
\ border in columns 0 and 32, or the last usable column in column 31).
\
\ Returns:
\
\   A                   A is set to 0
\
\   Y                   Y is set to 0
\
\ ******************************************************************************

.CLYNS

 LDA #20                \ Move the text cursor to row 20, near the bottom of
 STA YC                 \ the screen

 LDA #&75               \ Set the two-byte value in SC to &7507
 STA SC+1
 LDA #7
 STA SC

 JSR TT67               \ Print a newline, which will move the text cursor down
                        \ a line (to row 21) and back to column 1

 LDA #0                 \ Call LYN to clear the pixels from &7507 to &75F0
 JSR LYN

 INC SC+1               \ Increment SC+1 so SC points to &7607

 JSR LYN                \ Call LYN to clear the pixels from &7607 to &76F0

 INC SC+1               \ Increment SC+1 so SC points to &7707

 INY                    \ Move the text cursor to column 1 (as LYN sets Y to 0)
 STY XC

                        \ Fall through into LYN to clear the pixels from &7707
                        \ to &77F0

\ ******************************************************************************
\
\       Name: LYN
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear most of a row of pixels
\
\ ------------------------------------------------------------------------------
\
\ Set pixels 0-233 to the value in A, starting at the pixel pointed to by SC.
\
\ Arguments:
\
\   A                   The value to store in pixels 1-233 (the only value that
\                       is actually used is A = 0, which clears those pixels)
\
\ Returns:
\
\   Y                   Y is set to 0
\
\ Other entry points:
\
\   SC5                 Contains an RTS
\
\ ******************************************************************************

.LYN

 LDY #233               \ Set up a counter in Y to count down from pixel 233

.EE2

 STA (SC),Y             \ Store A in the Y-th byte after the address pointed to
                        \ by SC

 DEY                    \ Decrement Y

 BNE EE2                \ Loop back until Y is zero

.SC5

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SCAN
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Display the current ship on the scanner
\  Deep dive: The 3D scanner
\
\ ------------------------------------------------------------------------------
\
\ This is used both to display a ship on the scanner, and to erase it again.
\
\ Arguments:
\
\   INWK                The ship's data block
\
\ ******************************************************************************

.SCAN

 LDA INWK+31            \ Fetch the ship's scanner flag from byte #31

 AND #%00010000         \ If bit 4 is clear then the ship should not be shown
 BEQ SC5                \ on the scanner, so return from the subroutine (as SC5
                        \ contains an RTS)

 LDA TYPE               \ Fetch the ship's type from TYPE into A

 BMI SC5                \ If this is the planet or the sun, then the type will
                        \ have bit 7 set and we don't want to display it on the
                        \ scanner, so return from the subroutine (as SC5
                        \ contains an RTS)

 LDX #&FF               \ Set X to the default scanner colour of green/cyan
                        \ (a 4-pixel mode 5 byte in colour 3)

\CMP #TGL               \ These instructions are commented out in the original
\BEQ SC49               \ source. Along with the block just below, they would
                        \ set X to colour 1 (red) for asteroids, cargo canisters
                        \ and escape pods, rather than green/cyan. Presumably
                        \ they decided it didn't work that well against the red
                        \ ellipse and took this code out for release

 CMP #MSL               \ If this is not a missile, skip the following
 BNE P%+4               \ instruction

 LDX #&F0               \ This is a missile, so set X to colour 2 (yellow/white)

\CMP #AST               \ These instructions are commented out in the original
\BCC P%+4               \ source. See above for an explanation of what they do
\LDX #&0F
\.SC49

 STX COL                \ Store X, the colour of this ship on the scanner, in
                        \ COL

 LDA INWK+1             \ If any of x_hi, y_hi and z_hi have a 1 in bit 6 or 7,
 ORA INWK+4             \ then the ship is too far away to be shown on the
 ORA INWK+7             \ scanner, so return from the subroutine (as SC5
 AND #%11000000         \ contains an RTS)
 BNE SC5

                        \ If we get here, we know x_hi, y_hi and z_hi are all
                        \ 63 (%00111111) or less

                        \ Now, we convert the x_hi coordinate of the ship into
                        \ the screen x-coordinate of the dot on the scanner,
                        \ using the following (see the deep dive on "The 3D
                        \ scanner" for an explanation):
                        \
                        \   X1 = 123 + (x_sign x_hi)

 LDA INWK+1             \ Set x_hi

 CLC                    \ Clear the C flag so we can do addition below

 LDX INWK+2             \ Set X = x_sign

 BPL SC2                \ If x_sign is positive, skip the following

 EOR #%11111111         \ x_sign is negative, so flip the bits in A and subtract
 ADC #1                 \ 1 to make it a negative number (bit 7 will now be set
                        \ as we confirmed above that bits 6 and 7 are clear). So
                        \ this gives A the sign of x_sign and gives it a value
                        \ range of -63 (%11000001) to 0

.SC2

 ADC #123               \ Set X1 = 123 + x_hi
 STA X1

                        \ Next, we convert the z_hi coordinate of the ship into
                        \ the y-coordinate of the base of the ship's stick,
                        \ like this (see the deep dive on "The 3D scanner" for
                        \ an explanation):
                        \
                        \   SC = 220 - (z_sign z_hi) / 4
                        \
                        \ though the following code actually does it like this:
                        \
                        \   SC = 255 - (35 + z_hi / 4)

 LDA INWK+7             \ Set A = z_hi / 4
 LSR A                  \
 LSR A                  \ So A is in the range 0-15

 CLC                    \ Clear the C flag

 LDX INWK+8             \ Set X = z_sign

 BPL SC3                \ If z_sign is positive, skip the following

 EOR #%11111111         \ z_sign is negative, so flip the bits in A and set the
 SEC                    \ C flag. As above, this makes A negative, this time
                        \ with a range of -16 (%11110000) to -1 (%11111111). And
                        \ as we are about to do an ADC, the SEC effectively adds
                        \ another 1 to that value, giving a range of -15 to 0

.SC3

 ADC #35                \ Set A = 35 + A to give a number in the range 20 to 50

 EOR #%11111111         \ Flip all the bits and store in SC, so SC is in the
 STA SC                 \ range 205 to 235, with a higher z_hi giving a lower SC

                        \ Now for the stick height, which we calculate using the
                        \ following (see the deep dive on "The 3D scanner" for
                        \ an explanation):
                        \
                        \ A = - (y_sign y_hi) / 2

 LDA INWK+4             \ Set A = y_hi / 2
 LSR A

 CLC                    \ Clear the C flag

 LDX INWK+5             \ Set X = y_sign

 BMI SCD6               \ If y_sign is negative, skip the following, as we
                        \ already have a positive value in A

 EOR #%11111111         \ y_sign is positive, so flip the bits in A and set the
 SEC                    \ C flag. This makes A negative, and as we are about to
                        \ do an ADC below, the SEC effectively adds another 1 to
                        \ that value to implement two's complement negation, so
                        \ we don't need to add another 1 here

.SCD6

                        \ We now have all the information we need to draw this
                        \ ship on the scanner, namely:
                        \
                        \   X1 = the screen x-coordinate of the ship's dot
                        \
                        \   SC = the screen y-coordinate of the base of the
                        \        stick
                        \
                        \   A = the screen height of the ship's stick, with the
                        \       correct sign for adding to the base of the stick
                        \       to get the dot's y-coordinate
                        \
                        \ First, though, we have to make sure the dot is inside
                        \ the dashboard, by moving it if necessary

 ADC SC                 \ Set A = SC + A, so A now contains the y-coordinate of
                        \ the end of the stick, plus the length of the stick, to
                        \ give us the screen y-coordinate of the dot

 BPL ld246              \ If the result has bit 0 clear, then the result has
                        \ overflowed and is bigger than 256, so jump to ld246 to
                        \ set A to the maximum allowed value of 246 (this
                        \ instruction isn't required as we test both the maximum
                        \ and minimum below, but it might save a few cycles)

 CMP #194               \ If A >= 194, skip the following instruction, as 194 is
 BCS P%+4               \ the minimum allowed value of A

 LDA #194               \ A < 194, so set A to 194, the minimum allowed value
                        \ for the y-coordinate of our ship's dot

 CMP #247               \ If A < 247, skip the following instruction, as 246 is
 BCC P%+4               \ the maximum allowed value of A

.ld246

 LDA #246               \ A >= 247, so set A to 246, the maximum allowed value
                        \ for the y-coordinate of our ship's dot

 STA Y1                 \ Store A in Y1, as it now contains the screen
                        \ y-coordinate for the ship's dot, clipped so that it
                        \ fits within the dashboard

 SEC                    \ Set A = A - SC to get the stick length, by reversing
 SBC SC                 \ the ADC SC we did above. This clears the C flag if the
                        \ result is negative (i.e. the stick length is negative)
                        \ and sets it if the result is positive (i.e. the stick
                        \ length is negative)

                        \ So now we have the following:
                        \
                        \   X1 = the screen x-coordinate of the ship's dot,
                        \        clipped to fit into the dashboard
                        \
                        \   Y1 = the screen y-coordinate of the ship's dot,
                        \        clipped to fit into the dashboard
                        \
                        \   SC = the screen y-coordinate of the base of the
                        \        stick
                        \
                        \   A = the screen height of the ship's stick, with the
                        \       correct sign for adding to the base of the stick
                        \       to get the dot's y-coordinate
                        \
                        \   C = 0 if A is negative, 1 if A is positive
                        \
                        \ and we can get on with drawing the dot and stick

 PHP                    \ Store the flags (specifically the C flag) from the
                        \ above subtraction

\BCS SC48               \ These instructions are commented out in the original
\EOR #&FF               \ source. They would negate A if the C flag were set,
\ADC #1                 \ which would reverse the direction of all the sticks,
                        \ so you could turn your joystick around. Perhaps one of
                        \ the authors' test sticks was easier to use upside
                        \ down? Who knows...

.SC48

 PHA                    \ Store the stick height in A on the stack

 JSR CPIX4              \ Draw a double-height dot at (X1, Y1). This also leaves
                        \ the following variables set up for the dot's top-right
                        \ pixel, the last pixel to be drawn (as the dot gets
                        \ drawn from the bottom up):
                        \
                        \   SC(1 0) = screen address of the pixel's character
                        \             block
                        \
                        \   Y = number of the character row containing the pixel
                        \
                        \   X = the pixel's number (0-3) in that row
                        \
                        \ We can use there as the starting point for drawing the
                        \ stick, if there is one

 LDA CTWOS+1,X          \ Load the same mode 5 1-pixel byte that we just used
 AND COL                \ for the top-right pixel, and mask it with the same
 STA X1                 \ colour, storing the result in X1, so we can use it as
                        \ the character row byte for the stick

 PLA                    \ Restore the stick height from the stack into A

 PLP                    \ Restore the flags from above, so the C flag once again
                        \ reflects the sign of the stick height

 TAX                    \ Copy the stick height into X

 BEQ RTS                \ If the stick height is zero, then there is no stick to
                        \ draw, so return from the subroutine (as RTS contains
                        \ an RTS)

 BCC RTS+1              \ If the C flag is clear then the stick height in A is
                        \ negative, so jump down to RTS+1

.VLL1

                        \ If we get here then the stick length is positive (so
                        \ the dot is below the ellipse and the stick is above
                        \ the dot, and we need to draw the stick upwards from
                        \ the dot)

 DEY                    \ We want to draw the stick upwards, so decrement the
                        \ pixel row in Y

 BPL VL1                \ If Y is still positive then it correctly points at the
                        \ line above, so jump to VL1 to skip the following

 LDY #7                 \ We just decremented Y up through the top of the
                        \ character block, so we need to move it to the last row
                        \ in the character above, so set Y to 7, the number of
                        \ the last row

 DEC SC+1               \ Decrement the high byte of the screen address to move
                        \ to the character block above

.VL1

 LDA X1                 \ Set A to the character row byte for the stick, which
                        \ we stored in X1 above, and which has the same pixel
                        \ pattern as the bottom-right pixel of the dot (so the
                        \ stick comes out of the right side of the dot)

 EOR (SC),Y             \ Draw the stick on row Y of the character block using
 STA (SC),Y             \ EOR logic

 DEX                    \ Decrement the (positive) stick height in X

 BNE VLL1               \ If we still have more stick to draw, jump up to VLL1
                        \ to draw the next pixel

.RTS

 RTS                    \ Return from the subroutine

                        \ If we get here then the stick length is negative (so
                        \ the dot is above the ellipse and the stick is below
                        \ the dot, and we need to draw the stick downwards from
                        \ the dot)

 INY                    \ We want to draw the stick downwards, so we first
                        \ increment the row counter so that it's pointing to the
                        \ bottom-right pixel in the dot (as opposed to the top-
                        \ right pixel that the call to CPIX4 finished on)

 CPY #8                 \ If the row number in Y is less than 8, then it
 BNE P%+6               \ correctly points at the next line down, so jump to
                        \ VLL2 to skip the following

 LDY #0                 \ We just incremented Y down through the bottom of the
                        \ character block, so we need to move it to the first
                        \ row in the character below, so set Y to 0, the number
                        \ of the first row

 INC SC+1               \ Increment the high byte of the screen address to move
                        \ to the character block above

.VLL2

 INY                    \ We want to draw the stick itself, heading downwards,
                        \ so increment the pixel row in Y

 CPY #8                 \ If the row number in Y is less than 8, then it
 BNE VL2                \ correctly points at the next line down, so jump to
                        \ VL2 to skip the following

 LDY #0                 \ We just incremented Y down through the bottom of the
                        \ character block, so we need to move it to the first
                        \ row in the character below, so set Y to 0, the number
                        \ of the first row

 INC SC+1               \ Increment the high byte of the screen address to move
                        \ to the character block above

.VL2

 LDA X1                 \ Set A to the character row byte for the stick, which
                        \ we stored in X1 above, and which has the same pixel
                        \ pattern as the bottom-right pixel of the dot (so the
                        \ stick comes out of the right side of the dot)

 EOR (SC),Y             \ Draw the stick on row Y of the character block using
 STA (SC),Y             \ EOR logic

 INX                    \ Increment the (negative) stick height in X

 BNE VLL2               \ If we still have more stick to draw, jump up to VLL2
                        \ to draw the next pixel

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: WSCAN
\       Type: Subroutine
\   Category: Screen mode
\    Summary: Wait for the vertical sync
\
\ ------------------------------------------------------------------------------
\
\ Wait for vertical sync to occur on the video system - in other words, wait
\ for the screen to start its refresh cycle, which it does 50 times a second
\ (50Hz).
\
\ ******************************************************************************

.WSCAN

 LDA #0                 \ Set DL to 0
 STA DL

 LDA DL                 \ Loop round these two instructions until DL is no
 BEQ P%-2               \ longer 0 (DL gets set to 30 in the LINSCN routine,
                        \ which is run when vertical sync has occurred on the
                        \ video system, so DL will change to a non-zero value
                        \ at the start of each screen refresh)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save ELTC.bin
\
\ ******************************************************************************

PRINT "ELITE C"
PRINT "Assembled at ", ~CODE_C%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_C%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_C%

PRINT "S.ELTC ", ~CODE_C%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_C%
SAVE "3-assembled-output/ELTC.bin", CODE_C%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE D FILE
\
\ Produces the binary file ELTD.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CODE_D% = P%
LOAD_D% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: tnpr
\       Type: Subroutine
\   Category: Market
\    Summary: Work out if we have space for a specific amount of cargo
\
\ ------------------------------------------------------------------------------
\
\ Given a market item and an amount, work out whether there is room in the
\ cargo hold for this item.
\
\ For standard tonne canisters, the limit is given by the type of cargo hold we
\ have, with a standard cargo hold having a capacity of 20t and an extended
\ cargo bay being 35t.
\
\ For items measured in kg (gold, platinum), g (gem-stones) and alien items,
\ the individual limit on each of these is 200 units.
\
\ Arguments:
\
\   A                   The number of units of this market item
\
\   QQ29                The type of market item (see QQ23 for a list of market
\                       item numbers)
\
\ Returns:
\
\   A                   A is preserved
\
\   C flag              Returns the result:
\
\                         * Set if there is no room for this item
\
\                         * Clear if there is room for this item
\
\ ******************************************************************************

.tnpr

 PHA                    \ Store A on the stack

 LDX #12                \ If QQ29 > 12 then jump to kg below, as this cargo
 CPX QQ29               \ type is gold, platinum, gem-stones or alien items,
 BCC kg                 \ and they have different cargo limits to the standard
                        \ tonne canisters

.Tml

                        \ Here we count the tonne canisters we have in the hold
                        \ and add to A to see if we have enough room for A more
                        \ tonnes of cargo, using X as the loop counter, starting
                        \ with X = 12

 ADC QQ20,X             \ Set A = A + the number of tonnes we have in the hold
                        \ of market item number X. Note that the first time we
                        \ go round this loop, the C flag is set (as we didn't
                        \ branch with the BCC above, so the effect of this loop
                        \ is to count the number of tonne canisters in the hold,
                        \ and add 1

 DEX                    \ Decrement the loop counter

 BPL Tml                \ Loop back to add in the next market item in the hold,
                        \ until we have added up all market items from 12
                        \ (minerals) down to 0 (food)

 CMP CRGO               \ If A < CRGO then the C flag will be clear (we have
                        \ room in the hold)
                        \
                        \ If A >= CRGO then the C flag will be set (we do not
                        \ have room in the hold)
                        \
                        \ This works because A contains the number of canisters
                        \ plus 1, while CRGO contains our cargo capacity plus 2,
                        \ so if we actually have "a" canisters and a capacity
                        \ of "c", then:
                        \
                        \ A < CRGO means: a+1 <  c+2
                        \                 a   <  c+1
                        \                 a   <= c
                        \
                        \ So this is why the value in CRGO is 2 higher than the
                        \ actual cargo bay size, i.e. it's 22 for the standard
                        \ 20-tonne bay, and 37 for the large 35-tonne bay

 PLA                    \ Restore A from the stack

 RTS                    \ Return from the subroutine

.kg

                        \ Here we count the number of items of this type that
                        \ we already have in the hold, and add to A to see if
                        \ we have enough room for A more units

 LDY QQ29               \ Set Y to the item number we want to add

 ADC QQ20,Y             \ Set A = A + the number of units of this item that we
                        \ already have in the hold

 CMP #200               \ Is the result greater than 200 (the limit on
                        \ individual stocks of gold, platinum, gem-stones and
                        \ alien items)?
                        \
                        \ If so, this sets the C flag (no room)
                        \
                        \ Otherwise it is clear (we have room)

 PLA                    \ Restore A from the stack

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT20
\       Type: Subroutine
\   Category: Universe
\    Summary: Twist the selected system's seeds four times
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Twist the three 16-bit seeds in QQ15 (selected system) four times, to
\ generate the next system.
\
\ ******************************************************************************

.TT20

 JSR P%+3               \ This line calls the line below as a subroutine, which
                        \ does two twists before returning here, and then we
                        \ fall through to the line below for another two
                        \ twists, so the net effect of these two consecutive
                        \ JSR calls is four twists, not counting the ones
                        \ inside your head as you try to follow this process

 JSR P%+3               \ This line calls TT54 as a subroutine to do a twist,
                        \ and then falls through into TT54 to do another twist
                        \ before returning from the subroutine

\ ******************************************************************************
\
\       Name: TT54
\       Type: Subroutine
\   Category: Universe
\    Summary: Twist the selected system's seeds
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ This routine twists the three 16-bit seeds in QQ15 once.
\
\ ******************************************************************************

.TT54

 LDA QQ15               \ X = tmp_lo = s0_lo + s1_lo
 CLC
 ADC QQ15+2
 TAX

 LDA QQ15+1             \ Y = tmp_hi = s1_hi + s1_hi + C
 ADC QQ15+3
 TAY

 LDA QQ15+2             \ s0_lo = s1_lo
 STA QQ15

 LDA QQ15+3             \ s0_hi = s1_hi
 STA QQ15+1

 LDA QQ15+5             \ s1_hi = s2_hi
 STA QQ15+3

 LDA QQ15+4             \ s1_lo = s2_lo
 STA QQ15+2

 CLC                    \ s2_lo = X + s1_lo
 TXA
 ADC QQ15+2
 STA QQ15+4

 TYA                    \ s2_hi = Y + s1_hi + C
 ADC QQ15+3
 STA QQ15+5

 RTS                    \ The twist is complete so return from the subroutine

\ ******************************************************************************
\
\       Name: TT146
\       Type: Subroutine
\   Category: Text
\    Summary: Print the distance to the selected system in light years
\
\ ------------------------------------------------------------------------------
\
\ If it is non-zero, print the distance to the selected system in light years.
\ If it is zero, just move the text cursor down a line.
\
\ Specifically, if the distance in QQ8 is non-zero, print token 31 ("DISTANCE"),
\ then a colon, then the distance to one decimal place, then token 35 ("LIGHT
\ YEARS"). If the distance is zero, move the cursor down one line.
\
\ ******************************************************************************

.TT146

 LDA QQ8                \ Take the two bytes of the 16-bit value in QQ8 and
 ORA QQ8+1              \ OR them together to check whether there are any
 BNE TT63               \ non-zero bits, and if so, jump to TT63 to print the
                        \ distance

 INC YC                 \ The distance is zero, so we just move the text cursor
 RTS                    \ in YC down by one line and return from the subroutine

.TT63

 LDA #191               \ Print recursive token 31 ("DISTANCE") followed by
 JSR TT68               \ a colon

 LDX QQ8                \ Load (Y X) from QQ8, which contains the 16-bit
 LDY QQ8+1              \ distance we want to show

 SEC                    \ Set the C flag so that the call to pr5 will include a
                        \ decimal point, and display the value as (Y X) / 10

 JSR pr5                \ Print (Y X) to 5 digits, including a decimal point

 LDA #195               \ Set A to the recursive token 35 (" LIGHT YEARS") and
                        \ fall through into TT60 to print the token followed
                        \ by a paragraph break

\ ******************************************************************************
\
\       Name: TT60
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token and a paragraph break
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). Then print a paragraph break (a blank line between
\ paragraphs) by moving the cursor down a line, setting Sentence Case, and then
\ printing a newline.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.TT60

 JSR TT27               \ Print the text token in A and fall through into TTX69
                        \ to print the paragraph break

\ ******************************************************************************
\
\       Name: TTX69
\       Type: Subroutine
\   Category: Text
\    Summary: Print a paragraph break
\
\ ------------------------------------------------------------------------------
\
\ Print a paragraph break (a blank line between paragraphs) by moving the cursor
\ down a line, setting Sentence Case, and then printing a newline.
\
\ ******************************************************************************

.TTX69

 INC YC                 \ Move the text cursor down a line

                        \ Fall through into TT69 to set Sentence Case and print
                        \ a newline

\ ******************************************************************************
\
\       Name: TT69
\       Type: Subroutine
\   Category: Text
\    Summary: Set Sentence Case and print a newline
\
\ ******************************************************************************

.TT69

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

                        \ Fall through into TT67 to print a newline

\ ******************************************************************************
\
\       Name: TT67
\       Type: Subroutine
\   Category: Text
\    Summary: Print a newline
\
\ ******************************************************************************

.TT67

 LDA #13                \ Load a newline character into A

 JMP TT27               \ Print the text token in A and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT70
\       Type: Subroutine
\   Category: Text
\    Summary: Display "MAINLY " and jump to TT72
\
\ ------------------------------------------------------------------------------
\
\ This subroutine is called by TT25 when displaying a system's economy.
\
\ ******************************************************************************

.TT70

 LDA #173               \ Print recursive token 13 ("MAINLY ")
 JSR TT27

 JMP TT72               \ Jump to TT72 to continue printing system data as part
                        \ of routine TT25

\ ******************************************************************************
\
\       Name: spc
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a space
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token) followed by a space.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.spc

 JSR TT27               \ Print the text token in A

 JMP TT162              \ Print a space and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: TT25
\       Type: Subroutine
\   Category: Universe
\    Summary: Show the Data on System screen (red key f6)
\  Deep dive: Generating system data
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   TT72                Used by TT70 to re-enter the routine after displaying
\                       "MAINLY" for the economy type
\
\ ******************************************************************************

.TT25

 JSR TT66-2             \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 1

 LDA #9                 \ Move the text cursor to column 9
 STA XC

 LDA #163               \ Print recursive token 3 as a title in capitals at
 JSR TT27               \ the top ("DATA ON {selected system name}")

 JSR NLIN               \ Draw a horizontal line underneath the title

 JSR TTX69              \ Print a paragraph break and set Sentence Case

 INC YC                 \ Move the text cursor down one more line

 JSR TT146              \ If the distance to this system is non-zero, print
                        \ "DISTANCE", then the distance, "LIGHT YEARS" and a
                        \ paragraph break, otherwise just move the cursor down
                        \ a line

 LDA #194               \ Print recursive token 34 ("ECONOMY") followed by
 JSR TT68               \ a colon

 LDA QQ3                \ The system economy is determined by the value in QQ3,
                        \ so fetch it into A. First we work out the system's
                        \ prosperity as follows:
                        \
                        \   QQ3 = 0 or 5 = %000 or %101 = Rich
                        \   QQ3 = 1 or 6 = %001 or %110 = Average
                        \   QQ3 = 2 or 7 = %010 or %111 = Poor
                        \   QQ3 = 3 or 4 = %011 or %100 = Mainly

 CLC                    \ If (QQ3 + 1) >> 1 = %10, i.e. if QQ3 = %011 or %100
 ADC #1                 \ (3 or 4), then call TT70, which prints "MAINLY " and
 LSR A                  \ jumps down to TT72 to print the type of economy
 CMP #%00000010
 BEQ TT70

 LDA QQ3                \ The LSR A above shifted bit 0 of QQ3 into the C flag,
 BCC TT71               \ so this jumps to TT71 if bit 0 of QQ3 is 0, in other
                        \ words if QQ3 = %000, %001 or %010 (0, 1 or 2)

 SBC #5                 \ Here QQ3 = %101, %110 or %111 (5, 6 or 7), so subtract
 CLC                    \ 5 to bring it down to 0, 1 or 2 (the C flag is already
                        \ set so the SBC will be correct)

.TT71

 ADC #170               \ A is now 0, 1 or 2, so print recursive token 10 + A.
 JSR TT27               \ This means that:
                        \
                        \   QQ3 = 0 or 5 prints token 10 ("RICH ")
                        \   QQ3 = 1 or 6 prints token 11 ("AVERAGE ")
                        \   QQ3 = 2 or 7 prints token 12 ("POOR ")

.TT72

 LDA QQ3                \ Now to work out the type of economy, which is
 LSR A                  \ determined by bit 2 of QQ3, as follows:
 LSR A                  \
                        \   QQ3 bit 2 = 0 = Industrial
                        \   QQ3 bit 2 = 1 = Agricultural
                        \
                        \ So we fetch QQ3 into A and set A = bit 2 of QQ3 using
                        \ two right shifts (which will work as QQ3 is only a
                        \ 3-bit number)

 CLC                    \ Print recursive token 8 + A, followed by a paragraph
 ADC #168               \ break and Sentence Case, so:
 JSR TT60               \
                        \   QQ3 bit 2 = 0 prints token 8 ("INDUSTRIAL")
                        \   QQ3 bit 2 = 1 prints token 9 ("AGRICULTURAL")

 LDA #162               \ Print recursive token 2 ("GOVERNMENT") followed by
 JSR TT68               \ a colon

 LDA QQ4                \ The system economy is determined by the value in QQ4,
                        \ so fetch it into A

 CLC                    \ Print recursive token 17 + A, followed by a paragraph
 ADC #177               \ break and Sentence Case, so:
 JSR TT60               \
                        \   QQ4 = 0 prints token 17 ("ANARCHY")
                        \   QQ4 = 1 prints token 18 ("FEUDAL")
                        \   QQ4 = 2 prints token 19 ("MULTI-GOVERNMENT")
                        \   QQ4 = 3 prints token 20 ("DICTATORSHIP")
                        \   QQ4 = 4 prints token 21 ("COMMUNIST")
                        \   QQ4 = 5 prints token 22 ("CONFEDERACY")
                        \   QQ4 = 6 prints token 23 ("DEMOCRACY")
                        \   QQ4 = 7 prints token 24 ("CORPORATE STATE")

 LDA #196               \ Print recursive token 36 ("TECH.LEVEL") followed by a
 JSR TT68               \ colon

 LDX QQ5                \ Fetch the tech level from QQ5 and increment it, as it
 INX                    \ is stored in the range 0-14 but the displayed range
                        \ should be 1-15

 CLC                    \ Call pr2 to print the technology level as a 3-digit
 JSR pr2                \ number without a decimal point (by clearing the C
                        \ flag)

 JSR TTX69              \ Print a paragraph break and set Sentence Case

 LDA #192               \ Print recursive token 32 ("POPULATION") followed by a
 JSR TT68               \ colon

 SEC                    \ Call pr2 to print the population as a 3-digit number
 LDX QQ6                \ with a decimal point (by setting the C flag), so the
 JSR pr2                \ number printed will be population / 10

 LDA #198               \ Print recursive token 38 (" BILLION"), followed by a
 JSR TT60               \ paragraph break and Sentence Case

 LDA #'('               \ Print an opening bracket
 JSR TT27

 LDA QQ15+4             \ Now to calculate the species, so first check bit 7 of
 BMI TT75               \ s2_lo, and if it is set, jump to TT75 as this is an
                        \ alien species

 LDA #188               \ Bit 7 of s2_lo is clear, so print recursive token 28
 JSR TT27               \ ("HUMAN COLONIAL")

 JMP TT76               \ Jump to TT76 to print "S)" and a paragraph break, so
                        \ the whole species string is "(HUMAN COLONIALS)"

.TT75

 LDA QQ15+5             \ This is an alien species, and we start with the first
 LSR A                  \ adjective, so fetch bits 2-7 of s2_hi into A and push
 LSR A                  \ onto the stack so we can use this later
 PHA

 AND #%00000111         \ Set A = bits 0-2 of A (so that's bits 2-4 of s2_hi)

 CMP #3                 \ If A >= 3, jump to TT205 to skip the first adjective,
 BCS TT205

 ADC #227               \ Otherwise A = 0, 1 or 2, so print recursive token
 JSR spc                \ 67 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 67 ("LARGE") and a space
                        \   A = 1 prints token 67 ("FIERCE") and a space
                        \   A = 2 prints token 67 ("SMALL") and a space

.TT205

 PLA                    \ Now for the second adjective, so restore A to bits
 LSR A                  \ 2-7 of s2_hi, and throw away bits 2-4 to leave
 LSR A                  \ A = bits 5-7 of s2_hi
 LSR A

 CMP #6                 \ If A >= 6, jump to TT206 to skip the second adjective
 BCS TT206

 ADC #230               \ Otherwise A = 0 to 5, so print recursive token
 JSR spc                \ 70 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 70 ("GREEN") and a space
                        \   A = 1 prints token 71 ("RED") and a space
                        \   A = 2 prints token 72 ("YELLOW") and a space
                        \   A = 3 prints token 73 ("BLUE") and a space
                        \   A = 4 prints token 74 ("BLACK") and a space
                        \   A = 5 prints token 75 ("HARMLESS") and a space

.TT206

 LDA QQ15+3             \ Now for the third adjective, so EOR the high bytes of
 EOR QQ15+1             \ s0 and s1 and extract bits 0-2 of the result:
 AND #%00000111         \
 STA QQ19               \   A = (s0_hi EOR s1_hi) AND %111
                        \
                        \ storing the result in QQ19 so we can use it later

 CMP #6                 \ If A >= 6, jump to TT207 to skip the third adjective
 BCS TT207

 ADC #236               \ Otherwise A = 0 to 5, so print recursive token
 JSR spc                \ 76 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 76 ("SLIMY") and a space
                        \   A = 1 prints token 77 ("BUG-EYED") and a space
                        \   A = 2 prints token 78 ("HORNED") and a space
                        \   A = 3 prints token 79 ("BONY") and a space
                        \   A = 4 prints token 80 ("FAT") and a space
                        \   A = 5 prints token 81 ("FURRY") and a space

.TT207

 LDA QQ15+5             \ Now for the actual species, so take bits 0-1 of
 AND #%00000011         \ s2_hi, add this to the value of A that we used for
 CLC                    \ the third adjective, and take bits 0-2 of the result
 ADC QQ19
 AND #%00000111

 ADC #242               \ A = 0 to 7, so print recursive token 82 + A, so:
 JSR TT27               \
                        \   A = 0 prints token 76 ("RODENT")
                        \   A = 1 prints token 76 ("FROG")
                        \   A = 2 prints token 76 ("LIZARD")
                        \   A = 3 prints token 76 ("LOBSTER")
                        \   A = 4 prints token 76 ("BIRD")
                        \   A = 5 prints token 76 ("HUMANOID")
                        \   A = 6 prints token 76 ("FELINE")
                        \   A = 7 prints token 76 ("INSECT")

.TT76

 LDA #'S'               \ Print an "S" to pluralise the species
 JSR TT27

 LDA #')'               \ And finally, print a closing bracket, followed by a
 JSR TT60               \ paragraph break and Sentence Case, to end the species
                        \ section

 LDA #193               \ Print recursive token 33 ("GROSS PRODUCTIVITY"),
 JSR TT68               \ followed by colon

 LDX QQ7                \ Fetch the 16-bit productivity value from QQ7 into
 LDY QQ7+1              \ (Y X)

 JSR pr6                \ Print (Y X) to 5 digits with no decimal point

 JSR TT162              \ Print a space

 LDA #0                 \ Set QQ17 = 0 to switch to ALL CAPS
 STA QQ17

 LDA #'M'               \ Print "M"
 JSR TT27

 LDA #226               \ Print recursive token 66 (" CR"), followed by a
 JSR TT60               \ paragraph break and Sentence Case

 LDA #250               \ Print recursive token 90 ("AVERAGE RADIUS"), followed
 JSR TT68               \ by a colon

                        \ The average radius is calculated like this:
                        \
                        \   ((s2_hi AND %1111) + 11) * 256 + s1_hi
                        \
                        \ or, in terms of memory locations:
                        \
                        \   ((QQ15+5 AND %1111) + 11) * 256 + QQ15+3
                        \
                        \ Because the multiplication is by 256, this is the
                        \ same as saying a 16-bit number, with high byte:
                        \
                        \   (QQ15+5 AND %1111) + 11
                        \
                        \ and low byte:
                        \
                        \   QQ15+3
                        \
                        \ so we can set this up in (Y X) and call the pr5
                        \ routine to print it out

 LDA QQ15+5             \ Set A = QQ15+5
 LDX QQ15+3             \ Set X = QQ15+3

 AND #%00001111         \ Set Y = (A AND %1111) + 11
 CLC
 ADC #11
 TAY

 JSR pr5                \ Print (Y X) to 5 digits, not including a decimal
                        \ point, as the C flag will be clear (as the maximum
                        \ radius will always fit into 16 bits)

 JSR TT162              \ Print a space

 LDA #'k'               \ Print "km", returning from the subroutine using a
 JSR TT26               \ tail call
 LDA #'m'
 JMP TT26

\ ******************************************************************************
\
\       Name: TT24
\       Type: Subroutine
\   Category: Universe
\    Summary: Calculate system data from the system seeds
\  Deep dive: Generating system data
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Calculate system data from the seeds in QQ15 and store them in the relevant
\ locations. Specifically, this routine calculates the following from the three
\ 16-bit seeds in QQ15 (using only s0_hi, s1_hi and s1_lo):
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
\ ******************************************************************************

.TT24

 LDA QQ15+1             \ Fetch s0_hi and extract bits 0-2 to determine the
 AND #%00000111         \ system's economy, and store in QQ3
 STA QQ3

 LDA QQ15+2             \ Fetch s1_lo and extract bits 3-5 to determine the
 LSR A                  \ system's government, and store in QQ4
 LSR A
 LSR A
 AND #%00000111
 STA QQ4

 LSR A                  \ If government isn't anarchy or feudal, skip to TT77,
 BNE TT77               \ as we need to fix the economy of anarchy and feudal
                        \ systems so they can't be rich

 LDA QQ3                \ Set bit 1 of the economy in QQ3 to fix the economy
 ORA #%00000010         \ for anarchy and feudal governments
 STA QQ3

.TT77

 LDA QQ3                \ Now to work out the tech level, which we do like this:
 EOR #%00000111         \
 CLC                    \   flipped_economy + (s1_hi AND %11) + (government / 2)
 STA QQ5                \
                        \ or, in terms of memory locations:
                        \
                        \   QQ5 = (QQ3 EOR %111) + (QQ15+3 AND %11) + (QQ4 / 2)
                        \
                        \ We start by setting QQ5 = QQ3 EOR %111

 LDA QQ15+3             \ We then take the first 2 bits of s1_hi (QQ15+3) and
 AND #%00000011         \ add it into QQ5
 ADC QQ5
 STA QQ5

 LDA QQ4                \ And finally we add QQ4 / 2 and store the result in
 LSR A                  \ QQ5, using LSR then ADC to divide by 2, which rounds
 ADC QQ5                \ up the result for odd-numbered government types
 STA QQ5

 ASL A                  \ Now to work out the population, like so:
 ASL A                  \
 ADC QQ3                \   (tech level * 4) + economy + government + 1
 ADC QQ4                \
 ADC #1                 \ or, in terms of memory locations:
 STA QQ6                \
                        \   QQ6 = (QQ5 * 4) + QQ3 + QQ4 + 1

 LDA QQ3                \ Finally, we work out productivity, like this:
 EOR #%00000111         \
 ADC #3                 \  (flipped_economy + 3) * (government + 4)
 STA P                  \                        * population
 LDA QQ4                \                        * 8
 ADC #4                 \
 STA Q                  \ or, in terms of memory locations:
 JSR MULTU              \
                        \   QQ7 = (QQ3 EOR %111 + 3) * (QQ4 + 4) * QQ6 * 8
                        \
                        \ We do the first step by setting P to the first
                        \ expression in brackets and Q to the second, and
                        \ calling MULTU, so now (A P) = P * Q. The highest this
                        \ can be is 10 * 11 (as the maximum values of economy
                        \ and government are 7), so the high byte of the result
                        \ will always be 0, so we actually have:
                        \
                        \   P = P * Q
                        \     = (flipped_economy + 3) * (government + 4)

 LDA QQ6                \ We now take the result in P and multiply by the
 STA Q                  \ population to get the productivity, by setting Q to
 JSR MULTU              \ the population from QQ6 and calling MULTU again, so
                        \ now we have:
                        \
                        \   (A P) = P * population

 ASL P                  \ Next we multiply the result by 8, as a 16-bit number,
 ROL A                  \ so we shift both bytes to the left three times, using
 ASL P                  \ the C flag to carry bits from bit 7 of the low byte
 ROL A                  \ into bit 0 of the high byte
 ASL P
 ROL A

 STA QQ7+1              \ Finally, we store the productivity in two bytes, with
 LDA P                  \ the low byte in QQ7 and the high byte in QQ7+1
 STA QQ7

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT22
\       Type: Subroutine
\   Category: Charts
\    Summary: Show the Long-range Chart (red key f4)
\
\ ******************************************************************************

.TT22

 LDA #64                \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 32 (Long-
                        \ range Chart)

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

 LDA #199               \ Print recursive token 39 ("GALACTIC CHART{galaxy
 JSR TT27               \ number right-aligned to width 3}")

 JSR NLIN               \ Draw a horizontal line at pixel row 23 to box in the
                        \ title and act as the top frame of the chart, and move
                        \ the text cursor down one line

 LDA #152               \ Draw a screen-wide horizontal line at pixel row 152
 JSR NLIN2              \ for the bottom edge of the chart, so the chart itself
                        \ is 128 pixels high, starting on row 24 and ending on
                        \ row 151

 JSR TT14               \ Call TT14 to draw a circle with crosshairs at the
                        \ current system's galactic coordinates

 LDX #0                 \ We're now going to plot each of the galaxy's systems,
                        \ so set up a counter in X for each system, starting at
                        \ 0 and looping through to 255

.TT83

 STX XSAV               \ Store the counter in XSAV

 LDX QQ15+3             \ Fetch the s1_hi seed into X, which gives us the
                        \ galactic x-coordinate of this system

 LDY QQ15+4             \ Fetch the s2_lo seed and set bits 4 and 6, storing the
 TYA                    \ result in ZZ to give a random number between 80 and
 ORA #%01010000         \ (but which will always be the same for this system).
 STA ZZ                 \ We use this value to determine the size of the point
                        \ for this system on the chart by passing it as the
                        \ distance argument to the PIXEL routine below

 LDA QQ15+1             \ Fetch the s0_hi seed into A, which gives us the
                        \ galactic y-coordinate of this system

 LSR A                  \ We halve the y-coordinate because the galaxy in
                        \ in Elite is rectangular rather than square, and is
                        \ twice as wide (x-axis) as it is high (y-axis), so the
                        \ chart is 256 pixels wide and 128 high

 CLC                    \ Add 24 to the halved y-coordinate and store in XX15+1
 ADC #24                \ (as the top of the chart is on pixel row 24, just
 STA XX15+1             \ below the line we drew on row 23 above)

 JSR PIXEL              \ Call PIXEL to draw a point at (X, A), with the size of
                        \ the point dependent on the distance specified in ZZ
                        \ (so a high value of ZZ will produce a 1-pixel point,
                        \ a medium value will produce a 2-pixel dash, and a
                        \ small value will produce a 4-pixel square)

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 LDX XSAV               \ Restore the loop counter from XSAV

 INX                    \ Increment the counter

 BNE TT83               \ If X > 0 then we haven't done all 256 systems yet, so
                        \ loop back up to TT83

 LDA QQ9                \ Set QQ19 to the selected system's x-coordinate
 STA QQ19

 LDA QQ10               \ Set QQ19+1 to the selected system's y-coordinate,
 LSR A                  \ halved to fit it into the chart
 STA QQ19+1

 LDA #4                 \ Set QQ19+2 to size 4 for the crosshairs size
 STA QQ19+2

                        \ Fall through into TT15 to draw crosshairs of size 4 at
                        \ the selected system's coordinates

\ ******************************************************************************
\
\       Name: TT15
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a set of crosshairs
\
\ ------------------------------------------------------------------------------
\
\ For all views except the Short-range Chart, the centre is drawn 24 pixels to
\ the right of the y-coordinate given.
\
\ Arguments:
\
\   QQ19                The pixel x-coordinate of the centre of the crosshairs
\
\   QQ19+1              The pixel y-coordinate of the centre of the crosshairs
\
\   QQ19+2              The size of the crosshairs
\
\ ******************************************************************************

.TT15

 LDA #24                \ Set A to 24, which we will use as the minimum
                        \ screen indent for the crosshairs (i.e. the minimum
                        \ distance from the top-left corner of the screen)

 LDX QQ11               \ If the current view is not the Short-range Chart,
 BPL P%+4               \ which is the only view with bit 7 set, then skip the
                        \ following instruction

 LDA #0                 \ This is the Short-range Chart, so set A to 0, so the
                        \ crosshairs can go right up against the screen edges

 STA QQ19+5             \ Set QQ19+5 to A, which now contains the correct indent
                        \ for this view

 LDA QQ19               \ Set A = crosshairs x-coordinate - crosshairs size
 SEC                    \ to get the x-coordinate of the left edge of the
 SBC QQ19+2             \ crosshairs

 BCS TT84               \ If the above subtraction didn't underflow, then A is
                        \ positive, so skip the next instruction

 LDA #0                 \ The subtraction underflowed, so set A to 0 so the
                        \ crosshairs don't spill out of the left of the screen

.TT84

                        \ In the following, the authors have used XX15 for
                        \ temporary storage. XX15 shares location with X1, Y1,
                        \ X2 and Y2, so in the following, you can consider
                        \ the variables like this:
                        \
                        \   XX15   is the same as X1
                        \   XX15+1 is the same as Y1
                        \   XX15+2 is the same as X2
                        \   XX15+3 is the same as Y2
                        \
                        \ Presumably this routine was written at a different
                        \ time to the line-drawing routine, before the two
                        \ workspaces were merged to save space

 STA XX15               \ Set XX15 (X1) = A (the x-coordinate of the left edge
                        \ of the crosshairs)

 LDA QQ19               \ Set A = crosshairs x-coordinate + crosshairs size
 CLC                    \ to get the x-coordinate of the right edge of the
 ADC QQ19+2             \ crosshairs

 BCC P%+4               \ If the above addition didn't overflow, then A is
                        \ correct, so skip the next instruction

 LDA #255               \ The addition overflowed, so set A to 255 so the
                        \ crosshairs don't spill out of the right of the screen
                        \ (as 255 is the x-coordinate of the rightmost pixel
                        \ on-screen)

 STA XX15+2             \ Set XX15+2 (X2) = A (the x-coordinate of the right
                        \ edge of the crosshairs)

 LDA QQ19+1             \ Set XX15+1 (Y1) = crosshairs y-coordinate + indent
 CLC                    \ to get the y-coordinate of the centre of the
 ADC QQ19+5             \ crosshairs
 STA XX15+1

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1),
                        \ which will draw from the left edge of the crosshairs
                        \ to the right edge, through the centre of the
                        \ crosshairs

 LDA QQ19+1             \ Set A = crosshairs y-coordinate - crosshairs size
 SEC                    \ to get the y-coordinate of the top edge of the
 SBC QQ19+2             \ crosshairs

 BCS TT86               \ If the above subtraction didn't underflow, then A is
                        \ correct, so skip the next instruction

 LDA #0                 \ The subtraction underflowed, so set A to 0 so the
                        \ crosshairs don't spill out of the top of the screen

.TT86

 CLC                    \ Set XX15+1 (Y1) = A + indent to get the y-coordinate
 ADC QQ19+5             \ of the top edge of the indented crosshairs
 STA XX15+1

 LDA QQ19+1             \ Set A = crosshairs y-coordinate + crosshairs size
 CLC                    \ + indent to get the y-coordinate of the bottom edge
 ADC QQ19+2             \ of the indented crosshairs
 ADC QQ19+5

 CMP #152               \ If A < 152 then skip the following, as the crosshairs
 BCC TT87               \ won't spill out of the bottom of the screen

 LDX QQ11               \ A >= 152, so we need to check whether this will fit in
                        \ this view, so fetch the view number

 BMI TT87               \ If this is the Short-range Chart then the y-coordinate
                        \ is fine, so skip to TT87

 LDA #151               \ Otherwise this is the Long-range Chart, so we need to
                        \ clip the crosshairs at a maximum y-coordinate of 151

.TT87

 STA XX15+3             \ Set XX15+3 (Y2) = A (the y-coordinate of the bottom
                        \ edge of the crosshairs)

 LDA QQ19               \ Set XX15 (X1) = the x-coordinate of the centre of the
 STA XX15               \ crosshairs

 STA XX15+2             \ Set XX15+2 (X2) = the x-coordinate of the centre of
                        \ the crosshairs

 JMP LL30               \ Draw a vertical line (X1, Y1) to (X2, Y2), which will
                        \ draw from the top edge of the crosshairs to the bottom
                        \ edge, through the centre of the crosshairs, returning
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT14
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle with crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with crosshairs at the current system's galactic coordinates.
\
\ ******************************************************************************

.TT126

 LDA #104               \ Set QQ19 = 104, for the x-coordinate of the centre of
 STA QQ19               \ the fixed circle on the Short-range Chart

 LDA #90                \ Set QQ19+1 = 90, for the y-coordinate of the centre of
 STA QQ19+1             \ the fixed circle on the Short-range Chart

 LDA #16                \ Set QQ19+2 = 16, the size of the crosshairs on the
 STA QQ19+2             \ Short-range Chart

 JSR TT15               \ Draw the set of crosshairs defined in QQ19, at the
                        \ exact coordinates as this is the Short-range Chart

 LDA QQ14               \ Set K to the fuel level from QQ14, so this can act as
 STA K                  \ the circle's radius (70 being a full tank)

 JMP TT128              \ Jump to TT128 to draw a circle with the centre at the
                        \ same coordinates as the crosshairs, (QQ19, QQ19+1),
                        \ and radius K that reflects the current fuel levels,
                        \ returning from the subroutine using a tail call

.TT14

 LDA QQ11               \ If the current view is the Short-range Chart, which
 BMI TT126              \ is the only view with bit 7 set, then jump up to TT126
                        \ to draw the crosshairs and circle for that view

                        \ Otherwise this is the Long-range Chart, so we draw the
                        \ crosshairs and circle for that view instead

 LDA QQ14               \ Set K to the fuel level from QQ14 divided by 4, so
 LSR A                  \ this can act as the circle's radius (70 being a full
 LSR A                  \ tank, which divides down to a radius of 17)
 STA K

 LDA QQ0                \ Set QQ19 to the x-coordinate of the current system,
 STA QQ19               \ which will be the centre of the circle and crosshairs
                        \ we draw

 LDA QQ1                \ Set QQ19+1 to the y-coordinate of the current system,
 LSR A                  \ halved because the galactic chart is half as high as
 STA QQ19+1             \ it is wide, which will again be the centre of the
                        \ circle and crosshairs we draw

 LDA #7                 \ Set QQ19+2 = 7, the size of the crosshairs on the
 STA QQ19+2             \ Long-range Chart

 JSR TT15               \ Draw the set of crosshairs defined in QQ19, which will
                        \ be drawn 24 pixels to the right of QQ19+1

 LDA QQ19+1             \ Add 24 to the y-coordinate of the crosshairs in QQ19+1
 CLC                    \ so that the centre of the circle matches the centre
 ADC #24                \ of the crosshairs
 STA QQ19+1

                        \ Fall through into TT128 to draw a circle with the
                        \ centre at the same coordinates as the crosshairs,
                        \ (QQ19, QQ19+1), and radius K that reflects the
                        \ current fuel levels

\ ******************************************************************************
\
\       Name: TT128
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle on a chart
\  Deep dive: Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with the centre at (QQ19, QQ19+1) and radius K.
\
\ Arguments:
\
\   QQ19                The x-coordinate of the centre of the circle
\
\   QQ19+1              The y-coordinate of the centre of the circle
\
\   K                   The radius of the circle
\
\ ******************************************************************************

.TT128

 LDA QQ19               \ Set K3 = the x-coordinate of the centre
 STA K3

 LDA QQ19+1             \ Set K4 = the y-coordinate of the centre
 STA K4

 LDX #0                 \ Set the high bytes of K3(1 0) and K4(1 0) to 0
 STX K4+1
 STX K3+1

\STX LSX                \ This instruction is commented out in the original
                        \ source

 INX                    \ Set LSP = 1 to reset the ball line heap
 STX LSP

 LDX #2                 \ Set STP = 2, the step size for the circle
 STX STP

 JSR CIRCLE2            \ Call CIRCLE2 to draw a circle with the centre at
                        \ (K3(1 0), K4(1 0)) and radius K

\LDA #&FF               \ These instructions are commented out in the original
\STA LSX                \ source

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT219
\       Type: Subroutine
\   Category: Market
\    Summary: Show the Buy Cargo screen (red key f1)
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   BAY2                Jump into the main loop at FRCE, setting the key
\                       "pressed" to red key f9 (so we show the Inventory
\                       screen)
\
\ ******************************************************************************

.TT219

\LDA #2                 \ This instruction is commented out in the original
                        \ source. Perhaps this view originally had a QQ11 value
                        \ of 2, but it turned out not to need its own unique ID,
                        \ so the authors found they could just use a view value
                        \ of 1 and save an instruction at the same time?

 JSR TT66-2             \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 1

 JSR TT163              \ Print the column headers for the prices table

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case, with the
 STA QQ17               \ next letter in capitals

\JSR FLKB               \ This instruction is commented out in the original
                        \ source. It calls a routine to flush the keyboard
                        \ buffer (FLKB) that isn't present in the cassette
                        \ version but is in other versions

 LDA #0                 \ We're going to loop through all the available market
 STA QQ29               \ items, so we set up a counter in QQ29 to denote the
                        \ current item and start it at 0

.TT220

 JSR TT151              \ Call TT151 to print the item name, market price and
                        \ availability of the current item, and set QQ24 to the
                        \ item's price / 4, QQ25 to the quantity available and
                        \ QQ19+1 to byte #1 from the market prices table for
                        \ this item

 LDA QQ25               \ If there are some of the current item available, jump
 BNE TT224              \ to TT224 below to see if we want to buy any

 JMP TT222              \ Otherwise there are none available, so jump down to
                        \ TT222 to skip this item

.TQ4

 LDY #176               \ Set Y to the recursive token 16 ("QUANTITY")

.Tc

 JSR TT162              \ Print a space

 TYA                    \ Print the recursive token in Y followed by a question
 JSR prq                \ mark

.TTX224

 JSR dn2                \ Call dn2 to make a short, high beep and delay for 1
                        \ second

.TT224

 JSR CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows

 LDA #204               \ Print recursive token 44 ("QUANTITY OF ")
 JSR TT27

 LDA QQ29               \ Print recursive token 48 + QQ29, which will be in the
 CLC                    \ range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
 ADC #208               \ prints the current item's name
 JSR TT27

 LDA #'/'               \ Print "/"
 JSR TT27

 JSR TT152              \ Print the unit ("t", "kg" or "g") for the current item
                        \ (as the call to TT151 above set QQ19+1 with the
                        \ appropriate value)

 LDA #'?'               \ Print "?"
 JSR TT27

 JSR TT67               \ Print a newline

 LDX #0                 \ These instructions have no effect, as they are
 STX R                  \ repeated at the start of gnum, which we call next.
 LDX #12                \ Perhaps they were left behind when code was moved from
 STX T1                 \ here into gnum, and weren't deleted?

\.TT223                 \ This label is commented out in the original source,
                        \ and is a duplicate of a label in gnum, so this could
                        \ also be a remnant if the code in gnum was originally
                        \ here, but got moved into the gnum subroutine

 JSR gnum               \ Call gnum to get a number from the keyboard, which
                        \ will be the quantity of this item we want to purchase,
                        \ returning the number entered in A and R

 BCS TQ4                \ If gnum set the C flag, the number entered is greater
                        \ then the quantity available, so jump up to TQ4 to
                        \ display a "Quantity?" error, beep, clear the number
                        \ and try again

 STA P                  \ Otherwise we have a valid purchase quantity entered,
                        \ so store the amount we want to purchase in P

 JSR tnpr               \ Call tnpr to work out whether there is room in the
                        \ cargo hold for this item

 LDY #206               \ Set Y to recursive token 46 (" CARGO{sentence case}")
                        \ to pass to the Tc routine if we call it

 BCS Tc                 \ If the C flag is set, then there is no room in the
                        \ cargo hold, jump up to Tc to print a "Cargo?" error,
                        \ beep, clear the number and try again

 LDA QQ24               \ There is room in the cargo hold, so now to check
 STA Q                  \ whether we have enough cash, so fetch the item's
                        \ price / 4, which was returned in QQ24 by the call
                        \ to TT151 above and store it in Q

 JSR GCASH              \ Call GCASH to calculate
                        \
                        \   (Y X) = P * Q * 4
                        \
                        \ which will be the total price of this transaction
                        \ (as P contains the purchase quantity and Q contains
                        \ the item's price / 4)

 JSR LCASH              \ Subtract (Y X) cash from the cash pot in CASH

 LDY #197               \ If the C flag is clear, we didn't have enough cash,
 BCC Tc                 \ so set Y to the recursive token 37 ("CASH") and jump
                        \ up to Tc to print a "Cash?" error, beep, clear the
                        \ number and try again

 LDY QQ29               \ Fetch the current market item number from QQ29 into Y

 LDA R                  \ Set A to the number of items we just purchased (this
                        \ was set by gnum above)

 PHA                    \ Store the quantity just purchased on the stack

 CLC                    \ Add the number purchased to the Y-th byte of QQ20,
 ADC QQ20,Y             \ which contains the number of items of this type in
 STA QQ20,Y             \ our hold (so this transfers the bought items into our
                        \ cargo hold)

 LDA AVL,Y              \ Subtract the number of items from the Y-th byte of
 SEC                    \ AVL, which contains the number of items of this type
 SBC R                  \ that are available on the market
 STA AVL,Y

 PLA                    \ Restore the quantity just purchased

 BEQ TT222              \ If we didn't buy anything, jump to TT222 to skip the
                        \ following instruction

 JSR dn                 \ Call dn to print the amount of cash left in the cash
                        \ pot, then make a short, high beep to confirm the
                        \ purchase, and delay for 1 second

.TT222

 LDA QQ29               \ Move the text cursor to row QQ29 + 5 (where QQ29 is
 CLC                    \ the item number, starting from 0)
 ADC #5
 STA YC

 LDA #0                 \ Move the text cursor to column 0
 STA XC

 INC QQ29               \ Increment QQ29 to point to the next item

 LDA QQ29               \ If QQ29 >= 17 then jump to BAY2 as we have done the
 CMP #17                \ last item
 BCS BAY2

 JMP TT220              \ Otherwise loop back to TT220 to print the next market
                        \ item

.BAY2

 LDA #f9                \ Jump into the main loop at FRCE, setting the key
 JMP FRCE               \ "pressed" to red key f9 (so we show the Inventory
                        \ screen)

\ ******************************************************************************
\
\       Name: gnum
\       Type: Subroutine
\   Category: Market
\    Summary: Get a number from the keyboard
\
\ ------------------------------------------------------------------------------
\
\ Get a number from the keyboard, up to the maximum number in QQ25, for the
\ buying and selling of cargo and equipment.
\
\ Pressing a key with an ASCII code less than ASCII "0" will return a 0 in A (so
\ that includes pressing Space or Return), while pressing a key with an ASCII
\ code greater than ASCII "9" will jump to the Inventory screen (so that
\ includes all letters and most punctuation).
\
\ Arguments:
\
\   QQ25                The maximum number allowed
\
\ Returns:
\
\   A                   The number entered
\
\   R                   Also contains the number entered
\
\   C flag              Set if the number is too large (> QQ25), clear otherwise
\
\ ******************************************************************************

.gnum

 LDX #0                 \ We will build the number entered in R, so initialise
 STX R                  \ it with 0

 LDX #12                \ We will check for up to 12 key presses, so set a
 STX T1                 \ counter in T1

.TT223

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A (and X)

 STA Q                  \ Store the key pressed in Q

 SEC                    \ Subtract ASCII "0" from the key pressed, to leave the
 SBC #'0'               \ numeric value of the key in A (if it was a number key)

 BCC OUT                \ If A < 0, jump to OUT to return from the subroutine
                        \ with a result of 0, as the key pressed was not a
                        \ number or letter and is less than ASCII "0"

 CMP #10                \ If A >= 10, jump to BAY2 to display the Inventory
 BCS BAY2               \ screen, as the key pressed was a letter or other
                        \ non-digit and is greater than ASCII "9"

 STA S                  \ Store the numeric value of the key pressed in S

 LDA R                  \ Fetch the result so far into A

 CMP #26                \ If A >= 26, where A is the number entered so far, then
 BCS OUT                \ adding a further digit will make it bigger than 256,
                        \ so jump to OUT to return from the subroutine with the
                        \ result in R (i.e. ignore the last key press)

 ASL A                  \ Set A = (A * 2) + (A * 8) = A * 10
 STA T
 ASL A
 ASL A
 ADC T

 ADC S                  \ Add the pressed digit to A and store in R, so R now
 STA R                  \ contains its previous value with the new key press
                        \ tacked onto the end

 CMP QQ25               \ If the result in R = the maximum allowed in QQ25, jump
 BEQ TT226              \ to TT226 to print the key press and keep looping (the
                        \ BEQ is needed because the BCS below would jump to OUT
                        \ if R >= QQ25, which we don't want)

 BCS OUT                \ If the result in R > QQ25, jump to OUT to return from
                        \ the subroutine with the result in R

.TT226

 LDA Q                  \ Print the character in Q (i.e. the key that was
 JSR TT26               \ pressed, as we stored the ASCII value in Q earlier)

 DEC T1                 \ Decrement the loop counter

 BNE TT223              \ Loop back to TT223 until we have checked for 12 digits

.OUT

 LDA R                  \ Set A to the result we have been building in R

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT208
\       Type: Subroutine
\   Category: Market
\    Summary: Show the Sell Cargo screen (red key f2)
\
\ ******************************************************************************

.TT208

 LDA #4                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 4 (Sell
                        \ Cargo screen)

 LDA #4                 \ Move the text cursor to row 4, column 4
 STA YC
 STA XC

\JSR FLKB               \ This instruction is commented out in the original
                        \ source. It calls a routine to flush the keyboard
                        \ buffer (FLKB) that isn't present in the cassette
                        \ version but is in other versions

 LDA #205               \ Print recursive token 45 ("SELL")
 JSR TT27

 LDA #206               \ Print recursive token 46 (" CARGO{sentence case}")
 JSR TT68               \ followed by a colon

                        \ Fall through into TT210 to show the Inventory screen
                        \ with the option to sell

\ ******************************************************************************
\
\       Name: TT210
\       Type: Subroutine
\   Category: Inventory
\    Summary: Show a list of current cargo in our hold, optionally to sell
\
\ ------------------------------------------------------------------------------
\
\ Show a list of current cargo in our hold, either with the ability to sell (the
\ Sell Cargo screen) or without (the Inventory screen), depending on the current
\ view.
\
\ Arguments:
\
\   QQ11                The current view:
\
\                           * 4 = Sell Cargo
\
\                           * 8 = Inventory
\
\ ******************************************************************************

.TT210

 LDY #0                 \ We're going to loop through all the available market
                        \ items and check whether we have any in the hold (and,
                        \ if we are in the Sell Cargo screen, whether we want
                        \ to sell any items), so we set up a counter in Y to
                        \ denote the current item and start it at 0

.TT211

 STY QQ29               \ Store the current item number in QQ29

 LDX QQ20,Y             \ Fetch into X the amount of the current item that we
 BEQ TT212              \ have in our cargo hold, which is stored in QQ20+Y,
                        \ and if there are no items of this type in the hold,
                        \ jump down to TT212 to skip to the next item

 TYA                    \ Set Y = Y * 4, so this will act as an index into the
 ASL A                  \ market prices table at QQ23 for this item (as there
 ASL A                  \ are four bytes per item in the table)
 TAY

 LDA QQ23+1,Y           \ Fetch byte #1 from the market prices table for the
 STA QQ19+1             \ current item and store it in QQ19+1, for use by the
                        \ call to TT152 below

 TXA                    \ Store the amount of item in the hold (in X) on the
 PHA                    \ stack

 JSR TT69               \ Call TT69 to set Sentence Case and print a newline

 CLC                    \ Print recursive token 48 + QQ29, which will be in the
 LDA QQ29               \ range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
 ADC #208               \ prints the current item's name
 JSR TT27

 LDA #14                \ Move the text cursor to column 14, for the item's
 STA XC                 \ quantity

 PLA                    \ Restore the amount of item in the hold into X
 TAX

 CLC                    \ Print the 8-bit number in X to 3 digits, without a
 JSR pr2                \ decimal point

 JSR TT152              \ Print the unit ("t", "kg" or "g") for the market item
                        \ whose byte #1 from the market prices table is in
                        \ QQ19+1 (which we set up above)

 LDA QQ11               \ If the current view type in QQ11 is not 4 (Sell Cargo
 CMP #4                 \ screen), jump to TT212 to skip the option to sell
 BNE TT212              \ items

 LDA #205               \ Set A to recursive token 45 ("SELL")

 JSR TT214              \ Call TT214 to print "Sell(Y/N)?" and return the
                        \ response in the C flag

 BCC TT212              \ If the response was "no", jump to TT212 to move on to
                        \ the next item

 LDA QQ29               \ We are selling this item, so fetch the item number
                        \ from QQ29

 LDX #255               \ Set QQ17 = 255 to disable printing
 STX QQ17

 JSR TT151              \ Call TT151 to set QQ24 to the item's price / 4 (the
                        \ routine doesn't print the item details, as we just
                        \ disabled printing)

 LDY QQ29               \ Set P to the amount of this item we have in our cargo
 LDA QQ20,Y             \ hold (which is the amount to sell)
 STA P

 LDA QQ24               \ Set Q to the item's price / 4
 STA Q

 JSR GCASH              \ Call GCASH to calculate
                        \
                        \   (Y X) = P * Q * 4
                        \
                        \ which will be the total price we make from this sale
                        \ (as P contains the quantity we're selling and Q
                        \ contains the item's price / 4)

 JSR MCASH              \ Add (Y X) cash to the cash pot in CASH

 LDA #0                 \ We've made the sale, so set the amount
 LDY QQ29
 STA QQ20,Y

 STA QQ17               \ Set QQ17 = 0, which enables printing again

.TT212

 LDY QQ29               \ Fetch the item number from QQ29 into Y, and increment
 INY                    \ Y to point to the next item

 CPY #17                \ If Y >= 17 then skip the next instruction as we have
 BCS P%+5               \ done the last item

 JMP TT211              \ Otherwise loop back to TT211 to print the next item
                        \ in the hold

 LDA QQ11               \ If the current view type in QQ11 is not 4 (Sell Cargo
 CMP #4                 \ screen), skip the next two instructions and just
 BNE P%+8               \ return from the subroutine

 JSR dn2                \ This is the Sell Cargo screen, so call dn2 to make a
                        \ short, high beep and delay for 1 second

 JMP BAY2               \ And then jump to BAY2 to display the Inventory
                        \ screen, as we have finished selling cargo

 RTS                    \ Return from the subroutine

INCLUDE "1-source-files/main-sources/elite-source-2.asm"
