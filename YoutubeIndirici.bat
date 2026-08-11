@echo off
chcp 65001 >nul
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0YoutubeIndirici.ps1"
pause
