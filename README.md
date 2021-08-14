# Fully documented source code for Elite on the BBC Micro

**BBC Micro (cassette)** | [BBC Micro (disc)](https://github.com/markmoxon/disc-elite-beebasm) | [6502 Second Processor](https://github.com/markmoxon/6502sp-elite-beebasm) | [BBC Master](https://github.com/markmoxon/master-elite-beebasm) | [Acorn Electron](https://github.com/markmoxon/electron-elite-beebasm) | [Elite-A](https://github.com/markmoxon/elite-a-beebasm)

![Screenshot of Elite on the BBC Micro](https://www.bbcelite.com/images/github/Elite-BBCMicro.png)

This repository contains the original source code for Elite on the BBC Micro, with every single line documented and (for the most part) explained.

It is a companion to the [bbcelite.com website](https://www.bbcelite.com).

See the [introduction](#introduction) for more information.

## Contents

* [Introduction](#introduction)

* [Acknowledgements](#acknowledgements)

  * [A note on licences, copyright etc.](#user-content-a-note-on-licences-copyright-etc)

* [Browsing the source in an IDE](#browsing-the-source-in-an-ide)

* [Building Elite from the source](#building-elite-from-the-source)

  * [Requirements](#requirements)
  * [Build targets](#build-targets)
  * [Windows](#windows)
  * [Mac and Linux](#mac-and-linux)
  * [Verifying the output](#verifying-the-output)
  * [Log files](#log-files)

* [Building different releases of the cassette version of Elite](#building-different-releases-of-the-cassette-version-of-elite)

  * [Building the source disc release](#building-the-source-disc-release)
  * [Building the text sources release](#building-the-text-sources-release)

* [Notes on the original source files](#notes-on-the-original-source-files)

  * [Fixing a bug in the source disc](#fixing-a-bug-in-the-source-disc)

## Introduction

This repository contains the original source code for Elite on the BBC Micro, with every single line documented and (for the most part) explained.

You can build the fully functioning game from this source. [Two releases](#building-different-releases-of-the-cassette-version-of-elite) are currently supported: the version produced by the original source discs from Ian Bell's site, and the version built from the text sources from the same site.

It is a companion to the [bbcelite.com website](https://www.bbcelite.com), which contains all the code from this repository, but laid out in a much more human-friendly fashion. The links at the top of this page will take you to repositories for the other versions of Elite that are covered by this project.

* If you want to browse the source and read about how Elite works under the hood, you will probably find [the website](https://www.bbcelite.com) is a better place to start than this repository.

* If you would rather explore the source code in your favourite IDE, then the [annotated source](sources/elite-source.asm) is what you're looking for. It contains the exact same content as the website, so you won't be missing out (the website is generated from the source files, so they are guaranteed to be identical). You might also like to read the section on [Browsing the source in an IDE](#browsing-the-source-in-an-ide) for some tips.

* If you want to build Elite from the source on a modern computer, to produce a working game disc that can be loaded into a BBC Micro or an emulator, then you want the section on [Building Elite from the source](#building-elite-from-the-source).

My hope is that this repository and the [accompanying website](https://www.bbcelite.com) will be useful for those who want to learn more about Elite and what makes it tick. It is provided on an educational and non-profit basis, with the aim of helping people appreciate one of the most iconic games of the 8-bit era.

## Acknowledgements

Elite was written by Ian Bell and David Braben and is copyright &copy; Acornsoft 1984.

The code on this site is identical to the source discs released on [Ian Bell's personal website](http://www.elitehomepage.org/) (it's just been reformatted to be more readable).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with; to Paul Brink for his annotated disassembly; and to Kieran Connell for his [BeebAsm version](https://github.com/kieranhj/elite-beebasm), which I forked as the original basis for this project. You can find more information about this project in the [accompanying website's project page](https://www.bbcelite.com/about_site/about_this_project.html).

The following archives from Ian Bell's site form the basis for this project:

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

* The most interesting files are in the [sources](sources) folder:

  * The main game's source code is in the [elite-source.asm](sources/elite-source.asm) file - this is the motherlode and probably contains all the stuff you're interested in.

  * The game's loader is in the [elite-loader.asm](sources/elite-loader.asm) file - this is mainly concerned with setup and copy protection.

* It's probably worth skimming through the [notes on terminology and notations](https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html) on the accompanying website, as this explains a number of terms used in the commentary, without which it might be a bit tricky to follow at times (in particular, you should understand the terminology I use for multi-byte numbers).

* The accompanying website contains [a number of "deep dive" articles](https://www.bbcelite.com/deep_dives/), each of which goes into an aspect of the game in detail. Routines that are explained further in these articles are tagged with the label `Deep dive:` and the relevant article name.

* There are loads of routines and variables in Elite - literally hundreds. You can find them in the source files by searching for the following: `Type: Subroutine`, `Type: Variable`, `Type: Workspace` and `Type: Macro`.

* If you know the name of a routine, you can find it by searching for `Name: <name>`, as in `Name: SCAN` (for the 3D scanner routine) or `Name: LL9` (for the ship-drawing routine).

* The entry point for the [main game code](sources/elite-source.asm) is routine `TT170`, which you can find by searching for `Name: TT170`. If you want to follow the program flow all the way from the title screen around the main game loop, then you can find a number of [deep dives on program flow](https://www.bbcelite.com/deep_dives/) on the accompanying website.

* The source code is designed to be read at an 80-column width and with a monospaced font, just like in the good old days.

I hope you enjoy exploring the inner-workings of BBC Elite as much as I have.

## Building Elite from the source

### Requirements

You will need the following to build Elite from the source:

* BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). Mac and Linux users will have to build their own executable with `make code`, while Windows users can just download the `beebasm.exe` file.

* Python. Both versions 2.7 and 3.x should work.

* Mac and Linux users may need to install `make` if it isn't already present (for Windows users, `make.exe` is included in this repository).

For details of how the build process works, see the [build documentation on bbcelite.com](https://www.bbcelite.com/about_site/building_elite.html).

Let's look at how to build Elite from the source.

### Build targets

There are two main build targets available. They are:

* `build` - An unencrypted version
* `encrypt` - An encrypted version that exactly matches the released version of the game

The unencrypted version should be more useful for anyone who wants to make modifications to the game code. It includes a default commander with lots of cash and equipment, which makes it easier to test the game. As this target produces unencrypted files, the binaries produced will be quite different to the binaries on the original source disc, which are encrypted.

The encrypted version produces the released version of Elite, along with the standard default commander.

Builds are supported for both Windows and Mac/Linux systems. In all cases the build process is defined in the `Makefile` provided.

Note that the build ends with a warning that there is no `SAVE` command in the source file. You can ignore this, as the source file contains a `PUTFILE` command instead, but BeebAsm still reports this as a warning.

### Windows

For Windows users, there is a batch file called `make.bat` to which you can pass one of the build targets above. Before this will work, you should edit the batch file and change the values of the `BEEBASM` and `PYTHON` variables to point to the locations of your `beebasm.exe` and `python.exe` executables. You also need to change directory to the repository folder (i.e. the same folder as `make.exe`).

All being well, doing one of the following:

```
make.bat build
```

```
make.bat encrypt
```

will produce a file called `elite-cassette-from-source-disc.ssd` containing the source disc release, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Mac and Linux

The build process uses a standard GNU `Makefile`, so you just need to install `make` if your system doesn't already have it. If BeebAsm or Python are not on your path, then you can either fix this, or you can edit the `Makefile` and change the `BEEBASM` and `PYTHON` variables in the first two lines to point to their locations. You also need to change directory to the repository folder (i.e. the same folder as `Makefile`).

All being well, doing one of the following:

```
make build
```

```
make encrypt
```

will produce a file called `elite-cassette-from-source-disc.ssd` containing the source disc release, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Verifying the output

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

The binaries in the `extracted` folder were taken straight from the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip) (though see the [notes on `ELTB`](#eltb) below), while those in the `output` folder are produced by the build process. For example, if you don't make any changes to the code and build the project with `make encrypt verify`, then this is the output of the verification process:

```
[--extracted--]  [---output----]
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

All the compiled binaries match the extracts, so we know we are producing the same final game as the release version.

### Log files

During compilation, details of every step are output in a file called `compile.txt` in the `output` folder. If you have problems, it might come in handy, and it's a great reference if you need to know the addresses of labels and variables for debugging (or just snooping around).

## Building different releases of the cassette version of Elite

This repository contains the source code for two different releases of the cassette version of Elite:

* The version produced by the original source discs from Ian Bell's site

* The version built from the text sources from the same site

It turns out that the BASIC source files in the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip) are not identical to the [cassette sources as text files](http://www.elitehomepage.org/archive/a/a4080610.zip), hence the two different releases.

By default the build process builds the source disc release, but you can build the other release as follows.

### Building the text sources release

You can build the text sources release by appending `release=text-sources` to the `make` command, like this on Windows:

```
make.bat encrypt verify release=text-sources
```

or this on a Mac or Linux:

```
make encrypt verify release=text-sources
```

This will produce a file called `elite-cassette-from-text-sources.ssd` that contains the Ian Bell disc release.

### Building the source disc release

You can add `release=source-disc` to produce the `elite-cassette-from-source-disc.ssd.ssd` file containing the source disc release, though that's the default value so it isn't necessary.

### Differences between the releases

You can see the differences between the releases by searching the source code for `_SOURCE_DISC` (for features in the source disc release) or `_TEXT_SOURCES` (for features in the text sources release). There are only minor differences:

* The text sources contain an extra call in the galactic hyperspace routine that sets the current system to the nearest system to the crosshairs. This code is present in all other versions of the game (albeit in a different place), but not the original source disc from Ian Bell's site

* In order to fit this extra call in (which takes three extra bytes), the text sources also contain four modifications to create space for the call, which together save four bytes.

* There is a small change in the TTX66 routine to reset LAS2 to 0 instead of LASCT to stop laser pulsing, as this is slightly more efficient.

All these changes are carried through to all other versions of the game, so it looks like the text sources contain a slightly later version of the game than the source disc.

See the [accompanying website](https://www.bbcelite.com/disc/releases.html) for a comprehensive list of differences between the releases.

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

Given the above, we can see that `O.ELITEB` correctly produces a default commander with no a rear laser if `Q%` is `FALSE`, but adds a rear beam laser if `Q%` is `TRUE`. This matches the released game, whose executable can be found as `ELTcode` on the same disc. The version of `ELITEB` in the [cassette sources as text files](http://www.elitehomepage.org/archive/a/a4080610.zip) matches this version, `O.ELITEB`.

In contrast, `$.ELITEB` will always produce a default commander with a rear pulse laser, irrespective of the setting of `Q%`, so it doesn't match the released version.

The `ELTB` binary file in the `extracted` folder of this repository matches the release version, so we can easily tell whether any changes we've made to the code deviate from the release version. However, the `ELTB` binary file on the sources disc matches the version produced by `$.ELITEB`, rather than the released version produced by `O.ELITEB` - in other words, `ELTB` on the source disc is not the release version.

The implication is that the `ELTB` binary file on the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip) was produced by `$.ELITEB`, while the `ELTcode` file (the released game) used `O.ELITEB`. Perhaps the released game was compiled, and then someone backed up the `ELITEB` source to `O.ELITEB`, edited the `$.ELITEB` to have a rear pulse laser, and then generated a new `ELTB` binary file. Who knows? Unfortunately, files on DFS discs don't have timestamps, so it's hard to tell.

---

Right on, Commanders!

_Mark Moxon_