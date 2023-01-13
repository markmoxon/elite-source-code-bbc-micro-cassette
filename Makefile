BEEBASM?=beebasm
PYTHON?=python

# You can set the variant that gets built by adding 'variant=<rel>' to
# the make command, where <rel> is one of:
#
#   source-disc
#   text-sources
#
# So, for example:
#
#   make encrypt verify variant=text-sources
#
# will build the variant from the text sources on Ian Bell's site. If you
# omit the variant parameter, it will build the source disc variant.

ifeq ($(variant), text-sources)
  variant-cassette=2
  folder-cassette=/text-sources
  suffix-cassette=-from-text-sources
else
  variant-cassette=1
  folder-cassette=/source-disc
  suffix-cassette=-from-source-disc
endif

.PHONY:build
build:
	echo _VERSION=1 > 1-source-files/main-sources/elite-build-options.asm
	echo _VARIANT=$(variant-cassette) >> 1-source-files/main-sources/elite-build-options.asm
	echo _REMOVE_CHECKSUMS=TRUE >> 1-source-files/main-sources/elite-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-bcfs.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py -u -rel$(variant-cassette)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm -do 5-compiled-game-discs/elite-cassette-flicker-free$(suffix-cassette).ssd -boot ELTdata -title "E L I T E"

.PHONY:encrypt
encrypt:
	echo _VERSION=1 > 1-source-files/main-sources/elite-build-options.asm
	echo _VARIANT=$(variant-cassette) >> 1-source-files/main-sources/elite-build-options.asm
	echo _REMOVE_CHECKSUMS=FALSE >> 1-source-files/main-sources/elite-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-bcfs.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	$(PYTHON) 2-build-files/elite-checksum.py -rel$(variant-cassette)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm -do 5-compiled-game-discs/elite-cassette-flicker-free$(suffix-cassette).ssd -boot ELTdata -title "E L I T E"

.PHONY:verify
verify:
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries$(folder-cassette) 3-assembled-output
