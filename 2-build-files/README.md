# Build files for the BBC Micro cassette version of Elite

This folder contains support scripts for building the BBC Micro cassette version of Elite.

* [crc32.py](crc32.py) calculates checksums during the verify stage and compares the results with the relevant binaries in the [4-reference-binaries](../4-reference-binaries) folder

* [elite-checksum.py](elite-checksum.py) adds checksums and encryption to the assembled output

* [elite-decrypt.py](elite-decrypt.py) decrypts an encrypted game binary by doing the opposite to the elite-checksum.py script (this is not used in the build process, but is useful when trying to decrypt any new releases that might be found)

* mktibet.php and tibetuef.php are used to create UEFs from files.

It also contains the `make.exe` executable for Windows, plus the required DLL files.

---

Right on, Commanders!

_Mark Moxon_