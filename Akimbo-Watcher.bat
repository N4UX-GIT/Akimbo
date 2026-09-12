@echo off
title Akimbo Background Monitor Watcher
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Akimbo-Span.ps1" -Watch
