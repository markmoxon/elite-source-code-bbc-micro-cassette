BEEBASM?=beebasm
PYTHON?=python

.PHONY:build
build:
	echo _REMOVE_CHECKSUMS=TRUE > sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-source.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-bcfs.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py -u
	$(BEEBASM) -i sources/elite-disc.asm -do elite.ssd -opt 3

.PHONY:encrypt
encrypt:
	echo _REMOVE_CHECKSUMS=FALSE > sources/elite-header.h.asm
	$(BEEBASM) -i sources/elite-source.asm -v > output/compile.txt
	$(BEEBASM) -i sources/elite-bcfs.asm -v >> output/compile.txt
	$(BEEBASM) -i sources/elite-loader.asm -v >> output/compile.txt
	$(PYTHON) sources/elite-checksum.py
	$(BEEBASM) -i sources/elite-disc.asm -do elite.ssd -opt 3

.PHONY:verify
verify:
	@$(PYTHON) sources/crc32.py extracted output
