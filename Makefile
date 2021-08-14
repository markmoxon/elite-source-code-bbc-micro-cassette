BEEBASM?=beebasm
PYTHON?=python

# You can set the release that gets built by adding 'release=<rel>' to
# the make command, where <rel> is one of:
#
#   source-disc
#   text-sources
#
# So, for example:
#
#   make encrypt verify release=text-sources
#
# will build the version from the text sources on Ian Bell's site. If you
# omit the release parameter, it will build the source disc version.

ifeq ($(release), text-sources)
  rel-cassette=2
  folder-cassette=/text-sources
  suffix-cassette=-from-text-sources
else
  rel-cassette=1
  folder-cassette=/source-disc
  suffix-cassette=-from-source-disc
endif

.PHONY:build
build:
	echo _VERSION=1 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-cassette) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=TRUE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-source.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-bcfs.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -u -rel$(rel-cassette)
	$(BEEBASM) -i sources/elite-disc.asm -do elite-cassette$(suffix-cassette).ssd -boot ELTdata

.PHONY:encrypt
encrypt:
	echo _VERSION=1 > sources/elite-header.h.asm
	echo _RELEASE=$(rel-cassette) >> sources/elite-header.h.asm
	echo _REMOVE_CHECKSUMS=FALSE >> sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-source.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-bcfs.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -rel$(rel-cassette)
	$(BEEBASM) -i sources/elite-disc.asm -do elite-cassette$(suffix-cassette).ssd -boot ELTdata

.PHONY:verify
verify:
	@$(PYTHON) sources/crc32.py extracted$(folder-cassette) output
