@echo off
title Offhand Window Watcher
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Offhand-Span.ps1" -Watch
if errorlevel 1 pause
