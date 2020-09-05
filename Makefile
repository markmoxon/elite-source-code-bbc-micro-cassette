BEEBASM?=beebasm
PYTHON?=python

.PHONY:build
build:
	echo _REMOVE_CHECKSUMS=TRUE > annotated_sources/elite-header.h.asm
	echo _FIX_REAR_LASER=TRUE >> annotated_sources/elite-header.h.asm
	$(BEEBASM) -i annotated_sources/elite-source.asm -v > output/compile.txt
	$(BEEBASM) -i annotated_sources/elite-bcfs.asm -v >> output/compile.txt
	$(BEEBASM) -i annotated_sources/elite-loader.asm -v >> output/compile.txt
	$(PYTHON) annotated_sources/elite-checksum.py -u
	$(BEEBASM) -i annotated_sources/elite-disc.asm -do elite.ssd -boot ELITE

.PHONY:encrypt
encrypt:
	echo _REMOVE_CHECKSUMS=FALSE > annotated_sources/elite-header.h.asm
	echo _FIX_REAR_LASER=TRUE >> annotated_sources/elite-header.h.asm
	$(BEEBASM) -i annotated_sources/elite-source.asm -v > output/compile.txt
	$(BEEBASM) -i annotated_sources/elite-bcfs.asm -v >> output/compile.txt
	$(BEEBASM) -i annotated_sources/elite-loader.asm -v >> output/compile.txt
	$(PYTHON) annotated_sources/elite-checksum.py
	$(BEEBASM) -i annotated_sources/elite-disc.asm -do elite.ssd -boot ELITE

.PHONY:extract
extract:
	echo _REMOVE_CHECKSUMS=FALSE > annotated_sources/elite-header.h.asm
	echo _FIX_REAR_LASER=FALSE >> annotated_sources/elite-header.h.asm
	$(BEEBASM) -i annotated_sources/elite-source.asm -v > output/compile.txt
	$(BEEBASM) -i annotated_sources/elite-bcfs.asm -v >> output/compile.txt
	$(BEEBASM) -i annotated_sources/elite-loader.asm -v >> output/compile.txt
	$(PYTHON) annotated_sources/elite-checksum.py
	$(BEEBASM) -i annotated_sources/elite-disc.asm -do elite.ssd -boot ELITE

.PHONY:verify
verify:
	@$(PYTHON) annotated_sources/crc32.py extracted output
