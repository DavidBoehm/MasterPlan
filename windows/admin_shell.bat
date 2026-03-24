@echo off
powershell -Command "Start-Process powershell -ArgumentList '-NoExit', '-Command', 'Set-Location -Path ''%CD%''' -Verb RunAs"