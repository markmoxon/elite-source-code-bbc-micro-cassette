# Fully documented source code for Elite on the BBC Micro

**BBC Micro cassette Elite** | [BBC Micro disc Elite](https://github.com/markmoxon/disc-elite-beebasm) | [6502 Second Processor Elite](https://github.com/markmoxon/6502sp-elite-beebasm) | [BBC Master Elite](https://github.com/markmoxon/master-elite-beebasm) | [Acorn Electron Elite](https://github.com/markmoxon/electron-elite-beebasm) | [NES Elite](https://github.com/markmoxon/nes-elite-beebasm) | [Elite-A](https://github.com/markmoxon/elite-a-beebasm) | [Teletext Elite](https://github.com/markmoxon/teletext-elite) | [Elite Universe Editor](https://github.com/markmoxon/elite-universe-editor) | [Elite Compendium](https://github.com/markmoxon/elite-compendium) | [Flicker-free C64 Elite](https://github.com/markmoxon/c64-elite-flicker-free) | [Aviator](https://github.com/markmoxon/aviator-beebasm) | [Revs](https://github.com/markmoxon/revs-beebasm)


![Screenshot of Elite on the BBC Micro](https://www.bbcelite.com/images/github/Elite-BBCMicro.png)

This repository contains the original source code for Elite on the BBC Micro, with every single line documented and (for the most part) explained. It is literally the original source code, just heavily documented.

It is a companion to the [bbcelite.com website](https://www.bbcelite.com).

See the [introduction](#introduction) for more information, or jump straight into the [documented source code](1-source-files/main-sources).

## Contents

* [Introduction](#introduction)

* [Acknowledgements](#acknowledgements)

  * [A note on licences, copyright etc.](#user-content-a-note-on-licences-copyright-etc)

* [Browsing the source in an IDE](#browsing-the-source-in-an-ide)

* [Folder structure](#folder-structure)

* [Flicker-free Elite](#flicker-free-elite)

* [Building Elite from the source](#building-elite-from-the-source)

  * [Requirements](#requirements)
  * [Windows](#windows)
  * [Mac and Linux](#mac-and-linux)
  * [Build options](#build-options)
  * [Updating the checksum scripts if you change the code](#updating-the-checksum-scripts-if-you-change-the-code)
  * [Verifying the output](#verifying-the-output)
  * [Log files](#log-files)
  * [Auto-deploying to the b2 emulator](#auto-deploying-to-the-b2-emulator)

* [Building different variants of the cassette version of Elite](#building-different-variants-of-the-cassette-version-of-elite)

  * [Building the source disc variant](#building-the-source-disc-variant)
  * [Building the text sources variant](#building-the-text-sources-variant)
  * [Differences between the variants](#differences-between-the-variants)

* [Notes on the original source files](#notes-on-the-original-source-files)

  * [Fixing a bug in the source disc](#fixing-a-bug-in-the-source-disc)

## Introduction

This repository contains the original source code for Elite on the BBC Micro, with every single line documented and (for the most part) explained.

You can build the fully functioning game from this source. [Two variants](#building-different-variants-of-the-cassette-version-of-elite) are currently supported: the version produced by the original source discs from Ian Bell's personal website, and the version built from the text sources from the same site.

It is a companion to the [bbcelite.com website](https://www.bbcelite.com), which contains all the code from this repository, but laid out in a much more human-friendly fashion. The links at the top of this page will take you to repositories for the other versions of Elite that are covered by this project.

* If you want to browse the source and read about how Elite works under the hood, you will probably find [the website](https://www.bbcelite.com) is a better place to start than this repository.

* If you would rather explore the source code in your favourite IDE, then the [annotated source](1-source-files/main-sources/elite-source.asm) is what you're looking for. It contains the exact same content as the website, so you won't be missing out (the website is generated from the source files, so they are guaranteed to be identical). You might also like to read the section on [Browsing the source in an IDE](#browsing-the-source-in-an-ide) for some tips.

* If you want to build Elite from the source on a modern computer, to produce a working game disc that can be loaded into a BBC Micro or an emulator, then you want the section on [Building Elite from the source](#building-elite-from-the-source).

My hope is that this repository and the [accompanying website](https://www.bbcelite.com) will be useful for those who want to learn more about Elite and what makes it tick. It is provided on an educational and non-profit basis, with the aim of helping people appreciate one of the most iconic games of the 8-bit era.

## Acknowledgements

Elite was written by Ian Bell and David Braben and is copyright &copy; Acornsoft 1984.

The code on this site is identical to the source discs released on [Ian Bell's personal website](http://www.elitehomepage.org/) (it's just been reformatted to be more readable).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with; to Paul Brink for his annotated disassembly; and to Kieran Connell for his [BeebAsm version](https://github.com/kieranhj/elite-beebasm), which I forked as the original basis for this project. You can find more information about this project in the [accompanying website's project page](https://www.bbcelite.com/about_site/about_this_project.html).

The following archives from Ian Bell's personal website form the basis for this project:

* [Cassette sources as a disc image](http://www.elitehomepage.org/archive/a/a4080602.zip)
* [Cassette sources as text files](http://www.elitehomepage.org/archive/a/a4080610.zip)

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my commentary is intertwined with the original Elite source code, and the original source code is copyright. The whole site is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation. I do hope, though, that along with the various other disassemblies and commentaries of this source, it will remain viable.

## Browsing the source in an IDE

If you want to browse the source in an IDE, you might find the following useful.

* The most interesting files are in the [main-sources](1-source-files/main-sources) folder:

  * The main game's source code is in the [elite-source.asm](1-source-files/main-sources/elite-source.asm) file - this is the motherlode and probably contains all the stuff you're interested in.

  * The game's loader is in the [elite-loader.asm](1-source-files/main-sources/elite-loader.asm) file - this is mainly concerned with setup and copy protection.

* It's probably worth skimming through the [notes on terminology and notations](https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html) on the accompanying website, as this explains a number of terms used in the commentary, without which it might be a bit tricky to follow at times (in particular, you should understand the terminology I use for multi-byte numbers).

* The accompanying website contains [a number of "deep dive" articles](https://www.bbcelite.com/deep_dives/), each of which goes into an aspect of the game in detail. Routines that are explained further in these articles are tagged with the label `Deep dive:` and the relevant article name.

* There are loads of routines and variables in Elite - literally hundreds. You can find them in the source files by searching for the following: `Type: Subroutine`, `Type: Variable`, `Type: Workspace` and `Type: Macro`.

* If you know the name of a routine, you can find it by searching for `Name: <name>`, as in `Name: SCAN` (for the 3D scanner routine) or `Name: LL9` (for the ship-drawing routine).

* The entry point for the [main game code](1-source-files/main-sources/elite-source.asm) is routine `TT170`, which you can find by searching for `Name: TT170`. If you want to follow the program flow all the way from the title screen around the main game loop, then you can find a number of [deep dives on program flow](https://www.bbcelite.com/deep_dives/) on the accompanying website.

* The source code is designed to be read at an 80-column width and with a monospaced font, just like in the good old days.

I hope you enjoy exploring the inner workings of BBC Elite as much as I have.

## Folder structure

There are five main folders in this repository, which reflect the order of the build process.

* [1-source-files](1-source-files) contains all the different source files, such as the main assembler source files, image binaries, fonts, boot files and so on.

* [2-build-files](2-build-files) contains build-related scripts, such as the checksum, encryption and crc32 verification scripts.

* [3-assembled-output](3-assembled-output) contains the output from the assembly process, when the source files are assembled and the results processed by the build files.

* [4-reference-binaries](4-reference-binaries) contains the correct binaries for each variant, so we can verify that our assembled output matches the reference.

* [5-compiled-game-discs](5-compiled-game-discs) contains the final output of the build process: an SSD disc image that contains the compiled game and which can be run on real hardware or in an emulator.

## Flicker-free Elite

This repository also includes a flicker-free version, which incorporates the backported flicker-free ship-drawing routines from the BBC Master. The flicker-free code is in a separate branch called `flicker-free`, and apart from the code differences for reducing flicker, this branch is identical to the main branch and the same build process applies.

The annotated source files in the `flicker-free` branch contain both the original Acornsoft code and all of the modifications for flicker-free Elite, so you can look through the source to see exactly what's changed. Any code that I've removed from the original version is commented out in the source files, so when they are assembled they produce the flicker-free binaries, while still containing details of all the modifications. You can find all the diffs by searching the sources for `Mod:`.

For more information on flicker-free Elite, see the [hacks section of the accompanying website](https://www.bbcelite.com/hacks/flicker-free_elite.html).

## Building Elite from the source

Builds are supported for both Windows and Mac/Linux systems. In all cases the build process is defined in the `Makefile` provided.

### Requirements

You will need the following to build Elite from the source:

* BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). Mac and Linux users will have to build their own executable with `make code`, while Windows users can just download the `beebasm.exe` file.

* Python. Both versions 2.7 and 3.x should work.

* Mac and Linux users may need to install `make` if it isn't already present (for Windows users, `make.exe` is included in this repository).

For details of how the build process works, see the [build documentation on bbcelite.com](https://www.bbcelite.com/about_site/building_elite.html).

Let's look at how to build Elite from the source.

### Windows

For Windows users, there is a batch file called `make.bat` which you can use to build the game. Before this will work, you should edit the batch file and change the values of the `BEEBASM` and `PYTHON` variables to point to the locations of your `beebasm.exe` and `python.exe` executables. You also need to change directory to the repository folder (i.e. the same folder as `make.bat`).

All being well, entering the following into a command window:

```
make.bat
```

will produce a file called `elite-cassette-from-source-disc.ssd` in the `5-compiled-game-discs` folder that contains the source disc variant, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Mac and Linux

The build process uses a standard GNU `Makefile`, so you just need to install `make` if your system doesn't already have it. If BeebAsm or Python are not on your path, then you can either fix this, or you can edit the `Makefile` and change the `BEEBASM` and `PYTHON` variables in the first two lines to point to their locations. You also need to change directory to the repository folder (i.e. the same folder as `Makefile`).

All being well, entering the following into a terminal window:

```
make
```

will produce a file called `elite-cassette-from-source-disc.ssd` in the `5-compiled-game-discs` folder that contains the source disc variant, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Build options

By default the build process will create a typical Elite game disc with a standard commander and verified binaries. There are various arguments you can pass to the build to change how it works. They are:

* `variant=<name>` - Build the specified variant:

  * `variant=source-disc` (default)
  * `variant=text-sources`

* `commander=max` - Start with a maxed-out commander (specifically, this is the test commander file from the original source, which is almost but not quite maxed-out)

* `encrypt=no` - Disable encryption and checksum routines

* `verify=no` - Disable crc32 verification of the game binaries

So, for example:

`make variant=text-sources commander=max encrypt=no match=no verify=no`

will build an unencrypted text sources variant with a maxed-out commander, no workspace noise and no crc32 verification.

The unencrypted version should be more useful for anyone who wants to make modifications to the game code. As this argument produces unencrypted files, the binaries produced will be quite different to the binaries on the original source disc, which are encrypted.

See below for more on the verification process.

### Updating the checksum scripts if you change the code

If you change the source code in any way, you may break the game; if so, it will typically hang at the loading screen, though in some versions it may hang when launching from the space station.

To fix this, you may need to update some of the hard-coded addresses in the checksum script so that they match the new addresses in your changed version of the code. See the comments in the [elite-checksum.py](2-build-files/elite-checksum.py) script for details.

### Verifying the output

The default build process prints out checksums of all the generated files, along with the checksums of the files from the original sources. You can disable verification by passing `verify=no` to the build.

The Python script `crc32.py` in the `2-build-files` folder does the actual verification, and shows the checksums and file sizes of both sets of files, alongside each other, and with a Match column that flags any discrepancies. If you are building an unencrypted set of files then there will be lots of differences, while the encrypted files should mostly match (see the Differences section below for more on this).

The binaries in the `4-reference-binaries` folder were taken straight from the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip), while those in the `3-assembled-output` folder are produced by the build process. For example, if you don't make any changes to the code and build the project with `make`, then this is the output of the verification process:

```
Results for variant: source-disc
[--originals--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
a88ca82b   5426  a88ca82b   5426   Yes   ELITE.bin
f40816ec   5426  f40816ec   5426   Yes   ELITE.unprot.bin
0f1ad255   2228  0f1ad255   2228   Yes   ELTA.bin
e725760a   2600  e725760a   2600   Yes   ELTB.bin
97e338e8   2735  97e338e8   2735   Yes   ELTC.bin
322b174c   2882  322b174c   2882   Yes   ELTD.bin
29f7b8cb   2663  29f7b8cb   2663   Yes   ELTE.bin
8a4cecc2   2721  8a4cecc2   2721   Yes   ELTF.bin
7a6a5d1a   2340  7a6a5d1a   2340   Yes   ELTG.bin
01a00dce  20712  01a00dce  20712   Yes   ELTcode.bin
1e4466ec  20712  1e4466ec  20712   Yes   ELTcode.unprot.bin
00d5bb7a     40  00d5bb7a     40   Yes   ELThead.bin
99529ca8    256  99529ca8    256   Yes   PYTHON.bin
49ee043c   2502  49ee043c   2502   Yes   SHIPS.bin
c4547e5e   1023  c4547e5e   1023   Yes   WORDS9.bin
```

All the compiled binaries match the originals, so we know we are producing the same final game as the source disc variant.

### Log files

During compilation, details of every step are output in a file called `compile.txt` in the `3-assembled-output` folder. If you have problems, it might come in handy, and it's a great reference if you need to know the addresses of labels and variables for debugging (or just snooping around).

### Auto-deploying to the b2 emulator

For users of the excellent [b2 emulator](https://github.com/tom-seddon/b2), you can include the build parameter `b2` to automatically load and boot the assembled disc image in b2. The b2 emulator must be running for this to work.

For example, to build, verify and load the game into b2, you can do this on Windows:

```
make.bat all b2
```

or this on Mac/Linux:

```
make all b2
```

If you omit the `all` target then b2 will start up with the results of the last successful build.

Note that you should manually choose the correct platform in b2 (I intentionally haven't automated this part to make it easier to test across multiple platforms).

## Building different variants of the cassette version of Elite

This repository contains the source code for two different variants of the cassette version of Elite:

* The variant produced by the original source discs from Ian Bell's personal website

* The variant built from the text sources from the same site

It turns out that the BASIC source files in the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip) are not identical to the [cassette sources as text files](http://www.elitehomepage.org/archive/a/a4080610.zip), hence the two different variants.

By default the build process builds the source disc variant, but you can build a specified variant using the `variant=` build parameter.

### Building the source disc variant

You can add `variant=source-disc` to produce the `elite-cassette-from-source-disc.ssd` file containing the source disc variant, though that's the default value so it isn't necessary. In other words, you can build it like this:

```
make.bat variant=source-disc
```

or this on a Mac or Linux:

```
make variant=source-disc
```

This will produce a file called `elite-cassette-from-source-disc.NES` in the `5-compiled-game-discs` folder that contains the source disc variant.

The verification checksums for this version are as follows:

```
Results for variant: source-disc
[--originals--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
a88ca82b   5426  a88ca82b   5426   Yes   ELITE.bin
f40816ec   5426  f40816ec   5426   Yes   ELITE.unprot.bin
0f1ad255   2228  0f1ad255   2228   Yes   ELTA.bin
e725760a   2600  e725760a   2600   Yes   ELTB.bin
97e338e8   2735  97e338e8   2735   Yes   ELTC.bin
322b174c   2882  322b174c   2882   Yes   ELTD.bin
29f7b8cb   2663  29f7b8cb   2663   Yes   ELTE.bin
8a4cecc2   2721  8a4cecc2   2721   Yes   ELTF.bin
7a6a5d1a   2340  7a6a5d1a   2340   Yes   ELTG.bin
01a00dce  20712  01a00dce  20712   Yes   ELTcode.bin
1e4466ec  20712  1e4466ec  20712   Yes   ELTcode.unprot.bin
00d5bb7a     40  00d5bb7a     40   Yes   ELThead.bin
99529ca8    256  99529ca8    256   Yes   PYTHON.bin
49ee043c   2502  49ee043c   2502   Yes   SHIPS.bin
c4547e5e   1023  c4547e5e   1023   Yes   WORDS9.bin
```

### Building the text sources variant

You can build the text sources variant by appending `variant=text-sources` to the `make` command, like this on Windows:

```
make.bat variant=text-sources
```

or this on a Mac or Linux:

```
make variant=text-sources
```

This will produce a file called `elite-cassette-from-text-sources.ssd` in the `5-compiled-game-discs` folder that contains the Ian Bell disc variant.

The verification checksums for this version are as follows:

```
Results for variant: text-sources
[--originals--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
093c73aa   5426  093c73aa   5426   Yes   ELITE.bin
24da3246   5426  24da3246   5426   Yes   ELITE.unprot.bin
6c109c76   2228  6c109c76   2228   Yes   ELTA.bin
cd8bee0c   2600  cd8bee0c   2600   Yes   ELTB.bin
20c22628   2732  20c22628   2732   Yes   ELTC.bin
23c13c71   2885  23c13c71   2885   Yes   ELTD.bin
ce0d9ec7   2663  ce0d9ec7   2663   Yes   ELTE.bin
5aed3c61   2719  5aed3c61   2719   Yes   ELTF.bin
13f3eace   2340  13f3eace   2340   Yes   ELTG.bin
8b79fe39  20710  8b79fe39  20710   Yes   ELTcode.bin
7c24aab0  20712  7c24aab0  20712   Yes   ELTcode.unprot.bin
00d5bb7a     40  00d5bb7a     40   Yes   ELThead.bin
99529ca8    256  99529ca8    256   Yes   PYTHON.bin
8f4b6f2b   2502  8f4b6f2b   2502   Yes   SHIPS.bin
c4547e5e   1023  c4547e5e   1023   Yes   WORDS9.bin
```

### Differences between the variants

You can see the differences between the variants by searching the source code for `_SOURCE_DISC` (for features in the source disc variant) or `_TEXT_SOURCES` (for features in the text sources variant). There are only minor differences:

* The text sources contain an extra call in the galactic hyperspace routine that sets the current system to the nearest system to the crosshairs. This code is present in all other versions of the game (albeit in a different place), but not the original source disc from Ian Bell's personal website

* In order to fit this extra call in (which takes three extra bytes), the text sources also contain four modifications to create space for the call, which together save five bytes.

* There is a small change in the TTX66 routine to reset LAS2 to 0 instead of LASCT to stop laser pulsing, as this is slightly more efficient.

All these changes are carried through to all other versions of the game, so it looks like the text sources contain a slightly later version of the game than the source disc.

See the [accompanying website](https://www.bbcelite.com/disc/releases.html) for a comprehensive list of differences between the variants.

## Notes on the original source files

### Fixing a bug in the source disc

It also turns out there are two versions of the `ELITEB` BASIC source program on the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip), one called `$.ELITEB` and another called `O.ELITEB`. These two versions of `ELITEB` differ by just one byte in the default commander data. This byte controls whether or not the commander has a rear pulse laser. In `O.ELITEB` this byte is generated by:

```
EQUB (POW + 128) AND Q%
```

while in `$.ELITEB`, this byte is generated by:

```
EQUB POW
```

The BASIC variable `Q%` is a Boolean flag that, if `TRUE`, will create a default commander with lots of cash and equipment, which is useful for testing. You can see this in action if you build an unencrypted binary with `make build`, as the unencrypted build sets `Q%` to `TRUE` for this build target.

The BASIC variable `POW` has a value of 15, which is the power of a pulse laser. `POW + 128`, meanwhile, is the power of a beam laser.

Given the above, we can see that `O.ELITEB` correctly produces a default commander with no a rear laser if `Q%` is `FALSE`, but adds a rear beam laser if `Q%` is `TRUE`. This matches the default commander from the released game, and produces the `ELTcode` executable on the same disc. The version of `ELITEB` in the [cassette sources as text files](http://www.elitehomepage.org/archive/a/a4080610.zip) matches this version, `O.ELITEB`.

In contrast, `$.ELITEB` will always produce a default commander with a rear pulse laser, irrespective of the setting of `Q%`, so it doesn't match the released version.

The `ELTB` binary file in the `4-reference-binaries` folder of this repository matches the version generated by the source disc, so we can easily tell whether any changes we've made to the code deviate from this version. However, the `ELTB` binary file on the sources disc matches the version produced by `$.ELITEB`, rather than the version produced by `O.ELITEB` - in other words, `ELTB` on the source disc is not the version generated by the source code on the same disc.

The implication is that the `ELTB` binary file on the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip) was produced by `$.ELITEB`, while the `ELTcode` file (the released game) used `O.ELITEB`. Perhaps the released game was compiled, and then someone backed up the `ELITEB` source to `O.ELITEB`, edited the `$.ELITEB` to have a rear pulse laser, and then generated a new `ELTB` binary file. Who knows? Unfortunately, files on DFS discs don't have timestamps, so it's hard to tell.

---

Right on, Commanders!

_Mark Moxon_