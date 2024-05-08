#!/usr/bin/env python
#
# ******************************************************************************
#
# CASSETTE ELITE CHECKSUM SCRIPT
#
# Written by Kieran Connell and Mark Moxon
#
# This script applies encryption, checksums and obfuscation to the compiled
# binaries for the main game and the loader. The script has two parts:
#
#   * The first part generates an encrypted version of the main game's "ELTcode"
#     binary, based on the code in the original "S.BCFS" BASIC source program
#
#   * The second part generates an encrypted version of the main game's "ELITE"
#     binary, based on the code in the original "ELITES" BASIC source program
#
# ******************************************************************************

from __future__ import print_function
import sys

argv = sys.argv
argc = len(argv)
Encrypt = True
disc = True
prot = False
release = 1

for arg in argv[1:]:
    if arg == "-u":
        Encrypt = False
    if arg == "-t":
        disc = False
    if arg == "-p":
        prot = True
    if arg == "-rel1":
        release = 1
    if arg == "-rel2":
        release = 2
    if arg == "-rel3":
        release = 3

print("Cassette Elite Checksum")
print("Encryption = ", Encrypt)
print("Build for disc = ", disc)
print("Add tape protection = ", prot)

# Configuration variables for scrambling code and calculating checksums
#
# Values must match those in 3-assembled-output/compile.txt
#
# If you alter the source code, then you should extract the correct values for
# the following variables and plug them into the following, otherwise the game
# will fail the checksum process and will hang on loading
#
# You can find the correct values for these variables by building your updated
# source, and then searching compile.txt for "elite-checksum.py", where the new
# values will be listed

if release == 1 or release == 2:

    BLOCK_offset = 0x14B0
    ENDBLOCK_offset = 0x1530
    MAINSUM_offset = 0x1335
    TUT_offset = 0x13E1
    CHECKbyt_offset = 0x1334
    CODE_offset = 0x0F86

elif release == 3:

    if prot:
        # PROT = TRUE
        BLOCK_offset = 0x14E1
        ENDBLOCK_offset = 0x1567
        MAINSUM_offset = 0x134A
        TUT_offset = 0x13F6
        CHECKbyt_offset = 0x1349
        CODE_offset = 0x0F86

    else:
        # PROT = FALSE
        BLOCK_offset = 0x14B0
        ENDBLOCK_offset = 0x1530
        MAINSUM_offset = 0x1335
        TUT_offset = 0x13E1
        CHECKbyt_offset = 0x1334
        CODE_offset = 0x0F86

# Load assembled code files that make up big code file

data_block = bytearray()
eliteb_offset = 0

# Append all assembled code files

elite_names = ("ELThead", "ELTA", "ELTB", "ELTC", "ELTD", "ELTE", "ELTF", "ELTG")

for file_name in elite_names:
    print(str(len(data_block)), file_name)
    if file_name == "ELTB":
        eliteb_offset = len(data_block)
    elite_file = open("3-assembled-output/" + file_name + ".bin", "rb")
    data_block.extend(elite_file.read())
    elite_file.close()

# Commander data checksum

commander_offset = 0x52
CH = 0x4B - 2
CY = 0
for i in range(CH, 0, -1):
    CH = CH + CY + data_block[eliteb_offset + i + 7]
    CY = (CH > 255) & 1
    CH = CH % 256
    CH = CH ^ data_block[eliteb_offset + i + 8]

print("Commander checksum = ", hex(CH))

# Must have Commander checksum otherwise game will lock:

if Encrypt:
    data_block[eliteb_offset + commander_offset] = CH ^ 0xA9
    data_block[eliteb_offset + commander_offset + 1] = CH

# Skip one byte for checksum0

checksum0_offset = len(data_block)
data_block.append(0)

# Append SHIPS file

ships_file = open("3-assembled-output/SHIPS.bin", "rb")
data_block.extend(ships_file.read())
ships_file.close()

print("3-assembled-output/SHIPS.bin file read")

# Calculate checksum0

checksum0 = 0
for n in range(0x0, 0x4600):
    checksum0 += data_block[n + 0x28]

print("checksum 0 = ", hex(checksum0))

if Encrypt:
    data_block[checksum0_offset] = checksum0 % 256

# Encrypt data block

if Encrypt:
    for n in range(0x0, len(data_block) - 0x28):
        data_block[n + 0x28] ^= (n % 256)

# Calculate checksum1

checksum1 = 0
for n in range(0x0, 0x28):
    checksum1 += data_block[n]

print("checksum 1 = ", hex(checksum1))

# Write output file for ELTcode

output_file = open("3-assembled-output/ELTcode.bin", "wb")
output_file.write(data_block)
output_file.close()

print("3-assembled-output/ELTcode.bin file saved")

output_file = None

data_block = None

# Start again but for loader
print("Elite Loader Checksums")

loader_block = bytearray()

loader_file = open("3-assembled-output/ELITE.unprot.bin", "rb")
loader_block.extend(loader_file.read())
loader_file.close()

# Reverse bytes between BLOCK and ENDBLOCK

for i in range(0, int((ENDBLOCK_offset - BLOCK_offset) / 2)):
    temp = loader_block[BLOCK_offset + i]
    loader_block[BLOCK_offset + i] = loader_block[ENDBLOCK_offset - i - 1]
    loader_block[ENDBLOCK_offset - i - 1] = temp

#  Compute MAINSUM

MAINSUM = 0
for i in range(0, 0x400):
    MAINSUM += loader_block[i]

print("MAINSUM = ", hex(MAINSUM))

if Encrypt:
    loader_block[MAINSUM_offset + 1] = MAINSUM % 256

# Compute CHECKbyt

CHECKbyt = 0
for i in range(1, 384):
    CHECKbyt += loader_block[CHECKbyt_offset + i]

print("CHECKbyt = ", hex(CHECKbyt))

if Encrypt:
    loader_block[CHECKbyt_offset] = CHECKbyt % 256

if Encrypt:
    print("Encypting...")

    #  EOR code in BLOCK to ENDBLOCK

    for i in range(0, ENDBLOCK_offset - BLOCK_offset):
        loader_block[TUT_offset + i] ^= loader_block[BLOCK_offset + i]

    # EOR checksum code from CHECKbyt to end of loader
    # See Elite loader (Part 3 of 6) for decryption routine where we
    # EOR 2 pages for Ian Bell's variants, and 3 pages for STH variant

    if release == 1 or release == 2:

        for i in range(0, 2):
            for j in range(0, 256):
                if (j + i * 256 + CHECKbyt_offset) < len(loader_block):
                    loader_block[j + i * 256 + CHECKbyt_offset] ^= loader_block[j + CODE_offset]

    elif release == 3:

        for i in range(0, 3):
            for j in range(0, 256):
                if (j + i * 256 + CHECKbyt_offset) < len(loader_block):
                    loader_block[j + i * 256 + CHECKbyt_offset] ^= loader_block[j + CODE_offset]

    # EOR 15 pages of data at beginning of loader

    for i in range(0, 0xf):
        for j in range(0, 256):
            loader_block[j + i * 256] ^= loader_block[j + CODE_offset]

# Write output file for ELITE

output_file = open("3-assembled-output/ELITE.bin", "wb")
output_file.write(loader_block)
output_file.close()
print("3-assembled-output/ELITE.bin file saved")
