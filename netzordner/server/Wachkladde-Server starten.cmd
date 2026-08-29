@echo off
rem  Startet den Wachkladde-Server auf diesem Rechner.
rem  Fenster offen lassen, solange die Wache damit arbeitet.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wachkladde-server.ps1" %*
pause
