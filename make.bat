@echo off
SETLOCAL
SET BEEBASM=..\..\bin\beebasm.exe
SET PYTHON=C:\Home\Python27\python.exe
make %1
if [%2]==[] goto skip
make %2
:skip
