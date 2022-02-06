# Build files for the BBC Micro cassette version of Elite

This folder contains support scripts for building the BBC Micro cassette version of Elite.

* [crc32.py](crc32.py) calculates checksums during the verify stage and compares the results with the relevant binaries in the [4-reference-binaries](../4-reference-binaries) folder

* [elite-checksum.py](elite-checksum.py) adds checksums and encryption to the assembled output

It also contains the `make.exe` executable for Windows, plus the required DLL files.

---

Right on, Commanders!

_Mark Moxon_