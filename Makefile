BEEBASM?=beebasm
PYTHON?=python

# A make command with no arguments will build the source disc variant with
# encrypted binaries, checksums enabled, the standard commander and crc32
# verification of the game binaries
#
# Optional arguments for the make command are:
#
#   variant=<release>   Build the specified variant:
#
#                         source-disc (default)
#                         text-sources
#                         sth
#
#   disc=no             Build a version to load from cassette rather than disc
#
#   protect=no          Disable block-level tape protection code (disc=no only)
#
#   commander=max       Start with a maxed-out commander
#
#   encrypt=no          Disable encryption and checksum routines
#
#   verify=no           Disable crc32 verification of the game binaries
#
# So, for example:
#
#   make variant=text-sources commander=max encrypt=no verify=no
#
# will build an unencrypted text sources variant with a maxed-out commander
# and no crc32 verification
#
# The following variables are written into elite-build-options.asm depending on
# the above arguments, so they can be passed to BeebAsm:
#
# _VERSION
#   1 = BBC Micro cassette
#
# _VARIANT
#   1 = Source disc
#   2 = Text sources
#   3 = Stairway to Hell (default)
#
# _MAX_COMMANDER
#   TRUE  = Maxed-out commander
#   FALSE = Standard commander
#
# _REMOVE_CHECKSUMS
#   TRUE  = Disable checksum routines
#   FALSE = Enable checksum routines
#
# _MATCH_ORIGINAL_BINARIES
#   TRUE  = Match binaries to released version (i.e. fill workspaces with noise)
#   FALSE = Zero-fill workspaces
#
# _DISC
#   TRUE  = Build for loading from disc
#   FALSE = Build for loading from cassette
#
# _PROT
#   TRUE  = Apply block-level tape protection
#   FALSE = Do not apply block-level tape protection
#
# The encrypt and verify arguments are passed to the elite-checksum.py and
# crc32.py scripts, rather than BeebAsm

ifeq ($(commander), max)
  max-commander=TRUE
else
  max-commander=FALSE
endif

ifeq ($(encrypt), no)
  unencrypt=-u
  remove-checksums=TRUE
else
  unencrypt=
  remove-checksums=FALSE
endif

ifeq ($(match), no)
  match-original-binaries=FALSE
else
  match-original-binaries=TRUE
endif

ifeq ($(protect), no)
  protect-tape=
  prot=FALSE
else
  protect-tape=-p
  prot=TRUE
endif

ifeq ($(disc), no)
  tape-or-disc=-t
  build-for-disc=FALSE
else
  tape-or-disc=
  build-for-disc=TRUE
  protect-tape=
  prot=FALSE
endif

ifeq ($(variant), text-sources)
  variant-number=2
  folder=/text-sources
  suffix=-flicker-free-from-text-sources
else ifeq ($(variant), source-disc)
  variant-number=1
  folder=/source-disc
  suffix=-flicker-free-from-source-disc
else
  variant-number=3
  suffix=-elite-compendium-sth
  ifeq ($(disc), no)
    folder=/sth-for-tape
  else
    folder=/sth
  endif
endif

.PHONY:all
all:
	echo _VERSION=1 > 1-source-files/main-sources/elite-build-options.asm
	echo _VARIANT=$(variant-number) >> 1-source-files/main-sources/elite-build-options.asm
	echo _REMOVE_CHECKSUMS=$(remove-checksums) >> 1-source-files/main-sources/elite-build-options.asm
	echo _MAX_COMMANDER=$(max-commander) >> 1-source-files/main-sources/elite-build-options.asm
	echo _DISC=$(build-for-disc) >> 1-source-files/main-sources/elite-build-options.asm
	echo _PROT=$(prot) >> 1-source-files/main-sources/elite-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/elite-source.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-bcfs.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-loader.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/elite-readme.asm -v >> 3-assembled-output/compile.txt
	cat 1-source-files/music/elite-music.rom 3-assembled-output/rom-extra1.bin 3-assembled-output/rom-extra2.bin 3-assembled-output/rom-extra3.bin 3-assembled-output/rom-extra4.bin > 3-assembled-output/elite-music.rom
	$(PYTHON) 2-build-files/elite-checksum.py $(unencrypt) $(tape-or-disc) $(protect-tape) -rel$(variant-number)
	$(BEEBASM) -i 1-source-files/main-sources/elite-disc.asm -do 5-compiled-game-discs/elite-cassette$(suffix).ssd -opt 3 -title "E L I T E"
ifneq ($(verify), no)
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries$(folder) 3-assembled-output
endif

.PHONY:b2
b2:
	curl -G "http://localhost:48075/reset/b2"
	curl -H "Content-Type:application/binary" --upload-file "5-compiled-game-discs/elite-cassette$(suffix).ssd" "http://localhost:48075/run/b2?name=elite-cassette$(suffix).ssd"
