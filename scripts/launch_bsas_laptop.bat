@echo off
TITLE Border Safety Alert System (BSAS) - Laptop Launcher
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch_bsas_laptop.ps1"
pause
