@echo off
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy', 'Bypass', '-NoExit', '-Command', 'Set-Location -Path ''%CD%''' -Verb RunAs"