# Annotated source code for the BBC Micro cassette version of Elite

This folder contains the annotated source code for the BBC Micro cassette version of Elite.

* [elite-bcfs.asm](elite-bcfs.asm) contains the Big Code File source, which concatenates individually assembled binaries into the final game binary

* [elite-disc.asm](elite-disc.asm) builds the SSD disc image from the assembled binaries and other source files

* [elite-loader.asm](elite-loader.asm) contains the source for the loader

* [elite-readme.asm](elite-readme.asm) generates a README file for inclusion on the SSD disc image

* [elite-source.asm](elite-source.asm) contains the main source for the game

It also contains the following file that is generated during the build process:

* [elite-build-options.asm](elite-build-options.asm) stores the make options in BeebAsm format so they can be included in the assembly process

---

Right on, Commanders!

_Mark Moxon_