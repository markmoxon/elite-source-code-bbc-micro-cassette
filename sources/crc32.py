#!/usr/bin/env python
#
# ******************************************************************************
#
# ELITE VERIFICATION SCRIPT
#
# Written by Kieran Connell, extended by Mark Moxon
#
# This script performs checksums on the compiled files from the build process,
# and checks them against the extracted files from the original source disc
#
# ******************************************************************************

from __future__ import print_function
import sys
import os
import os.path
import zlib


def main():
    if len(sys.argv) <= 2:
        # Do CRC on single folder
        folder = sys.argv[1] if len(sys.argv) == 2 else "."
        names = sorted(os.listdir(folder))

        print()
        print('Checksum   Size  Filename')
        print('------------------------------------------')

        for name in names:
            if name.endswith(".bin"):
                full_name = os.path.join(folder, name)
                if not os.path.isfile(full_name):
                    continue
                with open(full_name, 'rb') as f:
                    data = f.read()
                print('%08x  %5d  %s' % (
                    zlib.crc32(data) & 0xffffffff,
                    len(data),
                    full_name)
                )
        print()
    else:
        # Do CRC on two folders
        folder1 = sys.argv[1]
        names1 = sorted(os.listdir(folder1))
        folder2 = sys.argv[2]
        names2 = sorted(os.listdir(folder2))
        names = list(names1)
        names.extend(x for x in names2 if x not in names)

        src = '[{0: ^13}]'.format(folder1[0:13]).replace(' ', '-')
        dest = '[{0: ^13}]'.format(folder2[0:13]).replace(' ', '-')

        print()
        print(src + '  ' + dest)
        print('Checksum   Size  Checksum   Size  Match  Filename')
        print('-----------------------------------------------------------')

        for name in names:
            if name.endswith(".bin"):
                full_name1 = os.path.join(folder1, name)
                full_name2 = os.path.join(folder2, name)

                if name in names1 and name in names2 and os.path.isfile(full_name1) and os.path.isfile(full_name2):
                    with open(full_name1, 'rb') as f:
                        data1 = f.read()
                    with open(full_name2, 'rb') as f:
                        data2 = f.read()
                    crc1 = zlib.crc32(data1) & 0xffffffff
                    crc2 = zlib.crc32(data2) & 0xffffffff
                    match = ' Yes ' if crc1 == crc2 and len(data1) == len(data2) else ' No  '
                    print('%08x  %5d  %08x  %5d  %s  %s' % (
                        crc1,
                        len(data1),
                        crc2,
                        len(data2),
                        match,
                        name)
                    )
                elif name in names1 and os.path.isfile(full_name1):
                    with open(full_name1, 'rb') as f:
                        data = f.read()
                    print('%08x  %5d  %s  %s  %s  %s' % (
                        zlib.crc32(data) & 0xffffffff,
                        len(data),
                        '-       ',
                        '    -',
                        '  -  ',
                        name)
                    )
                elif name in names2 and os.path.isfile(full_name2):
                    with open(full_name2, 'rb') as f:
                        data = f.read()
                    print('%s  %s  %08x  %5d  %s  %s' % (
                        '-       ',
                        '    -',
                        zlib.crc32(data) & 0xffffffff,
                        len(data),
                        '  -  ',
                        name)
                    )
        print()


if __name__ == '__main__':
    main()
