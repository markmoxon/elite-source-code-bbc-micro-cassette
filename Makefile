BEEBASM?=beebasm
PYTHON?=python

rel-cassette=1
folder-cassette=
suffix-cassette=-from-source-disc

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
