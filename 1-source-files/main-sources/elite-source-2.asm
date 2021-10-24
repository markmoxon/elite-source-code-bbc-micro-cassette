\ ******************************************************************************
\
\       Name: TT213
\       Type: Subroutine
\   Category: Inventory
\    Summary: Show the Inventory screen (red key f9)
\
\ ******************************************************************************

.TT213

 LDA #8                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 8 (Inventory
                        \ screen)

 LDA #11                \ Move the text cursor to column 11 to print the screen
 STA XC                 \ title

 LDA #164               \ Print recursive token 4 ("INVENTORY{crlf}") followed
 JSR TT60               \ by a paragraph break and Sentence Case

 JSR NLIN4              \ Draw a horizontal line at pixel row 19 to box in the
                        \ title. The authors could have used a call to NLIN3
                        \ instead and saved the above call to TT60, but you
                        \ just can't optimise everything

 JSR fwl                \ Call fwl to print the fuel and cash levels on two
                        \ separate lines

 LDA CRGO               \ If our ship's cargo capacity is < 26 (i.e. we do not
 CMP #26                \ have a cargo bay extension), skip the following two
 BCC P%+7               \ instructions

 LDA #107               \ We do have a cargo bay extension, so print recursive
 JSR TT27               \ token 107 ("LARGE CARGO{sentence case} BAY")

 JMP TT210              \ Jump to TT210 to print the contents of our cargo bay
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT214
\       Type: Subroutine
\   Category: Inventory
\    Summary: Ask a question with a "Y/N?" prompt and return the response
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to print before the "Y/N?" prompt
\
\ Returns:
\
\   C flag              Set if the response was "yes", clear otherwise
\
\ ******************************************************************************

.TT214

 PHA                    \ Print a space, using the stack to preserve the value
 JSR TT162              \ of A
 PLA

.TT221

 JSR TT27               \ Print the text token in A

 LDA #225               \ Print recursive token 65 ("(Y/N)?")
 JSR TT27

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A and X

 ORA #%00100000         \ Set bit 5 in the value of the key pressed, which
                        \ converts it to lower case

 CMP #'y'               \ If "y" was pressed, jump to TT218
 BEQ TT218

 LDA #'n'               \ Otherwise jump to TT26 to print "n" and return from
 JMP TT26               \ the subroutine using a tail call (so all other
                        \ responses apart from "y" indicate a no)

.TT218

 JSR TT26               \ Print the character in A, i.e. print "y"

 SEC                    \ Set the C flag to indicate a "yes" response

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT16
\       Type: Subroutine
\   Category: Charts
\    Summary: Move the crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Move the chart crosshairs by the amount in X and Y.
\
\ Arguments:
\
\   X                   The amount to move the crosshairs in the x-axis
\
\   Y                   The amount to move the crosshairs in the y-axis
\
\ ******************************************************************************

.TT16

 TXA                    \ Push the change in X onto the stack (let's call this
 PHA                    \ the x-delta)

 DEY                    \ Negate the change in Y and push it onto the stack
 TYA                    \ (let's call this the y-delta)
 EOR #&FF
 PHA

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn and we can move the crosshairs with
                        \ no screen flicker

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 PLA                    \ Store the y-delta in QQ19+3 and fetch the current
 STA QQ19+3             \ y-coordinate of the crosshairs from QQ10 into A, ready
 LDA QQ10               \ for the call to TT123

 JSR TT123              \ Call TT123 to move the selected system's galactic
                        \ y-coordinate by the y-delta, putting the new value in
                        \ QQ19+4

 LDA QQ19+4             \ Store the updated y-coordinate in QQ10 (the current
 STA QQ10               \ y-coordinate of the crosshairs)

 STA QQ19+1             \ This instruction has no effect, as QQ19+1 is
                        \ overwritten below, both in TT103 and TT105

 PLA                    \ Store the x-delta in QQ19+3 and fetch the current
 STA QQ19+3             \ x-coordinate of the crosshairs from QQ10 into A, ready
 LDA QQ9                \ for the call to TT123

 JSR TT123              \ Call TT123 to move the selected system's galactic
                        \ x-coordinate by the x-delta, putting the new value in
                        \ QQ19+4

 LDA QQ19+4             \ Store the updated x-coordinate in QQ9 (the current
 STA QQ9                \ x-coordinate of the crosshairs)

 STA QQ19               \ This instruction has no effect, as QQ19 is overwritten
                        \ below, both in TT103 and TT105

                        \ Now we've updated the coordinates of the crosshairs,
                        \ fall through into TT103 to redraw them at their new
                        \ location

\ ******************************************************************************
\
\       Name: TT103
\       Type: Subroutine
\   Category: Charts
\    Summary: Draw a small set of crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Draw a small set of crosshairs on a galactic chart at the coordinates in
\ (QQ9, QQ10).
\
\ ******************************************************************************

.TT103

 LDA QQ11               \ Fetch the current view type into A

 BEQ TT180              \ If this is a space view, return from the subroutine
                        \ (as TT180 contains an RTS), as there are no moveable
                        \ crosshairs in space

 BMI TT105              \ If this is the Short-range Chart screen, jump to TT105

 LDA QQ9                \ Store the crosshairs x-coordinate in QQ19
 STA QQ19

 LDA QQ10               \ Halve the crosshairs y-coordinate and store it in QQ19
 LSR A                  \ (we halve it because the Long-range Chart is half as
 STA QQ19+1             \ high as it is wide)

 LDA #4                 \ Set QQ19+2 to 4 denote crosshairs of size 4
 STA QQ19+2

 JMP TT15               \ Jump to TT15 to draw crosshairs of size 4 at the
                        \ crosshairs coordinates, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT123
\       Type: Subroutine
\   Category: Charts
\    Summary: Move galactic coordinates by a signed delta
\
\ ------------------------------------------------------------------------------
\
\ Move an 8-bit galactic coordinate by a certain distance in either direction
\ (i.e. a signed 8-bit delta), but only if it doesn't cause the coordinate to
\ overflow. The coordinate is in a single axis, so it's either an x-coordinate
\ or a y-coordinate.
\
\ Arguments:
\
\   A                   The galactic coordinate to update
\
\   QQ19+3              The delta (can be positive or negative)
\
\ Returns:
\
\   QQ19+4              The updated coordinate after moving by the delta (this
\                       will be the same as A if moving by the delta overflows)
\
\ Other entry points:
\
\   TT180               Contains an RTS
\
\ ******************************************************************************

.TT123

 STA QQ19+4             \ Store the original coordinate in temporary storage at
                        \ QQ19+4

 CLC                    \ Set A = A + QQ19+3, so A now contains the original
 ADC QQ19+3             \ coordinate, moved by the delta

 LDX QQ19+3             \ If the delta is negative, jump to TT124
 BMI TT124

 BCC TT125              \ If the C flag is clear, then the above addition didn't
                        \ overflow, so jump to TT125 to return the updated value

 RTS                    \ Otherwise the C flag is set and the above addition
                        \ overflowed, so do not update the return value

.TT124

 BCC TT180              \ If the C flag is clear, then because the delta is
                        \ negative, this indicates the addition (which is
                        \ effectively a subtraction) underflowed, so jump to
                        \ TT180 to return from the subroutine without updating
                        \ the return value

.TT125

 STA QQ19+4             \ Store the updated coordinate in QQ19+4

.TT180

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT105
\       Type: Subroutine
\   Category: Charts
\    Summary: Draw crosshairs on the Short-range Chart, with clipping
\
\ ------------------------------------------------------------------------------
\
\ Check whether the crosshairs are close enough to the current system to appear
\ on the Short-range Chart, and if so, draw them.
\
\ ******************************************************************************

.TT105

 LDA QQ9                \ Set A = QQ9 - QQ0, the horizontal distance between the
 SEC                    \ crosshairs (QQ9) and the current system (QQ0)
 SBC QQ0

 CMP #38                \ If the horizontal distance in A < 38, then the
 BCC TT179              \ crosshairs are close enough to the current system to
                        \ appear in the Short-range Chart, so jump to TT179 to
                        \ check the vertical distance

 CMP #230               \ If the horizontal distance in A < -26, then the
 BCC TT180              \ crosshairs are too far from the current system to
                        \ appear in the Short-range Chart, so jump to TT180 to
                        \ return from the subroutine (as TT180 contains an RTS)

.TT179

 ASL A                  \ Set QQ19 = 104 + A * 4
 ASL A                  \
 CLC                    \ 104 is the x-coordinate of the centre of the chart,
 ADC #104               \ so this sets QQ19 to the screen pixel x-coordinate
 STA QQ19               \ of the crosshairs

 LDA QQ10               \ Set A = QQ10 - QQ1, the vertical distance between the
 SEC                    \ crosshairs (QQ10) and the current system (QQ1)
 SBC QQ1

 CMP #38                \ If the vertical distance in A is < 38, then the
 BCC P%+6               \ crosshairs are close enough to the current system to
                        \ appear in the Short-range Chart, so skip the next two
                        \ instructions

 CMP #220               \ If the horizontal distance in A is < -36, then the
 BCC TT180              \ crosshairs are too far from the current system to
                        \ appear in the Short-range Chart, so jump to TT180 to
                        \ return from the subroutine (as TT180 contains an RTS)

 ASL A                  \ Set QQ19+1 = 90 + A * 2
 CLC                    \
 ADC #90                \ 90 is the y-coordinate of the centre of the chart,
 STA QQ19+1             \ so this sets QQ19+1 to the screen pixel x-coordinate
                        \ of the crosshairs

 LDA #8                 \ Set QQ19+2 to 8 denote crosshairs of size 8
 STA QQ19+2

 JMP TT15               \ Jump to TT15 to draw crosshairs of size 8 at the
                        \ crosshairs coordinates, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT23
\       Type: Subroutine
\   Category: Charts
\    Summary: Show the Short-range Chart (red key f5)
\
\ ******************************************************************************

.TT23

 LDA #128               \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 128 (Short-
                        \ range Chart)

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 LDA #190               \ Print recursive token 30 ("SHORT RANGE CHART") and
 JSR NLIN3              \ draw a horizontal line at pixel row 19 to box in the
                        \ title

 JSR TT14               \ Call TT14 to draw a circle with crosshairs at the
                        \ current system's galactic coordinates

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ i.e. at the selected system

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

 LDA #0                 \ Set A = 0, which we'll use below to zero out the INWK
                        \ workspace

 STA XX20               \ We're about to start working our way through each of
                        \ the galaxy's systems, so set up a counter in XX20 for
                        \ each system, starting at 0 and looping through to 255

 LDX #24                \ First, though, we need to zero out the 25 bytes at
                        \ INWK so we can use them to work out which systems have
                        \ room for a label, so set a counter in X for 25 bytes

.EE3

 STA INWK,X             \ Set the X-th byte of INWK to zero

 DEX                    \ Decrement the counter

 BPL EE3                \ Loop back to EE3 for the next byte until we've zeroed
                        \ all 25 bytes

                        \ We now loop through every single system in the galaxy
                        \ and check the distance from the current system whose
                        \ coordinates are in (QQ0, QQ1). We get the galactic
                        \ coordinates of each system from the system's seeds,
                        \ like this:
                        \
                        \   x = s1_hi (which is stored in QQ15+3)
                        \   y = s0_hi (which is stored in QQ15+1)
                        \
                        \ so the following loops through each system in the
                        \ galaxy in turn and calculates the distance between
                        \ (QQ0, QQ1) and (s1_hi, s0_hi) to find the closest one

.TT182

 LDA QQ15+3             \ Set A = s1_hi - QQ0, the horizontal distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ0, QQ1)
 SBC QQ0

 BCS TT184              \ If a borrow didn't occur, i.e. s1_hi >= QQ0, then the
                        \ result is positive, so jump to TT184 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s1_hi - QQ0|)

.TT184

 CMP #20                \ If the horizontal distance in A is >= 20, then this
 BCS TT187              \ system is too far away from the current system to
                        \ appear in the Short-range Chart, so jump to TT187 to
                        \ move on to the next system

 LDA QQ15+1             \ Set A = s0_hi - QQ1, the vertical distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ0, QQ1)
 SBC QQ1

 BCS TT186              \ If a borrow didn't occur, i.e. s0_hi >= QQ1, then the
                        \ result is positive, so jump to TT186 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s0_hi - QQ1|)

.TT186

 CMP #38                \ If the vertical distance in A is >= 38, then this
 BCS TT187              \ system is too far away from the current system to
                        \ appear in the Short-range Chart, so jump to TT187 to
                        \ move on to the next system

                        \ This system should be shown on the Short-range Chart,
                        \ so now we need to work out where the label should go,
                        \ and set up the various variables we need to draw the
                        \ system's filled circle on the chart

 LDA QQ15+3             \ Set A = s1_hi - QQ0, the horizontal distance between
 SEC                    \ this system and the current system, where |A| < 20.
 SBC QQ0                \ Let's call this the x-delta, as it's the horizontal
                        \ difference between the current system at the centre of
                        \ the chart, and this system (and this time we keep the
                        \ sign of A, so it can be negative if it's to the left
                        \ of the chart's centre, or positive if it's to the
                        \ right)

 ASL A                  \ Set XX12 = 104 + x-delta * 4
 ASL A                  \
 ADC #104               \ 104 is the x-coordinate of the centre of the chart,
 STA XX12               \ so this sets XX12 to the centre 104 +/- 76, the pixel
                        \ x-coordinate of this system

 LSR A                  \ Move the text cursor to column x-delta / 2 + 1
 LSR A                  \ which will be in the range 1-10
 LSR A
 STA XC
 INC XC

 LDA QQ15+1             \ Set A = s0_hi - QQ1, the vertical distance between
 SEC                    \ this system and the current system, where |A| < 38.
 SBC QQ1                \ Let's call this the y-delta, as it's the vertical
                        \ difference between the current system at the centre of
                        \ the chart, and this system (and this time we keep the
                        \ sign of A, so it can be negative if it's above the
                        \ chart's centre, or positive if it's below)

 ASL A                  \ Set K4 = 90 + y-delta * 2
 ADC #90                \
 STA K4                 \ 90 is the y-coordinate of the centre of the chart,
                        \ so this sets K4 to the centre 90 +/- 74, the pixel
                        \ y-coordinate of this system

 LSR A                  \ Set Y = K4 / 8, so Y contains the number of the text
 LSR A                  \ row that contains this system
 LSR A
 TAY

                        \ Now to see if there is room for this system's label.
                        \ Ideally we would print the system name on the same
                        \ text row as the system, but we only want to print one
                        \ label per row, to prevent overlap, so now we check
                        \ this system's row, and if that's already occupied,
                        \ the row above, and if that's already occupied, the
                        \ row below... and if that's already occupied, we give
                        \ up and don't print a label for this system

 LDX INWK,Y             \ If the value in INWK+Y is 0 (i.e. the text row
 BEQ EE4                \ containing this system does not already have another
                        \ system's label on it), jump to EE4 to store this
                        \ system's label on this row

 INY                    \ If the value in INWK+Y+1 is 0 (i.e. the text row below
 LDX INWK,Y             \ the one containing this system does not already have
 BEQ EE4                \ another system's label on it), jump to EE4 to store
                        \ this system's label on this row

 DEY                    \ If the value in INWK+Y-1 is 0 (i.e. the text row above
 DEY                    \ the one containing this system does not already have
 LDX INWK,Y             \ another system's label on it), fall through into to
 BNE ee1                \ EE4 to store this system's label on this row,
                        \ otherwise jump to ee1 to skip printing a label for
                        \ this system (as there simply isn't room)

.EE4

 STY YC                 \ Now to print the label, so move the text cursor to row
                        \ Y (which contains the row where we can print this
                        \ system's label)

 CPY #3                 \ If Y < 3, then the system would clash with the chart
 BCC TT187              \ title, so jump to TT187 to skip showing the system

 DEX                    \ We entered the EE4 routine with X = 0, so this stores
 STX INWK,Y             \ &FF in INWK+Y, to denote that this row is now occupied
                        \ so we don't try to print another system's label on
                        \ this row

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

 JSR cpl                \ Call cpl to print out the system name for the seeds
                        \ in QQ15 (which now contains the seeds for the current
                        \ system)

.ee1

 LDA #0                 \ Now to plot the star, so set the high bytes of K, K3
 STA K3+1               \ and K4 to 0
 STA K4+1
 STA K+1

 LDA XX12               \ Set the low byte of K3 to XX12, the pixel x-coordinate
 STA K3                 \ of this system

 LDA QQ15+5             \ Fetch s2_hi for this system from QQ15+5, extract bit 0
 AND #1                 \ and add 2 to get the size of the star, which we store
 ADC #2                 \ in K. This will be either 2, 3 or 4, depending on the
 STA K                  \ value of bit 0, and whether the C flag is set (which
                        \ will vary depending on what happens in the above call
                        \ to cpl). Incidentally, the planet's average radius
                        \ also uses s2_hi, bits 0-3 to be precise, but that
                        \ doesn't mean the two sizes affect each other

                        \ We now have the following:
                        \
                        \   K(1 0)  = radius of star (2, 3 or 4)
                        \
                        \   K3(1 0) = pixel x-coordinate of system
                        \
                        \   K4(1 0) = pixel y-coordinate of system
                        \
                        \ which we can now pass to the SUN routine to draw a
                        \ small "sun" on the Short-range Chart for this system

 JSR FLFLLS             \ Call FLFLLS to reset the LSO block

 JSR SUN                \ Call SUN to plot a sun with radius K at pixel
                        \ coordinate (K3, K4)

 JSR FLFLLS             \ Call FLFLLS to reset the LSO block

.TT187

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC XX20               \ Increment the counter

 BEQ TT111-1            \ If X = 0 then we have done all 256 systems, so return
                        \ from the subroutine (as TT111-1 contains an RTS)

 JMP TT182              \ Otherwise jump back up to TT182 to process the next
                        \ system

\ ******************************************************************************
\
\       Name: TT81
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the selected system's seeds to those of system 0
\
\ ------------------------------------------------------------------------------
\
\ Copy the three 16-bit seeds for the current galaxy's system 0 (QQ21) into the
\ seeds for the selected system (QQ15) - in other words, set the selected
\ system's seeds to those of system 0.
\
\ ******************************************************************************

.TT81

 LDX #5                 \ Set up a counter in X to copy six bytes (for three
                        \ 16-bit numbers)

 LDA QQ21,X             \ Copy the X-th byte in QQ21 to the X-th byte in QQ15
 STA QQ15,X

 DEX                    \ Decrement the counter

 BPL TT81+2             \ Loop back up to the LDA instruction if we still have
                        \ more bytes to copy

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT111
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the current system to the nearest system to a point
\
\ ------------------------------------------------------------------------------
\
\ Given a set of galactic coordinates in (QQ9, QQ10), find the nearest system
\ to this point in the galaxy, and set this as the currently selected system.
\
\ Arguments:
\
\   QQ9                 The x-coordinate near which we want to find a system
\
\   QQ10                The y-coordinate near which we want to find a system
\
\ Returns:
\
\   QQ8(1 0)            The distance from the current system to the nearest
\                       system to the original coordinates
\
\   QQ9                 The x-coordinate of the nearest system to the original
\                       coordinates
\
\   QQ10                The y-coordinate of the nearest system to the original
\                       coordinates
\
\   QQ15 to QQ15+5      The three 16-bit seeds of the nearest system to the
\                       original coordinates
\
\ Other entry points:
\
\   TT111-1             Contains an RTS
\
\ ******************************************************************************

.TT111

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

                        \ We now loop through every single system in the galaxy
                        \ and check the distance from (QQ9, QQ10). We get the
                        \ galactic coordinates of each system from the system's
                        \ seeds, like this:
                        \
                        \   x = s1_hi (which is stored in QQ15+3)
                        \   y = s0_hi (which is stored in QQ15+1)
                        \
                        \ so the following loops through each system in the
                        \ galaxy in turn and calculates the distance between
                        \ (QQ9, QQ10) and (s1_hi, s0_hi) to find the closest one

 LDY #127               \ Set Y = T = 127 to hold the shortest distance we've
 STY T                  \ found so far, which we initially set to half the
                        \ distance across the galaxy, or 127, as our coordinate
                        \ system ranges from (0,0) to (255, 255)

 LDA #0                 \ Set A = U = 0 to act as a counter for each system in
 STA U                  \ the current galaxy, which we start at system 0 and
                        \ loop through to 255, the last system

.TT130

 LDA QQ15+3             \ Set A = s1_hi - QQ9, the horizontal distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ9, QQ10)
 SBC QQ9

 BCS TT132              \ If a borrow didn't occur, i.e. s1_hi >= QQ9, then the
                        \ result is positive, so jump to TT132 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s1_hi - QQ9|)

.TT132

 LSR A                  \ Set S = A / 2
 STA S                  \       = |s1_hi - QQ9| / 2

 LDA QQ15+1             \ Set A = s0_hi - QQ10, the vertical distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ9, QQ10)
 SBC QQ10

 BCS TT134              \ If a borrow didn't occur, i.e. s0_hi >= QQ10, then the
                        \ result is positive, so jump to TT134 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s0_hi - QQ10|)

.TT134

 LSR A                  \ Set A = S + A / 2
 CLC                    \       = |s1_hi - QQ9| / 2 + |s0_hi - QQ10| / 2
 ADC S                  \
                        \ So A now contains the sum of the horizontal and
                        \ vertical distances, both divided by 2 so the result
                        \ fits into one byte, and although this doesn't contain
                        \ the actual distance between the systems, it's a good
                        \ enough approximation to use for comparing distances

 CMP T                  \ If A >= T, then this system's distance is bigger than
 BCS TT135              \ our "minimum distance so far" stored in T, so it's no
                        \ closer than the systems we have already found, so
                        \ skip to TT135 to move on to the next system

 STA T                  \ This system is the closest to (QQ9, QQ10) so far, so
                        \ update T with the new "distance" approximation

 LDX #5                 \ As this system is the closest we have found yet, we
                        \ want to store the system's seeds in case it ends up
                        \ being the closest of all, so we set up a counter in X
                        \ to copy six bytes (for three 16-bit numbers)

.TT136

 LDA QQ15,X             \ Copy the X-th byte in QQ15 to the X-th byte in QQ19,
 STA QQ19,X             \ where QQ15 contains the seeds for the system we just
                        \ found to be the closest so far, and QQ19 is temporary
                        \ storage

 DEX                    \ Decrement the counter

 BPL TT136              \ Loop back to TT136 if we still have more bytes to
                        \ copy

.TT135

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC U                  \ Increment the system counter in U

 BNE TT130              \ If U > 0 then we haven't done all 256 systems yet, so
                        \ loop back up to TT130

                        \ We have now finished checking all the systems in the
                        \ galaxy, and the seeds for the closest system are in
                        \ QQ19, so now we want to copy these seeds to QQ15,
                        \ to set the selected system to this closest system

 LDX #5                 \ So we set up a counter in X to copy six bytes (for
                        \ three 16-bit numbers)

.TT137

 LDA QQ19,X             \ Copy the X-th byte in QQ19 to the X-th byte in QQ15,
 STA QQ15,X

 DEX                    \ Decrement the counter

 BPL TT137              \ Loop back to TT137 if we still have more bytes to
                        \ copy

 LDA QQ15+1             \ The y-coordinate of the system described by the seeds
 STA QQ10               \ in QQ15 is in QQ15+1 (s0_hi), so we copy this to QQ10
                        \ as this is where we store the selected system's
                        \ y-coordinate

 LDA QQ15+3             \ The x-coordinate of the system described by the seeds
 STA QQ9                \ in QQ15 is in QQ15+3 (s1_hi), so we copy this to QQ9
                        \ as this is where we store the selected system's
                        \ x-coordinate

                        \ We have now found the closest system to (QQ9, QQ10)
                        \ and have set it as the selected system, so now we
                        \ need to work out the distance between the selected
                        \ system and the current system

 SEC                    \ Set A = QQ9 - QQ0, the horizontal distance between
 SBC QQ0                \ the selected system's x-coordinate (QQ9) and the
                        \ current system's x-coordinate (QQ0)

 BCS TT139              \ If a borrow didn't occur, i.e. QQ9 >= QQ0, then the
                        \ result is positive, so jump to TT139 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |QQ9 - QQ0|)

                        \ A now contains the difference between the two
                        \ systems' x-coordinates, with the sign removed. We
                        \ will refer to this as the x-delta ("delta" means
                        \ change or difference in maths)

.TT139

 JSR SQUA2              \ Set (A P) = A * A
                        \           = |QQ9 - QQ0| ^ 2
                        \           = x_delta ^ 2

 STA K+1                \ Store (A P) in K(1 0)
 LDA P
 STA K

 LDA QQ10               \ Set A = QQ10 - QQ1, the vertical distance between the
 SEC                    \ selected system's y-coordinate (QQ10) and the current
 SBC QQ1                \ system's y-coordinate (QQ1)

 BCS TT141              \ If a borrow didn't occur, i.e. QQ10 >= QQ1, then the
                        \ result is positive, so jump to TT141 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |QQ10 - QQ1|)

.TT141

 LSR A                  \ Set A = A / 2

                        \ A now contains the difference between the two
                        \ systems' y-coordinates, with the sign removed, and
                        \ halved. We halve the value because the galaxy in
                        \ in Elite is rectangular rather than square, and is
                        \ twice as wide (x-axis) as it is high (y-axis), so to
                        \ get a distance that matches the shape of the
                        \ long-range galaxy chart, we need to halve the
                        \ distance between the vertical y-coordinates. We will
                        \ refer to this as the y-delta

 JSR SQUA2              \ Set (A P) = A * A
                        \           = (|QQ10 - QQ1| / 2) ^ 2
                        \           = y_delta ^ 2

                        \ By this point we have the following results:
                        \
                        \   K(1 0) = x_delta ^ 2
                        \    (A P) = y_delta ^ 2
                        \
                        \ so to find the distance between the two points, we
                        \ can use Pythagoras - so first we need to add the two
                        \ results together, and then take the square root

 PHA                    \ Store the high byte of the y-axis value on the stack,
                        \ so we can use A for another purpose

 LDA P                  \ Set Q = P + K, which adds the low bytes of the two
 CLC                    \ calculated values
 ADC K
 STA Q

 PLA                    \ Restore the high byte of the y-axis value from the
                        \ stack into A again

 ADC K+1                \ Set R = A + K+1, which adds the high bytes of the two
 STA R                  \ calculated values, so we now have:
                        \
                        \   (R Q) = K(1 0) + (A P)
                        \         = (x_delta ^ 2) + (y_delta ^ 2)

 JSR LL5                \ Set Q = SQRT(R Q), so Q now contains the distance
                        \ between the two systems, in terms of coordinates

                        \ We now store the distance to the selected system * 4
                        \ in the two-byte location QQ8, by taking (0 Q) and
                        \ shifting it left twice, storing it in QQ8(1 0)

 LDA Q                  \ First we shift the low byte left by setting
 ASL A                  \ A = Q * 2, with bit 7 of A going into the C flag

 LDX #0                 \ Now we set the high byte in QQ8+1 to 0 and rotate
 STX QQ8+1              \ the C flag into bit 0 of QQ8+1
 ROL QQ8+1

 ASL A                  \ And then we repeat the shift left of (QQ8+1 A)
 ROL QQ8+1

 STA QQ8                \ And store A in the low byte, QQ8, so QQ8(1 0) now
                        \ contains Q * 4. Given that the width of the galaxy is
                        \ 256 in coordinate terms, the width of the galaxy
                        \ would be 1024 in the units we store in QQ8

 JMP TT24               \ Call TT24 to calculate system data from the seeds in
                        \ QQ15 and store them in the relevant locations, so our
                        \ new selected system is fully set up, and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: hy6
\       Type: Subroutine
\   Category: Flight
\    Summary: Print a message to say no hyperspacing inside the station
\
\ ------------------------------------------------------------------------------
\
\ Print "Docked" at the bottom of the screen to indicate we can't hyperspace
\ when docked.
\
\ ******************************************************************************

.hy6

 JSR CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows

 LDA #15                \ Move the text cursor to column 15 (the middle of the
 STA XC                 \ screen), setting A to 15 at the same time for the
                        \ following call to TT27

 JMP TT27               \ Print recursive token 129 ("{sentence case}DOCKED")
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: hyp
\       Type: Subroutine
\   Category: Flight
\    Summary: Start the hyperspace process
\
\ ------------------------------------------------------------------------------
\
\ Called when "H" or CTRL-H is pressed during flight. Checks the following:
\
\   * We are in space
\
\   * We are not already in a hyperspace countdown
\
\ If CTRL is being held down, we jump to Ghy to engage the galactic hyperdrive,
\ otherwise we check that:
\
\   * The selected system is not the current system
\
\   * We have enough fuel to make the jump
\
\ and if all the pre-jump checks are passed, we print the destination on-screen
\ and start the countdown.
\
\ ******************************************************************************

.hyp

 LDA QQ12               \ If we are docked (QQ12 = &FF) then jump to hy6 to
 BNE hy6                \ print an error message and return from the subroutine
                        \ using a tail call (as we can't hyperspace when docked)

 LDA QQ22+1             \ Fetch QQ22+1, which contains the number that's shown
                        \ on-screen during hyperspace countdown

 BNE zZ+1               \ If it is non-zero, return from the subroutine (as zZ+1
                        \ contains an RTS), as there is already a countdown in
                        \ progress

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed

 BMI Ghy                \ If it is, then the galactic hyperdrive has been
                        \ activated, so jump to Ghy to process it

 JSR hm                 \ This is a chart view, so call hm to redraw the chart
                        \ crosshairs

 LDA QQ8                \ If both bytes of the distance to the selected system
 ORA QQ8+1              \ in QQ8 are zero, return from the subroutine (as zZ+1
 BEQ zZ+1               \ contains an RTS), as the selected system is the
                        \ current system

 LDA #7                 \ Move the text cursor to column 7, row 23 (in the
 STA XC                 \ middle of the bottom text row)
 LDA #23
 STA YC

 LDA #0                 \ Set QQ17 = 0 to switch to ALL CAPS
 STA QQ17

 LDA #189               \ Print recursive token 29 ("HYPERSPACE ")
 JSR TT27

 LDA QQ8+1              \ If the high byte of the distance to the selected
 BNE TT147              \ system in QQ8 is > 0, then it is definitely too far to
                        \ jump (as our maximum range is 7.0 light years, or a
                        \ value of 70 in QQ8(1 0)), so jump to TT147 to print
                        \ "RANGE?" and return from the subroutine using a tail
                        \ call

 LDA QQ14               \ Fetch our current fuel level from Q114 into A

 CMP QQ8                \ If our fuel reserves are less than the distance to the
 BCC TT147              \ selected system, then we don't have enough fuel for
                        \ this jump, so jump to TT147 to print "RANGE?" and
                        \ return from the subroutine using a tail call

 LDA #'-'               \ Print a hyphen
 JSR TT27

 JSR cpl                \ Call cpl to print the name of the selected system

                        \ Fall through into wW to start the hyperspace countdown

\ ******************************************************************************
\
\       Name: wW
\       Type: Subroutine
\   Category: Flight
\    Summary: Start a hyperspace countdown
\
\ ------------------------------------------------------------------------------
\
\ Start the hyperspace countdown (for both inter-system hyperspace and the
\ galactic hyperdrive).
\
\ ******************************************************************************

.wW

 LDA #15                \ The hyperspace countdown starts from 15, so set A to
                        \ to 15 so we can set the two hyperspace counters

 STA QQ22+1             \ Set the number in QQ22+1 to 15, which is the number
                        \ that's shown on-screen during the hyperspace countdown

 STA QQ22               \ Set the number in QQ22 to 15, which is the internal
                        \ counter that counts down by 1 each iteration of the
                        \ main game loop, and each time it reaches zero, the
                        \ on-screen counter gets decremented, and QQ22 gets set
                        \ to 5, so setting QQ22 to 15 here makes the first tick
                        \ of the hyperspace counter longer than subsequent ticks

 TAX                    \ Print the 8-bit number in X (i.e. 15) at text location
 JMP ee3                \ (0, 1), padded to 5 digits, so it appears in the top
                        \ left corner of the screen, and return from the
                        \ subroutine using a tail call

\.hy5                   \ This instruction and the hy5 label are commented out
\RTS                    \ in the original - they can actually be found at the
                        \ end of the jmp routine below, so perhaps this is where
                        \ they were originally, but the authors realised they
                        \ could save a byte by using a tail call instead of an
                        \ RTS?

\ ******************************************************************************
\
\       Name: Ghy
\       Type: Subroutine
\   Category: Flight
\    Summary: Perform a galactic hyperspace jump
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Engage the galactic hyperdrive. Called from the hyp routine above if CTRL-H is
\ being pressed.
\
\ This routine also updates the galaxy seeds to point to the next galaxy. Using
\ a galactic hyperdrive rotates each seed byte to the left, rolling each byte
\ left within itself like this:
\
\   01234567 -> 12345670
\
\ to get the seeds for the next galaxy. So after 8 galactic jumps, the seeds
\ roll round to those of the first galaxy again.
\
\ We always arrive in a new galaxy at galactic coordinates (96, 96), and then
\ find the nearest system and set that as our location.
\
\ Other entry points:
\
\   zZ+1                Contains an RTS
\
\ ******************************************************************************

.Ghy

IF _TEXT_SOURCES

 JSR TT111              \ Call TT111 to set the current system to the nearest
                        \ system to (QQ9, QQ10), and put the seeds of the
                        \ nearest system into QQ15 to QQ15+5
                        \
                        \ This appears to be a failed attempt to fix a bug in
                        \ the cassette version, where the galactic hyperdrive
                        \ will take us to coordinates (96, 96) in the new
                        \ galaxy, even if there isn't actually a system there,
                        \ so if we jump when you are low on fuel, it is
                        \ possible to get stuck in the middle of nowhere when
                        \ changing galaxy
                        \
                        \ All the other versions contain a fix for this bug that
                        \ involves adding an extra JSR TT111 instruction after
                        \ the coordinates are set to (96, 96) below, which finds
                        \ the nearest system to those coordinates  and sets that
                        \ as the current system
                        \
                        \ The cassette version on the original source disc
                        \ doesn't contain this instruction, and although the
                        \ text sources do, it's in the wrong place at the start
                        \ of the Ghy routine, as the fix only works if it's done
                        \ after the new coordinates are set, not before

ENDIF

 LDX GHYP               \ Fetch GHYP, which tells us whether we own a galactic
 BEQ hy5                \ hyperdrive, and if it is zero, which means we don't,
                        \ return from the subroutine (as hy5 contains an RTS)

 INX                    \ We own a galactic hyperdrive, so X is &FF, so this
                        \ instruction sets X = 0

 STX QQ8                \ Set the distance to the selected system in QQ8(1 0)
 STX QQ8+1              \ to 0

 STX GHYP               \ The galactic hyperdrive is a one-use item, so set GHYP
                        \ to 0 so we no longer have one fitted

 STX FIST               \ Changing galaxy also clears our criminal record, so
                        \ set our legal status in FIST to 0 ("clean")

 JSR wW                 \ Call wW to start the hyperspace countdown

 LDX #5                 \ To move galaxy, we rotate the galaxy's seeds left, so
                        \ set a counter in X for the 6 seed bytes

 INC GCNT               \ Increment the current galaxy number in GCNT

 LDA GCNT               \ Set GCNT = GCNT mod 8, so we jump from galaxy 7 back
 AND #7                 \ to galaxy 0 (shown in-game as going from galaxy 8 back
 STA GCNT               \ to the starting point in galaxy 1)

.G1

 LDA QQ21,X             \ Load the X-th seed byte into A

 ASL A                  \ Set the C flag to bit 7 of the seed

 ROL QQ21,X             \ Rotate the seed in memory, which will add bit 7 back
                        \ in as bit 0, so this rolls the seed around on itself

 DEX                    \ Decrement the counter

 BPL G1                 \ Loop back for the next seed byte, until we have
                        \ rotated them all

\JSR DORND              \ This instruction is commented out in the original
                        \ source, and would set A and X to random numbers, so
                        \ perhaps the original plan was to arrive in each new
                        \ galaxy in a random place?

.zZ

 LDA #96                \ Set (QQ9, QQ10) to (96, 96), which is where we always
 STA QQ9                \ arrive in a new galaxy (the selected system will be
 STA QQ10               \ set to the nearest actual system later on)

 JSR TT110              \ Call TT110 to show the front space view

 LDA #116               \ Print recursive token 116 (GALACTIC HYPERSPACE ")
 JSR MESS               \ as an in-flight message

                        \ Fall through into jmp to set the system to the
                        \ current system and return from the subroutine there

\ ******************************************************************************
\
\       Name: jmp
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the current system to the selected system
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   (QQ0, QQ1)          The galactic coordinates of the new system
\
\ Other entry points:
\
\   hy5                 Contains an RTS
\
\ ******************************************************************************

.jmp

 LDA QQ9                \ Set the current system's galactic x-coordinate to the
 STA QQ0                \ x-coordinate of the selected system

 LDA QQ10               \ Set the current system's galactic y-coordinate to the
 STA QQ1                \ y-coordinate of the selected system

.hy5

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ee3
\       Type: Subroutine
\   Category: Text
\    Summary: Print the hyperspace countdown in the top-left of the screen
\
\ ------------------------------------------------------------------------------
\
\ Print the 8-bit number in X at text location (0, 1). Print the number to
\ 5 digits, left-padding with spaces for numbers with fewer than 3 digits (so
\ numbers < 10000 are right-aligned), with no decimal point.
\
\ Arguments:
\
\   X                   The number to print
\
\ ******************************************************************************

.ee3

 LDY #1                 \ Move the text cursor to row 1
 STY YC

 DEY                    \ Decrement Y to 0 for the high byte in pr6

 STY XC                 \ Move the text cursor to column 0

                        \ Fall through into pr6 to print X to 5 digits, as the
                        \ high byte in Y is 0

\ ******************************************************************************
\
\       Name: pr6
\       Type: Subroutine
\   Category: Text
\    Summary: Print 16-bit number, left-padded to 5 digits, no point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned),
\ with no decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\ ******************************************************************************

.pr6

 CLC                    \ Do not display a decimal point when printing

                        \ Fall through into pr5 to print X to 5 digits

\ ******************************************************************************
\
\       Name: pr5
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 16-bit number, left-padded to 5 digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned).
\ Optionally include a decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\   C flag              If set, include a decimal point
\
\ ******************************************************************************

.pr5

 LDA #5                 \ Set the number of digits to print to 5

 JMP TT11               \ Call TT11 to print (Y X) to 5 digits and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT147
\       Type: Subroutine
\   Category: Text
\    Summary: Print an error when a system is out of hyperspace range
\
\ ------------------------------------------------------------------------------
\
\ Print "RANGE?" for when the hyperspace distance is too far
\
\ ******************************************************************************

.TT147

 LDA #202               \ Load A with token 42 ("RANGE") and fall through into
                        \ prq to print it, followed by a question mark

\ ******************************************************************************
\
\       Name: prq
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a question mark
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.prq

 JSR TT27               \ Print the text token in A

 LDA #'?'               \ Print a question mark and return from the
 JMP TT27               \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT151
\       Type: Subroutine
\   Category: Market
\    Summary: Print the name, price and availability of a market item
\  Deep dive: Market item prices and availability
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of the market item to print, 0-16 (see QQ23
\                       for details of item numbers)
\
\ Returns:
\
\   QQ19+1              Byte #1 from the market prices table for this item
\
\   QQ24                The item's price / 4
\
\   QQ25                The item's availability
\
\ ******************************************************************************

.TT151

 PHA                    \ Store the item number on the stack and in QQ14+4
 STA QQ19+4

 ASL A                  \ Store the item number * 4 in QQ19, so this will act as
 ASL A                  \ an index into the market prices table at QQ23 for this
 STA QQ19               \ item (as there are four bytes per item in the table)

 LDA #1                 \ Move the text cursor to column 1, for the item's name
 STA XC

 PLA                    \ Restore the item number

 ADC #208               \ Print recursive token 48 + A, which will be in the
 JSR TT27               \ range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
                        \ prints the item's name

 LDA #14                \ Move the text cursor to column 14, for the price
 STA XC

 LDX QQ19               \ Fetch byte #1 from the market prices table (units and
 LDA QQ23+1,X           \ economic_factor) for this item and store in QQ19+1
 STA QQ19+1

 LDA QQ26               \ Fetch the random number for this system visit and
 AND QQ23+3,X           \ AND with byte #3 from the market prices table (mask)
                        \ to give:
                        \
                        \   A = random AND mask

 CLC                    \ Add byte #0 from the market prices table (base_price),
 ADC QQ23,X             \ so we now have:
 STA QQ24               \
                        \   A = base_price + (random AND mask)

 JSR TT152              \ Call TT152 to print the item's unit ("t", "kg" or
                        \ "g"), padded to a width of two characters

 JSR var                \ Call var to set QQ19+3 = economy * |economic_factor|
                        \ (and set the availability of alien items to 0)

 LDA QQ19+1             \ Fetch the byte #1 that we stored above and jump to
 BMI TT155              \ TT155 if it is negative (i.e. if the economic_factor
                        \ is negative)

 LDA QQ24               \ Set A = QQ24 + QQ19+3
 ADC QQ19+3             \
                        \       = base_price + (random AND mask)
                        \         + (economy * |economic_factor|)
                        \
                        \ which is the result we want, as the economic_factor
                        \ is positive

 JMP TT156              \ Jump to TT156 to multiply the result by 4

.TT155

 LDA QQ24               \ Set A = QQ24 - QQ19+3
 SEC                    \
 SBC QQ19+3             \       = base_price + (random AND mask)
                        \         - (economy * |economic_factor|)
                        \
                        \ which is the result we want, as economic_factor
                        \ is negative

.TT156

 STA QQ24               \ Store the result in QQ24 and P
 STA P

 LDA #0                 \ Set A = 0 and call GC2 to calculate (Y X) = (A P) * 4,
 JSR GC2                \ which is the same as (Y X) = P * 4 because A = 0

 SEC                    \ We now have our final price, * 10, so we can call pr5
 JSR pr5                \ to print (Y X) to 5 digits, including a decimal
                        \ point, as the C flag is set

 LDY QQ19+4             \ We now move on to availability, so fetch the market
                        \ item number that we stored in QQ19+4 at the start

 LDA #5                 \ Set A to 5 so we can print the availability to 5
                        \ digits (right-padded with spaces)

 LDX AVL,Y              \ Set X to the item's availability, which is given in
                        \ the AVL table

 STX QQ25               \ Store the availability in QQ25

 CLC                    \ Clear the C flag

 BEQ TT172              \ If none are available, jump to TT172 to print a tab
                        \ and a "-"

 JSR pr2+2              \ Otherwise print the 8-bit number in X to 5 digits,
                        \ right-aligned with spaces. This works because we set
                        \ A to 5 above, and we jump into the pr2 routine just
                        \ after the first instruction, which would normally
                        \ set the number of digits to 3

 JMP TT152              \ Print the unit ("t", "kg" or "g") for the market item,
                        \ with a following space if required to make it two
                        \ characters long

.TT172

 LDA XC                 \ Move the text cursor in XC to the right by 4 columns,
 ADC #4                 \ so the cursor is where the last digit would be if we
 STA XC                 \ were printing a 5-digit availability number

 LDA #'-'               \ Print a "-" character by jumping to TT162+2, which
 BNE TT162+2            \ contains JMP TT27 (this BNE is effectively a JMP as A
                        \ will never be zero), and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT152
\       Type: Subroutine
\   Category: Market
\    Summary: Print the unit ("t", "kg" or "g") for a market item
\
\ ------------------------------------------------------------------------------
\
\ Print the unit ("t", "kg" or "g") for the market item whose byte #1 from the
\ market prices table is in QQ19+1, right-padded with spaces to a width of two
\ characters (so that's "t ", "kg" or "g ").
\
\ ******************************************************************************

.TT152

 LDA QQ19+1             \ Fetch the economic_factor from QQ19+1

 AND #96                \ If bits 5 and 6 are both clear, jump to TT160 to
 BEQ TT160              \ print "t" for tonne, followed by a space, and return
                        \ from the subroutine using a tail call

 CMP #32                \ If bit 5 is set, jump to TT161 to print "kg" for
 BEQ TT161              \ kilograms, and return from the subroutine using a tail
                        \ call

 JSR TT16a              \ Otherwise call TT16a to print "g" for grams, and fall
                        \ through into TT162 to print a space and return from
                        \ the subroutine

\ ******************************************************************************
\
\       Name: TT162
\       Type: Subroutine
\   Category: Text
\    Summary: Print a space
\
\ Other entry points:
\
\   TT162+2             Jump to TT27 to print the text token in A
\
\ ******************************************************************************

.TT162

 LDA #' '               \ Load a space character into A

 JMP TT27               \ Print the text token in A and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT160
\       Type: Subroutine
\   Category: Market
\    Summary: Print "t" (for tonne) and a space
\
\ ******************************************************************************

.TT160

 LDA #'t'               \ Load a "t" character into A

 JSR TT26               \ Print the character, using TT216 so that it doesn't
                        \ change the character case

 BCC TT162              \ Jump to TT162 to print a space and return from the
                        \ subroutine using a tail call (this BCC is effectively
                        \ a JMP as the C flag is cleared by TT26)

\ ******************************************************************************
\
\       Name: TT161
\       Type: Subroutine
\   Category: Market
\    Summary: Print "kg" (for kilograms)
\
\ ******************************************************************************

.TT161

 LDA #'k'               \ Load a "k" character into A

 JSR TT26               \ Print the character, using TT216 so that it doesn't
                        \ change the character case, and fall through into
                        \ TT16a to print a "g" character

\ ******************************************************************************
\
\       Name: TT16a
\       Type: Subroutine
\   Category: Market
\    Summary: Print "g" (for grams)
\
\ ******************************************************************************

.TT16a

 LDA #'g'               \ Load a "g" character into A

 JMP TT26               \ Print the character, using TT216 so that it doesn't
                        \ change the character case, and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT163
\       Type: Subroutine
\   Category: Market
\    Summary: Print the headers for the table of market prices
\
\ ------------------------------------------------------------------------------
\
\ Print the column headers for the prices table in the Buy Cargo and Market
\ Price screens.
\
\ ******************************************************************************

.TT163

 LDA #17                \ Move the text cursor in XC to column 17
 STA XC

 LDA #255               \ Print recursive token 95 token ("UNIT  QUANTITY
 BNE TT162+2            \ {crlf} PRODUCT   UNIT PRICE FOR SALE{crlf}{lf}") by
                        \ jumping to TT162+2, which contains JMP TT27 (this BNE
                        \ is effectively a JMP as A will never be zero), and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT167
\       Type: Subroutine
\   Category: Market
\    Summary: Show the Market Price screen (red key f7)
\
\ ******************************************************************************

.TT167

 LDA #16                \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 16 (Market
                        \ Price screen)

 LDA #5                 \ Move the text cursor to column 4
 STA XC

 LDA #167               \ Print recursive token 7 ("{current system name} MARKET
 JSR NLIN3              \ PRICES") and draw a horizontal line at pixel row 19
                        \ to box in the title

 LDA #3                 \ Move the text cursor to row 3
 STA YC

 JSR TT163              \ Print the column headers for the prices table

 LDA #0                 \ We're going to loop through all the available market
 STA QQ29               \ items, so we set up a counter in QQ29 to denote the
                        \ current item and start it at 0

.TT168

 LDX #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case, with the
 STX QQ17               \ next letter in capitals

 JSR TT151              \ Call TT151 to print the item name, market price and
                        \ availability of the current item, and set QQ24 to the
                        \ item's price / 4, QQ25 to the quantity available and
                        \ QQ19+1 to byte #1 from the market prices table for
                        \ this item

 INC YC                 \ Move the text cursor down one row

 INC QQ29               \ Increment QQ29 to point to the next item

 LDA QQ29               \ If QQ29 >= 17 then jump to TT168 as we have done the
 CMP #17                \ last item
 BCC TT168

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: var
\       Type: Subroutine
\   Category: Market
\    Summary: Calculate QQ19+3 = economy * |economic_factor|
\
\ ------------------------------------------------------------------------------
\
\ Set QQ19+3 = economy * |economic_factor|, given byte #1 of the market prices
\ table for an item. Also sets the availability of alien items to 0.
\
\ This routine forms part of the calculations for market item prices (TT151)
\ and availability (GVL).
\
\ Arguments:
\
\   QQ19+1              Byte #1 of the market prices table for this market item
\                       (which contains the economic_factor in bits 0-5, and the
\                       sign of the economic_factor in bit 7)
\
\ ******************************************************************************

.var

 LDA QQ19+1             \ Extract bits 0-5 from QQ19+1 into A, to get the
 AND #31                \ economic_factor without its sign, in other words:
                        \
                        \   A = |economic_factor|

 LDY QQ28               \ Set Y to the economy byte of the current system

 STA QQ19+2             \ Store A in QQ19+2

 CLC                    \ Clear the C flag so we can do additions below

 LDA #0                 \ Set AVL+16 (availability of alien items) to 0,
 STA AVL+16             \ setting A to 0 in the process

.TT153

                        \ We now do the multiplication by doing a series of
                        \ additions in a loop, building the result in A. Each
                        \ loop adds QQ19+2 (|economic_factor|) to A, and it
                        \ loops the number of times given by the economy byte;
                        \ in other words, because A starts at 0, this sets:
                        \
                        \   A = economy * |economic_factor|

 DEY                    \ Decrement the economy in Y, exiting the loop when it
 BMI TT154              \ becomes negative

 ADC QQ19+2             \ Add QQ19+2 to A

 JMP TT153              \ Loop back to TT153 to do another addition

.TT154

 STA QQ19+3             \ Store the result in QQ19+3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: hyp1
\       Type: Subroutine
\   Category: Universe
\    Summary: Process a jump to the system closest to (QQ9, QQ10)
\
\ ------------------------------------------------------------------------------
\
\ Do a hyperspace jump to the system closest to galactic coordinates
\ (QQ9, QQ10), and set up the current system's state to those of the new system.
\
\ Returns:
\
\   (QQ0, QQ1)          The galactic coordinates of the new system
\
\   QQ2 to QQ2+6        The seeds of the new system
\
\   EV                  Set to 0
\
\   QQ28                The new system's economy
\
\   tek                 The new system's tech level
\
\   gov                 The new system's government
\
\ Other entry points:
\
\   hyp1+3              Jump straight to the system at (QQ9, QQ10) without
\                       first calculating which system is closest. We do this
\                       if we already know that (QQ9, QQ10) points to a system
\
\ ******************************************************************************

.hyp1

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 JSR jmp                \ Set the current system to the selected system

 LDX #5                 \ We now want to copy the seeds for the selected system
                        \ in QQ15 into QQ2, where we store the seeds for the
                        \ current system, so set up a counter in X for copying
                        \ 6 bytes (for three 16-bit seeds)

.TT112

 LDA QQ15,X             \ Copy the X-th byte in QQ15 to the X-th byte in QQ2, to
 STA QQ2,X              \ update the selected system to the new one. Note that
                        \ this approach has a minor bug associated with it: if
                        \ your hyperspace counter hits 0 just as you're docking,
                        \ then you will magically appear in the station in your
                        \ hyperspace destination, without having to go to the
                        \ effort of actually flying there. This bug was fixed in
                        \ later versions by saving the destination seeds in a
                        \ separate location called safehouse, and using those
                        \ instead... but that isn't the case in this version

 DEX                    \ Decrement the counter

 BPL TT112              \ Loop back to TT112 if we still have more bytes to
                        \ copy

 INX                    \ Set X = 0 (as we ended the above loop with X = &FF)

 STX EV                 \ Set EV, the extra vessels spawning counter, to 0, as
                        \ we are entering a new system with no extra vessels
                        \ spawned

 LDA QQ3                \ Set the current system's economy in QQ28 to the
 STA QQ28               \ selected system's economy from QQ3

 LDA QQ5                \ Set the current system's tech level in tek to the
 STA tek                \ selected system's economy from QQ5

 LDA QQ4                \ Set the current system's government in gov to the
 STA gov                \ selected system's government from QQ4

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GVL
\       Type: Subroutine
\   Category: Universe
\    Summary: Calculate the availability of market items
\  Deep dive: Market item prices and availability
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Calculate the availability for each market item and store it in AVL. This is
\ called on arrival in a new system.
\
\ Other entry points:
\
\   hyR                 Contains an RTS
\
\ ******************************************************************************

.GVL

 JSR DORND              \ Set A and X to random numbers

 STA QQ26               \ Set QQ26 to the random byte that's used in the market
                        \ calculations

 LDX #0                 \ We are now going to loop through the market item
 STX XX4                \ availability table in AVL, so set a counter in XX4
                        \ (and X) for the market item number, starting with 0

.hy9

 LDA QQ23+1,X           \ Fetch byte #1 from the market prices table (units and
 STA QQ19+1             \ economic_factor) for item number X and store it in
                        \ QQ19+1

 JSR var                \ Call var to set QQ19+3 = economy * |economic_factor|
                        \ (and set the availability of alien items to 0)

 LDA QQ23+3,X           \ Fetch byte #3 from the market prices table (mask) and
 AND QQ26               \ AND with the random number for this system visit
                        \ to give:
                        \
                        \   A = random AND mask

 CLC                    \ Add byte #2 from the market prices table
 ADC QQ23+2,X           \ (base_quantity) so we now have:
                        \
                        \   A = base_quantity + (random AND mask)

 LDY QQ19+1             \ Fetch the byte #1 that we stored above and jump to
 BMI TT157              \ TT157 if it is negative (i.e. if the economic_factor
                        \ is negative)

 SEC                    \ Set A = A - QQ19+3
 SBC QQ19+3             \
                        \       = base_quantity + (random AND mask)
                        \         - (economy * |economic_factor|)
                        \
                        \ which is the result we want, as the economic_factor
                        \ is positive

 JMP TT158              \ Jump to TT158 to skip TT157

.TT157

 CLC                    \ Set A = A + QQ19+3
 ADC QQ19+3             \
                        \       = base_quantity + (random AND mask)
                        \         + (economy * |economic_factor|)
                        \
                        \ which is the result we want, as the economic_factor
                        \ is negative

.TT158

 BPL TT159              \ If A < 0, then set A = 0, so we don't have negative
 LDA #0                 \ availability

.TT159

 LDY XX4                \ Fetch the counter (the market item number) into Y

 AND #%00111111         \ Take bits 0-5 of A, i.e. A mod 64, and store this as
 STA AVL,Y              \ this item's availability in the Y=th byte of AVL, so
                        \ each item has a maximum availability of 63t

 INY                    \ Increment the counter into XX44, Y and A
 TYA
 STA XX4

 ASL A                  \ Set X = counter * 4, so that X points to the next
 ASL A                  \ item's entry in the four-byte market prices table,
 TAX                    \ ready for the next loop

 CMP #63                \ If A < 63, jump back up to hy9 to set the availability
 BCC hy9                \ for the next market item

.hyR

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GTHG
\       Type: Subroutine
\   Category: Universe
\    Summary: Spawn a Thargoid ship and a Thargon companion
\  Deep dive: Fixing ship positions
\
\ ******************************************************************************

.GTHG

 JSR Ze                 \ Call Ze to initialise INWK
                        \
                        \ Note that because Ze uses the value of X returned by
                        \ DORND, and X contains the value of A returned by the
                        \ previous call to DORND, this does not set the new ship
                        \ to a totally random location. See the deep dive on
                        \ "Fixing ship positions" for details

 LDA #%11111111         \ Set the AI flag in byte #32 so that the ship has AI,
 STA INWK+32            \ is extremely and aggressively hostile, and has E.C.M.

 LDA #THG               \ Call NWSHP to add a new Thargoid ship to our local
 JSR NWSHP              \ bubble of universe

 LDA #TGL               \ Call NWSHP to add a new Thargon ship to our local
 JMP NWSHP              \ bubble of universe, and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: MJP
\       Type: Subroutine
\   Category: Flight
\    Summary: Process a mis-jump into witchspace
\
\ ------------------------------------------------------------------------------
\
\ Process a mis-jump into witchspace (which happens very rarely). Witchspace has
\ a strange, almost dust-free aspect to it, and it is populated by hostile
\ Thargoids. Using our escape pod will be fatal, and our position on the
\ galactic chart is in-between systems. It is a scary place...
\
\ There is a 1% chance that this routine is called from TT18 instead of doing
\ a normal hyperspace, or we can manually trigger a mis-jump by holding down
\ CTRL after first enabling the "author display" configuration option ("X") when
\ paused.
\
\ Other entry points:
\
\   ptg                 Called when the user manually forces a mis-jump
\
\ ******************************************************************************

.ptg

 LSR COK                \ Set bit 0 of the competition flags in COK, so that the
 SEC                    \ copmpetition code will include the fact that we have
 ROL COK                \ manually forced a mis-jump into witchspace

.MJP

\LDA #1                 \ This instruction is commented out in the original
                        \ source - it is not required as a call to TT66-2 sets
                        \ A to 1 for us. This is presumably an example of the
                        \ authors saving a couple of bytes by calling TT66-2
                        \ instead of TT66, while leaving the original LDA
                        \ instruction in place

 JSR TT66-2             \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 1

 JSR LL164              \ Call LL164 to show the hyperspace tunnel and make the
                        \ hyperspace sound for a second time (as we already
                        \ called LL164 in TT18)

 JSR RES2               \ Reset a number of flight variables and workspaces, as
                        \ well as setting Y to &FF

 STY MJ                 \ Set the mis-jump flag in MJ to &FF, to indicate that
                        \ we are now in witchspace

.MJP1

 JSR GTHG               \ Call GTHG to spawn a Thargoid ship

 LDA #3                 \ Fetch the number of Thargoid ships from MANY+THG, and
 CMP MANY+THG           \ if it is less than or equal to 3, loop back to MJP1 to
 BCS MJP1               \ spawn another one, until we have four Thargoids

 STA NOSTM              \ Set NOSTM (the maximum number of stardust particles)
                        \ to 3, so there are fewer bits of stardust in
                        \ witchspace (normal space has a maximum of 18)

 LDX #0                 \ Initialise the front space view
 JSR LOOK1

 LDA QQ1                \ Fetch the current system's galactic y-coordinate in
 EOR #%00011111         \ QQ1 and flip bits 0-5, so we end up somewhere in the
 STA QQ1                \ vicinity of our original destination, but above or
                        \ below it in the galactic chart

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT18
\       Type: Subroutine
\   Category: Flight
\    Summary: Try to initiate a jump into hyperspace
\
\ ------------------------------------------------------------------------------
\
\ Try to go through hyperspace. Called from TT102 in the main loop when the
\ hyperspace countdown has finished.
\
\ ******************************************************************************

.TT18

 LDA QQ14               \ Subtract the distance to the selected system (in QQ8)
 SEC                    \ from the amount of fuel in our tank (in QQ14) into A
 SBC QQ8

 STA QQ14               \ Store the updated fuel amount in QQ14

 LDA QQ11               \ If the current view is not a space view, jump to ee5
 BNE ee5                \ to skip the following

 JSR TT66               \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 0 (space
                        \ view)

 JSR LL164              \ Call LL164 to show the hyperspace tunnel and make the
                        \ hyperspace sound

.ee5

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

 AND PATG               \ If the game is configured to show the author's names
                        \ on the start-up screen, then PATG will contain &FF,
                        \ otherwise it will be 0

 BMI ptg                \ By now, A will be negative if we are holding down CTRL
                        \ and author names are configured, which is what we have
                        \ to do in order to trigger a manual mis-jump, so jump
                        \ to ptg to do a mis-jump (ptg not only mis-jumps, but
                        \ updates the competition flags, so Acornsoft could tell
                        \ from the competition code whether this feature had
                        \ been used)

 JSR DORND              \ Set A and X to random numbers

 CMP #253               \ If A >= 253 (1% chance) then jump to MJP to trigger a
 BCS MJP                \ mis-jump into witchspace

\JSR TT111              \ This instruction is commented out in the original
                        \ source. It finds the closest system to coordinates
                        \ (QQ9, QQ10), but we don't need to do this as the
                        \ crosshairs will already be on a system by this point

 JSR hyp1+3             \ Jump straight to the system at (QQ9, QQ10) without
                        \ first calculating which system is closest

 JSR GVL                \ Calculate the availability for each market item in the
                        \ new system

 JSR RES2               \ Reset a number of flight variables and workspaces

 JSR SOLAR              \ Halve our legal status, update the missile indicators,
                        \ and set up data blocks and slots for the planet and
                        \ sun

 LDA QQ11               \ If the current view in QQ11 is not a space view (0) or
 AND #%00111111         \ one of the charts (64 or 128), return from the
 BNE hyR                \ subroutine (as hyR contains an RTS)

 JSR TTX66              \ Otherwise clear the screen and draw a white border

 LDA QQ11               \ If the current view is one of the charts, jump to
 BNE TT114              \ TT114 (from which we jump to the correct routine to
                        \ display the chart)

 INC QQ11               \ This is a space view, so increment QQ11 to 1

                        \ Fall through into TT110 to show the front space view

\ ******************************************************************************
\
\       Name: TT110
\       Type: Subroutine
\   Category: Flight
\    Summary: Launch from a station or show the front space view
\
\ ------------------------------------------------------------------------------
\
\ Launch the ship (if we are docked), or show the front space view (if we are
\ already in space).
\
\ Called when red key f0 is pressed while docked (launch), after we arrive in a
\ new galaxy, or after a hyperspace if the current view is a space view.
\
\ ******************************************************************************

.TT110

 LDX QQ12               \ If we are not docked (QQ12 = 0) then jump to NLUNCH
 BEQ NLUNCH             \ to skip the launch tunnel and setup process

 JSR LAUN               \ Show the space station launch tunnel

 JSR RES2               \ Reset a number of flight variables and workspaces

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 INC INWK+8             \ Increment z_sign ready for the call to SOS, so the
                        \ planet appears at a z_sign of 1 in front of us when
                        \ we launch

 JSR SOS1               \ Call SOS1 to set up the planet's data block and add it
                        \ to FRIN, where it will get put in the first slot as
                        \ it's the first one to be added to our local bubble of
                        \ universe following the call to RES2 above

 LDA #128               \ For the space station, set z_sign to &80, so it's
 STA INWK+8             \ behind us (&80 is negative)

 INC INWK+7             \ And increment z_hi, so it's only just behind us

 JSR NWSPS              \ Add a new space station to our local bubble of
                        \ universe

 LDA #12                \ Set our launch speed in DELTA to 12
 STA DELTA

 JSR BAD                \ Call BAD to work out how much illegal contraband we
                        \ are carrying in our hold (A is up to 40 for a
                        \ standard hold crammed with contraband, up to 70 for
                        \ an extended cargo hold full of narcotics and slaves)

 ORA FIST               \ OR the value in A with our legal status in FIST to
                        \ get a new value that is at least as high as both
                        \ values, to reflect the fact that launching with a
                        \ hold full of contraband can only make matters worse

 STA FIST               \ Update our legal status with the new value

.NLUNCH

 LDX #0                 \ Set QQ12 to 0 to indicate we are not docked
 STX QQ12

 JMP LOOK1              \ Jump to LOOK1 to switch to the front view (X = 0),
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT114
\       Type: Subroutine
\   Category: Charts
\    Summary: Display either the Long-range or Short-range Chart
\
\ ------------------------------------------------------------------------------
\
\ Display either the Long-range or Short-range Chart, depending on the current
\ view setting. Called from TT18 once we know the current view is one of the
\ charts.
\
\ Arguments:
\
\   A                   The current view, loaded from QQ11
\
\ ******************************************************************************

.TT114

 BMI TT115              \ If bit 7 of the current view is set (i.e. the view is
                        \ the Short-range Chart, 128), skip to TT115 below to
                        \ jump to TT23 to display the chart

 JMP TT22               \ Otherwise the current view is the Long-range Chart, so
                        \ jump to TT22 to display it

.TT115

 JMP TT23               \ Jump to TT23 to display the Short-range Chart

\ ******************************************************************************
\
\       Name: LCASH
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Subtract an amount of cash from the cash pot
\
\ ------------------------------------------------------------------------------
\
\ Subtract (Y X) cash from the cash pot in CASH, but only if there is enough
\ cash in the pot. As CASH is a four-byte number, this calculates:
\
\   CASH(0 1 2 3) = CASH(0 1 2 3) - (0 0 Y X)
\
\ Returns:
\
\   C flag              If set, there was enough cash to do the subtraction
\
\                       If clear, there was not enough cash to do the
\                       subtraction
\
\ ******************************************************************************

.LCASH

 STX T1                 \ Subtract the least significant bytes:
 LDA CASH+3             \
 SEC                    \   CASH+3 = CASH+3 - X
 SBC T1
 STA CASH+3

 STY T1                 \ Then the second most significant bytes:
 LDA CASH+2             \
 SBC T1                 \   CASH+2 = CASH+2 - Y
 STA CASH+2

 LDA CASH+1             \ Then the third most significant bytes (which are 0):
 SBC #0                 \
 STA CASH+1             \   CASH+1 = CASH+1 - 0

 LDA CASH               \ And finally the most significant bytes (which are 0):
 SBC #0                 \
 STA CASH               \   CASH = CASH - 0

 BCS TT113              \ If the C flag is set then the subtraction didn't
                        \ underflow, so the value in CASH is correct and we can
                        \ jump to TT113 to return from the subroutine with the
                        \ C flag set to indicate success (as TT113 contains an
                        \ RTS)

                        \ Otherwise we didn't have enough cash in CASH to
                        \ subtract (Y X) from it, so fall through into
                        \ MCASH to reverse the sum and restore the original
                        \ value in CASH, and returning with the C flag clear

\ ******************************************************************************
\
\       Name: MCASH
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Add an amount of cash to the cash pot
\
\ ------------------------------------------------------------------------------
\
\ Add (Y X) cash to the cash pot in CASH. As CASH is a four-byte number, this
\ calculates:
\
\   CASH(0 1 2 3) = CASH(0 1 2 3) + (Y X)
\
\ Other entry points:
\
\   TT113               Contains an RTS
\
\ ******************************************************************************

.MCASH

 TXA                    \ Add the least significant bytes:
 CLC                    \
 ADC CASH+3             \   CASH+3 = CASH+3 + X
 STA CASH+3

 TYA                    \ Then the second most significant bytes:
 ADC CASH+2             \
 STA CASH+2             \   CASH+2 = CASH+2 + Y

 LDA CASH+1             \ Then the third most significant bytes (which are 0):
 ADC #0                 \
 STA CASH+1             \   CASH+1 = CASH+1 + 0

 LDA CASH               \ And finally the most significant bytes (which are 0):
 ADC #0                 \
 STA CASH               \   CASH = CASH + 0

 CLC                    \ Clear the C flag, so if the above was done following
                        \ a failed LCASH call, the C flag correctly indicates
                        \ failure

.TT113

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GCASH
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (Y X) = P * Q * 4
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following multiplication of unsigned 8-bit numbers:
\
\   (Y X) = P * Q * 4
\
\ ******************************************************************************

.GCASH

 JSR MULTU              \ Call MULTU to calculate (A P) = P * Q

\ ******************************************************************************
\
\       Name: GC2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (Y X) = (A P) * 4
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following multiplication of unsigned 16-bit numbers:
\
\   (Y X) = (A P) * 4
\
\ ******************************************************************************

.GC2

 ASL P                  \ Set (A P) = (A P) * 4
 ROL A
 ASL P
 ROL A

 TAY                    \ Set (Y X) = (A P)
 LDX P

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: EQSHP
\       Type: Subroutine
\   Category: Equipment
\    Summary: Show the Equip Ship screen (red key f3)
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   err                 Beep, pause and go to the docking bay (i.e. show the
\                       Status Mode screen)
\
\   pres                Given an item number A with the item name in recursive
\                       token Y, show an error to say that the item is already
\                       present, refund the cost of the item, and then beep and
\                       exit to the docking bay (i.e. show the Status Mode
\                       screen)
\
\ ******************************************************************************

.bay

 JMP BAY                \ Go to the docking bay (i.e. show the Status Mode
                        \ screen)

.EQSHP

 JSR DIALS              \ Call DIALS to update the dashboard

 LDA #32                \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 32 (Equip
                        \ Ship screen)

 LDA #12                \ Move the text cursor to column 12
 STA XC

 LDA #207               \ Print recursive token 47 ("EQUIP") followed by a space
 JSR spc

 LDA #185               \ Print recursive token 25 ("SHIP") and draw a
 JSR NLIN3              \ horizontal line at pixel row 19 to box in the title

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case, with the
 STA QQ17               \ next letter in capitals

 INC YC                 \ Move the text cursor down one line

 LDA tek                \ Fetch the tech level of the current system from tek
 CLC                    \ and add 3 (the tech level is stored as 0-14, so A is
 ADC #3                 \ now set to between 3 and 17)

 CMP #12                \ If A >= 12 then set A = 12, so A is now set to between
 BCC P%+4               \ 3 and 12
 LDA #12

 STA Q                  \ Set QQ25 = A (so QQ25 is in the range 3-12 and
 STA QQ25               \ represents number of the most advanced item available
 INC Q                  \ in this system, which we can pass to gnum below when
                        \ asking which item we want to buy)
                        \
                        \ Set Q = A + 1 (so Q is in the range 4-13 and contains
                        \ QQ25 + 1, i.e. the highest item number on sale + 1)

 LDA #70                \ Set A = 70 - QQ14, where QQ14 contains the current
 SEC                    \ fuel in light years * 10, so this leaves the amount
 SBC QQ14               \ of fuel we need to fill 'er up (in light years * 10)

 ASL A                  \ The price of fuel is always 2 Cr per light year, so we
 STA PRXS               \ double A and store it in PRXS, as the first price in
                        \ the price list (which is reserved for fuel), and
                        \ because the table contains prices as price * 10, it's
                        \ in the right format (so tank containing 7.0 light
                        \ years of fuel would be 14.0 Cr, or a PRXS value of
                        \ 140)

 LDX #1                 \ We are now going to work our way through the equipment
                        \ price list at PRXS, printing out the equipment that is
                        \ available at this station, so set a counter in X,
                        \ starting at 1, to hold the number of the current item
                        \ plus 1 (so the item number in X loops through 1-13)

.EQL1

 STX XX13               \ Store the current item number + 1 in XX13

 JSR TT67               \ Print a newline

 LDX XX13               \ Print the current item number + 1 to 3 digits, left-
 CLC                    \ padding with spaces, and with no decimal point, so the
 JSR pr2                \ items are numbered from 1

 JSR TT162              \ Print a space

 LDA XX13               \ Print recursive token 104 + XX13, which will be in the
 CLC                    \ range 105 ("FUEL") to 116 ("GALACTIC HYPERSPACE ")
 ADC #104               \ so this prints the current item's name
 JSR TT27

 LDA XX13               \ Call prx-3 to set (Y X) to the price of the item with
 JSR prx-3              \ number XX13 - 1 (as XX13 contains the item number + 1)

 SEC                    \ Set the C flag so we will print a decimal point when
                        \ we print the price

 LDA #25                \ Move the text cursor to column 25
 STA XC

 LDA #6                 \ Print the number in (Y X) to 6 digits, left-padding
 JSR TT11               \ with spaces and including a decimal point, which will
                        \ be the correct price for this item as (Y X) contains
                        \ the price * 10, so the trailing zero will go after the
                        \ decimal point (i.e. 5250 will be printed as 525.0)

 LDX XX13               \ Increment the current item number in XX13
 INX

 CPX Q                  \ If X < Q, loop back up to print the next item on the
 BCC EQL1               \ list of equipment available at this station

 JSR CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows

 LDA #127               \ Print recursive token 127 ("ITEM") followed by a
 JSR prq                \ question mark

 JSR gnum               \ Call gnum to get a number from the keyboard, which
                        \ will be the number of the item we want to purchase,
                        \ returning the number entered in A and R, and setting
                        \ the C flag if the number is bigger than the highest
                        \ item number in QQ25

 BEQ bay                \ If no number was entered, jump up to bay to go to the
                        \ docking bay (i.e. show the Status Mode screen)

 BCS bay                \ If the number entered was too big, jump up to bay to
                        \ go to the docking bay (i.e. show the Status Mode
                        \ screen)

 SBC #0                 \ Set A to the number entered - 1 (because the C flag is
                        \ clear), which will be the actual item number we want
                        \ to buy

 LDX #2                 \ Move the text cursor to column 2
 STX XC

 INC YC                 \ Move the text cursor down one line

 PHA                    \ While preserving the value in A, call eq to subtract
 JSR eq                 \ the price of the item we want to buy (which is in A)
 PLA                    \ from our cash pot, but only if we have enough cash in
                        \ the pot. If we don't have enough cash, exit to the
                        \ docking bay (i.e. show the Status Mode screen)

 BNE et0                \ If A is not 0 (i.e. the item we've just bought is not
                        \ fuel), skip to et0

 STA MCNT               \ We just bought fuel, so we zero the main loop counter

 LDX #70                \ Set the current fuel level * 10 in QQ14 to 70, or 7.0
 STX QQ14               \ light years (a full tank)

.et0

 CMP #1                 \ If A is not 1 (i.e. the item we've just bought is not
 BNE et1                \ a missile), skip to et1

 LDX NOMSL              \ Fetch the current number of missiles from NOMSL into X

 INX                    \ Increment X to the new number of missiles

 LDY #117               \ Set Y to recursive token 117 ("ALL")

 CPX #5                 \ If buying this missile would give us 5 missiles, this
 BCS pres               \ is more than the maximum of 4 missiles that we can
                        \ fit, so jump to pres to show the error "All Present",
                        \ beep and exit to the docking bay (i.e. show the Status
                        \ Mode screen)

 STX NOMSL              \ Otherwise update the number of missiles in NOMSL

 JSR msblob             \ Reset the dashboard's missile indicators so none of
                        \ them are targeted

.et1

 LDY #107               \ Set Y to recursive token 107 ("LARGE CARGO{sentence
                        \ case} BAY")

 CMP #2                 \ If A is not 2 (i.e. the item we've just bought is not
 BNE et2                \ a large cargo bay), skip to et2

 LDX #37                \ If our current cargo capacity in CRGO is 37, then we
 CPX CRGO               \ already have a large cargo bay fitted, so jump to pres
 BEQ pres               \ to show the error "Large Cargo Bay Present", beep and
                        \ exit to the docking bay (i.e. show the Status Mode
                        \ screen)

 STX CRGO               \ Otherwise we just scored ourselves a large cargo bay,
                        \ so update our current cargo capacity in CRGO to 37

.et2

 CMP #3                 \ If A is not 3 (i.e. the item we've just bought is not
 BNE et3                \ an E.C.M. system), skip to et3

 INY                    \ Increment Y to recursive token 108 ("E.C.M.SYSTEM")

 LDX ECM                \ If we already have an E.C.M. fitted (i.e. ECM is
 BNE pres               \ non-zero), jump to pres to show the error "E.C.M.
                        \ System Present", beep and exit to the docking bay
                        \ (i.e. show the Status Mode screen)

 DEC ECM                \ Otherwise we just took delivery of a brand new E.C.M.
                        \ system, so set ECM to &FF (as ECM was 0 before the DEC
                        \ instruction)

.et3

 CMP #4                 \ If A is not 4 (i.e. the item we've just bought is not
 BNE et4                \ an extra pulse laser), skip to et4

 JSR qv                 \ Print a menu listing the four views, with a "View ?"
                        \ prompt, and ask for a view number, which is returned
                        \ in X (which now contains 0-3)

 LDA #4                 \ This instruction doesn't appear to do anything, as we
                        \ either don't need it (if we already have this laser)
                        \ or we set A to 4 below (if we buy it)

 LDY LASER,X            \ If there is no laser mounted in the chosen view (i.e.
 BEQ ed4                \ LASER+X, which contains the laser power for view X, is
                        \ zero), jump to ed4 to buy a pulse laser

.ed7

 LDY #187               \ Otherwise we already have a laser mounted in this
 BNE pres               \ view, so jump to pres with Y set to token 27
                        \ (" LASER") to show the error "Laser Present", beep
                        \ and exit to the docking bay (i.e. show the Status
                        \ Mode screen)

.ed4

 LDA #POW               \ We just bought a pulse laser for view X, so we need
 STA LASER,X            \ to fit it by storing the laser power for a pulse laser
                        \ (given in POW) in LASER+X

 LDA #4                 \ Set A to 4 as we just overwrote the original value,
                        \ and we still need it set correctly so we can continue
                        \ through the conditional statements for all the other
                        \ equipment

.et4

 CMP #5                 \ If A is not 5 (i.e. the item we've just bought is not
 BNE et5                \ an extra beam laser), skip to et5

 JSR qv                 \ Print a menu listing the four views, with a "View ?"
                        \ prompt, and ask for a view number, which is returned
                        \ in X (which now contains 0-3)

 STX T1                 \ Store the view in T1 so we can retrieve it below

 LDA #5                 \ Set A to 5 as the call to qv will have overwritten
                        \ the original value, and we still need it set
                        \ correctly so we can continue through the conditional
                        \ statements for all the other equipment

 LDY LASER,X            \ If there is no laser mounted in the chosen view (i.e.
 BEQ ed5                \ LASER+X, which contains the laser power for view X,
                        \ is zero), jump to ed5 to buy a beam laser

\BPL P%+4               \ This instruction is commented out in the original
                        \ source, though it would have no effect (it would
                        \ simply skip the BMI if A is positive, which is what
                        \ BMI does anyway)

 BMI ed7                \ If there is a beam laser already mounted in the chosen
                        \ view (i.e. LASER+X has bit 7 set, which indicates a
                        \ beam laser rather than a pulse laser), skip back to
                        \ ed7 to print a "Laser Present" error, beep and exit
                        \ to the docking bay (i.e. show the Status Mode screen)

 LDA #4                 \ If we get here then we already have a pulse laser in
 JSR prx                \ the selected view, so we call prx to set (Y X) to the
                        \ price of equipment item number 4 (extra pulse laser)
                        \ so we can give a refund of the pulse laser

 JSR MCASH              \ Add (Y X) cash to the cash pot in CASH, so we refund
                        \ the price of the pulse laser we are exchanging for a
                        \ new beam laser

.ed5

 LDA #POW+128           \ We just bought a beam laser for view X, so we need
 LDX T1                 \ to fit it by storing the laser power for a beam laser
 STA LASER,X            \ (given in POW+128) in LASER+X, using the view number
                        \ we stored in T1 earlier, as the call to prx will have
                        \ overwritten the original value in X

.et5

 LDY #111               \ Set Y to recursive token 107 ("FUEL SCOOPS")

 CMP #6                 \ If A is not 6 (i.e. the item we've just bought is not
 BNE et6                \ a fuel scoop), skip to et6

 LDX BST                \ If we already have fuel scoops fitted (i.e. BST is
 BEQ ed9                \ zero), jump to ed9, otherwise fall through into pres
                        \ to show the error "Fuel Scoops Present", beep and
                        \ exit to the docking bay (i.e. show the Status Mode
                        \ screen)

.pres

                        \ If we get here we need to show an error to say that
                        \ the item whose name is in recursive token Y is already
                        \ present, and then process a refund for the cost of
                        \ item number A

 STY K                  \ Store the item's name in K

 JSR prx                \ Call prx to set (Y X) to the price of equipment item
                        \ number A

 JSR MCASH              \ Add (Y X) cash to the cash pot in CASH, as the station
                        \ already took the money for this item in the JSR eq
                        \ instruction above, but we can't fit the item, so need
                        \ our money back

 LDA K                  \ Print the recursive token in K (the item's name)
 JSR spc                \ followed by a space

 LDA #31                \ Print recursive token 145 ("PRESENT")
 JSR TT27

.err

 JSR dn2                \ Call dn2 to make a short, high beep and delay for 1
                        \ second

 JMP BAY                \ Jump to BAY to go to the docking bay (i.e. show the
                        \ Status Mode screen)

.ed9

 DEC BST                \ We just bought a shiny new fuel scoop, so set BST to
                        \ &FF (as BST was 0 before the jump to ed9 above)

.et6

 INY                    \ Increment Y to recursive token 112 ("E.C.M.SYSTEM")

 CMP #7                 \ If A is not 7 (i.e. the item we've just bought is not
 BNE et7                \ an escape pod), skip to et7

 LDX ESCP               \ If we already have an escape pod fitted (i.e. ESCP is
 BNE pres               \ non-zero), jump to pres to show the error "Escape Pod
                        \ Present", beep and exit to the docking bay (i.e. show
                        \ the Status Mode screen)

 DEC ESCP               \ Otherwise we just bought an escape pod, so set ESCP
                        \ to &FF (as ESCP was 0 before the DEC instruction)

.et7

 INY                    \ Increment Y to recursive token 113 ("ENERGY BOMB")

 CMP #8                 \ If A is not 8 (i.e. the item we've just bought is not
 BNE et8                \ an energy bomb), skip to et8

 LDX BOMB               \ If we already have an energy bomb fitted (i.e. BOMB
 BNE pres               \ is non-zero), jump to pres to show the error "Energy
                        \ Bomb Present", beep and exit to the docking bay (i.e.
                        \ show the Status Mode screen)

 LDX #&7F               \ Otherwise we just bought an energy bomb, so set BOMB
 STX BOMB               \ to &7F

.et8

 INY                    \ Increment Y to recursive token 114 ("ENERGY UNIT")

 CMP #9                 \ If A is not 9 (i.e. the item we've just bought is not
 BNE etA                \ an energy unit), skip to etA

 LDX ENGY               \ If we already have an energy unit fitted (i.e. ENGY is
 BNE pres               \ non-zero), jump to pres to show the error "Energy Unit
                        \ Present", beep and exit to the docking bay (i.e. show
                        \ the Status Mode screen)

 INC ENGY               \ Otherwise we just picked up an energy unit, so set
                        \ ENGY to 1 (as ENGY was 0 before the INC instruction)

.etA

 INY                    \ Increment Y to recursive token 115 ("DOCKING
                        \ COMPUTERS")

 CMP #10                \ If A is not 10 (i.e. the item we've just bought is not
 BNE etB                \ a docking computer), skip to etB

 LDX DKCMP              \ If we already have a docking computer fitted (i.e.
 BNE pres               \ DKCMP is non-zero), jump to pres to show the error
                        \ "Docking Computer Present", beep and exit to the
                        \ docking bay (i.e. show the Status Mode screen)

 DEC DKCMP              \ Otherwise we just got hold of a docking computer, so
                        \ set DKCMP to &FF (as DKCMP was 0 before the DEC
                        \ instruction)

.etB

 INY                    \ Increment Y to recursive token 116 ("GALACTIC
                        \ HYPERSPACE ")

 CMP #11                \ If A is not 11 (i.e. the item we've just bought is not
 BNE et9                \ a galactic hyperdrive), skip to et9

 LDX GHYP               \ If we already have a galactic hyperdrive fitted (i.e.
 BNE pres               \ GHYP is non-zero), jump to pres to show the error
                        \ "Galactic Hyperspace Present", beep and exit to the
                        \ docking bay (i.e. show the Status Mode screen)

 DEC GHYP               \ Otherwise we just splashed out on a galactic
                        \ hyperdrive, so set GHYP to &FF (as GHYP was 0 before
                        \ the DEC instruction)

.et9

 JSR dn                 \ We are done buying equipment, so print the amount of
                        \ cash left in the cash pot, then make a short, high
                        \ beep to confirm the purchase, and delay for 1 second

 JMP EQSHP              \ Jump back up to EQSHP to show the Equip Ship screen
                        \ again and see if we can't track down another bargain

\ ******************************************************************************
\
\       Name: dn
\       Type: Subroutine
\   Category: Text
\    Summary: Print the amount of cash and beep
\
\ ------------------------------------------------------------------------------
\
\ Print the amount of money in the cash pot, then make a short, high beep and
\ delay for 1 second.
\
\ ******************************************************************************

.dn

 JSR TT162              \ Print a space

 LDA #119               \ Print recursive token 119 ("CASH:{cash} CR{crlf}")
 JSR spc                \ followed by a space

                        \ Fall through into dn2 to make a beep and delay for
                        \ 1 second before returning from the subroutine

\ ******************************************************************************
\
\       Name: dn2
\       Type: Subroutine
\   Category: Text
\    Summary: Make a short, high beep and delay for 1 second
\
\ ******************************************************************************

.dn2

 JSR BEEP               \ Call the BEEP subroutine to make a short, high beep

 LDY #50                \ Delay for 50 vertical syncs (50/50 = 1 second) and
 JMP DELAY              \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: eq
\       Type: Subroutine
\   Category: Equipment
\    Summary: Subtract the price of equipment from the cash pot
\
\ ------------------------------------------------------------------------------
\
\ If we have enough cash, subtract the price of a specified piece of equipment
\ from our cash pot and return from the subroutine. If we don't have enough
\ cash, exit to the docking bay (i.e. show the Status Mode screen).
\
\ Arguments:
\
\   A                   The item number of the piece of equipment (0-11) as
\                       shown in the table at PRXS
\
\ ******************************************************************************

.eq

 JSR prx                \ Call prx to set (Y X) to the price of equipment item
                        \ number A

 JSR LCASH              \ Subtract (Y X) cash from the cash pot, but only if
                        \ we have enough cash

 BCS c                  \ If the C flag is set then we did have enough cash for
                        \ the transaction, so jump to c to return from the
                        \ subroutine (as c contains an RTS)

 LDA #197               \ Otherwise we don't have enough cash to buy this piece
 JSR prq                \ of equipment, so print recursive token 37 ("CASH")
                        \ followed by a question mark

 JMP err                \ Jump to err to beep, pause and go to the docking bay
                        \ (i.e. show the Status Mode screen)

\ ******************************************************************************
\
\       Name: prx
\       Type: Subroutine
\   Category: Equipment
\    Summary: Return the price of a piece of equipment
\
\ ------------------------------------------------------------------------------
\
\ This routine returns the price of equipment as listed in the table at PRXS.
\
\ Arguments:
\
\   A                   The item number of the piece of equipment (0-11) as
\                       shown in the table at PRXS
\
\ Returns:
\
\   (Y X)               The item price in Cr * 10 (Y = high byte, X = low byte)
\
\ Other entry points:
\
\   prx-3               Return the price of the item with number A - 1
\
\   c                   Contains an RTS
\
\ ******************************************************************************

 SEC                    \ Decrement A (for when this routine is called via
 SBC #1                 \ prx-3)

.prx

 ASL A                  \ Set Y = A * 2, so it can act as an index into the
 TAY                    \ PRXS table, which has two bytes per entry

 LDX PRXS,Y             \ Fetch the low byte of the price into X

 LDA PRXS+1,Y           \ Fetch the high byte of the price into A and transfer
 TAY                    \ it to X, so the price is now in (Y X)

.c

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: qv
\       Type: Subroutine
\   Category: Equipment
\    Summary: Print a menu of the four space views, for buying lasers
\
\ ------------------------------------------------------------------------------
\
\ Print a menu in the bottom-middle of the screen, at row 16, column 12, that
\ lists the four available space views, like this:
\
\                 0 Front
\                 1 Rear
\                 2 Left
\                 3 Right
\
\ Also print a "View ?" prompt and ask for a view number. The menu is shown
\ when we choose to buy a new laser in the Equip Ship screen.
\
\ Returns:
\
\   X                   The chosen view number (0-3)
\
\ ******************************************************************************

.qv

 LDY #16                \ Move the text cursor to row 16, and at the same time
 STY YC                 \ set Y to a counter going from 16 to 19 in the loop
                        \ below

.qv1

 LDX #12                \ Move the text cursor to column 12
 STX XC

 TYA                    \ Transfer the counter value from Y to A

 CLC                    \ Print ASCII character "0" - 16 + A, so as A goes from
 ADC #'0'-16            \ 16 to 19, this prints "0" through "3" followed by a
 JSR spc                \ space

 LDA YC                 \ Print recursive text token 80 + YC, so as YC goes from
 CLC                    \ 16 to 19, this prints "FRONT", "REAR", "LEFT" and
 ADC #80                \ "RIGHT"
 JSR TT27

 INC YC                 \ Move the text cursor down a row, and increment the
                        \ counter in YC at the same time

 LDY YC                 \ Update Y with the incremented counter in YC

 CPY #20                \ If Y < 20 then loop back up to qv1 to print the next
 BCC qv1                \ view in the menu

.qv3

 JSR CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows

.qv2

 LDA #175               \ Print recursive text token 15 ("VIEW ") followed by
 JSR prq                \ a question mark

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A (and X)

 SEC                    \ Subtract ASCII "0" from the key pressed, to leave the
 SBC #'0'               \ numeric value of the key in A (if it was a number key)

 CMP #4                 \ If the number entered in A >= 4, then it is not a
 BCS qv3                \ valid view number, so jump back to qv3 to try again

 TAX                    \ We have a valid view number, so transfer it to X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save ELTD.bin
\
\ ******************************************************************************

PRINT "ELITE D"
PRINT "Assembled at ", ~CODE_D%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_D%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_D%

PRINT "S.ELTD ", ~CODE_D%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_D%
SAVE "3-assembled-output/ELTD.bin", CODE_D%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE E FILE
\
\ Produces the binary file ELTE.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CODE_E% = P%
LOAD_E% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: Authors' names
\       Type: Variable
\   Category: Copy protection
\    Summary: The authors' names and a copyright notice, buried in the code
\
\ ------------------------------------------------------------------------------
\
\ This copyright notice is not used anywhere and it is obfuscated by EOR'ing
\ each character with 164, but presumably the authors wanted their names buried
\ in the code somewhere. Though they do also have recursive token 94, which
\ reads "BY D.BRABEN & I.BELL" and can be displayed on the title screen using
\ the "X" configuration option, so this isn't the only author name easter egg
\ in the game. It contains the following text:
\
\   (C)Bell/Braben1984
\
\ ******************************************************************************

 EQUB '(' EOR 164
 EQUB 'C' EOR 164
 EQUB ')' EOR 164
 EQUB 'B' EOR 164
 EQUB 'e' EOR 164
 EQUB 'l' EOR 164
 EQUB 'l' EOR 164
 EQUB '/' EOR 164
 EQUB 'B' EOR 164
 EQUB 'r' EOR 164
 EQUB 'a' EOR 164
 EQUB 'b' EOR 164
 EQUB 'e' EOR 164
 EQUB 'n' EOR 164
 EQUB '1' EOR 164
 EQUB '9' EOR 164
 EQUB '8' EOR 164
 EQUB '4' EOR 164

\ ******************************************************************************
\
\       Name: cpl
\       Type: Subroutine
\   Category: Text
\    Summary: Print the selected system name
\  Deep dive: Generating system names
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Print control code 3 (the selected system name, i.e. the one in the crosshairs
\ in the Short-range Chart).
\
\ ******************************************************************************

.cpl

 LDX #5                 \ First we need to backup the seeds in QQ15, so set up
                        \ a counter in X to cover three 16-bit seeds (i.e.
                        \ 6 bytes)

.TT53

 LDA QQ15,X             \ Copy byte X from QQ15 to QQ19
 STA QQ19,X

 DEX                    \ Decrement the loop counter

 BPL TT53               \ Loop back for the next byte to backup

 LDY #3                 \ Step 1: Now that the seeds are backed up, we can
                        \ start the name-generation process. We will either
                        \ need to loop three or four times, so for now set
                        \ up a counter in Y to loop four times

 BIT QQ15               \ Check bit 6 of s0_lo, which is stored in QQ15

 BVS P%+3               \ If bit 6 is set then skip over the next instruction

 DEY                    \ Bit 6 is clear, so we only want to loop three times,
                        \ so decrement the loop counter in Y

 STY T                  \ Store the loop counter in T

.TT55

 LDA QQ15+5             \ Step 2: Load s2_hi, which is stored in QQ15+5, and
 AND #%00011111         \ extract bits 0-4 by AND'ing with %11111

 BEQ P%+7               \ If all those bits are zero, then skip the following
                        \ two instructions to go to step 3

 ORA #%10000000         \ We now have a number in the range 1-31, which we can
                        \ easily convert into a two-letter token, but first we
                        \ need to add 128 (or set bit 7) to get a range of
                        \ 129-159

 JSR TT27               \ Print the two-letter token in A

 JSR TT54               \ Step 3: twist the seeds in QQ15

 DEC T                  \ Decrement the loop counter

 BPL TT55               \ Loop back for the next two letters

 LDX #5                 \ We have printed the system name, so we can now
                        \ restore the seeds we backed up earlier. Set up a
                        \ counter in X to cover three 16-bit seeds (i.e. 6
                        \ bytes)

.TT56

 LDA QQ19,X             \ Copy byte X from QQ19 to QQ15
 STA QQ15,X

 DEX                    \ Decrement the loop counter

 BPL TT56               \ Loop back for the next byte to restore

 RTS                    \ Once all the seeds are restored, return from the
                        \ subroutine

\ ******************************************************************************
\
\       Name: cmn
\       Type: Subroutine
\   Category: Text
\    Summary: Print the commander's name
\
\ ------------------------------------------------------------------------------
\
\ Print control code 4 (the commander's name).
\
\ Other entry points:
\
\   cmn-1               Contains an RTS
\
\ ******************************************************************************

.cmn

 LDY #0                 \ Set up a counter in Y, starting from 0

.QUL4

 LDA NA%,Y              \ The commander's name is stored at NA%, so load the
                        \ Y-th character from NA%

 CMP #13                \ If we have reached the end of the name, return from
 BEQ ypl-1              \ the subroutine (ypl-1 points to the RTS below)

 JSR TT26               \ Print the character we just loaded

 INY                    \ Increment the loop counter

 BNE QUL4               \ Loop back for the next character

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ypl
\       Type: Subroutine
\   Category: Text
\    Summary: Print the current system name
\
\ ------------------------------------------------------------------------------
\
\ Print control code 2 (the current system name).
\
\ Other entry points:
\
\   ypl-1               Contains an RTS
\
\ ******************************************************************************

.ypl

 LDA MJ                 \ Check the mis-jump flag at MJ, and if it is non-zero
 BNE cmn-1              \ then we are in witchspace, and witchspace doesn't have
                        \ a system name, so return from the subroutine (cmn-1
                        \ contains an RTS)

 JSR TT62               \ Call TT62 below to swap the three 16-bit seeds in
                        \ QQ2 and QQ15 (before the swap, QQ2 contains the seeds
                        \ for the current system, while QQ15 contains the seeds
                        \ for the selected system)

 JSR cpl                \ Call cpl to print out the system name for the seeds
                        \ in QQ15 (which now contains the seeds for the current
                        \ system)

                        \ Now we fall through into the TT62 subroutine, which
                        \ will swap QQ2 and QQ15 once again, so everything goes
                        \ back into the right place, and the RTS at the end of
                        \ TT62 will return from the subroutine

.TT62

 LDX #5                 \ Set up a counter in X for the three 16-bit seeds we
                        \ want to swap (i.e. 6 bytes)

.TT78

 LDA QQ15,X             \ Swap byte X between QQ2 and QQ15
 LDY QQ2,X
 STA QQ2,X
 STY QQ15,X

 DEX                    \ Decrement the loop counter

 BPL TT78               \ Loop back for the next byte to swap

 RTS                    \ Once all bytes are swapped, return from the
                        \ subroutine

\ ******************************************************************************
\
\       Name: tal
\       Type: Subroutine
\   Category: Text
\    Summary: Print the current galaxy number
\
\ ------------------------------------------------------------------------------
\
\ Print control code 1 (the current galaxy number, right-aligned to width 3).
\
\ ******************************************************************************

.tal

 CLC                    \ We don't want to print the galaxy number with a
                        \ decimal point, so clear the C flag for pr2 to take as
                        \ an argument

 LDX GCNT               \ Load the current galaxy number from GCNT into X

 INX                    \ Add 1 to the galaxy number, as the galaxy numbers
                        \ are 0-7 internally, but we want to display them as
                        \ galaxy 1 through 8

 JMP pr2                \ Jump to pr2, which prints the number in X to a width
                        \ of 3 figures, left-padding with spaces to a width of
                        \ 3, and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: fwl
\       Type: Subroutine
\   Category: Text
\    Summary: Print fuel and cash levels
\
\ ------------------------------------------------------------------------------
\
\ Print control code 5 ("FUEL: ", fuel level, " LIGHT YEARS", newline, "CASH:",
\ control code 0).
\
\ ******************************************************************************

.fwl

 LDA #105               \ Print recursive token 105 ("FUEL") followed by a
 JSR TT68               \ colon

 LDX QQ14               \ Load the current fuel level from QQ14

 SEC                    \ We want to print the fuel level with a decimal point,
                        \ so set the C flag for pr2 to take as an argument

 JSR pr2                \ Call pr2, which prints the number in X to a width of
                        \ 3 figures (i.e. in the format x.x, which will always
                        \ be exactly 3 characters as the maximum fuel is 7.0)

 LDA #195               \ Print recursive token 35 ("LIGHT YEARS") followed by
 JSR plf                \ a newline

.PCASH

 LDA #119               \ Print recursive token 119 ("CASH:" then control code
 BNE TT27               \ 0, which prints cash levels, then " CR" and newline)

\ ******************************************************************************
\
\       Name: csh
\       Type: Subroutine
\   Category: Text
\    Summary: Print the current amount of cash
\
\ ------------------------------------------------------------------------------
\
\ Print control code 0 (the current amount of cash, right-aligned to width 9,
\ followed by " CR" and a newline).
\
\ ******************************************************************************

.csh

 LDX #3                 \ We are going to use the BPRNT routine to print out
                        \ the current amount of cash, which is stored as a
                        \ 32-bit number at location CASH. BPRNT prints out
                        \ the 32-bit number stored in K, so before we call
                        \ BPRNT, we need to copy the four bytes from CASH into
                        \ K, so first we set up a counter in X for the 4 bytes

.pc1

 LDA CASH,X             \ Copy byte X from CASH to K
 STA K,X

 DEX                    \ Decrement the loop counter

 BPL pc1                \ Loop back for the next byte to copy

 LDA #9                 \ We want to print the cash amount using up to 9 digits
 STA U                  \ (including the decimal point), so store this in U
                        \ for BRPNT to take as an argument

 SEC                    \ We want to print the cash amount with a decimal point,
                        \ so set the C flag for BRPNT to take as an argument

 JSR BPRNT              \ Print the amount of cash to 9 digits with a decimal
                        \ point

 LDA #226               \ Print recursive token 66 (" CR") followed by a
                        \ newline by falling through into plf

\ ******************************************************************************
\
\       Name: plf
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a newline
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.plf

 JSR TT27               \ Print the text token in A

 JMP TT67               \ Jump to TT67 to print a newline and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT68
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a colon
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.TT68

 JSR TT27               \ Print the text token in A and fall through into TT73
                        \ to print a colon

\ ******************************************************************************
\
\       Name: TT73
\       Type: Subroutine
\   Category: Text
\    Summary: Print a colon
\
\ ******************************************************************************

.TT73

 LDA #':'               \ Set A to ASCII ":" and fall through into TT27 to
                        \ actually print the colon

\ ******************************************************************************
\
\       Name: TT27
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). See variable QQ18 for a discussion of the token system
\ used in Elite.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.TT27

 TAX                    \ Copy the token number from A to X. We can then keep
                        \ decrementing X and testing it against zero, while
                        \ keeping the original token number intact in A; this
                        \ effectively implements a switch statement on the
                        \ value of the token

 BEQ csh                \ If token = 0, this is control code 0 (current amount
                        \ of cash and newline), so jump to csh

 BMI TT43               \ If token > 127, this is either a two-letter token
                        \ (128-159) or a recursive token (160-255), so jump
                        \ to TT43 to process tokens

 DEX                    \ If token = 1, this is control code 1 (current galaxy
 BEQ tal                \ number), so jump to tal

 DEX                    \ If token = 2, this is control code 2 (current system
 BEQ ypl                \ name), so jump to ypl

 DEX                    \ If token > 3, skip the following instruction
 BNE P%+5

 JMP cpl                \ This token is control code 3 (selected system name)
                        \ so jump to cpl

 DEX                    \ If token = 4, this is control code 4 (commander
 BEQ cmn                \ name), so jump to cmm

 DEX                    \ If token = 5, this is control code 5 (fuel, newline,
 BEQ fwl                \ cash, newline), so jump to fwl

 DEX                    \ If token > 6, skip the following three instructions
 BNE P%+7

 LDA #%10000000         \ This token is control code 6 (switch to Sentence
 STA QQ17               \ Case), so set bit 7 of QQ17 to switch to Sentence Case
 RTS                    \ and return from the subroutine as we are done

 DEX                    \ If token > 8, skip the following two instructions
 DEX
 BNE P%+5

 STX QQ17               \ This token is control code 8 (switch to ALL CAPS), so
 RTS                    \ set QQ17 to 0 to switch to ALL CAPS and return from
                        \ the subroutine as we are done

 DEX                    \ If token = 9, this is control code 9 (tab to column
 BEQ crlf               \ 21 and print a colon), so jump to crlf

 CMP #96                \ By this point, token is either 7, or in 10-127.
 BCS ex                 \ Check token number in A and if token >= 96, then the
                        \ token is in 96-127, which is a recursive token, so
                        \ jump to ex, which prints recursive tokens in this
                        \ range (i.e. where the recursive token number is
                        \ correct and doesn't need correcting)

 CMP #14                \ If token < 14, skip the following two instructions
 BCC P%+6

 CMP #32                \ If token < 32, then this means token is in 14-31, so
 BCC qw                 \ this is a recursive token that needs 114 adding to it
                        \ to get the recursive token number, so jump to qw
                        \ which will do this

                        \ By this point, token is either 7 (beep) or in 10-13
                        \ (line feeds and carriage returns), or in 32-95
                        \ (ASCII letters, numbers and punctuation)

 LDX QQ17               \ Fetch QQ17, which controls letter case, into X

 BEQ TT74               \ If QQ17 = 0, then ALL CAPS is set, so jump to TT27
                        \ to print this character as is (i.e. as a capital)

 BMI TT41               \ If QQ17 has bit 7 set, then we are using Sentence
                        \ Case, so jump to TT41, which will print the
                        \ character in upper or lower case, depending on
                        \ whether this is the first letter in a word

 BIT QQ17               \ If we get here, QQ17 is not 0 and bit 7 is clear, so
 BVS TT46               \ either it is bit 6 that is set, or some other flag in
                        \ QQ17 is set (bits 0-5). So check whether bit 6 is set.
                        \ If it is, then ALL CAPS has been set (as bit 7 is
                        \ clear) but bit 6 is still indicating that the next
                        \ character should be printed in lower case, so we need
                        \ to fix this. We do this with a jump to TT46, which
                        \ will print this character in upper case and clear bit
                        \ 6, so the flags are consistent with ALL CAPS going
                        \ forward

                        \ If we get here, some other flag is set in QQ17 (one
                        \ of bits 0-5 is set), which shouldn't happen in this
                        \ version of Elite. If this were the case, then we
                        \ would fall through into TT42 to print in lower case,
                        \ which is how printing all words in lower case could
                        \ be supported (by setting QQ17 to 1, say)

\ ******************************************************************************
\
\       Name: TT42
\       Type: Subroutine
\   Category: Text
\    Summary: Print a letter in lower case
\
\ ------------------------------------------------------------------------------
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
\ Other entry points:
\
\   TT44                Jumps to TT26 to print the character in A (used to
\                       enable us to use a branch instruction to jump to TT26)
\
\ ******************************************************************************

.TT42

 CMP #'A'               \ If A < ASCII "A", then this is punctuation, so jump
 BCC TT44               \ to TT26 (via TT44) to print the character as is, as
                        \ we don't care about the character's case

 CMP #'Z'+1             \ If A >= (ASCII "Z" + 1), then this is also
 BCS TT44               \ punctuation, so jump to TT26 (via TT44) to print the
                        \ character as is, as we don't care about the
                        \ character's case

 ADC #32                \ Add 32 to the character, to convert it from upper to
                        \ to lower case

.TT44

 JMP TT26               \ Print the character in A

\ ******************************************************************************
\
\       Name: TT41
\       Type: Subroutine
\   Category: Text
\    Summary: Print a letter according to Sentence Case
\
\ ------------------------------------------------------------------------------
\
\ The rules for printing in Sentence Case are as follows:
\
\   * If QQ17 bit 6 is set, print lower case (via TT45)
\
\   * If QQ17 bit 6 clear, then:
\
\       * If character is punctuation, just print it
\
\       * If character is a letter, set QQ17 bit 6 and print letter as a capital
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
\   X                   Contains the current value of QQ17
\
\   QQ17                Bit 7 is set
\
\ ******************************************************************************

.TT41

                        \ If we get here, then QQ17 has bit 7 set, so we are in
                        \ Sentence Case

 BIT QQ17               \ If QQ17 also has bit 6 set, jump to TT45 to print
 BVS TT45               \ this character in lower case

                        \ If we get here, then QQ17 has bit 6 clear and bit 7
                        \ set, so we are in Sentence Case and we need to print
                        \ the next letter in upper case

 CMP #'A'               \ If A < ASCII "A", then this is punctuation, so jump
 BCC TT74               \ to TT26 (via TT44) to print the character as is, as
                        \ we don't care about the character's case

 PHA                    \ Otherwise this is a letter, so store the token number

 TXA                    \ Set bit 6 in QQ17 (X contains the current QQ17)
 ORA #%1000000          \ so the next letter after this one is printed in lower
 STA QQ17               \ case

 PLA                    \ Restore the token number into A

 BNE TT44               \ Jump to TT26 (via TT44) to print the character in A
                        \ (this BNE is effectively a JMP as A will never be
                        \ zero)

\ ******************************************************************************
\
\       Name: qw
\       Type: Subroutine
\   Category: Text
\    Summary: Print a recursive token in the range 128-145
\
\ ------------------------------------------------------------------------------
\
\ Print a recursive token where the token number is in 128-145 (so the value
\ passed to TT27 is in the range 14-31).
\
\ Arguments:
\
\   A                   A value from 128-145, which refers to a recursive token
\                       in the range 14-31
\
\ ******************************************************************************

.qw

 ADC #114               \ This is a recursive token in the range 0-95, so add
 BNE ex                 \ 114 to the argument to get the token number 128-145
                        \ and jump to ex to print it

\ ******************************************************************************
\
\       Name: crlf
\       Type: Subroutine
\   Category: Text
\    Summary: Tab to column 21 and print a colon
\
\ ------------------------------------------------------------------------------
\
\ Print control code 9 (tab to column 21 and print a colon). The subroutine
\ name is pretty misleading, as it doesn't have anything to do with carriage
\ returns or line feeds.
\
\ ******************************************************************************

.crlf

 LDA #21                \ Set the X-column in XC to 21
 STA XC

 BNE TT73               \ Jump to TT73, which prints a colon (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: TT45
\       Type: Subroutine
\   Category: Text
\    Summary: Print a letter in lower case
\
\ ------------------------------------------------------------------------------
\
\ This routine prints a letter in lower case. Specifically:
\
\   * If QQ17 = 255, abort printing this character as printing is disabled
\
\   * If this is a letter then print in lower case
\
\   * Otherwise this is punctuation, so clear bit 6 in QQ17 and print
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
\   X                   Contains the current value of QQ17
\
\   QQ17                Bits 6 and 7 are set
\
\ ******************************************************************************

.TT45

                        \ If we get here, then QQ17 has bit 6 and 7 set, so we
                        \ are in Sentence Case and we need to print the next
                        \ letter in lower case

 CPX #255               \ If QQ17 = 255 then printing is disabled, so return
 BEQ TT48               \ from the subroutine (as TT48 contains an RTS)

 CMP #'A'               \ If A >= ASCII "A", then jump to TT42, which will
 BCS TT42               \ print the letter in lowercase

                        \ Otherwise this is not a letter, it's punctuation, so
                        \ this is effectively a word break. We therefore fall
                        \ through to TT46 to print the character and set QQ17
                        \ to ensure the next word starts with a capital letter

\ ******************************************************************************
\
\       Name: TT46
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character and switch to capitals
\
\ ------------------------------------------------------------------------------
\
\ Print a character and clear bit 6 in QQ17, so that the next letter that gets
\ printed after this will start with a capital letter.
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
\   X                   Contains the current value of QQ17
\
\   QQ17                Bits 6 and 7 are set
\
\ ******************************************************************************

.TT46

 PHA                    \ Store the token number

 TXA                    \ Clear bit 6 in QQ17 (X contains the current QQ17) so
 AND #%10111111         \ the next letter after this one is printed in upper
 STA QQ17               \ case

 PLA                    \ Restore the token number into A

                        \ Now fall through into TT74 to print the character

\ ******************************************************************************
\
\       Name: TT74
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to be printed
\
\ ******************************************************************************

.TT74

 JMP TT26               \ Print the character in A

\ ******************************************************************************
\
\       Name: TT43
\       Type: Subroutine
\   Category: Text
\    Summary: Print a two-letter token or recursive token 0-95
\
\ ------------------------------------------------------------------------------
\
\ Print a two-letter token, or a recursive token where the token number is in
\ 0-95 (so the value passed to TT27 is in the range 160-255).
\
\ Arguments:
\
\   A                   One of the following:
\
\                         * 128-159 (two-letter token)
\
\                         * 160-255 (the argument to TT27 that refers to a
\                           recursive token in the range 0-95)
\
\ ******************************************************************************

.TT43

 CMP #160               \ If token >= 160, then this is a recursive token, so
 BCS TT47               \ jump to TT47 below to process it

 AND #127               \ This is a two-letter token with number 128-159. The
 ASL A                  \ set of two-letter tokens is stored in a lookup table
                        \ at QQ16, with each token taking up two bytes, so to
                        \ convert this into the token's position in the table,
                        \ we subtract 128 (or just clear bit 7) and multiply
                        \ by 2 (or shift left)

 TAY                    \ Transfer the token's position into Y so we can look
                        \ up the token using absolute indexed mode

 LDA QQ16,Y             \ Get the first letter of the token and print it
 JSR TT27

 LDA QQ16+1,Y           \ Get the second letter of the token

 CMP #'?'               \ If the second letter of the token is a question mark
 BEQ TT48               \ then this is a one-letter token, so just return from
                        \ the subroutine without printing (as TT48 contains an
                        \ RTS)

 JMP TT27               \ Print the second letter and return from the
                        \ subroutine

.TT47

 SBC #160               \ This is a recursive token in the range 160-255, so
                        \ subtract 160 from the argument to get the token
                        \ number 0-95 and fall through into ex to print it

\ ******************************************************************************
\
\       Name: ex
\       Type: Subroutine
\   Category: Text
\    Summary: Print a recursive token
\
\ ------------------------------------------------------------------------------
\
\ This routine works its way through the recursive tokens that are stored in
\ tokenised form in memory at &0400 to &06FF, and when it finds token number A,
\ it prints it. Tokens are null-terminated in memory and fill three pages,
\ but there is no lookup table as that would consume too much memory, so the
\ only way to find the correct token is to start at the beginning and look
\ through the table byte by byte, counting tokens as we go until we are in the
\ right place. This approach might not be terribly speed efficient, but it is
\ certainly memory-efficient.
\
\ For details of the tokenisation system, see variable QQ18.
\
\ Arguments:
\
\   A                   The recursive token to be printed, in the range 0-148
\
\ Other entry points:
\
\   TT48                Contains an RTS
\
\ ******************************************************************************

.ex

 TAX                    \ Copy the token number into X

 LDA #LO(QQ18)          \ Set V(1 0) to point to the recursive token table at
 STA V                  \ location QQ18
 LDA #HI(QQ18)
 STA V+1

 LDY #0                 \ Set a counter Y to point to the character offset
                        \ as we scan through the table

 TXA                    \ Copy the token number back into A, so both A and X
                        \ now contain the token number we want to print

 BEQ TT50               \ If the token number we want is 0, then we have
                        \ already found the token we are looking for, so jump
                        \ to TT50, otherwise start working our way through the
                        \ null-terminated token table until we find the X-th
                        \ token

.TT51

 LDA (V),Y              \ Fetch the Y-th character from the token table page
                        \ we are currently scanning

 BEQ TT49               \ If the character is null, we've reached the end of
                        \ this token, so jump to TT49

 INY                    \ Increment character pointer and loop back round for
 BNE TT51               \ the next character in this token, assuming Y hasn't
                        \ yet wrapped around to 0

 INC V+1                \ If it has wrapped round to 0, we have just crossed
 BNE TT51               \ into a new page, so increment V+1 so that V points
                        \ to the start of the new page

.TT49

 INY                    \ Increment the character pointer

 BNE TT59               \ If Y hasn't just wrapped around to 0, skip the next
                        \ instruction

 INC V+1                \ We have just crossed into a new page, so increment
                        \ V+1 so that V points to the start of the new page

.TT59

 DEX                    \ We have just reached a new token, so decrement the
                        \ token number we are looking for

 BNE TT51               \ Assuming we haven't yet reached the token number in
                        \ X, look back up to keep fetching characters

.TT50

                        \ We have now reached the correct token in the token
                        \ table, with Y pointing to the start of the token as
                        \ an offset within the page pointed to by V, so let's
                        \ print the recursive token. Because recursive tokens
                        \ can contain other recursive tokens, we need to store
                        \ our current state on the stack, so we can retrieve
                        \ it after printing each character in this token

 TYA                    \ Store the offset in Y on the stack
 PHA

 LDA V+1                \ Store the high byte of V (the page containing the
 PHA                    \ token we have found) on the stack, so the stack now
                        \ contains the address of the start of this token

 LDA (V),Y              \ Load the character at offset Y in the token table,
                        \ which is the next character of this token that we
                        \ want to print

 EOR #35                \ Tokens are stored in memory having been EOR'd with 35
                        \ (see variable QQ18 for details), so we repeat the
                        \ EOR to get the actual character to print

 JSR TT27               \ Print the text token in A, which could be a letter,
                        \ number, control code, two-letter token or another
                        \ recursive token

 PLA                    \ Restore the high byte of V (the page containing the
 STA V+1                \ token we have found) into V+1

 PLA                    \ Restore the offset into Y
 TAY

 INY                    \ Increment Y to point to the next character in the
                        \ token we are printing

 BNE P%+4               \ If Y is zero then we have just crossed into a new
 INC V+1                \ page, so increment V+1 so that V points to the start
                        \ of the new page

 LDA (V),Y              \ Load the next character we want to print into A

 BNE TT50               \ If this is not the null character at the end of the
                        \ token, jump back up to TT50 to print the next
                        \ character, otherwise we are done printing

.TT48

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DOEXP
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw an exploding ship
\  Deep dive: Drawing explosion clouds
\             Generating random numbers
\
\ ******************************************************************************

.EX2

 LDA INWK+31            \ Set bits 5 and 7 of the ship's byte #31 to denote that
 ORA #%10100000         \ the ship is exploding and has been killed
 STA INWK+31

 RTS                    \ Return from the subroutine

.DOEXP

 LDA INWK+31            \ If bit 6 of the ship's byte #31 is clear, then the
 AND #%01000000         \ ship is not already exploding so there is no existing
 BEQ P%+5               \ explosion cloud to remove, so skip the following
                        \ instruction

 JSR PTCLS              \ Call PTCLS to remove the existing cloud by drawing it
                        \ again

 LDA INWK+6             \ Set T = z_lo
 STA T

 LDA INWK+7             \ Set A = z_hi, so (A T) = z

 CMP #32                \ If z_hi < 32, skip the next two instructions
 BCC P%+6

 LDA #&FE               \ Set A = 254 and jump to yy (this BNE is effectively a
 BNE yy                 \ JMP, as A is never zero)

 ASL T                  \ Shift (A T) left twice
 ROL A
 ASL T
 ROL A

 SEC                    \ And then shift A left once more, inserting a 1 into
 ROL A                  \ bit 0

                        \ Overall, the above multiplies A by 8 and makes sure it
                        \ is at least 1, to leave a one-byte distance in A. We
                        \ can use this as the distance for our cloud, to ensure
                        \ that the explosion cloud is visible even for ships
                        \ that blow up a long way away

.yy

 STA Q                  \ Store the distance to the explosion in Q

 LDY #1                 \ Fetch byte #1 of the ship line heap, which contains
 LDA (XX19),Y           \ the cloud counter

 ADC #4                 \ Add 4 to the cloud counter, so it ticks onwards every
                        \ we redraw it

 BCS EX2                \ If the addition overflowed, jump up to EX2 to update
                        \ the explosion flags and return from the subroutine

 STA (XX19),Y           \ Store the updated cloud counter in byte #1 of the ship
                        \ line heap

 JSR DVID4              \ Calculate the following:
                        \
                        \   (P R) = 256 * A / Q
                        \         = 256 * cloud counter / distance
                        \
                        \ We are going to use this as our cloud size, so the
                        \ further away the cloud, the smaller it is, and as the
                        \ cloud counter ticks onward, the cloud expands

 LDA P                  \ Set A = P, so we now have:
                        \
                        \   (A R) = 256 * cloud counter / distance

 CMP #&1C               \ If A < 28, skip the next two instructions
 BCC P%+6

 LDA #&FE               \ Set A = 254 and skip the following (this BNE is
 BNE LABEL_1            \ effectively a JMP as A is never zero)

 ASL R                  \ Shift (A R) left three times to multiply by 8
 ROL A
 ASL R
 ROL A
 ASL R
 ROL A

                        \ Overall, the above multiplies (A R) by 8 to leave a
                        \ one-byte cloud size in A, given by the following:
                        \
                        \   A = 8 * cloud counter / distance

.LABEL_1

 DEY                    \ Decrement Y to 0

 STA (XX19),Y           \ Store the cloud size in byte #0 of the ship line heap

 LDA INWK+31            \ Clear bit 6 of the ship's byte #31 to denote that the
 AND #%10111111         \ explosion has not yet been drawn
 STA INWK+31

 AND #%00001000         \ If bit 3 of the ship's byte #31 is clear, then nothing
 BEQ TT48               \ is being drawn on-screen for this ship anyway, so
                        \ return from the subroutine (as TT48 contains an RTS)

 LDY #2                 \ Otherwise it's time to draw an explosion cloud, so
 LDA (XX19),Y           \ fetch byte #2 of the ship line heap into Y, which we
 TAY                    \ set to the explosion count for this ship (i.e. the
                        \ number of vertices used as origins for explosion
                        \ clouds)
                        \
                        \ The explosion count is stored as 4 * n + 6, where n is
                        \ the number of vertices, so the following loop copies
                        \ the coordinates of the first n vertices from the heap
                        \ at XX3, which is where we stored all the visible
                        \ vertex coordinates in part 8 of the LL9 routine, and
                        \ sticks them in the ship line heap pointed to by XX19,
                        \ starting at byte #7 (so it leaves the first 6 bytes of
                        \ the ship line heap alone)

.EXL1

 LDA XX3-7,Y            \ Copy byte Y-7 from the XX3 heap, into the Y-th byte of
 STA (XX19),Y           \ the ship line heap

 DEY                    \ Decrement the loop counter

 CPY #6                 \ Keep copying vertex coordinates into the ship line
 BNE EXL1               \ heap until Y = 6 (which will copy n vertices, where n
                        \ is the number of vertices we should be exploding)

 LDA INWK+31            \ Set bit 6 of the ship's byte #31 to denote that the
 ORA #%01000000         \ explosion has been drawn (as it's about to be)
 STA INWK+31

.PTCLS

                        \ This part of the routine actually draws the explosion
                        \ cloud

 LDY #0                 \ Fetch byte #0 of the ship line heap, which contains
 LDA (XX19),Y           \ the cloud size we stored above, and store it in Q
 STA Q

 INY                    \ Increment the index in Y to point to byte #1

 LDA (XX19),Y           \ Fetch byte #1 of the ship line heap, which contains
                        \ the cloud counter. We are now going to process this
                        \ into the number of particles in each vertex's cloud

 BPL P%+4               \ If the cloud counter < 128, then we are in the first
                        \ half of the cloud's existence, so skip the next
                        \ instruction

 EOR #&FF               \ Flip the value of A so that in the second half of the
                        \ cloud's existence, A counts down instead of up

 LSR A                  \ Divide A by 8 so that is has a maximum value of 15
 LSR A
 LSR A

 ORA #1                 \ Make sure A is at least 1 and store it in U, to
 STA U                  \ give us the number of particles in the explosion for
                        \ each vertex

 INY                    \ Increment the index in Y to point to byte #2

 LDA (XX19),Y           \ Fetch byte #2 of the ship line heap, which contains
 STA TGT                \ the explosion count for this ship (i.e. the number of
                        \ vertices used as origins for explosion clouds) and
                        \ store it in TGT

 LDA RAND+1             \ Fetch the current random number seed in RAND+1 and
 PHA                    \ store it on the stack, so we can re-randomise the
                        \ seeds when we are done

 LDY #6                 \ Set Y = 6 to point to the byte before the first vertex
                        \ coordinate we stored on the ship line heap above (we
                        \ increment it below so it points to the first vertex)

.EXL5

 LDX #3                 \ We are about to fetch a pair of coordinates from the
                        \ ship line heap, so set a counter in X for 4 bytes

.EXL3

 INY                    \ Increment the index in Y so it points to the next byte
                        \ from the coordinate we are copying

 LDA (XX19),Y           \ Copy the Y-th byte from the ship line heap to the X-th
 STA K3,X               \ byte of K3

 DEX                    \ Decrement the X index

 BPL EXL3               \ Loop back to EXL3 until we have copied all four bytes

                        \ The above loop copies the vertex coordinates from the
                        \ ship line heap to K3, reversing them as we go, so it
                        \ sets the following:
                        \
                        \   K3+3 = x_lo
                        \   K3+2 = x_hi
                        \   K3+1 = y_lo
                        \   K3+0 = y_hi

 STY CNT                \ Set CNT to the index that points to the next vertex on
                        \ the ship line heap

 LDY #2                 \ Set Y = 2, which we will use to point to bytes #3 to
                        \ #6, after incrementing it

                        \ This next loop copies bytes #3 to #6 from the ship
                        \ line heap into the four random number seeds in RAND to
                        \ RAND+3, EOR'ing them with the vertex index so they are
                        \ different for every vertex. This enables us to
                        \ generate random numbers for drawing each vertex that
                        \ are random but repeatable, which we need when we
                        \ redraw the cloud to remove it
                        \
                        \ Note that we haven't actually set the values of bytes
                        \ #3 to #6 in the ship line heap, so we have no idea
                        \ what they are, we just use what's already there. But
                        \ the fact that those bytes are stored for this ship
                        \ means we can repeat the random generation of the
                        \ cloud, which is the important bit

.EXL2

 INY                    \ Increment the index in Y so it points to the next
                        \ random number seed to copy

 LDA (XX19),Y           \ Fetch the Y-th byte from the ship line heap

 EOR CNT                \ EOR with the vertex index, so the seeds are different
                        \ for each vertex

 STA &FFFD,Y            \ Y is going from 3 to 6, so this stores the four bytes
                        \ in memory locations &00, &01, &02 and &03, which are
                        \ the memory locations of RAND through RAND+3

 CPY #6                 \ Loop back to EXL2 until Y = 6, which means we have
 BNE EXL2               \ copied four bytes

 LDY U                  \ Set Y to the number of particles in the explosion for
                        \ each vertex, which we stored in U above. We will now
                        \ use this as a loop counter to iterate through all the
                        \ particles in the explosion

.EXL4

 JSR DORND2             \ Set ZZ to a random number, making sure the C flag
 STA ZZ                 \ doesn't affect the outcome

 LDA K3+1               \ Set (A R) = (y_hi y_lo)
 STA R                  \           = y
 LDA K3

 JSR EXS1               \ Set (A X) = (A R) +/- random * cloud size
                        \           = y +/- random * cloud size

 BNE EX11               \ If A is non-zero, the particle is off-screen as the
                        \ coordinate is bigger than 255), so jump to EX11 to do
                        \ the next particle

 CPX #2*Y-1             \ If X > the y-coordinate of the bottom of the screen,
 BCS EX11               \ the particle is off the bottom of the screen, so jump
                        \ to EX11 to do the next particle

                        \ Otherwise X contains a random y-coordinate within the
                        \ cloud

 STX Y1                 \ Set Y1 = our random y-coordinate within the cloud

 LDA K3+3               \ Set (A R) = (x_hi x_lo)
 STA R
 LDA K3+2

 JSR EXS1               \ Set (A X) = (A R) +/- random * cloud size
                        \           = x +/- random * cloud size

 BNE EX4                \ If A is non-zero, the particle is off-screen as the
                        \ coordinate is bigger than 255), so jump to EX11 to do
                        \ the next particle

                        \ Otherwise X contains a random x-coordinate within the
                        \ cloud

 LDA Y1                 \ Set A = our random y-coordinate within the cloud

 JSR PIXEL              \ Draw a point at screen coordinate (X, A) with the
                        \ point size determined by the distance in ZZ

.EX4

 DEY                    \ Decrement the loop counter for the next particle

 BPL EXL4               \ Loop back to EXL4 until we have done all the particles
                        \ in the cloud

 LDY CNT                \ Set Y to the index that points to the next vertex on
                        \ the ship line heap

 CPY TGT                \ If Y < TGT, which we set to the explosion count for
 BCC EXL5               \ this ship (i.e. the number of vertices used as origins
                        \ for explosion clouds), loop back to EXL5 to do a cloud
                        \ for the next vertex

 PLA                    \ Restore the current random number seed to RAND+1 that
 STA RAND+1             \ we stored at the start of the routine

 LDA K%+6               \ Store the z_lo coordinate for the planet (which will
 STA RAND+3             \ be pretty random) in the RAND+3 seed

 RTS                    \ Return from the subroutine

.EX11

 JSR DORND2             \ Set A and X to random numbers, making sure the C flag
                        \ doesn't affect the outcome

 JMP EX4                \ We just skipped a particle, so jump up to EX4 to do
                        \ the next one

.EXS1

                        \ This routine calculates the following:
                        \
                        \   (A X) = (A R) +/- random * cloud size
                        \
                        \ returning with the flags set for the high byte in A

 STA S                  \ Store A in S so we can use it later

 JSR DORND2             \ Set A and X to random numbers, making sure the C flag
                        \ doesn't affect the outcome

 ROL A                  \ Set A = A * 2

 BCS EX5                \ If bit 7 of A was set (50% chance), jump to EX5

 JSR FMLTU              \ Set A = A * Q / 256
                        \       = random << 1 * projected cloud size / 256

 ADC R                  \ Set (A X) = (S R) + A
 TAX                    \           = (S R) + random * projected cloud size
                        \
                        \ where S contains the argument A, starting with the low
                        \ bytes

 LDA S                  \ And then the high bytes
 ADC #0

 RTS                    \ Return from the subroutine

.EX5

 JSR FMLTU              \ Set T = A * Q / 256
 STA T                  \       = random << 1 * projected cloud size / 256

 LDA R                  \ Set (A X) = (S R) - T
 SBC T                  \
 TAX                    \ where S contains the argument A, starting with the low
                        \ bytes

 LDA S                  \ And then the high bytes
 SBC #0

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SOS1
\       Type: Subroutine
\   Category: Universe
\    Summary: Update the missile indicators, set up the planet data block
\
\ ------------------------------------------------------------------------------
\
\ Update the missile indicators, and set up a data block for the planet, but
\ only setting the pitch and roll counters to 127 (no damping).
\
\ ******************************************************************************

.SOS1

 JSR msblob             \ Reset the dashboard's missile indicators so none of
                        \ them are targeted

 LDA #127               \ Set the pitch and roll counters to 127 (no damping
 STA INWK+29            \ so the planet's rotation doesn't slow down)
 STA INWK+30

 LDA tek                \ Set A = 128 or 130 depending on bit 1 of the system's
 AND #%00000010         \ tech level in tek
 ORA #%10000000

 JMP NWSHP              \ Add a new planet to our local bubble of universe,
                        \ with the planet type defined by A (128 is a planet
                        \ with an equator and meridian, 130 is a planet with
                        \ a crater)

\ ******************************************************************************
\
\       Name: SOLAR
\       Type: Subroutine
\   Category: Universe
\    Summary: Set up various aspects of arriving in a new system
\
\ ------------------------------------------------------------------------------
\
\ Halve our legal status, update the missile indicators, and set up data blocks
\ and slots for the planet and sun.
\
\ ******************************************************************************

.SOLAR

 LSR FIST               \ Halve our legal status in FIST, making us less bad,
                        \ and moving bit 0 into the C flag (so every time we
                        \ arrive in a new system, our legal status improves a
                        \ bit)

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace, which
                        \ doesn't affect the C flag

 LDA QQ15+1             \ Fetch s0_hi

 AND #%00000111         \ Extract bits 0-2 (which also happen to determine the
                        \ economy), which will be between 0 and 7

 ADC #6                 \ Add 6 + C, and divide by 2, to get a result between 3
 LSR A                  \ and 7, at the same time shifting bit 0 of the result
                        \ of the addition into the C flag

 STA INWK+8             \ Store the result in z_sign in byte #6

 ROR A                  \ Halve A, rotating in the C flag, which was previously
 STA INWK+2             \ bit 0 of s0_hi + 6 + C, so when this is stored in both
 STA INWK+5             \ x_sign and y_sign, it moves the planet to the upper
                        \ right or lower left

 JSR SOS1               \ Call SOS1 to set up the planet's data block and add it
                        \ to FRIN, where it will get put in the first slot as
                        \ it's the first one to be added to our local bubble of
                        \ this new system's universe

 LDA QQ15+3             \ Fetch s1_hi, extract bits 0-2, set bits 0 and 7 and
 AND #%00000111         \ store in z_sign, so the sun is behind us at a distance
 ORA #%10000001         \ of 1 to 7
 STA INWK+8

 LDA QQ15+5             \ Fetch s2_hi, extract bits 0-1 and store in x_sign and
 AND #%00000011         \ y_sign, so the sun is either dead in our rear laser
 STA INWK+2             \ crosshairs, or off to the top left by a distance of 1
 STA INWK+1             \ or 2 when we look out the back

 LDA #0                 \ Set the pitch and roll counters to 0 (no rotation)
 STA INWK+29
 STA INWK+30

 LDA #129               \ Set A = 129, the ship type for the sun

 JSR NWSHP              \ Call NWSHP to set up the sun's data block and add it
                        \ to FRIN, where it will get put in the second slot as
                        \ it's the second one to be added to our local bubble
                        \ of this new system's universe

\ ******************************************************************************
\
\       Name: NWSTARS
\       Type: Subroutine
\   Category: Stardust
\    Summary: Initialise the stardust field
\
\ ------------------------------------------------------------------------------
\
\ This routine is called when the space view is initialised in routine LOOK1.
\
\ ******************************************************************************

.NWSTARS

 LDA QQ11               \ If this is not a space view, jump to WPSHPS to skip
\ORA MJ                 \ the initialisation of the SX, SY and SZ tables. The OR
 BNE WPSHPS             \ instruction is commented out in the original source,
                        \ but it would have the effect of also skipping the
                        \ initialisation if we had mis-jumped into witchspace

\ ******************************************************************************
\
\       Name: nWq
\       Type: Subroutine
\   Category: Stardust
\    Summary: Create a random cloud of stardust
\
\ ------------------------------------------------------------------------------
\
\ Create a random cloud of stardust containing the correct number of dust
\ particles, i.e. NOSTM of them, which is 3 in witchspace and 18 (#NOST) in
\ normal space. Also clears the scanner and initialises the LSO block.
\
\ This is called by the DEATH routine when it displays our untimely demise.
\
\ ******************************************************************************

.nWq

 LDY NOSTM              \ Set Y to the current number of stardust particles, so
                        \ we can use it as a counter through all the stardust

.SAL4

 JSR DORND              \ Set A and X to random numbers

 ORA #8                 \ Set A so that it's at least 8

 STA SZ,Y               \ Store A in the Y-th particle's z_hi coordinate at
                        \ SZ+Y, so the particle appears in front of us

 STA ZZ                 \ Set ZZ to the particle's z_hi coordinate

 JSR DORND              \ Set A and X to random numbers

 STA SX,Y               \ Store A in the Y-th particle's x_hi coordinate at
                        \ SX+Y, so the particle appears in front of us

 STA X1                 \ Set X1 to the particle's x_hi coordinate

 JSR DORND              \ Set A and X to random numbers

 STA SY,Y               \ Store A in the Y-th particle's y_hi coordinate at
                        \ SY+Y, so the particle appears in front of us

 STA Y1                 \ Set Y1 to the particle's y_hi coordinate

 JSR PIXEL2             \ Draw a stardust particle at (X1,Y1) with distance ZZ

 DEY                    \ Decrement the counter to point to the next particle of
                        \ stardust

 BNE SAL4               \ Loop back to SAL4 until we have randomised all the
                        \ stardust particles

                        \ Fall through into WPSHPS to clear the scanner and
                        \ reset the LSO block

\ ******************************************************************************
\
\       Name: WPSHPS
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Clear the scanner, reset the ball line and sun line heaps
\
\ ------------------------------------------------------------------------------
\
\ Remove all ships from the scanner, reset the sun line heap at LSO, and reset
\ the ball line heap at LSX2 and LSY2.
\
\ ******************************************************************************

.WPSHPS

 LDX #0                 \ Set up a counter in X to work our way through all the
                        \ ship slots in FRIN

.WSL1

 LDA FRIN,X             \ Fetch the ship type in slot X

 BEQ WS2                \ If the slot contains 0 then it is empty and we have
                        \ checked all the slots (as they are always shuffled
                        \ down in the main loop to close up and gaps), so jump
                        \ to WS2 as we are done

 BMI WS1                \ If the slot contains a ship type with bit 7 set, then
                        \ it contains the planet or the sun, so jump down to WS1
                        \ to skip this slot, as the planet and sun don't appear
                        \ on the scanner

 STA TYPE               \ Store the ship type in TYPE

 JSR GINF               \ Call GINF to get the address of the data block for
                        \ ship slot X and store it in INF

 LDY #31                \ We now want to copy the first 32 bytes from the ship's
                        \ data block into INWK, so set a counter in Y

.WSL2

 LDA (INF),Y            \ Copy the Y-th byte from the data block pointed to by
 STA INWK,Y             \ INF into the Y-th byte of INWK workspace

 DEY                    \ Decrement the counter to point at the next byte

 BPL WSL2               \ Loop back to WSL2 until we have copied all 32 bytes

 STX XSAV               \ Store the ship slot number in XSAV while we call SCAN

 JSR SCAN               \ Call SCAN to plot this ship on the scanner, which will
                        \ remove it as it's plotted with EOR logic

 LDX XSAV               \ Restore the ship slot number from XSAV into X

 LDY #31                \ Clear bits 3, 4 and 6 in the ship's byte #31, which
 LDA (INF),Y            \ stops drawing the ship on-screen (bit 3), hides it
 AND #%10100111         \ from the scanner (bit 4) and stops any lasers firing
 STA (INF),Y            \ at it (bit 6)

.WS1

 INX                    \ Increment X to point to the next ship slot

 BNE WSL1               \ Loop back up to process the next slot (this BNE is
                        \ effectively a JMP as X will never be zero)

.WS2

 LDX #&FF               \ Set LSX2 = LSY2 = &FF to clear the ball line heap
 STX LSX2
 STX LSY2

                        \ Fall through into FLFLLS to reset the LSO block

\ ******************************************************************************
\
\       Name: FLFLLS
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Reset the sun line heap
\
\ ------------------------------------------------------------------------------
\
\ Reset the sun line heap at LSO by zero-filling it and setting the first byte
\ to &FF.
\
\ Returns:
\
\   A                   A is set to 0
\
\ ******************************************************************************

.FLFLLS

 LDY #2*Y-1             \ #Y is the y-coordinate of the centre of the space
                        \ view, so this sets Y as a counter for the number of
                        \ lines in the space view (i.e. 191), which is also the
                        \ number of lines in the LSO block

 LDA #0                 \ Set A to 0 so we can zero-fill the LSO block

.SAL6

 STA LSO,Y              \ Set the Y-th byte of the LSO block to 0

 DEY                    \ Decrement the counter

 BNE SAL6               \ Loop back until we have filled all the way to LSO+1

 DEY                    \ Decrement Y to value of &FF (as we exit the above loop
                        \ with Y = 0)

 STY LSX                \ Set the first byte of the LSO block, which has its own
                        \ label LSX, to &FF, to indicate that the sun line heap
                        \ is empty

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DET1
\       Type: Subroutine
\   Category: Screen mode
\    Summary: Show or hide the dashboard (for when we die)
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the screen to show the number of text rows given in X.
\
\ It is used when we are killed, as reducing the number of rows from the usual
\ 31 to 24 has the effect of hiding the dashboard, leaving a monochrome image
\ of ship debris and explosion clouds. Increasing the rows back up to 31 makes
\ the dashboard reappear, as the dashboard's screen memory doesn't get touched
\ by this process.
\
\ Arguments:
\
\   X                   The number of text rows to display on the screen (24
\                       will hide the dashboard, 31 will make it reappear)
\
\ Returns:
\
\   A                   A is set to 6
\
\ ******************************************************************************

.DET1

 LDA #6                 \ Set A to 6 so we can update 6845 register R6 below

 SEI                    \ Disable interrupts so we can update the 6845

 STA VIA+&00            \ Set 6845 register R6 to the value in X. Register R6
 STX VIA+&01            \ is the "vertical displayed" register, which sets the
                        \ number of rows shown on the screen

 CLI                    \ Re-enable interrupts

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SHD
\       Type: Subroutine
\   Category: Flight
\    Summary: Charge a shield and drain some energy from the energy banks
\
\ ------------------------------------------------------------------------------
\
\ Charge up a shield, and if it needs charging, drain some energy from the
\ energy banks.
\
\ Arguments:
\
\   X                   The value of the shield to recharge
\
\ ******************************************************************************

 DEX                    \ Increment the shield value so that it doesn't go past
                        \ a maximum of 255

 RTS                    \ Return from the subroutine

.SHD

 INX                    \ Increment the shield value

 BEQ SHD-2              \ If the shield value is 0 then this means it was 255
                        \ before, which is the maximum value, so jump to SHD-2
                        \ to bring it back down to 258 and return

                        \ Otherwise fall through into DENGY to drain our energy
                        \ to pay for all this shield charging

\ ******************************************************************************
\
\       Name: DENGY
\       Type: Subroutine
\   Category: Flight
\    Summary: Drain some energy from the energy banks
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   Z flag              Set if we have no energy left, clear otherwise
\
\ ******************************************************************************

.DENGY

 DEC ENERGY             \ Decrement the energy banks in ENERGY

 PHP                    \ Save the flags on the stack

 BNE P%+5               \ If the energy levels are not yet zero, skip the
                        \ following instruction

 INC ENERGY             \ The minimum allowed energy level is 1, and we just
                        \ reached 0, so increment ENERGY back to 1

 PLP                    \ Restore the flags from the stack, so we return with
                        \ the Z flag from the DEC instruction above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: COMPAS
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Update the compass
\
\ ******************************************************************************

.COMPAS

 JSR DOT                \ Call DOT to redraw (i.e. remove) the current compass
                        \ dot

 LDA SSPR               \ If we are inside the space station safe zone, jump to
 BNE SP1                \ SP1 to draw the space station on the compass

 JSR SPS1               \ Otherwise we need to draw the planet on the compass,
                        \ so first call SPS1 to calculate the vector to the
                        \ planet and store it in XX15

 JMP SP2                \ Jump to SP2 to draw XX15 on the compass, returning
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: SPS2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (Y X) = A / 10
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following, where A is a signed 8-bit integer and the result is a
\ signed 16-bit integer:
\
\   (Y X) = A / 10
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.SPS2

 ASL A                  \ Set X = |A| * 2, and set the C flag to the sign bit of
 TAX                    \ A

 LDA #0                 \ Set Y to have the sign bit from A in bit 7, with the
 ROR A                  \ rest of its bits zeroed, so Y now contains the sign of
 TAY                    \ the original argument

 LDA #20                \ Set Q = 20
 STA Q

 TXA                    \ Copy X into A, so A now contains the argument A * 2

 JSR DVID4              \ Calculate the following:
                        \
                        \   P = A / Q
                        \     = |argument A| * 2 / 20
                        \     = |argument A| / 10

 LDX P                  \ Set X to the result

 TYA                    \ If the sign of the original argument A is negative,
 BMI LL163              \ jump to LL163 to flip the sign of the result

 LDY #0                 \ Set the high byte of the result to 0, as the result is
                        \ positive

 RTS                    \ Return from the subroutine

.LL163

 LDY #&FF               \ The result is negative, so set the high byte to &FF

 TXA                    \ Flip the low byte and add 1 to get the negated low
 EOR #&FF               \ byte, using two's complement
 TAX
 INX

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SPS4
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the vector to the space station
\
\ ------------------------------------------------------------------------------
\
\ Calculate the vector between our ship and the space station and store it in
\ XX15.
\
\ ******************************************************************************

.SPS4

 LDX #8                 \ First we need to copy the space station's coordinates
                        \ into K3, so set a counter to copy the first 9 bytes
                        \ (the 3-byte x, y and z coordinates) from the station's
                        \ data block at K% + NI% into K3

.SPL1

 LDA K%+NI%,X           \ Copy the X-th byte from the station's data block at
 STA K3,X               \ K% + NI% to the X-th byte of K3

 DEX                    \ Decrement the loop counter

 BPL SPL1               \ Loop back to SPL1 until we have copied all 9 bytes

 JMP TAS2               \ Call TAS2 to build XX15 from K3, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: SP1
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw the space station on the compass
\
\ ******************************************************************************

.SP1

 JSR SPS4               \ Call SPS4 to calculate the vector to the space station
                        \ and store it in XX15

                        \ Fall through into SP2 to draw XX15 on the compass

\ ******************************************************************************
\
\       Name: SP2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw a dot on the compass, given the planet/station vector
\
\ ------------------------------------------------------------------------------
\
\ Draw a dot on the compass to represent the planet or station, whose normalised
\ vector is in XX15.
\
\   XX15 to XX15+2      The normalised vector to the planet or space station,
\                       stored as x in XX15, y in XX15+1 and z in XX15+2
\
\ ******************************************************************************

.SP2

 LDA XX15               \ Set A to the x-coordinate of the planet or station to
                        \ show on the compass, which will be in the range -96 to
                        \ +96 as the vector has been normalised

 JSR SPS2               \ Set (Y X) = A / 10, so X will be from -9 to +9, which
                        \ is the x-offset from the centre of the compass of the
                        \ dot we want to draw. Returns with the C flag clear

 TXA                    \ Set COMX = 195 + X, as 186 is the pixel x-coordinate
 ADC #195               \ of the leftmost dot possible on the compass, and X can
 STA COMX               \ be -9, which would be 195 - 9 = 186. This also means
                        \ that the highest value for COMX is 195 + 9 = 204,
                        \ which is the pixel x-coordinate of the rightmost dot
                        \ in the compass... but the compass dot is actually two
                        \ pixels wide, so the compass dot can overlap the right
                        \ edge of the compass, but not the left edge

 LDA XX15+1             \ Set A to the y-coordinate of the planet or station to
                        \ show on the compass, which will be in the range -96 to
                        \ +96 as the vector has been normalised

 JSR SPS2               \ Set (Y X) = A / 10, so X will be from -9 to +9, which
                        \ is the y-offset from the centre of the compass of the
                        \ dot we want to draw. Returns with the C flag clear

 STX T                  \ Set COMY = 204 - X, as 203 is the pixel y-coordinate
 LDA #204               \ of the centre of the compass, the C flag is clear,
 SBC T                  \ and the y-axis needs to be flipped around (because
 STA COMY               \ when the planet or station is above us, and the
                        \ vector is therefore positive, we want to show the dot
                        \ higher up on the compass, which has a smaller pixel
                        \ y-coordinate). So this calculation does this:
                        \
                        \   COMY = 204 - X - (1 - 0) = 203 - X

 LDA #&F0               \ Set A to a 4-pixel mode 5 byte row in colour 2
                        \ (yellow/white), the colour for when the planet or
                        \ station in the compass is in front of us

 LDX XX15+2             \ If the z-coordinate of the XX15 vector is positive,
 BPL P%+4               \ skip the following instruction

 LDA #&FF               \ The z-coordinate of XX15 is negative, so the planet or
                        \ station is behind us and the compass dot should be in
                        \ green/cyan, so set A to a 4-pixel mode 5 byte row in
                        \ colour 3

 STA COMC               \ Store the compass colour in COMC

                        \ Fall through into DOT to draw the dot on the compass

\ ******************************************************************************
\
\       Name: DOT
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw a dash on the compass
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   COMX                The screen pixel x-coordinate of the dash
\
\   COMY                The screen pixel y-coordinate of the dash
\
\   COMC                The colour and thickness of the dash:
\
\                         * &F0 = a double-height dash in yellow/white, for when
\                           the object in the compass is in front of us
\
\                         * &FF = a single-height dash in green/cyan, for when
\                           the object in the compass is behind us
\
\ ******************************************************************************

.DOT

 LDA COMY               \ Set Y1 = COMY, the y-coordinate of the dash
 STA Y1

 LDA COMX               \ Set X1 = COMX, the x-coordinate of the dash
 STA X1

 LDA COMC               \ Set COL = COMC, the mode 5 colour byte for the dash
 STA COL

 CMP #&F0               \ If COL is &F0 then the planet/station is in front of
 BNE CPIX2              \ us and we want to draw a double-height dash, so if it
                        \ isn't &F0 jump to CPIX2 to draw a single-height dash

                        \ Otherwise fall through into CPIX4 to draw a double-
                        \ height dash

\ ******************************************************************************
\
\       Name: CPIX4
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a double-height dot on the dashboard
\
\ ------------------------------------------------------------------------------
\
\ Draw a double-height mode 5 dot (2 pixels high, 2 pixels wide).
\
\ Arguments:
\
\   X1                  The screen pixel x-coordinate of the bottom-left corner
\                       of the dot
\
\   Y1                  The screen pixel y-coordinate of the bottom-left corner
\                       of the dot
\
\   COL                 The colour of the dot as a mode 5 character row byte
\
\ ******************************************************************************

.CPIX4

 JSR CPIX2              \ Call CPIX2 to draw a single-height dash at (X1, Y1)

 DEC Y1                 \ Decrement Y1

                        \ Fall through into CPIX2 to draw a second single-height
                        \ dash on the pixel row above the first one, to create a
                        \ double-height dot

\ ******************************************************************************
\
\       Name: CPIX2
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a single-height dash on the dashboard
\  Deep dive: Drawing colour pixels in mode 5
\
\ ------------------------------------------------------------------------------
\
\ Draw a single-height mode 5 dash (1 pixel high, 2 pixels wide).
\
\ Arguments:
\
\   X1                  The screen pixel x-coordinate of the dash
\
\   Y1                  The screen pixel y-coordinate of the dash
\
\   COL                 The colour of the dash as a mode 5 character row byte
\
\ ******************************************************************************

.CPIX2

 LDA Y1                 \ Fetch the y-coordinate into A

\.CPIX                  \ This label is commented out in the original source. It
                        \ would provide a new entry point with A specifying the
                        \ y-coordinate instead of Y1, but it isn't used anywhere

 TAY                    \ Store the y-coordinate in Y

 LSR A                  \ Set A = A / 8, so A now contains the character row we
 LSR A                  \ need to draw in (as each character row contains 8
 LSR A                  \ pixel rows)

 ORA #&60               \ Each character row in Elite's screen mode takes up one
                        \ page in memory (256 bytes), so we now OR with &60 to
                        \ get the page containing the dash (see the comments in
                        \ routine TT26 for more discussion about calculating
                        \ screen memory addresses)

 STA SCH                \ Store the screen page in the high byte of SC(1 0)

 LDA X1                 \ Each character block contains 8 pixel rows, so to get
 AND #%11111000         \ the address of the first byte in the character block
                        \ that we need to draw into, as an offset from the start
                        \ of the row, we clear bits 0-2

 STA SC                 \ Store the address of the character block in the low
                        \ byte of SC(1 0), so now SC(1 0) points to the
                        \ character block we need to draw into

 TYA                    \ Set Y to just bits 0-2 of the y-coordinate, which will
 AND #%00000111         \ be the number of the pixel row we need to draw into
 TAY                    \ within the character block

 LDA X1                 \ Copy bits 0-1 of X1 to bits 1-2 of X, and clear the C
 AND #%00000110         \ flag in the process (using the LSR). X will now be
 LSR A                  \ a value between 0 and 3, and will be the pixel number
 TAX                    \ in the character row for the left pixel in the dash.
                        \ This is because each character row is one byte that
                        \ contains 4 pixels, but covers 8 screen coordinates, so
                        \ this effectively does the division by 2 that we need

 LDA CTWOS,X            \ Fetch a mode 5 1-pixel byte with the pixel position
 AND COL                \ at X, and AND with the colour byte so that pixel takes
                        \ on the colour we want to draw (i.e. A is acting as a
                        \ mask on the colour byte)

 EOR (SC),Y             \ Draw the pixel on-screen using EOR logic, so we can
 STA (SC),Y             \ remove it later without ruining the background that's
                        \ already on-screen

 LDA CTWOS+1,X          \ Fetch a mode 5 1-pixel byte with the pixel position
                        \ at X+1, so we can draw the right pixel of the dash

 BPL CP1                \ The CTWOS table has an extra row at the end of it that
                        \ repeats the first value, %10001000, so if we have not
                        \ fetched that value, then the right pixel of the dash
                        \ is in the same character block as the left pixel, so
                        \ jump to CP1 to draw it

 LDA SC                 \ Otherwise the left pixel we drew was at the last
 ADC #8                 \ position of four in this character block, so we add
 STA SC                 \ 8 to the screen address to move onto the next block
                        \ along (as there are 8 bytes in a character block).
                        \ The C flag was cleared above, so this ADC is correct

 LDA CTWOS+1,X          \ Refetch the mode 5 1-pixel byte, as we just overwrote
                        \ A (the byte will still be the fifth byte from the
                        \ table, which is correct as we want to draw the
                        \ leftmost pixel in the next character along as the
                        \ dash's right pixel)

.CP1

 AND COL                \ Apply the colour mask to the pixel byte, as above

 EOR (SC),Y             \ Draw the dash's right pixel according to the mask in
 STA (SC),Y             \ A, with the colour in COL, using EOR logic, just as
                        \ above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: OOPS
\       Type: Subroutine
\   Category: Flight
\    Summary: Take some damage
\
\ ------------------------------------------------------------------------------
\
\ We just took some damage, so reduce the shields if we have any, or reduce the
\ energy levels and potentially take some damage to the cargo if we don't.
\
\ Arguments:
\
\   A                   The amount of damage to take
\
\   INF                 The address of the ship block for the ship that attacked
\                       us, or the ship that we just ran into
\
\ ******************************************************************************

.OOPS

 STA T                  \ Store the amount of damage in T

 LDY #8                 \ Fetch byte #8 (z_sign) for the ship attacking us, and
 LDX #0                 \ set X = 0
 LDA (INF),Y

 BMI OO1                \ If A is negative, then we got hit in the rear, so jump
                        \ to OO1 to process damage to the aft shield

 LDA FSH                \ Otherwise the forward shield was damaged, so fetch the
 SBC T                  \ shield strength from FSH and subtract the damage in T

 BCC OO2                \ If the C flag is clear then this amount of damage was
                        \ too much for the shields, so jump to OO2 to set the
                        \ shield level to 0 and start taking damage directly
                        \ from the energy banks

 STA FSH                \ Store the new value of the forward shield in FSH

 RTS                    \ Return from the subroutine

.OO2

\LDX #0                 \ This instruction is commented out in the original
                        \ source, and isn't required as X is set to 0 above

 STX FSH                \ Set the forward shield to 0

 BCC OO3                \ Jump to OO3 to start taking damage directly from the
                        \ energy banks (this BCC is effectively a JMP as the C
                        \ flag is clear, as we jumped to OO2 with a BCC)

.OO1

 LDA ASH                \ The aft shield was damaged, so fetch the shield
 SBC T                  \ strength from ASH and subtract the damage in T

 BCC OO5                \ If the C flag is clear then this amount of damage was
                        \ too much for the shields, so jump to OO5 to set the
                        \ shield level to 0 and start taking damage directly
                        \ from the energy banks

 STA ASH                \ Store the new value of the aft shield in ASH

 RTS                    \ Return from the subroutine

.OO5

\LDX #0                 \ This instruction is commented out in the original
                        \ source, and isn't required as X is set to 0 above

 STX ASH                \ Set the aft shield to 0

.OO3

 ADC ENERGY             \ A is negative and contains the amount by which the
 STA ENERGY             \ damage overwhelmed the shields, so this drains the
                        \ energy banks by that amount (and because the energy
                        \ banks are shown over four indicators rather than one,
                        \ but with the same value range of 0-255, energy will
                        \ appear to drain away four times faster than the
                        \ shields did)

 BEQ P%+4               \ If we have just run out of energy, skip the next
                        \ instruction to jump straight to our death

 BCS P%+5               \ If the C flag is set, then subtracting the damage from
                        \ the energy banks didn't underflow, so we had enough
                        \ energy to survive, and we can skip the next
                        \ instruction to make a sound and take some damage

 JMP DEATH              \ Otherwise our energy levels are either 0 or negative,
                        \ and in either case that means we jump to our DEATH,
                        \ returning from the subroutine using a tail call

 JSR EXNO3              \ We didn't die, so call EXNO3 to make the sound of a
                        \ collision

 JMP OUCH               \ And jump to OUCH to take damage and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: SPS3
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Copy a space coordinate from the K% block into K3
\
\ ------------------------------------------------------------------------------
\
\ Copy one of the planet's coordinates into the corresponding location in the
\ temporary variable K3. The high byte and absolute value of the sign byte are
\ copied into the first two K3 bytes, and the sign of the sign byte is copied
\ into the highest K3 byte.
\
\ The comments below are written for copying the planet's x-coordinate into
\ K3(2 1 0).
\
\ Arguments:
\
\   X                   Determines which coordinate to copy, and to where:
\
\                         * X = 0 copies (x_sign, x_hi) into K3(2 1 0)
\
\                         * X = 3 copies (y_sign, y_hi) into K3(5 4 3)
\
\                         * X = 6 copies (z_sign, z_hi) into K3(8 7 6)
\
\ ******************************************************************************

.SPS3

 LDA K%+1,X             \ Copy x_hi into K3+X
 STA K3,X

 LDA K%+2,X             \ Set A = Y = x_sign
 TAY

 AND #%01111111         \ Set K3+1 = |x_sign|
 STA K3+1,X

 TYA                    \ Set K3+2 = the sign of x_sign
 AND #%10000000
 STA K3+2,X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GINF
\       Type: Subroutine
\   Category: Universe
\    Summary: Fetch the address of a ship's data block into INF
\
\ ------------------------------------------------------------------------------
\
\ Get the address of the data block for ship slot X and store it in INF. This
\ address is fetched from the UNIV table, which stores the addresses of the 13
\ ship data blocks in workspace K%.
\
\ Arguments:
\
\   X                   The ship slot number for which we want the data block
\                       address
\
\ ******************************************************************************

.GINF

 TXA                    \ Set Y = X * 2
 ASL A
 TAY

 LDA UNIV,Y             \ Get the high byte of the address of the X-th ship
 STA INF                \ from UNIV and store it in INF

 LDA UNIV+1,Y           \ Get the low byte of the address of the X-th ship
 STA INF+1              \ from UNIV and store it in INF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: NWSPS
\       Type: Subroutine
\   Category: Universe
\    Summary: Add a new space station to our local bubble of universe
\
\ ******************************************************************************

.NWSPS

 JSR SPBLB              \ Light up the space station bulb on the dashboard

 LDX #%00000001         \ Set the AI flag in byte #32 to %00000001 (friendly, no
 STX INWK+32            \ AI, has an E.C.M.)

 DEX                    \ Set pitch counter to 0 (no pitch, roll only)
 STX INWK+30

\STX INWK+31            \ This instruction is commented out in the original
                        \ source. It would set the exploding state and missile
                        \ count to 0

 STX FRIN+1             \ Set the sun/space station slot at FRIN+1 to 0, to
                        \ indicate we should show the space station rather than
                        \ the sun

 DEX                    \ Set roll counter to 255 (maximum roll with no
 STX INWK+29            \ damping)

 LDX #10                \ Call NwS1 to flip the sign of nosev_x_hi (byte #10)
 JSR NwS1

 JSR NwS1               \ And again to flip the sign of nosev_y_hi (byte #12)

 JSR NwS1               \ And again to flip the sign of nosev_z_hi (byte #14)

 LDA #LO(LSO)           \ Set bytes #33 and #34 to point to LSO for the ship
 STA INWK+33            \ line heap for the space station
 LDA #HI(LSO)
 STA INWK+34

 LDA #SST               \ Set A to the space station type, and fall through
                        \ into NWSHP to finish adding the space station to the
                        \ universe

\ ******************************************************************************
\
\       Name: NWSHP
\       Type: Subroutine
\   Category: Universe
\    Summary: Add a new ship to our local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ This creates a new block of ship data in the K% workspace, allocates a new
\ block in the ship line heap at WP, adds the new ship's type into the first
\ empty slot in FRIN, and adds a pointer to the ship data into UNIV. If there
\ isn't enough free memory for the new ship, it isn't added.
\
\ Arguments:
\
\   A                   The type of the ship to add (see variable XX21 for a
\                       list of ship types)
\
\ Returns:
\
\   C flag              Set if the ship was successfully added, clear if it
\                       wasn't (as there wasn't enough free memory)
\
\   INF                 Points to the new ship's data block in K%
\
\ ******************************************************************************

.NWSHP

 STA T                  \ Store the ship type in location T

 LDX #0                 \ Before we can add a new ship, we need to check
                        \ whether we have an empty slot we can put it in. To do
                        \ this, we need to loop through all the slots to look
                        \ for an empty one, so set a counter in X that starts
                        \ from the first slot at 0. When ships are killed, then
                        \ the slots are shuffled down by the KILLSHP routine, so
                        \ the first empty slot will always come after the last
                        \ filled slot. This allows us to tack the new ship's
                        \ data block and ship line heap onto the end of the
                        \ existing ship data and heap, as shown in the memory
                        \ map below

.NWL1

 LDA FRIN,X             \ Load the ship type for the X-th slot

 BEQ NW1                \ If it is zero, then this slot is empty and we can use
                        \ it for our new ship, so jump down to NW1

 INX                    \ Otherwise increment X to point to the next slot

 CPX #NOSH              \ If we haven't reached the last slot yet, loop back up
 BCC NWL1               \ to NWL1 to check the next slot (note that this means
                        \ only slots from 0 to #NOSH - 1 are populated by this
                        \ routine, but there is one more slot reserved in FRIN,
                        \ which is used to identify the end of the slot list
                        \ when shuffling the slots down in the KILLSHP routine)

.NW3

 CLC                    \ Otherwise we don't have an empty slot, so we can't
 RTS                    \ add a new ship, so clear the C flag to indicate that
                        \ we have not managed to create the new ship, and return
                        \ from the subroutine

.NW1

                        \ If we get here, then we have found an empty slot at
                        \ index X, so we can go ahead and create our new ship.
                        \ We do that by creating a ship data block at INWK and,
                        \ when we are done, copying the block from INWK into
                        \ the K% workspace (specifically, to INF)

 JSR GINF               \ Get the address of the data block for ship slot X
                        \ (which is in workspace K%) and store it in INF

 LDA T                  \ If the type of ship that we want to create is
 BMI NW2                \ negative, then this indicates a planet or sun, so
                        \ jump down to NW2, as the next section sets up a ship
                        \ data block, which doesn't apply to planets and suns,
                        \ as they don't have things like shields, missiles,
                        \ vertices and edges

                        \ This is a ship, so first we need to set up various
                        \ pointers to the ship blueprint we will need. The
                        \ blueprints for each ship type in Elite are stored
                        \ in a table at location XX21, so refer to the comments
                        \ on that variable for more details on the data we're
                        \ about to access

 ASL A                  \ Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           \ The ship blueprints at XX21 start with a lookup
 STA XX0                \ table that points to the individual ship blueprints,
                        \ so this fetches the low byte of this particular ship
                        \ type's blueprint and stores it in XX0

 LDA XX21-1,Y           \ Fetch the high byte of this particular ship type's
 STA XX0+1              \ blueprint and store it in XX0+1, so XX0(1 0) now
                        \ contains the address of this ship's blueprint

 CPY #2*SST             \ If the ship type is a space station (SST), then jump
 BEQ NW6                \ to NW6, skipping the heap space steps below, as the
                        \ space station has its own line heap at LSO (which it
                        \ shares with the sun)

                        \ We now want to allocate space for a heap that we can
                        \ use to store the lines we draw for our new ship (so it
                        \ can easily be erased from the screen again). SLSP
                        \ points to the start of the current heap space, and we
                        \ can extend it downwards with the heap for our new ship
                        \ (as the heap space always ends just before the WP
                        \ workspace)

 LDY #5                 \ Fetch ship blueprint byte #5, which contains the
 LDA (XX0),Y            \ maximum heap size required for plotting the new ship,
 STA T1                 \ and store it in T1

 LDA SLSP               \ Take the 16-bit address in SLSP and subtract T1,
 SEC                    \ storing the 16-bit result in INWK(34 33), so this now
 SBC T1                 \ points to the start of the line heap for our new ship
 STA INWK+33
 LDA SLSP+1
 SBC #0
 STA INWK+34

                        \ We now need to check that there is enough free space
                        \ for both this new line heap and the new data block
                        \ for our ship. In memory, this is the layout of the
                        \ ship data blocks and ship line heaps:
                        \
                        \   +-----------------------------------+   &0F34
                        \   |                                   |
                        \   | WP workspace                      |
                        \   |                                   |
                        \   +-----------------------------------+   &0D40 = WP
                        \   |                                   |
                        \   | Current ship line heap            |
                        \   |                                   |
                        \   +-----------------------------------+   SLSP
                        \   |                                   |
                        \   | Proposed heap for new ship        |
                        \   |                                   |
                        \   +-----------------------------------+   INWK(34 33)
                        \   |                                   |
                        \   .                                   .
                        \   .                                   .
                        \   .                                   .
                        \   .                                   .
                        \   .                                   .
                        \   |                                   |
                        \   +-----------------------------------+   INF + NI%
                        \   |                                   |
                        \   | Proposed data block for new ship  |
                        \   |                                   |
                        \   +-----------------------------------+   INF
                        \   |                                   |
                        \   | Existing ship data blocks         |
                        \   |                                   |
                        \   +-----------------------------------+   &0900 = K%
                        \
                        \ So, to work out if we have enough space, we have to
                        \ make sure there is room between the end of our new
                        \ ship data block at INF + NI%, and the start of the
                        \ proposed heap for our new ship at the address we
                        \ stored in INWK(34 33). Or, to put it another way, we
                        \ and to make sure that:
                        \
                        \   INWK(34 33) > INF + NI%
                        \
                        \ which is the same as saying:
                        \
                        \   INWK+33 - INF > NI%
                        \
                        \ because INWK is in zero page, so INWK+34 = 0

 LDA INWK+33            \ Calculate INWK+33 - INF, again using 16-bit
\SEC                    \ arithmetic, and put the result in (A Y), so the high
 SBC INF                \ byte is in A and the low byte in Y. The SEC
 TAY                    \ instruction is commented out in the original source;
 LDA INWK+34            \ as the previous subtraction will never underflow, it
 SBC INF+1              \ is superfluous

 BCC NW3+1              \ If we have an underflow from the subtraction, then
                        \ INF > INWK+33 and we definitely don't have enough
                        \ room for this ship, so jump to NW3+1, which returns
                        \ from the subroutine (with the C flag already cleared)

 BNE NW4                \ If the subtraction of the high bytes in A is not
                        \ zero, and we don't have underflow, then we definitely
                        \ have enough space, so jump to NW4 to continue setting
                        \ up the new ship

 CPY #NI%               \ Otherwise the high bytes are the same in our
 BCC NW3+1              \ subtraction, so now we compare the low byte of the
                        \ result (which is in Y) with NI%. This is the same as
                        \ doing INWK+33 - INF > NI% (see above). If this isn't
                        \ true, the C flag will be clear and we don't have
                        \ enough space, so we jump to NW3+1, which returns
                        \ from the subroutine (with the C flag already cleared)

.NW4

 LDA INWK+33            \ If we get here then we do have enough space for our
 STA SLSP               \ new ship, so store the new bottom of the ship line
 LDA INWK+34            \ heap (i.e. INWK+33) in SLSP, doing both the high and
 STA SLSP+1             \ low bytes

.NW6

 LDY #14                \ Fetch ship blueprint byte #14, which contains the
 LDA (XX0),Y            \ ship's energy, and store it in byte #35
 STA INWK+35

 LDY #19                \ Fetch ship blueprint byte #19, which contains the
 LDA (XX0),Y            \ number of missiles and laser power, and AND with %111
 AND #%00000111         \ to extract the number of missiles before storing in
 STA INWK+31            \ byte #31

 LDA T                  \ Restore the ship type we stored above

.NW2

 STA FRIN,X             \ Store the ship type in the X-th byte of FRIN, so the
                        \ this slot is now shown as occupied in the index table

 TAX                    \ Copy the ship type into X

 BMI P%+5               \ If the ship type is negative (planet or sun), then
                        \ skip the following instruction

 INC MANY,X             \ Increment the total number of ships of type X

 LDY #(NI%-1)           \ The final step is to copy the new ship's data block
                        \ from INWK to INF, so set up a counter for NI% bytes
                        \ in Y

.NWL3

 LDA INWK,Y             \ Load the Y-th byte of INWK and store in the Y-th byte
 STA (INF),Y            \ of the workspace pointed to by INF

 DEY                    \ Decrement the loop counter

 BPL NWL3               \ Loop back for the next byte until we have copied them
                        \ all over

 SEC                    \ We have successfully created our new ship, so set the
                        \ C flag to indicate success

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: NwS1
\       Type: Subroutine
\   Category: Universe
\    Summary: Flip the sign and double an INWK byte
\
\ ------------------------------------------------------------------------------
\
\ Flip the sign of the INWK byte at offset X, and increment X by 2. This is
\ used by the space station creation routine at NWSPS.
\
\ Arguments:
\
\   X                   The offset of the INWK byte to be flipped
\
\ Returns:
\
\   X                   X is incremented by 2
\
\ ******************************************************************************

.NwS1

 LDA INWK,X             \ Load the X-th byte of INWK into A and flip bit 7,
 EOR #%10000000         \ storing the result back in the X-th byte of INWK
 STA INWK,X

 INX                    \ Add 2 to X
 INX

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ABORT
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Disarm missiles and update the dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   The new status of the leftmost missile indicator
\
\ ******************************************************************************

.ABORT

 LDX #&FF               \ Set X to &FF, which is the value of MSTG when we have
                        \ no target lock for our missile

                        \ Fall through into ABORT2 to set the missile lock to
                        \ the value in X, which effectively disarms the missile

\ ******************************************************************************
\
\       Name: ABORT2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Set/unset the lock target for a missile and update the dashboard
\
\ ------------------------------------------------------------------------------
\
\ Set the lock target for the leftmost missile and update the dashboard.
\
\ Arguments:
\
\   X                   The slot number of the ship to lock our missile onto, or
\                       &FF to remove missile lock
\
\   Y                   The new colour of the missile indicator:
\
\                         * &00 = black (no missile)
\
\                         * &0E = red (armed and locked)
\
\                         * &E0 = yellow/white (armed)
\
\                         * &EE = green/cyan (disarmed)
\
\ ******************************************************************************

.ABORT2

 STX MSTG               \ Store the target of our missile lock in MSTG

 LDX NOMSL              \ Call MSBAR to update the leftmost indicator in the
 JSR MSBAR              \ dashboard's missile bar, which returns with Y = 0

 STY MSAR               \ Set MSAR = 0 to indicate that the leftmost missile
                        \ is no longer seeking a target lock

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ECBLB2
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Start up the E.C.M. (indicator, start countdown and make sound)
\
\ ------------------------------------------------------------------------------
\
\ Light up the E.C.M. indicator bulb on the dashboard, set the E.C.M. countdown
\ timer to 32, and start making the E.C.M. sound.
\
\ ******************************************************************************

.ECBLB2

 LDA #32                \ Set the E.C.M. countdown timer in ECMA to 32
 STA ECMA

 ASL A                  \ Call the NOISE routine with A = 64 to make the sound
 JSR NOISE              \ of the E.C.M. being switched on

                        \ Fall through into ECBLB to light up the E.C.M. bulb

\ ******************************************************************************
\
\       Name: ECBLB
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Light up the E.C.M. indicator bulb ("E") on the dashboard
\
\ ******************************************************************************

.ECBLB

 LDA #7*8               \ The E.C.M. bulb is in character block number 7
                        \ with each character taking 8 bytes, so this sets the
                        \ low byte of the screen address of the character block
                        \ we want to draw to

 LDX #LO(ECBT)          \ Set (Y X) to point to the character definition in
 LDY #HI(ECBT)          \ ECBT. The LDY has no effect, as we overwrite Y with
                        \ the jump to BULB-2, which writes the high byte of SPBT
                        \ into Y. This works as long as ECBT and SPBT are in
                        \ the same page of memory, so perhaps the BNE below got
                        \ changed from BULB to BULB-2 so they could remove the
                        \ LDY, but for some reason it didn't get culled? Who
                        \ knows...

 BNE BULB-2             \ Jump down to BULB-2 (this BNE is effectively a JMP as
                        \ A will never be zero)

\ ******************************************************************************
\
\       Name: SPBLB
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Light up the space station indicator ("S") on the dashboard
\
\ ******************************************************************************

.SPBLB

 LDA #24*8              \ The space station bulb is in character block number 24
                        \ with each character taking 8 bytes, so this sets the
                        \ low byte of the screen address of the character block
                        \ we want to draw to

 LDX #LO(SPBT)          \ Set (Y X) to point to the character definition in SPBT
 LDY #HI(SPBT)

                        \ Fall through into BULB to draw the space station bulb

\ ******************************************************************************
\
\       Name: BULB
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw an indicator bulb on the dashboard
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The y-coordinate of the bulb as a low-byte screen
\                       address offset within screen page &7D (as both bulbs
\                       are on this character row in the dashboard)
\
\   (Y X)               The address of the character definition of the bulb to
\                       be drawn (i.e. ECBT for the E.C.M. bulb, or SPBT for the
\                       space station bulb)
\
\ Other entry points:
\
\   BULB-2              Set the Y screen address
\
\ ******************************************************************************

.BULB

 STA SC                 \ Store the low byte of the screen address in SC

 STX P+1                \ Set P(2 1) = (Y X)
 STY P+2

 LDA #&7D               \ Set A to the high byte of the screen address, which is
                        \ &7D as the bulbs are both in the character row from
                        \ &7D00 to &7DFF

 JMP RREN               \ Call RREN to print the character definition pointed to
                        \ by P(2 1) at the screen address pointed to by (A SC),
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: ECBT
\       Type: Variable
\   Category: Dashboard
\    Summary: The character bitmap for the E.C.M. indicator bulb
\
\ ------------------------------------------------------------------------------
\
\ The character bitmap for the E.C.M. indicator's "E" bulb that gets displayed
\ on the dashboard.
\
\ The E.C.M. indicator uses the first 5 rows of the space station's "S" bulb
\ below, as the bottom 5 rows of the "E" match the top 5 rows of the "S".
\
\ Each pixel is in mode 5 colour 2 (%10), which is yellow/white.
\
\ ******************************************************************************

.ECBT

 EQUB %11100000         \ x x x .
 EQUB %11100000         \ x x x .
 EQUB %10000000         \ x . . .
                        \ x x x .
                        \ x x x .
                        \ x . . .
                        \ x x x .
                        \ x x x .

\ ******************************************************************************
\
\       Name: SPBT
\       Type: Variable
\   Category: Dashboard
\    Summary: The bitmap definition for the space station indicator bulb
\
\ ------------------------------------------------------------------------------
\
\ The bitmap definition for the space station indicator's "S" bulb that gets
\ displayed on the dashboard.
\
\ Each pixel is in mode 5 colour 2 (%10), which is yellow/white.
\
\ ******************************************************************************

.SPBT

 EQUB %11100000         \ x x x .
 EQUB %11100000         \ x x x .
 EQUB %10000000         \ x . . .
 EQUB %11100000         \ x x x .
 EQUB %11100000         \ x x x .
 EQUB %00100000         \ . . x .
 EQUB %11100000         \ x x x .
 EQUB %11100000         \ x x x .

\ ******************************************************************************
\
\       Name: MSBAR
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Draw a specific indicator in the dashboard's missile bar
\
\ ------------------------------------------------------------------------------
\
\ Each indicator is a rectangle that's 3 pixels wide and 5 pixels high. If the
\ indicator is set to black, this effectively removes a missile.
\
\ Arguments:
\
\   X                   The number of the missile indicator to update (counting
\                       from right to left, so indicator NOMSL is the leftmost
\                       indicator)
\
\   Y                   The colour of the missile indicator:
\
\                         * &00 = black (no missile)
\
\                         * &0E = red (armed and locked)
\
\                         * &E0 = yellow/white (armed)
\
\                         * &EE = green/cyan (disarmed)
\
\ Returns:
\
\   X                   X is preserved
\
\   Y                   Y is set to 0
\
\ ******************************************************************************

.MSBAR

 TXA                    \ Set T = X * 8
 ASL A
 ASL A
 ASL A
 STA T

 LDA #49                \ Set SC = 49 - T
 SBC T                  \        = 48 + 1 - (X * 8)
 STA SC

                        \ So the low byte of SC(1 0) contains the row address
                        \ for the rightmost missile indicator, made up as
                        \ follows:
                        \
                        \   * 48 (character block 7, as byte #7 * 8 = 48), the
                        \     character block of the rightmost missile
                        \
                        \   * 1 (so we start drawing on the second row of the
                        \     character block)
                        \
                        \   * Move right one character (8 bytes) for each count
                        \     of X, so when X = 0 we are drawing the rightmost
                        \     missile, for X = 1 we hop to the left by one
                        \     character, and so on

 LDA #&7E               \ Set the high byte of SC(1 0) to &7E, the character row
 STA SCH                \ that contains the missile indicators (i.e. the bottom
                        \ row of the screen)

 TYA                    \ Set A to the correct colour, which is a 3-pixel wide
                        \ mode 5 character row in the correct colour (for
                        \ example, a green block has Y = &EE, or %11101110, so
                        \ the missile blocks are 3 pixels wide, with the
                        \ fourth pixel on the character row being empty)

 LDY #5                 \ We now want to draw this line five times, so set a
                        \ counter in Y

.MBL1

 STA (SC),Y             \ Draw the 3-pixel row, and as we do not use EOR logic,
                        \ this will overwrite anything that is already there
                        \ (so drawing a black missile will delete what's there)

 DEY                    \ Decrement the counter for the next row

 BNE MBL1               \ Loop back to MBL1 if have more rows to draw

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PROJ
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Project the current ship onto the screen
\  Deep dive: Extended screen coordinates
\
\ ------------------------------------------------------------------------------
\
\ Project the current ship's location onto the screen, either returning the
\ screen coordinates of the projection (if it's on-screen), or returning an
\ error via the C flag.
\
\ In this context, "on-screen" means that the point is projected into the
\ following range:
\
\   centre of screen - 1024 < x < centre of screen + 1024
\   centre of screen - 1024 < y < centre of screen + 1024
\
\ This is to cater for ships (and, more likely, planets and suns) whose centres
\ are off-screen but whose edges may still be visible.
\
\ The projection calculation is:
\
\   K3(1 0) = #X + x / z
\   K4(1 0) = #Y + y / z
\
\ where #X and #Y are the pixel x-coordinate and y-coordinate of the centre of
\ the screen.
\
\ Arguments:
\
\   INWK                The ship data block for the ship to project on-screen
\
\ Returns:
\
\   K3(1 0)             The x-coordinate of the ship's projection on-screen
\
\   K4(1 0)             The y-coordinate of the ship's projection on-screen
\
\   C flag              Set if the ship's projection doesn't fit on the screen,
\                       clear if it does project onto the screen
\
\   A                   Contains K4+1, the high byte of the y-coordinate
\
\ ******************************************************************************

.PROJ

 LDA INWK               \ Set P(1 0) = (x_hi x_lo)
 STA P                  \            = x
 LDA INWK+1
 STA P+1

 LDA INWK+2             \ Set A = x_sign

 JSR PLS6               \ Call PLS6 to calculate:
                        \
                        \   (X K) = (A P) / (z_sign z_hi z_lo)
                        \         = (x_sign x_hi x_lo) / (z_sign z_hi z_lo)
                        \         = x / z

 BCS PL2-1              \ If the C flag is set then the result overflowed and
                        \ the coordinate doesn't fit on the screen, so return
                        \ from the subroutine with the C flag set (as PL2-1
                        \ contains an RTS)

 LDA K                  \ Set K3(1 0) = (X K) + #X
 ADC #X                 \             = #X + x / z
 STA K3                 \
                        \ first doing the low bytes

 TXA                    \ And then the high bytes. #X is the x-coordinate of
 ADC #0                 \ the centre of the space view, so this converts the
 STA K3+1               \ space x-coordinate into a screen x-coordinate

 LDA INWK+3             \ Set P(1 0) = (y_hi y_lo)
 STA P
 LDA INWK+4
 STA P+1

 LDA INWK+5             \ Set A = -y_sign
 EOR #%10000000

 JSR PLS6               \ Call PLS6 to calculate:
                        \
                        \   (X K) = (A P) / (z_sign z_hi z_lo)
                        \         = -(y_sign y_hi y_lo) / (z_sign z_hi z_lo)
                        \         = -y / z

 BCS PL2-1              \ If the C flag is set then the result overflowed and
                        \ the coordinate doesn't fit on the screen, so return
                        \ from the subroutine with the C flag set (as PL2-1
                        \ contains an RTS)

 LDA K                  \ Set K4(1 0) = (X K) + #Y
 ADC #Y                 \             = #Y - y / z
 STA K4                 \
                        \ first doing the low bytes

 TXA                    \ And then the high bytes. #Y is the y-coordinate of
 ADC #0                 \ the centre of the space view, so this converts the
 STA K4+1               \ space x-coordinate into a screen y-coordinate

 CLC                    \ Clear the C flag to indicate success

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PL2
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Remove the planet or sun from the screen
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   PL2-1               Contains an RTS
\
\ ******************************************************************************

.PL2

 LDA TYPE               \ Shift bit 0 of the planet/sun's type into the C flag
 LSR A

 BCS P%+5               \ If the planet/sun's type has bit 0 clear, then it's
                        \ either 128 or 130, which is a planet; meanwhile, the
                        \ sun has type 129, which has bit 0 set. So if this is
                        \ the sun, skip the following instruction

 JMP WPLS2              \ This is the planet, so jump to WPLS2 to remove it from
                        \ screen, returning from the subroutine using a tail
                        \ call

 JMP WPLS               \ This is the sun, so jump to WPLS to remove it from
                        \ screen, returning from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: PLANET
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw the planet or sun
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   INWK                The planet or sun's ship data block
\
\ ******************************************************************************

.PLANET

 LDA INWK+8             \ Set A = z_sign (the highest byte in the planet/sun's
                        \ coordinates)

 BMI PL2                \ If A is negative then the planet/sun is behind us, so
                        \ jump to PL2 to remove it from the screen, returning
                        \ from the subroutine using a tail call

 CMP #48                \ If A >= 48 then the planet/sun is too far away to be
 BCS PL2                \ seen, so jump to PL2 to remove it from the screen,
                        \ returning from the subroutine using a tail call

 ORA INWK+7             \ Set A to z_sign OR z_hi to get the maximum of the two

 BEQ PL2                \ If the maximum is 0, then the planet/sun is too close
                        \ to be shown, so jump to PL2 to remove it from the
                        \ screen, returning from the subroutine using a tail
                        \ call

 JSR PROJ               \ Project the planet/sun onto the screen, returning the
                        \ centre's coordinates in K3(1 0) and K4(1 0)

 BCS PL2                \ If the C flag is set by PROJ then the planet/sun is
                        \ not visible on-screen, so jump to PL2 to remove it
                        \ from the screen, returning from the subroutine using
                        \ a tail call

 LDA #96                \ Set (A P+1 P) = (0 96 0) = 24576
 STA P+1                \
 LDA #0                 \ This represents the planet/sun's radius at a distance
 STA P                  \ of z = 1

 JSR DVID3B2            \ Call DVID3B2 to calculate:
                        \
                        \   K(3 2 1 0) = (A P+1 P) / (z_sign z_hi z_lo)
                        \              = (0 96 0) / z
                        \              = 24576 / z
                        \
                        \ so K now contains the planet/sun's radius, reduced by
                        \ the actual distance to the planet/sun. We know that
                        \ K+3 and K+2 will be 0, as the number we are dividing,
                        \ (0 96 0), fits into the two bottom bytes, so the
                        \ result is actually in K(1 0)

 LDA K+1                \ If the high byte of the reduced radius is zero, jump
 BEQ PL82               \ to PL82, as K contains the radius on its own

 LDA #248               \ Otherwise set K = 248, to use as our one-byte radius
 STA K

.PL82

 LDA TYPE               \ If the planet/sun's type has bit 0 clear, then it's
 LSR A                  \ either 128 or 130, which is a planet (the sun has type
 BCC PL9                \ 129, which has bit 0 set). So jump to PL9 to draw the
                        \ planet with radius K, returning from the subroutine
                        \ using a tail call

 JMP SUN                \ Otherwise jump to SUN to draw the sun with radius K,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PL9 (Part 1 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw the planet, with either an equator and meridian, or a crater
\
\ ------------------------------------------------------------------------------
\
\ Draw the planet with radius K at pixel coordinate (K3, K4), and with either an
\ equator and meridian, or a crater.
\
\ Arguments:
\
\   K(1 0)              The planet's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the planet
\
\   K4(1 0)             Pixel y-coordinate of the centre of the planet
\
\   INWK                The planet's ship data block
\
\ ******************************************************************************

.PL9

 JSR WPLS2              \ Call WPLS2 to remove the planet from the screen

 JSR CIRCLE             \ Call CIRCLE to draw the planet's new circle

 BCS PL20               \ If the call to CIRCLE returned with the C flag set,
                        \ then the circle does not fit on-screen, so jump to
                        \ PL20 to return from the subroutine

 LDA K+1                \ If K+1 is zero, jump to PL25 as K(1 0) < 256, so the
 BEQ PL25               \ planet fits on the screen

.PL20

 RTS                    \ The planet doesn't fit on-screen, so return from the
                        \ subroutine

.PL25

 LDA TYPE               \ If the planet type is 128 then it has an equator and
 CMP #128               \ a meridian, so this jumps to PL26 if this is not a
 BNE PL26               \ planet with an equator - in other words, if it is a
                        \ planet with a crater

                        \ Otherwise this is a planet with an equator and
                        \ meridian, so fall through into the following to draw
                        \ them

\ ******************************************************************************
\
\       Name: PL9 (Part 2 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw the planet's equator and meridian
\  Deep dive: Drawing meridians and equators
\
\ ------------------------------------------------------------------------------
\
\ Draw the planet's equator and meridian.
\
\ Arguments:
\
\   K(1 0)              The planet's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the planet
\
\   K4(1 0)             Pixel y-coordinate of the centre of the planet
\
\   INWK                The planet's ship data block
\
\ ******************************************************************************

 LDA K                  \ If the planet's radius is less than 6, the planet is
 CMP #6                 \ too small to show a crater, so jump to PL20 to return
 BCC PL20               \ from the subroutine

 LDA INWK+14            \ Set P = -nosev_z_hi
 EOR #%10000000
 STA P

 LDA INWK+20            \ Set A = roofv_z_hi

 JSR PLS4               \ Call PLS4 to calculate the following:
                        \
                        \   CNT2 = arctan(P / A) / 4
                        \        = arctan(-nosev_z_hi / roofv_z_hi) / 4
                        \
                        \ and give the result the opposite sign to nosev_z_hi

 LDX #9                 \ Set X to 9 so the call to PLS1 divides nosev_x

 JSR PLS1               \ Call PLS1 to calculate the following:
 STA K2                 \
 STY XX16               \   (XX16 K2) = nosev_x / z
                        \
                        \ and increment X to point to nosev_y for the next call

 JSR PLS1               \ Call PLS1 to calculate the following:
 STA K2+1               \
 STY XX16+1             \   (XX16+1 K2+1) = nosev_y / z

 LDX #15                \ Set X to 15 so the call to PLS5 divides roofv_x

 JSR PLS5               \ Call PLS5 to calculate the following:
                        \
                        \   (XX16+2 K2+2) = roofv_x / z
                        \
                        \   (XX16+3 K2+3) = roofv_y / z

 JSR PLS2               \ Call PLS2 to draw the first meridian

 LDA INWK+14            \ Set P = -nosev_z_hi
 EOR #%10000000
 STA P

 LDA INWK+26            \ Set A = sidev_z_hi, so the second meridian will be at
                        \ 90 degrees to the first

 JSR PLS4               \ Call PLS4 to calculate the following:
                        \
                        \   CNT2 = arctan(P / A) / 4
                        \        = arctan(-nosev_z_hi / sidev_z_hi) / 4
                        \
                        \ and give the result the opposite sign to nosev_z_hi

 LDX #21                \ Set X to 21 so the call to PLS5 divides sidev_x

 JSR PLS5               \ Call PLS5 to calculate the following:
                        \
                        \   (XX16+2 K2+2) = sidev_x / z
                        \
                        \   (XX16+3 K2+3) = sidev_y / z

 JMP PLS2               \ Jump to PLS2 to draw the second meridian, returning
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PL9 (Part 3 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw the planet's crater
\  Deep dive: Drawing craters
\
\ ------------------------------------------------------------------------------
\
\ Draw the planet's crater.
\
\ Arguments:
\
\   K(1 0)              The planet's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the planet
\
\   K4(1 0)             Pixel y-coordinate of the centre of the planet
\
\   INWK                The planet's ship data block
\
\ ******************************************************************************

.PL26

 LDA INWK+20            \ Set A = roofv_z_hi

 BMI PL20               \ If A is negative, the crater is on the far side of the
                        \ planet, so return from the subroutine (as PL2
                        \ contains an RTS)

 LDX #15                \ Set X = 15, so the following call to PLS3 operates on
                        \ roofv

 JSR PLS3               \ Call PLS3 to calculate:
                        \
                        \   (Y A P) = 222 * roofv_x / z
                        \
                        \ to give the x-coordinate of the crater offset and
                        \ increment X to point to roofv_y for the next call

 CLC                    \ Calculate:
 ADC K3                 \
 STA K3                 \   K3(1 0) = (Y A) + K3(1 0)
                        \           = 222 * roofv_x / z + x-coordinate of planet
                        \             centre
                        \
                        \ starting with the high bytes

 TYA                    \ And then doing the low bytes, so now K3(1 0) contains
 ADC K3+1               \ the x-coordinate of the crater offset plus the planet
 STA K3+1               \ centre to give the x-coordinate of the crater's centre

 JSR PLS3               \ Call PLS3 to calculate:
                        \
                        \   (Y A P) = 222 * roofv_y / z
                        \
                        \ to give the y-coordinate of the crater offset

 STA P                  \ Calculate:
 LDA K4                 \
 SEC                    \   K4(1 0) = K4(1 0) - (Y A)
 SBC P                  \           = 222 * roofv_x / z - y-coordinate of planet
 STA K4                 \             centre
                        \
                        \ starting with the low bytes

 STY P                  \ And then doing the low bytes, so now K4(1 0) contains
 LDA K4+1               \ the y-coordinate of the crater offset plus the planet
 SBC P                  \ centre to give the y-coordinate of the crater's centre
 STA K4+1

 LDX #9                 \ Set X = 9, so the following call to PLS1 operates on
                        \ nosev

 JSR PLS1               \ Call PLS1 to calculate the following:
                        \
                        \   (Y A) = nosev_x / z
                        \
                        \ and increment X to point to nosev_y for the next call

 LSR A                  \ Set (XX16 K2) = (Y A) / 2
 STA K2
 STY XX16

 JSR PLS1               \ Call PLS1 to calculate the following:
                        \
                        \   (Y A) = nosev_y / z
                        \
                        \ and increment X to point to nosev_z for the next call

 LSR A                  \ Set (XX16+1 K2+1) = (Y A) / 2
 STA K2+1
 STY XX16+1

 LDX #21                \ Set X = 21, so the following call to PLS1 operates on
                        \ sidev

 JSR PLS1               \ Call PLS1 to calculate the following:
                        \
                        \   (Y A) = sidev_x / z
                        \
                        \ and increment X to point to sidev_y for the next call

 LSR A                  \ Set (XX16+2 K2+2) = (Y A) / 2
 STA K2+2
 STY XX16+2

 JSR PLS1               \ Call PLS1 to calculate the following:
                        \
                        \   (Y A) = sidev_y / z
                        \
                        \ and increment X to point to sidev_z for the next call

 LSR A                  \ Set (XX16+3 K2+3) = (Y A) / 2
 STA K2+3
 STY XX16+3

 LDA #64                \ Set TGT = 64, so we draw a full circle in the call to
 STA TGT                \ PLS22 below

 LDA #0                 \ Set CNT2 = 0 as we are drawing a full circle, so we
 STA CNT2               \ don't need to apply an offset

 JMP PLS22              \ Jump to PLS22 to draw the crater, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: PLS1
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Calculate (Y A) = nosev_x / z
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division of a specified value from one of the
\ orientation vectors (in this example, nosev_x):
\
\   (Y A) = nosev_x / z
\
\ where z is the z-coordinate of the planet from INWK. The result is an 8-bit
\ magnitude in A, with maximum value 254, and just a sign bit (bit 7) in Y.
\
\ Arguments:
\
\   X                   Determines which of the INWK orientation vectors to
\                       divide:
\
\                         * X = 9, 11, 13: divides nosev_x, nosev_y, nosev_z
\
\                         * X = 15, 17, 19: divides roofv_x, roofv_y, roofv_z
\
\                         * X = 21, 23, 25: divides sidev_x, sidev_y, sidev_z
\
\   INWK                The planet's ship data block
\
\ Returns:
\
\   A                   The result as an 8-bit magnitude with maximum value 254
\
\   Y                   The sign of the result in bit 7
\
\   K+3                 Also the sign of the result in bit 7
\
\   X                   X gets incremented by 2 so it points to the next
\                       coordinate in this orientation vector (so consecutive
\                       calls to the routine will start with x, then move onto y
\                       and then z)
\
\ ******************************************************************************

.PLS1

 LDA INWK,X             \ Set P = nosev_x_lo
 STA P

 LDA INWK+1,X           \ Set P+1 = |nosev_x_hi|
 AND #%01111111
 STA P+1

 LDA INWK+1,X           \ Set A = sign bit of nosev_x_lo
 AND #%10000000

 JSR DVID3B2            \ Call DVID3B2 to calculate:
                        \
                        \   K(3 2 1 0) = (A P+1 P) / (z_sign z_hi z_lo)

 LDA K                  \ Fetch the lowest byte of the result into A

 LDY K+1                \ Fetch the second byte of the result into Y

 BEQ P%+4               \ If the second byte is 0, skip the next instruction

 LDA #254               \ The second byte is non-zero, so the result won't fit
                        \ into one byte, so set A = 254 as our maximum one-byte
                        \ value to return

 LDY K+3                \ Fetch the sign of the result from K+3 into Y

 INX                    \ Add 2 to X so the index points to the next coordinate
 INX                    \ in this orientation vector (so consecutive calls to
                        \ the routine will start with x, then move onto y and z)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PLS2
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw a half-circle
\
\ ------------------------------------------------------------------------------
\
\ Draw a half-circle, used for the planet's equator and meridian.
\
\ ******************************************************************************

.PLS2

 LDA #31                \ Set TGT = 31, so we only draw half a circle
 STA TGT

                        \ Fall through into PLS22 to draw the half circle

\ ******************************************************************************
\
\       Name: PLS22
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw a circle or half-circle
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle or half-circle, used for the planet's equator and meridian, or
\ crater.
\
\ This routine is called from parts 2 and 3 of PL9, and does the following:
\
\   K6(1 0) = K3(1 0) + (XX16 K2) * cos(CNT2) + (XX16+2 K2+2) * sin(CNT2)
\
\   (T X) = - |XX16+1 K2+1| * cos(CNT2) - |XX16+3 K2+3| * sin(CNT2)
\
\ before calling BLINE to draw a circle segment to these coordinates.
\
\ Arguments:
\
\   K(1 0)              The planet's radius
\
\   INWK                The planet's ship data block
\
\   TGT                 The number of segments to draw:
\
\                         * 32 for a half circle (a meridian)
\
\                         * 64 for a half circle (a crater)
\
\   CNT2                The starting segment for drawing the half-circle
\
\ ******************************************************************************

.PLS22

 LDX #0                 \ Set CNT = 0
 STX CNT

 DEX                    \ Set FLAG = &FF to reset the ball line heap in the call
 STX FLAG               \ to the BLINE routine below

.PLL4

 LDA CNT2               \ Set A = CNT2 mod 32
 AND #31
 TAX

 LDA SNE,X              \ Set Q = sin(CNT2)
 STA Q

 LDA K2+2               \ Set A = K2+2
                        \       = |roofv_x / z|

 JSR FMLTU              \ Set R = A * Q / 256
 STA R                  \       = |roofv_x / z| * sin(CNT2) / 256

 LDA K2+3               \ Set A = K2+2
                        \       = |roofv_y / z|

 JSR FMLTU              \ Set K = A * Q / 256
 STA K                  \       = |roofv_y / z| * sin(CNT2) / 256

 LDX CNT2               \ If CNT2 >= 33 then this sets the C flag, otherwise
 CPX #33                \ it's clear

 LDA #0                 \ Shift the C flag into the sign bit of XX16+5, so:
 ROR A                  \
 STA XX16+5             \   XX16+5 = +ve if CNT2 < 33
                        \            -ve if CNT2 >= 33

 LDA CNT2               \ Set A = (CNT2 + 16) mod 32
 CLC
 ADC #16
 AND #31
 TAX

 LDA SNE,X              \ Set Q = sin(CNT2 + 16)
 STA Q                  \       = cos(CNT2)

 LDA K2+1               \ Set A = K2+1
                        \       = |nosev_y / z|

 JSR FMLTU              \ Set K+2 = A * Q / 256
 STA K+2                \         = |nosev_y / z| * cos(CNT2) / 256

 LDA K2                 \ Set A = K2
                        \       = |nosev_x / z|

 JSR FMLTU              \ Set P = A * Q / 256
 STA P                  \       = |nosev_x / z| * cos(CNT2) / 256

 LDA CNT2               \ If (CNT2 + 15) mod 64 >= 33 then this sets the C flag,
 ADC #15                \ otherwise it's clear
 AND #63
 CMP #33

 LDA #0                 \ Shift the C flag into the sign bit of XX16+4, so:
 ROR A                  \
 STA XX16+4             \   XX16+4 = +ve if (CNT2 + 15) mod 64 < 33,
                        \            -ve if (CNT2 + 15) mod 64 >= 33

 LDA XX16+5             \ Set S = the sign of (roofv_x / z * CNT2 < 33 sign)
 EOR XX16+2
 STA S

 LDA XX16+4             \ Set A = the sign of (nosev_x / z * CNT2 + 15 < 33
 EOR XX16               \ sign)

 JSR ADD                \ Set (A X) = (A P) + (S R)
                        \           =   (nosev_x / z) * cos(CNT2)
                        \             + (roofv_x / z) * sin(CNT2)

 STA T                  \ Store the high byte in T, so the result is now:
                        \
                        \   (T X) =  (nosev_x / z) * cos(CNT2)
                        \           + (roofv_x / z) * sin(CNT2)

 BPL PL42               \ If the result is positive, jump down to PL42

 TXA                    \ The result is negative, so we need to negate the
 EOR #%11111111         \ magnitude using two's complement, first doing the low
 CLC                    \ byte in X
 ADC #1
 TAX

 LDA T                  \ And then the high byte in T, making sure to leave the
 EOR #%01111111         \ sign bit alone
 ADC #0
 STA T

.PL42

 TXA                    \ Set K6(1 0) = K3(1 0) + (T X)
 ADC K3                 \
 STA K6                 \ starting with the low bytes

 LDA T                  \ And then doing the high bytes, so we now get:
 ADC K3+1               \
 STA K6+1               \  K6(1 0) = K3(1 0) + (nosev_x / z) * cos(CNT2)
                        \           + (roofv_x / z) * sin(CNT2)

 LDA K                  \ Set R = K = |roofv_y / z| * sin(CNT2) / 256
 STA R

 LDA XX16+5             \ Set S = the sign of (roofv_y / z * CNT2 < 33 sign)
 EOR XX16+3
 STA S

 LDA K+2                \ Set P = K+2 = |nosev_y / z| * cos(CNT2) / 256
 STA P

 LDA XX16+4             \ Set A = the sign of (nosev_y / z * CNT2 + 15 < 33
 EOR XX16+1             \ sign)

 JSR ADD                \ Set (A X) = (A P) + (S R)
                        \           =   |nosev_y / z| * cos(CNT2)
                        \             + |roofv_y / z| * sin(CNT2)

 EOR #%10000000         \ Store the negated high byte in T, so the result is
 STA T                  \ now:
                        \
                        \   (T X) = - |nosev_y / z| * cos(CNT2)
                        \           - |roofv_y / z| * sin(CNT2)

 BPL PL43               \ If the result is positive, jump down to PL43

 TXA                    \ The result is negative, so we need to negate the
 EOR #%11111111         \ magnitude using two's complement, first doing the low
 CLC                    \ byte in X
 ADC #1
 TAX

 LDA T                  \ And then the high byte in T, making sure to leave the
 EOR #%01111111         \ sign bit alone
 ADC #0
 STA T

.PL43

 JSR BLINE              \ Call BLINE to draw this segment, which also returns
                        \ the updated value of CNT in A

 CMP TGT                \ If CNT > TGT then jump to PL40 to stop drawing the
 BEQ P%+4               \ circle (which is how we draw half-circles)
 BCS PL40

 LDA CNT2               \ Set CNT2 = (CNT2 + STP) mod 64
 CLC
 ADC STP
 AND #63
 STA CNT2

 JMP PLL4               \ Jump back to PLL4 to draw the next segment

.PL40

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SUN (Part 1 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Set up all the variables needed
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ Draw a new sun with radius K at pixel coordinate (K3, K4), removing the old
\ sun if there is one. This routine is used to draw the sun, as well as the
\ star systems on the Short-range Chart.
\
\ The first part sets up all the variables needed to draw the new sun.
\
\ Arguments:
\
\   K                   The new sun's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the new sun
\
\   K4(1 0)             Pixel y-coordinate of the centre of the new sun
\
\   SUNX(1 0)           The x-coordinate of the vertical centre axis of the old
\                       sun (the one currently on-screen)
\
\ ******************************************************************************

 JMP WPLS               \ Jump to WPLS to remove the old sun from the screen. We
                        \ only get here via the BCS just after the SUN entry
                        \ point below, when there is no new sun to draw

.PLF3

                        \ This is called from below to negate X and set A to
                        \ &FF, for when the new sun's centre is off the bottom
                        \ of the screen (so we don't need to draw its bottom
                        \ half)

 TXA                    \ Negate X using two's complement, so X = ~X + 1
 EOR #%11111111         \
 CLC                    \ We do this because X is negative at this point, as it
 ADC #1                 \ is calculated as 191 - the y-coordinate of the sun's
 TAX                    \ centre, and the centre is off the bottom of the
                        \ screen, past 191. So we negate it to make it positive

.PLF17

                        \ This is called from below to set A to &FF, for when
                        \ the new sun's centre is right on the bottom of the
                        \ screen (so we don't need to draw its bottom half)

 LDA #&FF               \ Set A = &FF

 JMP PLF5               \ Jump to PLF5

.SUN

 LDA #1                 \ Set LSX = 1 to indicate the sun line heap is about to
 STA LSX                \ be filled up

 JSR CHKON              \ Call CHKON to check whether any part of the new sun's
                        \ circle appears on-screen, and of it does, set P(2 1)
                        \ to the maximum y-coordinate of the new sun on-screen

 BCS PLF3-3             \ If CHKON set the C flag then the new sun's circle does
                        \ not appear on-screen, so jump to WPLS (via the JMP at
                        \ the top of this routine) to remove the sun from the
                        \ screen, returning from the subroutine using a tail
                        \ call

 LDA #0                 \ Set A = 0

 LDX K                  \ Set X = K = radius of the new sun

 CPX #96                \ If X >= 96, set the C flag and rotate it into bit 0
 ROL A                  \ of A, otherwise rotate a 0 into bit 0

 CPX #40                \ If X >= 40, set the C flag and rotate it into bit 0
 ROL A                  \ of A, otherwise rotate a 0 into bit 0

 CPX #16                \ If X >= 16, set the C flag and rotate it into bit 0
 ROL A                  \ of A, otherwise rotate a 0 into bit 0

                        \ By now, A contains the following:
                        \
                        \   * If radius is 96-255 then A = %111 = 7
                        \
                        \   * If radius is 40-95  then A = %11  = 3
                        \
                        \   * If radius is 16-39  then A = %1   = 1
                        \
                        \   * If radius is 0-15   then A = %0   = 0
                        \
                        \ The value of A determines the size of the new sun's
                        \ ragged fringes - the bigger the sun, the bigger the
                        \ fringes

.PLF18

 STA CNT                \ Store the fringe size in CNT

                        \ We now calculate the highest pixel y-coordinate of the
                        \ new sun, given that P(2 1) contains the 16-bit maximum
                        \ y-coordinate of the new sun on-screen

 LDA #2*Y-1             \ #Y is the y-coordinate of the centre of the space
                        \ view, so this sets Y to the y-coordinate of the bottom
                        \ of the space view, i.e. 191

 LDX P+2                \ If P+2 is non-zero, the maximum y-coordinate is off
 BNE PLF2               \ the bottom of the screen, so skip to PLF2 with A = 191

 CMP P+1                \ If A < P+1, the maximum y-coordinate is underneath the
 BCC PLF2               \ the dashboard, so skip to PLF2 with A = 191

 LDA P+1                \ Set A = P+1, the low byte of the maximum y-coordinate
                        \ of the sun on-screen

 BNE PLF2               \ If A is non-zero, skip to PLF2 as it contains the
                        \ value we are after

 LDA #1                 \ Otherwise set A = 1, the top line of the screen

.PLF2

 STA TGT                \ Set TGT to A, the maximum y-coordinate of the sun on
                        \ screen

                        \ We now calculate the number of lines we need to draw
                        \ and the direction in which we need to draw them, both
                        \ from the centre of the new sun

 LDA #2*Y-1             \ Set (A X) = y-coordinate of bottom of screen - K4(1 0)
 SEC                    \
 SBC K4                 \ Starting with the low bytes
 TAX

 LDA #0                 \ And then doing the high bytes, so (A X) now contains
 SBC K4+1               \ the number of lines between the centre of the sun and
                        \ the bottom of the screen. If it is positive then the
                        \ centre of the sun is above the bottom of the screen,
                        \ if it is negative then the centre of the sun is below
                        \ the bottom of the screen

 BMI PLF3               \ If A < 0, then this means the new sun's centre is off
                        \ the bottom of the screen, so jump up to PLF3 to negate
                        \ the height in X (so it becomes positive), set A to &FF
                        \ and jump down to PLF5

 BNE PLF4               \ If A > 0, then the new sun's centre is at least a full
                        \ screen above the bottom of the space view, so jump
                        \ down to PLF4 to set X = radius and A = 0

 INX                    \ Set the flags depending on the value of X
 DEX

 BEQ PLF17              \ If X = 0 (we already know A = 0 by this point) then
                        \ jump up to PLF17 to set A to &FF before jumping down
                        \ to PLF5

 CPX K                  \ If X < the radius in K, jump down to PLF5, so if
 BCC PLF5               \ X >= the radius in K, we set X = radius and A = 0

.PLF4

 LDX K                  \ Set X to the radius

 LDA #0                 \ Set A = 0

.PLF5

 STX V                  \ Store the height in V

 STA V+1                \ Store the direction in V+1

 LDA K                  \ Set (A P) = K * K
 JSR SQUA2

 STA K2+1               \ Set K2(1 0) = (A P) = K * K
 LDA P
 STA K2

                        \ By the time we get here, the variables should be set
                        \ up as shown in the header for part 3 below

\ ******************************************************************************
\
\       Name: SUN (Part 2 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Start from bottom of screen and erase the old sun
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ This part erases the old sun, starting at the bottom of the screen and working
\ upwards until we reach the bottom of the new sun.
\
\ ******************************************************************************

 LDY #2*Y-1             \ Set Y = y-coordinate of the bottom of the screen,
                        \ which we use as a counter in the following routine to
                        \ redraw the old sun

 LDA SUNX               \ Set YY(1 0) = SUNX(1 0), the x-coordinate of the
 STA YY                 \ vertical centre axis of the old sun that's currently
 LDA SUNX+1             \ on-screen
 STA YY+1

.PLFL2

 CPY TGT                \ If Y = TGT, we have reached the line where we will
 BEQ PLFL               \ start drawing the new sun, so there is no need to
                        \ keep erasing the old one, so jump down to PLFL

 LDA LSO,Y              \ Fetch the Y-th point from the sun line heap, which
                        \ gives us the half-width of the old sun's line on this
                        \ line of the screen

 BEQ PLF13              \ If A = 0, skip the following call to HLOIN2 as there
                        \ is no sun line on this line of the screen

 JSR HLOIN2             \ Call HLOIN2 to draw a horizontal line on pixel line Y,
                        \ with centre point YY(1 0) and half-width A, and remove
                        \ the line from the sun line heap once done

.PLF13

 DEY                    \ Decrement the loop counter

 BNE PLFL2              \ Loop back for the next line in the line heap until
                        \ we have either gone through the entire heap, or
                        \ reached the bottom row of the new sun

\ ******************************************************************************
\
\       Name: SUN (Part 3 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Continue to move up the screen, drawing the new sun
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ This part draws the new sun. By the time we get to this point, the following
\ variables should have been set up by parts 1 and 2:
\
\   V                   As we draw lines for the new sun, V contains the
\                       vertical distance between the line we're drawing and the
\                       centre of the new sun. As we draw lines and move up the
\                       screen, we either decrement (bottom half) or increment
\                       (top half) this value. See the deep dive on "Drawing the
\                       sun" to see a diagram that shows V in action
\
\   V+1                 This determines which half of the new sun we are drawing
\                       as we work our way up the screen, line by line:
\
\                         * 0 means we are drawing the bottom half, so the lines
\                           get wider as we work our way up towards the centre,
\                           at which point we will move into the top half, and
\                           V+1 will switch to &FF
\
\                         * &FF means we are drawing the top half, so the lines
\                           get smaller as we work our way up, away from the
\                           centre
\
\   TGT                 The maximum y-coordinate of the new sun on-screen (i.e.
\                       the screen y-coordinate of the bottom row of the new
\                       sun)
\
\   CNT                 The fringe size of the new sun
\
\   K2(1 0)             The new sun's radius squared, i.e. K^2
\
\   Y                   The y-coordinate of the bottom row of the new sun
\
\ ******************************************************************************

.PLFL

 LDA V                  \ Set (T P) = V * V
 JSR SQUA2              \           = V^2
 STA T

 LDA K2                 \ Set (R Q) = K^2 - V^2
 SEC                    \
 SBC P                  \ First calculating the low bytes
 STA Q

 LDA K2+1               \ And then doing the high bytes
 SBC T
 STA R

 STY Y1                 \ Store Y in Y1, so we can restore it after the call to
                        \ LL5

 JSR LL5                \ Set Q = SQRT(R Q)
                        \       = SQRT(K^2 - V^2)
                        \
                        \ So Q contains the half-width of the new sun's line at
                        \ height V from the sun's centre - in other words, it
                        \ contains the half-width of the sun's line on the
                        \ current pixel row Y

 LDY Y1                 \ Restore Y from Y1

 JSR DORND              \ Set A and X to random numbers

 AND CNT                \ Reduce A to a random number in the range 0 to CNT,
                        \ where CNT is the fringe size of the new sun

 CLC                    \ Set A = A + Q
 ADC Q                  \
                        \ So A now contains the half-width of the sun on row
                        \ V, plus a random variation based on the fringe size

 BCC PLF44              \ If the above addition did not overflow, skip the
                        \ following instruction

 LDA #255               \ The above overflowed, so set the value of A to 255

                        \ So A contains the half-width of the new sun on pixel
                        \ line Y, changed by a random amount within the size of
                        \ the sun's fringe

.PLF44

 LDX LSO,Y              \ Set X to the line heap value for the old sun's line
                        \ at row Y

 STA LSO,Y              \ Store the half-width of the new row Y line in the line
                        \ heap

 BEQ PLF11              \ If X = 0 then there was no sun line on pixel row Y, so
                        \ jump to PLF11

 LDA SUNX               \ Set YY(1 0) = SUNX(1 0), the x-coordinate of the
 STA YY                 \ vertical centre axis of the old sun that's currently
 LDA SUNX+1             \ on-screen
 STA YY+1

 TXA                    \ Transfer the line heap value for the old sun's line
                        \ from X into A

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A, i.e.
                        \ the line for the old sun

 LDA X1                 \ Store X1 and X2, the ends of the line for the old sun,
 STA XX                 \ in XX and XX+1
 LDA X2
 STA XX+1

 LDA K3                 \ Set YY(1 0) = K3(1 0), the x-coordinate of the centre
 STA YY                 \ of the new sun
 LDA K3+1
 STA YY+1

 LDA LSO,Y              \ Fetch the half-width of the new row Y line from the
                        \ line heap (which we stored above)

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A, i.e.
                        \ the line for the new sun

 BCS PLF23              \ If the C flag is set, the new line doesn't fit on the
                        \ screen, so jump to PLF23 to just draw the old line
                        \ without drawing the new one

                        \ At this point the old line is from XX to XX+1 and the
                        \ new line is from X1 to X2, and both fit on-screen. We
                        \ now want to remove the old line and draw the new one.
                        \ We could do this by simply drawing the old one then
                        \ drawing the new one, but instead Elite does this by
                        \ drawing first from X1 to XX and then from X2 to XX+1,
                        \ which you can see in action by looking at all the
                        \ permutations below of the four points on the line and
                        \ imagining what happens if you draw from X1 to XX and
                        \ X2 to XX+1 using EOR logic. The six possible
                        \ permutations are as follows, along with the result of
                        \ drawing X1 to XX and then X2 to XX+1:
                        \
                        \   X1    X2    XX____XX+1      ->      +__+  +  +
                        \
                        \   X1    XX____X2____XX+1      ->      +__+__+  +
                        \
                        \   X1    XX____XX+1  X2        ->      +__+__+__+
                        \
                        \   XX____X1____XX+1  X2        ->      +  +__+__+
                        \
                        \   XX____XX+1  X1    X2        ->      +  +  +__+
                        \
                        \   XX____X1____X2____XX+1      ->      +  +__+  +
                        \
                        \ They all end up with a line between X1 and X2, which
                        \ is what we want. There's probably a mathematical proof
                        \ of why this works somewhere, but the above is probably
                        \ easier to follow.
                        \
                        \ We can draw from X1 to XX and X2 to XX+1 by swapping
                        \ XX and X2 and drawing from X1 to X2, and then drawing
                        \ from XX to XX+1, so let's do this now

 LDA X2                 \ Swap XX and X2
 LDX XX
 STX X2
 STA XX

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1)

.PLF23

                        \ If we jump here from the BCS above when there is no
                        \ new line this will just draw the old line

 LDA XX                 \ Set X1 = XX
 STA X1

 LDA XX+1               \ Set X2 = XX+1
 STA X2

.PLF16

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1)

.PLF6

 DEY                    \ Decrement the line number in Y to move to the line
                        \ above

 BEQ PLF8               \ If we have reached the top of the screen, jump to PLF8
                        \ as we are done drawing (the top line of the screen is
                        \ the border, so we don't draw there)

 LDA V+1                \ If V+1 is non-zero then we are doing the top half of
 BNE PLF10              \ the new sun, so jump down to PLF10 to increment V and
                        \ decrease the width of the line we draw

 DEC V                  \ Decrement V, the height of the sun that we use to work
                        \ out the width, so this makes the line get wider, as we
                        \ move up towards the sun's centre

 BNE PLFL               \ If V is non-zero, jump back up to PLFL to do the next
                        \ screen line up

 DEC V+1                \ Otherwise V is 0 and we have reached the centre of the
                        \ sun, so decrement V+1 to -1 so we start incrementing V
                        \ each time, thus doing the top half of the new sun

.PLFLS

 JMP PLFL               \ Jump back up to PLFL to do the next screen line up

.PLF11

                        \ If we get here then there is no old sun line on this
                        \ line, so we can just draw the new sun's line. The new

 LDX K3                 \ Set YY(1 0) = K3(1 0), the x-coordinate of the centre
 STX YY                 \ of the new sun's line
 LDX K3+1
 STX YY+1

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A, i.e.
                        \ the line for the new sun

 BCC PLF16              \ If the line is on-screen, jump up to PLF16 to draw the
                        \ line and loop round for the next line up

 LDA #0                 \ The line is not on-screen, so set the line heap for
 STA LSO,Y              \ line Y to 0, which means there is no sun line here

 BEQ PLF6               \ Jump up to PLF6 to loop round for the next line up
                        \ (this BEQ is effectively a JMP as A is always zero)

.PLF10

 LDX V                  \ Increment V, the height of the sun that we use to work
 INX                    \ out the width, so this makes the line get narrower, as
 STX V                  \ we move up and away from the sun's centre

 CPX K                  \ If V <= the radius of the sun, we still have lines to
 BCC PLFLS              \ draw, so jump up to PLFL (via PLFLS) to do the next
 BEQ PLFLS              \ screen line up

\ ******************************************************************************
\
\       Name: SUN (Part 4 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Continue to the top of the screen, erasing old sun
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ This part erases any remaining traces of the old sun, now that we have drawn
\ all the way to the top of the new sun.
\
\ Other entry points:
\
\   RTS2                Contains an RTS
\
\ ******************************************************************************

 LDA SUNX               \ Set YY(1 0) = SUNX(1 0), the x-coordinate of the
 STA YY                 \ vertical centre axis of the old sun that's currently
 LDA SUNX+1             \ on-screen
 STA YY+1

.PLFL3

 LDA LSO,Y              \ Fetch the Y-th point from the sun line heap, which
                        \ gives us the half-width of the old sun's line on this
                        \ line of the screen

 BEQ PLF9               \ If A = 0, skip the following call to HLOIN2 as there
                        \ is no sun line on this line of the screen

 JSR HLOIN2             \ Call HLOIN2 to draw a horizontal line on pixel line Y,
                        \ with centre point YY(1 0) and half-width A, and remove
                        \ the line from the sun line heap once done

.PLF9

 DEY                    \ Decrement the line number in Y to move to the line
                        \ above

 BNE PLFL3              \ Jump up to PLFL3 to redraw the next line up, until we
                        \ have reached the top of the screen

.PLF8

                        \ If we get here, we have successfully made it from the
                        \ bottom line of the screen to the top, and the old sun
                        \ has been replaced by the new one

 CLC                    \ Clear the C flag to indicate success in drawing the
                        \ sun

 LDA K3                 \ Set SUNX(1 0) = K3(1 0)
 STA SUNX
 LDA K3+1
 STA SUNX+1

.RTS2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CIRCLE
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle for the planet
\  Deep dive: Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with the centre at (K3, K4) and radius K. Used to draw the
\ planet's main outline.
\
\ Arguments:
\
\   K                   The planet's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the planet
\
\   K4(1 0)             Pixel y-coordinate of the centre of the planet
\
\ ******************************************************************************

.CIRCLE

 JSR CHKON              \ Call CHKON to check whether the circle fits on-screen

 BCS RTS2               \ If CHKON set the C flag then the circle does not fit
                        \ on-screen, so return from the subroutine (as RTS2
                        \ contains an RTS)

 LDA #0                 \ Set LSX2 = 0
 STA LSX2

 LDX K                  \ Set X = K = radius

 LDA #8                 \ Set A = 8

 CPX #8                 \ If the radius < 8, skip to PL89
 BCC PL89

 LSR A                  \ Halve A so A = 4

 CPX #60                \ If the radius < 60, skip to PL89
 BCC PL89

 LSR A                  \ Halve A so A = 2

.PL89

 STA STP                \ Set STP = A. STP is the step size for the circle, so
                        \ the above sets a smaller step size for bigger circles

                        \ Fall through into CIRCLE2 to draw the circle with the
                        \ correct step size

\ ******************************************************************************
\
\       Name: CIRCLE2
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle (for the planet or chart)
\  Deep dive: Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with the centre at (K3, K4) and radius K. Used to draw the
\ planet and the chart circles.
\
\ Arguments:
\
\   STP                 The step size for the circle
\
\   K                   The circle's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the circle
\
\   K4(1 0)             Pixel y-coordinate of the centre of the circle
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.CIRCLE2

 LDX #&FF               \ Set FLAG = &FF to reset the ball line heap in the call
 STX FLAG               \ to the BLINE routine below

 INX                    \ Set CNT = 0, our counter that goes up to 64, counting
 STX CNT                \ segments in our circle

.PLL3

 LDA CNT                \ Set A = CNT

 JSR FMLTU2             \ Call FMLTU2 to calculate:
                        \
                        \   A = K * sin(A)
                        \     = K * sin(CNT)

 LDX #0                 \ Set T = 0, so we have the following:
 STX T                  \
                        \   (T A) = K * sin(CNT)
                        \
                        \ which is the x-coordinate of the circle for this count

 LDX CNT                \ If CNT < 33 then jump to PL37, as this is the right
 CPX #33                \ half of the circle and the sign of the x-coordinate is
 BCC PL37               \ correct

 EOR #%11111111         \ This is the left half of the circle, so we want to
 ADC #0                 \ flip the sign of the x-coordinate in (T A) using two's
 TAX                    \ complement, so we start with the low byte and store it
                        \ in X (the ADC adds 1 as we know the C flag is set)

 LDA #&FF               \ And then we flip the high byte in T
 ADC #0
 STA T

 TXA                    \ Finally, we restore the low byte from X, so we have
                        \ now negated the x-coordinate in (T A)

 CLC                    \ Clear the C flag so we can do some more addition below

.PL37

 ADC K3                 \ We now calculate the following:
 STA K6                 \
                        \   K6(1 0) = (T A) + K3(1 0)
                        \
                        \ to add the coordinates of the centre to our circle
                        \ point, starting with the low bytes

 LDA K3+1               \ And then doing the high bytes, so we now have:
 ADC T                  \
 STA K6+1               \   K6(1 0) = K * sin(CNT) + K3(1 0)
                        \
                        \ which is the result we want for the x-coordinate

 LDA CNT                \ Set A = CNT + 16
 CLC
 ADC #16

 JSR FMLTU2             \ Call FMLTU2 to calculate:
                        \
                        \   A = K * sin(A)
                        \     = K * sin(CNT + 16)
                        \     = K * cos(CNT)

 TAX                    \ Set X = A
                        \       = K * cos(CNT)

 LDA #0                 \ Set T = 0, so we have the following:
 STA T                  \
                        \   (T X) = K * cos(CNT)
                        \
                        \ which is the y-coordinate of the circle for this count

 LDA CNT                \ Set A = (CNT + 15) mod 64
 ADC #15
 AND #63

 CMP #33                \ If A < 33 (i.e. CNT is 0-16 or 48-64) then jump to
 BCC PL38               \ PL38, as this is the bottom half of the circle and the
                        \ sign of the y-coordinate is correct

 TXA                    \ This is the top half of the circle, so we want to
 EOR #%11111111         \ flip the sign of the y-coordinate in (T X) using two's
 ADC #0                 \ complement, so we start with the low byte in X (the
 TAX                    \ ADC adds 1 as we know the C flag is set)

 LDA #&FF               \ And then we flip the high byte in T, so we have
 ADC #0                 \ now negated the y-coordinate in (T X)
 STA T

 CLC                    \ Clear the C flag so we can do some more addition below

.PL38

 JSR BLINE              \ Call BLINE to draw this segment, which also increases
                        \ CNT by STP, the step size

 CMP #65                \ If CNT >= 65 then skip the next instruction
 BCS P%+5

 JMP PLL3               \ Jump back for the next segment

 CLC                    \ Clear the C flag to indicate success

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: WPLS2
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Remove the planet from the screen
\  Deep dive: The ball line heap
\
\ ------------------------------------------------------------------------------
\
\ We do this by redrawing it using the lines stored in the ball line heap when
\ the planet was originally drawn by the BLINE routine.
\
\ ******************************************************************************

.WPLS2

 LDY LSX2               \ If LSX2 is non-zero (which indicates the ball line
 BNE WP1                \ heap is empty), jump to WP1 to reset the line heap
                        \ without redrawing the planet

                        \ Otherwise Y is now 0, so we can use it as a counter to
                        \ loop through the lines in the line heap, redrawing
                        \ each one to remove the planet from the screen, before
                        \ resetting the line heap once we are done

.WPL1

 CPY LSP                \ If Y >= LSP then we have reached the end of the line
 BCS WP1                \ heap and have finished redrawing the planet (as LSP
                        \ points to the end of the heap), so jump to WP1 to
                        \ reset the line heap, returning from the subroutine
                        \ using a tail call

 LDA LSY2,Y             \ Set A to the y-coordinate of the current heap entry

 CMP #&FF               \ If the y-coordinate is &FF, this indicates that the
 BEQ WP2                \ next point in the heap denotes the start of a line
                        \ segment, so jump to WP2 to put it into (X1, Y1)

 STA Y2                 \ Set (X2, Y2) to the x- and y-coordinates from the
 LDA LSX2,Y             \ heap
 STA X2

 JSR LOIN               \ Draw a line from (X1, Y1) to (X2, Y2)

 INY                    \ Increment the loop counter to point to the next point

 LDA SWAP               \ If SWAP is non-zero then we swapped the coordinates
 BNE WPL1               \ when filling the heap in BLINE, so loop back WPL1
                        \ for the next point in the heap

 LDA X2                 \ Swap (X1, Y1) and (X2, Y2), so the next segment will
 STA X1                 \ be drawn from the current (X2, Y2) to the next point
 LDA Y2                 \ in the heap
 STA Y1

 JMP WPL1               \ Loop back to WPL1 for the next point in the heap

.WP2

 INY                    \ Increment the loop counter to point to the next point

 LDA LSX2,Y             \ Set (X1, Y1) to the x- and y-coordinates from the
 STA X1                 \ heap
 LDA LSY2,Y
 STA Y1

 INY                    \ Increment the loop counter to point to the next point

 JMP WPL1               \ Loop back to WPL1 for the next point in the heap

\ ******************************************************************************
\
\       Name: WP1
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Reset the ball line heap
\
\ ******************************************************************************

.WP1

 LDA #1                 \ Set LSP = 1 to reset the ball line heap pointer
 STA LSP

 LDA #&FF               \ Set LSX2 = &FF to indicate the ball line heap is empty
 STA LSX2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: WPLS
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Remove the sun from the screen
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ We do this by redrawing it using the lines stored in the sun line heap when
\ the sun was originally drawn by the SUN routine.
\
\ Arguments:
\
\   SUNX(1 0)           The x-coordinate of the vertical centre axis of the sun
\
\ Other entry points:
\
\   WPLS-1              Contains an RTS
\
\ ******************************************************************************

.WPLS

 LDA LSX                \ If LSX < 0, the sun line heap is empty, so return from
 BMI WPLS-1             \ the subroutine (as WPLS-1 contains an RTS)

 LDA SUNX               \ Set YY(1 0) = SUNX(1 0), the x-coordinate of the
 STA YY                 \ vertical centre axis of the sun that's currently on
 LDA SUNX+1             \ screen
 STA YY+1

 LDY #2*Y-1             \ #Y is the y-coordinate of the centre of the space
                        \ view, so this sets Y as a counter for the number of
                        \ lines in the space view (i.e. 191), which is also the
                        \ number of lines in the LSO block

.WPL2

 LDA LSO,Y              \ Fetch the Y-th point from the sun line heap, which
                        \ gives us the half-width of the sun's line on this line
                        \ of the screen

 BEQ P%+5               \ If A = 0, skip the following call to HLOIN2 as there
                        \ is no sun line on this line of the screen

 JSR HLOIN2             \ Call HLOIN2 to draw a horizontal line on pixel line Y,
                        \ with centre point YY(1 0) and half-width A, and remove
                        \ the line from the sun line heap once done

 DEY                    \ Decrement the loop counter

 BNE WPL2               \ Loop back for the next line in the line heap until
                        \ we have gone through the entire heap

 DEY                    \ This sets Y to &FF, as we end the loop with Y = 0

 STY LSX                \ Set LSX to &FF to indicate the sun line heap is empty

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: EDGES
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line given a centre and a half-width
\
\ ------------------------------------------------------------------------------
\
\ Set X1 and X2 to the x-coordinates of the ends of the horizontal line with
\ centre x-coordinate YY(1 0), and length A in either direction from the centre
\ (so a total line length of 2 * A). In other words, this line:
\
\   X1             YY(1 0)             X2
\   +-----------------+-----------------+
\         <- A ->           <- A ->
\
\ The resulting line gets clipped to the edges of the screen, if needed. If the
\ calculation doesn't overflow, we return with the C flag clear, otherwise the C
\ flag gets set to indicate failure and the Y-th LSO entry gets set to 0.
\
\ Arguments:
\
\   A                   The half-length of the line
\
\   YY(1 0)             The centre x-coordinate
\
\ Returns:
\
\   C flag              Clear if the line fits on-screen, set if it doesn't
\
\   X1, X2              The x-coordinates of the clipped line
\
\   LSO+Y               If the line doesn't fit, LSO+Y is set to 0
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.EDGES

 STA T                  \ Set T to the line's half-length in argument A

 CLC                    \ We now calculate:
 ADC YY                 \
 STA X2                 \  (A X2) = YY(1 0) + A
                        \
                        \ to set X2 to the x-coordinate of the right end of the
                        \ line, starting with the low bytes

 LDA YY+1               \ And then adding the high bytes
 ADC #0

 BMI ED1                \ If the addition is negative then the calculation has
                        \ overflowed, so jump to ED1 to return a failure

 BEQ P%+6               \ If the high byte A from the result is 0, skip the
                        \ next two instructions, as the result already fits on
                        \ the screen

 LDA #254               \ The high byte is positive and non-zero, so we went
 STA X2                 \ past the right edge of the screen, so clip X2 to the
                        \ x-coordinate of the right edge of the screen

 LDA YY                 \ We now calculate:
 SEC                    \
 SBC T                  \   (A X1) = YY(1 0) - argument A
 STA X1                 \
                        \ to set X1 to the x-coordinate of the left end of the
                        \ line, starting with the low bytes

 LDA YY+1               \ And then subtracting the high bytes
 SBC #0

 BNE ED3                \ If the high byte subtraction is non-zero, then skip
                        \ to ED3

 CLC                    \ Otherwise the high byte of the subtraction was zero,
                        \ so the line fits on-screen and we clear the C flag to
                        \ indicate success

 RTS                    \ Return from the subroutine

.ED3

 BPL ED1                \ If the addition is positive then the calculation has
                        \ underflowed, so jump to ED1 to return a failure

 LDA #2                 \ The high byte is negative and non-zero, so we went
 STA X1                 \ past the left edge of the screen, so clip X1 to the
                        \ y-coordinate of the left edge of the screen

 CLC                    \ The line does fit on-screen, so clear the C flag to
                        \ indicate success

 RTS                    \ Return from the subroutine

.ED1

 LDA #0                 \ Set the Y-th byte of the LSO block to 0
 STA LSO,Y

 SEC                    \ The line does not fit on the screen, so set the C flag
                        \ to indicate this result

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CHKON
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Check whether any part of a circle appears on the extended screen
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   K                   The circle's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the circle
\
\   K4(1 0)             Pixel y-coordinate of the centre of the circle
\
\ Returns:
\
\   C flag              Clear if any part of the circle appears on-screen, set
\                       if none of the circle appears on-screen
\
\   (A X)               Minimum y-coordinate of the circle on-screen (i.e. the
\                       y-coordinate of the top edge of the circle)
\
\   P(2 1)              Maximum y-coordinate of the circle on-screen (i.e. the
\                       y-coordinate of the bottom edge of the circle)
\
\ ******************************************************************************

.CHKON

 LDA K3                 \ Set A = K3 + K
 CLC
 ADC K

 LDA K3+1               \ Set A = K3+1 + 0 + any carry from above, so this
 ADC #0                 \ effectively sets A to the high byte of K3(1 0) + K:
                        \
                        \   (A ?) = K3(1 0) + K
                        \
                        \ so A is the high byte of the x-coordinate of the right
                        \ edge of the circle

 BMI PL21               \ If A is negative then the right edge of the circle is
                        \ to the left of the screen, so jump to PL21 to set the
                        \ C flag and return from the subroutine, as the whole
                        \ circle is off-screen to the left

 LDA K3                 \ Set A = K3 - K
 SEC
 SBC K

 LDA K3+1               \ Set A = K3+1 - 0 - any carry from above, so this
 SBC #0                 \ effectively sets A to the high byte of K3(1 0) - K:
                        \
                        \   (A ?) = K3(1 0) - K
                        \
                        \ so A is the high byte of the x-coordinate of the left
                        \ edge of the circle

 BMI PL31               \ If A is negative then the left edge of the circle is
                        \ to the left of the screen, and we already know the
                        \ right edge is either on-screen or off-screen to the
                        \ right, so skip to PL31 to move on to the y-coordinate
                        \ checks, as at least part of the circle is on-screen in
                        \ terms of the x-axis

 BNE PL21               \ If A is non-zero, then the left edge of the circle is
                        \ to the right of the screen, so jump to PL21 to set the
                        \ C flag and return from the subroutine, as the whole
                        \ circle is off-screen to the right

.PL31

 LDA K4                 \ Set P+1 = K4 + K
 CLC
 ADC K
 STA P+1

 LDA K4+1               \ Set A = K4+1 + 0 + any carry from above, so this
 ADC #0                 \ does the following:
                        \
                        \   (A P+1) = K4(1 0) + K
                        \
                        \ so A is the high byte of the y-coordinate of the
                        \ bottom edge of the circle

 BMI PL21               \ If A is negative then the bottom edge of the circle is
                        \ above the top of the screen, so jump to PL21 to set
                        \ the C flag and return from the subroutine, as the
                        \ whole circle is off-screen to the top

 STA P+2                \ Store the high byte in P+2, so now we have:
                        \
                        \   P(2 1) = K4(1 0) + K
                        \
                        \ i.e. the maximum y-coordinate of the circle on-screen
                        \ (which we return)

 LDA K4                 \ Set X = K4 - K
 SEC
 SBC K
 TAX

 LDA K4+1               \ Set A = K4+1 - 0 - any carry from above, so this
 SBC #0                 \ does the following:
                        \
                        \   (A X) = K4(1 0) - K
                        \
                        \ so A is the high byte of the y-coordinate of the top
                        \ edge of the circle

 BMI PL44               \ If A is negative then the top edge of the circle is
                        \ above the top of the screen, and we already know the
                        \ bottom edge is either on-screen or below the bottom
                        \ of the screen, so skip to PL44 to clear the C flag and
                        \ return from the subroutine using a tail call, as part
                        \ of the circle definitely appears on-screen

 BNE PL21               \ If A is non-zero, then the top edge of the circle is
                        \ below the bottom of the screen, so jump to PL21 to set
                        \ the C flag and return from the subroutine, as the
                        \ whole circle is off-screen to the bottom

 CPX #2*Y-1             \ If we get here then A is zero, which means the top
                        \ edge of the circle is within the screen boundary, so
                        \ now we need to check whether it is in the space view
                        \ (in which case it is on-screen) or the dashboard (in
                        \ which case the top of the circle is hidden by the
                        \ dashboard, so the circle isn't on-screen). We do this
                        \ by checking the low byte of the result in X against
                        \ 2 * #Y - 1, and returning the C flag from this
                        \ comparison. The constant #Y is the y-coordinate of the
                        \ mid-point of the space view, so 2 * #Y - 1 is 191, the
                        \ y-coordinate of the bottom pixel row of the space
                        \ view. So this does the following:
                        \
                        \   * The C flag is set if coordinate (A X) is below the
                        \     bottom row of the space view, i.e. the top edge of
                        \     the circle is hidden by the dashboard
                        \
                        \   * The C flag is clear if coordinate (A X) is above
                        \     the bottom row of the space view, i.e. the top
                        \     edge of the circle is on-screen

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PL21
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Return from a planet/sun-drawing routine with a failure flag
\
\ ------------------------------------------------------------------------------
\
\ Set the C flag and return from the subroutine. This is used to return from a
\ planet- or sun-drawing routine with the C flag indicating an overflow in the
\ calculation.
\
\ ******************************************************************************

.PL21

 SEC                    \ Set the C flag to indicate an overflow

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PLS3
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Calculate (Y A P) = 222 * roofv_x / z
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following, with X determining the vector to use:
\
\   (Y A P) = 222 * roofv_x / z
\
\ though in reality only (Y A) is used.
\
\ Although the code below supports a range of values of X, in practice the
\ routine is only called with X = 15, and then again after X has been
\ incremented to 17. So the values calculated by PLS1 use roofv_x first, then
\ roofv_y. The comments below refer to roofv_x, for the first call.
\
\ Arguments:
\
\   X                   Determines which of the INWK orientation vectors to
\                       divide:
\
\                         * X = 15: divides roofv_x
\
\                         * X = 17: divides roofv_y
\
\ Returns:
\
\   X                   X gets incremented by 2 so it points to the next
\                       coordinate in this orientation vector (so consecutive
\                       calls to the routine will start with x, then move onto y
\                       and then z)
\
\ ******************************************************************************

.PLS3

 JSR PLS1               \ Call PLS1 to calculate the following:
 STA P                  \
                        \   P = |roofv_x / z|
                        \   K+3 = sign of roofv_x / z
                        \
                        \ and increment X to point to roofv_y for the next call

 LDA #222               \ Set Q = 222, the offset to the crater
 STA Q

 STX U                  \ Store the vector index X in U for retrieval after the
                        \ call to MULTU

 JSR MULTU              \ Call MULTU to calculate
                        \
                        \   (A P) = P * Q
                        \         = 222 * |roofv_x / z|

 LDX U                  \ Restore the vector index from U into X

 LDY K+3                \ If the sign of the result in K+3 is positive, skip to
 BPL PL12               \ PL12 to return with Y = 0

 EOR #&FF               \ Otherwise the result should be negative, so negate the
 CLC                    \ high byte of the result using two's complement with
 ADC #1                 \ A = ~A + 1

 BEQ PL12               \ If A = 0, jump to PL12 to return with (Y A) = 0

 LDY #&FF               \ Set Y = &FF to be a negative high byte

 RTS                    \ Return from the subroutine

.PL12

 LDY #0                 \ Set Y = 0 to be a positive high byte

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PLS4
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Calculate CNT2 = arctan(P / A) / 4
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   CNT2 = arctan(P / A) / 4
\
\ giving the result the opposite sign to nosev_z_hi. This is called with the
\ following arguments when calculating the equator and meridian for planets:
\
\   * A = roofv_z_hi, P = -nosev_z_hi
\
\   * A = sidev_z_hi, P = -nosev_z_hi
\
\ So it calculates the angle between the planet's orientation vectors, in the
\ z-axis.
\
\ ******************************************************************************

.PLS4

 STA Q                  \ Set Q = A

 JSR ARCTAN             \ Call ARCTAN to calculate:
                        \
                        \   A = arctan(P / Q)
                        \       arctan(P / A)

 LDX INWK+14            \ If nosev_z_hi is negative, skip the following
 BMI P%+4               \ instruction

 EOR #%10000000         \ nosev_z_hi is positive, so make the arctan negative

 LSR A                  \ Set CNT2 = A / 4
 LSR A
 STA CNT2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PLS5
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Calculate roofv_x / z and roofv_y / z
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following divisions of a specified value from one of the
\ orientation vectors (in this example, roofv):
\
\   (XX16+2 K2+2) = roofv_x / z
\
\   (XX16+3 K2+3) = roofv_y / z
\
\ Arguments:
\
\   X                   Determines which of the INWK orientation vectors to
\                       divide:
\
\                         * X = 15: divides roofv_x and roofv_y
\
\                         * X = 21: divides sidev_x and sidev_y
\
\   INWK                The planet's ship data block
\
\ ******************************************************************************

.PLS5

 JSR PLS1               \ Call PLS1 to calculate the following:
 STA K2+2               \
 STY XX16+2             \   K+2    = |roofv_x / z|
                        \   XX16+2 = sign of roofv_x / z
                        \
                        \ i.e. (XX16+2 K2+2) = roofv_x / z
                        \
                        \ and increment X to point to roofv_y for the next call

 JSR PLS1               \ Call PLS1 to calculate the following:
 STA K2+3               \
 STY XX16+3             \   K+3    = |roofv_y / z|
                        \   XX16+3 = sign of roofv_y / z
                        \
                        \ i.e. (XX16+3 K2+3) = roofv_y / z
                        \
                        \ and increment X to point to roofv_z for the next call

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PLS6
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Calculate (X K) = (A P) / (z_sign z_hi z_lo)
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   (X K) = (A P) / (z_sign z_hi z_lo)
\
\ returning an overflow in the C flag if the result is >= 1024.
\
\ Arguments:
\
\   INWK                The planet or sun's ship data block
\
\ Returns:
\
\   C flag              Set if the result >= 1024, clear otherwise
\
\ Other entry points:
\
\   PL44                Clear the C flag and return from the subroutine
\
\ ******************************************************************************

.PLS6

 JSR DVID3B2            \ Call DVID3B2 to calculate:
                        \
                        \   K(3 2 1 0) = (A P+1 P) / (z_sign z_hi z_lo)

 LDA K+3                \ Set A = |K+3| OR K+2
 AND #%01111111
 ORA K+2

 BNE PL21               \ If A is non-zero then the two high bytes of K(3 2 1 0)
                        \ are non-zero, so jump to PL21 to set the C flag and
                        \ return from the subroutine

                        \ We can now just consider K(1 0), as we know the top
                        \ two bytes of K(3 2 1 0) are both 0

 LDX K+1                \ Set X = K+1, so now (X K) contains the result in
                        \ K(1 0), which is the format we want to return the
                        \ result in

 CPX #4                 \ If the high byte of K(1 0) >= 4 then the result is
 BCS PL6                \ >= 1024, so return from the subroutine with the C flag
                        \ set to indicate an overflow (as PL6 contains an RTS)

 LDA K+3                \ Fetch the sign of the result from K+3 (which we know
                        \ has zeroes in bits 0-6, so this just fetches the sign)

\CLC                    \ This instruction is commented out in the original
                        \ source. It would have no effect as we know the C flag
                        \ is already clear, as we skipped past the BCS above

 BPL PL6                \ If the sign bit is clear and the result is positive,
                        \ then the result is already correct, so return from
                        \ the subroutine with the C flag clear to indicate
                        \ success (as PL6 contains an RTS)

 LDA K                  \ Otherwise we need to negate the result, which we do
 EOR #%11111111         \ using two's complement, starting with the low byte:
 ADC #1                 \
 STA K                  \   K = ~K + 1

 TXA                    \ And then the high byte:
 EOR #%11111111         \
 ADC #0                 \   X = ~X
 TAX

.PL44

 CLC                    \ Clear the C flag to indicate success

.PL6

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT17
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard for cursor key or joystick movement
\
\ ------------------------------------------------------------------------------
\
\ Scan the keyboard and joystick for cursor key or stick movement, and return
\ the result as deltas (changes) in x- and y-coordinates as follows:
\
\   * For joystick, X and Y are integers between -2 and +2 depending on how far
\     the stick has moved
\
\   * For keyboard, X and Y are integers between -1 and +1 depending on which
\     keys are pressed
\
\ Returns:
\
\   A                   The key pressed, if the arrow keys were used
\
\   X                   Change in the x-coordinate according to the cursor keys
\                       being pressed or joystick movement, as an integer (see
\                       above)
\
\   Y                   Change in the y-coordinate according to the cursor keys
\                       being pressed or joystick movement, as an integer (see
\                       above)
\
\ ******************************************************************************

.TT17

 JSR DOKEY              \ Scan the keyboard for flight controls and pause keys,
                        \ (or the equivalent on joystick) and update the key
                        \ logger, setting KL to the key pressed

 LDA JSTK               \ If the joystick is not configured, jump down to TJ1,
 BEQ TJ1                \ otherwise we move the cursor with the joystick

 LDA JSTX               \ Fetch the joystick roll, ranging from 1 to 255 with
                        \ 128 as the centre point

 EOR #&FF               \ Flip the sign so A = -JSTX, because the joystick roll
                        \ works in the opposite way to moving a cursor on-screen
                        \ in terms of left and right

 JSR TJS1               \ Call TJS1 just below to set A to a value between -2
                        \ and +2 depending on the joystick roll value (moving
                        \ the stick sideways)

 TYA                    \ Copy Y to A

 TAX                    \ Copy A to X, so X contains the joystick roll value

 LDA JSTY               \ Fetch the joystick pitch, ranging from 1 to 255 with
                        \ 128 as the centre point, and fall through into TJS1 to
                        \ set Y to the joystick pitch value (moving the stick up
                        \ and down)

.TJS1

 TAY                    \ Store A in Y

 LDA #0                 \ Set the result, A = 0

 CPY #16                \ If Y >= 16 set the C flag, so A = A - 1
 SBC #0

\CPY #&20               \ These instructions are commented out in the original
\SBC #0                 \ source, but they would make the joystick move the
                        \ cursor faster by increasing the range of Y by -1 to +1

 CPY #64                \ If Y >= 64 set the C flag, so A = A - 1
 SBC #0

 CPY #192               \ If Y >= 192 set the C flag, so A = A + 1
 ADC #0

 CPY #224               \ If Y >= 224 set the C flag, so A = A + 1
 ADC #0

\CPY #&F0               \ These instructions are commented out in the original
\ADC #0                 \ source, but they would make the joystick move the
                        \ cursor faster by increasing the range of Y by -1 to +1

 TAY                    \ Copy the value of A into Y

 LDA KL                 \ Set A to the value of KL (the key pressed)

 RTS                    \ Return from the subroutine

.TJ1

 LDA KL                 \ Set A to the value of KL (the key pressed)

 LDX #0                 \ Set the initial values for the results, X = Y = 0,
 LDY #0                 \ which we now increase or decrease appropriately

 CMP #&19               \ If left arrow was pressed, set X = X - 1
 BNE P%+3
 DEX

 CMP #&79               \ If right arrow was pressed, set X = X + 1
 BNE P%+3
 INX

 CMP #&39               \ If up arrow was pressed, set Y = Y + 1
 BNE P%+3
 INY

 CMP #&29               \ If down arrow was pressed, set Y = Y - 1
 BNE P%+3
 DEY

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ping
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the selected system to the current system
\
\ ******************************************************************************

.ping

 LDX #1                 \ We want to copy the X- and Y-coordinates of the
                        \ current system in (QQ0, QQ1) to the selected system's
                        \ coordinates in (QQ9, QQ10), so set up a counter to
                        \ copy two bytes

.pl1

 LDA QQ0,X              \ Load byte X from the current system in QQ0/QQ1

 STA QQ9,X              \ Store byte X in the selected system in QQ9/QQ10

 DEX                    \ Decrement the loop counter

 BPL pl1                \ Loop back for the next byte to copy

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save ELTE.bin
\
\ ******************************************************************************

PRINT "ELITE E"
PRINT "Assembled at ", ~CODE_E%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_E%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_E%

PRINT "S.ELTE ", ~CODE_E%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_E%
SAVE "3-assembled-output/ELTE.bin", CODE_E%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE F FILE
\
\ Produces the binary file ELTF.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CODE_F% = P%
LOAD_F% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: KS3
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the SLSP ship heap pointer after shuffling ship slots
\
\ ------------------------------------------------------------------------------
\
\ The final part of the KILLSHP routine, called after we have shuffled the ship
\ slots and sorted out our missiles. This simply sets SLSP to the new bottom of
\ the ship heap space.
\
\ Arguments:
\
\   P(1 0)              Points to the ship line heap of the ship in the last
\                       occupied slot (i.e. it points to the bottom of the
\                       descending heap)
\
\ ******************************************************************************

.KS3

 LDA P                  \ After shuffling the ship slots, P(1 0) will point to
 STA SLSP               \ the new bottom of the ship heap, so store this in
 LDA P+1                \ SLSP(1 0), which stores the bottom of the heap
 STA SLSP+1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: KS1
\       Type: Subroutine
\   Category: Universe
\    Summary: Remove the current ship from our local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ Part 12 of the main flight loop calls this routine to remove the ship that is
\ currently being analysed by the flight loop. Once the ship is removed, it
\ jumps back to MAL1 to re-join the main flight loop, with X pointing to the
\ same slot that we just cleared (and which now contains the next ship in the
\ local bubble of universe).
\
\ Arguments:
\
\   XX0                 The address of the blueprint for this ship
\
\   INF                 The address of the data block for this ship
\
\ ******************************************************************************

.KS1

 LDX XSAV               \ Store the current ship's slot number in XSAV

 JSR KILLSHP            \ Call KILLSHP to remove the ship in slot X from our
                        \ local bubble of universe

 LDX XSAV               \ Restore the current ship's slot number from XSAV,
                        \ which now points to the next ship in the bubble

 JMP MAL1               \ Jump to MAL1 to re-join the main flight loop at the
                        \ start of the ship analysis loop

\ ******************************************************************************
\
\       Name: KS4
\       Type: Subroutine
\   Category: Universe
\    Summary: Remove the space station and replace it with the sun
\
\ ******************************************************************************

.KS4

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

 JSR FLFLLS             \ Reset the LSO block, returns with A = 0

 STA FRIN+1             \ Set the second slot in the FRIN table to 0, which
                        \ sets this slot to empty, so when we call NWSHP below
                        \ the new sun that gets created will go into FRIN+1

 STA SSPR               \ Set the "space station present" flag to 0, as we are
                        \ no longer in the space station's safe zone

 JSR SPBLB              \ Call SPBLB to redraw the space station bulb, which
                        \ will erase it from the dashboard

 LDA #6                 \ Set the sun's y_sign to 6
 STA INWK+5

 LDA #129               \ Set A = 129, the ship type for the sun

 JMP NWSHP              \ Call NWSHP to set up the sun's data block and add it
                        \ to FRIN, where it will get put in the second slot as
                        \ we just cleared out the second slot, and the first
                        \ slot is already taken by the planet

\ ******************************************************************************
\
\       Name: KS2
\       Type: Subroutine
\   Category: Universe
\    Summary: Check the local bubble for missiles with target lock
\
\ ------------------------------------------------------------------------------
\
\ Check the local bubble of universe to see if there are any missiles with
\ target lock in the vicinity. If there are, then check their targets; if we
\ just removed their target in the KILLSHP routine, then switch off their AI so
\ they just drift in space, otherwise update their targets to reflect the newly
\ shuffled slot numbers.
\
\ This is called from KILLSHP once the slots have been shuffled down, following
\ the removal of a ship.
\
\ Arguments:
\
\   XX4                 The slot number of the ship we removed just before
\                       calling this routine
\
\ ******************************************************************************

.KS2

 LDX #&FF               \ We want to go through the ships in our local bubble
                        \ and pick out all the missiles, so set X to &FF to
                        \ use as a counter

.KSL4

 INX                    \ Increment the counter (so it starts at 0 on the first
                        \ iteration)

 LDA FRIN,X             \ If slot X is empty, loop round again until it isn't,
 BEQ KS3                \ at which point A contains the ship type in that slot

 CMP #MSL               \ If the slot does not contain a missile, loop back to
 BNE KSL4               \ KSL4 to check the next slot

                        \ We have found a slot containing a missile, so now we
                        \ want to check whether it has target lock

 TXA                    \ Set Y = X * 2 and fetch the Y-th address from UNIV
 ASL A                  \ and store it in SC and SC+1 - in other words, set
 TAY                    \ SC(1 0) to point to the missile's ship data block
 LDA UNIV,Y
 STA SC
 LDA UNIV+1,Y
 STA SC+1

 LDY #32                \ Fetch byte #32 from the missile's ship data (AI)
 LDA (SC),Y

 BPL KSL4               \ If bit 7 of byte #32 is clear, then the missile is
                        \ dumb and has no AI, so loop back to KSL4 to move on
                        \ to the next slot

 AND #%01111111         \ Otherwise this missile has AI, so clear bit 7 and
 LSR A                  \ shift right to set the C flag to the missile's "is
                        \ locked" flag, and A to the target's slot number

 CMP XX4                \ If this missile's target is less than XX4, then the
 BCC KSL4               \ target's slot isn't being shuffled down, so jump to
                        \ KSL4 to move on to the next slot

 BEQ KS6                \ If this missile was locked onto the ship that we just
                        \ removed in KILLSHP, jump to KS6 to stop the missile
                        \ from continuing to hunt it down

 SBC #1                 \ Otherwise this missile is locked and has AI enabled,
                        \ and its target will have moved down a slot, so
                        \ subtract 1 from the target number (we know C is set
                        \ from the BCC above)

 ASL A                  \ Shift the target number left by 1, so it's in bits
                        \ 1-6 once again, and also set bit 0 to 1, as the C
                        \ flag is still set, so this makes sure the missile is
                        \ still set to being locked

 ORA #%10000000         \ Set bit 7, so the missile's AI is enabled

 STA (SC),Y             \ Update the missile's AI flag to the value in A

 BNE KSL4               \ Loop back to KSL4 to move on to the next slot (this
                        \ BNE is effectively a JMP as A will never be zero)

.KS6

 LDA #0                 \ The missile's target lock just got removed, so set the
 STA (SC),Y             \ AI flag to 0 to make it dumb and not locked

 BEQ KSL4               \ Loop back to KSL4 to move on to the next slot (this
                        \ BEQ is effectively a JMP as A is always zero)

\ ******************************************************************************
\
\       Name: KILLSHP
\       Type: Subroutine
\   Category: Universe
\    Summary: Remove a ship from our local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ Remove the ship in slot X from our local bubble of universe. This happens
\ when we kill a ship, collide with a ship and destroy it, or when a ship moves
\ outside our local bubble.
\
\ We also use this routine when we move out of range of the space station, in
\ which case we replace it with the sun.
\
\ When removing a ship, this creates a gap in the ship slots at FRIN, so we
\ shuffle all the later slots down to close the gap. We also shuffle the ship
\ data blocks at K% and ship line heap at WP, to reclaim all the memory that
\ the removed ship used to occupy.
\
\ Arguments:
\
\   X                   The slot number of the ship to remove
\
\   XX0                 The address of the blueprint for the ship to remove
\
\   INF                 The address of the data block for the ship to remove
\
\ ******************************************************************************

.KILLSHP

 STX XX4                \ Store the slot number of the ship to remove in XX4

IF _SOURCE_DISC

 LDA MSTG               \ Check whether this slot matches the slot number in
 CMP XX4                \ MSTG, which is the target of our missile lock

ELIF _TEXT_SOURCES

 CPX MSTG               \ Check whether this slot matches the slot number in
                        \ MSTG, which is the target of our missile lock
                        \
                        \ This instructions saves two bytes of memory over the
                        \ LDA and CMP-based code in the source disc version, as
                        \ CPX MSTG is a two-byte opcode, while LDA MSTG and
                        \ CMP XX4 take up four bytes between them (the code does
                        \ the same thing)

ENDIF

 BNE KS5                \ If our missile is not locked on this ship, jump to KS5

 LDY #&EE               \ Otherwise we need to remove our missile lock, so call
 JSR ABORT              \ ABORT to disarm the missile and update the missile
                        \ indicators on the dashboard to green/cyan (Y = &EE)

 LDA #200               \ Print recursive token 40 ("TARGET LOST") as an
 JSR MESS               \ in-flight message

.KS5

 LDY XX4                \ Restore the slot number of the ship to remove into Y

 LDX FRIN,Y             \ Fetch the contents of the slot, which contains the
                        \ ship type

 CPX #SST               \ If this is the space station, then jump to KS4 to
 BEQ KS4                \ replace the space station with the sun

 DEC MANY,X             \ Decrease the number of this type of ship in our little
                        \ bubble, which is stored in MANY+X (where X is the ship
                        \ type)

 LDX XX4                \ Restore the slot number of the ship to remove into X

                        \ We now want to remove this ship and reclaim all the
                        \ memory that it uses. Removing the ship will leave a
                        \ gap in three places, which we need to close up:
                        \
                        \   * The ship slots in FRIN
                        \
                        \   * The ship data blocks in K%
                        \
                        \   * The descending ship line heap at WP down
                        \
                        \ The rest of this routine closes up these gaps by
                        \ looping through all the occupied ship slots after the
                        \ slot we are removing, one by one, and shuffling each
                        \ ship's slot, data block and line heap down to close
                        \ up the gaps left by the removed ship. As part of this,
                        \ we have to make sure we update any address pointers
                        \ so they point to the newly shuffled data blocks and
                        \ line heaps
                        \
                        \ In the following, when shuffling a ship's data down
                        \ into the preceding empty slot, we call the ship that
                        \ we are shuffling down the "source", and we call the
                        \ empty slot we are shuffling it into the "destination"
                        \
                        \ Before we start looping through the ships we need to
                        \ shuffle down, we need to set up some variables to
                        \ point to the source and destination line heaps

 LDY #5                 \ Fetch byte #5 of the removed ship's blueprint into A,
 LDA (XX0),Y            \ which gives the ship's maximum heap size for the ship
                        \ we are removing (i.e. the size of the gap in the heap
                        \ created by the ship removal)

                        \ INF currently contains the ship data for the ship we
                        \ are removing, and INF(34 33) contains the address of
                        \ the bottom of the ship's heap, so we can calculate
                        \ the address of the top of the heap by adding the heap
                        \ size to this address

 LDY #33                \ First we add A and the address in INF+33, to get the
 CLC                    \ low byte of the top of the heap, which we store in P
 ADC (INF),Y
 STA P

 INY                    \ And next we add A and address in INF+34, with any
 LDA (INF),Y            \ from the previous addition, to get the high byte of
 ADC #0                 \ the top of the heap, which we store in P+1, so P(1 0)
 STA P+1                \ points to the top of this ship's heap

                        \ Now, we're ready to start looping through the ships
                        \ we want to move, moving the slots, data blocks and
                        \ line heap from the source to the destination. In the
                        \ following, we set up SC to point to the source data,
                        \ and INF (which currently points to the removed ship's
                        \ data that we can now overwrite) points to the
                        \ destination
                        \
                        \ So P(1 0) now points to the top of the line heap for
                        \ the destination

.KSL1

 INX                    \ On entry, X points to the empty slot we want to
                        \ shuffle the next ship into (the destination), so
                        \ this increment points X to the next slot - i.e. the
                        \ source slot we want to shuffle down

 LDA FRIN,X             \ Copy the contents of the source slot into the
 STA FRIN-1,X           \ destination slot

 BEQ KS2                \ If the slot we just shuffled down contains 0, then
                        \ the source slot is empty and we are done shuffling,
                        \ so jump to KS2 to move on to processing missiles

 ASL A                  \ Otherwise we have a source ship to shuffle down into
 TAY                    \ the destination, so set Y = A * 2 so it can act as an
                        \ index into the two-byte ship blueprint lookup table
                        \ at XX21 for the source ship

 LDA XX21-2,Y           \ Set SC(0 1) to point to the blueprint data for the
 STA SC                 \ source ship
 LDA XX21-1,Y
 STA SC+1

 LDY #5                 \ Fetch blueprint byte #5 for the source ship, which
 LDA (SC),Y             \ gives us its maximum heap size, and store it in T
 STA T

                        \ We now subtract T from P(1 0), so P(1 0) will point to
                        \ the bottom of the line heap for the destination
                        \ (which we will use later when closing up the gap in
                        \ the heap space)

 LDA P                  \ First, we subtract the low bytes
 SEC
 SBC T
 STA P

 LDA P+1                \ And then we do the high bytes, for which we subtract
 SBC #0                 \ 0 to include any carry, so this is effectively doing
 STA P+1                \ P(1 0) = P(1 0) - (0 T)

                        \ Next, we want to set SC(1 0) to point to the source
                        \ ship's data block

 TXA                    \ Set Y = X * 2 so it can act as an index into the
 ASL A                  \ two-byte lookup table at UNIV, which contains the
 TAY                    \ addresses of the ship data blocks. In this case we are
                        \ multiplying X by 2, and X contains the source ship's
                        \ slot number so Y is now an index for the source ship's
                        \ entry in UNIV

 LDA UNIV,Y             \ Set SC(1 0) to the address of the data block for the
 STA SC                 \ source ship
 LDA UNIV+1,Y
 STA SC+1

                        \ We have now set up our variables as follows:
                        \
                        \   SC(1 0) points to the source's ship data block
                        \
                        \   INF(1 0) points to the destination's ship data block
                        \
                        \   P(1 0) points to the destination's line heap
                        \
                        \ so let's start copying data from the source to the
                        \ destination

 LDY #35                \ We are going to be using Y as a counter for the 36
                        \ bytes of ship data we want to copy from the source
                        \ to the destination, so we set it to 35 to start things
                        \ off, and will decrement Y for each byte we copy

 LDA (SC),Y             \ Fetch byte #35 of the source's ship data block at SC,
 STA (INF),Y            \ and store it in byte #35 of the destination's block
                        \ at INF, so that's the ship's energy copied from the
                        \ source to the destination. One down, quite a few to
                        \ go...

 DEY                    \ Fetch byte #34 of the source ship, which is the
 LDA (SC),Y             \ high byte of the source ship's line heap, and store
 STA K+1                \ in K+1

 LDA P+1                \ Set the low byte of the destination's heap pointer
 STA (INF),Y            \ to P+1

 DEY                    \ Fetch byte #33 of the source ship, which is the
 LDA (SC),Y             \ low byte of the source ship's heap, and store in K
 STA K                  \ so now we have the following:
                        \
                        \   K(1 0) points to the source's line heap

 LDA P                  \ Set the low byte of the destination's heap pointer
 STA (INF),Y            \ to P, so now the destination's heap pointer is to
                        \ P(1 0), so that's the heap pointer in bytes #33 and
                        \ #34 done

 DEY                    \ Luckily, we can just copy the rest of the source's
                        \ ship data block into the destination, as there are no
                        \ more address pointers, so first we decrement our
                        \ counter in Y to point to the next byte (the AI flag)
                        \ in byte #32) and then start looping

.KSL2

 LDA (SC),Y             \ Copy the Y-th byte of the source to the Y-th byte of
 STA (INF),Y            \ the destination

 DEY                    \ Decrement the counter

 BPL KSL2               \ Loop back to KSL2 to copy the next byte until we have
                        \ copied the whole block

                        \ We have now shuffled the ship's slot and the ship's
                        \ data block, so we only have the heap data itself to do

 LDA SC                 \ First, we copy SC into INF, so when we loop round
 STA INF                \ again, INF will correctly point to the destination for
 LDA SC+1               \ the next iteration
 STA INF+1

 LDY T                  \ Now we want to move the contents of the heap, as all
                        \ we did above was to update the pointers, so first
                        \ we set a counter in Y that is initially set to T
                        \ (which we set above to the maximum heap size for the
                        \ source ship)
                        \
                        \ As a reminder, we have already set the following:
                        \
                        \   K(1 0) points to the source's line heap
                        \
                        \   P(1 0) points to the destination's line heap
                        \
                        \ so we can move the heap data by simply copying the
                        \ correct number of bytes from K(1 0) to P(1 0)
.KSL3

 DEY                    \ Decrement the counter

 LDA (K),Y              \ Copy the Y-th byte of the source heap at K(1 0) to
 STA (P),Y              \ the destination heap at P(1 0)

 TYA                    \ Loop back to KSL3 to copy the next byte, until we
 BNE KSL3               \ have done them all

 BEQ KSL1               \ We have now shuffled everything down one slot, so
                        \ jump back up to KSL1 to see if there is another slot
                        \ that needs shuffling down (this BEQ is effectively a
                        \ JMP as A will always be zero)

\ ******************************************************************************
\
\       Name: SFX
\       Type: Variable
\   Category: Sound
\    Summary: Sound data
\
\ ------------------------------------------------------------------------------
\
\ Sound data. To make a sound, the NOS1 routine copies the four relevant sound
\ bytes to XX16, and NO3 then makes the sound. The sound numbers are shown in
\ the table, and are always multiples of 8. Generally, sounds are made by
\ calling the NOISE routine with the sound number in A.
\
\ These bytes are passed to OSWORD 7, and are the equivalents to the parameters
\ passed to the SOUND keyword in BASIC. The parameters therefore have these
\ meanings:
\
\   channel/flush, amplitude (or envelope number if 1-4), pitch, duration
\
\ For the channel/flush parameter, the first byte is the channel while the
\ second is the flush control (where a flush control of 0 queues the sound,
\ while a flush control of 1 makes the sound instantly). When written in
\ hexadecimal, the first figure gives the flush control, while the second is
\ the channel (so &13 indicates flush control = 1 and channel = 3).
\
\ So when we call NOISE with A = 40 to make a long, low beep, then this is
\ effectively what the NOISE routine does:
\
\   SOUND &13, &F4, &0C, &08
\
\ which makes a sound with flush control 1 on channel 3, and with amplitude &F4
\ (-12), pitch &0C (2) and duration &08 (8). Meanwhile, to make the hyperspace
\ sound, the NOISE routine does this:
\
\   SOUND &10, &02, &60, &10
\
\ which makes a sound with flush control 1 on channel 0, using envelope 2,
\ and with pitch &60 (96) and duration &10 (16). The four sound envelopes (1-4)
\ are set up by the loading process.
\
\ ******************************************************************************

.SFX

 EQUB &12,&01,&00,&10   \ 0  - Lasers fired by us
 EQUB &12,&02,&2C,&08   \ 8  - We're being hit by lasers
 EQUB &11,&03,&F0,&18   \ 16 - We died 1 / We made a hit or kill 2
 EQUB &10,&F1,&07,&1A   \ 24 - We died 2 / We made a hit or kill 1
 EQUB &03,&F1,&BC,&01   \ 32 - Short, high beep
 EQUB &13,&F4,&0C,&08   \ 40 - Long, low beep
 EQUB &10,&F1,&06,&0C   \ 48 - Missile launched / Ship launched from station
 EQUB &10,&02,&60,&10   \ 56 - Hyperspace drive engaged
 EQUB &13,&04,&C2,&FF   \ 64 - E.C.M. on
 EQUB &13,&00,&00,&00   \ 72 - E.C.M. off

\ ******************************************************************************
\
\       Name: RESET
\       Type: Subroutine
\   Category: Start and end
\    Summary: Reset most variables
\
\ ------------------------------------------------------------------------------
\
\ Reset our ship and various controls, recharge shields and energy, and then
\ fall through into RES2 to reset the stardust and the ship workspace at INWK.
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
\     * QQ22 - Set hyperspace counters to 0
\
\     * ECMA - Turn E.C.M. off
\
\ It also sets QQ12 to &FF, to indicate we are docked, recharges the shields and
\ energy banks, and then falls through into RES2.
\
\ Other entry points:
\
\   RES4                Reset the shields and energy banks, then fall through
\                       into RES2 to reset the stardust and the ship workspace
\                       at INWK
\
\ ******************************************************************************

.RESET

 JSR ZERO               \ Zero-fill pages &9, &A, &B, &C and &D, which clears
                        \ the ship data blocks, the ship line heap, the ship
                        \ slots for the local bubble of universe, and various
                        \ flight and ship status variables

 LDX #6                 \ Set up a counter for zeroing BETA through BETA+6

.SAL3

 STA BETA,X             \ Zero the X-th byte after BETA

 DEX                    \ Decrement the loop counter

 BPL SAL3               \ Loop back for the next byte to zero

 STX QQ12               \ X is now negative - i.e. &FF - so this sets QQ12 to
                        \ &FF to indicate we are docked

                        \ We now fall through into RES4 to restore shields and
                        \ energy, and reset the stardust and ship workspace at
                        \ INWK

.RES4

 LDA #&FF               \ Set A to &FF so we can fill up the shields and energy
                        \ bars with a full charge

 LDX #2                 \ We're now going to recharge both shields and the
                        \ energy bank, which live in the three bytes at FSH,
                        \ ASH (FSH+1) and ENERGY (FSH+2), so set a loop counter
                        \ in X for 3 bytes

.REL5

 STA FSH,X              \ Set the X-th byte of FSH to &FF to charge up that
                        \ shield/bank

 DEX                    \ Decrement the lopp counter

 BPL REL5               \ Loop back to REL5 until we have recharged both shields
                        \ and the energy bank

                        \ Fall through into RES2 to reset the stardust and ship
                        \ workspace at INWK

\ ******************************************************************************
\
\       Name: RES2
\       Type: Subroutine
\   Category: Start and end
\    Summary: Reset a number of flight variables and workspaces
\
\ ------------------------------------------------------------------------------
\
\ This is called after we launch from a space station, arrive in a new system
\ after hyperspace, launch an escape pod, or die a cold, lonely death in the
\ depths of space.
\
\ Returns:
\
\   Y                   Y is set to &FF
\
\ ******************************************************************************

.RES2

 LDA #NOST              \ Reset NOSTM, the number of stardust particles, to the
 STA NOSTM              \ maximum allowed (18)

 LDX #&FF               \ Reset LSX2 and LSY2, the ball line heaps used by the
 STX LSX2               \ BLINE routine for drawing circles, to &FF, to set the
 STX LSY2               \ heap to empty

 STX MSTG               \ Reset MSTG, the missile target, to &FF (no target)

 LDA #128               \ Set the current pitch rate to the mid-point, 128
 STA JSTY

 STA ALP2               \ Reset ALP2 (roll sign) and BET2 (pitch sign)
 STA BET2               \ to negative, i.e. pitch and roll negative

 ASL A                  \ This sets A to 0

 STA ALP2+1             \ Reset ALP2+1 (flipped roll sign) and BET2+1 (flipped
 STA BET2+1             \ pitch sign) to positive, i.e. pitch and roll negative

 STA MCNT               \ Reset MCNT (the main loop counter) to 0

 LDA #3                 \ Reset DELTA (speed) to 3
 STA DELTA

 STA ALPHA              \ Reset ALPHA (roll angle alpha) to 3

 STA ALP1               \ Reset ALP1 (magnitude of roll angle alpha) to 3

 LDA SSPR               \ Fetch the "space station present" flag, and if we are
 BEQ P%+5               \ not inside the safe zone, skip the next instruction

 JSR SPBLB              \ Light up the space station bulb on the dashboard

 LDA ECMA               \ Fetch the E.C.M. status flag, and if E.C.M. is off,
 BEQ yu                 \ skip the next instruction

 JSR ECMOF              \ Turn off the E.C.M. sound

.yu

 JSR WPSHPS             \ Wipe all ships from the scanner

 JSR ZERO               \ Zero-fill pages &9, &A, &B, &C and &D, which clears
                        \ the ship data blocks, the ship line heap, the ship
                        \ slots for the local bubble of universe, and various
                        \ flight and ship status variables

 LDA #LO(WP-1)          \ We have reset the ship line heap, so we now point
 STA SLSP               \ SLSP to the byte before the WP workspace to indicate
 LDA #HI(WP-1)          \ that the heap is empty
 STA SLSP+1

 JSR DIALS              \ Update the dashboard

                        \ Finally, fall through into ZINF to reset the INWK
                        \ ship workspace

\ ******************************************************************************
\
\       Name: ZINF
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Reset the INWK workspace and orientation vectors
\  Deep dive: Orientation vectors
\
\ ------------------------------------------------------------------------------
\
\ Zero-fill the INWK ship workspace and reset the orientation vectors, with
\ nosev pointing out of the screen, towards us.
\
\ Returns:
\
\   Y                   Y is set to &FF
\
\ ******************************************************************************

.ZINF

 LDY #NI%-1             \ There are NI% bytes in the INWK workspace, so set a
                        \ counter in Y so we can loop through them

 LDA #0                 \ Set A to 0 so we can zero-fill the workspace

.ZI1

 STA INWK,Y             \ Zero the Y-th byte of the INWK workspace

 DEY                    \ Decrement the loop counter

 BPL ZI1                \ Loop back for the next byte, ending when we have
                        \ zero-filled the last byte at INWK, which leaves Y
                        \ with a value of &FF

                        \ Finally, we reset the orientation vectors as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0, -1)
                        \
                        \ 96 * 256 (&6000) represents 1 in the orientation
                        \ vectors, while -96 * 256 (&E000) represents -1. We
                        \ already set the vectors to zero above, so we just
                        \ need to set up the high bytes of the diagonal values
                        \ and we're done. The negative nosev makes the ship
                        \ point towards us, as the z-axis points into the screen

 LDA #96                \ Set A to represent a 1 (in vector terms)

 STA INWK+18            \ Set byte #18 = roofv_y_hi = 96 = 1

 STA INWK+22            \ Set byte #22 = sidev_x_hi = 96 = 1

 ORA #128               \ Flip the sign of A to represent a -1

 STA INWK+14            \ Set byte #14 = nosev_z_hi = -96 = -1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: msblob
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Display the dashboard's missile indicators in green
\
\ ------------------------------------------------------------------------------
\
\ Display the dashboard's missile indicators, with all the missiles reset to
\ green/cyan (i.e. not armed or locked).
\
\ ******************************************************************************

.msblob

 LDX #4                 \ Set up a loop counter in X to count through all four
                        \ missile indicators

.ss

 CPX NOMSL              \ If the counter is equal to the number of missiles,
 BEQ SAL8               \ jump down to SQL8 to draw remaining the missiles, as
                        \ the rest of them are present and should be drawn in
                        \ green/cyan

 LDY #0                 \ Draw the missile indicator at position X in black
 JSR MSBAR

 DEX                    \ Decrement the counter to point to the next missile

 BNE ss                 \ Loop back to ss if we still have missiles to draw

 RTS                    \ Return from the subroutine

.SAL8

 LDY #&EE               \ Draw the missile indicator at position X in green/cyan
 JSR MSBAR

 DEX                    \ Decrement the counter to point to the next missile

 BNE SAL8               \ Loop back to SAL8 if we still have missiles to draw

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: me2
\       Type: Subroutine
\   Category: Text
\    Summary: Remove an in-flight message from the space view
\
\ ******************************************************************************

.me2

 LDA MCH                \ Fetch the token number of the current message into A

 JSR MESS               \ Call MESS to print the token, which will remove it
                        \ from the screen as printing uses EOR logic

 LDA #0                 \ Set the delay in DLY to 0, so any new in-flight
 STA DLY                \ messages will be shown instantly

 JMP me3                \ Jump back into the main spawning loop at me3

\ ******************************************************************************
\
\       Name: Ze
\       Type: Subroutine
\   Category: Universe
\    Summary: Initialise the INWK workspace to a hostile ship
\  Deep dive: Fixing ship positions
\
\ ------------------------------------------------------------------------------
\
\ Specifically, this routine does the following:
\
\   * Reset the INWK ship workspace
\
\   * Set the ship to a fair distance away in all axes, in front of us but
\     randomly up or down, left or right
\
\   * Give the ship a 4% chance of having E.C.M.
\
\   * Set the ship to hostile, with AI enabled
\
\ This routine also sets A, X, T1 and the C flag to random values.
\
\ Note that because this routine uses the value of X returned by DORND, and X
\ contains the value of A returned by the previous call to DORND, this routine
\ does not necessarily set the new ship to a totally random location. See the
\ deep dive on "Fixing ship positions" for details.
\
\ ******************************************************************************

.Ze

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

 JSR DORND              \ Set A and X to random numbers

 STA T1                 \ Store A in T1

 AND #%10000000         \ Extract the sign of A and store in x_sign
 STA INWK+2

 TXA                    \ Extract the sign of X and store in y_sign
 AND #%10000000
 STA INWK+5

 LDA #32                \ Set x_hi = y_hi = z_hi = 32, a fair distance away
 STA INWK+1
 STA INWK+4
 STA INWK+7

 TXA                    \ Set the C flag if X >= 245 (4% chance)
 CMP #245

 ROL A                  \ Set bit 0 of A to the C flag (i.e. there's a 4%
                        \ chance of this ship having E.C.M.)

 ORA #%11000000         \ Set bits 6 and 7 of A, so the ship is hostile (bit 6
                        \ and has AI (bit 7)

 STA INWK+32            \ Store A in the AI flag of this ship

                        \ Fall through into DORND2 to set A, X and the C flag
                        \ randomly

\ ******************************************************************************
\
\       Name: DORND
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Generate random numbers
\  Deep dive: Generating random numbers
\             Fixing ship positions
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to random numbers (though note that X is set to the random number
\ that was returned in A the last time DORND was called).
\
\ The C and V flags are also set randomly.
\
\ If we want to generate a repeatable sequence of random numbers, when
\ generating explosion clouds, for example, then we call DORND2 to ensure that
\ the value of the C flag on entry doesn't affect the outcome, as otherwise we
\ might not get the same sequence of numbers if the C flag changes.
\
\ Other entry points:
\
\   DORND2              Make sure the C flag doesn't affect the outcome
\
\ ******************************************************************************

.DORND2

 CLC                    \ Clear the C flag so the value of the C flag on entry
                        \ doesn't affect the outcome

.DORND

 LDA RAND               \ Calculate the next two values f2 and f3 in the feeder
 ROL A                  \ sequence:
 TAX                    \
 ADC RAND+2             \   * f2 = (f1 << 1) mod 256 + C flag on entry
 STA RAND               \   * f3 = f0 + f2 + (1 if bit 7 of f1 is set)
 STX RAND+2             \   * C flag is set according to the f3 calculation

 LDA RAND+1             \ Calculate the next value m2 in the main sequence:
 TAX                    \
 ADC RAND+3             \   * A = m2 = m0 + m1 + C flag from feeder calculation
 STA RAND+1             \   * X = m1
 STX RAND+3             \   * C and V flags set according to the m2 calculation

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: Main game loop (Part 1 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Spawn a trader (a peaceful Cobra Mk III)
\  Deep dive: Program flow of the main game loop
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ This is part of the main game loop. This is where the core loop of the game
\ lives, and it's in two parts. The shorter loop (just parts 5 and 6) is
\ iterated when we are docked, while the entire loop from part 1 to 6 iterates
\ if we are in space.
\
\ This section covers the following:
\
\   * Spawn a trader, i.e. a Cobra Mk III that isn't hostile, with a 50% chance
\     of it having a missile, a 50% chance of it having an E.C.M., a speed
\     between 16 and 31, and a gentle clockwise roll
\
\ We call this from within the main loop, with A set to a random number.
\
\ ******************************************************************************

.MTT4

 LSR A                  \ Clear bit 7 of our random number in A and set the C
                        \ flag to bit 0 of A, which os random

 STA INWK+32            \ Store this in the ship's AI flag, so this ship does
                        \ not have AI

 STA INWK+29            \ Store A in the ship's roll counter, giving it a
                        \ clockwise roll (as bit 7 is clear), and a 1 in 127
                        \ chance of it having no damping

 ROL INWK+31            \ Set bit 0 of the ship's missile count ramdomly (as the
                        \ C flag was set), giving the ship either no missiles or
                        \ one missile

 AND #31                \ Set the ship speed to our random number, set to a
 ORA #16                \ minimum of 16 and a maximum of 31
 STA INWK+27

 LDA #CYL               \ Add a new Cobra Mk III to the local bubble and fall
 JSR NWSHP              \ through into the main game loop again

\ ******************************************************************************
\
\       Name: Main game loop (Part 2 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Call the main flight loop, and potentially spawn a trader, an
\             asteroid, or a cargo canister
\  Deep dive: Program flow of the main game loop
\             Ship data blocks
\             Fixing ship positions
\
\ ------------------------------------------------------------------------------
\
\ This section covers the following:
\
\   * Call M% to do the main flight loop
\
\   * Potentially spawn a trader, asteroid or cargo canister
\
\ Other entry points:
\
\   TT100               The entry point for the start of the main game loop,
\                       which calls the main flight loop and the moves into the
\                       spawning routine
\
\   me3                 Used by me2 to jump back into the main game loop after
\                       printing an in-flight message
\
\ ******************************************************************************

.TT100

 JSR M%                 \ Call M% to iterate through the main flight loop

 DEC DLY                \ Decrement the delay counter in DLY, so any in-flight
                        \ messages get removed once the counter reaches zero

 BEQ me2                \ If DLY is now 0, jump to me2 to remove any in-flight
                        \ message from the space view, and once done, return to
                        \ me3 below, skipping the following two instructions

 BPL me3                \ If DLY is positive, jump to me3 to skip the next
                        \ instruction

 INC DLY                \ If we get here, DLY is negative, so we have gone too
                        \ and need to increment DLY back to 0

.me3

 DEC MCNT               \ Decrement the main loop counter in MCNT

 BEQ P%+5               \ If the counter has reached zero, which it will do
                        \ every 256 main loops, skip the next JMP instruction
                        \ (or to put it another way, if the counter hasn't
                        \ reached zero, jump down to MLOOP, skipping all the
                        \ following checks)

.ytq

 JMP MLOOP              \ Jump down to MLOOP to do some end-of-loop tidying and
                        \ restart the main loop

                        \ We only get here once every 256 iterations of the
                        \ main loop. If we aren't in witchspace and don't
                        \ already have 3 or more asteroids in our local bubble,
                        \ then this section has a 13% chance of spawning
                        \ something benign (the other 87% of the time we jump
                        \ down to consider spawning cops, pirates and bounty
                        \ hunters)
                        \
                        \ If we are in that 13%, then 50% of the time this will
                        \ be a Cobra Mk III trader, and the other 50% of the
                        \ time it will either be an asteroid (98.5% chance) or,
                        \ very rarely, a cargo canister (1.5% chance)

 LDA MJ                 \ If we are in witchspace following a mis-jump, skip the
 BNE ytq                \ following by jumping down to MLOOP (via ytq above)

 JSR DORND              \ Set A and X to random numbers

 CMP #35                \ If A >= 35 (87% chance), jump down to MTT1 to skip
 BCS MTT1               \ the spawning of an asteroid or cargo canister and
                        \ potentially spawn something else

 LDA MANY+AST           \ If we already have 3 or more asteroids in the local
 CMP #3                 \ bubble, jump down to MTT1 to skip the following and
 BCS MTT1               \ potentially spawn something else

 JSR ZINF               \ Call ZINF to reset the INWK ship workspace

 LDA #38                \ Set z_hi = 38 (far away)
 STA INWK+7

 JSR DORND              \ Set A, X and C flag to random numbers

 STA INWK               \ Set x_lo = random

 STX INWK+3             \ Set y_lo = random
                        \
                        \ Note that because we use the value of X returned by
                        \ DORND, and X contains the value of A returned by the
                        \ previous call to DORND, this does not set the new ship
                        \ to a totally random location. See the deep dive on
                        \ "Fixing ship positions" for details

 AND #%10000000         \ Set x_sign = bit 7 of x_lo
 STA INWK+2

 TXA                    \ Set y_sign = bit 7 of y_lo
 AND #%10000000
 STA INWK+5

 ROL INWK+1             \ Set bit 1 of x_hi to the C flag, which is random, so
 ROL INWK+1             \ this randomly moves us off-centre by 512 (as if x_hi
                        \ is %00000010, then (x_hi x_lo) is 512 + x_lo)

 JSR DORND              \ Set A, X and V flag to random numbers

 BVS MTT4               \ If V flag is set (50% chance), jump up to MTT4 to
                        \ spawn a trader

 ORA #%01101111         \ Take the random number in A and set bits 0-3 and 5-6,
 STA INWK+29            \ so the result has a 50% chance of being positive or
                        \ negative, and a 50% chance of bits 0-6 being 127.
                        \ Storing this number in the roll counter therefore
                        \ gives our new ship a fast roll speed with a 50%
                        \ chance of having no damping, plus a 50% chance of
                        \ rolling clockwise or anti-clockwise

 LDA SSPR               \ If we are inside the space station safe zone, jump
 BNE MTT1               \ down to MTT1 to skip the following and potentially
                        \ spawn something else

 TXA                    \ Set A to the random X we set above, which we haven't
 BCS MTT2               \ used yet, and if the C flag is set (50% chance) jump
                        \ down to MTT2 to skip the following

 AND #31                \ Set the ship speed to our random number, set to a
 ORA #16                \ minimum of 16 and a maximum of 31
 STA INWK+27

 BCC MTT3               \ Jump down to MTT3, skipping the following (this BCC
                        \ is effectively a JMP as we know the C flag is clear,
                        \ having passed through the BCS above)

.MTT2

 ORA #%01111111         \ Set bits 0-6 of A to 127, leaving bit 7 as random, so
 STA INWK+30            \ storing this number in the pitch counter means we have
                        \ full pitch with no damping, with a 50% chance of
                        \ pitching up or down

.MTT3

 JSR DORND              \ Set A and X to random numbers

 CMP #5                 \ Set A to the ship number of an asteroid, and keep
 LDA #AST               \ this value for 98.5% of the time (i.e. if random
 BCS P%+4               \ A >= 5 then skip the following instruction)

 LDA #OIL               \ Set A to the ship number of a cargo canister

 JSR NWSHP              \ Add our new asteroid or canister to the universe

\ ******************************************************************************
\
\       Name: Main game loop (Part 3 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Potentially spawn a cop, particularly if we've been bad
\  Deep dive: Program flow of the main game loop
\             Ship data blocks
\             Fixing ship positions
\
\ ------------------------------------------------------------------------------
\
\ This section covers the following:
\
\   * Potentially spawn a cop (in a Viper), very rarely if we have been good,
\     more often if have been naughty, and very often if we have been properly
\     bad
\
\ ******************************************************************************

.MTT1

 LDA SSPR               \ If we are inside the space station's safe zone, jump
 BNE MLOOP              \ to MLOOP to skip the following

 JSR BAD                \ Call BAD to work out how much illegal contraband we
                        \ are carrying in our hold (A is up to 40 for a
                        \ standard hold crammed with contraband, up to 70 for
                        \ an extended cargo hold full of narcotics and slaves)

 ASL A                  \ Double A to a maximum of 80 or 140

 LDX MANY+COPS          \ If there are no cops in the local bubble, skip the
 BEQ P%+5               \ next instruction

 ORA FIST               \ There are cops in the vicinity and we've got a hold
                        \ full of jail time, so OR the value in A with FIST to
                        \ get a new value that is at least as high as both
                        \ values, to reflect the fact that they have almost
                        \ certainly scanned our ship

 STA T                  \ Store our badness level in T

 JSR Ze                 \ Call Ze to initialise INWK to a potentially hostile
                        \ ship, and set A and X to random values
                        \
                        \ Note that because Ze uses the value of X returned by
                        \ DORND, and X contains the value of A returned by the
                        \ previous call to DORND, this does not set the new ship
                        \ to a totally random location. See the deep dive on
                        \ "Fixing ship positions" for details

 CMP T                  \ If the random value in A >= our badness level, which
 BCS P%+7               \ will be the case unless we have been really, really
                        \ bad, then skip the following two instructions (so
                        \ if we are really bad, there's a higher chance of
                        \ spawning a cop, otherwise we got away with it, for
                        \ now)

 LDA #COPS              \ Add a new police ship to the local bubble
 JSR NWSHP

 LDA MANY+COPS          \ If we now have at least one cop in the local bubble,
 BNE MLOOP              \ jump down to MLOOP, otherwise fall through into the
                        \ next part to look at spawning something else

\ ******************************************************************************
\
\       Name: Main game loop (Part 4 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Potentially spawn a lone bounty hunter, a Thargoid, or up to four
\             pirates
\  Deep dive: Program flow of the main game loop
\             Ship data blocks
\             Fixing ship positions
\
\ ------------------------------------------------------------------------------
\
\ This section covers the following:
\
\   * Potentially spawn (35% chance) either a lone bounty hunter (a Mamba,
\     Python or Cobra Mk III), a Thargoid, or a group of up to 4 pirates
\     (Sidewinders and/or Mambas)
\
\ ******************************************************************************

 DEC EV                 \ Decrement EV, the extra vessels spawning delay, and
 BPL MLOOP              \ jump to MLOOP if it is still positive, so we only
                        \ do the following when the EV counter runs down

 INC EV                 \ EV is negative, so bump it up again, setting it back
                        \ to 0

 JSR DORND              \ Set A and X to random numbers

 LDY gov                \ If the government of this system is 0 (anarchy), jump
 BEQ LABEL_2            \ straight to LABEL_2 to start spawning pirates or a
                        \ lone bounty hunter

 CMP #90                \ If the random number in A >= 90 (65% chance), jump to
 BCS MLOOP              \ MLOOP to stop spawning (so there's a 35% chance of
                        \ spawning pirates or a lone bounty hunter)

 AND #7                 \ Reduce the random number in A to the range 0-7, and
 CMP gov                \ if A is less than government of this system, jump
 BCC MLOOP              \ to MLOOP to stop spawning (so safer governments with
                        \ larger gov numbers have a greater chance of jumping
                        \ out, which is another way of saying that more
                        \ dangerous systems spawn pirates and bounty hunters
                        \ more often)

.LABEL_2

                        \ Now to spawn a lone bounty hunter, a Thargoid or a
                        \ group of pirates

 JSR Ze                 \ Call Ze to initialise INWK to a potentially hostile
                        \ ship, and set A and X to random values
                        \
                        \ Note that because Ze uses the value of X returned by
                        \ DORND, and X contains the value of A returned by the
                        \ previous call to DORND, this does not set the new ship
                        \ to a totally random location. See the deep dive on
                        \ "Fixing ship positions" for details

 CMP #200               \ If the random number in A >= 200 (13% chance), jump
 BCS mt1                \ to mt1 to spawn pirates, otherwise keep going to
                        \ spawn a lone bounty hunter or a Thargoid

 INC EV                 \ Increase the extra vessels spawning counter, to
                        \ prevent the next attempt to spawn extra vessels

 AND #3                 \ Set A = Y = random number in the range 3-6, which
 ADC #3                 \ we will use to determine the type of ship
 TAY

                        \ We now build the AI flag for this ship in A

 TXA                    \ First, copy the random number in X to A

 CMP #200               \ First, set the C flag if X >= 200 (22% chance)

 ROL A                  \ Set bit 0 of A to the C flag (i.e. there's a 22%
                        \ chance of this ship having E.C.M.)

 ORA #%11000000         \ Set bits 6 and 7 of A, so the ship is hostile (bit 6)
                        \ and has AI (bit 7)

 CPY #6                 \ If Y = 6 (i.e. a Thargoid), jump down to the tha
 BEQ tha                \ routine in part 6 to decide whether or not to spawn it
                        \ (where there's a 22% chance of this happening)

 STA INWK+32            \ Store A in the AI flag of this ship

 TYA                    \ Add a new ship of type Y to the local bubble, so
 JSR NWSHP              \ that's a Mamba, Cobra Mk III or Python

.mj1

 JMP MLOOP              \ Jump down to MLOOP, as we are done spawning ships

.mt1

 AND #3                 \ It's time to spawn a group of pirates, so set A to a
                        \ random number in the range 0-3, which will be the
                        \ loop counter for spawning pirates below (so we will
                        \ spawn 1-4 pirates)

 STA EV                 \ Delay further spawnings by this number

 STA XX13               \ Store the number in XX13, the pirate counter

.mt3

 JSR DORND              \ Set A and X to random numbers

 AND #3                 \ Set A to a random number in the range 0-3

 ORA #1                 \ Set A to %01 or %11 (Sidewinder or Mamba)

 JSR NWSHP              \ Try adding a new ship of type A to the local bubble

 DEC XX13               \ Decrement the pirate counter

 BPL mt3                \ If we need more pirates, loop back up to mt3,
                        \ otherwise we are done spawning, so fall through into
                        \ the end of the main loop at MLOOP

\ ******************************************************************************
\
\       Name: Main game loop (Part 5 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Cool down lasers, make calls to update the dashboard
\  Deep dive: Program flow of the main game loop
\             The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ This is the first half of the minimal game loop, which we iterate when we are
\ docked. This section covers the following:
\
\   * Cool down lasers
\
\   * Make calls to update the dashboard
\
\ Other entry points:
\
\   MLOOP               The entry point for the main game loop. This entry point
\                       comes after the call to the main flight loop and
\                       spawning routines, so it marks the start of the main
\                       game loop for when we are docked (as we don't need to
\                       call the main flight loop or spawning routines if we
\                       aren't in space)
\
\ ******************************************************************************

.MLOOP

 LDA #%00000001         \ Set 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bit 1 (i.e. disable the CA2 interrupt,
                        \ which comes from the keyboard)

 LDX #&FF               \ Set the stack pointer to &01FF, which is the standard
 TXS                    \ location for the 6502 stack, so this instruction
                        \ effectively resets the stack

 LDX GNTMP              \ If the laser temperature in GNTMP is non-zero,
 BEQ EE20               \ decrement it (i.e. cool it down a bit)
 DEC GNTMP

.EE20

 JSR DIALS              \ Call DIALS to update the dashboard

 LDA QQ11               \ If this is a space view, skip the following four
 BEQ P%+11              \ instructions (i.e. jump to JSR TT17 below)

 AND PATG               \ If PATG = &FF (author names are shown on start-up)
 LSR A                  \ and bit 0 of QQ11 is 1 (the current view is type 1),
 BCS P%+5               \ then skip the following instruction

 JSR DELAY-5            \ Delay for 8 vertical syncs (8/50 = 0.16 seconds), to
                        \ slow the main loop down a bit

 JSR TT17               \ Scan the keyboard for the cursor keys or joystick,
                        \ returning the cursor's delta values in X and Y and
                        \ the key pressed in A

\ ******************************************************************************
\
\       Name: Main game loop (Part 6 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Process non-flight key presses (red function keys, docked keys)
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ This is the second half of the minimal game loop, which we iterate when we are
\ docked. This section covers the following:
\
\   * Process more key presses (red function keys, docked keys etc.)
\
\ It also support joining the main loop with a key already "pressed", so we can
\ jump into the main game loop to perform a specific action. In practice, this
\ is used when we enter the docking bay in BAY to display Status Mode (red key
\ f8), and when we finish buying or selling cargo in BAY2 to jump to the
\ Inventory (red key f9).
\
\ Other entry points:
\
\   FRCE                The entry point for the main game loop if we want to
\                       jump straight to a specific screen, by pretending to
\                       "press" a key, in which case A contains the internal key
\                       number of the key we want to "press"
\
\   tha                 Consider spawning a Thargoid (22% chance)
\
\ ******************************************************************************

.FRCE

 JSR TT102              \ Call TT102 to process the key pressed in A

 LDA QQ12               \ Fetch the docked flag from QQ12 into A

 BNE MLOOP              \ If we are docked, loop back up to MLOOP just above
                        \ to restart the main loop, but skipping all the flight
                        \ and spawning code in the top part of the main loop

 JMP TT100              \ Otherwise jump to TT100 to restart the main loop from
                        \ the start

.tha

 JSR DORND              \ Set A and X to random numbers

 CMP #200               \ If A < 200 (78% chance), skip the next instruction
 BCC P%+5

 JSR GTHG               \ Call GTHG to spawn a Thargoid ship

 JMP MLOOP              \ Jump back into the main loop at MLOOP, which is just
                        \ after the ship-spawning section

\ ******************************************************************************
\
\       Name: TT102
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Process function key, save key, hyperspace and chart key presses
\             and update the hyperspace counter
\
\ ------------------------------------------------------------------------------
\
\ Process function key presses, plus "@" (save commander), "H" (hyperspace),
\ "D" (show distance to system) and "O" (move chart cursor back to current
\ system). We can also pass cursor position deltas in X and Y to indicate that
\ the cursor keys or joystick have been used (i.e. the values that are returned
\ by routine TT17).
\
\ Arguments:
\
\   A                   The internal key number of the key pressed (see p.142 of
\                       the Advanced User Guide for a list of internal key
\                       numbers)
\
\   X                   The amount to move the crosshairs in the x-axis
\
\   Y                   The amount to move the crosshairs in the y-axis
\
\ Other entry points:
\
\   T95                 Print the distance to the selected system
\
\ ******************************************************************************

.TT102

 CMP #f8                \ If red key f8 was pressed, jump to STATUS to show the
 BNE P%+5               \ Status Mode screen, returning from the subroutine
 JMP STATUS             \ using a tail call

 CMP #f4                \ If red key f4 was pressed, jump to TT22 to show the
 BNE P%+5               \ Long-range Chart, returning from the subroutine using
 JMP TT22               \ a tail call

 CMP #f5                \ If red key f5 was pressed, jump to TT23 to show the
 BNE P%+5               \ Short-range Chart, returning from the subroutine using
 JMP TT23               \ a tail call

 CMP #f6                \ If red key f6 was pressed, call TT111 to select the
 BNE TT92               \ system nearest to galactic coordinates (QQ9, QQ10)
 JSR TT111              \ (the location of the chart crosshairs) and jump to
 JMP TT25               \ TT25 to show the Data on System screen, returning
                        \ from the subroutine using a tail call

.TT92

 CMP #f9                \ If red key f9 was pressed, jump to TT213 to show the
 BNE P%+5               \ Inventory screen, returning from the subroutine
 JMP TT213              \ using a tail call

 CMP #f7                \ If red key f7 was pressed, jump to TT167 to show the
 BNE P%+5               \ Market Price screen, returning from the subroutine
 JMP TT167              \ using a tail call

 CMP #f0                \ If red key f0 was pressed, jump to TT110 to launch our
 BNE fvw                \ ship (if docked), returning from the subroutine using
 JMP TT110              \ a tail call

.fvw

 BIT QQ12               \ If bit 7 of QQ12 is clear (i.e. we are not docked, but
 BPL INSP               \ in space), jump to INSP to skip the following checks
                        \ for f1-f3 and "@" (save commander file) key presses

 CMP #f3                \ If red key f3 was pressed, jump to EQSHP to show the
 BNE P%+5               \ Equip Ship screen, returning from the subroutine using
 JMP EQSHP              \ a tail call

 CMP #f1                \ If red key f1 was pressed, jump to TT219 to show the
 BNE P%+5               \ Buy Cargo screen, returning from the subroutine using
 JMP TT219              \ a tail call

 CMP #&47               \ If "@" was pressed, jump to SVE to save the commander
 BNE P%+5               \ file, returning from the subroutine using a tail call
 JMP SVE

 CMP #f2                \ If red key f2 was pressed, jump to TT208 to show the
 BNE LABEL_3            \ Sell Cargo screen, returning from the subroutine using
 JMP TT208              \ a tail call

.INSP

 CMP #f1                \ If the key pressed is < red key f1 or > red key f3,
 BCC LABEL_3            \ jump to LABEL_3 (so only do the following if the key
 CMP #f3+1              \ pressed is f1, f2 or f3)
 BCS LABEL_3

 AND #3                 \ If we get here then we are either in space, or we are
 TAX                    \ docked and none of f1-f3 were pressed, so we can now
 JMP LOOK1              \ process f1-f3 with their in-flight functions, i.e.
                        \ switching space views
                        \
                        \ A will contain &71, &72 or &73 (for f1, f2 or f3), so
                        \ set X to the last digit (1, 2 or 3) and jump to LOOK1
                        \ to switch to view X (rear, left or right), returning
                        \ from the subroutine using a tail call

.LABEL_3

 CMP #&54               \ If "H" was pressed, jump to hyp to do a hyperspace
 BNE P%+5               \ jump (if we are in space), returning from the
 JMP hyp                \ subroutine using a tail call

 CMP #&32               \ If "D" was pressed, jump to T95 to print the distance
 BEQ T95                \ to a system (if we are in one of the chart screens)

 STA T1                 \ Store A (the key that's been pressed) in T1

 LDA QQ11               \ If the current view is a chart (QQ11 = 64 or 128),
 AND #%11000000         \ keep going, otherwise jump down to TT107 to skip the
 BEQ TT107              \ following

 LDA QQ22+1             \ If the on-screen hyperspace counter is non-zero,
 BNE TT107              \ then we are already counting down, so jump to TT107
                        \ to skip the following

 LDA T1                 \ Restore the original value of A (the key that's been
                        \ pressed) from T1

 CMP #&36               \ If "O" was pressed, do the following three jumps,
 BNE ee2                \ otherwise skip to ee2 to continue

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 JSR ping               \ Set the target system to the current system (which
                        \ will move the location in (QQ9, QQ10) to the current
                        \ home system

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will draw the crosshairs at our current home
                        \ system

.ee2

 JSR TT16               \ Call TT16 to move the crosshairs by the amount in X
                        \ and Y, which were passed to this subroutine as
                        \ arguments

.TT107

 LDA QQ22+1             \ If the on-screen hyperspace counter is zero, return
 BEQ t95                \ from the subroutine (as t95 contains an RTS), as we
                        \ are not currently counting down to a hyperspace jump

 DEC QQ22               \ Decrement the internal hyperspace counter

 BNE t95                \ If the internal hyperspace counter is still non-zero,
                        \ then we are still counting down, so return from the
                        \ subroutine (as t95 contains an RTS)

                        \ If we get here then the internal hyperspace counter
                        \ has just reached zero and it wasn't zero before, so
                        \ we need to reduce the on-screen counter and update
                        \ the screen. We do this by first printing the next
                        \ number in the countdown sequence, and then printing
                        \ the old number, which will erase the old number
                        \ and display the new one because printing uses EOR
                        \ logic

 LDX QQ22+1             \ Set X = the on-screen hyperspace counter - 1
 DEX                    \ (i.e. the next number in the sequence)

 JSR ee3                \ Print the 8-bit number in X at text location (0, 1)

 LDA #5                 \ Reset the internal hyperspace counter to 5
 STA QQ22

 LDX QQ22+1             \ Set X = the on-screen hyperspace counter (i.e. the
                        \ current number in the sequence, which is already
                        \ shown on-screen)

 JSR ee3                \ Print the 8-bit number in X at text location (0, 1),
                        \ i.e. print the hyperspace countdown in the top-left
                        \ corner

 DEC QQ22+1             \ Decrement the on-screen hyperspace countdown

 BNE t95                \ If the countdown is not yet at zero, return from the
                        \ subroutine (as t95 contains an RTS)

 JMP TT18               \ Otherwise the countdown has finished, so jump to TT18
                        \ to do a hyperspace jump, returning from the subroutine
                        \ using a tail call

.t95

 RTS                    \ Return from the subroutine

.T95

                        \ If we get here, "D" was pressed, so we need to show
                        \ the distance to the selected system (if we are in a
                        \ chart view)

 LDA QQ11               \ If the current view is a chart (QQ11 = 64 or 128),
 AND #%11000000         \ keep going, otherwise return from the subroutine (as
 BEQ t95                \ t95 contains an RTS)

 JSR hm                 \ Call hm to move the crosshairs to the target system
                        \ in (QQ9, QQ10), returning with A = 0

 STA QQ17               \ Set QQ17 = 0 to switch to ALL CAPS

 JSR cpl                \ Print control code 3 (the selected system name)

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case, with the
 STA QQ17               \ next letter in capitals

 LDA #1                 \ Move the text cursor to column 1 and down one line
 STA XC                 \ (in other words, to the start of the next line)
 INC YC

 JMP TT146              \ Print the distance to the selected system and return
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: BAD
\       Type: Subroutine
\   Category: Status
\    Summary: Calculate how bad we have been
\
\ ------------------------------------------------------------------------------
\
\ Work out how bad we are from the amount of contraband in our hold. The
\ formula is:
\
\   (slaves + narcotics) * 2 + firearms
\
\ so slaves and narcotics are twice as illegal as firearms. The value in FIST
\ (our legal status) is set to at least this value whenever we launch from a
\ space station, and a FIST of 50 or more gives us fugitive status, so leaving a
\ station carrying 25 tonnes of slaves/narcotics, or 50 tonnes of firearms
\ across multiple trips, is enough to make us a fugitive.
\
\ Returns:
\
\   A                   A value that determines how bad we are from the amount
\                       of contraband in our hold
\
\ ******************************************************************************

.BAD

 LDA QQ20+3             \ Set A to the number of tonnes of slaves in the hold

 CLC                    \ Clear the C flag so we can do addition without the
                        \ C flag affecting the result

 ADC QQ20+6             \ Add the number of tonnes of narcotics in the hold

 ASL A                  \ Double the result and add the number of tonnes of
 ADC QQ20+10            \ firearms in the hold

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FAROF
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Compare x_hi, y_hi and z_hi with 224
\
\ ------------------------------------------------------------------------------
\
\ Compare x_hi, y_hi and z_hi with 224, and set the C flag if all three <= 224,
\ otherwise clear the C flag.
\
\ Returns:
\
\   C flag              Set if x_hi <= 224 and y_hi <= 224 and z_hi <= 224
\
\                       Clear otherwise (i.e. if any one of them are bigger than
\                       224)
\
\ ******************************************************************************

.FAROF

 LDA #224               \ Set A = 224 and fall through into FAROF2 to do the
                        \ comparison

\ ******************************************************************************
\
\       Name: FAROF2
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Compare x_hi, y_hi and z_hi with A
\
\ ------------------------------------------------------------------------------
\
\ Compare x_hi, y_hi and z_hi with A, and set the C flag if all three <= A,
\ otherwise clear the C flag.
\
\ Returns:
\
\   C flag              Set if x_hi <= A and y_hi <= A and z_hi <= A
\
\                       Clear otherwise (i.e. if any one of them are bigger than
\                       A)
\
\ ******************************************************************************

.FAROF2

 CMP INWK+1             \ If A < x_hi, C will be clear so jump to MA34 to
 BCC MA34               \ return from the subroutine with C clear, otherwise
                        \ C will be set so move on to the next one

 CMP INWK+4             \ If A < y_hi, C will be clear so jump to MA34 to
 BCC MA34               \ return from the subroutine with C clear, otherwise
                        \ C will be set so move on to the next one

 CMP INWK+7             \ If A < z_hi, C will be clear, otherwise C will be set

.MA34

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MAS4
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate a cap on the maximum distance to a ship
\
\ ------------------------------------------------------------------------------
\
\ Logical OR the value in A with the high bytes of the ship's position (x_hi,
\ y_hi and z_hi).
\
\ Returns:
\
\   A                   A OR x_hi OR y_hi OR z_hi
\
\ ******************************************************************************

.MAS4

 ORA INWK+1             \ OR A with x_hi, y_hi and z_hi
 ORA INWK+4
 ORA INWK+7

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DEATH
\       Type: Subroutine
\   Category: Start and end
\    Summary: Display the death screen
\
\ ------------------------------------------------------------------------------
\
\ We have been killed, so display the chaos of our destruction above a "GAME
\ OVER" sign, and clean up the mess ready for the next attempt.
\
\ ******************************************************************************

.DEATH

 JSR EXNO3              \ Make the sound of us dying

 JSR RES2               \ Reset a number of flight variables and workspaces

 ASL DELTA              \ Divide our speed in DELTA by 4
 ASL DELTA

 LDX #24                \ Set the screen to only show 24 text rows, which hides
 JSR DET1               \ the dashboard, setting A to 6 in the process

 JSR TT66               \ Clear the top part of the screen, draw a white border,
                        \ and set the current view type in QQ11 to 6 (death
                        \ screen)

 JSR BOX                \ Call BOX to redraw the same white border (BOX is part
                        \ of TT66), which removes the border as it is drawn
                        \ using EOR logic

 JSR nWq                \ Create a cloud of stardust containing the correct
                        \ number of dust particles (i.e. NOSTM of them)

 LDA #12                \ Move the text cursor to column 12 on row 12
 STA YC
 STA XC

 LDA #146               \ Print recursive token 146 ("{all caps}GAME OVER")
 JSR ex

.D1

 JSR Ze                 \ Call Ze to initialise INWK to a potentially hostile
                        \ ship, and set A and X to random values

 LSR A                  \ Set A = A / 4, so A is now between 0 and 63, and
 LSR A                  \ store in byte #0 (x_lo)
 STA INWK

 LDY #0                 \ Set the following to 0: the current view in QQ11
 STY QQ11               \ (space view), x_hi, y_hi, z_hi and the AI flag (no AI
 STY INWK+1             \ or E.C.M. and not hostile)
 STY INWK+4
 STY INWK+7
 STY INWK+32

 DEY                    \ Set Y = 255

 STY MCNT               \ Reset the main loop counter to 255, so all timer-based
                        \ calls will be stopped

 STY LASCT              \ Set the laser count to 255 to act as a counter in the
                        \ D2 loop below, so this setting determines how long the
                        \ death animation lasts (it's 5.1 seconds, as LASCT is
                        \ decremented every vertical sync, or 50 times a second,
                        \ and 255 / 50 = 5.1)

 EOR #%00101010         \ Flip bits 1, 3 and 5 in A (x_lo) to get another number
 STA INWK+3             \ between 48 and 63, and store in byte #3 (y_lo)

 ORA #%01010000         \ Set bits 4 and 6 of A to bump it up to between 112 and
 STA INWK+6             \ 127, and store in byte #6 (z_lo)

 TXA                    \ Set A to the random number in X and keep bits 0-3 and
 AND #%10001111         \ the bit 7 to get a number between -15 and +15, and
 STA INWK+29            \ store in byte #29 (roll counter) to give our ship a
                        \ gentle roll with damping

 ROR A                  \ The C flag is randomly set from the above call to Ze,
 AND #%10000111         \ so this sets A to a number between -7 and +7, which
 STA INWK+30            \ we store in byte #30 (the pitch counter) to give our
                        \ ship a very gentle pitch with damping

 PHP                    \ Store the processor flags

 LDX #OIL               \ Call fq1 with X set to #OIL, which adds a new cargo
 JSR fq1                \ canister to our local bubble of universe and points it
                        \ away from us with double DELTA speed (i.e. 6, as DELTA
                        \ was set to 3 by the call to RES2 above). INF is set to
                        \ point to the canister's ship data block in K%

 PLP                    \ Restore the processor flags, including our random C
                        \ flag from before

 LDA #0                 \ Set bit 7 of A to our random C flag and store in byte
 ROR A                  \ #31 of the ship's data block, so this has a 50% chance
 LDY #31                \ of marking our new canister as being killed (so it
 STA (INF),Y            \ will explode)

 LDA FRIN+3             \ The call we made to RES2 before we entered the loop at
 BEQ D1                 \ D1 will have reset all the ship slots at FRIN, so this
                        \ checks to see if the fourth slot is empty, and if it
                        \ is we loop back to D1 to add another canister, until
                        \ we have added four of them

 JSR U%                 \ Clear the key logger, which also sets A = 0

 STA DELTA              \ Set our speed in DELTA to 0, as we aren't going
                        \ anywhere any more

.D2

 JSR M%                 \ Call the M% routine to do the main flight loop once,
                        \ which will display our exploding canister scene and
                        \ move everything about

 LDA LASCT              \ Loop back to D2 to run the main flight loop until
 BNE D2                 \ LASCT reaches zero (which will take 5.1 seconds, as
                        \ explained above)

 LDX #31                \ Set the screen to show all 31 text rows, which shows
 JSR DET1               \ the dashboard

                        \ Fall through into DEATH2 to reset and restart the game

\ ******************************************************************************
\
\       Name: DEATH2
\       Type: Subroutine
\   Category: Start and end
\    Summary: Reset most of the game and restart from the title screen
\
\ ------------------------------------------------------------------------------
\
\ This routine is called following death, and when the game is quit by pressing
\ ESCAPE when paused.
\
\ ******************************************************************************

.DEATH2

 JSR RES2               \ Reset a number of flight variables and workspaces
                        \ and fall through into the entry code for the game
                        \ to restart from the title screen

\ ******************************************************************************
\
\       Name: TT170
\       Type: Subroutine
\   Category: Start and end
\    Summary: Main entry point for the Elite game code
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ This is the main entry point for the main game code.
\
\ ******************************************************************************

.TT170

 LDX #&FF               \ Set the stack pointer to &01FF, which is the standard
 TXS                    \ location for the 6502 stack, so this instruction
                        \ effectively resets the stack. We need to do this
                        \ because the loader code in elite-loader.asm pushes
                        \ code onto the stack, and this effectively removes that
                        \ code so we start afresh

                        \ Fall through into BR1 to start the game

\ ******************************************************************************
\
\       Name: BR1 (Part 1 of 2)
\       Type: Subroutine
\   Category: Start and end
\    Summary: Start or restart the game
\
\ ------------------------------------------------------------------------------
\
\ BRKV is set to point to BR1 by the loading process.
\
\ ******************************************************************************

.BR1

 LDX #3                 \ Set XC = 3 (set text cursor to column 3)
 STX XC

 JSR FX200              \ Disable the ESCAPE key and clear memory if the BREAK
                        \ key is pressed (*FX 200,3)

 LDX #CYL               \ Call TITLE to show a rotating Cobra Mk III (#CYL) and
 LDA #128               \ token 128 ("  LOAD NEW COMMANDER (Y/N)?{crlf}{crlf}"),
 JSR TITLE              \ returning with the internal number of the key pressed
                        \ in A

 CMP #&44               \ Did we press "Y"? If not, jump to QU5, otherwise
 BNE QU5                \ continue on to load a new commander

\BR1                    \ These instructions are commented out in the original
\LDX #3                 \ source. This block starts with the same *FX call as
\STX XC                 \ above, then clears the screen, calls a routine to
\JSR FX200              \ flush the keyboard buffer (FLKB) that isn't present
\LDA #1                 \ in the cassette version but is in other versions,
\JSR TT66               \ and then it displays "LOAD NEW COMMANDER (Y/N)?" and
\JSR FLKB               \ lists the current cargo, before falling straight into
\LDA #14                \ the load routine below, whether or not we have
\JSR TT214              \ pressed "Y". This may be a bit of testing code, as the
\BCC QU5                \ first line is a commented label, BR1, which is where
                        \ BRKV points, so when this is uncommented, pressing
                        \ the BREAK key should jump straight to the load screen

 JSR GTNME              \ We want to load a new commander, so we need to get
                        \ the commander name to load

 JSR LOD                \ We then call the LOD subroutine to load the commander
                        \ file to address NA%+8, which is where we store the
                        \ commander save file

 JSR TRNME              \ Once loaded, we copy the commander name to NA%

 JSR TTX66              \ And we clear the top part of the screen and draw a
                        \ white border

\ ******************************************************************************
\
\       Name: QU5
\       Type: Subroutine
\   Category: Start and end
\    Summary: Reset the current commander data block to the last saved commander
\
\ ******************************************************************************

.QU5

                        \ By the time we get here, the correct commander name
                        \ is at NA% and the correct commander data is at NA%+8.
                        \ Specifically:
                        \
                        \   * If we loaded a commander file, then the name and
                        \     data from that file will be at NA% and NA%+8
                        \
                        \   * If this is a brand new game, then NA% will contain
                        \     the default starting commander name ("JAMESON")
                        \     and NA%+8 will contain the default commander data
                        \
                        \   * If this is not a new game (because they died or
                        \     quit) and we didn't want to load a commander file,
                        \     then NA% will contain the last saved commander
                        \     name, and NA%+8 the last saved commander data. If
                        \     the game has never been saved, this will still be
                        \     the default commander

\JSR TTX66              \ This instruction is commented out in the original
                        \ source; it clears the screen and draws a border

 LDX #NT%               \ The size of the commander data block is NT% bytes,
                        \ and it starts at NA%+8, so we need to copy the data
                        \ from the "last saved" buffer at NA%+8 to the current
                        \ commander workspace at TP. So we set up a counter in X
                        \ for the NT% bytes that we want to copy

.QUL1

 LDA NA%+7,X            \ Copy the X-th byte of NA%+7 to the X-th byte of TP-1,
 STA TP-1,X             \ (the -1 is because X is counting down from NT% to 1)

 DEX                    \ Decrement the loop counter

 BNE QUL1               \ Loop back for the next byte of the commander data
                        \ block

 STX QQ11               \ X is 0 by the end of the above loop, so this sets QQ11
                        \ to 0, which means we will be showing a view without a
                        \ boxed title at the top (i.e. we're going to use the
                        \ screen layout of a space view in the following)

                        \ If the commander check below fails, we keep jumping
                        \ back to here to crash the game with an infinite loop

 JSR CHECK              \ Call the CHECK subroutine to calculate the checksum
                        \ for the current commander block at NA%+8 and put it
                        \ in A

 CMP CHK                \ Test the calculated checksum against CHK

IF _REMOVE_CHECKSUMS

 NOP                    \ If we have disabled checksums, then ignore the result
 NOP                    \ of the comparison and fall through into the next part

ELSE

 BNE P%-6               \ If the calculated checksum does not match CHK, then
                        \ loop back to repeat the check - in other words, we
                        \ enter an infinite loop here, as the checksum routine
                        \ will keep returning the same incorrect value

ENDIF

                        \ The checksum CHK is correct, so now we check whether
                        \ CHK2 = CHK EOR A9, and if this check fails, bit 7 of
                        \ the competition flags at COK gets set, to indicate
                        \ to Acornsoft via the competition code that there has
                        \ been some hacking going on with this competition entry

 EOR #&A9               \ X = checksum EOR &A9
 TAX

 LDA COK                \ Set A to the competition flags in COK

 CPX CHK2               \ If X = CHK2, then skip the next instruction
 BEQ tZ

 ORA #%10000000         \ Set bit 7 of A to indicate this commander file has
                        \ been tampered with

.tZ

 ORA #%00000010         \ Set bit 1 of A to denote that this is the cassette
                        \ version

 STA COK                \ Store the updated competition flags in COK

\ ******************************************************************************
\
\       Name: BR1 (Part 2 of 2)
\       Type: Subroutine
\   Category: Start and end
\    Summary: Show the "Load New Commander (Y/N)?" screen and start the game
\
\ ------------------------------------------------------------------------------
\
\ BRKV is set to point to BR1 by the loading process.
\
\ ******************************************************************************

 JSR msblob             \ Reset the dashboard's missile indicators so none of
                        \ them are targeted

 LDA #147               \ Call TITLE to show a rotating Mamba (#3) and token
 LDX #3                 \ 147 ("PRESS FIRE OR SPACE,COMMANDER.{crlf}{crlf}"),
 JSR TITLE              \ returning with the internal number of the key pressed
                        \ in A

 JSR ping               \ Set the target system coordinates (QQ9, QQ10) to the
                        \ current system coordinates (QQ0, QQ1) we just loaded

 JSR hyp1               \ Arrive in the system closest to (QQ9, QQ10) and then
                        \ fall through into the docking bay routine below

\ ******************************************************************************
\
\       Name: BAY
\       Type: Subroutine
\   Category: Status
\    Summary: Go to the docking bay (i.e. show the Status Mode screen)
\
\ ------------------------------------------------------------------------------
\
\ We end up here after the start-up process (load commander etc.), as well as
\ after a successful save, an escape pod launch, a successful docking, the end
\ of a cargo sell, and various errors (such as not having enough cash, entering
\ too many items when buying, trying to fit an item to your ship when you
\ already have it, running out of cargo space, and so on).
\
\ ******************************************************************************

.BAY

 LDA #&FF               \ Set QQ12 = &FF (the docked flag) to indicate that we
 STA QQ12               \ are docked

 LDA #f8                \ Jump into the main loop at FRCE, setting the key
 JMP FRCE               \ that's "pressed" to red key f8 (so we show the Status
                        \ Mode screen)

\ ******************************************************************************
\
\       Name: TITLE
\       Type: Subroutine
\   Category: Start and end
\    Summary: Display a title screen with a rotating ship and prompt
\
\ ------------------------------------------------------------------------------
\
\ Display the title screen, with a rotating ship and a text token at the bottom
\ of the screen.
\
\ Arguments:
\
\   A                   The number of the recursive token to show below the
\                       rotating ship (see variable QQ18 for details of
\                       recursive tokens)
\
\   X                   The type of the ship to show (see variable XX21 for a
\                       list of ship types)
\
\ Returns:
\
\   X                   If a key is being pressed, X contains the internal key
\                       number, otherwise it contains 0
\
\ ******************************************************************************

.TITLE

 PHA                    \ Store the token number on the stack for later

 STX TYPE               \ Store the ship type in location TYPE

 JSR RESET              \ Reset our ship so we can use it for the rotating
                        \ title ship

 LDA #1                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 1

 DEC QQ11               \ Decrement QQ11 to 0, so from here on we are using a
                        \ space view

 LDA #96                \ Set nosev_z hi = 96 (96 is the value of unity in the
 STA INWK+14            \ rotation vector)

\LSR A                  \ This instruction is commented out in the original
                        \ source. It would halve the value of z_hi to 48, so the
                        \ ship would start off closer to the viewer

 STA INWK+7             \ Set z_hi, the high byte of the ship's z-coordinate,
                        \ to 96, which is the distance at which the rotating
                        \ ship starts out before coming towards us

 LDX #127               \ Set roll counter = 127, so don't dampen the roll
 STX INWK+29

 STX INWK+30            \ Set pitch counter = 127, so don't dampen the pitch

 INX                    \ Set QQ17 to 128 (so bit 7 is set) to switch to
 STX QQ17               \ Sentence Case, with the next letter printing in upper
                        \ case

 LDA TYPE               \ Set up a new ship, using the ship type in TYPE
 JSR NWSHP

 LDY #6                 \ Move the text cursor to column 6
 STY XC

 JSR DELAY              \ Delay for 6 vertical syncs (6/50 = 0.12 seconds)

 LDA #30                \ Print recursive token 144 ("---- E L I T E ----")
 JSR plf                \ followed by a newline

 LDY #6                 \ Move the text cursor to column 6 again
 STY XC

 INC YC                 \ Move the text cursor down a row

 LDA PATG               \ If PATG = 0, skip the following two lines, which
 BEQ awe                \ print the author credits (PATG can be toggled by
                        \ pausing the game and pressing "X")

 LDA #254               \ Print recursive token 94 ("BY D.BRABEN & I.BELL")
 JSR TT27

.awe

 JSR CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows.
                        \ It also returns with Y = 0

 STY DELTA              \ Set DELTA = 0 (i.e. ship speed = 0)

 STY JSTK               \ Set JSTK = 0 (i.e. keyboard, not joystick)

 PLA                    \ Restore the recursive token number we stored on the
 JSR ex                 \ stack at the start of this subroutine, and print that
                        \ token

 LDA #148               \ Set A to recursive token 148

 LDX #7                 \ Move the text cursor to column 7
 STX XC

 JSR ex                 \ Print recursive token 148 ("(C) ACORNSOFT 1984")

.TLL2

 LDA INWK+7             \ If z_hi (the ship's distance) is 1, jump to TL1 to
 CMP #1                 \ skip the following decrement
 BEQ TL1

 DEC INWK+7             \ Decrement the ship's distance, to bring the ship
                        \ a bit closer to us

.TL1

 JSR MVEIT              \ Move the ship in space according to the orientation
                        \ vectors and the new value in z_hi

 LDA #128               \ Set z_lo = 128, so the closest the ship gets to us is
 STA INWK+6             \ z_hi = 1, z_lo = 128, or 256 + 128 = 384

 ASL A                  \ Set A = 0

 STA INWK               \ Set x_lo = 0, so the ship remains in the screen centre

 STA INWK+3             \ Set y_lo = 0, so the ship remains in the screen centre

 JSR LL9                \ Call LL9 to display the ship

 DEC MCNT               \ Decrement the main loop counter

 LDA VIA+&40            \ Read 6522 System VIA input register IRB (SHEILA &40)

 AND #%00010000         \ Bit 4 of IRB (PB4) is clear if joystick 1's fire
                        \ button is pressed, otherwise it is set, so AND'ing
                        \ the value of IRB with %10000 extracts this bit

\TAX                    \ This instruction is commented out in the original
                        \ source; it would have no effect, as the comparison
                        \ flags are already set by the AND, and the value of X
                        \ is not used anywhere

 BEQ TL2                \ If the joystick fire button is pressed, jump to TL2

 JSR RDKEY              \ Scan the keyboard for a key press

 BEQ TLL2               \ If no key was pressed, loop back up to move/rotate
                        \ the ship and check again for a key press

 RTS                    \ Return from the subroutine

.TL2

 DEC JSTK               \ Joystick fire button was pressed, so set JSTK to &FF
                        \ (it was set to 0 above), to disable keyboard and
                        \ enable joysticks

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CHECK
\       Type: Subroutine
\   Category: Save and load
\    Summary: Calculate the checksum for the last saved commander data block
\  Deep dive: Commander save files
\
\ ------------------------------------------------------------------------------
\
\ The checksum for the last saved commander data block is saved as part of the
\ commander file, in two places (CHK AND CHK2), to protect against file
\ tampering. This routine calculates the checksum and returns it in A.
\
\ This algorithm is also implemented in elite-checksum.py.
\
\ Returns:
\
\   A                   The checksum for the last saved commander data block
\
\ ******************************************************************************

.CHECK

 LDX #NT%-2             \ Set X to the size of the commander data block, less
                        \ 2 (to omit the checksum bytes and the save count)

 CLC                    \ Clear the C flag so we can do addition without the
                        \ C flag affecting the result

 TXA                    \ Seed the checksum calculation by setting A to the
                        \ size of the commander data block, less 2

                        \ We now loop through the commander data block,
                        \ starting at the end and looping down to the start
                        \ (so at the start of this loop, the X-th byte is the
                        \ last byte of the commander data block, i.e. the save
                        \ count)

.QUL2

 ADC NA%+7,X            \ Add the X-1-th byte of the data block to A, plus the
                        \ C flag

 EOR NA%+8,X            \ EOR A with the X-th byte of the data block

 DEX                    \ Decrement the loop counter

 BNE QUL2               \ Loop back for the next byte in the calculation, until
                        \ we have added byte #0 and EOR'd with byte #1 of the
                        \ data block

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TRNME
\       Type: Subroutine
\   Category: Save and load
\    Summary: Copy the last saved commander's name from INWK to NA%
\
\ ******************************************************************************

.TRNME

 LDX #7                 \ The commander's name can contain a maximum of 7
                        \ characters, and is terminated by a carriage return,
                        \ so set up a counter in X to copy 8 characters

.GTL1

 LDA INWK,X             \ Copy the X-th byte of INWK to the X-th byte of NA%
 STA NA%,X

 DEX                    \ Decrement the loop counter

 BPL GTL1               \ Loop back until we have copied all 8 bytes

                        \ Fall through into TR1 to copy the name back from NA%
                        \ to INWK. This isn't necessary as the name is already
                        \ there, but it does save one byte, as we don't need an
                        \ RTS here

\ ******************************************************************************
\
\       Name: TR1
\       Type: Subroutine
\   Category: Save and load
\    Summary: Copy the last saved commander's name from NA% to INWK
\
\ ******************************************************************************

.TR1

 LDX #7                 \ The commander's name can contain a maximum of 7
                        \ characters, and is terminated by a carriage return,
                        \ so set up a counter in X to copy 8 characters

.GTL2

 LDA NA%,X              \ Copy the X-th byte of NA% to the X-th byte of INWK
 STA INWK,X

 DEX                    \ Decrement the loop counter

 BPL GTL2               \ Loop back until we have copied all 8 bytes

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GTNME
\       Type: Subroutine
\   Category: Save and load
\    Summary: Fetch the name of a commander file to save or load
\
\ ------------------------------------------------------------------------------
\
\ Get the commander's name for loading or saving a commander file. The name is
\ stored in the INWK workspace and is terminated by a return character (13).
\
\ If ESCAPE is pressed or a blank name is entered, then the name stored is set
\ to the name from the last saved commander block.
\
\ Returns:
\
\   INWK                The commander name entered, terminated by a return
\                       character (13)
\
\ ******************************************************************************

.GTNME

 LDA #1                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 1

 LDA #123               \ Print recursive token 123 ("{crlf}COMMANDER'S NAME? ")
 JSR TT27

 JSR DEL8               \ Wait for 8/50 of a second (0.16 seconds)

 LDA #%10000001         \ Clear 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bit 1 (i.e. enable the CA2 interrupt,
                        \ which comes from the keyboard)

 LDA #15                \ Call OSBYTE with A = 15 (flush all buffers)
 TAX
 JSR OSBYTE

 LDX #LO(RLINE)         \ Set (Y X) to point to the RLINE parameter block
 LDY #HI(RLINE)         \ configuration block below

 LDA #0                 \ Call OSWORD with A = 0 to read a line from the current
 JSR OSWORD             \ input stream (i.e. the keyboard)

\LDA #%00000001         \ These instructions are commented out in the original
\STA VIA+&4E            \ source, but they would set 6522 System VIA interrupt
                        \ enable register IER (SHEILA &4E) bit 1 (i.e. disable
                        \ the CA2 interrupt, which comes from the keyboard)

 BCS TR1                \ The C flag will be set if we pressed ESCAPE when
                        \ entering the name, in which case jump to TR1 to copy
                        \ the last saved commander's name from NA% to INWK
                        \ and return from the subroutine there

 TYA                    \ The OSWORD call returns the length of the commander's
                        \ name in Y, so transfer this to A

 BEQ TR1                \ If A = 0, no name was entered, so jump to TR1 to copy
                        \ the last saved commander's name from NA% to INWK
                        \ and return from the subroutine there

 JMP TT67               \ We have a name, so jump to TT67 to print a newline
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: RLINE
\       Type: Variable
\   Category: Text
\    Summary: The OSWORD configuration block used to fetch a line of text from
\             the keyboard
\
\ ******************************************************************************

.RLINE

 EQUW INWK              \ The address to store the input, so the commander's
                        \ name will be stored in INWK as it is typed

 EQUB 7                 \ Maximum line length = 7, as that's the maximum size
                        \ for a commander's name

 EQUB '!'               \ Allow ASCII characters from "!" through to "z" in
 EQUB 'z'               \ the name

\ ******************************************************************************
\
\       Name: ZERO
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill pages &9, &A, &B, &C and &D
\
\ ------------------------------------------------------------------------------
\
\ This resets the following workspaces to zero:
\
\   * The ship data blocks ascending from K% at &0900
\
\   * The ship line heap descending from WP at &0D40
\
\   * WP workspace variables from FRIN to de, which include the ship slots for
\     the local bubble of universe, and various flight and ship status variables
\     (only a portion of the LSX/LSO sun line heap is cleared)
\
\ ******************************************************************************

.ZERO

 LDX #&D                \ Point X to page &D

.ZEL

 JSR ZES1               \ Call ZES1 to zero-fill the page in X

 DEX                    \ Decrement X to point to the next page

 CPX #9                 \ If X is > 9 (i.e. is &A, &B or &C), then loop back
 BNE ZEL                \ up to clear the next page

                        \ Then fall through into ZES1 with X set to 9, so we
                        \ clear page &9 too

\ ******************************************************************************
\
\       Name: ZES1
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill the page whose number is in X
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The page we want to zero-fill
\
\ ******************************************************************************

.ZES1

 LDY #0                 \ If we set Y = SC = 0 and fall through into ZES2
 STY SC                 \ below, then we will zero-fill 255 bytes starting from
                        \ SC - in other words, we will zero-fill the whole of
                        \ page X

\ ******************************************************************************
\
\       Name: ZES2
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill a specific page
\
\ ------------------------------------------------------------------------------
\
\ Zero-fill from address (X SC) + Y to (X SC) + &FF.
\
\ Arguments:
\
\   X                   The high byte (i.e. the page) of the starting point of
\                       the zero-fill
\
\   Y                   The offset from (X SC) where we start zeroing, counting
\                       up to to &FF
\
\   SC                  The low byte (i.e. the offset into the page) of the
\                       starting point of the zero-fill
\
\ Returns:
\
\   Z flag              Z flag is set
\
\ ******************************************************************************

.ZES2

 LDA #0                 \ Load A with the byte we want to fill the memory block
                        \ with - i.e. zero

 STX SC+1               \ We want to zero-fill page X, so store this in the
                        \ high byte of SC, so the 16-bit address in SC and
                        \ SC+1 is now pointing to the SC-th byte of page X

.ZEL1

 STA (SC),Y             \ Zero the Y-th byte of the block pointed to by SC,
                        \ so that's effectively the Y-th byte before SC

 INY                    \ Increment the loop counter

 BNE ZEL1               \ Loop back to zero the next byte

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SVE
\       Type: Subroutine
\   Category: Save and load
\    Summary: Save the commander file
\  Deep dive: Commander save files
\             The competition code
\
\ ******************************************************************************

.SVE

 JSR GTNME              \ Clear the screen and ask for the commander filename
                        \ to save, storing the name at INWK

 JSR TRNME              \ Transfer the commander filename from INWK to NA%

 JSR ZERO               \ Zero-fill pages &9, &A, &B, &C and &D, which clears
                        \ the ship data blocks, the ship line heap, the ship
                        \ slots for the local bubble of universe, and various
                        \ flight and ship status variables

 LSR SVC                \ Halve the save count value in SVC

 LDX #NT%               \ We now want to copy the current commander data block
                        \ from location TP to the last saved commander block at
                        \ NA%+8, so set a counter in X to copy the NT% bytes in
                        \ the commander data block
                        \
                        \ We also want to copy the data block to another
                        \ location &0B00, which is normally used for the ship
                        \ lines heap

.SVL1

 LDA TP,X               \ Copy the X-th byte of TP to the X-th byte of &0B00
 STA &0B00,X            \ and NA%+8
 STA NA%+8,X

 DEX                    \ Decrement the loop counter

 BPL SVL1               \ Loop back until we have copied all the bytes in the
                        \ commander data block

 JSR CHECK              \ Call CHECK to calculate the checksum for the last
                        \ saved commander and return it in A

 STA CHK                \ Store the checksum in CHK, which is at the end of the
                        \ last saved commander block

 PHA                    \ Store the checksum on the stack

 ORA #%10000000         \ Set K = checksum with bit 7 set
 STA K

 EOR COK                \ Set K+2 = K EOR COK (the competition flags)
 STA K+2

 EOR CASH+2             \ Set K+1 = K+2 EOR CASH+2 (the third cash byte)
 STA K+1

 EOR #&5A               \ Set K+3 = K+1 EOR &5A EOR TALLY+1 (the high byte of
 EOR TALLY+1            \ the kill tally)
 STA K+3

 JSR BPRNT              \ Print the competition number stored in K to K+3. The
                        \ value of U might affect how this is printed, and as
                        \ it's a temporary variable in zero page that isn't
                        \ reset by ZERO, it might have any value, but as the
                        \ competition code is a 10-digit number, this just means
                        \ it may or may not have an extra space of padding

 JSR TT67               \ Call TT67 twice to print two newlines
 JSR TT67

 PLA                    \ Restore the checksum from the stack

 STA &0B00+NT%          \ Store the checksum in the last byte of the save file
                        \ at &0B00 (the equivalent of CHK in the last saved
                        \ block)

 EOR #&A9               \ Store the checksum EOR &A9 in CHK2, the penultimate
 STA CHK2               \ byte of the last saved commander block

 STA &0AFF+NT%          \ Store the checksum EOR &A9 in the penultimate byte of
                        \ the save file at &0B00 (the equivalent of CHK2 in the
                        \ last saved block)

 LDY #&B                \ Set up an OSFILE block at &0C00, containing:
 STY &0C0B              \
 INY                    \ Start address for save = &00000B00 in &0C0A to &0C0D
 STY &0C0F              \
                        \ End address for save = &00000C00 in &0C0E to &0C11
                        \
                        \ Y is left containing &C which we use below

 LDA #%10000001         \ Clear 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bit 1 (i.e. enable the CA2 interrupt,
                        \ which comes from the keyboard)

 INC SVN                \ Increment SVN to indicate we are about to start saving

 LDA #0                 \ Call QUS1 with A = 0, Y = &C to save the commander
 JSR QUS1               \ file with the filename we copied to INWK at the start
                        \ of this routine

 LDX #0                 \ Set X = 0 for storing in SVN below

\STX VIA+&4E            \ This instruction is commented out in the original
                        \ source. It would affect the 6522 System VIA interrupt
                        \ enable register IER (SHEILA &4E) if any of bits 0-6
                        \ of X were set, but they aren't, so this instruction
                        \ would have no effect anyway

\DEX                    \ This instruction is commented out in the original
                        \ source. It would end up setting SVN to &FF, which
                        \ affects the logic in the IRQ1 handler

 STX SVN                \ Set SVN to 0 to indicate we are done saving

 JMP BAY                \ Go to the docking bay (i.e. show Status Mode)

\ ******************************************************************************
\
\       Name: QUS1
\       Type: Subroutine
\   Category: Save and load
\    Summary: Save or load the commander file
\  Deep dive: Commander save files
\
\ ------------------------------------------------------------------------------
\
\ The filename should be stored at INWK, terminated with a carriage return (13).
\ The routine should be called with Y set to &C.
\
\ Arguments:
\
\   A                   File operation to be performed. Can be one of the
\                       following:
\
\                         * 0 (save file)
\
\                         * &FF (load file)
\
\   Y                   Points to the page number containing the OSFILE block,
\                       which must be &C because that's where the pointer to the
\                       filename in INWK is stored below (by the STX &0C00
\                       instruction)
\
\ ******************************************************************************

.QUS1

 LDX #INWK              \ Store a pointer to INWK at the start of the block at
 STX &0C00              \ &0C00, storing #INWK in the low byte because INWK is
                        \ in zero page

 LDX #0                 \ Set X to 0 so (Y X) = &0C00

 JMP OSFILE             \ Jump to OSFILE to do the file operation specified in
                        \ &0C00 (i.e. save or load a file depending on the value
                        \ of A), returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: LOD
\       Type: Subroutine
\   Category: Save and load
\    Summary: Load a commander file
\
\ ------------------------------------------------------------------------------
\
\ The filename should be stored at INWK, terminated with a carriage return (13).
\
\ ******************************************************************************

.LOD

 LDX #2                 \ Enable the ESCAPE key and clear memory if the BREAK
 JSR FX200              \ key is pressed (*FX 200,2)

 JSR ZERO               \ Zero-fill pages &9, &A, &B, &C and &D, which clears
                        \ the ship data blocks, the ship line heap, the ship
                        \ slots for the local bubble of universe, and various
                        \ flight and ship status variables

 LDY #&B                \ Set up an OSFILE block at &0C00, containing:
 STY &0C03              \
 INC &0C0B              \ Load address = &00000B00 in &0C02 to &0C05
                        \
                        \ Length of file = &00000100 in &0C0A to &0C0D

 INY                    \ Increment Y to &C, which we use next

 LDA #&FF               \ Call QUS1 with A = &FF, Y = &C to load the commander
 JSR QUS1               \ file to address &0B00

 LDA &0B00              \ If the first byte of the loaded file has bit 7 set,
 BMI SPS1+1             \ jump to SPS+1, which is the second byte of an LDA #0
                        \ instruction, i.e. a BRK instruction, which will force
                        \ an interrupt to call the address in BRKV, which is set
                        \ to BR1... so this instruction restarts the game from
                        \ the title screen. Valid commander files for the
                        \ cassette version of Elite only have 0 for the first
                        \ byte, as there are no missions in this version, so
                        \ having bit 7 set is invalid anyway

 LDX #NT%               \ We have successfully loaded the commander file at
                        \ &0B00, so now we want to copy it to the last saved
                        \ commander data block at NA%+8, so we set up a counter
                        \ in X to copy NT% bytes

.LOL1

 LDA &0B00,X            \ Copy the X-th byte of &0B00 to the X-th byte of NA%+8
 STA NA%+8,X

 DEX                    \ Decrement the loop counter

 BPL LOL1               \ Loop back until we have copied all NT% bytes

 LDX #3                 \ Fall through into FX200 to disable the ESCAPE key and
                        \ clear memory if the BREAK key is pressed (*FX 200,3)
                        \ and return from the subroutine there

\ ******************************************************************************
\
\       Name: FX200
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Set the behaviour of the ESCAPE and BREAK keys
\
\ ------------------------------------------------------------------------------
\
\ This is the equivalent of a *FX 200 command, which controls the behaviour of
\ the ESCAPE and BREAK keys.
\
\ Arguments:
\
\   X                   Controls the behaviour as follows:
\
\                         * 0 = Enable ESCAPE key
\                               Normal BREAK key action
\
\                         * 1 = Disable ESCAPE key
\                               Normal BREAK key action
\
\                         * 2 = Enable ESCAPE key
\                               Clear memory if the BREAK key is pressed
\
\                         * 3 = Disable ESCAPE key
\                               Clear memory if the BREAK key is pressed
\
\ ******************************************************************************

.FX200

 LDY #0                 \ Call OSBYTE 200 with Y = 0, so the new value is set to
 LDA #200               \ X, and return from the subroutine using a tail call
 JMP OSBYTE

 RTS                    \ This instruction has no effect, as we already returned
                        \ from the subroutine

\ ******************************************************************************
\
\       Name: SPS1
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the vector to the planet and store it in XX15
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   SPS1+1              A BRK instruction
\
\ ******************************************************************************

.SPS1

 LDX #0                 \ Copy the two high bytes of the planet's x-coordinate
 JSR SPS3               \ into K3(2 1 0), separating out the sign bit into K3+2

 LDX #3                 \ Copy the two high bytes of the planet's y-coordinate
 JSR SPS3               \ into K3(5 4 3), separating out the sign bit into K3+5

 LDX #6                 \ Copy the two high bytes of the planet's z-coordinate
 JSR SPS3               \ into K3(8 7 6), separating out the sign bit into K3+8

                        \ Fall through into TAS2 to build XX15 from K3

\ ******************************************************************************
\
\       Name: TAS2
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Normalise the three-coordinate vector in K3
\
\ ------------------------------------------------------------------------------
\
\ Normalise the vector in K3, which has 16-bit values and separate sign bits,
\ and store the normalised version in XX15 as a signed 8-bit vector.
\
\ A normalised vector (also known as a unit vector) has length 1, so this
\ routine takes an existing vector in K3 and scales it so the length of the
\ new vector is 1. This is used in two places: when drawing the compass, and
\ when applying AI tactics to ships.
\
\ We do this in two stages. This stage shifts the 16-bit vector coordinates in
\ K3 to the left as far as they will go without losing any bits off the end, so
\ we can then take the high bytes and use them as the most accurate 8-bit vector
\ to normalise. Then the next stage (in routine NORM) does the normalisation.
\
\ Arguments:
\
\   K3(2 1 0)           The 16-bit x-coordinate as (x_sign x_hi x_lo), where
\                       x_sign is just bit 7
\
\   K3(5 4 3)           The 16-bit y-coordinate as (y_sign y_hi y_lo), where
\                       y_sign is just bit 7
\
\   K3(8 7 6)           The 16-bit z-coordinate as (z_sign z_hi z_lo), where
\                       z_sign is just bit 7
\
\ Returns:
\
\   XX15                The normalised vector, with:
\
\                         * The x-coordinate in XX15
\
\                         * The y-coordinate in XX15+1
\
\                         * The z-coordinate in XX15+2
\
\ Other entry points:
\
\   TA2                 Calculate the length of the vector in XX15 (ignoring the
\                       low coordinates), returning it in Q
\
\ ******************************************************************************

.TAS2

 LDA K3                 \ OR the three low bytes and 1 to get a byte that has
 ORA K3+3               \ a 1 wherever any of the three low bytes has a 1
 ORA K3+6               \ (as well as always having bit 0 set), and store in
 ORA #1                 \ K3+9
 STA K3+9

 LDA K3+1               \ OR the three high bytes to get a byte in A that has a
 ORA K3+4               \ 1 wherever any of the three high bytes has a 1
 ORA K3+7

                        \ (A K3+9) now has a 1 wherever any of the 16-bit
                        \ values in K3 has a 1
.TAL2

 ASL K3+9               \ Shift (A K3+9) to the left, so bit 7 of the high byte
 ROL A                  \ goes into the C flag

 BCS TA2                \ If the left shift pushed a 1 out of the end, then we
                        \ know that at least one of the coordinates has a 1 in
                        \ this position, so jump to TA2 as we can't shift the
                        \ values in K3 any further to the left

 ASL K3                 \ Shift K3(1 0), the x-coordinate, to the left
 ROL K3+1

 ASL K3+3               \ Shift K3(4 3), the y-coordinate, to the left
 ROL K3+4

 ASL K3+6               \ Shift K3(6 7), the z-coordinate, to the left
 ROL K3+7

 BCC TAL2               \ Jump back to TAL2 to do another shift left (this BCC
                        \ is effectively a JMP as we know bit 7 of K3+7 is not a
                        \ 1, as otherwise bit 7 of A would have been a 1 and we
                        \ would have taken the BCS above)

.TA2

 LDA K3+1               \ Fetch the high byte of the x-coordinate from our left-
 LSR A                  \ shifted K3, shift it right to clear bit 7, stick the
 ORA K3+2               \ sign bit in there from the x_sign part of K3, and
 STA XX15               \ store the resulting signed 8-bit x-coordinate in XX15

 LDA K3+4               \ Fetch the high byte of the y-coordinate from our left-
 LSR A                  \ shifted K3, shift it right to clear bit 7, stick the
 ORA K3+5               \ sign bit in there from the y_sign part of K3, and
 STA XX15+1             \ store the resulting signed 8-bit y-coordinate in
                        \ XX15+1

 LDA K3+7               \ Fetch the high byte of the z-coordinate from our left-
 LSR A                  \ shifted K3, shift it right to clear bit 7, stick the
 ORA K3+8               \ sign bit in there from the z_sign part of K3, and
 STA XX15+2             \ store the resulting signed 8-bit  z-coordinate in
                        \ XX15+2

                        \ Now we have a signed 8-bit version of the vector K3 in
                        \ XX15, so fall through into NORM to normalise it

\ ******************************************************************************
\
\       Name: NORM
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Normalise the three-coordinate vector in XX15
\  Deep dive: Tidying orthonormal vectors
\             Orientation vectors
\
\ ------------------------------------------------------------------------------
\
\ We do this by dividing each of the three coordinates by the length of the
\ vector, which we can calculate using Pythagoras. Once normalised, 96 (&E0) is
\ used to represent a value of 1, and 96 with bit 7 set (&E0) is used to
\ represent -1. This enables us to represent fractional values of less than 1
\ using integers.
\
\ Arguments:
\
\   XX15                The vector to normalise, with:
\
\                         * The x-coordinate in XX15
\
\                         * The y-coordinate in XX15+1
\
\                         * The z-coordinate in XX15+2
\
\ Returns:
\
\   XX15                The normalised vector
\
\   Q                   The length of the original XX15 vector
\
\ Other entry points:
\
\   NO1                 Contains an RTS
\
\ ******************************************************************************

.NORM

 LDA XX15               \ Fetch the x-coordinate into A

 JSR SQUA               \ Set (A P) = A * A = x^2

 STA R                  \ Set (R Q) = (A P) = x^2
 LDA P
 STA Q

 LDA XX15+1             \ Fetch the y-coordinate into A

 JSR SQUA               \ Set (A P) = A * A = y^2

 STA T                  \ Set (T P) = (A P) = y^2

 LDA P                  \ Set (R Q) = (R Q) + (T P) = x^2 + y^2
 ADC Q                  \
 STA Q                  \ First, doing the low bytes, Q = Q + P

 LDA T                  \ And then the high bytes, R = R + T
 ADC R
 STA R

 LDA XX15+2             \ Fetch the z-coordinate into A

 JSR SQUA               \ Set (A P) = A * A = z^2

 STA T                  \ Set (T P) = (A P) = z^2

 LDA P                  \ Set (R Q) = (R Q) + (T P) = x^2 + y^2 + z^2
 ADC Q                  \
 STA Q                  \ First, doing the low bytes, Q = Q + P

 LDA T                  \ And then the high bytes, R = R + T
 ADC R
 STA R

 JSR LL5                \ We now have the following:
                        \
                        \ (R Q) = x^2 + y^2 + z^2
                        \
                        \ so we can call LL5 to use Pythagoras to get:
                        \
                        \ Q = SQRT(R Q)
                        \   = SQRT(x^2 + y^2 + z^2)
                        \
                        \ So Q now contains the length of the vector (x, y, z),
                        \ and we can normalise the vector by dividing each of
                        \ the coordinates by this value, which we do by calling
                        \ routine TIS2. TIS2 returns the divided figure, using
                        \ 96 to represent 1 and 96 with bit 7 set for -1

 LDA XX15               \ Call TIS2 to divide the x-coordinate in XX15 by Q,
 JSR TIS2               \ with 1 being represented by 96
 STA XX15

 LDA XX15+1             \ Call TIS2 to divide the y-coordinate in XX15+1 by Q,
 JSR TIS2               \ with 1 being represented by 96
 STA XX15+1

 LDA XX15+2             \ Call TIS2 to divide the z-coordinate in XX15+2 by Q,
 JSR TIS2               \ with 1 being represented by 96
 STA XX15+2

.NO1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RDKEY
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard for key presses
\
\ ------------------------------------------------------------------------------
\
\ Scan the keyboard, starting with internal key number 16 ("Q") and working
\ through the set of internal key numbers (see p.142 of the Advanced User Guide
\ for a list of internal key numbers).
\
\ This routine is effectively the same as OSBYTE 122, though the OSBYTE call
\ preserves A, unlike this routine.
\
\ Returns:
\
\   X                   If a key is being pressed, X contains the internal key
\                       number, otherwise it contains 0
\
\   A                   Contains the same as X
\
\ ******************************************************************************

.RDKEY

 LDX #16                \ Start the scan with internal key number 16 ("Q")

.Rd1

 JSR DKS4               \ Scan the keyboard to see if the key in X is currently
                        \ being pressed, returning the result in A and X

 BMI Rd2                \ Jump to Rd2 if this key is being pressed (in which
                        \ case DKS4 will have returned the key number with bit
                        \ 7 set, which is negative)

 INX                    \ Increment the key number, which was unchanged by the
                        \ above call to DKS4

 BPL Rd1                \ Loop back to test the next key, ending the loop when
                        \ X is negative (i.e. 128)

 TXA                    \ If we get here, nothing is being pressed, so copy X
                        \ into A so that X = A = 128 = %10000000

.Rd2

 EOR #%10000000         \ EOR A with #%10000000 to flip bit 7, so A now contains
                        \ 0 if no key has been pressed, or the internal key
                        \ number if a key has been pressed

 TAX                    \ Copy A into X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ECMOF
\       Type: Subroutine
\   Category: Sound
\    Summary: Switch off the E.C.M.
\
\ ------------------------------------------------------------------------------
\
\ Switch the E.C.M. off, turn off the dashboard bulb and make the sound of the
\ E.C.M. switching off).
\
\ ******************************************************************************

.ECMOF

 LDA #0                 \ Set ECMA and ECMB to 0 to indicate that no E.C.M. is
 STA ECMA               \ currently running
 STA ECMP

 JSR ECBLB              \ Update the E.C.M. indicator bulb on the dashboard

 LDA #72                \ Call the NOISE routine with A = 72 to make the sound
 BNE NOISE              \ of the E.C.M. being turned off and return from the
                        \ subroutine using a tail call (this BNE is effectively
                        \ a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: EXNO3
\       Type: Subroutine
\   Category: Sound
\    Summary: Make an explosion sound
\
\ ------------------------------------------------------------------------------
\
\ Make the sound of death in the cold, hard vacuum of space. Apparently, in
\ Elite space, everyone can hear you scream.
\
\ This routine also makes the sound of a destroyed cargo canister if we don't
\ get scooping right, the sound of us colliding with another ship, and the sound
\ of us being hit with depleted shields. It is not a good sound to hear.
\
\ ******************************************************************************

.EXNO3

 LDA #16                \ Call the NOISE routine with A = 16 to make the first
 JSR NOISE              \ death sound

 LDA #24                \ Call the NOISE routine with A = 24 to make the second
 BNE NOISE              \ death sound and return from the subroutine using a
                        \ tail call (this BNE is effectively a JMP as A will
                        \ never be zero)

\ ******************************************************************************
\
\       Name: SFRMIS
\       Type: Subroutine
\   Category: Tactics
\    Summary: Add an enemy missile to our local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ An enemy has fired a missile, so add the missile to our universe if there is
\ room, and if there is, make the appropriate warnings and noises.
\
\ ******************************************************************************

.SFRMIS

 LDX #MSL               \ Set X to the ship type of a missile, and call SFS1-2
 JSR SFS1-2             \ to add the missile to our universe with an AI flag
                        \ of %11111110 (AI enabled, hostile, no E.C.M.)

 BCC NO1                \ The C flag will be set if the call to SFS1-2 was a
                        \ success, so if it's clear, jump to NO1 to return from
                        \ the subroutine (as NO1 contains an RTS)

 LDA #120               \ Print recursive token 120 ("INCOMING MISSILE") as an
 JSR MESS               \ in-flight message

 LDA #48                \ Call the NOISE routine with A = 48 to make the sound
 BNE NOISE              \ of the missile being launched and return from the
                        \ subroutine using a tail call (this BNE is effectively
                        \ a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: EXNO2
\       Type: Subroutine
\   Category: Sound
\    Summary: Process us making a kill
\  Deep dive: Combat rank
\
\ ------------------------------------------------------------------------------
\
\ We have killed a ship, so increase the kill tally, displaying an iconic
\ message of encouragement if the kill total is a multiple of 256, and then
\ make a nearby explosion sound.
\
\
\ ******************************************************************************

.EXNO2

 INC TALLY              \ Increment the low byte of the kill count in TALLY

 BNE EXNO-2             \ If there is no carry, jump to the LDX #7 below (at
                        \ EXNO-2)

 INC TALLY+1            \ Increment the high byte of the kill count in TALLY

 LDA #101               \ The kill total is a multiple of 256, so it's time
 JSR MESS               \ for a pat on the back, so print recursive token 101
                        \ ("RIGHT ON COMMANDER!") as an in-flight message

 LDX #7                 \ Set X = 7 and fall through into EXNO to make the
                        \ sound of a ship exploding

\ ******************************************************************************
\
\       Name: EXNO
\       Type: Subroutine
\   Category: Sound
\    Summary: Make the sound of a laser strike or ship explosion
\
\ ------------------------------------------------------------------------------
\
\ Make the two-part explosion sound of us making a laser strike, or of another
\ ship exploding.
\
\ The volume of the first explosion is affected by the distance of the ship
\ being hit, with more distant ships being quieter. The value in X also affects
\ the volume of the first explosion, with a higher X giving a quieter sound
\ (so X can be used to differentiate a laser strike from an explosion).
\
\ Arguments:
\
\   X                   The larger the value of X, the fainter the explosion.
\                       Allowed values are:
\
\                         * 7  = explosion is louder (i.e. the ship has just
\                                exploded)
\
\                         * 15 = explosion is quieter (i.e. this is just a laser
\                                strike)
\
\ Other entry points:
\
\   EXNO-2              Set X = 7 and fall through into EXNO to make the sound
\                       of a ship exploding
\
\ ******************************************************************************

.EXNO

 STX T                  \ Store the distance in T

 LDA #24                \ Set A = 24 to denote the sound of us making a hit or
 JSR NOS1               \ kill (part 1 of the explosion), and call NOS1 to set
                        \ up the sound block in XX16

 LDA INWK+7             \ Fetch z_hi, the distance of the ship being hit in
 LSR A                  \ terms of the z-axis (in and out of the screen), and
 LSR A                  \ divide by 4. If z_hi has either bit 6 or 7 set then
                        \ that ship is too far away to be shown on the scanner
                        \ (as per the SCAN routine), so we know the maximum
                        \ z_hi at this point is %00111111, and shifting z_hi
                        \ to the right twice gives us a maximum value of
                        \ %00001111

 AND T                  \ This reduces A to a maximum of X; X can be either
                        \ 7 = %0111 or 15 = %1111, so AND'ing with 15 will
                        \ not affect A, while AND'ing with 7 will clear bit
                        \ 3, reducing the maximum value in A to 7

 ORA #%11110001         \ The SOUND statement's amplitude ranges from 0 (for no
                        \ sound) to -15 (full volume), so we can set bits 0 and
                        \ 4-7 in A, and keep bits 1-3 from the above to get
                        \ a value between -15 (%11110001) and -1 (%11111111),
                        \ with lower values of z_hi and argument X leading
                        \ to a more negative, or quieter number (so the closer
                        \ the ship, i.e. the smaller the value of X, the louder
                        \ the sound)

 STA XX16+2             \ The amplitude byte of the sound block in XX16 is in
                        \ byte #3 (where it's the low byte of the amplitude), so
                        \ this sets the amplitude to the value in A

 JSR NO3                \ Make the sound from our updated sound block in XX16

 LDA #16                \ Set A = 16 to denote we have made a hit or kill
                        \ (part 2 of the explosion), and fall through into NOISE
                        \ to make the sound

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &20, or BIT &20A9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: BEEP
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a short, high beep
\
\ ******************************************************************************

.BEEP

 LDA #32                \ Set A = 32 to denote a short, high beep, and fall
                        \ through into the NOISE routine to make the sound

\ ******************************************************************************
\
\       Name: NOISE
\       Type: Subroutine
\   Category: Sound
\    Summary: Make the sound whose number is in A
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of the sound to be made. See the
\                       documentation for variable SFX for a list of sound
\                       numbers
\
\ ******************************************************************************

.NOISE

 JSR NOS1               \ Set up the sound block in XX16 for the sound in A and
                        \ fall through into NO3 to make the sound

\ ******************************************************************************
\
\       Name: NO3
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a sound from a prepared sound block
\
\ ------------------------------------------------------------------------------
\
\ Make a sound from a prepared sound block in XX16 (if sound is enabled). See
\ routine NOS1 for details of preparing the XX16 sound block.
\
\ ******************************************************************************

.NO3

 LDX DNOIZ              \ Set X to the DNOIZ configuration setting

 BNE NO1                \ If DNOIZ is non-zero, then sound is disabled, so
                        \ return from the subroutine (as NO1 contains an RTS)

 LDX #LO(XX16)          \ Otherwise set (Y X) to point to the sound block in
 LDY #HI(XX16)          \ XX16

 LDA #7                 \ Call OSWORD 7 to makes the sound, as described in the
 JMP OSWORD             \ documentation for variable SFX, and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: NOS1
\       Type: Subroutine
\   Category: Sound
\    Summary: Prepare a sound block
\
\ ------------------------------------------------------------------------------
\
\ Copy four sound bytes from SFX into XX16, interspersing them with null bytes,
\ with Y indicating the sound number to copy (from the values in the sound
\ table at SFX). So, for example, if we call this routine with A = 40 (long,
\ low beep), the following bytes will be set in XX16 to XX16+7:
\
\   &13 &00 &F4 &00 &0C &00 &08 &00
\
\ This block will be passed to OSWORD 7 to make the sound, which expects the
\ four sound attributes as 16-bit big-endian values - in other words, with the
\ low byte first. So the above block would pass the values &0013, &00F4, &000C
\ and &0008 to the SOUND statement when used with OSWORD 7, or:
\
\   SOUND &13, &F4, &0C, &08
\
\ as the high bytes are always zero.
\
\ Arguments:
\
\   A                   The sound number to copy from SFX to XX16, which is
\                       always a multiple of 8
\
\ ******************************************************************************

.NOS1

 LSR A                  \ Divide A by 2, and also clear the C flag, as bit 0 of
                        \ A is always zero (as A is a multiple of 8)

 ADC #3                 \ Set Y = A + 3, so Y now points to the last byte of
 TAY                    \ four within the block of four-byte values

 LDX #7                 \ We want to copy four bytes, spread out into an 8-byte
                        \ block, so set a counter in Y to cover 8 bytes

.NOL1

 LDA #0                 \ Set the X-th byte of XX16 to 0
 STA XX16,X

 DEX                    \ Decrement the destination byte pointer

 LDA SFX,Y              \ Set the X-th byte of XX16 to the value from SFX+Y
 STA XX16,X

 DEY                    \ Decrement the source byte pointer again

 DEX                    \ Decrement the destination byte pointer again

 BPL NOL1               \ Loop back for the next source byte

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: KYTB
\       Type: Variable
\   Category: Keyboard
\    Summary: Lookup table for in-flight keyboard controls
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
\
\ Keyboard table for in-flight controls. This table contains the internal key
\ codes for the flight keys (see p.142 of the Advanced User Guide for a list of
\ internal key numbers).
\
\ The pitch, roll, speed and laser keys (i.e. the seven primary flight
\ control keys) have bit 7 set, so they have 128 added to their internal
\ values. This doesn't appear to be used anywhere.
\
\ ******************************************************************************

KYTB = P% - 1           \ Point KYTB to the byte before the start of the table

                        \ These are the primary flight controls (pitch, roll,
                        \ speed and lasers):

 EQUB &68 + 128         \ ?         KYTB+1      Slow down
 EQUB &62 + 128         \ Space     KYTB+2      Speed up
 EQUB &66 + 128         \ <         KYTB+3      Roll left
 EQUB &67 + 128         \ >         KYTB+4      Roll right
 EQUB &42 + 128         \ X         KYTB+5      Pitch up
 EQUB &51 + 128         \ S         KYTB+6      Pitch down
 EQUB &41 + 128         \ A         KYTB+7      Fire lasers

                        \ These are the secondary flight controls:

 EQUB &60               \ TAB       KYTB+8      Energy bomb
 EQUB &70               \ ESCAPE    KYTB+9      Launch escape pod
 EQUB &23               \ T         KYTB+10     Arm missile
 EQUB &35               \ U         KYTB+11     Unarm missile
 EQUB &65               \ M         KYTB+12     Fire missile
 EQUB &22               \ E         KYTB+13     E.C.M.
 EQUB &45               \ J         KYTB+14     In-system jump
 EQUB &52               \ C         KYTB+15     Docking computer

\ ******************************************************************************
\
\       Name: DKS1
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard for a flight key
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
\
\ Scan the keyboard for the flight key given in register Y, where Y is the
\ offset into the KYTB table above (so we can scan for Space by setting Y to
\ 2, for example). If the key is pressed, set the corresponding byte in the
\ key logger at KL to &FF.
\
\ Arguments:
\
\   Y                   The offset into the KYTB table above of the key that we
\                       want to scan on the keyboard
\
\ ******************************************************************************

.DKS1

 LDX KYTB,Y             \ Get the internal key number from the Y-th byte of the
                        \ KYTB table above

 JSR DKS4               \ Call DKS4, which will set A and X to a negative value
                        \ if the key is being pressed

 BPL DKS2-1             \ The key is not being pressed, so return from the
                        \ subroutine (as DKS2-1 contains an RTS)

 LDX #&FF               \ Store &FF in the Y-th byte of the key logger at KL
 STX KL,Y

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CTRL
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard to see if CTRL is currently pressed
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   X = %10000001 (i.e. 129 or -127) if CTRL is being
\                       pressed
\
\                       X = 1 if CTRL is not being pressed
\
\   A                   Contains the same as X
\
\ ******************************************************************************

.CTRL

 LDX #1                 \ Set X to the internal key number for CTRL and fall
                        \ through to DKS4 to scan the keyboard

\ ******************************************************************************
\
\       Name: DKS4
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard to see if a specific key is being pressed
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The internal number of the key to check (see p.142 of
\                       the Advanced User Guide for a list of internal key
\                       numbers)
\
\ Returns:
\
\   A                   If the key in A is being pressed, A contains the
\                       original argument A, but with bit 7 set (i.e. A + 128).
\                       If the key in A is not being pressed, the value in A is
\                       unchanged
\
\   X                   Contains the same as A
\
\ ******************************************************************************

.DKS4

 LDA #%00000011         \ Set A to %00000011, so it's ready to send to SHEILA
                        \ once interrupts have been disabled

 SEI                    \ Disable interrupts so we can scan the keyboard
                        \ without being hijacked

 STA VIA+&40            \ Set 6522 System VIA output register ORB (SHEILA &40)
                        \ to %00000011 to stop auto scan of keyboard

 LDA #%01111111         \ Set 6522 System VIA data direction register DDRA
 STA VIA+&43            \ (SHEILA &43) to %01111111. This sets the A registers
                        \ (IRA and ORA) so that:
                        \
                        \   * Bits 0-6 of ORA will be sent to the keyboard
                        \
                        \   * Bit 7 of IRA will be read from the keyboard

 STX VIA+&4F            \ Set 6522 System VIA output register ORA (SHEILA &4F)
                        \ to X, the key we want to scan for; bits 0-6 will be
                        \ sent to the keyboard, of which bits 0-3 determine the
                        \ keyboard column, and bits 4-6 the keyboard row

 LDX VIA+&4F            \ Read 6522 System VIA output register IRA (SHEILA &4F)
                        \ into X; bit 7 is the only bit that will have changed.
                        \ If the key is pressed, then bit 7 will be set,
                        \ otherwise it will be clear

 LDA #%00001011         \ Set 6522 System VIA output register ORB (SHEILA &40)
 STA VIA+&40            \ to %00001011 to restart auto scan of keyboard

 CLI                    \ Allow interrupts again

 TXA                    \ Transfer X into A

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DKS2
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Read the joystick position
\
\ ------------------------------------------------------------------------------
\
\ Return the value of ADC channel in X (used to read the joystick). The value
\ will be inverted if the game has been configured to reverse both joystick
\ channels (which can be done by pausing the game and pressing J).
\
\ Arguments:
\
\   X                   The ADC channel to read:
\
\                         * 1 = joystick X
\
\                         * 2 = joystick Y
\
\ Returns:
\
\   (A X)               The 16-bit value read from channel X, with the value
\                       inverted if the game has been configured to reverse the
\                       joystick
\
\ Other entry points:
\
\   DKS2-1              Contains an RTS
\
\ ******************************************************************************

.DKS2

 LDA #128               \ Call OSBYTE with A = 128 to fetch the 16-bit value
 JSR OSBYTE             \ from ADC channel X, returning (Y X), i.e. the high
                        \ byte in Y and the low byte in X

 TYA                    \ Copy Y to A, so the result is now in (A X)

 EOR JSTE               \ The high byte A is now EOR'd with the value in
                        \ location JSTE, which contains &FF if both joystick
                        \ channels are reversed and 0 otherwise (so A now
                        \ contains the high byte but inverted, if that's what
                        \ the current settings say)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DKS3
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Toggle a configuration setting and emit a beep
\
\ ------------------------------------------------------------------------------
\
\ This is called when the game is paused and a key is pressed that changes the
\ game's configuration.
\
\ Specifically, this routine toggles the configuration settings for the
\ following keys:
\
\   * CAPS LOCK toggles keyboard flight damping (&40)
\   * A toggles keyboard auto-recentre (&41)
\   * X toggles author names on start-up screen (&42)
\   * F toggles flashing console bars (&43)
\   * Y toggles reverse joystick Y channel (&44)
\   * J toggles reverse both joystick channels (&45)
\   * K toggles keyboard and joystick (&46)
\
\ The numbers in brackets are the internal key numbers (see p.142 of the
\ Advanced User Guide for a list of internal key numbers). We pass the key that
\ has been pressed in X, and the configuration option to check it against in Y,
\ so this routine is typically called in a loop that loops through the various
\ configuration options.
\
\ Arguments:
\
\   X                   The internal number of the key that's been pressed
\
\   Y                   The internal number of the configuration key to check
\                       against, from the list above (i.e. Y must be from &40 to
\                       &46)
\
\ ******************************************************************************

.DKS3

 STY T                  \ Store the configuration key argument in T

 CPX T                  \ If X <> Y, jump to Dk3 to return from the subroutine
 BNE Dk3

                        \ We have a match between X and Y, so now to toggle
                        \ the relevant configuration byte. CAPS LOCK has a key
                        \ value of &40 and has its configuration byte at
                        \ location DAMP, A has a value of &41 and has its byte
                        \ at location DJD, which is DAMP+1, and so on. So we
                        \ can toggle the configuration byte by changing the
                        \ byte at DAMP + (X - &40), or to put it in indexing
                        \ terms, DAMP-&40,X. It's no coincidence that the
                        \ game's configuration bytes are set up in this order
                        \ and with these keys (and this is also why the sound
                        \ on/off keys are dealt with elsewhere, as the internal
                        \ key for S and Q are &51 and &10, which don't fit
                        \ nicely into this approach)

 LDA DAMP-&40,X         \ Fetch the byte from DAMP + (X - &40), invert it and
 EOR #&FF               \ put it back (0 means no and &FF means yes in the
 STA DAMP-&40,X         \ configuration bytes, so this toggles the setting)

 JSR BELL               \ Make a beep sound so we know something has happened

 JSR DELAY              \ Wait for Y vertical syncs (Y is between 64 and 70, so
                        \ this is always a bit longer than a second)

 LDY T                  \ Restore the configuration key argument into Y

.Dk3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DKJ1
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Read joystick and flight controls
\
\ ------------------------------------------------------------------------------
\
\ Specifically, scan the keyboard for the speed up and slow down keys, and read
\ the joystick's fire button and X and Y axes, storing the results in the key
\ logger and the joystick position variables.
\
\ This routine is only called if joysticks are enabled (JSTK = non-zero).
\
\ ******************************************************************************

.DKJ1

 LDY #1                 \ Update the key logger for key 1 in the KYTB table, so
 JSR DKS1               \ KY1 will be &FF if "?" (slow down) is being pressed

 INY                    \ Update the key logger for key 2 in the KYTB table, so
 JSR DKS1               \ KY2 will be &FF if Space (speed up) is being pressed

 LDA VIA+&40            \ Read 6522 System VIA input register IRB (SHEILA &40)

 TAX                    \ This instruction doesn't seem to have any effect, as
                        \ X is overwritten in a few instructions. When the
                        \ joystick is checked in a similar way in the TITLE
                        \ subroutine for the "Press Fire Or Space,Commander."
                        \ stage of the start-up screen, there's another
                        \ unnecessary TAX instruction present, but there it's
                        \ commented out

 AND #%00010000         \ Bit 4 of IRB (PB4) is clear if joystick 1's fire
                        \ button is pressed, otherwise it is set, so AND'ing
                        \ the value of IRB with %10000 extracts this bit

 EOR #%00010000         \ Flip bit 4 so that it's set if the fire button has
 STA KY7                \ been pressed, and store the result in the keyboard
                        \ logger at location KY7, which is also where the A key
                        \ (fire lasers) key is logged

 LDX #1                 \ Call DKS2 to fetch the value of ADC channel 1 (the
 JSR DKS2               \ joystick X value) into (A X), and OR A with 1. This
 ORA #1                 \ ensures that the high byte is at least 1, and then we
 STA JSTX               \ store the result in JSTX

 LDX #2                 \ Call DKS2 to fetch the value of ADC channel 2 (the
 JSR DKS2               \ joystick Y value) into (A X), and EOR A with JSTGY.
 EOR JSTGY              \ JSTGY will be &FF if the game is configured to
 STA JSTY               \ reverse the joystick Y channel, so this EOR does
                        \ exactly that, and then we store the result in JSTY

 JMP DK4                \ We are done scanning the joystick flight controls,
                        \ so jump to DK4 to scan for other keys, using a tail
                        \ call so we can return from the subroutine there

\ ******************************************************************************
\
\       Name: U%
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Clear the key logger
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   A is set to 0
\
\   Y                   Y is set to 0
\
\ ******************************************************************************

.U%

 LDA #0                 \ Set A to 0, as this means "key not pressed" in the
                        \ key logger at KL

 LDY #15                \ We want to clear the 15 key logger locations from
                        \ KY1 to KY19, so set a counter in Y

.DKL3

 STA KL,Y               \ Store 0 in the Y-th byte of the key logger

 DEY                    \ Decrement the counter

 BNE DKL3               \ And loop back for the next key, until we have just
                        \ KL+1. We don't want to clear the first key logger
                        \ location at KL, as the keyboard table at KYTB starts
                        \ with offset 1, not 0, so KL is not technically part of
                        \ the key logger (it's actually used for logging keys
                        \ that don't appear in the keyboard table, and which
                        \ therefore don't use the key logger)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DOKEY
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan for the seven primary flight controls
\  Deep dive: The key logger
\             The docking computer
\
\ ------------------------------------------------------------------------------
\
\ Scan for the seven primary flight controls (or the equivalent on joystick),
\ pause and configuration keys, and secondary flight controls, and update the
\ key logger accordingly. Specifically:
\
\   * If we are on keyboard configuration, clear the key logger and update it
\     for the seven primary flight controls, and update the pitch and roll
\     rates accordingly.
\
\   * If we are on joystick configuration, clear the key logger and jump to
\     DKJ1, which reads the joystick equivalents of the primary flight
\     controls.
\
\ Both options end up at DK4 to scan for other keys, beyond the seven primary
\ flight controls.
\
\ ******************************************************************************

.DOKEY

 JSR U%                 \ Call U% to clear the key logger

 LDA JSTK               \ If JSTK is non-zero, then we are configured to use
 BNE DKJ1               \ the joystick rather than keyboard, so jump to DKJ1
                        \ to read the joystick flight controls, before jumping
                        \ to DK4 to scan for pause, configuration and secondary
                        \ flight keys

 LDY #7                 \ We're going to work our way through the primary flight
                        \ control keys (pitch, roll, speed and laser), so set a
                        \ counter in Y so we can loop through all 7

.DKL2

 JSR DKS1               \ Call DKS1 to see if the KYTB key at offset Y is being
                        \ pressed, and set the key logger accordingly

 DEY                    \ Decrement the loop counter

 BNE DKL2               \ Loop back for the next key, working our way from A at
                        \ KYTB+7 down to ? at KYTB+1

 LDX JSTX               \ Set X = JSTX, the current roll rate (as shown in the
                        \ RL indicator on the dashboard)

 LDA #7                 \ Set A to 7, which is the amount we want to alter the
                        \ roll rate by if the roll keys are being pressed

 LDY KL+3               \ If the "<" key is being pressed, then call the BUMP2
 BEQ P%+5               \ routine to increase the roll rate in X by A
 JSR BUMP2

 LDY KL+4               \ If the ">" key is being pressed, then call the REDU2
 BEQ P%+5               \ routine to decrease the roll rate in X by A, taking
 JSR REDU2              \ the keyboard auto re-centre setting into account

 STX JSTX               \ Store the updated roll rate in JSTX

 ASL A                  \ Double the value of A, to 14

 LDX JSTY               \ Set X = JSTY, the current pitch rate (as shown in the
                        \ DC indicator on the dashboard)

 LDY KL+5               \ If the "X" key is being pressed, then call the REDU2
 BEQ P%+5               \ routine to decrease the pitch rate in X by A, taking
 JSR REDU2              \ the keyboard auto re-centre setting into account

 LDY KL+6               \ If the "S" key is being pressed, then call the BUMP2
 BEQ P%+5               \ routine to increase the pitch rate in X by A
 JSR BUMP2

 STX JSTY               \ Store the updated roll rate in JSTY

                        \ Fall through into DK4 to scan for other keys

\ ******************************************************************************
\
\       Name: DK4
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan for pause, configuration and secondary flight keys
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
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
\
\ ******************************************************************************

.DK4

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 STX KL                 \ Store X in KL, byte #0 of the key logger

 CPX #&69               \ If COPY is not being pressed, jump to DK2 below,
 BNE DK2                \ otherwise let's process the configuration keys

.FREEZE

                        \ COPY is being pressed, so we enter a loop that
                        \ listens for configuration keys, and we keep looping
                        \ until we detect a DELETE key press. This effectively
                        \ pauses the game when COPY is pressed, and unpauses
                        \ it when DELETE is pressed

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 CPX #&51               \ If "S" is not being pressed, skip to DK6
 BNE DK6

 LDA #0                 \ "S" is being pressed, so set DNOIZ to 0 to turn the
 STA DNOIZ              \ sound on

.DK6

 LDY #&40               \ We now want to loop through the keys that toggle
                        \ various settings. These have internal key numbers
                        \ between &40 (CAPS LOCK) and &46 ("K"), so we set up
                        \ the first key number in Y to act as a loop counter.
                        \ See subroutine DKS3 for more details on this

.DKL4

 JSR DKS3               \ Call DKS3 to scan for the key given in Y, and toggle
                        \ the relevant setting if it is pressed

 INY                    \ Increment Y to point to the next toggle key

 CPY #&47               \ The last toggle key is &46 (K), so check whether we
                        \ have just done that one

 BNE DKL4               \ If not, loop back to check for the next toggle key

.DK55

 CPX #&10               \ If "Q" is not being pressed, skip to DK7
 BNE DK7

 STX DNOIZ              \ "Q" is being pressed, so set DNOIZ to X, which is
                        \ non-zero (&10), so this will turn the sound off

.DK7

 CPX #&70               \ If ESCAPE is not being pressed, skip over the next
 BNE P%+5               \ instruction

 JMP DEATH2             \ ESCAPE is being pressed, so jump to DEATH2 to end
                        \ the game

 CPX #&59               \ If DELETE is not being pressed, we are still paused,
 BNE FREEZE             \ so loop back up to keep listening for configuration
                        \ keys, otherwise fall through into the rest of the
                        \ key detection code, which unpauses the game

.DK2

 LDA QQ11               \ If the current view is non-zero (i.e. not a space
 BNE DK5                \ view), return from the subroutine (as DK5 contains
                        \ an RTS)

 LDY #15                \ This is a space view, so now we want to check for all
                        \ the secondary flight keys. The internal key numbers
                        \ are in the keyboard table KYTB from KYTB+8 to
                        \ KYTB+15, and their key logger locations are from KL+8
                        \ to KL+15. So set a decreasing counter in Y for the
                        \ index, starting at 15, so we can loop through them

 LDA #&FF               \ Set A to &FF so we can store this in the keyboard
                        \ logger for keys that are being pressed

.DKL1

 LDX KYTB,Y             \ Get the internal key number of the Y-th flight key
                        \ the KYTB keyboard table

 CPX KL                 \ We stored the key that's being pressed in KL above,
                        \ so check to see if the Y-th flight key is being
                        \ pressed

 BNE DK1                \ If it is not being pressed, skip to DK1 below

 STA KL,Y               \ The Y-th flight key is being pressed, so set that
                        \ key's location in the key logger to &FF

.DK1

 DEY                    \ Decrement the loop counter

 CPY #7                 \ Have we just done the last key?

 BNE DKL1               \ If not, loop back to process the next key

.DK5

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT217
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard until a key is pressed
\
\ ------------------------------------------------------------------------------
\
\ Scan the keyboard until a key is pressed, and return the key's ASCII code.
\ If, on entry, a key is already being held down, then wait until that key is
\ released first (so this routine detects the first key down event following
\ the subroutine call).
\
\ Returns:
\
\   X                   The ASCII code of the key that was pressed
\
\   A                   Contains the same as X
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   out                 Contains an RTS
\
\ ******************************************************************************

.TT217

 STY YSAV               \ Store Y in temporary storage, so we can restore it
                        \ later

.t

 JSR DELAY-5            \ Delay for 8 vertical syncs (8/50 = 0.16 seconds) so we
                        \ don't take up too much CPU time while looping round

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 BNE t                  \ If a key was already being held down when we entered
                        \ this routine, keep looping back up to t, until the
                        \ key is released

.t2

 JSR RDKEY              \ Any pre-existing key press is now gone, so we can
                        \ start scanning the keyboard again, returning the
                        \ internal key number in X (or 0 for no key press)

 BEQ t2                 \ Keep looping up to t2 until a key is pressed

 TAY                    \ Copy A to Y, so Y contains the internal key number
                        \ of the key pressed

 LDA (TRTB%),Y          \ The address in TRTB% points to the MOS key
                        \ translation table, which is used to translate
                        \ internal key numbers to ASCII, so this fetches the
                        \ key's ASCII code into A

 LDY YSAV               \ Restore the original value of Y we stored above

 TAX                    \ Copy A into X

.out

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: me1
\       Type: Subroutine
\   Category: Text
\    Summary: Erase an old in-flight message and display a new one
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\   X                   Must be set to 0
\
\ ******************************************************************************

.me1

 STX DLY                \ Set the message delay in DLY to 0, so any new
                        \ in-flight messages will be shown instantly

 PHA                    \ Store the new message token we want to print

 LDA MCH                \ Set A to the token number of the message that is
 JSR mes9               \ currently on-screen, and call mes9 to print it (which
                        \ will remove it from the screen, as printing is done
                        \ using EOR logic)

 PLA                    \ Restore the new message token

 EQUB &2C               \ Fall through into ou2 to print the new message, but
                        \ skip the first instruction by turning it into
                        \ &2C &A9 &6C, or BIT &6CA9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: ou2
\       Type: Subroutine
\   Category: Text
\    Summary: Display "E.C.M.SYSTEM DESTROYED" as an in-flight message
\
\ ******************************************************************************

.ou2

 LDA #108               \ Set A to recursive token 108 ("E.C.M.SYSTEM")

 EQUB &2C               \ Fall through into ou3 to print the new message, but
                        \ skip the first instruction by turning it into
                        \ &2C &A9 &6F, or BIT &6FA9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: ou3
\       Type: Subroutine
\   Category: Text
\    Summary: Display "FUEL SCOOPS DESTROYED" as an in-flight message
\
\ ******************************************************************************

.ou3

 LDA #111               \ Set A to recursive token 111 ("FUEL SCOOPS")

\ ******************************************************************************
\
\       Name: MESS
\       Type: Subroutine
\   Category: Text
\    Summary: Display an in-flight message
\
\ ------------------------------------------------------------------------------
\
\ Display an in-flight message in capitals at the bottom of the space view,
\ erasing any existing in-flight message first.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.MESS

 LDX #0                 \ Set QQ17 = 0 to switch to ALL CAPS
 STX QQ17

 LDY #9                 \ Move the text cursor to column 9, row 22, at the
 STY XC                 \ bottom middle of the screen, and set Y = 22
 LDY #22
 STY YC

 CPX DLY                \ If the message delay in DLY is not zero, jump up to
 BNE me1                \ me1 to erase the current message first (whose token
                        \ number will be in MCH)

 STY DLY                \ Set the message delay in DLY to 22

 STA MCH                \ Set MCH to the token we are about to display

                        \ Fall through into mes9 to print the token in A

\ ******************************************************************************
\
\       Name: mes9
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token, possibly followed by " DESTROYED"
\
\ ------------------------------------------------------------------------------
\
\ Print a text token, followed by " DESTROYED" if the destruction flag is set
\ (for when a piece of equipment is destroyed).
\
\ ******************************************************************************

.mes9

 JSR TT27               \ Call TT27 to print the text token in A

 LSR de                 \ If bit 0 of variable de is clear, return from the
 BCC out                \ subroutine (as out contains an RTS)

 LDA #253               \ Print recursive token 93 (" DESTROYED") and return
 JMP TT27               \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: OUCH
\       Type: Subroutine
\   Category: Flight
\    Summary: Potentially lose cargo or equipment following damage
\
\ ------------------------------------------------------------------------------
\
\ Our shields are dead and we are taking damage, so there is a small chance of
\ losing cargo or equipment.
\
\ ******************************************************************************

.OUCH

 JSR DORND              \ Set A and X to random numbers

 BMI out                \ If A < 0 (50% chance), return from the subroutine
                        \ (as out contains an RTS)

 CPX #22                \ If X >= 22 (91% chance), return from the subroutine
 BCS out                \ (as out contains an RTS)

 LDA QQ20,X             \ If we do not have any of item QQ20+X, return from the
 BEQ out                \ subroutine (as out contains an RTS). X is in the range
                        \ 0-21, so this not only checks for cargo, but also for
                        \ E.C.M., fuel scoops, energy bomb, energy unit and
                        \ docking computer, all of which can be destroyed

 LDA DLY                \ If there is already an in-flight message on-screen,
 BNE out                \ return from the subroutine (as out contains an RTS)

 LDY #3                 \ Set bit 1 of de, the equipment destruction flag, so
 STY de                 \ that when we call MESS below, " DESTROYED" is appended
                        \ to the in-flight message

 STA QQ20,X             \ A is 0 (as we didn't branch with the BNE above), so
                        \ this sets QQ20+X to 0, which destroys any cargo or
                        \ equipment we have of that type

 CPX #17                \ If X >= 17 then we just lost a piece of equipment, so
 BCS ou1                \ jump to ou1 to print the relevant message

 TXA                    \ Print recursive token 48 + A as an in-flight token,
 ADC #208               \ which will be in the range 48 ("FOOD") to 64 ("ALIEN
 BNE MESS               \ ITEMS") as the C flag is clear, so this prints the
                        \ destroyed item's name, followed by " DESTROYED" (as we
                        \ set bit 1 of the de flag above), and returns from the
                        \ subroutine using a tail call

.ou1

 BEQ ou2                \ If X = 17, jump to ou2 to print "E.C.M.SYSTEM
                        \ DESTROYED" and return from the subroutine using a tail
                        \ call

 CPX #18                \ If X = 18, jump to ou3 to print "FUEL SCOOPS
 BEQ ou3                \ DESTROYED" and return from the subroutine using a tail
                        \ call

 TXA                    \ Otherwise X is in the range 19 to 21 and the C flag is
 ADC #113-20            \ set (as we got here via a BCS to ou1), so we set A as
                        \ follows:
                        \
                        \   A = 113 - 20 + X + C
                        \     = 113 - 19 + X
                        \     = 113 to 115

 BNE MESS               \ Print recursive token A ("ENERGY BOMB", "ENERGY UNIT"
                        \ or "DOCKING COMPUTERS") as an in-flight message,
                        \ followed by " DESTROYED", and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: QQ16
\       Type: Variable
\   Category: Text
\    Summary: The two-letter token lookup table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ Two-letter token lookup table for tokens 128-159. See the deep dive on
\ "Printing text tokens" for details of how the two-letter token system works.
\
\ ******************************************************************************

.QQ16

 EQUS "AL"              \ Token 128
 EQUS "LE"              \ Token 129
 EQUS "XE"              \ Token 130
 EQUS "GE"              \ Token 131
 EQUS "ZA"              \ Token 132
 EQUS "CE"              \ Token 133
 EQUS "BI"              \ Token 134
 EQUS "SO"              \ Token 135
 EQUS "US"              \ Token 136
 EQUS "ES"              \ Token 137
 EQUS "AR"              \ Token 138
 EQUS "MA"              \ Token 139
 EQUS "IN"              \ Token 140
 EQUS "DI"              \ Token 141
 EQUS "RE"              \ Token 142
 EQUS "A?"              \ Token 143
 EQUS "ER"              \ Token 144
 EQUS "AT"              \ Token 145
 EQUS "EN"              \ Token 146
 EQUS "BE"              \ Token 147
 EQUS "RA"              \ Token 148
 EQUS "LA"              \ Token 149
 EQUS "VE"              \ Token 150
 EQUS "TI"              \ Token 151
 EQUS "ED"              \ Token 152
 EQUS "OR"              \ Token 153
 EQUS "QU"              \ Token 154
 EQUS "AN"              \ Token 155
 EQUS "TE"              \ Token 156
 EQUS "IS"              \ Token 157
 EQUS "RI"              \ Token 158
 EQUS "ON"              \ Token 159

\ ******************************************************************************
\
\       Name: ITEM
\       Type: Macro
\   Category: Market
\    Summary: Macro definition for the market prices table
\  Deep dive: Market item prices and availability
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the market prices table:
\
\   ITEM price, factor, units, quantity, mask
\
\ It inserts an item into the market prices table at QQ23. See the deep dive on
\ "Market item prices and availability" for more information on how the market
\ system works.
\
\ Arguments:
\
\   price               Base price
\
\   factor              Economic factor
\
\   units               Units: "t", "g" or "k"
\
\   quantity            Base quantity
\
\   mask                Fluctuations mask
\
\ ******************************************************************************

MACRO ITEM price, factor, units, quantity, mask

  IF factor < 0
    s = 1 << 7
  ELSE
    s = 0
  ENDIF

  IF units = 't'
    u = 0
  ELIF units = 'k'
    u = 1 << 5
  ELSE
    u = 1 << 6
  ENDIF

  e = ABS(factor)

  EQUB price
  EQUB s + u + e
  EQUB quantity
  EQUB mask

ENDMACRO

\ ******************************************************************************
\
\       Name: QQ23
\       Type: Variable
\   Category: Market
\    Summary: Market prices table
\
\ ------------------------------------------------------------------------------
\
\ Each item has four bytes of data, like this:
\
\   Byte #0 = Base price
\   Byte #1 = Economic factor in bits 0-4, with the sign in bit 7
\             Unit in bits 5-6
\   Byte #2 = Base quantity
\   Byte #3 = Mask to control price fluctuations
\
\ To make it easier for humans to follow, we've defined a macro called ITEM
\ that takes the following arguments and builds the four bytes for us:
\
\   ITEM base price, economic factor, units, base quantity, mask
\
\ So for food, we have the following:
\
\   * Base price = 19
\   * Economic factor = -2
\   * Unit = tonnes
\   * Base quantity = 6
\   * Mask = %00000001
\
\ ******************************************************************************

.QQ23

 ITEM 19,  -2, 't',   6, %00000001   \  0 = Food
 ITEM 20,  -1, 't',  10, %00000011   \  1 = Textiles
 ITEM 65,  -3, 't',   2, %00000111   \  2 = Radioactives
 ITEM 40,  -5, 't', 226, %00011111   \  3 = Slaves
 ITEM 83,  -5, 't', 251, %00001111   \  4 = Liquor/Wines
 ITEM 196,  8, 't',  54, %00000011   \  5 = Luxuries
 ITEM 235, 29, 't',   8, %01111000   \  6 = Narcotics
 ITEM 154, 14, 't',  56, %00000011   \  7 = Computers
 ITEM 117,  6, 't',  40, %00000111   \  8 = Machinery
 ITEM 78,   1, 't',  17, %00011111   \  9 = Alloys
 ITEM 124, 13, 't',  29, %00000111   \ 10 = Firearms
 ITEM 176, -9, 't', 220, %00111111   \ 11 = Furs
 ITEM 32,  -1, 't',  53, %00000011   \ 12 = Minerals
 ITEM 97,  -1, 'k',  66, %00000111   \ 13 = Gold
 ITEM 171, -2, 'k',  55, %00011111   \ 14 = Platinum
 ITEM 45,  -1, 'g', 250, %00001111   \ 15 = Gem-Stones
 ITEM 53,  15, 't', 192, %00000111   \ 16 = Alien items

\ ******************************************************************************
\
\       Name: TIDY
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Orthonormalise the orientation vectors for a ship
\  Deep dive: Tidying orthonormal vectors
\             Orientation vectors
\
\ ------------------------------------------------------------------------------
\
\ This routine orthonormalises the orientation vectors for a ship. This means
\ making the three orientation vectors orthogonal (perpendicular to each other),
\ and normal (so each of the vectors has length 1).
\
\ We do this because we use the small angle approximation to rotate these
\ vectors in space. It is not completely accurate, so the three vectors tend
\ to get stretched over time, so periodically we tidy the vectors with this
\ routine to ensure they remain as orthonormal as possible.
\
\ ******************************************************************************

.TI2

                        \ Called from below with A = 0, X = 0, Y = 4 when
                        \ nosev_x and nosev_y are small, so we assume that
                        \ nosev_z is big

 TYA                    \ A = Y = 4
 LDY #2
 JSR TIS3               \ Call TIS3 with X = 0, Y = 2, A = 4, to set roofv_z =
 STA INWK+20            \ -(nosev_x * roofv_x + nosev_y * roofv_y) / nosev_z

 JMP TI3                \ Jump to TI3 to keep tidying

.TI1

                        \ Called from below with A = 0, Y = 4 when nosev_x is
                        \ small

 TAX                    \ Set X = A = 0

 LDA XX15+1             \ Set A = nosev_y, and if the top two magnitude bits
 AND #%01100000         \ are both clear, jump to TI2 with A = 0, X = 0, Y = 4
 BEQ TI2

 LDA #2                 \ Otherwise nosev_y is big, so set up the index values
                        \ to pass to TIS3

 JSR TIS3               \ Call TIS3 with X = 0, Y = 4, A = 2, to set roofv_y =
 STA INWK+18            \ -(nosev_x * roofv_x + nosev_z * roofv_z) / nosev_y

 JMP TI3                \ Jump to TI3 to keep tidying

.TIDY

 LDA INWK+10            \ Set (XX15, XX15+1, XX15+2) = nosev
 STA XX15
 LDA INWK+12
 STA XX15+1
 LDA INWK+14
 STA XX15+2

 JSR NORM               \ Call NORM to normalise the vector in XX15, i.e. nosev

 LDA XX15               \ Set nosev = (XX15, XX15+1, XX15+2)
 STA INWK+10
 LDA XX15+1
 STA INWK+12
 LDA XX15+2
 STA INWK+14

 LDY #4                 \ Set Y = 4

 LDA XX15               \ Set A = nosev_x, and if the top two magnitude bits
 AND #%01100000         \ are both clear, jump to TI1 with A = 0, Y = 4
 BEQ TI1

 LDX #2                 \ Otherwise nosev_x is big, so set up the index values
 LDA #0                 \ to pass to TIS3

 JSR TIS3               \ Call TIS3 with X = 2, Y = 4, A = 0, to set roofv_x =
 STA INWK+16            \ -(nosev_y * roofv_y + nosev_z * roofv_z) / nosev_x

.TI3

 LDA INWK+16            \ Set (XX15, XX15+1, XX15+2) = roofv
 STA XX15
 LDA INWK+18
 STA XX15+1
 LDA INWK+20
 STA XX15+2

 JSR NORM               \ Call NORM to normalise the vector in XX15, i.e. roofv

 LDA XX15               \ Set roofv = (XX15, XX15+1, XX15+2)
 STA INWK+16
 LDA XX15+1
 STA INWK+18
 LDA XX15+2
 STA INWK+20

 LDA INWK+12            \ Set Q = nosev_y
 STA Q

 LDA INWK+20            \ Set A = roofv_z

 JSR MULT12             \ Set (S R) = Q * A = nosev_y * roofv_z

 LDX INWK+14            \ Set X = nosev_z

 LDA INWK+18            \ Set A = roofv_y

 JSR TIS1               \ Set (A ?) = (-X * A + (S R)) / 96
                        \        = (-nosev_z * roofv_y + nosev_y * roofv_z) / 96
                        \
                        \ This also sets Q = nosev_z

 EOR #%10000000         \ Set sidev_x = -A
 STA INWK+22            \        = (nosev_z * roofv_y - nosev_y * roofv_z) / 96

 LDA INWK+16            \ Set A = roofv_x

 JSR MULT12             \ Set (S R) = Q * A = nosev_z * roofv_x

 LDX INWK+10            \ Set X = nosev_x

 LDA INWK+20            \ Set A = roofv_z

 JSR TIS1               \ Set (A ?) = (-X * A + (S R)) / 96
                        \        = (-nosev_x * roofv_z + nosev_z * roofv_x) / 96
                        \
                        \ This also sets Q = nosev_x

 EOR #%10000000         \ Set sidev_y = -A
 STA INWK+24            \        = (nosev_x * roofv_z - nosev_z * roofv_x) / 96

 LDA INWK+18            \ Set A = roofv_y

 JSR MULT12             \ Set (S R) = Q * A = nosev_x * roofv_y

 LDX INWK+12            \ Set X = nosev_y

 LDA INWK+16            \ Set A = roofv_x

 JSR TIS1               \ Set (A ?) = (-X * A + (S R)) / 96
                        \        = (-nosev_y * roofv_x + nosev_x * roofv_y) / 96

 EOR #%10000000         \ Set sidev_z = -A
 STA INWK+26            \        = (nosev_y * roofv_x - nosev_x * roofv_y) / 96

 LDA #0                 \ Set A = 0 so we can clear the low bytes of the
                        \ orientation vectors

 LDX #14                \ We want to clear the low bytes, so start from sidev_y
                        \ at byte #9+14 (we clear all except sidev_z_lo, though
                        \ I suspect this is in error and that X should be 16)

.TIL1

 STA INWK+9,X           \ Set the low byte in byte #9+X to zero

 DEX                    \ Set X = X - 2 to jump down to the next low byte
 DEX

 BPL TIL1               \ Loop back until we have zeroed all the low bytes

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TIS2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = A / Q
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division, where A is a sign-magnitude number and Q is
\ a positive integer:
\
\   A = A / Q
\
\ The value of A is returned as a sign-magnitude number with 96 representing 1,
\ and the maximum value returned is 1 (i.e. 96). This routine is used when
\ normalising vectors, where we represent fractions using integers, so this
\ gives us an approximation to two decimal places.
\
\ ******************************************************************************

.TIS2

 TAY                    \ Store the argument A in Y

 AND #%01111111         \ Strip the sign bit from the argument, so A = |A|

 CMP Q                  \ If A >= Q then jump to TI4 to return a 1 with the
 BCS TI4                \ correct sign

 LDX #%11111110         \ Set T to have bits 1-7 set, so we can rotate through 7
 STX T                  \ loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use T to catch our result bits into bit 0 each time

.TIL2

 ASL A                  \ Shift A to the left

 CMP Q                  \ If A < Q skip the following subtraction
 BCC P%+4

 SBC Q                  \ A >= Q, so set A = A - Q
                        \
                        \ Going into this subtraction we know the C flag is
                        \ set as we passed through the BCC above, and we also
                        \ know that A >= Q, so the C flag will still be set once
                        \ we are done

 ROL T                  \ Rotate the counter in T to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS TIL2               \ If we still have set bits in T, loop back to TIL2 to
                        \ do the next iteration of 7

                        \ We've done the division and now have a result in the
                        \ range 0-255 here, which we need to reduce to the range
                        \ 0-96. We can do that by multiplying the result by 3/8,
                        \ as 256 * 3/8 = 96

 LDA T                  \ Set T = T / 4
 LSR A
 LSR A
 STA T

 LSR A                  \ Set T = T / 8 + T / 4
 ADC T                  \       = 3T / 8
 STA T

 TYA                    \ Fetch the sign bit of the original argument A
 AND #%10000000

 ORA T                  \ Apply the sign bit to T

 RTS                    \ Return from the subroutine

.TI4

 TYA                    \ Fetch the sign bit of the original argument A
 AND #%10000000

 ORA #96                \ Apply the sign bit to 96 (which represents 1)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TIS3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate -(nosev_1 * roofv_1 + nosev_2 * roofv_2) / nosev_3
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following expression:
\
\   A = -(nosev_1 * roofv_1 + nosev_2 * roofv_2) / nosev_3
\
\ where 1, 2 and 3 are x, y, or z, depending on the values of X, Y and A. This
\ routine is called with the following values:
\
\   X = 0, Y = 2, A = 4 ->
\         A = -(nosev_x * roofv_x + nosev_y * roofv_y) / nosev_z
\
\   X = 0, Y = 4, A = 2 ->
\         A = -(nosev_x * roofv_x + nosev_z * roofv_z) / nosev_y
\
\   X = 2, Y = 4, A = 0 ->
\         A = -(nosev_y * roofv_y + nosev_z * roofv_z) / nosev_x
\
\ Arguments:
\
\   X                   Index 1 (0 = x, 2 = y, 4 = z)
\
\   Y                   Index 2 (0 = x, 2 = y, 4 = z)
\
\   A                   Index 3 (0 = x, 2 = y, 4 = z)
\
\ ******************************************************************************

.TIS3

 STA P+2                \ Store P+2 in A for later

 LDA INWK+10,X          \ Set Q = nosev_x_hi (plus X)
 STA Q

 LDA INWK+16,X          \ Set A = roofv_x_hi (plus X)

 JSR MULT12             \ Set (S R) = Q * A
                        \           = nosev_x_hi * roofv_x_hi

 LDX INWK+10,Y          \ Set Q = nosev_x_hi (plus Y)
 STX Q

 LDA INWK+16,Y          \ Set A = roofv_x_hi (plus Y)

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = (nosev_x,X * roofv_x,X) +
                        \             (nosev_x,Y * roofv_x,Y)

 STX P                  \ Store low byte of result in P, so result is now in
                        \ (A P)

 LDY P+2                \ Set Q = roofv_x_hi (plus argument A)
 LDX INWK+10,Y
 STX Q

 EOR #%10000000         \ Flip the sign of A

                        \ Fall through into DIVDT to do:
                        \
                        \   (P+1 A) = (A P) / Q
                        \
                        \     = -((nosev_x,X * roofv_x,X) +
                        \         (nosev_x,Y * roofv_x,Y))
                        \       / nosev_x,A

\ ******************************************************************************
\
\       Name: DVIDT
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P+1 A) = (A P) / Q
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following integer division between sign-magnitude numbers:
\
\   (P+1 A) = (A P) / Q
\
\ This uses the same shift-and-subtract algorithm as TIS2.
\
\ ******************************************************************************

.DVIDT

 STA P+1                \ Set P+1 = A, so P(1 0) = (A P)

 EOR Q                  \ Set T = the sign bit of A EOR Q, so it's 1 if A and Q
 AND #%10000000         \ have different signs, i.e. it's the sign of the result
 STA T                  \ of A / Q

 LDA #0                 \ Set A = 0 for us to build a result

 LDX #16                \ Set a counter in X to count the 16 bits in P(1 0)

 ASL P                  \ Shift P(1 0) left
 ROL P+1

 ASL Q                  \ Clear the sign bit of Q the C flag at the same time
 LSR Q

.DVL2

 ROL A                  \ Shift A to the left

 CMP Q                  \ If A < Q skip the following subtraction
 BCC P%+4

 SBC Q                  \ Set A = A - Q
                        \
                        \ Going into this subtraction we know the C flag is
                        \ set as we passed through the BCC above, and we also
                        \ know that A >= Q, so the C flag will still be set once
                        \ we are done

 ROL P                  \ Rotate P(1 0) to the left, and catch the result bit
 ROL P+1                \ into the C flag (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 DEX                    \ Decrement the loop counter

 BNE DVL2               \ Loop back for the next bit until we have done all 16
                        \ bits of P(1 0)

 LDA P                  \ Set A = P so the low byte is in the result in A

 ORA T                  \ Set A to the correct sign bit that we set in T above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save ELTF.bin
\
\ ******************************************************************************

PRINT "ELITE F"
PRINT "Assembled at ", ~CODE_F%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_F%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_F%

PRINT "S.ELTF ", ~CODE_F%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_F%
SAVE "3-assembled-output/ELTF.bin", CODE_F%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE G FILE
\
\ Produces the binary file ELTG.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CODE_G% = P%
LOAD_G% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: SHPPT
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw a distant ship as a point rather than a full wireframe
\
\ ******************************************************************************

.SHPPT

 JSR EE51               \ Call EE51 to remove the ship's wireframe from the
                        \ screen, if there is one

 JSR PROJ               \ Project the ship onto the screen, returning:
                        \
                        \   * K3(1 0) = the screen x-coordinate
                        \   * K4(1 0) = the screen y-coordinate
                        \   * A = K4+1

 ORA K3+1               \ If either of the high bytes of the screen coordinates
 BNE nono               \ are non-zero, jump to nono as the ship is off-screen

 LDA K4                 \ Set A = the y-coordinate of the dot

 CMP #Y*2-2             \ If the y-coordinate is bigger than the y-coordinate of
 BCS nono               \ the bottom of the screen, jump to nono as the ship's
                        \ dot is off the bottom of the space view

 LDY #2                 \ Call Shpt with Y = 2 to set up bytes 1-4 in the ship
 JSR Shpt               \ lines space, aborting the call to LL9 if the dot is
                        \ off the side of the screen. This call sets up the
                        \ first row of the dot (i.e. a four-pixel dash)

 LDY #6                 \ Set Y to 6 for the next call to Shpt

 LDA K4                 \ Set A = y-coordinate of dot + 1 (so this is the second
 ADC #1                 \ row of the two-pixel-high dot)

 JSR Shpt               \ Call Shpt with Y = 6 to set up bytes 5-8 in the ship
                        \ lines space, aborting the call to LL9 if the dot is
                        \ off the side of the screen. This call sets up the
                        \ second row of the dot (i.e. another four-pixel dash,
                        \ on the row below the first one)

 LDA #%00001000         \ Set bit 3 of the ship's byte #31 to record that we
 ORA XX1+31             \ have now drawn something on-screen for this ship
 STA XX1+31

 LDA #8                 \ Set A = 8 so when we call LL18+2 next, byte #0 of the
                        \ heap gets set to 8, for the 8 bytes we just stuck on
                        \ the heap

 JMP LL81+2             \ Call LL81+2 to draw the ship's dot, returning from the
                        \ subroutine using a tail call

 PLA                    \ Pull the return address from the stack, so the RTS
 PLA                    \ below actually returns from the subroutine that called
                        \ LL9 (as we called SHPPT from LL9 with a JMP)

.nono

 LDA #%11110111         \ Clear bit 3 of the ship's byte #31 to record that
 AND XX1+31             \ nothing is being drawn on-screen for this ship
 STA XX1+31

 RTS                    \ Return from the subroutine

.Shpt

                        \ This routine sets up four bytes in the ship line heap,
                        \ from byte Y-1 to byte Y+2. If the ship's screen point
                        \ turns out to be off-screen, then this routine aborts
                        \ the entire call to LL9, exiting via nono. The four
                        \ bytes define a horizontal 4-pixel dash, for either the
                        \ top or the bottom of the ship's dot

 STA (XX19),Y           \ Store A in byte Y of the ship line heap

 INY                    \ Store A in byte Y+2 of the ship line heap
 INY
 STA (XX19),Y

 LDA K3                 \ Set A = screen x-coordinate of the ship dot

 DEY                    \ Store A in byte Y+1 of the ship line heap
 STA (XX19),Y

 ADC #3                 \ Set A = screen x-coordinate of the ship dot + 3

 BCS nono-2             \ If the addition pushed the dot off the right side of
                        \ the screen, jump to nono-2 to return from the parent
                        \ subroutine early (i.e. LL9). This works because we
                        \ called Shpt from above with a JSR, so nono-2 removes
                        \ that return address from the stack, leaving the next
                        \ return address exposed. LL9 called SHPPT with a JMP.
                        \ so the next return address is the one that was put on
                        \ the stack by the original call to LL9. So the RTS in
                        \ nono will actually return us from the original call
                        \ to LL9, thus aborting the entire drawing process

 DEY                    \ Store A in byte Y-1 of the ship line heap
 DEY
 STA (XX19),Y

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL5
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate Q = SQRT(R Q)
\  Deep dive: Calculating square roots
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following square root:
\
\   Q = SQRT(R Q)
\
\ ******************************************************************************

.LL5

 LDY R                  \ Set (Y S) = (R Q)
 LDA Q
 STA S

                        \ So now to calculate Q = SQRT(Y S)

 LDX #0                 \ Set X = 0, to hold the remainder

 STX Q                  \ Set Q = 0, to hold the result

 LDA #8                 \ Set T = 8, to use as a loop counter
 STA T

.LL6

 CPX Q                  \ If X < Q, jump to LL7
 BCC LL7

 BNE LL8                \ If X > Q, jump to LL8

 CPY #64                \ If Y < 64, jump to LL7 with the C flag clear,
 BCC LL7                \ otherwise fall through into LL8 with the C flag set

.LL8

 TYA                    \ Set Y = Y - 64
 SBC #64                \
 TAY                    \ This subtraction will work as we know C is set from
                        \ the BCC above, and the result will not underflow as we
                        \ already checked that Y >= 64, so the C flag is also
                        \ set for the next subtraction

 TXA                    \ Set X = X - Q
 SBC Q
 TAX

.LL7

 ROL Q                  \ Shift the result in Q to the left, shifting the C flag
                        \ into bit 0 and bit 7 into the C flag

 ASL S                  \ Shift the dividend in (Y S) to the left, inserting
 TYA                    \ bit 7 from above into bit 0
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 ASL S                  \ Shift the dividend in (Y S) to the left
 TYA
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 DEC T                  \ Decrement the loop counter

 BNE LL6                \ Loop back to LL6 until we have done 8 loops

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL28
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate R = 256 * A / Q
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following, where A < Q:
\
\   R = 256 * A / Q
\
\ This is a sister routine to LL61, which does the division when A >= Q.
\
\ If A >= Q then 255 is returned and the C flag is set to indicate an overflow
\ (the C flag is clear if the division was a success).
\
\ The result is returned in one byte as the result of the division multiplied
\ by 256, so we can return fractional results using integers.
\
\ This routine uses the same shift-and-subtract algorithm that's documented in
\ TIS2, but it leaves the fractional result in the integer range 0-255.
\
\ Returns:
\
\   C flag              Set if the answer is too big for one byte, clear if the
\                       division was a success
\
\ Other entry points:
\
\   LL28+4              Skips the A >= Q check and always returns with C flag
\                       cleared, so this can be called if we know the division
\                       will work
\
\   LL31                Skips the A >= Q check and does not set the R counter,
\                       so this can be used for jumping straight into the
\                       division loop if R is already set to 254 and we know the
\                       division will work
\
\ ******************************************************************************

.LL28

 CMP Q                  \ If A >= Q, then the answer will not fit in one byte,
 BCS LL2                \ so jump to LL2 to return 255

 LDX #%11111110         \ Set R to have bits 1-7 set, so we can rotate through 7
 STX R                  \ loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use R to catch our result bits into bit 0 each time

.LL31

 ASL A                  \ Shift A to the left

 BCS LL29               \ If bit 7 of A was set, then jump straight to the
                        \ subtraction

 CMP Q                  \ If A < Q, skip the following subtraction
 BCC P%+4

 SBC Q                  \ A >= Q, so set A = A - Q

 ROL R                  \ Rotate the counter in R to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS LL31               \ If we still have set bits in R, loop back to LL31 to
                        \ do the next iteration of 7

 RTS                    \ R left with remainder of division

.LL29

 SBC Q                  \ A >= Q, so set A = A - Q

 SEC                    \ Set the C flag to rotate into the result in R

 ROL R                  \ Rotate the counter in R to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS LL31               \ If we still have set bits in R, loop back to LL31 to
                        \ do the next iteration of 7

 RTS                    \ Return from the subroutine with R containing the
                        \ remainder of the division

.LL2

 LDA #255               \ The division is very close to 1, so return the closest
 STA R                  \ possible answer to 256, i.e. R = 255

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL38
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S A) = (S R) + (A Q)
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following between sign-magnitude numbers:
\
\   (S A) = (S R) + (A Q)
\
\ where the sign bytes only contain the sign bits, not magnitudes.
\
\ Returns:
\
\   C flag              Set if the addition overflowed, clear otherwise
\
\ ******************************************************************************

.LL38

 EOR S                  \ If the sign of A * S is negative, skip to LL35, as
 BMI LL39               \ A and S have different signs so we need to subtract

 LDA Q                  \ Otherwise set A = R + Q, which is the result we need,
 CLC                    \ as S already contains the correct sign
 ADC R

 RTS                    \ Return from the subroutine

.LL39

 LDA R                  \ Set A = R - Q
 SEC
 SBC Q

 BCC P%+4               \ If the subtraction underflowed, skip the next two
                        \ instructions so we can negate the result

 CLC                    \ Otherwise the result is correct, and S contains the
                        \ correct sign of the result as R is the dominant side
                        \ of the subtraction, so clear the C flag

 RTS                    \ And return from the subroutine

                        \ If we get here we need to negate both the result and
                        \ the sign in S, as both are the wrong sign

 PHA                    \ Store the result of the subtraction on the stack

 LDA S                  \ Flip the sign of S
 EOR #%10000000
 STA S

 PLA                    \ Restore the subtraction result into A

 EOR #%11111111         \ Negate the result in A using two's complement, i.e.
 ADC #1                 \ set A = ~A + 1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL51
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the dot product of XX15 and XX16
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following dot products:
\
\   XX12(1 0) = XX15(5 0) . XX16(5 0)
\   XX12(3 2) = XX15(5 0) . XX16(11 6)
\   XX12(5 4) = XX15(5 0) . XX16(12 17)
\
\ storing the results as sign-magnitude numbers in XX12 through XX12+5.
\
\ When called from part 5 of LL9, XX12 contains the vector [x y z] to the ship
\ we're drawing, and XX16 contains the orientation vectors, so it returns:
\
\   [ x ]   [ sidev_x ]         [ x ]   [ roofv_x ]         [ x ]   [ nosev_x ]
\   [ y ] . [ sidev_y ]         [ y ] . [ roofv_y ]         [ y ] . [ nosev_y ]
\   [ z ]   [ sidev_z ]         [ z ]   [ roofv_z ]         [ z ]   [ nosev_z ]
\
\ When called from part 6 of LL9, XX12 contains the vector [x y z] of the vertex
\ we're analysing, and XX16 contains the transposed orientation vectors with
\ each of them containing the x, y and z elements of the original vectors, so it
\ returns:
\
\   [ x ]   [ sidev_x ]         [ x ]   [ sidev_y ]         [ x ]   [ sidev_z ]
\   [ y ] . [ roofv_x ]         [ y ] . [ roofv_y ]         [ y ] . [ roofv_z ]
\   [ z ]   [ nosev_x ]         [ z ]   [ nosev_y ]         [ z ]   [ nosev_z ]
\
\ Arguments:
\
\   XX15(1 0)           The ship (or vertex)'s x-coordinate as (x_sign x_lo)
\
\   XX15(3 2)           The ship (or vertex)'s y-coordinate as (y_sign y_lo)
\
\   XX15(5 4)           The ship (or vertex)'s z-coordinate as (z_sign z_lo)
\
\   XX16 to XX16+5      The scaled sidev (or _x) vector, with:
\
\                         * x, y, z magnitudes in XX16, XX16+2, XX16+4
\
\                         * x, y, z signs in XX16+1, XX16+3, XX16+5
\
\   XX16+6 to XX16+11   The scaled roofv (or _y) vector, with:
\
\                         * x, y, z magnitudes in XX16+6, XX16+8, XX16+10
\
\                         * x, y, z signs in XX16+7, XX16+9, XX16+11
\
\   XX16+12 to XX16+17  The scaled nosev (or _z) vector, with:
\
\                         * x, y, z magnitudes in XX16+12, XX16+14, XX16+16
\
\                         * x, y, z signs in XX16+13, XX16+15, XX16+17
\
\ Returns:
\
\   XX12(1 0)           The dot product of [x y z] vector with the sidev (or _x)
\                       vector, with the sign in XX12+1 and magnitude in XX12
\
\   XX12(3 2)           The dot product of [x y z] vector with the roofv (or _y)
\                       vector, with the sign in XX12+3 and magnitude in XX12+2
\
\   XX12(5 4)           The dot product of [x y z] vector with the nosev (or _z)
\                       vector, with the sign in XX12+5 and magnitude in XX12+4
\
\ ******************************************************************************

.LL51

 LDX #0                 \ Set X = 0, which will contain the offset of the vector
                        \ to use in the calculation, increasing by 6 for each
                        \ new vector

 LDY #0                 \ Set Y = 0, which will contain the offset of the
                        \ result bytes in XX12, increasing by 2 for each new
                        \ result

.ll51

 LDA XX15               \ Set Q = x_lo
 STA Q

 LDA XX16,X             \ Set A = |sidev_x|

 JSR FMLTU              \ Set T = A * Q / 256
 STA T                  \       = |sidev_x| * x_lo / 256

 LDA XX15+1             \ Set S to the sign of x_sign * sidev_x
 EOR XX16+1,X
 STA S

 LDA XX15+2             \ Set Q = y_lo
 STA Q

 LDA XX16+2,X           \ Set A = |sidev_y|

 JSR FMLTU              \ Set Q = A * Q / 256
 STA Q                  \       = |sidev_y| * y_lo / 256

 LDA T                  \ Set R = T
 STA R                  \       = |sidev_x| * x_lo / 256

 LDA XX15+3             \ Set A to the sign of y_sign * sidev_y
 EOR XX16+3,X

 JSR LL38               \ Set (S T) = (S R) + (A Q)
 STA T                  \           = |sidev_x| * x_lo + |sidev_y| * y_lo

 LDA XX15+4             \ Set Q = z_lo
 STA Q

 LDA XX16+4,X           \ Set A = |sidev_z|

 JSR FMLTU              \ Set Q = A * Q / 256
 STA Q                  \       = |sidev_z| * z_lo / 256

 LDA T                  \ Set R = T
 STA R                  \       = |sidev_x| * x_lo + |sidev_y| * y_lo

 LDA XX15+5             \ Set A to the sign of z_sign * sidev_z
 EOR XX16+5,X

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = |sidev_x| * x_lo + |sidev_y| * y_lo
                        \             + |sidev_z| * z_lo

 STA XX12,Y             \ Store the result in XX12+Y(1 0)
 LDA S
 STA XX12+1,Y

 INY                    \ Set Y = Y + 2
 INY

 TXA                    \ Set X = X + 6
 CLC
 ADC #6
 TAX

 CMP #17                \ If X < 17, loop back to ll51 for the next vector
 BCC ll51

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL9 (Part 1 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Check if ship is exploding, check if ship is in front
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This routine draws the current ship on the screen. This part checks to see if
\ the ship is exploding, or if it should start exploding, and if it does it sets
\ things up accordingly.
\
\ It also does some basic checks to see if we can see the ship, and if not it
\ removes it from the screen.
\
\ In this code, XX1 is used to point to the current ship's data block at INWK
\ (the two labels are interchangeable).
\
\ Arguments:
\
\   XX1                 XX1 shares its location with INWK, which contains the
\                       zero-page copy of the data block for this ship from the
\                       K% workspace
\
\   INF                 The address of the data block for this ship in workspace
\                       K%
\
\   XX19(1 0)           XX19(1 0) shares its location with INWK(34 33), which
\                       contains the ship line heap address pointer
\
\   XX0                 The address of the blueprint for this ship
\
\ Other entry points:
\
\   EE51                Remove the current ship from the screen, called from
\                       SHPPT before drawing the ship as a point
\
\ ******************************************************************************

.LL25

 JMP PLANET             \ Jump to the PLANET routine, returning from the
                        \ subroutine using a tail call

.LL9

 LDA TYPE               \ If the ship type is negative then this indicates a
 BMI LL25               \ planet or sun, so jump to PLANET via LL25 above

 LDA #31                \ Set XX4 = 31 to store the ship's distance for later
 STA XX4                \ comparison with the visibility distance. We will
                        \ update this value below with the actual ship's
                        \ distance if it turns out to be visible on-screen

 LDA #%00100000         \ If bit 5 of the ship's byte #31 is set, then the ship
 BIT XX1+31             \ is currently exploding, so jump down to EE28
 BNE EE28

 BPL EE28               \ If bit 7 of the ship's byte #31 is clear then the ship
                        \ has not just been killed, so jump down to EE28

                        \ Otherwise bit 5 is clear and bit 7 is set, so the ship
                        \ is not yet exploding but it has been killed, so we
                        \ need to start an explosion

 ORA XX1+31             \ Clear bits 6 and 7 of the ship's byte #31, to stop the
 AND #%00111111         \ ship from firing its laser and to mark it as no longer
 STA XX1+31             \ having just been killed

 LDA #0                 \ Set the ship's acceleration in byte #31 to 0, updating
 LDY #28                \ the byte in the workspace K% data block so we don't
 STA (INF),Y            \ have to copy it back from INWK later

 LDY #30                \ Set the ship's pitch counter in byte #30 to 0, to stop
 STA (INF),Y            \ the ship from pitching

 JSR EE51               \ Call EE51 to remove the ship from the screen

                        \ We now need to set up a new explosion cloud. We
                        \ initialise it with a size of 18 (which gets increased
                        \ by 4 every time the cloud gets redrawn), and the
                        \ explosion count (i.e. the number of particles in the
                        \ explosion), which go into bytes 1 and 2 of the ship
                        \ line heap. See DOEXP for more details of explosion
                        \ clouds

 LDY #1                 \ Set byte #1 of the ship line heap to 18, the initial
 LDA #18                \ size of the explosion cloud
 STA (XX19),Y

 LDY #7                 \ Fetch byte #7 from the ship's blueprint, which
 LDA (XX0),Y            \ determines the explosion count (i.e. the number of
 LDY #2                 \ vertices used as origins for explosion clouds), and
 STA (XX19),Y           \ store it in byte #2 of the ship line heap

\LDA XX1+32             \ These instructions are commented out in the original
\AND #&7F               \ source

                        \ The following loop sets bytes 3-6 of the of the ship
                        \ line heap to random numbers

.EE55

 INY                    \ Increment Y (so the loop starts at 3)

 JSR DORND              \ Set A and X to random numbers

 STA (XX19),Y           \ Store A in the Y-th byte of the ship line heap

 CPY #6                 \ Loop back until we have randomised the 6th byte
 BNE EE55

.EE28

 LDA XX1+8              \ Set A = z_sign

.EE49

 BPL LL10               \ If A is positive, i.e. the ship is in front of us,
                        \ jump down to LL10

.LL14

                        \ The following removes the ship from the screen by
                        \ redrawing it (or, if it is exploding, by redrawing the
                        \ explosion cloud). We call it when the ship is no
                        \ longer on-screen, is too far away to be fully drawn,
                        \ and so on

 LDA XX1+31             \ If bit 5 of the ship's byte #31 is clear, then the
 AND #%00100000         \ ship is not currently exploding, so jump down to EE51
 BEQ EE51               \ to redraw its wireframe

 LDA XX1+31             \ The ship is exploding, so clear bit 3 of the ship's
 AND #%11110111         \ byte #31 to denote that the ship is no longer being
 STA XX1+31             \ drawn on-screen

 JMP DOEXP              \ Jump to DOEXP to display the explosion cloud, which
                        \ will remove it from the screen, returning from the
                        \ subroutine using a tail call

.EE51

 LDA #%00001000         \ If bit 3 of the ship's byte #31 is clear, then there
 BIT XX1+31             \ is already nothing being shown for this ship, so
 BEQ LL10-1             \ return from the subroutine (as LL10-1 contains an RTS)

 EOR XX1+31             \ Otherwise flip bit 3 of byte #31 and store it (which
 STA XX1+31             \ clears bit 3 as we know it was set before the EOR), so
                        \ this sets this ship as no longer being drawn on-screen

 JMP LL155              \ Jump to LL155 to draw the ship, which removes it from
                        \ the screen, returning from the subroutine using a
                        \ tail call

\.LL24                  \ This label is commented out in the original source,
                        \ and was presumably used to label the RTS which is
                        \ actually called by LL10-1 above, not LL24

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL9 (Part 2 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Check if ship is in field of view, close enough to draw
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part checks whether the ship is in our field of view, and whether it is
\ close enough to be fully drawn (if not, we jump to SHPPT to draw it as a dot).
\
\ Other entry points:
\
\   LL10-1              Contains an RTS
\
\ ******************************************************************************

.LL10

 LDA XX1+7              \ Set A = z_hi

 CMP #192               \ If A >= 192 then the ship is a long way away, so jump
 BCS LL14               \ to LL14 to remove the ship from the screen

 LDA XX1                \ If x_lo >= z_lo, set the C flag, otherwise clear it
 CMP XX1+6

 LDA XX1+1              \ Set A = x_hi - z_hi using the carry from the low
 SBC XX1+7              \ bytes, which sets the C flag as if we had done a full
                        \ two-byte subtraction (x_hi x_lo) - (z_hi z_lo)

 BCS LL14               \ If the C flag is set then x >= z, so the ship is
                        \ further to the side than it is in front of us, so it's
                        \ outside our viewing angle of 45 degrees, and we jump
                        \ to LL14 to remove it from the screen

 LDA XX1+3              \ If y_lo >= z_lo, set the C flag, otherwise clear it
 CMP XX1+6

 LDA XX1+4              \ Set A = y_hi - z_hi using the carry from the low
 SBC XX1+7              \ bytes, which sets the C flag as if we had done a full
                        \ two-byte subtraction (y_hi y_lo) - (z_hi z_lo)

 BCS LL14               \ If the C flag is set then y >= z, so the ship is
                        \ further above us than it is in front of us, so it's
                        \ outside our viewing angle of 45 degrees, and we jump
                        \ to LL14 to remove it from the screen

 LDY #6                 \ Fetch byte #6 from the ship's blueprint into X, which
 LDA (XX0),Y            \ is the number * 4 of the vertex used for the ship's
 TAX                    \ laser

 LDA #255               \ Set bytes X and X+1 of the XX3 heap to 255. We're
 STA XX3,X              \ going to use XX3 to store the screen coordinates of
 STA XX3+1,X            \ all the visible vertices of this ship, so setting the
                        \ laser vertex to 255 means that if we don't update this
                        \ vertex with its screen coordinates in parts 6 and 7,
                        \ this vertex's entry in the XX3 heap will still be 255,
                        \ which we can check in part 9 to see if the laser
                        \ vertex is visible (and therefore whether we should
                        \ draw laser lines if the ship is firing on us)

 LDA XX1+6              \ Set (A T) = (z_hi z_lo)
 STA T
 LDA XX1+7

 LSR A                  \ Set (A T) = (A T) / 8
 ROR T
 LSR A
 ROR T
 LSR A
 ROR T

 LSR A                  \ If A >> 4 is non-zero, i.e. z_hi >= 16, jump to LL13
 BNE LL13               \ as the ship is possibly far away enough to be shown as
                        \ a dot

 LDA T                  \ Otherwise the C flag contains the previous bit 0 of A,
 ROR A                  \ which could have been set, so rotate A right four
 LSR A                  \ times so it's in the form %000xxxxx, i.e. z_hi reduced
 LSR A                  \ to a maximum value of 31
 LSR A

 STA XX4                \ Store A in XX4, which is now the distance of the ship
                        \ we can use for visibility testing

 BPL LL17               \ Jump down to LL17 (this BPL is effectively a JMP as we
                        \ know bit 7 of A is definitely clear)

.LL13

                        \ If we get here then the ship is possibly far enough
                        \ away to be shown as a dot

 LDY #13                \ Fetch byte #13 from the ship's blueprint, which gives
 LDA (XX0),Y            \ the ship's visibility distance, beyond which we show
                        \ the ship as a dot

 CMP XX1+7              \ If z_hi <= the visibility distance, skip to LL17 to
 BCS LL17               \ draw the ship fully, rather than as a dot, as it is
                        \ closer than the visibility distance

 LDA #%00100000         \ If bit 5 of the ship's byte #31 is set, then the
 AND XX1+31             \ ship is currently exploding, so skip to LL17 to draw
 BNE LL17               \ the ship's explosion cloud

 JMP SHPPT              \ Otherwise jump to SHPPT to draw the ship as a dot,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: LL9 (Part 3 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Set up orientation vector, ship coordinate variables
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part sets up the following variable blocks:
\
\   * XX16 contains the orientation vectors, divided to normalise them
\
\   * XX18 contains the ship's x, y and z coordinates in space
\
\ ******************************************************************************

.LL17

 LDX #5                 \ First we copy the three orientation vectors into XX16,
                        \ so set up a counter in X for the 6 bytes in each
                        \ vector

.LL15

 LDA XX1+21,X           \ Copy the X-th byte of sidev to the X-th byte of XX16
 STA XX16,X

 LDA XX1+15,X           \ Copy the X-th byte of roofv to XX16+6 to the X-th byte
 STA XX16+6,X           \ of XX16+6

 LDA XX1+9,X            \ Copy the X-th byte of nosev to XX16+12 to the X-th
 STA XX16+12,X          \ byte of XX16+12

 DEX                    \ Decrement the counter

 BPL LL15               \ Loop back to copy the next byte of each vector, until
                        \ we have the following:
                        \
                        \   * XX16(1 0) = sidev_x
                        \   * XX16(3 2) = sidev_y
                        \   * XX16(5 4) = sidev_z
                        \
                        \   * XX16(7 6) = roofv_x
                        \   * XX16(9 8) = roofv_y
                        \   * XX16(11 10) = roofv_z
                        \
                        \   * XX16(13 12) = nosev_x
                        \   * XX16(15 14) = nosev_y
                        \   * XX16(17 16) = nosev_z

 LDA #197               \ Set Q = 197
 STA Q

 LDY #16                \ Set Y to be a counter that counts down by 2 each time,
                        \ starting with 16, then 14, 12 and so on. We use this
                        \ to work through each of the coordinates in each of the
                        \ orientation vectors

.LL21

 LDA XX16,Y             \ Set A = the low byte of the vector coordinate, e.g.
                        \ nosev_z_lo when Y = 16

 ASL A                  \ Shift bit 7 into the C flag

 LDA XX16+1,Y           \ Set A = the high byte of the vector coordinate, e.g.
                        \ nosev_z_hi when Y = 16

 ROL A                  \ Rotate A left, incorporating the C flag, so A now
                        \ contains the original high byte, doubled, and without
                        \ a sign bit, e.g. A = |nosev_z_hi| * 2

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \
                        \ so, for nosev, this would be:
                        \
                        \   R = 256 * |nosev_z_hi| * 2 / 197
                        \     = 2.6 * |nosev_z_hi|

 LDX R                  \ Store R in the low byte's location, so we can keep the
 STX XX16,Y             \ old, unscaled high byte intact for the sign

 DEY                    \ Decrement the loop counter twice
 DEY

 BPL LL21               \ Loop back for the next vector coordinate until we have
                        \ divided them all

                        \ By this point, the vectors have been turned into
                        \ scaled magnitudes, so we have the following:
                        \
                        \   * XX16   = scaled |sidev_x|
                        \   * XX16+2 = scaled |sidev_y|
                        \   * XX16+4 = scaled |sidev_z|
                        \
                        \   * XX16+6  = scaled |roofv_x|
                        \   * XX16+8  = scaled |roofv_y|
                        \   * XX16+10 = scaled |roofv_z|
                        \
                        \   * XX16+12 = scaled |nosev_x|
                        \   * XX16+14 = scaled |nosev_y|
                        \   * XX16+16 = scaled |nosev_z|

 LDX #8                 \ Next we copy the ship's coordinates into XX18, so set
                        \ up a counter in X for 9 bytes

.ll91

 LDA XX1,X              \ Copy the X-th byte from XX1 to XX18
 STA XX18,X

 DEX                    \ Decrement the loop counter

 BPL ll91               \ Loop back for the next byte until we have copied all
                        \ three coordinates

                        \ So we now have the following:
                        \
                        \   * XX18(2 1 0) = (x_sign x_hi x_lo)
                        \
                        \   * XX18(5 4 3) = (y_sign y_hi y_lo)
                        \
                        \   * XX18(8 7 6) = (z_sign z_hi z_lo)

 LDA #255               \ Set the 15th byte of XX2 to 255, so that face 15 is
 STA XX2+15             \ always visible. No ship definitions actually have this
                        \ number of faces in the cassette version, but this
                        \ allows us to force a vertex to always be visible by
                        \ associating it with face 15 (see the blueprints for
                        \ the Cobra Mk III at SHIP_COBRA_MK_3 and asteroid at
                        \ SHIP_ASTEROID for examples)

 LDY #12                \ Set Y = 12 to point to the ship blueprint byte #12,

 LDA XX1+31             \ If bit 5 of the ship's byte #31 is clear, then the
 AND #%00100000         \ ship is not currently exploding, so jump down to EE29
 BEQ EE29               \ to skip the following

                        \ Otherwise we fall through to set up the visibility
                        \ block for an exploding ship

\ ******************************************************************************
\
\       Name: LL9 (Part 4 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Set visibility for exploding ship (all faces visible)
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part sets up the visibility block in XX2 for a ship that is exploding.
\
\ The XX2 block consists of one byte for each face in the ship's blueprint,
\ which holds the visibility of that face. Because the ship is exploding, we
\ want to set all the faces to be visible. A value of 255 in the visibility
\ table means the face is visible, so the following code sets each face to 255
\ and then skips over the face visibility calculations that we would apply to a
\ non-exploding ship.
\
\ ******************************************************************************

 LDA (XX0),Y            \ Fetch byte #12 of the ship's blueprint, which contains
                        \ the number of faces * 4

 LSR A                  \ Set X = A / 4
 LSR A                  \       = the number of faces
 TAX

 LDA #255               \ Set A = 255

.EE30

 STA XX2,X              \ Set the X-th byte of XX2 to 255

 DEX                    \ Decrement the loop counter

 BPL EE30               \ Loop back for the next byte until there is one byte
                        \ set to 255 for each face

 INX                    \ Set XX4 = 0 for the distance value we use to test
 STX XX4                \ for visibility, so we always shows everything

.LL41

 JMP LL42               \ Jump to LL42 to skip the face visibility calculations
                        \ as we don't need to do them now we've set up the XX2
                        \ block for the explosion

\ ******************************************************************************
\
\       Name: LL9 (Part 5 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's faces
\  Deep dive: Drawing ships
\             Back-face culling
\
\ ******************************************************************************

.EE29

 LDA (XX0),Y            \ We set Y to 12 above before jumping down to EE29, so
                        \ this fetches byte #12 of the ship's blueprint, which
                        \ contains the number of faces * 4

 BEQ LL41               \ If there are no faces in this ship, jump to LL42 (via
                        \ LL41) to skip the face visibility calculations

 STA XX20               \ Set A = the number of faces * 4

 LDY #18                \ Fetch byte #18 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the factor by which we scale the face normals, into X
 TAX

 LDA XX18+7             \ Set A = z_hi

.LL90

 TAY                    \ Set Y = z_hi

 BEQ LL91               \ If z_hi = 0 then jump to LL91

                        \ The following is a loop that jumps back to LL90+3,
                        \ i.e. here. LL90 is only used for this loop, so it's a
                        \ bit of a strange use of the label here

 INX                    \ Increment the scale factor in X

 LSR XX18+4             \ Divide (y_hi y_lo) by 2
 ROR XX18+3

 LSR XX18+1             \ Divide (x_hi x_lo) by 2
 ROR XX18

 LSR A                  \ Divide (z_hi z_lo) by 2 (as A contains z_hi)
 ROR XX18+6

 TAY                    \ Set Y = z_hi

 BNE LL90+3             \ If Y is non-zero, loop back to LL90+3 to divide the
                        \ three coordinates until z_hi is 0

.LL91

                        \ By this point z_hi is 0 and X contains the number of
                        \ right shifts we had to do, plus the scale factor from
                        \ the blueprint

 STX XX17               \ Store the updated scale factor in XX17

 LDA XX18+8             \ Set XX15+5 = z_sign
 STA XX15+5

 LDA XX18               \ Set XX15(1 0) = (x_sign x_lo)
 STA XX15
 LDA XX18+2
 STA XX15+1

 LDA XX18+3             \ Set XX15(3 2) = (y_sign y_lo)
 STA XX15+2
 LDA XX18+5
 STA XX15+3

 LDA XX18+6             \ Set XX15+4 = z_lo, so now XX15(5 4) = (z_sign z_lo)
 STA XX15+4

 JSR LL51               \ Call LL51 to set XX12 to the dot products of XX15 and
                        \ XX16, which we'll call dot_sidev, dot_roofv and
                        \ dot_nosev:
                        \
                        \   XX12(1 0) = [x y z] . sidev
                        \             = (dot_sidev_sign dot_sidev_lo)
                        \             = dot_sidev
                        \
                        \   XX12(3 2) = [x y z] . roofv
                        \             = (dot_roofv_sign dot_roofv_lo)
                        \             = dot_roofv
                        \
                        \   XX12(5 4) = [x y z] . nosev
                        \             = (dot_nosev_sign dot_nosev_lo)
                        \             = dot_nosev

 LDA XX12               \ Set XX18(2 0) = dot_sidev
 STA XX18
 LDA XX12+1
 STA XX18+2

 LDA XX12+2             \ Set XX18(5 3) = dot_roofv
 STA XX18+3
 LDA XX12+3
 STA XX18+5

 LDA XX12+4             \ Set XX18(8 6) = dot_nosev
 STA XX18+6
 LDA XX12+5
 STA XX18+8

 LDY #4                 \ Fetch byte #4 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the low byte of the offset to the faces data

 CLC                    \ Set V = low byte faces offset + XX0
 ADC XX0
 STA V

 LDY #17                \ Fetch byte #17 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the high byte of the offset to the faces data

 ADC XX0+1              \ Set V+1 = high byte faces offset + XX0+1
 STA V+1                \
                        \ So V(1 0) now points to the start of the faces data
                        \ for this ship

 LDY #0                 \ We're now going to loop through all the faces for this
                        \ ship, so set a counter in Y, starting from 0, which we
                        \ will increment by 4 each loop to step through the
                        \ four bytes of data for each face

.LL86

 LDA (V),Y              \ Fetch byte #0 for this face into A, so:
                        \
                        \   A = %xyz vvvvv, where:
                        \
                        \     * Bits 0-4 = visibility distance, beyond which the
                        \       face is always shown
                        \
                        \     * Bits 7-5 = the sign bits of normal_x, normal_y
                        \       and normal_z

 STA XX12+1             \ Store byte #0 in XX12+1, so XX12+1 now has the sign of
                        \ normal_x

 AND #%00011111         \ Extract bits 0-4 to give the visibility distance

 CMP XX4                \ If XX4 <= the visibility distance, where XX4 contains
 BCS LL87               \ the ship's z-distance reduced to 0-31 (which we set in
                        \ part 2), skip to LL87 as this face is close enough
                        \ that we have to test its visibility using the face
                        \ normals

                        \ Otherwise this face is within range and is therefore
                        \ always shown

 TYA                    \ Set X = Y / 4
 LSR A                  \       = the number of this face * 4 /4
 LSR A                  \       = the number of this face
 TAX

 LDA #255               \ Set the X-th byte of XX2 to 255 to denote that this
 STA XX2,X              \ face is visible

 TYA                    \ Set Y = Y + 4 to point to the next face
 ADC #4
 TAY

 JMP LL88               \ Jump down to LL88 to skip the following, as we don't
                        \ need to test the face normals

.LL87

 LDA XX12+1             \ Fetch byte #0 for this face into A

 ASL A                  \ Shift A left and store it, so XX12+3 now has the sign
 STA XX12+3             \ of normal_y

 ASL A                  \ Shift A left and store it, so XX12+5 now has the sign
 STA XX12+5             \ of normal_z

 INY                    \ Increment Y to point to byte #1

 LDA (V),Y              \ Fetch byte #1 for this face and store in XX12, so
 STA XX12               \ XX12 = normal_x

 INY                    \ Increment Y to point to byte #2

 LDA (V),Y              \ Fetch byte #2 for this face and store in XX12+2, so
 STA XX12+2             \ XX12+2 = normal_y

 INY                    \ Increment Y to point to byte #3

 LDA (V),Y              \ Fetch byte #3 for this face and store in XX12+4, so
 STA XX12+4             \ XX12+4 = normal_z

                        \ So we now have:
                        \
                        \   XX12(1 0) = (normal_x_sign normal_x)
                        \
                        \   XX12(3 2) = (normal_y_sign normal_y)
                        \
                        \   XX12(5 4) = (normal_z_sign normal_z)

 LDX XX17               \ If XX17 < 4 then jump to LL92, otherwise we stored a
 CPX #4                 \ larger scale factor above
 BCC LL92

.LL143

 LDA XX18               \ Set XX15(1 0) = XX18(2 0)
 STA XX15               \               = dot_sidev
 LDA XX18+2
 STA XX15+1

 LDA XX18+3             \ Set XX15(3 2) = XX18(5 3)
 STA XX15+2             \               = dot_roofv
 LDA XX18+5
 STA XX15+3

 LDA XX18+6             \ Set XX15(5 4) = XX18(8 6)
 STA XX15+4             \               = dot_nosev
 LDA XX18+8
 STA XX15+5

 JMP LL89               \ Jump down to LL89

.ovflw

                        \ If we get here then the addition below overflowed, so
                        \ we halve the dot products and normal vector

 LSR XX18               \ Divide dot_sidev_lo by 2, so dot_sidev = dot_sidev / 2

 LSR XX18+6             \ Divide dot_nosev_lo by 2, so dot_nosev = dot_nosev / 2

 LSR XX18+3             \ Divide dot_roofv_lo by 2, so dot_roofv = dot_roofv / 2

 LDX #1                 \ Set X = 1 so when we fall through into LL92, we divide
                        \ the normal vector by 2 as well

.LL92

                        \ We jump here from above with the scale factor in X,
                        \ and now we apply it by scaling the normal vector down
                        \ by a factor of 2^X (i.e. divide by 2^X)

 LDA XX12               \ Set XX15 = normal_x
 STA XX15

 LDA XX12+2             \ Set XX15+2 = normal_y
 STA XX15+2

 LDA XX12+4             \ Set A = normal_z

.LL93

 DEX                    \ Decrement the scale factor in X

 BMI LL94               \ If X was 0 before the decrement, there is no scaling
                        \ to do, so jump to LL94 to exit the loop

 LSR XX15               \ Set XX15 = XX15 / 2
                        \          = normal_x / 2

 LSR XX15+2             \ Set XX15+2 = XX15+2 / 2
                        \            = normal_y / 2

 LSR A                  \ Set A = A / 2
                        \       = normal_z / 2

 DEX                    \ Decrement the scale factor in X

 BPL LL93+3             \ If we have more scaling to do, loop back up to the
                        \ first LSR above until the normal vector is scaled down

.LL94

 STA R                  \ Set R = normal_z

 LDA XX12+5             \ Set S = normal_z_sign
 STA S

 LDA XX18+6             \ Set Q = dot_nosev_lo
 STA Q

 LDA XX18+8             \ Set A = dot_nosev_sign

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = normal_z + dot_nosev
                        \
                        \ setting the sign of the result in S

 BCS ovflw              \ If the addition overflowed, jump up to ovflw to divide
                        \ both the normal vector and dot products by 2 and try
                        \ again

 STA XX15+4             \ Set XX15(5 4) = (S A)
 LDA S                  \               = normal_z + dot_nosev
 STA XX15+5

 LDA XX15               \ Set R = normal_x
 STA R

 LDA XX12+1             \ Set S = normal_x_sign
 STA S

 LDA XX18               \ Set Q = dot_sidev_lo
 STA Q

 LDA XX18+2             \ Set A = dot_sidev_sign

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = normal_x + dot_sidev
                        \
                        \ setting the sign of the result in S

 BCS ovflw              \ If the addition overflowed, jump up to ovflw to divide
                        \ both the normal vector and dot products by 2 and try
                        \ again

 STA XX15               \ Set XX15(1 0) = (S A)
 LDA S                  \               = normal_x + dot_sidev
 STA XX15+1

 LDA XX15+2             \ Set R = normal_y
 STA R

 LDA XX12+3             \ Set S = normal_y_sign
 STA S

 LDA XX18+3             \ Set Q = dot_roofv_lo
 STA Q

 LDA XX18+5             \ Set A = dot_roofv_sign

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = normal_y + dot_roofv

 BCS ovflw              \ If the addition overflowed, jump up to ovflw to divide
                        \ both the normal vector and dot products by 2 and try
                        \ again

 STA XX15+2             \ Set XX15(3 2) = (S A)
 LDA S                  \               = normal_y + dot_roofv
 STA XX15+3

.LL89

                        \ When we get here, we have set up the following:
                        \
                        \   XX15(1 0) = normal_x + dot_sidev
                        \             = normal_x + [x y z] . sidev
                        \
                        \   XX15(3 2) = normal_y + dot_roofv
                        \             = normal_y + [x y z] . roofv
                        \
                        \   XX15(5 4) = normal_z + dot_nosev
                        \             = normal_z + [x y z] . nosev
                        \
                        \ and:
                        \
                        \   XX12(1 0) = (normal_x_sign normal_x)
                        \
                        \   XX12(3 2) = (normal_y_sign normal_y)
                        \
                        \   XX12(5 4) = (normal_z_sign normal_z)
                        \
                        \ We now calculate the dot product XX12 . XX15 to tell
                        \ us whether or not this face is visible

 LDA XX12               \ Set Q = XX12
 STA Q

 LDA XX15               \ Set A = XX15

 JSR FMLTU              \ Set T = A * Q / 256
 STA T                  \       = XX15 * XX12 / 256

 LDA XX12+1             \ Set S = sign of XX15(1 0) * XX12(1 0), so:
 EOR XX15+1             \
 STA S                  \   (S T) = XX15(1 0) * XX12(1 0) / 256

 LDA XX12+2             \ Set Q = XX12+2
 STA Q

 LDA XX15+2             \ Set A = XX15+2

 JSR FMLTU              \ Set Q = A * Q
 STA Q                  \       = XX15+2 * XX12+2 / 256

 LDA T                  \ Set T = R, so now:
 STA R                  \
                        \   (S R) = XX15(1 0) * XX12(1 0) / 256

 LDA XX12+3             \ Set A = sign of XX15+3 * XX12+3, so:
 EOR XX15+3             \
                        \   (A Q) = XX15(3 2) * XX12(3 2) / 256

 JSR LL38               \ Set (S T) = (S R) + (A Q)
 STA T                  \           =   XX15(1 0) * XX12(1 0) / 256
                        \             + XX15(3 2) * XX12(3 2) / 256

 LDA XX12+4             \ Set Q = XX12+4
 STA Q

 LDA XX15+4             \ Set A = XX15+4

 JSR FMLTU              \ Set Q = A * Q
 STA Q                  \       = XX15+4 * XX12+4 / 256

 LDA T                  \ Set T = R, so now:
 STA R                  \
                        \   (S R) =   XX15(1 0) * XX12(1 0) / 256
                        \           + XX15(3 2) * XX12(3 2) / 256

 LDA XX15+5             \ Set A = sign of XX15+5 * XX12+5, so:
 EOR XX12+5             \
                        \   (A Q) = XX15(5 4) * XX12(5 4) / 256

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           =   XX15(1 0) * XX12(1 0) / 256
                        \             + XX15(3 2) * XX12(3 2) / 256
                        \             + XX15(5 4) * XX12(5 4) / 256

 PHA                    \ Push the result A onto the stack, so the stack now
                        \ contains the dot product XX12 . XX15

 TYA                    \ Set X = Y / 4
 LSR A                  \       = the number of this face * 4 /4
 LSR A                  \       = the number of this face
 TAX

 PLA                    \ Pull the dot product off the stack into A

 BIT S                  \ If bit 7 of S is set, i.e. the dot product is
 BMI P%+4               \ negative, then this face is visible as its normal is
                        \ pointing towards us, so skip the following instruction

 LDA #0                 \ Otherwise the face is not visible, so set A = 0 so we
                        \ can store this to mean "not visible"

 STA XX2,X              \ Store the face's visibility in the X-th byte of XX2

 INY                    \ Above we incremented Y to point to byte #3, so this
                        \ increments Y to point to byte #4, i.e. byte #0 of the
                        \ next face

.LL88

 CPY XX20               \ If Y >= XX20, the number of faces * 4, jump down to
 BCS LL42               \ LL42 to move on to the

 JMP LL86               \ Otherwise loop back to LL86 to work out the visibility
                        \ of the next face

\ ******************************************************************************
\
\       Name: LL9 (Part 6 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's vertices
\  Deep dive: Drawing ships
\             Calculating vertex coordinates
\
\ ------------------------------------------------------------------------------
\
\ This section calculates the visibility of each of the ship's vertices, and for
\ those that are visible, it starts the process of calculating the screen
\ coordinates of each vertex
\
\ ******************************************************************************

.LL42

                        \ The first task is to set up the inverse matrix, ready
                        \ for us to send to the dot product routine at LL51.
                        \ Back up in part 3, we set up the following variables:
                        \
                        \   * XX16(1 0) = sidev_x
                        \   * XX16(3 2) = sidev_y
                        \   * XX16(5 4) = sidev_z
                        \
                        \   * XX16(7 6) = roofv_x
                        \   * XX16(9 8) = roofv_y
                        \   * XX16(11 10) = roofv_z
                        \
                        \   * XX16(13 12) = nosev_x
                        \   * XX16(15 14) = nosev_y
                        \   * XX16(17 16) = nosev_z
                        \
                        \ and we then scaled the vectors to give the following:
                        \
                        \   * XX16   = scaled |sidev_x|
                        \   * XX16+2 = scaled |sidev_y|
                        \   * XX16+4 = scaled |sidev_z|
                        \
                        \   * XX16+6  = scaled |roofv_x|
                        \   * XX16+8  = scaled |roofv_y|
                        \   * XX16+10 = scaled |roofv_z|
                        \
                        \   * XX16+12 = scaled |nosev_x|
                        \   * XX16+14 = scaled |nosev_y|
                        \   * XX16+16 = scaled |nosev_z|
                        \
                        \ We now need to rearrange these locations so they
                        \ effectively transpose the matrix into its inverse

 LDY XX16+2             \ Set XX16+2 = XX16+6 = scaled |roofv_x|
 LDX XX16+3             \ Set XX16+3 = XX16+7 = roofv_x_hi
 LDA XX16+6             \ Set XX16+6 = XX16+2 = scaled |sidev_y|
 STA XX16+2             \ Set XX16+7 = XX16+3 = sidev_y_hi
 LDA XX16+7
 STA XX16+3
 STY XX16+6
 STX XX16+7

 LDY XX16+4             \ Set XX16+4 = XX16+12 = scaled |nosev_x|
 LDX XX16+5             \ Set XX16+5 = XX16+13 = nosev_x_hi
 LDA XX16+12            \ Set XX16+12 = XX16+4 = scaled |sidev_z|
 STA XX16+4             \ Set XX16+13 = XX16+5 = sidev_z_hi
 LDA XX16+13
 STA XX16+5
 STY XX16+12
 STX XX16+13

 LDY XX16+10            \ Set XX16+10 = XX16+14 = scaled |nosev_y|
 LDX XX16+11            \ Set XX16+11 = XX16+15 = nosev_y_hi
 LDA XX16+14            \ Set XX16+14 = XX16+10 = scaled |roofv_z|
 STA XX16+10            \ Set XX16+15 = XX16+11 = roofv_z
 LDA XX16+15
 STA XX16+11
 STY XX16+14
 STX XX16+15

                        \ So now we have the following sign-magnitude variables
                        \ containing parts of the scaled orientation vectors:
                        \
                        \   XX16(1 0)   = scaled sidev_x
                        \   XX16(3 2)   = scaled roofv_x
                        \   XX16(5 4)   = scaled nosev_x
                        \
                        \   XX16(7 6)   = scaled sidev_y
                        \   XX16(9 8)   = scaled roofv_y
                        \   XX16(11 10) = scaled nosev_y
                        \
                        \   XX16(13 12) = scaled sidev_z
                        \   XX16(15 14) = scaled roofv_z
                        \   XX16(17 16) = scaled nosev_z
                        \
                        \ which is what we want, as the various vectors are now
                        \ arranged so we can use LL51 to multiply by the
                        \ transpose (i.e. the inverse of the matrix)

 LDY #8                 \ Fetch byte #8 of the ship's blueprint, which is the
 LDA (XX0),Y            \ number of vertices * 8, and store it in XX20
 STA XX20

                        \ We now set V(1 0) = XX0(1 0) + 20, so V(1 0) points
                        \ to byte #20 of the ship's blueprint, which is always
                        \ where the vertex data starts (i.e. just after the 20
                        \ byte block that define the ship's characteristics)

 LDA XX0                \ We start with the low bytes
 CLC
 ADC #20
 STA V

 LDA XX0+1              \ And then do the high bytes
 ADC #0
 STA V+1

 LDY #0                 \ We are about to step through all the vertices, using
                        \ Y as a counter. There are six data bytes for each
                        \ vertex, so we will increment Y by 6 for each iteration
                        \ so it can act as an offset from V(1 0) to the current
                        \ vertex's data

 STY CNT                \ Set CNT = 0, which we will use as a pointer to the
                        \ heap at XX3, starting it at zero so the heap starts
                        \ out empty

.LL48

 STY XX17               \ Set XX17 = Y, so XX17 now contains the offset of the
                        \ current vertex's data

 LDA (V),Y              \ Fetch byte #0 for this vertex into XX15, so:
 STA XX15               \
                        \   XX15 = magnitude of the vertex's x-coordinate

 INY                    \ Increment Y to point to byte #1

 LDA (V),Y              \ Fetch byte #1 for this vertex into XX15+2, so:
 STA XX15+2             \
                        \   XX15+2 = magnitude of the vertex's y-coordinate

 INY                    \ Increment Y to point to byte #2

 LDA (V),Y              \ Fetch byte #2 for this vertex into XX15+4, so:
 STA XX15+4             \
                        \   XX15+4 = magnitude of the vertex's z-coordinate

 INY                    \ Increment Y to point to byte #3

 LDA (V),Y              \ Fetch byte #3 for this vertex into T, so:
 STA T                  \
                        \   T = %xyz vvvvv, where:
                        \
                        \     * Bits 0-4 = visibility distance, beyond which the
                        \                  vertex is not shown
                        \
                        \     * Bits 7-5 = the sign bits of x, y and z

 AND #%00011111         \ Extract bits 0-4 to get the visibility distance

 CMP XX4                \ If XX4 > the visibility distance, where XX4 contains
 BCC LL49-3             \ the ship's z-distance reduced to 0-31 (which we set in
                        \ part 2), then this vertex is too far away to be
                        \ visible, so jump down to LL50 (via the JMP instruction
                        \ in LL49-3) to move on to the next vertex

 INY                    \ Increment Y to point to byte #4

 LDA (V),Y              \ Fetch byte #4 for this vertex into P, so:
 STA P                  \
                        \  P = %ffff ffff, where:
                        \
                        \    * Bits 0-3 = the number of face 1
                        \
                        \    * Bits 4-7 = the number of face 2

 AND #%00001111         \ Extract the number of face 1 into X
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 1 is visible, so jump to LL49

 LDA P                  \ Fetch byte #4 for this vertex into A

 LSR A                  \ Shift right four times to extract the number of face 2
 LSR A                  \ from bits 4-7 into X
 LSR A
 LSR A
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 2 is visible, so jump to LL49

 INY                    \ Increment Y to point to byte #5

 LDA (V),Y              \ Fetch byte #5 for this vertex into P, so:
 STA P                  \
                        \  P = %ffff ffff, where:
                        \
                        \    * Bits 0-3 = the number of face 3
                        \
                        \    * Bits 4-7 = the number of face 4

 AND #%00001111         \ Extract the number of face 1 into X
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 3 is visible, so jump to LL49

 LDA P                  \ Fetch byte #5 for this vertex into A

 LSR A                  \ Shift right four times to extract the number of face 4
 LSR A                  \ from bits 4-7 into X
 LSR A
 LSR A
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 4 is visible, so jump to LL49

 JMP LL50               \ If we get here then none of the four faces associated
                        \ with this vertex are visible, so this vertex is also
                        \ not visible, so jump to LL50 to move on to the next
                        \ vertex

.LL49

 LDA T                  \ Fetch byte #5 for this vertex into A and store it, so
 STA XX15+1             \ XX15+1 now has the sign of the vertex's x-coordinate

 ASL A                  \ Shift A left and store it, so XX15+3 now has the sign
 STA XX15+3             \ of the vertex's y-coordinate

 ASL A                  \ Shift A left and store it, so XX15+5 now has the sign
 STA XX15+5             \ of the vertex's z-coordinate

                        \ By this point we have the following:
                        \
                        \   XX15(1 0) = vertex x-coordinate
                        \   XX15(3 2) = vertex y-coordinate
                        \   XX15(5 4) = vertex z-coordinate
                        \
                        \   XX16(1 0)   = scaled sidev_x
                        \   XX16(3 2)   = scaled roofv_x
                        \   XX16(5 4)   = scaled nosev_x
                        \
                        \   XX16(7 6)   = scaled sidev_y
                        \   XX16(9 8)   = scaled roofv_y
                        \   XX16(11 10) = scaled nosev_y
                        \
                        \   XX16(13 12) = scaled sidev_z
                        \   XX16(15 14) = scaled roofv_z
                        \   XX16(17 16) = scaled nosev_z

 JSR LL51               \ Call LL51 to set XX12 to the dot products of XX15 and
                        \ XX16, as follows:
                        \
                        \   XX12(1 0) = [ x y z ] . [ sidev_x roofv_x nosev_x ]
                        \
                        \   XX12(3 2) = [ x y z ] . [ sidev_y roofv_y nosev_y ]
                        \
                        \   XX12(5 4) = [ x y z ] . [ sidev_z roofv_z nosev_z ]
                        \
                        \ XX12 contains the vector from the ship's centre to
                        \ the vertex, transformed from the orientation vector
                        \ space to the universe orientated around our ship. So
                        \ we can refer to this vector below, let's call it
                        \ vertv, so:
                        \
                        \   vertv_x = [ x y z ] . [ sidev_x roofv_x nosev_x ]
                        \
                        \   vertv_y = [ x y z ] . [ sidev_y roofv_y nosev_y ]
                        \
                        \   vertv_z = [ x y z ] . [ sidev_z roofv_z nosev_z ]
                        \
                        \ To finish the calculation, we now want to calculate:
                        \
                        \   vertv + [ x y z ]
                        \
                        \ So let's start with the vertv_x + x

 LDA XX1+2              \ Set A = x_sign of the ship's location

 STA XX15+2             \ Set XX15+2 = x_sign

 EOR XX12+1             \ If the sign of x_sign * the sign of vertv_x is
 BMI LL52               \ negative (i.e. they have different signs), skip to
                        \ LL52

 CLC                    \ Set XX15(2 1 0) = XX1(2 1 0) + XX12(1 0)
 LDA XX12               \                 = (x_sign x_hi x_lo) + vertv_x
 ADC XX1                \
 STA XX15               \ Starting with the low bytes

 LDA XX1+1              \ And then doing the high bytes (we can add 0 here as
 ADC #0                 \ we know the sign byte of vertv_x is 0)
 STA XX15+1

 JMP LL53               \ We've added the x-coordinates, so jump to LL53 to do
                        \ the y-coordinates

.LL52

                        \ If we get here then x_sign and vertv_x have different
                        \ signs, so we need to subtract them to get the result

 LDA XX1                \ Set XX15(2 1 0) = XX1(2 1 0) - XX12(1 0)
 SEC                    \                 = (x_sign x_hi x_lo) - vertv_x
 SBC XX12               \
 STA XX15               \ Starting with the low bytes

 LDA XX1+1              \ And then doing the high bytes (we can subtract 0 here
 SBC #0                 \ as we know the sign byte of vertv_x is 0)
 STA XX15+1

 BCS LL53               \ If the subtraction didn't underflow, then the sign of
                        \ the result is the same sign as x_sign, and that's what
                        \ we want, so we can jump down to LL53 to do the
                        \ y-coordinates

 EOR #%11111111         \ Otherwise we need to negate the result using two's
 STA XX15+1             \ complement, so first we flip the bits of the high byte

 LDA #1                 \ And then subtract the low byte from 1
 SBC XX15
 STA XX15

 BCC P%+4               \ If the above subtraction underflowed then we need to
 INC XX15+1             \ bump the high byte of the result up by 1

 LDA XX15+2             \ And now we flip the sign of the result to get the
 EOR #%10000000         \ correct result
 STA XX15+2

.LL53

                        \ Now for the y-coordinates, vertv_y + y

 LDA XX1+5              \ Set A = y_sign of the ship's location

 STA XX15+5             \ Set XX15+5 = y_sign

 EOR XX12+3             \ If the sign of y_sign * the sign of vertv_y is
 BMI LL54               \ negative (i.e. they have different signs), skip to
                        \ LL54

 CLC                    \ Set XX15(5 4 3) = XX1(5 4 3) + XX12(3 2)
 LDA XX12+2             \                 = (y_sign y_hi y_lo) + vertv_y
 ADC XX1+3              \
 STA XX15+3             \ Starting with the low bytes

 LDA XX1+4              \ And then doing the high bytes (we can add 0 here as
 ADC #0                 \ we know the sign byte of vertv_y is 0)
 STA XX15+4

 JMP LL55               \ We've added the y-coordinates, so jump to LL55 to do
                        \ the z-coordinates

.LL54

                        \ If we get here then y_sign and vertv_y have different
                        \ signs, so we need to subtract them to get the result

 LDA XX1+3              \ Set XX15(5 4 3) = XX1(5 4 3) - XX12(3 2)
 SEC                    \                 = (y_sign y_hi y_lo) - vertv_y
 SBC XX12+2             \
 STA XX15+3             \ Starting with the low bytes

 LDA XX1+4              \ And then doing the high bytes (we can subtract 0 here
 SBC #0                 \ as we know the sign byte of vertv_z is 0)
 STA XX15+4

 BCS LL55               \ If the subtraction didn't underflow, then the sign of
                        \ the result is the same sign as y_sign, and that's what
                        \ we want, so we can jump down to LL55 to do the
                        \ z-coordinates

 EOR #%11111111         \ Otherwise we need to negate the result using two's
 STA XX15+4             \ complement, so first we flip the bits of the high byte

 LDA XX15+3             \ And then flip the bits of the low byte and add 1
 EOR #%11111111
 ADC #1
 STA XX15+3

 LDA XX15+5             \ And now we flip the sign of the result to get the
 EOR #%10000000         \ correct result
 STA XX15+5

 BCC LL55               \ If the above subtraction underflowed then we need to
 INC XX15+4             \ bump the high byte of the result up by 1

.LL55

                        \ Now for the z-coordinates, vertv_z + z

 LDA XX12+5             \ If vertv_z_hi is negative, jump down to LL56
 BMI LL56

 LDA XX12+4             \ Set (U T) = XX1(7 6) + XX12(5 4)
 CLC                    \           = (z_hi z_lo) + vertv_z
 ADC XX1+6              \
 STA T                  \ Starting with the low bytes

 LDA XX1+7              \ And then doing the high bytes (we can add 0 here as
 ADC #0                 \ we know the sign byte of vertv_y is 0)
 STA U

 JMP LL57               \ We've added the z-coordinates, so jump to LL57

                        \ The adding process is continued in part 7, after a
                        \ couple of subroutines that we don't need quite yet

\ ******************************************************************************
\
\       Name: LL61
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (U R) = 256 * A / Q
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following, where A >= Q:
\
\   (U R) = 256 * A / Q
\
\ This is a sister routine to LL28, which does the division when A < Q.
\
\ ******************************************************************************

.LL61

 LDX Q                  \ If Q = 0, jump down to LL84 to return a division
 BEQ LL84               \ error

                        \ The LL28 routine returns A / Q, but only if A < Q. In
                        \ our case A >= Q, but we still want to use the LL28
                        \ routine, so we halve A until it's less than Q, call
                        \ the division routine, and then double A by the same
                        \ number of times

 LDX #0                 \ Set X = 0 to count the number of times we halve A

.LL63

 LSR A                  \ Halve A by shifting right

 INX                    \ Increment X

 CMP Q                  \ If A >= Q, loop back to LL63 to halve it again
 BCS LL63

 STX S                  \ Otherwise store the number of times we halved A in S

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \
                        \ which we can do now as A < Q

 LDX S                  \ Otherwise restore the number of times we halved A
                        \ above into X

 LDA R                  \ Set A = our division result

.LL64

 ASL A                  \ Double (U A) by shifting left
 ROL U

 BMI LL84               \ If bit 7 of U is set, the doubling has overflowed, so
                        \ jump to LL84 to return a division error

 DEX                    \ Decrement X

 BNE LL64               \ If X is not yet zero then we haven't done as many
                        \ doublings as we did halvings earlier, so loop back for
                        \ another doubling

 STA R                  \ Store the low byte of the division result in R

 RTS                    \ Return from the subroutine

.LL84

 LDA #50                \ If we get here then either we tried to divide by 0, or
 STA R                  \ the result overflowed, so we set U and R to 50
 STA U

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL62
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate 128 - (U R)
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following for a positive sign-magnitude number (U R):
\
\   128 - (U R)
\
\ and then store the result, low byte then high byte, on the end of the heap at
\ XX3, where X points to the first free byte on the heap. Return by jumping down
\ to LL66.
\
\ Returns:
\
\   X                   X is incremented by 1
\
\ ******************************************************************************

.LL62

 LDA #128               \ Calculate 128 - (U R), starting with the low bytes
 SEC
 SBC R

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA #0                 \ And then subtract the high bytes
 SBC U

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 JMP LL66               \ Jump down to LL66

\ ******************************************************************************
\
\       Name: LL9 (Part 7 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's vertices
\  Deep dive: Drawing ships
\             Calculating vertex coordinates
\
\ ------------------------------------------------------------------------------
\
\ This section continues the coordinate adding from part 6 by finishing off the
\ calculation that we started above:
\
\                      [ sidev_x roofv_x nosev_x ]   [ x ]   [ x ]
\   vector to vertex = [ sidev_y roofv_y nosev_y ] . [ y ] + [ y ]
\                      [ sidev_z roofv_z nosev_z ]   [ z ]   [ z ]
\
\ The gets stored as follows, in sign-magnitude values with the magnitudes
\ fitting into the low bytes:
\
\   XX15(2 0)           [ x y z ] . [ sidev_x roofv_x nosev_x ] + [ x y z ]
\
\   XX15(5 3)           [ x y z ] . [ sidev_y roofv_y nosev_y ] + [ x y z ]
\
\   (U T)               [ x y z ] . [ sidev_z roofv_z nosev_z ] + [ x y z ]
\
\ Finally, because this vector is from our ship to the vertex, and we are at the
\ origin, this vector is the same as the coordinates of the vertex. In other
\ words, we have just worked out:
\
\   XX15(2 0)           x-coordinate of the current vertex
\
\   XX15(5 3)           y-coordinate of the current vertex
\
\   (U T)               z-coordinate of the current vertex
\
\ ******************************************************************************

.LL56

 LDA XX1+6              \ Set (U T) = XX1(7 6) - XX12(5 4)
 SEC                    \           = (z_hi z_lo) - vertv_z
 SBC XX12+4             \
 STA T                  \ Starting with the low bytes

 LDA XX1+7              \ And then doing the high bytes (we can subtract 0 here
 SBC #0                 \ as we know the sign byte of vertv_z is 0)
 STA U

 BCC LL140              \ If the subtraction just underflowed, skip to LL140 to
                        \ set (U T) to the minimum value of 4

 BNE LL57               \ If U is non-zero, jump down to LL57

 LDA T                  \ If T >= 4, jump down to LL57
 CMP #4
 BCS LL57

.LL140

 LDA #0                 \ If we get here then either (U T) < 4 or the
 STA U                  \ subtraction underflowed, so set (U T) = 4
 LDA #4
 STA T

.LL57

                        \ By this point we have our results, so now to scale
                        \ the 16-bit results down into 8-bit values

 LDA U                  \ If the high bytes of the result are all zero, we are
 ORA XX15+1             \ done, so jump down to LL60 for the next stage
 ORA XX15+4
 BEQ LL60

 LSR XX15+1             \ Shift XX15(1 0) to the right
 ROR XX15

 LSR XX15+4             \ Shift XX15(4 3) to the right
 ROR XX15+3

 LSR U                  \ Shift (U T) to the right
 ROR T

 JMP LL57               \ Jump back to LL57 to see if we can shift the result
                        \ any more

\ ******************************************************************************
\
\       Name: LL9 (Part 8 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the screen coordinates of visible vertices
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This section projects the coordinate of the vertex into screen coordinates and
\ stores them on the XX3 heap. By the end of this part, the XX3 heap contains
\ four bytes containing the 16-bit screen coordinates of the current vertex, in
\ the order: x_lo, x_hi, y_lo, y_hi.
\
\ When we reach here, we are looping through the vertices, and we've just worked
\ out the coordinates of the vertex in our normal coordinate system, as follows
\
\   XX15(2 0)           (x_sign x_lo) = x-coordinate of the current vertex
\
\   XX15(5 3)           (y_sign y_lo) = y-coordinate of the current vertex
\
\   (U T)               (z_sign z_lo) = z-coordinate of the current vertex
\
\ Note that U is always zero when we get to this point, as the vertex is always
\ in front of us (so it has a positive z-coordinate, into the screen).
\
\ Other entry points:
\
\   LL70+1              Contains an RTS (as the first byte of an LDA
\                       instruction)
\
\ ******************************************************************************

.LL60

 LDA T                  \ Set Q = z_lo
 STA Q

 LDA XX15               \ Set A = x_lo

 CMP Q                  \ If x_lo < z_lo jump to LL69
 BCC LL69

 JSR LL61               \ Call LL61 to calculate:
                        \
                        \   (U R) = 256 * A / Q
                        \         = 256 * x / z
                        \
                        \ which we can do as x >= z

 JMP LL65               \ Jump to LL65 to skip the division for x_lo < z_lo

.LL69

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * x / z
                        \
                        \ Because x < z, the result fits into one byte, and we
                        \ also know that U = 0, so (U R) also contains the
                        \ result

.LL65

                        \ At this point we have:
                        \
                        \   (U R) = x / z
                        \
                        \ so (U R) contains the vertex's x-coordinate projected
                        \ on screen
                        \
                        \ The next task is to convert (U R) to a pixel screen
                        \ coordinate and stick it on the XX3 heap.
                        \
                        \ We start with the x-coordinate. To convert the
                        \ x-coordinate to a screen pixel we add 128, the
                        \ x-coordinate of the centre of the screen, because the
                        \ projected value is relative to an origin at the centre
                        \ of the screen, but the origin of the screen pixels is
                        \ at the top-left of the screen

 LDX CNT                \ Fetch the pointer to the end of the XX3 heap from CNT
                        \ into X

 LDA XX15+2             \ If x_sign is negative, jump up to LL62, which will
 BMI LL62               \ store 128 - (U R) on the XX3 heap and return by
                        \ jumping down to LL66 below

 LDA R                  \ Calculate 128 + (U R), starting with the low bytes
 CLC
 ADC #128

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA U                  \ And then add the high bytes
 ADC #0

 STA XX3,X              \ Store the high byte of the result in the X-th byte of
                        \ the heap at XX3

.LL66

                        \ We've just stored the screen x-coordinate of the
                        \ vertex on the XX3 heap, so now for the y-coordinate

 TXA                    \ Store the heap pointer in X on the stack (at this
 PHA                    \ it points to the last entry on the heap, not the first
                        \ free byte)

 LDA #0                 \ Set U = 0
 STA U

 LDA T                  \ Set Q = z_lo
 STA Q

 LDA XX15+3             \ Set A = y_lo

 CMP Q                  \ If y_lo < z_lo jump to LL67
 BCC LL67

 JSR LL61               \ Call LL61 to calculate:
                        \
                        \   (U R) = 256 * A / Q
                        \         = 256 * y / z
                        \
                        \ which we can do as y >= z

 JMP LL68               \ Jump to LL68 to skip the division for y_lo < z_lo

.LL70

                        \ This gets called from below when y_sign is negative

 LDA #Y                 \ Calculate #Y + (U R), starting with the low bytes
 CLC
 ADC R

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA #0                 \ And then add the high bytes
 ADC U

 STA XX3,X              \ Store the high byte of the result in the X-th byte of
                        \ the heap at XX3

 JMP LL50               \ Jump to LL68 to skip the division for y_lo < z_lo

.LL67

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * y / z
                        \
                        \ Because y < z, the result fits into one byte, and we
                        \ also know that U = 0, so (U R) also contains the
                        \ result

.LL68

                        \ At this point we have:
                        \
                        \   (U R) = y / z
                        \
                        \ so (U R) contains the vertex's y-coordinate projected
                        \ on screen
                        \
                        \ We now want to convert this to a screen y-coordinate
                        \ and stick it on the XX3 heap, much like we did with
                        \ the x-coordinate above. Again, we convert the
                        \ coordinate by adding or subtracting the y-coordinate
                        \ of the centre of the screen, which is in the constant
                        \ #Y, but this time we do the opposite, as a positive
                        \ projected y-coordinate, i.e. up the space y-axis and
                        \ up the screen, converts to a low y-coordinate, which
                        \ is the opposite way round to the x-coordinates

 PLA                    \ Restore the heap pointer from the stack into X
 TAX

 INX                    \ When we stored the heap pointer, it pointed to the
                        \ last entry on the heap, not the first free byte, so we
                        \ increment it so it does point to the next free byte

 LDA XX15+5             \ If y_sign is negative, jump up to LL70, which will
 BMI LL70               \ store #Y + (U R) on the XX3 heap and return by jumping
                        \ down to LL50 below

 LDA #Y                 \ Calculate #Y - (U R), starting with the low bytes
 SEC
 SBC R

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA #0                 \ And then subtract the high bytes
 SBC U

 STA XX3,X              \ Store the high byte of the result in the X-th byte of
                        \ the heap at XX3

.LL50

                        \ By the time we get here, the XX3 heap contains four
                        \ bytes containing the screen coordinates of the current
                        \ vertex, in the order: x_lo, x_hi, y_lo, y_hi

 CLC                    \ Set CNT = CNT + 4, so the heap pointer points to the
 LDA CNT                \ next free byte on the heap
 ADC #4
 STA CNT

 LDA XX17               \ Set A to the offset of the current vertex's data,
                        \ which we set in part 6

 ADC #6                 \ Set Y = A + 6, so Y now points to the data for the
 TAY                    \ next vertex

 BCS LL72               \ If the addition just overflowed, meaning we just tried
                        \ to access vertex #43, jump to LL72, as the maximum
                        \ number of vertices allowed is 42

 CMP XX20               \ If Y >= number of vertices * 6 (which we stored in
 BCS LL72               \ XX20 in part 6), jump to LL72, as we have processed
                        \ all the vertices for this ship

 JMP LL48               \ Loop back to LL48 in part 6 to calculate visibility
                        \ and screen coordinates for the next vertex

\ ******************************************************************************
\
\       Name: LL9 (Part 9 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Draw laser beams if the ship is firing its laser at us
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part sets things up so we can loop through the edges in the next part. It
\ also adds a line to the ship line heap, if the ship is firing at us.
\
\ When we get here, the heap at XX3 contains all the visible vertex screen
\ coordinates.
\
\ ******************************************************************************

.LL72

 LDA XX1+31             \ If bit 5 of the ship's byte #31 is clear, then the
 AND #%00100000         \ ship is not currently exploding, so jump down to EE31
 BEQ EE31

 LDA XX1+31             \ The ship is exploding, so set bit 3 of the ship's byte
 ORA #8                 \ #31 to denote that we are drawing something on-screen
 STA XX1+31             \ for this ship

 JMP DOEXP              \ Jump to DOEXP to display the explosion cloud,
                        \ returning from the subroutine using a tail call

.EE31

 LDA #%00001000         \ If bit 3 of the ship's byte #31 is clear, then there
 BIT XX1+31             \ is nothing already being shown for this ship, so skip
 BEQ LL74               \ to LL74 as we don't need to erase anything from the
                        \ screen

 JSR LL155              \ Otherwise call LL155 to draw the existing ship, which
                        \ removes it from the screen

 LDA #%00001000         \ Set bit 3 of A so the next instruction sets bit 3 of
                        \ the ship's byte #31 to denote that we are drawing
                        \ something on-screen for this ship

.LL74

 ORA XX1+31             \ Apply bit 3 of A to the ship's byte #31, so if there
 STA XX1+31             \ was no ship already on screen, the bit is clear,
                        \ otherwise it is set

 LDY #9                 \ Fetch byte #9 of the ship's blueprint, which is the
 LDA (XX0),Y            \ number of edges, and store it in XX20
 STA XX20

 LDY #0                 \ We are about to step through all the edges, using Y
                        \ as a counter

 STY U                  \ Set U = 0 (though we increment it to 1 below)

 STY XX17               \ Set XX17 = 0, which we are going to use as a counter
                        \ for stepping through the ship's edges

 INC U                  \ We are going to start calculating the lines we need to
                        \ draw for this ship, and will store them in the ship
                        \ line heap, using U to point to the end of the heap, so
                        \ we start by setting U = 1

 BIT XX1+31             \ If bit 6 of the ship's byte #31 is clear, then the
 BVC LL170              \ ship is not firing its lasers, so jump to LL170 to
                        \ skip the drawing of laser lines

                        \ The ship is firing its laser at us, so we need to draw
                        \ the laser lines

 LDA XX1+31             \ Clear bit 6 of the ship's byte #31 so the ship doesn't
 AND #%10111111         \ keep firing endlessly
 STA XX1+31

 LDY #6                 \ Fetch byte #6 of the ship's blueprint, which is the
 LDA (XX0),Y            \ number * 4 of the vertex where the ship has its lasers

 TAY                    \ Put the vertex number into Y, where it can act as an
                        \ index into list of vertex screen coordinates we added
                        \ to the XX3 heap

 LDX XX3,Y              \ Fetch the x_lo coordinate of the laser vertex from the
 STX XX15               \ XX3 heap into XX15

 INX                    \ If X = 255 then the laser vertex is not visible, as
 BEQ LL170              \ the value we stored in part 2 wasn't overwritten by
                        \ the vertex calculation in part 6 and 7, so jump to
                        \ LL170 to skip drawing the laser lines

                        \ We now build a laser beam from the ship's laser vertex
                        \ towards our ship, as follows:
                        \
                        \   XX15(1 0) = laser vertex x-coordinate
                        \
                        \   XX15(3 2) = laser vertex y-coordinate
                        \
                        \   XX15(5 4) = x-coordinate of the end of the beam
                        \
                        \   XX12(1 0) = y-coordinate of the end of the beam
                        \
                        \ The end of the laser beam will be set positioned to
                        \ look good, rather than being directly aimed at us, as
                        \ otherwise we would only see a flashing point of light
                        \ as they unleashed their attack

 LDX XX3+1,Y            \ Fetch the x_hi coordinate of the laser vertex from the
 STX XX15+1             \ XX3 heap into XX15+1

 INX                    \ If X = 255 then the laser vertex is not visible, as
 BEQ LL170              \ the value we stored in part 2 wasn't overwritten by
                        \ a vertex calculation in part 6 and 7, so jump to LL170
                        \ to skip drawing the laser beam

 LDX XX3+2,Y            \ Fetch the y_lo coordinate of the laser vertex from the
 STX XX15+2             \ XX3 heap into XX15+2

 LDX XX3+3,Y            \ Fetch the y_hi coordinate of the laser vertex from the
 STX XX15+3             \ XX3 heap into XX15+3

 LDA #0                 \ Set XX15(5 4) = 0, so their laser beam fires to the
 STA XX15+4             \ left edge of the screen
 STA XX15+5

 STA XX12+1             \ Set XX12(1 0) = the ship's z_lo coordinate, which will
 LDA XX1+6              \ effectively make the vertical position of the end of
 STA XX12               \ the laser beam move around as the ship moves in space

 LDA XX1+2              \ If the ship's x_sign is positive, skip the next
 BPL P%+4               \ instruction

 DEC XX15+4             \ The ship's x_sign is negative (i.e. it's on the left
                        \ side of the screen), so switch the laser beam so it
                        \ goes to the right edge of the screen by decrementing
                        \ XX15(5 4) to 255

 JSR LL145              \ Call LL145 to see if the laser beam needs to be
                        \ clipped to fit on-screen, returning the clipped line's
                        \ end-points in (X1, Y1) and (X2, Y2)

 BCS LL170              \ If the C flag is set then the line is not visible on
                        \ screen, so jump to LL170 so we don't store this line
                        \ in the ship line heap

 LDY U                  \ Fetch the ship line heap pointer, which points to the
                        \ next free byte on the heap, into Y

 LDA XX15               \ Add X1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+1             \ Add Y1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+2             \ Add X2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+3             \ Add Y2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 STY U                  \ Store the updated ship line heap pointer in U

\ ******************************************************************************
\
\       Name: LL9 (Part 10 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's edges
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part calculates which edges are visible - in other words, which lines we
\ should draw - and clips them to fit on the screen.
\
\ When we get here, the heap at XX3 contains all the visible vertex screen
\ coordinates.
\
\ ******************************************************************************

.LL170

 LDY #3                 \ Fetch byte #3 of the ship's blueprint, which contains
 CLC                    \ the low byte of the offset to the edges data
 LDA (XX0),Y

 ADC XX0                \ Set V = low byte edges offset + XX0
 STA V

 LDY #16                \ Fetch byte #16 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the high byte of the offset to the edges data

 ADC XX0+1              \ Set V+1 = high byte edges offset + XX0+1
 STA V+1                \
                        \ So V(1 0) now points to the start of the edges data
                        \ for this ship

 LDY #5                 \ Fetch byte #5 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the maximum heap size for plotting the ship (which is
 STA T1                 \ 1 + 4 * the maximum number of visible edges) and store
                        \ it in T1

 LDY XX17               \ Set Y to the edge counter in XX17

.LL75

 LDA (V),Y              \ Fetch byte #0 for this edge, which contains the
                        \ visibility distance for this edge, beyond which the
                        \ edge is not shown

 CMP XX4                \ If XX4 > the visibility distance, where XX4 contains
 BCC LL78               \ the ship's z-distance reduced to 0-31 (which we set in
                        \ part 2), then this edge is too far away to be visible,
                        \ so jump down to LL78 to move on to the next edge

 INY                    \ Increment Y to point to byte #1

 LDA (V),Y              \ Fetch byte #1 for this edge into A, so:
                        \
                        \   A = %ffff ffff, where:
                        \
                        \     * Bits 0-3 = the number of face 1
                        \
                        \     * Bits 4-7 = the number of face 2

 INY                    \ Increment Y to point to byte #2

 STA P                  \ Store byte #1 into P

 AND #%00001111         \ Extract the number of face 1 into X
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL79               \ face 1 is visible, so jump to LL79

 LDA P                  \ Fetch byte #1 for this edge into A

 LSR A                  \ Shift right four times to extract the number of face 2
 LSR A                  \ from bits 4-7 into X
 LSR A
 LSR A
 TAX

 LDA XX2,X              \ If XX2+X is zero then we decided in part 5 that
 BEQ LL78               \ face 2 is hidden, so jump to LL78

.LL79

                        \ We now build the screen line for this edge, as
                        \ follows:
                        \
                        \   XX15(1 0) = start x-coordinate
                        \
                        \   XX15(3 2) = start y-coordinate
                        \
                        \   XX15(5 4) = end x-coordinate
                        \
                        \   XX12(1 0) = end y-coordinate
                        \
                        \ We can then pass this to the line clipping routine
                        \ before storing the resulting line in the ship line
                        \ heap

 LDA (V),Y              \ Fetch byte #2 for this edge into X, which contains
 TAX                    \ the number of the vertex at the start of the edge

 INY                    \ Increment Y to point to byte #3

 LDA (V),Y              \ Fetch byte #3 for this edge into Q, which contains
 STA Q                  \ the number of the vertex at the end of the edge

 LDA XX3+1,X            \ Fetch the x_hi coordinate of the edge's start vertex
 STA XX15+1             \ from the XX3 heap into XX15+1

 LDA XX3,X              \ Fetch the x_lo coordinate of the edge's start vertex
 STA XX15               \ from the XX3 heap into XX15

 LDA XX3+2,X            \ Fetch the y_lo coordinate of the edge's start vertex
 STA XX15+2             \ from the XX3 heap into XX15+2

 LDA XX3+3,X            \ Fetch the y_hi coordinate of the edge's start vertex
 STA XX15+3             \ from the XX3 heap into XX15+3

 LDX Q                  \ Set X to the number of the vertex at the end of the
                        \ edge, which we stored in Q

 LDA XX3,X              \ Fetch the x_lo coordinate of the edge's end vertex
 STA XX15+4             \ from the XX3 heap into XX15+4

 LDA XX3+3,X            \ Fetch the y_hi coordinate of the edge's end vertex
 STA XX12+1             \ from the XX3 heap into XX11+1

 LDA XX3+2,X            \ Fetch the y_lo coordinate of the edge's end vertex
 STA XX12               \ from the XX3 heap into XX12

 LDA XX3+1,X            \ Fetch the x_hi coordinate of the edge's end vertex
 STA XX15+5             \ from the XX3 heap into XX15+5

 JSR LL147              \ Call LL147 to see if the new line segment needs to be
                        \ clipped to fit on-screen, returning the clipped line's
                        \ end-points in (X1, Y1) and (X2, Y2)

 BCS LL78               \ If the C flag is set then the line is not visible on
                        \ screen, so jump to LL78 so we don't store this line
                        \ in the ship line heap

\ ******************************************************************************
\
\       Name: LL9 (Part 11 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Add all visible edges to the ship line heap
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part adds all the visible edges to the ship line heap, so we can draw
\ them in part 12.
\
\ Other entry points:
\
\   LL81+2              Draw the contents of the ship line heap, used to draw
\                       the ship as a dot from SHPPT
\
\ ******************************************************************************

.LL80

 LDY U                  \ Fetch the ship line heap pointer, which points to the
                        \ next free byte on the heap, into Y

 LDA XX15               \ Add X1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+1             \ Add Y1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+2             \ Add X2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+3             \ Add Y2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 STY U                  \ Store the updated ship line heap pointer in U

 CPY T1                 \ If Y >= T1 then we have reached the maximum number of
 BCS LL81               \ edge lines that we can store in the ship line heap, so
                        \ skip to LL81 so we don't loop back for the next edge

.LL78

 INC XX17               \ Increment the edge counter to point to the next edge

 LDY XX17               \ If Y >= XX20, which contains the number of edges in
 CPY XX20               \ the blueprint, jump to LL81 as we have processed all
 BCS LL81               \ the edges and don't need to loop back for the next one

 LDY #0                 \ Set Y to point to byte #0 again, ready for the next
                        \ edge

 LDA V                  \ Increment V by 4 so V(1 0) points to the data for the
 ADC #4                 \ next edge
 STA V

 BCC ll81               \ If the above addition didn't overflow, jump to ll81

 INC V+1                \ Otherwise increment the high byte of V(1 0), as we
                        \ just moved the V(1 0) pointer past a page boundary

.ll81

 JMP LL75               \ Loop back to LL75 to process the next edge

.LL81

                        \ We have finished adding lines to the ship line heap,
                        \ so now we need to set the first byte of the heap to
                        \ the number of bytes stored there

 LDA U                  \ Fetch the ship line heap pointer from U into A, which
                        \ points to the end of the heap, and therefore contains
                        \ the heap size

 LDY #0                 \ Store A as the first byte of the ship line heap, so
 STA (XX19),Y           \ the heap is now correctly set up

\ ******************************************************************************
\
\       Name: LL9 (Part 12 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Draw all the visible edges from the ship line heap
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part draws the lines in the ship line heap, which is used both to draw
\ the ship, and to remove it from the screen.
\
\ ******************************************************************************

.LL155

 LDY #0                 \ Fetch the first byte from the ship line heap into A,
 LDA (XX19),Y           \ which contains the number of bytes in the heap

 STA XX20               \ Store the heap size in XX20

 CMP #4                 \ If the heap size is less than 4, there is nothing to
 BCC LL118-1            \ draw, so return from the subroutine (as LL118-1
                        \ contains an RTS)

 INY                    \ Set Y = 1, which we will use as an index into the ship
                        \ line heap, starting at byte #1 (as byte #0 contains
                        \ the heap size)

.LL27

 LDA (XX19),Y           \ Fetch the X1 line coordinate from the heap and store
 STA XX15               \ it in XX15

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the Y1 line coordinate from the heap and store
 STA XX15+1             \ it in XX15+1

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the X2 line coordinate from the heap and store
 STA XX15+2             \ it in XX15+2

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the Y2 line coordinate from the heap and store
 STA XX15+3             \ it in XX15+3

 JSR LL30               \ Draw a line from (X1, Y1) to (X2, Y2)

 INY                    \ Increment the heap pointer

 CPY XX20               \ If the heap counter is less than the size of the heap,
 BCC LL27               \ loop back to LL27 to draw the next line from the heap

\.LL82                  \ This label is commented out in the original source

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL118
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Move a point along a line until it is on-screen
\  Deep dive: Line-clipping
\
\ ------------------------------------------------------------------------------
\
\ Given a point (x1, y1), a gradient and a direction of slope, move the point
\ along the line until it is on-screen, so this effectively clips the (x1, y1)
\ end of a line to be on the screen.
\
\ See the deep dive on "Line-clipping" for more details.
\
\ Arguments:
\
\   XX15(1 0)           x1 as a 16-bit coordinate (x1_hi x1_lo)
\
\   XX15(3 2)           y1 as a 16-bit coordinate (y1_hi y1_lo)
\
\   XX12+2              The line's gradient * 256 (so 1.0 = 256)
\
\   XX12+3              The direction of slope:
\
\                         * Positive (bit 7 clear) = top left to bottom right
\
\                         * Negative (bit 7 set) = top right to bottom left
\
\   T                   The type of slope:
\
\                         * 0 if it's more vertical than horizontal
\
\                         * &FF if it's more horizontal than vertical
\
\ Returns:
\
\   XX15                x1 as an 8-bit coordinate
\
\   XX15+2              y1 as an 8-bit coordinate
\
\ Other entry points:
\
\   LL118-1             Contains an RTS
\
\ ******************************************************************************

.LL118

 LDA XX15+1             \ If x1_hi is positive, jump down to LL119 to skip
 BPL LL119              \ the following

 STA S                  \ Otherwise x1_hi is negative, i.e. off the left of the
                        \ screen, so set S = x1_hi

 JSR LL120              \ Call LL120 to calculate:
                        \
                        \   (Y X) = (S x1_lo) * XX12+2      if T = 0
                        \         = x1 * gradient
                        \
                        \   (Y X) = (S x1_lo) / XX12+2      if T <> 0
                        \         = x1 / gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set y1 = y1 + (Y X)
 CLC                    \
 ADC XX15+2             \ starting with the low bytes
 STA XX15+2

 TYA                    \ And then adding the high bytes
 ADC XX15+3
 STA XX15+3

 LDA #0                 \ Set x1 = 0
 STA XX15
 STA XX15+1

 TAX                    \ Set X = 0 so the next instruction becomes a JMP

.LL119

 BEQ LL134              \ If x1_hi = 0 then jump down to LL134 to skip the
                        \ following, as the x-coordinate is already on-screen
                        \ (as 0 <= (x_hi x_lo) <= 255)

 STA S                  \ Otherwise x1_hi is positive, i.e. x1 >= 256 and off
 DEC S                  \ the right side of the screen, so set S = x1_hi - 1

 JSR LL120              \ Call LL120 to calculate:
                        \
                        \   (Y X) = (S x1_lo) * XX12+2      if T = 0
                        \         = (x1 - 256) * gradient
                        \
                        \   (Y X) = (S x1_lo) / XX12+2      if T <> 0
                        \         = (x1 - 256) / gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set y1 = y1 + (Y X)
 CLC                    \
 ADC XX15+2             \ starting with the low bytes
 STA XX15+2

 TYA                    \ And then adding the high bytes
 ADC XX15+3
 STA XX15+3

 LDX #255               \ Set x1 = 255
 STX XX15
 INX
 STX XX15+1

.LL134

                        \ We have moved the point so the x-coordinate is on
                        \ screen (i.e. in the range 0-255), so now for the
                        \ y-coordinate

 LDA XX15+3             \ If y1_hi is positive, jump down to LL119 to skip
 BPL LL135              \ the following

 STA S                  \ Otherwise y1_hi is negative, i.e. off the top of the
                        \ screen, so set S = y1_hi

 LDA XX15+2             \ Set R = y1_lo
 STA R

 JSR LL123              \ Call LL123 to calculate:
                        \
                        \   (Y X) = (S R) / XX12+2      if T = 0
                        \         = y1 / gradient
                        \
                        \   (Y X) = (S R) * XX12+2      if T <> 0
                        \         = y1 * gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set x1 = x1 + (Y X)
 CLC                    \
 ADC XX15               \ starting with the low bytes
 STA XX15

 TYA                    \ And then adding the high bytes
 ADC XX15+1
 STA XX15+1

 LDA #0                 \ Set y1 = 0
 STA XX15+2
 STA XX15+3

.LL135

\BNE LL139              \ This instruction is commented out in the original
                        \ source

 LDA XX15+2             \ Set (S R) = (y1_hi y1_lo) - 192
 SEC                    \
 SBC #Y*2               \ starting with the low bytes
 STA R

 LDA XX15+3             \ And then subtracting the high bytes
 SBC #0
 STA S

 BCC LL136              \ If the subtraction underflowed, i.e. if y1 < 192, then
                        \ y1 is already on-screen, so jump to LL136 to return
                        \ from the subroutine, as we are done

.LL139

                        \ If we get here then y1 >= 192, i.e. off the bottom of
                        \ the screen

 JSR LL123              \ Call LL123 to calculate:
                        \
                        \   (Y X) = (S R) / XX12+2      if T = 0
                        \         = (y1 - 192) / gradient
                        \
                        \   (Y X) = (S R) * XX12+2      if T <> 0
                        \         = (y1 - 192) * gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set x1 = x1 + (Y X)
 CLC                    \
 ADC XX15               \ starting with the low bytes
 STA XX15

 TYA                    \ And then adding the high bytes
 ADC XX15+1
 STA XX15+1

 LDA #Y*2-1             \ Set y1 = 2 * #Y - 1. The constant #Y is 96, the
 STA XX15+2             \ y-coordinate of the mid-point of the space view, so
 LDA #0                 \ this sets Y2 to 191, the y-coordinate of the bottom
 STA XX15+3             \ pixel row of the space view

.LL136

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL120
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (Y X) = (S x1_lo) * XX12+2 or (S x1_lo) / XX12+2
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   * If T = 0  (more vertical than horizontal), (Y X) = (S x1_lo) * XX12+2
\
\   * If T <> 0 (more horizontal than vertical), (Y X) = (S x1_lo) / XX12+2
\
\ giving (Y X) the opposite sign to the slope direction in XX12+3.
\
\ Other entry points:
\
\   LL122               Calculate (Y X) = (S R) * Q and set the sign to the
\                       opposite of the top byte on the stack
\
\ ******************************************************************************

.LL120

 LDA XX15               \ Set R = x1_lo
 STA R

\.LL120                 \ This label is commented out in the original source

 JSR LL129              \ Call LL129 to do the following:
                        \
                        \   Q = XX12+2
                        \     = line gradient
                        \
                        \   A = S EOR XX12+3
                        \     = S EOR slope direction
                        \
                        \   (S R) = |S R|
                        \
                        \ So A contains the sign of S * slope direction

 PHA                    \ Store A on the stack so we can use it later

 LDX T                  \ If T is non-zero, so it's more horizontal than
 BNE LL121              \ vertical, jump down to LL121 to calculate this
                        \ instead:
                        \
                        \   (Y X) = (S R) / Q

.LL122

                        \ The following calculates:
                        \
                        \   (Y X) = (S R) * Q
                        \
                        \ using the same shift-and-add algorithm that's
                        \ documented in MULT1

 LDA #0                 \ Set A = 0

 TAX                    \ Set (Y X) = 0 so we can start building the answer here
 TAY

 LSR S                  \ Shift (S R) to the right, so we extract bit 0 of (S R)
 ROR R                  \ into the C flag

 ASL Q                  \ Shift Q to the left, catching bit 7 in the C flag

 BCC LL126              \ If C (i.e. the next bit from Q) is clear, do not do
                        \ the addition for this bit of Q, and instead skip to
                        \ LL126 to just do the shifts

.LL125

 TXA                    \ Set (Y X) = (Y X) + (S R)
 CLC                    \
 ADC R                  \ starting with the low bytes
 TAX

 TYA                    \ And then doing the high bytes
 ADC S
 TAY

.LL126

 LSR S                  \ Shift (S R) to the right
 ROR R

 ASL Q                  \ Shift Q to the left, catching bit 7 in the C flag

 BCS LL125              \ If C (i.e. the next bit from Q) is set, loop back to
                        \ LL125 to do the addition for this bit of Q

 BNE LL126              \ If Q has not yet run out of set bits, loop back to
                        \ LL126 to do the "shift" part of shift-and-add until
                        \ we have done additions for all the set bits in Q, to
                        \ give us our multiplication result

 PLA                    \ Restore A, which we calculated above, from the stack

 BPL LL133              \ If A is positive jump to LL133 to negate (Y X) and
                        \ return from the subroutine using a tail call

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL123
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (Y X) = (S R) / XX12+2 or (S R) * XX12+2
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   * If T = 0,  calculate (Y X) = (S R) / XX12+2
\
\   * If T <> 0, calculate (Y X) = (S R) * XX12+2
\
\ giving (Y X) the opposite sign to the slope direction in XX12+3.
\
\ Arguments:
\
\   XX12+2              The line's gradient * 256 (so 1.0 = 256)
\
\   XX12+3              The direction of slope:
\
\                         * Bit 7 clear means top left to bottom right
\
\                         * Bit 7 set means top right to bottom left
\
\ Other entry points:
\
\   LL121               Calculate (Y X) = (S R) / Q and set the sign to the
\                       opposite of the top byte on the stack
\
\   LL133               Negate (Y X) and return from the subroutine
\
\   LL128               Contains an RTS
\
\ ******************************************************************************

.LL123

 JSR LL129              \ Call LL129 to do the following:
                        \
                        \   Q = XX12+2
                        \     = line gradient
                        \
                        \   A = S EOR XX12+3
                        \     = S EOR slope direction
                        \
                        \   (S R) = |S R|
                        \
                        \ So A contains the sign of S * slope direction

 PHA                    \ Store A on the stack so we can use it later

 LDX T                  \ If T is non-zero, so it's more horizontal than
 BNE LL122              \ vertical, jump up to LL122 to calculate this instead:
                        \
                        \   (Y X) = (S R) * Q

.LL121

                        \ The following calculates:
                        \
                        \   (Y X) = (S R) / Q
                        \
                        \ using the same shift-and-subtract algorithm that's
                        \ documented in TIS2

 LDA #%11111111         \ Set Y = %11111111
 TAY

 ASL A                  \ Set X = %11111110
 TAX

                        \ This sets (Y X) = %1111111111111110, so we can rotate
                        \ through 15 loop iterations, getting a 1 each time, and
                        \ then getting a 0 on the 16th iteration... and we can
                        \ also use it to catch our result bits into bit 0 each
                        \ time

.LL130

 ASL R                  \ Shift (S R) to the left
 ROL S

 LDA S                  \ Set A = S

 BCS LL131              \ If bit 7 of S was set, then jump straight to the
                        \ subtraction

 CMP Q                  \ If A < Q (i.e. S < Q), skip the following subtractions
 BCC LL132

.LL131

 SBC Q                  \ A >= Q (i.e. S >= Q) so set:
 STA S                  \
                        \   S = (A R) - Q
                        \     = (S R) - Q
                        \
                        \ starting with the low bytes (we know the C flag is
                        \ set so the subtraction will be correct)

 LDA R                  \ And then doing the high bytes
 SBC #0
 STA R

 SEC                    \ Set the C flag to rotate into the result in (Y X)

.LL132

 TXA                    \ Rotate the counter in (Y X) to the left, and catch the
 ROL A                  \ result bit into bit 0 (which will be a 0 if we didn't
 TAX                    \ do the subtraction, or 1 if we did)
 TYA
 ROL A
 TAY

 BCS LL130              \ If we still have set bits in (Y X), loop back to LL130
                        \ to do the next iteration of 15, until we have done the
                        \ whole division

 PLA                    \ Restore A, which we calculated above, from the stack

 BMI LL128              \ If A is negative jump to LL128 to return from the
                        \ subroutine with (Y X) as is

.LL133

 TXA                    \ Otherwise negate (Y X) using two's complement by first
 EOR #%11111111         \ setting the low byte to ~X + 1
\CLC                    \
 ADC #1                 \ The CLC instruction is commented out in the original
 TAX                    \ source. It would have no effect as we know the C flag
                        \ is clear from when we passed through the BCS above

 TYA                    \ Then set the high byte to ~Y + C
 EOR #%11111111
 ADC #0
 TAY

.LL128

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL129
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate Q = XX12+2, A = S EOR XX12+3 and (S R) = |S R|
\
\ ------------------------------------------------------------------------------
\
\ Do the following, in this order:
\
\   Q = XX12+2
\
\   A = S EOR XX12+3
\
\   (S R) = |S R|
\
\ This sets up the variables required above to calculate (S R) / XX12+2 and give
\ the result the opposite sign to XX13+3.
\
\ ******************************************************************************

.LL129

 LDX XX12+2             \ Set Q = XX12+2
 STX Q

 LDA S                  \ If S is positive, jump to LL127
 BPL LL127

 LDA #0                 \ Otherwise set R = -R
 SEC
 SBC R
 STA R

 LDA S                  \ Push S onto the stack
 PHA

 EOR #%11111111         \ Set S = ~S + 1 + C
 ADC #0
 STA S

 PLA                    \ Pull the original, negative S from the stack into A

.LL127

 EOR XX12+3             \ Set A = original argument S EOR'd with XX12+3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL145 (Part 1 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Work out which end-points are on-screen, if any
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ------------------------------------------------------------------------------
\
\ This routine clips the line from (x1, y1) to (x2, y2) so it fits on-screen, or
\ returns an error if it can't be clipped to fit. The arguments are 16-bit
\ coordinates, and the clipped line is returned using 8-bit screen coordinates.
\
\ This part sets XX13 to reflect which of the two points are on-screen and
\ off-screen.
\
\ Arguments:
\
\   XX15(1 0)           x1 as a 16-bit coordinate (x1_hi x1_lo)
\
\   XX15(3 2)           y1 as a 16-bit coordinate (y1_hi y1_lo)
\
\   XX15(5 4)           x2 as a 16-bit coordinate (x2_hi x2_lo)
\
\   XX12(1 0)           y2 as a 16-bit coordinate (y2_hi y2_lo)
\
\ Returns:
\
\   (X1, Y1)            Screen coordinate of the start of the clipped line
\
\   (X2, Y2)            Screen coordinate of the end of the clipped line
\
\   C flag              Clear if the clipped line fits on-screen, set if it
\                       doesn't
\
\   XX13                The state of the original coordinates on-screen:
\
\                         * 0   = (x2, y2) on-screen
\
\                         * 95  = (x1, y1) on-screen,  (x2, y2) off-screen
\
\                         * 191 = (x1, y1) off-screen, (x2, y2) off-screen
\
\                       So XX13 is non-zero if the end of the line was clipped,
\                       meaning the next line sent to BLINE can't join onto the
\                       end but has to start a new segment
\
\   SWAP                The swap status of the returned coordinates:
\
\                         * &FF if we swapped the values of (x1, y1) and
\                           (x2, y2) as part of the clipping process
\
\                         * 0 if the coordinates are still in the same order
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   LL147               Don't initialise the values in SWAP or A
\
\ ******************************************************************************

.LL145

 LDA #0                 \ Set SWAP = 0
 STA SWAP

 LDA XX15+5             \ Set A = x2_hi

.LL147

 LDX #Y*2-1             \ Set Y2 = #Y * 2 - 1. The constant #Y is 96, the
                        \ y-coordinate of the mid-point of the space view, so
                        \ this sets Y2 to 191, the y-coordinate of the bottom
                        \ pixel row of the space view

 ORA XX12+1             \ If one or both of x2_hi and y2_hi are non-zero, jump
 BNE LL107              \ to LL107 to skip the following

 CPX XX12               \ If y2_lo > the y-coordinate of the bottom of screen
 BCC LL107              \ then (x2, y2) is off the bottom of the screen, so skip
                        \ the following instruction, leaving X at 191

 LDX #0                 \ Set X = 0

.LL107

 STX XX13               \ Set XX13 = X, so we have:
                        \
                        \   * XX13 = 0 if x2_hi = y2_hi = 0, y2_lo is on-screen
                        \
                        \   * XX13 = 191 if x2_hi or y2_hi are non-zero or y2_lo
                        \            is off the bottom of the screen
                        \
                        \ In other words, XX13 is 191 if (x2, y2) is off-screen,
                        \ otherwise it is 0

 LDA XX15+1             \ If one or both of x1_hi and y1_hi are non-zero, jump
 ORA XX15+3             \ jump to LL83
 BNE LL83

 LDA #Y*2-1             \ If y1_lo > the y-coordinate of the bottom of screen
 CMP XX15+2             \ then (x1, y1) is off the bottom of the screen, so jump
 BCC LL83               \ to LL83

                        \ If we get here, (x1, y1) is on-screen

 LDA XX13               \ If XX13 is non-zero, i.e. (x2, y2) is off-screen, jump
 BNE LL108              \ to LL108 to halve it before continuing at LL83

                        \ If we get here, the high bytes are all zero, which
                        \ means the x-coordinates are < 256 and therefore fit on
                        \ screen, and neither coordinate is off the bottom of
                        \ the screen. That means both coordinates are already on
                        \ screen, so we don't need to do any clipping, all we
                        \ need to do is move the low bytes into (X1, Y1) and
                        \ X2, Y2) and return

.LL146

                        \ If we get here then we have clipped our line to the
                        \ (if we had to clip it at all), so we move the low
                        \ bytes from (x1, y1) and (x2, y2) into (X1, Y1) and
                        \ (X2, Y2), remembering that they share locations with
                        \ XX15:
                        \
                        \   X1 = XX15
                        \   Y1 = XX15+1
                        \   X2 = XX15+2
                        \   Y2 = XX15+3
                        \
                        \ X1 already contains x1_lo, so now we do the rest

 LDA XX15+2             \ Set Y1 (aka XX15+1) = y1_lo
 STA XX15+1

 LDA XX15+4             \ Set X2 (aka XX15+2) = x2_lo
 STA XX15+2

 LDA XX12               \ Set Y2 (aka XX15+3) = y2_lo
 STA XX15+3

 CLC                    \ Clear the C flag as the clipped line fits on-screen

 RTS                    \ Return from the subroutine

.LL109

 SEC                    \ Set the C flag to indicate the clipped line does not
                        \ fit on-screen

 RTS                    \ Return from the subroutine

.LL108

 LSR XX13               \ If we get here then (x2, y2) is off-screen and XX13 is
                        \ 191, so shift XX13 right to halve it to 95

\ ******************************************************************************
\
\       Name: LL145 (Part 2 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Work out if any part of the line is on-screen
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ------------------------------------------------------------------------------
\
\ This part does a number of tests to see if the line is on or off the screen.
\
\ If we get here then at least one of (x1, y1) and (x2, y2) is off-screen, with
\ XX13 set as follows:
\
\   * 0   = (x1, y1) off-screen, (x2, y2) on-screen
\
\   * 95  = (x1, y1) on-screen,  (x2, y2) off-screen
\
\   * 191 = (x1, y1) off-screen, (x2, y2) off-screen
\
\ where "off-screen" is defined as having a non-zero high byte in one of the
\ coordinates, or in the case of y-coordinates, having a low byte > 191, the
\ y-coordinate of the bottom of the space view.
\
\ ******************************************************************************

.LL83

 LDA XX13               \ If XX13 < 128 then only one of the points is on-screen
 BPL LL115              \ so jump down to LL115 to skip the checks of whether
                        \ both points are in the strips to the right or bottom
                        \ of the screen

                        \ If we get here, both points are off-screen

 LDA XX15+1             \ If both x1_hi and x2_hi have bit 7 set, jump to LL109
 AND XX15+5             \ to return from the subroutine with the C flag set, as
 BMI LL109              \ the entire line is above the top of the screen

 LDA XX15+3             \ If both y1_hi and y2_hi have bit 7 set, jump to LL109
 AND XX12+1             \ to return from the subroutine with the C flag set, as
 BMI LL109              \ the entire line is to the left of the screen

 LDX XX15+1             \ Set A = X = x1_hi - 1
 DEX
 TXA

 LDX XX15+5             \ Set XX12+2 = x2_hi - 1
 DEX
 STX XX12+2

 ORA XX12+2             \ If neither (x1_hi - 1) or (x2_hi - 1) have bit 7 set,
 BPL LL109              \ jump to LL109 to return from the subroutine with the C
                        \ flag set, as the line doesn't fit on-screen

 LDA XX15+2             \ If y1_lo < y-coordinate of screen bottom, clear the C
 CMP #Y*2               \ flag, otherwise set it

 LDA XX15+3             \ Set XX12+2 = y1_hi - (1 - C), so:
 SBC #0                 \
 STA XX12+2             \  * Set XX12+2 = y1_hi - 1 if y1_lo is on-screen
                        \  * Set XX12+2 = y1_hi     otherwise
                        \
                        \ We do this subtraction because we are only interested
                        \ in trying to move the points up by a screen if that
                        \ might move the point into the space view portion of
                        \ the screen, i.e. if y1_lo is on-screen

 LDA XX12               \ If y2_lo < y-coordinate of screen bottom, clear the C
 CMP #Y*2               \ flag, otherwise set it

 LDA XX12+1             \ Set XX12+2 = y2_hi - (1 - C), so:
 SBC #0                 \
                        \  * Set XX12+1 = y2_hi - 1 if y2_lo is on-screen
                        \  * Set XX12+1 = y2_hi     otherwise
                        \
                        \ We do this subtraction because we are only interested
                        \ in trying to move the points up by a screen if that
                        \ might move the point into the space view portion of
                        \ the screen, i.e. if y1_lo is on-screen

 ORA XX12+2             \ If neither XX12+1 or XX12+2 have bit 7 set, jump to
 BPL LL109              \ LL109 to return from the subroutine with the C flag
                        \ set, as the line doesn't fit on-screen

\ ******************************************************************************
\
\       Name: LL145 (Part 3 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Calculate the line's gradient
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ******************************************************************************

.LL115

 TYA                    \ Store Y on the stack so we can preserve it through the
 PHA                    \ call to this subroutine

 LDA XX15+4             \ Set XX12+2 = x2_lo - x1_lo
 SEC
 SBC XX15
 STA XX12+2

 LDA XX15+5             \ Set XX12+3 = x2_hi - x1_hi
 SBC XX15+1
 STA XX12+3

 LDA XX12               \ Set XX12+4 = y2_lo - y1_lo
 SEC
 SBC XX15+2
 STA XX12+4

 LDA XX12+1             \ Set XX12+5 = y2_hi - y1_hi
 SBC XX15+3
 STA XX12+5

                        \ So we now have:
                        \
                        \   delta_x in XX12(3 2)
                        \   delta_y in XX12(5 4)
                        \
                        \ where the delta is (x1, y1) - (x2, y2))

 EOR XX12+3             \ Set S = the sign of delta_x * the sign of delta_y, so
 STA S                  \ if bit 7 of S is set, the deltas have different signs

 LDA XX12+5             \ If delta_y_hi is positive, jump down to LL110 to skip
 BPL LL110              \ the following

 LDA #0                 \ Otherwise flip the sign of delta_y to make it
 SEC                    \ positive, starting with the low bytes
 SBC XX12+4
 STA XX12+4

 LDA #0                 \ And then doing the high bytes, so now:
 SBC XX12+5             \
 STA XX12+5             \   XX12(5 4) = |delta_y|

.LL110

 LDA XX12+3             \ If delta_x_hi is positive, jump down to LL111 to skip
 BPL LL111              \ the following

 SEC                    \ Otherwise flip the sign of delta_x to make it
 LDA #0                 \ positive, starting with the low bytes
 SBC XX12+2
 STA XX12+2

 LDA #0                 \ And then doing the high bytes, so now:
 SBC XX12+3             \
                        \   (A XX12+2) = |delta_x|

.LL111

                        \ We now keep halving |delta_x| and |delta_y| until
                        \ both of them have zero in their high bytes

 TAX                    \ IF |delta_x_hi| is non-zero, skip the following
 BNE LL112

 LDX XX12+5             \ If |delta_y_hi| = 0, jump down to LL113 (as both
 BEQ LL113              \ |delta_x_hi| and |delta_y_hi| are 0)

.LL112

 LSR A                  \ Halve the value of delta_x in (A XX12+2)
 ROR XX12+2

 LSR XX12+5             \ Halve the value of delta_y XX12(5 4)
 ROR XX12+4

 JMP LL111              \ Loop back to LL111

.LL113

                        \ By now, the high bytes of both |delta_x| and |delta_y|
                        \ are zero

 STX T                  \ We know that X = 0 as that's what we tested with a BEQ
                        \ above, so this sets T = 0

 LDA XX12+2             \ If delta_x_lo < delta_y_lo, so our line is more
 CMP XX12+4             \ vertical than horizontal, jump to LL114
 BCC LL114

 STA Q                  \ Set Q = delta_x_lo

 LDA XX12+4             \ Set A = delta_y_lo

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * delta_y_lo / delta_x_lo

 JMP LL116              \ Jump to LL116, as we now have the line's gradient in R

.LL114

 LDA XX12+4             \ Set Q = delta_y_lo
 STA Q
 LDA XX12+2             \ Set A = delta_x_lo

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * delta_x_lo / delta_y_lo

 DEC T                  \ T was set to 0 above, so this sets T = &FF

\ ******************************************************************************
\
\       Name: LL145 (Part 4 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Call the routine in LL188 to do the actual clipping
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ------------------------------------------------------------------------------
\
\ This part sets things up to call the routine in LL188, which does the actual
\ clipping.
\
\ If we get here, then R has been set to the gradient of the line (x1, y1) to
\ (x2, y2), with T indicating the type of slope:
\
\   * 0   = it's more vertical than horizontal
\
\   * &FF = it's more horizontal than vertical
\
\ and XX13 has been set as follows:
\
\   * 0   = (x1, y1) off-screen, (x2, y2) on-screen
\
\   * 95  = (x1, y1) on-screen,  (x2, y2) off-screen
\
\   * 191 = (x1, y1) off-screen, (x2, y2) off-screen
\
\ ******************************************************************************

.LL116

 LDA R                  \ Store the gradient in XX12+2
 STA XX12+2

 LDA S                  \ Store the type of slope in XX12+3, bit 7 clear means
 STA XX12+3             \ top left to bottom right, bit 7 set means top right to
                        \ bottom left

 LDA XX13               \ If XX13 = 0, skip the following instruction
 BEQ LL138

 BPL LLX117             \ If XX13 is positive, it must be 95. This means
                        \ (x1, y1) is on-screen but (x2, y2) isn't, so we jump
                        \ to LLX117 to swap the (x1, y1) and (x2, y2)
                        \ coordinates around before doing the actual clipping,
                        \ because we need to clip (x2, y2) but the clipping
                        \ routine at LL118 only clips (x1, y1)

.LL138

                        \ If we get here, XX13 = 0 or 191, so (x1, y1) is
                        \ off-screen and needs clipping

 JSR LL118              \ Call LL118 to move (x1, y1) along the line onto the
                        \ screen, i.e. clip the line at the (x1, y1) end

 LDA XX13               \ If XX13 = 0, i.e. (x2, y2) is on-screen, jump down to
 BPL LL124              \ LL124 to return with a successfully clipped line

.LL117

                        \ If we get here, XX13 = 191 (both coordinates are
                        \ off-screen)

 LDA XX15+1             \ If either of x1_hi or y1_hi are non-zero, jump to
 ORA XX15+3             \ LL137 to return from the subroutine with the C flag
 BNE LL137              \ set, as the line doesn't fit on-screen

 LDA XX15+2             \ If y1_lo > y-coordinate of the bottom of the screen
 CMP #Y*2               \ jump to LL137 to return from the subroutine with the
 BCS LL137              \ C flag set, as the line doesn't fit on-screen

.LLX117

                        \ If we get here, XX13 = 95 or 191, and in both cases
                        \ (x2, y2) is off-screen, so we now need to swap the
                        \ (x1, y1) and (x2, y2) coordinates around before doing
                        \ the actual clipping, because we need to clip (x2, y2)
                        \ but the clipping routine at LL118 only clips (x1, y1)

 LDX XX15               \ Swap x1_lo = x2_lo
 LDA XX15+4
 STA XX15
 STX XX15+4

 LDA XX15+5             \ Swap x2_lo = x1_lo
 LDX XX15+1
 STX XX15+5
 STA XX15+1

 LDX XX15+2             \ Swap y1_lo = y2_lo
 LDA XX12
 STA XX15+2
 STX XX12

 LDA XX12+1             \ Swap y2_lo = y1_lo
 LDX XX15+3
 STX XX12+1
 STA XX15+3

 JSR LL118              \ Call LL118 to move (x1, y1) along the line onto the
                        \ screen, i.e. clip the line at the (x1, y1) end

 DEC SWAP               \ Set SWAP = &FF to indicate that we just clipped the
                        \ line at the (x2, y2) end by swapping the coordinates
                        \ (the DEC does this as we set SWAP to 0 at the start of
                        \ this subroutine)

.LL124

 PLA                    \ Restore Y from the stack so it gets preserved through
 TAY                    \ the call to this subroutine

 JMP LL146              \ Jump up to LL146 to move the low bytes of (x1, y1) and
                        \ (x2, y2) into (X1, Y1) and (X2, Y2), and return from
                        \ the subroutine with a successfully clipped line

.LL137

 PLA                    \ Restore Y from the stack so it gets preserved through
 TAY                    \ the call to this subroutine

 SEC                    \ Set the C flag to indicate the clipped line does not
                        \ fit on-screen

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save ELTG.bin
\
\ ******************************************************************************

PRINT "ELITE G"
PRINT "Assembled at ", ~CODE_G%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_G%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_G%

PRINT "S.ELTG ", ~CODE_G%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_G%
SAVE "3-assembled-output/ELTG.bin", CODE_G%, P%, LOAD%

\ ******************************************************************************
\
\       Name: checksum0
\       Type: Variable
\   Category: Copy protection
\    Summary: Checksum for the entire main game code
\
\ ------------------------------------------------------------------------------
\
\ This byte contains a checksum for the entire main game code. It is populated
\ by elite-checksum.py and is used by the encryption checks in elite-loader.asm
\ (see the CHK routine in the loader for more details).
\
\ ******************************************************************************

.checksum0

 SKIP 1                 \ This value is checked against the calculated checksum
                        \ in part 6 of the loader in elite-loader.asm

\ ******************************************************************************
\
\ ELITE SHIP BLUEPRINTS FILE
\
\ Produces the binary file SHIPS.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CODE_SHIPS% = P%
LOAD_SHIPS% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: XX21
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprints lookup table
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.XX21

 EQUW SHIP_SIDEWINDER   \         1 = Sidewinder
 EQUW SHIP_VIPER        \ COPS =  2 = Viper
 EQUW SHIP_MAMBA        \         3 = Mamba
 EQUW SHIP_PYTHON       \         4 = Python
 EQUW SHIP_COBRA_MK_3   \         5 = Cobra Mk III (bounty hunter)
 EQUW SHIP_THARGOID     \ THG  =  6 = Thargoid
 EQUW SHIP_COBRA_MK_3   \ CYL  =  7 = Cobra Mk III (trader)
 EQUW SHIP_CORIOLIS     \ SST  =  8 = Coriolis space station
 EQUW SHIP_MISSILE      \ MSL  =  9 = Missile
 EQUW SHIP_ASTEROID     \ AST  = 10 = Asteroid
 EQUW SHIP_CANISTER     \ OIL  = 11 = Cargo canister
 EQUW SHIP_THARGON      \ TGL  = 12 = Thargon
 EQUW SHIP_ESCAPE_POD   \ ESC  = 13 = Escape pod

\ ******************************************************************************
\
\       Name: VERTEX
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding vertices to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   VERTEX x, y, z, face1, face2, face3, face4, visibility
\
\ See the deep dive on "Ship blueprints" for details of how vertices are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how vertices are used to draw 3D wiremesh ships.
\
\ Arguments:
\
\   x                   The vertex's x-coordinate
\
\   y                   The vertex's y-coordinate
\
\   z                   The vertex's z-coordinate
\
\   face1               The number of face 1 associated with this vertex
\
\   face2               The number of face 2 associated with this vertex
\
\   face3               The number of face 3 associated with this vertex
\
\   face4               The number of face 4 associated with this vertex
\
\   visibility          The visibility distance, beyond which the vertex is not
\                       shown
\
\ ******************************************************************************

MACRO VERTEX x, y, z, face1, face2, face3, face4, visibility

  IF x < 0
    s_x = 1 << 7
  ELSE
    s_x = 0
  ENDIF

  IF y < 0
    s_y = 1 << 6
  ELSE
    s_y = 0
  ENDIF

  IF z < 0
    s_z = 1 << 5
  ELSE
    s_z = 0
  ENDIF

  s = s_x + s_y + s_z + visibility
  f1 = face1 + (face2 << 4)
  f2 = face3 + (face4 << 4)
  ax = ABS(x)
  ay = ABS(y)
  az = ABS(z)

  EQUB ax, ay, az, s, f1, f2

ENDMACRO

\ ******************************************************************************
\
\       Name: EDGE
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding edges to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   EDGE vertex1, vertex2, face1, face2, visibility
\
\ See the deep dive on "Ship blueprints" for details of how edges are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how edges are used to draw 3D wiremesh ships.
\
\ Arguments:
\
\   vertex1             The number of the vertex at the start of the edge
\
\   vertex1             The number of the vertex at the end of the edge
\
\   face1               The number of face 1 associated with this edge
\
\   face2               The number of face 2 associated with this edge
\
\   visibility          The visibility distance, beyond which the edge is not
\                       shown
\
\ ******************************************************************************

MACRO EDGE vertex1, vertex2, face1, face2, visibility

  f = face1 + (face2 << 4)
  EQUB visibility, f, vertex1 << 2, vertex2 << 2

ENDMACRO

\ ******************************************************************************
\
\       Name: FACE
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding faces to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   FACE normal_x, normal_y, normal_z, visibility
\
\ See the deep dive on "Ship blueprints" for details of how faces are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how faces are used to draw 3D wiremesh ships.
\
\ Arguments:
\
\   normal_x            The face normal's x-coordinate
\
\   normal_y            The face normal's y-coordinate
\
\   normal_z            The face normal's z-coordinate
\
\   visibility          The visibility distance, beyond which the edge is always
\                       shown
\
\ ******************************************************************************

MACRO FACE normal_x, normal_y, normal_z, visibility

  IF normal_x < 0
    s_x = 1 << 7
  ELSE
    s_x = 0
  ENDIF

  IF normal_y < 0
    s_y = 1 << 6
  ELSE
    s_y = 0
  ENDIF

  IF normal_z < 0
    s_z = 1 << 5
  ELSE
    s_z = 0
  ENDIF

  s = s_x + s_y + s_z + visibility
  ax = ABS(normal_x)
  ay = ABS(normal_y)
  az = ABS(normal_z)

  EQUB s, ax, ay, az

ENDMACRO

\ ******************************************************************************
\
\       Name: SHIP_SIDEWINDER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Sidewinder
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_SIDEWINDER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 65 * 65           \ Targetable area          = 65 * 65
 EQUB LO(SHIP_SIDEWINDER_EDGES - SHIP_SIDEWINDER)  \ Edges data offset (low)
 EQUB LO(SHIP_SIDEWINDER_FACES - SHIP_SIDEWINDER)  \ Faces data offset (low)
 EQUB 61                \ Max. edge count          = (61 - 1) / 4 = 15
 EQUB 0                 \ Gun vertex               = 0
 EQUB 30                \ Explosion count          = 6, as (4 * n) + 6 = 30
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 15                \ Number of edges          = 15
 EQUW 50                \ Bounty                   = 50
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 20                \ Visibility distance      = 20
 EQUB 70                \ Max. energy              = 70
 EQUB 37                \ Max. speed               = 37
 EQUB HI(SHIP_SIDEWINDER_EDGES - SHIP_SIDEWINDER)  \ Edges data offset (high)
 EQUB HI(SHIP_SIDEWINDER_FACES - SHIP_SIDEWINDER)  \ Faces data offset (high)
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010000         \ Laser power              = 2
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -32,    0,   36,     0,      1,    4,     5,         31    \ Vertex 0
 VERTEX   32,    0,   36,     0,      2,    5,     6,         31    \ Vertex 1
 VERTEX   64,    0,  -28,     2,      3,    6,     6,         31    \ Vertex 2
 VERTEX  -64,    0,  -28,     1,      3,    4,     4,         31    \ Vertex 3
 VERTEX    0,   16,  -28,     0,      1,    2,     3,         31    \ Vertex 4
 VERTEX    0,  -16,  -28,     3,      4,    5,     6,         31    \ Vertex 5
 VERTEX  -12,    6,  -28,     3,      3,    3,     3,         15    \ Vertex 6
 VERTEX   12,    6,  -28,     3,      3,    3,     3,         15    \ Vertex 7
 VERTEX   12,   -6,  -28,     3,      3,    3,     3,         12    \ Vertex 8
 VERTEX  -12,   -6,  -28,     3,      3,    3,     3,         12    \ Vertex 9

.SHIP_SIDEWINDER_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,     5,         31    \ Edge 0
 EDGE       1,       2,     2,     6,         31    \ Edge 1
 EDGE       1,       4,     0,     2,         31    \ Edge 2
 EDGE       0,       4,     0,     1,         31    \ Edge 3
 EDGE       0,       3,     1,     4,         31    \ Edge 4
 EDGE       3,       4,     1,     3,         31    \ Edge 5
 EDGE       2,       4,     2,     3,         31    \ Edge 6
 EDGE       3,       5,     3,     4,         31    \ Edge 7
 EDGE       2,       5,     3,     6,         31    \ Edge 8
 EDGE       1,       5,     5,     6,         31    \ Edge 9
 EDGE       0,       5,     4,     5,         31    \ Edge 10
 EDGE       6,       7,     3,     3,         15    \ Edge 11
 EDGE       7,       8,     3,     3,         12    \ Edge 12
 EDGE       6,       9,     3,     3,         12    \ Edge 13
 EDGE       8,       9,     3,     3,         12    \ Edge 14

.SHIP_SIDEWINDER_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       32,        8,         31    \ Face 0
 FACE      -12,       47,        6,         31    \ Face 1
 FACE       12,       47,        6,         31    \ Face 2
 FACE        0,        0,     -112,         31    \ Face 3
 FACE      -12,      -47,        6,         31    \ Face 4
 FACE        0,      -32,        8,         31    \ Face 5
 FACE       12,      -47,        6,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_VIPER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Viper
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_VIPER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 75 * 75           \ Targetable area          = 75 * 75
 EQUB LO(SHIP_VIPER_EDGES - SHIP_VIPER)            \ Edges data offset (low)
 EQUB LO(SHIP_VIPER_FACES - SHIP_VIPER)            \ Faces data offset (low)
 EQUB 77                \ Max. edge count          = (77 - 1) / 4 = 19
 EQUB 0                 \ Gun vertex               = 0
 EQUB 42                \ Explosion count          = 9, as (4 * n) + 6 = 42
 EQUB 90                \ Number of vertices       = 90 / 6 = 15
 EQUB 20                \ Number of edges          = 20
 EQUW 0                 \ Bounty                   = 0
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 23                \ Visibility distance      = 23
 EQUB 120               \ Max. energy              = 120
 EQUB 32                \ Max. speed               = 32
 EQUB HI(SHIP_VIPER_EDGES - SHIP_VIPER)            \ Edges data offset (high)
 EQUB HI(SHIP_VIPER_FACES - SHIP_VIPER)            \ Faces data offset (high)
 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00010001         \ Laser power              = 2
                        \ Missiles                 = 1

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,   72,     1,      2,    3,     4,         31    \ Vertex 0
 VERTEX    0,   16,   24,     0,      1,    2,     2,         30    \ Vertex 1
 VERTEX    0,  -16,   24,     3,      4,    5,     5,         30    \ Vertex 2
 VERTEX   48,    0,  -24,     2,      4,    6,     6,         31    \ Vertex 3
 VERTEX  -48,    0,  -24,     1,      3,    6,     6,         31    \ Vertex 4
 VERTEX   24,  -16,  -24,     4,      5,    6,     6,         30    \ Vertex 5
 VERTEX  -24,  -16,  -24,     5,      3,    6,     6,         30    \ Vertex 6
 VERTEX   24,   16,  -24,     0,      2,    6,     6,         31    \ Vertex 7
 VERTEX  -24,   16,  -24,     0,      1,    6,     6,         31    \ Vertex 8
 VERTEX  -32,    0,  -24,     6,      6,    6,     6,         19    \ Vertex 9
 VERTEX   32,    0,  -24,     6,      6,    6,     6,         19    \ Vertex 10
 VERTEX    8,    8,  -24,     6,      6,    6,     6,         19    \ Vertex 11
 VERTEX   -8,    8,  -24,     6,      6,    6,     6,         19    \ Vertex 12
 VERTEX   -8,   -8,  -24,     6,      6,    6,     6,         18    \ Vertex 13
 VERTEX    8,   -8,  -24,     6,      6,    6,     6,         18    \ Vertex 14

.SHIP_VIPER_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       3,     2,     4,         31    \ Edge 0
 EDGE       0,       1,     1,     2,         30    \ Edge 1
 EDGE       0,       2,     3,     4,         30    \ Edge 2
 EDGE       0,       4,     1,     3,         31    \ Edge 3
 EDGE       1,       7,     0,     2,         30    \ Edge 4
 EDGE       1,       8,     0,     1,         30    \ Edge 5
 EDGE       2,       5,     4,     5,         30    \ Edge 6
 EDGE       2,       6,     3,     5,         30    \ Edge 7
 EDGE       7,       8,     0,     6,         31    \ Edge 8
 EDGE       5,       6,     5,     6,         30    \ Edge 9
 EDGE       4,       8,     1,     6,         31    \ Edge 10
 EDGE       4,       6,     3,     6,         30    \ Edge 11
 EDGE       3,       7,     2,     6,         31    \ Edge 12
 EDGE       3,       5,     6,     4,         30    \ Edge 13
 EDGE       9,      12,     6,     6,         19    \ Edge 14
 EDGE       9,      13,     6,     6,         18    \ Edge 15
 EDGE      10,      11,     6,     6,         19    \ Edge 16
 EDGE      10,      14,     6,     6,         18    \ Edge 17
 EDGE      11,      14,     6,     6,         16    \ Edge 18
 EDGE      12,      13,     6,     6,         16    \ Edge 19

.SHIP_VIPER_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       32,        0,         31    \ Face 0
 FACE      -22,       33,       11,         31    \ Face 1
 FACE       22,       33,       11,         31    \ Face 2
 FACE      -22,      -33,       11,         31    \ Face 3
 FACE       22,      -33,       11,         31    \ Face 4
 FACE        0,      -32,        0,         31    \ Face 5
 FACE        0,        0,      -48,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_MAMBA
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Mamba
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_MAMBA

 EQUB 1                 \ Max. canisters on demise = 1
 EQUW 70 * 70           \ Targetable area          = 70 * 70
 EQUB LO(SHIP_MAMBA_EDGES - SHIP_MAMBA)            \ Edges data offset (low)
 EQUB LO(SHIP_MAMBA_FACES - SHIP_MAMBA)            \ Faces data offset (low)
 EQUB 93                \ Max. edge count          = (93 - 1) / 4 = 23
 EQUB 0                 \ Gun vertex               = 0
 EQUB 34                \ Explosion count          = 7, as (4 * n) + 6 = 34
 EQUB 150               \ Number of vertices       = 150 / 6 = 25
 EQUB 28                \ Number of edges          = 28
 EQUW 150               \ Bounty                   = 150
 EQUB 20                \ Number of faces          = 20 / 4 = 5
 EQUB 25                \ Visibility distance      = 25
 EQUB 90                \ Max. energy              = 90
 EQUB 30                \ Max. speed               = 30
 EQUB HI(SHIP_MAMBA_EDGES - SHIP_MAMBA)            \ Edges data offset (high)
 EQUB HI(SHIP_MAMBA_FACES - SHIP_MAMBA)            \ Faces data offset (high)
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010010         \ Laser power              = 2
                        \ Missiles                 = 2

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,   64,     0,      1,    2,     3,         31    \ Vertex 0
 VERTEX  -64,   -8,  -32,     0,      2,    4,     4,         31    \ Vertex 1
 VERTEX  -32,    8,  -32,     1,      2,    4,     4,         30    \ Vertex 2
 VERTEX   32,    8,  -32,     1,      3,    4,     4,         30    \ Vertex 3
 VERTEX   64,   -8,  -32,     0,      3,    4,     4,         31    \ Vertex 4
 VERTEX   -4,    4,   16,     1,      1,    1,     1,         14    \ Vertex 5
 VERTEX    4,    4,   16,     1,      1,    1,     1,         14    \ Vertex 6
 VERTEX    8,    3,   28,     1,      1,    1,     1,         13    \ Vertex 7
 VERTEX   -8,    3,   28,     1,      1,    1,     1,         13    \ Vertex 8
 VERTEX  -20,   -4,   16,     0,      0,    0,     0,         20    \ Vertex 9
 VERTEX   20,   -4,   16,     0,      0,    0,     0,         20    \ Vertex 10
 VERTEX  -24,   -7,  -20,     0,      0,    0,     0,         20    \ Vertex 11
 VERTEX  -16,   -7,  -20,     0,      0,    0,     0,         16    \ Vertex 12
 VERTEX   16,   -7,  -20,     0,      0,    0,     0,         16    \ Vertex 13
 VERTEX   24,   -7,  -20,     0,      0,    0,     0,         20    \ Vertex 14
 VERTEX   -8,    4,  -32,     4,      4,    4,     4,         13    \ Vertex 15
 VERTEX    8,    4,  -32,     4,      4,    4,     4,         13    \ Vertex 16
 VERTEX    8,   -4,  -32,     4,      4,    4,     4,         14    \ Vertex 17
 VERTEX   -8,   -4,  -32,     4,      4,    4,     4,         14    \ Vertex 18
 VERTEX  -32,    4,  -32,     4,      4,    4,     4,          7    \ Vertex 19
 VERTEX   32,    4,  -32,     4,      4,    4,     4,          7    \ Vertex 20
 VERTEX   36,   -4,  -32,     4,      4,    4,     4,          7    \ Vertex 21
 VERTEX  -36,   -4,  -32,     4,      4,    4,     4,          7    \ Vertex 22
 VERTEX  -38,    0,  -32,     4,      4,    4,     4,          5    \ Vertex 23
 VERTEX   38,    0,  -32,     4,      4,    4,     4,          5    \ Vertex 24

.SHIP_MAMBA_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,     2,         31    \ Edge 0
 EDGE       0,       4,     0,     3,         31    \ Edge 1
 EDGE       1,       4,     0,     4,         31    \ Edge 2
 EDGE       1,       2,     2,     4,         30    \ Edge 3
 EDGE       2,       3,     1,     4,         30    \ Edge 4
 EDGE       3,       4,     3,     4,         30    \ Edge 5
 EDGE       5,       6,     1,     1,         14    \ Edge 6
 EDGE       6,       7,     1,     1,         12    \ Edge 7
 EDGE       7,       8,     1,     1,         13    \ Edge 8
 EDGE       5,       8,     1,     1,         12    \ Edge 9
 EDGE       9,      11,     0,     0,         20    \ Edge 10
 EDGE       9,      12,     0,     0,         16    \ Edge 11
 EDGE      10,      13,     0,     0,         16    \ Edge 12
 EDGE      10,      14,     0,     0,         20    \ Edge 13
 EDGE      13,      14,     0,     0,         14    \ Edge 14
 EDGE      11,      12,     0,     0,         14    \ Edge 15
 EDGE      15,      16,     4,     4,         13    \ Edge 16
 EDGE      17,      18,     4,     4,         14    \ Edge 17
 EDGE      15,      18,     4,     4,         12    \ Edge 18
 EDGE      16,      17,     4,     4,         12    \ Edge 19
 EDGE      20,      21,     4,     4,          7    \ Edge 20
 EDGE      20,      24,     4,     4,          5    \ Edge 21
 EDGE      21,      24,     4,     4,          5    \ Edge 22
 EDGE      19,      22,     4,     4,          7    \ Edge 23
 EDGE      19,      23,     4,     4,          5    \ Edge 24
 EDGE      22,      23,     4,     4,          5    \ Edge 25
 EDGE       0,       2,     1,     2,         30    \ Edge 26
 EDGE       0,       3,     1,     3,         30    \ Edge 27

.SHIP_MAMBA_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,      -24,        2,         30    \ Face 0
 FACE        0,       24,        2,         30    \ Face 1
 FACE      -32,       64,       16,         30    \ Face 2
 FACE       32,       64,       16,         30    \ Face 3
 FACE        0,        0,     -127,         30    \ Face 4

\ ******************************************************************************
\
\       Name: SHIP_COBRA_MK_3
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Cobra Mk III
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_COBRA_MK_3

 EQUB 3                 \ Max. canisters on demise = 3
 EQUW 95 * 95           \ Targetable area          = 95 * 95
 EQUB LO(SHIP_COBRA_MK_3_EDGES - SHIP_COBRA_MK_3)  \ Edges data offset (low)
 EQUB LO(SHIP_COBRA_MK_3_FACES - SHIP_COBRA_MK_3)  \ Faces data offset (low)
 EQUB 153               \ Max. edge count          = (153 - 1) / 4 = 38
 EQUB 84                \ Gun vertex               = 84 / 4 = 21
 EQUB 42                \ Explosion count          = 9, as (4 * n) + 6 = 42
 EQUB 168               \ Number of vertices       = 168 / 6 = 28
 EQUB 38                \ Number of edges          = 38
 EQUW 0                 \ Bounty                   = 0
 EQUB 52                \ Number of faces          = 52 / 4 = 13
 EQUB 50                \ Visibility distance      = 50
 EQUB 150               \ Max. energy              = 150
 EQUB 28                \ Max. speed               = 28
 EQUB HI(SHIP_COBRA_MK_3_EDGES - SHIP_COBRA_MK_3)  \ Edges data offset (low)
 EQUB HI(SHIP_COBRA_MK_3_FACES - SHIP_COBRA_MK_3)  \ Faces data offset (low)
 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00010011         \ Laser power              = 2
                        \ Missiles                 = 3

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   32,    0,   76,    15,     15,   15,    15,         31    \ Vertex 0
 VERTEX  -32,    0,   76,    15,     15,   15,    15,         31    \ Vertex 1
 VERTEX    0,   26,   24,    15,     15,   15,    15,         31    \ Vertex 2
 VERTEX -120,   -3,   -8,     3,      7,   10,    10,         31    \ Vertex 3
 VERTEX  120,   -3,   -8,     4,      8,   12,    12,         31    \ Vertex 4
 VERTEX  -88,   16,  -40,    15,     15,   15,    15,         31    \ Vertex 5
 VERTEX   88,   16,  -40,    15,     15,   15,    15,         31    \ Vertex 6
 VERTEX  128,   -8,  -40,     8,      9,   12,    12,         31    \ Vertex 7
 VERTEX -128,   -8,  -40,     7,      9,   10,    10,         31    \ Vertex 8
 VERTEX    0,   26,  -40,     5,      6,    9,     9,         31    \ Vertex 9
 VERTEX  -32,  -24,  -40,     9,     10,   11,    11,         31    \ Vertex 10
 VERTEX   32,  -24,  -40,     9,     11,   12,    12,         31    \ Vertex 11
 VERTEX  -36,    8,  -40,     9,      9,    9,     9,         20    \ Vertex 12
 VERTEX   -8,   12,  -40,     9,      9,    9,     9,         20    \ Vertex 13
 VERTEX    8,   12,  -40,     9,      9,    9,     9,         20    \ Vertex 14
 VERTEX   36,    8,  -40,     9,      9,    9,     9,         20    \ Vertex 15
 VERTEX   36,  -12,  -40,     9,      9,    9,     9,         20    \ Vertex 16
 VERTEX    8,  -16,  -40,     9,      9,    9,     9,         20    \ Vertex 17
 VERTEX   -8,  -16,  -40,     9,      9,    9,     9,         20    \ Vertex 18
 VERTEX  -36,  -12,  -40,     9,      9,    9,     9,         20    \ Vertex 19
 VERTEX    0,    0,   76,     0,     11,   11,    11,          6    \ Vertex 20
 VERTEX    0,    0,   90,     0,     11,   11,    11,         31    \ Vertex 21
 VERTEX  -80,   -6,  -40,     9,      9,    9,     9,          8    \ Vertex 22
 VERTEX  -80,    6,  -40,     9,      9,    9,     9,          8    \ Vertex 23
 VERTEX  -88,    0,  -40,     9,      9,    9,     9,          6    \ Vertex 24
 VERTEX   80,    6,  -40,     9,      9,    9,     9,          8    \ Vertex 25
 VERTEX   88,    0,  -40,     9,      9,    9,     9,          6    \ Vertex 26
 VERTEX   80,   -6,  -40,     9,      9,    9,     9,          8    \ Vertex 27

.SHIP_COBRA_MK_3_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,    11,         31    \ Edge 0
 EDGE       0,       4,     4,    12,         31    \ Edge 1
 EDGE       1,       3,     3,    10,         31    \ Edge 2
 EDGE       3,       8,     7,    10,         31    \ Edge 3
 EDGE       4,       7,     8,    12,         31    \ Edge 4
 EDGE       6,       7,     8,     9,         31    \ Edge 5
 EDGE       6,       9,     6,     9,         31    \ Edge 6
 EDGE       5,       9,     5,     9,         31    \ Edge 7
 EDGE       5,       8,     7,     9,         31    \ Edge 8
 EDGE       2,       5,     1,     5,         31    \ Edge 9
 EDGE       2,       6,     2,     6,         31    \ Edge 10
 EDGE       3,       5,     3,     7,         31    \ Edge 11
 EDGE       4,       6,     4,     8,         31    \ Edge 12
 EDGE       1,       2,     0,     1,         31    \ Edge 13
 EDGE       0,       2,     0,     2,         31    \ Edge 14
 EDGE       8,      10,     9,    10,         31    \ Edge 15
 EDGE      10,      11,     9,    11,         31    \ Edge 16
 EDGE       7,      11,     9,    12,         31    \ Edge 17
 EDGE       1,      10,    10,    11,         31    \ Edge 18
 EDGE       0,      11,    11,    12,         31    \ Edge 19
 EDGE       1,       5,     1,     3,         29    \ Edge 20
 EDGE       0,       6,     2,     4,         29    \ Edge 21
 EDGE      20,      21,     0,    11,          6    \ Edge 22
 EDGE      12,      13,     9,     9,         20    \ Edge 23
 EDGE      18,      19,     9,     9,         20    \ Edge 24
 EDGE      14,      15,     9,     9,         20    \ Edge 25
 EDGE      16,      17,     9,     9,         20    \ Edge 26
 EDGE      15,      16,     9,     9,         19    \ Edge 27
 EDGE      14,      17,     9,     9,         17    \ Edge 28
 EDGE      13,      18,     9,     9,         19    \ Edge 29
 EDGE      12,      19,     9,     9,         19    \ Edge 30
 EDGE       2,       9,     5,     6,         30    \ Edge 31
 EDGE      22,      24,     9,     9,          6    \ Edge 32
 EDGE      23,      24,     9,     9,          6    \ Edge 33
 EDGE      22,      23,     9,     9,          8    \ Edge 34
 EDGE      25,      26,     9,     9,          6    \ Edge 35
 EDGE      26,      27,     9,     9,          6    \ Edge 36
 EDGE      25,      27,     9,     9,          8    \ Edge 37

.SHIP_COBRA_MK_3_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       62,       31,         31    \ Face 0
 FACE      -18,       55,       16,         31    \ Face 1
 FACE       18,       55,       16,         31    \ Face 2
 FACE      -16,       52,       14,         31    \ Face 3
 FACE       16,       52,       14,         31    \ Face 4
 FACE      -14,       47,        0,         31    \ Face 5
 FACE       14,       47,        0,         31    \ Face 6
 FACE      -61,      102,        0,         31    \ Face 7
 FACE       61,      102,        0,         31    \ Face 8
 FACE        0,        0,      -80,         31    \ Face 9
 FACE       -7,      -42,        9,         31    \ Face 10
 FACE        0,      -30,        6,         31    \ Face 11
 FACE        7,      -42,        9,         31    \ Face 12

\ ******************************************************************************
\
\       Name: SHIP_THARGOID
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Thargoid mothership
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_THARGOID

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 99 * 99           \ Targetable area          = 99 * 99
 EQUB LO(SHIP_THARGOID_EDGES - SHIP_THARGOID)      \ Edges data offset (low)
 EQUB LO(SHIP_THARGOID_FACES - SHIP_THARGOID)      \ Faces data offset (low)
 EQUB 101               \ Max. edge count          = (101 - 1) / 4 = 25
 EQUB 60                \ Gun vertex               = 60 / 4 = 15
 EQUB 38                \ Explosion count          = 8, as (4 * n) + 6 = 38
 EQUB 120               \ Number of vertices       = 120 / 6 = 20
 EQUB 26                \ Number of edges          = 26
 EQUW 500               \ Bounty                   = 500
 EQUB 40                \ Number of faces          = 40 / 4 = 10
 EQUB 55                \ Visibility distance      = 55
 EQUB 240               \ Max. energy              = 240
 EQUB 39                \ Max. speed               = 39
 EQUB HI(SHIP_THARGOID_EDGES - SHIP_THARGOID)      \ Edges data offset (high)
 EQUB HI(SHIP_THARGOID_FACES - SHIP_THARGOID)      \ Faces data offset (high)
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010110         \ Laser power              = 2
                        \ Missiles                 = 6

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   32,  -48,   48,     0,      4,    8,     8,         31    \ Vertex 0
 VERTEX   32,  -68,    0,     0,      1,    4,     4,         31    \ Vertex 1
 VERTEX   32,  -48,  -48,     1,      2,    4,     4,         31    \ Vertex 2
 VERTEX   32,    0,  -68,     2,      3,    4,     4,         31    \ Vertex 3
 VERTEX   32,   48,  -48,     3,      4,    5,     5,         31    \ Vertex 4
 VERTEX   32,   68,    0,     4,      5,    6,     6,         31    \ Vertex 5
 VERTEX   32,   48,   48,     4,      6,    7,     7,         31    \ Vertex 6
 VERTEX   32,    0,   68,     4,      7,    8,     8,         31    \ Vertex 7
 VERTEX  -24, -116,  116,     0,      8,    9,     9,         31    \ Vertex 8
 VERTEX  -24, -164,    0,     0,      1,    9,     9,         31    \ Vertex 9
 VERTEX  -24, -116, -116,     1,      2,    9,     9,         31    \ Vertex 10
 VERTEX  -24,    0, -164,     2,      3,    9,     9,         31    \ Vertex 11
 VERTEX  -24,  116, -116,     3,      5,    9,     9,         31    \ Vertex 12
 VERTEX  -24,  164,    0,     5,      6,    9,     9,         31    \ Vertex 13
 VERTEX  -24,  116,  116,     6,      7,    9,     9,         31    \ Vertex 14
 VERTEX  -24,    0,  164,     7,      8,    9,     9,         31    \ Vertex 15
 VERTEX  -24,   64,   80,     9,      9,    9,     9,         30    \ Vertex 16
 VERTEX  -24,   64,  -80,     9,      9,    9,     9,         30    \ Vertex 17
 VERTEX  -24,  -64,  -80,     9,      9,    9,     9,         30    \ Vertex 18
 VERTEX  -24,  -64,   80,     9,      9,    9,     9,         30    \ Vertex 19

.SHIP_THARGOID_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       7,     4,     8,         31    \ Edge 0
 EDGE       0,       1,     0,     4,         31    \ Edge 1
 EDGE       1,       2,     1,     4,         31    \ Edge 2
 EDGE       2,       3,     2,     4,         31    \ Edge 3
 EDGE       3,       4,     3,     4,         31    \ Edge 4
 EDGE       4,       5,     4,     5,         31    \ Edge 5
 EDGE       5,       6,     4,     6,         31    \ Edge 6
 EDGE       6,       7,     4,     7,         31    \ Edge 7
 EDGE       0,       8,     0,     8,         31    \ Edge 8
 EDGE       1,       9,     0,     1,         31    \ Edge 9
 EDGE       2,      10,     1,     2,         31    \ Edge 10
 EDGE       3,      11,     2,     3,         31    \ Edge 11
 EDGE       4,      12,     3,     5,         31    \ Edge 12
 EDGE       5,      13,     5,     6,         31    \ Edge 13
 EDGE       6,      14,     6,     7,         31    \ Edge 14
 EDGE       7,      15,     7,     8,         31    \ Edge 15
 EDGE       8,      15,     8,     9,         31    \ Edge 16
 EDGE       8,       9,     0,     9,         31    \ Edge 17
 EDGE       9,      10,     1,     9,         31    \ Edge 18
 EDGE      10,      11,     2,     9,         31    \ Edge 19
 EDGE      11,      12,     3,     9,         31    \ Edge 20
 EDGE      12,      13,     5,     9,         31    \ Edge 21
 EDGE      13,      14,     6,     9,         31    \ Edge 22
 EDGE      14,      15,     7,     9,         31    \ Edge 23
 EDGE      16,      17,     9,     9,         30    \ Edge 24
 EDGE      18,      19,     9,     9,         30    \ Edge 25

.SHIP_THARGOID_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE      103,      -60,       25,         31    \ Face 0
 FACE      103,      -60,      -25,         31    \ Face 1
 FACE      103,      -25,      -60,         31    \ Face 2
 FACE      103,       25,      -60,         31    \ Face 3
 FACE       64,        0,        0,         31    \ Face 4
 FACE      103,       60,      -25,         31    \ Face 5
 FACE      103,       60,       25,         31    \ Face 6
 FACE      103,       25,       60,         31    \ Face 7
 FACE      103,      -25,       60,         31    \ Face 8
 FACE      -48,        0,        0,         31    \ Face 9

\ ******************************************************************************
\
\       Name: SHIP_CORIOLIS
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Coriolis space station
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_CORIOLIS

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 160 * 160         \ Targetable area          = 160 * 160
 EQUB LO(SHIP_CORIOLIS_EDGES - SHIP_CORIOLIS)      \ Edges data offset (low)
 EQUB LO(SHIP_CORIOLIS_FACES - SHIP_CORIOLIS)      \ Faces data offset (low)
 EQUB 85                \ Max. edge count          = (85 - 1) / 4 = 21
 EQUB 0                 \ Gun vertex               = 0
 EQUB 54                \ Explosion count          = 12, as (4 * n) + 6 = 54
 EQUB 96                \ Number of vertices       = 96 / 6 = 16
 EQUB 28                \ Number of edges          = 28
 EQUW 0                 \ Bounty                   = 0
 EQUB 56                \ Number of faces          = 56 / 4 = 14
 EQUB 120               \ Visibility distance      = 120
 EQUB 240               \ Max. energy              = 240
 EQUB 0                 \ Max. speed               = 0
 EQUB HI(SHIP_CORIOLIS_EDGES - SHIP_CORIOLIS)      \ Edges data offset (high)
 EQUB HI(SHIP_CORIOLIS_FACES - SHIP_CORIOLIS)      \ Faces data offset (high)
 EQUB 0                 \ Normals are scaled by    = 2^0 = 1
 EQUB %00000110         \ Laser power              = 0
                        \ Missiles                 = 6

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  160,    0,  160,     0,      1,    2,     6,         31    \ Vertex 0
 VERTEX    0,  160,  160,     0,      2,    3,     8,         31    \ Vertex 1
 VERTEX -160,    0,  160,     0,      3,    4,     7,         31    \ Vertex 2
 VERTEX    0, -160,  160,     0,      1,    4,     5,         31    \ Vertex 3
 VERTEX  160, -160,    0,     1,      5,    6,    10,         31    \ Vertex 4
 VERTEX  160,  160,    0,     2,      6,    8,    11,         31    \ Vertex 5
 VERTEX -160,  160,    0,     3,      7,    8,    12,         31    \ Vertex 6
 VERTEX -160, -160,    0,     4,      5,    7,     9,         31    \ Vertex 7
 VERTEX  160,    0, -160,     6,     10,   11,    13,         31    \ Vertex 8
 VERTEX    0,  160, -160,     8,     11,   12,    13,         31    \ Vertex 9
 VERTEX -160,    0, -160,     7,      9,   12,    13,         31    \ Vertex 10
 VERTEX    0, -160, -160,     5,      9,   10,    13,         31    \ Vertex 11
 VERTEX   10,  -30,  160,     0,      0,    0,     0,         30    \ Vertex 12
 VERTEX   10,   30,  160,     0,      0,    0,     0,         30    \ Vertex 13
 VERTEX  -10,   30,  160,     0,      0,    0,     0,         30    \ Vertex 14
 VERTEX  -10,  -30,  160,     0,      0,    0,     0,         30    \ Vertex 15

.SHIP_CORIOLIS_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       3,     0,     1,         31    \ Edge 0
 EDGE       0,       1,     0,     2,         31    \ Edge 1
 EDGE       1,       2,     0,     3,         31    \ Edge 2
 EDGE       2,       3,     0,     4,         31    \ Edge 3
 EDGE       3,       4,     1,     5,         31    \ Edge 4
 EDGE       0,       4,     1,     6,         31    \ Edge 5
 EDGE       0,       5,     2,     6,         31    \ Edge 6
 EDGE       5,       1,     2,     8,         31    \ Edge 7
 EDGE       1,       6,     3,     8,         31    \ Edge 8
 EDGE       2,       6,     3,     7,         31    \ Edge 9
 EDGE       2,       7,     4,     7,         31    \ Edge 10
 EDGE       3,       7,     4,     5,         31    \ Edge 11
 EDGE       8,      11,    10,    13,         31    \ Edge 12
 EDGE       8,       9,    11,    13,         31    \ Edge 13
 EDGE       9,      10,    12,    13,         31    \ Edge 14
 EDGE      10,      11,     9,    13,         31    \ Edge 15
 EDGE       4,      11,     5,    10,         31    \ Edge 16
 EDGE       4,       8,     6,    10,         31    \ Edge 17
 EDGE       5,       8,     6,    11,         31    \ Edge 18
 EDGE       5,       9,     8,    11,         31    \ Edge 19
 EDGE       6,       9,     8,    12,         31    \ Edge 20
 EDGE       6,      10,     7,    12,         31    \ Edge 21
 EDGE       7,      10,     7,     9,         31    \ Edge 22
 EDGE       7,      11,     5,     9,         31    \ Edge 23
 EDGE      12,      13,     0,     0,         30    \ Edge 24
 EDGE      13,      14,     0,     0,         30    \ Edge 25
 EDGE      14,      15,     0,     0,         30    \ Edge 26
 EDGE      15,      12,     0,     0,         30    \ Edge 27

.SHIP_CORIOLIS_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,        0,      160,         31    \ Face 0
 FACE      107,     -107,      107,         31    \ Face 1
 FACE      107,      107,      107,         31    \ Face 2
 FACE     -107,      107,      107,         31    \ Face 3
 FACE     -107,     -107,      107,         31    \ Face 4
 FACE        0,     -160,        0,         31    \ Face 5
 FACE      160,        0,        0,         31    \ Face 6
 FACE     -160,        0,        0,         31    \ Face 7
 FACE        0,      160,        0,         31    \ Face 8
 FACE     -107,     -107,     -107,         31    \ Face 9
 FACE      107,     -107,     -107,         31    \ Face 10
 FACE      107,      107,     -107,         31    \ Face 11
 FACE     -107,      107,     -107,         31    \ Face 12
 FACE        0,        0,     -160,         31    \ Face 13

\ ******************************************************************************
\
\       Name: SHIP_MISSILE
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a missile
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_MISSILE

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 40 * 40           \ Targetable area          = 40 * 40
 EQUB LO(SHIP_MISSILE_EDGES - SHIP_MISSILE)        \ Edges data offset (low)
 EQUB LO(SHIP_MISSILE_FACES - SHIP_MISSILE)        \ Faces data offset (low)
 EQUB 81                \ Max. edge count          = (81 - 1) / 4 = 20
 EQUB 0                 \ Gun vertex               = 0
 EQUB 10                \ Explosion count          = 1, as (4 * n) + 6 = 10
 EQUB 102               \ Number of vertices       = 102 / 6 = 17
 EQUB 24                \ Number of edges          = 24
 EQUW 0                 \ Bounty                   = 0
 EQUB 36                \ Number of faces          = 36 / 4 = 9
 EQUB 14                \ Visibility distance      = 14
 EQUB 2                 \ Max. energy              = 2
 EQUB 44                \ Max. speed               = 44
 EQUB HI(SHIP_MISSILE_EDGES - SHIP_MISSILE)        \ Edges data offset (high)
 EQUB HI(SHIP_MISSILE_FACES - SHIP_MISSILE)        \ Faces data offset (high)
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,   68,     0,      1,    2,     3,         31    \ Vertex 0
 VERTEX    8,   -8,   36,     1,      2,    4,     5,         31    \ Vertex 1
 VERTEX    8,    8,   36,     2,      3,    4,     7,         31    \ Vertex 2
 VERTEX   -8,    8,   36,     0,      3,    6,     7,         31    \ Vertex 3
 VERTEX   -8,   -8,   36,     0,      1,    5,     6,         31    \ Vertex 4
 VERTEX    8,    8,  -44,     4,      7,    8,     8,         31    \ Vertex 5
 VERTEX    8,   -8,  -44,     4,      5,    8,     8,         31    \ Vertex 6
 VERTEX   -8,   -8,  -44,     5,      6,    8,     8,         31    \ Vertex 7
 VERTEX   -8,    8,  -44,     6,      7,    8,     8,         31    \ Vertex 8
 VERTEX   12,   12,  -44,     4,      7,    8,     8,          8    \ Vertex 9
 VERTEX   12,  -12,  -44,     4,      5,    8,     8,          8    \ Vertex 10
 VERTEX  -12,  -12,  -44,     5,      6,    8,     8,          8    \ Vertex 11
 VERTEX  -12,   12,  -44,     6,      7,    8,     8,          8    \ Vertex 12
 VERTEX   -8,    8,  -12,     6,      7,    7,     7,          8    \ Vertex 13
 VERTEX   -8,   -8,  -12,     5,      6,    6,     6,          8    \ Vertex 14
 VERTEX    8,    8,  -12,     4,      7,    7,     7,          8    \ Vertex 15
 VERTEX    8,   -8,  -12,     4,      5,    5,     5,          8    \ Vertex 16

.SHIP_MISSILE_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     1,     2,         31    \ Edge 0
 EDGE       0,       2,     2,     3,         31    \ Edge 1
 EDGE       0,       3,     0,     3,         31    \ Edge 2
 EDGE       0,       4,     0,     1,         31    \ Edge 3
 EDGE       1,       2,     4,     2,         31    \ Edge 4
 EDGE       1,       4,     1,     5,         31    \ Edge 5
 EDGE       3,       4,     0,     6,         31    \ Edge 6
 EDGE       2,       3,     3,     7,         31    \ Edge 7
 EDGE       2,       5,     4,     7,         31    \ Edge 8
 EDGE       1,       6,     4,     5,         31    \ Edge 9
 EDGE       4,       7,     5,     6,         31    \ Edge 10
 EDGE       3,       8,     6,     7,         31    \ Edge 11
 EDGE       7,       8,     6,     8,         31    \ Edge 12
 EDGE       5,       8,     7,     8,         31    \ Edge 13
 EDGE       5,       6,     4,     8,         31    \ Edge 14
 EDGE       6,       7,     5,     8,         31    \ Edge 15
 EDGE       6,      10,     5,     8,          8    \ Edge 16
 EDGE       5,       9,     7,     8,          8    \ Edge 17
 EDGE       8,      12,     7,     8,          8    \ Edge 18
 EDGE       7,      11,     5,     8,          8    \ Edge 19
 EDGE       9,      15,     4,     7,          8    \ Edge 20
 EDGE      10,      16,     4,     5,          8    \ Edge 21
 EDGE      12,      13,     6,     7,          8    \ Edge 22
 EDGE      11,      14,     5,     6,          8    \ Edge 23

.SHIP_MISSILE_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE      -64,        0,       16,         31    \ Face 0
 FACE        0,      -64,       16,         31    \ Face 1
 FACE       64,        0,       16,         31    \ Face 2
 FACE        0,       64,       16,         31    \ Face 3
 FACE       32,        0,        0,         31    \ Face 4
 FACE        0,      -32,        0,         31    \ Face 5
 FACE      -32,        0,        0,         31    \ Face 6
 FACE        0,       32,        0,         31    \ Face 7
 FACE        0,        0,     -176,         31    \ Face 8

\ ******************************************************************************
\
\       Name: SHIP_ASTEROID
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an asteroid
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ASTEROID

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 80 * 80           \ Targetable area          = 80 * 80
 EQUB LO(SHIP_ASTEROID_EDGES - SHIP_ASTEROID)      \ Edges data offset (low)
 EQUB LO(SHIP_ASTEROID_FACES - SHIP_ASTEROID)      \ Faces data offset (low)
 EQUB 65                \ Max. edge count          = (65 - 1) / 4 = 16
 EQUB 0                 \ Gun vertex               = 0
 EQUB 34                \ Explosion count          = 7, as (4 * n) + 6 = 34
 EQUB 54                \ Number of vertices       = 54 / 6 = 9
 EQUB 21                \ Number of edges          = 21
 EQUW 5                 \ Bounty                   = 5
 EQUB 56                \ Number of faces          = 56 / 4 = 14
 EQUB 50                \ Visibility distance      = 50
 EQUB 60                \ Max. energy              = 60
 EQUB 30                \ Max. speed               = 30
 EQUB HI(SHIP_ASTEROID_EDGES - SHIP_ASTEROID)      \ Edges data offset (high)
 EQUB HI(SHIP_ASTEROID_FACES - SHIP_ASTEROID)      \ Faces data offset (high)
 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,   80,    0,    15,     15,   15,    15,         31    \ Vertex 0
 VERTEX  -80,  -10,    0,    15,     15,   15,    15,         31    \ Vertex 1
 VERTEX    0,  -80,    0,    15,     15,   15,    15,         31    \ Vertex 2
 VERTEX   70,  -40,    0,    15,     15,   15,    15,         31    \ Vertex 3
 VERTEX   60,   50,    0,     5,      6,   12,    13,         31    \ Vertex 4
 VERTEX   50,    0,   60,    15,     15,   15,    15,         31    \ Vertex 5
 VERTEX  -40,    0,   70,     0,      1,    2,     3,         31    \ Vertex 6
 VERTEX    0,   30,  -75,    15,     15,   15,    15,         31    \ Vertex 7
 VERTEX    0,  -50,  -60,     8,      9,   10,    11,         31    \ Vertex 8

.SHIP_ASTEROID_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     2,     7,         31    \ Edge 0
 EDGE       0,       4,     6,    13,         31    \ Edge 1
 EDGE       3,       4,     5,    12,         31    \ Edge 2
 EDGE       2,       3,     4,    11,         31    \ Edge 3
 EDGE       1,       2,     3,    10,         31    \ Edge 4
 EDGE       1,       6,     2,     3,         31    \ Edge 5
 EDGE       2,       6,     1,     3,         31    \ Edge 6
 EDGE       2,       5,     1,     4,         31    \ Edge 7
 EDGE       5,       6,     0,     1,         31    \ Edge 8
 EDGE       0,       5,     0,     6,         31    \ Edge 9
 EDGE       3,       5,     4,     5,         31    \ Edge 10
 EDGE       0,       6,     0,     2,         31    \ Edge 11
 EDGE       4,       5,     5,     6,         31    \ Edge 12
 EDGE       1,       8,     8,    10,         31    \ Edge 13
 EDGE       1,       7,     7,     8,         31    \ Edge 14
 EDGE       0,       7,     7,    13,         31    \ Edge 15
 EDGE       4,       7,    12,    13,         31    \ Edge 16
 EDGE       3,       7,     9,    12,         31    \ Edge 17
 EDGE       3,       8,     9,    11,         31    \ Edge 18
 EDGE       2,       8,    10,    11,         31    \ Edge 19
 EDGE       7,       8,     8,     9,         31    \ Edge 20

.SHIP_ASTEROID_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE        9,       66,       81,         31    \ Face 0
 FACE        9,      -66,       81,         31    \ Face 1
 FACE      -72,       64,       31,         31    \ Face 2
 FACE      -64,      -73,       47,         31    \ Face 3
 FACE       45,      -79,       65,         31    \ Face 4
 FACE      135,       15,       35,         31    \ Face 5
 FACE       38,       76,       70,         31    \ Face 6
 FACE      -66,       59,      -39,         31    \ Face 7
 FACE      -67,      -15,      -80,         31    \ Face 8
 FACE       66,      -14,      -75,         31    \ Face 9
 FACE      -70,      -80,      -40,         31    \ Face 10
 FACE       58,     -102,      -51,         31    \ Face 11
 FACE       81,        9,      -67,         31    \ Face 12
 FACE       47,       94,      -63,         31    \ Face 13

\ ******************************************************************************
\
\       Name: SHIP_CANISTER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a cargo canister
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_CANISTER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 20 * 20           \ Targetable area          = 20 * 20
 EQUB LO(SHIP_CANISTER_EDGES - SHIP_CANISTER)      \ Edges data offset (low)
 EQUB LO(SHIP_CANISTER_FACES - SHIP_CANISTER)      \ Faces data offset (low)
 EQUB 49                \ Max. edge count          = (49 - 1) / 4 = 12
 EQUB 0                 \ Gun vertex               = 0
 EQUB 18                \ Explosion count          = 3, as (4 * n) + 6 = 18
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 15                \ Number of edges          = 15
 EQUW 0                 \ Bounty                   = 0
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 12                \ Visibility distance      = 12
 EQUB 17                \ Max. energy              = 17
 EQUB 15                \ Max. speed               = 15
 EQUB HI(SHIP_CANISTER_EDGES - SHIP_CANISTER)      \ Edges data offset (high)
 EQUB HI(SHIP_CANISTER_FACES - SHIP_CANISTER)      \ Faces data offset (high)
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   24,   16,    0,     0,      1,    5,     5,         31    \ Vertex 0
 VERTEX   24,    5,   15,     0,      1,    2,     2,         31    \ Vertex 1
 VERTEX   24,  -13,    9,     0,      2,    3,     3,         31    \ Vertex 2
 VERTEX   24,  -13,   -9,     0,      3,    4,     4,         31    \ Vertex 3
 VERTEX   24,    5,  -15,     0,      4,    5,     5,         31    \ Vertex 4
 VERTEX  -24,   16,    0,     1,      5,    6,     6,         31    \ Vertex 5
 VERTEX  -24,    5,   15,     1,      2,    6,     6,         31    \ Vertex 6
 VERTEX  -24,  -13,    9,     2,      3,    6,     6,         31    \ Vertex 7
 VERTEX  -24,  -13,   -9,     3,      4,    6,     6,         31    \ Vertex 8
 VERTEX  -24,    5,  -15,     4,      5,    6,     6,         31    \ Vertex 9

.SHIP_CANISTER_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,     1,         31    \ Edge 0
 EDGE       1,       2,     0,     2,         31    \ Edge 1
 EDGE       2,       3,     0,     3,         31    \ Edge 2
 EDGE       3,       4,     0,     4,         31    \ Edge 3
 EDGE       0,       4,     0,     5,         31    \ Edge 4
 EDGE       0,       5,     1,     5,         31    \ Edge 5
 EDGE       1,       6,     1,     2,         31    \ Edge 6
 EDGE       2,       7,     2,     3,         31    \ Edge 7
 EDGE       3,       8,     3,     4,         31    \ Edge 8
 EDGE       4,       9,     4,     5,         31    \ Edge 9
 EDGE       5,       6,     1,     6,         31    \ Edge 10
 EDGE       6,       7,     2,     6,         31    \ Edge 11
 EDGE       7,       8,     3,     6,         31    \ Edge 12
 EDGE       8,       9,     4,     6,         31    \ Edge 13
 EDGE       9,       5,     5,     6,         31    \ Edge 14

.SHIP_CANISTER_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE       96,        0,        0,         31    \ Face 0
 FACE        0,       41,       30,         31    \ Face 1
 FACE        0,      -18,       48,         31    \ Face 2
 FACE        0,      -51,        0,         31    \ Face 3
 FACE        0,      -18,      -48,         31    \ Face 4
 FACE        0,       41,      -30,         31    \ Face 5
 FACE      -96,        0,        0,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_THARGON
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Thargon
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The ship blueprint for the Thargon reuses the edges data from the cargo
\ canister, so the edges data offset is negative.
\
\ ******************************************************************************

.SHIP_THARGON

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 40 * 40           \ Targetable area          = 40 * 40
 EQUB LO(SHIP_CANISTER_EDGES - SHIP_THARGON)       \ Edges from canister
 EQUB LO(SHIP_THARGON_FACES - SHIP_THARGON)        \ Faces data offset (low)
 EQUB 65                \ Max. edge count          = (65 - 1) / 4 = 16
 EQUB 0                 \ Gun vertex               = 0
 EQUB 18                \ Explosion count          = 3, as (4 * n) + 6 = 18
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 15                \ Number of edges          = 15
 EQUW 50                \ Bounty                   = 50
 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 20                \ Visibility distance      = 20
 EQUB 20                \ Max. energy              = 20
 EQUB 30                \ Max. speed               = 30
 EQUB HI(SHIP_CANISTER_EDGES - SHIP_THARGON)       \ Edges from canister
 EQUB HI(SHIP_THARGON_FACES - SHIP_THARGON)        \ Faces data offset (high)
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00010000         \ Laser power              = 2
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   -9,    0,   40,     1,      0,    5,     5,         31    \ Vertex 0
 VERTEX   -9,  -38,   12,     1,      0,    2,     2,         31    \ Vertex 1
 VERTEX   -9,  -24,  -32,     2,      0,    3,     3,         31    \ Vertex 2
 VERTEX   -9,   24,  -32,     3,      0,    4,     4,         31    \ Vertex 3
 VERTEX   -9,   38,   12,     4,      0,    5,     5,         31    \ Vertex 4
 VERTEX    9,    0,   -8,     5,      1,    6,     6,         31    \ Vertex 5
 VERTEX    9,  -10,  -15,     2,      1,    6,     6,         31    \ Vertex 6
 VERTEX    9,   -6,  -26,     3,      2,    6,     6,         31    \ Vertex 7
 VERTEX    9,    6,  -26,     4,      3,    6,     6,         31    \ Vertex 8
 VERTEX    9,   10,  -15,     5,      4,    6,     6,         31    \ Vertex 9

.SHIP_THARGON_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE      -36,        0,        0,         31    \ Face 0
 FACE       20,       -5,        7,         31    \ Face 1
 FACE       46,      -42,      -14,         31    \ Face 2
 FACE       36,        0,     -104,         31    \ Face 3
 FACE       46,       42,      -14,         31    \ Face 4
 FACE       20,        5,        7,         31    \ Face 5
 FACE       36,        0,        0,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_ESCAPE_POD
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an escape pod
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ESCAPE_POD

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 16 * 16           \ Targetable area          = 16 * 16
 EQUB LO(SHIP_ESCAPE_POD_EDGES - SHIP_ESCAPE_POD)  \ Edges data offset (low)
 EQUB LO(SHIP_ESCAPE_POD_FACES - SHIP_ESCAPE_POD)  \ Faces data offset (low)
 EQUB 25                \ Max. edge count          = (25 - 1) / 4 = 6
 EQUB 0                 \ Gun vertex               = 0
 EQUB 22                \ Explosion count          = 4, as (4 * n) + 6 = 22
 EQUB 24                \ Number of vertices       = 24 / 6 = 4
 EQUB 6                 \ Number of edges          = 6
 EQUW 0                 \ Bounty                   = 0
 EQUB 16                \ Number of faces          = 16 / 4 = 4
 EQUB 8                 \ Visibility distance      = 8
 EQUB 17                \ Max. energy              = 17
 EQUB 8                 \ Max. speed               = 8
 EQUB HI(SHIP_ESCAPE_POD_EDGES - SHIP_ESCAPE_POD)  \ Edges data offset (high)
 EQUB HI(SHIP_ESCAPE_POD_FACES - SHIP_ESCAPE_POD)  \ Faces data offset (high)
 EQUB 3                 \ Normals are scaled by    =  2^3 = 8
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   -7,    0,   36,     2,      1,    3,     3,         31    \ Vertex 0
 VERTEX   -7,  -14,  -12,     2,      0,    3,     3,         31    \ Vertex 1
 VERTEX   -7,   14,  -12,     1,      0,    3,     3,         31    \ Vertex 2
 VERTEX   21,    0,    0,     1,      0,    2,     2,         31    \ Vertex 3

.SHIP_ESCAPE_POD_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     3,     2,         31    \ Edge 0
 EDGE       1,       2,     3,     0,         31    \ Edge 1
 EDGE       2,       3,     1,     0,         31    \ Edge 2
 EDGE       3,       0,     2,     1,         31    \ Edge 3
 EDGE       0,       2,     3,     1,         31    \ Edge 4
 EDGE       3,       1,     2,     0,         31    \ Edge 5

.SHIP_ESCAPE_POD_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE       26,        0,      -61,         31    \ Face 0
 FACE       19,       51,       15,         31    \ Face 1
 FACE       19,      -51,       15,         31    \ Face 2
 FACE      -56,        0,        0,         31    \ Face 3

\ ******************************************************************************
\
\ Save SHIPS.bin
\
\ ******************************************************************************

PRINT "SHIPS"
PRINT "Assembled at ", ~CODE_SHIPS%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_SHIPS%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_SHIPS%

PRINT "S.SHIPS ", ~CODE_SHIPS%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_SHIPS%
SAVE "3-assembled-output/SHIPS.bin", CODE_SHIPS%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE PYTHON SHIP BLUEPRINT FILE
\
\ Produces the binary file PYTHON.bin that gets loaded by elite-bcfs.asm.
\
\ ******************************************************************************

CLEAR 0, &7F00

CODE_PYTHON% = &7F00
LOAD_PYTHON% = &1B00

ORG CODE_PYTHON%

\ ******************************************************************************
\
\       Name: SHIP_PYTHON
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Python
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_PYTHON

 EQUB 3                 \ Max. canisters on demise = 3
 EQUW 120 * 120         \ Targetable area          = 120 * 120
 EQUB LO(SHIP_PYTHON_EDGES - SHIP_PYTHON)          \ Edges data offset (low)
 EQUB LO(SHIP_PYTHON_FACES - SHIP_PYTHON)          \ Faces data offset (low)
 EQUB 85                \ Max. edge count          = (85 - 1) / 4 = 21
 EQUB 0                 \ Gun vertex               = 0
 EQUB 46                \ Explosion count          = 10, as (4 * n) + 6 = 46
 EQUB 66                \ Number of vertices       = 66 / 6 = 11
 EQUB 26                \ Number of edges          = 26
 EQUW 200               \ Bounty                   = 200
 EQUB 52                \ Number of faces          = 52 / 4 = 13
 EQUB 40                \ Visibility distance      = 40
 EQUB 250               \ Max. energy              = 250
 EQUB 20                \ Max. speed               = 20
 EQUB HI(SHIP_PYTHON_EDGES - SHIP_PYTHON)          \ Edges data offset (high)
 EQUB HI(SHIP_PYTHON_FACES - SHIP_PYTHON)          \ Faces data offset (high)
 EQUB 0                 \ Normals are scaled by    = 2^0 = 1
 EQUB %00011011         \ Laser power              = 3
                        \ Missiles                 = 3

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,  224,     0,      1,    2,     3,         31    \ Vertex 0
 VERTEX    0,   48,   48,     0,      1,    4,     5,         30    \ Vertex 1
 VERTEX   96,    0,  -16,    15,     15,   15,    15,         31    \ Vertex 2
 VERTEX  -96,    0,  -16,    15,     15,   15,    15,         31    \ Vertex 3
 VERTEX    0,   48,  -32,     4,      5,    8,     9,         30    \ Vertex 4
 VERTEX    0,   24, -112,     9,      8,   12,    12,         31    \ Vertex 5
 VERTEX  -48,    0, -112,     8,     11,   12,    12,         31    \ Vertex 6
 VERTEX   48,    0, -112,     9,     10,   12,    12,         31    \ Vertex 7
 VERTEX    0,  -48,   48,     2,      3,    6,     7,         30    \ Vertex 8
 VERTEX    0,  -48,  -32,     6,      7,   10,    11,         30    \ Vertex 9
 VERTEX    0,  -24, -112,    10,     11,   12,    12,         30    \ Vertex 10

.SHIP_PYTHON_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       8,     2,     3,         30    \ Edge 0
 EDGE       0,       3,     0,     2,         31    \ Edge 1
 EDGE       0,       2,     1,     3,         31    \ Edge 2
 EDGE       0,       1,     0,     1,         30    \ Edge 3
 EDGE       2,       4,     9,     5,         29    \ Edge 4
 EDGE       1,       2,     1,     5,         29    \ Edge 5
 EDGE       2,       8,     7,     3,         29    \ Edge 6
 EDGE       1,       3,     0,     4,         29    \ Edge 7
 EDGE       3,       8,     2,     6,         29    \ Edge 8
 EDGE       2,       9,     7,    10,         29    \ Edge 9
 EDGE       3,       4,     4,     8,         29    \ Edge 10
 EDGE       3,       9,     6,    11,         29    \ Edge 11
 EDGE       3,       5,     8,     8,          5    \ Edge 12
 EDGE       3,      10,    11,    11,          5    \ Edge 13
 EDGE       2,       5,     9,     9,          5    \ Edge 14
 EDGE       2,      10,    10,    10,          5    \ Edge 15
 EDGE       2,       7,     9,    10,         31    \ Edge 16
 EDGE       3,       6,     8,    11,         31    \ Edge 17
 EDGE       5,       6,     8,    12,         31    \ Edge 18
 EDGE       5,       7,     9,    12,         31    \ Edge 19
 EDGE       7,      10,    12,    10,         29    \ Edge 20
 EDGE       6,      10,    11,    12,         29    \ Edge 21
 EDGE       4,       5,     8,     9,         29    \ Edge 22
 EDGE       9,      10,    10,    11,         29    \ Edge 23
 EDGE       1,       4,     4,     5,         29    \ Edge 24
 EDGE       8,       9,     6,     7,         29    \ Edge 25

.SHIP_PYTHON_FACES

\FACE normal_x, normal_y, normal_z, visibility
 FACE      -27,       40,       11,         30    \ Face 0
 FACE       27,       40,       11,         30    \ Face 1
 FACE      -27,      -40,       11,         30    \ Face 2
 FACE       27,      -40,       11,         30    \ Face 3
 FACE      -19,       38,        0,         30    \ Face 4
 FACE       19,       38,        0,         30    \ Face 5
 FACE      -19,      -38,        0,         30    \ Face 6
 FACE       19,      -38,        0,         30    \ Face 7
 FACE      -25,       37,      -11,         30    \ Face 8
 FACE       25,       37,      -11,         30    \ Face 9
 FACE       25,      -37,      -11,         30    \ Face 10
 FACE      -25,      -37,      -11,         30    \ Face 11
 FACE        0,        0,     -112,         30    \ Face 12

 SKIP 11                \ This space appears to be unused

\ ******************************************************************************
\
\       Name: SVN
\       Type: Variable
\   Category: Save and load
\    Summary: The "saving in progress" flag
\
\ ******************************************************************************

.SVN

 SKIP 1                 \ "Saving in progress" flag
                        \
                        \   * Non-zero while we are saving a commander
                        \
                        \   * 0 otherwise

\ ******************************************************************************
\
\       Name: VEC
\       Type: Variable
\   Category: Screen mode
\    Summary: The original value of the IRQ1 vector
\
\ ******************************************************************************

.VEC

 SKIP 2                 \ VEC = &7FFE
                        \
                        \ This gets set to the value of the original IRQ1 vector
                        \ by the loading process

\ ******************************************************************************
\
\ Save PYTHON.bin
\
\ ******************************************************************************

PRINT "PYTHON"
PRINT "Assembled at ", ~CODE_PYTHON%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_PYTHON%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_PYTHON%

PRINT "S.PYTHON ", ~CODE_B%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_PYTHON%
SAVE "3-assembled-output/PYTHON.bin", CODE_PYTHON%, P%, LOAD%

\ ******************************************************************************
\
\ Show free space
\
\ ******************************************************************************

PRINT "ELITE game code ", ~(&6000-P%), " bytes free"
PRINT "Ends at ", ~P%
