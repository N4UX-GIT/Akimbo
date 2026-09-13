@echo off
title Offhand Multi-Monitor Spanner
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Offhand-Span.ps1"
if errorlevel 1 pause
