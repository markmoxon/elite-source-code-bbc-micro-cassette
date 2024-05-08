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

# Configuration variables for ELTcode

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

print("[ Decrypt ] 4-reference-binaries/" + folder + "/ELTcode.bin")

# Write output file for D.CODE.decrypt

output_file = open("4-reference-binaries/" + folder + "/ELTcode.decrypt.bin", "wb")
output_file.write(data_block)
output_file.close()

print("[ Save    ] 4-reference-binaries/" + folder + "/ELTcode.decrypt.bin")
print()
