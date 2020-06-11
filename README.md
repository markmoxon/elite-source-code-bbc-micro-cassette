# elite-beebasm
A port of the original BBC Elite source code from BASIC assembler to BeebAsm assembler for building in modern development environments.

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

## Files

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

This contains the source for the ships and other 3D objects in Elite. It produces the `SHIPS` binary that is loaded by the `elite-bcfs.asm` builder.

### elite-bcfs.asm

The BASIC source file `S.BCFS` is responsible for creating the Big Code File, i.e. concatenating the `ELTA`...`ELTG` binaries plus the `SHIPS` data into a single executable for the Elite main game called `ELTcode`.

There is a simple checksum test added to the start of the code. The checksum function cannot be performed in the BeebAsm source so has been reproduced in the `elite-checksum.py` Python script described below.

### elite-words.asm

This is the source for the Elite tokenisation system (which contains the game's text). It produces the `WORDS9` binary that is loaded by the Elite loader.

### elite-loader.asm

The BASIC source file `ELITES` creates the executable Elite loader `ELITE`. This is responsible for displaying the title screen and planet, drawing the initial (static) HUD, setting up interrupt routines (for the MODE 4/5 split in the HUD), relocating many routines to lower memory (below `PAGE`) and loading the main executable. It loads four image binaries from the `data` folder for the loading screen, and it also loads the `WORDS9` data file that contains the game's text.

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
- Comuter checksum for CHECKbyt
- Poke checksum value into binary
- Encrypt a block of code by XOR'ing with the code to be placed on the stack
- Encrypt all code destined for lower RAM by XOR'ing with loader boot code
- Encrypt binary data (HUD graphics etc.) by XOR'ing with loader boot code
- Output `ELITE` binary (protected)

## Build

There are three build targets available. They are:

- `build` - An unencrypted version, which will be different to the extracted binaries (as they are encrypted). This version should allow for more modifications to the source, though this is still a fairly brittle process.
- `encrypt` - An encrypted version that exactly matches the released version of the game.
- `extract` - An encrypted version that matches the cassette source files, which differ slightly from the released version (see the `ELTB` section below for more details).

Builds are supported for both Windows and Mac/Linux systems. In all cases the build process is defined in the `Makefile` provided.

Note that the build ends with a warning that there is no `SAVE` command in the source file. You can ignore this, as the source file contains a `PUTFILE` command instead, but BeebAsm still reports this as a warning.

### Requirements

You will need the following to build Elite from source:

- BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). Mac and Linux users will have to build their own executable, while Windows users can just download the `beebasm.exe` file.
- Python. Both versions 2.7 and 3.x should work.
- Mac and Linux users may need to install `make` if it isn't already present.

### Windows

For Windows users, there is a batch file called `make.bat` to which you can pass one of the three build targets above. Before this will work, you should edit the batch file and change the values of the `BEEBASM` and `PYTHON` variables to point to the locations of your `beebasm.exe` and `python.exe` executables.

All being well, doing one of the following:

- `make.bat build`
- `make.bat encrypt`
- `make.bat extract`

will produce a file called `elite.ssd`, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Mac and Linux

The build process uses a standard GNU `Makefile`, so you just need to install `make` if your system doesn't already have it. If BeebAsm or Python are not on your path, then you can either fix this, or you can edit the `Makefile` and change the `BEEBASM` and `PYTHON` variables in the first two lines to point to their locations.

All being well, doing one of the following:

- `make build`
- `make encrypt`
- `make extract`

will produce a file called `elite.ssd`, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

## Verify

The build process also support a verification target that prints out checksums of all the generated files, along with the checksums of the files extracted from the original sources.

You can run this verification step on its own, or you can run it once a build has finished. To run it on its own, use the following command:

- `make.bat verify` (Windows)
- `make verify` (Mac/Linux)

To run a build and then verify the results, you can add two targets, like this:

- `make.bat encrypt verify` (Windows)
- `make encrypt verify` (Mac/Linux)

The Python script `crc32.py` does the actual verification, and shows the checksums and file sizes of both sets of files, alongside each other, and with a Match column that shows any discrepancies. If you are building an unencrypted set of files then there will be lots of differences, while the encrypted files should mostly match (see the Differences section below for more on this).

The binaries in the `extracted` folder were taken straight from the [cassette sources disk image](http://www.elitehomepage.org/archive/a/a4080602.zip), while those in the `output` folder are produced by the build process. For example, if you build with `make encrypt verify`, then this is the output of the verification process:

```
[--extracted--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
a88ca82b   5426  a88ca82b   5426   Yes   ELITE.bin
0f1ad255   2228  0f1ad255   2228   Yes   ELTA.bin
0d6f4900   2600  e725760a   2600   No!   ELTB.bin
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

## Differences

### ELITEC

It was discovered that the [Text Files archive](http://www.elitehomepage.org/archive/a/a4080610.zip) does not contain an identical source to the binaries in the [Disk Image archive](http://www.elitehomepage.org/archive/a/a4080602.zip). Specifically, there are three instructions in the `ELTC` binary that are missing from the `ELITEC.TXT` source file:

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

These missing instructions have been added to the BeebAsm version so that the build process produce binaries that match the released version.

### ELTB

As noted above, the `ELTB` binary output from the build process is not identical to the extracted file from the [cassette sources disk image](http://www.elitehomepage.org/archive/a/a4080602.zip), yet the final `ELTcode` binary is. What gives?

This comes down to a single byte in the default Commander data. This byte controls whether or not the Commander has a rear pulse laser, and is related to whether the BASIC variable `Q%` is TRUE or FALSE. This appears to be a cheat flag used during testing.

The implication is that the `ELTB` binary file on the cassette sources disk was not produced at the same time as the `ELTcode` file in the released product, but was modified after the `ELTcode` file was created. (We can see that running the build process in an emulator results in a different output and checksum values.)

To support this discrepancy, there are two build targets for building the encrypted game: `make encrypt` and `make extract`. The first target produces an `ELTcode` executable that is identical to the `ELTcode` file extracted from the cassette sources disk image (and which was released as the final game). The second target produces an `ELTB` binary file that is identical to the `ELTB` file extracted from the cassette sources disk image, though this means that the `ELTcode` executable produced by this build target is different to the released version (because the default Commander has the extra rear pulse laser).

You can use the verify target above to confirm this. Doing `make encrypt verify` shows that all the generated files match the extracted ones except for `ELTB`, while `make extract verify` shows that the all the generated files match the extracted ones except for `ELTcode`.

## Next Steps

Although the binary files output are identical, the build process is *brittle* meaning that the source cannot be altered. The main problem is that the encrytion process does not have knowledge of the symbols produced by the assembler, so these values have been hard coded for temporary convenience.

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
