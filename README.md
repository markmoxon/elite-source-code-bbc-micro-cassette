# elite-beebasm
A port of the original BBC Elite source code from BASIC assembler to BeebAsm assembler for building in modern development environments.

## Contents

- [Background](#Background)
- [Version](#Version)
- [Source files](#Source-files)
  - [elite-source.asm](#elite-source.asm)
  - [elite-ships.asm](#elite-ships.asm)
  - [elite-bcfs.asm](#elite-bcfs.asm)
  - [elite-words.asm](#elite-words.asm)
  - [elite-loader.asm](#elite-loader.asm)
  - [elite-checksum.py](#elite-checksum.py)
  - [elite-disc.asm](#elite-disc.asm)
- [Building Elite from the source](#Building-Elite-from-the-source)
  - [Requirements](#Requirements)
  - [Build targets](#Build-targets)
  - [Windows](#Windows)
  - [Mac and Linux](#Mac-and-Linux)
- [Verifying the output](#Verifying-the-output)
- [Differences between the various source files](#Differences-between-the-various-source-files)
  - [ELITEC](#ELITEC)
  - [ELTB](#ELTB)
- [Next steps](#Next-steps)

## Background
The original source files for BBC Elite can be found on [Ian Bell's personal website](http://www.iancgbell.clara.net/elite/).

The following archives are available:

- [Cassette sources](http://www.elitehomepage.org/archive/a/a4080602.zip) as DFS disk image
- [Cassette sources](http://www.elitehomepage.org/archive/a/a4080610.zip) as text files
- [BBC 2nd processor sources](http://www.elitehomepage.org/archive/a/a5022201.zip) as DFS disk image
- [Original Elite ship sources](http://www.elitehomepage.org/archive/a/a4100082.zip) as DFS disk image
- [Elite 2 ship sources](http://www.elitehomepage.org/archive/a/b80000C0.zip) as DFS disk image
- [Original BBC Disk version](http://www.elitehomepage.org/archive/a/a4100000.zip) of Elite (game only)
- [Master 128 and 2nd Processor versions](http://www.elitehomepage.org/archive/a/b8020001.zip) of Elite (game only)
- [BBC disk source (docked) annotated by Paul Brink](http://www.elitehomepage.org/archive/a/d4090010.txt) as text file
- [BBC disk source (flight) annotated by Paul Brink](http://www.elitehomepage.org/archive/a/d4090012.txt) as text file

As the game was written on 8-bit machines with very limited RAM and disk storage (the game started life on an Acorn Atom) the source code is incredibly terse, densely packed and effectively unreadable to anyone but the original authors (even then, I'd imagine both would struggle some 30+ years later..!)

This project aims to develop a readable, fast and reproducible build of Elite that can be used for learning and non-profit modification purposes.

## Version

The BBC Cassette version of the game but built for disk was chosen as the initial starting point for simplicity. It generates just two binary executable files - `ELITE` (the loader) and `ELTcode` (the game) - and will run on a standard issue Model B with DFS, which is the most common configuration of any BBC system and easily emulated.

Future versions may include BBC Disk, Master and 2nd processor configurations.

## Source files

### elite-source.asm

This is the main source for the Elite game. It is made up of 7 original BASIC source files concatenated and converted to BeebAsm assembler syntax:

- `ELITEA` outputting `ELTA` binary
- `ELITEB` outputting `ELTB` binary
- `ELITEC` outputting `ELTC` binary
- `ELITED` outputting `ELTD` binary
- `ELITEE` outputting `ELTE` binary
- `ELITEF` outputting `ELTF` binary
- `ELITEG` outputting `ELTG` binary

It totals ~10,000 lines of 6502 assembler.

### elite-ships.asm

This is the BeebAsm source for the ships and other 3D objects in Elite. It produces the `SHIPS` binary that is loaded by the `elite-bcfs.asm` source file.

### elite-bcfs.asm

This is the BeebAsm version of the BASIC source file `S.BCFS`, which is responsible for creating the Big Code File - i.e. concatenating the `ELTA`...`ELTG` binaries plus the `SHIPS` data into a single executable for the Elite main game called `ELTcode`.

There is a simple checksum test added to the start of the code. The checksum function cannot be performed in the BeebAsm source so has been reproduced in the `elite-checksum.py` Python script described below.

### elite-words.asm

This is the BeebAsm source for the Elite tokenisation system (which contains most of the game's text). It produces the `WORDS9` binary that is loaded by the `elite-loader.asm` source file.

### elite-loader.asm

This is the BeebAsm version of the BASIC source file `ELITES`, which creates the executable Elite loader `ELITE`. This is responsible for displaying the title screen and planet, drawing the initial (static) HUD, setting up interrupt routines (for the MODE 4/5 split in the HUD), relocating many routines to lower memory (below `PAGE`) and loading the main executable. It loads four image binaries from the `data` folder for the loading screen, and it also loads the `WORDS9` data file that contains the game's text.

There are a number of checksum and protection routines that XOR the code and data with other parts of memory in an attempt to obfuscate and protect the game from tampering. This cannot be done in the BeebAsm source so has been reproduced in the `elite-checksum.py` Python script below.

### elite-checksum.py

There are a number of checksum and simple XOR encryption routines that form part of the Elite build process. These are trivial to interleave with the assembly process in BBC BASIC but have had to be converted to a Python script to run as part of a modern development environment.

The script has two parts. Firstly performing some functions from the `S.BCFS` source to generate a protected version of the `ELTcode` binary:

- Concatenate all Elite game binaries
- Compute checksum for Commander data
- Poke Commander checksum value into binary
- Compute checksum for all game code except boot header
- Poke checksum value into binary
- Encrypt all game code except boot header with cycling XOR value (0-255)
- Compute final checksum for game code
- Output `ELTcode` binary (protected)

Secondly it performs the checksum and encryption functions from the `ELITES` loader source:

- Reverse the bytes for a block of code that is placed on the stack
- Compute checksum for MAINSUM
- Poke checksum value into binary
- Compute checksum for CHECKbyt
- Poke checksum value into binary
- Encrypt a block of code by XOR'ing with the code to be placed on the stack
- Encrypt all code destined for lower RAM by XOR'ing with loader boot code
- Encrypt binary data (HUD graphics etc.) by XOR'ing with loader boot code
- Output `ELITE` binary (protected)

### elite-disc.asm

This script builds the final disk image. It copies the assembled `ELITE` and `ELTcode` binary files from the `output` folder to the disk image, and is passed as an argument to BeebAsm by the `Makefile` when it creates the disk image. The BeebAsm command is configured to add a `!Boot` file that `*RUN`s the `ELITE` binary, so the result is a bootable BBC Micro disk image that runs the tape version of Elite.

The disk image is called `elite.ssd`, and you can load it into an emulator, or into a real BBC Micro using a device like a Gotek.

## Building Elite from the source

### Requirements

You will need the following to build Elite from source:

- BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). Mac and Linux users will have to build their own executable with `make code`, while Windows users can just download the `beebasm.exe` file.
- Python. Both versions 2.7 and 3.x should work.
- Mac and Linux users may need to install `make` if it isn't already present (for Windows users, `make.exe` is included in this repository).

### Build targets

There are two main build targets available. They are:

- `build` - An unencrypted version
- `encrypt` - An encrypted version that exactly matches the released version of the game

The unencrypted version should be more useful for anyone who wants to make modifications to the game code. It includes a default Commander with lots of cash and equipment, which makes it easier to test the game. As this target produces unencrypted files, the binaries produced will be quite different to the extracted binaries, which are encrypted.

The encrypted version produces the released version of Elite, along with the standard default Commander.

(Note that there is a third build target, `extract`, which is explained in the Differences section below.)

Builds are supported for both Windows and Mac/Linux systems. In all cases the build process is defined in the `Makefile` provided.

Note that the build ends with a warning that there is no `SAVE` command in the source file. You can ignore this, as the source file contains a `PUTFILE` command instead, but BeebAsm still reports this as a warning.

### Windows

For Windows users, there is a batch file called `make.bat` to which you can pass one of the three build targets above. Before this will work, you should edit the batch file and change the values of the `BEEBASM` and `PYTHON` variables to point to the locations of your `beebasm.exe` and `python.exe` executables.

All being well, doing one of the following:

```
make.bat build
```

```
make.bat encrypt
```

will produce a file called `elite.ssd`, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Mac and Linux

The build process uses a standard GNU `Makefile`, so you just need to install `make` if your system doesn't already have it. If BeebAsm or Python are not on your path, then you can either fix this, or you can edit the `Makefile` and change the `BEEBASM` and `PYTHON` variables in the first two lines to point to their locations.

All being well, doing one of the following:

```
make build
```

```
make encrypt
```

will produce a file called `elite.ssd`, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

## Verifying the output

The build process also supports a verification target that prints out checksums of all the generated files, along with the checksums of the files extracted from the original sources.

You can run this verification step on its own, or you can run it once a build has finished. To run it on its own, use the following command on Windows:

```
make.bat verify
```

or on Mac/Linux:

```
make verify
```

To run a build and then verify the results, you can add two targets, like this on Windows:

```
make.bat encrypt verify
```

or this on Mac/Linux:

```
make encrypt verify
```

The Python script `crc32.py` does the actual verification, and shows the checksums and file sizes of both sets of files, alongside each other, and with a Match column that flags any discrepancies. If you are building an unencrypted set of files then there will be lots of differences, while the encrypted files should mostly match (see the Differences section below for more on this).

The binaries in the `extracted` folder were taken straight from the [cassette sources disk image](http://www.elitehomepage.org/archive/a/a4080602.zip), while those in the `output` folder are produced by the build process. For example, if you build with `make encrypt verify`, then this is the output of the verification process:

```
[--extracted--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
a88ca82b   5426  a88ca82b   5426   Yes   ELITE.bin
0f1ad255   2228  0f1ad255   2228   Yes   ELTA.bin
0d6f4900   2600  e725760a   2600   No    ELTB.bin
97e338e8   2735  97e338e8   2735   Yes   ELTC.bin
322b174c   2882  322b174c   2882   Yes   ELTD.bin
29f7b8cb   2663  29f7b8cb   2663   Yes   ELTE.bin
8a4cecc2   2721  8a4cecc2   2721   Yes   ELTF.bin
7a6a5d1a   2340  7a6a5d1a   2340   Yes   ELTG.bin
01a00dce  20712  01a00dce  20712   Yes   ELTcode.bin
49ee043c   2502  49ee043c   2502   Yes   SHIPS.bin
c4547e5e   1023  c4547e5e   1023   Yes   WORDS9.bin
-             -  f40816ec   5426    -    ELITE.unprot.bin
-             -  1e4466ec  20712    -    ELTcode.unprot.bin
-             -  00d5bb7a     40    -    ELThead.bin
```

You can see that in this case, the `ELTB.bin` file produced by BeebAsm does not match the `ELTB` binary extracted from the source disk, but the `ELTcode.bin` files do match. This is explained below.

## Differences between the various source files

### ELITEC

It was discovered that the [cassette sources as text files](http://www.elitehomepage.org/archive/a/a4080610.zip) do not contain identical code to the binaries in the [cassette sources disk image](http://www.elitehomepage.org/archive/a/a4080602.zip). Specifically, there are three instructions in the `ELTC` binary that are missing from the `ELITEC.TXT` source file:

```
.WARP
LDA MANY+AST
CLC
ADC MANY+ESC
CLC             ; Not in ELITEC.TXT, but in ELTC source image
ADC MANY+OIL
TAX
LDA FRIN+2,X
ORA SSPR
ORA MJ
BNE WA1
LDY K%+8
BMI WA3
TAY
JSR MAS2
;LSR A
;BEQ WA1
CMP #2
BCC WA1         ; Not in ELITEC.TXT, but in ELTC source image
.WA3
LDY K%+NI%+8
BMI WA2
LDY #NI%
JSR m
;LSR A
;BEQ WA1
CMP #2
BCC WA1         ; Not in ELITEC.TXT, but in ELTC source image
```

These missing instructions have been added to the BeebAsm version so that the build process produce binaries that match the released version of the game.

### ELTB

As noted above, the `ELTB` binary output from the build process is not identical to the `ELTB` file in the [cassette sources disk image](http://www.elitehomepage.org/archive/a/a4080602.zip), yet the final `ELTcode` binary from the build process does match. What gives?

It turns out there are two versions of the `ELITEB` BASIC source program on the cassette sources disk, `$.ELITEB` and `O.ELITEB`. These two versions of `ELITEB` differ by just one byte in the default Commander data. This byte controls whether or not the Commander has a rear pulse laser. In `O.ELITEB` this byte is generated by:

```
EQUB (POW + 128) AND Q%
```

while in `$.ELITEB`, this byte is generated by:

```
EQUB POW
```

The BASIC variable `Q%` is a Boolean flag that, if `TRUE`, will create a default Commander with lots of cash and equipment, which is useful for testing. You can see this in action if you build an unencrypted binary with `make build`, as the unencrypted build sets `Q%` to `TRUE` for this build target.

The BASIC variable `POW` has a value of 15, which is the power of a pulse laser. `POW + 128`, meanwhile, is the power of a beam laser.

Given the above, we can see that `O.ELITEB` correctly produces a default Commander with no a rear laser if `Q%` is `FALSE`, but adds a rear beam laser if `Q%` is `TRUE`. This matches the released game, whose executable can be found as `ELTcode` on the same disk. The version of `ELITEB` in the [cassette sources as text files](http://www.elitehomepage.org/archive/a/a4080610.zip) matches this version, `O.ELITEB`.

In contrast, `$.ELITEB` will always produce a default Commander with a rear pulse laser, irrespective of the setting of `Q%`.

The implication is that the `ELTB` binary file on the cassette sources disk was produced by `$.ELITEB`, while the `ELTcode` file (the released game) used `O.ELITEB`. Perhaps the released game was compiled, and then someone backed up the `ELITEB` source to `O.ELITEB`, edited the `$.ELITEB` to have a rear pulse laser, and then generated a new `ELTB` binary file. Who knows? Unfortunately, files on DFS disks don't have timestamps, so it's hard to tell.

To support this discrepancy, there is an extra build target for building the `ELTB` binary as found on the sources disk, and as produced by `$.ELITEB`. You can build this version, which has the rear pulse laser, with:

  `make extract`

The `ELTcode` executable produced by this build target is different to the released version, because the default Commander has the extra rear pulse laser. You can use the verify target to confirm this. Doing `make encrypt verify` shows that all the generated files match the extracted ones except for `ELTB`, while `make extract verify` shows that the all the generated files match the extracted ones except for `ELTcode`.

## Next steps

Although the binary files output are identical, the build process is *brittle* meaning that the source cannot be altered. The main problem is that the encryption process does not have knowledge of the symbols produced by the assembler, so these values have been hard coded for temporary convenience.

_Update:_ The checksum code and encryption has been removed to allow modification of the game code in `elite-source.asm`. However, the build process will likely fail if the `elite-loader.asm` file is modified in any non-trivial way.

The next steps are:

- ~~Improve whitespacing for readability~~
- ~~Commenting of critical functions in Elite loader code~~
- ~~Remove loader code requiring checksums and copy protection to allow game source to be modified freely~~
- Commenting of critical functions in Elite game code
- Improve label names for readability
- Add BBC Disk, Master and 2nd processor versions to build

I am fully open to PR's if anyone feels like contributing to this project!

---
#### Kieran Connell | July 2018
