#!/usr/bin/env python
#
# ******************************************************************************
#
# CASSETTE ELITE DECRYPTION SCRIPT
#
# Written by Mark Moxon
#
# This script removes encryption and checksums from the compiled binaries for
# the main game code. It reads the encrypted "ELTcode.bin" binary and generates
# a decrypted version as "ELTcode.decrypt.bin"
#
# Files are saved using the decrypt.bin suffix so they don't overwrite any
# existing unprot.bin files, so they can be compared if required
#
# Run this script by changing directory to the repository's root folder and
# running the script with "python 2-build-files/elite-decrypt.py"
#
# You can decrypt specific releases by adding the following arguments, as in
# "python 2-build-files/elite-decrypt.py -rel1" for example:
#
#   -rel1   Decrypt the source discs from Ian Bell's site
#   -rel2   Decrypt the text source discs from Ian Bell's site
#   -rel3   Decrypt the Stairway to Hell release
#
# If unspecified, the default is rel3
#
# ******************************************************************************

from __future__ import print_function
import sys

print()
print("BBC cassette Elite decryption")

argv = sys.argv
release = 3
folder = "sth"

for arg in argv[1:]:
    if arg == "-rel1":
        release = 1
        folder = "source-disc"
    if arg == "-rel2":
        release = 2
        folder = "text-sources"
    if arg == "-rel3":
        release = 3
        folder = "sth"

# Configuration variables

if release == 1 or release == 2:

    BLOCK_offset = 0x14B0
    ENDBLOCK_offset = 0x1530
    MAINSUM_offset = 0x1335
    TUT_offset = 0x13E1
    CHECKbyt_offset = 0x1334
    CODE_offset = 0x0F86
    checksum0_offset = 0x4721

elif release == 3:

    BLOCK_offset = 0x14B0
    ENDBLOCK_offset = 0x1530
    MAINSUM_offset = 0x1335
    TUT_offset = 0x13E1
    CHECKbyt_offset = 0x1334
    CODE_offset = 0x0F86

if release == 1:

    checksum0_offset = 0x4721

elif release == 2:

    checksum0_offset = 0x471F

# Decrypt ELTcode

data_block = bytearray()

# Load assembled code file

elite_file = open("4-reference-binaries/" + folder + "/ELTcode.bin", "rb")
data_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] 4-reference-binaries/" + folder + "/ELTcode.bin")

# Do decryption

for n in range(0x0, len(data_block) - 0x28):
    data_block[n + 0x28] ^= (n % 256)

if release == 1 or release == 2:
    data_block[checksum0_offset] = 0

if release == 2:
    data_block.append(0)
    data_block.append(0)

print("[ Decrypt ] 4-reference-binaries/" + folder + "/ELTcode.bin")

# Write output file for ELTcode.decrypt

output_file = open("4-reference-binaries/" + folder + "/ELTcode.decrypt.bin", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] 4-reference-binaries/" + folder + "/ELTcode.decrypt.bin")

# Configuration variables for ELITE

loader_block = bytearray()

# Load assembled code file

elite_file = open("4-reference-binaries/" + folder + "/ELITE.bin", "rb")
loader_block.extend(elite_file.read())
elite_file.close()

print()
print("[ Read    ] 4-reference-binaries/" + folder + "/ELITE.bin")

# Do decryption

# EOR 15 pages of data at beginning of loader

for i in range(0xe, -1, -1):
    for j in range(255, -1, -1):
        loader_block[j + i * 256] ^= loader_block[j + CODE_offset]

# EOR checksum code from CHECKbyt to end of loader
# See Elite loader (Part 3 of 6) for decryption routine where we
# EOR 2 pages for Ian Bell's variants, and 3 pages for STH variant

if release == 1 or release == 2:

    for i in range(1, -1, -1):
        for j in range(255, -1, -1):
            if (j + i * 256 + CHECKbyt_offset) < len(loader_block):
                loader_block[j + i * 256 + CHECKbyt_offset] ^= loader_block[j + CODE_offset]

elif release == 3:

    for i in range(2, -1, -1):
        for j in range(255, -1, -1):
            if (j + i * 256 + CHECKbyt_offset) < len(loader_block):
                loader_block[j + i * 256 + CHECKbyt_offset] ^= loader_block[j + CODE_offset]

#  EOR code in BLOCK to ENDBLOCK

for i in range(ENDBLOCK_offset - BLOCK_offset - 1, -1, -1):
    loader_block[TUT_offset + i] ^= loader_block[BLOCK_offset + i]

# Reverse bytes between BLOCK and ENDBLOCK

for i in range(0, int((ENDBLOCK_offset - BLOCK_offset) / 2)):
    temp = loader_block[BLOCK_offset + i]
    loader_block[BLOCK_offset + i] = loader_block[ENDBLOCK_offset - i - 1]
    loader_block[ENDBLOCK_offset - i - 1] = temp

# Zero two checksum bytes to match assembled code

loader_block[CHECKbyt_offset] = 0
loader_block[MAINSUM_offset + 1] = 0

print("[ Decrypt ] 4-reference-binaries/" + folder + "/ELITE.bin")

# Write output file for ELITE.decrypt

output_file = open("4-reference-binaries/" + folder + "/ELITE.decrypt.bin", "wb")
output_file.write(loader_block)
output_file.close()

print("[ Save    ] 4-reference-binaries/" + folder + "/ELITE.decrypt.bin")
print()
