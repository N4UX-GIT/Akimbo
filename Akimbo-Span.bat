@echo off
title Akimbo Multi-Monitor Spanner
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Akimbo-Span.ps1"
if errorlevel 1 pause
