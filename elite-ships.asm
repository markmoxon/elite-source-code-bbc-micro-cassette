ORG &563A

L%=&5822
CODE%=P%

\ This data is at .XX21
\ It is loaded at &5822 and moved to &563A at runtime
\ The following lookup table points to the individual ship definitions

EQUW &5654                          ; Sidewinder
EQUW &56FC                          ; Viper
EQUW &57D6                          ; Mamba
EQUW &7F00                          ; Points to start of MODE 4 screen memory
EQUW &5904                          ; Cobra Mk III
EQUW &5A8C                          ; Thargoid
EQUW &5904                          ; Cobra Mk III (again)
EQUW &5BA8                          ; Coriolis
EQUW &5CC4                          ; Missile
EQUW &5DC2                          ; Asteroid
EQUW &5E98                          ; Cargo
EQUW &5F40                          ; Thargon
EQUW &5FAC                          ; Escape pod

\ Start Hull Data. For each ship, the first 20 bytes give header info:
\
\ hull byte#0       high nibble is scoop info, lower nibble is debris spin info
\ hull byte#1-2     area, &for missile lock, lo, hi
\ hull byte#3       edges data info offset lo
\ hull byte#4       faces data info offset lo
\ hull byte#5       4*maxlines+1, &for ship lines stack
\ hull byte#6       gun vertex*4
\ hull byte#7       explosion count e.g. &2A = 4*n+6
\ hull byte#8       vertices*6		
\ hull bytes#10-11  bounty lo hi
\ hull byte#12      faces*4
\ hull byte#13      dot beyond distance	
\ hull byte#14      energy
\ hull byte#15      speed (end of 4th row)
\ hull byte#16      edges offset hi (goes -ve to use other's edge net).
\ hull byte#17      faces offset hi
\ hull byte#18      Q% scaling of normals to make large objects' normals flare out further away
\ hull bute#19      laser|missile(=lower 3 bits)

\ Sidewinder

PRINT "Sidewinder=",~P%

EQUB &00
EQUB &81, &10
EQUB &50
EQUB &8C
EQUB &3D
EQUB &00                            ; gun vertex = 0
EQUB &1E
EQUB &3C                            ; vertices = &3C/6 = 10
EQUB &0F                            ; edges = &0F = 15
EQUB &32, &00
EQUB &1C                            ; faces = &1C/4 = 7
EQUB &14
EQUB &46
EQUB &25
EQUB &00
EQUB &00
EQUB &02
EQUB &10                            ; %10000, laser = 2, missiles = 0

EQUB &20, &00, &24, &9F, &10, &54   ; vertices data (10*6)
EQUB &20, &00, &24, &1F, &20, &65
EQUB &40, &00, &1C, &3F, &32, &66
EQUB &40, &00, &1C, &BF, &31, &44
EQUB &00, &10, &1C, &3F, &10, &32

EQUB &00, &10, &1C, &7F, &43, &65
EQUB &0C, &06, &1C, &AF, &33, &33
EQUB &0C, &06, &1C, &2F, &33, &33
EQUB &0C, &06, &1C, &6C, &33, &33
EQUB &0C, &06, &1C, &EC, &33, &33

EQUB &1F, &50, &00, &04             ; edges data (15*4)
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

EQUB &1F, &00, &20, &08             ; faces data (7*4)
EQUB &9F, &0C, &2F, &06
EQUB &1F, &0C, &2F, &06
EQUB &3F, &00, &00, &70
EQUB &DF, &0C, &2F, &06

EQUB &5F, &00, &20, &08
EQUB &5F, &0C, &2F, &06

\ Viper

PRINT "Viper=",~P%

EQUB &00
EQUB &F9, &15
EQUB &6E
EQUB &BE
EQUB &4D
EQUB &00                            ; gun vertex = 0
EQUB &2A
EQUB &5A                            ; vertices = &5A/6 = 15
EQUB &14                            ; edges = &14 = 20
EQUB &00, &00                       ; bounty = 0
EQUB &1C                            ; faces = &1C/4 = 7
EQUB &17
EQUB &78
EQUB &20
EQUB &00
EQUB &00
EQUB &01
EQUB &11                            ; %10001, laser = 2, missiles = 1

EQUB &00, &00, &48, &1F, &21, &43   ; vertices data (15*6)
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

EQUB &1F, &42, &00, &0C             ; edges data (20*4)
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

EQUB &1F, &00, &20, &00             ; faces data (7*4)
EQUB &9F, &16, &21, &0B
EQUB &1F, &16, &21, &0B
EQUB &DF, &16, &21, &0B
EQUB &5F, &16, &21, &0B

EQUB &5F, &00, &20, &00
EQUB &3F, &00, &00, &30

\ Mamba

PRINT "Mamba=",~P%

EQUB &01
EQUB &24, &13
EQUB &AA
EQUB &1A
EQUB &5D
EQUB &00                            ; gun vertex = 0
EQUB &22
EQUB &96                            ; vertices = &96/6 = 25
EQUB &1C                            ; edges = &1C = 28
EQUB &96, &00
EQUB &14                            ; faces = &14/4 = 5
EQUB &19
EQUB &5A
EQUB &1E
EQUB &00
EQUB &01
EQUB &02
EQUB &12                            ; %10010, laser = 2, missiles = 2

EQUB &00, &00, &40, &1F, &10, &32   ; vertices data (25*6)
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

EQUB &1F, &20, &00, &04             ; edges data (28*4)
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

EQUB &5E, &00, &18, &02             ; faces data (5*4)
EQUB &1E, &00, &18, &02
EQUB &9E, &20, &40, &10
EQUB &1E, &20, &40, &10
EQUB &3E, &00, &00, &7F

\ Cobra Mk III

PRINT "CobraMkIII=",~P%

EQUB &03                            ; scoop = 0, debris spin = 3
EQUB &41, &23                       ; area for missile lock, lo, hi
EQUB &BC                            ; edges data info offset lo
EQUB &54                            ; faces data info offset lo
EQUB &99                            ; 4*maxlines+1 for ship lines stack
EQUB &54                            ; gun vertex = &54/4 = 21 = &15
EQUB &2A                            ; explosion count, &2A = 4*n+6
EQUB &A8                            ; vertices = &A8/6 = 28
EQUB &26                            ; edges = &26 = 38
EQUB &00, &00                       ; bounty = 0
EQUB &34                            ; faces = &34/4 = 13
EQUB &32
EQUB &96
EQUB &1C
EQUB &00
EQUB &01
EQUB &01
EQUB &13                            ; %10011, laser = 2, missiles = 3

EQUB &20, &00, &4C, &1F, &FF, &FF   ; vertices data (28*6)
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

EQUB &1F, &B0, &00, &04             ; edges data (38*4)
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

EQUB &1F, &00, &3E, &1F             ; faces data (13*4)
EQUB &9F, &12, &37, &10             ; start normals #0 = top front plate of, &Cobra Mk III
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

\ Thargoid

PRINT "Thargoid=",~P%

EQUB &00
EQUB &49, &26
EQUB &8C
EQUB &F4
EQUB &65
EQUB &3C                            ; gun vertex = &3C/4 = 15 = &0F
EQUB &26
EQUB &78                            ; vertices = &78/6 = 20
EQUB &1A                            ; edges = &1A = 26
EQUB &F4, &01
EQUB &28                            ; faces = &28/4 = 10
EQUB &37
EQUB &F0
EQUB &27
EQUB &00
EQUB &00
EQUB &02
EQUB &16                            ; %10110, laser = 2, missiles = 6

EQUB &20, &30, &30, &5F, &40, &88   ; vertices data (20)
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

EQUB &1F, &84, &00, &1C             ; edges data (26*4)
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

EQUB &5F, &67, &3C, &19             ; faces data (10*4)
EQUB &7F, &67, &3C, &19
EQUB &7F, &67, &19, &3C
EQUB &3F, &67, &19, &3C
EQUB &1F, &40, &00, &00

EQUB &3F, &67, &3C, &19
EQUB &1F, &67, &3C, &19
EQUB &1F, &67, &19, &3C
EQUB &5F, &67, &19, &3C
EQUB &9F, &30, &00, &00

\ Coriolis

PRINT "Coriolis=",~P%

EQUB &00
EQUB &00, &64
EQUB &74
EQUB &E4
EQUB &55
EQUB &00                            ; gun vertex = 0
EQUB &36
EQUB &60                            ; vertices = &60/6 = 16
EQUB &1C                            ; edges = &1C = 28
EQUB &00, &00
EQUB &38                            ; faces = &38/4 = 14
EQUB &78
EQUB &F0
EQUB &00
EQUB &00
EQUB &00
EQUB &00
EQUB &06

EQUB &A0, &00, &A0, &1F, &10, &62   ; vertices data (16*6)
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

EQUB &1F, &10, &00, &0C             ; edges data (28*4)
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

EQUB &1F, &00, &00, &A0             ; faces data (14*4)
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

\ Missile

PRINT "Missile=",~P%

EQUB &00
EQUB &40, &06
EQUB &7A
EQUB &DA
EQUB &51
EQUB &00                            ; gun vertex = 0
EQUB &0A
EQUB &66                            ; vertices = &66/6 = 17
EQUB &18                            ; edges = &18 = 24
EQUB &00, &00                       ; bounty = 0
EQUB &24                            ; faces = &24/4 = 9
EQUB &0E
EQUB &02
EQUB &2C
EQUB &00
EQUB &00
EQUB &02
EQUB &00                            ; %00000, laser = 0, missiles = 0

EQUB &00, &00, &44, &1F, &10, &32   ; vertices data (17*6)
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

EQUB &1F, &21, &00, &04             ; edges data (24*4)
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

EQUB &9F, &40, &00, &10              ; faces data (9*4)
EQUB &5F, &00, &40, &10
EQUB &1F, &40, &00, &10
EQUB &1F, &00, &40, &10
EQUB &1F, &20, &00, &00

EQUB &5F, &00, &20, &00
EQUB &9F, &20, &00, &00
EQUB &1F, &00, &20, &00
EQUB &3F, &00, &00, &B0

\ Asteroid

PRINT "Asteroid=",~P%

EQUB &00
EQUB &00, &19
EQUB &4A
EQUB &9E
EQUB &41
EQUB &00                            ; gun vertex = 0
EQUB &22
EQUB &36                            ; vertices = &36/6 = 9
EQUB &15                            ; edges = &15 = 21
EQUB &05, &00
EQUB &38                            ; faces = &38/4 = 14
EQUB &32
EQUB &3C
EQUB &1E
EQUB &00
EQUB &00
EQUB &01
EQUB &00                            ; %00000, laser = 0, missiles = 0

EQUB &00, &50, &00, &1F, &FF, &FF   ; vertices data (25*9)
EQUB &50, &0A, &00, &DF, &FF, &FF
EQUB &00, &50, &00, &5F, &FF, &FF
EQUB &46, &28, &00, &5F, &FF, &FF
EQUB &3C, &32, &00, &1F, &65, &DC

EQUB &32, &00, &3C, &1F, &FF, &FF
EQUB &28, &00, &46, &9F, &10, &32
EQUB &00, &1E, &4B, &3F, &FF, &FF
EQUB &00, &32, &3C, &7F, &98, &BA

EQUB &1F, &72, &00, &04             ; edges data (21*4)
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

EQUB &1F, &09, &42, &51             ; faces data (14*4)
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

\ Cargo cannister

PRINT "Cargo=",~P%

EQUB &00
EQUB &90, &01
EQUB &50
EQUB &8C
EQUB &31
EQUB &00                            ; gun vertex = 0
EQUB &12
EQUB &3C                            ; vertices = &3C/6 = 10
EQUB &0F                            ; edges = &0F = 15
EQUB &00, &00                       ; bounty = 0
EQUB &1C                            ; faces = &1C/4 = 7
EQUB &0C
EQUB &11
EQUB &0F
EQUB &00
EQUB &00
EQUB &02
EQUB &00                            ; %00000, laser = 0, missiles = 0

EQUB &18, &10, &00, &1F, &10, &55   ; vertices data (10*6)
EQUB &18, &05, &0F, &1F, &10, &22
EQUB &18, &0D, &09, &5F, &20, &33
EQUB &18, &0D, &09, &7F, &30, &44
EQUB &18, &05, &0F, &3F, &40, &55

EQUB &18, &10, &00, &9F, &51, &66
EQUB &18, &05, &0F, &9F, &21, &66
EQUB &18, &0D, &09, &DF, &32, &66
EQUB &18, &0D, &09, &FF, &43, &66
EQUB &18, &05, &0F, &BF, &54, &66

EQUB &1F, &10, &00, &04             ; edges data (15*4)
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

EQUB &1F, &60, &00, &00             ; faces data (7*4)
EQUB &1F, &00, &29, &1E
EQUB &5F, &00, &12, &30
EQUB &5F, &00, &33, &00
EQUB &7F, &00, &12, &30

EQUB &3F, &00, &29, &1E
EQUB &9F, &60, &00, &00

\ Thargon

PRINT "Thargon=",~P%

EQUB &00
EQUB &40, &06
EQUB &A8
EQUB &50
EQUB &41
EQUB &00                            ; gun vertex = 0
EQUB &12
EQUB &3C                            ; vertices = &3C/6 = 10
EQUB &0F                            ; edges = &0F = 15
EQUB &32, &00
EQUB &1C                            ; faces = &1C/4 = 7
EQUB &14
EQUB &14
EQUB &1E
EQUB &FF
EQUB &00
EQUB &02
EQUB &10

EQUB &09, &00, &28, &9F, &01, &55   ; vertices data (10*6)
EQUB &09, &26, &0C, &DF, &01, &22
EQUB &09, &18, &20, &FF, &02, &33
EQUB &09, &18, &20, &BF, &03, &44
EQUB &09, &26, &0C, &9F, &04, &55

EQUB &09, &00, &08, &3F, &15, &66
EQUB &09, &0A, &0F, &7F, &12, &66
EQUB &09, &06, &1A, &7F, &23, &66
EQUB &09, &06, &1A, &3F, &34, &66
EQUB &09, &0A, &0F, &3F, &45, &66

EQUB &9F, &24, &00, &00             ; faces data (7*4)
EQUB &5F, &14, &05, &07
EQUB &7F, &2E, &2A, &0E
EQUB &3F, &24, &00, &68
EQUB &3F, &2E, &2A, &0E

EQUB &1F, &14, &05, &07
EQUB &1F, &24, &00, &00

\ Escape capsule

PRINT "Escape capsule=",~P%

EQUB &00
EQUB &00, &01
EQUB &2C
EQUB &44
EQUB &19
EQUB &00                            ; gun vertex = 0
EQUB &16
EQUB &18                            ; vertices = &18/6 = 4
EQUB &06                            ; edges = &06 = 6
EQUB &00, &00
EQUB &10                            ; faces = &10/4 = 4
EQUB &08
EQUB &11
EQUB &08
EQUB &00
EQUB &00
EQUB &03
EQUB &00

EQUB &07, &00, &24, &9F, &12, &33   ; vertices data (4*6)
EQUB &07, &0E, &0C, &FF, &02, &33
EQUB &07, &0E, &0C, &BF, &01, &33
EQUB &15, &00, &00, &1F, &01, &22

EQUB &1F, &23, &00, &04             ; edges data (6*4)
EQUB &1F, &03, &04, &08
EQUB &1F, &01, &08, &0C
EQUB &1F, &12, &0C, &00
EQUB &1F, &13, &00, &08

EQUB &1F, &02, &0C, &04

EQUB &3F, &1A, &00, &3D             ; faces data (4*4)
EQUB &1F, &13, &33, &0F
EQUB &5F, &13, &33, &0F
EQUB &9F, &38, &00, &00

PRINT "output/SHIPS.bin"
PRINT "ASSEMBLE AT W%=", ~CODE%
PRINT "P%=",~P%
PRINT "CODE SIZE=", ~(P%-CODE%)
PRINT "RELOAD AT H%=", ~L%

PRINT "S.SHIPS ",~CODE%," ",~P%," ",~L%," ",~L%

SAVE "output/SHIPS.bin", CODE%, P%, L%, L%
