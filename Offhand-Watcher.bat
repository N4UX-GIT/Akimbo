@echo off
title Offhand Background Monitor Watcher
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Offhand-Span.ps1" -Watch
